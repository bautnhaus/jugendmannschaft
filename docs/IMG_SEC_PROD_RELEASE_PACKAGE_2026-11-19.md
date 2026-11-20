# IMG-SEC – PROD-Freigabe- und Ausführungsplan

**Status:** vorbereitet, nicht ausgeführt; PROD-Freigabe bis zur AP02-Korrektur gesperrt.  
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

IMG-SEC ist technisch vorbereitet, aber wegen des dokumentierten AP02-Superadmin-Kontext-Bypasses noch nicht PROD-freigabefähig. **Eine PROD-Ausführungsfreigabe liegt nicht vor.** Vor jeder PROD-Ausführung werden die vier Migrationen und die zugehörigen Rollback-Skripte gemeinsam einzeln geprüft. Bis zu einer separaten ausdrücklichen Freigabe bleiben PROD, Buckets, Datenbank und Deployment unverändert.


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


## Ergänzung: Migrationsledger und Ausführungsweg

Die PROD-Migrationen werden zum Release über den Supabase-Migrationsmechanismus ausgeführt (nicht als unprotokollierte Einzel-Ausführung im SQL Editor). Für jede Migration wird der genaue Name aus der folgenden Liste verwendet; die vom Migrationsmechanismus zurückgegebene Versions-ID wird unmittelbar im Release-Protokoll und SQL-Release-Katalog festgehalten:

- `img_sec_01_private_player_photo_storage_v1_0_0_prod`
- `img_sec_01_harden_private_policy_helpers_prod`
- `img_sec_02_profile_avatar_hardening_v1_0_0_prod`
- `img_sec_03_private_profile_and_club_asset_buckets_prod`

Die Dateien im Release-Branch sind die verbindlichen SQL-Inhalte. Vor jeder Ausführung werden Dateipfad, Inhalt, Zielprojekt **PROD** und Reihenfolge gemeinsam bestätigt. Der Migrationsmechanismus muss den Eintrag in `supabase_migrations.schema_migrations` selbst registrieren. Keine manuelle, unvollständige oder geratene Ledger-Eintragung. Falls eine Migration ausnahmsweise im SQL Editor ausgeführt werden muss, wird vorher ein eigener, freigegebener Plan für die korrekte Ledger-Nachführung erstellt; nicht einfach fortfahren.

## Ergänzung: abgestufte Rollback-Strategie inklusive Frontend

Ein Datenbank-Rollback darf nicht isoliert von der ausgelieferten Frontend-Version betrachtet werden. Die neue Frontend-Version nutzt `players.photo_path` und speichert Profilbildreferenzen als Storage-Pfade; der bisherige PROD-Frontend-Stand verwendet dagegen `players.photo_data` und erwartet bei Profilbildern öffentliche URLs.

### A. Teil-Rollback bei weiterverwendetem IMG-SEC-01-Frontend

Wenn bereits neue Profilbildpfade oder Spielerfotos angelegt wurden, darf nicht pauschal auf das alte Frontend zurückgestellt werden. In diesem Fall:
- IMG-SEC-01 und die neue Bild-Frontend-Version bleiben bestehen, damit `photo_path` und die gespeicherten Pfade weiter funktionieren.
- Ein erforderlicher Rollback von IMG-SEC-03 (Buckets wieder öffentlich) und/oder IMG-SEC-02 wird separat auf Datenkompatibilität und Sicherheitsfolgen geprüft.
- Das alte Frontend wird nicht deployt, solange neue Pfade in `profiles.avatar_url` oder `players.photo_path` vorhanden sind.

### B. Vollständige Rückkehr zum bisherigen PROD-Stand

Eine vollständige Rückkehr zum bisherigen Frontend und zur alten IMG-SEC-Datenbankstruktur ist nur zulässig, wenn die nachfolgende read-only Prüfung bestätigt, dass keine neuen Bilddaten entstanden sind:
- `players.photo_path` enthält keine Werte und `player-photos` enthält keine Objekte.
- `profiles.avatar_url` enthält keine neuen Pfade im Format `<user-uuid>/avatar-<13-stellige Millisekunden>.(jpg|png|webp)`.
- `profile-avatars` enthält keine neu hochgeladenen Objekte, die das alte Frontend nicht als öffentliche URL referenzieren kann.
- Vorhandene Vereinslogo-Neuanlage ist mit dem alten Frontend kompatibel, weil der bisherige `club-assets`-Pfad und `clubs.crest_path` weiterverwendet werden.

Wenn diese Bedingungen erfüllt sind, ist die Rückwärtsreihenfolge:
1. IMG-SEC-03-Rollback: beide Buckets wieder öffentlich stellen (nur nach ausdrücklicher Freigabe; Sicherheitsdowngrade).
2. IMG-SEC-02-Rollback: ursprüngliche Profilbild-RPCs und Schreibpolicies wiederherstellen.
3. Bisheriges Frontend aus `main` wieder deployen und Funktion prüfen.
4. IMG-SEC-01-Rollback: erst danach und nur bei weiterhin leeren `photo_path`-Daten und leerem `player-photos`-Bucket ausführen.

Bei neuen Profilbild- oder Spielerfotodaten ist die vollständige Rückkehr blockiert, bis ein gesonderter Datenkompatibilitäts-/Migrationsplan erstellt und freigegeben wurde. Rollbacks erfolgen nie automatisch.



## Ergänzung: verschärfte Migrations-Preflights

Die vier PROD-Migrationsdateien wurden am 20.11.2026 nochmals gegen den installierten DEV-Stand geprüft und mit zusätzlichen Abbruchbedingungen versehen:
- IMG-SEC-01a prüft vor Änderungen den erwarteten PROD-Ausgangsstand (fehlende `photo_path`-Spalte und Helper, vorhandene ursprüngliche Vereinsasset-SELECT-Policy, keine bereits vorhandenen IMG-SEC-Policies). Nach Bucket-Anlage prüft es neben `public=false` auch die erwartete Dateigrößenbegrenzung von 2 MiB und die exakte MIME-Allowlist.
- IMG-SEC-01b prüft vor dem Schemawechsel, dass alle IMG-SEC-01a-Helper und die erwarteten Policies vorhanden sind und tatsächlich auf die öffentlichen IMG-SEC-01a-Helper zeigen. Nach dem Verschieben, dass die drei Policy-Helper ausschließlich in `private` liegen, `authenticated` Schema-/EXECUTE-Rechte hat und `anon` weder Schema-USAGE noch EXECUTE erhält.
- IMG-SEC-02 prüft vor Ausführung, dass der private IMG-SEC-01-Helper existiert, die erwarteten Rechte gelten und die bestehende Profilbild-SELECT-Policy tatsächlich den privaten Helper verwendet.
- IMG-SEC-03 prüft zusätzlich den privaten Spielerfoto-Bucket, die `photo_path`-Spalte, alle benötigten privaten Helper, die Auth-/Anon-Rechte und die tatsächlichen SELECT-Policy-Ausdrücke. Nach dem Cutover müssen alle drei Bild-Buckets privat sein.

Die erwarteten Rechte und Policy-Ausdrücke wurden read-only mit dem installierten DEV-Stand abgeglichen. Die PROD-Dateien sind dadurch strenger abgesichert; es wurde keine Migration ausgeführt.


## Ergänzung: strikte Superadmin-Kontextprüfung in IMG-SEC-02 (20.11.2026)

Bei der DEV-Rollenprüfung wurde festgestellt, dass `public.can_manage_club_context(uuid)` bei einem Superadmin mit zusätzlicher `club_admin`-Rolle auch ohne ausgewählten Vereinskontext `true` liefern kann. Das verletzt die verbindliche Regel, dass Superadmins nur im ausdrücklich ausgewählten Kontext handeln.

Die IMG-SEC-02-Migration wurde deshalb korrigiert:
- Avatar-Verwaltung für Vereinsmitglieder verwendet `public.is_club_admin(target.club_id)`.
- Die Vereinsprofil-RPC verwendet `public.is_club_admin(p_club_id)`.
- Das Preflight prüft diese Funktion explizit.
- Das IMG-SEC-02-Rollback behält diese strengere Kontextprüfung in der Vereinsprofil-RPC und in allen drei Profilbild-Schreibpolicies bewusst bei. Auch das IMG-SEC-01-Rollback verwendet für `club_assets_select_scoped` `public.is_club_admin(...)`. Kein Rollback führt den bekannten Bypass wieder ein.

Die Rollenprüfungen wurden in DEV ausschließlich lesend bzw. in vollständig zurückgerollten Simulationstransaktionen durchgeführt. Bestanden: Superadmin ohne Kontext = kein Fremdzugriff; Superadmin mit ausgewähltem Vereinskontext = Zugriff im ausgewählten Verein; normaler Vereinsadmin = Zugriff im eigenen Verein; Mannschaftsadmin = Zugriff auf Mitglieder der eigenen Mannschaft; Trainer = kein Fremdzugriff, aber Selbstverwaltung bleibt möglich.

**Hinweis:** Die Änderung ist bislang nur in den GitHub-SQL-Dateien enthalten. Keine DEV- oder PROD-Migration wurde ausgeführt.

## Release-Blocker: übergreifender AP02-Superadmin-Kontext (20.11.2026)

Die read-only Prüfung von DEV und PROD hat einen über IMG-SEC hinausgehenden AP02-Kontext-Bypass bestätigt. In beiden Umgebungen besitzt jeweils ein Superadmin zusätzlich eine `club_admin`-Rollenzuweisung und eine direkte `club_members`-Mitgliedschaft. `public.can_manage_club_context(uuid)` kann dadurch für diesen Superadmin ohne ausgewählten Vereinskontext `true` liefern.

IMG-SEC härtet die unmittelbar betroffenen Profilbild- und Vereinsasset-Zugriffe mit `public.is_club_admin(...)` bzw. `public.is_team_member(...)`. Die übrigen Club-Management-Funktionen und Policies, die weiterhin `can_manage_club_context` verwenden, sind nicht Teil dieses Release-Pakets.

**IMG-SEC darf nicht in PROD freigegeben werden, bevor die separate AP02-Korrektur umgesetzt und geprüft wurde.** Erforderlich sind eine gehärtete zentrale `can_manage_club_context`-Semantik (Superadmins ausschließlich im ausgewählten Vereinskontext) und eine separat freizugebende Datenbereinigung der direkten Vereinsmitgliedschaft/-rolle des Superadmins. Dafür ist ein eigener Preflight, eine eigene Migration, eine Rollback-/Auswirkungsprüfung und ein DEV-Praxistest erforderlich.

Dieser Release-Blocker wurde ausschließlich dokumentiert. Keine Supabase-Daten oder Rollen wurden verändert.