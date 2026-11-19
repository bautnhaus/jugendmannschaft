# IMG-SEC – Security-Abschlussprüfung DEV und PROD-Bestandsaufnahme

**Datum:** 19.11.2026  
**Umgebungen:** Supabase DEV `pzazqvvoruqnqhcorbwx`; Supabase PROD `qdugtpzgefpswnnqbusd`  
**Modus:** DEV-Tests und PROD ausschließlich lesend. Keine PROD-Änderung.

## 1. DEV – gezielte Berechtigungsprüfungen

Die folgenden Prüfungen wurden mit transaktionsisolierten Rollen-/JWT-Simulationen ausgeführt. Jede Testtransaktion wurde zurückgerollt; es wurden keine Datensätze verändert.

| Test | Ergebnis |
|---|---|
| Anonymer Zugriff auf `profile-avatars`-Objekt über Storage-RLS | 0 Zeilen |
| Anonymer Zugriff auf `club-assets`-Objekt über Storage-RLS | 0 Zeilen |
| Nicht zugehöriger authentifizierter Benutzer – Profilbild | Helper false, 0 Zeilen |
| Nicht zugehöriger authentifizierter Benutzer – Vereinslogo | Helper false, 0 Zeilen |
| Trainer ohne gemeinsame Mannschaft – fremdes Profilbild | Helper false, 0 Zeilen |
| Berechtigter Betrachter aus derselben Mannschaft – Profilbild | Helper true, 1 Zeile |
| Vereinsmitglied – Vereinslogo | Helper true, 1 Zeile |
| Superadmin im ausdrücklich ausgewählten Vereinskontext – Vereinslogo | Helper true, 1 Zeile |

### 1.1 Aktueller DEV-Datenbestand

| Bucket / Referenz | Bestand |
|---|---:|
| `player-photos` | 2 Objekte |
| `profile-avatars` | 4 Objekte |
| Davon exakt durch `profiles.avatar_url` referenziert | 2 |
| Nicht referenzierte Profilbildobjekte | 2 |
| `club-assets` | 1 Objekt |
| Davon exakt durch `clubs.crest_path` referenziert | 1 |

Die zwei nicht referenzierten Profilbildobjekte werden nicht automatisch gelöscht. Für sie ist keine Bereinigungsfreigabe erteilt.

### 1.2 Noch offener direkter HTTP-Negativtest

Die Datenbank-RLS-Simulationen und die Einstellung `public=false` sind bestätigt. Ein echter unauthentifizierter HTTP-Aufruf der früheren `/object/public/...`-Adressen konnte aus der verfügbaren Laufzeit nicht zuverlässig ausgeführt werden, weil der Supabase-Storage-Endpunkt dort nicht erreichbar war.

Daher ist der direkte öffentliche URL-Test als **noch nicht unabhängig per HTTP bestätigt** markiert. Er muss vor endgültiger PROD-Freigabe in einem privaten Browserfenster ohne KADAssist-Login durchgeführt werden. Erwartung: kein Bildinhalt, sondern Zugriff verweigert/Objekt nicht öffentlich verfügbar.

## 2. PROD – read-only Bestandsaufnahme

### 2.1 Storage und Daten

- Buckets vorhanden: `profile-avatars` und `club-assets`; beide derzeit `public=true`.
- Bucket `player-photos` ist in PROD nicht vorhanden.
- `players`: 39 Datensätze; Spalte `photo_path` fehlt; `photo_data` enthält 0 Werte.
- `profiles`: 6 Datensätze; `avatar_url` enthält 0 Referenzen; `profile-avatars` enthält 0 Objekte.
- `clubs`: 1 gespeicherte Logo-Referenz; `club-assets` enthält 1 Objekt. Objektpfad und `clubs.crest_path` stimmen exakt überein.
- Es ist keine Datenmigration von Base64-Spielerbildern erforderlich, da `photo_data` leer ist. Die Migration legt lediglich die neue Pfadspalte und den privaten Bucket an.

### 2.2 Berechtigungsunterschiede zu DEV

- Das Schema `private` existiert in PROD noch nicht.
- `profile_avatars_select_authorized` fehlt in PROD.
- Die bestehende `club_assets_select_scoped`-Policy erlaubt derzeit nur den Verwaltungs-Kontext; sie entspricht nicht der DEV-Leseregel für Vereinsmitglieder und Admins.
- Die drei IMG-SEC-01/02-Helper für private Bildanzeige/-verwaltung fehlen in PROD.
- Die bestehenden Profilbild-Schreibpolicies und Profil-RPCs sind vorhanden. Die beiden Profil-RPC-Definitionen stimmen mit dem geprüften Ausgangsstand überein, auf dem IMG-SEC-02 aufbaut.

Die vorbereitete IMG-SEC-01-PROD-Migration ergänzt die fehlenden Helper und setzt die beiden SELECT-Policies auf die getestete DEV-Logik. IMG-SEC-02 härtet danach Pfadvalidierung und Schreibwege.

### 2.3 Frontend-Ausgangslage

- `main/index.html` enthält noch 7 Aufrufe von `getPublicUrl()`.
- Der PROD-Stand hat weder den gemeinsamen Signed-URL-Resolver noch die `photo_path`-Integration.
- `main` liegt 96 Commits hinter `develop`. Ein pauschales Merge von `develop` nach `main` würde zahlreiche andere Änderungen mitnehmen und ist ausdrücklich nicht Teil dieses Bildsicherheits-Releases.
- Deshalb wurde ein isolierter Release-Branch `release/img-sec-2026-11-19` von `main` erstellt. Darin wurden ausschließlich die 15 nachvollziehbaren Bild-/Storage-Frontend-Änderungen angewendet. Die resultierende `index.html` hat denselben Blob-SHA wie die getestete DEV-Datei: `cc2ff9534d3847e9e9c343f3da2b741c865c5b9c`.
- Der Release-Branch enthält keine Übernahme der übrigen 96 Commits als Branch-Merge.

## 3. PROD-Migrationspaket

Vorbereitet auf dem Release-Branch und zusätzlich dokumentiert auf `develop`:

1. `20261119180000_img_sec_01_private_player_photo_storage_v1_0_0_prod.sql`
2. `20261119180100_img_sec_01_harden_private_policy_helpers_prod.sql`
3. `20261119180200_img_sec_02_profile_avatar_hardening_v1_0_0_prod.sql`
4. `20261119180300_img_sec_03_private_profile_and_club_asset_buckets_prod.sql`

Rollback-Dateien:
- IMG-SEC-01: `supabase/rollback/20261119180000_img_sec_01_private_player_photo_storage_rollback_prod.sql`
- IMG-SEC-02: `supabase/rollback/20261119180200_img_sec_02_profile_avatar_hardening_rollback_prod.sql`
- IMG-SEC-03: `supabase/rollback/20261119180300_img_sec_03_private_profile_and_club_asset_buckets_rollback_prod.sql`

## 4. Vorgesehene PROD-Reihenfolge

1. Vorherige Datensicherung und erneuter read-only Preflight.
2. IMG-SEC-01a ausführen: `photo_path`, privaten `player-photos`-Bucket, Helper und Storage-Policies anlegen.
3. IMG-SEC-01b ausführen: Helper ins Schema `private` verschieben und Rechte härten.
4. IMG-SEC-02 ausführen: Profilbildpfade validieren, Trigger und Storage-Schreibregeln härten.
5. Isolierten Frontend-Stand aus `release/img-sec-2026-11-19` deployen. Die Buckets `profile-avatars` und `club-assets` sind zu diesem Zeitpunkt noch öffentlich; die App muss mit Signed URLs und dem neuen Spielerfoto-Pfad bereits funktionieren.
6. Smoke- und Rollenprüfungen ausführen.
7. Erst danach IMG-SEC-03 ausführen: `profile-avatars` und `club-assets` auf privat umstellen.
8. Direkte öffentliche URLs, Signed URLs, Rollen, iPhone/Safari, Login/Logout und Kontextwechsel erneut prüfen.

IMG-SEC-03 darf nicht vor dem Frontend-Deploy und erfolgreichen Smoke-Test erfolgen, sonst könnte die aktuelle PROD-App Bilder nicht mehr laden.

## 5. Rollback-Reihenfolge und Grenzen

- IMG-SEC-03-Rollback stellt die beiden Buckets auf `public=true`; das macht die Objekte wieder öffentlich.
- IMG-SEC-02-Rollback stellt die vorherigen Profilbild-RPCs und Schreibpolicies wieder her; Profil- und Storage-Daten bleiben bestehen.
- IMG-SEC-01-Rollback ist nur möglich, wenn `players.photo_path` leer ist und `player-photos` keine Objekte enthält. Nach dem ersten produktiven Spielerfoto ist dieser Rollback nicht mehr ohne gesonderte Daten-/Migrationsplanung möglich.
- Kein Rollback wird ohne gesonderte ausdrückliche Freigabe ausgeführt.

## 6. Status

- DEV: IMG-SEC-01/02/03 installiert; App-Funktionstests und RLS-Simulationen bestanden.
- DEV: direkter unauthentifizierter HTTP-Aufruf der öffentlichen URL noch offen.
- PROD: ausschließlich read-only geprüft; keine Migration, kein Bucket-Update und kein Frontend-Deploy ausgeführt.
- PROD-Paket: vorbereitet, aber noch nicht zur Ausführung freigegeben.


### 2.4 Zusätzliche PROD-Preflight-Prüfung

Alle von den vorbereiteten IMG-SEC-01/02-Migrationen benötigten Tabellen, Kontext-Tabellen, Rollenfunktionen und Profil-RPC-Signaturen sind in PROD vorhanden. Das Schema `private` fehlt erwartungsgemäß und wird in IMG-SEC-01b angelegt. Die vier vorgesehenen PROD-Migrationsversionen sind noch nicht registriert.

Der Release-Branch `release/img-sec-2026-11-19` enthält 12 geänderte Dateien (zusätzliche Branch-Commits aktualisieren nur die Prüfdokumentation) gegenüber `main`: die Bild-Frontend-Datei, vier Migrationen, drei Rollbacks und vier Prüfdokumente. Kein vollständiges Merge von `develop`.
