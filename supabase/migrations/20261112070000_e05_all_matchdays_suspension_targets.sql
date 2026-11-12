-- DB-MIG-2026-010
-- E05: All planned matchdays are suspension-relevant, regardless of game_type.
-- Prepared for explicit approval. DEV only. NOT EXECUTED.
-- The guarded replacements deliberately fail if the live DEV function source
-- differs from the reviewed baseline. No tables, data, RLS, or grants are changed.

do $migration$
declare
  v_def text;
  v_count integer;
begin
  -- 1) Automatic assignment: remove club/team game-type configuration and
  --    all game_type filters. Keep date, team, season, status, exceptions,
  --    manual locks, reservation and audit behavior unchanged.
  v_def := pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure);

  if position('v_types text[];' in v_def) = 0
     or position('if cardinality(v_types) > 0 then' in v_def) = 0
     or position('and m.game_type = any(v_types)' in v_def) = 0 then
    raise exception 'DB-MIG-2026-010: e05_assign_player_suspensions differs from reviewed baseline';
  end if;

  v_def := replace(v_def, '  v_club_id uuid;' || E'\n', '');
  v_def := replace(v_def, '  v_types text[];' || E'\n', '');
  v_def := replace(v_def, '  v_has_team_override boolean;' || E'\n', '');

  v_def := replace(v_def,
$old_config$
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

$old_config$, '');

  v_count := (length(v_def) - length(replace(v_def, 'and m.game_type = any(v_types)', ''))) / length('and m.game_type = any(v_types)');
  if v_count <> 3 then
    raise exception 'DB-MIG-2026-010: expected 3 game_type filters in assignment function, found %', v_count;
  end if;
  v_def := replace(v_def, '        and m.game_type = any(v_types)' || E'\n', '');

  v_def := replace(v_def, '    if cardinality(v_types) > 0 then' || E'\n', '');
  v_def := replace(v_def, '      select m.id, m.match_date, m.opponent' || E'\n', '    select m.id, m.match_date, m.opponent' || E'\n');
  v_def := replace(v_def,
    '      limit 1' || E'\n' ||
    '      for update;' || E'\n' ||
    '    end if;' || E'\n' ||
    E'\n' ||
    '    if v_matchday_id is not null then',
    '      limit 1' || E'\n' ||
    '      for update;' || E'\n' ||
    E'\n' ||
    '    if v_matchday_id is not null then');
  if position('v_types' in v_def) > 0 or position('v_club_id' in v_def) > 0
     or position('cardinality(v_types)' in v_def) > 0 then
    raise exception 'DB-MIG-2026-010: game-type configuration references remain in assignment function';
  end if;
  execute v_def;

  -- 2) Manual correction: retain permission, chronology, future/planned
  --    target, same team/season, exception, duplicate-target and audit checks.
  v_def := pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure);
  if position('Target matchday game type is not configured as suspension-relevant' in v_def) = 0 then
    raise exception 'DB-MIG-2026-010: correct_suspension differs from reviewed baseline';
  end if;

  v_def := replace(v_def, '  v_club_id uuid;' || E'\n', '');
  v_def := replace(v_def, '  v_types text[];' || E'\n', '');
  v_def := replace(v_def, '  v_has_team_override boolean;' || E'\n', '');
  v_def := replace(v_def,
$old_manual_config$
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

$old_manual_config$, '');
  if position('v_types' in v_def) > 0 or position('v_club_id' in v_def) > 0
     or position('game_type' in v_def) > 0 then
    raise exception 'DB-MIG-2026-010: game-type configuration references remain in correct_suspension';
  end if;
  execute v_def;

  -- 3) Serving a suspension: every completed matchday can serve it,
  --    including game_type NULL. Retain authentication, team permission,
  --    completed-status, sequencing, audit and post-service reassignment.
  v_def := pg_get_functiondef('public.serve_matchday_suspensions(uuid)'::regprocedure);
  if position('This matchday game type is not relevant for suspensions' in v_def) = 0 then
    raise exception 'DB-MIG-2026-010: serve_matchday_suspensions differs from reviewed baseline';
  end if;

  v_def := replace(v_def, '  v_game_type text;' || E'\n', '');
  v_def := replace(v_def, '  v_club_id uuid;' || E'\n', '');
  v_def := replace(v_def, '  v_types text[];' || E'\n', '');
  v_def := replace(v_def, '  v_has_team_override boolean;' || E'\n', '');
  v_def := replace(v_def,
    '  select m.team_id,m.season_id,m.match_date,m.opponent,m.game_type,m.status' || E'\n' ||
    '    into v_team_id,v_match_season_id,v_match_date,v_opponent,v_game_type,v_match_status',
    '  select m.team_id,m.season_id,m.match_date,m.opponent,m.status' || E'\n' ||
    '    into v_team_id,v_match_season_id,v_match_date,v_opponent,v_match_status');

  v_def := replace(v_def,
$old_serve_config$
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

$old_serve_config$, '');
  if position('suspension_game_type' in v_def) > 0 or position('v_types' in v_def) > 0
     or position('v_game_type' in v_def) > 0 then
    raise exception 'DB-MIG-2026-010: game-type configuration references remain in serve_matchday_suspensions';
  end if;
  execute v_def;
end
$migration$;

-- Post-migration invariant checks (read-only):
-- 1) The three function definitions no longer reference suspension game-type settings.
-- 2) EXECUTE ACLs, SECURITY DEFINER, search_path and function signatures remain unchanged.
-- 3) No tables, rows, RLS policies, triggers, or historical audit entries are changed.
