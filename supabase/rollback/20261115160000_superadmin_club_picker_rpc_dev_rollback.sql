-- Rollback for DB-MIG-2026-024 (DEV only).
-- Drops only the function introduced by the matching migration.

begin;

do $preflight$
begin
  if to_regprocedure('public.get_super_admin_clubs()') is null then
    raise exception 'Rollback preflight: get_super_admin_clubs() does not exist';
  end if;

  if not (
    select prosecdef
       and proowner='postgres'::regrole
       and proconfig @> array['search_path=pg_catalog, public']
    from pg_proc
    where oid='public.get_super_admin_clubs()'::regprocedure
  ) then
    raise exception 'Rollback preflight: function no longer matches the migration security attributes';
  end if;
end;
$preflight$;

drop function public.get_super_admin_clubs();

commit;
