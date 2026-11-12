-- DB-MIG-2026-010
-- E05: every planned matchday is eligible, independent of game_type (including NULL).
-- Prepared for explicit approval. DEV only. NOT EXECUTED.
-- Guarded source transformations fail closed if live DEV definitions have drifted.
-- No table, data, RLS, trigger, or grant changes.

do $migration$
declare
  v_def text;
  v_count integer;
begin
  -- Automatic assignment: preserve team existence, date/team/season/status,
  -- exceptions, manual target reservation/locks, ordering and audit behavior.
  v_def := pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure);
  if position('v_types text[];' in v_def)=0
     or position('if cardinality(v_types) > 0 then' in v_def)=0 then
    raise exception 'DB-MIG-2026-010: assignment function differs from reviewed baseline';
  end if;

  v_def := replace(v_def,'  v_club_id uuid;'||E'\n','');
  v_def := replace(v_def,'  v_types text[];'||E'\n','');
  v_def := replace(v_def,'  v_has_team_override boolean;'||E'\n','');

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

$old_config$,
$new_config$
  if not exists (select 1 from public.teams t where t.id = p_team_id) then
    raise exception using errcode = 'P0002', message = 'Team not found';
  end if;

$new_config$);

  v_count := (length(v_def)-length(replace(v_def,'and m.game_type = any(v_types)','')))/length('and m.game_type = any(v_types)');
  if v_count <> 3 then
    raise exception 'DB-MIG-2026-010: expected 3 assignment game_type filters, found %',v_count;
  end if;
  v_def := replace(v_def,'and m.game_type = any(v_types)'||E'\n','');
  v_def := replace(v_def,'    if cardinality(v_types) > 0 then'||E'\n','');
  v_def := replace(v_def,'      select m.id, m.match_date, m.opponent'||E'\n','    select m.id, m.match_date, m.opponent'||E'\n');
  v_def := replace(v_def,
    '      for update;'||E'\n'||'    end if;'||E'\n'||E'\n'||
    '    if v_matchday_id is not null then',
    '      for update;'||E'\n'||E'\n'||
    '    if v_matchday_id is not null then');
  if position('v_types' in v_def)>0 or position('v_club_id' in v_def)>0 then
    raise exception 'DB-MIG-2026-010: assignment game-type references remain';
  end if;
  execute v_def;

  -- Manual correction: retain all authorization, date, team, season,
  -- exception, duplicate target, manual lock and audit checks.
  v_def := pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure);
  if position('Target matchday game type is not configured as suspension-relevant' in v_def)=0 then
    raise exception 'DB-MIG-2026-010: correction function differs from reviewed baseline';
  end if;
  v_def := replace(v_def,'  v_club_id uuid;'||E'\n','');
  v_def := replace(v_def,'  v_types text[];'||E'\n','');
  v_def := replace(v_def,'  v_has_team_override boolean;'||E'\n','');
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

$old_manual_config$,'');
  if position('v_types' in v_def)>0 or position('v_club_id' in v_def)>0 then
    raise exception 'DB-MIG-2026-010: correction game-type references remain';
  end if;
  execute v_def;

  -- A completed matchday serves a suspension regardless of game_type,
  -- including NULL. Preserve all other serve/sequence/audit behavior.
  v_def := pg_get_functiondef('public.serve_matchday_suspensions(uuid)'::regprocedure);
  if position('This matchday game type is not relevant for suspensions' in v_def)=0 then
    raise exception 'DB-MIG-2026-010: serving function differs from reviewed baseline';
  end if;
  v_def := replace(v_def,'  v_game_type text;'||E'\n','');
  v_def := replace(v_def,'  v_club_id uuid;'||E'\n','');
  v_def := replace(v_def,'  v_types text[];'||E'\n','');
  v_def := replace(v_def,'  v_has_team_override boolean;'||E'\n','');
  v_def := replace(v_def,
    '  select m.team_id,m.season_id,m.match_date,m.opponent,m.game_type,m.status'||E'\n'||
    '    into v_team_id,v_match_season_id,v_match_date,v_opponent,v_game_type,v_match_status',
    '  select m.team_id,m.season_id,m.match_date,m.opponent,m.status'||E'\n'||
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

$old_serve_config$,'');
  if position('v_types' in v_def)>0 or position('v_club_id' in v_def)>0
     or position('v_game_type' in v_def)>0 then
    raise exception 'DB-MIG-2026-010: serving game-type references remain';
  end if;
  execute v_def;
end
$migration$;

-- Verification after execution (read-only): inspect the three pg_get_functiondef
-- outputs, SECURITY DEFINER/search_path, ACLs and confirm no game_type filtering.
