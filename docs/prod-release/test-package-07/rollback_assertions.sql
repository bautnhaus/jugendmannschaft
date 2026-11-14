\set ON_ERROR_STOP on
DO $$
BEGIN
  IF to_regclass('public.team_season_closure_audit') IS NOT NULL THEN RAISE EXCEPTION 'closure audit table remains after rollback'; END IF;
  IF to_regprocedure('public.close_team_season(uuid,text)') IS NOT NULL THEN RAISE EXCEPTION 'close RPC remains after rollback'; END IF;
  IF to_regprocedure('public.e05_reject_season_closure_audit_mutation()') IS NOT NULL THEN RAISE EXCEPTION 'trigger function remains after rollback'; END IF;
END $$;
