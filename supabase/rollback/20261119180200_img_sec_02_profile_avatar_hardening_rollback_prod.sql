-- KADAssist IMG-SEC-02 / Rollback / PROD
-- Nur ausführen, wenn IMG-SEC-02 Migration 20261119180200 erfolgreich installiert wurde
-- und eine ausdrückliche Rollback-Freigabe vorliegt.
-- Stellt die vor IMG-SEC-02 in PROD ausgelesenen RPC-Definitionen und
-- Storage-Schreibpolicies wieder her. Keine Profil-/Storage-Daten werden gelöscht.
-- Die SELECT-Policy bleibt unverändert.

begin;

do $preflight$
begin
  if to_regprocedure('public.is_club_admin(uuid)') is null
     or to_regprocedure('private.can_manage_profile_avatar(uuid)') is null
     or to_regprocedure('private.is_valid_profile_avatar_path(uuid,text)') is null
     or to_regprocedure('private.enforce_profile_avatar_path()') is null then
    raise exception 'Rollback abgebrochen: IMG-SEC-02 Helper fehlen; Migration möglicherweise nicht installiert.';
  end if;

  if not exists (
    select 1 from pg_trigger t
    join pg_class c on c.oid=t.tgrelid
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='profiles'
      and t.tgname='profiles_validate_avatar_path' and not t.tgisinternal
  ) then
    raise exception 'Rollback abgebrochen: IMG-SEC-02-Trigger fehlt.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='profile_avatars_insert_self_or_admin'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='profile_avatars_update_self_or_admin'
  ) or not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='profile_avatars_delete_self_or_admin'
  ) then
    raise exception 'Rollback abgebrochen: IMG-SEC-02-Profilbild-Schreibpolicies fehlen.';
  end if;

  -- Das alte Frontend erwartet vollständige öffentliche URLs. Neu angelegte
  -- IMG-SEC-Profilbildpfade sind relative Storage-Pfade und dürfen bei einer
  -- Rückkehr zum alten Daten-/Frontendstand nicht unbemerkt zurückbleiben.
  if exists (
    select 1 from public.profiles
    where avatar_url ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/avatar-[0-9]{13}[.](jpg|png|webp)

-- 1) Trigger entfernen.
drop trigger if exists profiles_validate_avatar_path on public.profiles;
drop function if exists private.enforce_profile_avatar_path();

-- 2) Profilbild-Admin-RPCs auf den vorherigen Stand zurücksetzen.
-- Die Vereinsadmin-Prüfung verwendet absichtlich public.is_club_admin statt
-- public.can_manage_club_context: So bleibt die verbindliche Regel erhalten,
-- dass Superadmins auch bei zusätzlicher club_admin-Rolle einen ausgewählten
-- Vereinskontext benötigen.
create or replace function public.admin_update_member_profile(
  p_team_id uuid,
  p_user_id uuid,
  p_display_name text,
  p_avatar_url text
)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
declare v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not (
    (public.is_super_admin() and public.has_selected_team_context(p_team_id))
    or (not public.is_super_admin() and public.is_team_admin(auth.uid(), p_team_id))
  ) then
    raise exception 'Nicht berechtigt' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (
    select 1 from public.team_member_roles r
    where r.team_id = p_team_id and r.user_id = p_user_id
  ) then
    raise exception 'Mitglied gehört nicht zur ausgewählten Mannschaft' using errcode = '22023';
  end if;
  if v_name = '' then raise exception 'Name darf nicht leer sein' using errcode = '22023'; end if;
  if p_avatar_url is not null and length(p_avatar_url) > 2048 then
    raise exception 'Profilbild-Adresse ist ungültig' using errcode = '22023';
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
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
declare v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not public.is_club_admin(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (
    select 1 from public.club_members cm where cm.club_id=p_club_id and cm.user_id=p_user_id
  ) then raise exception 'Konto gehört nicht zum ausgewählten Verein' using errcode = '42501'; end if;
  if v_name = '' then raise exception 'Name darf nicht leer sein' using errcode = '22023'; end if;
  if p_avatar_url is not null and length(p_avatar_url)>2048 then raise exception 'Profilbild-Adresse ist ungültig' using errcode = '22023'; end if;
  insert into public.profiles(id,display_name,avatar_url) values(p_user_id,v_name,p_avatar_url)
  on conflict(id) do update set display_name=excluded.display_name,avatar_url=excluded.avatar_url;
end;
$function$;

-- 3) Die ursprünglichen INSERT-/UPDATE-/DELETE-Policies wiederherstellen.
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
    else false
  end
)
with check (
  bucket_id = 'profile-avatars'
  and case
    when split_part(name, '/', 1) ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
    else false
  end
);

-- 4) Neue IMG-SEC-02 Helper entfernen.
drop function if exists private.can_manage_profile_avatar(uuid);
drop function if exists private.is_valid_profile_avatar_path(uuid,text);

-- 5) SELECT-Policy, Bucket-Einstellungen, profiles-Daten und Storage-Objekte bleiben unangetastet.
commit;

  ) then
    raise exception 'Rollback abgebrochen: profiles.avatar_url enthält neue IMG-SEC-02-Pfade. Zuerst Datenkompatibilität herstellen.';
  end if;

  if exists (
    select 1 from storage.objects
    where bucket_id='profile-avatars'
      and name ~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/avatar-[0-9]{13}[.](jpg|png|webp)

-- 1) Trigger entfernen.
drop trigger if exists profiles_validate_avatar_path on public.profiles;
drop function if exists private.enforce_profile_avatar_path();

-- 2) Profilbild-Admin-RPCs auf den vorherigen Stand zurücksetzen.
-- Die Vereinsadmin-Prüfung verwendet absichtlich public.is_club_admin statt
-- public.can_manage_club_context: So bleibt die verbindliche Regel erhalten,
-- dass Superadmins auch bei zusätzlicher club_admin-Rolle einen ausgewählten
-- Vereinskontext benötigen.
create or replace function public.admin_update_member_profile(
  p_team_id uuid,
  p_user_id uuid,
  p_display_name text,
  p_avatar_url text
)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
declare v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not (
    (public.is_super_admin() and public.has_selected_team_context(p_team_id))
    or (not public.is_super_admin() and public.is_team_admin(auth.uid(), p_team_id))
  ) then
    raise exception 'Nicht berechtigt' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (
    select 1 from public.team_member_roles r
    where r.team_id = p_team_id and r.user_id = p_user_id
  ) then
    raise exception 'Mitglied gehört nicht zur ausgewählten Mannschaft' using errcode = '22023';
  end if;
  if v_name = '' then raise exception 'Name darf nicht leer sein' using errcode = '22023'; end if;
  if p_avatar_url is not null and length(p_avatar_url) > 2048 then
    raise exception 'Profilbild-Adresse ist ungültig' using errcode = '22023';
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
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
declare v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not public.is_club_admin(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (
    select 1 from public.club_members cm where cm.club_id=p_club_id and cm.user_id=p_user_id
  ) then raise exception 'Konto gehört nicht zum ausgewählten Verein' using errcode = '42501'; end if;
  if v_name = '' then raise exception 'Name darf nicht leer sein' using errcode = '22023'; end if;
  if p_avatar_url is not null and length(p_avatar_url)>2048 then raise exception 'Profilbild-Adresse ist ungültig' using errcode = '22023'; end if;
  insert into public.profiles(id,display_name,avatar_url) values(p_user_id,v_name,p_avatar_url)
  on conflict(id) do update set display_name=excluded.display_name,avatar_url=excluded.avatar_url;
end;
$function$;

-- 3) Die ursprünglichen INSERT-/UPDATE-/DELETE-Policies wiederherstellen.
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
    else false
  end
)
with check (
  bucket_id = 'profile-avatars'
  and case
    when split_part(name, '/', 1) ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
    else false
  end
);

-- 4) Neue IMG-SEC-02 Helper entfernen.
drop function if exists private.can_manage_profile_avatar(uuid);
drop function if exists private.is_valid_profile_avatar_path(uuid,text);

-- 5) SELECT-Policy, Bucket-Einstellungen, profiles-Daten und Storage-Objekte bleiben unangetastet.
commit;

  ) then
    raise exception 'Rollback abgebrochen: profile-avatars enthält neue IMG-SEC-02-Objekte. Zuerst Datenkompatibilität herstellen.';
  end if;
end;
$preflight$;

-- 1) Trigger entfernen.
drop trigger if exists profiles_validate_avatar_path on public.profiles;
drop function if exists private.enforce_profile_avatar_path();

-- 2) Profilbild-Admin-RPCs auf den vorherigen Stand zurücksetzen.
-- Die Vereinsadmin-Prüfung verwendet absichtlich public.is_club_admin statt
-- public.can_manage_club_context: So bleibt die verbindliche Regel erhalten,
-- dass Superadmins auch bei zusätzlicher club_admin-Rolle einen ausgewählten
-- Vereinskontext benötigen.
create or replace function public.admin_update_member_profile(
  p_team_id uuid,
  p_user_id uuid,
  p_display_name text,
  p_avatar_url text
)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
declare v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not (
    (public.is_super_admin() and public.has_selected_team_context(p_team_id))
    or (not public.is_super_admin() and public.is_team_admin(auth.uid(), p_team_id))
  ) then
    raise exception 'Nicht berechtigt' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (
    select 1 from public.team_member_roles r
    where r.team_id = p_team_id and r.user_id = p_user_id
  ) then
    raise exception 'Mitglied gehört nicht zur ausgewählten Mannschaft' using errcode = '22023';
  end if;
  if v_name = '' then raise exception 'Name darf nicht leer sein' using errcode = '22023'; end if;
  if p_avatar_url is not null and length(p_avatar_url) > 2048 then
    raise exception 'Profilbild-Adresse ist ungültig' using errcode = '22023';
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
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
declare v_name text := trim(coalesce(p_display_name, ''));
begin
  if auth.uid() is null or not public.is_club_admin(p_club_id) then
    raise exception 'Nicht berechtigt oder kein ausgewählter Vereinskontext' using errcode = '42501';
  end if;
  if p_user_id is null or not exists (
    select 1 from public.club_members cm where cm.club_id=p_club_id and cm.user_id=p_user_id
  ) then raise exception 'Konto gehört nicht zum ausgewählten Verein' using errcode = '42501'; end if;
  if v_name = '' then raise exception 'Name darf nicht leer sein' using errcode = '22023'; end if;
  if p_avatar_url is not null and length(p_avatar_url)>2048 then raise exception 'Profilbild-Adresse ist ungültig' using errcode = '22023'; end if;
  insert into public.profiles(id,display_name,avatar_url) values(p_user_id,v_name,p_avatar_url)
  on conflict(id) do update set display_name=excluded.display_name,avatar_url=excluded.avatar_url;
end;
$function$;

-- 3) Die ursprünglichen INSERT-/UPDATE-/DELETE-Policies wiederherstellen.
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
    else false
  end
)
with check (
  bucket_id = 'profile-avatars'
  and case
    when split_part(name, '/', 1) ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
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
    then (
      split_part(name, '/', 1)::uuid = auth.uid()
      or exists (
        select 1 from public.club_members target
        where target.user_id = split_part(name, '/', 1)::uuid
          and public.is_club_admin(target.club_id)
      )
    )
    else false
  end
);

-- 4) Neue IMG-SEC-02 Helper entfernen.
drop function if exists private.can_manage_profile_avatar(uuid);
drop function if exists private.is_valid_profile_avatar_path(uuid,text);

-- 5) SELECT-Policy, Bucket-Einstellungen, profiles-Daten und Storage-Objekte bleiben unangetastet.
commit;
