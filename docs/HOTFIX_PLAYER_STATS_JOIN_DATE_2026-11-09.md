# Hotfix: Spielerstatistiken ab Mannschaftsbeitritt und isolierter Main-Deploy

**Datum:** 09.11.2026  
**Status:** Hotfix in `main` gemergt und vom Nutzer erfolgreich nach PROD deployed; Funktionsprüfung in PROD noch ausstehend.

## 1. Anlass und fachliche Korrektur

Trainings- und Spieltagsstatistiken berücksichtigten zuvor auch Ereignisse, die vor dem Eintritt eines Spielers in die Mannschaft lagen. Das verfälschte Teilnahmequoten und konnte die Kaderempfehlung beeinflussen.

Die Auswertung berücksichtigt ein Ereignis jetzt nur, wenn der Spieler zum Ereigniszeitpunkt bereits zur Mannschaft gehörte. Maßgeblich ist `players.created_at` (Zeitstempel mit Zeitzone, NOT NULL, Default `now()`).

**Zeitregel (verbindlich):**
- Eintritt vor Trainingsbeginn bzw. Anstoß: Ereignis ist für die Statistik relevant.
- Eintritt nach Trainingsbeginn bzw. Anstoß: Ereignis ist nicht relevant.
- Eintritt am selben Kalendertag: die Uhrzeit entscheidet.
- Fehlende Ereigniszeit wird im aktuellen Code mit 00:00 behandelt.
- Die Regel wird für Trainings und Spieltage verwendet.

Die Teilnahme-/Anwesenheitserfassung für historische Ereignisse bleibt möglich. Ausgeschlossen wird nur die Berücksichtigung in den betreffenden Statistiken und Vergleichen. Die Trainingshistorie, Trainingsdetails, Spieltagshistorie und Fairness-/Kaderempfehlungslogik verwenden dieselbe Eintrittsberechtigung.

## 2. Technische Umsetzung

- Frontend-Datei: `index.html`; keine Datenbankänderung und keine Migration.
- `players.created_at` war bereits in DEV und PROD vorhanden und ist `timestamptz NOT NULL DEFAULT now()`.
- Hilfsfunktionen prüfen die Eintrittsberechtigung anhand Datum und Startzeit/Anstoßzeit.
- Anwesenheitsstatistik, Trainingsrecency, Spieltagsfairness sowie Spieler-Trainings- und Spieltagshistorien filtern entsprechend.

## 3. DEV-Praxistest

Der Nutzer hat folgende sechs Fälle in DEV praktisch geprüft; alle verhielten sich wie erwartet:

1. Training vor Mannschaftsbeitritt: Anwesenheit kann erfasst werden, zählt aber nicht in die Statistik.
2. Training nach Mannschaftsbeitritt: wird gezählt (Testwert 1/1).
3. Spieltag vor Mannschaftsbeitritt: Anwesenheit/Einsatz kann erfasst werden, zählt aber nicht in die Statistik.
4. Spieltag nach Mannschaftsbeitritt: wird gezählt.
5. Eintritt am selben Tag nach Trainingsbeginn: Training wird nicht gezählt.
6. Eintritt am selben Tag vor Trainingsbeginn: Training wird gezählt.

**Nachweisgrenze:** Die beiden Same-Day-Uhrzeitfälle wurden explizit am Training getestet. Die entsprechende Spieltagslogik nutzt dieselbe gemeinsame Eintrittsprüfung; ein separater Same-Day-Spieltagstest ist nicht dokumentiert.

## 4. Git-/Hotfix-Weg und PROD-Deployment

Der Hotfix wurde bewusst isoliert von weiteren, noch nicht freigegebenen Änderungen in `develop` nach `main` übernommen.

- DEV-Implementierung: Commit `aa980688fadb811ecbdb6b31efdeffd9bcde5aea`.
- Isolierter Hotfix-Branch: `hotfix/player-stats-join-date`.
- Hotfix-Commit: `104ab8ad3c10787c50382bde607caf49033e0050`.
- Pull Request: [#5 – Hotfix Spielerstatistiken ab Mannschaftsbeitritt](https://github.com/bautnhaus/jugendmannschaft/pull/5).
- Merge nach `main`: `8adb30b5f996f277a6df63d30a08ec3f411676b1` (Squash).
- Der Hotfix umfasste ausschließlich `index.html`; der resultierende Datei-Blob war identisch mit dem geprüften DEV-Stand (`ea65f81d53a48bb9a17a15e18b76bfcc3418f6bc`).
- Keine SQL-Ausführung, keine Migration und keine Datenbankänderung.
- Der Nutzer bestätigte anschließend den erfolgreichen PROD-Deploy über den neuen Workflow mit „Alles grün“.

## 5. Neuer Workflow: Main Deploy

Datei: [`.github/workflows/deploy-main.yml`](../.github/workflows/deploy-main.yml)

Der manuell startbare Workflow wurde ergänzend zum bestehenden `Deploy PROD` eingerichtet, um einen bereits isoliert in `main` gemergten Hotfix deployen zu können, ohne dabei den gesamten aktuellen `develop`-Stand nach `main` zu übernehmen.

**Verhalten:**
- Auslösung ausschließlich manuell über `workflow_dispatch`.
- Checkout explizit von Branch `main`.
- Ersetzt im temporären Actions-Arbeitsverzeichnis die DEV-Supabase-URL und den DEV-Publishable-Key durch die PROD-Werte.
- Prüft vor dem Upload, dass die DEV-Konfiguration entfernt und die PROD-Konfiguration vorhanden ist.
- Lädt das Ergebnis als GitHub-Pages-Artefakt hoch und deployt es.
- Führt keinen Git-Push aus und verändert weder `main` noch `develop`.
- Der bestehende Workflow `Deploy PROD` bleibt unverändert.

**Abgrenzung der Deploy-Wege:**

| Workflow | Zweck |
|---|---|
| `Deploy DEV` | DEV-Stand ausliefern |
| `Deploy PROD` | regulärer Releaseweg: geprüften `develop`-Stand kontrolliert nach `main` übernehmen und mit PROD-Konfiguration deployen |
| `Main Deploy` | bereits in `main` vorhandenen Stand deployen, ohne `develop` zu übernehmen oder Branches zu verändern |

**Wichtige Sicherheitsregel:** `Main Deploy` ist kein Ersatz für den regulären Releaseprozess und kein Weg, ungetestete Änderungen direkt in `main` einzubringen. Änderungen müssen weiterhin geprüft, freigegeben und zuerst kontrolliert nach `main` gemergt werden. Der Workflow deployed nur den vorhandenen Inhalt von `main`.

Der Nutzer hat den Workflow am 09.11.2026 manuell auf Branch `main` gestartet und den erfolgreichen Abschluss aller Actions-Schritte bestätigt („Erfolgreich. Alles grün“).

## 6. Noch ausstehend

- Nutzer prüft die korrigierten Statistiken in der laufenden PROD-App. Der erfolgreiche Workflow-Lauf belegt den Deploy, ersetzt aber nicht diese fachliche PROD-Prüfung.
- Temporären Testspieler in DEV nach Abschluss der Prüfung entfernen.
- Keine Testdaten in PROD anlegen.

## 7. Relevante Commits und Dateien

- `develop`: `aa980688fadb811ecbdb6b31efdeffd9bcde5aea`
- Hotfix-Merge `main`: `8adb30b5f996f277a6df63d30a08ec3f411676b1`
- Main Deploy Workflow: `471596887dd71ecf9ded70a8fdcd1f43344bfa05`
- `index.html` Blob nach Hotfix: `ea65f81d53a48bb9a17a15e18b76bfcc3418f6bc`
- Workflow-Datei Blob: `d9e1c5ff4174129d12ddb01dbd3a4144c7593d8a`
