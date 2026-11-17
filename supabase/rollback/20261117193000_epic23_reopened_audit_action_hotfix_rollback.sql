-- Guarded rollback for Epic 23 reopened-audit-action hotfix (DEV only)
-- Refuses rollback while any 'reopened' audit row exists.

begin;

do $preflight$
begin
  if to_regclass('public.matchday_nomination_reminder_audit') is null then
    raise exception 'Rollback: audit table is missing';
  end if;

  if exists (
    select 1 from public.matchday_nomination_reminder_audit
    where action='reopened'
  ) then
    raise exception 'Rollback refused: reopened audit history exists; preserve the four-action constraint';
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid='public.matchday_nomination_reminder_audit'::regclass
      and conname='matchday_nomination_reminder_audit_action_check'
      and contype='c'
  ) then
    raise exception 'Rollback: expected action CHECK constraint is missing';
  end if;
end;
$preflight$;

alter table public.matchday_nomination_reminder_audit
  drop constraint matchday_nomination_reminder_audit_action_check;

alter table public.matchday_nomination_reminder_audit
  add constraint matchday_nomination_reminder_audit_action_check
  check (action in ('created','fulfilled','cancelled'));

commit;
