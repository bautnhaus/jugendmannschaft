-- Rollback for DB-MIG-2026-011.
-- Prepared for review only. Execute only after explicit approval.
-- Restore the exact pre-migration recommendation RPC and remove only
-- the two E05 triggers and their dedicated trigger function.
begin;

drop trigger if exists e05_guard_matchday_nomination_suspension
  on public.matchday_players;
drop trigger if exists e05_guard_matchday_recommendation_suspension
  on public.matchday_recommendation_players;

drop function if exists public.e05_assert_matchday_player_not_suspended();

create or replace function public.save_matchday_recommendation(p_matchday_id uuid, p_player_ids uuid[])
 returns uuid
 language plpgsql
 set search_path to 'pg_catalog', 'public'
as $function$
DECLARE
    v_team_id uuid;
    v_recommendation_id uuid;
    v_count integer;
    v_distinct_count integer;
BEGIN
    IF p_matchday_id IS NULL THEN
        RAISE EXCEPTION 'Spieltag fehlt.';
    END IF;

    IF p_player_ids IS NULL
       OR cardinality(p_player_ids) = 0 THEN
        RAISE EXCEPTION
            'Eine leere Kaderempfehlung wird nicht gespeichert.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM unnest(p_player_ids) AS u(player_id)
        WHERE u.player_id IS NULL
    ) THEN
        RAISE EXCEPTION
            'Die Empfehlung enthält eine ungültige Spieler-ID.';
    END IF;

    SELECT m.team_id
    INTO v_team_id
    FROM public.matchdays m
    WHERE m.id = p_matchday_id
    FOR UPDATE;

    IF v_team_id IS NULL THEN
        RAISE EXCEPTION 'Spieltag nicht gefunden.';
    END IF;

    IF NOT public.is_team_member(v_team_id) THEN
        RAISE EXCEPTION
            'Keine Berechtigung für diesen Spieltag.';
    END IF;

    SELECT count(*), count(DISTINCT u.player_id)
    INTO v_count, v_distinct_count
    FROM unnest(p_player_ids) AS u(player_id);

    IF v_count <> v_distinct_count THEN
        RAISE EXCEPTION
            'Die Empfehlung enthält doppelte Spieler.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM unnest(p_player_ids) AS u(player_id)
        LEFT JOIN public.players p ON p.id = u.player_id
        WHERE p.id IS NULL
           OR p.team_id <> v_team_id
           OR p.active IS NOT TRUE
    ) THEN
        RAISE EXCEPTION
            'Mindestens ein Spieler ist ungültig, inaktiv oder gehört nicht zur Mannschaft des Spieltags.';
    END IF;

    INSERT INTO public.matchday_recommendation_runs (
        matchday_id,
        created_at,
        created_by
    )
    VALUES (
        p_matchday_id,
        now(),
        auth.uid()
    )
    ON CONFLICT (matchday_id)
    DO UPDATE SET
        created_at = EXCLUDED.created_at,
        created_by = EXCLUDED.created_by
    RETURNING id INTO v_recommendation_id;

    DELETE FROM public.matchday_recommendation_players
    WHERE recommendation_id = v_recommendation_id;

    INSERT INTO public.matchday_recommendation_players (
        recommendation_id,
        player_id,
        rank
    )
    SELECT
        v_recommendation_id,
        u.player_id,
        u.ordinality::integer
    FROM unnest(p_player_ids)
         WITH ORDINALITY AS u(player_id, ordinality);

    RETURN v_recommendation_id;
END;
$function$;

commit;
