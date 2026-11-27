import { assertEquals, assert } from "jsr:@std/assert";
import { authorizePreviewTeam } from "./restore-preview-auth.ts";
import { validateBackupTeamClosure } from "../../../src/backup/restore-preview-contract.js";

function clientStub({ user = { id: "synthetic-user" }, authError = null, allowed = true, rpcError = null }: { user?: { id: string } | null; authError?: unknown; allowed?: boolean; rpcError?: unknown }) {
  const calls: Array<Record<string, unknown>> = [];
  const createClient = (_url: string, _key: string, options: unknown) => {
    calls.push({ type: "client", options });
    return {
      auth: { getUser: async () => ({ data: { user }, error: authError }) },
      rpc: async (name: string, args: Record<string, unknown>) => {
        calls.push({ type: "rpc", name, args });
        return { data: allowed, error: rpcError };
      },
    };
  };
  return { createClient, calls };
}

Deno.test("missing bearer blocks before client creation", async () => {
  const stub = clientStub({});
  const result = await authorizePreviewTeam({ ...stub, url: "synthetic", anonKey: "synthetic", authHeader: null, teamId: "team-fixture" });
  assertEquals(result, { ok: false, status: 401, code: "AUTH_REQUIRED" });
  assertEquals(stub.calls.length, 0);
});

Deno.test("invalid user blocks before permission RPC", async () => {
  const stub = clientStub({ user: null, authError: { message: "synthetic" } });
  const result = await authorizePreviewTeam({ ...stub, url: "synthetic", anonKey: "synthetic", authHeader: "Bearer fixture", teamId: "team-fixture" });
  assertEquals(result.ok, false);
  assertEquals(result.status, 401);
  assertEquals(stub.calls.filter(x => x.type === "rpc").length, 0);
});

Deno.test("permission RPC error fails closed", async () => {
  const stub = clientStub({ rpcError: { message: "synthetic" } });
  const result = await authorizePreviewTeam({ ...stub, url: "synthetic", anonKey: "synthetic", authHeader: "Bearer fixture", teamId: "team-fixture" });
  assertEquals(result, { ok: false, status: 500, code: "PERMISSION_CHECK_FAILED" });
});

Deno.test("non-admin denied", async () => {
  const stub = clientStub({ allowed: false });
  const result = await authorizePreviewTeam({ ...stub, url: "synthetic", anonKey: "synthetic", authHeader: "Bearer fixture", teamId: "team-fixture" });
  assertEquals(result, { ok: false, status: 403, code: "TEAM_ACCESS_DENIED" });
});

Deno.test("team admin passes only after exact team permission RPC", async () => {
  const stub = clientStub({ allowed: true });
  const result = await authorizePreviewTeam({ ...stub, url: "synthetic", anonKey: "synthetic", authHeader: "Bearer fixture", teamId: "team-fixture" });
  assert(result.ok);
  assertEquals(result.userId, "synthetic-user");
  assertEquals(stub.calls.at(-1), { type: "rpc", name: "is_team_admin", args: { p_team_id: "team-fixture" } });
});

const TEAM = "team-fixture";
Deno.test("backup direct team_id must equal authorized team", () => {
  const result = validateBackupTeamClosure({
    backupData: { players: [{ id: "p1", team_id: "other-team" }] },
    selectedTables: ["players"], teamId: TEAM, targetRows: { teams: [{ id: TEAM }] },
  });
  assertEquals(result.ok, false);
  assertEquals(result.code, "BACKUP_TEAM_OR_FOREIGN_KEY_SCOPE_INVALID");
});

Deno.test("backup FK resolves through same-team selected parent", () => {
  const result = validateBackupTeamClosure({
    backupData: {
      players: [{ id: "p1", team_id: TEAM }],
      positions: [{ id: "pos1", team_id: TEAM }],
      player_positions: [{ player_id: "p1", position_id: "pos1" }],
    },
    selectedTables: ["players", "positions", "player_positions"],
    teamId: TEAM, targetRows: { teams: [{ id: TEAM }] },
  });
  assertEquals(result.ok, true);
});

Deno.test("backup FK without backup or scoped target parent fails closed", () => {
  const result = validateBackupTeamClosure({
    backupData: { attendance: [{ training_id: "unknown-training", player_id: "unknown-player", present: true }] },
    selectedTables: ["attendance"], teamId: TEAM, targetRows: { trainings: [], players: [] },
  });
  assertEquals(result.ok, false);
});

Deno.test("child FK can resolve only against scope-filtered target parents", () => {
  const result = validateBackupTeamClosure({
    backupData: { attendance: [{ training_id: "tr1", player_id: "p1", present: true }] },
    selectedTables: ["attendance"], teamId: TEAM,
    targetRows: { trainings: [{ id: "tr1", team_id: TEAM }], players: [{ id: "p1", team_id: TEAM }] },
  });
  assertEquals(result.ok, true);
});
