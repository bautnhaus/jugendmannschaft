-- DB-MIG-2026-024: Secure superadmin club picker RPC (DEV only)
-- Purpose: let a neutral platform superadmin load the club picker without
-- granting broad SELECT access to public.clubs.
-- Returns only id, name, short_name and crest_path.
-- No table, data, RLS policy, trigger, storage or existing function changes.

begin;

do $preflight$
begin
  if to_regprocedure('public.get_super_admin_clubs()') is not null then
    raise exception 'Preflight: get_super_admin_clubs() already exists; review before applying';
  end if;

  if to_regclass('public.clubs') is null then
    raise exception 'Preflight: public.clubs is missing';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='clubs' and column_name='id' and data_type='uuid'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='clubs' and column_name='name' and data_type='text'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='clubs' and column_name='short_name' and data_type='text'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='clubs' and column_name='crest_path' and data_type='text'
  ) then
    raise exception 'Preflight: expected clubs columns or data types differ';
  end if;

  if md5(pg_get_functiondef('public.is_super_admin()'::regprocedure))
       is distinct from '088bac067fc9142f78eaa964ebf9bed2' then
    raise exception 'Preflight: is_super_admin() changed; review authorization dependency';
  end if;

  if not (
    select prosecdef
       and proowner='postgres'::regrole
       and proconfig @> array['search_path=pg_catalog, public']
    from pg_proc
    where oid='public.is_super_admin()'::regprocedure
  ) then
    raise exception 'Preflight: is_super_admin() security attributes differ';
  end if;
end;
$preflight$;

create function public.get_super_admin_clubs()
returns table (
  id uuid,
  name text,
  short_name text,
  crest_path text
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $function$
  select c.id, c.name, c.short_name, c.crest_path
  from public.clubs as c
  where auth.uid() is not null
    and public.is_super_admin()
  order by c.name;
$function$;

-- Do not expose the SECURITY DEFINER function to PUBLIC or anonymous callers.
revoke all on function public.get_super_admin_clubs() from public;
revoke all on function public.get_super_admin_clubs() from anon;
grant execute on function public.get_super_admin_clubs() to authenticated;

do $postflight$
begin
  if not (
    select prosecdef
       and proowner='postgres'::regrole
       and proconfig @> array['search_path=pg_catalog, public']
    from pg_proc
    where oid='public.get_super_admin_clubs()'::regprocedure
  ) then
    raise exception 'Postflight: SECURITY DEFINER, owner or fixed search_path not as expected';
  end if;

  if not has_function_privilege('authenticated','public.get_super_admin_clubs()'::regprocedure,'EXECUTE') then
    raise exception 'Postflight: authenticated is missing EXECUTE';
  end if;

  if has_function_privilege('anon','public.get_super_admin_clubs()'::regprocedure,'EXECUTE') then
    raise exception 'Postflight: anon must not have EXECUTE';
  end if;
end;
$postflight$;

commit;
