-- E05 / AP05 – Paket 8: Vorzeitiger Sperrausgleich
-- Target: Supabase DEV only (pzazqvvoruqnqhcorbwx)
-- Status: REVIEW PACKAGE – NOT APPROVED – DO NOT EXECUTE
-- PROD is out of scope.

begin;

-- 1) Immutable history of an optional early suspension-equivalent reset.
create table public.matchday_early_suspension_resets (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null,
  team_name_snapshot text not null,
  season_id uuid not null,
  season_name_snapshot text not null,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null check (nullif(btrim(player_name_snapshot),'') is not null),
  matchday_id uuid not null,
  matchday_date_snapshot date not null,
  matchday_opponent_snapshot text,
  status text not null default 'pending'
    check (status in ('pending','applied','cancelled')),
  reason text not null check (nullif(btrim(reason),'') is not null),
  created_by uuid references auth.users(id) on delete set null,
  created_by_snapshot text,
  created_at timestamptz not null default now(),
  applied_at timestamptz,
  cancelled_by uuid references auth.users(id) on delete set null,
  cancelled_by_snapshot text,
  cancelled_at timestamptz,
  cancel_reason text,
  constraint matchday_early_suspension_resets_state_check check (
    (status='pending' and applied_at is null and cancelled_at is null
      and cancelled_by is null and cancel_reason is null)
    or
    (status='applied' and applied_at is not null and cancelled_at is null
      and cancelled_by is null and cancel_reason is null)
    or
    (status='cancelled' and applied_at is null and cancelled_at is not null
      and nullif(btrim(cancel_reason),'') is not null)
  )
);

create unique index matchday_early_suspension_resets_one_live_per_player_matchday
  on public.matchday_early_suspension_resets(matchday_id,player_id)
  where status in ('pending','applied');
create index matchday_early_suspension_resets_player_season_idx
  on public.matchday_early_suspension_resets(team_id,season_id,player_id,created_at desc);

create table public.matchday_early_suspension_reset_audit (
  id uuid primary key default gen_random_uuid(),
  reset_id uuid not null references public.matchday_early_suspension_resets(id) on delete restrict,
  action text not null check (action in ('created','applied','cancelled')),
  old_values jsonb,
  new_values jsonb not null,
  reason text not null check (nullif(btrim(reason),'') is not null),
  changed_by uuid references auth.users(id) on delete set null,
  changed_by_snapshot text,
  changed_at timestamptz not null default now()
);
create index matchday_early_suspension_reset_audit_reset_idx
  on public.matchday_early_suspension_reset_audit(reset_id,changed_at desc);

alter table public.matchday_early_suspension_resets enable row level security;
alter table public.matchday_early_suspension_reset_audit enable row level security;

revoke all on public.matchday_early_suspension_resets from anon,authenticated;
revoke all on public.matchday_early_suspension_reset_audit from anon,authenticated;
grant select on public.matchday_early_suspension_resets to authenticated;
grant select on public.matchday_early_suspension_reset_audit to authenticated;

create policy matchday_early_suspension_resets_select_team
on public.matchday_early_suspension_resets for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy matchday_early_suspension_reset_audit_select_team
on public.matchday_early_suspension_reset_audit for select to authenticated
using (
  exists (
    select 1 from public.matchday_early_suspension_resets r
    where r.id=reset_id
      and (public.is_team_member(r.team_id) or public.has_selected_team_context(r.team_id))
  )
);

create or replace function public.e05_reject_early_reset_audit_mutation()
returns trigger language plpgsql security definer
set search_path=pg_catalog,public
as $function$
begin
  raise exception 'Early reset audit is append-only';
end;
$function$;

revoke all on function public.e05_reject_early_reset_audit_mutation()
from public,anon,authenticated,service_role;

create trigger matchday_early_suspension_reset_audit_no_mutation
before update or delete or truncate on public.matchday_early_suspension_reset_audit
for each statement execute function public.e05_reject_early_reset_audit_mutation();

-- 2) Internal state transition helper. Only pending records can transition.
create or replace function public.e05_transition_early_reset(
  p_reset_id uuid,
  p_target_status text,
  p_reason text,
  p_actor uuid
) returns boolean
language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_reset public.matchday_early_suspension_resets%rowtype;
  v_actor_name text;
  v_old jsonb;
  v_new jsonb;
  v_now timestamptz:=now();
begin
  if p_target_status not in ('applied','cancelled')
     or nullif(btrim(p_reason),'') is null then
    raise exception using errcode='22023',message='Valid target state and reason required';
  end if;

  select * into v_reset
  from public.matchday_early_suspension_resets
  where id=p_reset_id
  for update;

  if not found then
    raise exception using errcode='P0002',message='Early reset not found';
  end if;

  if v_reset.status<>'pending' then
    return false;
  end if;

  select pr.display_name into v_actor_name
  from public.profiles pr where pr.id=p_actor;

  v_old:=jsonb_build_object(
    'status',v_reset.status,'applied_at',v_reset.applied_at,
    'cancelled_at',v_reset.cancelled_at,'cancel_reason',v_reset.cancel_reason
  );

  if p_target_status='applied' then
    update public.matchday_early_suspension_resets
    set status='applied',applied_at=v_now
    where id=p_reset_id;
    v_new:=jsonb_build_object('status','applied','applied_at',v_now);
  else
    update public.matchday_early_suspension_resets
    set status='cancelled',cancelled_by=p_actor,
        cancelled_by_snapshot=v_actor_name,cancelled_at=v_now,
        cancel_reason=btrim(p_reason)
    where id=p_reset_id;
    v_new:=jsonb_build_object(
      'status','cancelled','cancelled_by',p_actor,
      'cancelled_by_snapshot',v_actor_name,'cancelled_at',v_now,
      'cancel_reason',btrim(p_reason)
    );
  end if;

  insert into public.matchday_early_suspension_reset_audit(
    reset_id,action,old_values,new_values,reason,changed_by,changed_by_snapshot,changed_at
  ) values (
    p_reset_id,p_target_status,v_old,v_new,btrim(p_reason),p_actor,v_actor_name,v_now
  );
  return true;
end;
$function$;

revoke all on function public.e05_transition_early_reset(uuid,text,text,uuid)
from public,anon,authenticated,service_role;

-- 3) Explicit scheduling RPC.
create or replace function public.schedule_early_suspension_reset(
  p_matchday_id uuid,
  p_player_id uuid,
  p_reason text
) returns uuid
language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_actor uuid:=auth.uid();
  v_matchday public.matchdays%rowtype;
  v_player public.players%rowtype;
  v_season_name text;
  v_team_name text;
  v_actor_name text;
  v_reset_id uuid;
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_matchday_id is null or p_player_id is null
     or nullif(btrim(p_reason),'') is null then
    raise exception using errcode='22023',message='Matchday, player and reason are required';
  end if;

  select * into v_matchday from public.matchdays
  where id=p_matchday_id for update;
  if not found then
    raise exception using errcode='P0002',message='Matchday not found';
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
    raise exception using errcode='42501',message='Team trainer/admin permission required';
  end if;

  if v_matchday.status is distinct from 'planned'
     or v_matchday.match_date<current_date then
    raise exception using errcode='23514',message='Only a future planned matchday can receive an early reset';
  end if;

  if v_matchday.season_id is null then
    raise exception using errcode='23514',message='Matchday must belong to a season';
  end if;

  select * into v_player from public.players
  where id=p_player_id and team_id=v_matchday.team_id
  for update;
  if not found or v_player.active is not true then
    raise exception using errcode='23514',message='Player must be active and belong to the matchday team';
  end if;

  if not exists (
    select 1 from public.seasons s
    where s.id=v_matchday.season_id and s.team_id=v_matchday.team_id
      and s.is_active is true
  ) then
    raise exception using errcode='23514',message='Matchday season must be active for its team';
  end if;

  if exists (
    select 1 from public.matchday_players mp
    where mp.matchday_id=v_matchday.id and mp.player_id=v_player.id
  ) then
    raise exception using errcode='23514',message='A nominated player cannot receive an early reset';
  end if;

  select name into v_team_name from public.teams where id=v_matchday.team_id;
  select name into v_season_name from public.seasons where id=v_matchday.season_id;
  select display_name into v_actor_name from public.profiles where id=v_actor;

  insert into public.matchday_early_suspension_resets(
    team_id,team_name_snapshot,season_id,season_name_snapshot,
    player_id,player_name_snapshot,matchday_id,matchday_date_snapshot,
    matchday_opponent_snapshot,status,reason,created_by,created_by_snapshot
  ) values (
    v_matchday.team_id,coalesce(v_team_name,v_matchday.team_id::text),
    v_matchday.season_id,v_season_name,v_player.id,v_player.name,
    v_matchday.id,v_matchday.match_date,v_matchday.opponent,
    'pending',btrim(p_reason),v_actor,v_actor_name
  ) returning id into v_reset_id;

  insert into public.matchday_early_suspension_reset_audit(
    reset_id,action,old_values,new_values,reason,changed_by,changed_by_snapshot
  ) values (
    v_reset_id,'created',null,
    jsonb_build_object(
      'status','pending','team_id',v_matchday.team_id,
      'season_id',v_matchday.season_id,'player_id',v_player.id,
      'matchday_id',v_matchday.id,'matchday_date',v_matchday.match_date,
      'reason',btrim(p_reason)
    ),btrim(p_reason),v_actor,v_actor_name
  );

  return v_reset_id;
end;
$function$;

-- 4) Explicit cancellation RPC (manual cancellation before the matchday).
create or replace function public.cancel_early_suspension_reset(
  p_reset_id uuid,
  p_reason text
) returns uuid
language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_actor uuid:=auth.uid();
  v_reset public.matchday_early_suspension_resets%rowtype;
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_reset_id is null or nullif(btrim(p_reason),'') is null then
    raise exception using errcode='22023',message='Reset and cancellation reason are required';
  end if;

  select * into v_reset from public.matchday_early_suspension_resets
  where id=p_reset_id for update;
  if not found then
    raise exception using errcode='P0002',message='Early reset not found';
  end if;

  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_reset.team_id and r.user_id=v_actor
      and r.role in ('trainer','admin')
  ) and not (
    exists(select 1 from public.global_user_roles g
      where g.user_id=v_actor and g.role='super_admin')
    and public.has_selected_team_context(v_reset.team_id)
  ) then
    raise exception using errcode='42501',message='Team trainer/admin permission required';
  end if;

  if v_reset.status<>'pending' then
    raise exception using errcode='23514',message='Only a pending reset can be cancelled';
  end if;

  if not public.e05_transition_early_reset(
    v_reset.id,'cancelled',btrim(p_reason),v_actor
  ) then
    raise exception using errcode='23514',message='Reset is no longer pending';
  end if;
  return v_reset.id;
end;
$function$;

revoke all on function public.schedule_early_suspension_reset(uuid,uuid,text)
from public,anon,authenticated,service_role;
grant execute on function public.schedule_early_suspension_reset(uuid,uuid,text)
to authenticated;

-- 5) Automatic cancellation when the player is later nominated.
create or replace function public.e05_cancel_early_reset_on_nomination()
returns trigger language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_team_id uuid;
  v_actor uuid:=auth.uid();
  v_reset record;
begin
  select m.team_id into v_team_id
  from public.matchdays m where m.id=new.matchday_id;

  for v_reset in
    select r.id from public.matchday_early_suspension_resets r
    where r.matchday_id=new.matchday_id and r.player_id=new.player_id
      and r.status='pending'
    for update
  loop
    perform public.e05_transition_early_reset(
      v_reset.id,'cancelled',
      'Automatisch storniert: Spieler wurde nachträglich für diesen Spieltag nominiert.',
      v_actor
    );
  end loop;
  return new;
end;
$function$;

create trigger matchday_players_cancel_early_reset
after insert or update of matchday_id,player_id on public.matchday_players
for each row execute function public.e05_cancel_early_reset_on_nomination();

-- 6) Automatic cancellation on matchday cancellation and application on completion.
create or replace function public.e05_reconcile_early_resets_on_matchday_status()
returns trigger language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_reset record;
  v_actor uuid:=auth.uid();
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  if new.status not in ('cancelled','done') then
    return new;
  end if;

  for v_reset in
    select r.id from public.matchday_early_suspension_resets r
    where r.matchday_id=new.id and r.status='pending'
    for update
  loop
    if new.status='cancelled' then
      perform public.e05_transition_early_reset(
        v_reset.id,'cancelled',
        'Automatisch storniert: Der zugehörige Spieltag wurde abgesagt.',
        v_actor
      );
    elsif new.status='done' then
      perform public.e05_transition_early_reset(
        v_reset.id,'applied',
        'Vorzeitiger Sperrausgleich nach tatsächlich durchgeführtem Spieltag.',
        v_actor
      );
    end if;
  end loop;
  return new;
end;
$function$;

create trigger matchdays_reconcile_early_resets
after update of status on public.matchdays
for each row execute function public.e05_reconcile_early_resets_on_matchday_status();

-- 7) Extend yellow-card accounting: an applied early reset starts a new
-- active yellow-card account. This is the current DEV award RPC with only
-- the lower-bound calculation extended to include the latest applied reset.
create or replace function public.award_training_behavior_event(
  p_training_id uuid,
  p_player_id uuid,
  p_event_type text,
  p_reason text default null
) returns uuid
language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_actor uuid;
  v_team_id uuid;
  v_training_date date;
  v_training_name text;
  v_training_status text;
  v_training_season_id uuid;
  v_player_name text;
  v_player_active boolean;
  v_season_id uuid;
  v_season_name text;
  v_active_season_count integer;
  v_present boolean;
  v_event_id uuid;
  v_suspension_id uuid;
  v_suspension_source_event_id uuid;
  v_yellow_count integer;
  v_yellow_since timestamptz;
begin
  v_actor:=auth.uid();
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_training_id is null or p_player_id is null then
    raise exception using errcode='22023',message='Training and player are required';
  end if;
  if p_event_type is null or p_event_type not in ('yellow_card','red_card','positive_star') then
    raise exception using errcode='22023',message='Unsupported event type';
  end if;
  if p_event_type in ('yellow_card','red_card') and nullif(btrim(p_reason),'') is null then
    raise exception using errcode='22023',message='A reason is required for yellow and red cards';
  end if;

  select t.team_id,t.training_date,coalesce(nullif(btrim(t.name),''),'Training'),
         t.status,t.season_id
    into v_team_id,v_training_date,v_training_name,v_training_status,v_training_season_id
  from public.trainings t where t.id=p_training_id for update;
  if not found then
    raise exception using errcode='P0002',message='Training not found';
  end if;
  if v_training_status='cancelled' then
    raise exception using errcode='23514',message='Cancelled training cannot receive events';
  end if;

  select p.name,p.active into v_player_name,v_player_active
  from public.players p where p.id=p_player_id and p.team_id=v_team_id for update;
  if not found then
    raise exception using errcode='P0002',message='Player not found in training team';
  end if;
  if v_player_active is not true then
    raise exception using errcode='23514',message='Inactive player cannot receive events';
  end if;

  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_team_id and r.user_id=v_actor and r.role in ('trainer','admin')
  ) and not (
    exists(select 1 from public.global_user_roles gur
      where gur.user_id=v_actor and gur.role='super_admin')
    and public.has_selected_team_context(v_team_id)
  ) then
    raise exception using errcode='42501',message='Not authorized for this team';
  end if;

  select a.present into v_present from public.attendance a
  where a.training_id=p_training_id and a.player_id=p_player_id for update;
  if not found or v_present is not true then
    raise exception using errcode='23514',message='Player is not marked present';
  end if;

  if v_training_season_id is not null then
    select s.id,s.name into v_season_id,v_season_name
    from public.seasons s
    where s.id=v_training_season_id and s.team_id=v_team_id and s.is_active is true;
    if not found then
      raise exception using errcode='23514',
        message='Training season is not an active season of its team';
    end if;
  else
    select count(*)::integer,min(s.id::text)::uuid,min(s.name)
      into v_active_season_count,v_season_id,v_season_name
    from public.seasons s where s.team_id=v_team_id and s.is_active is true;
    if v_active_season_count<>1 then
      raise exception using errcode='23514',
        message='Exactly one active team season is required';
    end if;
  end if;

  insert into public.training_behavior_events(
    team_id,season_id,training_id,training_date_snapshot,training_name_snapshot,
    player_id,player_name_snapshot,event_type,reason,status,awarded_by,awarded_at
  ) values (
    v_team_id,v_season_id,p_training_id,v_training_date,v_training_name,
    p_player_id,v_player_name,p_event_type,nullif(btrim(p_reason),''),'active',v_actor,now()
  ) returning id into v_event_id;

  insert into public.training_behavior_event_audit(
    event_id,action,old_values,new_values,reason,changed_by,changed_at
  ) values (
    v_event_id,'created',null,
    jsonb_build_object(
      'id',v_event_id,'team_id',v_team_id,'season_id',v_season_id,
      'training_id',p_training_id,'training_date_snapshot',v_training_date,
      'training_name_snapshot',v_training_name,'player_id',p_player_id,
      'player_name_snapshot',v_player_name,'event_type',p_event_type,
      'reason',nullif(btrim(p_reason),''),'status','active','awarded_by',v_actor
    ),null,v_actor,now()
  );

  if p_event_type='red_card' then
    v_suspension_source_event_id:=v_event_id;
    insert into public.training_suspensions(
      team_id,season_id,player_id,player_name_snapshot,
      source_event_id,suspension_type,status,created_by,created_at
    ) values (
      v_team_id,v_season_id,p_player_id,v_player_name,
      v_event_id,'red','open',v_actor,now()
    ) returning id into v_suspension_id;

  elsif p_event_type='yellow_card' then
    select greatest(
      coalesce((
        select max(s.served_at) from public.training_suspensions s
        where s.team_id=v_team_id and s.season_id=v_season_id
          and s.player_id=p_player_id and s.suspension_type='yellow'
          and s.status='served'
      ),'-infinity'::timestamptz),
      coalesce((
        select max(r.applied_at) from public.matchday_early_suspension_resets r
        where r.team_id=v_team_id and r.season_id=v_season_id
          and r.player_id=p_player_id and r.status='applied'
      ),'-infinity'::timestamptz)
    ) into v_yellow_since;

    select count(*)::integer into v_yellow_count
    from public.training_behavior_events e
    where e.team_id=v_team_id and e.season_id=v_season_id
      and e.player_id=p_player_id and e.event_type='yellow_card'
      and e.status='active' and e.awarded_at>v_yellow_since;

    if v_yellow_count>=5 and not exists (
      select 1 from public.training_suspensions s
      where s.team_id=v_team_id and s.season_id=v_season_id
        and s.player_id=p_player_id and s.suspension_type='yellow'
        and s.status='open'
    ) then
      select e.id into v_suspension_source_event_id
      from public.training_behavior_events e
      where e.team_id=v_team_id and e.season_id=v_season_id
        and e.player_id=p_player_id and e.event_type='yellow_card'
        and e.status='active' and e.awarded_at>v_yellow_since
      order by e.awarded_at,e.id offset 4 limit 1;

      if v_suspension_source_event_id is not null then
        insert into public.training_suspensions(
          team_id,season_id,player_id,player_name_snapshot,
          source_event_id,suspension_type,status,created_by,created_at
        ) values (
          v_team_id,v_season_id,p_player_id,v_player_name,
          v_suspension_source_event_id,'yellow','open',v_actor,now()
        ) returning id into v_suspension_id;
      end if;
    end if;
  end if;

  if v_suspension_id is not null then
    insert into public.training_suspension_audit(
      suspension_id,action,old_values,new_values,reason,changed_by,changed_at
    ) values (
      v_suspension_id,'created',null,
      jsonb_build_object(
        'id',v_suspension_id,'team_id',v_team_id,'season_id',v_season_id,
        'player_id',p_player_id,'player_name_snapshot',v_player_name,
        'source_event_id',v_suspension_source_event_id,
        'suspension_type',case when p_event_type='red_card' then 'red' else 'yellow' end,
        'status','open','created_by',v_actor
      ),null,v_actor,now()
    );
  end if;
  return v_event_id;
end;
$function$;

revoke all on function public.award_training_behavior_event(uuid,uuid,text,text)
from public,anon,authenticated,service_role;
grant execute on function public.award_training_behavior_event(uuid,uuid,text,text)
to authenticated;

commit;
