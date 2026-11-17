-- Epic 23 – Paket 1: guarded rollback (DEV)
-- STATUS: PREPARED ONLY – NOT EXECUTED
-- Refuses rollback when reminder/audit history exists. No data deletion.

begin;

do $guard$
begin
  if to_regclass('public.matchday_nomination_reminders') is null
     or to_regclass('public.matchday_nomination_reminder_audit') is null
     or to_regprocedure('public.create_matchday_nomination_reminder(uuid,uuid,text,boolean)') is null
     or to_regprocedure('public.cancel_matchday_nomination_reminder(uuid,text)') is null
     or to_regprocedure('public.epic23_fulfill_nomination_reminder()') is null
     or to_regprocedure('public.epic23_reject_nomination_reminder_audit_mutation()') is null then
    raise exception 'Epic 23 rollback: expected package objects missing; manual reconciliation required';
  end if;
  if exists(select 1 from public.matchday_nomination_reminders)
     or exists(select 1 from public.matchday_nomination_reminder_audit) then
    raise exception 'Epic 23 rollback refused: reminder or audit history exists; export and manual plan required';
  end if;
end;
$guard$;

drop trigger matchday_players_fulfill_nomination_reminder on public.matchday_players;
drop trigger matchday_nomination_reminder_audit_no_mutation on public.matchday_nomination_reminder_audit;

drop function public.epic23_fulfill_nomination_reminder();
drop function public.create_matchday_nomination_reminder(uuid,uuid,text,boolean);
drop function public.cancel_matchday_nomination_reminder(uuid,text);
drop function public.epic23_reject_nomination_reminder_audit_mutation();

drop policy matchday_nomination_reminder_audit_select_team on public.matchday_nomination_reminder_audit;
drop policy matchday_nomination_reminders_select_team on public.matchday_nomination_reminders;

drop table public.matchday_nomination_reminder_audit;
drop table public.matchday_nomination_reminders;

commit;
