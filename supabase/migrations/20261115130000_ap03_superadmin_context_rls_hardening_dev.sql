-- AP03: Superadmin-Zugriff an explizit gewählten Vereinskontext binden.
-- Ziel: ausschließlich Supabase DEV (pzazqvvoruqnqhcorbwx).
-- Keine Datenänderung; nur Funktionsdefinitionen und RLS-Policies.
-- Preflight ist absichtlich streng: bei unerwartetem Ausgangsstand wird abgebrochen.

BEGIN;

DO $preflight$
DECLARE
  v_policy_count integer;
  v_rls_count integer;
BEGIN
  IF current_database() IS NULL THEN
    RAISE EXCEPTION 'Preflight: Datenbank nicht verfügbar';
  END IF;

  IF to_regprocedure('public.is_club_admin(uuid)') IS NULL
     OR md5(pg_get_functiondef('public.is_club_admin(uuid)'::regprocedure))
        <> '71b8d94cf8a29d890dc437ad731eebd5' THEN
    RAISE EXCEPTION 'Preflight: is_club_admin(uuid) entspricht nicht dem geprüften DEV-Ausgangsstand';
  END IF;

  IF to_regprocedure('public.can_manage_club_context(uuid)') IS NULL
     OR to_regprocedure('public.is_super_admin()') IS NULL THEN
    RAISE EXCEPTION 'Preflight: erforderliche Kontext-/Rollenfunktion fehlt';
  END IF;

  SELECT count(*) INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (
      (tablename = 'club_members' AND policyname = 'club_members_select_member_or_admin')
      OR (tablename = 'club_member_roles' AND policyname = 'club_member_roles_select_member_or_admin')
      OR (tablename = 'teams' AND policyname = 'teams_select_context_admin')
    );

  IF v_policy_count <> 3 THEN
    RAISE EXCEPTION 'Preflight: erwartete Ausgangs-RLS-Policies fehlen oder sind mehrfach vorhanden';
  END IF;
  IF (SELECT md5(qual) FROM pg_policies
      WHERE schemaname='public' AND tablename='club_members'
        AND policyname='club_members_select_member_or_admin')
       IS DISTINCT FROM 'aa6c1a9bf90c07114a850459106a6752'
     OR (SELECT md5(qual) FROM pg_policies
      WHERE schemaname='public' AND tablename='club_member_roles'
        AND policyname='club_member_roles_select_member_or_admin')
       IS DISTINCT FROM 'ef3e2cef229a93116acf490641a0535c'
     OR (SELECT md5(qual) FROM pg_policies
      WHERE schemaname='public' AND tablename='teams'
        AND policyname='teams_select_context_admin')
       IS DISTINCT FROM '26656e900f10c80db415ed9cf321f812' THEN
    RAISE EXCEPTION 'Preflight: RLS-Policydefinitionen weichen vom geprüften DEV-Ausgangsstand ab';
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND (
        (tablename = 'user_club_context' AND policyname = 'user_club_context_select_self')
        OR (tablename = 'user_team_context' AND policyname = 'user_team_context_select_self')
      )
  ) THEN
    RAISE EXCEPTION 'Preflight: mindestens eine Ziel-Kontextpolicy existiert bereits; manueller Abgleich erforderlich';
  END IF;

  SELECT count(*) INTO v_rls_count
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname IN (
      'club_members',
      'club_member_roles',
      'teams',
      'user_club_context',
      'user_team_context'
    )
    AND c.relrowsecurity;

  IF v_rls_count <> 5 THEN
    RAISE EXCEPTION 'Preflight: RLS ist nicht auf allen fünf betroffenen Tabellen aktiviert';
  END IF;
END;
$preflight$;

-- Superadmins bleiben vereinsneutral. Zugriff auf Vereinsadmin-Ebene nur,
-- wenn genau dieser Verein ausdrücklich im user_club_context ausgewählt ist.
CREATE OR REPLACE FUNCTION public.is_club_admin(p_club_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT auth.uid() IS NOT NULL
     AND CASE
       WHEN public.is_super_admin() THEN EXISTS (
         SELECT 1
         FROM public.user_club_context ctx
         WHERE ctx.user_id = auth.uid()
           AND ctx.club_id = p_club_id
       )
       ELSE EXISTS (
         SELECT 1
         FROM public.club_members m
         JOIN public.club_member_roles r
           ON r.user_id = m.user_id
         WHERE m.user_id = auth.uid()
           AND m.club_id = p_club_id
           AND r.role = 'club_admin'
       )
     END;
$function$;

-- Vereinsmitglieder: eigene Mitgliedschaft oder Admin des konkret
-- ausgewählten Vereins. Kein pauschaler Superadmin-Bypass.
DROP POLICY club_members_select_member_or_admin ON public.club_members;
CREATE POLICY club_members_select_member_or_admin
ON public.club_members
FOR SELECT
TO authenticated
USING (
  user_id = (SELECT auth.uid())
  OR (SELECT public.is_club_admin(club_id))
);

-- Vereinsrollen: eigene Rolle oder Vereinsadmin des Vereins, dem
-- das jeweilige Zielmitglied angehört. Der Helper erzwingt den Kontext.
DROP POLICY club_member_roles_select_member_or_admin ON public.club_member_roles;
CREATE POLICY club_member_roles_select_member_or_admin
ON public.club_member_roles
FOR SELECT
TO authenticated
USING (
  user_id = (SELECT auth.uid())
  OR EXISTS (
    SELECT 1
    FROM public.club_members m
    WHERE m.user_id = club_member_roles.user_id
      AND public.is_club_admin(m.club_id)
  )
);

-- Superadmin darf Mannschaften nur im explizit ausgewählten Vereinskontext
-- lesen. Vereinsadmins behalten den Lesezugriff auf ihren eigenen Verein.
DROP POLICY teams_select_context_admin ON public.teams;
CREATE POLICY teams_select_context_admin
ON public.teams
FOR SELECT
TO authenticated
USING (
  (SELECT public.can_manage_club_context(club_id))
);

-- Kontextdatensätze sind nur für den jeweiligen Benutzer lesbar.
-- Schreibzugriffe bleiben ausschließlich über die vorgesehenen RPCs.
CREATE POLICY user_club_context_select_self
ON public.user_club_context
FOR SELECT
TO authenticated
USING (user_id = (SELECT auth.uid()));

CREATE POLICY user_team_context_select_self
ON public.user_team_context
FOR SELECT
TO authenticated
USING (user_id = (SELECT auth.uid()));

DO $postflight$
DECLARE
  v_policy_count integer;
  v_fn text;
  v_acl text;
BEGIN
  SELECT pg_get_functiondef('public.is_club_admin(uuid)'::regprocedure)
  INTO v_fn;

  IF position('WHEN public.is_super_admin() THEN EXISTS' IN v_fn) = 0
     OR position('ctx.club_id = p_club_id' IN v_fn) = 0 THEN
    RAISE EXCEPTION 'Postflight: Superadmin-Kontextprüfung in is_club_admin fehlt';
  END IF;

  IF NOT (
    SELECT p.prosecdef
       AND pg_get_userbyid(p.proowner) = 'postgres'
       AND p.proconfig @> ARRAY['search_path=pg_catalog, public']
    FROM pg_proc p
    WHERE p.oid = 'public.is_club_admin(uuid)'::regprocedure
  ) THEN
    RAISE EXCEPTION 'Postflight: SECURITY DEFINER, Owner oder search_path unerwartet';
  END IF;

  SELECT p.proacl::text INTO v_acl
  FROM pg_proc p
  WHERE p.oid = 'public.is_club_admin(uuid)'::regprocedure;

  IF v_acl <> '{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}' THEN
    RAISE EXCEPTION 'Postflight: EXECUTE-ACL von is_club_admin wurde unerwartet verändert: %', v_acl;
  END IF;

  SELECT count(*) INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (
      (tablename = 'club_members' AND policyname = 'club_members_select_member_or_admin'
        AND qual LIKE '%is_club_admin%' AND qual NOT LIKE '%is_super_admin%')
      OR
      (tablename = 'club_member_roles' AND policyname = 'club_member_roles_select_member_or_admin'
        AND qual LIKE '%is_club_admin%' AND qual NOT LIKE '%is_super_admin%')
      OR
      (tablename = 'teams' AND policyname = 'teams_select_context_admin'
        AND qual LIKE '%can_manage_club_context%' AND qual NOT LIKE '%is_super_admin%')
      OR
      (tablename = 'user_club_context' AND policyname = 'user_club_context_select_self'
        AND qual LIKE '%auth.uid%')
      OR
      (tablename = 'user_team_context' AND policyname = 'user_team_context_select_self'
        AND qual LIKE '%auth.uid%')
    );

  IF v_policy_count <> 5 THEN
    RAISE EXCEPTION 'Postflight: nicht alle fünf RLS-Policies entsprechen dem Zielzustand';
  END IF;
END;
$postflight$;

COMMIT;
