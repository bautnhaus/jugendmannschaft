-- Rollback for DB-MIG-2026-011.
-- Restore the exact pre-migration DEV definition of save_matchday_recommendation.
-- Remove only the trigger/function introduced by DB-MIG-2026-011.
-- Execute only after frontend callers have been reverted as appropriate.
begin;

drop trigger if exists matchday_players_prevent_suspended_nomination
    on public.matchday_players;

drop function if exists public.prevent_suspended_matchday_nomination();

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

commit;
