-- KADAssist IMG-SEC-01 helper hardening follow-up; PROD release copy; apply only after explicit PROD approval.
begin;
create schema if not exists private;
revoke all on schema private from public,anon;
grant usage on schema private to authenticated;
alter function public.can_manage_player_photo(uuid,uuid) set schema private;
alter function public.can_view_club_asset(uuid) set schema private;
alter function public.can_view_profile_avatar(uuid) set schema private;
drop function if exists public.can_view_player_photo(uuid);
revoke all on function private.can_manage_player_photo(uuid,uuid) from public,anon;
revoke all on function private.can_view_club_asset(uuid) from public,anon;
revoke all on function private.can_view_profile_avatar(uuid) from public,anon;
grant execute on function private.can_manage_player_photo(uuid,uuid) to authenticated;
grant execute on function private.can_view_club_asset(uuid) to authenticated;
grant execute on function private.can_view_profile_avatar(uuid) to authenticated;

-- Guard: the policy helpers must now exist only in private and must not be callable by anon.
do $postflight$
begin
  if not has_schema_privilege('authenticated','private','USAGE')
     or has_schema_privilege('anon','private','USAGE') then
    raise exception 'IMG-SEC-01b Postflight: unexpected private schema USAGE privileges.';
  end if;

  if to_regprocedure('private.can_manage_player_photo(uuid,uuid)') is null
     or to_regprocedure('private.can_view_club_asset(uuid)') is null
     or to_regprocedure('private.can_view_profile_avatar(uuid)') is null
     or to_regprocedure('public.can_manage_player_photo(uuid,uuid)') is not null
     or to_regprocedure('public.can_view_club_asset(uuid)') is not null
     or to_regprocedure('public.can_view_profile_avatar(uuid)') is not null
     or to_regprocedure('public.can_view_player_photo(uuid)') is not null then
    raise exception 'IMG-SEC-01b Postflight: helper schema migration is incomplete.';
  end if;

  if not has_function_privilege('authenticated','private.can_manage_player_photo(uuid,uuid)','EXECUTE')
     or not has_function_privilege('authenticated','private.can_view_club_asset(uuid)','EXECUTE')
     or not has_function_privilege('authenticated','private.can_view_profile_avatar(uuid)','EXECUTE')
     or has_function_privilege('anon','private.can_manage_player_photo(uuid,uuid)','EXECUTE')
     or has_function_privilege('anon','private.can_view_club_asset(uuid)','EXECUTE')
     or has_function_privilege('anon','private.can_view_profile_avatar(uuid)','EXECUTE') then
    raise exception 'IMG-SEC-01b Postflight: unexpected helper EXECUTE privileges.';
  end if;
end;
$postflight$;

commit;
