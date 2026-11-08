-- Supabase migration: 20261108213035 / e05_package_09_fix_card_correction_player_lock
-- Actual DEV correction SQL: replace SELECT-without-destination by PERFORM.
create or replace function public.correct_training_behavior_event(
  p_event_id uuid,
  p_target_status text,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_actor uuid := auth.uid();
  v_actor_name text;
  v_event public.training_behavior_events%rowtype;
  v_old jsonb;
  v_new jsonb;
  v_now timestamptz := now();
  v_audit_action text;
begin
  if v_actor is null then
    raise exception using errcode = '42501',
      message = 'Authentication required';
  end if;

  if p_event_id is null
     or p_target_status is null
     or p_target_status not in ('active', 'voided')
     or nullif(btrim(p_reason), '') is null then
    raise exception using errcode = '22023',
      message = 'Event, valid target status and correction reason are required';
  end if;

  -- Lock player first to serialize corrections against concurrent card awards.
  perform p.id
  from public.players p
  join public.training_behavior_events e on e.player_id = p.id
  where e.id = p_event_id
  for update of p;

  select * into v_event
  from public.training_behavior_events
  where id = p_event_id
  for update;

  if not found then
    raise exception using errcode = 'P0002',
      message = 'Training behavior event not found';
  end if;

  if v_event.player_id is null then
    raise exception using errcode = '23514',
      message = 'A card event without a linked player cannot be corrected';
  end if;

  if v_event.event_type not in ('yellow_card', 'red_card') then
    raise exception using errcode = '23514',
      message = 'Only yellow and red card events can be corrected in Paket 9';
  end if;

  perform public.e05_assert_suspension_correction_permission(
    v_event.team_id, v_actor
  );

  if v_event.status = p_target_status then
    raise exception using errcode = '23514',
      message = 'Event already has the requested status; duplicate correction rejected';
  end if;

  select nullif(btrim(pr.display_name), '')
  into v_actor_name
  from public.profiles pr
  where pr.id = v_actor;

  v_old := jsonb_build_object(
    'status', v_event.status,
    'voided_by', v_event.voided_by,
    'voided_at', v_event.voided_at,
    'void_reason', v_event.void_reason,
    'event_type', v_event.event_type,
    'awarded_at', v_event.awarded_at
  );

  if p_target_status = 'voided' then
    update public.training_behavior_events
    set status = 'voided',
        voided_by = v_actor,
        voided_at = v_now,
        void_reason = btrim(p_reason),
        updated_at = v_now
    where id = v_event.id;

    v_audit_action := 'voided';
    v_new := jsonb_build_object(
      'status', 'voided',
      'voided_by', v_actor,
      'voided_by_snapshot', v_actor_name,
      'voided_at', v_now,
      'void_reason', btrim(p_reason)
    );
  else
    update public.training_behavior_events
    set status = 'active',
        voided_by = null,
        voided_at = null,
        void_reason = null,
        updated_at = v_now
    where id = v_event.id;

    v_audit_action := 'reinstated';
    v_new := jsonb_build_object('status', 'active');
  end if;

  insert into public.training_behavior_event_audit(
    event_id, action, old_values, new_values, reason,
    changed_by, changed_by_snapshot, changed_at
  ) values (
    v_event.id, v_audit_action, v_old, v_new, btrim(p_reason),
    v_actor, v_actor_name, v_now
  );

  -- Reconcile suspension state in the same transaction. A served suspension
  -- is deliberately never changed by this helper.
  perform public.e05_reconcile_suspensions_after_event_correction(
    v_event.id, v_actor, btrim(p_reason)
  );

  return v_event.id;
end;
$function$;

revoke all on function
  public.correct_training_behavior_event(uuid, text, text)
from public, anon, authenticated, service_role;
