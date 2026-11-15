-- AP03 PROD rollback: restore the exact reviewed pre-migration behavior.
-- This intentionally restores the unconditional Superadmin team-list branch
-- and removes the pinned search_path. Use only after an explicit rollback decision.

BEGIN;

DO $preflight$
DECLARE
  v_qual text;
  v_acl text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    WHERE p.oid='public.set_updated_at()'::regprocedure
      AND p.proconfig @> ARRAY['search_path=pg_catalog, public']
      AND NOT p.prosecdef
  ) THEN
    RAISE EXCEPTION 'Rollback preflight: hardened set_updated_at() not found';
  END IF;

  SELECT qual INTO v_qual
  FROM pg_policies
  WHERE schemaname='public' AND tablename='teams'
    AND policyname='teams_select_context_admin';

  IF v_qual IS NULL
     OR v_qual NOT LIKE '%can_manage_club_context%'
     OR v_qual LIKE '%is_super_admin%' THEN
    RAISE EXCEPTION 'Rollback preflight: expected hardened teams policy not found';
  END IF;

  SELECT p.proacl::text INTO v_acl
  FROM pg_proc p
  WHERE p.oid='public.set_updated_at()'::regprocedure;

  IF v_acl <> '{=X/postgres,postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}' THEN
    RAISE EXCEPTION 'Rollback preflight: unexpected set_updated_at ACL: %',v_acl;
  END IF;
END;
$preflight$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

DROP POLICY teams_select_context_admin ON public.teams;
CREATE POLICY teams_select_context_admin
ON public.teams
FOR SELECT
TO authenticated
USING (
  (EXISTS (
    SELECT 1
    FROM public.global_user_roles gur
    WHERE gur.user_id = auth.uid()
      AND gur.role = 'super_admin'
  ))
  OR (EXISTS (
    SELECT 1
    FROM public.club_members cm
    JOIN public.club_member_roles cmr
      ON cmr.user_id = cm.user_id
    WHERE cm.user_id = auth.uid()
      AND cm.club_id = teams.club_id
      AND cmr.role = 'club_admin'
  ))
);

COMMIT;
