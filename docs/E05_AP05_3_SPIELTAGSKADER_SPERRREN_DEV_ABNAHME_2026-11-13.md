# E05.3 – DEV-Praxistest Spieltagskader und Sperren

**Datum:** 13.11.2026  
**Branch:** `develop`  
**Umgebung:** DEV  
**Ergebnis:** Alle sechs vom Nutzer geprüften Testfälle bestanden.

## Abgenommene Testfälle

| Nr. | Prüffall | Ergebnis |
|---:|---|---|
| 1 | Regulär gesperrter Spieler wird im Spieltagskontext rot dargestellt. | Bestanden |
| 2 | Nach Erteilung einer Spieltagsausnahme ist der Spieler für diesen Spieltag wieder nominierbar. | Bestanden |
| 3 | Nach Zurücknahme der Ausnahme wird der Spieler wieder regulär gesperrt. | Bestanden |
| 4 | Die offene Sperre wird dem nächsten relevanten Spieltag zugeordnet. | Bestanden |
| 5 | Die Kaderempfehlung berücksichtigt den aktuellen Sperrenstatus. | Bestanden |
| 6 | Trainer und Mannschaftsadmin sehen die jeweils vorgesehenen Bedienmöglichkeiten. | Bestanden |

Die Ergebnisse beruhen auf der ausdrücklichen Nutzerbestätigung aller sechs Prüffälle am 13.11.2026.

## Abgrenzung

- Die sechs aufgeführten Spieltags-/Sperrenfälle gelten im DEV-Praxistest als fachlich bestätigt.
- Die Abnahme ersetzt nicht die übrigen offenen Arbeiten aus Epic 05, insbesondere die vollständige Spielercard-Historie und Korrektur-/Audit-End-to-End-Tests, die Prüfung einer zentralen Ereignisansicht sowie die Gesamtregression.
- Keine SQL-Ausführung oder Datenbankänderung im Rahmen dieser Abnahme.
- Keine Änderung an PROD oder GitHub `main`.

## Nächster sinnvoller Arbeitsschritt

Mit den verbleibenden End-to-End-Tests der Spielercard fortfahren: Historie und Auditdetails prüfen sowie gelbe/rote Karten stornieren und wiederherstellen und die daraus resultierenden Kartenkonten-/Sperrenzustände kontrollieren. Dabei weiterhin ausschließlich DEV verwenden.
