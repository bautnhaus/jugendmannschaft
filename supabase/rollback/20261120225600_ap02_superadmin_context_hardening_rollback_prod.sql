-- AP02 PROD Rollback: stellt PROD-Funktionssemantik und direkte Vereinszuweisung wieder her.
-- Nur nach separater ausdrücklicher Rollback-Freigabe ausführen.
-- Die bereits vor AP02 gehärtete is_team_admin(uuid) bleibt unverändert.
-- Die vorhandene Superadmin-Teamrolle 'admin' wird nicht verändert.

BEGIN;

DO $preflight$
DECLARE
  v_user_id uuid;
  v_expected_team_roles text[];
  v_expected_team_memberships text[];
  v_actual_team_roles text[];
  v_actual_team_memberships text[];
BEGIN
  IF to_regclass('ap02_release_private.superadmin_membership_backup') IS NULL
     OR (SELECT count(*) FROM ap02_release_private.superadmin_membership_backup) <> 1 THEN
    RAISE EXCEPTION 'AP02 PROD Rollback: eindeutige Sicherungsdaten fehlen; Abbruch';
  END IF;

  SELECT user_id,team_roles,team_memberships
    INTO v_user_id,v_expected_team_roles,v_expected_team_memberships
  FROM ap02_release_private.superadmin_membership_backup;

  IF NOT EXISTS (SELECT 1 FROM public.global_user_roles WHERE user_id=v_user_id AND role='super_admin') THEN
    RAISE EXCEPTION 'AP02 PROD Rollback: globale Superadmin-Rolle hat sich geändert';
  END IF;
  IF EXISTS (SELECT 1 FROM public.club_members WHERE user_id=v_user_id) THEN
    RAISE EXCEPTION 'AP02 PROD Rollback: Vereinsmitgliedschaft wurde zwischenzeitlich neu angelegt';
  END IF;

  SELECT COALESCE(array_agg(r.team_id::text||':'||r.role ORDER BY r.team_id::text,r.role),ARRAY[]::text[])
    INTO v_actual_team_roles FROM public.team_member_roles r WHERE r.user_id=v_user_id;
  SELECT COALESCE(array_agg(r.team_id::text||':'||r.role ORDER BY r.team_id::text,r.role),ARRAY[]::text[])
    INTO v_actual_team_memberships FROM public.team_members r WHERE r.user_id=v_user_id;
  IF v_actual_team_roles IS DISTINCT FROM v_expected_team_roles
     OR v_actual_team_memberships IS DISTINCT FROM v_expected_team_memberships THEN
    RAISE EXCEPTION 'AP02 PROD Rollback: Teamrollen/-mitgliedschaften haben sich geändert; manueller Abgleich erforderlich';
  END IF;

  IF position('WHEN public.is_super_admin() THEN EXISTS' IN
       pg_get_functiondef('public.can_manage_club_context(uuid)'::regprocedure))=0
     OR position('OR EXISTS' IN
       pg_get_functiondef('public.can_manage_club_context(uuid)'::regprocedure))>0
     OR md5(pg_get_functiondef('public.is_team_admin(uuid)'::regprocedure))
       IS DISTINCT FROM 'f983aaebc7db5fcbb9284ffacc280b2c' THEN
    RAISE EXCEPTION 'AP02 PROD Rollback: zentrale Kontextfunktionen weichen vom AP02-Ausgangszustand ab';
  END IF;
END;
$preflight$;

INSERT INTO public.club_members(user_id,club_id)
SELECT user_id,club_id FROM ap02_release_private.superadmin_membership_backup;

INSERT INTO public.club_member_roles(user_id,role)
SELECT b.user_id,r.role
FROM ap02_release_private.superadmin_membership_backup b
CROSS JOIN LATERAL unnest(b.club_roles) AS r(role)
ON CONFLICT (user_id,role) DO NOTHING;

-- Ursprüngliche PROD-Semantik: Superadmin im ausgewählten Vereinskontext ODER regulärer club_admin.
CREATE OR REPLACE FUNCTION public.can_manage_club_context(p_club_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT auth.uid() IS NOT NULL
     AND (
       (
         public.is_super_admin()
         AND EXISTS (
           SELECT 1 FROM public.user_club_context ctx
           WHERE ctx.user_id=auth.uid() AND ctx.club_id=p_club_id
         )
       )
       OR EXISTS (
         SELECT 1
         FROM public.club_members cm
         JOIN public.club_member_roles cmr ON cmr.user_id=cm.user_id
         WHERE cm.user_id=auth.uid()
           AND cm.club_id=p_club_id
           AND cmr.role='club_admin'
       )
     );
$function$;

DO $restore_functions$
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
       'public.is_team_admin(p_team_id)',
       'public.is_team_admin(auth.uid(), p_team_id)'),
      ('public.admin_add_team_role(uuid,uuid,text)',
       'OR (NOT public.is_super_admin() AND v_club_id IS NOT NULL
               AND public.can_manage_club_context(v_club_id))',
       'OR (v_club_id IS NOT NULL
               AND public.can_manage_club_context(v_club_id))'),
      ('public.admin_remove_team_role(uuid,uuid,text)',
       'public.is_team_admin(p_team_id)',
       'public.is_team_admin(auth.uid(),p_team_id)'),
      ('public.admin_remove_team_role(uuid,uuid,text)',
       'or (NOT public.is_super_admin() AND v_club_id is not null and public.can_manage_club_context(v_club_id))',
       'or (v_club_id is not null and public.can_manage_club_context(v_club_id))'),
      ('public.admin_update_member_profile(uuid,uuid,text,text)',
       'public.is_team_admin(p_team_id)',
       'public.is_team_admin(auth.uid(), p_team_id)'),
      ('public.admin_set_trainer_label(uuid,text,text)',
       'public.is_team_admin(p_team_id)',
       'public.is_team_admin(auth.uid(), p_team_id)'),
      ('public.get_team_trainers(uuid)',
       'public.is_team_admin(p_team_id)',
       'public.is_team_admin(auth.uid(), p_team_id)'),
      ('public.get_team_trainers_v2(uuid)',
       'public.is_team_admin(p_team_id)',
       'public.is_team_admin(auth.uid(), p_team_id)'),
      ('public.get_team_role_change_log(uuid)',
       '(public.is_super_admin() AND public.has_selected_team_context(p_team_id))',
       'public.is_super_admin()')
    ) AS changes(signature,old_text,new_text)
  LOOP
    v_oid := to_regprocedure(v_sig);
    IF v_oid IS NULL THEN
      RAISE EXCEPTION 'AP02 PROD Rollback: Funktion % fehlt',v_sig;
    END IF;
    v_def := pg_get_functiondef(v_oid);
    IF position(v_old IN v_def)=0
       OR (length(v_def)-length(replace(v_def,v_old,'')))/length(v_old) <> 1 THEN
      RAISE EXCEPTION 'AP02 PROD Rollback: AP02-Ausdruck in % fehlt oder ist nicht eindeutig',v_sig;
    END IF;
    IF position(v_new IN v_def)>0 AND position(v_new IN v_old)=0 THEN
      RAISE EXCEPTION 'AP02 PROD Rollback: ursprünglicher Ausdruck in % ist bereits vorhanden',v_sig;
    END IF;
    EXECUTE replace(v_def,v_old,v_new);
    v_count := v_count + 1;
  END LOOP;

  IF v_count <> 9 THEN
    RAISE EXCEPTION 'AP02 PROD Rollback: erwartet neun Funktionswiederherstellungen, ausgeführt %',v_count;
  END IF;
END;
$restore_functions$;

DO $postflight$
DECLARE
  v_user_id uuid;
  v_club_id uuid;
  v_expected_club_roles text[];
  v_actual_club_roles text[];
BEGIN
  SELECT user_id,club_id,club_roles
    INTO v_user_id,v_club_id,v_expected_club_roles
  FROM ap02_release_private.superadmin_membership_backup;

  IF NOT EXISTS (SELECT 1 FROM public.club_members WHERE user_id=v_user_id AND club_id=v_club_id) THEN
    RAISE EXCEPTION 'AP02 PROD Rollback: Vereinsmitgliedschaft nicht wiederhergestellt';
  END IF;
  SELECT COALESCE(array_agg(role ORDER BY role),ARRAY[]::text[])
    INTO v_actual_club_roles FROM public.club_member_roles WHERE user_id=v_user_id;
  IF v_actual_club_roles IS DISTINCT FROM v_expected_club_roles THEN
    RAISE EXCEPTION 'AP02 PROD Rollback: Vereinsrollen weichen vom Snapshot ab';
  END IF;
END;
$postflight$;

DROP SCHEMA ap02_release_private CASCADE;

COMMIT;
