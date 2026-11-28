# AP-BR02 Browser-Regressionstest

## Status

**DEV-Browser-Test: BESTANDEN — 5/5 Prüfungen**  
Ergebnis vom Nutzer am 28.11.2026 per Screenshot bestätigt.

Der Lauf ist ein isolierter Regressionstest. Er bestätigt die geprüfte Merge-Planer-Logik, ist aber keine Freigabe für einen Restore mit echten Daten und ersetzt keine DEV-Praxistests.

## Ausführen auf DEV

Nach dem erfolgreichen DEV-Spiegel-Deployment öffnen:

https://dev.kadassist.de/tests/backup/ap-br02-newer-wins-runner.html

Die Seite führt den isolierten Test gegen `src/backup/restore-planner.js` aus und zeigt jeden Prüffall einzeln als PASS/FAIL.

## Bestätigte Prüffälle

1. Neuerer Backup-Zeitstempel schlägt Aktualisierung vor.
2. Neuerer Backup-Zeitstempel löscht keine Datensätze.
3. Älterer Backup-Zeitstempel behält den Zielwert.
4. Älteres Backup löscht keine Datensätze.
5. Gleicher Zeitstempel aktualisiert nicht.

## Sicherheitsgrenze

- ausschließlich synthetische Fixture-Daten
- kein Supabase-Client und keine Netzwerkzugriffe aus dem Testcode
- keine Schreiboperationen und keine Änderungen an echten Teamdaten

## Quellen

- Testlaufseite: `ap-br02-newer-wins-runner.html`
- ursprünglicher Regressionstest: `ap-br02-newer-wins.html`
- geprüfte Implementierung: `../../src/backup/restore-planner.js`

## Operation Contract V1 – synthetischer Test (28.11.2026)

- Pure Entscheidungsfunktion: `src/backup/restore-operation-contract.js`.
- Browser-Fixtures: `ap-br02-operation-contract-v1.html`.
- Prüft Insert, strikt neueres whitelisted Update, Older/Equal Keep, unverifizierbaren Zeitstempel als Conflict, protected-field/table deny, Insert-only collision, zusätzliche Unique-Kollisionen und Never-delete bei Backup-Auslassung.
- Der Test ist neu und **noch nicht vom Nutzer im DEV-Browser bestätigt**.
- Die Funktion ist kein Restore-Executor: sie authentifiziert keine Rolle, validiert keinen Live-Scope, liest keine DB und führt keine Writes aus. Serverseitige Autorisierung und trusted plan derivation bleiben zwingend.


### Regression: protected field (28.11.2026)

Der erste DEV-Browserlauf des Operation Contract V1 zeigte **10/11**. Der Test `Protected team_id change → blocked` lieferte `keep`, weil geschützte Felder bislang erst innerhalb der mutable-field Prüfung berücksichtigt wurden. Das ist fachlich nicht ausreichend: Ein Backup darf geschützte Identitäts-/Scope-Felder nicht abweichend vorschlagen.

Korrektur in Commit `d2a5f3d`: protected-field Unterschiede werden nun vor der Mutable-Allowlist erkannt und als `blocked` zurückgegeben. Nach DEV-Deployment ist der Browser-Test erneut auszuführen. Bis zur bestätigten 11/11 bleibt der Contract-Test offen. Weiterhin keine echten Daten oder Writes.
