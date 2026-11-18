-- Epic 23 – Paket 2: Read API for pending nomination reminders (PROD)
-- Database-only package. No frontend changes and no PROD changes.
-- Supplies the current matchday's eligible reminder records to the frontend.
-- Ranking priority and visual presentation remain client-side.

begin;

do $preflight$
begin
  if to_regclass('public.matchday_nomination_reminders') is null
     or to_regclass('public.matchdays') is null
     or to_regclass('public.matchday_players') is null
     or to_regprocedure('public.has_selected_team_context(uuid)') is null then
    raise exception 'Epic 23 Paket 2: required Paket 1 objects missing';
  end if;
  if to_regprocedure('public.get_matchday_nomination_reminders(uuid)') is not null then
    raise exception 'Epic 23 Paket 2: read API already exists; manual reconciliation required';
  end if;
end;
$preflight$;

create function public.get_matchday_nomination_reminders(
  p_matchday_id uuid
)
returns table (
  reminder_id uuid,
  player_id uuid,
  player_name text,
  reason text,
  source_matchday_date date,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_actor uuid:=auth.uid();
  v_matchday public.matchdays%rowtype;
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_matchday_id is null then
    raise exception using errcode='22023',message='Spieltag ist erforderlich.';
  end if;

  select * into v_matchday
  from public.matchdays
  where id=p_matchday_id;
  if not found then
    raise exception using errcode='P0002',message='Spieltag nicht gefunden.';
  end if;

  if not exists (
    select 1 from public.team_member_roles r
    where r.team_id=v_matchday.team_id and r.user_id=v_actor
      and r.role in ('trainer','admin')
  ) and not (
    exists(select 1 from public.global_user_roles g
      where g.user_id=v_actor and g.role='super_admin')
    and public.has_selected_team_context(v_matchday.team_id)
  ) then
    raise exception using errcode='42501',message='Keine Berechtigung für diese Mannschaft.';
  end if;

  return query
  select r.id,r.player_id,r.player_name_snapshot,r.reason,
         r.source_matchday_date_snapshot,r.created_at
  from public.matchday_nomination_reminders r
  where r.team_id=v_matchday.team_id
    and r.status='pending'
    and r.player_id is not null
    and v_matchday.match_date > r.source_matchday_date_snapshot
    and not exists (
      select 1 from public.matchday_players mp
      where mp.matchday_id=v_matchday.id and mp.player_id=r.player_id
    )
  order by r.created_at,r.player_name_snapshot;
end;
$function$;

revoke all on function public.get_matchday_nomination_reminders(uuid)
from public,anon,authenticated,service_role;
grant execute on function public.get_matchday_nomination_reminders(uuid)
to authenticated;

commit;
