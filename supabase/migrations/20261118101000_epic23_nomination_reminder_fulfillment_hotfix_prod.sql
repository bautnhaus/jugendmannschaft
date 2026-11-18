-- Epic 23 – Paket 1 Hotfix 1: Fulfillment timestamp ordering
-- PROD release. Applied successfully on 2026-11-17. Safe to re-run. No data changes.
-- Fix: PostgreSQL now() is transaction_timestamp(); a reminder created and
-- a later matchday nomination inserted in one transaction share that value.
-- <= allows the later INSERT event to fulfill the reminder.

create or replace function public.epic23_fulfill_nomination_reminder()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public,auth
as $function$
declare
  v_team_id uuid;
  v_match_date date;
  v_actor uuid:=auth.uid();
  v_reminder record;
  v_actor_name text;
  v_now timestamptz:=clock_timestamp();
begin
  if tg_op='UPDATE'
     and new.matchday_id is not distinct from old.matchday_id
     and new.player_id is not distinct from old.player_id then
    return new;
  end if;

  select m.team_id,m.match_date into v_team_id,v_match_date
  from public.matchdays m where m.id=new.matchday_id;
  if v_team_id is null then return new; end if;

  select display_name into v_actor_name from public.profiles where id=v_actor;

  for v_reminder in
    select r.*
    from public.matchday_nomination_reminders r
    where r.team_id=v_team_id
      and r.player_id=new.player_id
      and r.status='pending'
      and r.created_at <= v_now
      and v_match_date > r.source_matchday_date_snapshot
    for update
  loop
    update public.matchday_nomination_reminders
    set status='fulfilled',fulfilled_matchday_id=new.matchday_id,
        fulfilled_matchday_date_snapshot=v_match_date,fulfilled_at=v_now
    where id=v_reminder.id;

    insert into public.matchday_nomination_reminder_audit(
      reminder_id,action,old_values,new_values,reason,changed_by,changed_by_snapshot,changed_at
    ) values (
      v_reminder.id,'fulfilled',
      jsonb_build_object('status','pending'),
      jsonb_build_object('status','fulfilled','fulfilled_matchday_id',new.matchday_id,
        'fulfilled_matchday_date',v_match_date,'fulfilled_at',v_now),
      'Automatisch erfüllt: Spieler wurde nach Erstellung der Vormerkung für einen späteren Spieltag nominiert.',
      v_actor,v_actor_name,v_now
    );
  end loop;
  return new;
end;
$function$;

revoke all on function public.epic23_fulfill_nomination_reminder()
from public,anon,authenticated,service_role;
