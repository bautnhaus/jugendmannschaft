# AP-BR02 Browser-Regressionstest

## Ausführen auf DEV

Nach dem erfolgreichen DEV-Spiegel-Deployment öffnen:

https://dev.kadassist.de/tests/backup/ap-br02-newer-wins-runner.html

Die Seite führt den isolierten Test gegen `src/backup/restore-planner.js` aus und zeigt jeden Prüffall einzeln als PASS/FAIL.

## Sicherheitsgrenze

- ausschließlich synthetische Fixture-Daten
- kein Supabase-Client und keine API-/Netzwerkzugriffe aus dem Testcode
- keine Schreiboperationen und keine Änderungen an echten Teamdaten
- geprüft werden Newer-wins, Never-delete, Older-wins/Keep und Gleichstand der Zeitstempel

## Quellen

- Testlaufseite: `ap-br02-newer-wins-runner.html`
- ursprünglicher Regressionstest: `ap-br02-newer-wins.html`
- geprüfte Implementierung: `../../src/backup/restore-planner.js`

Ein erfolgreicher Browser-Test ist ein isolierter Regressionstest und ersetzt keine DEV-Praxistests oder Restore-Freigabe.
