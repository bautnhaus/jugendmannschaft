-- Epic 23 – Paket 3: Reminder visibility on source matchday and reversible fulfillment (DEV)
-- Adds the source matchday to the read API and reopens a fulfilled reminder
-- when its fulfilling nomination is removed and no later nomination remains.

begin;

do $preflight$
begin
  if to_regclass('public.matchday_nomination_reminders') is null
     or to_regclass('public.matchday_nomination_reminder_audit') is null
     or to_regclass('public.matchday_players') is null
     or to_regprocedure('public.get_matchday_nomination_reminders(uuid)') is null
     or to_regprocedure('public.epic23_fulfill_nomination_reminder()') is null then
    raise exception 'Epic 23 Paket 3: required Paket 1/2 objects missing';
  end if;
  if exists(select 1 from pg_trigger where tgname='matchday_players_reopen_nomination_reminder' and tgrelid='public.matchday_players'::regclass) then
    raise exception 'Epic 23 Paket 3: reopen trigger already exists; manual reconciliation required';
  end if;
end;
$preflight$;

create or replace function public.get_matchday_nomination_reminders(p_matchday_id uuid)
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

  select * into v_matchday from public.matchdays where id=p_matchday_id;
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
    and v_matchday.match_date >= r.source_matchday_date_snapshot
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

create function public.epic23_reopen_nomination_reminder_on_delete()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_match_date date;
  v_actor uuid:=auth.uid();
  v_actor_name text;
  v_now timestamptz:=clock_timestamp();
  v_reminder record;
begin
  -- Serialize against a simultaneous nomination/create for the same player.
  perform pg_advisory_xact_lock(hashtextextended(old.player_id::text,0));

  select m.match_date into v_match_date
  from public.matchdays m where m.id=old.matchday_id;
  if v_match_date is null then return old; end if;

  for v_reminder in
    select r.*
    from public.matchday_nomination_reminders r
    where r.status='fulfilled'
      and r.player_id=old.player_id
      and r.fulfilled_matchday_id=old.matchday_id
      and v_match_date > r.source_matchday_date_snapshot
    for update
  loop
    -- A later nomination still fulfils the reminder; only reopen when none remain.
    if not exists (
      select 1
      from public.matchday_players mp
      join public.matchdays m on m.id=mp.matchday_id
      where mp.player_id=old.player_id
        and m.match_date > v_reminder.source_matchday_date_snapshot
    ) then
      select display_name into v_actor_name from public.profiles where id=v_actor;
      update public.matchday_nomination_reminders
      set status='pending',
          fulfilled_matchday_id=null,
          fulfilled_matchday_date_snapshot=null,
          fulfilled_at=null
      where id=v_reminder.id;

      insert into public.matchday_nomination_reminder_audit(
        reminder_id,action,old_values,new_values,reason,changed_by,changed_by_snapshot,changed_at
      ) values (
        v_reminder.id,'reopened',
        jsonb_build_object('status','fulfilled','fulfilled_matchday_id',old.matchday_id,
          'fulfilled_matchday_date',v_match_date),
        jsonb_build_object('status','pending'),
        'Automatisch wieder geöffnet: Die Nominierung für den erfüllenden Spieltag wurde entfernt.',
        v_actor,v_actor_name,v_now
      );
    end if;
  end loop;
  return old;
end;
$function$;

revoke all on function public.epic23_reopen_nomination_reminder_on_delete()
from public,anon,authenticated,service_role;

create trigger matchday_players_reopen_nomination_reminder
after delete on public.matchday_players
for each row execute function public.epic23_reopen_nomination_reminder_on_delete();

commit;
