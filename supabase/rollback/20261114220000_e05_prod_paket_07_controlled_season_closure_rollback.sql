-- E05 PROD Paket 7 – Guarded Rollback
-- Nur zulässig, solange kein Saisonabschluss ausgeführt wurde.
-- Audit-/Sperrenhistorie wird niemals gelöscht oder rückwirkend rekonstruiert.

begin;

do $guard$
begin
  if to_regclass('public.team_season_closure_audit') is null then
    raise exception 'Rollback Paket 7 abgebrochen: Saisonabschluss-Audit-Tabelle fehlt';
  end if;
  if exists (select 1 from public.team_season_closure_audit) then
    raise exception 'Rollback Paket 7 gesperrt: mindestens ein Saisonabschluss wurde auditiert';
  end if;
  if to_regprocedure('public.close_team_season(uuid,text)') is null
     or to_regprocedure('public.e05_reject_season_closure_audit_mutation()') is null then
    raise exception 'Rollback Paket 7 abgebrochen: erwartete Paketobjekte fehlen';
  end if;
end;
$guard$;

drop function public.close_team_season(uuid,text);
drop trigger team_season_closure_audit_no_mutation on public.team_season_closure_audit;
drop function public.e05_reject_season_closure_audit_mutation();
drop table public.team_season_closure_audit;

commit;
