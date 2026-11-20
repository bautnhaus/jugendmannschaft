-- AP02 Rollback: stellt Funktionsdefinitionen und direkte Vereinszuweisung wieder her.
-- Nur nach separater ausdrücklicher Rollback-Freigabe ausführen.
-- Teamrollen werden nicht verändert.

BEGIN;

DO $preflight$
DECLARE
  v_user_id uuid;
BEGIN
  IF to_regclass('ap02_release_private.superadmin_membership_backup') IS NULL THEN
    RAISE EXCEPTION 'AP02 Rollback: gesicherte Ausgangsdaten fehlen; Abbruch';
  END IF;
  IF (SELECT count(*) FROM ap02_release_private.superadmin_membership_backup) <> 1 THEN
    RAISE EXCEPTION 'AP02 Rollback: Sicherungsbestand ist nicht eindeutig';
  END IF;
  SELECT user_id INTO v_user_id
  FROM ap02_release_private.superadmin_membership_backup;

  IF EXISTS (SELECT 1 FROM public.club_members WHERE user_id=v_user_id) THEN
    RAISE EXCEPTION 'AP02 Rollback: Vereinsmitgliedschaft wurde zwischenzeitlich neu angelegt; manueller Abgleich erforderlich';
  END IF;
  IF position('CASE WHEN public.is_super_admin()' IN
       pg_get_functiondef('public.can_manage_club_context(uuid)'::regprocedure))=0 THEN
    RAISE EXCEPTION 'AP02 Rollback: zentrale Funktion entspricht nicht dem erwarteten AP02-Stand';
  END IF;
END;
$preflight$;

-- Exakte Vereinszuweisung aus dem gesicherten Snapshot wiederherstellen.
INSERT INTO public.club_members(user_id,club_id)
SELECT user_id,club_id
FROM ap02_release_private.superadmin_membership_backup;

INSERT INTO public.club_member_roles(user_id,role)
SELECT b.user_id,roles.role
FROM ap02_release_private.superadmin_membership_backup b
CROSS JOIN LATERAL unnest(b.club_roles) AS roles(role)
ON CONFLICT (user_id,role) DO NOTHING;

-- Vorherige can_manage_club_context-Semantik wiederherstellen.
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
      ('public.admin_remove_team_role(uuid,uuid,text)',
       'public.is_team_admin(p_team_id)',
       'public.is_team_admin(auth.uid(),p_team_id)'),
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
      RAISE EXCEPTION 'AP02 Rollback: Funktion % fehlt',v_sig;
    END IF;
    v_def := pg_get_functiondef(v_oid);
    IF position(v_old IN v_def)=0 THEN
      RAISE EXCEPTION 'AP02 Rollback: erwarteter AP02-Ausdruck in % fehlt',v_sig;
    END IF;
    EXECUTE replace(v_def,v_old,v_new);
    v_count := v_count + 1;
  END LOOP;
  IF v_count <> 7 THEN
    RAISE EXCEPTION 'AP02 Rollback: erwartete sieben Funktionswiederherstellungen, ausgeführt %',v_count;
  END IF;
END;
$restore_functions$;

DO $postflight$
DECLARE
  v_user_id uuid;
  v_club_id uuid;
BEGIN
  SELECT user_id,club_id INTO v_user_id,v_club_id
  FROM ap02_release_private.superadmin_membership_backup;

  IF NOT EXISTS (
    SELECT 1 FROM public.club_members
    WHERE user_id=v_user_id AND club_id=v_club_id
  ) THEN
    RAISE EXCEPTION 'AP02 Rollback Postflight: Vereinsmitgliedschaft wurde nicht wiederhergestellt';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.club_member_roles
    WHERE user_id=v_user_id AND role='club_admin'
  ) THEN
    RAISE EXCEPTION 'AP02 Rollback Postflight: club_admin-Rolle wurde nicht wiederhergestellt';
  END IF;
END;
$postflight$;

DROP SCHEMA ap02_release_private CASCADE;

COMMIT;
