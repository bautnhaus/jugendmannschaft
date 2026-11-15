-- AP04 PROD Paket 12: Profil- und Mitglieder-/Rollenverwaltung
-- DB-MIG-2026-023 (proposed; only apply after explicit approval)
-- Source: exact live DEV definitions read on 2026-11-15.
-- Scope: six existing functions only. No table/data/policy/trigger/storage changes.

begin;

do $preflight$
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
    raise exception 'Paket 12 Preflight: SECURITY DEFINER/Owner/search_path von admin_update_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Preflight: EXECUTE-ACL von admin_update_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Preflight: SECURITY DEFINER/Owner/search_path von admin_update_club_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Preflight: EXECUTE-ACL von admin_update_club_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Preflight: SECURITY DEFINER/Owner/search_path von admin_add_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Preflight: EXECUTE-ACL von admin_add_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_remove_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Preflight: SECURITY DEFINER/Owner/search_path von admin_remove_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Preflight: EXECUTE-ACL von admin_remove_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Preflight: SECURITY DEFINER/Owner/search_path von admin_add_club_member_by_email unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Preflight: EXECUTE-ACL von admin_add_club_member_by_email unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Preflight: SECURITY DEFINER/Owner/search_path von admin_set_club_member_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Preflight: EXECUTE-ACL von admin_set_club_member_role unerwartet';
  end if;
end;
$preflight$;

-- Current live DEV definitions; CREATE OR REPLACE preserves owner and ACL.
CREATE OR REPLACE FUNCTION public.admin_update_member_profile(p_team_id uuid, p_user_id uuid, p_display_name text, p_avatar_url text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not (
    public.is_team_admin(auth.uid(), p_team_id)
    or (public.is_super_admin() and public.has_selected_team_context(p_team_id))
  ) then
    raise exception 'Nicht berechtigt' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (
    select 1 from public.team_member_roles r
    where r.team_id = p_team_id and r.user_id = p_user_id
  ) then
    raise exception 'Mitglied gehört nicht zur ausgewählten Mannschaft' using errcode = '22023';
  end if;
  if v_name = '' then raise exception 'Name darf nicht leer sein' using errcode = '22023'; end if;
  if p_avatar_url is not null and length(p_avatar_url) > 2048 then
    raise exception 'Profilbild-Adresse ist ungültig' using errcode = '22023';
  end if;
  insert into public.profiles(id, display_name, avatar_url)
  values (p_user_id, v_name, p_avatar_url)
  on conflict (id) do update
    set display_name = excluded.display_name,
        avatar_url = excluded.avatar_url;
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_update_club_member_profile(p_club_id uuid, p_user_id uuid, p_display_name text, p_avatar_url text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not public.can_manage_club_context(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (
    select 1 from public.club_members cm where cm.club_id=p_club_id and cm.user_id=p_user_id
  ) then raise exception 'Konto gehört nicht zum ausgewählten Verein' using errcode = '42501'; end if;
  if v_name = '' then raise exception 'Name darf nicht leer sein' using errcode = '22023'; end if;
  if p_avatar_url is not null and length(p_avatar_url)>2048 then raise exception 'Profilbild-Adresse ist ungültig' using errcode = '22023'; end if;
  insert into public.profiles(id,display_name,avatar_url) values(p_user_id,v_name,p_avatar_url)
  on conflict(id) do update set display_name=excluded.display_name,avatar_url=excluded.avatar_url;
end;
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

CREATE OR REPLACE FUNCTION public.admin_remove_team_role(p_team_id uuid, p_user_id uuid, p_role text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare v_admin_count integer; v_club_id uuid;
begin
  select t.club_id into v_club_id from public.teams t where t.id=p_team_id for update;
  if not found then raise exception 'Mannschaft nicht gefunden'; end if;
  if auth.uid() is null or not (
    public.is_team_admin(auth.uid(),p_team_id)
    or (v_club_id is not null and public.can_manage_club_context(v_club_id))
    or (public.is_super_admin() and public.has_selected_team_context(p_team_id))
  ) then raise exception 'Nicht berechtigt oder kein passender Vereins-/Mannschaftskontext' using errcode='42501'; end if;
  if p_user_id=auth.uid() then raise exception 'Eigene Mannschaftsrollen können nicht geändert werden' using errcode='42501'; end if;
  if p_role not in ('admin','trainer') then raise exception 'Ungültige Teamrolle' using errcode='22023'; end if;
  if p_role='admin' then
    select count(*) into v_admin_count from public.team_member_roles r where r.team_id=p_team_id and r.role='admin';
    if exists(select 1 from public.team_member_roles r where r.team_id=p_team_id and r.user_id=p_user_id and r.role='admin') and v_admin_count<=1 then
      raise exception 'Der letzte Team-Admin kann nicht entfernt werden' using errcode='23514';
    end if;
  end if;
  delete from public.team_member_roles where team_id=p_team_id and user_id=p_user_id and role=p_role;
  if not exists(select 1 from public.team_member_roles r where r.team_id=p_team_id and r.user_id=p_user_id) then
    delete from public.team_members where team_id=p_team_id and user_id=p_user_id;
  end if;
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_add_club_member_by_email(p_club_id uuid, p_email text, p_role text DEFAULT 'member'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare v_user_id uuid;
begin
  if auth.uid() is null or not public.can_manage_club_context(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext' using errcode='42501';
  end if;
  if p_role not in ('member','club_admin') then raise exception 'Ungültige Vereinsrolle' using errcode='22023'; end if;
  if nullif(btrim(p_email),'') is null then raise exception 'E-Mail-Adresse fehlt' using errcode='22023'; end if;
  select u.id into v_user_id from auth.users u where lower(u.email)=lower(btrim(p_email)) limit 1;
  if v_user_id is null then raise exception 'Kein bestehendes Konto mit dieser E-Mail-Adresse gefunden. Bitte zuerst eine Einladung auslösen.' using errcode='P0002'; end if;
  perform public.admin_add_club_member(p_club_id,v_user_id,p_role);
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_set_club_member_role(p_club_id uuid, p_user_id uuid, p_role text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare v_admin_count integer;
begin
  if auth.uid() is null or not public.can_manage_club_context(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext' using errcode='42501';
  end if;
  if p_user_id=auth.uid() then raise exception 'Die eigene Vereinsrolle kann nicht geändert werden' using errcode='42501'; end if;
  if p_role not in ('member','club_admin') then raise exception 'Ungültige Vereinsrolle' using errcode='22023'; end if;
  perform 1 from public.clubs c where c.id=p_club_id for update;
  if not found then raise exception 'Verein nicht gefunden' using errcode='22023'; end if;
  if not exists(select 1 from public.club_members m where m.club_id=p_club_id and m.user_id=p_user_id) then
    raise exception 'Das Konto ist kein Mitglied dieses Vereins' using errcode='P0002';
  end if;
  if p_role='club_admin' then
    insert into public.club_member_roles(user_id,role) values(p_user_id,'club_admin') on conflict(user_id,role) do nothing;
  else
    if exists(select 1 from public.club_member_roles r where r.user_id=p_user_id and r.role='club_admin') then
      select count(*) into v_admin_count from public.club_members m join public.club_member_roles r on r.user_id=m.user_id and r.role='club_admin' where m.club_id=p_club_id;
      if v_admin_count<=1 then raise exception 'Der letzte Vereinsadmin kann nicht herabgestuft werden' using errcode='23514'; end if;
    end if;
    delete from public.club_member_roles r where r.user_id=p_user_id and r.role='club_admin';
  end if;
end;
$function$;

do $postflight$
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
    raise exception 'Paket 12 Postflight: SECURITY DEFINER/Owner/search_path von admin_update_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Postflight: EXECUTE-ACL von admin_update_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Postflight: SECURITY DEFINER/Owner/search_path von admin_update_club_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Postflight: EXECUTE-ACL von admin_update_club_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Postflight: SECURITY DEFINER/Owner/search_path von admin_add_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Postflight: EXECUTE-ACL von admin_add_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_remove_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Postflight: SECURITY DEFINER/Owner/search_path von admin_remove_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Postflight: EXECUTE-ACL von admin_remove_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Postflight: SECURITY DEFINER/Owner/search_path von admin_add_club_member_by_email unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Postflight: EXECUTE-ACL von admin_add_club_member_by_email unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Postflight: SECURITY DEFINER/Owner/search_path von admin_set_club_member_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Postflight: EXECUTE-ACL von admin_set_club_member_role unerwartet';
  end if;
end;
$postflight$;

commit;
