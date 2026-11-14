\set ON_ERROR_STOP on
create role anon nologin;
create role authenticated nologin;
create role service_role nologin;

create schema auth;
create table auth.users (id uuid primary key);
create or replace function auth.uid()
returns uuid language sql stable
as $$ select null::uuid $$;

create table public.players (id uuid primary key);
create or replace function public.is_team_member(uuid)
returns boolean language sql stable
as $$ select false $$;
create or replace function public.has_selected_team_context(uuid)
returns boolean language sql stable
as $$ select false $$;
