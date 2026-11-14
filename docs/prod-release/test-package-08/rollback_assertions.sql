\set ON_ERROR_STOP on
do $assert$
begin
 if to_regclass('public.matchday_early_suspension_resets') is not null
    or to_regclass('public.matchday_early_suspension_reset_audit') is not null then
   raise exception 'Package 8 tables remain after rollback';
 end if;
 if to_regprocedure('public.schedule_early_suspension_reset(uuid,uuid,text)') is not null
    or to_regprocedure('public.cancel_early_suspension_reset(uuid,text)') is not null
    or to_regprocedure('public.e05_transition_early_reset(uuid,text,text,uuid)') is not null then
   raise exception 'Package 8 functions remain after rollback';
 end if;
 if position('matchday_early_suspension_resets' in pg_get_functiondef('public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure))>0 then
   raise exception 'Award RPC was not restored to its pre-Paket-8 source';
 end if;
end;
$assert$;
