-- DB-MIG-2026-026: Secure Superadmin club picker RPC (PROD)
-- Scope: Supabase PROD only.
-- Adds the narrowly scoped RPC required by the develop frontend.
-- No table, data, existing function, RLS, trigger or storage changes.

BEGIN;

DO $preflight$
DECLARE
  v_policy text;
BEGIN
  IF to_regprocedure('public.get_super_admin_clubs()') IS NOT NULL THEN
    RAISE EXCEPTION 'Preflight: get_super_admin_clubs() already exists; stop and review';
  END IF;

  IF md5(pg_get_functiondef('public.is_super_admin()'::regprocedure))
       IS DISTINCT FROM 'cffa76d7f45b67cb7c7add371df764bd' THEN
    RAISE EXCEPTION 'Preflight: PROD is_super_admin() differs from the reviewed definition';
  END IF;

  IF NOT (
    SELECT p.prosecdef
       AND pg_get_userbyid(p.proowner) = 'postgres'
       AND p.proconfig @> ARRAY['search_path=pg_catalog, public']
    FROM pg_proc p
    WHERE p.oid = 'public.is_super_admin()'::regprocedure
  ) THEN
    RAISE EXCEPTION 'Preflight: is_super_admin() security attributes differ';
  END IF;

  SELECT qual INTO v_policy
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'clubs'
    AND policyname = 'clubs_select_member_or_superadmin'
    AND cmd = 'SELECT'
    AND roles = ARRAY['authenticated']::name[];

  IF v_policy IS NULL
     OR md5(v_policy) IS DISTINCT FROM '9640c9290a5e2d7f17af970b6fd161a0' THEN
    RAISE EXCEPTION 'Preflight: clubs SELECT policy is not the reviewed context-bound policy';
  END IF;

  IF (SELECT count(*) FROM pg_policies
      WHERE schemaname='public' AND tablename='clubs' AND cmd='SELECT') <> 1 THEN
    RAISE EXCEPTION 'Preflight: unexpected additional clubs SELECT policies';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='clubs'
      AND column_name='id' AND data_type='uuid'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='clubs'
      AND column_name='name' AND data_type='text'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='clubs'
      AND column_name='short_name' AND data_type='text'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='clubs'
      AND column_name='crest_path' AND data_type='text'
  ) THEN
    RAISE EXCEPTION 'Preflight: required clubs columns are missing or have unexpected types';
  END IF;
END;
$preflight$;

CREATE FUNCTION public.get_super_admin_clubs()
RETURNS TABLE (
  id uuid,
  name text,
  short_name text,
  crest_path text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
  SELECT c.id, c.name, c.short_name, c.crest_path
  FROM public.clubs AS c
  WHERE auth.uid() IS NOT NULL
    AND public.is_super_admin()
  ORDER BY c.name;
$function$;

REVOKE ALL ON FUNCTION public.get_super_admin_clubs() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_super_admin_clubs() FROM anon;
GRANT EXECUTE ON FUNCTION public.get_super_admin_clubs() TO authenticated;

DO $postflight$
BEGIN
  IF NOT (
    SELECT p.prosecdef
       AND pg_get_userbyid(p.proowner) = 'postgres'
       AND p.proconfig @> ARRAY['search_path=pg_catalog, public']
    FROM pg_proc p
    WHERE p.oid = 'public.get_super_admin_clubs()'::regprocedure
  ) THEN
    RAISE EXCEPTION 'Postflight: SECURITY DEFINER, owner or fixed search_path is unexpected';
  END IF;

  IF NOT has_function_privilege('authenticated','public.get_super_admin_clubs()'::regprocedure,'EXECUTE')
     OR has_function_privilege('anon','public.get_super_admin_clubs()'::regprocedure,'EXECUTE')
     OR EXISTS (
       SELECT 1
       FROM pg_proc p, LATERAL aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
       WHERE p.oid = 'public.get_super_admin_clubs()'::regprocedure
         AND a.grantee = 0
         AND a.privilege_type = 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Postflight: unexpected EXECUTE grants';
  END IF;

  IF (SELECT count(*) FROM pg_policies
      WHERE schemaname='public' AND tablename='clubs' AND cmd='SELECT') <> 1 THEN
    RAISE EXCEPTION 'Postflight: clubs RLS policy count changed unexpectedly';
  END IF;
END;
$postflight$;

COMMIT;
