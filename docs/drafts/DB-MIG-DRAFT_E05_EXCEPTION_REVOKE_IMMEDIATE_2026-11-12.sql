-- REVIEW DRAFT ONLY – NOT A SUPABASE MIGRATION
-- E05 / AP05 – immediate exception revocation and nomination serialization
-- Target if separately approved: Supabase DEV only.
-- NOT EXECUTED. No PROD/main changes.
--
-- Purpose:
-- 1) On revoking an exception, remove any current nomination for the same
--    player and original matchday in the same transaction.
-- 2) Serialize nomination inserts/updates against exception revocation by
--    locking the player row before the suspension check.
--
-- Important: review this complete draft against the live DEV schema and the
-- latest function definitions before any execution. This file is a proposal,
-- not an executable release package yet.

begin;

do $preflight$
begin
  if to_regprocedure('public.revoke_suspension_exception(uuid,text)') is null then
    raise exception 'Expected revoke_suspension_exception(uuid,text) is missing';
  end if;
  if to_regprocedure('public.prevent_suspended_matchday_nomination()') is null then
    raise exception 'Expected nomination guard trigger function is missing';
  end if;
  if to_regclass('public.matchday_players') is null
     or to_regclass('public.training_suspension_exceptions') is null
     or to_regclass('public.training_suspension_audit') is null then
    raise exception 'Required E05 tables are missing';
  end if;
  if not exists (
    select 1 from pg_trigger
    where tgrelid='public.matchday_players'::regclass
      and tgname='matchday_players_prevent_suspended_nomination'
      and not tgisinternal
  ) then
    raise exception 'Expected matchday nomination guard trigger is missing';
  end if;
end;
$preflight$;

-- Serialize direct/API nomination writes with the exception-revocation RPC.
-- The revoke RPC already takes the player row lock first. This matching lock
-- order closes the race in which a nomination could otherwise be inserted
-- while the exception is being revoked.
create or replace function public.prevent_suspended_matchday_nomination()
returns trigger
language plpgsql
set search_path to 'pg_catalog', 'public'
as $function$
declare
    v_team_id uuid;
    v_blocking_suspension_id uuid;
begin
    if tg_op = 'UPDATE'
       and new.matchday_id is not distinct from old.matchday_id
       and new.player_id is not distinct from old.player_id then
        return new;
    end if;

    -- Match the revoke RPC lock order: player first, then evaluate the
    -- matchday-specific suspension/exception state.
    perform 1
      from public.players p
     where p.id = new.player_id
     for update;

    if not found then
        raise exception
            'Der Spieler wurde nicht gefunden.'
            using errcode = '23503';
    end if;

    select m.team_id
      into v_team_id
      from public.matchdays m
     where m.id = new.matchday_id;

    if v_team_id is null then
        raise exception
            'Der ausgewählte Spieltag wurde nicht gefunden.'
            using errcode = '23503';
    end if;

    select s.id
      into v_blocking_suspension_id
      from public.training_suspensions s
     where s.team_id = v_team_id
       and s.player_id = new.player_id
       and s.status = 'open'
       and s.intended_matchday_id = new.matchday_id
       and not exists (
           select 1
             from public.training_suspension_exceptions e
            where e.suspension_id = s.id
              and e.matchday_id = new.matchday_id
              and e.revoked_at is null
       )
     order by s.created_at, s.id
     limit 1;

    if v_blocking_suspension_id is not null then
        raise exception
            'Nominierung nicht möglich: Für diesen Spieler besteht eine Sperre für diesen Spieltag. Bitte zuerst eine Ausnahme erteilen.'
            using errcode = '23514';
    end if;

    return new;
end;
$function$;

-- Preserve the current RPC contract, permission model, lock order, audit and
-- reassignment logic. The only functional addition is atomic removal of an
-- existing nomination for the exact matchday covered by the revoked exception.
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
  v_nomination_removed boolean := false;
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

  -- Lock order: player, suspension, exception, matchday.
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

  -- Remove only the current nomination for the exact matchday exception.
  -- This deletion and the revocation/audit/reassignment are one transaction.
  if v_exception.player_id is not null then
    delete from public.matchday_players
    where matchday_id=v_exception.matchday_id
      and player_id=v_exception.player_id
    returning true into v_nomination_removed;
  end if;

  v_new_values:=jsonb_build_object(
    'revoked_at',now(),
    'revoked_by',v_actor,
    'revoked_by_snapshot',v_actor_name,
    'revoke_reason',btrim(p_revoke_reason),
    'suspension_id',v_exception.suspension_id,
    'matchday_id',v_exception.matchday_id,
    'nomination_removed',v_nomination_removed
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

-- Keep the same explicit RPC exposure as the current DEV function.
revoke all on function public.revoke_suspension_exception(uuid,text)
from public,anon,service_role;
grant execute on function public.revoke_suspension_exception(uuid,text)
to authenticated;

-- Trigger functions are not API endpoints.
revoke all on function public.prevent_suspended_matchday_nomination()
from public,anon,authenticated,service_role;

commit;

-- Postflight checks to run separately after a separately approved execution:
-- 1) inspect pg_get_functiondef() for both updated functions;
-- 2) inspect EXECUTE ACLs on revoke_suspension_exception;
-- 3) confirm the trigger remains attached to INSERT/UPDATE OF matchday_id,player_id;
-- 4) run the approved DEV positive/negative and concurrency test matrix.
