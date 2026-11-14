\set ON_ERROR_STOP on
create schema if not exists auth;
do $$ begin
  if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role nologin; end if;
end $$;
create table auth.users(id uuid primary key);
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;

create table public.teams(id uuid primary key,name text);
create table public.seasons(id uuid primary key,team_id uuid not null references public.teams(id),name text not null,is_active boolean not null default true);
create table public.players(id uuid primary key,team_id uuid not null references public.teams(id),name text not null,active boolean not null default true);
create table public.profiles(id uuid primary key,display_name text);
create table public.team_member_roles(team_id uuid,user_id uuid,role text);
create table public.global_user_roles(user_id uuid,role text);
create table public.matchdays(
 id uuid primary key,team_id uuid not null references public.teams(id),
 season_id uuid references public.seasons(id),match_date date not null,
 opponent text,status text not null
);
create table public.matchday_players(matchday_id uuid not null references public.matchdays(id),player_id uuid not null references public.players(id),primary key(matchday_id,player_id));
create table public.trainings(id uuid primary key,team_id uuid,training_date date,name text,status text,season_id uuid);
create table public.attendance(training_id uuid,player_id uuid,present boolean);
create table public.training_behavior_events(id uuid primary key default gen_random_uuid());
create table public.training_suspensions(
 id uuid primary key default gen_random_uuid(),team_id uuid,season_id uuid,player_id uuid,
 player_name_snapshot text,source_event_id uuid,suspension_type text,status text,
 intended_matchday_id uuid,intended_matchday_date_snapshot date,intended_matchday_opponent_snapshot text,
 created_by uuid,created_at timestamptz default now(),served_at timestamptz,
 expired_at timestamptz,voided_by uuid,voided_at timestamptz,void_reason text
);
create table public.training_suspension_audit(id uuid primary key default gen_random_uuid(),suspension_id uuid,action text,old_values jsonb,new_values jsonb,reason text,changed_by uuid,changed_at timestamptz default now());
create or replace function public.is_team_member(p_team_id uuid) returns boolean
language sql stable as $$ select exists(select 1 from public.team_member_roles r where r.team_id=p_team_id and r.user_id=auth.uid()) $$;
create or replace function public.has_selected_team_context(p_team_id uuid) returns boolean
language sql stable as $$ select coalesce(current_setting('test.selected_team',true),'')=p_team_id::text $$;

-- Exact PROD Paket-2 anchor used by Paket 8's guarded source transformation.
create or replace function public.award_training_behavior_event(
 p_training_id uuid,p_player_id uuid,p_event_type text,p_reason text default null
) returns uuid language plpgsql security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_yellow_since timestamptz;
begin
  if p_event_type = 'yellow_card' then
    select coalesce(max(s.served_at), '-infinity'::timestamptz)
      into v_yellow_since
    from public.training_suspensions s
    where s.team_id = v_team_id
      and s.season_id = v_season_id
      and s.player_id = p_player_id
      and s.suspension_type = 'yellow'
      and s.status = 'served';
  end if;
  return gen_random_uuid();
end;
$function$;
grant usage on schema public to anon,authenticated,service_role;
