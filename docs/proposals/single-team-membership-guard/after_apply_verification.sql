-- READ-ONLY VERIFIKATION NACH EINER SEPARAT FREIGEGEBENEN DEV-AUSFÜHRUNG.
-- Dieses Skript ändert keine Daten oder Schemaobjekte.
--
-- Fachliche Leitlinie:
--   * Höchstens eine tatsächliche Teammitgliedschaft pro Benutzer.
--   * Superadmin und Vereinsadmin dürfen zusätzlich echte Mitgliedschaften
--     und Teamrollen besitzen.
--   * Verwaltungsrechte in weiteren Teams werden über den ausgewählten
--     Vereins-/Teamkontext geprüft und benötigen dort keine Mitgliedschaft.

-- 1) Neue Trigger und Aktivstatus.
SELECT
    n.nspname AS schema_name,
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
--    Die beiden Tabellen werden zusammen betrachtet; eine doppelte
--    Darstellung derselben Mannschaft zählt als eine Zuordnung.
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

-- 4) Superadmins mit tatsächlicher Mannschaftsmitgliedschaft.
--    Dieser Wert ist ausdrücklich nur informativ und darf größer als 0 sein.
SELECT count(DISTINCT gur.user_id) AS superadmins_with_team_membership
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

-- 5) Kein alter Gegentrigger zur Superadmin-Hochstufung darf bestehen.
SELECT count(*) AS obsolete_superadmin_team_triggers
FROM pg_trigger AS t
JOIN pg_class AS c ON c.oid = t.tgrelid
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND t.tgname = 'global_user_roles_no_team_assignment'
  AND NOT t.tgisinternal;
-- Erwartung: 0.

-- 6) Relevante Indizes.
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('team_members', 'team_member_roles')
ORDER BY tablename, indexname;

-- 7) Relevante Funktionsdefinitionen und Kontextprüfungen.
--    Die Definitionen müssen zeigen:
--      a) Team-Zielperson wird auf vorhandene andere Mannschaft geprüft.
--      b) Superadmin wird NICHT als Zielperson abgewiesen.
--      c) Superadmin/Vereinsadmin als Handelnde verwenden den ausgewählten
--         Vereins-/Teamkontext, ohne Teammitgliedschaft in jeder Mannschaft.
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
      'enforce_single_team_membership',
      'admin_add_team_role',
      'admin_create_team',
      'admin_list_team_admin_candidates',
      'admin_complete_member_invitation',
      'can_manage_club_context',
      'has_selected_team_context',
      'is_team_admin',
      'is_super_admin'
  )
ORDER BY p.proname, arguments;

-- 8) Die globale Superadmin-Rolle bleibt eine eigenständige Rolle.
--    Für authenticated sind auf global_user_roles weiterhin keine
--    direkten Schreibrechte vorgesehen.
SELECT
    has_table_privilege('authenticated','public.global_user_roles','INSERT') AS auth_insert,
    has_table_privilege('authenticated','public.global_user_roles','UPDATE') AS auth_update,
    has_table_privilege('authenticated','public.global_user_roles','DELETE') AS auth_delete;
