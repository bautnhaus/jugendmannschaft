-- E05 / AP05 – Paket 5: Einzelfall-Ausnahme für einen konkreten Spieltag
-- Ziel: Supabase DEV only (pzazqvvoruqnqhcorbwx)
-- Status: AM 08.11.2026 IN SUPABASE DEV AUSGEFÜHRT; KORREKTURMIGRATION UND FUNKTIONSTESTS ERFOLGREICH
-- Abhängigkeit: Pakete 1–4, insbesondere training_suspensions,
-- training_suspension_audit und e05_assign_player_suspensions().
-- Keine PROD-Änderungen.

begin;

-- 1. Exception record. One active exception per suspension and matchday.
create table public.training_suspension_exceptions (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
  team_id uuid not null,
  team_name_snapshot text not null,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null,
  matchday_id uuid not null,
  matchday_date_snapshot date not null,
  matchday_opponent_snapshot text,
  reason text not null check (nullif(btrim(reason),'') is not null),
  granted_by uuid references auth.users(id) on delete set null,
  granted_by_snapshot text,
  granted_at timestamptz not null default now(),
  revoked_by uuid references auth.users(id) on delete set null,
  revoked_by_snapshot text,
  revoked_at timestamptz,
  revoke_reason text,
  constraint training_suspension_exceptions_revocation_check
    check (
      (revoked_at is null and revoked_by is null and revoke_reason is null)
      or (revoked_at is not null and nullif(btrim(revoke_reason),'') is not null)
    )
);

create unique index training_suspension_exceptions_one_active_per_suspension_matchday
  on public.training_suspension_exceptions(suspension_id,matchday_id)
  where revoked_at is null;
create index training_suspension_exceptions_matchday_idx
  on public.training_suspension_exceptions(team_id,matchday_id);

alter table public.training_suspension_exceptions enable row level security;
revoke all on public.training_suspension_exceptions from public,anon,authenticated,service_role;
grant select on public.training_suspension_exceptions to authenticated,service_role;

create policy training_suspension_exceptions_read
on public.training_suspension_exceptions for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

-- The existing suspension audit can now refer to either a suspension or an
-- exception. Existing suspension audit rows remain valid.
alter table public.training_suspension_audit
  add column exception_id uuid references public.training_suspension_exceptions(id) on delete restrict;

-- Existing audit rows reference suspensions; exception audit rows reference
-- exceptions instead. Exactly one of these two columns must be populated.
alter table public.training_suspension_audit
  alter column suspension_id drop not null;

alter table public.training_suspension_audit
  add constraint training_suspension_audit_one_subject_check
  check (num_nonnulls(suspension_id,exception_id)=1);

create index training_suspension_audit_exception_idx
  on public.training_suspension_audit(exception_id,changed_at desc)
  where exception_id is not null;

-- Exception rows are not directly writable by API roles. A later controlled
-- revoke RPC may update only revocation metadata; the audit table stays append-only.

-- 2. Rebuild the package-4 assignment helper so an active exception excludes
--    exactly its matchday from that suspension's next eligible target.
create or replace function public.e05_assign_player_suspensions(
  p_team_id uuid,
  p_player_id uuid,
  p_actor_id uuid
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_club_id uuid;
  v_types text[];
  v_has_team_override boolean;
  v_suspension record;
  v_matchday_id uuid;
  v_match_date date;
  v_opponent text;
  v_used_matchdays uuid[] := '{}'::uuid[];
  v_changed integer := 0;
  v_old_values jsonb;
  v_new_values jsonb;
begin
  select t.club_id into v_club_id
  from public.teams t where t.id=p_team_id;
  if not found then
    raise exception using errcode='P0002',message='Team not found';
  end if;

  select exists(
    select 1 from public.team_suspension_game_type_settings s where s.team_id=p_team_id
  ) into v_has_team_override;

  if v_has_team_override then
    select coalesce(array_agg(g.game_type order by g.game_type),'{}'::text[])
      into v_types
    from public.team_suspension_game_types g where g.team_id=p_team_id;
  else
    select coalesce(s.relevant_game_types,'{}'::text[])
      into v_types
    from public.club_suspension_settings s where s.club_id=v_club_id;
    if not found then v_types := '{}'::text[]; end if;
  end if;

  if exists (
    select 1 from public.training_suspensions s
    join public.matchdays m on m.id=s.intended_matchday_id
    where s.team_id=p_team_id and s.player_id=p_player_id
      and s.status='open' and m.status='done'
  ) then
    raise exception using errcode='23514',
      message='A completed assigned matchday must be processed before reassignment';
  end if;

  for v_suspension in
    select s.*
    from public.training_suspensions s
    where s.team_id=p_team_id and s.player_id=p_player_id and s.status='open'
    order by case s.suspension_type when 'yellow' then 0 else 1 end,
             s.created_at,s.id
    for update
  loop
    v_old_values := jsonb_build_object(
      'intended_matchday_id',v_suspension.intended_matchday_id,
      'intended_matchday_date_snapshot',v_suspension.intended_matchday_date_snapshot,
      'intended_matchday_opponent_snapshot',v_suspension.intended_matchday_opponent_snapshot
    );

    v_matchday_id := null;
    v_match_date := null;
    v_opponent := null;

    if cardinality(v_types)>0 then
      select m.id,m.match_date,m.opponent
        into v_matchday_id,v_match_date,v_opponent
      from public.matchdays m
      where m.team_id=p_team_id
        and m.season_id=v_suspension.season_id
        and m.status='planned'
        and m.match_date>=current_date
        and m.game_type=any(v_types)
        and not (m.id=any(v_used_matchdays))
        and not exists (
          select 1 from public.training_suspension_exceptions e
          where e.suspension_id=v_suspension.id
            and e.matchday_id=m.id and e.revoked_at is null
        )
      order by m.match_date,m.kickoff_time nulls last,m.created_at,m.id
      limit 1
      for update;
    end if;

    if v_matchday_id is not null then
      v_used_matchdays := array_append(v_used_matchdays,v_matchday_id);
    end if;

    v_new_values := jsonb_build_object(
      'intended_matchday_id',v_matchday_id,
      'intended_matchday_date_snapshot',v_match_date,
      'intended_matchday_opponent_snapshot',v_opponent
    );

    if v_old_values is distinct from v_new_values then
      update public.training_suspensions
      set intended_matchday_id=v_matchday_id,
          intended_matchday_date_snapshot=v_match_date,
          intended_matchday_opponent_snapshot=v_opponent
      where id=v_suspension.id;

      insert into public.training_suspension_audit(
        suspension_id,action,old_values,new_values,reason,changed_by,changed_at
      ) values (
        v_suspension.id,'target_changed',v_old_values,v_new_values,
        'Automatische Zuordnung bzw. Neuzuordnung nach einer Spieltagsausnahme.',
        p_actor_id,now()
      );
      v_changed:=v_changed+1;
    end if;
  end loop;

  return v_changed;
end;
$function$;

revoke all on function public.e05_assign_player_suspensions(uuid,uuid,uuid)
from public,anon,authenticated,service_role;

-- 3. Grant a specific exception and immediately shift the suspension to the
--    next relevant matchday. Nomination/appearance rows are not modified.
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
  ) and not public.has_selected_team_context(v_suspension.team_id) then
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

  -- Serialize all suspension/exception assignment work for this player.
  if v_suspension.player_id is not null then
    perform 1 from public.players p where p.id=v_suspension.player_id for update;
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

commit;
