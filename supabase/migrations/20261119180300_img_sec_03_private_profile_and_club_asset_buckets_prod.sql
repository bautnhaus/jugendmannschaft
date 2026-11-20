-- KADAssist IMG-SEC-03 / Private Buckets / PROD
-- PROD release copy; prepared, NOT executed.
-- Only execute in Supabase PROD after separate explicit PROD approval.
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
    select 1 from storage.buckets
    where id='player-photos' and public=false
  ) then
    raise exception 'IMG-SEC-03 Preflight: player-photos fehlt oder ist nicht privat.';
  end if;
  if to_regclass('public.players') is null
     or not exists (
       select 1 from information_schema.columns
       where table_schema='public' and table_name='players' and column_name='photo_path'
     ) then
    raise exception 'IMG-SEC-03 Preflight: players.photo_path fehlt.';
  end if;

  if to_regprocedure('private.can_manage_player_photo(uuid,uuid)') is null
     or to_regprocedure('private.can_view_club_asset(uuid)') is null
     or to_regprocedure('private.can_view_profile_avatar(uuid)') is null
     or to_regprocedure('private.can_manage_profile_avatar(uuid)') is null
     or to_regprocedure('private.is_valid_profile_avatar_path(uuid,text)') is null then
    raise exception 'IMG-SEC-03 Preflight: mindestens ein erforderlicher privater IMG-SEC-Helper fehlt.';
  end if;
  if not has_schema_privilege('authenticated','private','USAGE')
     or has_schema_privilege('anon','private','USAGE') then
    raise exception 'IMG-SEC-03 Preflight: private-Schema-Rechte sind unerwartet.';
  end if;
  if not has_function_privilege('authenticated','private.can_manage_player_photo(uuid,uuid)','EXECUTE')
     or not has_function_privilege('authenticated','private.can_view_club_asset(uuid)','EXECUTE')
     or not has_function_privilege('authenticated','private.can_view_profile_avatar(uuid)','EXECUTE')
     or not has_function_privilege('authenticated','private.can_manage_profile_avatar(uuid)','EXECUTE')
     or not has_function_privilege('authenticated','private.is_valid_profile_avatar_path(uuid,text)','EXECUTE')
     or has_function_privilege('anon','private.can_manage_player_photo(uuid,uuid)','EXECUTE')
     or has_function_privilege('anon','private.can_view_club_asset(uuid)','EXECUTE')
     or has_function_privilege('anon','private.can_view_profile_avatar(uuid)','EXECUTE')
     or has_function_privilege('anon','private.can_manage_profile_avatar(uuid)','EXECUTE')
     or has_function_privilege('anon','private.is_valid_profile_avatar_path(uuid,text)','EXECUTE') then
    raise exception 'IMG-SEC-03 Preflight: private Helper EXECUTE-Rechte sind unerwartet.';
  end if;

  -- Alle benötigten Policies müssen vor dem privaten Bucket-Cutover vorhanden sein.
  if (
    select count(*) from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname in (
        'profile_avatars_select_authorized',
        'profile_avatars_insert_self_or_admin',
        'profile_avatars_update_self_or_admin',
        'profile_avatars_delete_self_or_admin',
        'club_assets_select_scoped',
        'club_assets_insert_scoped',
        'club_assets_update_scoped',
        'club_assets_delete_scoped',
        'player_photos_select_team',
        'player_photos_insert_team',
        'player_photos_update_team',
        'player_photos_delete_team'
      )
  ) <> 12 then
    raise exception 'IMG-SEC-03 Preflight: mindestens eine erforderliche Storage-Policy fehlt.';
  end if;

  if (
    select count(*) from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname in ('club_assets_insert_scoped','club_assets_update_scoped','club_assets_delete_scoped')
      and (coalesce(qual,'') || coalesce(with_check,'')) like '%is_club_admin%'
  ) <> 3 then
    raise exception 'IMG-SEC-03 Preflight: Vereinsasset-Schreibpolicies verwenden nicht vollständig is_club_admin.';
  end if;

  if position('is_club_admin' in pg_get_functiondef('public.admin_update_club_crest(uuid,text)'::regprocedure)) = 0 then
    raise exception 'IMG-SEC-03 Preflight: Crest-RPC erzwingt den ausgewählten Vereinskontext nicht.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='profile_avatars_select_authorized'
      and cmd='SELECT'
      and qual like '%private.can_view_profile_avatar%'
  ) then
    raise exception 'IMG-SEC-03 Preflight: Profilbild-SELECT-Policy fehlt oder verwendet nicht den privaten Helper.';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='club_assets_select_scoped'
      and cmd='SELECT'
      and qual like '%private.can_view_club_asset%'
  ) then
    raise exception 'IMG-SEC-03 Preflight: Vereinsasset-SELECT-Policy fehlt oder verwendet nicht den privaten Helper.';
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
    where id in ('player-photos','profile-avatars','club-assets') and public is distinct from false
  ) then
    raise exception 'IMG-SEC-03 Postflight fehlgeschlagen: mindestens ein Bild-Bucket ist weiterhin öffentlich.';
  end if;
end;
$postflight$;

commit;
