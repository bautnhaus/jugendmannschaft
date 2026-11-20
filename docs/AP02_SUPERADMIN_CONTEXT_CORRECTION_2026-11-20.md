# AP02 – gezielte Superadmin-Kontextkorrektur

**Stand:** vorbereitet, nicht ausgeführt  
**Datum:** 20.11.2026  
**Arbeitszweig:** develop  
**Zielreihenfolge:** DEV-Test und Abnahme, danach separates PROD-Paket  
**Freigabeumfang:** Erstellung dieses Korrekturpakets. Keine Datenbankausführung oder PROD-Änderung.

## Fachlich verbindliche Regeln

1. Superadmins bleiben global Superadmins und vereinsneutral.
2. Superadmin-Zugriffe auf Vereinsverwaltung sind ausschließlich im ausdrücklich ausgewählten Vereinskontext zulässig.
3. Eine zusätzliche Mannschaftsadmin- oder Trainerrolle bleibt als Datensatz erhalten.
4. Diese Mannschaftsrolle begründet für einen Superadmin keinen kontextunabhängigen Zugriff. Der eigene Superadmin-Zugriff auf ein Team wird bereits in der zentralen Funktion `is_team_admin(team_id)` ausschließlich über den ausgewählten Teamkontext geprüft. Die zusätzliche gespeicherte Mannschaftsadmin-Rolle eröffnet keinen Bypass. Auch ein ausgewählter Vereinskontext darf bei Teamverwaltungs-RPCs den Mannschaftskontext nicht ersetzen.
5. Normale Vereinsadmins, Mannschaftsadmins und Trainer behalten ihre bisherigen Rollenrechte.
6. Keine DEV-Daten werden nach PROD übernommen.

## Live-Befund PROD (read-only, 20.11.2026)

- Ein globaler Superadmin.
- Eine direkte Zeile in `club_members`.
- Eine `club_admin`-Zuweisung in `club_member_roles`.
- Eine zusätzliche Mannschaftsadmin-Zuweisung in `team_member_roles` sowie die passende Zeile in `team_members`.
- `club_member_roles.user_id` referenziert `club_members.user_id` mit `ON DELETE CASCADE`.
- Keine weiteren Fremdschlüssel verweisen auf `club_members` oder `club_member_roles`; keine eigenen Trigger auf diesen beiden Tabellen.

## Korrekturumfang

- `can_manage_club_context(uuid)`: CASE-Priorität. Wenn der aufrufende Benutzer Superadmin ist, zählt ausschließlich `user_club_context`; die zusätzliche club_admin-Rolle darf keinen OR-Fallback eröffnen.
- Die Ein-Argument-Funktion `is_team_admin(team_id)` erzwingt für Superadmins ausschließlich den ausgewählten Mannschaftskontext; die Zwei-Argument-Funktion bleibt eine allgemeine Zielrollenabfrage.
- `admin_add_team_role` und `admin_remove_team_role` wechseln für die Aufruferprüfung auf `is_team_admin(team_id)`. Die alternative Vereinsadmin-Berechtigung über `can_manage_club_context` bleibt für Nicht-Superadmins erhalten, wird für Superadmins aber ausdrücklich ausgeschlossen. Ein ausgewählter Vereinskontext allein verleiht dem Superadmin somit keine Mannschaftsadmin-Rechte.
- Weitere Verwaltungs-/Read-RPCs wechseln auf die Ein-Argument-Prüfung: `admin_update_member_profile`, `admin_set_trainer_label`, `get_team_trainers`, `get_team_trainers_v2`.
- `is_team_admin(uuid)`: Superadmins werden vor der Rollenprüfung ausschließlich über `has_selected_team_context(team_id)` autorisiert; Nicht-Superadmins behalten die bisherige Rollenprüfung.
- `get_team_role_change_log(uuid)`: direkter Superadmin-Bypass wird an `has_selected_team_context(team_id)` gebunden.
- Die Vereinsadmin-Alternative in `admin_add_team_role` und `admin_remove_team_role` gilt ausdrücklich nur für Nicht-Superadmins; Superadmins benötigen für diese teambezogenen Schreibaktionen den ausgewählten Mannschaftskontext.
- Die Zwei-Argument-Funktion `is_team_admin(user_id, team_id)` bleibt als allgemeine Rollenabfrage für Zielbenutzer unverändert. Sie darf nicht global umgedeutet werden.

## Reversible Rollenbereinigung

Die vorbereitete DEV-Migration sichert die direkte Vereinsmitgliedschaft und alle zugehörigen Vereinsrollen in einem separaten, für Clientrollen gesperrten Schema `ap02_release_private`. Danach wird ausschließlich die Zeile aus `club_members` entfernt; die `club_admin`-Zeile wird durch den vorhandenen CASCADE-Fremdschlüssel entfernt.

Die zusätzlichen Teamrollen und Teammitgliedschaften werden weder gelöscht noch aktualisiert. Die Migration vergleicht deren vollständige Rollen-/Mitgliedschaftslisten im Postflight mit dem Snapshot. Der Snapshot bleibt bis zum Ablauf des Rollback-Fensters erhalten. Der Rollback stellt Vereinsmitgliedschaft und Vereinsrollen aus dem Snapshot wieder her und setzt die vorherigen Funktionsbedingungen zurück.

## Dateien

- Migration: `supabase/migrations/20261120120000_ap02_superadmin_context_hardening_dev.sql`
- Rollback: `supabase/rollback/20261120120000_ap02_superadmin_context_hardening_rollback_dev.sql`

Die Migration ist absichtlich streng und bricht bei abweichendem Bestand ab. Sie ist eine DEV-Fassung. Für PROD wird nach erfolgreichem DEV-Test eine separate, gegen den dann aktuellen PROD-Livebestand geprüfte Fassung erstellt. Die DEV-Migration darf nicht ungeprüft in PROD ausgeführt werden.

## Noch offene Prüfungen vor Ausführung

1. Statische SQL-Prüfung und Abgleich der zentralen Kontextfunktionen sowie aller neun gezielten Berechtigungsersetzungen in sieben RPC-Definitionen mit den DEV-Live-Definitionen.
2. DEV-Transaktionssimulation (inkl. Positiv-/Negativtests für Superadmin ohne Kontext, mit falschem Kontext und mit passendem Kontext).
3. Regression für normalen Vereinsadmin, Mannschaftsadmin und Trainer.
4. Nachweis, dass die zusätzliche Superadmin-Teamrolle unverändert bleibt.
5. Rollback-Simulation in einer kontrollierten DEV-Transaktion und Nachweis der Wiederherstellung.
6. Erst danach separate Freigabe zur tatsächlichen DEV-Ausführung.

## Status / Sicherheitsgrenze

- DEV-Live-Preflight (20.11.2026): genau ein Superadmin, eine direkte Vereinsmitgliedschaft, eine club_admin-Rolle, eine Teamrolle und eine Teammitgliedschaft; FK `club_member_roles.user_id -> club_members.user_id ON DELETE CASCADE` bestätigt; keine benutzerdefinierten Trigger auf den beiden Vereinsmitgliedschaftstabellen.
- DEV-Live-Preflight (20.11.2026): genau ein Superadmin, eine direkte Vereinsmitgliedschaft, eine club_admin-Rolle, eine Teamrolle und eine Teammitgliedschaft; FK `club_member_roles.user_id -> club_members.user_id ON DELETE CASCADE` bestätigt; keine benutzerdefinierten Trigger auf den beiden Vereinsmitgliedschaftstabellen.
- Keine SQL-Migration ausgeführt.
- Keine Rollen oder Mitgliedschaften verändert.
- Keine PROD-Änderung.
- Kein Frontend-Deploy.
- IMG-SEC-PROD bleibt bis zur AP02-Abnahme gesperrt.
