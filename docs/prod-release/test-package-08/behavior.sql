\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('00000000-0000-0000-0000-000000000001');
insert into public.teams(id,name) values ('10000000-0000-0000-0000-000000000001','CI Team');
insert into public.seasons(id,team_id,name,is_active) values ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','CI Season',true);
insert into public.profiles(id,display_name) values ('00000000-0000-0000-0000-000000000001','CI Trainer');
insert into public.team_member_roles(team_id,user_id,role) values ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','trainer');
insert into public.players(id,team_id,name,active) values
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Applied Player',true),
 ('30000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','Nominated Player',true),
 ('30000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','Cancelled Player',true),
 ('30000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000001','Already Nominated',true);
insert into public.matchdays(id,team_id,season_id,match_date,opponent,status) values
 ('40000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',current_date+10,'Opponent A','planned'),
 ('40000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',current_date+11,'Opponent B','planned'),
 ('40000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',current_date+12,'Opponent C','planned'),
 ('40000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',current_date+13,'Opponent D','planned');
insert into public.matchday_players(matchday_id,player_id) values
 ('40000000-0000-0000-0000-000000000004','30000000-0000-0000-0000-000000000004');
set local request.jwt.claim.sub='00000000-0000-0000-0000-000000000001';
set local test.selected_team='10000000-0000-0000-0000-000000000001';

do $test$
declare v_id uuid; v_status text; v_audit integer;
begin
  -- A pending reset is applied exactly once when the matchday becomes done.
  v_id:=public.schedule_early_suspension_reset('40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','CI applied case');
  select status into v_status from public.matchday_early_suspension_resets where id=v_id;
  if v_status<>'pending' then raise exception 'Expected pending before matchday completion'; end if;
  update public.matchdays set status='done' where id='40000000-0000-0000-0000-000000000001';
  select status into v_status from public.matchday_early_suspension_resets where id=v_id;
  if v_status<>'applied' then raise exception 'Expected applied after matchday completion'; end if;
  update public.matchdays set status='done' where id='40000000-0000-0000-0000-000000000001';
  select count(*) into v_audit from public.matchday_early_suspension_reset_audit where reset_id=v_id and action='applied';
  if v_audit<>1 then raise exception 'Reset must be applied and audited exactly once'; end if;

  -- A later nomination automatically cancels a pending reset.
  v_id:=public.schedule_early_suspension_reset('40000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002','CI nomination case');
  insert into public.matchday_players(matchday_id,player_id) values ('40000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002');
  select status into v_status from public.matchday_early_suspension_resets where id=v_id;
  if v_status<>'cancelled' then raise exception 'Later nomination must cancel pending reset'; end if;

  -- A cancelled matchday automatically cancels its pending reset.
  v_id:=public.schedule_early_suspension_reset('40000000-0000-0000-0000-000000000003','30000000-0000-0000-0000-000000000003','CI matchday cancellation case');
  update public.matchdays set status='cancelled' where id='40000000-0000-0000-0000-000000000003';
  select status into v_status from public.matchday_early_suspension_resets where id=v_id;
  if v_status<>'cancelled' then raise exception 'Matchday cancellation must cancel pending reset'; end if;

  -- A player already nominated cannot be scheduled for early reset.
  begin
    perform public.schedule_early_suspension_reset('40000000-0000-0000-0000-000000000004','30000000-0000-0000-0000-000000000004','CI invalid nominated player');
    raise exception 'Expected nominated-player rejection';
  exception when check_violation then null;
  end;
end;
$test$;
rollback;
