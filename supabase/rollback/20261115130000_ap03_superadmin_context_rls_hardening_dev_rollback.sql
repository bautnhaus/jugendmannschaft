-- Rollback zu AP03 Superadmin-Kontext-RLS-Härtung.
-- Ausschließlich DEV; stellt den dokumentierten Vorzustand wieder her.
-- Achtung: Der Rollback hebt die hier eingeführte Sicherheitskorrektur auf.

BEGIN;

DO $preflight$
DECLARE
  v_policy_count integer;
  v_fn text;
BEGIN
  SELECT pg_get_functiondef('public.is_club_admin(uuid)'::regprocedure)
  INTO v_fn;

  IF position('WHEN public.is_super_admin() THEN EXISTS' IN v_fn) = 0
     OR position('ctx.club_id = p_club_id' IN v_fn) = 0 THEN
    RAISE EXCEPTION 'Rollback-Preflight: erwarteter gehärteter Funktionsstand fehlt';
  END IF;

  SELECT count(*) INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (
      (tablename = 'club_members' AND policyname = 'club_members_select_member_or_admin')
      OR (tablename = 'club_member_roles' AND policyname = 'club_member_roles_select_member_or_admin')
      OR (tablename = 'teams' AND policyname = 'teams_select_context_admin')
      OR (tablename = 'user_club_context' AND policyname = 'user_club_context_select_self')
      OR (tablename = 'user_team_context' AND policyname = 'user_team_context_select_self')
    );

  IF v_policy_count <> 5 THEN
    RAISE EXCEPTION 'Rollback-Preflight: erwartete fünf Ziel-Policies nicht vollständig vorhanden';
  END IF;
END;
$preflight$;

DROP POLICY user_club_context_select_self ON public.user_club_context;
DROP POLICY user_team_context_select_self ON public.user_team_context;

CREATE OR REPLACE FUNCTION public.is_club_admin(p_club_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT auth.uid() IS NOT NULL
     AND (
       public.is_super_admin()
       OR EXISTS (
         SELECT 1
         FROM public.club_members m
         JOIN public.club_member_roles r
           ON r.user_id = m.user_id
         WHERE m.user_id = auth.uid()
           AND m.club_id = p_club_id
           AND r.role = 'club_admin'
       )
     );
$function$;

DROP POLICY club_members_select_member_or_admin ON public.club_members;
CREATE POLICY club_members_select_member_or_admin
ON public.club_members
FOR SELECT
TO authenticated
USING (
  (user_id = auth.uid())
  OR public.is_super_admin()
  OR public.is_club_admin(club_id)
);

DROP POLICY club_member_roles_select_member_or_admin ON public.club_member_roles;
CREATE POLICY club_member_roles_select_member_or_admin
ON public.club_member_roles
FOR SELECT
TO authenticated
USING (
  (user_id = auth.uid())
  OR public.is_super_admin()
  OR EXISTS (
    SELECT 1
    FROM public.club_members m
    WHERE m.user_id = club_member_roles.user_id
      AND public.is_club_admin(m.club_id)
  )
);

DROP POLICY teams_select_context_admin ON public.teams;
CREATE POLICY teams_select_context_admin
ON public.teams
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.global_user_roles gur
    WHERE gur.user_id = auth.uid()
      AND gur.role = 'super_admin'
  )
  OR EXISTS (
    SELECT 1
    FROM public.club_members cm
    JOIN public.club_member_roles cmr ON cmr.user_id = cm.user_id
    WHERE cm.user_id = auth.uid()
      AND cm.club_id = teams.club_id
      AND cmr.role = 'club_admin'
  )
);

COMMIT;
