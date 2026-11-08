-- E05 / AP05 – Paket 4: Spieltagszuordnung und Ableistung von Sperren
-- Ziel: Supabase DEV only (pzazqvvoruqnqhcorbwx)
-- Status: FREIGABEKANDIDAT – NICHT AUSFÜHREN VOR AUSDRÜCKLICHER FREIGABE
-- Abhängigkeit: Paket 1–3 und vorhandene training_suspensions /
-- training_suspension_audit Tabellen.
-- Keine bestehenden Daten werden gelöscht. Keine PROD-Änderungen.

begin;

-- ---------------------------------------------------------------------------
-- 1. Club default game types and complete team override
-- ---------------------------------------------------------------------------

create table public.club_suspension_settings (
  club_id uuid primary key references public.clubs(id) on delete restrict,
  relevant_game_types text[] not null default '{}'::text[],
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null,
  constraint club_suspension_settings_allowed_types
    check (relevant_game_types <@ array['Meisterschaft','Freundschaftsspiel','Turnier']::text[])
);

create table public.team_suspension_game_type_settings (
  team_id uuid primary key references public.teams(id) on delete cascade,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

create table public.team_suspension_game_types (
  team_id uuid not null references public.team_suspension_game_type_settings(team_id) on delete cascade,
  game_type text not null
    check (game_type in ('Meisterschaft','Freundschaftsspiel','Turnier')),
  created_at timestamptz not null default now(),
  primary key (team_id, game_type)
);

alter table public.club_suspension_settings enable row level security;
alter table public.team_suspension_game_type_settings enable row level security;
alter table public.team_suspension_game_types enable row level security;

revoke all on public.club_suspension_settings,
  public.team_suspension_game_type_settings,
  public.team_suspension_game_types
from public, anon, authenticated, service_role;

grant select on public.club_suspension_settings,
  public.team_suspension_game_type_settings,
  public.team_suspension_game_types
to authenticated, service_role;

create policy club_suspension_settings_read
on public.club_suspension_settings for select to authenticated
using (
  exists (
    select 1 from public.teams t
    where t.club_id = club_suspension_settings.club_id
      and public.is_team_member(t.id)
  )
  or (
    public.can_manage_club_context(club_id)
    and exists (
      select 1 from public.user_club_context c
      where c.user_id = auth.uid() and c.club_id = club_suspension_settings.club_id
    )
  )
);

create policy team_suspension_game_type_settings_read
on public.team_suspension_game_type_settings for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy team_suspension_game_types_read
on public.team_suspension_game_types for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

-- ---------------------------------------------------------------------------
-- 2. Configuration RPCs. Empty array is a valid explicit "no relevant types".
--    Removing a team override restores the club default.
-- ---------------------------------------------------------------------------

create or replace function public.set_club_suspension_game_types(
  p_club_id uuid,
  p_game_types text[]
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_types text[];
begin
  if auth.uid() is null then
    raise exception using errcode='42501', message='Authentication required';
  end if;
  if p_club_id is null or p_game_types is null then
    raise exception using errcode='22023', message='Club and game types are required';
  end if;
  if not public.can_manage_club_context(p_club_id) then
    raise exception using errcode='42501', message='Club management permission required';
  end if;
  if not (p_game_types <@ array['Meisterschaft','Freundschaftsspiel','Turnier']::text[]) then
    raise exception using errcode='22023', message='Unsupported game type';
  end if;

  select coalesce(array_agg(distinct x order by x), '{}'::text[])
    into v_types
  from unnest(p_game_types) as x;

  insert into public.club_suspension_settings(club_id,relevant_game_types,updated_at,updated_by)
  values(p_club_id,v_types,now(),auth.uid())
  on conflict(club_id) do update
    set relevant_game_types=excluded.relevant_game_types,
        updated_at=excluded.updated_at,
        updated_by=excluded.updated_by;
end;
$function$;

create or replace function public.set_team_suspension_game_types(
  p_team_id uuid,
  p_override_enabled boolean,
  p_game_types text[] default '{}'::text[]
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_types text[];
begin
  if auth.uid() is null then
    raise exception using errcode='42501', message='Authentication required';
  end if;
  if p_team_id is null or p_override_enabled is null then
    raise exception using errcode='22023', message='Team and override choice are required';
  end if;
  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=p_team_id and r.user_id=auth.uid() and r.role in ('trainer','admin')
  ) and not public.has_selected_team_context(p_team_id) then
    raise exception using errcode='42501', message='Team management permission required';
  end if;

  if not p_override_enabled then
    delete from public.team_suspension_game_type_settings where team_id=p_team_id;
    return;
  end if;

  if p_game_types is null
     or not (p_game_types <@ array['Meisterschaft','Freundschaftsspiel','Turnier']::text[]) then
    raise exception using errcode='22023', message='Unsupported or missing game type list';
  end if;

  select coalesce(array_agg(distinct x order by x), '{}'::text[])
    into v_types
  from unnest(p_game_types) as x;

  insert into public.team_suspension_game_type_settings(team_id,updated_at,updated_by)
  values(p_team_id,now(),auth.uid())
  on conflict(team_id) do update set updated_at=excluded.updated_at,updated_by=excluded.updated_by;

  delete from public.team_suspension_game_types where team_id=p_team_id;
  insert into public.team_suspension_game_types(team_id,game_type)
  select p_team_id,x from unnest(v_types) as x;
end;
$function$;

-- ---------------------------------------------------------------------------
-- 3. Internal helper: re-evaluate all open suspensions of one player and
--    assign them to consecutive upcoming relevant matchdays, yellow first.
--    The team override replaces the club list in full.
-- ---------------------------------------------------------------------------

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
  v_season_id uuid;
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
    raise exception using errcode='P0002', message='Team not found';
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
    if not found then
      v_types := '{}'::text[];
    end if;
  end if;

  -- Clear and rebuild only future targets for this player's open suspensions.
  -- Historical served/expired/voided rows are never modified.
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

    if cardinality(v_types) > 0 then
      select m.id,m.match_date,m.opponent
        into v_matchday_id,v_match_date,v_opponent
      from public.matchdays m
      where m.team_id=p_team_id
        and m.season_id=v_suspension.season_id
        and m.status='planned'
        and m.match_date >= current_date
        and m.game_type = any(v_types)
        and not (m.id = any(v_used_matchdays))
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
        'Automatische Zuordnung bzw. Neuzuordnung zum nächsten relevanten Spieltag.',
        p_actor_id,now()
      );
      v_changed := v_changed + 1;
    end if;
  end loop;

  return v_changed;
end;
$function$;

revoke all on function public.e05_assign_player_suspensions(uuid,uuid,uuid)
from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. Public assignment RPC
-- ---------------------------------------------------------------------------

create or replace function public.assign_next_suspension_matchday(
  p_team_id uuid,
  p_player_id uuid
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
begin
  if auth.uid() is null then
    raise exception using errcode='42501', message='Authentication required';
  end if;
  if p_team_id is null or p_player_id is null then
    raise exception using errcode='22023', message='Team and player are required';
  end if;
  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=p_team_id and r.user_id=auth.uid() and r.role in ('trainer','admin')
  ) and not public.has_selected_team_context(p_team_id) then
    raise exception using errcode='42501', message='Team permission required';
  end if;

  perform 1 from public.players p
  where p.id=p_player_id and p.team_id=p_team_id
  for update;
  if not found then
    raise exception using errcode='P0002', message='Player not found in team';
  end if;

  return public.e05_assign_player_suspensions(p_team_id,p_player_id,auth.uid());
end;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Serve suspensions only when the assigned matchday is actually done.
--    At most one suspension per player can be served on a matchday; yellow
--    precedes red. A later suspension cannot leapfrog an earlier one.
-- ---------------------------------------------------------------------------

create or replace function public.serve_matchday_suspensions(
  p_matchday_id uuid
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_actor uuid := auth.uid();
  v_team_id uuid;
  v_match_season_id uuid;
  v_match_date date;
  v_opponent text;
  v_game_type text;
  v_club_id uuid;
  v_types text[];
  v_has_team_override boolean;
  v_suspension record;
  v_served integer := 0;
  v_players uuid[] := '{}'::uuid[];
  v_old_values jsonb;
  v_new_values jsonb;
  v_player uuid;
begin
  if v_actor is null then
    raise exception using errcode='42501', message='Authentication required';
  end if;
  if p_matchday_id is null then
    raise exception using errcode='22023', message='Matchday is required';
  end if;

  select m.team_id,m.season_id,m.match_date,m.opponent,m.game_type
    into v_team_id,v_match_season_id,v_match_date,v_opponent,v_game_type
  from public.matchdays m where m.id=p_matchday_id
  for update;
  if not found then
    raise exception using errcode='P0002', message='Matchday not found';
  end if;
  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_team_id and r.user_id=v_actor and r.role in ('trainer','admin')
  ) and not public.has_selected_team_context(v_team_id) then
    raise exception using errcode='42501', message='Team permission required';
  end if;
  if (select m.status from public.matchdays m where m.id=p_matchday_id) <> 'done' then
    raise exception using errcode='23514', message='Only a completed matchday can serve suspensions';
  end if;

  select t.club_id into v_club_id from public.teams t where t.id=v_team_id;
  select exists(select 1 from public.team_suspension_game_type_settings s where s.team_id=v_team_id)
    into v_has_team_override;

  if v_has_team_override then
    select coalesce(array_agg(g.game_type order by g.game_type),'{}'::text[])
      into v_types from public.team_suspension_game_types g where g.team_id=v_team_id;
  else
    select coalesce(s.relevant_game_types,'{}'::text[])
      into v_types from public.club_suspension_settings s where s.club_id=v_club_id;
    if not found then v_types := '{}'::text[]; end if;
  end if;

  if v_game_type is null or not (v_game_type = any(v_types)) then
    raise exception using errcode='23514', message='This matchday game type is not relevant for suspensions';
  end if;

  for v_suspension in
    select s.*
    from public.training_suspensions s
    where s.team_id=v_team_id
      and s.season_id=v_match_season_id
      and s.status='open'
      and s.intended_matchday_id=p_matchday_id
    order by s.player_id,
             case s.suspension_type when 'yellow' then 0 else 1 end,
             s.created_at,s.id
    for update
  loop
    -- Never serve a later suspension while an earlier one remains open.
    if exists (
      select 1 from public.training_suspensions prior
      where prior.team_id=v_suspension.team_id
        and prior.season_id=v_suspension.season_id
        and prior.player_id=v_suspension.player_id
        and prior.status='open'
        and (
          (prior.suspension_type='yellow' and v_suspension.suspension_type='red')
          or (prior.suspension_type=v_suspension.suspension_type
              and (prior.created_at,prior.id) < (v_suspension.created_at,v_suspension.id))
        )
    ) then
      continue;
    end if;

    v_old_values := jsonb_build_object(
      'status',v_suspension.status,
      'intended_matchday_id',v_suspension.intended_matchday_id
    );
    v_new_values := jsonb_build_object(
      'status','served',
      'served_matchday_id',p_matchday_id,
      'served_matchday_date_snapshot',v_match_date,
      'served_matchday_opponent_snapshot',v_opponent
    );

    update public.training_suspensions
    set status='served',
        served_matchday_id=p_matchday_id,
        served_matchday_date_snapshot=v_match_date,
        served_matchday_opponent_snapshot=v_opponent,
        served_at=now()
    where id=v_suspension.id;

    insert into public.training_suspension_audit(
      suspension_id,action,old_values,new_values,reason,changed_by,changed_at
    ) values (
      v_suspension.id,'served',v_old_values,v_new_values,
      'Sperre durch tatsächlich durchgeführten relevanten Spieltag abgeleistet.',
      v_actor,now()
    );

    v_served := v_served + 1;
    if v_suspension.player_id is not null
       and not (v_suspension.player_id = any(v_players)) then
      v_players := array_append(v_players,v_suspension.player_id);
    end if;
  end loop;

  -- After serving, immediately recalculate the remaining open suspensions.
  foreach v_player in array v_players loop
    perform public.e05_assign_player_suspensions(v_team_id,v_player,v_actor);
  end loop;

  return v_served;
end;
$function$;

-- Tight function ACLs
revoke all on function public.set_club_suspension_game_types(uuid,text[])
from public, anon, authenticated, service_role;
grant execute on function public.set_club_suspension_game_types(uuid,text[])
to authenticated;

revoke all on function public.set_team_suspension_game_types(uuid,boolean,text[])
from public, anon, authenticated, service_role;
grant execute on function public.set_team_suspension_game_types(uuid,boolean,text[])
to authenticated;

revoke all on function public.assign_next_suspension_matchday(uuid,uuid)
from public, anon, authenticated, service_role;
grant execute on function public.assign_next_suspension_matchday(uuid,uuid)
to authenticated;

revoke all on function public.serve_matchday_suspensions(uuid)
from public, anon, authenticated, service_role;
grant execute on function public.serve_matchday_suspensions(uuid)
to authenticated;

commit;
