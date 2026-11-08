-- E05 / AP05 – Paket 01: Trainingsereignisse – Datenbankfundament
-- Erstellt: 08.11.2026
-- Ziel: Supabase DEV (Projekt pzazqvvoruqnqhcorbwx)
-- Status: FREIGABE AUSSTEHEND – NICHT AUSGEFÜHRT
--
-- Umfang bewusst klein:
--   1) training_behavior_events
--   2) training_behavior_event_audit
--   3) Eindeutigkeitsindizes für Karte und positiven Stern
--   4) RLS-Lesepolicies und minimale API-Rechte
--   5) Append-only-Schutz für das Audit
--
-- Keine Änderung an bestehenden Tabellen, Daten, Rollen oder Funktionen.
-- Keine Schreib-RPCs in diesem Paket. Schreibzugriffe folgen in Paket 02.
-- Rückbau vor Produktivfreigabe: Tabellen/Objekte dieses Pakets entfernen,
-- nachdem Paket 02 noch nicht darauf aufbaut bzw. abhängige Pakete zurückgebaut sind.
--
-- Voraussetzung geprüft: DEV enthält players(id uuid), teams/Trainings-Bestand
-- und Rollenhelfer public.is_team_member(uuid), public.has_selected_team_context(uuid).
-- Ereignisse speichern Team-/Saison-/Trainings-/Spieler-Snapshots, damit die
-- Historie bei späteren Änderungen an Stammdaten nachvollziehbar bleibt.

begin;

create table public.training_behavior_events (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null,
  team_name_snapshot text not null,
  season_id uuid not null,
  season_name_snapshot text not null,
  training_id uuid not null,
  training_date_snapshot date not null,
  training_name_snapshot text not null,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null
    check (nullif(btrim(player_name_snapshot), '') is not null),
  event_type text not null
    check (event_type in ('yellow_card', 'red_card', 'positive_star')),
  reason text,
  status text not null default 'active'
    check (status in ('active', 'voided')),
  awarded_by uuid references auth.users(id) on delete set null,
  awarded_by_snapshot text,
  awarded_at timestamptz not null default now(),
  voided_by uuid references auth.users(id) on delete set null,
  voided_by_snapshot text,
  voided_at timestamptz,
  void_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint training_behavior_events_reason_check
    check (
      event_type = 'positive_star'
      or nullif(btrim(reason), '') is not null
    ),
  constraint training_behavior_events_void_metadata_check
    check (
      (status = 'active'
        and voided_by is null
        and voided_by_snapshot is null
        and voided_at is null
        and void_reason is null)
      or
      (status = 'voided'
        and voided_at is not null
        and nullif(btrim(void_reason), '') is not null)
    )
);

comment on table public.training_behavior_events is
  'E05: historisierte Trainingsereignisse (gelbe/rote Karte, positiver Stern). Schreibzugriff ausschließlich über geprüfte RPCs.';
comment on column public.training_behavior_events.team_id is
  'Historische Teamzuordnung zum Zeitpunkt der Vergabe; absichtlich kein FK.';
comment on column public.training_behavior_events.season_id is
  'Historische Saisonzuordnung zum Zeitpunkt der Vergabe; absichtlich kein FK.';
comment on column public.training_behavior_events.training_id is
  'Historische Trainingsreferenz; absichtlich kein FK.';
comment on column public.training_behavior_events.player_id is
  'Spielerreferenz; wird bei Spieler-Löschung auf NULL gesetzt, Snapshot bleibt erhalten.';

create unique index training_behavior_events_one_card_per_player_training
  on public.training_behavior_events (training_id, player_id)
  where status = 'active'
    and player_id is not null
    and event_type in ('yellow_card', 'red_card');

create unique index training_behavior_events_one_star_per_player_training
  on public.training_behavior_events (training_id, player_id)
  where status = 'active'
    and player_id is not null
    and event_type = 'positive_star';

create index training_behavior_events_player_season_idx
  on public.training_behavior_events (team_id, season_id, player_id, awarded_at desc);

create index training_behavior_events_training_idx
  on public.training_behavior_events (training_id, player_id);

create table public.training_behavior_event_audit (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null
    references public.training_behavior_events(id) on delete restrict,
  action text not null
    check (action in ('created', 'corrected', 'voided', 'reinstated')),
  old_values jsonb,
  new_values jsonb not null,
  reason text,
  changed_by uuid references auth.users(id) on delete set null,
  changed_by_snapshot text,
  changed_at timestamptz not null default now(),
  constraint training_behavior_event_audit_reason_check
    check (
      action = 'created'
      or nullif(btrim(reason), '') is not null
    )
);

comment on table public.training_behavior_event_audit is
  'E05: unveränderliches Auditprotokoll aller Änderungen an Trainingsereignissen.';

create index training_behavior_event_audit_event_idx
  on public.training_behavior_event_audit (event_id, changed_at desc);

-- Audit-Tabellen sind append-only. Änderungen/Löschungen werden technisch abgewiesen.
create function public.e05_reject_audit_mutation()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $function$
begin
  raise exception 'E05 audit tables are append-only; % is not permitted on %',
    TG_OP, TG_TABLE_NAME
    using errcode = '55000';
end;
$function$;

create trigger training_behavior_event_audit_append_only
before update or delete on public.training_behavior_event_audit
for each row execute function public.e05_reject_audit_mutation();

create trigger training_behavior_event_audit_no_truncate
before truncate on public.training_behavior_event_audit
for each statement execute function public.e05_reject_audit_mutation();

revoke all on function public.e05_reject_audit_mutation()
from public, anon, authenticated, service_role;

-- API-Rollen erhalten ausschließlich Leserechte. Schreibzugriff folgt über RPCs.
revoke all on public.training_behavior_events,
  public.training_behavior_event_audit
from public, anon, authenticated, service_role;

grant select on public.training_behavior_events,
  public.training_behavior_event_audit
to authenticated, service_role;

alter table public.training_behavior_events enable row level security;
alter table public.training_behavior_event_audit enable row level security;

create policy training_behavior_events_select
on public.training_behavior_events
for select to authenticated
using (
  public.is_team_member(team_id)
  or public.has_selected_team_context(team_id)
);

create policy training_behavior_event_audit_select
on public.training_behavior_event_audit
for select to authenticated
using (
  exists (
    select 1
    from public.training_behavior_events e
    where e.id = event_id
      and (
        public.is_team_member(e.team_id)
        or public.has_selected_team_context(e.team_id)
      )
  )
);

commit;
