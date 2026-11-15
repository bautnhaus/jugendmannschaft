-- DB-MIG-2026-022
-- E05 PROD Paket 11: Sperrprüfung bei Kaderempfehlung und Nominierung.
-- Aligns the live DEV DB-MIG-2026-011 behavior with the existing PROD Paket-6 guard.
-- PROD already has the matchday nomination trigger and atomic exception-revocation
-- behavior from Paket 6; this migration preserves that trigger and tightens its
-- function ACL to the DEV contract. It adds the missing suspension check to the
-- recommendation RPC. No table/data/RLS/trigger changes.

begin;

do $preflight$
declare
  v_save text;
  v_guard text;
  v_revoke text;
begin
  if to_regprocedure('public.save_matchday_recommendation(uuid,uuid[])') is null
     or to_regprocedure('public.prevent_suspended_matchday_nomination()') is null
     or to_regprocedure('public.revoke_suspension_exception(uuid,text)') is null
     or to_regclass('public.training_suspensions') is null
     or to_regclass('public.training_suspension_exceptions') is null
     or to_regclass('public.matchday_players') is null
     or to_regclass('public.matchday_recommendation_runs') is null
     or to_regclass('public.matchday_recommendation_players') is null then
    raise exception 'Paket 11 Preflight: benötigte E05-/Kaderobjekte fehlen';
  end if;

  v_save := pg_get_functiondef('public.save_matchday_recommendation(uuid,uuid[])'::regprocedure);
  v_guard := pg_get_functiondef('public.prevent_suspended_matchday_nomination()'::regprocedure);
  v_revoke := pg_get_functiondef('public.revoke_suspension_exception(uuid,text)'::regprocedure);

  if position('training_suspensions' in lower(v_save)) > 0 then
    raise exception 'Paket 11 Preflight: recommendation RPC enthält die Sperrprüfung bereits; Live-Stand prüfen';
  end if;
  if position('pg_advisory_xact_lock' in v_guard)=0
     or position('training_suspensions' in lower(v_guard))=0
     or position('training_suspension_exceptions' in lower(v_guard))=0 then
    raise exception 'Paket 11 Preflight: bestehender Paket-6-Nominierungstrigger weicht vom erwarteten PROD-Stand ab';
  end if;
  if position('pg_advisory_xact_lock' in v_revoke)=0
     or position('nomination_removed' in v_revoke)=0
     or position('removed_nomination_snapshot' in v_revoke)=0
     or position('played' in lower(v_revoke))=0 then
    raise exception 'Paket 11 Preflight: atomarer Ausnahme-Widerruf aus Paket 6 weicht vom DEV-Stand ab';
  end if;

  if (select count(*) from pg_trigger
      where tgrelid='public.matchday_players'::regclass
        and tgname='matchday_players_prevent_suspended_nomination'
        and not tgisinternal
        and tgfoid='public.prevent_suspended_matchday_nomination()'::regprocedure) <> 1 then
    raise exception 'Paket 11 Preflight: bestehender Nominierungstrigger fehlt oder ist nicht eindeutig';
  end if;

  if not (select not prosecdef and proowner='postgres'::regrole
          and proconfig @> array['search_path=pg_catalog, public']
          from pg_proc where oid='public.save_matchday_recommendation(uuid,uuid[])'::regprocedure)
     or not (select not prosecdef and proowner='postgres'::regrole
          and proconfig @> array['search_path=pg_catalog, public']
          from pg_proc where oid='public.prevent_suspended_matchday_nomination()'::regprocedure)
     or not (select prosecdef and proowner='postgres'::regrole
          and proconfig @> array['search_path=pg_catalog, public, auth']
          from pg_proc where oid='public.revoke_suspension_exception(uuid,text)'::regprocedure) then
    raise exception 'Paket 11 Preflight: Owner/Security/search_path weicht vom geprüften Stand ab';
  end if;

  if not has_function_privilege('authenticated','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE')
     or not has_function_privilege('authenticated','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or not has_function_privilege('anon','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or not has_function_privilege('authenticated','public.revoke_suspension_exception(uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.revoke_suspension_exception(uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 11 Preflight: EXECUTE-ACLs weichen vom erwarteten PROD-Ausgangsstand ab';
  end if;
end;
$preflight$;

-- Exact current DEV DB-MIG-2026-011 function definition.
CREATE OR REPLACE FUNCTION public.save_matchday_recommendation(p_matchday_id uuid, p_player_ids uuid[])
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
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
$function$
;

-- The trigger and its function already exist from PROD Paket 6. Restrict direct
-- API invocation to match the current DEV ACL; service_role and trigger behavior
-- remain unchanged.
revoke all on function public.prevent_suspended_matchday_nomination()
  from public, anon, authenticated;

do $postflight$
declare
  v_save text;
  v_revoke text;
begin
  v_save := pg_get_functiondef('public.save_matchday_recommendation(uuid,uuid[])'::regprocedure);
  v_revoke := pg_get_functiondef('public.revoke_suspension_exception(uuid,text)'::regprocedure);

  if position('training_suspensions' in lower(v_save))=0
     or position('training_suspension_exceptions' in lower(v_save))=0
     or position('intended_matchday_id' in lower(v_save))=0
     or position('23514' in v_save)=0 then
    raise exception 'Paket 11 Postflight: recommendation RPC enthält nicht die erwartete Sperren-/Ausnahmeprüfung';
  end if;
  if has_function_privilege('public','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or has_function_privilege('authenticated','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE') then
    raise exception 'Paket 11 Postflight: Triggerfunktions-ACL ist nicht auf DEV-Stand';
  end if;
  if not has_function_privilege('authenticated','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE') then
    raise exception 'Paket 11 Postflight: recommendation RPC ACL wurde unerwartet verändert';
  end if;
  if (select count(*) from pg_trigger
      where tgrelid='public.matchday_players'::regclass
        and tgname='matchday_players_prevent_suspended_nomination'
        and not tgisinternal
        and tgfoid='public.prevent_suspended_matchday_nomination()'::regprocedure) <> 1 then
    raise exception 'Paket 11 Postflight: bestehender Nominierungstrigger wurde verändert';
  end if;
  if position('nomination_removed' in v_revoke)=0
     or position('removed_nomination_snapshot' in v_revoke)=0
     or position('pg_advisory_xact_lock' in v_revoke)=0 then
    raise exception 'Paket 11 Postflight: bestehender atomarer Ausnahme-Widerruf wurde verändert';
  end if;
end;
$postflight$;

commit;
