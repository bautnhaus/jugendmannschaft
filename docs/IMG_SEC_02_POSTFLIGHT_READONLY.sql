-- IMG-SEC-02 Postflight – ausschließlich lesende Prüfung
-- Erst nach separat freigegebener und erfolgreicher DEV-Migration ausführen.

-- A. Migration ledger
select version, name
from supabase_migrations.schema_migrations
where version = '20261119120000';

-- B. Helper-Funktionen, Trigger-Funktion und RPC-Signaturen
select n.nspname as schema_name, p.proname,
       pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer, p.proconfig as settings,
       coalesce(array_to_string(p.proacl, ', '), 'DEFAULT') as acl
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where (n.nspname = 'private' and p.proname in
       ('is_valid_profile_avatar_path','can_manage_profile_avatar','enforce_profile_avatar_path'))
   or (n.nspname = 'public' and p.proname in
       ('admin_update_member_profile','admin_update_club_member_profile'))
order by n.nspname, p.proname;

-- C. Trigger
select t.tgname, pg_get_triggerdef(t.oid) as definition
from pg_trigger t
where t.tgrelid = 'public.profiles'::regclass
  and not t.tgisinternal
  and t.tgname = 'profiles_validate_avatar_path';

-- D. Profilbild-Storage-Policies
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and policyname in (
    'profile_avatars_select_authorized',
    'profile_avatars_insert_self_or_admin',
    'profile_avatars_update_self_or_admin',
    'profile_avatars_delete_self_or_admin'
  )
order by policyname;

-- E. Helper-EXECUTE-Rechte
select
  has_function_privilege('anon','private.is_valid_profile_avatar_path(uuid,text)','EXECUTE') as anon_can_validate_path,
  has_function_privilege('anon','private.can_manage_profile_avatar(uuid)','EXECUTE') as anon_can_manage_avatar,
  has_function_privilege('authenticated','private.is_valid_profile_avatar_path(uuid,text)','EXECUTE') as authenticated_can_validate_path,
  has_function_privilege('authenticated','private.can_manage_profile_avatar(uuid)','EXECUTE') as authenticated_can_manage_avatar;

-- F. Validator-Testvektoren (synthetische UUID; keine Datenänderung)
select
  private.is_valid_profile_avatar_path(
    '11111111-1111-4111-8111-111111111111',
    '11111111-1111-4111-8111-111111111111/avatar-1763571600000.jpg'
  ) as accepts_valid_jpg,
  private.is_valid_profile_avatar_path(
    '11111111-1111-4111-8111-111111111111',
    '22222222-2222-4222-8222-222222222222/avatar-1763571600000.jpg'
  ) as rejects_other_user_folder,
  private.is_valid_profile_avatar_path(
    '11111111-1111-4111-8111-111111111111',
    '11111111-1111-4111-8111-111111111111/avatar-1763571600000.svg'
  ) as rejects_svg,
  private.is_valid_profile_avatar_path(
    '11111111-1111-4111-8111-111111111111',
    '11111111-1111-4111-8111-111111111111/../avatar-1763571600000.jpg'
  ) as rejects_traversal;

-- G. Datenbestand und Bucket-Einstellungen
select count(*) as profile_rows,
       count(*) filter (where avatar_url is not null) as profiles_with_avatar
from public.profiles;

select id, public
from storage.buckets
where id in ('profile-avatars','club-assets');

select bucket_id, count(*) as object_count
from storage.objects
where bucket_id in ('profile-avatars','club-assets')
group by bucket_id
order by bucket_id;

-- Erwartung:
-- A: genau ein Ledger-Eintrag.
-- B: drei private Helper/Trigger-Funktionen und beide Admin-RPCs vorhanden.
-- C: genau ein Trigger.
-- D: vier Policies vorhanden; SELECT-Ausdruck entspricht unverändert dem Vorher-Stand.
-- E: anon_can_* = false; authenticated_can_* = true.
-- F: true, false, false, false.
-- G: vor/nach Werte vergleichen; Migration selbst verändert keine Profile/Storage-Objekte.
