// AP-BR02 server-authorized backup snapshot (DEV source; deployment is a separate step).
import { createClient } from "npm:@supabase/supabase-js@2";

const corsOrigins = new Set(["https://dev.kadassist.de"]);
function headers(req: Request) {
  const origin = req.headers.get("Origin") || "";
  return {
    ...(corsOrigins.has(origin) ? { "Access-Control-Allow-Origin": origin } : {}),
    "Vary": "Origin",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Content-Type": "application/json",
    "Cache-Control": "no-store",
  };
}
function reply(req: Request, body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: headers(req) });
}
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const CATEGORIES = new Set(["team_core", "training", "matchday", "season_history", "discipline_history"]);
const TEAM_TABLES: Record<string, { table: string; select: string; key?: string }> = {
  positions: { table: "positions", select: "id,team_id,name,sort_order,color,created_at" },
  players: { table: "players", select: "id,team_id,name,first_name,last_name,birth_year,preferred_foot,level,photo_data,photo_path,notes,active,created_at,updated_at" },
  player_positions: { table: "player_positions", select: "player_id,position_id", key: "player_id" },
  teams: { table: "teams", select: "id,name,club_id,active,birth_cohorts,abbreviation,recommended_squad_size,created_at,updated_at" },
  seasons: { table: "seasons", select: "id,team_id,name,start_date,end_date,is_active,created_at,updated_at" },
  training_series: { table: "training_series", select: "id,team_id,start_date,end_date,start_time,duration_minutes,weekdays,location,name,created_at,updated_at" },
  trainings: { table: "trainings", select: "id,team_id,training_date,name,start_time,duration_minutes,location,status,note,series_id,overrides,season_id,created_at,updated_at" },
  attendance: { table: "attendance", select: "training_id,player_id,present", key: "training_id" },
  training_players: { table: "training_players", select: "training_id,player_id,team_number,goalkeeper", key: "training_id" },
  training_trainers: { table: "training_trainers", select: "training_id,user_id,present", key: "training_id" },
  training_responses: { table: "training_responses", select: "training_id,player_id,status,created_at", key: "training_id" },
  matchdays: { table: "matchdays", select: "id,team_id,match_date,name,opponent,location,notes,kickoff_time,duration_minutes,game_type,status,season_id,created_at,updated_at" },
  matchday_players: { table: "matchday_players", select: "matchday_id,player_id,available,team_number,goalkeeper,played", key: "matchday_id" },
  matchday_attendance: { table: "matchday_attendance", select: "matchday_id,player_id,present,updated_at", key: "matchday_id" },
  matchday_trainers: { table: "matchday_trainers", select: "matchday_id,user_id,present", key: "matchday_id" },
  matchday_recommendation_runs: { table: "matchday_recommendation_runs", select: "id,matchday_id,created_at,created_by", key: "matchday_id" },
  matchday_recommendation_players: { table: "matchday_recommendation_players", select: "recommendation_id,player_id,rank", key: "recommendation_id" },
  training_behavior_events: { table: "training_behavior_events", select: "id,team_id,season_id,training_id,training_date_snapshot,training_name_snapshot,player_id,player_name_snapshot,event_type,reason,status,awarded_by,awarded_at,voided_by,voided_at,void_reason,created_at,updated_at" },
  training_suspensions: { table: "training_suspensions", select: "id,team_id,season_id,player_id,player_name_snapshot,source_event_id,suspension_type,status,intended_matchday_id,intended_matchday_date_snapshot,intended_matchday_opponent_snapshot,served_matchday_id,served_matchday_date_snapshot,served_matchday_opponent_snapshot,created_by,created_at,served_at,expired_at,voided_by,voided_at,void_reason,manual_target_locked" },
  training_suspension_exceptions: { table: "training_suspension_exceptions", select: "id,suspension_id,team_id,team_name_snapshot,player_id,player_name_snapshot,matchday_id,matchday_date_snapshot,matchday_opponent_snapshot,reason,granted_by,granted_by_snapshot,granted_at,revoked_by,revoked_by_snapshot,revoked_at,revoke_reason" },
  matchday_early_suspension_resets: { table: "matchday_early_suspension_resets", select: "id,team_id,team_name_snapshot,season_id,season_name_snapshot,player_id,player_name_snapshot,matchday_id,matchday_date_snapshot,matchday_opponent_snapshot,status,reason,created_by,created_by_snapshot,created_at,applied_at,cancelled_by,cancelled_by_snapshot,cancelled_at,cancel_reason" },
  matchday_nomination_reminders: { table: "matchday_nomination_reminders", select: "id,team_id,team_name_snapshot,player_id,player_name_snapshot,source_matchday_id,source_matchday_date_snapshot,source_matchday_opponent_snapshot,source_nomination_snapshot,status,reason,created_by,created_by_snapshot,created_at,fulfilled_matchday_id,fulfilled_matchday_date_snapshot,fulfilled_at,cancelled_by,cancelled_by_snapshot,cancelled_at,cancel_reason" },
  team_suspension_game_type_settings: { table: "team_suspension_game_type_settings", select: "team_id,updated_at,updated_by" },
  team_suspension_game_types: { table: "team_suspension_game_types", select: "team_id,game_type,created_at" },
  team_season_closure_audit: { table: "team_season_closure_audit", select: "id,team_id,season_id,closed_by,closed_at,reason,expired_suspensions_count,season_name_snapshot" },
};
const CATEGORY_TABLES: Record<string, string[]> = {
  team_core: ["positions", "players", "player_positions", "teams"],
  training: ["training_series", "trainings", "attendance", "training_players", "training_trainers", "training_responses"],
  matchday: ["matchdays", "matchday_players", "matchday_attendance", "matchday_trainers", "matchday_recommendation_runs", "matchday_recommendation_players"],
  season_history: ["seasons", "team_season_closure_audit"],
  discipline_history: ["training_behavior_events", "training_suspensions", "training_suspension_exceptions", "matchday_early_suspension_resets", "matchday_nomination_reminders", "team_suspension_game_type_settings", "team_suspension_game_types"],
};
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { status: 200, headers: headers(req) });
  if (req.method !== "POST") return reply(req, { error: "Nur POST ist zulässig." }, 405);
  try {
    const url = Deno.env.get("SUPABASE_URL") || "";
    let anon = Deno.env.get("SUPABASE_ANON_KEY") || "";
    const publishableRaw = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") || "";
    if (!anon && publishableRaw) {
      try { anon = JSON.parse(publishableRaw).default || ""; } catch { /* validated below */ }
    }
    // Supabase-js v2 expects a JWT in Authorization; a newer sb_secret key is not a JWT.
    // Use the legacy service-role JWT until admin access is migrated to @supabase/server.
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    if (!url || !anon || !serviceRoleKey) return reply(req, { error: "Backup-Backend ist nicht konfiguriert (Service-Role-Key fehlt)." }, 500);
    const auth = req.headers.get("Authorization");
    if (!auth?.startsWith("Bearer ")) return reply(req, { error: "Anmeldung erforderlich." }, 401);
    const user = createClient(url, anon, { global: { headers: { Authorization: auth } }, auth: { persistSession: false, autoRefreshToken: false } });
    const { data: authData, error: authError } = await user.auth.getUser();
    if (authError || !authData.user) return reply(req, { error: "Benutzer konnte nicht authentifiziert werden." }, 401);
    let body: any;
    try { body = await req.json(); } catch { return reply(req, { error: "Ungültiger JSON-Request." }, 400); }
    if (!body || !["team", "club"].includes(body.scope_type) || !UUID.test(String(body.scope_id || "")) || !Array.isArray(body.categories) || !body.categories.length || body.categories.some((c: unknown) => typeof c !== "string" || !CATEGORIES.has(c)) || new Set(body.categories).size !== body.categories.length) {
      return reply(req, { error: "Scope oder Kategorien ungültig. Bitte ausschließlich erlaubte Kategorien ausdrücklich auswählen." }, 400);
    }
    const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const scopeId = String(body.scope_id);
    const authorizedTeamIds: string[] = [];
    let clubId: string | null = null;
    if (body.scope_type === "team") {
      const { data: allowed, error } = await user.rpc("is_team_admin", { p_team_id: scopeId });
      if (error) return reply(req, { error: "Mannschaftsberechtigung konnte nicht geprüft werden." }, 500);
      if (allowed !== true) return reply(req, { error: "Kein Zugriff auf diesen Mannschaftskontext." }, 403);
      authorizedTeamIds.push(scopeId);
      const { data: team, error: teamError } = await admin.from("teams").select("id,club_id").eq("id", scopeId).maybeSingle();
      if (teamError || !team) return reply(req, { error: "Mannschaftskontext nicht gefunden." }, 404);
      clubId = team.club_id;
    } else {
      const { data: allowed, error } = await user.rpc("can_manage_club_context", { p_club_id: scopeId });
      if (error) return reply(req, { error: "Vereinsberechtigung konnte nicht geprüft werden." }, 500);
      if (allowed !== true) return reply(req, { error: "Kein Zugriff auf diesen Vereinskontext." }, 403);
      clubId = scopeId;
      const { data: teams, error: teamError } = await admin.from("teams").select("id").eq("club_id", scopeId);
      if (teamError) return reply(req, { error: "Mannschaften des Vereins konnten nicht ermittelt werden." }, 500);
      authorizedTeamIds.push(...(teams || []).map((t: any) => String(t.id)));
    }
    const snapshot: Record<string, unknown[]> = {};
    for (const category of body.categories as string[]) {
      for (const name of CATEGORY_TABLES[category]) {
        const spec = TEAM_TABLES[name];
        let query = admin.from(spec.table).select(spec.select);
        if (name === "teams") query = query.in("id", authorizedTeamIds);
        else if (spec.select.includes("team_id")) query = query.in("team_id", authorizedTeamIds);
        else {
          // Child relations are resolved from already authorized parent IDs, never queried unscoped.
          const parent = name === "matchday_recommendation_players" ? "matchday_recommendation_runs" : (name.startsWith("training_") || name === "attendance" ? "trainings" : "matchdays");
          const parentIds = (snapshot[parent] || []).map((row: any) => row.id).filter(Boolean);
          if (name === "player_positions") {
            const playerIds = (snapshot.players || []).map((row: any) => row.id).filter(Boolean);
            if (!playerIds.length) { snapshot[name] = []; continue; }
            query = query.in("player_id", playerIds);
          } else if (spec.key && parentIds.length) query = query.in(spec.key, parentIds);
          else if (spec.key && !parentIds.length) { snapshot[name] = []; continue; }
          else if (!spec.select.includes("team_id")) {
            // A table lacking a team_id must be parent-filtered; no unbounded select is allowed.
            snapshot[name] = [];
            continue;
          }
        }
        // Page every scoped query so the API default row cap cannot silently truncate data.
        const rows: any[] = [];
        const pageSize = 500;
        for (let offset = 0; ; offset += pageSize) {
          const { data, error } = await query.range(offset, offset + pageSize - 1);
          if (error) return reply(req, { error: "Exportabfrage fehlgeschlagen: " + spec.table }, 500);
          const page = data || [];
          rows.push(...page);
          if (page.length < pageSize) break;
        }
        snapshot[name] = rows;
      }
    }
    return reply(req, {
      format: "KADAssist-Teamdaten-JSON",
      version: 16,
      generated_at: new Date().toISOString(),
      scope: { type: body.scope_type, id: scopeId, club_id: clubId, team_ids: authorizedTeamIds },
      authorization: { user_id: authData.user.id, verified_server_side: true },
      categories: body.categories,
      data: snapshot,
      status: "server_snapshot_prototype_storage_and_encrypted_archive_not_included",
    });
  } catch (e) {
    console.error("AP-BR02 backup error", e);
    return reply(req, { error: "Backup-Snapshot konnte nicht erstellt werden." }, 500);
  }
});
