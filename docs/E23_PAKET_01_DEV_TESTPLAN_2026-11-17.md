# Epic 23 – DEV-Testplan Paket 1: Datenbank-Grundlage

**Status:** vorbereitet, nicht ausgeführt. Ziel: Supabase DEV. PROD ist ausgeschlossen.

## Vorbedingungen
- Aktuellen DEV-Schema- und Policy-Stand sichern.
- Migration Paket 1 ausführen.
- Read-only-Verifikation aus `docs/E23_PAKET_01_VERIFICATION_2026-11-17.sql` ausführen.
- Testkonten: ein Trainer, ein Mannschaftsadmin, ein Superadmin mit explizitem Teamkontext sowie ein nicht berechtigter Nutzer.
- Testspieler und geplante Spieltage derselben Mannschaft verwenden. Keine echten Spielerdaten verändern; Testdaten nach jedem Test kontrolliert bereinigen.

## Testfälle
1. Trainer legt Vormerkung für aktiven, nicht nominierten Spieler an; Verfügbarkeit bestätigt, Begründung gesetzt. Erwartung: pending + created-Audit; keine matchday_players-Zeile wird gelöscht.
2. Trainer legt Vormerkung für nominierten, noch nicht eingesetzten Spieler an. Erwartung: pending + created-Audit; genau die Ausgangsnominierung wird entfernt und als JSON-Snapshot gespeichert.
3. Ausgangsnominierung mit available=false. Erwartung: RPC-Fehler; keine Vormerkung, keine Abwahl.
4. Ausgangsnominierung mit played=true. Erwartung: RPC-Fehler; keine Vormerkung, keine Abwahl.
4. Bereits für einen anderen zukünftigen Spieltag nominierter Spieler. Erwartung: Vormerkung zulässig; diese bestehende Nominierung bleibt bestehen und erfüllt die neue Vormerkung nicht rückwirkend.
5. Verfügbarkeitsparameter false oder NULL. Erwartung: Ablehnung; keine Datenänderung.
6. Leere Begründung. Erwartung: Ablehnung; keine Datenänderung.
7. Doppelte offene Vormerkung desselben Spielers derselben Mannschaft. Erwartung: zweite Erstellung wird abgelehnt; nur eine pending-Zeile.
8. Trainer nimmt pending-Vormerkung mit Begründung zurück. Erwartung: cancelled + Audit; Priorisierung wird später entfernt; Ausgangsnominierung wird nicht wiederhergestellt.
9. Rücknahme ohne Begründung oder durch unberechtigten Nutzer. Erwartung: Ablehnung.
10. Tatsächliche Nominierung des Spielers nach Erstellung auf späterem Spieltag derselben Mannschaft. Erwartung: fulfilled + fulfilled_matchday_id + Audit.
11. Historische Nominierung, die bereits vor Erstellung der Vormerkung bestand. Erwartung: kein rückwirkendes Fulfillment.
12. Änderung nur an team_number, goalkeeper oder played. Erwartung: kein Fulfillment.
13. Nominierung an einem früheren/gleich datierten Spieltag oder in anderer Mannschaft. Erwartung: kein Fulfillment.
14. Audit UPDATE/DELETE/TRUNCATE. Erwartung: Trigger lehnt Änderung ab.
15. Unberechtigter Zugriff auf Tabellen anderer Teams. Erwartung: RLS liefert keine fremden Datensätze.
16. Parallel zwei Create-Aufrufe für denselben Spieler. Erwartung: höchstens eine offene Vormerkung; keine Teilabwahl.
17. Erstellen parallel zu einer tatsächlichen Nominierung. Erwartung: serialisiertes, konsistentes Ergebnis; keine Teiländerung.
18. Transaktionsfehler nach Reminder-INSERT, aber vor Nominierungs-DELETE/Audit (kontrolliert in isoliertem Test). Erwartung: gesamter RPC-Aufruf rollt zurück.

## Abnahmekriterien
- Alle Positiv- und Negativtests bestanden.
- Read-only-Verifikation zeigt RLS aktiv, Policies korrekt, nur authenticated EXECUTE für Create/Cancel, keine Client-Ausführung der internen Triggerfunktionen.
- Keine unerwarteten Trigger-/Policy-Änderungen an bestehenden Tabellen.
- Nach jedem Test sind Testdaten und Auditfolgen nachvollziehbar; keine Produktionsdaten berührt.
- Erst nach Paket-1-Abnahme wird Paket 2 (Empfehlungspriorisierung und Frontend) begonnen.


## Testergebnisse Paket 1 – 17.11.2026

**Testmodus:** isolierte SQL-Testtransaktionen mit temporären Testmannschaften, Testspielern und Testspieltagen. Jede Transaktion wurde mit ROLLBACK beendet. Es verblieben keine Testdaten in der DEV-Datenbank.

| Test | Ergebnis |
|---|---|
| Erstellen für nicht nominierten Spieler | PASS |
| Doppelte offene Vormerkung ablehnen | PASS |
| Vormerkung mit Begründung zurücknehmen | PASS |
| Verfügbarkeitsbestätigung FALSE ablehnen | PASS |
| Leere Begründung ablehnen | PASS |
| Bestehende Ausgangsnominierung atomar entfernen und Snapshot speichern | PASS |
| Rücknahme stellt entfernte Nominierung nicht wieder her | PASS |
| Vorhandene Nominierung mit available=false ablehnen | PASS |
| Bereits eingesetzten Spieler nicht aus Nominierung entfernen | PASS |
| Spätere tatsächliche Nominierung erfüllt Vormerkung | PASS nach Hotfix 1 |
| Audit-Manipulation per UPDATE blockieren | PASS |
| Bestehende Nominierung auf anderem zukünftigen Spieltag blockiert Vormerkung nicht und erfüllt sie nicht rückwirkend | PASS |
| Teammitglied sieht eigene Vormerkung über RLS | PASS |
| Nichtmitglied sieht fremde Vormerkung nicht über RLS | PASS |

**Ergebnis:** 14/14 ausgeführte Funktions- und RLS-Assertions bestanden, wobei die Fulfillment-Prüfung erst nach Hotfix 1 bestand.

### Gefundener Fehler und Korrektur

Der erste Testlauf fand einen Fehler in der Erfüllungslogik: `now()` liefert in PostgreSQL den Transaktionszeitpunkt. Eine Vormerkung und eine spätere Nominierung innerhalb derselben Transaktion erhielten daher denselben Zeitstempel; der strikte Vergleich `created_at < v_now` verhinderte die Erfüllung.

Korrektur in `supabase/migrations/20261117140000_epic23_nomination_reminder_fulfillment_hotfix_dev.sql`: Triggerfunktion verwendet `clock_timestamp()` und `created_at <= v_now`. Hotfix wurde erfolgreich in DEV angewendet. Der erneute Testlauf bestand.

### Nicht ausgeführte Tests

- echte parallele Sessions / Race-Condition-Tests für zwei gleichzeitige Create-Aufrufe;
- Konkurrenz zwischen Create und einer gleichzeitig eingehenden Nominierung;
- gezielter künstlicher Fehler zwischen den einzelnen Statements der RPC, um Rollback unter Fehlerbedingungen zu beobachten;
- Superadmin mit explizitem Teamkontext und explizit unberechtigter RPC-Aufruf als separate Rollenfälle;
- TRUNCATE- und DELETE-Audit-Blockade separat (UPDATE wurde geprüft; der gemeinsame Statement-Trigger umfasst alle drei Ereignisse).

Diese Punkte bleiben offen; Paket 1 ist daher funktional weitgehend geprüft, aber noch nicht vollständig für alle Konkurrenz-/Rollenfälle abgenommen.


## Ergänzende technische Tests – 17.11.2026, Runde 2

- **Parallele Create-Aufrufe:** zwei getrennte Supabase-SQL-Aufrufe für denselben Spieler wurden zeitlich überlappend gestartet. Genau ein Create wurde erfolgreich; der zweite wurde wegen bereits offener Vormerkung abgelehnt. PASS.
- **Create parallel zu späterer Nominierung:** erster Versuch mit vertauschter Reihenfolge der Testspieltage war nicht aussagekräftig und wurde als Testaufbaufehler verworfen. Nach Korrektur (Ausgangsspieltag 18.11.2026, späterer Spieltag 25.11.2026) wurde die Vormerkung bei parallelem Create/INSERT korrekt auf fulfilled gesetzt. Dafür war Hotfix 2 nötig: der Fulfillment-Trigger nimmt jetzt denselben spielerbezogenen Advisory-Lock wie die Create-RPC. PASS nach Hotfix 2.
- **Hotfix 2:** `supabase/migrations/20261117150000_epic23_nomination_reminder_concurrency_hotfix_dev.sql`, erfolgreich in DEV ausgeführt.
- **Audit DELETE:** blockiert durch append-only-Trigger. PASS.
- **Audit TRUNCATE:** blockiert durch append-only-Trigger. PASS.
- **Unberechtigter Cross-Team-RPC-Aufruf:** mit einem Benutzer aus einer anderen Mannschaft getestet; Create wurde mit „Keine Berechtigung für diese Mannschaft“ abgelehnt. PASS.
- **Wichtige Testkorrektur:** ein zunächst verwendeter Testaccount war bereits Mitglied der temporären Testmannschaft und war daher nicht unberechtigt. Der negative Berechtigungstest wurde mit einem anderen Account wiederholt.
- **RPC-Fehler-/Rollback mitten in der Transaktion:** nicht gezielt provoziert. Das erfordert einen kontrollierten Fehler zwischen Reminder-INSERT, optionalem Nominierungs-DELETE und Audit-INSERT; ohne temporäre Test-Trigger-/DDL-Manipulation lässt sich dieser Zwischenzustand über die öffentliche RPC nicht deterministisch auslösen. Keine temporäre DDL-Manipulation vorgenommen.
- **Superadmin mit explizitem Teamkontext:** nicht separat getestet; erfordert einen Testaccount mit Superadmin-Rolle und kontrolliertem ausgewähltem Teamkontext. Kein Frontend-Test wurde durchgeführt.

### Testdaten

Die Testmannschaften/Spieler/Spieltag-Datensätze wurden in DEV angelegt. Ein Teil der Reminder hat append-only Audit-Historie und kann deshalb nicht durch einfaches Löschen entfernt werden. Die Datensätze sind eindeutig als `E23 ... TEMP` markiert und wurden nicht für reale App-Abläufe verwendet. Sie bleiben isoliert in DEV, bis ein kontrollierter Testdaten-Bereinigungsweg unter Wahrung der Audit-Unveränderlichkeit festgelegt ist.
