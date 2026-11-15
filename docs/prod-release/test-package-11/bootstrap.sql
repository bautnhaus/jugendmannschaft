\set ON_ERROR_STOP on
-- Minimal, isolated PostgreSQL fixture mirroring the relevant PROD Paket-6 baseline.
do $$ begin
  if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role nologin; end if;
end $$;
create schema if not exists auth;
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;

create table public.teams(id uuid primary key);
create table public.players(id uuid primary key,team_id uuid,active boolean default true);
create table public.matchdays(id uuid primary key,team_id uuid,season_id uuid,status text,match_date date);
create table public.matchday_players(matchday_id uuid,player_id uuid,played boolean default false,primary key(matchday_id,player_id));
create table public.training_suspensions(id uuid primary key,team_id uuid,season_id uuid,player_id uuid,status text,intended_matchday_id uuid,created_at timestamptz default now());
create table public.training_suspension_exceptions(id uuid primary key,suspension_id uuid,team_id uuid,player_id uuid,matchday_id uuid,revoked_at timestamptz,revoked_by uuid,revoked_by_snapshot text,revoke_reason text);
create table public.training_suspension_audit(id uuid primary key default gen_random_uuid(),exception_id uuid,action text,old_values jsonb,new_values jsonb,reason text,changed_by uuid,changed_at timestamptz default now());
create table public.matchday_recommendation_runs(id uuid primary key default gen_random_uuid(),matchday_id uuid unique,created_at timestamptz,created_by uuid);
create table public.matchday_recommendation_players(recommendation_id uuid,player_id uuid,rank integer);
create table public.profiles(id uuid,display_name text);
create table public.team_member_roles(team_id uuid,user_id uuid,role text);
create table public.global_user_roles(user_id uuid,role text);

create or replace function public.is_team_member(p_team_id uuid) returns boolean
language sql stable as $$ select true $$;
create or replace function public.has_selected_team_context(p_team_id uuid) returns boolean
language sql stable as $$ select false $$;
create or replace function public.e05_assign_player_suspensions(p_team_id uuid,p_player_id uuid,p_actor_id uuid)
returns integer language sql as $$ select 0 $$;

CREATE OR REPLACE FUNCTION public.save_matchday_recommendation(p_matchday_id uuid, p_player_ids uuid[])
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
    v_team_id uuid;
    v_recommendation_id uuid;
    v_count integer;
    v_distinct_count integer;
BEGIN
    IF p_matchday_id IS NULL THEN
        RAISE EXCEPTION 'Spieltag fehlt.';
    END IF;

    IF p_player_ids IS NULL OR cardinality(p_player_ids) = 0 THEN
        RAISE EXCEPTION 'Eine leere Kaderempfehlung wird nicht gespeichert.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM unnest(p_player_ids) AS u(player_id)
        WHERE u.player_id IS NULL
    ) THEN
        RAISE EXCEPTION 'Die Empfehlung enthaelt eine ungueltige Spieler-ID.';
    END IF;

    SELECT m.team_id
    INTO v_team_id
    FROM public.matchdays m
    WHERE m.id = p_matchday_id
    FOR UPDATE;

    IF v_team_id IS NULL THEN
        RAISE EXCEPTION 'Spieltag nicht gefunden.';
    END IF;

    IF NOT public.is_team_member(v_team_id) THEN
        RAISE EXCEPTION 'Keine Berechtigung fuer diesen Spieltag.';
    END IF;

    SELECT count(*), count(DISTINCT u.player_id)
    INTO v_count, v_distinct_count
    FROM unnest(p_player_ids) AS u(player_id);

    IF v_count <> v_distinct_count THEN
        RAISE EXCEPTION 'Die Empfehlung enthaelt doppelte Spieler.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM unnest(p_player_ids) AS u(player_id)
        LEFT JOIN public.players p ON p.id = u.player_id
        WHERE p.id IS NULL
           OR p.team_id <> v_team_id
           OR p.active IS NOT TRUE
    ) THEN
        RAISE EXCEPTION
          'Mindestens ein Spieler ist ungueltig, inaktiv oder gehoert nicht zur Mannschaft des Spieltags.';
    END IF;

    INSERT INTO public.matchday_recommendation_runs (
        matchday_id, created_at, created_by
    )
    VALUES (p_matchday_id, now(), auth.uid())
    ON CONFLICT (matchday_id)
    DO UPDATE SET
        created_at = EXCLUDED.created_at,
        created_by = EXCLUDED.created_by
    RETURNING id INTO v_recommendation_id;

    DELETE FROM public.matchday_recommendation_players
    WHERE recommendation_id = v_recommendation_id;

    INSERT INTO public.matchday_recommendation_players (
        recommendation_id, player_id, rank
    )
    SELECT v_recommendation_id, u.player_id, u.ordinality::integer
    FROM unnest(p_player_ids)
         WITH ORDINALITY AS u(player_id, ordinality);

    RETURN v_recommendation_id;
END;
$function$
;
CREATE OR REPLACE FUNCTION public.prevent_suspended_matchday_nomination()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
    v_team_id uuid;
    v_blocking_suspension_id uuid;
begin
    if tg_op = 'UPDATE'
       and new.matchday_id is not distinct from old.matchday_id
       and new.player_id is not distinct from old.player_id then
        return new;
    end if;
    if tg_op = 'UPDATE' and old.player_id is distinct from new.player_id then
        if old.player_id::text < new.player_id::text then
            perform pg_advisory_xact_lock(hashtextextended(old.player_id::text,0));
            perform pg_advisory_xact_lock(hashtextextended(new.player_id::text,0));
        else
            perform pg_advisory_xact_lock(hashtextextended(new.player_id::text,0));
            perform pg_advisory_xact_lock(hashtextextended(old.player_id::text,0));
        end if;
    else
        perform pg_advisory_xact_lock(hashtextextended(new.player_id::text,0));
    end if;
    select m.team_id into v_team_id from public.matchdays m where m.id=new.matchday_id;
    if v_team_id is null then
        raise exception 'Der ausgewählte Spieltag wurde nicht gefunden.' using errcode='23503';
    end if;
    select s.id into v_blocking_suspension_id
      from public.training_suspensions s
     where s.team_id=v_team_id and s.player_id=new.player_id
       and s.status='open' and s.intended_matchday_id=new.matchday_id
       and not exists (
         select 1 from public.training_suspension_exceptions e
          where e.suspension_id=s.id and e.matchday_id=new.matchday_id
            and e.revoked_at is null
       )
     order by s.created_at,s.id limit 1;
    if v_blocking_suspension_id is not null then
      raise exception 'Nominierung nicht möglich: Für diesen Spieler besteht eine Sperre für diesen Spieltag. Bitte zuerst eine Ausnahme erteilen.'
        using errcode='23514';
    end if;
    return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.revoke_suspension_exception(p_exception_id uuid, p_revoke_reason text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_exception public.training_suspension_exceptions%rowtype;
  v_suspension public.training_suspensions%rowtype;
  v_matchday public.matchdays%rowtype;
  v_actor_name text;
  v_old_values jsonb;
  v_new_values jsonb;
  v_reassigned integer := 0;
  v_nomination_snapshot jsonb;
begin
  if v_actor is null then
    raise exception using errcode='42501',message='Authentication required';
  end if;
  if p_exception_id is null or nullif(btrim(p_revoke_reason),'') is null then
    raise exception using errcode='22023',message='Exception and non-empty revocation reason are required';
  end if;
  select * into v_exception from public.training_suspension_exceptions where id=p_exception_id;
  if not found then raise exception using errcode='P0002',message='Suspension exception not found'; end if;
  if v_exception.player_id is not null then
    perform pg_advisory_xact_lock(hashtextextended(v_exception.player_id::text,0));
    perform 1 from public.players p where p.id=v_exception.player_id for update;
  end if;
  select * into v_suspension from public.training_suspensions where id=v_exception.suspension_id for update;
  if not found then raise exception using errcode='P0002',message='Related suspension not found'; end if;
  select * into v_exception from public.training_suspension_exceptions where id=p_exception_id for update;
  if not found then raise exception using errcode='P0002',message='Suspension exception not found'; end if;
  if v_exception.revoked_at is not null then raise exception using errcode='23514',message='Suspension exception has already been revoked'; end if;
  if v_suspension.status<>'open' then raise exception using errcode='23514',message='Only an open suspension can have its exception revoked'; end if;
  if v_suspension.team_id<>v_exception.team_id or v_suspension.player_id is distinct from v_exception.player_id then
    raise exception using errcode='23514',message='Exception and suspension ownership do not match';
  end if;
  if not exists (
    select 1 from public.team_member_roles r
     where r.team_id=v_exception.team_id and r.user_id=v_actor and r.role in ('trainer','admin')
  ) and not (
    exists(select 1 from public.global_user_roles g where g.user_id=v_actor and g.role='super_admin')
    and public.has_selected_team_context(v_exception.team_id)
  ) then
    raise exception using errcode='42501',message='Team permission required';
  end if;
  select * into v_matchday from public.matchdays where id=v_exception.matchday_id for update;
  if not found then raise exception using errcode='P0002',message='Original matchday not found'; end if;
  if v_matchday.team_id<>v_exception.team_id
     or v_matchday.season_id is distinct from v_suspension.season_id
     or v_matchday.status<>'planned'
     or v_matchday.match_date<current_date then
    raise exception using errcode='23514',message='An exception can only be revoked before its original matchday is held or has passed';
  end if;
  select pr.display_name into v_actor_name from public.profiles pr where pr.id=v_actor;
  update public.training_suspension_exceptions
     set revoked_by=v_actor,revoked_by_snapshot=v_actor_name,revoked_at=now(),revoke_reason=btrim(p_revoke_reason)
   where id=v_exception.id;
  if v_suspension.player_id is not null then
    v_reassigned:=public.e05_assign_player_suspensions(v_suspension.team_id,v_suspension.player_id,v_actor);
  end if;
  if exists (
    select 1 from public.training_suspensions s
     where s.team_id=v_exception.team_id and s.player_id=v_exception.player_id
       and s.status='open' and s.intended_matchday_id=v_exception.matchday_id
       and not exists (
         select 1 from public.training_suspension_exceptions e
          where e.suspension_id=s.id and e.matchday_id=v_exception.matchday_id and e.revoked_at is null
       )
  ) then
    select to_jsonb(mp) into v_nomination_snapshot
      from public.matchday_players mp
     where mp.matchday_id=v_exception.matchday_id and mp.player_id=v_exception.player_id
     for update;
    if v_nomination_snapshot is not null
       and coalesce((v_nomination_snapshot->>'played')::boolean,false) is true then
      raise exception using errcode='23514',
        message='Widerruf abgebrochen: Für diesen Spieler ist bereits ein tatsächlicher Einsatz dokumentiert.';
    end if;
    if v_nomination_snapshot is not null then
      delete from public.matchday_players
       where matchday_id=v_exception.matchday_id and player_id=v_exception.player_id;
    end if;
  end if;
  v_old_values:=jsonb_build_object(
    'revoked_at',v_exception.revoked_at,'revoked_by',v_exception.revoked_by,
    'revoke_reason',v_exception.revoke_reason,'suspension_id',v_exception.suspension_id,
    'matchday_id',v_exception.matchday_id
  );
  v_new_values:=jsonb_build_object(
    'revoked_at',now(),'revoked_by',v_actor,'revoked_by_snapshot',v_actor_name,
    'revoke_reason',btrim(p_revoke_reason),'suspension_id',v_exception.suspension_id,
    'matchday_id',v_exception.matchday_id,'nomination_removed',v_nomination_snapshot is not null,
    'removed_nomination_snapshot',v_nomination_snapshot
  );
  insert into public.training_suspension_audit(exception_id,action,old_values,new_values,reason,changed_by,changed_at)
  values(v_exception.id,'exception_revoked',v_old_values,v_new_values,btrim(p_revoke_reason),v_actor,now());
  return v_exception.id;
end;
$function$
;

revoke all on function public.save_matchday_recommendation(uuid,uuid[]) from public,anon,authenticated,service_role;
grant execute on function public.save_matchday_recommendation(uuid,uuid[]) to authenticated,service_role;
revoke all on function public.prevent_suspended_matchday_nomination() from public,anon,authenticated,service_role;
grant execute on function public.prevent_suspended_matchday_nomination() to public,anon,authenticated,service_role;
revoke all on function public.revoke_suspension_exception(uuid,text) from public,anon,authenticated,service_role;
grant execute on function public.revoke_suspension_exception(uuid,text) to authenticated;

create trigger matchday_players_prevent_suspended_nomination
before insert or update of matchday_id,player_id on public.matchday_players
for each row execute function public.prevent_suspended_matchday_nomination();
