-- DB-MIG-2026-011
-- E05: enforce suspension-aware recommendation persistence and matchday nomination.
-- Prepared for review only. Target: Supabase DEV. NOT EXECUTED.
-- No table/column/RLS-policy changes. Existing suspension exception RPCs remain unchanged.
begin;

do $preflight$
declare
  v_def text;
begin
  if to_regprocedure('public.save_matchday_recommendation(uuid,uuid[])') is null then
    raise exception 'DB-MIG-2026-011: save_matchday_recommendation(uuid,uuid[]) not found';
  end if;
  v_def := pg_get_functiondef('public.save_matchday_recommendation(uuid,uuid[])'::regprocedure);
  if position('matchday_recommendation_runs' in v_def)=0
     or position('matchday_recommendation_players' in v_def)=0
     or position('public.is_team_member(v_team_id)' in v_def)=0
     or position('p.active IS NOT TRUE' in v_def)=0 then
    raise exception 'DB-MIG-2026-011: recommendation RPC differs from reviewed DEV baseline; aborting';
  end if;
  if to_regclass('public.training_suspensions') is null
     or to_regclass('public.training_suspension_exceptions') is null
     or to_regclass('public.matchday_players') is null then
    raise exception 'DB-MIG-2026-011: required E05 tables missing; aborting';
  end if;
  if exists (
    select 1 from pg_trigger
    where tgrelid='public.matchday_players'::regclass
      and tgname='matchday_players_prevent_suspended_nomination'
      and not tgisinternal
  ) then
    raise exception 'DB-MIG-2026-011: nomination guard trigger already exists; inspect before proceeding';
  end if;
end;
$preflight$;

-- Preserve the existing RPC contract and all previous checks.
-- Add only: reject recommendation candidates with an open suspension assigned
-- to this matchday, unless an active exception exists for this exact suspension
-- and matchday. Exception grant shifts the open suspension to its next target;
-- the exception row remains the auditable permission for the original matchday.
create or replace function public.save_matchday_recommendation(
    p_matchday_id uuid,
    p_player_ids uuid[]
)
returns uuid
language plpgsql
set search_path to 'pg_catalog', 'public'
as $function$
declare
    v_team_id uuid;
    v_recommendation_id uuid;
    v_count integer;
    v_distinct_count integer;
begin
    if p_matchday_id is null then
        raise exception 'Spieltag fehlt.';
    end if;

    if p_player_ids is null
       or cardinality(p_player_ids) = 0 then
        raise exception
            'Eine leere Kaderempfehlung wird nicht gespeichert.';
    end if;

    if exists (
        select 1
        from unnest(p_player_ids) as u(player_id)
        where u.player_id is null
    ) then
        raise exception
            'Die Empfehlung enthält eine ungültige Spieler-ID.';
    end if;

    select m.team_id
    into v_team_id
    from public.matchdays m
    where m.id = p_matchday_id
    for update;

    if v_team_id is null then
        raise exception 'Spieltag nicht gefunden.';
    end if;

    if not public.is_team_member(v_team_id) then
        raise exception
            'Keine Berechtigung für diesen Spieltag.';
    end if;

    select count(*), count(distinct u.player_id)
    into v_count, v_distinct_count
    from unnest(p_player_ids) as u(player_id);

    if v_count <> v_distinct_count then
        raise exception
            'Die Empfehlung enthält doppelte Spieler.';
    end if;

    if exists (
        select 1
        from unnest(p_player_ids) as u(player_id)
        left join public.players p on p.id = u.player_id
        where p.id is null
           or p.team_id <> v_team_id
           or p.active is not true
    ) then
        raise exception
            'Mindestens ein Spieler ist ungültig, inaktiv oder gehört nicht zur Mannschaft des Spieltags.';
    end if;

    -- E05: a current open suspension blocks recommendation for its assigned
    -- matchday. A granted, non-revoked exception for that exact suspension and
    -- matchday is permitted. No general/other-matchday exception is accepted.
    if exists (
        select 1
        from unnest(p_player_ids) as u(player_id)
        join public.training_suspensions s
          on s.player_id = u.player_id
         and s.team_id = v_team_id
         and s.status = 'open'
         and s.intended_matchday_id = p_matchday_id
        where not exists (
            select 1
            from public.training_suspension_exceptions e
            where e.suspension_id = s.id
              and e.matchday_id = p_matchday_id
              and e.revoked_at is null
        )
    ) then
        raise exception
            'Die Kaderempfehlung enthält mindestens einen für diesen Spieltag gesperrten Spieler.'
            using errcode = '23514';
    end if;

    insert into public.matchday_recommendation_runs (
        matchday_id,
        created_at,
        created_by
    )
    values (
        p_matchday_id,
        now(),
        auth.uid()
    )
    on conflict (matchday_id)
    do update set
        created_at = excluded.created_at,
        created_by = excluded.created_by
    returning id into v_recommendation_id;

    delete from public.matchday_recommendation_players
    where recommendation_id = v_recommendation_id;

    insert into public.matchday_recommendation_players (
        recommendation_id,
        player_id,
        rank
    )
    select
        v_recommendation_id,
        u.player_id,
        u.ordinality::integer
    from unnest(p_player_ids)
         with ordinality as u(player_id, ordinality);

    return v_recommendation_id;
end;
$function$;

-- Direct table writes are protected too. SECURITY INVOKER deliberately keeps
-- the caller's existing RLS visibility and role context in force.
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

drop trigger if exists matchday_players_prevent_suspended_nomination
    on public.matchday_players;

create trigger matchday_players_prevent_suspended_nomination
before insert or update of matchday_id, player_id
on public.matchday_players
for each row
execute function public.prevent_suspended_matchday_nomination();

-- Trigger functions are invoked by the trigger; do not expose them as RPCs.
revoke all on function public.prevent_suspended_matchday_nomination() from public, anon, authenticated;

commit;
