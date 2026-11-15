-- DB-MIG-2026-025: Scope direct club SELECT to membership/selected context (DEV only).
-- The neutral superadmin club picker uses get_super_admin_clubs() instead.
-- This removes the broad superadmin bypass from direct public.clubs reads.

begin;

do $preflight$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public'
      and tablename='clubs'
      and policyname='clubs_select_member_or_superadmin'
      and cmd='SELECT'
      and roles='{authenticated}'
      and qual='(is_super_admin() OR is_club_member(id))'
  ) then
    raise exception 'Preflight: expected clubs SELECT policy differs; stop and review';
  end if;

  if (select count(*) from pg_policies where schemaname='public' and tablename='clubs' and cmd='SELECT') <> 1 then
    raise exception 'Preflight: unexpected additional clubs SELECT policies';
  end if;

  if md5(pg_get_functiondef('public.is_club_member(uuid)'::regprocedure))
       is distinct from 'fa9b3b855d47a7bbf1a6ba8065647ad3' then
    raise exception 'Preflight: is_club_member(uuid) changed';
  end if;

  if md5(pg_get_functiondef('public.is_club_admin(uuid)'::regprocedure))
       is distinct from '69f262b070d159f9ae9e473a0874edf9' then
    raise exception 'Preflight: is_club_admin(uuid) changed';
  end if;

  if to_regprocedure('public.get_super_admin_clubs()') is null
     or not has_function_privilege('authenticated','public.get_super_admin_clubs()'::regprocedure,'EXECUTE')
     or has_function_privilege('anon','public.get_super_admin_clubs()'::regprocedure,'EXECUTE') then
    raise exception 'Preflight: secure superadmin club picker RPC is missing or has unexpected grants';
  end if;
end;
$preflight$;

drop policy clubs_select_member_or_superadmin on public.clubs;

create policy clubs_select_member_or_superadmin
on public.clubs
for select
to authenticated
using (
  public.is_club_member(id)
  or public.is_club_admin(id)
);

do $postflight$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public'
      and tablename='clubs'
      and policyname='clubs_select_member_or_superadmin'
      and cmd='SELECT'
      and roles='{authenticated}'
      and qual like '%is_club_member%'
      and qual like '%is_club_admin%'
      and qual not like '%is_super_admin%'
  ) then
    raise exception 'Postflight: clubs SELECT policy is not context-scoped as expected';
  end if;

  if (select count(*) from pg_policies where schemaname='public' and tablename='clubs' and cmd='SELECT') <> 1 then
    raise exception 'Postflight: unexpected clubs SELECT policy count';
  end if;
end;
$postflight$;

commit;
