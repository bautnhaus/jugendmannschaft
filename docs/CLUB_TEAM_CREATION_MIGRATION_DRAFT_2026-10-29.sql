-- CLUB / TEAM CREATION – DRAFT ONLY
-- Target: Supabase DEV project pzazqvvoruqnqhcorbwx
-- Status: NOT APPROVED FOR EXECUTION; this is a review draft, not a migration-history file.
-- PROD: must not be changed.
--
-- Related design: docs/CLUB_TEAM_CREATION_PLAN_2026-10-29.md
-- Before execution:
--   1. Review this SQL against the live DEV schema and current function dependencies.
--   2. Obtain explicit user approval.
--   3. Execute only in DEV.
--   4. Record the applied migration version and postflight results in the DB changelog.

begin;

-- 1. Club/team master data fields.
alter table public.clubs
  add column if not exists short_name text,
  add column if not exists crest_path text,
  add column if not exists home_venue_name text,
  add column if not exists home_venue_street text,
  add column if not exists home_venue_postal_code text,
  add column if not exists home_venue_city text,
  add column if not exists home_venue_country text,
  add column if not exists training_location_differs boolean not null default false,
  add column if not exists training_venue_name text,
  add column if not exists training_venue_street text,
  add column if not exists training_venue_postal_code text,
  add column if not exists training_venue_city text,
  add column if not exists training_venue_country text;

alter table public.teams
  add column if not exists birth_cohorts text,
  add column if not exists abbreviation text;

-- A separate training address must be complete when the checkbox is enabled.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.clubs'::regclass
      and conname = 'clubs_training_venue_complete_when_different'
  ) then
    alter table public.clubs
      add constraint clubs_training_venue_complete_when_different
      check (
        not training_location_differs
        or (
          nullif(btrim(training_venue_name), '') is not null
          and nullif(btrim(training_venue_street), '') is not null
          and nullif(btrim(training_venue_postal_code), '') is not null
          and nullif(btrim(training_venue_city), '') is not null
          and nullif(btrim(training_venue_country), '') is not null
        )
      );
  end if;
end
$$;

-- 2. Server-side selected club context. No direct client table access.
create table if not exists public.user_club_context (
  user_id uuid primary key references auth.users(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  selected_at timestamptz not null default now()
);

alter table public.user_club_context enable row level security;
revoke all on table public.user_club_context from anon, authenticated, public;

-- True only for an actual club admin of this club, or a Super Admin who has
-- explicitly selected this club in user_club_context.
create or replace function public.can_manage_club_context(p_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $function$
  select auth.uid() is not null and (
    (
      exists (
        select 1 from public.global_user_roles gur
        where gur.user_id = auth.uid() and gur.role = 'super_admin'
      )
      and exists (
        select 1 from public.user_club_context ctx
        where ctx.user_id = auth.uid() and ctx.club_id = p_club_id
      )
    )
    or exists (
      select 1
      from public.club_members cm
      join public.club_member_roles cmr on cmr.user_id = cm.user_id
      where cm.user_id = auth.uid()
        and cm.club_id = p_club_id
        and cmr.role = 'club_admin'
    )
  );
$function$;

create or replace function public.select_club_context(p_club_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_club public.clubs%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Anmeldung erforderlich' using errcode = '42501';
  end if;

  select * into v_club from public.clubs where id = p_club_id;
  if not found then
    raise exception 'Verein nicht gefunden' using errcode = '22023';
  end if;

  if not (
    public.is_super_admin()
    or exists (
      select 1
      from public.club_members cm
      join public.club_member_roles cmr on cmr.user_id = cm.user_id
      where cm.user_id = auth.uid()
        and cm.club_id = p_club_id
        and cmr.role = 'club_admin'
    )
  ) then
    raise exception 'Keine Berechtigung für diesen Verein' using errcode = '42501';
  end if;

  insert into public.user_club_context(user_id, club_id, selected_at)
  values (auth.uid(), p_club_id, now())
  on conflict (user_id) do update
    set club_id = excluded.club_id, selected_at = excluded.selected_at;

  return jsonb_build_object('club_id', v_club.id, 'club_name', v_club.name);
end;
$function$;

create or replace function public.get_selected_club_context()
returns table(club_id uuid, club_name text)
language sql
stable
security definer
set search_path = pg_catalog, public
as $function$
  select c.id, c.name
  from public.user_club_context ctx
  join public.clubs c on c.id = ctx.club_id
  where ctx.user_id = auth.uid()
    and public.can_manage_club_context(c.id)
  limit 1;
$function$;

create or replace function public.clear_club_context()
returns void
language sql
security definer
set search_path = pg_catalog, public
as $function$
  delete from public.user_club_context where user_id = auth.uid();
$function$;

revoke all on function public.can_manage_club_context(uuid) from public, anon;
revoke all on function public.select_club_context(uuid) from public, anon;
revoke all on function public.get_selected_club_context() from public, anon;
revoke all on function public.clear_club_context() from public, anon;
grant execute on function public.can_manage_club_context(uuid) to authenticated;
grant execute on function public.select_club_context(uuid) to authenticated;
grant execute on function public.get_selected_club_context() to authenticated;
grant execute on function public.clear_club_context() to authenticated;

-- 3. Create a club. Only Super Admins may create clubs. Creation does not add
-- the Super Admin as a club member; it selects the new club context instead.
create or replace function public.admin_create_club(
  p_name text,
  p_short_name text default null,
  p_home_venue_name text default null,
  p_home_venue_street text default null,
  p_home_venue_postal_code text default null,
  p_home_venue_city text default null,
  p_home_venue_country text default null,
  p_training_location_differs boolean default false,
  p_training_venue_name text default null,
  p_training_venue_street text default null,
  p_training_venue_postal_code text default null,
  p_training_venue_city text default null,
  p_training_venue_country text default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_club_id uuid;
  v_training_differs boolean := coalesce(p_training_location_differs, false);
begin
  if auth.uid() is null or not public.is_super_admin() then
    raise exception 'Nur Super Admins dürfen neue Vereine anlegen' using errcode = '42501';
  end if;
  if nullif(btrim(p_name), '') is null then
    raise exception 'Vereinsname darf nicht leer sein' using errcode = '22023';
  end if;
  if v_training_differs and (
    nullif(btrim(p_training_venue_name), '') is null
    or nullif(btrim(p_training_venue_street), '') is null
    or nullif(btrim(p_training_venue_postal_code), '') is null
    or nullif(btrim(p_training_venue_city), '') is null
    or nullif(btrim(p_training_venue_country), '') is null
  ) then
    raise exception 'Bitte Name und vollständige Adresse des abweichenden Trainingsorts angeben' using errcode = '22023';
  end if;

  insert into public.clubs (
    name, short_name, home_venue_name, home_venue_street,
    home_venue_postal_code, home_venue_city, home_venue_country,
    training_location_differs, training_venue_name, training_venue_street,
    training_venue_postal_code, training_venue_city, training_venue_country
  ) values (
    btrim(p_name), nullif(btrim(p_short_name), ''),
    nullif(btrim(p_home_venue_name), ''), nullif(btrim(p_home_venue_street), ''),
    nullif(btrim(p_home_venue_postal_code), ''), nullif(btrim(p_home_venue_city), ''),
    nullif(btrim(p_home_venue_country), ''),
    v_training_differs,
    case when v_training_differs then nullif(btrim(p_training_venue_name), '') else null end,
    case when v_training_differs then nullif(btrim(p_training_venue_street), '') else null end,
    case when v_training_differs then nullif(btrim(p_training_venue_postal_code), '') else null end,
    case when v_training_differs then nullif(btrim(p_training_venue_city), '') else null end,
    case when v_training_differs then nullif(btrim(p_training_venue_country), '') else null end
  ) returning id into v_club_id;

  insert into public.user_club_context(user_id, club_id, selected_at)
  values (auth.uid(), v_club_id, now())
  on conflict (user_id) do update
    set club_id = excluded.club_id, selected_at = excluded.selected_at;

  return v_club_id;
end;
$function$;

revoke all on function public.admin_create_club(text,text,text,text,text,text,text,boolean,text,text,text,text,text) from public, anon;
grant execute on function public.admin_create_club(text,text,text,text,text,text,text,boolean,text,text,text,text,text) to authenticated;

-- Upload the crest first to club-assets/<club-id>/crest.<extension>, then set
-- the database path through this RPC. This also verifies that the object exists.
create or replace function public.admin_update_club_crest(p_club_id uuid, p_crest_path text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, storage
as $function$
begin
  if auth.uid() is null or not public.can_manage_club_context(p_club_id) then
    raise exception 'Nicht berechtigt, das Vereinswappen zu ändern' using errcode = '42501';
  end if;

  if p_crest_path is not null then
    if split_part(p_crest_path, '/', 1) <> p_club_id::text then
      raise exception 'Wappenpfad muss im Ordner des ausgewählten Vereins liegen' using errcode = '22023';
    end if;
    if not exists (
      select 1 from storage.objects
      where bucket_id = 'club-assets' and name = p_crest_path
    ) then
      raise exception 'Die Wappendatei wurde im Storage nicht gefunden' using errcode = '22023';
    end if;
  end if;

  update public.clubs
  set crest_path = p_crest_path, updated_at = now()
  where id = p_club_id;
end;
$function$;

revoke all on function public.admin_update_club_crest(uuid,text) from public, anon;
grant execute on function public.admin_update_club_crest(uuid,text) to authenticated;

-- 4. Storage for public club crests. The files are public branding assets;
-- uploads/updates/deletes remain scoped to a selected club or that club's admin.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('club-assets', 'club-assets', true, 2097152, array['image/png','image/jpeg','image/webp'])
on conflict (id) do nothing;

drop policy if exists club_assets_insert_scoped on storage.objects;
create policy club_assets_insert_scoped on storage.objects
for insert to authenticated
with check (
  bucket_id = 'club-assets'
  and public.can_manage_club_context(
    case
      when split_part(name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then split_part(name, '/', 1)::uuid
      else null
    end
  )
);

drop policy if exists club_assets_update_scoped on storage.objects;
create policy club_assets_update_scoped on storage.objects
for update to authenticated
using (
  bucket_id = 'club-assets'
  and public.can_manage_club_context(
    case
      when split_part(name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then split_part(name, '/', 1)::uuid
      else null
    end
  )
)
with check (
  bucket_id = 'club-assets'
  and public.can_manage_club_context(
    case
      when split_part(name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then split_part(name, '/', 1)::uuid
      else null
    end
  )
);

drop policy if exists club_assets_delete_scoped on storage.objects;
create policy club_assets_delete_scoped on storage.objects
for delete to authenticated
using (
  bucket_id = 'club-assets'
  and public.can_manage_club_context(
    case
      when split_part(name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then split_part(name, '/', 1)::uuid
      else null
    end
  )
);

-- 5. Replace the old team-create signature so there is one unambiguous RPC.
-- Existing frontend does not call the old RPC; it is replaced with an extended
-- version. Super Admins must have selected this exact club; they remain neutral.
drop function if exists public.admin_create_team(uuid, text, integer);

create function public.admin_create_team(
  p_club_id uuid,
  p_name text,
  p_recommended_squad_size integer default 16,
  p_birth_cohorts text default null,
  p_abbreviation text default null,
  p_season_name text default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_team_id uuid;
  v_is_super_admin boolean := public.is_super_admin();
  v_is_club_admin boolean;
begin
  if auth.uid() is null then
    raise exception 'Anmeldung erforderlich' using errcode = '42501';
  end if;

  if v_is_super_admin then
    if not exists (
      select 1 from public.user_club_context ctx
      where ctx.user_id = auth.uid() and ctx.club_id = p_club_id
    ) then
      raise exception 'Bitte wählen Sie zuerst genau diesen Verein aus' using errcode = '42501';
    end if;
  else
    select exists (
      select 1
      from public.club_members cm
      join public.club_member_roles cmr on cmr.user_id = cm.user_id
      where cm.user_id = auth.uid()
        and cm.club_id = p_club_id
        and cmr.role = 'club_admin'
    ) into v_is_club_admin;
    if not v_is_club_admin then
      raise exception 'Keine Berechtigung für diesen Verein' using errcode = '42501';
    end if;
  end if;

  if nullif(btrim(p_name), '') is null then
    raise exception 'Mannschaftsname darf nicht leer sein' using errcode = '22023';
  end if;
  if p_recommended_squad_size is null or p_recommended_squad_size < 1 or p_recommended_squad_size > 100 then
    raise exception 'Kadergröße muss zwischen 1 und 100 liegen' using errcode = '22023';
  end if;
  if not exists (select 1 from public.clubs c where c.id = p_club_id) then
    raise exception 'Verein nicht gefunden' using errcode = '22023';
  end if;

  insert into public.teams(name, club_id, recommended_squad_size, birth_cohorts, abbreviation)
  values (
    btrim(p_name), p_club_id, p_recommended_squad_size,
    nullif(btrim(p_birth_cohorts), ''), nullif(btrim(p_abbreviation), '')
  )
  returning id into v_team_id;

  -- A Super Admin remains neutral; only a real club admin becomes team admin.
  if not v_is_super_admin then
    insert into public.team_members(team_id, user_id, role)
    values (v_team_id, auth.uid(), 'admin')
    on conflict (team_id, user_id) do nothing;

    insert into public.team_member_roles(team_id, user_id, role)
    values (v_team_id, auth.uid(), 'admin')
    on conflict (team_id, user_id, role) do nothing;
  end if;

  if nullif(btrim(p_season_name), '') is not null then
    insert into public.seasons(team_id, name, is_active)
    values (v_team_id, btrim(p_season_name), true);
  end if;

  return v_team_id;
end;
$function$;

revoke all on function public.admin_create_team(uuid,text,integer,text,text,text) from public, anon;
grant execute on function public.admin_create_team(uuid,text,integer,text,text,text) to authenticated;

commit;

-- Postflight (run read-only after the migration, not inside this transaction):
-- 1. Confirm clubs/teams columns and user_club_context exist; RLS is enabled.
-- 2. Confirm admin_create_club and admin_create_team have EXECUTE only for authenticated.
-- 3. Confirm no INSERT/UPDATE/DELETE policies allow direct writes to public.clubs.
-- 4. Confirm bucket club-assets is public, size limit 2 MiB, MIME allow-list PNG/JPEG/WebP.
-- 5. Confirm Storage INSERT/UPDATE/DELETE policies are scoped to can_manage_club_context.
-- 6. Test Super Admin can create a club, but gets no club_members/team_members/team_member_roles row.
-- 7. Test Super Admin cannot create a team until the matching club context is selected.
-- 8. Test club admin can create a team only in their own club and is added as team admin.
-- 9. Test season name creates one active public.seasons row for the new team.
