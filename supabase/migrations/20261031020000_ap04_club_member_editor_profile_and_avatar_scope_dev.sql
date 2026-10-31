-- AP04: Club-context profile editing for existing members; DEV only.
create or replace function public.admin_update_club_member_profile(
  p_club_id uuid, p_user_id uuid, p_display_name text, p_avatar_url text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
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
revoke all on function public.admin_update_club_member_profile(uuid,uuid,text,text) from public;
grant execute on function public.admin_update_club_member_profile(uuid,uuid,text,text) to authenticated;

drop policy if exists profile_avatars_insert_self_or_admin on storage.objects;
create policy profile_avatars_insert_self_or_admin on storage.objects for insert to authenticated
with check (bucket_id='profile-avatars' and case
 when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then (split_part(name,'/',1)::uuid=auth.uid() or exists(select 1 from public.club_members target where target.user_id=split_part(name,'/',1)::uuid and public.can_manage_club_context(target.club_id)))
 else false end);

drop policy if exists profile_avatars_update_self_or_admin on storage.objects;
create policy profile_avatars_update_self_or_admin on storage.objects for update to authenticated
using (bucket_id='profile-avatars' and case
 when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then (split_part(name,'/',1)::uuid=auth.uid() or exists(select 1 from public.club_members target where target.user_id=split_part(name,'/',1)::uuid and public.can_manage_club_context(target.club_id)))
 else false end)
with check (bucket_id='profile-avatars' and case
 when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then (split_part(name,'/',1)::uuid=auth.uid() or exists(select 1 from public.club_members target where target.user_id=split_part(name,'/',1)::uuid and public.can_manage_club_context(target.club_id)))
 else false end);

drop policy if exists profile_avatars_delete_self_or_admin on storage.objects;
create policy profile_avatars_delete_self_or_admin on storage.objects for delete to authenticated
using (bucket_id='profile-avatars' and case
 when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
 then (split_part(name,'/',1)::uuid=auth.uid() or exists(select 1 from public.club_members target where target.user_id=split_part(name,'/',1)::uuid and public.can_manage_club_context(target.club_id)))
 else false end);
