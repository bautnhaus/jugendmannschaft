-- E05 Foundation | 20261108061900
-- Supabase DEV only: pzazqvvoruqnqhcorbwx
-- PREPARED ONLY. DO NOT EXECUTE without explicit user approval.
-- Additive schema; no existing rows are updated or deleted.
begin;

create table public.training_behavior_events (
 id uuid primary key default gen_random_uuid(),
 team_id uuid not null references public.teams(id) on delete restrict,
 season_id uuid references public.seasons(id) on delete restrict,
 training_id uuid not null references public.trainings(id) on delete restrict,
 player_id uuid not null references public.players(id) on delete restrict,
 event_type text not null check(event_type in ('yellow_card','red_card','positive_star')),
 reason text,
 awarded_by uuid not null,
 awarded_at timestamptz not null default now(),
 is_voided boolean not null default false,
 voided_at timestamptz,
 voided_by uuid,
 void_reason text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint tbe_reason_required check(event_type='positive_star' or nullif(btrim(reason),'') is not null),
 constraint tbe_void_metadata check(not is_voided or
   (voided_at is not null and voided_by is not null and nullif(btrim(void_reason),'') is not null))
);
create index tbe_team_season_player_idx on public.training_behavior_events(team_id,season_id,player_id,awarded_at desc);
create index tbe_training_idx on public.training_behavior_events(training_id,player_id);
create unique index tbe_one_active_card on public.training_behavior_events(training_id,player_id)
 where not is_voided and event_type in ('yellow_card','red_card');
create unique index tbe_one_active_star on public.training_behavior_events(training_id,player_id)
 where not is_voided and event_type='positive_star';

create table public.training_behavior_event_audit (
 id uuid primary key default gen_random_uuid(),
 event_id uuid not null references public.training_behavior_events(id) on delete restrict,
 team_id uuid not null references public.teams(id) on delete restrict,
 action text not null check(action in ('created','corrected','voided','reinstated')),
 actor_user_id uuid,
 occurred_at timestamptz not null default now(),
 reason text,
 old_values jsonb,
 new_values jsonb,
 constraint tbea_reason_required check(action='created' or nullif(btrim(reason),'') is not null)
);
create index tbea_event_time_idx on public.training_behavior_event_audit(event_id,occurred_at desc);

create table public.training_suspensions (
 id uuid primary key default gen_random_uuid(),
 team_id uuid not null references public.teams(id) on delete restrict,
 season_id uuid references public.seasons(id) on delete restrict,
 player_id uuid not null references public.players(id) on delete restrict,
 source_event_id uuid references public.training_behavior_events(id) on delete restrict,
 suspension_type text not null check(suspension_type in ('yellow','red')),
 status text not null default 'open' check(status in ('open','served','expired','cancelled')),
 intended_matchday_id uuid references public.matchdays(id) on delete restrict,
 served_matchday_id uuid references public.matchdays(id) on delete restrict,
 created_at timestamptz not null default now(),
 created_by uuid,
 closed_at timestamptz,
 closed_by uuid,
 closure_reason text,
 manual_correction_reason text,
 constraint ts_served_fields check(status<>'served' or (served_matchday_id is not null and closed_at is not null)),
 constraint ts_closure_reason check(status not in ('expired','cancelled') or nullif(btrim(closure_reason),'') is not null)
);
create index ts_player_status_idx on public.training_suspensions(team_id,season_id,player_id,status);
create index ts_intended_matchday_idx on public.training_suspensions(intended_matchday_id) where status='open';
create unique index ts_one_per_source_event on public.training_suspensions(source_event_id) where source_event_id is not null;

create table public.training_suspension_exceptions (
 id uuid primary key default gen_random_uuid(),
 suspension_id uuid not null references public.training_suspensions(id) on delete restrict,
 team_id uuid not null references public.teams(id) on delete restrict,
 matchday_id uuid not null references public.matchdays(id) on delete restrict,
 reason text not null check(nullif(btrim(reason),'') is not null),
 granted_by uuid not null,
 granted_at timestamptz not null default now(),
 created_at timestamptz not null default now(),
 unique(suspension_id,matchday_id)
);
create index tse_team_matchday_idx on public.training_suspension_exceptions(team_id,matchday_id);

create table public.training_suspension_resets (
 id uuid primary key default gen_random_uuid(),
 team_id uuid not null references public.teams(id) on delete restrict,
 season_id uuid references public.seasons(id) on delete restrict,
 player_id uuid not null references public.players(id) on delete restrict,
 matchday_id uuid not null references public.matchdays(id) on delete restrict,
 status text not null default 'pending' check(status in ('pending','applied','cancelled')),
 reason text not null check(nullif(btrim(reason),'') is not null),
 created_by uuid not null,
 created_at timestamptz not null default now(),
 applied_at timestamptz,
 cancelled_at timestamptz,
 cancelled_by uuid,
 cancellation_reason text,
 constraint tsr_applied_fields check(status<>'applied' or applied_at is not null),
 constraint tsr_cancelled_fields check(status<>'cancelled' or
   (cancelled_at is not null and nullif(btrim(cancellation_reason),'') is not null))
);
create unique index tsr_one_pending_player_matchday on public.training_suspension_resets(matchday_id,player_id) where status='pending';
create index tsr_team_season_status_idx on public.training_suspension_resets(team_id,season_id,status);

create table public.training_suspension_audit (
 id uuid primary key default gen_random_uuid(),
 team_id uuid not null references public.teams(id) on delete restrict,
 suspension_id uuid references public.training_suspensions(id) on delete restrict,
 exception_id uuid references public.training_suspension_exceptions(id) on delete restrict,
 reset_id uuid references public.training_suspension_resets(id) on delete restrict,
 action text not null check(action in ('suspension_created','suspension_corrected','suspension_served','suspension_expired','suspension_cancelled','exception_granted','reset_created','reset_applied','reset_cancelled')),
 actor_user_id uuid,
 occurred_at timestamptz not null default now(),
 reason text,
 old_values jsonb,
 new_values jsonb,
 constraint tsa_one_subject check(num_nonnulls(suspension_id,exception_id,reset_id)=1),
 constraint tsa_reason_required check(action in ('suspension_created','reset_created') or nullif(btrim(reason),'') is not null)
);
create index tsa_team_time_idx on public.training_suspension_audit(team_id,occurred_at desc);

create table public.club_suspension_settings (
 club_id uuid primary key references public.clubs(id) on delete restrict,
 relevant_game_types text[] not null,
 updated_at timestamptz not null default now(),
 updated_by uuid,
 constraint css_nonempty check(cardinality(relevant_game_types)>0),
 constraint css_values check(relevant_game_types <@ array['Meisterschaft','Freundschaftsspiel','Turnier']::text[])
);
create table public.team_suspension_settings (
 team_id uuid primary key references public.teams(id) on delete restrict,
 relevant_game_types text[] not null,
 updated_at timestamptz not null default now(),
 updated_by uuid,
 constraint tss_nonempty check(cardinality(relevant_game_types)>0),
 constraint tss_values check(relevant_game_types <@ array['Meisterschaft','Freundschaftsspiel','Turnier']::text[])
);

-- Validate attendance, active player and team/season consistency at write time.
create function public.validate_training_behavior_event_insert()
returns trigger language plpgsql security invoker
set search_path=pg_catalog,public
as $$
declare v_team uuid; v_season uuid; v_status text; v_player_team uuid; v_present boolean;
begin
 if auth.uid() is null then raise exception 'Anmeldung erforderlich' using errcode='42501'; end if;
 select team_id,season_id,status into v_team,v_season,v_status from public.trainings where id=new.training_id;
 if not found then raise exception 'Training nicht gefunden' using errcode='23503'; end if;
 select team_id into v_player_team from public.players where id=new.player_id and active=true;
 if not found then raise exception 'Spieler nicht gefunden oder inaktiv' using errcode='23514'; end if;
 select present into v_present from public.attendance where training_id=new.training_id and player_id=new.player_id;
 if coalesce(v_present,false) is not true then raise exception 'Ereignisse nur für anwesende Spieler' using errcode='23514'; end if;
 if v_status='cancelled' then raise exception 'Abgesagtes Training' using errcode='23514'; end if;
 if new.team_id is distinct from v_team or new.team_id is distinct from v_player_team then
   raise exception 'Training, Spieler und Ereignis müssen derselben Mannschaft zugeordnet sein' using errcode='23514';
 end if;
 if new.season_id is distinct from v_season then raise exception 'Saison stimmt nicht mit Training überein' using errcode='23514'; end if;
 if new.awarded_by is distinct from auth.uid() then raise exception 'awarded_by muss dem angemeldeten Benutzer entsprechen' using errcode='42501'; end if;
 return new;
end; $$;
create trigger validate_training_behavior_event_insert before insert on public.training_behavior_events
for each row execute function public.validate_training_behavior_event_insert();

-- Immutable audit snapshots. Updates require a transaction-local reason set by the future audited RPC.
create function public.audit_training_behavior_event_change()
returns trigger language plpgsql security definer
set search_path=pg_catalog,public,auth
as $$
declare v_reason text; v_action text;
begin
 if tg_op='INSERT' then
   insert into public.training_behavior_event_audit(event_id,team_id,action,actor_user_id,new_values)
   values(new.id,new.team_id,'created',auth.uid(),to_jsonb(new));
   return new;
 end if;
 v_reason:=nullif(btrim(current_setting('app.e05_audit_reason',true)),'');
 if v_reason is null then raise exception 'Änderung benötigt eine Begründung' using errcode='23514'; end if;
 if not old.is_voided and new.is_voided then v_action:='voided';
 elsif old.is_voided and not new.is_voided then v_action:='reinstated';
 else v_action:='corrected'; end if;
 insert into public.training_behavior_event_audit(event_id,team_id,action,actor_user_id,reason,old_values,new_values)
 values(new.id,new.team_id,v_action,auth.uid(),v_reason,to_jsonb(old),to_jsonb(new));
 return new;
end; $$;
create trigger audit_training_behavior_event_change after insert or update on public.training_behavior_events
for each row execute function public.audit_training_behavior_event_change();

alter table public.training_behavior_events enable row level security;
alter table public.training_behavior_event_audit enable row level security;
alter table public.training_suspensions enable row level security;
alter table public.training_suspension_exceptions enable row level security;
alter table public.training_suspension_resets enable row level security;
alter table public.training_suspension_audit enable row level security;
alter table public.club_suspension_settings enable row level security;
alter table public.team_suspension_settings enable row level security;

create policy training_behavior_events_select on public.training_behavior_events for select to authenticated
using(public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_behavior_events_insert on public.training_behavior_events for insert to authenticated
with check(public.is_team_member(team_id) and awarded_by=auth.uid() and exists(
 select 1 from public.trainings t join public.players p on p.id=training_behavior_events.player_id
 join public.attendance a on a.training_id=t.id and a.player_id=p.id
 where t.id=training_behavior_events.training_id and t.team_id=training_behavior_events.team_id
 and t.season_id is not distinct from training_behavior_events.season_id
 and p.team_id=training_behavior_events.team_id and p.active and a.present and t.status<>'cancelled'
));
create policy training_behavior_event_audit_select on public.training_behavior_event_audit for select to authenticated
using(public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_suspensions_select on public.training_suspensions for select to authenticated
using(public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_suspension_exceptions_select on public.training_suspension_exceptions for select to authenticated
using(public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_suspension_resets_select on public.training_suspension_resets for select to authenticated
using(public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy training_suspension_audit_select on public.training_suspension_audit for select to authenticated
using(public.is_team_member(team_id) or public.has_selected_team_context(team_id));
create policy club_suspension_settings_select on public.club_suspension_settings for select to authenticated
using(exists(select 1 from public.teams t where t.club_id=club_suspension_settings.club_id
 and (public.is_team_member(t.id) or public.has_selected_team_context(t.id))));
create policy team_suspension_settings_select on public.team_suspension_settings for select to authenticated
using(public.is_team_member(team_id) or public.has_selected_team_context(team_id));

-- Remove inherited/default privileges, then grant only the required read/insert surface.
revoke all on public.training_behavior_events,public.training_behavior_event_audit,public.training_suspensions,
 public.training_suspension_exceptions,public.training_suspension_resets,public.training_suspension_audit,
 public.club_suspension_settings,public.team_suspension_settings from public,anon,authenticated;
grant select,insert on public.training_behavior_events to authenticated;
grant select on public.training_behavior_event_audit,public.training_suspensions,public.training_suspension_exceptions,
 public.training_suspension_resets,public.training_suspension_audit,public.club_suspension_settings,
 public.team_suspension_settings to authenticated;
revoke all on function public.audit_training_behavior_event_change() from public,anon,authenticated;
revoke all on function public.validate_training_behavior_event_insert() from public,anon,authenticated;

commit;
