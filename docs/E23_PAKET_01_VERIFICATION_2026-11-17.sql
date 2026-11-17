-- Epic 23 – Paket 1: read-only verification queries (DEV)
-- Run after migration. All statements are SELECT-only.

select to_regclass('public.matchday_nomination_reminders') as reminders_table,
       to_regclass('public.matchday_nomination_reminder_audit') as audit_table,
       to_regprocedure('public.create_matchday_nomination_reminder(uuid,uuid,text,boolean)') as create_rpc,
       to_regprocedure('public.cancel_matchday_nomination_reminder(uuid,text)') as cancel_rpc,
       to_regprocedure('public.epic23_fulfill_nomination_reminder()') as fulfillment_trigger_function;

select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname in ('matchday_nomination_reminders','matchday_nomination_reminder_audit');

select p.proname, p.prosecdef, p.proconfig,
       has_function_privilege('anon',p.oid,'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_can_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('create_matchday_nomination_reminder',
                    'cancel_matchday_nomination_reminder',
                    'epic23_fulfill_nomination_reminder',
                    'epic23_reject_nomination_reminder_audit_mutation')
order by p.proname;

select c.relname as table_name,t.tgname,pg_get_triggerdef(t.oid) as definition
from pg_trigger t join pg_class c on c.oid=t.tgrelid
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and not t.tgisinternal
  and (t.tgname='matchday_players_fulfill_nomination_reminder'
       or t.tgname='matchday_nomination_reminder_audit_no_mutation');

select schemaname,tablename,policyname,cmd,roles,qual,with_check
from pg_policies
where schemaname='public'
  and tablename in ('matchday_nomination_reminders','matchday_nomination_reminder_audit')
order by tablename,policyname;

select status,count(*) from public.matchday_nomination_reminders group by status order by status;
select action,count(*) from public.matchday_nomination_reminder_audit group by action order by action;
