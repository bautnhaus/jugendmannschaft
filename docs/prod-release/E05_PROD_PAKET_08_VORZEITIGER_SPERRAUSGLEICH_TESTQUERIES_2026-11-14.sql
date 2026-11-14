-- E05 PROD Paket 8 – read-only Nachkontrollabfragen

select c.relname,c.relrowsecurity,c.relforcerowsecurity,
       array_agg(a.attname order by a.attnum) as columns
from pg_class c join pg_namespace n on n.oid=c.relnamespace
join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
where n.nspname='public'
  and c.relname in ('matchday_early_suspension_resets','matchday_early_suspension_reset_audit')
group by c.relname,c.relrowsecurity,c.relforcerowsecurity order by c.relname;

select tablename,policyname,cmd,qual from pg_policies
where schemaname='public'
  and tablename in ('matchday_early_suspension_resets','matchday_early_suspension_reset_audit')
order by tablename,policyname;

select table_name,grantee,privilege_type from information_schema.role_table_grants
where table_schema='public'
  and table_name in ('matchday_early_suspension_resets','matchday_early_suspension_reset_audit')
order by table_name,grantee,privilege_type;

select p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef,p.proowner::regrole as owner,p.proconfig,
       has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
       has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
       has_function_privilege('service_role',p.oid,'EXECUTE') as service_role_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('schedule_early_suspension_reset','cancel_early_suspension_reset',
    'e05_transition_early_reset','e05_cancel_early_reset_on_nomination',
    'e05_reconcile_early_resets_on_matchday_status','e05_reject_early_reset_audit_mutation',
    'award_training_behavior_event')
order by p.proname;

select c.relname as table_name,t.tgname,pg_get_triggerdef(t.oid) as definition
from pg_trigger t join pg_class c on c.oid=t.tgrelid
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and t.tgname in ('matchday_players_cancel_early_reset',
    'matchdays_reconcile_early_resets','matchday_early_suspension_reset_audit_no_mutation')
  and not t.tgisinternal order by c.relname,t.tgname;

select (select count(*) from public.matchday_early_suspension_resets) as reset_rows,
       (select count(*) from public.matchday_early_suspension_reset_audit) as audit_rows;

select position('matchday_early_suspension_resets' in
       pg_get_functiondef('public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure)) > 0
       as award_includes_early_reset;
