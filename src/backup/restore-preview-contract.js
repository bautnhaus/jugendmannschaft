/**
 * AP-BR02 read-only target-preview contract.
 * Pure contract helpers only: no Supabase client, credentials, network or writes.
 * Server endpoint must perform auth/scope validation BEFORE calling target SELECTs.
 */
export const RESTORE_PREVIEW_VERSION = 1;
export const RESTORE_PREVIEW_MAX_ROWS_PER_TABLE = 5000;

// Fixed server-side SELECT allowlist derived from the current KADB v1 / snapshot v16 export contract.
// Do not accept table names or select expressions from the client.
export const PREVIEW_SELECTS = Object.freeze({
  teams: "id,name,club_id,active,created_at,updated_at",
  positions: "id,team_id,name,sort_order,created_at,updated_at",
  players: "id,team_id,name,birth_year,preferred_foot,photo_path,photo_data,active,created_at,updated_at",
  player_positions: "player_id,position_id",
  training_series: "id,team_id,name,created_at,updated_at",
  trainings: "id,team_id,series_id,date,time,location,notes,created_at,updated_at",
  attendance: "training_id,player_id,status,created_at,updated_at",
  training_players: "training_id,player_id",
  training_trainers: "training_id,user_id",
  training_responses: "training_id,player_id,response,updated_at",
  matchdays: "id,team_id,season_id,date,time,opponent,game_type,status,created_at,updated_at",
  matchday_players: "matchday_id,player_id,status,created_at,updated_at",
  matchday_attendance: "matchday_id,player_id,status,updated_at",
  matchday_trainers: "matchday_id,user_id",
  matchday_recommendation_runs: "id,matchday_id,created_by,created_at",
  matchday_recommendation_players: "recommendation_id,player_id,rank,created_at",
  seasons: "id,team_id,name,start_date,end_date,created_at,updated_at",
  team_season_closure_audit: "id,team_id,season_id,closed_by,closed_at,reason,expired_suspensions_count,season_name_snapshot",
  training_behavior_events: "id,team_id,training_id,player_id,event_type,created_at,awarded_by,voided_by,voided_at",
  training_suspensions: "id,team_id,player_id,source_event_id,created_at,updated_at",
  training_suspension_exceptions: "id,suspension_id,matchday_id,created_at,revoked_at",
  matchday_early_suspension_resets: "id,team_id,matchday_id,player_id,status,created_at,updated_at",
  matchday_nomination_reminders: "id,team_id,player_id,status,created_at,updated_at",
  team_suspension_game_type_settings: "team_id,updated_at,updated_by",
  team_suspension_game_types: "team_id,game_type,created_at"
});

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/** Validates the exact same-scope restore preview request. Does not authorize it. */
export function validateRestorePreviewRequest(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) throw new Error("REQUEST_INVALID");
  const { scope_type, scope_id, selected_team_id, manifest_scope } = body;
  if (scope_type !== "team" || !UUID.test(String(scope_id || "")) ||
      !UUID.test(String(selected_team_id || "")) || scope_id !== selected_team_id) {
    throw new Error("SCOPE_MISMATCH");
  }
  if (!manifest_scope || manifest_scope.type !== scope_type || manifest_scope.id !== scope_id) {
    throw new Error("MANIFEST_SCOPE_MISMATCH");
  }
  if (manifest_scope.team_ids !== undefined &&
      (!Array.isArray(manifest_scope.team_ids) || manifest_scope.team_ids.length !== 1 ||
       manifest_scope.team_ids[0] !== selected_team_id)) {
    throw new Error("TEAM_SET_MISMATCH");
  }
  return Object.freeze({ scope_type, scope_id, selected_team_id });
}

/** Builds a fail-closed envelope; incomplete target reads are never presented as a plan. */
export function makePreviewEnvelope({ scope, rowsByTable, readErrors = [], source = "target-read" }) {
  if (readErrors.length) {
    return {
      version: RESTORE_PREVIEW_VERSION,
      status: "blocked",
      complete: false,
      write_count: 0,
      message_code: "TARGET_READ_INCOMPLETE",
      errors: readErrors.map(e => String(e?.code || "TARGET_READ_FAILED")),
      scope,
      source
    };
  }
  return {
    version: RESTORE_PREVIEW_VERSION,
    status: "read_only_ready",
    complete: true,
    write_count: 0,
    message_code: "PREVIEW_ONLY_NO_CHANGES",
    scope,
    source,
    rows_by_table: rowsByTable
  };
}
