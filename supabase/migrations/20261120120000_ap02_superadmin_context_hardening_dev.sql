-- AP02: Superadmin-Kontextkorrektur und reversible Neutralisierung der direkten Vereinszuweisung.
-- Ziel: zunächst DEV; nicht ausführen, bevor separate DEV-Ausführungsfreigabe vorliegt.
-- Erstellt aus dem read-only PROD-Livebestand vom 20.11.2026.
-- Die Teamrollen des Superadmins werden NICHT verändert.
-- Die direkte Vereinsmitgliedschaft wird vor dem Entfernen in einem gesperrten
-- Backup-Schema gesichert. club_member_roles wird per FK ON DELETE CASCADE entfernt.

BEGIN;

DO $preflight$
DECLARE
  v_superadmins integer;
  v_memberships integer;
  v_club_admin_roles integer;
  v_team_roles integer;
  v_team_members integer;
BEGIN
  IF to_regprocedure('public.can_manage_club_context(uuid)') IS NULL
     OR to_regprocedure('public.has_selected_team_context(uuid)') IS NULL
     OR to_regprocedure('public.is_team_admin(uuid)') IS NULL
     OR to_regprocedure('public.is_super_admin()') IS NULL THEN
    RAISE EXCEPTION 'AP02 Preflight: erforderliche Kontextfunktionen fehlen';
  END IF;

  IF md5(pg_get_functiondef('public.is_team_admin(uuid)'::regprocedure))
       IS DISTINCT FROM '466701a808244b3fe9a14b91bda17af0'
     OR md5(pg_get_functiondef('public.can_manage_club_context(uuid)'::regprocedure))
       IS DISTINCT FROM '40b864bf0cee883fbe9a5f37c675bfaa' THEN
    RAISE EXCEPTION 'AP02 Preflight: zentrale Kontextfunktionen weichen vom geprüften DEV-Ausgangsstand ab';
  END IF;

  IF (
    SELECT count(*) FROM pg_constraint
    WHERE contype='f'
      AND confrelid='public.club_members'::regclass
  ) <> 1
  OR NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE contype='f'
      AND conrelid='public.club_member_roles'::regclass
      AND confrelid='public.club_members'::regclass
      AND pg_get_constraintdef(oid) ILIKE '%ON DELETE CASCADE%'
  ) THEN
    RAISE EXCEPTION 'AP02 Preflight: FK-Struktur von club_members weicht vom geprüften DEV-Ausgangsstand ab';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_trigger t
    JOIN pg_class c ON c.oid=t.tgrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public'
      AND c.relname IN ('club_members','club_member_roles')
      AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'AP02 Preflight: unerwarteter benutzerdefinierter Trigger auf Vereinsmitgliedschaftstabellen';
  END IF;

  SELECT count(*) INTO v_superadmins
  FROM public.global_user_roles WHERE role='super_admin';
  IF v_superadmins <> 1 THEN
    RAISE EXCEPTION 'AP02 Preflight: erwartet genau einen Superadmin, gefunden %',v_superadmins;
  END IF;

  SELECT count(*) INTO v_memberships
  FROM public.club_members cm
  JOIN public.global_user_roles g ON g.user_id=cm.user_id AND g.role='super_admin';
  IF v_memberships <> 1 THEN
    RAISE EXCEPTION 'AP02 Preflight: erwartet genau eine direkte Superadmin-Vereinsmitgliedschaft, gefunden %',v_memberships;
  END IF;

  SELECT count(*) INTO v_club_admin_roles
  FROM public.club_member_roles r
  JOIN public.global_user_roles g ON g.user_id=r.user_id AND g.role='super_admin'
  WHERE r.role='club_admin';
  IF v_club_admin_roles <> 1 THEN
    RAISE EXCEPTION 'AP02 Preflight: erwartet genau eine Superadmin-club_admin-Rolle, gefunden %',v_club_admin_roles;
  END IF;

  SELECT count(*) INTO v_team_roles
  FROM public.team_member_roles r
  JOIN public.global_user_roles g ON g.user_id=r.user_id AND g.role='super_admin';
  SELECT count(*) INTO v_team_members
  FROM public.team_members r
  JOIN public.global_user_roles g ON g.user_id=r.user_id AND g.role='super_admin';

  IF v_team_roles < 1 OR v_team_members < 1 THEN
    RAISE EXCEPTION 'AP02 Preflight: erwartete bestehende Teamzuordnung fehlt; keine Bereinigung';
  END IF;

  IF to_regnamespace('ap02_release_private') IS NOT NULL THEN
    RAISE EXCEPTION 'AP02 Preflight: Backup-Schema ap02_release_private existiert bereits; manueller Abgleich erforderlich';
  END IF;
END;
$preflight$;

-- Zentraler Fix: Superadmin wird ausschließlich über den explizit gewählten
-- Vereinskontext autorisiert. Nur Nicht-Superadmins verwenden club_admin-Rollen.
CREATE OR REPLACE FUNCTION public.can_manage_club_context(p_club_id uuid)
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
         FROM public.club_members cm
         JOIN public.club_member_roles cmr
           ON cmr.user_id = cm.user_id
         WHERE cm.user_id = auth.uid()
           AND cm.club_id = p_club_id
           AND cmr.role = 'club_admin'
       )
     END;
$function$;

-- Die Zwei-Argument-Rollenfunktion bleibt eine allgemeine Abfrage über
-- Zielbenutzerrollen. Verwaltungs-RPCs müssen stattdessen die Ein-Argument-
-- Funktion auf den handelnden Benutzer anwenden; diese erzwingt für
-- Superadmins den ausgewählten Teamkontext.
CREATE OR REPLACE FUNCTION public.is_team_admin(p_team_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT auth.uid() IS NOT NULL
     AND CASE
       WHEN public.is_super_admin()
         THEN public.has_selected_team_context(p_team_id)
       ELSE EXISTS (
         SELECT 1
         FROM public.team_member_roles r
         WHERE r.team_id = p_team_id
           AND r.user_id = auth.uid()
           AND r.role = 'admin'
       )
     END;
$function$;

DO $function_hardening$
DECLARE
  v_sig text;
  v_old text;
  v_new text;
  v_oid regprocedure;
  v_def text;
  v_count integer := 0;
BEGIN
  FOR v_sig,v_old,v_new IN
    SELECT * FROM (VALUES
      ('public.admin_add_team_role(uuid,uuid,text)',
       'public.is_team_admin(auth.uid(), p_team_id)',
       'public.is_team_admin(p_team_id)'),
      ('public.admin_add_team_role(uuid,uuid,text)',
       'OR (v_club_id IS NOT NULL
               AND public.can_manage_club_context(v_club_id))',
       'OR (NOT public.is_super_admin() AND v_club_id IS NOT NULL
               AND public.can_manage_club_context(v_club_id))'),
      ('public.admin_remove_team_role(uuid,uuid,text)',
       'public.is_team_admin(auth.uid(),p_team_id)',
       'public.is_team_admin(p_team_id)'),
      ('public.admin_remove_team_role(uuid,uuid,text)',
       'or (v_club_id is not null and public.can_manage_club_context(v_club_id))',
       'or (NOT public.is_super_admin() AND v_club_id is not null and public.can_manage_club_context(v_club_id))'),
      ('public.admin_update_member_profile(uuid,uuid,text,text)',
       'public.is_team_admin(auth.uid(), p_team_id)',
       'public.is_team_admin(p_team_id)'),
      ('public.admin_set_trainer_label(uuid,text,text)',
       'public.is_team_admin(auth.uid(),p_team_id)',
       'public.is_team_admin(p_team_id)'),
      ('public.get_team_trainers(uuid)',
       'public.is_team_admin(auth.uid(), p_team_id)',
       'public.is_team_admin(p_team_id)'),
      ('public.get_team_trainers_v2(uuid)',
       'public.is_team_admin(auth.uid(),p_team_id)',
       'public.is_team_admin(p_team_id)'),
      ('public.get_team_role_change_log(uuid)',
       'public.is_super_admin()',
       '(public.is_super_admin() AND public.has_selected_team_context(p_team_id))')
    ) AS changes(signature,old_text,new_text)
  LOOP
    v_oid := to_regprocedure(v_sig);
    IF v_oid IS NULL THEN
      RAISE EXCEPTION 'AP02 Preflight: erwartete Funktion % fehlt',v_sig;
    END IF;
    v_def := pg_get_functiondef(v_oid);
    IF position(v_old IN v_def)=0 THEN
      RAISE EXCEPTION 'AP02 Preflight: erwarteter alter Berechtigungsaufruf in % nicht gefunden',v_sig;
    END IF;
    IF position(v_new IN v_def)>0 THEN
      RAISE EXCEPTION 'AP02 Preflight: % enthält bereits den Zielaufruf; manueller Abgleich erforderlich',v_sig;
    END IF;
    EXECUTE replace(v_def,v_old,v_new);
    v_count := v_count + 1;
  END LOOP;

  IF v_count <> 9 THEN
    RAISE EXCEPTION 'AP02: erwartet neun gezielte Berechtigungsersetzungen, ausgeführt %',v_count;
  END IF;
END;
$function_hardening$;

-- Reversible Sicherung der direkten Vereinszuweisung und der unveränderten
-- Teamrollen. Das Schema ist für Clientrollen vollständig gesperrt.
CREATE SCHEMA ap02_release_private;
REVOKE ALL ON SCHEMA ap02_release_private FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE ap02_release_private.superadmin_membership_backup (
  user_id uuid PRIMARY KEY,
  club_id uuid NOT NULL,
  club_roles text[] NOT NULL,
  team_roles text[] NOT NULL,
  team_memberships text[] NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE ap02_release_private.superadmin_membership_backup ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE ap02_release_private.superadmin_membership_backup
  FROM PUBLIC, anon, authenticated, service_role;

INSERT INTO ap02_release_private.superadmin_membership_backup
  (user_id,club_id,club_roles,team_roles,team_memberships)
SELECT
  g.user_id,
  cm.club_id,
  COALESCE((
    SELECT array_agg(r.role ORDER BY r.role)
    FROM public.club_member_roles r WHERE r.user_id=g.user_id
  ),ARRAY[]::text[]),
  COALESCE((
    SELECT array_agg(r.team_id::text||':'||r.role ORDER BY r.team_id::text,r.role)
    FROM public.team_member_roles r WHERE r.user_id=g.user_id
  ),ARRAY[]::text[]),
  COALESCE((
    SELECT array_agg(r.team_id::text||':'||r.role ORDER BY r.team_id::text,r.role)
    FROM public.team_members r WHERE r.user_id=g.user_id
  ),ARRAY[]::text[])
FROM public.global_user_roles g
JOIN public.club_members cm ON cm.user_id=g.user_id
WHERE g.role='super_admin';

DO $backup_check$
BEGIN
  IF (SELECT count(*) FROM ap02_release_private.superadmin_membership_backup) <> 1 THEN
    RAISE EXCEPTION 'AP02: Sicherung der Superadmin-Vereinszuweisung ist nicht eindeutig';
  END IF;
  IF has_schema_privilege('authenticated','ap02_release_private','USAGE')
     OR has_schema_privilege('anon','ap02_release_private','USAGE')
     OR has_table_privilege('authenticated','ap02_release_private.superadmin_membership_backup','SELECT')
     OR has_table_privilege('anon','ap02_release_private.superadmin_membership_backup','SELECT') THEN
    RAISE EXCEPTION 'AP02: Backup-Schema oder -Tabelle ist für Clientrollen erreichbar';
  END IF;
END;
$backup_check$;

-- Nur die direkte Vereinsmitgliedschaft entfernen. Die Vereinsrolle wird
-- ausschließlich durch den dokumentierten ON DELETE CASCADE-FK entfernt.
-- team_members und team_member_roles werden ausdrücklich nicht verändert.
DELETE FROM public.club_members cm
USING public.global_user_roles g
WHERE cm.user_id=g.user_id
  AND g.role='super_admin';

DO $postflight$
DECLARE
  v_user_id uuid;
  v_expected_team_roles text[];
  v_expected_team_memberships text[];
  v_actual_team_roles text[];
  v_actual_team_memberships text[];
BEGIN
  SELECT user_id,team_roles,team_memberships
    INTO v_user_id,v_expected_team_roles,v_expected_team_memberships
  FROM ap02_release_private.superadmin_membership_backup;

  IF EXISTS (SELECT 1 FROM public.club_members WHERE user_id=v_user_id)
     OR EXISTS (SELECT 1 FROM public.club_member_roles WHERE user_id=v_user_id) THEN
    RAISE EXCEPTION 'AP02 Postflight: direkte Vereinsmitgliedschaft oder Vereinsrolle besteht weiterhin';
  END IF;

  SELECT COALESCE(array_agg(r.team_id::text||':'||r.role ORDER BY r.team_id::text,r.role),ARRAY[]::text[])
    INTO v_actual_team_roles
  FROM public.team_member_roles r WHERE r.user_id=v_user_id;

  SELECT COALESCE(array_agg(r.team_id::text||':'||r.role ORDER BY r.team_id::text,r.role),ARRAY[]::text[])
    INTO v_actual_team_memberships
  FROM public.team_members r WHERE r.user_id=v_user_id;

  IF v_actual_team_roles IS DISTINCT FROM v_expected_team_roles
     OR v_actual_team_memberships IS DISTINCT FROM v_expected_team_memberships THEN
    RAISE EXCEPTION 'AP02 Postflight: Teamrollen oder Teammitgliedschaften wurden unerwartet verändert';
  END IF;

  IF position('WHEN public.is_super_admin()' IN
       pg_get_functiondef('public.is_team_admin(uuid)'::regprocedure))=0
     OR position('public.has_selected_team_context(p_team_id)' IN
       pg_get_functiondef('public.is_team_admin(uuid)'::regprocedure))=0 THEN
    RAISE EXCEPTION 'AP02 Postflight: Superadmin-Kontext hat in is_team_admin Vorrang';
  END IF;

  IF position('WHEN public.is_super_admin() THEN EXISTS' IN
       pg_get_functiondef('public.can_manage_club_context(uuid)'::regprocedure))=0 THEN
    RAISE EXCEPTION 'AP02 Postflight: zentrale Superadmin-Kontextpriorität fehlt';
  END IF;

  IF position('OR EXISTS' IN pg_get_functiondef('public.can_manage_club_context(uuid)'::regprocedure))>0 THEN
    RAISE EXCEPTION 'AP02 Postflight: alter paralleler Rollen-Bypass ist noch vorhanden';
  END IF;

  IF position('NOT public.is_super_admin()' IN
       pg_get_functiondef('public.admin_add_team_role(uuid,uuid,text)'::regprocedure))=0
     OR position('NOT public.is_super_admin()' IN
       pg_get_functiondef('public.admin_remove_team_role(uuid,uuid,text)'::regprocedure))=0 THEN
    RAISE EXCEPTION 'AP02 Postflight: Vereinskontext darf Superadmin-Teamrolle nicht umgehen';
  END IF;

  IF position('public.is_super_admin() AND public.has_selected_team_context(p_team_id)'
       IN pg_get_functiondef('public.get_team_role_change_log(uuid)'::regprocedure))=0 THEN
    RAISE EXCEPTION 'AP02 Postflight: Rollenhistorie ist nicht teamkontextgebunden';
  END IF;
END;
$postflight$;

COMMIT;
