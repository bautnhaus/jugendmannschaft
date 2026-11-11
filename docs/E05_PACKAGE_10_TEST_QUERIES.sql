-- E05 Package 10 read-only verification queries
-- Run before and after migration; these queries do not mutate data.
-- 1. Yellow-card chronology by training date (not entry timestamp)
select team_id, season_id, player_id, training_date_snapshot, awarded_at, id, status
from public.training_behavior_events
where event_type='yellow_card'
order by team_id, season_id, player_id, training_date_snapshot, id;

-- 2. Suspensions and source training date
select s.id, s.player_id, s.status, s.suspension_type, s.source_event_id,
       e.training_date_snapshot as trigger_training_date,
       s.intended_matchday_id, s.intended_matchday_date_snapshot,
       s.manual_target_locked
from public.training_suspensions s
left join public.training_behavior_events e on e.id=s.source_event_id
order by s.created_at, s.id;

-- 3. Open suspensions whose target is not strictly after trigger date
select s.id, s.player_id, e.training_date_snapshot, m.match_date, m.game_type, m.status
from public.training_suspensions s
join public.training_behavior_events e on e.id=s.source_event_id
left join public.matchdays m on m.id=s.intended_matchday_id
where s.status='open'
  and (m.id is null or m.match_date <= e.training_date_snapshot);

-- 4. Existing game-type configuration (read-only; must remain unchanged)
select t.id team_id, t.club_id,
       exists(select 1 from public.team_suspension_game_type_settings x where x.team_id=t.id) has_team_override,
       (select array_agg(g.game_type order by g.game_type) from public.team_suspension_game_types g where g.team_id=t.id) team_types,
       (select c.relevant_game_types from public.club_suspension_settings c where c.club_id=t.club_id) club_types
from public.teams t;

-- 5. Count of active yellow cards per player/season, ranked by training date
with ranked as (
  select e.team_id,e.season_id,e.player_id,e.id,e.training_date_snapshot,e.awarded_at,
         row_number() over (
           partition by e.team_id,e.season_id,e.player_id
           order by e.training_date_snapshot,e.id
         ) as training_date_rank
  from public.training_behavior_events e
  where e.event_type='yellow_card' and e.status='active'
)
select * from ranked
order by team_id,season_id,player_id,training_date_rank;

-- 6. Open suspensions whose source is not the currently calculated fifth active card.
-- This query is diagnostic; served suspensions and applied resets establish the lower bound.
with lower_bounds as (
  select t.team_id,t.season_id,t.player_id,
         greatest(
           coalesce((select max(s.served_matchday_date_snapshot)
                     from public.training_suspensions s
                     where s.team_id=t.team_id and s.season_id=t.season_id
                       and s.player_id=t.player_id and s.suspension_type='yellow'
                       and s.status='served'),'-infinity'::date),
           coalesce((select max(r.matchday_date_snapshot)
                     from public.matchday_early_suspension_resets r
                     where r.team_id=t.team_id and r.season_id=t.season_id
                       and r.player_id=t.player_id and r.status='applied'),'-infinity'::date)
         ) as lower_bound
  from (select distinct team_id,season_id,player_id
        from public.training_behavior_events
        where event_type='yellow_card') t
), expected as (
  select e.team_id,e.season_id,e.player_id,e.id,
         row_number() over (
           partition by e.team_id,e.season_id,e.player_id
           order by e.training_date_snapshot,e.id
         ) rn
  from public.training_behavior_events e
  join lower_bounds b using(team_id,season_id,player_id)
  where e.event_type='yellow_card' and e.status='active'
    and e.training_date_snapshot>b.lower_bound
)
select s.id suspension_id,s.team_id,s.season_id,s.player_id,
       s.source_event_id,expected.id expected_fifth_event_id
from public.training_suspensions s
left join expected on expected.team_id=s.team_id
  and expected.season_id=s.season_id and expected.player_id=s.player_id
  and expected.rn=5
where s.suspension_type='yellow' and s.status='open'
  and s.source_event_id is distinct from expected.id;

-- 7. All assigned open suspensions must target a planned, configured,
-- strictly post-trigger matchday. Also reports missing targets separately.
with effective_types as (
  select t.id team_id,
         case when exists(select 1 from public.team_suspension_game_type_settings x where x.team_id=t.id)
              then coalesce((select array_agg(g.game_type) from public.team_suspension_game_types g where g.team_id=t.id),'{}'::text[])
              else coalesce((select c.relevant_game_types from public.club_suspension_settings c where c.club_id=t.club_id),'{}'::text[])
         end game_types
  from public.teams t
)
select s.id suspension_id,s.player_id,s.source_event_id,
       e.training_date_snapshot trigger_date,
       m.id target_matchday_id,m.match_date,m.game_type,m.status,
       coalesce(et.game_types,'{}'::text[]) configured_game_types,
       case when m.id is null then 'NO_TARGET'
            when m.match_date<=e.training_date_snapshot then 'TARGET_NOT_AFTER_TRIGGER'
            when m.status<>'planned' then 'TARGET_NOT_PLANNED'
            when not (m.game_type=any(et.game_types)) then 'TARGET_GAME_TYPE_NOT_CONFIGURED'
            else 'OK' end validation
from public.training_suspensions s
join public.training_behavior_events e on e.id=s.source_event_id
left join public.matchdays m on m.id=s.intended_matchday_id
left join effective_types et on et.team_id=s.team_id
where s.status='open'
order by s.created_at,s.id;

-- 8. Audit trail for suspension creation, target correction and reassignment
select suspension_id,action,old_values,new_values,reason,
       changed_by,changed_by_snapshot,changed_at
from public.training_suspension_audit
order by changed_at desc,id desc
limit 250;

-- 9. Function security/grants after applying the migration.
-- Expected: four functions SECURITY DEFINER, fixed search_path, authenticated
-- EXECUTE only for award_training_behavior_event and correct_suspension;
-- internal assignment/reconciliation helpers remain non-callable by API roles.
select p.proname,pg_get_function_identity_arguments(p.oid) arguments,
       p.prosecdef security_definer,p.proconfig,
       has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_execute,
       has_function_privilege('anon',p.oid,'EXECUTE') anon_execute,
       has_function_privilege('service_role',p.oid,'EXECUTE') service_role_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('award_training_behavior_event','e05_assign_player_suspensions',
                    'e05_reconcile_suspensions_after_event_correction','correct_suspension')
order by p.proname;
