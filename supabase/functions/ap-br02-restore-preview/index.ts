// AP-BR02 target-state preview endpoint. SELECT-only; no Storage and no writes.
import { createClient } from "npm:@supabase/supabase-js@2";
import { CATEGORY_TABLES, validatePackageManifest, buildMergePreview } from "../../../src/backup/restore-planner.js";
import { PREVIEW_SELECTS, PREVIEW_PARENT_REFS, validateRestorePreviewRequest, makePreviewEnvelope, resolvePreviewReadClosure, RESTORE_PREVIEW_MAX_ROWS_PER_TABLE } from "../../../src/backup/restore-preview-contract.js";

const ORIGINS = new Set(["https://dev.kadassist.de"]);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const PAGE = 250;
const MAX_BODY = 32 * 1024 * 1024;
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

const REFS: Record<string, { field: string; parent: string; parentKey?: string }[]> = PREVIEW_PARENT_REFS;

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
    if (!body?.manifest) return reply(req, { error: "Manifest fehlt." }, 400);
    validatePackageManifest(body.manifest);
    const snapshotData = body.manifest.snapshot.data;
    if (!snapshotData || typeof snapshotData !== "object" || Array.isArray(snapshotData)) return reply(req, { error: "Snapshot fehlt oder ist ungültig." }, 400);
    const scope = validateRestorePreviewRequest({
      scope_type: body.manifest.scope?.type,
      scope_id: body.manifest.scope?.id,
      selected_team_id: body.selected_team_id,
      manifest_scope: { type: body.manifest.scope?.type, id: body.manifest.scope?.id, team_ids: body.manifest.scope?.team_ids },
    });
    if (scope.scope_type !== "team") return reply(req, { error: "Restore-Preview V1 erlaubt ausschließlich denselben Team-Scope." }, 400);

    if (!Array.isArray(body.manifest.categories) || !body.manifest.categories.every((category: unknown) => typeof category === "string")) return reply(req, { error: "Kategorien sind ungültig." }, 400);\n    const categoryTables: Record<string, string[]> = CATEGORY_TABLES;\n    const selectedTables: string[] = [...new Set((body.manifest.categories as string[]).flatMap((category: string) => Object.hasOwn(categoryTables, category) ? categoryTables[category] : []))];
    for (const table of selectedTables) {
      if (!Object.hasOwn(PREVIEW_SELECTS, table)) return reply(req, { error: "Tabelle ist nicht für die Preview freigegeben." }, 400);
      const rows = snapshotData[table];
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
    const required = resolvePreviewReadClosure(selectedTables, REFS);
    const current: Record<string, any[]> = {};
    const readErrors: { code: string }[] = [];
    for (const table of order) {
      if (!required.has(table)) continue;
      const select = (PREVIEW_SELECTS as Record<string, string>)[table];
      if (!select) { readErrors.push({ code: "TABLE_ALLOWLIST_MISSING" }); break; }
      let query = admin.from(table).select(select);
      if (table === "teams") query = query.eq("id", scope.scope_id);
      else if (select.split(",").includes("team_id")) query = query.eq("team_id", scope.scope_id);
      else {
        const parentRef = (REFS[table] || []).find(ref => ref.field !== "team_id");
        if (!parentRef || !Array.isArray(current[parentRef.parent])) { readErrors.push({ code: "PARENT_SCOPE_UNRESOLVED" }); break; }
        const ids = current[parentRef.parent].map(row => row[parentRef.parentKey || "id"]).filter(Boolean);
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
          const allowedIds = new Set((current[ref.parent] || []).map(parent => String(parent[ref.parentKey || "id"])));
          if (!allowedIds.has(String(value))) {
            return reply(req, makePreviewEnvelope({ scope, rowsByTable: {}, readErrors: [{ code: "TARGET_FOREIGN_KEY_SCOPE_INVALID" }] }), 200);
          }
        }
      }
    }

    // Avoid querying profiles for arbitrary IDs supplied by the untrusted backup:
    // this could expose a profile-existence oracle. Actor FK resolution is a
    // separate validation gate; the preview never silently remaps actors.
    const actorIds = new Set<string>();
    for (const table of selectedTables) for (const row of snapshotData[table] || []) {
      for (const field of ACTOR_FIELDS) if (row[field] && UUID.test(String(row[field]))) actorIds.add(String(row[field]));
    }
    const actorGate = actorIds.size ? "manual_review_required_no_user_lookup" : "not_applicable";

    const backup = snapshotData;
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
