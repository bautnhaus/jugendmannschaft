-- IMG-SEC PROD Postflight – ausschließlich lesende Prüfungen
-- Nur nach separater PROD-Freigabe ausführen. Alle Statements sind SELECT.

-- 0. Supabase migration ledger: all four named PROD migrations must be recorded.
select version,name,created_by
from supabase_migrations.schema_migrations
where name in (
  'img_sec_01_private_player_photo_storage_v1_0_0_prod',
  'img_sec_01_harden_private_policy_helpers_prod',
  'img_sec_02_profile_avatar_hardening_v1_0_0_prod',
  'img_sec_03_private_profile_and_club_asset_buckets_prod'
)
order by version;

-- 0b. AP02-Freigabegate: muss nach der separaten AP02-Korrektur 0 direkte
-- Vereins-/Mannschaftszuordnungen für Superadmins ergeben.
select
  (select count(*)
   from public.global_user_roles gur
   join public.club_members cm on cm.user_id=gur.user_id
   where gur.role='super_admin') as superadmins_with_club_membership,
  (select count(*)
   from public.global_user_roles gur
   join public.club_member_roles cmr on cmr.user_id=gur.user_id
   where gur.role='super_admin') as superadmins_with_club_roles,
  (select count(*)
   from public.global_user_roles gur
   join public.team_member_roles tmr on tmr.user_id=gur.user_id
   where gur.role='super_admin') as superadmins_with_team_roles;

-- 1. Bucket visibility and limits
select id,public,file_size_limit,allowed_mime_types
from storage.buckets
where id in ('player-photos','profile-avatars','club-assets')
order by id;

-- 2. Relevant storage policies
select policyname,cmd,roles,qual,with_check
from pg_policies
where schemaname='storage' and tablename='objects'
  and (policyname ilike 'player_photos_%'
    or policyname ilike 'profile_avatars_%'
    or policyname ilike 'club_assets_%')
order by policyname;

-- 3. Required helper functions and RPCs
select n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,p.proconfig as settings
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='private' and p.proname in (
  'can_manage_player_photo','can_view_club_asset','can_view_profile_avatar',
  'can_manage_profile_avatar','is_valid_profile_avatar_path','enforce_profile_avatar_path'
))
or (n.nspname='public' and p.proname in (
  'admin_update_member_profile','admin_update_club_member_profile','admin_update_club_crest'
))
order by n.nspname,p.proname;

-- 3b. Kontextschutz: Superadmins dürfen Vereins-/Teamzugriff nur im ausgewählten Kontext erhalten.
select n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) as arguments,
       pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='public' and p.proname in ('is_club_admin','is_team_admin','is_team_member','can_manage_club_context','admin_update_club_crest'))
   or (n.nspname='private' and p.proname in ('can_view_club_asset','can_view_profile_avatar','can_manage_profile_avatar'))
order by n.nspname,p.proname,arguments;

-- 3a. Schema and function privileges:
-- authenticated must use helpers; anon and service_role must not have helper EXECUTE.
-- private schema USAGE is intended for authenticated only.
select
  has_schema_privilege('authenticated','private','USAGE') as authenticated_private_usage,
  has_schema_privilege('anon','private','USAGE') as anon_private_usage,
  has_schema_privilege('service_role','private','USAGE') as service_role_private_usage,
  has_function_privilege('authenticated','private.can_manage_player_photo(uuid,uuid)','EXECUTE') as authenticated_manage_player_photo,
  has_function_privilege('anon','private.can_manage_player_photo(uuid,uuid)','EXECUTE') as anon_manage_player_photo,
  has_function_privilege('authenticated','private.can_view_club_asset(uuid)','EXECUTE') as authenticated_view_club_asset,
  has_function_privilege('anon','private.can_view_club_asset(uuid)','EXECUTE') as anon_view_club_asset,
  has_function_privilege('authenticated','private.can_view_profile_avatar(uuid)','EXECUTE') as authenticated_view_profile_avatar,
  has_function_privilege('anon','private.can_view_profile_avatar(uuid)','EXECUTE') as anon_view_profile_avatar,
  has_function_privilege('authenticated','private.can_manage_profile_avatar(uuid)','EXECUTE') as authenticated_manage_profile_avatar,
  has_function_privilege('anon','private.can_manage_profile_avatar(uuid)','EXECUTE') as anon_manage_profile_avatar,
  has_function_privilege('authenticated','private.is_valid_profile_avatar_path(uuid,text)','EXECUTE') as authenticated_validate_profile_avatar,
  has_function_privilege('anon','private.is_valid_profile_avatar_path(uuid,text)','EXECUTE') as anon_validate_profile_avatar,
  has_function_privilege('service_role','private.can_manage_player_photo(uuid,uuid)','EXECUTE') as service_role_manage_player_photo,
  has_function_privilege('service_role','private.can_view_club_asset(uuid)','EXECUTE') as service_role_view_club_asset,
  has_function_privilege('service_role','private.can_view_profile_avatar(uuid)','EXECUTE') as service_role_view_profile_avatar,
  has_function_privilege('service_role','private.can_manage_profile_avatar(uuid)','EXECUTE') as service_role_manage_profile_avatar,
  has_function_privilege('service_role','private.is_valid_profile_avatar_path(uuid,text)','EXECUTE') as service_role_validate_profile_avatar;

-- 4. Trigger
select t.tgname,pg_get_triggerdef(t.oid) as definition
from pg_trigger t
where t.tgrelid='public.profiles'::regclass
  and not t.tgisinternal
  and t.tgname='profiles_validate_avatar_path';

-- 5. Data inventory (compare before/after; migration must not delete data)
select
 (select count(*) from public.players) as players,
 (select count(*) from public.players where photo_path is not null) as players_with_photo_path,
 (select count(*) from public.players where photo_data is not null) as legacy_photo_data,
 (select count(*) from public.profiles) as profiles,
 (select count(*) from public.profiles where avatar_url is not null) as avatar_references,
 (select count(*) from public.clubs where crest_path is not null) as crest_references,
 (select count(*) from storage.objects where bucket_id='player-photos') as player_photo_objects,
 (select count(*) from storage.objects where bucket_id='profile-avatars') as avatar_objects,
 (select count(*) from storage.objects where bucket_id='club-assets') as club_asset_objects;

-- 6. Club crest path matching
select c.id,c.crest_path,o.name,(c.crest_path=o.name) as exact_match
from public.clubs c
left join storage.objects o
  on o.bucket_id='club-assets' and o.name=c.crest_path
where c.crest_path is not null;

-- Expected after full release AND after the club logo has been re-uploaded:
-- All four migration names are present in supabase_migrations.schema_migrations.
-- player-photos: public=false; profile-avatars: public=false; club-assets: public=false.
-- All bucket-specific SELECT/INSERT/UPDATE/DELETE policies remain present.
-- Trigger exists; helper functions are in private schema.
-- Newly uploaded club crest reference has its matching object.
-- Player/profile data is preserved. The old club logo object and crest_path
-- reference were deliberately removed as a separately approved release prerequisite,
-- then the logo was re-uploaded through KADAssist. No other object is deleted.
