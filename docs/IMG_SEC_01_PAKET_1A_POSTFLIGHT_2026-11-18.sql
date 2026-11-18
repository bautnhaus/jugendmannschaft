-- IMG-SEC-01 Paket 1A – read-only Postflight
select
 (select public from storage.buckets where id='player-photos') as player_bucket_public,
 (select count(*) from storage.objects where bucket_id='player-photos') as player_photo_objects,
 (select count(*) from information_schema.columns where table_schema='public' and table_name='players' and column_name='photo_path') as photo_path_exists,
 (select count(*) from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_select') as profiles_select_present,
 (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and policyname='club_assets_select_scoped') as club_select_present,
 (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and policyname like 'player_photos_%') as player_photo_policy_count,
 (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='private' and p.proname in ('can_manage_player_photo','can_view_club_asset','can_view_profile_avatar')) as private_helper_count,
 (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('can_manage_player_photo','can_view_club_asset','can_view_profile_avatar','can_view_player_photo')) as public_helper_count;
select version,name from supabase_migrations.schema_migrations
where name in ('img_sec_01_private_player_photo_storage_v1_0_0','img_sec_01_harden_private_policy_helpers')
order by version;
