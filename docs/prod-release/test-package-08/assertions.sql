\set ON_ERROR_STOP on
do $assert$
declare
 v_count integer;
begin
 if to_regclass('public.matchday_early_suspension_resets') is null
    or to_regclass('public.matchday_early_suspension_reset_audit') is null then
   raise exception 'Package 8 tables missing';
 end if;
 if not (select relrowsecurity from pg_class where oid='public.matchday_early_suspension_resets'::regclass)
    or not (select relrowsecurity from pg_class where oid='public.matchday_early_suspension_reset_audit'::regclass) then
   raise exception 'RLS must be enabled on both tables';
 end if;
 if not has_function_privilege('authenticated','public.schedule_early_suspension_reset(uuid,uuid,text)','EXECUTE')
    or not has_function_privilege('authenticated','public.cancel_early_suspension_reset(uuid,text)','EXECUTE')
    or has_function_privilege('anon','public.schedule_early_suspension_reset(uuid,uuid,text)','EXECUTE')
    or has_function_privilege('anon','public.cancel_early_suspension_reset(uuid,text)','EXECUTE') then
   raise exception 'Public RPC ACL mismatch';
 end if;
 if has_function_privilege('authenticated','public.e05_transition_early_reset(uuid,text,text,uuid)','EXECUTE')
    or has_function_privilege('authenticated','public.e05_cancel_early_reset_on_nomination()','EXECUTE')
    or has_function_privilege('authenticated','public.e05_reconcile_early_resets_on_matchday_status()','EXECUTE') then
   raise exception 'Internal trigger/helper function is directly executable';
 end if;
 if position('matchday_early_suspension_resets' in pg_get_functiondef('public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure))=0 then
   raise exception 'Award RPC does not include applied reset lower bound';
 end if;
 select count(*) into v_count from pg_trigger where not tgisinternal and tgname in
 ('matchday_players_cancel_early_reset','matchdays_reconcile_early_resets','matchday_early_suspension_reset_audit_no_mutation');
 if v_count<>3 then raise exception 'Expected exactly three Paket-8 triggers, found %',v_count; end if;
 select count(*) into v_count from pg_policies where schemaname='public' and tablename in
 ('matchday_early_suspension_resets','matchday_early_suspension_reset_audit');
 if v_count<>2 then raise exception 'Expected two Paket-8 SELECT policies, found %',v_count; end if;
 if (select count(*) from public.matchday_early_suspension_resets)<>0
    or (select count(*) from public.matchday_early_suspension_reset_audit)<>0 then
   raise exception 'Transactional behavior tests left persistent rows';
 end if;
end;
$assert$;
