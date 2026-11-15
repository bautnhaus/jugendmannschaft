-- Rollback DB-MIG-2026-026: remove only the RPC introduced by this migration.
-- Scope: Supabase PROD only. No existing policy/function/data is restored or changed.

BEGIN;

DO $guard$
BEGIN
  IF to_regprocedure('public.get_super_admin_clubs()') IS NULL THEN
    RAISE EXCEPTION 'Rollback guard: get_super_admin_clubs() is absent';
  END IF;

  IF NOT (
    SELECT p.prosecdef
       AND pg_get_userbyid(p.proowner) = 'postgres'
       AND p.proconfig @> ARRAY['search_path=pg_catalog, public']
    FROM pg_proc p
    WHERE p.oid = 'public.get_super_admin_clubs()'::regprocedure
  ) THEN
    RAISE EXCEPTION 'Rollback guard: function security attributes differ; refusing to drop';
  END IF;
END;
$guard$;

DROP FUNCTION public.get_super_admin_clubs();

COMMIT;
