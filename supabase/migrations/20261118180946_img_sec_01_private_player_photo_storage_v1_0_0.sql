-- KADAssist IMG-SEC-01 / Paket 1A / Version 1.0.0
-- Supabase DEV only. Existing profile-avatars and club-assets buckets remain public.
-- profiles_select and existing profile-avatar write policies remain unchanged.
begin;
alter table public.players add column if not exists photo_path text;
comment on column public.players.photo_path is 'Storage path in private player-photos bucket; replaces photo_data after verified migration.';
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('player-photos','player-photos',false,2097152,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
do $$
declare v_public boolean;
begin
  select public into v_public from storage.buckets where id='player-photos';
  if not found then raise exception 'Bucket player-photos missing after insert.'; end if;
  if v_public is distinct from false then raise exception 'Existing player-photos bucket is not private; aborting without changing it.'; end if;
end;
$$;
create or replace function public.can_view_player_photo(p_team_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $function$ select auth.uid() is not null and p_team_id is not null and public.is_team_member(p_team_id); $function$;
create or replace function public.can_manage_player_photo(p_team_id uuid,p_player_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $function$
select auth.uid() is not null and p_team_id is not null and p_player_id is not null
and exists(select 1 from public.players p where p.id=p_player_id and p.team_id=p_team_id)
and public.is_team_member(p_team_id);
$function$;
create or replace function public.can_view_club_asset(p_club_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $function$ select auth.uid() is not null and p_club_id is not null and (public.is_club_member(p_club_id) or public.is_club_admin(p_club_id)); $function$;
create or replace function public.can_view_profile_avatar(p_target_user_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $function$
select auth.uid() is not null and p_target_user_id is not null and (
 p_target_user_id=auth.uid()
 or exists(select 1 from public.team_member_roles viewer join public.team_member_roles target on target.team_id=viewer.team_id where viewer.user_id=auth.uid() and target.user_id=p_target_user_id)
 or exists(select 1 from public.club_members viewer_member join public.club_member_roles viewer_role on viewer_role.user_id=viewer_member.user_id join public.club_members target_member on target_member.club_id=viewer_member.club_id where viewer_member.user_id=auth.uid() and viewer_role.role='club_admin' and target_member.user_id=p_target_user_id)
 or exists(select 1 from public.global_user_roles gur join public.user_team_context ctx on ctx.user_id=gur.user_id join public.team_member_roles target on target.team_id=ctx.team_id where gur.user_id=auth.uid() and gur.role='super_admin' and target.user_id=p_target_user_id)
 or exists(select 1 from public.global_user_roles gur join public.user_club_context ctx on ctx.user_id=gur.user_id join public.club_members target on target.club_id=ctx.club_id where gur.user_id=auth.uid() and gur.role='super_admin' and target.user_id=p_target_user_id)
);
$function$;
revoke all on function public.can_view_player_photo(uuid) from public,anon;
revoke all on function public.can_manage_player_photo(uuid,uuid) from public,anon;
revoke all on function public.can_view_club_asset(uuid) from public,anon;
revoke all on function public.can_view_profile_avatar(uuid) from public,anon;
grant execute on function public.can_view_player_photo(uuid) to authenticated;
grant execute on function public.can_manage_player_photo(uuid,uuid) to authenticated;
grant execute on function public.can_view_club_asset(uuid) to authenticated;
grant execute on function public.can_view_profile_avatar(uuid) to authenticated;
drop policy if exists profile_avatars_select_authorized on storage.objects;
create policy profile_avatars_select_authorized on storage.objects for select to authenticated using (
 bucket_id='profile-avatars' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then public.can_view_profile_avatar(split_part(name,'/',1)::uuid) else false end
);
drop policy if exists club_assets_select_scoped on storage.objects;
create policy club_assets_select_scoped on storage.objects for select to authenticated using (
 bucket_id='club-assets' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then public.can_view_club_asset(split_part(name,'/',1)::uuid) else false end
);
drop policy if exists player_photos_select_team on storage.objects;
create policy player_photos_select_team on storage.objects for select to authenticated using (
 bucket_id='player-photos' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' and split_part(name,'/',2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then public.can_manage_player_photo(split_part(name,'/',1)::uuid,split_part(name,'/',2)::uuid) else false end
);
drop policy if exists player_photos_insert_team on storage.objects;
create policy player_photos_insert_team on storage.objects for insert to authenticated with check (
 bucket_id='player-photos' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' and split_part(name,'/',2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then public.can_manage_player_photo(split_part(name,'/',1)::uuid,split_part(name,'/',2)::uuid) else false end
);
drop policy if exists player_photos_update_team on storage.objects;
create policy player_photos_update_team on storage.objects for update to authenticated
using (bucket_id='player-photos' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' and split_part(name,'/',2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then public.can_manage_player_photo(split_part(name,'/',1)::uuid,split_part(name,'/',2)::uuid) else false end)
with check (bucket_id='player-photos' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' and split_part(name,'/',2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then public.can_manage_player_photo(split_part(name,'/',1)::uuid,split_part(name,'/',2)::uuid) else false end);
drop policy if exists player_photos_delete_team on storage.objects;
create policy player_photos_delete_team on storage.objects for delete to authenticated using (
 bucket_id='player-photos' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' and split_part(name,'/',2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then public.can_manage_player_photo(split_part(name,'/',1)::uuid,split_part(name,'/',2)::uuid) else false end
);
commit;
