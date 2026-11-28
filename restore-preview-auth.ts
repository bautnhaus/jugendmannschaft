/**
 * AP-BR02 RS04 – authenticated authorization gate for the read-only preview.
 * Uses only the caller's JWT/RLS client before any service-role client or
 * privileged target read is created. All grants/context come from DB RPCs.
 */
export async function authorizePreviewTeam({ createClient, url, anonKey, authHeader, teamId, packageScopeType = "team", packageClubId = null }: {
  createClient: (...args: any[]) => any;
  url: string;
  anonKey: string;
  authHeader: string | null;
  teamId: string;
  packageScopeType?: "team" | "club";
  packageClubId?: string | null;
}) {
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

  // First test the exact selected-team grant. is_team_admin is DB-backed and
  // applies the explicit selected-team context rule to Superadmins.
  const teamGrant = await userClient.rpc("is_team_admin", { p_team_id: teamId });
  if (teamGrant.error) {
    return { ok: false, status: 500, code: "PERMISSION_CHECK_FAILED" };
  }
  if (teamGrant.data === true) {
    return { ok: true, userClient, userId: authData.user.id, grant: "team" };
  }

  // Club-admin fallback is permitted only for a single-team subset of a
  // validated club package. The RPC checks membership AND explicit selected
  // club context. Verify the selected team belongs to that club using the
  // caller's RLS client, still before service-role creation/target reads.
  if (packageScopeType === "club" && packageClubId) {
    const clubGrant = await userClient.rpc("can_manage_club_context", { p_club_id: packageClubId });
    if (clubGrant.error) {
      return { ok: false, status: 500, code: "PERMISSION_CHECK_FAILED" };
    }
    if (clubGrant.data === true) {
      const { data: team, error: teamError } = await userClient
        .from("teams").select("id,club_id").eq("id", teamId).maybeSingle();
      if (teamError) {
        return { ok: false, status: 500, code: "CLUB_TEAM_CHECK_FAILED" };
      }
      if (!team || String(team.club_id || "") !== String(packageClubId)) {
        return { ok: false, status: 403, code: "TEAM_OUTSIDE_SELECTED_CLUB" };
      }
      return { ok: true, userClient, userId: authData.user.id, grant: "club" };
    }
  }
  return { ok: false, status: 403, code: "TEAM_ACCESS_DENIED" };
}
