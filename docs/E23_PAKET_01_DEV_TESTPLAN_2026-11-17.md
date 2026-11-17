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
