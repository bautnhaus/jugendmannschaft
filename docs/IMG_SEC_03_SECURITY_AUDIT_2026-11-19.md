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

### 1.2 Direkter HTTP-Negativtest – bestanden

Der Nutzer hat beide früheren öffentlichen Bild-URLs (Profilbild und Vereinslogo) in einem privaten Safari-Fenster ohne KADAssist-Login geöffnet. Rückmeldung: **„Ja beide fuhren ins nichts.“** Für beide URLs wurde kein Bildinhalt ausgeliefert. Der direkte öffentliche URL-Negativtest ist damit aus Nutzersicht bestanden.

Hinweis: Dies ist ein manueller Browser-Negativtest; er ersetzt nicht die nach dem PROD-Cutover vorgesehenen direkten URL-Tests in Gate D.

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
- `main` liegt 186 Commits hinter `develop`. Ein pauschales Merge von `develop` nach `main` würde zahlreiche andere Änderungen mitnehmen und ist ausdrücklich nicht Teil dieses Bildsicherheits-Releases.
- Deshalb wurde ein isolierter Release-Branch `release/img-sec-2026-11-19` von `main` erstellt. Darin wurden ausschließlich die 15 nachvollziehbaren Bild-/Storage-Frontend-Änderungen angewendet. Die resultierende `index.html` hat denselben Blob-SHA wie die getestete DEV-Datei: `cc2ff9534d3847e9e9c343f3da2b741c865c5b9c`.
- Der Release-Branch enthält keine Übernahme der übrigen 186 Commits als Branch-Merge.

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
- DEV: direkter öffentlicher URL-Negativtest für Profilbild und Vereinslogo im privaten Safari-Fenster vom Nutzer bestätigt; bestanden.
- IMG-SEC DEV-Sicherheitsprüfung: vollständig abgeschlossen.
- PROD: ausschließlich read-only geprüft; keine Migration, kein Bucket-Update und kein Frontend-Deploy ausgeführt.
- PROD-Paket: vorbereitet und als Release-Kandidat dokumentiert, aber noch nicht zur Ausführung freigegeben.


### 2.4 Zusätzliche PROD-Preflight-Prüfung

Alle von den vorbereiteten IMG-SEC-01/02-Migrationen benötigten Tabellen, Kontext-Tabellen, Rollenfunktionen und Profil-RPC-Signaturen sind in PROD vorhanden. Das Schema `private` fehlt erwartungsgemäß und wird in IMG-SEC-01b angelegt. Die vier vorgesehenen PROD-Migrationsversionen sind noch nicht registriert.

Der Release-Branch `release/img-sec-2026-11-19` enthält 12 geänderte Dateien (zusätzliche Branch-Commits aktualisieren nur die Prüfdokumentation) gegenüber `main`: die Bild-Frontend-Datei, vier Migrationen, drei Rollbacks und vier Prüfdokumente. Kein vollständiges Merge von `develop`.


## 7. Abschluss der DEV-Sicherheitsprüfung

Am 19.11.2026 bestätigte der Nutzer zusätzlich den direkten öffentlichen URL-Negativtest: Sowohl die Profilbild- als auch die Vereinslogo-URL lieferten in einem privaten Safari-Fenster keinen Bildinhalt. Zusammen mit den bestätigten Upload-/Ändern-/Entfernen-Praxistests und den RLS-Simulationen ist die IMG-SEC-Sicherheitsprüfung in DEV abgeschlossen.

**Status:** IMG-SEC ist technisch vorbereitet, aber wegen des übergreifenden AP02-Superadmin-Kontext-Bypasses noch nicht PROD-freigabefähig. Die nachträglich korrigierten SQL-Dateien wurden noch nicht in DEV installiert oder end-to-end getestet.


## 8. Ergänzende PROD-Kompatibilitäts- und Rollback-Prüfung (20.11.2026)

Die PROD-Funktionsdefinitionen wurden read-only geprüft. Dabei wurde insbesondere bestätigt:
- `public.is_team_admin(uuid)` erlaubt normalen Benutzern die Prüfung ihrer Admin-Rolle in der angegebenen Mannschaft.
- Bei Superadmins verlangt dieselbe Funktion `public.has_selected_team_context(team_id)`.
- `public.is_team_member(uuid)` verwendet für Superadmins ebenfalls den ausdrücklich ausgewählten Mannschaftskontext.
- `public.is_club_admin(uuid)` begrenzt Superadmins auch bei zusätzlicher `club_admin`-Rolle auf den ausgewählten Verein. `public.can_manage_club_context(uuid)` hat dagegen bei diesem dual-role-Sonderfall einen Kontext-Bypass; siehe Abschnitt 10.
- Die verwendeten Funktionen sind `SECURITY DEFINER` mit festgelegtem `search_path`. Für `is_team_admin` wurde zusätzlich geprüft: EXECUTE für `authenticated` vorhanden, für `anon` nicht vorhanden.

Die erste Bewertung wurde durch die vertiefte Rollenprüfung präzisiert: Für Superadmins mit zusätzlicher `club_admin`-Rolle darf IMG-SEC-02 nicht `can_manage_club_context` verwenden. Die korrigierte Migration verwendet stattdessen `is_club_admin`; Details und Tests stehen in Abschnitt 10.

Das IMG-SEC-01-Rollback wurde korrigiert:
- unterstützt IMG-SEC-01a allein und den Zustand nach IMG-SEC-01a plus IMG-SEC-01b;
- entfernt Helper abhängig davon, ob sie in `public` oder `private` liegen;
- stoppt, wenn IMG-SEC-02 noch installiert ist;
- entfernt das von IMG-SEC-01b angelegte Schema `private` nur dann, wenn es nach dem Entfernen der Helper leer ist; unabhängige Objekte werden ohne `CASCADE` geschützt;
- stellt die `club_assets_select_scoped`-Policy mit `public.is_club_admin(...)` wieder her, damit Superadmins auch im Rollback einen ausgewählten Vereinskontext benötigen;
- löscht keine Storage-Objekte oder fachlichen Datensätze.

Diese Prüfung war read-only. Keine PROD-Migration, kein Storage-Update, keine Datenänderung und kein Deployment wurden ausgeführt.


## 9. Frontend-/Datenkompatibilität bei Rollback (20.11.2026)

Die alte PROD-Frontend-Version auf `main` verwendet `players.photo_data`, öffentliche Storage-URLs und speichert Profilbild-URLs als vollständige öffentliche URL. Die IMG-SEC-Frontend-Version verwendet dagegen `players.photo_path`, Signed URLs und speichert neue Profilbildreferenzen als relative Storage-Pfade.

Daraus folgt:
- Ein vollständiger Frontend-Rollback ist nicht allein durch das Zurücksetzen der Datenbank möglich.
- Vor einer Rückkehr zum alten Frontend müssen neue Spielerfoto-Pfade und Objekte ausgeschlossen werden.
- Neue Profilbildpfade und neu hochgeladene Profilbildobjekte müssen ebenfalls ausgeschlossen sein, weil das alte Frontend relative Pfade nicht als vollständige öffentliche URLs rendert.
- Wenn neue Bilddaten existieren, bleibt das neue Frontend aktiv; ein Teil-Rollback einzelner Migrationen muss separat auf Datenkompatibilität und Sicherheitsfolgen geprüft werden.
- Für eine vollständige Rückkehr lautet die Reihenfolge: IMG-SEC-03-Rollback (Buckets wieder public; Sicherheitsdowngrade) → IMG-SEC-02-Rollback → altes Frontend deployen → IMG-SEC-01-Rollback. Jede Stufe benötigt eine separate ausdrückliche Freigabe.

Der PROD-Migrationsledger wurde read-only abgefragt. Die vier IMG-SEC-PROD-Migrationen sind dort noch nicht registriert. Die Release-Dokumentation legt deshalb fest, dass sie über den Supabase-Migrationsmechanismus mit stabilen Migrationsnamen ausgeführt werden; die dabei erzeugten Versions-IDs werden im SQL-Release-Katalog protokolliert. Unprotokollierte SQL-Editor-Ausführung oder manuell geratene Ledger-Einträge sind ausgeschlossen.

Die Postflight-Prüfung wurde ergänzt, um die vier Migrationsnamen im Ledger nachzuweisen und den neu hochgeladenen Vereinslogo-Pfad erst nach der Logo-Neuanlage als erfolgreich zu erwarten.

Diese Prüfung und Dokumentationsanpassung war read-only bzw. GitHub-Dokumentationsarbeit. Es wurden keine PROD-Daten, Buckets, Policies oder Deployments verändert.


## 10. Zusätzliche Preflight-Guards (20.11.2026)

Die PROD-Migrationen wurden um zusätzliche Preflight-/Postflight-Prüfungen ergänzt. Die Prüfungen wurden mit dem installierten DEV-Stand read-only abgeglichen:
- Bucket-Konfiguration von `player-photos`: privat, 2 MiB, JPEG/PNG/WebP.
- `private`-Schema-USAGE und Helper-EXECUTE: `authenticated` erlaubt, `anon` nicht erlaubt.
- IMG-SEC-01b bestätigt, dass die Helper nach dem Schemawechsel nicht mehr in `public` liegen.
- IMG-SEC-02 verlangt die vorhandene Profilbild-SELECT-Policy mit Verweis auf `private.can_view_profile_avatar`.
- IMG-SEC-03 verlangt alle privaten Helper, die private Spielerfoto-Bucket-Konfiguration und die tatsächlichen Policy-Ausdrücke für Profilbilder und Vereinsassets; nach dem Update müssen alle drei Bild-Buckets privat sein.

Der installierte DEV-Stand erfüllt die geprüften Bucket- und Rechteerwartungen. Die erwarteten SELECT-Policy-Ausdrücke lauten auf die Funktionen im Schema `private`. Die Ergänzungen wurden ausschließlich in GitHub vorgenommen; PROD blieb unverändert.


## 10. Korrektur Superadmin-Kontext bei Profilbildverwaltung (20.11.2026)

Bei der vertieften DEV-Rollenprüfung wurde ein echter Sonderfall entdeckt: Der DEV-Superadmin besitzt zusätzlich eine `club_admin`-Rolle. `public.can_manage_club_context(uuid)` liefert für diesen Account auch ohne ausgewählten Vereinskontext `true`, weil die Funktion neben dem Superadmin-Kontextpfad auch die Vereinsadmin-Rolle akzeptiert. Das widerspricht der verbindlichen KADAssist-Regel, dass Superadmins ausschließlich im ausdrücklich ausgewählten Vereins- oder Mannschaftskontext handeln.

Die vorhandene Funktion `public.is_club_admin(uuid)` behandelt diesen Fall korrekt: Bei Superadmins wird ausschließlich der ausgewählte Vereinskontext geprüft; bei normalen Vereinsadmins die zugewiesene `club_admin`-Rolle.

Daher wurde die IMG-SEC-02-PROD-Migration auf beiden Branches korrigiert:
- `private.can_manage_profile_avatar(uuid)` verwendet für Vereinszugriffe `public.is_club_admin(target.club_id)` statt `public.can_manage_club_context(target.club_id)`.
- `public.admin_update_club_member_profile(...)` verwendet ebenfalls `public.is_club_admin(p_club_id)`.
- Das IMG-SEC-02-Preflight prüft nun explizit, dass `public.is_club_admin(uuid)` vorhanden ist.
- Das IMG-SEC-02-Rollback behält diese Kontextprüfung in der Vereinsprofil-RPC und in allen drei Profilbild-Schreibpolicies bewusst bei, statt den festgestellten Superadmin-Kontext-Bypass wieder einzuführen. Die übrigen Profilbild-Validierungsänderungen werden zurückgesetzt.
- Auch das IMG-SEC-01-Rollback verwendet für die wiederhergestellte `club_assets_select_scoped`-Policy `public.is_club_admin(...)` statt der alten `can_manage_club_context(...)`-Prüfung.

Read-only DEV-Tests in zurückgerollten Transaktionen:
| Test | Ergebnis |
|---|---|
| Superadmin mit zusätzlicher `club_admin`-Rolle, ohne Vereins- und Mannschaftskontext | Fremde Profilbilder nicht verwaltbar |
| Derselbe Superadmin mit ausgewähltem Vereinskontext | Mitglieder dieses Vereins verwaltbar |
| Normale Vereinsadmin-Rolle | Vereinsmitglieder verwaltbar |
| Mannschaftsadmin | Profilbild eines Mitglieds derselben Mannschaft verwaltbar |
| Trainer | Fremdes Profilbild nicht verwaltbar |
| Trainer | Eigenes Profilbild weiterhin verwaltbar |

Die Tests zeigen zugleich, dass `can_manage_club_context` im konkreten dual-role-Sonderfall ohne Kontext zu weitreichend ist. Die Bildberechtigungen und die IMG-SEC-02-Vereinsprofil-RPC verwenden deshalb künftig `is_club_admin`.

Diese Korrektur ist bislang ausschließlich in den SQL-Dateien auf GitHub enthalten. Die DEV-Datenbank wurde nicht verändert; die Simulationen wurden zurückgerollt. PROD blieb vollständig read-only.

### 10.1 Read-only Abgleich des IMG-SEC-01a-PROD-Ausgangsstands

Am 20.11.2026 wurde die neue IMG-SEC-01a-Preflight-Bedingung als reine SELECT-Prüfung gegen PROD ausgeführt. Alle erwarteten Ausgangsbedingungen waren erfüllt:
- benötigte Tabellen vorhanden;
- `players.photo_path` fehlt;
- alle drei benötigten Rollen-/Kontextfunktionen vorhanden;
- die vier neuen IMG-SEC-Helper fehlen noch;
- ursprüngliche `club_assets_select_scoped`-SELECT-Policy vorhanden;
- keine der IMG-SEC-01-Policies ist bereits vorhanden.

Der aktuelle PROD-Ausgangsstand passt damit zum neuen IMG-SEC-01a-Preflight. Es wurde keine Migration ausgeführt.


## 11. Abgrenzung: übergreifender AP02-Superadmin-Kontext-Bypass (20.11.2026)

Eine zusätzliche read-only Suche über Funktionsdefinitionen und RLS-Policies in DEV und PROD zeigt, dass `public.can_manage_club_context(uuid)` weiterhin von mehreren nicht zu IMG-SEC gehörenden Club-Management-Funktionen und Policies verwendet wird. Bei einem Superadmin, der zusätzlich eine `club_admin`-Rolle besitzt, kann diese Funktion auch ohne ausgewählten Vereinskontext `true` liefern.

Der Datenbestand bestätigt den Sonderfall in beiden Umgebungen: Jeweils ein Superadmin hat zusätzlich eine `club_admin`-Rollenzuweisung und eine direkte `club_members`-Mitgliedschaft. Zusätzlich besitzt in PROD ein Superadmin eine `team_member_roles`-Zuweisung mit `role='admin'` (in DEV wurde diese Teamadmin-Zuweisung beim Superadmin nicht gefunden). Das widerspricht der fachlichen AP02-Entscheidung: Superadmins sind neutral und keine direkten Vereins- oder Mannschaftsadmins. Es wurden keine Daten verändert.

Die read-only Suche in PROD fand weitere Verwendungen außerhalb des IMG-SEC-Pakets: `admin_add_club_member_by_email`, `admin_add_team_role`, `admin_complete_member_invitation`, `admin_remove_team_role`, `admin_set_club_member_role`, `admin_update_club_details`, `get_club_members_v3`, `get_selected_club_context`, `set_club_suspension_game_types` sowie die Policies `club_member_roles_select_member_or_admin`, `club_members_select_member_or_admin`, `club_suspension_settings_read` und `teams_select_context_admin`. Diese Funktionen/Policies wurden im Rahmen dieser IMG-SEC-Prüfung nicht geändert.

IMG-SEC härtet ausschließlich die direkt betroffenen Bild-/Asset-Zugriffe:
- `can_view_club_asset` ignoriert direkte Vereinsmitgliedschaft für Superadmins und verlangt `is_club_admin` mit ausgewähltem Kontext.
- `can_view_profile_avatar` verwendet `is_team_member` bzw. `is_club_admin`, damit Superadmins nur im ausgewählten Team-/Vereinskontext fremde Profilbilder sehen.
- `club_assets_insert_scoped`, `club_assets_update_scoped` und `club_assets_delete_scoped` verwenden `is_club_admin`.
- `admin_update_club_crest` verwendet `is_club_admin`.
- IMG-SEC-02 verwendet `is_club_admin` für fremde Profilbilder und die Vereinsprofil-RPC.
- Die zugehörigen IMG-SEC-Rollbacks behalten diese strikte Kontextregel bei.

**Konsequenz:** Die globale AP02-Regel ist durch IMG-SEC allein noch nicht vollständig umgesetzt. Vor einer PROD-Freigabe ist eine separate AP02-Korrektur erforderlich: `can_manage_club_context` muss Superadmins unabhängig von zusätzlichen Vereinsrollen ausschließlich über den ausgewählten Vereinskontext autorisieren; zusätzlich müssen direkte `club_members`-/`club_member_roles`- sowie `team_member_roles`-Admin-Zuweisungen des Superadmins nach einer geprüften, ausdrücklich freigegebenen Datenbereinigung entfernt werden. Diese Arbeiten benötigen einen eigenen Preflight, eine Migration, Rollback-/Auswirkungsprüfung und separate Freigabe.

DEV- und PROD-Prüfungen waren read-only bzw. vollständig zurückgerollte Simulationen. Keine Daten-, Rollen-, Policy- oder Funktionsänderung wurde in Supabase ausgeführt.