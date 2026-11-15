-- DB-MIG-2026-021
-- E05 PROD Paket 10: Trainingsdatumsbasierte Kartenchronologie + alle geplanten Spieltage.
-- Final definitions copied from the live DEV functions after DB-MIG-2026-008 and DB-MIG-2026-010.
-- Replaces only five existing function bodies. No table, column, data, trigger, RLS, policy or grant changes.
-- DB-MIG-2026-009 read-only settings RPCs are intentionally not included: the current
-- suspension-target rule no longer reads game-type settings and the current frontend has no calls to them.
-- DB-MIG-2026-011 nomination guard is a separate package and is not changed here.
-- No backup/PITR prerequisite is introduced. A function-only rollback is supplied separately.
-- Execute only after explicit PROD approval.

begin;

do $preflight$
declare
  v_award text;
  v_assign text;
  v_reconcile text;
  v_correct text;
  v_serve text;
begin
  if to_regclass('public.training_behavior_events') is null
     or to_regclass('public.training_behavior_event_audit') is null
     or to_regclass('public.training_suspensions') is null
     or to_regclass('public.training_suspension_audit') is null
     or to_regclass('public.training_suspension_exceptions') is null
     or to_regclass('public.matchday_early_suspension_resets') is null
     or to_regclass('public.matchdays') is null
     or to_regclass('public.trainings') is null
     or to_regclass('public.attendance') is null then
    raise exception 'Paket 10 Preflight: erforderliche Pakete-1-bis-9-/Paket-8-Tabellen fehlen';
  end if;

  if not exists(select 1 from information_schema.columns
      where table_schema='public' and table_name='training_suspensions'
        and column_name='manual_target_locked')
     or not exists(select 1 from information_schema.columns
      where table_schema='public' and table_name='training_behavior_events'
        and column_name='training_date_snapshot')
     or not exists(select 1 from information_schema.columns
      where table_schema='public' and table_name='training_suspension_audit'
        and column_name='changed_by_snapshot')
     or not exists(select 1 from information_schema.columns
      where table_schema='public' and table_name='training_behavior_event_audit'
        and column_name='changed_by_snapshot') then
    raise exception 'Paket 10 Preflight: Paket-9-Spalten fehlen';
  end if;

  if to_regprocedure('public.award_training_behavior_event(uuid,uuid,text,text)') is null
     or to_regprocedure('public.e05_assign_player_suspensions(uuid,uuid,uuid)') is null
     or to_regprocedure('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)') is null
     or to_regprocedure('public.correct_suspension(uuid,uuid,text)') is null
     or to_regprocedure('public.serve_matchday_suspensions(uuid)') is null then
    raise exception 'Paket 10 Preflight: eine der fünf Zielfunktionen fehlt';
  end if;

  v_award := pg_get_functiondef('public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure);
  v_assign := pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure);
  v_reconcile := pg_get_functiondef('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure);
  v_correct := pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure);
  v_serve := pg_get_functiondef('public.serve_matchday_suspensions(uuid)'::regprocedure);

  -- Fail closed unless PROD is exactly at the expected Paket-9/Paket-8 baseline.
  if position('matchday_early_suspension_resets' in v_award)=0
     or position('e05_reconcile_suspensions_after_event_correction' in v_award)>0 then
    raise exception 'Paket 10 Preflight: award RPC is not the expected Paket-8 PROD baseline';
  end if;
  if position('m.game_type = any(v_types)' in v_assign)=0
     or position('manual_target_locked' in v_assign)=0
     or position('v_trigger_date' in v_assign)>0 then
    raise exception 'Paket 10 Preflight: allocator differs from the expected Paket-9 PROD baseline';
  end if;
  if position('awarded_at > v_yellow_since' in v_reconcile)=0
     or position('matchday_early_suspension_resets' in v_reconcile)=0
     or position('training_date_snapshot > v_yellow_since' in v_reconcile)>0 then
    raise exception 'Paket 10 Preflight: reconciliation differs from the expected Paket-9/Paket-8 baseline';
  end if;
  if position('Target matchday game type is not configured as suspension-relevant' in v_correct)=0
     or position('manual_target_locked = true' in v_correct)=0
     or position('v_trigger_date' in v_correct)>0 then
    raise exception 'Paket 10 Preflight: manual correction differs from the expected Paket-9 baseline';
  end if;
  if position('v_game_type' in v_serve)=0
     or position('This matchday game type is not relevant for suspensions' in v_serve)=0
     or position('training_date_snapshot' in v_serve)>0 then
    raise exception 'Paket 10 Preflight: suspension-serving RPC differs from the expected pre-Paket-10 baseline';
  end if;

  -- Preserve the security contract and function ownership while replacing bodies.
  if not (select prosecdef and proowner='postgres'::regrole
          from pg_proc where oid='public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure)
     or not (select prosecdef and proowner='postgres'::regrole
          from pg_proc where oid='public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure)
     or not (select prosecdef and proowner='postgres'::regrole
          from pg_proc where oid='public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure)
     or not (select prosecdef and proowner='postgres'::regrole
          from pg_proc where oid='public.correct_suspension(uuid,uuid,text)'::regprocedure)
     or not (select prosecdef and proowner='postgres'::regrole
          from pg_proc where oid='public.serve_matchday_suspensions(uuid)'::regprocedure) then
    raise exception 'Paket 10 Preflight: ownership/SECURITY DEFINER baseline differs';
  end if;
end;
$preflight$;

-- Final DEV definitions: DB-MIG-2026-008 + DB-MIG-2026-010 combined.
CREATE OR REPLACE FUNCTION public.award_training_behavior_event(p_training_id uuid, p_player_id uuid, p_event_type text, p_reason text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
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
  v_yellow_since date;
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
    -- Reuse the same canonical chronology/reconciliation path used by
    -- card voiding and reinstatement. This also handles backdated entries
    -- that change which active event is chronologically fifth.
    perform public.e05_reconcile_suspensions_after_event_correction(
      v_event_id,
      v_actor,
      coalesce(nullif(btrim(p_reason), ''), 'Gelbe Karte erfasst')
    );
  end if;

  if v_suspension_id is not null then
    -- Assign immediately using the canonical configured-game-type and
    -- post-trigger-training-date rules.
    perform public.e05_assign_player_suspensions(
      v_team_id, p_player_id, v_actor
    );

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

CREATE OR REPLACE FUNCTION public.e05_assign_player_suspensions(p_team_id uuid, p_player_id uuid, p_actor_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare
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
  v_trigger_date date;
begin
  select nullif(btrim(pr.display_name), '')
    into v_actor_name
  from public.profiles pr
  where pr.id = p_actor_id;

  if not exists (select 1 from public.teams t where t.id = p_team_id) then
    raise exception using errcode = 'P0002', message = 'Team not found';
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
    and m.match_date > coalesce((select e.training_date_snapshot from public.training_behavior_events e where e.id=s.source_event_id), '-infinity'::date)
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
    select e.training_date_snapshot into v_trigger_date
    from public.training_behavior_events e where e.id=v_suspension.source_event_id;
    if v_trigger_date is null then
      raise exception using errcode='23514', message='Suspension source event has no training date snapshot';
    end if;
    if v_suspension.manual_target_locked is true then
      select exists (
        select 1
        from public.matchdays m
        where m.id = v_suspension.intended_matchday_id
          and m.team_id = p_team_id
          and m.season_id = v_suspension.season_id
          and m.status = 'planned'
          and m.match_date >= current_date
          and m.match_date > v_trigger_date
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

    select m.id, m.match_date, m.opponent
        into v_matchday_id, v_match_date, v_opponent
      from public.matchdays m
      where m.team_id = p_team_id
        and m.season_id = v_suspension.season_id
        and m.status = 'planned'
        and m.match_date >= current_date
        and m.match_date > v_trigger_date
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

CREATE OR REPLACE FUNCTION public.e05_reconcile_suspensions_after_event_correction(p_event_id uuid, p_actor_id uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare
  v_event public.training_behavior_events%rowtype;
  v_actor_name text;
  v_yellow_since date;
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
      select max(s.served_matchday_date_snapshot)
      from public.training_suspensions s
      where s.team_id = v_event.team_id
        and s.season_id = v_event.season_id
        and s.player_id = v_event.player_id
        and s.suspension_type = 'yellow'
        and s.status = 'served'
    ), '-infinity'::date),
    coalesce((
      select max(r.matchday_date_snapshot)
      from public.matchday_early_suspension_resets r
      where r.team_id = v_event.team_id
        and r.season_id = v_event.season_id
        and r.player_id = v_event.player_id
        and r.status = 'applied'
    ), '-infinity'::date)
  ) into v_yellow_since;

  select count(*)::integer
  into v_yellow_count
  from public.training_behavior_events e
  where e.team_id = v_event.team_id
    and e.season_id = v_event.season_id
    and e.player_id = v_event.player_id
    and e.event_type = 'yellow_card'
    and e.status = 'active'
    and e.training_date_snapshot > v_yellow_since;

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
      and e.training_date_snapshot > v_yellow_since
    order by e.training_date_snapshot, e.id
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
    and e.training_date_snapshot > v_yellow_since
  order by e.training_date_snapshot, e.id
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

CREATE OR REPLACE FUNCTION public.correct_suspension(p_suspension_id uuid, p_target_matchday_id uuid, p_reason text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_actor_name text;
  v_suspension public.training_suspensions%rowtype;
  v_target public.matchdays%rowtype;
  v_old jsonb;
  v_new jsonb;
  v_now timestamptz := now();
  v_trigger_date date;
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

  select e.training_date_snapshot into v_trigger_date
  from public.training_behavior_events e where e.id=v_suspension.source_event_id;
  if v_trigger_date is null then
    raise exception using errcode='23514', message='Suspension source event has no training date snapshot';
  end if;
  if v_target.match_date <= v_trigger_date then
    raise exception using errcode='23514', message='Target matchday must be after the training that triggered the suspension';
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

CREATE OR REPLACE FUNCTION public.serve_matchday_suspensions(p_matchday_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_team_id uuid;
  v_match_season_id uuid;
  v_match_date date;
  v_opponent text;
  v_match_status text;
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

  select m.team_id,m.season_id,m.match_date,m.opponent,m.status
    into v_team_id,v_match_season_id,v_match_date,v_opponent,v_match_status
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
  if v_match_status is distinct from 'done' then
    raise exception using errcode='23514', message='Only a completed matchday can serve suspensions';
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

do $postflight$
declare
  v_award text;
  v_assign text;
  v_reconcile text;
  v_correct text;
  v_serve text;
begin
  v_award := pg_get_functiondef('public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure);
  v_assign := pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure);
  v_reconcile := pg_get_functiondef('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure);
  v_correct := pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure);
  v_serve := pg_get_functiondef('public.serve_matchday_suspensions(uuid)'::regprocedure);

  if position('e05_reconcile_suspensions_after_event_correction' in v_award)=0
     or position('training_date_snapshot' in v_award)=0 then
    raise exception 'Paket 10 Postflight: yellow-card creation does not use the shared training-date reconciliation';
  end if;
  if position('training_date_snapshot > v_yellow_since' in v_reconcile)=0
     or position('order by e.training_date_snapshot, e.id' in lower(v_reconcile))=0
     or position('awarded_at > v_yellow_since' in v_reconcile)>0
     or position('matchday_early_suspension_resets' in v_reconcile)=0 then
    raise exception 'Paket 10 Postflight: yellow-card chronology/reset boundary is incorrect';
  end if;
  if position('m.match_date > v_trigger_date' in v_assign)=0
     or position('manual_target_locked' in v_assign)=0
     or position('game_type' in lower(v_assign))>0 then
    raise exception 'Paket 10 Postflight: allocator must use trigger training date, preserve manual targets, and ignore game_type';
  end if;
  if position('v_target.match_date <= v_trigger_date' in v_correct)=0
     or position('manual_target_locked = true' in v_correct)=0
     or position('game_type' in lower(v_correct))>0 then
    raise exception 'Paket 10 Postflight: manual correction must require a strictly later matchday and ignore game_type';
  end if;
  if position('v_game_type' in v_serve)>0
     or position('game_type' in lower(v_serve))>0
     or position('v_match_status is distinct from ''done''' in lower(v_serve))=0
     or position('e05_assign_player_suspensions' in v_serve)=0 then
    raise exception 'Paket 10 Postflight: serving must accept all completed matchdays and recalculate remaining suspensions';
  end if;

  if not (select prosecdef and proconfig @> array['search_path=pg_catalog, public, auth']
          from pg_proc where oid='public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure)
     or not (select prosecdef and proconfig @> array['search_path=pg_catalog, public, auth']
          from pg_proc where oid='public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure)
     or not (select prosecdef and proconfig @> array['search_path=pg_catalog, public, auth']
          from pg_proc where oid='public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure)
     or not (select prosecdef and proconfig @> array['search_path=pg_catalog, public, auth']
          from pg_proc where oid='public.correct_suspension(uuid,uuid,text)'::regprocedure)
     or not (select prosecdef and proconfig @> array['search_path=pg_catalog, public, auth']
          from pg_proc where oid='public.serve_matchday_suspensions(uuid)'::regprocedure) then
    raise exception 'Paket 10 Postflight: SECURITY DEFINER/fixed search_path contract changed';
  end if;

  if not has_function_privilege('authenticated','public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('authenticated','public.correct_suspension(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.correct_suspension(uuid,uuid,text)'::regprocedure,'EXECUTE')
     or not has_function_privilege('authenticated','public.serve_matchday_suspensions(uuid)'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.serve_matchday_suspensions(uuid)'::regprocedure,'EXECUTE')
     or has_function_privilege('authenticated','public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure,'EXECUTE')
     or has_function_privilege('authenticated','public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure,'EXECUTE') then
    raise exception 'Paket 10 Postflight: function EXECUTE ACLs changed unexpectedly';
  end if;

  if not (select relrowsecurity from pg_class where oid='public.training_behavior_events'::regclass)
     or not (select relrowsecurity from pg_class where oid='public.training_behavior_event_audit'::regclass)
     or not (select relrowsecurity from pg_class where oid='public.training_suspensions'::regclass)
     or not (select relrowsecurity from pg_class where oid='public.training_suspension_audit'::regclass) then
    raise exception 'Paket 10 Postflight: existing E05 RLS was unexpectedly disabled';
  end if;
end;
$postflight$;

commit;
