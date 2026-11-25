/**
 * KADAssist AP-BR02 restore preflight – pure, read-only package validation.
 * No Supabase client, no writes, no credentials. Fail closed on unknown schema.
 */
export const PACKAGE_FORMAT = "KADAssist-Backup-Package";
export const PACKAGE_VERSION = 1;
export const SNAPSHOT_VERSION = 16;

export const CATEGORY_TABLES = Object.freeze({
  team_core: ["positions", "players", "player_positions", "teams"],
  training: ["training_series", "trainings", "attendance", "training_players", "training_trainers", "training_responses"],
  matchday: ["matchdays", "matchday_players", "matchday_attendance", "matchday_trainers", "matchday_recommendation_runs", "matchday_recommendation_players"],
  season_history: ["seasons", "team_season_closure_audit"],
  discipline_history: ["training_behavior_events", "training_suspensions", "training_suspension_exceptions", "matchday_early_suspension_resets", "matchday_nomination_reminders", "team_suspension_game_type_settings", "team_suspension_game_types"],
  files_images: []
});

const TABLE_KEYS = Object.freeze({
  teams: ["id"], positions: ["id"], players: ["id"], training_series: ["id"], trainings: ["id"], matchdays: ["id"],
  matchday_recommendation_runs: ["id"], seasons: ["id"], team_season_closure_audit: ["id"],
  training_behavior_events: ["id"], training_suspensions: ["id"], training_suspension_exceptions: ["id"],
  matchday_early_suspension_resets: ["id"], matchday_nomination_reminders: ["id"],
  team_suspension_game_type_settings: ["team_id"], team_suspension_game_types: ["team_id", "game_type"],
  player_positions: ["player_id", "position_id"], attendance: ["training_id", "player_id"],
  training_players: ["training_id", "player_id"], training_trainers: ["training_id", "user_id"],
  training_responses: ["training_id", "player_id"], matchday_players: ["matchday_id", "player_id"],
  matchday_attendance: ["matchday_id", "player_id"], matchday_trainers: ["matchday_id", "user_id"],
  matchday_recommendation_players: ["recommendation_id", "player_id"]
});

// Actual DEV-schema unique constraints beyond the primary/merge key.
const TABLE_UNIQUE_KEYS = Object.freeze({
  positions: [["team_id", "name"]],
  seasons: [["team_id", "name"]],
  matchday_recommendation_runs: [["matchday_id"]],
  matchday_recommendation_players: [["recommendation_id", "rank"]],
  team_season_closure_audit: [["season_id"]]
});

// Only these tables may propose a field-level Newer-wins update in preview.
// All other tables are insert-only/keep-on-conflict for V1.
const UPDATE_FIELDS = Object.freeze({
  teams: ["name", "recommended_squad_size", "birth_cohorts", "abbreviation"],
  players: ["name", "first_name", "last_name", "birth_year", "preferred_foot", "level", "notes"],
  seasons: ["name", "start_date", "end_date", "is_active"],
  training_series: ["start_date", "end_date", "start_time", "duration_minutes", "weekdays", "location", "name"],
  trainings: ["training_date", "name", "start_time", "duration_minutes", "location", "note", "series_id", "overrides", "season_id"],
  matchdays: ["match_date", "name", "opponent", "location", "notes", "kickoff_time", "duration_minutes", "game_type", "season_id"],
  matchday_attendance: ["present"]
});

const INSERT_ONLY_TABLES = new Set([
  "positions", "player_positions", "attendance", "training_players", "training_trainers", "training_responses",
  "matchday_players", "matchday_trainers", "matchday_recommendation_runs", "matchday_recommendation_players",
  "training_behavior_events", "training_suspensions", "training_suspension_exceptions",
  "matchday_early_suspension_resets", "matchday_nomination_reminders",
  "team_suspension_game_type_settings", "team_suspension_game_types", "team_season_closure_audit"
]);

const TABLE_REFS = Object.freeze({
  player_positions: [["player_id", "players"], ["position_id", "positions"]],
  attendance: [["training_id", "trainings"], ["player_id", "players"]],
  training_players: [["training_id", "trainings"], ["player_id", "players"]],
  training_trainers: [["training_id", "trainings"]],
  training_responses: [["training_id", "trainings"], ["player_id", "players"]],
  matchday_players: [["matchday_id", "matchdays"], ["player_id", "players"]],
  matchday_attendance: [["matchday_id", "matchdays"], ["player_id", "players"]],
  matchday_trainers: [["matchday_id", "matchdays"]],
  matchday_recommendation_runs: [["matchday_id", "matchdays"]],
  matchday_recommendation_players: [["recommendation_id", "matchday_recommendation_runs"], ["player_id", "players"]],
  trainings: [["series_id", "training_series"]],
});

const fail = (code, detail) => { throw new Error("RESTORE_PREFLIGHT_" + code + (detail ? ":" + detail : "")); };
const safePath = value => typeof value === "string" && value.length > 0 &&
  !value.startsWith("/") && !value.includes("\\") && !value.split("/").some(part => !part || part === "." || part === "..");

export function validatePackageManifest(manifest) {
  if (!manifest || manifest.format !== PACKAGE_FORMAT || manifest.format_version !== PACKAGE_VERSION) fail("FORMAT_UNSUPPORTED");
  if (manifest.snapshot?.format !== "KADAssist-Teamdaten-JSON" || manifest.snapshot?.version !== SNAPSHOT_VERSION) fail("SNAPSHOT_VERSION_UNSUPPORTED");
  const scope = manifest.scope;
  if (!scope || !["team", "club", "platform"].includes(scope.type) || typeof scope.id !== "string") fail("SCOPE_INVALID");
  if (!Array.isArray(scope.team_ids) || !scope.team_ids.every(x => typeof x === "string") || !Array.isArray(scope.club_ids)) fail("SCOPE_IDS_INVALID");
  if (!Array.isArray(manifest.categories) || !manifest.categories.length) fail("CATEGORIES_MISSING");
  if (new Set(manifest.categories).size !== manifest.categories.length || manifest.categories.some(c => !Object.hasOwn(CATEGORY_TABLES, c))) fail("CATEGORY_UNKNOWN");
  const expected = new Set(manifest.categories.flatMap(c => CATEGORY_TABLES[c]));
  const data = manifest.snapshot.data;
  if (!data || typeof data !== "object" || Array.isArray(data)) fail("SNAPSHOT_DATA_INVALID");
  for (const [table, rows] of Object.entries(data)) {
    if (!expected.has(table)) fail("TABLE_NOT_ALLOWED", table);
    if (!Array.isArray(rows) || rows.some(row => !row || typeof row !== "object" || Array.isArray(row))) fail("TABLE_SHAPE_INVALID", table);
    const keys = TABLE_KEYS[table];
    if (!keys) fail("TABLE_KEY_UNDEFINED", table);
    const seen = new Set();
    for (const row of rows) {
      if (keys.some(k => row[k] === null || row[k] === undefined || String(row[k]).length === 0)) fail("ROW_KEY_MISSING", table);
      const key = keys.map(k => String(row[k])).join("\u001f");
      if (seen.has(key)) fail("ROW_KEY_DUPLICATE", table);
      seen.add(key);
    }
  }
  for (const [table, refs] of Object.entries(TABLE_REFS)) {
    const rows = data[table] || [];
    for (const row of rows) for (const [field, parent] of refs) {
      if (row[field] == null) continue;
      const parentIds = new Set((data[parent] || []).map(x => String(x.id)));
      // Parent tables not included as a selected category may have valid external references;
      // those are validated against the scoped current database during the next stage.
      if (data[parent] && !parentIds.has(String(row[field]))) fail("FOREIGN_KEY_INVALID", table + "." + field);
    }
  }
  const assets = manifest.assets;
  if (!Array.isArray(assets)) fail("ASSETS_INVALID");
  const paths = new Set();
  for (const asset of assets) {
    if (!asset || !safePath(asset.archive_path) || paths.has(asset.archive_path) || !Number.isSafeInteger(asset.bytes) || asset.bytes < 0) fail("ASSET_ENTRY_INVALID");
    paths.add(asset.archive_path);
  }
  const declaredCount = Number(manifest.completeness?.asset_count);
  const declaredBytes = Number(manifest.completeness?.asset_bytes);
  if (declaredCount !== assets.length || declaredBytes !== assets.reduce((sum, a) => sum + a.bytes, 0)) fail("ASSET_TOTALS_MISMATCH");
  return { scope, categories: [...manifest.categories], data, assets, tableNames: [...expected].filter(t => Array.isArray(data[t])) };
}

/** Reads all ZIP entries with the vendored zip.js reader and validates actual asset bytes. */
export async function inspectRestoreArchive(zipBlob, zipApi = globalThis.zip) {
  if (!zipApi?.ZipReader || !(zipBlob instanceof Blob)) fail("ZIP_READER_UNAVAILABLE");
  const reader = new zipApi.ZipReader(new zipApi.BlobReader(zipBlob));
  try {
    const entries = await reader.getEntries();
    const byName = new Map();
    for (const entry of entries) {
      if (!safePath(entry.filename) || byName.has(entry.filename)) fail("ZIP_PATH_INVALID", entry.filename);
      byName.set(entry.filename, entry);
    }
    const manifestEntry = byName.get("manifest.json");
    if (!manifestEntry) fail("MANIFEST_NOT_FOUND");
    const manifestText = await manifestEntry.getData(new zipApi.TextWriter());
    let manifest;
    try { manifest = JSON.parse(manifestText); } catch { fail("MANIFEST_JSON_INVALID"); }
    const validated = validatePackageManifest(manifest);
    let actualBytes = 0;
    for (const asset of validated.assets) {
      const entry = byName.get(asset.archive_path);
      if (!entry) fail("ASSET_MISSING", asset.archive_path);
      const blob = await entry.getData(new zipApi.BlobWriter());
      if (blob.size !== asset.bytes) fail("ASSET_SIZE_MISMATCH", asset.archive_path);
      actualBytes += blob.size;
    }
    if (actualBytes !== Number(manifest.completeness.asset_bytes)) fail("ASSET_TOTAL_BYTES_MISMATCH");
    return { manifest, ...validated, archiveEntryCount: entries.length, verifiedAssetBytes: actualBytes };
  } finally {
    await reader.close();
  }
}

function rowKey(table, row) {
  const fields = TABLE_KEYS[table];
  if (!fields) fail("PLAN_KEY_UNDEFINED", table);
  return fields.map(f => String(row[f])).join("\u001f");
}
function timestamp(row) {
  // created_at is not a change marker; never use it for Newer-wins.
  for (const key of ["updated_at", "modified_at"]) {
    const value = row?.[key], parsed = value ? Date.parse(value) : NaN;
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}
function uniqueConflict(table, incoming, currentRows) {
  for (const fields of TABLE_UNIQUE_KEYS[table] || []) {
    const candidate = fields.map(field => incoming[field]);
    if (candidate.some(value => value === null || value === undefined)) continue; // PostgreSQL UNIQUE permits multiple NULLs
    const hit = currentRows.find(row => fields.every((field, i) => row[field] === candidate[i]));
    if (hit) return { fields, currentKey: fields.map(field => String(hit[field])).join("\\u001f") };
  }
  return null;
}

/**
 * Deterministic merge preview: missing rows are additions; existing rows are never deleted.
 * On changed matching keys, only a provably newer backup row is proposed as update.
 * Equal/unknown timestamps retain current data to avoid speculative overwrites.
 */
export function buildMergePreview(backupData, currentData, tableNames = Object.keys(backupData || {})) {
  const tables = [];
  let additions = 0, updates = 0, kept = 0, conflicts = 0;
  for (const table of tableNames) {
    const incoming = Array.isArray(backupData?.[table]) ? backupData[table] : [];
    const current = Array.isArray(currentData?.[table]) ? currentData[table] : [];
    const currentByKey = new Map(current.map(row => [rowKey(table, row), row]));
    const detail = { table, backupCount: incoming.length, currentCount: current.length, add: 0, update: 0, keep: 0, conflict: 0, newerBackup: 0 };
    for (const row of incoming) {
      const old = currentByKey.get(rowKey(table, row));
      if (!old) {
        const unique = uniqueConflict(table, row, current);
        if (unique) { detail.conflict++; conflicts++; detail.conflictDetails ||= []; detail.conflictDetails.push({ reason: "UNIQUE_CONSTRAINT_COLLISION", fields: unique.fields }); }
        else { detail.add++; additions++; }
        continue;
      }
      if (JSON.stringify(old) === JSON.stringify(row)) { detail.keep++; kept++; continue; }
      const allowed = UPDATE_FIELDS[table] || [];
      const mutableDifference = allowed.some(field => JSON.stringify(old[field]) !== JSON.stringify(row[field]));
      const backupTime = timestamp(row), currentTime = timestamp(old);
      if (!INSERT_ONLY_TABLES.has(table) && mutableDifference && backupTime !== null && currentTime !== null && backupTime > currentTime) {
        detail.update++; detail.newerBackup++; updates++;
      } else {
        detail.keep++; kept++;
        // Same identity but differing content in an append-only or non-versioned table is a review conflict.
        if (INSERT_ONLY_TABLES.has(table) || !mutableDifference || backupTime === null || currentTime === null) {
          detail.conflict++; conflicts++; detail.conflictDetails ||= []; detail.conflictDetails.push({ reason: INSERT_ONLY_TABLES.has(table) ? "INSERT_ONLY_ID_COLLISION" : "NO_VALID_NEWER_MUTABLE_FIELDS" });
        }
      }
    }
    detail.neverDelete = current.length; // all current rows absent from backup remain untouched
    tables.push(detail);
  }
  return { tables, additions, updates, kept, conflicts, deletes: 0, policy: "merge-never-delete-table-aware-newer-wins-preflight" };
}
