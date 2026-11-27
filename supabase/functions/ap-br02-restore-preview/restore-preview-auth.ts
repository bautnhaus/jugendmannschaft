/**
 * AP-BR02 authorization gate, isolated for synthetic unit tests.
 * It never creates a service-role client and never performs target-table reads.
 */
export async function authorizePreviewTeam({ createClient, url, anonKey, authHeader, teamId }) {
  if (!authHeader?.startsWith("Bearer ")) {
    return { ok: false, status: 401, code: "AUTH_REQUIRED" };
  }
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData?.user) {
    return { ok: false, status: 401, code: "AUTH_INVALID" };
  }
  const { data: allowed, error: permissionError } = await userClient.rpc(
    "is_team_admin",
    { p_team_id: teamId },
  );
  if (permissionError) {
    return { ok: false, status: 500, code: "PERMISSION_CHECK_FAILED" };
  }
  if (allowed !== true) {
    return { ok: false, status: 403, code: "TEAM_ACCESS_DENIED" };
  }
  return { ok: true, userClient, userId: authData.user.id };
}
