/**
 * AP-BR02 Restore Operation Contract V1.
 * Pure decision helper for synthetic fixtures only.
 * Not an executor: no auth lookup, DB access, SQL, network, or writes.
 * Server must validate role/scope independently and derive plans from trusted data.
 */
export const OPERATION = Object.freeze({
  INSERT: "insert",
  UPDATE_NEWER: "update_newer",
  KEEP: "keep",
  CONFLICT: "conflict",
  BLOCKED: "blocked"
});

const INSERT_ONLY = new Set([
  "positions","player_positions","attendance","training_players","training_trainers","training_responses",
  "matchday_players","matchday_trainers","matchday_recommendation_runs","matchday_recommendation_players",
  "training_behavior_events","training_suspensions","training_suspension_exceptions",
  "matchday_early_suspension_resets","matchday_nomination_reminders",
  "team_suspension_game_type_settings","team_suspension_game_types","team_season_closure_audit"
]);

const KEY_FIELDS = Object.freeze({
  teams:["id"], positions:["id"], players:["id"], seasons:["id"], trainings:["id"],
  training_series:["id"], matchdays:["id"], matchday_recommendation_runs:["id"],
  team_season_closure_audit:["id"], training_behavior_events:["id"], training_suspensions:["id"],
  training_suspension_exceptions:["id"], matchday_early_suspension_resets:["id"],
  matchday_nomination_reminders:["id"], team_suspension_game_type_settings:["team_id"],
  team_suspension_game_types:["team_id","game_type"], player_positions:["player_id","position_id"],
  attendance:["training_id","player_id"], training_players:["training_id","player_id"],
  training_trainers:["training_id","user_id"], training_responses:["training_id","player_id"],
  matchday_players:["matchday_id","player_id"], matchday_attendance:["matchday_id","player_id"],
  matchday_trainers:["matchday_id","user_id"],
  matchday_recommendation_players:["recommendation_id","player_id"]
});

const UNIQUE_FIELDS = Object.freeze({
  positions:[["team_id","name"]], seasons:[["team_id","name"]],
  matchday_recommendation_runs:[["matchday_id"]],
  matchday_recommendation_players:[["recommendation_id","rank"]],
  team_season_closure_audit:[["season_id"]]
});

const MUTABLE_FIELDS = Object.freeze({
  teams:["name","recommended_squad_size","birth_cohorts","abbreviation"],
  players:["name","first_name","last_name","birth_year","preferred_foot","level","notes"],
  seasons:["name","start_date","end_date","is_active"],
  training_series:["start_date","end_date","start_time","duration_minutes","weekdays","location","name"],
  trainings:["training_date","name","start_time","duration_minutes","location","note","series_id","overrides","season_id"],
  matchdays:["match_date","name","opponent","location","notes","kickoff_time","duration_minutes","game_type","season_id"],
  matchday_attendance:["present"]
});

const PROTECTED_FIELDS = new Set([
  "id","team_id","club_id","created_at","created_by","updated_by","actor_id",
  "user_id","awarded_by","voided_by","granted_by","revoked_by","closed_by",
  "status","active","played","team_number","goalkeeper"
]);

function stableKey(table,row) {
  const fields=KEY_FIELDS[table];
  if(!fields) return null;
  if(fields.some(f=>row?.[f]===null||row?.[f]===undefined||String(row[f])==="")) return null;
  return fields.map(f=>String(row[f])).join("\u001f");
}
function validTime(row) {
  const v=row?.updated_at ?? row?.modified_at;
  if(typeof v!=="string") return null;
  const n=Date.parse(v);
  return Number.isFinite(n)?n:null;
}
function conflictUnique(table,incoming,rows) {
  for(const fields of UNIQUE_FIELDS[table]||[]) {
    if(fields.some(f=>incoming[f]===null||incoming[f]===undefined)) continue;
    if(rows.some(row=>fields.every(f=>row[f]===incoming[f]))) return fields;
  }
  return null;
}

/**
 * Computes one proposed operation. Caller must supply a fixed server-owned
 * allowlist. Never accepts a client-provided write payload.
 */
export function decideRestoreOperation({table,backupRow,targetRows=[],allowedTables=[]}) {
  if(!Array.isArray(allowedTables)||!allowedTables.includes(table)||
     !backupRow||typeof backupRow!=="object"||Array.isArray(backupRow))
    return {operation:OPERATION.BLOCKED,reason:"TABLE_OR_ROW_NOT_ALLOWED"};
  const key=stableKey(table,backupRow);
  if(!key) return {operation:OPERATION.BLOCKED,reason:"IDENTITY_KEY_INVALID"};
  if(!Array.isArray(targetRows)) return {operation:OPERATION.BLOCKED,reason:"TARGET_READ_INVALID"};
  const matching=targetRows.filter(row=>stableKey(table,row)===key);
  if(matching.length>1) return {operation:OPERATION.BLOCKED,reason:"TARGET_IDENTITY_NOT_UNIQUE"};
  const target=matching[0];
  if(!target) {
    const unique=conflictUnique(table,backupRow,targetRows);
    return unique
      ? {operation:OPERATION.CONFLICT,reason:"UNIQUE_CONSTRAINT_COLLISION",fields:unique}
      : {operation:OPERATION.INSERT,reason:"MISSING_ALLOWED_ROW"};
  }
  if(INSERT_ONLY.has(table)) {
    return JSON.stringify(target)===JSON.stringify(backupRow)
      ? {operation:OPERATION.KEEP,reason:"IDENTICAL_APPEND_ONLY_ROW"}
      : {operation:OPERATION.CONFLICT,reason:"INSERT_ONLY_IDENTITY_COLLISION"};
  }
  const fields=MUTABLE_FIELDS[table]||[];
  const changed=fields.filter(field=>JSON.stringify(target[field])!==JSON.stringify(backupRow[field]));
  if(!changed.length) return {operation:OPERATION.KEEP,reason:"NO_MUTABLE_DIFFERENCE"};
  if(changed.some(field=>PROTECTED_FIELDS.has(field)))
    return {operation:OPERATION.BLOCKED,reason:"PROTECTED_FIELD"};
  const unique=conflictUnique(table,backupRow,targetRows.filter(row=>stableKey(table,row)!==key));
  if(unique) return {operation:OPERATION.CONFLICT,reason:"UPDATE_UNIQUE_CONSTRAINT_COLLISION",fields:unique};
  const bt=validTime(backupRow),tt=validTime(target);
  if(bt===null||tt===null) return {operation:OPERATION.CONFLICT,reason:"TIMESTAMP_UNVERIFIABLE",fields:changed};
  if(bt<=tt) return {operation:OPERATION.KEEP,reason:bt===tt?"TIMESTAMP_EQUAL":"BACKUP_NOT_NEWER"};
  return {operation:OPERATION.UPDATE_NEWER,reason:"BACKUP_STRICTLY_NEWER",fields:changed};
}

/** Never-delete invariant: backup omission cannot produce a delete operation. */
export function omissionOperation() {
  return Object.freeze({operation:OPERATION.KEEP,reason:"NEVER_DELETE_BACKUP_OMISSION"});
}
