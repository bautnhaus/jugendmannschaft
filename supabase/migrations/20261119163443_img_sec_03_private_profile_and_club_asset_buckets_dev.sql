-- KADAssist IMG-SEC-03 / Private Buckets / DEV
-- DEV-Ausführung am 19.11.2026 erfolgreich; Ledger-Version 20261119163443.
-- PROD-Fassung separat vorbereitet; keine PROD-Ausführung.
-- Zweck: profile-avatars und club-assets von public auf private umstellen.
-- Keine Dateien, Profile, Pfade, Policies oder sonstigen Daten verändern.

begin;

do $preflight$
declare
  v_profile_public boolean;
  v_club_public boolean;
begin
  select public into v_profile_public
  from storage.buckets where id='profile-avatars';
  if not found then
    raise exception 'IMG-SEC-03 Preflight: Bucket profile-avatars fehlt.';
  end if;

  select public into v_club_public
  from storage.buckets where id='club-assets';
  if not found then
    raise exception 'IMG-SEC-03 Preflight: Bucket club-assets fehlt.';
  end if;

  if v_profile_public is distinct from true then
    raise exception 'IMG-SEC-03 Preflight: profile-avatars ist nicht mehr public=true; Zustand prüfen, Abbruch.';
  end if;
  if v_club_public is distinct from true then
    raise exception 'IMG-SEC-03 Preflight: club-assets ist nicht mehr public=true; Zustand prüfen, Abbruch.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='profile_avatars_select_authorized' and cmd='SELECT'
  ) then
    raise exception 'IMG-SEC-03 Preflight: Profilbild-SELECT-Policy fehlt.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='club_assets_select_scoped' and cmd='SELECT'
  ) then
    raise exception 'IMG-SEC-03 Preflight: Vereinsasset-SELECT-Policy fehlt.';
  end if;

  if exists (
    select 1 from storage.objects
    where bucket_id='club-assets'
      and split_part(name,'/',1) !~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  ) then
    raise exception 'IMG-SEC-03 Preflight: mindestens ein Vereinsasset hat keinen erwarteten Vereins-ID-Pfad.';
  end if;

  if exists (
    select 1 from storage.objects
    where bucket_id='profile-avatars'
      and (
        split_part(name,'/',1) !~*
          '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        or not private.is_valid_profile_avatar_path(
          split_part(name,'/',1)::uuid, name
        )
      )
  ) then
    raise exception 'IMG-SEC-03 Preflight: mindestens ein Profilbildobjekt hat einen ungültigen Pfad.';
  end if;
end;
$preflight$;

-- Ausschließlich die Bucket-Sichtbarkeit ändern.
-- Vorhandene SELECT-/INSERT-/UPDATE-/DELETE-Policies bleiben unverändert.
update storage.buckets
set public=false
where id in ('profile-avatars','club-assets');

-- Guard: beide Buckets müssen nach dem Update privat sein.
do $postflight$
begin
  if exists (
    select 1 from storage.buckets
    where id in ('profile-avatars','club-assets') and public is distinct from false
  ) then
    raise exception 'IMG-SEC-03 Postflight fehlgeschlagen: mindestens ein Bucket ist weiterhin öffentlich.';
  end if;
end;
$postflight$;

commit;
