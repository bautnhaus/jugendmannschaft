-- KADAssist / IMG-SEC-02
-- KADAssist IMG-SEC-02 / Profilbild-Härtung / DEV
-- Version 1.0.0
-- Erstellt nach ausdrücklicher Nutzerfreigabe zur Erstellung der Migrationsdatei.
-- Diese Migration wurde NICHT ausgeführt. Supabase DEV/PROD bleiben unverändert.
-- Voraussetzung: IMG-SEC-01 Migrationen 20261118180946 und 20261118181010.

begin;

do $preflight$
begin
  if to_regnamespace('private') is null then
    raise exception 'Preflight fehlgeschlagen: Schema private fehlt.';
  end if;
  if to_regclass('public.profiles') is null
     or to_regclass('public.club_members') is null
     or to_regclass('public.team_member_roles') is null
     or to_regclass('storage.objects') is null then
    raise exception 'Preflight fehlgeschlagen: erforderliche Tabellen fehlen.';
  end if;
  if to_regprocedure('public.can_manage_club_context(uuid)') is null
     or to_regprocedure('public.is_team_admin(uuid)') is null
     or to_regprocedure('public.admin_update_member_profile(uuid,uuid,text,text)') is null
     or to_regprocedure('public.admin_update_club_member_profile(uuid,uuid,text,text)') is null then
    raise exception 'Preflight fehlgeschlagen: erwartete Berechtigungsfunktionen oder Profil-RPCs fehlen.';
  end if;
  if not has_schema_privilege('authenticated','private','USAGE') then
    raise exception 'Preflight fehlgeschlagen: authenticated besitzt kein USAGE auf private.';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='profile_avatars_select_authorized' and cmd='SELECT'
  ) then
    raise exception 'Preflight fehlgeschlagen: erwartete Profilbild-SELECT-Policy fehlt.';
  end if;
end;
$preflight$;

-- 1) Einheitliche Pfadvalidierung.
-- Erwartetes Format: <user-uuid>/avatar-<13-stellige Date.now()-Millisekunden>.(jpg|png|webp)
create or replace function private.is_valid_profile_avatar_path(
  p_user_id uuid,
  p_avatar_path text
)
returns boolean
language sql
immutable
security invoker
set search_path = pg_catalog
as $function$
  select p_user_id is not null
     and p_avatar_path is not null
     and p_avatar_path ~*
       ('^' || p_user_id::text || '/avatar-[0-9]{13}[.](jpg|png|webp)$');
$function$;

revoke all on function private.is_valid_profile_avatar_path(uuid, text) from public, anon;
grant execute on function private.is_valid_profile_avatar_path(uuid, text) to authenticated, service_role;

-- 2) Zentrale Autorisierung für die Verwaltung fremder Profilbilder.
-- Vereinsadmins: nur im ausgewählten Vereinskontext.
-- Mannschaftsadmins: nur für Mitglieder derselben Mannschaft.
-- Superadmins erben diese Prüfungen und benötigen den passenden ausgewählten Kontext.
create or replace function private.can_manage_profile_avatar(
  p_target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, auth
as $function$
  select auth.uid() is not null
     and p_target_user_id is not null
     and (
       p_target_user_id = auth.uid()
       or exists (
         select 1
         from public.club_members target
         where target.user_id = p_target_user_id
           and public.can_manage_club_context(target.club_id)
       )
       or exists (
         select 1
         from public.team_member_roles target
         where target.user_id = p_target_user_id
           and public.is_team_admin(target.team_id)
       )
     );
$function$;

revoke all on function private.can_manage_profile_avatar(uuid) from public, anon;
grant execute on function private.can_manage_profile_avatar(uuid) to authenticated, service_role;

-- 3) Schutz für jeden Schreibweg auf profiles.avatar_url.
-- Unveränderte Legacy-Werte werden bei reinen Namensänderungen nicht neu validiert.
create or replace function private.enforce_profile_avatar_path()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
begin
  if tg_op = 'UPDATE'
     and new.avatar_url is not distinct from old.avatar_url then
    return new;
  end if;

  if new.avatar_url is not null
     and not private.is_valid_profile_avatar_path(new.id, new.avatar_url) then
    raise exception 'Profilbild-Pfad ist ungültig oder gehört nicht zu diesem Benutzer'
      using errcode = '22023';
  end if;

  return new;
end;
$function$;

revoke all on function private.enforce_profile_avatar_path() from public, anon, authenticated, service_role;

drop trigger if exists profiles_validate_avatar_path on public.profiles;
create trigger profiles_validate_avatar_path
before insert or update on public.profiles
for each row execute function private.enforce_profile_avatar_path();

-- 4) Admin-RPCs: zusätzliche frühe Validierung.
-- Die vorhandenen Rollen-/Kontextprüfungen bleiben erhalten.
create or replace function public.admin_update_member_profile(
  p_team_id uuid,
  p_user_id uuid,
  p_display_name text,
  p_avatar_url text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth, private
as $function$
declare
  v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not (
    public.is_team_admin(auth.uid(), p_team_id)
    or (public.is_super_admin() and public.has_selected_team_context(p_team_id))
  ) then
    raise exception 'Nicht berechtigt' using errcode = '42501';
  end if;

  if p_user_id is null or not exists (
    select 1 from public.team_member_roles r
    where r.team_id = p_team_id and r.user_id = p_user_id
  ) then
    raise exception 'Mitglied gehört nicht zur ausgewählten Mannschaft' using errcode = '22023';
  end if;

  if v_name = '' then
    raise exception 'Name darf nicht leer sein' using errcode = '22023';
  end if;

  if p_avatar_url is not null
     and not private.is_valid_profile_avatar_path(p_user_id, p_avatar_url) then
    raise exception 'Profilbild-Pfad ist ungültig oder gehört nicht zu diesem Benutzer'
      using errcode = '22023';
  end if;

  insert into public.profiles(id, display_name, avatar_url)
  values (p_user_id, v_name, p_avatar_url)
  on conflict (id) do update
    set display_name = excluded.display_name,
        avatar_url = excluded.avatar_url;
end;
$function$;

create or replace function public.admin_update_club_member_profile(
  p_club_id uuid,
  p_user_id uuid,
  p_display_name text,
  p_avatar_url text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth, private
as $function$
declare
  v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not public.can_manage_club_context(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext'
      using errcode = '42501';
  end if;

  if p_user_id is null or not exists (
    select 1 from public.club_members cm
    where cm.club_id = p_club_id and cm.user_id = p_user_id
  ) then
    raise exception 'Konto gehört nicht zum ausgewählten Verein' using errcode = '42501';
  end if;

  if v_name = '' then
    raise exception 'Name darf nicht leer sein' using errcode = '22023';
  end if;

  if p_avatar_url is not null
     and not private.is_valid_profile_avatar_path(p_user_id, p_avatar_url) then
    raise exception 'Profilbild-Pfad ist ungültig oder gehört nicht zu diesem Benutzer'
      using errcode = '22023';
  end if;

  insert into public.profiles(id, display_name, avatar_url)
  values (p_user_id, v_name, p_avatar_url)
  on conflict (id) do update
    set display_name = excluded.display_name,
        avatar_url = excluded.avatar_url;
end;
$function$;

-- Die bestehenden EXECUTE-Rechte der beiden RPCs bleiben unverändert.
-- Die Trigger-Prüfung deckt zusätzlich direkte Self-Service-Updates ab.

-- 5) Storage-Policies für Profilbilder.
-- SELECT-Policy bleibt unverändert: private.can_view_profile_avatar(...).
-- INSERT/UPDATE/DELETE verwenden dieselbe zentrale Verwaltungsberechtigung.
-- Bei UPDATE wird der bisherige Objektpfad über USING autorisiert; WITH CHECK
-- erzwingt für den neuen Pfad das aktuelle Format. DELETE lässt alte, berechtigte
-- Legacy-Objekte löschbar, damit ein späterer kontrollierter Cleanup möglich bleibt.

drop policy if exists profile_avatars_insert_self_or_admin on storage.objects;
create policy profile_avatars_insert_self_or_admin
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-avatars'
  and case
    when split_part(name, '/', 1) ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then private.can_manage_profile_avatar(split_part(name, '/', 1)::uuid)
      and private.is_valid_profile_avatar_path(split_part(name, '/', 1)::uuid, name)
    else false
  end
);

drop policy if exists profile_avatars_update_self_or_admin on storage.objects;
create policy profile_avatars_update_self_or_admin
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-avatars'
  and case
    when split_part(name, '/', 1) ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then private.can_manage_profile_avatar(split_part(name, '/', 1)::uuid)
    else false
  end
)
with check (
  bucket_id = 'profile-avatars'
  and case
    when split_part(name, '/', 1) ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then private.can_manage_profile_avatar(split_part(name, '/', 1)::uuid)
      and private.is_valid_profile_avatar_path(split_part(name, '/', 1)::uuid, name)
    else false
  end
);

drop policy if exists profile_avatars_delete_self_or_admin on storage.objects;
create policy profile_avatars_delete_self_or_admin
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'profile-avatars'
  and case
    when split_part(name, '/', 1) ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then private.can_manage_profile_avatar(split_part(name, '/', 1)::uuid)
    else false
  end
);

-- 6) Nach Ausführung zwingend:
-- - SELECT-Prüfung von Funktionsdefinitionen, Triggern und Policy-Ausdrücken.
-- - Prüfung der EXECUTE-/USAGE-Rechte; keine PUBLIC-/anon-EXECUTE-Rechte auf neue Helper.
-- - Positiv-/Negativtests aus dem IMG-SEC-02-Plan.
-- - Supabase Security Advisors.
-- - Erst nach erfolgreichem DEV-Test separate PROD-Kompatibilitätsprüfung.
-- Kein Bucket-Cutover in diesem Entwurf.

commit;
