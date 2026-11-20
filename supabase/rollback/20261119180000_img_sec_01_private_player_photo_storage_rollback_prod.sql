-- KADAssist IMG-SEC-01 / guarded PROD rollback
-- Nur nach gesonderter ausdrücklicher Rollback-Freigabe ausführen.
-- Unterstützt beide Zwischenstände:
--   A) IMG-SEC-01a installiert, IMG-SEC-01b noch nicht installiert
--   B) IMG-SEC-01a und IMG-SEC-01b installiert
-- IMG-SEC-02 muss vorher vollständig zurückgerollt sein.
-- Keine Storage-Objekte oder fachlichen Datensätze werden gelöscht.

begin;

-- 1) Vorbedingungen prüfen, bevor irgendeine Änderung erfolgt.
do $preflight$
begin
  if to_regprocedure('public.is_club_admin(uuid)') is null then
    raise exception 'IMG-SEC-01 Rollback abgebrochen: public.is_club_admin(uuid) fehlt.';
  end if;

  if exists (
    select 1 from storage.buckets
    where id in ('profile-avatars','club-assets')
      and public is distinct from true
  ) then
    raise exception 'IMG-SEC-01 Rollback abgebrochen: IMG-SEC-03 ist noch aktiv. Zuerst IMG-SEC-03 zurückrollen.';
  end if;

  if exists (
    select 1 from public.players
    where photo_path is not null
  ) then
    raise exception 'IMG-SEC-01 Rollback abgebrochen: players.photo_path enthält noch Daten.';
  end if;

  if exists (
    select 1 from storage.objects
    where bucket_id = 'player-photos'
  ) then
    raise exception 'IMG-SEC-01 Rollback abgebrochen: player-photos enthält noch Objekte.';
  end if;

  -- IMG-SEC-02 verwendet ebenfalls das private-Schema. Immer in umgekehrter
  -- Reihenfolge zurückrollen, damit keine IMG-SEC-02-Abhängigkeiten verloren gehen.
  if to_regprocedure('private.can_manage_profile_avatar(uuid)') is not null
     or to_regprocedure('private.is_valid_profile_avatar_path(uuid,text)') is not null
     or to_regprocedure('private.enforce_profile_avatar_path()') is not null
     or exists (
       select 1
       from pg_trigger t
       join pg_class c on c.oid = t.tgrelid
       join pg_namespace n on n.oid = c.relnamespace
       where n.nspname = 'public'
         and c.relname = 'profiles'
         and t.tgname = 'profiles_validate_avatar_path'
         and not t.tgisinternal
     ) then
    raise exception 'IMG-SEC-01 Rollback abgebrochen: IMG-SEC-02 ist noch installiert. Zuerst IMG-SEC-02 zurückrollen.';
  end if;
end;
$preflight$;

-- 2) Policies entfernen, die auf IMG-SEC-01-Helper zeigen.
drop policy if exists player_photos_delete_team on storage.objects;
drop policy if exists player_photos_update_team on storage.objects;
drop policy if exists player_photos_insert_team on storage.objects;
drop policy if exists player_photos_select_team on storage.objects;
drop policy if exists profile_avatars_select_authorized on storage.objects;
drop policy if exists club_assets_select_scoped on storage.objects;
drop policy if exists club_assets_insert_scoped on storage.objects;
drop policy if exists club_assets_update_scoped on storage.objects;
drop policy if exists club_assets_delete_scoped on storage.objects;

-- 3) Ursprüngliche club-assets-Policies und Crest-RPC wiederherstellen.
-- Die Admin-Prüfung verwendet public.is_club_admin statt can_manage_club_context,
-- damit Superadmins auch bei zusätzlicher club_admin-Rolle den ausgewählten
-- Vereinskontext benötigen. Die IMG-SEC-01-Lesepolicy für profile-avatars war
-- vorher nicht vorhanden und wird deshalb entfernt.

create policy club_assets_select_scoped
on storage.objects for select to authenticated
using (
  bucket_id='club-assets'
  and case
    when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then public.is_club_admin(split_part(name,'/',1)::uuid)
    else false
  end
);

create policy club_assets_insert_scoped
on storage.objects for insert to authenticated
with check (
  bucket_id='club-assets'
  and case
    when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then public.is_club_admin(split_part(name,'/',1)::uuid)
    else false
  end
);

create policy club_assets_update_scoped
on storage.objects for update to authenticated
using (
  bucket_id='club-assets'
  and case
    when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then public.is_club_admin(split_part(name,'/',1)::uuid)
    else false
  end
)
with check (
  bucket_id='club-assets'
  and case
    when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then public.is_club_admin(split_part(name,'/',1)::uuid)
    else false
  end
);

create policy club_assets_delete_scoped
on storage.objects for delete to authenticated
using (
  bucket_id='club-assets'
  and case
    when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then public.is_club_admin(split_part(name,'/',1)::uuid)
    else false
  end
);

create or replace function public.admin_update_club_crest(
  p_club_id uuid,
  p_crest_path text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, storage
as $function$
begin
  if auth.uid() is null or not public.is_club_admin(p_club_id) then
    raise exception 'Nicht berechtigt, das Vereinswappen zu ändern'
      using errcode = '42501';
  end if;

  if p_crest_path is not null then
    if split_part(p_crest_path, '/', 1) <> p_club_id::text then
      raise exception 'Wappenpfad muss im Ordner des ausgewählten Vereins liegen'
        using errcode = '22023';
    end if;
    if not exists (
      select 1 from storage.objects
      where bucket_id = 'club-assets' and name = p_crest_path
    ) then
      raise exception 'Die Wappendatei wurde im Storage nicht gefunden'
        using errcode = '22023';
    end if;
  end if;

  update public.clubs
  set crest_path = p_crest_path, updated_at = now()
  where id = p_club_id;
end;
$function$;

-- 4) Helper-Funktionen entfernen.
-- Nach IMG-SEC-01a liegen sie in public; nach IMG-SEC-01b in private.
-- to_regprocedure + dynamisches DROP vermeidet Fehler, wenn das private-
-- Schema im Zwischenstand A noch nicht existiert.
do $drop_helpers$
begin
  if to_regprocedure('private.can_manage_player_photo(uuid,uuid)') is not null then
    execute 'drop function private.can_manage_player_photo(uuid,uuid)';
  end if;
  if to_regprocedure('private.can_view_club_asset(uuid)') is not null then
    execute 'drop function private.can_view_club_asset(uuid)';
  end if;
  if to_regprocedure('private.can_view_profile_avatar(uuid)') is not null then
    execute 'drop function private.can_view_profile_avatar(uuid)';
  end if;
end;
$drop_helpers$;

drop function if exists public.can_manage_player_photo(uuid,uuid);
drop function if exists public.can_view_club_asset(uuid);
drop function if exists public.can_view_profile_avatar(uuid);
drop function if exists public.can_view_player_photo(uuid);

-- 5) IMG-SEC-01-Struktur entfernen.
alter table public.players drop column if exists photo_path;

-- Bucket nur entfernen, wenn er leer ist. Die Vorprüfung hat dies bereits
-- abgesichert; die zusätzliche Bedingung schützt vor versehentlichem Löschen.
delete from storage.buckets
where id = 'player-photos'
  and not exists (
    select 1 from storage.objects where bucket_id = 'player-photos'
  );

-- Das Schema private wurde in PROD vor IMG-SEC-01 nicht verwendet.
-- Nach Entfernen der IMG-SEC-01/02-Helper wird es entfernt, sofern es leer ist.
-- Ohne CASCADE: unabhängige Objekte verhindern das Löschen und bleiben erhalten.
do $drop_private_schema$
begin
  if to_regnamespace('private') is not null then
    begin
      execute 'drop schema private';
    exception
      when dependent_objects_still_exist then
        raise notice 'Schema private bleibt bestehen, da es noch unabhängige Objekte enthält.';
    end;
  end if;
end;
$drop_private_schema$;



commit;
