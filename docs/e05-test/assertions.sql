\set ON_ERROR_STOP on

-- Structural assertions: 10 new tables, all RLS-enabled, each with one SELECT policy.
do $$
declare
  v_count integer;
begin
  select count(*) into v_count
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind='r'
    and c.relname in (
      'training_behavior_events','training_behavior_event_audit','training_suspensions',
      'training_suspension_exceptions','training_suspension_audit','club_suspension_settings',
      'team_suspension_game_type_settings','team_suspension_game_types',
      'matchday_early_suspension_resets','matchday_early_suspension_reset_audit'
    );
  if v_count <> 10 then raise exception 'Expected 10 tables, got %',v_count; end if;

  select count(*) into v_count
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relname in (
      'training_behavior_events','training_behavior_event_audit','training_suspensions',
      'training_suspension_exceptions','training_suspension_audit','club_suspension_settings',
      'team_suspension_game_type_settings','team_suspension_game_types',
      'matchday_early_suspension_resets','matchday_early_suspension_reset_audit'
    ) and c.relrowsecurity;
  if v_count <> 10 then raise exception 'RLS is not enabled on all 10 tables'; end if;

  select count(*) into v_count from pg_policies
  where schemaname='public' and tablename in (
      'training_behavior_events','training_behavior_event_audit','training_suspensions',
      'training_suspension_exceptions','training_suspension_audit','club_suspension_settings',
      'team_suspension_game_type_settings','team_suspension_game_types',
      'matchday_early_suspension_resets','matchday_early_suspension_reset_audit'
    );
  if v_count <> 10 then raise exception 'Expected 10 SELECT policies, got %',v_count; end if;
end $$;

-- Client roles have SELECT only; service_role has the explicitly granted backend surface.
do $$
begin
  if has_table_privilege('authenticated','public.training_behavior_events','insert')
    or has_table_privilege('authenticated','public.training_behavior_events','update')
    or has_table_privilege('authenticated','public.training_behavior_events','delete')
  then raise exception 'authenticated unexpectedly has event write privileges'; end if;
  if not has_table_privilege('authenticated','public.training_behavior_events','select')
  then raise exception 'authenticated is missing event SELECT'; end if;
  if not has_table_privilege('service_role','public.training_behavior_events','insert')
  then raise exception 'service_role is missing backend INSERT'; end if;
end $$;

-- Seed disposable data.
insert into public.clubs(id,name) values ('10000000-0000-0000-0000-000000000001','Test Club');
insert into public.teams(id,club_id,name) values ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Test Team');
insert into public.players(id,team_id,name) values ('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Test Player');
insert into auth.users(id) values ('40000000-0000-0000-0000-000000000001');
insert into public.club_suspension_settings(club_id,relevant_game_types)
values ('10000000-0000-0000-0000-000000000001',array['Meisterschaft']::text[]);
insert into public.team_suspension_game_type_settings(team_id)
values ('20000000-0000-0000-0000-000000000001');
-- Empty child list must be a valid full override.
do $$
begin
 if exists(select 1 from public.team_suspension_game_types where team_id='20000000-0000-0000-0000-000000000001')
 then raise exception 'Unexpected child row in empty team override'; end if;
end $$;

insert into public.training_behavior_events(
 id,team_id,team_name_snapshot,season_id,season_name_snapshot,training_id,
 training_date_snapshot,training_name_snapshot,player_id,player_name_snapshot,
 event_type,reason,awarded_by,awarded_by_snapshot
) values (
 '50000000-0000-0000-0000-000000000001',
 '20000000-0000-0000-0000-000000000001','Test Team',
 '60000000-0000-0000-0000-000000000001','Season 2026/27',
 '70000000-0000-0000-0000-000000000001',date '2026-11-07','Training',
 '30000000-0000-0000-0000-000000000001','Test Player',
 'yellow_card','Test reason','40000000-0000-0000-0000-000000000001','Test Coach'
);
-- One positive star may coexist with one card.
insert into public.training_behavior_events(
 id,team_id,team_name_snapshot,season_id,season_name_snapshot,training_id,
 training_date_snapshot,training_name_snapshot,player_id,player_name_snapshot,
 event_type,awarded_by,awarded_by_snapshot
) values (
 '50000000-0000-0000-0000-000000000002',
 '20000000-0000-0000-0000-000000000001','Test Team',
 '60000000-0000-0000-0000-000000000001','Season 2026/27',
 '70000000-0000-0000-0000-000000000001',date '2026-11-07','Training',
 '30000000-0000-0000-0000-000000000001','Test Player',
 'positive_star','40000000-0000-0000-0000-000000000001','Test Coach'
);

-- Duplicate card and duplicate star are rejected by partial unique indexes.
do $$
begin
  begin
    insert into public.training_behavior_events(
      team_id,team_name_snapshot,season_id,season_name_snapshot,training_id,
      training_date_snapshot,training_name_snapshot,player_id,player_name_snapshot,
      event_type,reason
    ) values (
      '20000000-0000-0000-0000-000000000001','Test Team',
      '60000000-0000-0000-0000-000000000001','Season 2026/27',
      '70000000-0000-0000-0000-000000000001',date '2026-11-07','Training',
      '30000000-0000-0000-0000-000000000001','Test Player','red_card','Duplicate'
    );
    raise exception 'Duplicate card unexpectedly succeeded';
  exception when unique_violation then null;
  end;
  begin
    insert into public.training_behavior_events(
      team_id,team_name_snapshot,season_id,season_name_snapshot,training_id,
      training_date_snapshot,training_name_snapshot,player_id,player_name_snapshot,
      event_type
    ) values (
      '20000000-0000-0000-0000-000000000001','Test Team',
      '60000000-0000-0000-0000-000000000001','Season 2026/27',
      '70000000-0000-0000-0000-000000000001',date '2026-11-07','Training',
      '30000000-0000-0000-0000-000000000001','Test Player','positive_star'
    );
    raise exception 'Duplicate star unexpectedly succeeded';
  exception when unique_violation then null;
  end;
end $$;

-- One event cannot create two suspensions; distinct red events can remain open concurrently.
insert into public.training_suspensions(
 id,team_id,team_name_snapshot,season_id,season_name_snapshot,player_id,player_name_snapshot,
 source_event_id,suspension_type,status
) values (
 '80000000-0000-0000-0000-000000000001',
 '20000000-0000-0000-0000-000000000001','Test Team',
 '60000000-0000-0000-0000-000000000001','Season 2026/27',
 '30000000-0000-0000-0000-000000000001','Test Player',
 '50000000-0000-0000-0000-000000000001','yellow','open'
);
do $$
begin
 begin
  insert into public.training_suspensions(
    team_id,team_name_snapshot,season_id,season_name_snapshot,player_id,player_name_snapshot,
    source_event_id,suspension_type,status
  ) values (
    '20000000-0000-0000-0000-000000000001','Test Team',
    '60000000-0000-0000-0000-000000000001','Season 2026/27',
    '30000000-0000-0000-0000-000000000001','Test Player',
    '50000000-0000-0000-0000-000000000001','yellow','open'
  );
  raise exception 'Duplicate source event unexpectedly succeeded';
 exception when unique_violation then null;
 end;
end $$;

-- Player and Auth deletion preserve historical snapshots.
delete from public.players where id='30000000-0000-0000-0000-000000000001';
delete from auth.users where id='40000000-0000-0000-0000-000000000001';
do $$
begin
 if not exists(select 1 from public.training_behavior_events
   where id='50000000-0000-0000-0000-000000000001'
     and player_id is null and player_name_snapshot='Test Player'
     and awarded_by is null and awarded_by_snapshot='Test Coach')
 then raise exception 'Player/actor snapshot retention failed'; end if;
end $$;

-- Team/season/training/matchday IDs are snapshots, so deleting operational records
-- does not cascade or block historical rows.
insert into public.trainings(id,team_id,training_date,name,status)
values ('70000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',date '2026-11-07','Training','done');
delete from public.trainings where id='70000000-0000-0000-0000-000000000001';
do $$
begin
 if not exists(select 1 from public.training_behavior_events
   where id='50000000-0000-0000-0000-000000000001'
     and training_id='70000000-0000-0000-0000-000000000001'
     and training_name_snapshot='Training')
 then raise exception 'Training snapshot was not retained'; end if;
end $$;

-- RLS: team member can read its rows; non-member cannot.
insert into public.training_behavior_events(
 id,team_id,team_name_snapshot,season_id,season_name_snapshot,training_id,
 training_date_snapshot,training_name_snapshot,player_name_snapshot,event_type,reason
) values (
 '50000000-0000-0000-0000-000000000003',
 '20000000-0000-0000-0000-000000000001','Test Team',
 '60000000-0000-0000-0000-000000000001','Season 2026/27',
 '70000000-0000-0000-0000-000000000002',date '2026-11-08','Training 2',
 'Deleted Player','yellow_card','RLS seed'
);
set role authenticated;
select set_config('test.team_member_team','20000000-0000-0000-0000-000000000001',false);
select count(*) = 1 as team_member_reads_event
from public.training_behavior_events
where id='50000000-0000-0000-0000-000000000003' \gset
\if :team_member_reads_event
\echo 'PASS: team member SELECT policy'
\else
\quit 1
\endif
select set_config('test.team_member_team','',false);
select count(*) = 0 as non_member_cannot_read
from public.training_behavior_events
where id='50000000-0000-0000-0000-000000000003' \gset
\if :non_member_cannot_read
\echo 'PASS: non-member denied by RLS'
\else
\quit 1
\endif

-- Club administrator needs a selected club context, not membership alone.
select set_config('test.can_manage_club','true',false);
select count(*) = 0 as no_selected_club_context
from public.club_suspension_settings
where club_id='10000000-0000-0000-0000-000000000001' \gset
\if :no_selected_club_context
\echo 'PASS: club admin without selected context denied'
\else
\quit 1
\endif
reset role;

insert into public.user_club_context(user_id,club_id)
values ('40000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001');
set role authenticated;
select set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000002',false);
select set_config('test.can_manage_club','true',false);
select count(*) = 1 as selected_club_admin_reads
from public.club_suspension_settings
where club_id='10000000-0000-0000-0000-000000000001' \gset
\if :selected_club_admin_reads
\echo 'PASS: selected club admin SELECT policy'
\else
\quit 1
\endif
reset role;

\echo 'PASS: E05 schema foundation PostgreSQL 17 test suite completed'
