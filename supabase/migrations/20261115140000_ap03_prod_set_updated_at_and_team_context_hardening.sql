-- AP03 PROD: Harden set_updated_at search_path and bind team listing to selected club context.
-- Target: Supabase PROD only (qdugtpzgefpswnnqbusd).
-- No data, table, column, trigger, or grant changes.
-- Strict preflight: abort if the live state differs from the reviewed baseline.

BEGIN;

DO $preflight$
DECLARE
  v_acl text;
  v_trigger_count integer;
  v_policy_count integer;
BEGIN
  IF md5(pg_get_functiondef('public.set_updated_at()'::regprocedure))
     <> '8de7ae383447503e8949149bfb3f0efb' THEN
    RAISE EXCEPTION 'Preflight: set_updated_at() differs from reviewed PROD baseline';
  END IF;

  SELECT p.proacl::text INTO v_acl
  FROM pg_proc p
  WHERE p.oid = 'public.set_updated_at()'::regprocedure;

  IF v_acl <> '{=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}' THEN
    RAISE EXCEPTION 'Preflight: set_updated_at() ACL differs from reviewed PROD baseline: %', v_acl;
  END IF;

  SELECT count(*) INTO v_trigger_count
  FROM pg_trigger t
  WHERE t.tgfoid = 'public.set_updated_at()'::regprocedure
    AND NOT t.tgisinternal;

  IF v_trigger_count <> 6 THEN
    RAISE EXCEPTION 'Preflight: expected 6 set_updated_at triggers, found %', v_trigger_count;
  END IF;

  IF (SELECT md5(qual) FROM pg_policies
      WHERE schemaname='public' AND tablename='teams'
        AND policyname='teams_select_context_admin')
     IS DISTINCT FROM '26656e900f10c80db415ed9cf321f812' THEN
    RAISE EXCEPTION 'Preflight: teams_select_context_admin differs from reviewed PROD baseline';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='user_club_context'
      AND policyname='user_club_context_select_self'
      AND qual = '(user_id = auth.uid())'
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='user_team_context'
      AND policyname='user_team_context_select_self'
      AND qual = '(user_id = auth.uid())'
  ) THEN
    RAISE EXCEPTION 'Preflight: expected self-only context SELECT policies are missing or changed';
  END IF;

  IF to_regprocedure('public.can_manage_club_context(uuid)') IS NULL
     OR to_regprocedure('public.is_club_admin(uuid)') IS NULL THEN
    RAISE EXCEPTION 'Preflight: required club-context helper functions are missing';
  END IF;

  IF position('ctx.club_id = p_club_id' IN pg_get_functiondef('public.can_manage_club_context(uuid)'::regprocedure)) = 0
     OR position('ctx.club_id = p_club_id' IN pg_get_functiondef('public.is_club_admin(uuid)'::regprocedure)) = 0 THEN
    RAISE EXCEPTION 'Preflight: context helper definitions do not enforce selected club context';
  END IF;

  SELECT count(*) INTO v_policy_count
  FROM pg_policies
  WHERE schemaname='public'
    AND (
      (tablename='club_members' AND policyname='club_members_select_member_or_admin'
       AND qual LIKE '%can_manage_club_context%')
      OR
      (tablename='club_member_roles' AND policyname='club_member_roles_select_member_or_admin'
       AND qual LIKE '%can_manage_club_context%')
    );

  IF v_policy_count <> 2 THEN
    RAISE EXCEPTION 'Preflight: expected context-aware club member SELECT policies are missing';
  END IF;
END;
$preflight$;

-- This trigger function only assigns NEW.updated_at and calls now().
-- Pinning search_path makes its resolution deterministic; it remains INVOKER.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'pg_catalog', 'public'
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

-- Replace the unconditional Superadmin branch with the already-reviewed
-- helper that requires the selected club context.
DROP POLICY teams_select_context_admin ON public.teams;
CREATE POLICY teams_select_context_admin
ON public.teams
FOR SELECT
TO authenticated
USING (
  (SELECT public.can_manage_club_context(club_id))
);

DO $postflight$
DECLARE
  v_acl text;
  v_trigger_count integer;
  v_policy_qual text;
BEGIN
  IF NOT (
    SELECT NOT p.prosecdef
       AND pg_get_userbyid(p.proowner) = 'postgres'
       AND p.proconfig @> ARRAY['search_path=pg_catalog, public']
    FROM pg_proc p
    WHERE p.oid = 'public.set_updated_at()'::regprocedure
  ) THEN
    RAISE EXCEPTION 'Postflight: set_updated_at() security mode, owner, or search_path is incorrect';
  END IF;

  SELECT p.proacl::text INTO v_acl
  FROM pg_proc p
  WHERE p.oid = 'public.set_updated_at()'::regprocedure;

  IF v_acl <> '{=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}' THEN
    RAISE EXCEPTION 'Postflight: set_updated_at() ACL changed unexpectedly: %', v_acl;
  END IF;

  SELECT count(*) INTO v_trigger_count
  FROM pg_trigger t
  WHERE t.tgfoid = 'public.set_updated_at()'::regprocedure
    AND NOT t.tgisinternal;

  IF v_trigger_count <> 6 THEN
    RAISE EXCEPTION 'Postflight: set_updated_at trigger count changed: %', v_trigger_count;
  END IF;

  SELECT qual INTO v_policy_qual
  FROM pg_policies
  WHERE schemaname='public' AND tablename='teams'
    AND policyname='teams_select_context_admin';

  IF v_policy_qual IS NULL
     OR v_policy_qual NOT LIKE '%can_manage_club_context%'
     OR v_policy_qual LIKE '%is_super_admin%' THEN
    RAISE EXCEPTION 'Postflight: teams SELECT policy is not context-bound';
  END IF;
END;
$postflight$;

COMMIT;
