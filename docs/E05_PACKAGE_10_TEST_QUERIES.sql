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
