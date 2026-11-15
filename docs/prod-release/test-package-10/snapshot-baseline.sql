\set ON_ERROR_STOP on
create schema if not exists ci;
drop table if exists ci.package10_trigger_baseline;
drop table if exists ci.package10_policy_baseline;
create table ci.package10_trigger_baseline as
select n.nspname,c.relname,t.tgname,pg_get_triggerdef(t.oid) definition
from pg_trigger t join pg_class c on c.oid=t.tgrelid
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and not t.tgisinternal;
create table ci.package10_policy_baseline as
select schemaname,tablename,policyname,cmd,roles,qual,with_check
from pg_policies where schemaname='public';
