\set ON_ERROR_STOP on
-- Ergänzt das Paket-8-PROD-Fixture um die vorhandene Paket-1-bis-8-Baseline,
-- die Paket 9 benötigt. Alle Tabellen und Daten sind ausschließlich CI-Testdaten.

alter table public.teams add column if not exists club_id uuid;
alter table public.matchdays add column if not exists game_type text;

alter table public.training_behavior_events
  add column if not exists team_id uuid,
  add column if not exists season_id uuid,
  add column if not exists training_id uuid,
  add column if not exists training_date_snapshot date,
  add column if not exists training_name_snapshot text,
  add column if not exists player_id uuid,
  add column if not exists player_name_snapshot text,
  add column if not exists event_type text,
  add column if not exists reason text,
  add column if not exists status text,
  add column if not exists awarded_by uuid,
  add column if not exists awarded_at timestamptz,
  add column if not exists voided_by uuid,
  add column if not exists voided_at timestamptz,
  add column if not exists void_reason text,
  add column if not exists updated_at timestamptz;

alter table public.training_suspensions
  add column if not exists served_matchday_id uuid,
  add column if not exists served_matchday_date_snapshot date,
  add column if not exists served_matchday_opponent_snapshot text,
  add column if not exists created_by uuid,
  add column if not exists voided_by uuid,
  add column if not exists voided_at timestamptz,
  add column if not exists void_reason text,
  add column if not exists expired_at timestamptz;

create table public.training_behavior_event_audit(
 id uuid primary key default gen_random_uuid(),
 event_id uuid,
 action text,
 old_values jsonb,
 new_values jsonb,
 reason text,
 changed_by uuid,
 changed_at timestamptz default now()
);

create table public.training_suspension_exceptions(
 id uuid primary key default gen_random_uuid(),
 suspension_id uuid,
 matchday_id uuid,
 revoked_at timestamptz
);

create table public.club_suspension_settings(
 club_id uuid primary key,
 relevant_game_types text[] not null default '{}'::text[],
 updated_at timestamptz,
 updated_by uuid
);
create table public.team_suspension_game_type_settings(
 team_id uuid primary key,
 updated_at timestamptz,
 updated_by uuid
);
create table public.team_suspension_game_types(
 team_id uuid not null,
 game_type text not null,
 created_at timestamptz default now(),
 primary key(team_id,game_type)
);

-- Paket-8-/Paket-9-Funktionen erwarten diese vorhandene RPC-Signatur.
-- Der Quelltextanker bildet die PROD-Paket-8-Allocator-Baseline ab.
create or replace function public.e05_assign_player_suspensions(
 p_team_id uuid,p_player_id uuid,p_actor_id uuid
) returns integer
language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
 v_types text[];
begin
 -- Baseline filter: m.game_type = any(v_types)
 return 0;
end;
$function$;
revoke all on function public.e05_assign_player_suspensions(uuid,uuid,uuid)
from public,anon,authenticated,service_role;

-- Mirror the existing audit-table protections that Paket 9 must preserve.
create or replace function public.test_reject_e05_audit_mutation()
returns trigger language plpgsql
as $function$
begin
 raise exception 'Audit append-only';
end;
$function$;
alter table public.training_behavior_events enable row level security;
alter table public.training_behavior_event_audit enable row level security;
alter table public.training_suspensions enable row level security;
alter table public.training_suspension_audit enable row level security;

create policy ci_events_select on public.training_behavior_events
for select to authenticated using (true);
create policy ci_event_audit_select on public.training_behavior_event_audit
for select to authenticated using (true);
create policy ci_suspensions_select on public.training_suspensions
for select to authenticated using (true);
create policy ci_suspension_audit_select on public.training_suspension_audit
for select to authenticated using (true);

create trigger ci_event_audit_no_update_delete
before update or delete on public.training_behavior_event_audit
for each row execute function public.test_reject_e05_audit_mutation();
create trigger ci_event_audit_no_truncate
before truncate on public.training_behavior_event_audit
for each statement execute function public.test_reject_e05_audit_mutation();
create trigger ci_suspension_audit_no_update_delete
before update or delete on public.training_suspension_audit
for each row execute function public.test_reject_e05_audit_mutation();
create trigger ci_suspension_audit_no_truncate
before truncate on public.training_suspension_audit
for each statement execute function public.test_reject_e05_audit_mutation();

grant select on public.training_behavior_events,public.training_behavior_event_audit,
 public.training_suspensions,public.training_suspension_audit to authenticated;
