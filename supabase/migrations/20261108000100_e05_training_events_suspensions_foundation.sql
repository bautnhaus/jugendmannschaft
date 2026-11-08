-- E05 / AP05 – schema foundation draft
-- Version: 20261108000100
-- Target: Supabase DEV only
-- Status: DRAFT FOR REVIEW – NOT APPROVED – DO NOT EXECUTE
-- Scope: append-only historical foundation tables and RLS.
-- This file intentionally does NOT implement lifecycle RPCs or recommendation changes.

begin;

create table public.training_behavior_events (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null,
  season_id uuid,
  training_id uuid not null references public.trainings(id) on delete restrict,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null,
  event_type text not null check (event_type in ('yellow_card','red_card','positive_star')),
  reason text,
  awarded_by uuid not null,
  awarded_at timestamptz not null default now(),
  voided_at timestamptz,
  voided_by uuid,
  void_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint training_behavior_events_reason_check
    check (event_type = 'positive_star' or nullif(btrim(reason), '') is not null),
  constraint training_behavior_events_void_check
    check (
      (voided_at is null and voided_by is null and void_reason is null)
      or
      (voided_at is not null and voided_by is not null and nullif(btrim(void_reason), '') is not null)
    )
);

create index training_behavior_events_team_season_player_idx
  on public.training_behavior_events(team_id, season_id, player_id, awarded_at desc);
create index training_behavior_events_training_idx
  on public.training_behavior_events(training_id, player_id);
create unique index training_behavior_events_one_card_per_training_player
  on public.training_behavior_events(training_id, player_id)
  where event_type in ('yellow_card','red_card') and voided_at is null and player_id is not null;
create unique index training_behavior_events_one_star_per_training_player
  on public.training_behavior_events(training_id, player_id)
  where event_type = 'positive_star' and voided_at is null and player_id is not null;

create table public.training_behavior_event_audit (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.training_behavior_events(id) on delete restrict,
  team_id uuid not null,
  action text not null check (action in ('created','corrected','voided','reinstated')),
  before_state jsonb,
  after_state jsonb not null,
  reason text,
  actor_id uuid not null,
  occurred_at timestamptz not null default now(),
  constraint training_behavior_event_audit_reason_check
    check (action = 'created' or nullif(btrim(reason), '') is not null)
);

create table public.training_suspensions (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null,
  season_id uuid,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null,
  suspension_type text not null check (suspension_type in ('yellow','red')),
  status text not null default 'open' check (status in ('open','served','expired','voided')),
  triggering_event_id uuid references public.training_behavior_events(id) on delete restrict,
  target_matchday_id uuid references public.matchdays(id) on delete restrict,
  served_matchday_id uuid references public.matchdays(id) on delete restrict,
  created_by uuid,
  created_at timestamptz not null default now(),
  closed_by uuid,
  closed_at timestamptz,
  close_reason text,
  constraint training_suspensions_closed_check
    check (
      (status = 'open' and closed_at is null)
      or (status <> 'open' and closed_at is not null)
    ),
  constraint training_suspensions_trigger_check
    check (
      (suspension_type = 'yellow' and triggering_event_id is not null)
      or (suspension_type = 'red' and triggering_event_id is not null)
    )
);
create index training_suspensions_open_player_idx
  on public.training_suspensions(team_id, season_id, player_id, created_at)
  where status = 'open';

create table public.training_suspension_exceptions (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
  team_id uuid not null,
  matchday_id uuid not null references public.matchdays(id) on delete restrict,
  reason text not null check (nullif(btrim(reason), '') is not null),
  approved_by uuid not null,
  approved_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (suspension_id, matchday_id)
);

create table public.training_suspension_audit (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
  team_id uuid not null,
  action text not null check (action in ('created','target_changed','served','expired','corrected','voided','exception_granted')),
  before_state jsonb,
  after_state jsonb not null,
  reason text,
  actor_id uuid not null references auth.users(id) on delete restrict,
  occurred_at timestamptz not null default now(),
  constraint training_suspension_audit_reason_check
    check (action in ('created','served','expired','exception_granted') or nullif(btrim(reason), '') is not null)
);

create table public.club_suspension_settings (
  club_id uuid primary key references public.clubs(id) on delete restrict,
  relevant_game_types text[] not null,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  constraint club_suspension_settings_nonempty_check
    check (cardinality(relevant_game_types) > 0),
  constraint club_suspension_settings_values_check
    check (relevant_game_types <@ array['Meisterschaft','Freundschaftsspiel','Turnier']::text[])
);

-- Presence of a team row means full replacement of the club default.
-- Absence means inherit the club setting.
create table public.team_suspension_settings (
  team_id uuid primary key references public.teams(id) on delete restrict,
  relevant_game_types text[] not null,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  constraint team_suspension_settings_nonempty_check
    check (cardinality(relevant_game_types) > 0),
  constraint team_suspension_settings_values_check
    check (relevant_game_types <@ array['Meisterschaft','Freundschaftsspiel','Turnier']::text[])
);

create table public.matchday_early_suspension_resets (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null,
  season_id uuid,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null,
  matchday_id uuid not null references public.matchdays(id) on delete restrict,
  status text not null default 'pending' check (status in ('pending','applied','cancelled')),
  reason text not null check (nullif(btrim(reason), '') is not null),
  created_by uuid not null,
  created_at timestamptz not null default now(),
  resolved_by uuid,
  resolved_at timestamptz,
  resolution_reason text,
  constraint matchday_early_suspension_resets_resolution_check
    check (
      (status = 'pending' and resolved_at is null)
      or (status <> 'pending' and resolved_at is not null)
    )
);
create unique index matchday_early_suspension_resets_one_pending_player_matchday
  on public.matchday_early_suspension_resets(matchday_id, player_id)
  where status = 'pending' and player_id is not null;

create table public.matchday_early_suspension_reset_audit (
  id uuid primary key default gen_random_uuid(),
  reset_id uuid not null references public.matchday_early_suspension_resets(id) on delete restrict,
  team_id uuid not null,
  action text not null check (action in ('created','applied','cancelled','corrected')),
  before_state jsonb,
  after_state jsonb not null,
  reason text,
  actor_id uuid,
  occurred_at timestamptz not null default now(),
  constraint matchday_early_suspension_reset_audit_reason_check
    check (action in ('created','applied') or nullif(btrim(reason), '') is not null)
);

-- Team and season snapshots are intentionally not foreign-keyed: historic rows must survive
-- team/season lifecycle operations. Training/matchday references use RESTRICT to prevent
-- accidental deletion of source events that still have dependent disciplinary history.

alter table public.training_behavior_events enable row level security;
alter table public.training_behavior_event_audit enable row level security;
alter table public.training_suspensions enable row level security;
alter table public.training_suspension_exceptions enable row level security;
alter table public.training_suspension_audit enable row level security;
alter table public.club_suspension_settings enable row level security;
alter table public.team_suspension_settings enable row level security;
alter table public.matchday_early_suspension_resets enable row level security;
alter table public.matchday_early_suspension_reset_audit enable row level security;

-- Read access follows existing team membership / selected administrative context.
create policy training_behavior_events_select on public.training_behavior_events
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_behavior_event_audit_select on public.training_behavior_event_audit
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_suspensions_select on public.training_suspensions
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_suspension_exceptions_select on public.training_suspension_exceptions
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_suspension_audit_select on public.training_suspension_audit
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy team_suspension_settings_select on public.team_suspension_settings
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy matchday_early_suspension_resets_select on public.matchday_early_suspension_resets
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy matchday_early_suspension_reset_audit_select on public.matchday_early_suspension_reset_audit
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy club_suspension_settings_select on public.club_suspension_settings
for select to authenticated
using (
  exists (
    select 1 from public.teams t
    where t.club_id = club_suspension_settings.club_id
      and (public.is_team_member(t.id) or public.has_selected_team_context(t.id))
  )
);

-- Explicit minimum read grants; RLS remains the row-level boundary.
grant select on public.training_behavior_events to authenticated;
grant select on public.training_behavior_event_audit to authenticated;
grant select on public.training_suspensions to authenticated;
grant select on public.training_suspension_exceptions to authenticated;
grant select on public.training_suspension_audit to authenticated;
grant select on public.club_suspension_settings to authenticated;
grant select on public.team_suspension_settings to authenticated;
grant select on public.matchday_early_suspension_resets to authenticated;
grant select on public.matchday_early_suspension_reset_audit to authenticated;

-- Deliberately no client INSERT/UPDATE/DELETE policies yet. Writes are introduced with
-- narrowly scoped, audited RPCs in the next migration stage. No broad table grants.

commit;
