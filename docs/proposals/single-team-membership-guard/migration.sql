-- VORSCHLAG FÜR SUPABASE DEV – NICHT AUSGEFÜHRT
-- Zweck: die fachliche Ein-Mannschaft-Regel zentral in der Datenbank absichern.
-- Vor Ausführung: Zielprojekt DEV und aktuelle Live-Definitionen erneut prüfen.
-- Es werden keine bestehenden Mitgliedschaftsdaten verändert oder bereinigt.

-- 1) Fail-fast, falls bereits widersprüchliche Daten existieren.
DO $preflight$
DECLARE
    v_multi_team_users bigint;
BEGIN
    SELECT count(*)
    INTO v_multi_team_users
    FROM (
        SELECT assignments.user_id
        FROM (
            SELECT tm.user_id, tm.team_id
            FROM public.team_members AS tm
            UNION
            SELECT tmr.user_id, tmr.team_id
            FROM public.team_member_roles AS tmr
        ) AS assignments
        GROUP BY assignments.user_id
        HAVING count(DISTINCT assignments.team_id) > 1
    ) AS conflicts;

    IF v_multi_team_users > 0 THEN
        RAISE EXCEPTION
            'Migration abgebrochen: % Benutzer besitzen bereits mehrere Mannschaftszuordnungen. Daten müssen zuerst separat geprüft werden.',
            v_multi_team_users
            USING ERRCODE = '23514';
    END IF;


END;
$preflight$;

-- 2) Index für die benutzerbezogene Prüfung in team_member_roles.
CREATE INDEX IF NOT EXISTS idx_team_member_roles_user
    ON public.team_member_roles (user_id);

-- 3) Zentraler Schutz für beide Tabellen, in denen Mannschaftszuordnungen
--    abgebildet werden. Die Sperre der Auth-Benutzerzeile serialisiert
--    konkurrierende Zuordnungen desselben Benutzers.
CREATE OR REPLACE FUNCTION public.enforce_single_team_membership()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
BEGIN
    IF NEW.user_id IS NULL OR NEW.team_id IS NULL THEN
        RAISE EXCEPTION 'Benutzer und Mannschaft müssen angegeben werden'
            USING ERRCODE = '22023';
    END IF;

    PERFORM 1
    FROM auth.users AS u
    WHERE u.id = NEW.user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Auth-Benutzer nicht gefunden'
            USING ERRCODE = '23503';
    END IF;



    IF EXISTS (
        SELECT 1
        FROM public.team_members AS tm
        WHERE tm.user_id = NEW.user_id
          AND tm.team_id <> NEW.team_id
    )
    OR EXISTS (
        SELECT 1
        FROM public.team_member_roles AS tmr
        WHERE tmr.user_id = NEW.user_id
          AND tmr.team_id <> NEW.team_id
    ) THEN
        RAISE EXCEPTION
            'Benutzer gehört bereits einer anderen Mannschaft an. Eine zweite Mannschaftszuordnung ist nicht möglich.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$function$;

-- Die Funktion ist ausschließlich Trigger-intern. Sie wird nicht als RPC
-- für anon/authenticated freigegeben.
REVOKE ALL ON FUNCTION public.enforce_single_team_membership()
    FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS team_members_single_team_guard
    ON public.team_members;

CREATE TRIGGER team_members_single_team_guard
BEFORE INSERT OR UPDATE OF user_id, team_id
ON public.team_members
FOR EACH ROW
EXECUTE FUNCTION public.enforce_single_team_membership();

DROP TRIGGER IF EXISTS team_member_roles_single_team_guard
    ON public.team_member_roles;

CREATE TRIGGER team_member_roles_single_team_guard
BEFORE INSERT OR UPDATE OF user_id, team_id
ON public.team_member_roles
FOR EACH ROW
EXECUTE FUNCTION public.enforce_single_team_membership();

-- 4) Rollen-RPC zusätzlich mit verständlicher Vorabprüfung absichern.
--    Die Trigger oben bleiben die zentrale Rückfallebene für alle Schreibwege.
CREATE OR REPLACE FUNCTION public.admin_add_team_role(
    p_team_id uuid,
    p_user_id uuid,
    p_role text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
    v_club_id uuid;
    v_existing_club_id uuid;
BEGIN
    SELECT t.club_id
    INTO v_club_id
    FROM public.teams AS t
    WHERE t.id = p_team_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Mannschaft nicht gefunden'
            USING ERRCODE = '22023';
    END IF;

    IF auth.uid() IS NULL
       OR NOT (
           public.is_team_admin(auth.uid(), p_team_id)
           OR (v_club_id IS NOT NULL
               AND public.can_manage_club_context(v_club_id))
           OR (public.is_super_admin()
               AND public.has_selected_team_context(p_team_id))
       ) THEN
        RAISE EXCEPTION
            'Nicht berechtigt oder kein passender Vereins-/Mannschaftskontext'
            USING ERRCODE = '42501';
    END IF;

    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'Benutzer muss angegeben werden'
            USING ERRCODE = '22023';
    END IF;

    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Eigene Mannschaftsrollen können nicht geändert werden'
            USING ERRCODE = '42501';
    END IF;

    IF p_role IS NULL OR p_role NOT IN ('admin', 'trainer') THEN
        RAISE EXCEPTION 'Ungültige Teamrolle'
            USING ERRCODE = '22023';
    END IF;

    PERFORM 1
    FROM auth.users AS u
    WHERE u.id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Benutzer nicht gefunden'
            USING ERRCODE = '22023';
    END IF;



    IF EXISTS (
        SELECT 1
        FROM public.team_members AS tm
        WHERE tm.user_id = p_user_id
          AND tm.team_id <> p_team_id
    )
    OR EXISTS (
        SELECT 1
        FROM public.team_member_roles AS tmr
        WHERE tmr.user_id = p_user_id
          AND tmr.team_id <> p_team_id
    ) THEN
        RAISE EXCEPTION
            'Benutzer gehört bereits einer anderen Mannschaft an. Eine zweite Mannschaftszuordnung ist nicht möglich.'
            USING ERRCODE = '23514';
    END IF;

    IF v_club_id IS NOT NULL THEN
        SELECT cm.club_id
        INTO v_existing_club_id
        FROM public.club_members AS cm
        WHERE cm.user_id = p_user_id;

        IF v_existing_club_id IS NOT NULL
           AND v_existing_club_id <> v_club_id THEN
            RAISE EXCEPTION
                'Benutzer ist bereits einem anderen Verein zugeordnet'
                USING ERRCODE = '23514';
        END IF;

        INSERT INTO public.club_members (user_id, club_id)
        VALUES (p_user_id, v_club_id)
        ON CONFLICT (user_id) DO NOTHING;

        IF NOT EXISTS (
            SELECT 1
            FROM public.club_members AS cm
            WHERE cm.user_id = p_user_id
              AND cm.club_id = v_club_id
        ) THEN
            RAISE EXCEPTION
                'Vereinszugehörigkeit konnte nicht bestätigt werden'
                USING ERRCODE = '23514';
        END IF;
    END IF;

    INSERT INTO public.team_members (team_id, user_id, role)
    VALUES (p_team_id, p_user_id, p_role)
    ON CONFLICT (team_id, user_id) DO NOTHING;

    INSERT INTO public.team_member_roles (team_id, user_id, role)
    VALUES (p_team_id, p_user_id, p_role)
    ON CONFLICT (team_id, user_id, role) DO NOTHING;
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_add_team_role(uuid, uuid, text)
    FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_add_team_role(uuid, uuid, text)
    TO authenticated;

-- 5) Auch bei der Neuanlage einer Mannschaft darf der gewählte Admin
--    noch keiner anderen Mannschaft zugeordnet sein. Die Trigger bleiben
--    die zentrale Rückfallebene; diese Prüfung liefert eine frühe Meldung.
CREATE OR REPLACE FUNCTION public.admin_create_team(
    p_club_id uuid,
    p_name text,
    p_recommended_squad_size integer DEFAULT 16,
    p_birth_cohorts text DEFAULT NULL,
    p_abbreviation text DEFAULT NULL,
    p_season_name text DEFAULT NULL,
    p_team_admin_user_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
    v_team_id uuid;
    v_target_email text;
    v_is_super_admin boolean := public.is_super_admin();
    v_is_club_admin boolean := false;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Anmeldung erforderlich'
            USING ERRCODE = '42501';
    END IF;

    IF v_is_super_admin THEN
        IF NOT EXISTS (
            SELECT 1
            FROM public.user_club_context AS ctx
            WHERE ctx.user_id = auth.uid()
              AND ctx.club_id = p_club_id
        ) THEN
            RAISE EXCEPTION
                'Bitte wählen Sie zuerst genau diesen Verein aus'
                USING ERRCODE = '42501';
        END IF;
    ELSE
        SELECT EXISTS (
            SELECT 1
            FROM public.club_members AS cm
            JOIN public.club_member_roles AS cmr
              ON cmr.user_id = cm.user_id
            WHERE cm.user_id = auth.uid()
              AND cm.club_id = p_club_id
              AND cmr.role = 'club_admin'
        )
        INTO v_is_club_admin;

        IF NOT v_is_club_admin THEN
            RAISE EXCEPTION 'Keine Berechtigung für diesen Verein'
                USING ERRCODE = '42501';
        END IF;
    END IF;

    IF nullif(btrim(p_name), '') IS NULL THEN
        RAISE EXCEPTION 'Mannschaftsname darf nicht leer sein'
            USING ERRCODE = '22023';
    END IF;

    IF p_recommended_squad_size IS NULL
       OR p_recommended_squad_size < 1
       OR p_recommended_squad_size > 100 THEN
        RAISE EXCEPTION
            'Kadergröße muss zwischen 1 und 100 liegen'
            USING ERRCODE = '22023';
    END IF;

    IF p_team_admin_user_id IS NULL THEN
        RAISE EXCEPTION 'Bitte einen Mannschaftsadmin auswählen'
            USING ERRCODE = '22023';
    END IF;

    SELECT u.email
    INTO v_target_email
    FROM auth.users AS u
    WHERE u.id = p_team_admin_user_id
    FOR UPDATE;

    IF NOT FOUND OR nullif(btrim(v_target_email), '') IS NULL THEN
        RAISE EXCEPTION
            'Der ausgewählte Mannschaftsadmin besitzt kein gültiges Benutzerkonto'
            USING ERRCODE = '22023';
    END IF;



    IF NOT EXISTS (
        SELECT 1
        FROM public.club_members AS cm
        WHERE cm.user_id = p_team_admin_user_id
          AND cm.club_id = p_club_id
    ) THEN
        RAISE EXCEPTION
            'Der ausgewählte Mannschaftsadmin ist kein Mitglied dieses Vereins'
            USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.team_members AS tm
        WHERE tm.user_id = p_team_admin_user_id
    )
    OR EXISTS (
        SELECT 1
        FROM public.team_member_roles AS tmr
        WHERE tmr.user_id = p_team_admin_user_id
    ) THEN
        RAISE EXCEPTION
            'Der ausgewählte Mannschaftsadmin gehört bereits einer Mannschaft an'
            USING ERRCODE = '23514';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.clubs AS c
        WHERE c.id = p_club_id
    ) THEN
        RAISE EXCEPTION 'Verein nicht gefunden'
            USING ERRCODE = '22023';
    END IF;

    INSERT INTO public.teams (
        name,
        club_id,
        recommended_squad_size,
        birth_cohorts,
        abbreviation
    )
    VALUES (
        btrim(p_name),
        p_club_id,
        p_recommended_squad_size,
        nullif(btrim(p_birth_cohorts), ''),
        nullif(btrim(p_abbreviation), '')
    )
    RETURNING id INTO v_team_id;

    INSERT INTO public.team_members (team_id, user_id, role)
    VALUES (v_team_id, p_team_admin_user_id, 'admin')
    ON CONFLICT (team_id, user_id)
    DO UPDATE SET role = 'admin';

    INSERT INTO public.team_member_roles (team_id, user_id, role)
    VALUES (v_team_id, p_team_admin_user_id, 'admin')
    ON CONFLICT (team_id, user_id, role) DO NOTHING;

    IF nullif(btrim(p_season_name), '') IS NOT NULL THEN
        INSERT INTO public.seasons (team_id, name, is_active)
        VALUES (v_team_id, btrim(p_season_name), true);
    END IF;

    RETURN v_team_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_create_team(
    uuid, text, integer, text, text, text, uuid
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_create_team(
    uuid, text, integer, text, text, text, uuid
) TO authenticated;

-- 6) Kandidatenliste für Mannschaftsadmins: nur Vereinsmitglieder ohne
--    bestehende Zuordnung zu irgendeiner Mannschaft anbieten.
CREATE OR REPLACE FUNCTION public.admin_list_team_admin_candidates(
    p_club_id uuid
)
RETURNS TABLE (
    user_id uuid,
    email text,
    is_club_admin boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Anmeldung erforderlich'
            USING ERRCODE = '42501';
    END IF;

    IF public.is_super_admin() THEN
        IF NOT EXISTS (
            SELECT 1
            FROM public.user_club_context AS ctx
            WHERE ctx.user_id = auth.uid()
              AND ctx.club_id = p_club_id
        ) THEN
            RAISE EXCEPTION
                'Bitte wählen Sie zuerst genau diesen Verein aus'
                USING ERRCODE = '42501';
        END IF;
    ELSIF NOT EXISTS (
        SELECT 1
        FROM public.club_members AS cm
        JOIN public.club_member_roles AS cmr
          ON cmr.user_id = cm.user_id
        WHERE cm.user_id = auth.uid()
          AND cm.club_id = p_club_id
          AND cmr.role = 'club_admin'
    ) THEN
        RAISE EXCEPTION 'Keine Berechtigung für diesen Verein'
            USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT
        cm.user_id,
        u.email::text,
        EXISTS (
            SELECT 1
            FROM public.club_member_roles AS r
            WHERE r.user_id = cm.user_id
              AND r.role = 'club_admin'
        ) AS is_club_admin
    FROM public.club_members AS cm
    JOIN auth.users AS u
      ON u.id = cm.user_id
    WHERE cm.club_id = p_club_id
      AND nullif(btrim(u.email), '') IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM public.team_members AS tm
          WHERE tm.user_id = cm.user_id
      )
      AND NOT EXISTS (
          SELECT 1
          FROM public.team_member_roles AS tmr
          WHERE tmr.user_id = cm.user_id
      )
    ORDER BY lower(u.email), cm.user_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_list_team_admin_candidates(uuid)
    FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_list_team_admin_candidates(uuid)
    TO authenticated;


-- 7) Die zentrale Einladung erlaubt Superadmins ebenfalls eine eigene
--    Vereinsmitgliedschaft und genau eine tatsächliche Mannschaftszuordnung.
--    Die globale Superadmin-Rolle bleibt von Vereins- und Teamrollen getrennt.
CREATE OR REPLACE FUNCTION public.admin_complete_member_invitation(
    p_user_id uuid,
    p_display_name text,
    p_club_id uuid,
    p_invited_role text,
    p_team_id uuid DEFAULT NULL::uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
    v_email text;
    v_existing_club_id uuid;
    v_team_club_id uuid;
    v_actor_can_manage_club boolean;
    v_actor_can_manage_team boolean := false;
    v_profile_name_before text;
    v_profile_name_after text;
    v_profile_name_updated boolean;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Anmeldung erforderlich'
            USING errcode = '42501';
    END IF;

    IF p_user_id IS NULL OR p_club_id IS NULL THEN
        RAISE EXCEPTION 'Benutzer und Verein müssen angegeben werden'
            USING errcode = '22023';
    END IF;

    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Du kannst dich nicht selbst einladen'
            USING errcode = '42501';
    END IF;

    IF nullif(btrim(p_display_name), '') IS NULL
       OR length(btrim(p_display_name)) > 120 THEN
        RAISE EXCEPTION 'Der persönliche Name fehlt oder ist zu lang'
            USING errcode = '22023';
    END IF;

    IF p_invited_role IS NULL
       OR p_invited_role NOT IN (
           'member', 'club_admin', 'team_admin', 'trainer'
       ) THEN
        RAISE EXCEPTION 'Ungültige Einladungsrolle'
            USING errcode = '22023';
    END IF;

    -- Zielbenutzer sperren: verhindert parallele Zuordnungsprüfungen.
    SELECT u.email
    INTO v_email
    FROM auth.users AS u
    WHERE u.id = p_user_id
    FOR UPDATE;

    IF NOT FOUND OR nullif(btrim(v_email), '') IS NULL THEN
        RAISE EXCEPTION 'Auth-Benutzer nicht gefunden'
            USING errcode = '22023';
    END IF;

    -- Superadmins dürfen zusätzlich Vereinsmitglied, Vereinsadmin,
    -- Mannschaftsadmin oder Trainer sein. Die Superadmin-Rolle wird
    -- hiervon nicht entfernt oder verändert.

    IF NOT EXISTS (
        SELECT 1 FROM public.clubs AS c
        WHERE c.id = p_club_id
    ) THEN
        RAISE EXCEPTION 'Verein nicht gefunden'
            USING errcode = '22023';
    END IF;

    IF p_invited_role IN ('team_admin', 'trainer') THEN
        IF p_team_id IS NULL THEN
            RAISE EXCEPTION
                'Für eine Mannschaftsrolle muss eine Mannschaft ausgewählt werden'
                USING errcode = '22023';
        END IF;

        SELECT t.club_id
        INTO v_team_club_id
        FROM public.teams AS t
        WHERE t.id = p_team_id
          AND t.active = true;

        IF NOT FOUND OR v_team_club_id IS DISTINCT FROM p_club_id THEN
            RAISE EXCEPTION
                'Die ausgewählte Mannschaft gehört nicht zum Verein oder ist nicht aktiv'
                USING errcode = '23514';
        END IF;
    ELSE
        IF p_team_id IS NOT NULL THEN
            RAISE EXCEPTION
                'Für eine reine Vereinsrolle darf keine Mannschaft angegeben werden'
                USING errcode = '22023';
        END IF;
    END IF;

    -- Berechtigung der handelnden Person: Superadmin/Vereinsadmin
    -- benötigen den ausgewählten Vereinskontext; ein Teamadmin darf
    -- innerhalb seiner Mannschaft handeln. Mitgliedschaft in jeder
    -- Zielmannschaft ist dafür nicht erforderlich.
    v_actor_can_manage_club :=
        public.can_manage_club_context(p_club_id);

    IF p_team_id IS NOT NULL THEN
        v_actor_can_manage_team := public.is_team_admin(p_team_id);
    END IF;

    IF NOT v_actor_can_manage_club
       AND NOT (
           v_actor_can_manage_team
           AND p_invited_role IN ('team_admin', 'trainer')
       ) THEN
        RAISE EXCEPTION
            'Keine Berechtigung für diese Einladung oder kein passender Vereins-/Mannschaftskontext'
            USING errcode = '42501';
    END IF;

    -- Ein Benutzer bleibt genau einem Verein zugeordnet.
    SELECT cm.club_id
    INTO v_existing_club_id
    FROM public.club_members AS cm
    WHERE cm.user_id = p_user_id;

    IF FOUND AND v_existing_club_id IS DISTINCT FROM p_club_id THEN
        RAISE EXCEPTION
            'Benutzer ist bereits einem anderen Verein zugeordnet'
            USING errcode = '23514';
    END IF;

    -- Ein Benutzer darf höchstens einer Mannschaft angehören.
    -- Globale oder Vereins-Berechtigungen in weiteren Kontexten werden
    -- hiervon nicht eingeschränkt.
    IF p_team_id IS NOT NULL AND (
        EXISTS (
            SELECT 1 FROM public.team_members AS tm
            WHERE tm.user_id = p_user_id
              AND tm.team_id <> p_team_id
        )
        OR EXISTS (
            SELECT 1 FROM public.team_member_roles AS r
            WHERE r.user_id = p_user_id
              AND r.team_id <> p_team_id
        )
    ) THEN
        RAISE EXCEPTION
            'Benutzer gehört bereits einer anderen Mannschaft an'
            USING errcode = '23514';
    END IF;

    -- Vorhandenes Profil ebenfalls sperren.
    SELECT p.display_name
    INTO v_profile_name_before
    FROM public.profiles AS p
    WHERE p.id = p_user_id
    FOR UPDATE;

    -- Persönlichen Namen nur bei leerem Profil oder E-Mail-Fallback setzen.
    INSERT INTO public.profiles AS existing_profile (
        id, display_name
    )
    VALUES (
        p_user_id, btrim(p_display_name)
    )
    ON CONFLICT (id) DO UPDATE
    SET display_name = CASE
        WHEN nullif(btrim(existing_profile.display_name), '') IS NULL
          OR lower(btrim(existing_profile.display_name)) = lower(btrim(v_email))
        THEN EXCLUDED.display_name
        ELSE existing_profile.display_name
    END
    RETURNING display_name INTO v_profile_name_after;

    v_profile_name_updated :=
        v_profile_name_before IS DISTINCT FROM v_profile_name_after;

    INSERT INTO public.club_members (user_id, club_id)
    VALUES (p_user_id, p_club_id)
    ON CONFLICT (user_id) DO NOTHING;

    IF p_invited_role = 'club_admin' THEN
        INSERT INTO public.club_member_roles (user_id, role)
        VALUES (p_user_id, 'club_admin')
        ON CONFLICT (user_id, role) DO NOTHING;
    END IF;

    IF p_invited_role IN ('team_admin', 'trainer') THEN
        INSERT INTO public.team_members AS existing_member (
            team_id, user_id, role
        )
        VALUES (
            p_team_id,
            p_user_id,
            CASE WHEN p_invited_role = 'team_admin'
                THEN 'admin' ELSE 'trainer' END
        )
        ON CONFLICT (team_id, user_id)
        DO UPDATE SET role = CASE
            WHEN existing_member.role = 'admin'
              OR EXCLUDED.role = 'admin'
            THEN 'admin'
            ELSE 'trainer'
        END;

        INSERT INTO public.team_member_roles (
            team_id, user_id, role
        )
        VALUES (
            p_team_id,
            p_user_id,
            CASE WHEN p_invited_role = 'team_admin'
                THEN 'admin' ELSE 'trainer' END
        )
        ON CONFLICT (team_id, user_id, role) DO NOTHING;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'role', p_invited_role,
        'club_id', p_club_id,
        'team_id', p_team_id,
        'profile_name_updated', v_profile_name_updated
    );
END;
$function$;

REVOKE ALL ON FUNCTION
    public.admin_complete_member_invitation(uuid, text, uuid, text, uuid)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION
    public.admin_complete_member_invitation(uuid, text, uuid, text, uuid)
TO authenticated;


-- Ende des Vorschlags. Keine Aussage über tatsächliche Ausführung.
