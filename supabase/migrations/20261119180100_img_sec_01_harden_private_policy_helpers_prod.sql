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
commit;
