-- KADAssist IMG-SEC-01 helper hardening follow-up; PROD release copy; apply only after explicit PROD approval.
begin;

-- Preflight: nur den vollständig installierten IMG-SEC-01a-Zwischenstand härten.
do $preflight$
begin
  if to_regprocedure('public.can_view_player_photo(uuid)') is null
     or to_regprocedure('public.can_manage_player_photo(uuid,uuid)') is null
     or to_regprocedure('public.can_view_club_asset(uuid)') is null
     or to_regprocedure('public.can_view_profile_avatar(uuid)') is null then
    raise exception 'IMG-SEC-01b Preflight: öffentliche IMG-SEC-01a-Helper fehlen.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='profile_avatars_select_authorized'
      and cmd='SELECT'
      and qual like '%public.can_view_profile_avatar%'
  ) then
    raise exception 'IMG-SEC-01b Preflight: Profilbild-Policy referenziert nicht den erwarteten IMG-SEC-01a-Helper.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='club_assets_select_scoped'
      and cmd='SELECT'
      and qual like '%public.can_view_club_asset%'
  ) then
    raise exception 'IMG-SEC-01b Preflight: Vereinsasset-Policy referenziert nicht den erwarteten IMG-SEC-01a-Helper.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='player_photos_select_team'
      and cmd='SELECT'
      and qual like '%public.can_manage_player_photo%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='player_photos_insert_team'
      and cmd='INSERT'
      and with_check like '%public.can_manage_player_photo%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='player_photos_update_team'
      and cmd='UPDATE'
      and coalesce(qual,'') || coalesce(with_check,'') like '%public.can_manage_player_photo%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='player_photos_delete_team'
      and cmd='DELETE'
      and qual like '%public.can_manage_player_photo%'
  ) then
    raise exception 'IMG-SEC-01b Preflight: Spielerfoto-Policies referenzieren nicht vollständig den erwarteten IMG-SEC-01a-Helper.';
  end if;
end;
$preflight$;

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

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='profile_avatars_select_authorized'
      and qual like '%private.can_view_profile_avatar%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='club_assets_select_scoped'
      and qual like '%private.can_view_club_asset%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='player_photos_select_team'
      and qual like '%private.can_manage_player_photo%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='player_photos_insert_team'
      and with_check like '%private.can_manage_player_photo%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='player_photos_update_team'
      and coalesce(qual,'') || coalesce(with_check,'') like '%private.can_manage_player_photo%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='player_photos_delete_team'
      and qual like '%private.can_manage_player_photo%'
  ) then
    raise exception 'IMG-SEC-01b Postflight: Storage-Policies wurden nicht vollständig auf private Helper umgestellt.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='club_assets_insert_scoped'
      and with_check like '%public.is_club_admin%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='club_assets_update_scoped'
      and coalesce(qual,'') || coalesce(with_check,'') like '%public.is_club_admin%'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='club_assets_delete_scoped'
      and qual like '%public.is_club_admin%'
  ) then
    raise exception 'IMG-SEC-01b Postflight: Vereinsasset-Schreibpolicies verwenden nicht den expliziten Vereinskontext.';
  end if;
end;
$postflight$;

commit;
