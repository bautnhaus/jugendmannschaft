-- IMG-SEC-01 guarded rollback; before any player-photo data is stored.
begin;
do $$
begin
 if exists(select 1 from public.players where photo_path is not null) then raise exception 'Rollback stopped: players.photo_path contains data.'; end if;
 if exists(select 1 from storage.objects where bucket_id='player-photos') then raise exception 'Rollback stopped: player-photos contains objects.'; end if;
end;
$$;
drop policy if exists player_photos_delete_team on storage.objects;
drop policy if exists player_photos_update_team on storage.objects;
drop policy if exists player_photos_insert_team on storage.objects;
drop policy if exists player_photos_select_team on storage.objects;
drop policy if exists profile_avatars_select_authorized on storage.objects;
drop policy if exists club_assets_select_scoped on storage.objects;
create policy club_assets_select_scoped on storage.objects for select to authenticated using (
 bucket_id='club-assets' and can_manage_club_context(
 case when split_part(name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then split_part(name,'/',1)::uuid else null::uuid end
 )
);
drop function if exists private.can_manage_player_photo(uuid,uuid);
drop function if exists private.can_view_club_asset(uuid);
drop function if exists private.can_view_profile_avatar(uuid);
drop function if exists public.can_view_player_photo(uuid);
alter table public.players drop column if exists photo_path;
delete from storage.buckets where id='player-photos' and not exists(select 1 from storage.objects where bucket_id='player-photos');
commit;
