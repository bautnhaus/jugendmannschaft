# IMG-SEC – PROD-Freigabe- und Ausführungsplan

**Status:** vorbereitet, nicht ausgeführt.  
**PROD-Projekt:** `qdugtpzgefpswnnqbusd`.  
**Freigabe:** Eine separate ausdrückliche PROD-Ausführungsfreigabe ist zwingend erforderlich.

## Migrationsdateien in Ausführungsreihenfolge

| Reihenfolge | Datei | Zweck |
|---|---|---|
| 1 | `supabase/migrations/20261119180000_img_sec_01_private_player_photo_storage_v1_0_0_prod.sql` | `photo_path`, privater Bucket `player-photos`, Helper und Policies |
| 2 | `supabase/migrations/20261119180100_img_sec_01_harden_private_policy_helpers_prod.sql` | Helper ins private Schema verschieben, Rechte begrenzen |
| 3 | `supabase/migrations/20261119180200_img_sec_02_profile_avatar_hardening_v1_0_0_prod.sql` | Profilbild-Pfadvalidierung, Trigger, RPC- und Schreibpolicy-Härtung |
| 4 | Frontend-Deploy aus `release/img-sec-2026-11-19` | Signed URLs, `photo_path`, Retry und Kontext-Cache |
| 5 | `supabase/migrations/20261119180300_img_sec_03_private_profile_and_club_asset_buckets_prod.sql` | Profilbilder und Vereinsassets privat stellen |

## Verbindliche Gates

- Gate A: Backup/Snapshot vorhanden und PROD-Preflight erneut bestanden.
- Gate B: Nach IMG-SEC-01/02 Datenbank-Postflight und Rollenprüfungen bestanden.
- Gate C: Frontend-Deploy erfolgreich; Profilbild, Vereinslogo und Spielerfotos funktionieren noch vor IMG-SEC-03.
- Gate D: Nach IMG-SEC-03 sind beide Buckets privat, die Bilder funktionieren über Signed URLs, direkte öffentliche URLs liefern keinen Bildinhalt.
- Gate E: iPhone/Safari, Login/Logout und Team-/Vereinskontextwechsel bestanden.

## PROD-Bestand aus der read-only Prüfung am 19.11.2026

- 39 Spieler; `photo_path` fehlt; `photo_data` ist in 0 Zeilen befüllt.
- 6 Profile; 0 `avatar_url`-Referenzen; 0 Objekte in `profile-avatars`.
- 1 Vereinslogo-Referenz und 1 passendes Objekt in `club-assets`.
- `profile-avatars` und `club-assets` sind derzeit öffentlich.
- `player-photos` fehlt in PROD.

Es ist keine bestehende Spielerfoto-Datei zu migrieren. Das vorhandene Vereinslogo wird unmittelbar vor dem Release kontrolliert aus PROD entfernt (Storage-Objekt und `clubs.crest_path`-Referenz); nach dem privaten Bucket-Cutover wird es über die KADAssist-Oberfläche neu hochgeladen.

## Frontend-Abgrenzung

`main` ist 96 Commits hinter `develop`. Kein vollständiges Merge von `develop` nach `main` für dieses Release. Der dedizierte Branch `release/img-sec-2026-11-19` basiert auf `main` und enthält die gezielten Bild-Frontend-Änderungen. Seine `index.html` entspricht dem getesteten DEV-Blob-SHA `cc2ff9534d3847e9e9c343f3da2b741c865c5b9c`.

## Rollback

- IMG-SEC-03: `supabase/rollback/20261119180300_img_sec_03_private_profile_and_club_asset_buckets_rollback_prod.sql`
- IMG-SEC-02: `supabase/rollback/20261119180200_img_sec_02_profile_avatar_hardening_rollback_prod.sql`
- IMG-SEC-01: `supabase/rollback/20261119180000_img_sec_01_private_player_photo_storage_rollback_prod.sql`

IMG-SEC-01-Rollback nur, solange keine Spielerfoto-Pfade und keine Objekte im Bucket `player-photos` existieren. Rollbacks nur nach separater ausdrücklicher Freigabe.

## Nicht enthalten

- Keine PROD-Ausführung.
- Kein PROD-Bucket-Cutover.
- Kein Merge nach `main`.
- Keine Löschung nicht referenzierter DEV-Profilbilder.
- Keine sonstigen Änderungen an bestehenden Vereinslogo- oder Profilbilddateien; die ausdrücklich geplante Logo-Neuanlage ist in der Release-Vorbereitung beschrieben.


## Read-only Preflight-Ergänzung PROD

Am 19.11.2026 wurde zusätzlich geprüft:
- Alle von IMG-SEC-01 benötigten Tabellen und Kontext-Tabellen sind vorhanden: `players`, `profiles`, `clubs`, `team_member_roles`, `club_members`, `club_member_roles`, `global_user_roles`, `user_team_context`, `user_club_context`, `storage.buckets`, `storage.objects`.
- Alle von IMG-SEC-01/02 benötigten Rollen-/Kontextfunktionen und beide Profil-RPC-Signaturen sind vorhanden.
- `private` fehlt erwartungsgemäß in PROD und wird durch IMG-SEC-01b angelegt.
- Die vier vorgesehenen PROD-Migrationsversionen sind noch nicht im PROD-Ledger registriert.
- Das Vereinslogoobjekt stimmt exakt mit `clubs.crest_path` überein.
- Der isolierte Release-Branch enthält gegenüber `main` 12 geänderte Dateien (die zusätzlichen Branch-Commits betreffen nur Aktualisierungen dieser Dokumentation): die Bild-Frontend-Datei, vier Migrationen, drei Rollbacks und vier Prüfdokumente. Es wurden keine anderen App-Funktionen aus `develop` übernommen.


## DEV-Abschluss / Release-Candidate-Status

Am 19.11.2026 wurde der direkte öffentliche URL-Negativtest für Profilbild und Vereinslogo vom Nutzer in einem privaten Safari-Fenster bestätigt: Beide URLs lieferten keinen Bildinhalt. Die DEV-Sicherheitsprüfung ist damit einschließlich RLS-Simulationen und bestätigter Upload-/Ändern-/Entfernen-Praxistests abgeschlossen.

IMG-SEC ist als technischer PROD-Release-Kandidat vorbereitet. **Eine PROD-Ausführungsfreigabe liegt weiterhin nicht vor.** Vor jeder PROD-Ausführung werden die vier Migrationen und die zugehörigen Rollback-Skripte gemeinsam einzeln geprüft. Bis zu einer separaten ausdrücklichen Freigabe bleiben PROD, Buckets, Datenbank und Deployment unverändert.


## Ergänzung: geplante Logo-Neuanlage unmittelbar vor dem Release

Der bisherige PROD-Logo-Datensatz soll nicht in den neuen privaten Bucket-Pfad übernommen werden. Stattdessen wird das vorhandene Logo unmittelbar vor Beginn der IMG-SEC-PROD-Ausführung kontrolliert entfernt und nach erfolgreichem Cutover über KADAssist neu hochgeladen.

Verbindliche Reihenfolge:
1. Direkt vor dem Release erneut read-only prüfen, welcher Datensatz in `public.clubs` betroffen ist und welchen exakten Objektpfad `clubs.crest_path` referenziert.
2. Vor jeder Löschung die Zuordnung von Verein, Referenz und Storage-Objekt gemeinsam anzeigen und vom Nutzer bestätigen lassen.
3. Das exakt bestätigte Objekt im Supabase-Dashboard unter **Storage → club-assets** löschen.
4. Anschließend die exakt zugehörige `clubs.crest_path`-Referenz kontrolliert auf `NULL` setzen. Vorherige SELECT-Kontrolle, eng begrenztes UPDATE und anschließende SELECT-Verifikation sind verpflichtend.
5. Erst wenn Objekt und Referenz nachweislich entfernt sind, IMG-SEC-Migrationen und Frontend-Release nach den Gates ausführen.
6. Nach IMG-SEC-03 das Vereinslogo über die KADAssist-Oberfläche neu hochladen. Danach neuen Objektpfad, Referenz, Signed-URL-Anzeige und fehlenden öffentlichen Direktzugriff prüfen.

**Sicherheits- und Freigaberegeln:**
- Diese Schritte sind nur geplant; sie wurden nicht ausgeführt.
- Keine Löschung und kein SQL-UPDATE ohne separate ausdrückliche Freigabe.
- Die konkrete Vereins-ID und der konkrete Objektpfad werden erst unmittelbar vor dem Release erneut read-only ermittelt; keine Werte aus älteren Prüfungen blind übernehmen.
- Die Löschung des Storage-Objekts und das Leeren der Referenz erfolgen als zwei nachvollziehbare, einzeln verifizierte Schritte. Ich leite den Nutzer dabei in Supabase Schritt für Schritt an.
- Bis dahin bleiben PROD-Logo, Referenz, Buckets, Datenbank und Deployment unverändert.

## Ergänzung: IMG-SEC-01-Rollback-Korrektur

Das IMG-SEC-01-Rollback wurde am 20.11.2026 korrigiert und auf `develop` sowie diesem Release-Branch aktualisiert. Es unterstützt jetzt beide Zwischenstände (IMG-SEC-01a allein sowie IMG-SEC-01a plus IMG-SEC-01b), entfernt die Helper je nach vorhandenem Schema und stoppt, solange IMG-SEC-02 noch installiert ist. Es löscht keine Storage-Objekte oder fachlichen Datensätze.
