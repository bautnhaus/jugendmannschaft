\set ON_ERROR_STOP on
do $assert$
declare
  v_count integer;
begin
  if to_regclass('public.training_behavior_events') is null
     or to_regclass('public.training_behavior_event_audit') is null then
    raise exception 'Paket 1 tables missing';
  end if;

  if (select relrowsecurity from pg_class where oid='public.training_behavior_events'::regclass) is not true
     or (select relrowsecurity from pg_class where oid='public.training_behavior_event_audit'::regclass) is not true then
    raise exception 'RLS is not enabled on both tables';
  end if;

  select count(*) into v_count from pg_policies
   where schemaname='public'
     and tablename in ('training_behavior_events','training_behavior_event_audit')
     and cmd='SELECT' and roles @> array['authenticated']::name[];
  if v_count <> 2 then raise exception 'Expected two SELECT policies, got %',v_count; end if;

  select count(*) into v_count from pg_indexes
   where schemaname='public' and tablename='training_behavior_events';
  if v_count <> 5 then raise exception 'Expected five event indexes including PK, got %',v_count; end if;

  select count(*) into v_count from pg_indexes
   where schemaname='public' and tablename='training_behavior_event_audit';
  if v_count <> 2 then raise exception 'Expected two audit indexes including PK, got %',v_count; end if;

  select count(*) into v_count from pg_trigger t
   join pg_class c on c.oid=t.tgrelid
   where c.oid='public.training_behavior_event_audit'::regclass
     and not t.tgisinternal;
  if v_count <> 2 then raise exception 'Expected two audit protection triggers, got %',v_count; end if;

  if not has_table_privilege('authenticated','public.training_behavior_events','SELECT')
     or has_table_privilege('authenticated','public.training_behavior_events','INSERT')
     or has_table_privilege('authenticated','public.training_behavior_events','UPDATE')
     or has_table_privilege('authenticated','public.training_behavior_events','DELETE') then
    raise exception 'Unexpected authenticated privileges on events';
  end if;
  if not has_table_privilege('authenticated','public.training_behavior_event_audit','SELECT')
     or has_table_privilege('authenticated','public.training_behavior_event_audit','INSERT')
     or has_table_privilege('authenticated','public.training_behavior_event_audit','UPDATE')
     or has_table_privilege('authenticated','public.training_behavior_event_audit','DELETE') then
    raise exception 'Unexpected authenticated privileges on audit';
  end if;
  if has_table_privilege('anon','public.training_behavior_events','SELECT')
     or has_table_privilege('anon','public.training_behavior_event_audit','SELECT') then
    raise exception 'anon unexpectedly has SELECT';
  end if;
  if has_table_privilege('service_role','public.training_behavior_events','SELECT') is not true
     or has_table_privilege('service_role','public.training_behavior_event_audit','SELECT') is not true then
    raise exception 'service_role SELECT grants missing';
  end if;

  if has_function_privilege('authenticated','public.e05_reject_event_audit_mutation()','EXECUTE')
     or has_function_privilege('anon','public.e05_reject_event_audit_mutation()','EXECUTE')
     or has_function_privilege('service_role','public.e05_reject_event_audit_mutation()','EXECUTE') then
    raise exception 'API role can execute internal audit guard';
  end if;

  if (select count(*) from public.training_behavior_events) <> 0
     or (select count(*) from public.training_behavior_event_audit) <> 0 then
    raise exception 'New tables should be empty';
  end if;
end;
$assert$;

-- Verify append-only guard rejects mutation, using a transaction-local synthetic row.
begin;
insert into public.training_behavior_events
(team_id,season_id,training_id,training_date_snapshot,training_name_snapshot,player_name_snapshot,event_type)
values
(gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),current_date,'CI Test','CI Test','positive_star');
insert into public.training_behavior_event_audit(event_id,action,new_values)
select id,'created','{}'::jsonb from public.training_behavior_events;
do $guard_test$
begin
  begin
    update public.training_behavior_event_audit set reason='should fail';
    raise exception 'Audit UPDATE unexpectedly succeeded';
  exception when sqlstate '55000' then
    null;
  end;
end;
$guard_test$;
rollback;
