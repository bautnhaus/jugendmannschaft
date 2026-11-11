-- Rollback for DB-MIG-2026-009. Revert frontend first.
revoke all on function public.get_club_suspension_game_types(uuid) from public,anon,authenticated;
revoke all on function public.get_team_suspension_game_type_settings(uuid) from public,anon,authenticated;
drop function if exists public.get_club_suspension_game_types(uuid);
drop function if exists public.get_team_suspension_game_type_settings(uuid);
