-- AP04: selected-club authorization and self-role protection for club membership changes.
create or replace function public.admin_add_club_member_by_email(p_club_id uuid,p_email text,p_role text default 'member')
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare v_user_id uuid;
begin
  if auth.uid() is null or not public.can_manage_club_context(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext' using errcode='42501';
  end if;
  if p_role not in ('member','club_admin') then raise exception 'Ungültige Vereinsrolle' using errcode='22023'; end if;
  if nullif(btrim(p_email),'') is null then raise exception 'E-Mail-Adresse fehlt' using errcode='22023'; end if;
  select u.id into v_user_id from auth.users u where lower(u.email)=lower(btrim(p_email)) limit 1;
  if v_user_id is null then raise exception 'Kein bestehendes Konto mit dieser E-Mail-Adresse gefunden. Bitte zuerst eine Einladung auslösen.' using errcode='P0002'; end if;
  perform public.admin_add_club_member(p_club_id,v_user_id,p_role);
end;
$function$;

create or replace function public.admin_set_club_member_role(p_club_id uuid,p_user_id uuid,p_role text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare v_admin_count integer;
begin
  if auth.uid() is null or not public.can_manage_club_context(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext' using errcode='42501';
  end if;
  if p_user_id=auth.uid() then raise exception 'Die eigene Vereinsrolle kann nicht geändert werden' using errcode='42501'; end if;
  if p_role not in ('member','club_admin') then raise exception 'Ungültige Vereinsrolle' using errcode='22023'; end if;
  perform 1 from public.clubs c where c.id=p_club_id for update;
  if not found then raise exception 'Verein nicht gefunden' using errcode='22023'; end if;
  if not exists(select 1 from public.club_members m where m.club_id=p_club_id and m.user_id=p_user_id) then
    raise exception 'Das Konto ist kein Mitglied dieses Vereins' using errcode='P0002';
  end if;
  if p_role='club_admin' then
    insert into public.club_member_roles(user_id,role) values(p_user_id,'club_admin') on conflict(user_id,role) do nothing;
  else
    if exists(select 1 from public.club_member_roles r where r.user_id=p_user_id and r.role='club_admin') then
      select count(*) into v_admin_count from public.club_members m join public.club_member_roles r on r.user_id=m.user_id and r.role='club_admin' where m.club_id=p_club_id;
      if v_admin_count<=1 then raise exception 'Der letzte Vereinsadmin kann nicht herabgestuft werden' using errcode='23514'; end if;
    end if;
    delete from public.club_member_roles r where r.user_id=p_user_id and r.role='club_admin';
  end if;
end;
$function$;
revoke all on function public.admin_add_club_member_by_email(uuid,text,text) from public;
revoke all on function public.admin_set_club_member_role(uuid,uuid,text) from public;
grant execute on function public.admin_add_club_member_by_email(uuid,text,text) to authenticated;
grant execute on function public.admin_set_club_member_role(uuid,uuid,text) to authenticated;
