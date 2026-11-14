\set ON_ERROR_STOP on
DO $$
DECLARE
  v_count integer;
BEGIN
  IF to_regclass('public.team_season_closure_audit') IS NULL THEN RAISE EXCEPTION 'closure audit table missing'; END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.team_season_closure_audit'::regclass) THEN RAISE EXCEPTION 'RLS disabled'; END IF;
  IF to_regprocedure('public.close_team_season(uuid,text)') IS NULL THEN RAISE EXCEPTION 'close RPC missing'; END IF;
  IF to_regprocedure('public.e05_reject_season_closure_audit_mutation()') IS NULL THEN RAISE EXCEPTION 'append-only trigger function missing'; END IF;
  IF NOT has_function_privilege('authenticated','public.close_team_season(uuid,text)','EXECUTE') THEN RAISE EXCEPTION 'authenticated cannot execute close RPC'; END IF;
  IF has_function_privilege('anon','public.close_team_season(uuid,text)','EXECUTE') THEN RAISE EXCEPTION 'anon can execute close RPC'; END IF;
  IF has_table_privilege('authenticated','public.team_season_closure_audit','INSERT')
     OR has_table_privilege('authenticated','public.team_season_closure_audit','UPDATE')
     OR has_table_privilege('authenticated','public.team_season_closure_audit','DELETE') THEN RAISE EXCEPTION 'authenticated has direct write privilege'; END IF;
  IF has_table_privilege('anon','public.team_season_closure_audit','SELECT') THEN RAISE EXCEPTION 'anon can read closure audit'; END IF;
  SELECT count(*) INTO v_count FROM pg_policies WHERE schemaname='public' AND tablename='team_season_closure_audit' AND policyname='team_season_closure_audit_select_team' AND cmd='SELECT' AND qual LIKE '%is_team_member%' AND qual LIKE '%has_selected_team_context%';
  IF v_count<>1 THEN RAISE EXCEPTION 'final team-context select policy missing'; END IF;
  SELECT count(*) INTO v_count FROM pg_trigger WHERE tgrelid='public.team_season_closure_audit'::regclass AND tgname='team_season_closure_audit_no_mutation' AND NOT tgisinternal;
  IF v_count<>1 THEN RAISE EXCEPTION 'append-only trigger missing'; END IF;
END $$;
