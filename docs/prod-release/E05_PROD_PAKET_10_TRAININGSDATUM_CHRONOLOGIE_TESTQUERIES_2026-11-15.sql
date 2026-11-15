-- E05 PROD Paket 10 – read-only pre/post verification
-- No statements in this file modify data or schema.

-- 1. Function signatures, ownership, SECURITY DEFINER, search_path and ACLs.
select p.proname,pg_get_function_identity_arguments(p.oid) arguments,
       p.prosecdef security_definer,pg_get_userbyid(p.proowner) owner,p.proconfig,
       has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_execute,
       has_function_privilege('anon',p.oid,'EXECUTE') anon_execute,
       has_function_privilege('service_role',p.oid,'EXECUTE') service_role_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('award_training_behavior_event','e05_assign_player_suspensions',
    'e05_reconcile_suspensions_after_event_correction','correct_suspension',
    'serve_matchday_suspensions')
order by p.proname;

-- 2. Training-date chronology markers (should all be true after Paket 10).
select
 position('e05_reconcile_suspensions_after_event_correction' in
  pg_get_functiondef('public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure))>0
  as yellow_award_uses_reconciliation,
 position('training_date_snapshot > v_yellow_since' in
  pg_get_functiondef('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure))>0
  as chronology_uses_training_date,
 position('order by e.training_date_snapshot, e.id' in lower(
  pg_get_functiondef('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure)))>0
  as fifth_card_order_is_training_date,
 position('m.match_date > v_trigger_date' in
  pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure))>0
  as target_after_trigger_training,
 position('v_target.match_date <= v_trigger_date' in
  pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure))>0
  as manual_correction_rejects_not_after_trigger;

-- 3. All planned matchdays independent of game_type (should be true after Paket 10).
select
 position('game_type' in lower(pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure)))=0
  as allocator_ignores_game_type,
 position('game_type' in lower(pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure)))=0
  as manual_correction_ignores_game_type,
 position('game_type' in lower(pg_get_functiondef('public.serve_matchday_suspensions(uuid)'::regprocedure)))=0
  as serving_ignores_game_type;

-- 4. Early-reset lower bound retained.
select position('matchday_early_suspension_resets' in
 pg_get_functiondef('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure))>0
 as early_reset_boundary_preserved;

-- 5. Existing data diagnostics (read-only).
select
 (select count(*) from public.training_behavior_events) events,
 (select count(*) from public.training_behavior_event_audit) event_audits,
 (select count(*) from public.training_suspensions) suspensions,
 (select count(*) from public.training_suspension_audit) suspension_audits,
 (select count(*) from public.training_suspensions where status='open') open_suspensions,
 (select count(*) from public.training_suspensions where status='open' and intended_matchday_id is null) open_without_target;
