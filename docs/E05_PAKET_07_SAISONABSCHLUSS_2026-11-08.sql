-- E05 / AP05 – Paket 7: Kontrollierter Saisonabschluss
-- Ziel: Supabase DEV only (pzazqvvoruqnqhcorbwx)
-- Status: AM 08.11.2026 IN SUPABASE DEV AUSGEFÜHRT; POSITIV-/NEGATIVTESTS BESTANDEN
-- Keine PROD-Änderungen.

begin;

create table if not exists public.team_season_closure_audit (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete restrict,
  season_id uuid not null references public.seasons(id) on delete restrict,
  closed_by uuid references auth.users(id) on delete set null,
  closed_at timestamptz not null default now(),
  reason text not null check (nullif(btrim(reason),'') is not null),
  expired_suspensions_count integer not null default 0 check (expired_suspensions_count >= 0),
  season_name_snapshot text not null,
  unique (season_id)
);

alter table public.team_season_closure_audit enable row level security;

revoke all on public.team_season_closure_audit from anon, authenticated;
grant select on public.team_season_closure_audit to authenticated;

create policy team_season_closure_audit_select_team
on public.team_season_closure_audit
for select to authenticated
using (public.is_team_member(team_id));

create or replace function public.e05_reject_season_closure_audit_mutation()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
begin
  raise exception 'Season closure audit is append-only';
end;
$function$;

revoke all on function public.e05_reject_season_closure_audit_mutation()
from public, anon, authenticated, service_role;

drop trigger if exists team_season_closure_audit_no_mutation
on public.team_season_closure_audit;

create trigger team_season_closure_audit_no_mutation
before update or delete or truncate
on public.team_season_closure_audit
for each statement
execute function public.e05_reject_season_closure_audit_mutation();

create or replace function public.close_team_season(
  p_season_id uuid,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_actor uuid := auth.uid();
  v_season public.seasons%rowtype;
  v_actor_name text;
  v_now timestamptz := now();
  v_expired_count integer := 0;
  v_audit_id uuid;
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;

  if p_season_id is null or nullif(btrim(p_reason),'') is null then
    raise exception using errcode='22023',
      message='Season ID and non-empty closure reason are required';
  end if;

  select * into v_season
  from public.seasons
  where id=p_season_id
  for update;

  if not found then
    raise exception using errcode='P0002',message='Season not found';
  end if;

  if not v_season.is_active then
    raise exception using errcode='23514',message='Season is already closed';
  end if;

  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_season.team_id
      and r.user_id=v_actor
      and r.role='admin'
  ) and not (
    exists (
      select 1 from public.global_user_roles gur
      where gur.user_id=v_actor and gur.role='super_admin'
    )
    and public.has_selected_team_context(v_season.team_id)
  ) then
    raise exception using errcode='42501',
      message='Team admin or selected-context super admin permission required';
  end if;

  select display_name into v_actor_name
  from public.profiles where id=v_actor;

  with expired as (
    update public.training_suspensions s
    set status='expired',
        expired_at=v_now
    where s.team_id=v_season.team_id
      and s.season_id=v_season.id
      and s.status='open'
    returning s.id,s.player_id,s.player_name_snapshot,s.suspension_type,
              s.intended_matchday_id,s.intended_matchday_date_snapshot,
              s.intended_matchday_opponent_snapshot
  ), audited as (
    insert into public.training_suspension_audit(
      suspension_id,action,old_values,new_values,reason,changed_by,changed_at
    )
    select e.id,'expired',
      jsonb_build_object(
        'status','open',
        'intended_matchday_id',e.intended_matchday_id,
        'intended_matchday_date_snapshot',e.intended_matchday_date_snapshot,
        'intended_matchday_opponent_snapshot',e.intended_matchday_opponent_snapshot
      ),
      jsonb_build_object(
        'status','expired',
        'expired_at',v_now,
        'season_id',v_season.id,
        'season_name',v_season.name,
        'player_id',e.player_id,
        'player_name',e.player_name_snapshot,
        'suspension_type',e.suspension_type,
        'closed_by',v_actor,
        'closed_by_snapshot',v_actor_name
      ),
      btrim(p_reason),v_actor,v_now
    from expired e
    returning suspension_id
  )
  select count(*) into v_expired_count from audited;

  update public.seasons
  set is_active=false,
      updated_at=v_now
  where id=v_season.id;

  insert into public.team_season_closure_audit(
    team_id,season_id,closed_by,closed_at,reason,
    expired_suspensions_count,season_name_snapshot
  ) values (
    v_season.team_id,v_season.id,v_actor,v_now,btrim(p_reason),
    v_expired_count,v_season.name
  )
  returning id into v_audit_id;

  return v_audit_id;
end;
$function$;

revoke all on function public.close_team_season(uuid,text)
from public, anon, authenticated, service_role;
grant execute on function public.close_team_season(uuid,text)
to authenticated;

commit;
