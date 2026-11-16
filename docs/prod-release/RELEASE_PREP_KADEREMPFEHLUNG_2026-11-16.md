# PROD-Releasevorbereitung – Kaderempfehlung / Frontendstand 16.11.2026

**Stand:** 16.11.2026  
**Quellbranch:** `develop`  
**Zielbranch:** `main`  
**Supabase DEV:** `pzazqvvoruqnqhcorbwx`  
**Supabase PROD:** `qdugtpzgefpswnnqbusd`  
**PROD-Deploy:** erfolgreich ausgeführt; PROD-Smoke-Test vom Nutzer bestätigt  
**DB-Migration:** für die Kaderempfehlungsänderung nicht erforderlich

## 1. Vorgesehener Releaseumfang

### Kaderempfehlung
- Rollierendes Acht-Wochen-Fenster.
- Gewichtung Anwesenheit / positive Sterne 70:30.
- Zuverlässigkeitsfaktor der Sternbewertung 0 / 0,3 / 0,6 / 1,0.
- Gelbkartenabzug 0 / 1 / 3 / 6 / 10; separates Bewertungs-Kartenkonto.
- Score-Gleichwertigkeitsgruppen mit maximal 2,00 Punkten Abstand zum jeweiligen Gruppenanker.
- Innerhalb der Gruppe tatsächliche Einsätze zuerst; nur `played = true` zählt als Einsatz.
- Aktive E05-Sperre bleibt harter Ausschluss; gültige spieltagbezogene Ausnahme hebt ihn für diesen Spieltag auf.
- Ereignisdaten werden beim Laden des Mannschaftskontexts geladen; vor dem Speichern der Empfehlung werden sie frisch geladen. Bei Ladefehler wird das Speichern abgebrochen.
- Nach erfolgreicher Neuberechnung wird die Spieltagsliste automatisch nach Kaderempfehlung sortiert.
- UI-Kontrastkorrektur für die dunkle Nominierungskachel.

### Separat enthaltene E05-Frontendänderung
Der aktuelle gemeinsame `index.html`-Stand enthält außerdem die bereits dokumentierte Funktion, offene Sperren nach dem Anlegen oder Speichern eines Spieltags erneut zuzuordnen (`reassignOpenTeamSuspensions()`; Commit `55ae095849a03bbfb4f430bed0cc174da55b5eec`).

**DEV-Teststatus: bestanden (16.11.2026).** In der regulären DEV-Mannschaft wurde für Spieler Vier eine rote Karte im Training vom 03.12.2026 erfasst, als noch kein nachfolgender Spieltag existierte. Nach Anlage und Speicherung des Spieltags am 06.12.2026 wurde die offene Sperre automatisch diesem Spieltag zugeordnet. Der Datenbankzustand bestätigte `intended_matchday_id`, Snapshot-Datum und Gegner sowie `manual_target_locked = false`. Nach erneutem Öffnen und Neuberechnen blieb Spieler Vier rot gesperrt und aus der Kaderempfehlung ausgeschlossen. Details siehe Implementierungs-/Testdokumentation. Damit ist der zuvor offene E05-Neuzuordnungstest abgeschlossen.

## 2. Branchvergleich

Read-only GitHub-Vergleich `main...develop`, Stand nach den Dokumentationsnachträgen am 16.11.2026:

- Zum Zeitpunkt der Releasevorbereitung war `develop` gegenüber `main` voraus; der Release wurde anschließend erfolgreich nach PROD ausgerollt.
- `main` ist 0 Commits vor `develop`; kein Branch-Drift in die Gegenrichtung.
- Geänderte Dateien im Vergleich:
  - `index.html` – 53 Ergänzungen, 9 Löschungen.
  - sieben neue Fach-/Testdokumente unter `docs/`.
- Es wurden keine SQL-Migrationsdateien, Rollback-Skripte oder DB-Changelog-/Migration-Log-Dateien durch diesen Releasevergleich geändert.

## 3. Datenbankprüfung

### Read-only Vergleich der für die Empfehlung verwendeten Tabellen

DEV und PROD wurden für folgende Tabellen auf Spaltenebene abgefragt:

- `players`
- `trainings`
- `attendance`
- `training_behavior_events`
- `training_suspensions`
- `training_suspension_exceptions`
- `matchdays`
- `matchday_players`

Die abgefragten Spaltennamen und Datentypen stimmen zwischen DEV und PROD überein. Zusätzlich wurde `players` einschließlich `birth_year` und `preferred_foot` separat verglichen; beide Spalten sind in DEV und PROD vorhanden.

**Nachweisgrenze:** Das ist ein gezielter Vergleich der für diese Funktion relevanten Tabellen/Spalten, kein vollständiger Schema-, Constraint-, Index-, Trigger-, Funktions-, RLS- oder Policy-Diff der gesamten Datenbanken.

### Datenbankänderungen im Release

- Die Kaderempfehlung führt keine SQL-Anweisungen aus und benötigt keine neue Migration.
- Keine neue Tabelle, Spalte, Funktion, RPC, Trigger oder Policy ist Bestandteil der Kaderempfehlungsimplementierung.
- Die isolierte [TEST]-Mannschaft und ihre Spieler-/Trainings-/Ereignis-/Spieltagsdaten liegen ausschließlich in DEV. Sie sind nicht Teil eines Frontend-Deployments und werden nicht nach PROD übertragen.
- Es wurden für diese Releasevorbereitung keine Daten verändert.

## 4. DEV-Teststatus

- Reguläre DEV-Mannschaft: Neuberechnung und automatische Sortierung praktisch geprüft.
- 21.11. und 29.11.: aktive Sperren werden separat rot angezeigt und aus der regulären Empfehlung ausgeschlossen.
- Spieltagbezogene Ausnahme: betroffener Spieler wird wieder regulär berücksichtigt.
- Einsatz-Fairness: vorhandene Einsatzdaten und sichtbare Rangfolge abgeglichen; keine Abweichung festgestellt.
- Numerische vollständige Score-Auditspur: nicht vorhanden, da Scores nicht eigenständig persistiert werden und die SQL-Rekonstruktion nicht alle clientseitigen Eligibility-/Zeitbedingungen exakt abbildet.
- Authentifizierter E05-End-to-End-Test der fünften gelben Karte: offen.
- E05-Neuzuordnung offener Sperren nach Spieltagsspeicherung: in regulärer DEV-Mannschaft praktisch und per Read-only-Datenbankprüfung bestanden.

Details: `docs/testing/KADEREMPFEHLUNG_IMPLEMENTIERUNG_DEV_2026-11-16.md`.

## 5. Durchgeführter PROD-Release und Smoke-Test

1. Der vollständige Frontend-Diff wurde vor dem Release geprüft; enthalten waren die dokumentierten Kaderempfehlungsänderungen, die E05-Neuzuordnung offener Sperren und die UI-Kontrastkorrektur.
2. Der Nutzer hat den bestehenden GitHub-Actions-Workflow `Deploy PROD` selbst gestartet.
3. Der Workflow wurde erfolgreich abgeschlossen.
4. Der anschließende PROD-Smoke-Test wurde vom Nutzer durchgeführt und mit „Sieht gut aus“ bestätigt.

**Release-Status: erfolgreich ausgerollt und Smoke-Test bestanden.**

## 6. Ausdrückliche Nicht-Ziele

- Keine Supabase-Migration.
- Keine Übertragung oder Neuerstellung von DEV-Testdaten in PROD.
- Keine Änderung an PROD-RLS, Policies, RPCs, Triggern oder Tabellen.
- Kein Merge nach `main` und kein PROD-Deploy durch dieses Vorbereitungsdokument.

## 7. Freigabestatus

**Erfolgreich in PROD ausgerollt; Smoke-Test bestätigt.**

Die Kaderempfehlung benötigt nach dem gezielten Schemaabgleich keine DB-Migration. Der E05-Praxistest ist abgeschlossen. Frontend-Diff-Prüfung, explizite Freigabe, PROD-Deploy über den bestehenden Workflow und anschließender Smoke-Test wurden durchgeführt.
