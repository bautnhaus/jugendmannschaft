\set ON_ERROR_STOP on
do $assert$
begin
  if to_regclass('public.training_behavior_events') is not null
     or to_regclass('public.training_behavior_event_audit') is not null
     or to_regprocedure('public.e05_reject_event_audit_mutation()') is not null then
    raise exception 'Rollback left Paket-1 objects behind';
  end if;
end;
$assert$;
