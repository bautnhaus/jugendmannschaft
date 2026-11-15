\set ON_ERROR_STOP on
do $assert$
declare v_save text;
begin
 v_save:=pg_get_functiondef('public.save_matchday_recommendation(uuid,uuid[])'::regprocedure);
 if position('training_suspensions' in lower(v_save))>0 then
  raise exception 'Rollback did not restore original PROD recommendation RPC';
 end if;
 if not has_function_privilege('public','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
    or not has_function_privilege('anon','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
    or not has_function_privilege('authenticated','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
    or not has_function_privilege('service_role','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE') then
  raise exception 'Rollback did not restore original PROD trigger-function ACL';
 end if;
 if (select count(*) from pg_trigger where tgrelid='public.matchday_players'::regclass
     and tgname='matchday_players_prevent_suspended_nomination' and not tgisinternal)<>1 then
  raise exception 'Rollback unexpectedly removed existing nomination trigger';
 end if;
end;
$assert$;
