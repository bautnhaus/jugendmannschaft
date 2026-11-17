-- Read-only postflight: Epic 23 reopened-action constraint hotfix (DEV)
select c.conname, pg_get_constraintdef(c.oid) as definition
from pg_constraint c
where c.conrelid='public.matchday_nomination_reminder_audit'::regclass
  and c.conname='matchday_nomination_reminder_audit_action_check';

select action, count(*) as row_count
from public.matchday_nomination_reminder_audit
group by action
order by action;
