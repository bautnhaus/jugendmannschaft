\set ON_ERROR_STOP on
do $assert$
declare
 v_def text;
begin
 v_def:=pg_get_functiondef('public.e05_assign_player_suspensions(uuid,uuid,uuid)'::regprocedure);
 if position('m.game_type = any(v_types)' in v_def)=0
    or position('training_date_snapshot' in v_def)>0 then
  raise exception 'Rollback did not restore Paket-9 allocator';
 end if;
 v_def:=pg_get_functiondef('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)'::regprocedure);
 if position('awarded_at > v_yellow_since' in v_def)=0 then
  raise exception 'Rollback did not restore Paket-9 reconciliation';
 end if;
 v_def:=pg_get_functiondef('public.correct_suspension(uuid,uuid,text)'::regprocedure);
 if position('Target matchday game type is not configured as suspension-relevant' in v_def)=0 then
  raise exception 'Rollback did not restore Paket-9 manual correction';
 end if;
 v_def:=pg_get_functiondef('public.serve_matchday_suspensions(uuid)'::regprocedure);
 if position('v_game_type' in v_def)=0 then
  raise exception 'Rollback did not restore pre-Paket-10 serving function';
 end if;
end;
$assert$;
