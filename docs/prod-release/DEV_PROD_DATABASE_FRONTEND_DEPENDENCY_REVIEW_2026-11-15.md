# DEV/PROD-Datenbank- und Frontend-Abgleich – 15.11.2026

**Zweck:** Read-only Abschlussprüfung der Datenbankabhängigkeiten vor einem möglichen Merge `develop` → `main`.  
**DEV-Projekt:** `pzazqvvoruqnqhcorbwx`  
**PROD-Projekt:** `qdugtpzgefpswnnqbusd`  
**Frontend develop Blob-SHA:** `f04bbb418a785539821884f191a700172902e1b8`  
**Frontend main Blob-SHA:** `ea65f81d53a48bb9a17a15e18b76bfcc3418f6bc`  
**Status:** Datenbank-Abgleich weitgehend bestanden; ein sicherheits-/funktionsrelevanter Kontextunterschied blockiert einen unkritischen Merge.

## 1. Schema- und Abhängigkeitsabgleich

| Prüffeld | DEV | PROD | Ergebnis |
|---|---:|---:|---|
| Public-Basistabellen | 38 | 38 | identisch |
| Public-Spalten | 288 | 288 | identisch |
| RLS-Policies | 159 | 159 | gleiche Anzahl; 14 Definitionen weichen ab |
| Public-Funktionen | 78 | 76 | kleine Funktionsdifferenz |
| Frontend-RPC-Aufrufe in develop | 27 | alle 27 vorhanden | keine fehlende PROD-RPC-Abhängigkeit |
| Frontend-Tabellen/Buckets in develop | 30 | alle 30 vorhanden | keine fehlende PROD-Tabellen-/Bucket-Abhängigkeit |

Die vier RPCs, die in develop zusätzlich gegenüber main aufgerufen werden (`award_training_behavior_event`, `correct_suspension`, `correct_training_behavior_event`, `grant_suspension_exception`), existieren bereits in PROD.

Die sechs zusätzlich von develop verwendeten Tabellen (`matchday_early_suspension_resets`, `training_behavior_event_audit`, `training_behavior_events`, `training_suspension_audit`, `training_suspension_exceptions`, `training_suspensions`) existieren ebenfalls in PROD. Die beiden Storage-Buckets `club-assets` und `profile-avatars` sind vorhanden.

## 2. Funktionsdifferenzen

DEV-only:
- `get_club_members(p_club_id uuid)`
- `get_club_suspension_game_types(p_club_id uuid)`
- `get_team_suspension_game_type_settings(p_team_id uuid)`

PROD-only:
- `rls_auto_enable()` – keine Trigger-Abhängigkeit in PROD gefunden.

Keine dieser vier Funktionsdifferenzen wird von den aktuellen develop-Frontend-RPC-Aufrufen verwendet. Sie blockieren die Frontend-/DB-Kompatibilität nicht unmittelbar.

Die direkte Funktionsdefinition `admin_add_club_member(uuid,uuid,text)` wurde erneut verglichen. Der fachliche Funktionskörper, die Kontextprüfung, die Ein-Verein-pro-Benutzer-Prüfung, SECURITY DEFINER, Owner, search_path und EXECUTE-ACL sind in DEV und PROD gleich. Die zuvor vermutete relevante Abweichung ist damit aktuell nicht bestätigt.

## 3. Merge-Blocker: Vereinsauswahl für Superadmins

Die Frontend-Funktion `window.loadSuperAdminClubs()` lädt die Vereinsauswahl direkt mit:

`from('clubs').select('id,name,short_name,crest_path').order('name')`

DEV-Policy `clubs_select_member_or_superadmin`:
`is_super_admin() OR is_club_member(id)`

PROD-Policy `clubs_select_member_or_superadmin`:
`is_club_member(id) OR is_club_admin(id)`

Die PROD-Funktion `is_club_member(uuid)` prüft ausschließlich eine tatsächliche Vereinsmitgliedschaft. `is_club_admin(uuid)` gibt einem Superadmin nur im passenden ausgewählten Vereinskontext Zugriff. Ein neutraler Superadmin ohne Vereinsmitgliedschaft und ohne bereits ausgewählten Kontext kann daher über diese Policy keine Vereinszeilen für den initialen Auswahlbildschirm lesen.

**Folge:** Die Vereinsauswahl im Superadmin-Startbildschirm kann in PROD leer bleiben bzw. die Abfrage kann keine Vereine liefern, obwohl sie in DEV durch den pauschalen Superadmin-Zweig funktioniert. Das wurde durch Schema-/Policyanalyse hergeleitet; ein authentifizierter PROD-UI-Test wurde nicht durchgeführt.

**Wichtig:** Die DEV-Policy darf nicht einfach unverändert nach PROD kopiert werden, denn sie gewährt dem Superadmin wieder pauschalen Tabellenzugriff auf alle Vereinszeilen und widerspricht der festgelegten Kontextregel. Saubere Lösung ist eine gezielte, minimale Auswahlmöglichkeit für Superadmins (z. B. eine eng begrenzte RPC, die nur die für den Auswahlbildschirm benötigten Vereinsfelder liefert und ausschließlich Superadmins zulässt). Anschließend muss die Frontend-Funktion auf diese RPC umgestellt und in DEV getestet werden. PROD erst nach eigener Freigabe.

## 4. Weitere RLS-Abweichungen zur fachlichen Bewertung

- `global_user_roles_select_self_or_superadmin`: DEV erlaubt Superadmins die SELECT-Sicht auf globale Rollen ohne Kontext. PROD verlangt zusätzlich, dass ein Vereinskontextdatensatz vorhanden ist. Da `global_user_roles` global und nicht vereinsbezogen ist, muss geklärt werden, ob Superadmins diese globale Rollenübersicht überhaupt kontextunabhängig lesen dürfen oder ob eine gezieltere Verwaltungs-RPC benötigt wird.
- `training_suspension_audit_select`: PROD berücksichtigt zusätzlich Audit-Einträge, die über eine Suspension-Ausnahme referenziert werden. DEV deckt aktuell nur Audit-Einträge ab, die direkt über `suspension_id` verbunden sind. Das sollte im E05-Audit-Frontend fachlich geprüft werden.
- Die übrigen abweichenden Policydefinitionen sind nicht automatisch semantisch verschieden; mehrere Unterschiede betreffen äquivalente Prädikate, Alias-/Join-Formen oder optimierte `auth.uid()`-Aufrufe. Keine pauschale Synchronisierung durchführen.

## 5. Security Advisor

PROD Security Advisor meldet weiterhin:
- 54 projektweite Hinweise auf SECURITY-DEFINER-Funktionen, die für `authenticated` ausführbar sind.
- 1 Hinweis auf deaktivierten Schutz vor kompromittierten Passwörtern.

Health Advisor: keine Findings. Diese Hinweise wurden in AP03 nicht pauschal verändert und benötigen eine separate Funktions-/ACL-Prüfung sowie eine gesonderte Entscheidung zur Auth-Einstellung.

## 6. Umsetzungsstand und verbleibende Freigabepunkte

**Superadmin-Vereinsauswahl: in DEV umgesetzt und datenbankseitig verifiziert.**

- Neue, eng begrenzte RPC `get_super_admin_clubs()`; keine direkten Vereinszeilen für einen neutralen Superadmin.
- DEV-Policy `clubs_select_member_or_superadmin` entspricht jetzt dem kontextgebundenen PROD-Prinzip.
- Frontend `loadSuperAdminClubs()` in `develop` verwendet die neue RPC.
- SQL-Tests bestanden: neutraler Superadmin (ohne Mitgliedschaft/Kontext) erhält über direkten SELECT 0 Zeilen und über die Picker-RPC 1 Verein; nach Kontextauswahl ist direkter SELECT auf den ausgewählten Verein möglich; normaler Benutzer erhält über die Picker-RPC 0 Zeilen; anonymer Aufruf wird verweigert.
- Vollständiger Nachweis: `docs/DEV_SUPERADMIN_CLUB_PICKER_RLS_2026-11-15.md`.

**Weiterhin offen vor einem Merge develop → main:**

1. Manueller DEV-Frontendtest mit dem Superadmin-Login auf der tatsächlichen DEV-Webseite (Vereinskachel wird angezeigt, Öffnen setzt Kontext und lädt Vereinsdetails).
2. Sichtbarkeit der globalen Rollenliste fachlich festlegen.
3. E05-Audit-Anzeige für Suspension-Ausnahmen prüfen.

Keine PROD-Änderung im Rahmen dieser Korrektur. Die zwei DEV-Migrationen sind im DEV-Ledger erfasst; PROD bleibt unverändert.


## Aktualisierung 15.11.2026 – Abschlussstand für den PROD-Release

Dieser Abschnitt aktualisiert die oben dokumentierte Momentaufnahme. Die zuvor genannten offenen Punkte zum Superadmin-Frontendtest und zur neutralen Vereinsauswahl sind erledigt:

- Der Nutzer hat den manuellen DEV-Test bestätigt: Vereinskachel sichtbar, Verein öffnet sich, Vereinsdetails laden, Rückkehr zur Vereinsauswahl funktioniert.
- AP03 PROD-Härtung wurde bereits erfolgreich ausgeführt (Ledger `20261115134422`): `set_updated_at()` abgesichert, Team-SELECT kontextgebunden; bestehende Kontext-Leserechte erhalten.
- PROD besitzt bereits die kontextgebundene `clubs`-SELECT-Policy und eine kontextgebundene `is_club_admin()`-Funktion. Diese Regeln werden nicht erneut geändert.
- Die einzige noch vorbereitete Datenbankergänzung ist DB-MIG-2026-026: neue `get_super_admin_clubs()`-RPC, ausschließlich für authentifizierte Superadmins und mit minimalen Rückgabefeldern. SQL, Rollback und Dossier liegen in `develop`; Ausführung wartet auf ausdrückliche Freigabe.
- Die Funktionsdifferenzen `get_club_members()`, `get_club_suspension_game_types()` und `get_team_suspension_game_type_settings()` werden vom aktuellen Frontend nicht verwendet und werden nicht in dieses Release aufgenommen.
- Die frühere Aussage „PROD bleibt unverändert“ bezieht sich auf den damaligen Stand vor AP03-Härtung und Paket 12 und ist durch die aktuellen PROD-Ledger-Nachweise überholt.

**Release-Fokus:** Keine weitere allgemeine Inventur. Nach Ausführung und Postflight von DB-MIG-2026-026 folgt die Dokumentationsaktualisierung; danach erfolgt das Frontend-Deployment ausschließlich über den bestehenden Workflow „Deploy PROD“. `index.html` und `main` werden hier nicht manuell geändert.
