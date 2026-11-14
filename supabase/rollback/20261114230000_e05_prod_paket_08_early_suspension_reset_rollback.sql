-- E05 PROD Paket 8: Guarded Rollback – Vorzeitiger Sperrausgleich
-- Nur vor Installation späterer E05-Pakete, die Reset-Objekte verwenden.
-- Keine Reset-/Auditdaten werden gelöscht oder rekonstruiert.

begin;

do $guard$
declare
  v_definition text;
  v_patched text := $new$    select greatest(
      coalesce((
        select max(s.served_at) from public.training_suspensions s
        where s.team_id = v_team_id
          and s.season_id = v_season_id
          and s.player_id = p_player_id
          and s.suspension_type = 'yellow'
          and s.status = 'served'
      ), '-infinity'::timestamptz),
      coalesce((
        select max(r.applied_at) from public.matchday_early_suspension_resets r
        where r.team_id = v_team_id
          and r.season_id = v_season_id
          and r.player_id = p_player_id
          and r.status = 'applied'
      ), '-infinity'::timestamptz)
    ) into v_yellow_since;$new$;
begin
  if to_regclass('public.matchday_early_suspension_resets') is null
     or to_regclass('public.matchday_early_suspension_reset_audit') is null
     or to_regprocedure('public.schedule_early_suspension_reset(uuid,uuid,text)') is null
     or to_regprocedure('public.cancel_early_suspension_reset(uuid,text)') is null then
    raise exception 'Paket-8-Rollback: erwarteter Paket-8-Objektstand fehlt; manueller Abgleich erforderlich';
  end if;
  if exists(select 1 from public.matchday_early_suspension_resets)
     or exists(select 1 from public.matchday_early_suspension_reset_audit) then
    raise exception 'Paket-8-Rollback abgebrochen: Reset-/Auditdaten vorhanden; keine Daten werden gelöscht';
  end if;
  if to_regprocedure('public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)') is not null
     or to_regprocedure('public.correct_training_behavior_event(uuid,text,text)') is not null then
    raise exception 'Paket-8-Rollback abgebrochen: spätere E05-Abhängigkeiten vorhanden';
  end if;

  v_definition := pg_get_functiondef(
    'public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure
  );
  if length(v_definition) - length(replace(v_definition, v_patched, '')) <> length(v_patched) then
    raise exception 'Paket-8-Rollback abgebrochen: award-RPC entspricht nicht exakt der Paket-8-Fassung';
  end if;
end;
$guard$;

do $restore$
declare
  v_definition text;
  v_patched text := $new$    select greatest(
      coalesce((
        select max(s.served_at) from public.training_suspensions s
        where s.team_id = v_team_id
          and s.season_id = v_season_id
          and s.player_id = p_player_id
          and s.suspension_type = 'yellow'
          and s.status = 'served'
      ), '-infinity'::timestamptz),
      coalesce((
        select max(r.applied_at) from public.matchday_early_suspension_resets r
        where r.team_id = v_team_id
          and r.season_id = v_season_id
          and r.player_id = p_player_id
          and r.status = 'applied'
      ), '-infinity'::timestamptz)
    ) into v_yellow_since;$new$;
  v_original text := $old$    select coalesce(max(s.served_at), '-infinity'::timestamptz)
      into v_yellow_since
    from public.training_suspensions s
    where s.team_id = v_team_id
      and s.season_id = v_season_id
      and s.player_id = p_player_id
      and s.suspension_type = 'yellow'
      and s.status = 'served';$old$;
begin
  v_definition := pg_get_functiondef(
    'public.award_training_behavior_event(uuid,uuid,text,text)'::regprocedure
  );
  execute replace(v_definition, v_patched, v_original);
end;
$restore$;

revoke all on function public.award_training_behavior_event(uuid,uuid,text,text)
from public,anon,authenticated,service_role;
grant execute on function public.award_training_behavior_event(uuid,uuid,text,text)
to authenticated;

drop trigger matchdays_reconcile_early_resets on public.matchdays;
drop trigger matchday_players_cancel_early_reset on public.matchday_players;
drop trigger matchday_early_suspension_reset_audit_no_mutation
  on public.matchday_early_suspension_reset_audit;

drop function public.e05_reconcile_early_resets_on_matchday_status();
drop function public.e05_cancel_early_reset_on_nomination();
drop function public.e05_transition_early_reset(uuid,text,text,uuid);
drop function public.e05_reject_early_reset_audit_mutation();
drop function public.cancel_early_suspension_reset(uuid,text);
drop function public.schedule_early_suspension_reset(uuid,uuid,text);

drop table public.matchday_early_suspension_reset_audit;
drop table public.matchday_early_suspension_resets;

commit;
