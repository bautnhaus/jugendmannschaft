-- READ-ONLY VERIFIKATION NACH EINER SEPARAT FREIGEGEBENEN DEV-AUSFÜHRUNG.
-- Dieses Skript ändert keine Daten oder Schemaobjekte.

-- 1) Neue Trigger und Aktivstatus.
SELECT
    c.relname AS table_name,
    t.tgname AS trigger_name,
    t.tgenabled AS enabled_code,
    pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger AS t
JOIN pg_class AS c ON c.oid = t.tgrelid
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND t.tgname IN (
      'team_members_single_team_guard',
      'team_member_roles_single_team_guard'
  )
  AND NOT t.tgisinternal
ORDER BY c.relname, t.tgname;

-- 2) Triggerfunktion: SECURITY DEFINER, fester Suchpfad und keine
--    EXECUTE-Freigabe für anon/authenticated.
SELECT
    p.prosecdef AS security_definer,
    p.proconfig AS function_settings,
    has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_can_execute,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_can_execute
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'enforce_single_team_membership'
  AND pg_get_function_identity_arguments(p.oid) = '';

-- 3) Benutzer mit mehr als einer Mannschaftszuordnung (Erwartung: 0).
SELECT count(*) AS users_in_multiple_teams
FROM (
    SELECT assignments.user_id
    FROM (
        SELECT user_id, team_id FROM public.team_members
        UNION
        SELECT user_id, team_id FROM public.team_member_roles
    ) AS assignments
    GROUP BY assignments.user_id
    HAVING count(DISTINCT assignments.team_id) > 1
) AS conflicts;

-- 4) Superadmins mit Mannschaftszuordnung (Erwartung: 0).
SELECT count(DISTINCT gur.user_id) AS super_admins_with_team_assignment
FROM public.global_user_roles AS gur
WHERE gur.role = 'super_admin'
  AND (
      EXISTS (
          SELECT 1 FROM public.team_members AS tm
          WHERE tm.user_id = gur.user_id
      )
      OR EXISTS (
          SELECT 1 FROM public.team_member_roles AS tmr
          WHERE tmr.user_id = gur.user_id
      )
  );

-- 5) Relevante Indizes.
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('team_members', 'team_member_roles')
ORDER BY tablename, indexname;

-- 6) Funktionale Definitionen der geänderten RPCs.
SELECT
    p.proname,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    p.prosecdef,
    p.proconfig,
    pg_get_functiondef(p.oid) AS definition
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
      'admin_add_team_role',
      'admin_create_team',
      'admin_list_team_admin_candidates'
  )
ORDER BY p.proname, arguments;
