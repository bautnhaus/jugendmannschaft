-- Guarded rollback for AP04 PROD Paket 12 / DB-MIG-2026-023.
-- Restores the exact six PROD definitions captured before Paket 12.
-- No ACL, table, data, policy, trigger, or storage changes are included.

begin;

do $preflight$
begin
  if md5(pg_get_functiondef('public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure)) <> '3a9eb766e1cbc357b16a25677b725577' then
    raise exception 'Paket 12 Postflight: Funktionsstand admin_update_member_profile unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure)) <> '6319ff70fc9bcbb00b43c7ec9a5d8570' then
    raise exception 'Paket 12 Postflight: Funktionsstand admin_update_club_member_profile unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_add_team_role(uuid,uuid,text)'::regprocedure)) <> '72289671afb1f722ed67befa08f9985c' then
    raise exception 'Paket 12 Postflight: Funktionsstand admin_add_team_role unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_remove_team_role(uuid,uuid,text)'::regprocedure)) <> '1e7ba2af3c1cf4c35087943aca95c953' then
    raise exception 'Paket 12 Postflight: Funktionsstand admin_remove_team_role unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure)) <> '5fd83e820b2edf50a5da0072c1ff3001' then
    raise exception 'Paket 12 Postflight: Funktionsstand admin_add_club_member_by_email unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure)) <> '36a81d72b40bdd76d72aa671b08cc121' then
    raise exception 'Paket 12 Postflight: Funktionsstand admin_set_club_member_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback preflight: SECURITY DEFINER/Owner/search_path von admin_update_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback preflight: EXECUTE-ACL von admin_update_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback preflight: SECURITY DEFINER/Owner/search_path von admin_update_club_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback preflight: EXECUTE-ACL von admin_update_club_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback preflight: SECURITY DEFINER/Owner/search_path von admin_add_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback preflight: EXECUTE-ACL von admin_add_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_remove_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback preflight: SECURITY DEFINER/Owner/search_path von admin_remove_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback preflight: EXECUTE-ACL von admin_remove_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback preflight: SECURITY DEFINER/Owner/search_path von admin_add_club_member_by_email unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback preflight: EXECUTE-ACL von admin_add_club_member_by_email unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback preflight: SECURITY DEFINER/Owner/search_path von admin_set_club_member_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback preflight: EXECUTE-ACL von admin_set_club_member_role unerwartet';
  end if;
end;
$preflight$;

-- Exact pre-Paket-12 PROD definitions.
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

do $postflight$
begin
  if md5(pg_get_functiondef('public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure)) <> '5a240ebe05fcf7ea01048dc429b6bad6' then
    raise exception 'Paket 12 Preflight: Funktionsstand admin_update_member_profile unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure)) <> '8ebed408aa5700582f034b384527efca' then
    raise exception 'Paket 12 Preflight: Funktionsstand admin_update_club_member_profile unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_add_team_role(uuid,uuid,text)'::regprocedure)) <> 'e2790dc60b75a6d64c475c480ce26c6c' then
    raise exception 'Paket 12 Preflight: Funktionsstand admin_add_team_role unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_remove_team_role(uuid,uuid,text)'::regprocedure)) <> '558ccda9a6ddc38c9c7625caf4fd84d6' then
    raise exception 'Paket 12 Preflight: Funktionsstand admin_remove_team_role unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure)) <> 'c71d52c28787644f7d514dfb71c21d87' then
    raise exception 'Paket 12 Preflight: Funktionsstand admin_add_club_member_by_email unerwartet';
  end if;
  if md5(pg_get_functiondef('public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure)) <> 'c5bca125f54511e9126f582bc05b873c' then
    raise exception 'Paket 12 Preflight: Funktionsstand admin_set_club_member_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback postflight: SECURITY DEFINER/Owner/search_path von admin_update_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback postflight: EXECUTE-ACL von admin_update_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback postflight: SECURITY DEFINER/Owner/search_path von admin_update_club_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback postflight: EXECUTE-ACL von admin_update_club_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback postflight: SECURITY DEFINER/Owner/search_path von admin_add_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback postflight: EXECUTE-ACL von admin_add_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_remove_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback postflight: SECURITY DEFINER/Owner/search_path von admin_remove_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback postflight: EXECUTE-ACL von admin_remove_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback postflight: SECURITY DEFINER/Owner/search_path von admin_add_club_member_by_email unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback postflight: EXECUTE-ACL von admin_add_club_member_by_email unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback postflight: SECURITY DEFINER/Owner/search_path von admin_set_club_member_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback postflight: EXECUTE-ACL von admin_set_club_member_role unerwartet';
  end if;
end;
$postflight$;

commit;
