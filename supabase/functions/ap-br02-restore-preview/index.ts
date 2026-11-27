// AP-BR02 target-state preview endpoint. SELECT-only; no Storage and no writes.
import { createClient } from "npm:@supabase/supabase-js@2";
import { CATEGORY_TABLES, validatePackageManifest, buildMergePreview } from "../../../src/backup/restore-planner.js";
import { PREVIEW_SELECTS, validateRestorePreviewRequest, makePreviewEnvelope, RESTORE_PREVIEW_MAX_ROWS_PER_TABLE } from "../../../src/backup/restore-preview-contract.js";

const ORIGINS = new Set(["https://dev.kadassist.de"]);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const PAGE = 250;
const MAX_BODY = 4 * 1024 * 1024;
const headers = (req: Request) => ({
  ...(ORIGINS.has(req.headers.get("Origin") || "") ? { "Access-Control-Allow-Origin": req.headers.get("Origin")! } : {}),
  "Vary": "Origin",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
});
const reply = (req: Request, body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: headers(req) });
const fail = (code: string, status = 400) => ({ code, status });

const REFS: Record<string, { field: string; parent: string; parentKey?: string }[]> = {
  positions: [{field:"team_id",parent:"teams"}], players: [{field:"team_id",parent:"teams"}],
  seasons: [{field:"team_id",parent:"teams"}], training_series: [{field:"team_id",parent:"teams"}],
  trainings: [{field:"team_id",parent:"teams"},{field:"season_id",parent:"seasons"},{field:"series_id",parent:"training_series"}],
  matchdays: [{field:"team_id",parent:"teams"},{field:"season_id",parent:"seasons"}],
  player_positions: [{field:"player_id",parent:"players"},{field:"position_id",parent:"positions"}],
  attendance: [{field:"training_id",parent:"trainings"},{field:"player_id",parent:"players"}],
  training_players: [{field:"training_id",parent:"trainings"},{field:"player_id",parent:"players"}],
  training_trainers: [{field:"training_id",parent:"trainings"}],
  training_responses: [{field:"training_id",parent:"trainings"},{field:"player_id",parent:"players"}],
  matchday_players: [{field:"matchday_id",parent:"matchdays"},{field:"player_id",parent:"players"}],
  matchday_attendance: [{field:"matchday_id",parent:"matchdays"},{field:"player_id",parent:"players"}],
  matchday_trainers: [{field:"matchday_id",parent:"matchdays"}],
  matchday_recommendation_runs: [{field:"matchday_id",parent:"matchdays"}],
  matchday_recommendation_players: [{field:"recommendation_id",parent:"matchday_recommendation_runs"},{field:"player_id",parent:"players"}],
  training_behavior_events: [{field:"team_id",parent:"teams"},{field:"season_id",parent:"seasons"},{field:"training_id",parent:"trainings"},{field:"player_id",parent:"players"}],
  training_suspensions: [{field:"team_id",parent:"teams"},{field:"season_id",parent:"seasons"},{field:"player_id",parent:"players"},{field:"source_event_id",parent:"training_behavior_events"},{field:"intended_matchday_id",parent:"matchdays"},{field:"served_matchday_id",parent:"matchdays"}],
  training_suspension_exceptions: [{field:"team_id",parent:"teams"},{field:"suspension_id",parent:"training_suspensions"},{field:"player_id",parent:"players"},{field:"matchday_id",parent:"matchdays"}],
  matchday_early_suspension_resets: [{field:"team_id",parent:"teams"},{field:"season_id",parent:"seasons"},{field:"player_id",parent:"players"},{field:"matchday_id",parent:"matchdays"}],
  matchday_nomination_reminders: [{field:"team_id",parent:"teams"},{field:"player_id",parent:"players"},{field:"source_matchday_id",parent:"matchdays"},{field:"fulfilled_matchday_id",parent:"matchdays"}],
  team_suspension_game_type_settings: [{field:"team_id",parent:"teams"}],
  team_suspension_game_types: [{field:"team_id",parent:"teams"}],
  team_season_closure_audit: [{field:"team_id",parent:"teams"},{field:"season_id",parent:"seasons"}],
};
const ACTOR_FIELDS = ["created_by","awarded_by","voided_by","granted_by","revoked_by","closed_by","updated_by","user_id","cancelled_by","fulfilled_by","served_by"];

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { status: 200, headers: headers(req) });
  if (req.method !== "POST") return reply(req, { error: "Nur POST ist zulässig." }, 405);
  try {
    const length = Number(req.headers.get("Content-Length") || 0);
    if (length > MAX_BODY) return reply(req, { error: "Preview-Request überschreitet die sichere Paketgröße." }, 413);
    const raw = await req.text();
    if (new TextEncoder().encode(raw).byteLength > MAX_BODY) return reply(req, { error: "Preview-Request überschreitet die sichere Paketgröße." }, 413);
    let body: any; try { body = JSON.parse(raw); } catch { return reply(req, { error: "Ungültiger JSON-Request." }, 400); }
    if (!body?.manifest || !body?.snapshot_data || typeof body.snapshot_data !== "object" || Array.isArray(body.snapshot_data)) return reply(req, { error: "Manifest oder Snapshot fehlt." }, 400);
    validatePackageManifest(body.manifest);
    const scope = validateRestorePreviewRequest({
      scope_type: body.manifest.scope?.type,
      scope_id: body.manifest.scope?.id,
      selected_team_id: body.selected_team_id,
      manifest_scope: { type: body.manifest.scope?.type, id: body.manifest.scope?.id, team_ids: body.manifest.scope?.team_ids },
    });
    if (scope.scope_type !== "team") return reply(req, { error: "Restore-Preview V1 erlaubt ausschließlich denselben Team-Scope." }, 400);
    if (JSON.stringify(body.snapshot_data) !== JSON.stringify(body.manifest.snapshot.data)) return reply(req, { error: "Snapshot und validiertes Manifest stimmen nicht überein." }, 400);
    const selectedTables = [...new Set(body.manifest.categories.flatMap((category: string) => CATEGORY_TABLES[category] || []))];
    for (const table of selectedTables) {
      if (!Object.hasOwn(PREVIEW_SELECTS, table)) return reply(req, { error: "Tabelle ist nicht für die Preview freigegeben." }, 400);
      const rows = body.snapshot_data[table];
      if (!Array.isArray(rows) || rows.length > RESTORE_PREVIEW_MAX_ROWS_PER_TABLE) return reply(req, { error: "Backup-Tabelle fehlt oder überschreitet das Preview-Limit: " + table }, 413);
    }

    const url = Deno.env.get("SUPABASE_URL") || "";
    const anon = Deno.env.get("SUPABASE_ANON_KEY") || "";
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    const authHeader = req.headers.get("Authorization");
    if (!url || !anon || !service) return reply(req, { error: "Preview-Backend nicht konfiguriert." }, 500);
    if (!authHeader?.startsWith("Bearer ")) return reply(req, { error: "Anmeldung erforderlich." }, 401);
    const user = createClient(url, anon, { global: { headers: { Authorization: authHeader } }, auth: { persistSession: false, autoRefreshToken: false } });
    const { data: authData, error: authError } = await user.auth.getUser();
    if (authError || !authData.user) return reply(req, { error: "Benutzer konnte nicht authentifiziert werden." }, 401);
    const { data: allowed, error: permissionError } = await user.rpc("is_team_admin", { p_team_id: scope.scope_id });
    if (permissionError) return reply(req, { error: "Mannschaftsberechtigung konnte nicht geprüft werden." }, 500);
    if (allowed !== true) return reply(req, { error: "Kein Zugriff auf diesen Mannschaftskontext." }, 403);
    const admin = createClient(url, service, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: team, error: teamError } = await admin.from("teams").select("id").eq("id", scope.scope_id).maybeSingle();
    if (teamError || !team) return reply(req, { error: "Zielmannschaft nicht eindeutig verfügbar." }, 404);

    // Read dependency closure in topological order. All direct rows are team-filtered;
    // child tables are constrained by IDs obtained from already scoped target parents.
    const order = ["teams","positions","players","seasons","training_series","trainings","matchdays","matchday_recommendation_runs","player_positions","attendance","training_players","training_trainers","training_responses","matchday_players","matchday_attendance","matchday_trainers","matchday_recommendation_players","team_season_closure_audit","training_behavior_events","training_suspensions","training_suspension_exceptions","matchday_early_suspension_resets","matchday_nomination_reminders","team_suspension_game_type_settings","team_suspension_game_types"];
    const required = new Set(selectedTables);
    for (const t of selectedTables) for (const p of REFS[t] || []) required.add(p.parent);
    const current: Record<string, any[]> = {};
    const readErrors: { code: string }[] = [];
    for (const table of order) {
      if (!required.has(table)) continue;
      const select = PREVIEW_SELECTS[table];
      if (!select) { readErrors.push({ code: "TABLE_ALLOWLIST_MISSING" }); break; }
      let query = admin.from(table).select(select);
      if (table === "teams") query = query.eq("id", scope.scope_id);
      else if (select.split(",").includes("team_id")) query = query.eq("team_id", scope.scope_id);
      else {
        const parentRef = (REFS[table] || []).find(ref => ref.field !== "team_id");
        if (!parentRef || !Array.isArray(current[parentRef.parent])) { readErrors.push({ code: "PARENT_SCOPE_UNRESOLVED" }); break; }
        const ids = current[parentRef.parent].map(row => row.id).filter(Boolean);
        if (!ids.length) { current[table] = []; continue; }
        query = query.in(parentRef.field, ids);
      }
      const rows: any[] = [];
      for (let offset = 0; ; offset += PAGE) {
        const { data, error } = await query.range(offset, offset + PAGE - 1);
        if (error) { readErrors.push({ code: "TARGET_SELECT_FAILED" }); break; }
        rows.push(...(data || []));
        if (rows.length > RESTORE_PREVIEW_MAX_ROWS_PER_TABLE) { readErrors.push({ code: "TARGET_ROW_LIMIT" }); break; }
        if ((data || []).length < PAGE) break;
      }
      if (readErrors.length) break;
      current[table] = rows;
    }
    if (readErrors.length) return reply(req, makePreviewEnvelope({ scope, rowsByTable: {}, readErrors }), 200);

    // Check every known foreign key against the complete, authorized target parent rows.
    for (const table of required) {
      for (const row of current[table] || []) {
        for (const ref of REFS[table] || []) {
          const value = row[ref.field];
          if (value == null) continue;
          const allowedIds = new Set((current[ref.parent] || []).map(parent => String(parent.id)));
          if (!allowedIds.has(String(value))) {
            return reply(req, makePreviewEnvelope({ scope, rowsByTable: {}, readErrors: [{ code: "TARGET_FOREIGN_KEY_SCOPE_INVALID" }] }), 200);
          }
        }
      }
    }

    // Actor/profile references are not silently remapped. Report an explicit gate
    // rather than implying the preview is integration-ready until actor resolution exists.
    const actorIds = new Set<string>();
    for (const table of selectedTables) for (const row of body.snapshot_data[table] || []) {
      for (const field of ACTOR_FIELDS) if (row[field] && UUID.test(String(row[field]))) actorIds.add(String(row[field]));
    }
    let actorGate = "not_applicable";
    if (actorIds.size) {
      const { data: profiles, error } = await admin.from("profiles").select("id").in("id", [...actorIds]);
      if (error) return reply(req, makePreviewEnvelope({ scope, rowsByTable: {}, readErrors: [{ code: "ACTOR_REFERENCE_READ_FAILED" }] }), 200);
      const existing = new Set((profiles || []).map((p: any) => String(p.id)));
      const missing = [...actorIds].filter(id => !existing.has(id));
      if (missing.length) return reply(req, makePreviewEnvelope({ scope, rowsByTable: {}, readErrors: [{ code: "ACTOR_REFERENCE_MISSING" }] }), 200);
      actorGate = "existing_profiles_verified_no_remap";
    }

    const backup = body.snapshot_data;
    const plan = buildMergePreview(backup, current, selectedTables);
    const envelope = makePreviewEnvelope({ scope, rowsByTable: {} });
    return reply(req, {
      ...envelope,
      categories: body.manifest.categories,
      summary: { additions: plan.additions, updates: plan.updates, kept: plan.kept, conflicts: plan.conflicts, never_delete: plan.tables.reduce((sum: number, t: any) => sum + t.neverDelete, 0), deletes: 0 },
      tables: plan.tables,
      actor_gate: actorGate,
      assets_gate: body.manifest.completeness?.files_images_included ? "deferred_not_restored_or_verified_by_preview" : "not_selected",
      notice: "Nur Vorschau – 0 Änderungen. Kein Restore wurde ausgeführt.",
    });
  } catch (e) {
    const message = String((e as Error)?.message || "");
    if (message.startsWith("RESTORE_PREFLIGHT_")) return reply(req, { status: "blocked", complete: false, write_count: 0, error_code: message.split(":")[0] }, 400);
    if (["REQUEST_INVALID","SCOPE_MISMATCH","MANIFEST_SCOPE_MISMATCH","TEAM_SET_MISMATCH"].includes(message)) return reply(req, { status: "blocked", complete: false, write_count: 0, error_code: message }, 400);
    console.error("AP-BR02 restore preview error", e);
    return reply(req, { status: "blocked", complete: false, write_count: 0, error_code: "PREVIEW_FAILED" }, 500);
  }
});
