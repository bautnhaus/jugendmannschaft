\set ON_ERROR_STOP on
do $assert$
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
    raise exception 'Paket 12 Rollback CI assertion: SECURITY DEFINER/Owner/search_path von admin_update_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback CI assertion: EXECUTE-ACL von admin_update_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback CI assertion: SECURITY DEFINER/Owner/search_path von admin_update_club_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback CI assertion: EXECUTE-ACL von admin_update_club_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback CI assertion: SECURITY DEFINER/Owner/search_path von admin_add_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback CI assertion: EXECUTE-ACL von admin_add_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_remove_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback CI assertion: SECURITY DEFINER/Owner/search_path von admin_remove_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback CI assertion: EXECUTE-ACL von admin_remove_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback CI assertion: SECURITY DEFINER/Owner/search_path von admin_add_club_member_by_email unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback CI assertion: EXECUTE-ACL von admin_add_club_member_by_email unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 Rollback CI assertion: SECURITY DEFINER/Owner/search_path von admin_set_club_member_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 Rollback CI assertion: EXECUTE-ACL von admin_set_club_member_role unerwartet';
  end if;
end;
$assert$;
