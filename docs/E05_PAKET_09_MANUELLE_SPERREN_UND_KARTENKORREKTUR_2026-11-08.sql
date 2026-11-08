-- =============================================================================
-- E05 / Paket 9 – Manuelle Sperren- und Kartenkorrektur
-- Ziel: Supabase DEV (Projekt pzazqvvoruqnqhcorbwx) – NICHT PROD
-- Status: IN SUPABASE DEV AUSGEFÜHRT (Migrationsversion 20261108212745)
--
-- Paket 9A: correct_suspension
--   Korrigiert ausschließlich die Zuordnung einer OFFENEN Sperre zu einem
--   anderen geplanten Spieltag derselben Mannschaft und Saison.
--
-- Paket 9B: correct_training_behavior_event
--   Storniert ein fehlerhaftes Kartenereignis oder stellt ein zuvor storniertes
--   Kartenereignis wieder her. Das aktive gelbe Kartenkonto wird neu bewertet.
--
-- Verbindliche Schutzregeln:
--   * Abgesessene Sperren werden niemals rückwirkend geändert.
--   * Historische Karten- und Sperrendatensätze werden nicht gelöscht.
--   * Jede Änderung und das zugehörige Audit erfolgen atomar.
--   * Begründung ist Pflicht.
--   * Berechtigung: Teamrolle trainer/admin oder Superadmin im ausgewählten
--     Teamkontext.
--   * Manuelle Zielzuordnung bleibt bei automatischen Neuberechnungen bestehen,
--     solange der gewählte Spieltag gültig und sperrenrelevant ist.
--   * Ungültige manuelle Zielzuordnungen werden bei der nächsten Ausführung
--     des kanonischen Zuordnungs-RPC freigegeben und neu vergeben. Ein
--     abgeschlossener Spieltag muss zuvor über die Ableistungs-RPC verarbeitet
--     werden. Ein Matchday-Trigger wird wegen möglicher Deadlocks nicht ergänzt.
--   * Keine direkten Tabellen-Schreibrechte werden erteilt.
--   * Der bestehende automatische Zuordnungs-RPC wird erweitert, damit eine
--     manuelle Korrektur nicht durch spätere Neuberechnungen überschrieben wird.
--
-- WICHTIG:
--   Wie bei den Paketen 1–8 ist Supabase DEV die verbindliche Testumgebung.
--   Vor Ausführung erfolgen statische SQL-, Schema-, Abhängigkeits- und
--   Berechtigungsprüfungen. Anschließend werden die Funktionen in DEV getestet;
--   erkannte Fehler werden auf develop korrigiert und erneut geprüft.
--   DEV-Ausführung: erfolgreich; Korrekturen 9.1 und 9.2 separat dokumentiert.
--   PROD-Ausführung: nicht erfolgt und nicht freigegeben.
-- =============================================================================

begin;

-- 1. Audit-Snapshots: bisherige Audit-Tabellen behalten ihre Struktur;
--    die Snapshot-Spalten werden additiv ergänzt.
alter table public.training_behavior_event_audit
  add column if not exists changed_by_snapshot text;

alter table public.training_suspension_audit
  add column if not exists changed_by_snapshot text;

-- A manually corrected target must survive later automatic recalculations.
alter table public.training_suspensions
  add column if not exists manual_target_locked boolean not null default false;


-- 2. Interner Berechtigungshelfer.
--    Kein eigenständiger API-Endpunkt; wird nur von den Paket-9-RPCs verwendet.
create or replace function public.e05_assert_suspension_correction_permission(
  p_team_id uuid,
  p_actor_id uuid
) returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
begin
  if p_actor_id is null then
    raise exception using errcode = '42501',
      message = 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.team_member_roles r
    where r.team_id = p_team_id
      and r.user_id = p_actor_id
      and r.role in ('trainer', 'admin')
  ) and not (
    exists (
      select 1
      from public.global_user_roles g
      where g.user_id = p_actor_id
        and g.role = 'super_admin'
    )
    and public.has_selected_team_context(p_team_id)
  ) then
    raise exception using errcode = '42501',
      message = 'Team trainer/admin permission required';
  end if;
end;
$function$;

revoke all on function
  public.e05_assert_suspension_correction_permission(uuid, uuid)
from public, anon, authenticated, service_role;


-- 3. Interner Abgleich der Sperre(n) nach Kartenkorrektur.
--    Die Funktion verändert ausschließlich offene Sperren.
create or replace function public.e05_reconcile_suspensions_after_event_correction(
  p_event_id uuid,
  p_actor_id uuid,
  p_reason text
) returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_event public.training_behavior_events%rowtype;
  v_actor_name text;
  v_yellow_since timestamptz;
  v_yellow_count integer;
  v_fifth_event_id uuid;
  v_open_suspension public.training_suspensions%rowtype;
  v_has_open_suspension boolean := false;
  v_existing_suspension public.training_suspensions%rowtype;
  v_red_suspension_changed boolean := false;
  v_red_suspension_exists boolean := false;
  v_old jsonb;
  v_new jsonb;
  v_now timestamptz := now();
begin
  select * into v_event
  from public.training_behavior_events
  where id = p_event_id;

  if not found then
    raise exception using errcode = 'P0002',
      message = 'Training behavior event not found during suspension reconciliation';
  end if;

  select nullif(btrim(pr.display_name), '')
  into v_actor_name
  from public.profiles pr
  where pr.id = p_actor_id;

  if v_event.event_type = 'red_card' then
    select * into v_existing_suspension
    from public.training_suspensions s
    where s.source_event_id = v_event.id
      and s.suspension_type = 'red'
    order by s.created_at desc
    limit 1
    for update;
    v_red_suspension_exists := found;

    if v_event.status = 'voided' then
      if v_red_suspension_exists and v_existing_suspension.status = 'open' then
        v_old := jsonb_build_object(
          'status', v_existing_suspension.status,
          'voided_at', v_existing_suspension.voided_at,
          'void_reason', v_existing_suspension.void_reason
        );

        update public.training_suspensions
        set status = 'voided',
            voided_by = p_actor_id,
            voided_at = v_now,
            void_reason = btrim(p_reason),
            intended_matchday_id = null,
            intended_matchday_date_snapshot = null,
            intended_matchday_opponent_snapshot = null,
            manual_target_locked = false
        where id = v_existing_suspension.id;

        v_new := jsonb_build_object(
          'status', 'voided',
          'voided_by', p_actor_id,
          'voided_by_snapshot', v_actor_name,
          'voided_at', v_now,
          'void_reason', btrim(p_reason)
        );

        insert into public.training_suspension_audit(
          suspension_id, action, old_values, new_values, reason,
          changed_by, changed_by_snapshot, changed_at
        ) values (
          v_existing_suspension.id, 'voided', v_old, v_new,
          btrim(p_reason), p_actor_id, v_actor_name, v_now
        );

        perform public.e05_assign_player_suspensions(
          v_event.team_id, v_event.player_id, p_actor_id
        );
      end if;

      -- Served/expired suspensions are deliberately left unchanged.
      return;
    end if;

    -- A reinstated red card restores its linked voided suspension, or creates
    -- a new open suspension if no historical suspension exists for the event.
    if v_event.status = 'active' then
      if v_red_suspension_exists and v_existing_suspension.status = 'voided' then
        v_old := jsonb_build_object(
          'status', v_existing_suspension.status,
          'voided_at', v_existing_suspension.voided_at,
          'void_reason', v_existing_suspension.void_reason
        );

        update public.training_suspensions
        set status = 'open',
            voided_by = null,
            voided_at = null,
            void_reason = null,
            expired_at = null,
            served_matchday_id = null,
            served_matchday_date_snapshot = null,
            served_matchday_opponent_snapshot = null,
            served_at = null,
            intended_matchday_id = null,
            intended_matchday_date_snapshot = null,
            intended_matchday_opponent_snapshot = null,
            manual_target_locked = false
        where id = v_existing_suspension.id;

        v_new := jsonb_build_object('status', 'open');

        insert into public.training_suspension_audit(
          suspension_id, action, old_values, new_values, reason,
          changed_by, changed_by_snapshot, changed_at
        ) values (
          v_existing_suspension.id, 'reinstated', v_old, v_new,
          btrim(p_reason), p_actor_id, v_actor_name, v_now
        );
        v_red_suspension_changed := true;

      elsif not v_red_suspension_exists then
        insert into public.training_suspensions(
          team_id, season_id, player_id, player_name_snapshot,
          source_event_id, suspension_type, status, created_by, created_at
        ) values (
          v_event.team_id, v_event.season_id, v_event.player_id,
          v_event.player_name_snapshot, v_event.id, 'red', 'open',
          p_actor_id, v_now
        ) returning * into v_existing_suspension;

        insert into public.training_suspension_audit(
          suspension_id, action, old_values, new_values, reason,
          changed_by, changed_by_snapshot, changed_at
        ) values (
          v_existing_suspension.id, 'created', null,
          jsonb_build_object(
            'id', v_existing_suspension.id,
            'source_event_id', v_event.id,
            'suspension_type', 'red',
            'status', 'open'
          ),
          btrim(p_reason), p_actor_id, v_actor_name, v_now
        );
        v_red_suspension_changed := true;
      end if;

      -- A restored red card creates/reopens an open suspension. Re-run the
      -- established assignment routine so the suspension receives the next
      -- eligible matchday under the existing club/team game-type rules.
      if v_red_suspension_changed and v_event.player_id is not null then
        perform public.e05_assign_player_suspensions(
          v_event.team_id, v_event.player_id, p_actor_id
        );
      end if;
    end if;

    return;
  end if;

  if v_event.event_type <> 'yellow_card' then
    return;
  end if;

  -- Same lower-bound rule as award_training_behavior_event:
  -- latest served yellow suspension OR latest applied early reset.
  select greatest(
    coalesce((
      select max(s.served_at)
      from public.training_suspensions s
      where s.team_id = v_event.team_id
        and s.season_id = v_event.season_id
        and s.player_id = v_event.player_id
        and s.suspension_type = 'yellow'
        and s.status = 'served'
    ), '-infinity'::timestamptz),
    coalesce((
      select max(r.applied_at)
      from public.matchday_early_suspension_resets r
      where r.team_id = v_event.team_id
        and r.season_id = v_event.season_id
        and r.player_id = v_event.player_id
        and r.status = 'applied'
    ), '-infinity'::timestamptz)
  ) into v_yellow_since;

  select count(*)::integer
  into v_yellow_count
  from public.training_behavior_events e
  where e.team_id = v_event.team_id
    and e.season_id = v_event.season_id
    and e.player_id = v_event.player_id
    and e.event_type = 'yellow_card'
    and e.status = 'active'
    and e.awarded_at > v_yellow_since;

  select * into v_open_suspension
  from public.training_suspensions s
  where s.team_id = v_event.team_id
    and s.season_id = v_event.season_id
    and s.player_id = v_event.player_id
    and s.suspension_type = 'yellow'
    and s.status = 'open'
  order by s.created_at
  limit 1
  for update;
  v_has_open_suspension := found;

  if v_yellow_count < 5 then
    if v_has_open_suspension then
      v_old := jsonb_build_object(
        'status', v_open_suspension.status,
        'source_event_id', v_open_suspension.source_event_id,
        'intended_matchday_id', v_open_suspension.intended_matchday_id
      );

      update public.training_suspensions
      set status = 'voided',
          voided_by = p_actor_id,
          voided_at = v_now,
          void_reason = btrim(p_reason),
          intended_matchday_id = null,
          intended_matchday_date_snapshot = null,
          intended_matchday_opponent_snapshot = null,
          manual_target_locked = false
      where id = v_open_suspension.id;

      v_new := jsonb_build_object(
        'status', 'voided',
        'voided_by', p_actor_id,
        'voided_by_snapshot', v_actor_name,
        'voided_at', v_now,
        'void_reason', btrim(p_reason)
      );

      insert into public.training_suspension_audit(
        suspension_id, action, old_values, new_values, reason,
        changed_by, changed_by_snapshot, changed_at
      ) values (
        v_open_suspension.id, 'voided', v_old, v_new,
        btrim(p_reason), p_actor_id, v_actor_name, v_now
      );

      perform public.e05_assign_player_suspensions(
        v_event.team_id, v_event.player_id, p_actor_id
      );
    end if;

    return;
  end if;

  -- At least five active cards remain. Preserve an existing open suspension.
  -- If its source card was voided, point it at the recomputed fifth active card.
  if v_has_open_suspension then
    select e.id into v_fifth_event_id
    from public.training_behavior_events e
    where e.team_id = v_event.team_id
      and e.season_id = v_event.season_id
      and e.player_id = v_event.player_id
      and e.event_type = 'yellow_card'
      and e.status = 'active'
      and e.awarded_at > v_yellow_since
    order by e.awarded_at, e.id
    offset 4 limit 1;

    if v_fifth_event_id is not null
       and v_open_suspension.source_event_id is distinct from v_fifth_event_id then
      select * into v_existing_suspension
      from public.training_suspensions s
      where s.source_event_id = v_fifth_event_id
        and s.suspension_type = 'yellow'
      for update;

      if found and v_existing_suspension.status = 'voided' then
        -- Reuse the historical suspension row for the newly recomputed fifth
        -- card. Keep the previous open row as voided history; do not violate
        -- the unique one-suspension-per-source-event index.
        v_old := jsonb_build_object(
          'status', v_open_suspension.status,
          'source_event_id', v_open_suspension.source_event_id
        );
        update public.training_suspensions
        set status = 'voided',
            voided_by = p_actor_id,
            voided_at = v_now,
            void_reason = btrim(p_reason),
            intended_matchday_id = null,
            intended_matchday_date_snapshot = null,
            intended_matchday_opponent_snapshot = null,
            manual_target_locked = false
        where id = v_open_suspension.id;
        v_new := jsonb_build_object(
          'status', 'voided',
          'source_event_id', v_open_suspension.source_event_id,
          'voided_at', v_now,
          'void_reason', btrim(p_reason)
        );
        insert into public.training_suspension_audit(
          suspension_id, action, old_values, new_values, reason,
          changed_by, changed_by_snapshot, changed_at
        ) values (
          v_open_suspension.id, 'voided', v_old, v_new,
          btrim(p_reason), p_actor_id, v_actor_name, v_now
        );

        v_old := jsonb_build_object(
          'status', v_existing_suspension.status,
          'source_event_id', v_existing_suspension.source_event_id
        );
        update public.training_suspensions
        set status = 'open',
            voided_by = null,
            voided_at = null,
            void_reason = null,
            expired_at = null,
            served_matchday_id = null,
            served_matchday_date_snapshot = null,
            served_matchday_opponent_snapshot = null,
            served_at = null,
            intended_matchday_id = null,
            intended_matchday_date_snapshot = null,
            intended_matchday_opponent_snapshot = null,
            manual_target_locked = false
        where id = v_existing_suspension.id;
        v_new := jsonb_build_object(
          'status', 'open',
          'source_event_id', v_existing_suspension.source_event_id
        );
        insert into public.training_suspension_audit(
          suspension_id, action, old_values, new_values, reason,
          changed_by, changed_by_snapshot, changed_at
        ) values (
          v_existing_suspension.id, 'reinstated', v_old, v_new,
          btrim(p_reason), p_actor_id, v_actor_name, v_now
        );
      elsif found and v_existing_suspension.status <> 'voided' then
        raise exception using errcode = '23514',
          message = 'The recomputed fifth yellow card already has a non-voided suspension history';
      else
        v_old := jsonb_build_object(
          'source_event_id', v_open_suspension.source_event_id
        );
        update public.training_suspensions
        set source_event_id = v_fifth_event_id
        where id = v_open_suspension.id;
        v_new := jsonb_build_object('source_event_id', v_fifth_event_id);

        insert into public.training_suspension_audit(
          suspension_id, action, old_values, new_values, reason,
          changed_by, changed_by_snapshot, changed_at
        ) values (
          v_open_suspension.id, 'corrected', v_old, v_new,
          btrim(p_reason), p_actor_id, v_actor_name, v_now
        );
      end if;
    end if;

    -- Keep assignment of all open suspensions consistent with the canonical
    -- automatic assignment logic after the card threshold has been recomputed.
    perform public.e05_assign_player_suspensions(
      v_event.team_id, v_event.player_id, p_actor_id
    );
    return;
  end if;

  -- No open suspension exists: identify the current fifth active card.
  select e.id into v_fifth_event_id
  from public.training_behavior_events e
  where e.team_id = v_event.team_id
    and e.season_id = v_event.season_id
    and e.player_id = v_event.player_id
    and e.event_type = 'yellow_card'
    and e.status = 'active'
    and e.awarded_at > v_yellow_since
  order by e.awarded_at, e.id
  offset 4 limit 1;

  if v_fifth_event_id is null then
    return;
  end if;

  select * into v_existing_suspension
  from public.training_suspensions s
  where s.source_event_id = v_fifth_event_id
    and s.suspension_type = 'yellow'
  order by s.created_at desc
  limit 1
  for update;

  if found then
    -- A served or expired suspension is never reopened by a later correction.
    if v_existing_suspension.status <> 'voided' then
      return;
    end if;

    v_old := jsonb_build_object(
      'status', v_existing_suspension.status,
      'voided_at', v_existing_suspension.voided_at,
      'void_reason', v_existing_suspension.void_reason
    );

    update public.training_suspensions
    set status = 'open',
        voided_by = null,
        voided_at = null,
        void_reason = null,
        expired_at = null,
        served_matchday_id = null,
        served_matchday_date_snapshot = null,
        served_matchday_opponent_snapshot = null,
        served_at = null,
        intended_matchday_id = null,
        intended_matchday_date_snapshot = null,
        intended_matchday_opponent_snapshot = null,
        manual_target_locked = false
    where id = v_existing_suspension.id;

    v_new := jsonb_build_object('status', 'open');

    insert into public.training_suspension_audit(
      suspension_id, action, old_values, new_values, reason,
      changed_by, changed_by_snapshot, changed_at
    ) values (
      v_existing_suspension.id, 'reinstated', v_old, v_new,
      btrim(p_reason), p_actor_id, v_actor_name, v_now
    );

  else
    insert into public.training_suspensions(
      team_id, season_id, player_id, player_name_snapshot,
      source_event_id, suspension_type, status, created_by, created_at
    ) values (
      v_event.team_id, v_event.season_id, v_event.player_id,
      v_event.player_name_snapshot, v_fifth_event_id, 'yellow', 'open',
      p_actor_id, v_now
    ) returning * into v_existing_suspension;

    insert into public.training_suspension_audit(
      suspension_id, action, old_values, new_values, reason,
      changed_by, changed_by_snapshot, changed_at
    ) values (
      v_existing_suspension.id, 'created', null,
      jsonb_build_object(
        'id', v_existing_suspension.id,
        'source_event_id', v_fifth_event_id,
        'suspension_type', 'yellow',
        'status', 'open'
      ),
      btrim(p_reason), p_actor_id, v_actor_name, v_now
    );
  end if;

  perform public.e05_assign_player_suspensions(
    v_event.team_id, v_event.player_id, p_actor_id
  );
end;
$function$;

revoke all on function
  public.e05_reconcile_suspensions_after_event_correction(uuid, uuid, text)
from public, anon, authenticated, service_role;


-- 4. Existing automatic allocator: extended to preserve valid manual targets.
--    The signature and SECURITY DEFINER boundary remain unchanged.
create or replace function public.e05_assign_player_suspensions(
  p_team_id uuid,
  p_player_id uuid,
  p_actor_id uuid
) returns integer
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
  v_manual_target_valid boolean;
  v_actor_name text;
begin
  select nullif(btrim(pr.display_name), '')
    into v_actor_name
  from public.profiles pr
  where pr.id = p_actor_id;

  select t.club_id into v_club_id
  from public.teams t where t.id = p_team_id;
  if not found then
    raise exception using errcode = 'P0002', message = 'Team not found';
  end if;

  select exists(
    select 1 from public.team_suspension_game_type_settings s
    where s.team_id = p_team_id
  ) into v_has_team_override;

  if v_has_team_override then
    select coalesce(array_agg(g.game_type order by g.game_type), '{}'::text[])
      into v_types
    from public.team_suspension_game_types g
    where g.team_id = p_team_id;
  else
    select coalesce(s.relevant_game_types, '{}'::text[])
      into v_types
    from public.club_suspension_settings s
    where s.club_id = v_club_id;
    if not found then
      v_types := '{}'::text[];
    end if;
  end if;

  if exists (
    select 1
    from public.training_suspensions s
    join public.matchdays m on m.id = s.intended_matchday_id
    where s.team_id = p_team_id
      and s.player_id = p_player_id
      and s.status = 'open'
      and m.status = 'done'
  ) then
    raise exception using errcode = '23514',
      message = 'A completed assigned matchday must be processed before reassignment';
  end if;

  -- Reserve all still-valid manually selected targets before allocating
  -- automatic targets, regardless of the order in which suspensions are read.
  select coalesce(array_agg(s.intended_matchday_id), '{}'::uuid[])
    into v_used_matchdays
  from public.training_suspensions s
  join public.matchdays m on m.id = s.intended_matchday_id
  where s.team_id = p_team_id
    and s.player_id = p_player_id
    and s.status = 'open'
    and s.manual_target_locked is true
    and m.team_id = p_team_id
    and m.season_id = s.season_id
    and m.status = 'planned'
    and m.match_date >= current_date
    and m.game_type = any(v_types)
    and not exists (
      select 1
      from public.training_suspension_exceptions e
      where e.suspension_id = s.id
        and e.matchday_id = m.id
        and e.revoked_at is null
    );

  for v_suspension in
    select s.*
    from public.training_suspensions s
    where s.team_id = p_team_id
      and s.player_id = p_player_id
      and s.status = 'open'
    order by case s.suspension_type when 'yellow' then 0 else 1 end,
             s.created_at, s.id
    for update
  loop
    if v_suspension.manual_target_locked is true then
      select exists (
        select 1
        from public.matchdays m
        where m.id = v_suspension.intended_matchday_id
          and m.team_id = p_team_id
          and m.season_id = v_suspension.season_id
          and m.status = 'planned'
          and m.match_date >= current_date
          and m.game_type = any(v_types)
          and not exists (
            select 1
            from public.training_suspension_exceptions e
            where e.suspension_id = v_suspension.id
              and e.matchday_id = m.id
              and e.revoked_at is null
          )
      ) into v_manual_target_valid;

      if v_manual_target_valid then
        -- Its target was pre-reserved above; do not overwrite it.
        continue;
      end if;

      v_old_values := jsonb_build_object(
        'intended_matchday_id', v_suspension.intended_matchday_id,
        'manual_target_locked', true
      );

      update public.training_suspensions
      set manual_target_locked = false
      where id = v_suspension.id;

      v_new_values := jsonb_build_object(
        'intended_matchday_id', v_suspension.intended_matchday_id,
        'manual_target_locked', false
      );

      insert into public.training_suspension_audit(
        suspension_id, action, old_values, new_values, reason,
        changed_by, changed_by_snapshot, changed_at
      ) values (
        v_suspension.id, 'target_changed', v_old_values, v_new_values,
        'Manuelle Zuordnung ist nicht mehr gültig; automatische Neuzuordnung freigegeben.',
        p_actor_id, v_actor_name, now()
      );

      v_suspension.manual_target_locked := false;
    end if;

    v_old_values := jsonb_build_object(
      'intended_matchday_id', v_suspension.intended_matchday_id,
      'intended_matchday_date_snapshot', v_suspension.intended_matchday_date_snapshot,
      'intended_matchday_opponent_snapshot', v_suspension.intended_matchday_opponent_snapshot,
      'manual_target_locked', v_suspension.manual_target_locked
    );

    v_matchday_id := null;
    v_match_date := null;
    v_opponent := null;

    if cardinality(v_types) > 0 then
      select m.id, m.match_date, m.opponent
        into v_matchday_id, v_match_date, v_opponent
      from public.matchdays m
      where m.team_id = p_team_id
        and m.season_id = v_suspension.season_id
        and m.status = 'planned'
        and m.match_date >= current_date
        and m.game_type = any(v_types)
        and not (m.id = any(v_used_matchdays))
        and not exists (
          select 1
          from public.training_suspension_exceptions e
          where e.suspension_id = v_suspension.id
            and e.matchday_id = m.id
            and e.revoked_at is null
        )
      order by m.match_date, m.kickoff_time nulls last, m.created_at, m.id
      limit 1
      for update;
    end if;

    if v_matchday_id is not null then
      v_used_matchdays := array_append(v_used_matchdays, v_matchday_id);
    end if;

    v_new_values := jsonb_build_object(
      'intended_matchday_id', v_matchday_id,
      'intended_matchday_date_snapshot', v_match_date,
      'intended_matchday_opponent_snapshot', v_opponent,
      'manual_target_locked', false
    );

    if v_old_values is distinct from v_new_values then
      update public.training_suspensions
      set intended_matchday_id = v_matchday_id,
          intended_matchday_date_snapshot = v_match_date,
          intended_matchday_opponent_snapshot = v_opponent,
          manual_target_locked = false
      where id = v_suspension.id;

      insert into public.training_suspension_audit(
        suspension_id, action, old_values, new_values, reason,
        changed_by, changed_by_snapshot, changed_at
      ) values (
        v_suspension.id, 'target_changed', v_old_values, v_new_values,
        'Automatische Zuordnung bzw. Neuzuordnung nach einer Spieltagsänderung.',
        p_actor_id, v_actor_name, now()
      );
      v_changed := v_changed + 1;
    end if;
  end loop;

  return v_changed;
end;
$function$;


-- A manual target that becomes invalid is released by the next invocation of
-- the canonical allocator (for example after a card correction or another
-- suspension event). We deliberately do not add a matchday trigger here:
-- matchday updates hold a matchday row lock, while card awards/manual corrections
-- lock player/suspension rows before matchdays. A trigger that calls the allocator
-- from the matchday update would invert this lock order and introduce deadlocks.


-- 5. Paket 9A: offene Sperre auf einen anderen geplanten Spieltag korrigieren.
create or replace function public.correct_suspension(
  p_suspension_id uuid,
  p_target_matchday_id uuid,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_actor uuid := auth.uid();
  v_actor_name text;
  v_suspension public.training_suspensions%rowtype;
  v_target public.matchdays%rowtype;
  v_club_id uuid;
  v_types text[];
  v_has_team_override boolean;
  v_old jsonb;
  v_new jsonb;
  v_now timestamptz := now();
begin
  if v_actor is null then
    raise exception using errcode = '42501',
      message = 'Authentication required';
  end if;

  if p_suspension_id is null
     or p_target_matchday_id is null
     or nullif(btrim(p_reason), '') is null then
    raise exception using errcode = '22023',
      message = 'Suspension, target matchday and correction reason are required';
  end if;

  -- Read scope, then lock player -> suspension -> matchday. This follows
  -- the established E05 player/suspension locking convention and serializes
  -- against card corrections and automatic target reassignment.
  select * into v_suspension
  from public.training_suspensions
  where id = p_suspension_id;

  if not found then
    raise exception using errcode = 'P0002',
      message = 'Suspension not found';
  end if;

  perform public.e05_assert_suspension_correction_permission(
    v_suspension.team_id, v_actor
  );

  if v_suspension.player_id is not null then
    perform 1 from public.players p
    where p.id = v_suspension.player_id
    for update;
  end if;

  select * into v_suspension
  from public.training_suspensions
  where id = p_suspension_id
  for update;

  if not found then
    raise exception using errcode = 'P0002',
      message = 'Suspension not found';
  end if;

  select * into v_target
  from public.matchdays
  where id = p_target_matchday_id
  for update;

  if not found then
    raise exception using errcode = 'P0002',
      message = 'Target matchday not found';
  end if;
  if v_suspension.status <> 'open' then
    raise exception using errcode = '23514',
      message = 'Only an open suspension can be manually corrected';
  end if;

  if v_suspension.intended_matchday_id is not null and exists (
    select 1
    from public.matchdays current_matchday
    where current_matchday.id = v_suspension.intended_matchday_id
      and current_matchday.status = 'done'
  ) then
    raise exception using errcode = '23514',
      message = 'A completed assigned matchday must be processed before manual correction';
  end if;

  if v_target.id = v_suspension.intended_matchday_id then
    raise exception using errcode = '23514',
      message = 'Suspension is already assigned to the selected matchday';
  end if;

  if v_target.team_id <> v_suspension.team_id
     or v_target.season_id <> v_suspension.season_id then
    raise exception using errcode = '23514',
      message = 'Target matchday must belong to the same team and season';
  end if;

  if v_target.status is distinct from 'planned'
     or v_target.match_date is null
     or v_target.match_date < current_date then
    raise exception using errcode = '23514',
      message = 'Target matchday must be a future planned matchday';
  end if;

  if v_suspension.player_id is null then
    raise exception using errcode = '23514',
      message = 'Suspension has no linked player and cannot be reassigned';
  end if;

  -- Manual corrections must obey the same configured game-type rules as
  -- automatic assignment; they cannot bypass club/team suspension settings.
  select t.club_id into v_club_id
  from public.teams t
  where t.id = v_suspension.team_id;

  select exists(
    select 1 from public.team_suspension_game_type_settings s
    where s.team_id = v_suspension.team_id
  ) into v_has_team_override;

  if v_has_team_override then
    select coalesce(array_agg(g.game_type order by g.game_type), '{}'::text[])
    into v_types
    from public.team_suspension_game_types g
    where g.team_id = v_suspension.team_id;
  else
    select coalesce(s.relevant_game_types, '{}'::text[])
    into v_types
    from public.club_suspension_settings s
    where s.club_id = v_club_id;
    if not found then
      v_types := '{}'::text[];
    end if;
  end if;

  if v_target.game_type is null or not (v_target.game_type = any(v_types)) then
    raise exception using errcode = '23514',
      message = 'Target matchday game type is not configured as suspension-relevant';
  end if;

  if exists (
    select 1
    from public.training_suspension_exceptions e
    where e.suspension_id = v_suspension.id
      and e.matchday_id = v_target.id
      and e.revoked_at is null
  ) then
    raise exception using errcode = '23514',
      message = 'An active exception excludes this matchday for the suspension';
  end if;

  if exists (
    select 1
    from public.training_suspensions other_s
    where other_s.team_id = v_suspension.team_id
      and other_s.season_id = v_suspension.season_id
      and other_s.player_id = v_suspension.player_id
      and other_s.status = 'open'
      and other_s.id <> v_suspension.id
      and other_s.intended_matchday_id = v_target.id
  ) then
    raise exception using errcode = '23514',
      message = 'Another open suspension for this player is already assigned to the selected matchday';
  end if;

  select nullif(btrim(pr.display_name), '')
  into v_actor_name
  from public.profiles pr
  where pr.id = v_actor;

  v_old := jsonb_build_object(
    'intended_matchday_id', v_suspension.intended_matchday_id,
    'intended_matchday_date_snapshot', v_suspension.intended_matchday_date_snapshot,
    'intended_matchday_opponent_snapshot', v_suspension.intended_matchday_opponent_snapshot,
    'manual_target_locked', v_suspension.manual_target_locked,
    'status', v_suspension.status
  );

  update public.training_suspensions
  set intended_matchday_id = v_target.id,
      intended_matchday_date_snapshot = v_target.match_date,
      intended_matchday_opponent_snapshot = v_target.opponent,
      manual_target_locked = true
  where id = v_suspension.id;

  v_new := jsonb_build_object(
    'intended_matchday_id', v_target.id,
    'intended_matchday_date_snapshot', v_target.match_date,
    'intended_matchday_opponent_snapshot', v_target.opponent,
    'manual_target_locked', true,
    'status', v_suspension.status
  );

  insert into public.training_suspension_audit(
    suspension_id, action, old_values, new_values, reason,
    changed_by, changed_by_snapshot, changed_at
  ) values (
    v_suspension.id, 'corrected', v_old, v_new, btrim(p_reason),
    v_actor, v_actor_name, v_now
  );

  return v_suspension.id;
end;
$function$;

revoke all on function
  public.correct_suspension(uuid, uuid, text)
from public, anon, authenticated, service_role;

grant execute on function
  public.correct_suspension(uuid, uuid, text)
to authenticated;


-- 6. Paket 9B: Kartenereignis stornieren oder wiederherstellen.
--    p_target_status = 'voided'  -> Ereignis als fehlerhaft stornieren
--    p_target_status = 'active'  -> zuvor storniertes Ereignis wiederherstellen
create or replace function public.correct_training_behavior_event(
  p_event_id uuid,
  p_target_status text,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_actor uuid := auth.uid();
  v_actor_name text;
  v_event public.training_behavior_events%rowtype;
  v_old jsonb;
  v_new jsonb;
  v_now timestamptz := now();
  v_audit_action text;
begin
  if v_actor is null then
    raise exception using errcode = '42501',
      message = 'Authentication required';
  end if;

  if p_event_id is null
     or p_target_status is null
     or p_target_status not in ('active', 'voided')
     or nullif(btrim(p_reason), '') is null then
    raise exception using errcode = '22023',
      message = 'Event, valid target status and correction reason are required';
  end if;

  -- Lock player first to serialize corrections against concurrent card awards.
  select p.id
  from public.players p
  join public.training_behavior_events e on e.player_id = p.id
  where e.id = p_event_id
  for update of p;

  select * into v_event
  from public.training_behavior_events
  where id = p_event_id
  for update;

  if not found then
    raise exception using errcode = 'P0002',
      message = 'Training behavior event not found';
  end if;

  if v_event.player_id is null then
    raise exception using errcode = '23514',
      message = 'A card event without a linked player cannot be corrected';
  end if;

  if v_event.event_type not in ('yellow_card', 'red_card') then
    raise exception using errcode = '23514',
      message = 'Only yellow and red card events can be corrected in Paket 9';
  end if;

  perform public.e05_assert_suspension_correction_permission(
    v_event.team_id, v_actor
  );

  if v_event.status = p_target_status then
    raise exception using errcode = '23514',
      message = 'Event already has the requested status; duplicate correction rejected';
  end if;

  select nullif(btrim(pr.display_name), '')
  into v_actor_name
  from public.profiles pr
  where pr.id = v_actor;

  v_old := jsonb_build_object(
    'status', v_event.status,
    'voided_by', v_event.voided_by,
    'voided_at', v_event.voided_at,
    'void_reason', v_event.void_reason,
    'event_type', v_event.event_type,
    'awarded_at', v_event.awarded_at
  );

  if p_target_status = 'voided' then
    update public.training_behavior_events
    set status = 'voided',
        voided_by = v_actor,
        voided_at = v_now,
        void_reason = btrim(p_reason),
        updated_at = v_now
    where id = v_event.id;

    v_audit_action := 'voided';
    v_new := jsonb_build_object(
      'status', 'voided',
      'voided_by', v_actor,
      'voided_by_snapshot', v_actor_name,
      'voided_at', v_now,
      'void_reason', btrim(p_reason)
    );
  else
    update public.training_behavior_events
    set status = 'active',
        voided_by = null,
        voided_at = null,
        void_reason = null,
        updated_at = v_now
    where id = v_event.id;

    v_audit_action := 'reinstated';
    v_new := jsonb_build_object('status', 'active');
  end if;

  insert into public.training_behavior_event_audit(
    event_id, action, old_values, new_values, reason,
    changed_by, changed_by_snapshot, changed_at
  ) values (
    v_event.id, v_audit_action, v_old, v_new, btrim(p_reason),
    v_actor, v_actor_name, v_now
  );

  -- Reconcile suspension state in the same transaction. A served suspension
  -- is deliberately never changed by this helper.
  perform public.e05_reconcile_suspensions_after_event_correction(
    v_event.id, v_actor, btrim(p_reason)
  );

  return v_event.id;
end;
$function$;

revoke all on function
  public.correct_training_behavior_event(uuid, text, text)
from public, anon, authenticated, service_role;

grant execute on function
  public.correct_training_behavior_event(uuid, text, text)
to authenticated;


-- 7. End-of-script verification queries (read-only).
--    Run separately after the migration has been approved and executed.
--    Do not interpret this draft's presence as evidence of execution.

commit;

-- Expected signatures after approved execution:
-- public.correct_suspension(uuid, uuid, text)
-- public.correct_training_behavior_event(uuid, text, text)
--
-- Required post-deploy checks:
-- 1. Function definitions and SECURITY DEFINER search_path.
-- 2. EXECUTE grants: authenticated only; no PUBLIC/anon/service_role.
-- 3. RLS remains enabled on all four event/suspension tables.
-- 4. Existing audit append-only triggers remain intact.
-- 5. Audit snapshots populated for new Paket-9 rows.
-- 6. Positive, negative, boundary, regression and concurrency tests.
--
-- Explicitly out of scope:
-- * Any update/delete of served suspensions.
-- * Any rewrite of matchday history or player nomination/attendance.
-- * Any direct table write grants.
-- * Any PROD execution.