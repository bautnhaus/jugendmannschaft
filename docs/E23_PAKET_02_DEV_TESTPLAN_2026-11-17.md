# Epic 23 – Paket 2 DEV-Testplan: Read-API

**Zielumgebung:** Supabase DEV  
**Migration:** 20261117160000_epic23_nomination_reminder_read_api_dev  
**Status:** ausgeführt; Tests bestanden.

| Test | Erwartung | Ergebnis |
|---|---|---|
| Offene Vormerkung für späteren Spieltag abrufen | Spieler-ID, Name und Begründung geliefert | PASS |
| Vormerkung auf Ausgangsspieltag abrufen | Kein Datensatz | PASS |
| Spieler ist bereits für Zielspieltag nominiert | Kein zusätzlicher Reminder-Datensatz | PASS |
| Benutzer ohne Mannschaftsberechtigung | RPC wird abgelehnt | PASS |
| SECURITY DEFINER und fester search_path | korrekt | PASS |
| EXECUTE-Rechte | authenticated ja, anon/PUBLIC nein | PASS |

## Testhinweise
- Testtransaktionen wurden zurückgerollt.
- Keine dauerhaften Testdatensätze angelegt.
- Keine Frontendtests durchgeführt.
- Keine PROD-Änderungen.
