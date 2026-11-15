\set ON_ERROR_STOP on
do $assert$
declare
 v_count integer;
 v_def text;
 v_oid oid;
begin
 foreach v_oid in array array[
  'public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure,
  'public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure,
  'public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure,
  'public.correct_suspension(uuid,uuid,text)'::regprocedure,
  'public.serve_matchday_suspensions(uuid)'::regprocedure
 ] loop
  if not (select prosecdef from pg_proc where oid=v_oid) then
   raise exception 'Function must remain SECURITY DEFINER: %',v_oid::regprocedure;
  end if;
  if not exists(select 1 from pg_proc where oid=v_oid and proconfig @> array['search_path=pg_catalog, public, auth']) then
   raise exception 'Fixed search_path missing: %',v_oid::regprocedure;
  end if;
 end loop;

 v_def:=pg_get_functiondef('public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure);
 if position('e05_reconcile_suspensions_after_event_correction' in v_def)=0 then
  raise exception 'New yellow cards must use the shared chronology/reconciliation path';
 end if;

 v_def:=pg_get_functiondef('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure);
 if position('training_date_snapshot > v_yellow_since' in v_def)=0
    or position('order by e.training_date_snapshot, e.id' in lower(v_def))=0
    or position('awarded_at > v_yellow_since' in v_def)>0
    or position('matchday_early_suspension_resets' in v_def)=0 then
  raise exception 'Yellow-card chronology must use training date and retain early-reset lower bound';
 end if;

 v_def:=pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure);
 if position('m.match_date > v_trigger_date' in v_def)=0
    or position('manual_target_locked' in v_def)=0
    or position('game_type' in lower(v_def))>0 then
  raise exception 'Allocator must use trigger date, preserve manual target locks, and accept all game types';
 end if;

 v_def:=pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure);
 if position('v_target.match_date <= v_trigger_date' in v_def)=0
    or position('manual_target_locked = true' in v_def)=0
    or position('game_type' in lower(v_def))>0 then
  raise exception 'Manual correction must require a later matchday and ignore game_type';
 end if;

 v_def:=pg_get_functiondef('public.serve_matchday_suspensions(uuid)'::regprocedure);
 if position('v_game_type' in v_def)>0
    or position('game_type' in lower(v_def))>0
    or position('v_match_status is distinct from ''done''' in lower(v_def))=0
    or position('e05_assign_player_suspensions' in v_def)=0 then
  raise exception 'Serving must work for all completed matchdays and recalculate remaining suspensions';
 end if;

 if not has_function_privilege('authenticated','public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
    or has_function_privilege('anon','public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure,'EXECUTE')
    or not has_function_privilege('authenticated','public.correct_suspension(uuid,uuid,text)'::regprocedure,'EXECUTE')
    or has_function_privilege('anon','public.correct_suspension(uuid,uuid,text)'::regprocedure,'EXECUTE')
    or not has_function_privilege('authenticated','public.serve_matchday_suspensions(uuid)'::regprocedure,'EXECUTE')
    or has_function_privilege('anon','public.serve_matchday_suspensions(uuid)'::regprocedure,'EXECUTE')
    or has_function_privilege('authenticated','public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure,'EXECUTE')
    or has_function_privilege('authenticated','public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure,'EXECUTE') then
  raise exception 'Paket 10 changed an existing function EXECUTE ACL';
 end if;

 select count(*) into v_count from pg_class c
 where c.oid in ('public.training_behavior_events'::regclass,
                 'public.training_behavior_event_audit'::regclass,
                 'public.training_suspensions'::regclass,
                 'public.training_suspension_audit'::regclass)
 and c.relrowsecurity;
 if v_count<>4 then raise exception 'Paket 10 changed existing E05 RLS'; end if;

 if (select count(*) from public.training_behavior_events)<>0
    or (select count(*) from public.training_behavior_event_audit)<>0
    or (select count(*) from public.training_suspensions)<>0
    or (select count(*) from public.training_suspension_audit)<>0 then
  raise exception 'Paket 10 fixture unexpectedly contains or creates domain data';
 end if;

 if exists(
  (select nspname,relname,tgname,definition from ci_package10_trigger_baseline
   except
   select n.nspname,c.relname,t.tgname,pg_get_triggerdef(t.oid)
   from pg_trigger t join pg_class c on c.oid=t.tgrelid
   join pg_namespace n on n.oid=c.relnamespace
   where n.nspname='public' and not t.tgisinternal)
  union all
  (select n.nspname,c.relname,t.tgname,pg_get_triggerdef(t.oid)
   from pg_trigger t join pg_class c on c.oid=t.tgrelid
   join pg_namespace n on n.oid=c.relnamespace
   where n.nspname='public' and not t.tgisinternal
   except
   select nspname,relname,tgname,definition from ci_package10_trigger_baseline)
 ) then raise exception 'Paket 10 modified trigger definitions'; end if;

 if exists(
  (select schemaname,tablename,policyname,cmd,roles,qual,with_check from ci_package10_policy_baseline
   except
   select schemaname,tablename,policyname,cmd,roles,qual,with_check from pg_policies where schemaname='public')
  union all
  (select schemaname,tablename,policyname,cmd,roles,qual,with_check from pg_policies where schemaname='public'
   except
   select schemaname,tablename,policyname,cmd,roles,qual,with_check from ci_package10_policy_baseline)
 ) then raise exception 'Paket 10 modified RLS policies'; end if;
end;
$assert$;
