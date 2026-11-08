-- E05-SQL-001 | Foundation: Trainingsereignisse, Sperren, Ausnahmen und Sperrausgleich
-- Ziel: ausschließlich Supabase DEV (pzazqvvoruqnqhcorbwx) nach ausdrücklicher Freigabe.
-- Status: VORBEREITET / NICHT AUSGEFÜHRT.
-- Reine Schema-Foundation. Keine Bestandsdaten werden geändert.
-- Schreibzugriffe durch Clients bleiben gesperrt, bis geprüfte Audit-RPCs separat freigegeben sind.

begin;

create table public.training_behavior_events (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete restrict,
  season_id uuid not null references public.seasons(id) on delete restrict,
  training_id uuid not null references public.trainings(id) on delete restrict,
  player_id uuid not null references public.players(id) on delete restrict,
  event_type text not null check (event_type in ('yellow_card','red_card','positive_star')),
  reason text,
  awarded_by uuid references auth.users(id) on delete set null,
  awarded_at timestamptz not null default now(),
  voided_at timestamptz,
  voided_by uuid references auth.users(id) on delete set null,
  void_reason text,
  reinstated_at timestamptz,
  reinstated_by uuid references auth.users(id) on delete set null,
  reinstatement_reason text,
  created_at timestamptz not null default now(),
  constraint training_behavior_events_reason_chk check (
    event_type = 'positive_star' or nullif(btrim(reason), '') is not null
  ),
  constraint training_behavior_events_void_chk check (
    (voided_at is null and voided_by is null and void_reason is null)
    or (voided_at is not null and nullif(btrim(void_reason), '') is not null)
  ),
  constraint training_behavior_events_reinstate_chk check (
    (reinstated_at is null and reinstated_by is null and reinstatement_reason is null)
    or (reinstated_at is not null and nullif(btrim(reinstatement_reason), '') is not null)
  )
);
comment on table public.training_behavior_events is
  'E05: Historisierte Trainingsereignisse (Karten/Sterne); Storno und Reaktivierung werden auditiert, nicht gelöscht.';
comment on column public.training_behavior_events.team_id is
  'Historischer Mannschaftsbezug zum Zeitpunkt des Ereignisses; nicht aus players.team_id ableiten.';
comment on column public.training_behavior_events.season_id is
  'Historischer Saisonbezug zum Zeitpunkt des Ereignisses; Vergabe-RPC ermittelt die aktive Saison, falls trainings.season_id leer ist.';
comment on column public.training_behavior_events.reason is
  'Bei gelber/roter Karte verpflichtend; bei positivem Stern optional.';

create unique index training_behavior_events_one_card_per_player_training_uq
  on public.training_behavior_events(training_id, player_id)
  where event_type in ('yellow_card','red_card') and voided_at is null;
create unique index training_behavior_events_one_star_per_player_training_uq
  on public.training_behavior_events(training_id, player_id)
  where event_type = 'positive_star' and voided_at is null;
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
  changed_by uuid references auth.users(id) on delete set null,
  changed_at timestamptz not null default now(),
  constraint training_behavior_event_audit_reason_chk check (
    action = 'created' or nullif(btrim(reason), '') is not null
  )
);
comment on table public.training_behavior_event_audit is
  'E05: Auditspur zu Anlage, Korrektur, Storno und Reaktivierung von Trainingsereignissen.';
create index training_behavior_event_audit_event_idx
  on public.training_behavior_event_audit(event_id, changed_at desc);

create table public.training_suspensions (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete restrict,
  season_id uuid not null references public.seasons(id) on delete restrict,
  player_id uuid not null references public.players(id) on delete restrict,
  triggering_event_id uuid not null references public.training_behavior_events(id) on delete restrict,
  suspension_type text not null check (suspension_type in ('yellow','red')),
  status text not null default 'open' check (status in ('open','served','expired')),
  intended_matchday_id uuid references public.matchdays(id) on delete restrict,
  served_matchday_id uuid references public.matchdays(id) on delete restrict,
  created_at timestamptz not null default now(),
  served_at timestamptz,
  expired_at timestamptz,
  constraint training_suspensions_lifecycle_chk check (
    (status = 'open' and served_matchday_id is null and served_at is null and expired_at is null)
    or (status = 'served' and served_matchday_id is not null and served_at is not null and expired_at is null)
    or (status = 'expired' and served_matchday_id is null and served_at is null and expired_at is not null)
  )
);
comment on table public.training_suspensions is
  'E05: Gelbe/rote Sperren mit eigenem Lebenszyklus und dauerhaftem Team-/Saisonbezug.';
create unique index training_suspensions_one_per_trigger_uq
  on public.training_suspensions(triggering_event_id);
create index training_suspensions_open_player_idx
  on public.training_suspensions(team_id, season_id, player_id, created_at)
  where status = 'open';
create index training_suspensions_target_matchday_idx
  on public.training_suspensions(intended_matchday_id)
  where status = 'open';

create table public.training_suspension_exceptions (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
  matchday_id uuid not null references public.matchdays(id) on delete restrict,
  reason text not null check (nullif(btrim(reason), '') is not null),
  granted_by uuid references auth.users(id) on delete set null,
  granted_at timestamptz not null default now(),
  revoked_by uuid references auth.users(id) on delete set null,
  revoked_at timestamptz,
  revocation_reason text,
  constraint training_suspension_exceptions_revocation_chk check (
    (revoked_at is null and revoked_by is null and revocation_reason is null)
    or (revoked_at is not null and nullif(btrim(revocation_reason), '') is not null)
  ),
  unique (suspension_id, matchday_id)
);
comment on table public.training_suspension_exceptions is
  'E05: Begründete, spieltagsspezifische Ausnahme; die Sperre bleibt offen und wird weitergeschoben.';
create index training_suspension_exceptions_matchday_idx
  on public.training_suspension_exceptions(matchday_id, suspension_id);

create table public.training_suspension_audit (
  id uuid primary key default gen_random_uuid(),
  suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
  action text not null check (action in ('created','reassigned','served','expired','corrected','exception_granted','exception_revoked')),
  old_values jsonb,
  new_values jsonb,
  reason text,
  changed_by uuid references auth.users(id) on delete set null,
  changed_at timestamptz not null default now(),
  constraint training_suspension_audit_reason_chk check (
    action in ('created','served','expired') or nullif(btrim(reason), '') is not null
  )
);
comment on table public.training_suspension_audit is
  'E05: Auditspur des Sperrenlebenszyklus, einschließlich Verschiebungen, Korrekturen und Ausnahmen.';
create index training_suspension_audit_suspension_idx
  on public.training_suspension_audit(suspension_id, changed_at desc);

create table public.club_suspension_game_type_settings (
  club_id uuid primary key references public.clubs(id) on delete restrict,
  relevant_game_types text[] not null default array['championship','friendly','tournament']::text[],
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null,
  constraint club_suspension_game_types_allowed_chk check (
    relevant_game_types <@ array['championship','friendly','tournament']::text[]
  )
);
comment on table public.club_suspension_game_type_settings is
  'E05: Vereinsstandard für Spielarten, die eine Sperre tatsächlich verbüßen.';

create table public.team_suspension_game_type_overrides (
  team_id uuid primary key references public.teams(id) on delete restrict,
  relevant_game_types text[] not null default array[]::text[],
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null,
  constraint team_suspension_game_types_allowed_chk check (
    relevant_game_types <@ array['championship','friendly','tournament']::text[]
  )
);
comment on table public.team_suspension_game_type_overrides is
  'E05: Vollständiger Mannschafts-Override; vorhandener Datensatz ersetzt den Vereinsstandard, auch bei leerer Liste.';

create table public.matchday_early_suspension_resets (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete restrict,
  season_id uuid not null references public.seasons(id) on delete restrict,
  matchday_id uuid not null references public.matchdays(id) on delete restrict,
  player_id uuid not null references public.players(id) on delete restrict,
  status text not null default 'pending' check (status in ('pending','applied','cancelled')),
  reason text not null check (nullif(btrim(reason), '') is not null),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  applied_at timestamptz,
  cancelled_by uuid references auth.users(id) on delete set null,
  cancelled_at timestamptz,
  cancellation_reason text,
  constraint matchday_early_suspension_resets_status_chk check (
    (status = 'pending' and applied_at is null and cancelled_at is null)
    or (status = 'applied' and applied_at is not null and cancelled_at is null)
    or (status = 'cancelled' and applied_at is null and cancelled_at is not null
        and nullif(btrim(cancellation_reason), '') is not null)
  ),
  unique (matchday_id, player_id)
);
comment on table public.matchday_early_suspension_resets is
  'E05: Freiwilliger, spieltagsspezifischer vorzeitiger Sperrausgleich; wirkt erst nach tatsächlichem Stattfinden und ist keine regulär verbüßte Sperre.';
create index matchday_early_suspension_resets_pending_idx
  on public.matchday_early_suspension_resets(team_id, season_id, player_id)
  where status = 'pending';

create table public.training_behavior_audit_log (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete restrict,
  entity_type text not null check (entity_type in ('event','suspension','exception','early_reset','configuration')),
  entity_id uuid not null,
  action text not null,
  old_values jsonb,
  new_values jsonb,
  reason text,
  changed_by uuid references auth.users(id) on delete set null,
  changed_at timestamptz not null default now()
);
comment on table public.training_behavior_audit_log is
  'E05: Ergänzendes Auditjournal für Konfigurations- und Querschnittsaktionen; entity_id ist polymorph.';

create index training_behavior_audit_log_team_idx
  on public.training_behavior_audit_log(team_id, changed_at desc);

alter table public.training_behavior_events enable row level security;
alter table public.training_behavior_event_audit enable row level security;
alter table public.training_suspensions enable row level security;
alter table public.training_suspension_exceptions enable row level security;
alter table public.training_suspension_audit enable row level security;
alter table public.club_suspension_game_type_settings enable row level security;
alter table public.team_suspension_game_type_overrides enable row level security;
alter table public.matchday_early_suspension_resets enable row level security;
alter table public.training_behavior_audit_log enable row level security;

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
create policy club_suspension_game_type_settings_select on public.club_suspension_game_type_settings
  for select to authenticated using (
    exists (
      select 1 from public.teams t
      where t.club_id = club_id and public.is_team_member(t.id)
    )
    or exists (
      select 1
      from public.club_members cm
      join public.club_member_roles cmr on cmr.user_id = cm.user_id
      join public.user_club_context ucc on ucc.user_id = cm.user_id and ucc.club_id = cm.club_id
      where cm.club_id = club_suspension_game_type_settings.club_id
        and cm.user_id = auth.uid()
        and cmr.role = 'club_admin'
    )
    or (public.is_super_admin() and exists (
      select 1 from public.user_club_context ucc
      where ucc.club_id = club_suspension_game_type_settings.club_id
        and ucc.user_id = auth.uid()
    ))
  );
create policy team_suspension_game_type_overrides_select on public.team_suspension_game_type_overrides
  for select to authenticated using (public.is_team_member(team_id));
create policy matchday_early_suspension_resets_select on public.matchday_early_suspension_resets
  for select to authenticated using (public.is_team_member(team_id));
create policy training_behavior_audit_log_select on public.training_behavior_audit_log
  for select to authenticated using (public.is_team_member(team_id));

-- Direct client writes are deliberately disabled until audited RPCs are added.
revoke all on public.training_behavior_events from anon, authenticated;
revoke all on public.training_behavior_event_audit from anon, authenticated;
revoke all on public.training_suspensions from anon, authenticated;
revoke all on public.training_suspension_exceptions from anon, authenticated;
revoke all on public.training_suspension_audit from anon, authenticated;
revoke all on public.club_suspension_game_type_settings from anon, authenticated;
revoke all on public.team_suspension_game_type_overrides from anon, authenticated;
revoke all on public.matchday_early_suspension_resets from anon, authenticated;
revoke all on public.training_behavior_audit_log from anon, authenticated;

grant select on public.training_behavior_events to authenticated;
grant select on public.training_behavior_event_audit to authenticated;
grant select on public.training_suspensions to authenticated;
grant select on public.training_suspension_exceptions to authenticated;
grant select on public.training_suspension_audit to authenticated;
grant select on public.club_suspension_game_type_settings to authenticated;
grant select on public.team_suspension_game_type_overrides to authenticated;
grant select on public.matchday_early_suspension_resets to authenticated;
grant select on public.training_behavior_audit_log to authenticated;

commit;
