# E05 PROD Paket 9 – Manuelle Sperren- und Kartenkorrektur

- **Status:** Erfolgreich in PROD ausgeführt und nachkontrolliert am 15.11.2026.
- **Zielumgebung:** Supabase PROD, Projekt qdugtpzgefpswnnqbusd (Jugendmannschaft, eu-west-1, PostgreSQL 17.6.1.166).
- **Quellbranch:** develop.
- **Vorgesehene Katalognummer:** DB-MIG-2026-020.
- **Vorgesehene Migration:** 20261114235000_e05_prod_paket_09_manual_suspension_card_correction.
- **PROD:** Erfolgreich ausgeführt; Supabase-Migrationsversion 20261115051236.
- **DEV:** Unverändert; die drei Paket-9-Migrationen sind seit 08.11.2026 erfolgreich vorhanden.

## 1. Fachlicher Umfang

Paket 9 ergänzt zwei kontrollierte Korrekturfunktionen:

1. correct_suspension(uuid,uuid,text): manuelle Umzuordnung einer offenen Sperre auf einen anderen zulässigen, zukünftigen Spieltag derselben Mannschaft und Saison.
2. correct_training_behavior_event(uuid,text,text): Stornierung eines fehlerhaften gelben/roten Kartenereignisses (voided) oder Wiederherstellung eines zuvor stornierten Ereignisses (active).

Ergänzend:
- Interner Berechtigungshelfer für Trainer/Admin sowie Superadmin im ausgewählten Teamkontext.
- Interne Neuberechnung der offenen Sperren nach Kartenkorrekturen.
- Erweiterung des kanonischen Zuordnungs-RPCs, damit gültige manuelle Zielzuordnungen bei automatischen Neuberechnungen erhalten bleiben.
- Audit-Snapshots der handelnden Person.

## 2. Verbindliche Schutzregeln

- Begründung ist Pflicht.
- Nur Trainer/Admin der betroffenen Mannschaft oder Superadmin im ausgewählten Teamkontext.
- Nur offene Sperren können manuell umgeordnet werden.
- Zielspieltag muss geplant, zukünftig, derselben Mannschaft und Saison zugeordnet sowie nach der bestehenden Spielartenkonfiguration sperrenrelevant sein.
- Aktive Ausnahme für den Zielspieltag schließt ihn aus.
- Eine zweite offene Sperre desselben Spielers darf nicht bereits demselben Zielspieltag zugeordnet sein.
- Gültige manuelle Zielzuordnungen bleiben bei automatischen Neuberechnungen erhalten.
- Ungültige manuelle Zielzuordnungen werden bei der nächsten regulären Ausführung des kanonischen Zuordnungs-RPC freigegeben und neu vergeben.
- Kein zusätzlicher Matchday-Trigger: Vermeidung einer umgekehrten Zeilensperren-Reihenfolge und möglicher Deadlocks.
- Karten- und Sperrenhistorie wird nicht gelöscht.
- Bereits abgeleistete/abgelaufene Sperren werden nicht rückwirkend verändert oder wieder geöffnet.
- Keine direkten Tabellen-Schreibrechte werden erteilt.

## 3. DEV-Quelle und Korrekturen

Die DEV-Abnahme liegt vor: docs/E05_PAKET_09_ABNAHME_UND_AUSFUEHRUNG_2026-11-08.md.

| DEV-Version | Migration | Ergebnis |
|---|---|---|
| 20261108212745 | e05_package_09_manual_suspension_and_card_correction_v6 | Erfolgreich |
| 20261108213035 | e05_package_09_fix_card_correction_player_lock | Erfolgreich |
| 20261108213211 | e05_package_09_fix_card_correction_authenticated_grant | Erfolgreich |

Korrekturen:
- **9.1 Spielerzeilensperre:** correct_training_behavior_event verwendet PERFORM p.id ... FOR UPDATE OF p statt eines SELECT ohne Ergebnisziel.
- **9.2 EXECUTE-Recht:** authenticated erhält nach der Funktionskorrektur ausdrücklich wieder EXECUTE; PUBLIC, anon und service_role bleiben ausgeschlossen.

Die finale PROD-Migration integriert beide Korrekturen in einem atomaren Paket. Sie basiert auf dem dokumentierten Paket-9-Quell-SQL und nicht auf einem unreflektierten Kopieren der heutigen DEV-Funktionsdefinitionen.

## 4. Abgrenzung zu Paket 10 / DB-MIG-2026-010

Die aktuelle DEV-Datenbank enthält spätere Paket-10-Änderungen. Diese werden ausdrücklich nicht vorgezogen.

Paket 9 wird in PROD auf der Paket-8-Baseline umgesetzt:
- Die bestehende Spielartenkonfiguration bleibt maßgeblich.
- Der Paket-9-Allocator bewahrt manuelle Ziele, berücksichtigt aber weiterhin die bisherige Spielartenfilterung.
- Die spätere training-date-basierte Chronologie und die Freigabe aller Spieltage unabhängig vom Spieltyp gehören zu Paket 10 / DB-MIG-2026-010 und bleiben separat.

Die PROD-Migration enthält einen Fail-closed-Preflight, der abbricht, wenn der vorhandene Allocator nicht mehr der erwarteten Paket-8-Baseline entspricht oder Paket-10-Logik bereits vorhanden ist.

Paket 9 berücksichtigt Paket 8: Die Kartenkorrektur verwendet den letzten abgeleisteten gelben Sperrzeitpunkt beziehungsweise den letzten angewendeten vorzeitigen Sperrausgleich als Untergrenze der gelben Kartenchronologie.

## 5. PROD-Live-Preflight (14.11.2026)

Zielprojekt und Schema wurden ausschließlich lesend geprüft.

| Prüfpunkt | PROD-Befund |
|---|---|
| E05 Pakete 1–8 in Migrationshistorie | Vorhanden |
| Paket-9-RPCs/Helfer | Fehlen |
| Paket-9-Spalte manual_target_locked | Fehlt |
| Event-Audit-Snapshot changed_by_snapshot | Fehlt |
| Suspension-Audit-Snapshot changed_by_snapshot | Bereits vorhanden |
| Spielarten-Konfigurationstabellen | Vorhanden |
| Paket-8-Früh-Sperrausgleich-Tabelle | Vorhanden |
| Allocator: bisherige Spielartenfilterung | Vorhanden |
| Allocator: manuelle Ziel-Sperre | Noch nicht vorhanden |
| Allocator: Paket-10-Trainingstaglogik | Noch nicht vorhanden |

Read-only Datenbestand:
- 0 Trainingsereignisse
- 0 Event-Auditzeilen
- 0 Sperren
- 0 Sperren-Auditzeilen
- 0 offene Sperren

RLS ist auf allen vier Event-/Sperren-Tabellen aktiviert. Die bestehenden Append-only-Trigger auf beiden Audit-Tabellen sind vorhanden. authenticated besitzt SELECT; direkte Tabellen-Schreibrechte für authenticated sind nicht vorhanden. Die bestehenden service_role-Rechte bleiben unverändert.

## 6. PROD-Migrationsinhalt

Datei: supabase/migrations/20261114235000_e05_prod_paket_09_manual_suspension_card_correction.sql.

Die Migration:
- ergänzt training_behavior_event_audit.changed_by_snapshot;
- ergänzt training_suspension_audit.changed_by_snapshot nur, falls nicht vorhanden;
- ergänzt training_suspensions.manual_target_locked boolean NOT NULL DEFAULT false;
- erstellt die internen Berechtigungs- und Reconciliation-Funktionen;
- erweitert e05_assign_player_suspensions um die Behandlung manueller Zielzuordnungen;
- erstellt die beiden öffentlichen Korrektur-RPCs;
- vergibt EXECUTE ausschließlich an authenticated für die beiden öffentlichen RPCs;
- belässt bestehende RLS-Policies und Append-only-Audit-Trigger unangetastet.

Es gibt keine Daten-Backfill- oder Statusänderungsanweisung. Bestehende Zeilen erhalten für manual_target_locked den Default false.

## 7. Isolierte PostgreSQL-CI

GitHub Actions:
- Workflow: .github/workflows/e05-prod-package-09-ci.yml
- Test-Baseline: Paket-8-PROD-Testfixture plus Paket-9-Abhängigkeiten.
- Exakte Paket-8-Migration wird zuerst angewendet.
- Anschließend wird die exakte Paket-9-Migration ausgeführt.
- Assertions prüfen Spalten, RLS, Audit-Trigger, RPC-SECURITY-DEFINER, festen search_path, EXECUTE-ACL, korrigierten PERFORM-Spielerlock und Paket-10-Abgrenzung.

Erster CI-Lauf: Run 43648769366 – Migration erfolgreich; eine Assertion hatte lediglich einen Groß-/Kleinschreibungsfehler im Testcode.

Korrigierter finaler CI-Lauf: Run 43648820383 – **success**. Alle Schritte einschließlich Paket-8-Baseline, Paket-9-Migration und Assertions bestanden.

**Testgrenze:** Die CI ist ein isolierter PostgreSQL-Struktur-/ACL-/Quelltexttest. Sie ersetzt keine authentifizierten Supabase-End-to-End-Tests. Die fachlichen DEV-Funktionstests aus der Abnahme bleiben die vorhandene Verhaltens-Testgrundlage.

## 8. Rollback / Wiederherstellung

Die DEV-Abnahme dokumentiert ausdrücklich, dass kein Schema-Rollback vorbereitet ist und die neuen Funktionen/Spalten nicht ohne Abhängigkeits- und Datenprüfung einfach gelöscht werden dürfen.

Für PROD wird daher kein automatischer DROP-Rollback vorgelegt. Nach Nutzung der Korrekturfunktionen können Auditdaten und manuelle Zuordnungen entstanden sein. Ein späterer Rückbau wäre nur nach einer eigenen, datenbewussten Prüfung und gesonderter Freigabe vertretbar. Im Fehlerfall ist ein gezielter Forward-Fix der bevorzugte Weg.

## 9. PROD-Ausführung und Nachkontrolle (15.11.2026)

Die ausdrückliche PROD-Freigabe wurde erteilt. Die Migration wurde anschließend über Supabase apply_migration ausgeführt; das Werkzeug meldete success=true.

Supabase-Migrationshistorie:
- Version: 20261115051236
- Name: e05_prod_paket_09_manual_suspension_card_correction

Read-only Nachkontrolle:
- Beide öffentlichen Korrektur-RPCs vorhanden und SECURITY DEFINER.
- Fester search_path pg_catalog, public, auth bei allen Paket-9-Funktionen.
- EXECUTE ausschließlich für authenticated bei den beiden öffentlichen RPCs; keine Ausführung für PUBLIC, anon oder service_role.
- Interne Helfer und interner Allocator nicht direkt für authenticated, anon oder service_role ausführbar.
- manual_target_locked ist boolean NOT NULL DEFAULT false.
- changed_by_snapshot auf beiden Audit-Tabellen vorhanden.
- RLS auf allen vier Event-/Sperren-Tabellen weiterhin aktiviert.
- Alle vier bestehenden Append-only-Audit-Trigger vorhanden.
- Keine direkten INSERT/UPDATE/DELETE/TRUNCATE-Rechte für authenticated auf den vier Event-/Sperren-Tabellen (0 Grants).
- Allocator bewahrt manuelle Zielzuordnungen und den bisherigen Spielartenfilter; Paket-10-Trainingstaglogik ist nicht enthalten.
- Korrigierter PERFORM-Spielerzeilenlock ist vorhanden.
- Datenbestand nach Ausführung: 0 Trainingsereignisse, 0 Event-Auditzeilen, 0 Sperren, 0 Sperren-Auditzeilen, 0 offene Sperren und 0 manuelle Zielzuordnungen. Es wurden keine vorhandenen fachlichen Datensätze verändert.

Die Ausführung ist damit strukturell und berechtigungsseitig erfolgreich verifiziert. Reale fachliche Korrekturfälle konnten in PROD mangels vorhandener Ereignis-/Sperrendaten nicht ausgeführt werden; die Verhaltensabnahme stützt sich weiterhin auf die DEV-Tests und die isolierte PostgreSQL-CI.

Vollständiger Ausführungsnachweis: DB_MIGRATION_LOG.md, DB-MIG-2026-020.

## 10. Freigabestatus

- Migration, Testqueries, isoliertes CI und aktualisiertes Dossier liegen auf develop.
- DB-MIG-2026-020 ist in DB_MIGRATION_LOG.md als erfolgreich ausgeführte PROD-Migration dokumentiert.
- PROD-Ausführung und Nachkontrolle sind abgeschlossen.
- DEV und GitHub main wurden im Rahmen dieses PROD-Releases nicht verändert.

**Paket 9 ist in PROD technisch ausgerollt und strukturell/berechtigungsseitig verifiziert.**
