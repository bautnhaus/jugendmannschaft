\set ON_ERROR_STOP on
do $assert$
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
    raise exception 'Paket 12 CI assertion: SECURITY DEFINER/Owner/search_path von admin_update_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 CI assertion: EXECUTE-ACL von admin_update_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 CI assertion: SECURITY DEFINER/Owner/search_path von admin_update_club_member_profile unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_update_club_member_profile(uuid,uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 CI assertion: EXECUTE-ACL von admin_update_club_member_profile unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 CI assertion: SECURITY DEFINER/Owner/search_path von admin_add_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 CI assertion: EXECUTE-ACL von admin_add_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_remove_team_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 CI assertion: SECURITY DEFINER/Owner/search_path von admin_remove_team_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_remove_team_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 CI assertion: EXECUTE-ACL von admin_remove_team_role unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure) then
    raise exception 'Paket 12 CI assertion: SECURITY DEFINER/Owner/search_path von admin_add_club_member_by_email unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_add_club_member_by_email(uuid,text,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 CI assertion: EXECUTE-ACL von admin_add_club_member_by_email unerwartet';
  end if;
  if not (select prosecdef and proowner='postgres'::regrole and proconfig @> array['search_path=pg_catalog, public, auth'] from pg_proc where oid='public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure) then
    raise exception 'Paket 12 CI assertion: SECURITY DEFINER/Owner/search_path von admin_set_club_member_role unerwartet';
  end if;
  if not has_function_privilege('authenticated','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('public','public.admin_set_club_member_role(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 12 CI assertion: EXECUTE-ACL von admin_set_club_member_role unerwartet';
  end if;
end;
$assert$;
