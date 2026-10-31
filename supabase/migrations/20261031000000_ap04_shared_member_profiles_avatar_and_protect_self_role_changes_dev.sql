-- AP04 shared member profiles, avatar storage and role self-change protection.
-- Applied to Supabase DEV as migration ap04_shared_member_profiles_avatar_and_protect_self_role_changes_dev.
-- See docs/AP04-profile-management.md for scope, execution record and PROD cutover notes.
-- This source file mirrors the migration applied to DEV; do not run independently on PROD.
alter table public.profiles add column if not exists avatar_url text;
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('profile-avatars','profile-avatars',true,2097152,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

-- Profile-image paths are <user-uuid>/avatar.<extension>. Read is public via the public bucket;
-- writes require ownership or admin rights in a shared team / selected Super Admin team context.
drop policy if exists profile_avatars_insert_self_or_admin on storage.objects;
create policy profile_avatars_insert_self_or_admin on storage.objects for insert to authenticated
with check (bucket_id='profile-avatars' and split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
and (split_part(name,'/',1)::uuid=auth.uid()
or exists(select 1 from public.team_member_roles t join public.team_member_roles a on a.team_id=t.team_id and a.user_id=auth.uid() and a.role='admin' where t.user_id=split_part(name,'/',1)::uuid)
or (public.is_super_admin() and exists(select 1 from public.team_member_roles t where t.user_id=split_part(name,'/',1)::uuid and public.has_selected_team_context(t.team_id)))));

drop policy if exists profile_avatars_update_self_or_admin on storage.objects;
create policy profile_avatars_update_self_or_admin on storage.objects for update to authenticated
using (bucket_id='profile-avatars' and (split_part(name,'/',1)::uuid=auth.uid()
or exists(select 1 from public.team_member_roles t join public.team_member_roles a on a.team_id=t.team_id and a.user_id=auth.uid() and a.role='admin' where t.user_id=split_part(name,'/',1)::uuid)
or (public.is_super_admin() and exists(select 1 from public.team_member_roles t where t.user_id=split_part(name,'/',1)::uuid and public.has_selected_team_context(t.team_id)))))
with check (bucket_id='profile-avatars' and (split_part(name,'/',1)::uuid=auth.uid()
or exists(select 1 from public.team_member_roles t join public.team_member_roles a on a.team_id=t.team_id and a.user_id=auth.uid() and a.role='admin' where t.user_id=split_part(name,'/',1)::uuid)
or (public.is_super_admin() and exists(select 1 from public.team_member_roles t where t.user_id=split_part(name,'/',1)::uuid and public.has_selected_team_context(t.team_id)))));

drop policy if exists profile_avatars_delete_self_or_admin on storage.objects;
create policy profile_avatars_delete_self_or_admin on storage.objects for delete to authenticated
using (bucket_id='profile-avatars' and (split_part(name,'/',1)::uuid=auth.uid()
or exists(select 1 from public.team_member_roles t join public.team_member_roles a on a.team_id=t.team_id and a.user_id=auth.uid() and a.role='admin' where t.user_id=split_part(name,'/',1)::uuid)
or (public.is_super_admin() and exists(select 1 from public.team_member_roles t where t.user_id=split_part(name,'/',1)::uuid and public.has_selected_team_context(t.team_id)))));

create or replace function public.admin_update_member_profile(p_team_id uuid,p_user_id uuid,p_display_name text,p_avatar_url text)
returns void language plpgsql security definer set search_path=pg_catalog,public,auth as $function$
declare v_name text:=trim(coalesce(p_display_name,''));
begin
 if auth.uid() is null or not (public.is_team_admin(auth.uid(),p_team_id) or (public.is_super_admin() and public.has_selected_team_context(p_team_id))) then raise exception 'Nicht berechtigt' using errcode='42501'; end if;
 if p_user_id is null or not exists(select 1 from public.team_member_roles r where r.team_id=p_team_id and r.user_id=p_user_id) then raise exception 'Mitglied gehört nicht zur ausgewählten Mannschaft' using errcode='22023'; end if;
 if v_name='' then raise exception 'Name darf nicht leer sein' using errcode='22023'; end if;
 if p_avatar_url is not null and length(p_avatar_url)>2048 then raise exception 'Profilbild-Adresse ist ungültig' using errcode='22023'; end if;
 insert into public.profiles(id,display_name,avatar_url) values(p_user_id,v_name,p_avatar_url)
 on conflict(id) do update set display_name=excluded.display_name,avatar_url=excluded.avatar_url;
end;$function$;
revoke all on function public.admin_update_member_profile(uuid,uuid,text,text) from public,anon;
grant execute on function public.admin_update_member_profile(uuid,uuid,text,text) to authenticated;

-- Preserve existing membership/club checks and last-admin protection; add an explicit self-role guard.
create or replace function public.admin_add_team_role(p_team_id uuid,p_user_id uuid,p_role text)
returns void language plpgsql security definer set search_path=pg_catalog,public,auth as $function$
declare v_club_id uuid; v_existing_club_id uuid;
begin
 if auth.uid() is null or not (public.is_team_admin(auth.uid(),p_team_id) or (public.is_super_admin() and public.has_selected_team_context(p_team_id))) then raise exception 'Nicht berechtigt' using errcode='42501'; end if;
 if p_user_id=auth.uid() then raise exception 'Eigene Mannschaftsrollen können nicht geändert werden' using errcode='42501'; end if;
 if p_role not in ('admin','trainer') then raise exception 'Ungültige Teamrolle' using errcode='22023'; end if;
 if not exists(select 1 from auth.users u where u.id=p_user_id) then raise exception 'Benutzer nicht gefunden' using errcode='22023'; end if;
 select t.club_id into v_club_id from public.teams t where t.id=p_team_id;
 if not found then raise exception 'Mannschaft nicht gefunden' using errcode='22023'; end if;
 if v_club_id is not null then
  select cm.club_id into v_existing_club_id from public.club_members cm where cm.user_id=p_user_id;
  if v_existing_club_id is not null and v_existing_club_id<>v_club_id then raise exception 'Benutzer ist bereits einem anderen Verein zugeordnet' using errcode='23514'; end if;
  insert into public.club_members(user_id,club_id) values(p_user_id,v_club_id) on conflict(user_id) do nothing;
  if not exists(select 1 from public.club_members cm where cm.user_id=p_user_id and cm.club_id=v_club_id) then raise exception 'Vereinszugehörigkeit konnte nicht bestätigt werden' using errcode='23514'; end if;
 end if;
 insert into public.team_members(team_id,user_id,role) values(p_team_id,p_user_id,p_role) on conflict(team_id,user_id) do nothing;
 insert into public.team_member_roles(team_id,user_id,role) values(p_team_id,p_user_id,p_role) on conflict(team_id,user_id,role) do nothing;
end;$function$;

create or replace function public.admin_remove_team_role(p_team_id uuid,p_user_id uuid,p_role text)
returns void language plpgsql security definer set search_path=pg_catalog,public as $function$
declare v_admin_count integer;
begin
 if auth.uid() is null or not (public.is_team_admin(auth.uid(),p_team_id) or (public.is_super_admin() and public.has_selected_team_context(p_team_id))) then raise exception 'Nicht berechtigt' using errcode='42501'; end if;
 if p_user_id=auth.uid() then raise exception 'Eigene Mannschaftsrollen können nicht geändert werden' using errcode='42501'; end if;
 if p_role not in ('admin','trainer') then raise exception 'Ungültige Teamrolle' using errcode='22023'; end if;
 perform 1 from public.teams t where t.id=p_team_id for update;
 if not found then raise exception 'Mannschaft nicht gefunden'; end if;
 if p_role='admin' then
  select count(*) into v_admin_count from public.team_member_roles r where r.team_id=p_team_id and r.role='admin';
  if exists(select 1 from public.team_member_roles r where r.team_id=p_team_id and r.user_id=p_user_id and r.role='admin') and v_admin_count<=1 then raise exception 'Der letzte Team-Admin kann nicht entfernt werden' using errcode='23514'; end if;
 end if;
 delete from public.team_member_roles where team_id=p_team_id and user_id=p_user_id and role=p_role;
 if not exists(select 1 from public.team_member_roles r where r.team_id=p_team_id and r.user_id=p_user_id) then delete from public.team_members where team_id=p_team_id and user_id=p_user_id; end if;
end;$function$;
revoke all on function public.admin_add_team_role(uuid,uuid,text) from public,anon;
revoke all on function public.admin_remove_team_role(uuid,uuid,text) from public,anon;
grant execute on function public.admin_add_team_role(uuid,uuid,text) to authenticated;
grant execute on function public.admin_remove_team_role(uuid,uuid,text) to authenticated;
