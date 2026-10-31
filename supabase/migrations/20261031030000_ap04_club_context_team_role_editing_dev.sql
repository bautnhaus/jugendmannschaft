-- AP04: permit club admins and superadmins in selected club context to manage team roles.
create or replace function public.admin_add_team_role(p_team_id uuid, p_user_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare v_club_id uuid; v_existing_club_id uuid;
begin
  select t.club_id into v_club_id from public.teams t where t.id=p_team_id;
  if not found then raise exception 'Mannschaft nicht gefunden' using errcode='22023'; end if;
  if auth.uid() is null or not (
    public.is_team_admin(auth.uid(),p_team_id)
    or (v_club_id is not null and public.can_manage_club_context(v_club_id))
    or (public.is_super_admin() and public.has_selected_team_context(p_team_id))
  ) then raise exception 'Nicht berechtigt oder kein passender Vereins-/Mannschaftskontext' using errcode='42501'; end if;
  if p_user_id=auth.uid() then raise exception 'Eigene Mannschaftsrollen können nicht geändert werden' using errcode='42501'; end if;
  if p_role not in ('admin','trainer') then raise exception 'Ungültige Teamrolle' using errcode='22023'; end if;
  if not exists(select 1 from auth.users u where u.id=p_user_id) then raise exception 'Benutzer nicht gefunden' using errcode='22023'; end if;
  if v_club_id is not null then
    select cm.club_id into v_existing_club_id from public.club_members cm where cm.user_id=p_user_id;
    if v_existing_club_id is not null and v_existing_club_id<>v_club_id then raise exception 'Benutzer ist bereits einem anderen Verein zugeordnet' using errcode='23514'; end if;
    insert into public.club_members(user_id,club_id) values(p_user_id,v_club_id) on conflict(user_id) do nothing;
    if not exists(select 1 from public.club_members cm where cm.user_id=p_user_id and cm.club_id=v_club_id) then raise exception 'Vereinszugehörigkeit konnte nicht bestätigt werden' using errcode='23514'; end if;
  end if;
  insert into public.team_members(team_id,user_id,role) values(p_team_id,p_user_id,p_role) on conflict(team_id,user_id) do nothing;
  insert into public.team_member_roles(team_id,user_id,role) values(p_team_id,p_user_id,p_role) on conflict(team_id,user_id,role) do nothing;
end;
$function$;

create or replace function public.admin_remove_team_role(p_team_id uuid, p_user_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
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

revoke all on function public.admin_add_team_role(uuid,uuid,text) from public;
revoke all on function public.admin_remove_team_role(uuid,uuid,text) from public;
grant execute on function public.admin_add_team_role(uuid,uuid,text) to authenticated;
grant execute on function public.admin_remove_team_role(uuid,uuid,text) to authenticated;
