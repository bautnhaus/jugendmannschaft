-- KADAssist IMG-SEC-03 / Rollback / DEV
-- Nur nach gesonderter ausdrücklicher Rollback-Freigabe ausführen.
-- Stellt die vorherige Bucket-Sichtbarkeit public=true wieder her.
-- Keine Storage-Objekte, Profile, Pfade oder Policies werden verändert.
-- ACHTUNG: public=true macht das Abrufen der Objekte wieder öffentlich.

begin;

do $preflight$
begin
  if not exists (select 1 from storage.buckets where id='profile-avatars' and public=false) then
    raise exception 'Rollback abgebrochen: profile-avatars fehlt oder ist nicht privat.';
  end if;
  if not exists (select 1 from storage.buckets where id='club-assets' and public=false) then
    raise exception 'Rollback abgebrochen: club-assets fehlt oder ist nicht privat.';
  end if;
end;
$preflight$;

update storage.buckets
set public=true
where id in ('profile-avatars','club-assets');

commit;
