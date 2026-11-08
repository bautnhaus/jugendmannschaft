-- E05 / AP05 – Schemafundament Trainingsereignisse und Sperren
-- Review-Entwurf Revision 3 | 08.11.2026
-- Target: Supabase DEV only (pzazqvvoruqnqhcorbwx)
-- Status: REVIEW DRAFT – NOT APPROVED – DO NOT EXECUTE
-- This is a review artifact under docs/, not a Supabase migration file.
-- Do not execute until static review, isolated PostgreSQL testing,
-- RLS/ACL review, rollback planning and explicit user approval are complete.
-- No existing table, function, trigger, policy or data row is modified.

begin;

-- 1. Training events. Team/season/training/matchday IDs are historical snapshots,
-- not operational FKs. This avoids partial failures in existing sequential delete flows.
-- Player identity survives player deletion via nullable FK + name snapshot.
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
  player_name_snapshot text not null check (nullif(btrim(player_name_snapshot),'') is not null),
  event_type text not null check (event_type in ('yellow_card','red_card','positive_star')),
  reason text,
  status text not null default 'active' check (status in ('active','voided')),
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
    check (event_type = 'positive_star' or nullif(btrim(reason),'') is not null),
  constraint training_behavior_events_void_metadata_check
    check (
      (status = 'active' and voided_by is null and voided_by_snapshot is null
       and voided_at is null and void_reason is null)
      or
      (status = 'voided' and voided_at is not null
       and nullif(btrim(void_reason),'') is not null)
    )
);

create unique index training_behavior_events_one_card_per_player_training
  on public.training_behavior_events(training_id, player_id)
  where status = 'active' and player_id is not null
    and event_type in ('yellow_card','red_card');
create unique index training_behavior_events_one_star_per_player_training
  on public.training_behavior_events(training_id, player_id)
  where status = 'active' and player_id is not null
    and event_type = 'positive_star';
create index training_behavior_events_player_season_idx
  on public.training_behavior_events(team_id, season_id, player_id, awarded_at desc);
create index training_behavior_events_training_idx
  on public.training_behavior_events(training_id, player_id);

-- 2. Event audit; actor FK may become NULL when an Auth account is deleted.
create table public.training_behavior_event_audit (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.training_behavior_events(id) on delete restrict,
  action text not null check (action in ('created','corrected','voided','reinstated')),
  old_values jsonb,
  new_values jsonb not null,
  reason text,
  changed_by uuid references auth.users(id) on delete set null,
  changed_by_snapshot text,
  changed_at timestamptz not null default now(),
  constraint training_behavior_event_audit_reason_check
    check (action = 'created' or nullif(btrim(reason),'') is not null)
);
create index training_behavior_event_audit_event_idx
  on public.training_behavior_event_audit(event_id, changed_at desc);

-- 3. Rule-based suspensions. A suspension always has one source event.
-- Matchday IDs/dates/opponents are snapshots; deleting a matchday does not block or erase history.
create table public.training_suspensions (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null,
  team_name_snapshot text not null,
  season_id uuid not null,
  season_name_snapshot text not null,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null check (nullif(btrim(player_name_snapshot),'') is not null),
  source_event_id uuid not null references public.training_behavior_events(id) on delete restrict,
  suspension_type text not null check (suspension_type in ('yellow','red')),
  status text not null default 'open'
    check (status in ('open','served','expired','voided')),
  intended_matchday_id uuid,
  intended_matchday_date_snapshot date,
  intended_matchday_opponent_snapshot text,
  served_matchday_id uuid,
  served_matchday_date_snapshot date,
  served_matchday_opponent_snapshot text,
  created_by uuid references auth.users(id) on delete set null,
  created_by_snapshot text,
  created_at timestamptz not null default now(),
  served_at timestamptz,
  expired_at timestamptz,
  voided_by uuid references auth.users(id) on delete set null,
  voided_by_snapshot text,
  voided_at timestamptz,
  void_reason text,
  constraint training_suspensions_served_metadata_check
    check ((status = 'served' and served_matchday_id is not null and served_at is not null)
       or (status <> 'served' and served_at is null and served_matchday_id is null)),
  constraint training_suspensions_expired_metadata_check
    check ((status = 'expired' and expired_at is not null)
       or (status <> 'expired' and expired_at is null)),
  constraint training_suspensions_void_metadata_check
    check ((status = 'voided' and voided_at is not null and nullif(btrim(void_reason),'') is not null)
       or (status <> 'voided' and voided_at is null and void_reason is null))
);
create unique index training_suspensions_one_per_source_event
  on public.training_suspensions(source_event_id);
create index training_suspensions_open_player_idx
  on public.training_suspensions(team_id, season_id, player_id, created_at)
  where status = 'open';
create index training_suspensions_matchday_idx
  on public.training_suspensions(intended_matchday_id)
  where status = 'open';

-- 4. Exceptions for one exact suspension + matchday; matchday identity is snapshotted.
create table public.training_suspension_exceptions (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
  team_id uuid not null,
  team_name_snapshot text not null,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null,
  matchday_id uuid not null,
  matchday_date_snapshot date not null,
  matchday_opponent_snapshot text,
  reason text not null check (nullif(btrim(reason),'') is not null),
  granted_by uuid references auth.users(id) on delete set null,
  granted_by_snapshot text,
  granted_at timestamptz not null default now(),
  revoked_by uuid references auth.users(id) on delete set null,
  revoked_by_snapshot text,
  revoked_at timestamptz,
  revoke_reason text,
  constraint training_suspension_exceptions_revocation_check
    check ((revoked_at is null and revoked_by is null and revoke_reason is null)
       or (revoked_at is not null and nullif(btrim(revoke_reason),'') is not null))
);
create unique index training_suspension_exceptions_one_active_per_suspension_matchday
  on public.training_suspension_exceptions(suspension_id, matchday_id)
  where revoked_at is null;
create index training_suspension_exceptions_matchday_idx
  on public.training_suspension_exceptions(team_id, matchday_id);

-- 5. Suspension/exception audit with exactly one audited subject.
create table public.training_suspension_audit (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid references public.training_suspensions(id) on delete restrict,
  exception_id uuid references public.training_suspension_exceptions(id) on delete restrict,
  action text not null check (
    action in ('created','target_changed','served','expired','exception_granted',
      'exception_revoked','corrected','voided','reinstated')
  ),
  old_values jsonb,
  new_values jsonb not null,
  reason text,
  changed_by uuid references auth.users(id) on delete set null,
  changed_by_snapshot text,
  changed_at timestamptz not null default now(),
  constraint training_suspension_audit_one_subject_check
    check (num_nonnulls(suspension_id, exception_id) = 1),
  constraint training_suspension_audit_reason_check
    check (action = 'created' or nullif(btrim(reason),'') is not null)
);
create index training_suspension_audit_suspension_idx
  on public.training_suspension_audit(suspension_id, changed_at desc)
  where suspension_id is not null;
create index training_suspension_audit_exception_idx
  on public.training_suspension_audit(exception_id, changed_at desc)
  where exception_id is not null;

-- 6. Club default list. A team override is a separate header + child list.
create table public.club_suspension_settings (
  club_id uuid primary key references public.clubs(id) on delete restrict,
  relevant_game_types text[] not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null,
  constraint club_suspension_settings_values_check
    check (relevant_game_types <@ array['Meisterschaft','Freundschaftsspiel','Turnier']::text[])
);

create table public.team_suspension_game_type_settings (
  team_id uuid primary key references public.teams(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);
-- Header existence means override. Zero child rows means an intentionally empty override.
create table public.team_suspension_game_types (
  team_id uuid not null references public.team_suspension_game_type_settings(team_id) on delete cascade,
  game_type text not null check (game_type in ('Meisterschaft','Freundschaftsspiel','Turnier')),
  created_at timestamptz not null default now(),
  primary key (team_id, game_type)
);

-- 7. Early suspension-equivalent reset for a specific matchday; matchday identity is snapshotted.
create table public.matchday_early_suspension_resets (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null,
  team_name_snapshot text not null,
  season_id uuid not null,
  season_name_snapshot text not null,
  player_id uuid references public.players(id) on delete set null,
  player_name_snapshot text not null check (nullif(btrim(player_name_snapshot),'') is not null),
  matchday_id uuid not null,
  matchday_date_snapshot date not null,
  matchday_opponent_snapshot text,
  status text not null default 'pending'
    check (status in ('pending','applied','cancelled')),
  reason text not null check (nullif(btrim(reason),'') is not null),
  created_by uuid references auth.users(id) on delete set null,
  created_by_snapshot text,
  created_at timestamptz not null default now(),
  applied_at timestamptz,
  cancelled_by uuid references auth.users(id) on delete set null,
  cancelled_by_snapshot text,
  cancelled_at timestamptz,
  cancel_reason text,
  constraint matchday_early_suspension_resets_state_check check (
    (status = 'pending' and applied_at is null and cancelled_at is null
      and cancelled_by is null and cancel_reason is null)
    or
    (status = 'applied' and applied_at is not null and cancelled_at is null
      and cancelled_by is null and cancel_reason is null)
    or
    (status = 'cancelled' and applied_at is null and cancelled_at is not null
      and nullif(btrim(cancel_reason),'') is not null)
  )
);
create unique index matchday_early_suspension_resets_one_pending_player_matchday
  on public.matchday_early_suspension_resets(matchday_id, player_id)
  where status = 'pending' and player_id is not null;
create index matchday_early_suspension_resets_team_matchday_idx
  on public.matchday_early_suspension_resets(team_id, matchday_id, status);

-- 8. Early reset audit.
create table public.matchday_early_suspension_reset_audit (
  id uuid primary key default gen_random_uuid(),
  reset_id uuid not null references public.matchday_early_suspension_resets(id) on delete restrict,
  action text not null check (action in ('created','applied','cancelled','corrected')),
  old_values jsonb,
  new_values jsonb not null,
  reason text,
  changed_by uuid references auth.users(id) on delete set null,
  changed_by_snapshot text,
  changed_at timestamptz not null default now(),
  constraint matchday_early_suspension_reset_audit_reason_check
    check (action in ('created','applied') or nullif(btrim(reason),'') is not null)
);
create index matchday_early_suspension_reset_audit_idx
  on public.matchday_early_suspension_reset_audit(reset_id, changed_at desc);

-- RLS on every exposed table.
alter table public.training_behavior_events enable row level security;
alter table public.training_behavior_event_audit enable row level security;
alter table public.training_suspensions enable row level security;
alter table public.training_suspension_exceptions enable row level security;
alter table public.training_suspension_audit enable row level security;
alter table public.club_suspension_settings enable row level security;
alter table public.team_suspension_game_type_settings enable row level security;
alter table public.team_suspension_game_types enable row level security;
alter table public.matchday_early_suspension_resets enable row level security;
alter table public.matchday_early_suspension_reset_audit enable row level security;

-- Append-only protection for audit history. Mutations are rejected even for service_role;
-- audited writes are INSERT-only and future RPCs execute as their tightly controlled owner.
create function public.e05_reject_audit_mutation()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $
begin
  raise exception 'E05 audit tables are append-only; % is not permitted on %', TG_OP, TG_TABLE_NAME
    using errcode = '55000';
end;
$;

create trigger training_behavior_event_audit_append_only
before update or delete on public.training_behavior_event_audit
for each row execute function public.e05_reject_audit_mutation();
create trigger training_suspension_audit_append_only
before update or delete on public.training_suspension_audit
for each row execute function public.e05_reject_audit_mutation();
create trigger matchday_early_suspension_reset_audit_append_only
before update or delete on public.matchday_early_suspension_reset_audit
for each row execute function public.e05_reject_audit_mutation();

-- Remove inherited/default API privileges before granting minimum access.
revoke all on public.training_behavior_events,
  public.training_behavior_event_audit,
  public.training_suspensions,
  public.training_suspension_exceptions,
  public.training_suspension_audit,
  public.club_suspension_settings,
  public.team_suspension_game_type_settings,
  public.team_suspension_game_types,
  public.matchday_early_suspension_resets,
  public.matchday_early_suspension_reset_audit
from public, anon, authenticated;

grant select on public.training_behavior_events,
  public.training_behavior_event_audit,
  public.training_suspensions,
  public.training_suspension_exceptions,
  public.training_suspension_audit,
  public.club_suspension_settings,
  public.team_suspension_game_type_settings,
  public.team_suspension_game_types,
  public.matchday_early_suspension_resets,
  public.matchday_early_suspension_reset_audit
to authenticated;

-- Backend role receives only read/insert at table level. Mutating domain rows is
-- reserved for future reviewed SECURITY DEFINER RPCs; audit rows are INSERT-only.
grant select, insert on public.training_behavior_events,
  public.training_behavior_event_audit,
  public.training_suspensions,
  public.training_suspension_exceptions,
  public.training_suspension_audit,
  public.club_suspension_settings,
  public.team_suspension_game_type_settings,
  public.team_suspension_game_types,
  public.matchday_early_suspension_resets,
  public.matchday_early_suspension_reset_audit
to service_role;

-- Team members and selected team-context administrators may read team-scoped rows.
create policy training_behavior_events_select on public.training_behavior_events
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy training_behavior_event_audit_select on public.training_behavior_event_audit
for select to authenticated using (
  exists (select 1 from public.training_behavior_events e
          where e.id = event_id
            and (public.is_team_member(e.team_id) or public.has_selected_team_context(e.team_id)))
);

create policy training_suspensions_select on public.training_suspensions
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy training_suspension_exceptions_select on public.training_suspension_exceptions
for select to authenticated using (
  exists (select 1 from public.training_suspensions s
          where s.id = suspension_id
            and (public.is_team_member(s.team_id) or public.has_selected_team_context(s.team_id)))
);

create policy training_suspension_audit_select on public.training_suspension_audit
for select to authenticated using (
  (suspension_id is not null and exists (
    select 1 from public.training_suspensions s where s.id = suspension_id
      and (public.is_team_member(s.team_id) or public.has_selected_team_context(s.team_id))))
  or
  (exception_id is not null and exists (
    select 1 from public.training_suspension_exceptions e
    join public.training_suspensions s on s.id = e.suspension_id
    where e.id = exception_id
      and (public.is_team_member(s.team_id) or public.has_selected_team_context(s.team_id))))
);

create policy club_suspension_settings_select on public.club_suspension_settings
for select to authenticated using (
  exists (
    select 1 from public.teams t
    where t.club_id = club_suspension_settings.club_id and public.is_team_member(t.id)
  )
  or (
    public.can_manage_club_context(club_id)
    and exists (
      select 1 from public.user_club_context ucc
      where ucc.user_id = auth.uid() and ucc.club_id = club_suspension_settings.club_id
    )
  )
);

create policy team_suspension_game_type_settings_select on public.team_suspension_game_type_settings
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy team_suspension_game_types_select on public.team_suspension_game_types
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy matchday_early_suspension_resets_select on public.matchday_early_suspension_resets
for select to authenticated
using (public.is_team_member(team_id) or public.has_selected_team_context(team_id));

create policy matchday_early_suspension_reset_audit_select on public.matchday_early_suspension_reset_audit
for select to authenticated using (
  exists (select 1 from public.matchday_early_suspension_resets r
          where r.id = reset_id
            and (public.is_team_member(r.team_id) or public.has_selected_team_context(r.team_id)))
);

-- No authenticated write policies. All future writes go through reviewed RPCs.
commit;
