-- E05 / AP05 – Paket 6: Kontrollierter Widerruf einer Spieltagsausnahme
-- Ziel: Supabase DEV only (pzazqvvoruqnqhcorbwx)
-- Status: FREIGABEKANDIDAT – NICHT AUSFÜHREN VOR AUSDRÜCKLICHER FREIGABE
-- Abhängigkeit: Pakete 1–5.
-- Keine PROD-Änderungen.

begin;

-- 1. Harden the existing grant RPC and use a consistent per-player lock order.
--    A normal user must have an explicit trainer/admin role. A super admin
--    must have the global role AND the selected team context.
create or replace function public.grant_suspension_exception(
  p_suspension_id uuid,
  p_matchday_id uuid,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog,public,auth
as $function$
declare
  v_actor uuid := auth.uid();
  v_suspension public.training_suspensions%rowtype;
  v_matchday public.matchdays%rowtype;
  v_team_name text;
  v_player_name text;
  v_actor_name text;
  v_exception_id uuid;
  v_reassigned integer;
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_suspension_id is null or p_matchday_id is null
     or nullif(btrim(p_reason),'') is null then
    raise exception using errcode='22023',message='Suspension, matchday and reason are required';
  end if;

  select * into v_suspension
  from public.training_suspensions
  where id=p_suspension_id;
  if not found then
    raise exception using errcode='P0002',message='Suspension not found';
  end if;

  -- Lock player first. All grant/revoke operations for this player serialize
  -- before they lock suspension rows and recalculate their targets.
  if v_suspension.player_id is not null then
    perform 1 from public.players p where p.id=v_suspension.player_id for update;
  end if;

  select * into v_suspension
  from public.training_suspensions
  where id=p_suspension_id
  for update;
  if not found then
    raise exception using errcode='P0002',message='Suspension not found';
  end if;
  if v_suspension.status<>'open' then
    raise exception using errcode='23514',message='Only an open suspension can receive an exception';
  end if;

  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_suspension.team_id
      and r.user_id=v_actor and r.role in ('trainer','admin')
  ) and not (
    exists (
      select 1 from public.global_user_roles g
      where g.user_id=v_actor and g.role='super_admin'
    )
    and public.has_selected_team_context(v_suspension.team_id)
  ) then
    raise exception using errcode='42501',message='Team permission required';
  end if;

  select * into v_matchday
  from public.matchdays
  where id=p_matchday_id
  for update;
  if not found then
    raise exception using errcode='P0002',message='Matchday not found';
  end if;

  if v_matchday.team_id<>v_suspension.team_id
     or v_matchday.season_id is distinct from v_suspension.season_id
     or v_matchday.id is distinct from v_suspension.intended_matchday_id
     or v_matchday.status<>'planned' then
    raise exception using errcode='23514',
      message='Exception must refer to the currently assigned planned matchday in the same team and season';
  end if;

  select t.name into v_team_name from public.teams t where t.id=v_suspension.team_id;
  select p.name into v_player_name from public.players p where p.id=v_suspension.player_id;
  select pr.display_name into v_actor_name from public.profiles pr where pr.id=v_actor;

  insert into public.training_suspension_exceptions(
    suspension_id,team_id,team_name_snapshot,player_id,player_name_snapshot,
    matchday_id,matchday_date_snapshot,matchday_opponent_snapshot,
    reason,granted_by,granted_by_snapshot,granted_at
  ) values (
    v_suspension.id,v_suspension.team_id,coalesce(v_team_name,v_suspension.team_id::text),
    v_suspension.player_id,coalesce(v_player_name,v_suspension.player_name_snapshot),
    v_matchday.id,v_matchday.match_date,v_matchday.opponent,
    btrim(p_reason),v_actor,v_actor_name,now()
  ) returning id into v_exception_id;

  insert into public.training_suspension_audit(
    exception_id,action,old_values,new_values,reason,changed_by,changed_at
  ) values (
    v_exception_id,'exception_granted',null,
    jsonb_build_object(
      'suspension_id',v_suspension.id,
      'matchday_id',v_matchday.id,
      'matchday_date',v_matchday.match_date,
      'matchday_opponent',v_matchday.opponent,
      'reason',btrim(p_reason)
    ),
    btrim(p_reason),v_actor,now()
  );

  v_reassigned:=public.e05_assign_player_suspensions(
    v_suspension.team_id,v_suspension.player_id,v_actor
  );

  return v_exception_id;
end;
$function$;

revoke all on function public.grant_suspension_exception(uuid,uuid,text)
from public,anon,authenticated,service_role;
grant execute on function public.grant_suspension_exception(uuid,uuid,text)
to authenticated;

-- 2. Controlled revocation. The exception is revoked only while its original
--    matchday is still planned and has not passed. The suspension stays open.
create or replace function public.revoke_suspension_exception(
  p_exception_id uuid,
  p_revoke_reason text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog,public,auth
as $function$
declare
  v_actor uuid := auth.uid();
  v_exception public.training_suspension_exceptions%rowtype;
  v_suspension public.training_suspensions%rowtype;
  v_matchday public.matchdays%rowtype;
  v_actor_name text;
  v_old_values jsonb;
  v_new_values jsonb;
  v_reassigned integer := 0;
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_exception_id is null or nullif(btrim(p_revoke_reason),'') is null then
    raise exception using errcode='22023',message='Exception and non-empty revocation reason are required';
  end if;

  select * into v_exception
  from public.training_suspension_exceptions
  where id=p_exception_id;
  if not found then
    raise exception using errcode='P0002',message='Suspension exception not found';
  end if;

  -- Match the grant RPC lock order: player, suspension, exception, matchday.
  if v_exception.player_id is not null then
    perform 1 from public.players p where p.id=v_exception.player_id for update;
  end if;

  select * into v_suspension
  from public.training_suspensions
  where id=v_exception.suspension_id
  for update;
  if not found then
    raise exception using errcode='P0002',message='Related suspension not found';
  end if;

  select * into v_exception
  from public.training_suspension_exceptions
  where id=p_exception_id
  for update;
  if not found then
    raise exception using errcode='P0002',message='Suspension exception not found';
  end if;
  if v_exception.revoked_at is not null then
    raise exception using errcode='23514',message='Suspension exception has already been revoked';
  end if;
  if v_suspension.status<>'open' then
    raise exception using errcode='23514',message='Only an open suspension can have its exception revoked';
  end if;

  if v_suspension.team_id<>v_exception.team_id
     or v_suspension.player_id is distinct from v_exception.player_id then
    raise exception using errcode='23514',
      message='Exception and suspension ownership do not match';
  end if;

  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_exception.team_id
      and r.user_id=v_actor and r.role in ('trainer','admin')
  ) and not (
    exists (
      select 1 from public.global_user_roles g
      where g.user_id=v_actor and g.role='super_admin'
    )
    and public.has_selected_team_context(v_exception.team_id)
  ) then
    raise exception using errcode='42501',message='Team permission required';
  end if;

  select * into v_matchday
  from public.matchdays
  where id=v_exception.matchday_id
  for update;
  if not found then
    raise exception using errcode='P0002',message='Original matchday not found';
  end if;

  if v_matchday.team_id<>v_exception.team_id
     or v_matchday.season_id is distinct from v_suspension.season_id
     or v_matchday.status<>'planned'
     or v_matchday.match_date<current_date then
    raise exception using errcode='23514',
      message='An exception can only be revoked before its original matchday is held or has passed';
  end if;

  select pr.display_name into v_actor_name
  from public.profiles pr where pr.id=v_actor;

  v_old_values:=jsonb_build_object(
    'revoked_at',v_exception.revoked_at,
    'revoked_by',v_exception.revoked_by,
    'revoke_reason',v_exception.revoke_reason,
    'suspension_id',v_exception.suspension_id,
    'matchday_id',v_exception.matchday_id
  );

  update public.training_suspension_exceptions
  set revoked_by=v_actor,
      revoked_by_snapshot=v_actor_name,
      revoked_at=now(),
      revoke_reason=btrim(p_revoke_reason)
  where id=v_exception.id;

  v_new_values:=jsonb_build_object(
    'revoked_at',now(),
    'revoked_by',v_actor,
    'revoked_by_snapshot',v_actor_name,
    'revoke_reason',btrim(p_revoke_reason),
    'suspension_id',v_exception.suspension_id,
    'matchday_id',v_exception.matchday_id
  );

  insert into public.training_suspension_audit(
    exception_id,action,old_values,new_values,reason,changed_by,changed_at
  ) values (
    v_exception.id,'exception_revoked',v_old_values,v_new_values,
    btrim(p_revoke_reason),v_actor,now()
  );

  if v_suspension.player_id is not null then
    v_reassigned:=public.e05_assign_player_suspensions(
      v_suspension.team_id,v_suspension.player_id,v_actor
    );
  end if;

  return v_exception.id;
end;
$function$;

revoke all on function public.revoke_suspension_exception(uuid,text)
from public,anon,authenticated,service_role;
grant execute on function public.revoke_suspension_exception(uuid,text)
to authenticated;

commit;
