# DEV – Bereinigung der Bild-Testdaten

**Datum:** 2026-11-18  
**Projekt:** Supabase DEV `pzazqvvoruqnqhcorbwx`  
**Status:** freigegebene Bereinigung; PROD ausdrücklich ausgeschlossen.

## Umfang

Die folgenden DEV-Daten wurden vor der Neuimplementierung als entbehrliche Testdaten freigegeben:

- `players.photo_data`: 3 Data-URLs
- `profiles.avatar_url`: 1 Profilbildreferenz
- `clubs.crest_path`: 1 Vereinswappenreferenz

Die zugehörigen Storage-Dateien sind:
- `profile-avatars/1c84aee5-0569-4c92-a53b-9237382f2b43/avatar-1793460014376.jpg`
- `profile-avatars/1c84aee5-0569-4c92-a53b-9237382f2b43/avatar-1793460141532.jpg`
- `club-assets/7f0e09be-2de5-450a-a39b-0061a2c9c56e/crest.jpg`
- `club-assets/7f0e09be-2de5-450a-a39b-0061a2c9c56e/crest.png`

## Datenbankbereinigung

```sql
begin;

update public.players
set photo_data = null
where photo_data is not null;

update public.profiles
set avatar_url = null
where id = '1c84aee5-0569-4c92-a53b-9237382f2b43'
  and avatar_url is not null;

update public.clubs
set crest_path = null
where id = '7f0e09be-2de5-450a-a39b-0061a2c9c56e'
  and crest_path is not null;

commit;
```

## Storage-Dateien – wichtiger Hinweis

Supabase dokumentiert ausdrücklich, dass Storage-Objekte ausschließlich über die Storage API (`storage.from(bucket).remove(paths)`) gelöscht werden sollen. Direkte SQL-Löschungen aus `storage.objects` entfernen die Binärdateien nicht zuverlässig und können verwaiste Objekte hinterlassen.

Die Storage-API-Löschung ist in diesem Schritt **noch nicht ausgeführt**. Die vier Objektpfade oben sind die verifizierte Löschliste. Nach API-Löschung muss die Objektanzahl in beiden Buckets erneut geprüft werden.

## Schutzgrenze

- Es wurden keine Änderungen an PROD vorgenommen.
- Es wurden keine Buckets, Policies oder Funktionen geändert.
- `players.photo_path` bleibt als vorbereitetes Feld bestehen.
