import { assertEquals, assert } from "jsr:@std/assert";
import { authorizePreviewTeam } from "./restore-preview-auth.ts";

function clientStub({ user = { id: "synthetic-user" }, authError = null, allowed = true, rpcError = null }) {
  const calls = [];
  const createClient = (_url, _key, options) => {
    calls.push({ type: "client", options });
    return {
      auth: { getUser: async () => ({ data: { user }, error: authError }) },
      rpc: async (name, args) => {
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
