# PROD-Releasevorbereitung – Kaderempfehlung / Frontendstand 16.11.2026

**Stand:** 16.11.2026  
**Quellbranch:** `develop`  
**Zielbranch:** `main`  
**Supabase DEV:** `pzazqvvoruqnqhcorbwx`  
**Supabase PROD:** `qdugtpzgefpswnnqbusd`  
**PROD-Deploy:** noch nicht freigegeben / nicht ausgeführt  
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

**Freigabegate:** Der dokumentierte Praxistest dieser E05-Neuzuordnung ist noch offen. Da beide Funktionspakete in derselben `index.html` liegen, muss vor dem PROD-Release ausdrücklich entschieden werden:
1. E05-Neuzuordnung in DEV vollständig testen und dann gemeinsam freigeben; oder
2. E05-Neuzuordnung aus dem Release herausnehmen und nur die Kaderempfehlungsänderungen ausliefern.

Keinesfalls stillschweigend einen ungetesteten E05-Codepfad mit PROD ausrollen.

## 2. Branchvergleich

Read-only GitHub-Vergleich `main...develop`, Stand nach den Dokumentationsnachträgen am 16.11.2026:

- `develop` ist 13 Commits vor `main`.
- `main` ist 0 Commits vor `develop`; kein Branch-Drift in die Gegenrichtung.
- Geänderte Dateien im Vergleich:
  - `index.html` – 53 Ergänzungen, 9 Löschungen.
  - sechs neue Fach-/Testdokumente unter `docs/`.
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
- E05-Neuzuordnung offener Sperren nach Spieltagsspeicherung: Praxistest offen.

Details: `docs/testing/KADEREMPFEHLUNG_IMPLEMENTIERUNG_DEV_2026-11-16.md`.

## 5. Vor PROD noch erforderlich

1. Entscheidung zum E05-Neuzuordnungs-Codepfad (testen und mitliefern oder aus dem Release herausnehmen).
2. Finale Prüfung des vollständigen aktuellen `develop/index.html`-Diffs gegenüber `main`, damit keine sachfremden Frontendänderungen versehentlich enthalten sind.
3. Sicherstellen, dass `develop`-Dokumentation vollständig und konsistent ist.
4. Explizite Nutzerfreigabe für den Merge/Deploy nach `main` und den bestehenden Workflow `Deploy PROD`.
5. Nach Deploy: PROD-Funktionstest mit realem Konto und ohne Änderungen an bestehenden Spieler-/Trainingsdaten.

## 6. Ausdrückliche Nicht-Ziele

- Keine Supabase-Migration.
- Keine Übertragung oder Neuerstellung von DEV-Testdaten in PROD.
- Keine Änderung an PROD-RLS, Policies, RPCs, Triggern oder Tabellen.
- Kein Merge nach `main` und kein PROD-Deploy durch dieses Vorbereitungsdokument.

## 7. Freigabestatus

**Vorbereitet, aber nicht PROD-freigegeben.**

Die Kaderempfehlung selbst benötigt nach dem gezielten Schemaabgleich keine DB-Migration. Der offene E05-Praxistest und die abschließende Freigabe des gesamten Frontend-Diffs bleiben Release-Gates.
