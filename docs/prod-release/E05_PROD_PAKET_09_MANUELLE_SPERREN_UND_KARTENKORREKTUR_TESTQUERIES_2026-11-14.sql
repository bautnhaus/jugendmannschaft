-- E05 PROD Paket 9 – read-only Nachkontrolle
-- Ausschließlich SELECTs; nach einer freigegebenen Ausführung ausführen.

select c.relname,c.relrowsecurity,c.relforcerowsecurity,
       array_agg(a.attname order by a.attnum) as columns
from pg_class c
join pg_namespace n on n.oid=c.relnamespace
join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
where n.nspname='public'
  and c.relname in ('training_behavior_events','training_behavior_event_audit',
                    'training_suspensions','training_suspension_audit')
group by c.relname,c.relrowsecurity,c.relforcerowsecurity
order by c.relname;

select table_name,column_name,data_type,is_nullable,column_default
from information_schema.columns
where table_schema='public'
  and ((table_name='training_behavior_event_audit' and column_name='changed_by_snapshot')
    or (table_name='training_suspension_audit' and column_name='changed_by_snapshot')
    or (table_name='training_suspensions' and column_name='manual_target_locked'))
order by table_name,column_name;

select p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef,pg_get_userbyid(p.proowner) as owner,p.proconfig,
       has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
       has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
       has_function_privilege('service_role',p.oid,'EXECUTE') as service_role_execute,
       pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('e05_assert_suspension_correction_permission',
    'e05_reconcile_suspensions_after_event_correction',
    'correct_suspension','correct_training_behavior_event',
    'e05_assign_player_suspensions','award_training_behavior_event')
order by p.proname;

select c.relname as table_name,t.tgname,pg_get_triggerdef(t.oid) as definition
from pg_trigger t
join pg_class c on c.oid=t.tgrelid
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname in ('training_behavior_event_audit','training_suspension_audit')
  and not t.tgisinternal
order by c.relname,t.tgname;

select tablename,policyname,cmd,roles,qual
from pg_policies
where schemaname='public'
  and tablename in ('training_behavior_events','training_behavior_event_audit',
                    'training_suspensions','training_suspension_audit')
order by tablename,policyname;

select
 (select count(*) from public.training_behavior_events) as behavior_events,
 (select count(*) from public.training_behavior_event_audit) as event_audit_rows,
 (select count(*) from public.training_suspensions) as suspensions,
 (select count(*) from public.training_suspension_audit) as suspension_audit_rows,
 (select count(*) from public.training_suspensions where status='open') as open_suspensions,
 (select count(*) from public.training_suspensions where manual_target_locked is true) as manually_locked_targets;

select
 position('PERFORM p.id' in pg_get_functiondef(
  'public.correct_training_behavior_event(uuid,text,text)'::regprocedure))>0
 as corrected_player_row_lock,
 position('manual_target_locked' in pg_get_functiondef(
  'public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure))>0
 as allocator_preserves_manual_targets,
 position('matchday_early_suspension_resets' in pg_get_functiondef(
  'public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure))>0
 as correction_respects_early_resets,
 position('m.game_type = any(v_types)' in pg_get_functiondef(
  'public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure))>0
 as package10_all_matchdays_not_deployed;
