# E05 – DB-MIG-2026-010: Spielartenkonfiguration aus Sperrenlogik entfernen

**Stand:** 12.11.2026  
**Branch:** `develop`  
**Zielumgebung:** ausschließlich Supabase DEV  
**Status:** Erfolgreich in Supabase DEV ausgeführt und read-only verifiziert  
**PROD / main:** unverändert

## 1. Ziel und fachliche Regel

Die Vereins- und Mannschaftskonfiguration für sperrenrelevante Spielarten wird aus der Sperrenlogik entfernt. Jeder Spieltag ist unabhängig von `game_type` ein zulässiges Sperrziel, auch wenn `game_type IS NULL` ist.

Ein Spieltag kann eine offene Sperre ableisten, wenn er tatsächlich durchgeführt wurde (`status = 'done'`) und die Sperre diesem Spieltag zugeordnet ist. Für automatische und manuelle Zielzuordnungen gelten weiterhin die bestehenden Team-, Saison-, Status-, Datums-, Ausnahme- und Berechtigungsprüfungen.

### Chronologie gelber Karten

Die Reihenfolge richtet sich ausschließlich nach `training_date_snapshot ASC, id ASC`, nicht nach `awarded_at` oder dem Zeitpunkt der Eingabe.

Beispiel: Vier Karten sind chronologisch bis 05.11. erfasst; eine weitere Karte wird am 10.11. eingetragen. Wird anschließend eine Karte mit Trainingsdatum 05.11. nachgetragen, ist die fünfte chronologische Karte die Karte vom 10.11. Die Sperre gilt ab dem ersten zulässigen Spieltag **nach dem 10.11.**

Die vorhandene Funktion `e05_reconcile_suspensions_after_event_correction` enthält bereits die chronologische Ermittlung mit `ORDER BY training_date_snapshot, id` und setzt `source_event_id` auf die chronologisch fünfte aktive Karte innerhalb der aktuellen Zählperiode. Diese Funktion wird in DB-MIG-2026-010 ausdrücklich nicht verändert.

## 2. Betroffene Datenbankfunktionen

| Funktion | Änderung |
|---|---|
| `e05_assign_player_suspensions(uuid,uuid,uuid)` | Vereins-/Team-Spielartenkonfiguration und drei `game_type`-Filter entfernen. Teamexistenz, Datum, Saison, Status, Ausnahmen, manuelle Zielreservierung/-sperre und Audit bleiben bestehen. |
| `correct_suspension(uuid,uuid,text)` | Spielartenkonfiguration und Prüfung des Spielartwerts entfernen. Berechtigung, Auslöserdatum, Zukunft/Status, Team/Saison, Ausnahme, Doppelzuordnung, manuelle Sperre und Audit bleiben bestehen. |
| `serve_matchday_suspensions(uuid)` | Spielartenkonfiguration und Spielartprüfung entfernen. Jeder abgeschlossene zugeordnete Spieltag kann die Sperre ableisten, auch bei leerer Spielart. Authentifizierung, Teamkontext, Status, Reihenfolge, Audit und Neuberechnung bleiben bestehen. |

Nicht verändert werden:
- `award_training_behavior_event`
- `e05_reconcile_suspensions_after_event_correction`
- `e05_assert_suspension_correction_permission`
- Tabellen, Spalten, Daten, Indizes, Trigger, Policies, Grants und bestehende Audit-Einträge.

Die drei Funktionen werden per `CREATE OR REPLACE` auf Basis ihrer in DEV vorhandenen Definitionen ersetzt. Dadurch bleiben Signaturen, Eigentümer und bestehende Funktionsrechte erhalten. Die Migration prüft vor jeder Ersetzung, ob die erwarteten Quelltextabschnitte vorhanden sind; bei Abweichung bricht sie ab.

## 3. Erhaltene Regeln

- Zielspieltag gehört zur selben Mannschaft und Saison.
- Automatisches Ziel: `status = 'planned'`, `match_date >= current_date` und `match_date > trigger_training_date`.
- Manuelles Ziel: gleicher Team-/Saisonkontext, geplanter zukünftiger Spieltag und `match_date > trigger_training_date`.
- Aktive Sperrausnahmen schließen den betreffenden Spieltag weiterhin aus.
- Ein Spieltag kann nicht doppelt für mehrere offene Sperren desselben Spielers reserviert werden.
- Gültige manuelle Zielzuordnungen bleiben geschützt.
- Ein erledigter Spieltag darf nicht rückwirkend neu zugeordnet werden.
- Nur ein tatsächlich durchgeführter Spieltag (`done`) kann eine Sperre ableisten.
- Berechtigungs- und Auditprüfungen bleiben unverändert.

## 4. Dateien

- Migration: `supabase/migrations/20261112055415_e05_all_matchdays_suspension_targets.sql`
- Rollback: `supabase/rollback/20261112070000_e05_all_matchdays_suspension_targets_rollback.sql`

Die Migration ist eine guarded source transformation der drei aktuellen DEV-Funktionsdefinitionen. Sie ist absichtlich keine Tabellenmigration und ändert keine fachlichen Daten.

## 5. Vorherige read-only Prüfung

Am 12.11.2026 wurden in Supabase DEV folgende Befunde read-only erhoben:

- Alle drei betroffenen Funktionen existieren mit den erwarteten Signaturen.
- Alle drei Funktionen sind `SECURITY DEFINER`.
- Die automatische Zuordnung enthält genau drei Filter `m.game_type = any(v_types)`.
- Die manuelle Korrektur weist `NULL`-Spielarten und nicht konfigurierte Spielarten zurück.
- Das Ableisten einer Sperre weist `NULL`-Spielarten und nicht konfigurierte Spielarten zurück.
- Die chronologische Reconciliation verwendet `training_date_snapshot` und die Sortierung `training_date_snapshot, id`.
- Migration `20261112070000` ist noch nicht in der Supabase-Migrationshistorie registriert.

Die read-only Prüfung beweist den Ausgangszustand, nicht die erfolgreiche Ausführung der vorbereiteten Migration. Die Migration und ihr Rollback wurden nicht in der Datenbank ausgeführt.

## 6. Verifikation nach späterer Freigabe und Ausführung

1. `pg_get_functiondef` der drei Funktionen prüfen: keine Referenzen mehr auf `club_suspension_settings`, `team_suspension_game_type_settings`, `team_suspension_game_types`, `v_types` oder `game_type` als Sperrenfilter.
2. Signaturen, `SECURITY DEFINER`, `search_path`, Eigentümer und EXECUTE-ACLs mit dem Vorherstand vergleichen.
3. Automatische Zuordnung bei `Meisterschaft`, `Freundschaftsspiel`, `Turnier` und `game_type IS NULL).
4. Ableistung durch einen abgeschlossenen Spieltag jeder der genannten Arten sowie ohne Spielart.
5. Manuelle Korrektur auf alle Spielarten einschließlich `NULL`.
6. Ungültige Fälle weiter abweisen: falsches Team/Saison, nicht geplanter Spieltag, Datum vor/gleich Auslöserdatum, fehlende Berechtigung, aktive Ausnahme, Doppelzuordnung.
7. Nachgetragene Karte testen: Trainingsdatum 10.11. der chronologisch fünften Karte bleibt maßgeblich, wenn die Eingabe am 05.11. nachgetragen wurde.
8. Storno/Wiederherstellung und manuelle Zielreservierung testen; Audit-Einträge kontrollieren.
9. Praxistest mit Trainer, Mannschaftsadmin und Superadmin im ausgewählten Teamkontext.

## 7. Rollback

Das Rollback stellt die vorherige Spielartenlogik in den drei Funktionen wieder her. Es verändert keine Daten oder Audit-Einträge. Vor einem Rollback ist der tatsächliche Funktionsstand zu prüfen. Das Rollback darf nur nach einer erfolgreichen Anwendung dieser Migration und bei passendem vereinfachtem Funktionsstand ausgeführt werden.

## 8. Ausführung und Verifikation am 12.11.2026

- Ausdrückliche Freigabe zur DEV-Ausführung lag vor.
- Supabase meldete `success: true`.
- Registrierte Migrationsversion: `20261112055415` (`e05_all_matchdays_suspension_targets`).
- Alle drei Zielfunktionen sind weiterhin `SECURITY DEFINER`, Eigentümer `postgres`, Suchpfad `pg_catalog, public, auth`.
- EXECUTE-ACLs sind unverändert: `correct_suspension` und `serve_matchday_suspensions` nur `authenticated` plus Eigentümer; `e05_assign_player_suspensions` nur Eigentümer. `anon` besitzt für keine der drei Funktionen EXECUTE.
- Read-only Funktionsprüfung: keine Spielarten-Konfigurationsreferenzen, kein `v_types`, keine Spielartfilter; bei manueller Korrektur keine `game_type`-Zielprüfung mehr.
- Chronologische Reconciliation weiterhin mit `training_date_snapshot` und `ORDER BY e.training_date_snapshot, e.id` nachgewiesen.
- Es wurden keine Tabellen, Spalten, Daten, Trigger, RLS-Policies oder Grants verändert.
- Keine synthetischen Testdaten und keine echten Sperren-/Spieltag-Aktionen wurden ausgeführt. Der Funktionsnachweis ist daher Metadaten-/Definitionsprüfung, kein vollständiger fachlicher E2E-Test.

## 9. Freigabestatus

- [x] Fachliche Vereinfachung bestätigt: jeder Spieltag zählt, auch ohne Spielart.
- [x] Technische Ausgangsdefinitionen in DEV read-only geprüft.
- [x] Migrations- und Rollbackdatei in `develop` vorbereitet.
- [x] SQL-Freigabe zur Ausführung in DEV
- [x] DEV-Migration ausgeführt und read-only verifiziert
- [ ] Frontend-Anpassung separat vorbereitet und freigegeben
- [ ] PROD-Freigabe (separater Vorgang)

**Wichtig:** Die bloße Ablage der Migrationsdatei in GitHub ist keine Ausführung. Bis zur ausdrücklichen SQL-Freigabe bleibt Supabase DEV unverändert.
