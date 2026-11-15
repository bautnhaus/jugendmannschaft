\set ON_ERROR_STOP on
-- Isolated PostgreSQL 17 baseline captured from live PROD before Paket 12.
do $$ begin
 if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
 if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
 if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role nologin; end if;
end $$;
create schema if not exists auth;
create or replace function auth.uid() returns uuid language sql stable as 'select null::uuid';

-- Minimal dependency tables for SQL-language helper functions in the PROD baseline.
create table public.global_user_roles(user_id uuid, role text);
create table public.user_club_context(user_id uuid, club_id uuid);
create table public.user_team_context(user_id uuid, team_id uuid);
create table public.teams(id uuid, club_id uuid);
create table public.club_members(user_id uuid, club_id uuid);
create table public.club_member_roles(user_id uuid, role text);
create table public.team_member_roles(team_id uuid, user_id uuid, role text);
create table public.clubs(id uuid);
create table auth.users(id uuid, email text);


-- Read-only dependency baseline used by the Paket-12 preflight.
CREATE OR REPLACE FUNCTION public.is_super_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT auth.uid() IS NOT NULL
     AND EXISTS (
       SELECT 1
       FROM public.global_user_roles r
       WHERE r.user_id = auth.uid()
         AND r.role = 'super_admin'
     );
$function$;

CREATE OR REPLACE FUNCTION public.has_selected_team_context(p_team_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_team_context ctx
    JOIN public.teams t ON t.id = ctx.team_id
    WHERE ctx.user_id = auth.uid()
      AND ctx.team_id = p_team_id
      AND (
        EXISTS (
          SELECT 1
          FROM public.global_user_roles gur
          WHERE gur.user_id = auth.uid()
            AND gur.role = 'super_admin'
        )
        OR EXISTS (
          SELECT 1
          FROM public.club_members cm
          JOIN public.club_member_roles cmr
            ON cmr.user_id = cm.user_id
          WHERE cm.user_id = auth.uid()
            AND cm.club_id = t.club_id
            AND cmr.role = 'club_admin'
        )
      )
  );
$function$;

CREATE OR REPLACE FUNCTION public.is_club_admin(p_club_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT auth.uid() IS NOT NULL
     AND CASE
       WHEN public.is_super_admin() THEN EXISTS (
         SELECT 1
         FROM public.user_club_context ctx
         WHERE ctx.user_id = auth.uid()
           AND ctx.club_id = p_club_id
       )
       ELSE EXISTS (
         SELECT 1
         FROM public.club_members m
         JOIN public.club_member_roles r
           ON r.user_id = m.user_id
         WHERE m.user_id = auth.uid()
           AND m.club_id = p_club_id
           AND r.role = 'club_admin'
       )
     END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_add_club_member(p_club_id uuid, p_user_id uuid, p_role text DEFAULT 'member'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
BEGIN
  IF auth.uid() IS NULL
     OR NOT (
       public.is_club_admin(p_club_id)
       OR (
         public.is_super_admin()
         AND EXISTS (
           SELECT 1
           FROM public.user_team_context ctx
           JOIN public.teams t ON t.id = ctx.team_id
           WHERE ctx.user_id = auth.uid()
             AND t.club_id = p_club_id
             AND public.has_selected_team_context(t.id)
         )
       )
     ) THEN
    RAISE EXCEPTION 'Nicht berechtigt'
      USING ERRCODE = '42501';
  END IF;

  IF p_role NOT IN ('member', 'club_admin') THEN
    RAISE EXCEPTION 'Ungültige Vereinsrolle'
      USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.clubs c WHERE c.id = p_club_id
  ) THEN
    RAISE EXCEPTION 'Verein nicht gefunden'
      USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Benutzer nicht gefunden'
      USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.club_members m
    WHERE m.user_id = p_user_id
      AND m.club_id <> p_club_id
  ) THEN
    RAISE EXCEPTION 'Benutzer ist bereits einem anderen Verein zugeordnet'
      USING ERRCODE = '23514';
  END IF;

  INSERT INTO public.club_members(user_id, club_id)
  VALUES (p_user_id, p_club_id)
  ON CONFLICT (user_id) DO NOTHING;

  IF p_role = 'club_admin' THEN
    INSERT INTO public.club_member_roles(user_id, role)
    VALUES (p_user_id, 'club_admin')
    ON CONFLICT (user_id, role) DO NOTHING;
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.can_manage_club_context(p_club_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$

    SELECT auth.uid() IS NOT NULL

       AND (

            (

                EXISTS (

                    SELECT 1

                    FROM public.global_user_roles gur

                    WHERE gur.user_id = auth.uid()

                      AND gur.role = 'super_admin'

                )

                AND EXISTS (

                    SELECT 1

                    FROM public.user_club_context ctx

                    WHERE ctx.user_id = auth.uid()

                      AND ctx.club_id = p_club_id

                )

            )

            OR EXISTS (

                SELECT 1

                FROM public.club_members cm

                JOIN public.club_member_roles cmr

                  ON cmr.user_id = cm.user_id

                WHERE cm.user_id = auth.uid()

                  AND cm.club_id = p_club_id

                  AND cmr.role = 'club_admin'

            )

       );

$function$;

CREATE OR REPLACE FUNCTION public.is_team_admin(p_user_id uuid, p_team_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT p_user_id IS NOT NULL
     AND EXISTS (
       SELECT 1
       FROM public.team_member_roles r
       WHERE r.team_id = p_team_id
         AND r.user_id = p_user_id
         AND r.role = 'admin'
     );
$function$;











CREATE OR REPLACE FUNCTION public.admin_update_member_profile(p_team_id uuid, p_user_id uuid, p_display_name text, p_avatar_url text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
  v_name text := trim(coalesce(p_display_name, ''));
BEGIN
  IF auth.uid() IS NULL OR NOT (
    public.is_team_admin(auth.uid(), p_team_id)
    OR (
      public.is_super_admin()
      AND public.has_selected_team_context(p_team_id)
    )
  ) THEN
    RAISE EXCEPTION 'Nicht berechtigt'
      USING errcode = '42501';
  END IF;

  IF p_user_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.team_member_roles r
    WHERE r.team_id = p_team_id
      AND r.user_id = p_user_id
  ) THEN
    RAISE EXCEPTION
      'Mitglied gehört nicht zur ausgewählten Mannschaft'
      USING errcode = '22023';
  END IF;

  IF v_name = '' THEN
    RAISE EXCEPTION 'Name darf nicht leer sein'
      USING errcode = '22023';
  END IF;

  IF p_avatar_url IS NOT NULL
     AND length(p_avatar_url) > 2048 THEN
    RAISE EXCEPTION 'Profilbild-Adresse ist ungültig'
      USING errcode = '22023';
  END IF;

  INSERT INTO public.profiles(id, display_name, avatar_url)
  VALUES (p_user_id, v_name, p_avatar_url)
  ON CONFLICT (id) DO UPDATE
    SET display_name = excluded.display_name,
        avatar_url = excluded.avatar_url;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_update_club_member_profile(p_club_id uuid, p_user_id uuid, p_display_name text, p_avatar_url text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
  v_name text := TRIM(COALESCE(p_display_name, ''));
BEGIN
  IF auth.uid() IS NULL
     OR NOT public.can_manage_club_context(p_club_id) THEN
    RAISE EXCEPTION 'Nicht berechtigt oder kein ausgewählter Vereinskontext'
      USING ERRCODE = '42501';
  END IF;

  IF p_user_id IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM public.club_members cm
       WHERE cm.club_id = p_club_id
         AND cm.user_id = p_user_id
     ) THEN
    RAISE EXCEPTION 'Konto gehört nicht zum ausgewählten Verein'
      USING ERRCODE = '42501';
  END IF;

  IF v_name = '' THEN
    RAISE EXCEPTION 'Name darf nicht leer sein'
      USING ERRCODE = '22023';
  END IF;

  IF p_avatar_url IS NOT NULL AND LENGTH(p_avatar_url) > 2048 THEN
    RAISE EXCEPTION 'Profilbild-Adresse ist ungültig'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.profiles(id, display_name, avatar_url)
  VALUES (p_user_id, v_name, p_avatar_url)
  ON CONFLICT (id)
  DO UPDATE SET
    display_name = EXCLUDED.display_name,
    avatar_url = EXCLUDED.avatar_url;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_add_team_role(p_team_id uuid, p_user_id uuid, p_role text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
    v_club_id uuid;
    v_existing_club_id uuid;
    v_legacy_role text;
BEGIN
    IF p_team_id IS NULL OR p_user_id IS NULL
       OR p_role IS NULL OR p_role NOT IN ('admin', 'trainer') THEN
        RAISE EXCEPTION 'Ungültige Mannschaft, Benutzer-ID oder Rolle'
            USING ERRCODE = '22023';
    END IF;

    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Eigene Mannschaftsrollen können nicht geändert werden'
            USING ERRCODE = '42501';
    END IF;

    SELECT t.club_id INTO v_club_id
      FROM public.teams t
     WHERE t.id = p_team_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Mannschaft nicht gefunden' USING ERRCODE = '22023';
    END IF;

    IF auth.uid() IS NULL OR NOT (
        public.is_team_admin(auth.uid(), p_team_id)
        OR (v_club_id IS NOT NULL AND public.can_manage_club_context(v_club_id))
        OR (public.is_super_admin() AND public.has_selected_team_context(p_team_id))
    ) THEN
        RAISE EXCEPTION 'Nicht berechtigt oder kein passender Kontext'
            USING ERRCODE = '42501';
    END IF;

    PERFORM 1 FROM auth.users u WHERE u.id = p_user_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Benutzer nicht gefunden' USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.team_members tm
         WHERE tm.user_id = p_user_id AND tm.team_id <> p_team_id
    ) OR EXISTS (
        SELECT 1 FROM public.team_member_roles tmr
         WHERE tmr.user_id = p_user_id AND tmr.team_id <> p_team_id
    ) THEN
        RAISE EXCEPTION
            'Benutzer gehört bereits einer anderen Mannschaft an. Eine zweite Mannschaftszuordnung ist nicht möglich.'
            USING ERRCODE = '23514';
    END IF;

    IF v_club_id IS NOT NULL THEN
        SELECT cm.club_id INTO v_existing_club_id
          FROM public.club_members cm
         WHERE cm.user_id = p_user_id;

        IF v_existing_club_id IS NOT NULL AND v_existing_club_id <> v_club_id THEN
            RAISE EXCEPTION 'Benutzer ist bereits einem anderen Verein zugeordnet'
                USING ERRCODE = '23514';
        END IF;

        INSERT INTO public.club_members(user_id, club_id)
        VALUES (p_user_id, v_club_id)
        ON CONFLICT (user_id) DO NOTHING;

        IF NOT EXISTS (
            SELECT 1 FROM public.club_members cm
             WHERE cm.user_id = p_user_id AND cm.club_id = v_club_id
        ) THEN
            RAISE EXCEPTION 'Vereinszugehörigkeit konnte nicht bestätigt werden'
                USING ERRCODE = '23514';
        END IF;
    END IF;

    INSERT INTO public.team_member_roles(team_id, user_id, role)
    VALUES (p_team_id, p_user_id, p_role)
    ON CONFLICT (team_id, user_id, role) DO NOTHING;

    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM public.team_member_roles r
         WHERE r.team_id = p_team_id AND r.user_id = p_user_id AND r.role = 'admin'
    ) THEN 'admin' ELSE 'trainer' END
    INTO v_legacy_role;

    INSERT INTO public.team_members(team_id, user_id, role)
    VALUES (p_team_id, p_user_id, v_legacy_role)
    ON CONFLICT (team_id, user_id)
    DO UPDATE SET role = EXCLUDED.role;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_remove_team_role(p_team_id uuid, p_user_id uuid, p_role text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
  v_club_id uuid;
  v_admin_count integer;
  v_remaining_role text;
BEGIN
  IF p_team_id IS NULL OR p_user_id IS NULL
     OR p_role IS NULL OR p_role NOT IN ('admin', 'trainer') THEN
    RAISE EXCEPTION 'Ungültige Mannschaft, Benutzer-ID oder Rolle'
      USING ERRCODE = '22023';
  END IF;

  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Eigene Mannschaftsrollen können nicht geändert werden'
      USING ERRCODE = '42501';
  END IF;

  SELECT t.club_id INTO v_club_id
  FROM public.teams t
  WHERE t.id = p_team_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Mannschaft nicht gefunden'
      USING ERRCODE = '22023';
  END IF;

  IF auth.uid() IS NULL OR NOT (
    public.is_team_admin(auth.uid(), p_team_id)
    OR (
      v_club_id IS NOT NULL
      AND public.can_manage_club_context(v_club_id)
    )
    OR (
      public.is_super_admin()
      AND public.has_selected_team_context(p_team_id)
    )
  ) THEN
    RAISE EXCEPTION 'Nicht berechtigt oder kein passender Kontext'
      USING ERRCODE = '42501';
  END IF;

  IF p_role = 'admin'
     AND EXISTS (
       SELECT 1 FROM public.team_member_roles r
       WHERE r.team_id = p_team_id
         AND r.user_id = p_user_id
         AND r.role = 'admin'
     ) THEN
    SELECT count(*) INTO v_admin_count
    FROM public.team_member_roles r
    WHERE r.team_id = p_team_id
      AND r.role = 'admin';

    IF v_admin_count <= 1 THEN
      RAISE EXCEPTION 'Der letzte Team-Admin kann nicht entfernt werden'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  DELETE FROM public.team_member_roles
  WHERE team_id = p_team_id
    AND user_id = p_user_id
    AND role = p_role;

  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM public.team_member_roles r
      WHERE r.team_id = p_team_id
        AND r.user_id = p_user_id
        AND r.role = 'admin'
    ) THEN 'admin'
    WHEN EXISTS (
      SELECT 1 FROM public.team_member_roles r
      WHERE r.team_id = p_team_id
        AND r.user_id = p_user_id
        AND r.role = 'trainer'
    ) THEN 'trainer'
    ELSE NULL
  END INTO v_remaining_role;

  IF v_remaining_role IS NULL THEN
    DELETE FROM public.team_members
    WHERE team_id = p_team_id
      AND user_id = p_user_id;
  ELSE
    UPDATE public.team_members
    SET role = v_remaining_role
    WHERE team_id = p_team_id
      AND user_id = p_user_id;
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_add_club_member_by_email(p_club_id uuid, p_email text, p_role text DEFAULT 'member'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
  v_user_id uuid;
BEGIN
  IF auth.uid() IS NULL
     OR NOT public.can_manage_club_context(p_club_id) THEN
    RAISE EXCEPTION 'Nicht berechtigt oder kein ausgewählter Vereinskontext'
      USING ERRCODE = '42501';
  END IF;

  IF p_role NOT IN ('member', 'club_admin') THEN
    RAISE EXCEPTION 'Ungültige Vereinsrolle'
      USING ERRCODE = '22023';
  END IF;

  IF NULLIF(BTRIM(p_email), '') IS NULL THEN
    RAISE EXCEPTION 'E-Mail-Adresse fehlt'
      USING ERRCODE = '22023';
  END IF;

  SELECT u.id
  INTO v_user_id
  FROM auth.users u
  WHERE LOWER(u.email) = LOWER(BTRIM(p_email))
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION
      'Kein bestehendes Konto mit dieser E-Mail-Adresse gefunden. Bitte zuerst eine Einladung auslösen.'
      USING ERRCODE = 'P0002';
  END IF;

  PERFORM public.admin_add_club_member(p_club_id, v_user_id, p_role);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_set_club_member_role(p_club_id uuid, p_user_id uuid, p_role text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
  v_admin_count integer;
BEGIN
  IF auth.uid() IS NULL
     OR NOT public.can_manage_club_context(p_club_id) THEN
    RAISE EXCEPTION 'Nicht berechtigt oder kein ausgewählter Vereinskontext'
      USING ERRCODE = '42501';
  END IF;

  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Die eigene Vereinsrolle kann nicht geändert werden'
      USING ERRCODE = '42501';
  END IF;

  IF p_role NOT IN ('member', 'club_admin') THEN
    RAISE EXCEPTION 'Ungültige Vereinsrolle'
      USING ERRCODE = '22023';
  END IF;

  PERFORM 1
  FROM public.clubs c
  WHERE c.id = p_club_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Verein nicht gefunden'
      USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.club_members m
    WHERE m.club_id = p_club_id
      AND m.user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Das Konto ist kein Mitglied dieses Vereins'
      USING ERRCODE = 'P0002';
  END IF;

  IF p_role = 'club_admin' THEN
    INSERT INTO public.club_member_roles(user_id, role)
    VALUES (p_user_id, 'club_admin')
    ON CONFLICT (user_id, role) DO NOTHING;
  ELSE
    IF EXISTS (
      SELECT 1
      FROM public.club_member_roles r
      WHERE r.user_id = p_user_id
        AND r.role = 'club_admin'
    ) THEN
      SELECT count(*)
      INTO v_admin_count
      FROM public.club_members m
      JOIN public.club_member_roles r
        ON r.user_id = m.user_id
       AND r.role = 'club_admin'
      WHERE m.club_id = p_club_id;

      IF v_admin_count <= 1 THEN
        RAISE EXCEPTION 'Der letzte Vereinsadmin kann nicht herabgestuft werden'
          USING ERRCODE = '23514';
      END IF;
    END IF;

    DELETE FROM public.club_member_roles r
    WHERE r.user_id = p_user_id
      AND r.role = 'club_admin';
  END IF;
END;
$function$;
revoke all on function public.admin_update_member_profile(uuid,uuid,text,text) from public, anon, authenticated, service_role;
grant execute on function public.admin_update_member_profile(uuid,uuid,text,text) to authenticated, service_role;
revoke all on function public.admin_update_club_member_profile(uuid,uuid,text,text) from public, anon, authenticated, service_role;
grant execute on function public.admin_update_club_member_profile(uuid,uuid,text,text) to authenticated, service_role;
revoke all on function public.admin_add_team_role(uuid,uuid,text) from public, anon, authenticated, service_role;
grant execute on function public.admin_add_team_role(uuid,uuid,text) to authenticated, service_role;
revoke all on function public.admin_remove_team_role(uuid,uuid,text) from public, anon, authenticated, service_role;
grant execute on function public.admin_remove_team_role(uuid,uuid,text) to authenticated, service_role;
revoke all on function public.admin_add_club_member_by_email(uuid,text,text) from public, anon, authenticated, service_role;
grant execute on function public.admin_add_club_member_by_email(uuid,text,text) to authenticated, service_role;
revoke all on function public.admin_set_club_member_role(uuid,uuid,text) from public, anon, authenticated, service_role;
grant execute on function public.admin_set_club_member_role(uuid,uuid,text) to authenticated, service_role;
