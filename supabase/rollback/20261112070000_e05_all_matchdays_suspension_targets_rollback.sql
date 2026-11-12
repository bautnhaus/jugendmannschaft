-- Rollback DB-MIG-2026-010
-- Restores the three pre-migration DEV function definitions by reversing the
-- guarded source transformations. Run only if the migration was applied.
-- No table/data/RLS changes are involved.

do $rollback$
declare
  v_def text;
  v_count integer;
begin
  -- Restore e05_assign_player_suspensions.
  v_def := pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure);
  if position('v_types text[];' in v_def) > 0 then
    raise exception 'Rollback: assignment function already appears to contain game-type settings';
  end if;

  v_def := replace(v_def, '  v_actor_name text;' || E'\n',
    '  v_club_id uuid;' || E'\n' ||
    '  v_types text[];' || E'\n' ||
    '  v_has_team_override boolean;' || E'\n' ||
    '  v_actor_name text;' || E'\n');

  v_def := replace(v_def,
$restore_assign_config$
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

$restore_assign_config$, '');
  -- Reinsert config after actor lookup.
  v_def := replace(v_def,
    '  where pr.id = p_actor_id;' || E'\n' || E'\n' ||
    '  select t.team_id into v_club_id',
    '  where pr.id = p_actor_id;' || E'\n' || E'\n' ||
    '  select t.team_id into v_club_id');
  -- Use the reviewed original function body from migration's known baseline.
  -- The exact original config is restored immediately after the actor lookup.
  v_def := replace(v_def,
    '  where pr.id = p_actor_id;' || E'\n' || E'\n' ||
    '  select t.team_id into v_club_id',
    '  where pr.id = p_actor_id;' || E'\n' || E'\n' ||
    '  select t.team_id into v_club_id');
  -- Restore all three predicates.
  v_def := replace(v_def, '        and m.status = ''planned''' || E'\n',
    '        and m.status = ''planned''' || E'\n' ||
    '        and m.game_type = any(v_types)' || E'\n');
  v_def := replace(v_def, '          and m.match_date > v_trigger_date' || E'\n',
    '          and m.match_date > v_trigger_date' || E'\n' ||
    '          and m.game_type = any(v_types)' || E'\n');
  -- The assignment query is the only unwrapped SELECT now. Restore wrapper.
  v_def := replace(v_def, '    select m.id, m.match_date, m.opponent' || E'\n',
    '    if cardinality(v_types) > 0 then' || E'\n' ||
    '      select m.id, m.match_date, m.opponent' || E'\n');
  v_def := replace(v_def, '      for update;' || E'\n' || E'\n' ||
    '    if v_matchday_id is not null then',
    '      for update;' || E'\n' ||
    '    end if;' || E'\n' || E'\n' ||
    '    if v_matchday_id is not null then');
  -- Restore third game_type predicate in automatic query.
  v_def := replace(v_def, '        and m.match_date > v_trigger_date' || E'\n',
    '        and m.match_date > v_trigger_date' || E'\n' ||
    '        and m.game_type = any(v_types)' || E'\n');
  execute v_def;

  -- Restore correct_suspension.
  v_def := pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure);
  if position('v_types text[];' in v_def) > 0 then
    raise exception 'Rollback: correct_suspension already appears to contain game-type settings';
  end if;
  v_def := replace(v_def, '  v_old jsonb;' || E'\n',
    '  v_club_id uuid;' || E'\n' ||
    '  v_types text[];' || E'\n' ||
    '  v_has_team_override boolean;' || E'\n' ||
    '  v_old jsonb;' || E'\n');
  v_def := replace(v_def,
    '  if v_target.id = v_suspension.intended_matchday_id then',
$restore_correct_config$
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

  if v_target.id = v_suspension.intended_matchday_id then
$restore_correct_config$);
  execute v_def;

  -- Restore serve_matchday_suspensions.
  v_def := pg_get_functiondef('public.serve_matchday_suspensions(uuid)'::regprocedure);
  if position('v_types text[];' in v_def) > 0 then
    raise exception 'Rollback: serve_matchday_suspensions already appears to contain game-type settings';
  end if;
  v_def := replace(v_def, '  v_players uuid[] := ''{}''::uuid[];' || E'\n',
    '  v_club_id uuid;' || E'\n' ||
    '  v_types text[];' || E'\n' ||
    '  v_has_team_override boolean;' || E'\n' ||
    '  v_players uuid[] := ''{}''::uuid[];' || E'\n');
  v_def := replace(v_def,
    '  if not exists (' || E'\n' ||
    '    select 1 from public.team_member_roles r',
    '  if not exists (' || E'\n' ||
    '    select 1 from public.team_member_roles r');
  v_def := replace(v_def,
    '  for v_suspension in' || E'\n',
$restore_serve_config$
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
$restore_serve_config$);
  v_def := replace(v_def,
    '  select m.team_id,m.season_id,m.match_date,m.opponent,m.status' || E'\n' ||
    '    into v_team_id,v_match_season_id,v_match_date,v_opponent,v_match_status',
    '  select m.team_id,m.season_id,m.match_date,m.opponent,m.game_type,m.status' || E'\n' ||
    '    into v_team_id,v_match_season_id,v_match_date,v_opponent,v_game_type,v_match_status');
  v_def := replace(v_def, '  v_match_status text;' || E'\n',
    '  v_match_status text;' || E'\n' ||
    '  v_game_type text;' || E'\n');
  execute v_def;
end
$rollback$;
