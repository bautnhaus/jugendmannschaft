\set ON_ERROR_STOP on
-- Isolierte Testumgebung: exakte PROD-Paket-8-/Paket-9-Baseline plus minimale
-- Spalten für die vollständigen Paket-10-Funktionsdefinitionen.
\ir ../test-package-08/bootstrap.sql
\ir ../test-package-09/bootstrap.sql

alter table public.matchdays
  add column if not exists kickoff_time time,
  add column if not exists created_at timestamptz not null default now();

-- Mirror the PROD ACL of the Paket-8 award RPC.
revoke all on function public.award_training_behavior_event(uuid,uuid,text,text)
  from public,anon,authenticated,service_role;
grant execute on function public.award_training_behavior_event(uuid,uuid,text,text)
  to authenticated;

-- serve_matchday_suspensions is part of the existing Paket-4 PROD baseline.
-- This minimal body contains the source anchors expected by Paket 10's guarded preflight.
create or replace function public.serve_matchday_suspensions(p_matchday_id uuid)
returns integer language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
 v_game_type text;
begin
 if v_game_type is null then
  raise exception 'This matchday game type is not relevant for suspensions';
 end if;
 return 0;
end;
$function$;
revoke all on function public.serve_matchday_suspensions(uuid)
  from public,anon,authenticated,service_role;
grant execute on function public.serve_matchday_suspensions(uuid) to authenticated;

-- Snapshot baseline trigger/policy counts. Paket 10 must not change either.
create temp table ci_package10_trigger_baseline as
select n.nspname,c.relname,t.tgname,pg_get_triggerdef(t.oid) definition
from pg_trigger t join pg_class c on c.oid=t.tgrelid
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and not t.tgisinternal;

create temp table ci_package10_policy_baseline as
select schemaname,tablename,policyname,cmd,roles,qual,with_check
from pg_policies where schemaname='public';
