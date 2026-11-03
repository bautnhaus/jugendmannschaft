import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://bautnhaus.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const respond = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

// The project reference determines the application URL. The caller cannot
// supply an arbitrary redirect URL. DEV and PROD remain explicitly separated.
const APP_URL_BY_PROJECT_REF: Record<string, string> = {
  "pzazqvvoruqnqhcorbwx": "https://bautnhaus.github.io/jugendmannschaft-dev/",
  "qdugtpzgefpswnnqbusd": "https://bautnhaus.github.io/jugendmannschaft/",
};

async function findAuthUserByEmail(adminClient: any, email: string) {
  const perPage = 1000;
  const maxPages = 100;

  for (let page = 1; page <= maxPages; page++) {
    const { data, error } = await adminClient.auth.admin.listUsers({
      page,
      perPage,
    });

    if (error) {
      throw new Error("Vorhandene Benutzer konnten nicht vollständig geprüft werden: " + error.message);
    }

    const users = data?.users || [];
    const found = users.find((user: any) =>
      String(user.email || "").trim().toLowerCase() === email
    );

    if (found) return found;
    if (users.length < perPage) return null;
  }

  throw new Error("Der Benutzerbestand ist zu groß für eine sichere E-Mail-Prüfung. Es wurde keine Einladung versendet.");
}

async function preflightExistingAssignments(
  adminClient: any,
  userId: string,
  clubId: string,
  invitedRole: string,
  teamId: string | null,
) {
  const { data: clubMember, error: clubError } = await adminClient
    .from("club_members")
    .select("club_id")
    .eq("user_id", userId)
    .maybeSingle();

  if (clubError) throw new Error("Bestehende Vereinszuordnung konnte nicht geprüft werden: " + clubError.message);

  if (clubMember && clubMember.club_id !== clubId) {
    throw new Error("Dieser Benutzer ist bereits einem anderen Verein zugeordnet.");
  }

  if (!teamId || !["team_admin", "trainer"].includes(invitedRole)) return;

  const { data: teamRows, error: teamError } = await adminClient
    .from("team_members")
    .select("team_id")
    .eq("user_id", userId);

  if (teamError) throw new Error("Bestehende Mannschaftszuordnungen konnten nicht geprüft werden: " + teamError.message);

  const { data: roleRows, error: roleError } = await adminClient
    .from("team_member_roles")
    .select("team_id")
    .eq("user_id", userId);

  if (roleError) throw new Error("Bestehende Mannschaftsrollen konnten nicht geprüft werden: " + roleError.message);

  const otherTeamExists = [...(teamRows || []), ...(roleRows || [])]
    .some((row: any) => row.team_id !== teamId);

  if (otherTeamExists) {
    throw new Error("Dieser Benutzer gehört bereits einer anderen Mannschaft an. Eine zweite Mannschaftszuordnung ist derzeit nicht möglich.");
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return respond({ error: "Nur POST-Anfragen sind erlaubt." }, 405);
  }

  try {
    const url = Deno.env.get("SUPABASE_URL") || "";
    const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS") || "";
    let anonKey = Deno.env.get("SUPABASE_ANON_KEY") || "";
    const publishableKeysRaw = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") || "";

    if (!anonKey && publishableKeysRaw) {
      try {
        anonKey = JSON.parse(publishableKeysRaw).default || "";
      } catch {
        // The missing key is handled below.
      }
    }

    if (!url || !anonKey || !secretKeysRaw) {
      return respond({ error: "Die Einladungsfunktion ist nicht korrekt konfiguriert." }, 500);
    }

    let projectRef = "";
    try {
      projectRef = new URL(url).hostname.split(".")[0];
    } catch {
      return respond({ error: "Die Supabase-Projektadresse ist ungültig." }, 500);
    }

    const redirectTo = APP_URL_BY_PROJECT_REF[projectRef];
    if (!redirectTo) {
      return respond({ error: "Für diese Supabase-Umgebung ist keine freigegebene App-Weiterleitung hinterlegt." }, 500);
    }

    let secretKeys: Record<string, string>;
    try {
      secretKeys = JSON.parse(secretKeysRaw);
    } catch {
      return respond({ error: "Der Supabase Secret Key hat kein gültiges Format." }, 500);
    }

    const secretKey = secretKeys.default;
    if (!secretKey) {
      return respond({ error: "Der Supabase Secret Key fehlt." }, 500);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return respond({ error: "Nicht angemeldet." }, 401);
    }

    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const adminClient = createClient(url, secretKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: userData, error: userError } = await userClient.auth.getUser();
    const inviter = userData?.user;
    if (userError || !inviter) {
      return respond({ error: "Die Anmeldung konnte nicht bestätigt werden." }, 401);
    }

    let body: {
      email?: string;
      display_name?: string;
      invited_role?: string;
      club_id?: string;
      team_id?: string | null;
    };

    try {
      body = await req.json();
    } catch {
      return respond({ error: "Ungültige Anfrage-Daten." }, 400);
    }

    const email = String(body.email || "").trim().toLowerCase();
    const displayName = String(body.display_name || "").trim();
    const invitedRole = String(body.invited_role || "");
    const clubId = String(body.club_id || "").trim();
    const teamId = body.team_id ? String(body.team_id).trim() : null;

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return respond({ error: "Bitte eine gültige E-Mail-Adresse angeben." }, 400);
    }

    if (!displayName || displayName.length > 120) {
      return respond({ error: "Bitte einen persönlichen Namen mit maximal 120 Zeichen eingeben." }, 400);
    }

    if (!clubId) {
      return respond({ error: "Der Vereinskontext fehlt." }, 400);
    }

    if (!["member", "club_admin", "team_admin", "trainer"].includes(invitedRole)) {
      return respond({ error: "Die ausgewählte Einladungsrolle ist ungültig." }, 400);
    }

    const isTeamRole = invitedRole === "team_admin" || invitedRole === "trainer";
    if (isTeamRole !== Boolean(teamId)) {
      return respond({
        error: isTeamRole
          ? "Für einen Mannschaftsadmin oder Trainer muss eine Mannschaft ausgewählt werden."
          : "Für eine reine Vereinsrolle darf keine Mannschaft angegeben werden.",
      }, 400);
    }

    // Validate the inviter before any email is sent.
    const { data: canManageClub, error: clubPermissionError } = await userClient
      .rpc("can_manage_club_context", { p_club_id: clubId });

    if (clubPermissionError) {
      console.error("Vereinsberechtigung konnte nicht geprüft werden:", clubPermissionError);
      return respond({ error: "Die Vereinsberechtigung konnte nicht geprüft werden." }, 500);
    }

    let canManageTeam = false;
    if (teamId) {
      const { data: teamAdmin, error: teamPermissionError } = await userClient
        .rpc("is_team_admin", { p_team_id: teamId });

      if (teamPermissionError) {
        console.error("Mannschaftsberechtigung konnte nicht geprüft werden:", teamPermissionError);
        return respond({ error: "Die Mannschaftsberechtigung konnte nicht geprüft werden." }, 500);
      }
      canManageTeam = teamAdmin === true;
    }

    if (canManageClub !== true && !(isTeamRole && canManageTeam)) {
      return respond({ error: "Keine Berechtigung für diese Einladung oder kein passender Vereins-/Mannschaftskontext." }, 403);
    }

    if (teamId) {
      const { data: team, error: teamError } = await adminClient
        .from("teams")
        .select("id, club_id, active")
        .eq("id", teamId)
        .maybeSingle();

      if (teamError) {
        console.error("Mannschaft konnte nicht geprüft werden:", teamError);
        return respond({ error: "Die ausgewählte Mannschaft konnte nicht geprüft werden." }, 500);
      }

      if (!team || team.active !== true || team.club_id !== clubId) {
        return respond({ error: "Die ausgewählte Mannschaft gehört nicht zum Verein oder ist nicht aktiv." }, 400);
      }
    }

    let targetUser: any = null;
    try {
      targetUser = await findAuthUserByEmail(adminClient, email);
    } catch (lookupError) {
      return respond({ error: lookupError instanceof Error ? lookupError.message : "Benutzerprüfung fehlgeschlagen." }, 500);
    }

    if (targetUser?.id === inviter.id) {
      return respond({ error: "Du kannst dich nicht selbst einladen." }, 400);
    }

    if (targetUser) {
      const { data: globalRoles, error: globalRoleError } = await adminClient
        .from("global_user_roles")
        .select("role")
        .eq("user_id", targetUser.id);

      if (globalRoleError) {
        console.error("Globale Benutzerrollen konnten nicht geprüft werden:", globalRoleError);
        return respond({ error: "Die globalen Rollen des bestehenden Kontos konnten nicht geprüft werden." }, 500);
      }

      if ((globalRoles || []).some((row: any) => row.role === "super_admin")) {
        return respond({ error: "Ein Super Admin kann nicht als Vereins- oder Mannschaftsmitglied zugeordnet werden." }, 409);
      }


      try {
        await preflightExistingAssignments(adminClient, targetUser.id, clubId, invitedRole, teamId);
      } catch (preflightError) {
        return respond({ error: preflightError instanceof Error ? preflightError.message : "Bestehende Zuordnungen konnten nicht geprüft werden." }, 409);
      }
    }

    let invitationEmailSent = false;
    let emailWarning = "";
    const existingUser = Boolean(targetUser);
    const wasAlreadyConfirmed = Boolean(targetUser?.email_confirmed_at);

    if (!targetUser || !wasAlreadyConfirmed) {
      const { data: inviteData, error: inviteError } =
        await adminClient.auth.admin.inviteUserByEmail(email, {
          redirectTo,
          data: { display_name: displayName },
        });

      if (inviteError || !inviteData?.user) {
        // A second request can win the race after our initial user lookup.
        // Re-read once so that no duplicate account is created or assumed.
        const racedUser = await findAuthUserByEmail(adminClient, email).catch(() => null);

        if (!racedUser) {
          return respond({
            error: inviteError?.message || "Die Einladungs-E-Mail konnte nicht versendet werden.",
            invitation_email_sent: false,
          }, 502);
        }

        targetUser = racedUser;
        emailWarning = "Für dieses Konto konnte keine neue Einladungs-E-Mail bestätigt werden. Die vorhandene Konto-/Einladungssituation wurde übernommen; bitte prüfen, ob der ursprüngliche Einladungslink noch gültig ist.";
      } else {
        targetUser = inviteData.user;
        invitationEmailSent = true;
      }
    }

    if (!targetUser?.id) {
      return respond({ error: "Auth-Benutzer konnte nicht ermittelt werden.", invitation_email_sent: invitationEmailSent }, 500);
    }

    // Confirmed accounts already have a working login; do not send an invite email.
    const { data: assignment, error: assignmentError } = await userClient.rpc(
      "admin_complete_member_invitation",
      {
        p_user_id: targetUser.id,
        p_display_name: displayName,
        p_club_id: clubId,
        p_invited_role: invitedRole,
        p_team_id: teamId,
      },
    );

    if (assignmentError || assignment?.success !== true) {
      console.error("Mitgliedschaft konnte nicht vollständig gespeichert werden:", assignmentError);
      return respond({
        error: invitationEmailSent
          ? "Die Einladung wurde versendet, aber Profil und Rollen konnten nicht vollständig gespeichert werden. Bitte denselben Vorgang mit derselben E-Mail-Adresse erneut ausführen; es wird kein zweites Konto angelegt."
          : "Profil und Rollen konnten nicht vollständig gespeichert werden: " + (assignmentError?.message || "Datenbankbestätigung fehlt."),
        invitation_email_sent: invitationEmailSent,
        partial: invitationEmailSent,
      }, 500);
    }

    let message: string;
    if (invitationEmailSent) {
      message = "Die Einladung wurde versendet und die Vereins-/Mannschaftszuordnung wurde gespeichert.";
    } else if (wasAlreadyConfirmed) {
      message = "Das bestehende Benutzerkonto wurde der ausgewählten Rolle zugeordnet. Eine neue E-Mail wurde nicht versendet.";
    } else {
      message = "Die Zuordnung wurde gespeichert. Eine erneute Einladungs-E-Mail konnte nicht bestätigt werden.";
    }

    return respond({
      success: true,
      existing_user: existingUser,
      invitation_email_sent: invitationEmailSent,
      role: invitedRole,
      message,
      warning: emailWarning || undefined,
      invitation_pending: Boolean(targetUser.email_confirmed_at === null),
    });
  } catch (error) {
    console.error("invite-member:", error);
    return respond({
      error: error instanceof Error
        ? error.message
        : "Bei der Einladung ist ein unerwarteter Fehler aufgetreten.",
    }, 500);
  }
});