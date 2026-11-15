-- DB-MIG-2026-022 guarded rollback.
-- Restores the exact PROD save_matchday_recommendation definition captured
-- immediately before Paket 11 and restores the previous trigger-function ACL.
-- The existing trigger and atomic exception-revocation RPC are retained.

begin;

do $preflight$
declare
  v_save text;
begin
  v_save := pg_get_functiondef('public.save_matchday_recommendation(uuid,uuid[])'::regprocedure);
  if position('training_suspensions' in lower(v_save))=0
     or has_function_privilege('public','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or has_function_privilege('authenticated','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE') then
    raise exception 'Paket-11-Rollback gestoppt: erwarteter Paket-11-Live-Stand fehlt';
  end if;
end;
$preflight$;

-- Exact PROD function definition captured read-only before Paket 11.
CREATE OR REPLACE FUNCTION public.save_matchday_recommendation(p_matchday_id uuid, p_player_ids uuid[])
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
    v_team_id uuid;
    v_recommendation_id uuid;
    v_count integer;
    v_distinct_count integer;
BEGIN
    IF p_matchday_id IS NULL THEN
        RAISE EXCEPTION 'Spieltag fehlt.';
    END IF;

    IF p_player_ids IS NULL OR cardinality(p_player_ids) = 0 THEN
        RAISE EXCEPTION 'Eine leere Kaderempfehlung wird nicht gespeichert.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM unnest(p_player_ids) AS u(player_id)
        WHERE u.player_id IS NULL
    ) THEN
        RAISE EXCEPTION 'Die Empfehlung enthaelt eine ungueltige Spieler-ID.';
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
        RAISE EXCEPTION 'Keine Berechtigung fuer diesen Spieltag.';
    END IF;

    SELECT count(*), count(DISTINCT u.player_id)
    INTO v_count, v_distinct_count
    FROM unnest(p_player_ids) AS u(player_id);

    IF v_count <> v_distinct_count THEN
        RAISE EXCEPTION 'Die Empfehlung enthaelt doppelte Spieler.';
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
          'Mindestens ein Spieler ist ungueltig, inaktiv oder gehoert nicht zur Mannschaft des Spieltags.';
    END IF;

    INSERT INTO public.matchday_recommendation_runs (
        matchday_id, created_at, created_by
    )
    VALUES (p_matchday_id, now(), auth.uid())
    ON CONFLICT (matchday_id)
    DO UPDATE SET
        created_at = EXCLUDED.created_at,
        created_by = EXCLUDED.created_by
    RETURNING id INTO v_recommendation_id;

    DELETE FROM public.matchday_recommendation_players
    WHERE recommendation_id = v_recommendation_id;

    INSERT INTO public.matchday_recommendation_players (
        recommendation_id, player_id, rank
    )
    SELECT v_recommendation_id, u.player_id, u.ordinality::integer
    FROM unnest(p_player_ids)
         WITH ORDINALITY AS u(player_id, ordinality);

    RETURN v_recommendation_id;
END;
$function$
;

-- Restore the pre-Paket-11 direct EXECUTE grants on the existing trigger function.
grant execute on function public.prevent_suspended_matchday_nomination()
  to public, anon, authenticated;

do $postflight$
declare
  v_save text;
begin
  v_save := pg_get_functiondef('public.save_matchday_recommendation(uuid,uuid[])'::regprocedure);
  if position('training_suspensions' in lower(v_save))>0 then
    raise exception 'Paket-11-Rollback Postflight: original recommendation RPC was not restored';
  end if;
  if not has_function_privilege('public','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or not has_function_privilege('anon','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or not has_function_privilege('authenticated','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE') then
    raise exception 'Paket-11-Rollback Postflight: original trigger-function ACL was not restored';
  end if;
end;
$postflight$;

commit;
