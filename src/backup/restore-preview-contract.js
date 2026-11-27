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
  positions: "id,team_id,name,sort_order,color,created_at",
  players: "id,team_id,name,first_name,last_name,birth_year,preferred_foot,level,photo_data,photo_path,notes,active,created_at,updated_at",
  player_positions: "player_id,position_id",
  teams: "id,name,club_id,active,birth_cohorts,abbreviation,recommended_squad_size,created_at,updated_at",
  seasons: "id,team_id,name,start_date,end_date,is_active,created_at,updated_at",
  training_series: "id,team_id,start_date,end_date,start_time,duration_minutes,weekdays,location,name,created_at,updated_at",
  trainings: "id,team_id,training_date,name,start_time,duration_minutes,location,status,note,series_id,overrides,season_id,created_at,updated_at",
  attendance: "training_id,player_id,present",
  training_players: "training_id,player_id,team_number,goalkeeper",
  training_trainers: "training_id,user_id,present",
  training_responses: "training_id,player_id,status,created_at",
  matchdays: "id,team_id,match_date,name,opponent,location,notes,kickoff_time,duration_minutes,game_type,status,season_id,created_at,updated_at",
  matchday_players: "matchday_id,player_id,available,team_number,goalkeeper,played",
  matchday_attendance: "matchday_id,player_id,present,updated_at",
  matchday_trainers: "matchday_id,user_id,present",
  matchday_recommendation_runs: "id,matchday_id,created_at,created_by",
  matchday_recommendation_players: "recommendation_id,player_id,rank",
  training_behavior_events: "id,team_id,season_id,training_id,training_date_snapshot,training_name_snapshot,player_id,player_name_snapshot,event_type,reason,status,awarded_by,awarded_at,voided_by,voided_at,void_reason,created_at,updated_at",
  training_suspensions: "id,team_id,season_id,player_id,player_name_snapshot,source_event_id,suspension_type,status,intended_matchday_id,intended_matchday_date_snapshot,intended_matchday_opponent_snapshot,served_matchday_id,served_matchday_date_snapshot,served_matchday_opponent_snapshot,created_by,created_at,served_at,expired_at,voided_by,voided_at,void_reason,manual_target_locked",
  training_suspension_exceptions: "id,suspension_id,team_id,team_name_snapshot,player_id,player_name_snapshot,matchday_id,matchday_date_snapshot,matchday_opponent_snapshot,reason,granted_by,granted_by_snapshot,granted_at,revoked_by,revoked_by_snapshot,revoked_at,revoke_reason",
  matchday_early_suspension_resets: "id,team_id,team_name_snapshot,season_id,season_name_snapshot,player_id,player_name_snapshot,matchday_id,matchday_date_snapshot,matchday_opponent_snapshot,status,reason,created_by,created_by_snapshot,created_at,applied_at,cancelled_by,cancelled_by_snapshot,cancelled_at,cancel_reason",
  matchday_nomination_reminders: "id,team_id,team_name_snapshot,player_id,player_name_snapshot,source_matchday_id,source_matchday_date_snapshot,source_matchday_opponent_snapshot,source_nomination_snapshot,status,reason,created_by,created_by_snapshot,created_at,fulfilled_matchday_id,fulfilled_matchday_date_snapshot,fulfilled_at,cancelled_by,cancelled_by_snapshot,cancelled_at,cancel_reason",
  team_suspension_game_type_settings: "team_id,updated_at,updated_by",
  team_suspension_game_types: "team_id,game_type,created_at",
  team_season_closure_audit: "id,team_id,season_id,closed_by,closed_at,reason,expired_suspensions_count,season_name_snapshot"
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

/** Builds a fail-closed envelope; incomplete target reads are never presented as a plan.
 * @param {{scope: unknown, rowsByTable: Record<string, unknown[]>, readErrors?: Array<{code?: string}>, source?: string}} options
 */
export function makePreviewEnvelope({ scope, rowsByTable, readErrors = [], source = "target-read" }) {export function makePreviewEnvelope({ scope, rowsByTable, readErrors = [] as { code?: string }[], source = "target-read" }) {
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


/** Resolves the complete transitive parent set needed for safe target reads.
 * @param {string[]} selectedTables
 * @param {Record<string, Array<{field: string, parent: string, parentKey?: string}>>} [parentRefs]
 * @returns {Set<string>}
 */
export function resolvePreviewReadClosure(selectedTables, parentRefs = PREVIEW_PARENT_REFS) {export function resolvePreviewReadClosure(\n  selectedTables: readonly string[],\n  parentRefs: Record<string, { field: string; parent: string; parentKey?: string }[]> = PREVIEW_PARENT_REFS as unknown as Record<string, { field: string; parent: string; parentKey?: string }[]>\n): Set<string> {
  const required = new Set(selectedTables || []);
  const pending = [...required];
  while (pending.length) {
    const table = pending.pop();
    for (const ref of parentRefs[table] || []) {
      if (!required.has(ref.parent)) {
        required.add(ref.parent);
        pending.push(ref.parent);
      }
    }
  }
  return required;
}

// Fixed FK/parent map for server preview reads; never supplied by the client.
export const PREVIEW_PARENT_REFS = Object.freeze( {
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
}) ;
