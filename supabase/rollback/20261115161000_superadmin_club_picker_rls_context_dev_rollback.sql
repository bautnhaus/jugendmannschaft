-- Rollback for DB-MIG-2026-025 (DEV only).
-- WARNING: restores broad direct SELECT for every superadmin.
-- Use only to recover a broken DEV environment; do not promote to PROD.

begin;

do $preflight$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public'
      and tablename='clubs'
      and policyname='clubs_select_member_or_superadmin'
      and cmd='SELECT'
      and qual like '%is_club_member%'
      and qual like '%is_club_admin%'
      and qual not like '%is_super_admin%'
  ) then
    raise exception 'Rollback preflight: current context-scoped clubs policy differs';
  end if;
end;
$preflight$;

drop policy clubs_select_member_or_superadmin on public.clubs;

create policy clubs_select_member_or_superadmin
on public.clubs
for select
to authenticated
using (
  public.is_super_admin()
  or public.is_club_member(id)
);

commit;
