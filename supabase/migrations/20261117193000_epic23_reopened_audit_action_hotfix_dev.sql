-- Epic 23 – Hotfix: allow the reopened audit action (DEV only)
-- Target: Supabase DEV (pzazqvvoruqnqhcorbwx)
-- Scope: replace one CHECK constraint; no row or trigger/function changes.
-- Guarded preflight rejects unexpected historical action values.

begin;

do $preflight$
begin
  if to_regclass('public.matchday_nomination_reminder_audit') is null then
    raise exception 'Epic 23 hotfix: audit table is missing';
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid='public.matchday_nomination_reminder_audit'::regclass
      and conname='matchday_nomination_reminder_audit_action_check'
      and contype='c'
  ) then
    raise exception 'Epic 23 hotfix: expected action CHECK constraint is missing';
  end if;

  if exists (
    select 1
    from public.matchday_nomination_reminder_audit
    where action not in ('created','fulfilled','cancelled','reopened')
  ) then
    raise exception 'Epic 23 hotfix: unexpected historical audit action; manual reconciliation required';
  end if;
end;
$preflight$;

alter table public.matchday_nomination_reminder_audit
  drop constraint matchday_nomination_reminder_audit_action_check;

alter table public.matchday_nomination_reminder_audit
  add constraint matchday_nomination_reminder_audit_action_check
  check (action in ('created','fulfilled','cancelled','reopened'));

commit;
