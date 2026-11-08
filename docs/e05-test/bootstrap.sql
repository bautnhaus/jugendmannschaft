-- Disposable PostgreSQL 17 test fixture. No Supabase project or user data is accessed.
\set ON_ERROR_STOP on

do $$ begin
  create role anon nologin;
exception when duplicate_object then null; end $$;
do $$ begin
  create role authenticated nologin;
exception when duplicate_object then null; end $$;
do $$ begin
  create role service_role nologin bypassrls;
exception when duplicate_object then null; end $$;

create schema auth;
create table auth.users(id uuid primary key);
create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create table public.clubs(id uuid primary key, name text not null);
create table public.teams(id uuid primary key, club_id uuid references public.clubs(id), name text not null);
create table public.seasons(id uuid primary key, team_id uuid not null, name text not null, is_active boolean not null default true);
create table public.trainings(id uuid primary key, team_id uuid not null, season_id uuid, training_date date not null, name text, status text not null);
create table public.players(id uuid primary key, team_id uuid not null, name text not null, active boolean not null default true);
create table public.matchdays(id uuid primary key, team_id uuid not null, match_date date not null, opponent text, game_type text, status text);
create table public.user_club_context(user_id uuid not null, club_id uuid not null);

create or replace function public.is_team_member(p_team_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $$ select current_setting('test.team_member_team', true) = p_team_id::text $$;
create or replace function public.has_selected_team_context(p_team_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $$ select current_setting('test.selected_team_id', true) = p_team_id::text $$;
create or replace function public.can_manage_club_context(p_club_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $$ select current_setting('test.can_manage_club', true) = 'true' $$;

grant usage on schema public, auth to authenticated, service_role;
grant execute on function auth.uid() to authenticated, service_role;
grant execute on function public.is_team_member(uuid), public.has_selected_team_context(uuid),
  public.can_manage_club_context(uuid) to authenticated, service_role;
