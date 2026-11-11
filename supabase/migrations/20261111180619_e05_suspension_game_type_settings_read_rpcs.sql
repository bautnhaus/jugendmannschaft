-- DB-MIG-2026-009 / E05 frontend read access for suspension game-type settings
-- DEV only. Adds permission-checked read RPCs; no table/data/RLS change.
create or replace function public.get_club_suspension_game_types(p_club_id uuid)
returns text[] language plpgsql stable security definer
set search_path = pg_catalog, public, auth
as $function$
declare v_types text[];
begin
 if auth.uid() is null then raise exception using errcode='42501',message='Authentication required'; end if;
 if p_club_id is null then raise exception using errcode='22023',message='Club is required'; end if;
 if not public.can_manage_club_context(p_club_id) then raise exception using errcode='42501',message='Club management permission required'; end if;
 select coalesce(s.relevant_game_types,'{}'::text[]) into v_types
 from public.clubs c left join public.club_suspension_settings s on s.club_id=c.id
 where c.id=p_club_id;
 if not found then raise exception using errcode='P0002',message='Club not found'; end if;
 return v_types;
end;
$function$;

create or replace function public.get_team_suspension_game_type_settings(p_team_id uuid)
returns table(override_enabled boolean,team_game_types text[],club_game_types text[])
language plpgsql stable security definer
set search_path = pg_catalog, public, auth
as $function$
declare v_club_id uuid; v_override boolean; v_team_types text[]; v_club_types text[];
begin
 if auth.uid() is null then raise exception using errcode='42501',message='Authentication required'; end if;
 if p_team_id is null then raise exception using errcode='22023',message='Team is required'; end if;
 select t.club_id into v_club_id from public.teams t where t.id=p_team_id;
 if not found then raise exception using errcode='P0002',message='Team not found'; end if;
 if not exists(select 1 from public.team_member_roles r where r.team_id=p_team_id and r.user_id=auth.uid() and r.role in ('trainer','admin'))
    and not public.has_selected_team_context(p_team_id) then
   raise exception using errcode='42501',message='Team management permission required';
 end if;
 select exists(select 1 from public.team_suspension_game_type_settings s where s.team_id=p_team_id) into v_override;
 select coalesce(array_agg(g.game_type order by g.game_type),'{}'::text[]) into v_team_types
 from public.team_suspension_game_types g where g.team_id=p_team_id;
 select coalesce(s.relevant_game_types,'{}'::text[]) into v_club_types
 from public.club_suspension_settings s where s.club_id=v_club_id;
 return query select v_override,v_team_types,coalesce(v_club_types,'{}'::text[]);
end;
$function$;

revoke all on function public.get_club_suspension_game_types(uuid) from public,anon;
grant execute on function public.get_club_suspension_game_types(uuid) to authenticated;
revoke all on function public.get_team_suspension_game_type_settings(uuid) from public,anon;
grant execute on function public.get_team_suspension_game_type_settings(uuid) to authenticated;
