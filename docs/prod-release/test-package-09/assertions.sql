\set ON_ERROR_STOP on
do $assert$
declare
 v_count integer;
 v_def text;
 v_oid oid;
begin
 if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='training_behavior_event_audit' and column_name='changed_by_snapshot' and data_type='text') then
  raise exception 'Missing event audit changed_by_snapshot';
 end if;
 if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='training_suspension_audit' and column_name='changed_by_snapshot' and data_type='text') then
  raise exception 'Missing suspension audit changed_by_snapshot';
 end if;
 if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='training_suspensions' and column_name='manual_target_locked' and is_nullable='NO' and column_default like '%false%') then
  raise exception 'manual_target_locked must be NOT NULL DEFAULT false';
 end if;

 select count(*) into v_count from pg_class c
 where c.oid in ('public.training_behavior_events'::regclass,
                 'public.training_behavior_event_audit'::regclass,
                 'public.training_suspensions'::regclass,
                 'public.training_suspension_audit'::regclass)
 and c.relrowsecurity;
 if v_count<>4 then raise exception 'Paket 9 changed/disabled existing RLS baseline'; end if;

 select count(*) into v_count from pg_trigger t
 join pg_class c on c.oid=t.tgrelid
 where not t.tgisinternal and
 ((c.relname='training_behavior_event_audit' and t.tgname in ('ci_event_audit_no_update_delete','ci_event_audit_no_truncate'))
 or (c.relname='training_suspension_audit' and t.tgname in ('ci_suspension_audit_no_update_delete','ci_suspension_audit_no_truncate')));
 if v_count<>4 then raise exception 'Existing append-only audit triggers were not preserved'; end if;

 foreach v_oid in array array[
  'public.correct_suspension(uuid,uuid,text)'::regprocedure,
  'public.correct_training_behavior_event(uuid,text,text)'::regprocedure
 ] loop
  if not (select prosecdef from pg_proc where oid=v_oid) then
   raise exception 'Public correction RPC must be SECURITY DEFINER';
  end if;
  if not has_function_privilege('authenticated',v_oid,'EXECUTE')
     or has_function_privilege('anon',v_oid,'EXECUTE')
     or has_function_privilege('service_role',v_oid,'EXECUTE') then
   raise exception 'Public correction RPC ACL mismatch: %',v_oid::regprocedure;
  end if;
  if exists(select 1 from aclexplode((select coalesce(proacl,acldefault('f',proowner)) from pg_proc where oid=v_oid)) a where a.grantee=0 and a.privilege_type='EXECUTE') then
   raise exception 'PUBLIC must not execute correction RPC %',v_oid::regprocedure;
  end if;
  if not exists(select 1 from pg_proc p where p.oid=v_oid and p.proconfig @> array['search_path=pg_catalog, public, auth']) then
   raise exception 'Fixed search_path missing for %',v_oid::regprocedure;
  end if;
 end loop;

 foreach v_oid in array array[
  'public.e05_assert_suspension_correction_permission(uuid,uuid)'::regprocedure,
  'public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure
 ] loop
  if has_function_privilege('authenticated',v_oid,'EXECUTE')
     or has_function_privilege('anon',v_oid,'EXECUTE')
     or has_function_privilege('service_role',v_oid,'EXECUTE') then
   raise exception 'Internal helper must not be directly executable: %',v_oid::regprocedure;
  end if;
 end loop;

 v_def:=pg_get_functiondef('public.correct_training_behavior_event(uuid,text,text)'::regprocedure);
 if position('PERFORM p.id' in upper(v_def))=0 or position('SELECT p.id' in upper(v_def))>0 then
  raise exception 'Player row lock must use the corrected PERFORM statement';
 end if;

 v_def:=pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure);
 if position('manual_target_locked' in v_def)=0
    or position('m.game_type = any(v_types)' in v_def)=0
    or position('training_date_snapshot' in v_def)>0 then
  raise exception 'Paket 9 allocator must preserve manual targets without prematurely deploying Paket 10 chronology';
 end if;

 v_def:=pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure);
 if position('Target matchday game type is not configured as suspension-relevant' in v_def)=0
    or position('manual_target_locked = true' in v_def)=0 then
  raise exception 'Manual correction must retain configured game-type and lock semantics';
 end if;

 v_def:=pg_get_functiondef('public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure);
 if position('matchday_early_suspension_resets' in v_def)=0 then
  raise exception 'Paket 8 Award RPC integration was not preserved';
 end if;

 if (select count(*) from public.training_behavior_events)<>0
    or (select count(*) from public.training_behavior_event_audit)<>0
    or (select count(*) from public.training_suspensions)<>0
    or (select count(*) from public.training_suspension_audit)<>0 then
  raise exception 'Migration fixture unexpectedly contains or created domain data';
 end if;
end;
$assert$;
