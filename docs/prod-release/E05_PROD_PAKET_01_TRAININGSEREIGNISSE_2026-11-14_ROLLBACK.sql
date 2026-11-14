-- KADAssist / E05 – PROD Release Paket 1 rollback
-- Status: REVIEWED DRAFT – destructive DDL; only after separate approval.
-- Safe only before any dependent E05 package has been installed.
-- Never use CASCADE. Any dependency error must stop the rollback.

begin;

do $guard$
declare
  v_events bigint;
  v_audit bigint;
begin
  if to_regclass('public.training_behavior_events') is null
     or to_regclass('public.training_behavior_event_audit') is null then
    raise exception 'Rollback stopped: one or both Paket-1 tables are missing; inspect partial state manually';
  end if;

  if to_regprocedure('public.award_training_behavior_event(uuid,uuid,text,text)') is not null then
    raise exception 'Rollback stopped: Paket 2 RPC exists; dependent package is installed';
  end if;
  if to_regclass('public.training_suspensions') is not null
     or to_regclass('public.training_suspension_exceptions') is not null
     or to_regclass('public.training_suspension_audit') is not null then
    raise exception 'Rollback stopped: suspension package objects exist';
  end if;

  execute 'select count(*) from public.training_behavior_events' into v_events;
  execute 'select count(*) from public.training_behavior_event_audit' into v_audit;

  if v_events <> 0 or v_audit <> 0 then
    raise exception 'Rollback stopped: Paket-1 tables contain data (events %, audit %); preserve/export data and prepare a reviewed recovery plan',
      v_events, v_audit;
  end if;
end;
$guard$;

drop policy training_behavior_event_audit_select
  on public.training_behavior_event_audit;
drop policy training_behavior_events_select
  on public.training_behavior_events;

drop trigger training_behavior_event_audit_no_update_delete
  on public.training_behavior_event_audit;
drop trigger training_behavior_event_audit_no_truncate
  on public.training_behavior_event_audit;

drop function public.e05_reject_event_audit_mutation();

-- RESTRICT is the default: unexpected database dependencies stop the rollback.
drop table public.training_behavior_event_audit;
drop table public.training_behavior_events;

commit;
