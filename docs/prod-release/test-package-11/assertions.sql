\set ON_ERROR_STOP on
do $assert$
declare
  v_save text;
  v_revoke text;
  v_id uuid;
begin
  v_save:=pg_get_functiondef('public.save_matchday_recommendation(uuid,uuid[])'::regprocedure);
  v_revoke:=pg_get_functiondef('public.revoke_suspension_exception(uuid,text)'::regprocedure);

  if position('training_suspensions' in lower(v_save))=0
     or position('training_suspension_exceptions' in lower(v_save))=0
     or position('intended_matchday_id' in lower(v_save))=0 then
    raise exception 'Recommendation RPC is missing suspension/exception guard';
  end if;
  if has_function_privilege('public','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or has_function_privilege('authenticated','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.prevent_suspended_matchday_nomination()'::regprocedure,'EXECUTE') then
    raise exception 'Trigger function EXECUTE ACL does not match DEV';
  end if;
  if not has_function_privilege('authenticated','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE')
     or not has_function_privilege('service_role','public.save_matchday_recommendation(uuid,uuid[])'::regprocedure,'EXECUTE') then
    raise exception 'Recommendation RPC ACL changed unexpectedly';
  end if;
  if position('nomination_removed' in v_revoke)=0
     or position('removed_nomination_snapshot' in v_revoke)=0
     or position('pg_advisory_xact_lock' in v_revoke)=0 then
    raise exception 'Atomic exception revocation baseline was not preserved';
  end if;
  if (select count(*) from pg_trigger where tgrelid='public.matchday_players'::regclass
      and tgname='matchday_players_prevent_suspended_nomination' and not tgisinternal)<>1 then
    raise exception 'Existing nomination trigger missing or duplicated';
  end if;
end;
$assert$;

-- Behavioral checks use only disposable fixture rows.
insert into public.matchdays(id,team_id,season_id,status,match_date)
values
 ('10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','planned',current_date+7),
 ('10000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','planned',current_date+14);
insert into public.players(id,team_id,active)
values ('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',true);
insert into public.training_suspensions(id,team_id,season_id,player_id,status,intended_matchday_id)
values ('50000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','open','10000000-0000-0000-0000-000000000001');

select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000001',false);

do $behavior$
declare
  v_recommendation uuid;
begin
  begin
    perform public.save_matchday_recommendation(
      '10000000-0000-0000-0000-000000000001',
      array['40000000-0000-0000-0000-000000000001'::uuid]
    );
    raise exception 'Expected suspended recommendation to be rejected';
  exception when check_violation then
    null;
  end;

  begin
    insert into public.matchday_players(matchday_id,player_id)
    values ('10000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001');
    raise exception 'Expected suspended direct nomination to be rejected';
  exception when check_violation then
    null;
  end;

  insert into public.training_suspension_exceptions(
    id,suspension_id,team_id,player_id,matchday_id,revoked_at
  ) values (
    '70000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',null
  );

  v_recommendation:=public.save_matchday_recommendation(
    '10000000-0000-0000-0000-000000000001',
    array['40000000-0000-0000-0000-000000000001'::uuid]
  );
  if v_recommendation is null then raise exception 'Allowed recommendation returned NULL'; end if;

  insert into public.matchday_players(matchday_id,player_id)
  values ('10000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001');

  update public.training_suspension_exceptions
     set revoked_at=now()
   where id='70000000-0000-0000-0000-000000000001';
  delete from public.matchday_players
   where matchday_id='10000000-0000-0000-0000-000000000001'
     and player_id='40000000-0000-0000-0000-000000000001';

  begin
    perform public.save_matchday_recommendation(
      '10000000-0000-0000-0000-000000000001',
      array['40000000-0000-0000-0000-000000000001'::uuid]
    );
    raise exception 'Expected revoked exception recommendation to be rejected';
  exception when check_violation then
    null;
  end;

  begin
    insert into public.matchday_players(matchday_id,player_id)
    values ('10000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001');
    raise exception 'Expected revoked exception nomination to be rejected';
  exception when check_violation then
    null;
  end;

  -- A suspension assigned to another matchday does not block this one.
  insert into public.matchday_players(matchday_id,player_id)
  values ('10000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001');
end;
$behavior$;
