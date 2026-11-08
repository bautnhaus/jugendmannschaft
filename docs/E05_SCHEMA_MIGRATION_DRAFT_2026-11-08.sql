-- E05 / AP05 – schema foundation draft
-- Target: Supabase DEV only (pzazqvvoruqnqhcorbwx)
-- Status: REVIEW DRAFT – NOT APPROVED – DO NOT EXECUTE
-- This file is a review artifact, not yet a supabase/migrations release file.
-- No existing table/function/policy is altered or replaced by this draft.
-- Full lifecycle RPCs, automated suspension processing and recommendation
-- integration are intentionally excluded and require separate reviewed migrations.

begin;

create table public.training_behavior_events (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete restrict,
  season_id uuid not null references public.seasons(id) on delete restrict,
  training_id uuid not null references public.trainings(id) on delete restrict,
  player_id uuid not null references public.players(id) on delete restrict,
  event_type text not null check (event_type in ('yellow_card','red_card','positive_star')),
  reason text,
  status text not null default 'active' check (status in ('active','voided')),
  awarded_by uuid not null references auth.users(id) on delete restrict,
  awarded_at timestamptz not null default now(),
  voided_by uuid references auth.users(id) on delete restrict,
  voided_at timestamptz,
  void_reason text,
  created_at timestamptz not null default now(),
  constraint training_behavior_events_reason_check
    check (event_type = 'positive_star' or nullif(btrim(reason),'') is not null),
  constraint training_behavior_events_void_metadata_check
    check (
      (status = 'active' and voided_by is null and voided_at is null and void_reason is null)
      or
      (status = 'voided' and voided_by is not null and voided_at is not null
       and nullif(btrim(void_reason),'') is not null)
    ),
  constraint training_behavior_events_training_identity_unique
    unique (id, team_id, season_id, player_id, training_id)
);

create unique index training_behavior_events_one_card_per_player_training
  on public.training_behavior_events(training_id, player_id)
  where status = 'active' and event_type in ('yellow_card','red_card');

create unique index training_behavior_events_one_star_per_player_training
  on public.training_behavior_events(training_id, player_id)
  where status = 'active' and event_type = 'positive_star';

create index training_behavior_events_player_season_idx
  on public.training_behavior_events(team_id, season_id, player_id, awarded_at desc);

create index training_behavior_events_training_idx
  on public.training_behavior_events(training_id, player_id);

create table public.training_behavior_event_audit (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.training_behavior_events(id) on delete restrict,
  action text not null check (action in ('created','corrected','voided','reinstated')),
  old_values jsonb,
  new_values jsonb,
  reason text,
  changed_by uuid not null references auth.users(id) on delete restrict,
  changed_at timestamptz not null default now(),
  constraint training_behavior_event_audit_reason_check
    check (action = 'created' or nullif(btrim(reason),'') is not null)
);

create index training_behavior_event_audit_event_idx
  on public.training_behavior_event_audit(event_id, changed_at desc);

create table public.training_suspensions (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete restrict,
  season_id uuid not null references public.seasons(id) on delete restrict,
  player_id uuid not null references public.players(id) on delete restrict,
  source_event_id uuid references public.training_behavior_events(id) on delete restrict,
  suspension_type text not null check (suspension_type in ('yellow','red')),
  status text not null default 'open'
    check (status in ('open','served','expired','voided')),
  intended_matchday_id uuid references public.matchdays(id) on delete restrict,
  served_matchday_id uuid references public.matchdays(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  served_at timestamptz,
  expired_at timestamptz,
  voided_at timestamptz,
  voided_by uuid references auth.users(id) on delete restrict,
  void_reason text,
  constraint training_suspensions_void_metadata_check
    check (
      (status <> 'voided' and voided_at is null and voided_by is null and void_reason is null)
      or
      (status = 'voided' and voided_at is not null and voided_by is not null
       and nullif(btrim(void_reason),'') is not null)
    ),
  constraint training_suspensions_served_metadata_check
    check (
      (status = 'served' and served_matchday_id is not null and served_at is not null)
      or status <> 'served'
    )
);

create index training_suspensions_open_player_idx
  on public.training_suspensions(team_id, season_id, player_id, created_at)
  where status = 'open';

create index training_suspensions_matchday_idx
  on public.training_suspensions(intended_matchday_id)
  where status = 'open';

create table public.training_suspension_exceptions (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
  matchday_id uuid not null references public.matchdays(id) on delete restrict,
  reason text not null check (nullif(btrim(reason),'') is not null),
  granted_by uuid not null references auth.users(id) on delete restrict,
  granted_at timestamptz not null default now(),
  revoked_by uuid references auth.users(id) on delete restrict,
  revoked_at timestamptz,
  revoke_reason text,
  constraint training_suspension_exceptions_revocation_check
    check (
      (revoked_at is null and revoked_by is null and revoke_reason is null)
      or
      (revoked_at is not null and revoked_by is not null
       and nullif(btrim(revoke_reason),'') is not null)
    ),
  unique (suspension_id, matchday_id)
);

create table public.training_suspension_audit (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
  action text not null check (
    action in ('created','target_changed','served','expired','exception_granted',
               'exception_revoked','corrected','voided','reinstated')
  ),
  old_values jsonb,
  new_values jsonb,
  reason text,
  changed_by uuid not null references auth.users(id) on delete restrict,
  changed_at timestamptz not null default now(),
  constraint training_suspension_audit_reason_check
    check (action = 'created' or nullif(btrim(reason),'') is not null)
);

create index training_suspension_audit_suspension_idx
  on public.training_suspension_audit(suspension_id, changed_at desc);

create table public.club_suspension_game_types (
  club_id uuid not null references public.clubs(id) on delete restrict,
  game_type text not null check (nullif(btrim(game_type),'') is not null),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  primary key (club_id, game_type)
);

create table public.team_suspension_game_types (
  team_id uuid not null references public.teams(id) on delete restrict,
  game_type text not null check (nullif(btrim(game_type),'') is not null),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  primary key (team_id, game_type)
);

create table public.training_early_suspension_resets (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete restrict,
  season_id uuid not null references public.seasons(id) on delete restrict,
  player_id uuid not null references public.players(id) on delete restrict,
  matchday_id uuid not null references public.matchdays(id) on delete restrict,
  status text not null default 'pending'
    check (status in ('pending','applied','cancelled')),
  reason text not null check (nullif(btrim(reason),'') is not null),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  applied_at timestamptz,
  cancelled_by uuid references auth.users(id) on delete restrict,
  cancelled_at timestamptz,
  cancel_reason text,
  constraint training_early_suspension_resets_state_check check (
    (status = 'pending' and applied_at is null and cancelled_at is null
      and cancelled_by is null and cancel_reason is null)
    or
    (status = 'applied' and applied_at is not null and cancelled_at is null
      and cancelled_by is null and cancel_reason is null)
    or
    (status = 'cancelled' and applied_at is null and cancelled_at is not null
      and cancelled_by is not null and nullif(btrim(cancel_reason),'') is not null)
  ),
  unique (player_id, matchday_id)
);

create table public.training_early_suspension_reset_audit (
  id uuid primary key default gen_random_uuid(),
  reset_id uuid not null references public.training_early_suspension_resets(id) on delete restrict,
  action text not null check (action in ('created','applied','cancelled')),
  old_values jsonb,
  new_values jsonb,
  reason text,
  changed_by uuid not null references auth.users(id) on delete restrict,
  changed_at timestamptz not null default now()
);

create index training_early_reset_team_matchday_idx
  on public.training_early_suspension_resets(team_id, matchday_id, status);

-- Every new exposed public table has RLS enabled.
alter table public.training_behavior_events enable row level security;
alter table public.training_behavior_event_audit enable row level security;
alter table public.training_suspensions enable row level security;
alter table public.training_suspension_exceptions enable row level security;
alter table public.training_suspension_audit enable row level security;
alter table public.club_suspension_game_types enable row level security;
alter table public.team_suspension_game_types enable row level security;
alter table public.training_early_suspension_resets enable row level security;
alter table public.training_early_suspension_reset_audit enable row level security;

-- Explicit minimal API grants. No direct INSERT/UPDATE/DELETE for authenticated.
grant select on public.training_behavior_events,
  public.training_behavior_event_audit,
  public.training_suspensions,
  public.training_suspension_exceptions,
  public.training_suspension_audit,
  public.club_suspension_game_types,
  public.team_suspension_game_types,
  public.training_early_suspension_resets,
  public.training_early_suspension_reset_audit
to authenticated;

grant all on public.training_behavior_events,
  public.training_behavior_event_audit,
  public.training_suspensions,
  public.training_suspension_exceptions,
  public.training_suspension_audit,
  public.club_suspension_game_types,
  public.team_suspension_game_types,
  public.training_early_suspension_resets,
  public.training_early_suspension_reset_audit
to service_role;

-- Team member read access. Existing helper functions retain the app's team context rules.
create policy training_behavior_events_select on public.training_behavior_events
for select to authenticated using (public.is_team_member(team_id));

create policy training_behavior_event_audit_select on public.training_behavior_event_audit
for select to authenticated using (
  exists (select 1 from public.training_behavior_events e
          where e.id = event_id and public.is_team_member(e.team_id))
);

create policy training_suspensions_select on public.training_suspensions
for select to authenticated using (public.is_team_member(team_id));

create policy training_suspension_exceptions_select on public.training_suspension_exceptions
for select to authenticated using (
  exists (select 1 from public.training_suspensions s
          where s.id = suspension_id and public.is_team_member(s.team_id))
);

create policy training_suspension_audit_select on public.training_suspension_audit
for select to authenticated using (
  exists (select 1 from public.training_suspensions s
          where s.id = suspension_id and public.is_team_member(s.team_id))
);

create policy club_suspension_game_types_select on public.club_suspension_game_types
for select to authenticated using (
  public.is_club_member(club_id)
  or exists (
    select 1 from public.teams t
    where t.club_id = club_suspension_game_types.club_id
      and public.has_selected_team_context(t.id)
  )
);

create policy team_suspension_game_types_select on public.team_suspension_game_types
for select to authenticated using (public.is_team_member(team_id));

create policy training_early_suspension_resets_select on public.training_early_suspension_resets
for select to authenticated using (public.is_team_member(team_id));

create policy training_early_suspension_reset_audit_select on public.training_early_suspension_reset_audit
for select to authenticated using (
  exists (select 1 from public.training_early_suspension_resets r
          where r.id = reset_id and public.is_team_member(r.team_id))
);

-- No authenticated write policies are defined in this foundation migration.
-- Subsequent RPC migration must implement server-side authorization and write paths.

commit;
