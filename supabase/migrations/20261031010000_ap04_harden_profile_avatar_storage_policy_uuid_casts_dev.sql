-- AP04 hardening follow-up migration.
-- Makes all UUID casts in profile-avatar Storage RLS policies safe for arbitrary object names.
drop policy if exists profile_avatars_insert_self_or_admin on storage.objects;
create policy profile_avatars_insert_self_or_admin on storage.objects for insert to authenticated
with check (bucket_id='profile-avatars' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then (
split_part(name,'/',1)::uuid=auth.uid()
or exists(select 1 from public.team_member_roles t join public.team_member_roles a on a.team_id=t.team_id and a.user_id=auth.uid() and a.role='admin' where t.user_id=split_part(name,'/',1)::uuid)
or (public.is_super_admin() and exists(select 1 from public.team_member_roles t where t.user_id=split_part(name,'/',1)::uuid and public.has_selected_team_context(t.team_id)))
) else false end);
drop policy if exists profile_avatars_update_self_or_admin on storage.objects;
create policy profile_avatars_update_self_or_admin on storage.objects for update to authenticated
using (bucket_id='profile-avatars' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then (
split_part(name,'/',1)::uuid=auth.uid()
or exists(select 1 from public.team_member_roles t join public.team_member_roles a on a.team_id=t.team_id and a.user_id=auth.uid() and a.role='admin' where t.user_id=split_part(name,'/',1)::uuid)
or (public.is_super_admin() and exists(select 1 from public.team_member_roles t where t.user_id=split_part(name,'/',1)::uuid and public.has_selected_team_context(t.team_id)))
) else false end)
with check (bucket_id='profile-avatars' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then (
split_part(name,'/',1)::uuid=auth.uid()
or exists(select 1 from public.team_member_roles t join public.team_member_roles a on a.team_id=t.team_id and a.user_id=auth.uid() and a.role='admin' where t.user_id=split_part(name,'/',1)::uuid)
or (public.is_super_admin() and exists(select 1 from public.team_member_roles t where t.user_id=split_part(name,'/',1)::uuid and public.has_selected_team_context(t.team_id)))
) else false end);
drop policy if exists profile_avatars_delete_self_or_admin on storage.objects;
create policy profile_avatars_delete_self_or_admin on storage.objects for delete to authenticated
using (bucket_id='profile-avatars' and case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then (
split_part(name,'/',1)::uuid=auth.uid()
or exists(select 1 from public.team_member_roles t join public.team_member_roles a on a.team_id=t.team_id and a.user_id=auth.uid() and a.role='admin' where t.user_id=split_part(name,'/',1)::uuid)
or (public.is_super_admin() and exists(select 1 from public.team_member_roles t where t.user_id=split_part(name,'/',1)::uuid and public.has_selected_team_context(t.team_id)))
) else false end);
