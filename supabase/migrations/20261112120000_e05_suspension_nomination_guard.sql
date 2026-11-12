-- DB-MIG-2026-011
-- E05: suspension-aware matchday recommendations and nominations.
-- Prepared for review only. DO NOT EXECUTE before explicit approval.
-- Target: Supabase DEV only. No PROD/main changes.
--
-- Behavior:
-- * Open suspension assigned to this matchday blocks recommendation and nomination.
-- * An active exception for this exact matchday allows both.
-- * Granting an exception moves the open suspension to the next matchday;
--   the original matchday remains allowed through its exception record.
-- * Revoking the exception reassigns the open suspension and makes the
--   original matchday blocked again when it is the intended target.
--
-- No data cleanup, no RLS policy changes, no table/column changes.

begin;

-- 1) Guard direct writes to both recommendation rows and actual nominations.
-- SECURITY DEFINER is intentionally limited to this read-only guard so RLS
-- visibility cannot cause a false negative. It performs no writes.
create or replace function public.e05_assert_matchday_player_not_suspended()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_matchday_id uuid;
  v_suspension_id uuid;
begin
  if tg_table_name = 'matchday_players' then
    v_matchday_id := new.matchday_id;
  elsif tg_table_name = 'matchday_recommendation_players' then
    select r.matchday_id
      into v_matchday_id
    from public.matchday_recommendation_runs r
    where r.id = new.recommendation_id;
  else
    raise exception 'Unsupported E05 suspension guard table: %', tg_table_name
      using errcode = '0A000';
  end if;

  if v_matchday_id is null then
    raise exception 'Spieltag der Zuordnung konnte nicht ermittelt werden.'
      using errcode = '23503';
  end if;

  -- Serialize this check against exception grant/revoke and reassignment.
  select s.id
    into v_suspension_id
  from public.training_suspensions s
  where s.player_id = new.player_id
    and s.status = 'open'
    and s.intended_matchday_id = v_matchday_id
    and not exists (
      select 1
      from public.training_suspension_exceptions e
      where e.suspension_id = s.id
        and e.matchday_id = v_matchday_id
        and e.revoked_at is null
    )
  order by s.created_at, s.id
  limit 1
  for update;

  if v_suspension_id is not null then
    raise exception
      'Spieler ist für diesen Spieltag gesperrt. Bitte zuerst eine Spieltag-Ausnahme erteilen.'
      using errcode = '23514';
  end if;

  return new;
end;
$function$;

-- Trigger functions are invoked by their triggers; no direct API execution.
revoke all on function public.e05_assert_matchday_player_not_suspended()
  from public, anon, authenticated, service_role;

drop trigger if exists e05_guard_matchday_nomination_suspension
  on public.matchday_players;
create trigger e05_guard_matchday_nomination_suspension
before insert or update of matchday_id, player_id
on public.matchday_players
for each row
execute function public.e05_assert_matchday_player_not_suspended();

drop trigger if exists e05_guard_matchday_recommendation_suspension
  on public.matchday_recommendation_players;
create trigger e05_guard_matchday_recommendation_suspension
before insert or update of recommendation_id, player_id
on public.matchday_recommendation_players
for each row
execute function public.e05_assert_matchday_player_not_suspended();

-- 2) Add the same rule to the existing recommendation RPC.
-- Guarded source transformation: abort if the DEV definition has drifted.
do $migration$
declare
  v_def text;
  v_marker text := $marker$
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
$marker$;
  v_replacement text := $replacement$
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

    -- E05: Reject players with an open suspension assigned to this matchday.
    -- A non-revoked exception for this exact matchday explicitly permits them.
    IF EXISTS (
        SELECT 1
        FROM unnest(p_player_ids) AS u(player_id)
        JOIN public.training_suspensions s
          ON s.player_id = u.player_id
         AND s.status = 'open'
         AND s.intended_matchday_id = p_matchday_id
        WHERE NOT EXISTS (
            SELECT 1
            FROM public.training_suspension_exceptions e
            WHERE e.suspension_id = s.id
              AND e.matchday_id = p_matchday_id
              AND e.revoked_at IS NULL
        )
    ) THEN
        RAISE EXCEPTION
            'Die Kaderempfehlung enthält mindestens einen für diesen Spieltag gesperrten Spieler.'
            USING ERRCODE = '23514';
    END IF;
$replacement$;
  v_count integer;
begin
  v_def := pg_get_functiondef(
    'public.save_matchday_recommendation(uuid,uuid[])'::regprocedure
  );

  v_count := (length(v_def) - length(replace(v_def, v_marker, '')))
             / length(v_marker);
  if v_count <> 1 then
    raise exception
      'DB-MIG-2026-011: save_matchday_recommendation baseline mismatch (marker count=%)',
      v_count;
  end if;

  v_def := replace(v_def, v_marker, v_replacement);
  execute v_def;
end;
$migration$;

commit;
