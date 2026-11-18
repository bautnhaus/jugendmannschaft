-- Epic 23 – Paket 1: Nominierungsvormerkung (PROD)
-- Prepared: 2026-11-17
-- Target: Supabase PROD (qdugtpzgefpswnnqbusd)
-- STATUS: PREPARED FOR PROD; NOT EXECUTED.
-- Creates reminder/audit tables, controlled RPCs and fulfillment trigger.
-- No frontend changes. PROD release file; not yet executed.

begin;

do $preflight$
begin
  if to_regclass('public.players') is null
     or to_regclass('public.teams') is null
     or to_regclass('public.matchdays') is null
     or to_regclass('public.matchday_players') is null
     or to_regclass('public.team_member_roles') is null
     or to_regclass('public.global_user_roles') is null
     or to_regclass('public.profiles') is null then
    raise exception 'Epic 23 Paket 1: required base tables missing';
  end if;
  if to_regprocedure('public.has_selected_team_context(uuid)') is null then
    raise exception 'Epic 23 Paket 1: selected team context helper missing';
  end if;
  if to_regclass('public.matchday_nomination_reminders') is not null
     or to_regclass('public.matchday_nomination_reminder_audit') is not null
     or to_regprocedure('public.create_matchday_nomination_reminder(uuid,uuid,text,boolean)') is not null
     or to_regprocedure('public.cancel_matchday_nomination_reminder(uuid,text)') is not null
     or to_regprocedure('public.epic23_fulfill_nomination_reminder()') is not null
     or to_regprocedure('public.epic23_reject_nomination_reminder_audit_mutation()') is not null then
    raise exception 'Epic 23 Paket 1: one or more target objects already exist; manual reconciliation required';
  end if;
end;
$preflight$;

create table public.matchday_nomination_reminders (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  team_name_snapshot text not null,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null check (nullif(btrim(player_name_snapshot),'') is not null),
  source_matchday_id uuid references public.matchdays(id) on delete set null,
  source_matchday_date_snapshot date not null,
  source_matchday_opponent_snapshot text,
  source_nomination_snapshot jsonb,
  status text not null default 'pending'
    check (status in ('pending','fulfilled','cancelled')),
  reason text not null check (nullif(btrim(reason),'') is not null),
  created_by uuid references auth.users(id) on delete set null,
  created_by_snapshot text,
  created_at timestamptz not null default now(),
  fulfilled_matchday_id uuid references public.matchdays(id) on delete set null,
  fulfilled_matchday_date_snapshot date,
  fulfilled_at timestamptz,
  cancelled_by uuid references auth.users(id) on delete set null,
  cancelled_by_snapshot text,
  cancelled_at timestamptz,
  cancel_reason text,
  constraint matchday_nomination_reminders_state_check check (
    (status='pending' and fulfilled_at is null and fulfilled_matchday_id is null
      and cancelled_at is null and cancelled_by is null and cancel_reason is null)
    or
    (status='fulfilled' and fulfilled_at is not null and fulfilled_matchday_id is not null
      and cancelled_at is null and cancelled_by is null and cancel_reason is null)
    or
    (status='cancelled' and fulfilled_at is null and fulfilled_matchday_id is null
      and cancelled_at is not null and nullif(btrim(cancel_reason),'') is not null)
  )
);

create unique index matchday_nomination_reminders_one_pending_per_player_team
  on public.matchday_nomination_reminders(team_id,player_id)
  where status='pending' and player_id is not null;
create index matchday_nomination_reminders_team_status_created_idx
  on public.matchday_nomination_reminders(team_id,status,created_at desc);
create index matchday_nomination_reminders_source_matchday_idx
  on public.matchday_nomination_reminders(source_matchday_id);
create index matchday_nomination_reminders_fulfilled_matchday_idx
  on public.matchday_nomination_reminders(fulfilled_matchday_id)
  where fulfilled_matchday_id is not null;

create table public.matchday_nomination_reminder_audit (
  id uuid primary key default gen_random_uuid(),
  reminder_id uuid not null references public.matchday_nomination_reminders(id) on delete restrict,
  action text not null check (action in ('created','fulfilled','cancelled')),
  old_values jsonb,
  new_values jsonb not null,
  reason text not null check (nullif(btrim(reason),'') is not null),
  changed_by uuid references auth.users(id) on delete set null,
  changed_by_snapshot text,
  changed_at timestamptz not null default now()
);
create index matchday_nomination_reminder_audit_reminder_idx
  on public.matchday_nomination_reminder_audit(reminder_id,changed_at desc);

alter table public.matchday_nomination_reminders enable row level security;
alter table public.matchday_nomination_reminder_audit enable row level security;

revoke all on public.matchday_nomination_reminders from anon,authenticated;
revoke all on public.matchday_nomination_reminder_audit from anon,authenticated;
grant select on public.matchday_nomination_reminders to authenticated;
grant select on public.matchday_nomination_reminder_audit to authenticated;

create policy matchday_nomination_reminders_select_team
on public.matchday_nomination_reminders for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy matchday_nomination_reminder_audit_select_team
on public.matchday_nomination_reminder_audit for select to authenticated
using (
  exists (
    select 1 from public.matchday_nomination_reminders r
    where r.id=reminder_id
      and (public.is_team_member(r.team_id) or public.has_selected_team_context(r.team_id))
  )
);

create or replace function public.epic23_reject_nomination_reminder_audit_mutation()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public
as $function$
begin
  raise exception 'Nomination reminder audit is append-only';
end;
$function$;
revoke all on function public.epic23_reject_nomination_reminder_audit_mutation()
from public,anon,authenticated,service_role;

create trigger matchday_nomination_reminder_audit_no_mutation
before update or delete or truncate on public.matchday_nomination_reminder_audit
for each statement execute function public.epic23_reject_nomination_reminder_audit_mutation();

-- Controlled creation. If the player is currently nominated on the source
-- matchday, that exact row is snapshotted and removed in the same transaction.
-- A nomination on another future matchday does NOT block creation and does NOT
-- fulfill this newly-created reminder.
create or replace function public.create_matchday_nomination_reminder(
  p_source_matchday_id uuid,
  p_player_id uuid,
  p_reason text,
  p_confirmed_available boolean
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_actor uuid:=auth.uid();
  v_matchday public.matchdays%rowtype;
  v_player public.players%rowtype;
  v_nomination public.matchday_players%rowtype;
  v_has_nomination boolean:=false;
  v_snapshot jsonb;
  v_team_name text;
  v_actor_name text;
  v_reminder_id uuid;
  v_now timestamptz:=now();
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_source_matchday_id is null or p_player_id is null
     or nullif(btrim(p_reason),'') is null
     or p_confirmed_available is distinct from true then
    raise exception using errcode='22023',
      message='Spieltag, Spieler, Verfügbarkeitsbestätigung und Begründung sind erforderlich.';
  end if;

  -- Same per-player advisory-lock key as the existing suspension nomination guard.
  perform pg_advisory_xact_lock(hashtextextended(p_player_id::text,0));

  select * into v_matchday
  from public.matchdays where id=p_source_matchday_id for update;
  if not found then
    raise exception using errcode='P0002',message='Ausgangsspieltag nicht gefunden.';
  end if;

  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_matchday.team_id and r.user_id=v_actor
      and r.role in ('trainer','admin')
  ) and not (
    exists(select 1 from public.global_user_roles g
      where g.user_id=v_actor and g.role='super_admin')
    and public.has_selected_team_context(v_matchday.team_id)
  ) then
    raise exception using errcode='42501',message='Keine Berechtigung für diese Mannschaft.';
  end if;

  if v_matchday.status is distinct from 'planned'
     or v_matchday.match_date<current_date then
    raise exception using errcode='23514',message='Nur ein geplanter, nicht vergangener Ausgangsspieltag ist zulässig.';
  end if;

  select * into v_player
  from public.players
  where id=p_player_id and team_id=v_matchday.team_id
  for update;
  if not found or v_player.active is not true then
    raise exception using errcode='23514',message='Der Spieler muss aktiv sein und zur Mannschaft gehören.';
  end if;

  select * into v_nomination
  from public.matchday_players
  where matchday_id=v_matchday.id and player_id=v_player.id
  for update;
  v_has_nomination:=found;

  if v_has_nomination and v_nomination.available is not true then
    raise exception using errcode='23514',message='Ein als nicht verfügbar markierter Spieler kann nicht vorgemerkt werden.';
  end if;

  if v_has_nomination and v_nomination.played is true then
    raise exception using errcode='23514',message='Ein bereits als eingesetzt markierter Spieler kann nicht aus dem Spieltagskader entfernt werden.';
  end if;

  if exists (
    select 1 from public.matchday_nomination_reminders r
    where r.team_id=v_matchday.team_id and r.player_id=v_player.id and r.status='pending'
  ) then
    raise exception using errcode='23505',message='Für diesen Spieler besteht bereits eine offene Nominierungsvormerkung.';
  end if;

  if v_has_nomination then
    v_snapshot:=to_jsonb(v_nomination);
  end if;

  select name into v_team_name from public.teams where id=v_matchday.team_id;
  select display_name into v_actor_name from public.profiles where id=v_actor;

  insert into public.matchday_nomination_reminders(
    team_id,team_name_snapshot,player_id,player_name_snapshot,
    source_matchday_id,source_matchday_date_snapshot,source_matchday_opponent_snapshot,
    source_nomination_snapshot,status,reason,created_by,created_by_snapshot,created_at
  ) values (
    v_matchday.team_id,coalesce(v_team_name,v_matchday.team_id::text),
    v_player.id,v_player.name,v_matchday.id,v_matchday.match_date,v_matchday.opponent,
    v_snapshot,'pending',btrim(p_reason),v_actor,v_actor_name,v_now
  ) returning id into v_reminder_id;

  if v_has_nomination then
    delete from public.matchday_players
    where matchday_id=v_matchday.id and player_id=v_player.id;
  end if;

  insert into public.matchday_nomination_reminder_audit(
    reminder_id,action,old_values,new_values,reason,changed_by,changed_by_snapshot,changed_at
  ) values (
    v_reminder_id,'created',null,
    jsonb_build_object(
      'status','pending','team_id',v_matchday.team_id,'player_id',v_player.id,
      'source_matchday_id',v_matchday.id,'source_matchday_date',v_matchday.match_date,
      'source_nomination_removed',v_has_nomination
    ),btrim(p_reason),v_actor,v_actor_name,v_now
  );
  return v_reminder_id;
end;
$function$;

revoke all on function public.create_matchday_nomination_reminder(uuid,uuid,text,boolean)
from public,anon,authenticated,service_role;
grant execute on function public.create_matchday_nomination_reminder(uuid,uuid,text,boolean)
to authenticated;

create or replace function public.cancel_matchday_nomination_reminder(
  p_reminder_id uuid,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_actor uuid:=auth.uid();
  v_reminder public.matchday_nomination_reminders%rowtype;
  v_actor_name text;
  v_now timestamptz:=now();
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_reminder_id is null or nullif(btrim(p_reason),'') is null then
    raise exception using errcode='22023',message='Vormerkung und Rücknahmebegründung sind erforderlich.';
  end if;

  select * into v_reminder
  from public.matchday_nomination_reminders
  where id=p_reminder_id for update;
  if not found then
    raise exception using errcode='P0002',message='Nominierungsvormerkung nicht gefunden.';
  end if;

  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_reminder.team_id and r.user_id=v_actor
      and r.role in ('trainer','admin')
  ) and not (
    exists(select 1 from public.global_user_roles g
      where g.user_id=v_actor and g.role='super_admin')
    and public.has_selected_team_context(v_reminder.team_id)
  ) then
    raise exception using errcode='42501',message='Keine Berechtigung für diese Mannschaft.';
  end if;

  if v_reminder.status<>'pending' then
    raise exception using errcode='23514',message='Nur eine offene Vormerkung kann zurückgenommen werden.';
  end if;

  select display_name into v_actor_name from public.profiles where id=v_actor;
  update public.matchday_nomination_reminders
  set status='cancelled',cancelled_by=v_actor,cancelled_by_snapshot=v_actor_name,
      cancelled_at=v_now,cancel_reason=btrim(p_reason)
  where id=v_reminder.id;

  insert into public.matchday_nomination_reminder_audit(
    reminder_id,action,old_values,new_values,reason,changed_by,changed_by_snapshot,changed_at
  ) values (
    v_reminder.id,'cancelled',
    jsonb_build_object('status','pending'),
    jsonb_build_object('status','cancelled','cancelled_by',v_actor,
      'cancelled_by_snapshot',v_actor_name,'cancelled_at',v_now,'cancel_reason',btrim(p_reason)),
    btrim(p_reason),v_actor,v_actor_name,v_now
  );
  return v_reminder.id;
end;
$function$;

revoke all on function public.cancel_matchday_nomination_reminder(uuid,text)
from public,anon,authenticated,service_role;
grant execute on function public.cancel_matchday_nomination_reminder(uuid,text)
to authenticated;

-- Fulfill only for a nomination event occurring after reminder creation,
-- for a later matchday of the same team. Historical nominations are untouched.
create or replace function public.epic23_fulfill_nomination_reminder()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_team_id uuid;
  v_match_date date;
  v_actor uuid:=auth.uid();
  v_reminder record;
  v_actor_name text;
  v_now timestamptz:=now();
begin
  if tg_op='UPDATE'
     and new.matchday_id is not distinct from old.matchday_id
     and new.player_id is not distinct from old.player_id then
    return new;
  end if;

  select m.team_id,m.match_date into v_team_id,v_match_date
  from public.matchdays m where m.id=new.matchday_id;
  if v_team_id is null then return new; end if;

  select display_name into v_actor_name from public.profiles where id=v_actor;

  for v_reminder in
    select r.*
    from public.matchday_nomination_reminders r
    where r.team_id=v_team_id
      and r.player_id=new.player_id
      and r.status='pending'
      and r.created_at < v_now
      and v_match_date > r.source_matchday_date_snapshot
    for update
  loop
    update public.matchday_nomination_reminders
    set status='fulfilled',fulfilled_matchday_id=new.matchday_id,
        fulfilled_matchday_date_snapshot=v_match_date,fulfilled_at=v_now
    where id=v_reminder.id;

    insert into public.matchday_nomination_reminder_audit(
      reminder_id,action,old_values,new_values,reason,changed_by,changed_by_snapshot,changed_at
    ) values (
      v_reminder.id,'fulfilled',
      jsonb_build_object('status','pending'),
      jsonb_build_object('status','fulfilled','fulfilled_matchday_id',new.matchday_id,
        'fulfilled_matchday_date',v_match_date,'fulfilled_at',v_now),
      'Automatisch erfüllt: Spieler wurde nach Erstellung der Vormerkung für einen späteren Spieltag nominiert.',
      v_actor,v_actor_name,v_now
    );
  end loop;
  return new;
end;
$function$;
revoke all on function public.epic23_fulfill_nomination_reminder()
from public,anon,authenticated,service_role;

create trigger matchday_players_fulfill_nomination_reminder
after insert or update of matchday_id,player_id on public.matchday_players
for each row execute function public.epic23_fulfill_nomination_reminder();

commit;
