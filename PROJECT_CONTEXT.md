# Jugendmannschaft – Projektkontext

**Dokumenttyp:** Zentrale Projektdokumentation  
**Stand:** 03.11.2026  
**Führende Quelle:** Branch `develop` im Repository `bautnhaus/jugendmannschaft`

## 1. Zweck und Dokumentationsprinzip

Diese Datei ist der kompakte Einstieg in das Projekt. Sie enthält den aktuellen, bestätigten Arbeitsstand, verbindliche Arbeitsregeln und Verweise auf die ausführlichen Fachdokumente.

- `develop` ist die zentrale Quelle für App-Entwicklung und Projektdokumentation.
- Nach einem regulären PROD-Release sollen `develop` und `main` denselben Dokumentationsstand enthalten.
- Es gibt keine dauerhaft getrennte DEV- und PROD-Dokumentationsbasis. Historische DEV-/PROD-Unterschiede bleiben dort gekennzeichnet, wo sie fachlich wichtig sind.
- Jedes Thema hat einen eindeutigen Hauptspeicherort. Dieses Dokument verweist auf Detaildokumente, statt deren vollständige Inhalte zu duplizieren.
- Historische Prüfberichte und SQL-Originale werden archiviert, nicht gelöscht. Archivierte Informationen sind keine automatisch aktuellen Statusaussagen.

## 2. Projekt und Produkt

**Repository:** https://github.com/bautnhaus/jugendmannschaft  
**App:** Jugendmannschaft – mobile Web-App zur Organisation von Mannschaften und Teamsportgruppen.

Die Anwendung unterstützt insbesondere:
- Spieler- und Mitgliederverwaltung,
- Mannschaften, Vereine, Rollen und Mitgliedschaften,
- Trainings, Trainingsserien und Anwesenheit,
- Spieltage, Verfügbarkeit und Kaderplanung,
- Empfehlungen und Teambildung,
- Konten, Einladungen, Administration und Datensicherung.

**Produktleitlinien:** iPhone-/Mobile-first, zugleich responsiv für größere Bildschirme; sportartneutral; neutrales Blau als primäre Gestaltungsfarbe; klare Navigation, konsistente Komponenten und verständliche Statusanzeigen. Rot, Gelb und Grün sind semantisch belegte Status-/Bedeutungsfarben und werden nicht als beliebige Dekorations- oder Primärfarben eingesetzt. Die App empfiehlt, die verantwortliche Person entscheidet.

## 3. Technische Umgebung und Branches

| Bereich | Verwendung |
|---|---|
| `develop` | Entwicklungs- und Dokumentationsquelle |
| `main` | PROD-Branch |
| Supabase DEV | `pzazqvvoruqnqhcorbwx` |
| Supabase PROD | `qdugtpzgefpswnnqbusd` |
| Hosting | GitHub Pages |
| Frontend | Single-Page-App, zentrale `index.html` |

Release 1.5.2 wurde laut Nutzerbestätigung am 02.11.2026 nach PROD deployed. Ein unabhängiger Post-Deploy-Smoke-Test und ein unabhängig bestätigter Post-Deploy-Commit-SHA sind nicht dokumentiert.

**Deployment-Ablauf:** Der bestehende manuelle PROD-Workflow übernimmt den Stand von `develop` nach `main` und deployt anschließend. Dieser Workflow bleibt vorerst unverändert. Deshalb müssen vor einem PROD-Release alle Änderungen in `develop` geprüft und freigegeben sein. Diese Dokumentationsbereinigung löst keinen Deployment-Workflow aus.

## 4. Verbindliche Arbeits- und Freigaberegeln

1. Reguläre App-Entwicklung erfolgt zuerst in `develop`; vor Codeänderungen die aktuelle Originaldatei frisch aus GitHub abrufen.
2. DEV testen und Ergebnisse dokumentieren. PROD bleibt bis zu einer gesonderten ausdrücklichen Freigabe unverändert.
3. Vor jeder schreibenden SQL-Ausführung Zweck, Zielumgebung und vollständigen SQL-Text vorlegen und ausdrückliche Freigabe einholen.
4. Jede tatsächlich ausgeführte schreibende SQL-Anweisung wird ausnahmslos im `DB_MIGRATION_LOG.md` dokumentiert – unabhängig davon, ob sie aus einer GitHub-Migrationsdatei, dem Supabase SQL Editor oder einem anderen administrativen Werkzeug stammt.
5. DEV- und PROD-Ausführungen werden getrennt nachgewiesen. Eine SQL-Datei, ein DEV-Erfolg oder ein Nutzerhinweis ersetzt keinen eigenständigen PROD-Ausführungsnachweis. Fehlgeschlagene oder teilweise ausgeführte Schreibversuche werden ebenfalls nachvollziehbar dokumentiert.
6. Keine Originaldefinitionen von Funktionen, Triggern, Policies oder SQL-Migrationen aus dem Gedächtnis rekonstruieren. Vor Änderungen die tatsächlichen Definitionen und Abhängigkeiten aus der Zielumgebung auslesen.
7. Vor GitHub-Schreibzugriffen Branch-HEAD und betroffene Originaldateien erneut prüfen. Nur den freigegebenen Umfang ändern.
8. Kein Deployment, keine PROD-Datenbankänderung und keine Auth-/Edge-Konfigurationsänderung ohne separate ausdrückliche Freigabe.

## 5. Verbindlicher Ablauf für neue Funktionen und Features

Neue Funktionen und Features werden grundsätzlich in einer abgestimmten Konzeptionsfolge entwickelt. Die Umsetzung beginnt nicht direkt mit dem Programmieren:

1. **Anforderungen klären:** Wenn möglich, bestehende Backlog-Einträge und bereits getroffene Produktentscheidungen als Ausgangspunkt verwenden. Ziel, Nutzen, Zielgruppe, Anwendungsfälle, Regeln, Randbedingungen und offene Fragen gemeinsam klären. Fehlende Anforderungen vor dem Entwurf sichtbar machen.
2. **Userflows und Grundstruktur abstimmen:** Zunächst mit schematischen Entwürfen, Wireframes und/oder Low-Fidelity-Skizzen die wesentlichen Abläufe, Navigation, Zustände und Interaktionen darstellen. Erst wenn der Userflow gemeinsam abgestimmt ist, geht es zur visuellen Ausarbeitung.
3. **High-Fidelity-Konzept abstimmen:** Auf Grundlage des freigegebenen Userflows das konkrete UI mit den vorgesehenen Komponenten, Abständen, Typografie, Farben und Zuständen ausarbeiten. Die tatsächliche UI-Umsetzung beginnt erst nach gemeinsamer Abstimmung dieses Konzepts.
4. **Vorhandene Komponenten wiederverwenden:** Bestehende UI-Bausteine – insbesondere Navigation, Icons, Buttons, Listenlayouts, Kacheln, Detailkarten und vergleichbare Elemente – sind grundsätzlich 1:1 aus der vorhandenen Anwendung zu übernehmen und für den jeweiligen Anwendungsfall anzupassen. Sie dürfen nicht ohne Notwendigkeit nachgebaut oder durch optisch ähnliche Eigenvarianten ersetzt werden. Vor einer Umsetzung ist die vorhandene Implementierung zu prüfen und als Referenz zu verwenden.
5. **Neue Komponenten gemeinsam entwickeln:** Ergibt die Prüfung, dass ein benötigter Baustein in der Anwendung noch nicht existiert oder sich ein vorhandener nicht sinnvoll anpassen lässt, wird der Bedarf gemeinsam geklärt und die neue Komponente abgestimmt entwickelt. Sie soll sich anschließend in das bestehende Designsystem einfügen und wiederverwendbar sein.
6. **Farb- und Designregeln beachten:** Neutrales Blau ist die primäre Marken-/Akzentfarbe. Rot, Gelb und Grün haben jeweils semantische Bedeutungen (z. B. Fehler/Warnung/Erfolg bzw. definierte Status) und dürfen nicht beliebig zur Gestaltung eingesetzt werden. Vorhandene Farb- und Komponentenregeln sind konsistent weiterzuverwenden.

**Verbindliche Reihenfolge:** Anforderungen → schematische Entwürfe/Wireframes/Low Fidelity und Userflow-Abstimmung → High-Fidelity-UI-Konzept und Abstimmung → Umsetzung und DEV-Prüfung. Abweichungen davon werden vorab gemeinsam vereinbart.

## 6. Dokumentationsübersicht – eindeutiger Speicherort

| Dokument | Zuständigkeit |
|---|---|
| `PROJECT_CONTEXT.md` | Projektüberblick, aktueller Stand, Regeln und Verweise |
| `DB_CHANGELOG.md` | Technische Datenbankobjekte, Änderungen, Definitionen und Prüfungen |
| `DB_MIGRATION_LOG.md` | Chronologischer Ausführungsnachweis aller schreibenden SQL-Eingriffe |
| `RELEASE_NOTES_*.md` | Fachlicher und technischer Umfang einer veröffentlichten Version |
| `docs/AP01-03_RELEASE_KATALOG_2026-11-01.md` | AP01–AP03-Releaseumfang, Abhängigkeiten und Freigabeblocker |
| `docs/AP01-03_MIGRATION_TEST_MAPPING_2026-11-01.md` | Zuordnung der Migrationen, Tests und offenen Nachweise |
| `docs/AP04-profile-management.md` | AP04-Profilverwaltung, Avatar und geschützte Rollenänderungen; Mitgliederbearbeitung im bestehenden Vereinskontext |
| `docs/CLUB_TEAM_CREATION_PLAN_2026-10-29.md` | Anlage von Vereinen und Mannschaften einschließlich verpflichtender Admin-Zuweisung |
| `docs/CLUB_TEAM_CREATION_PLAN_2026-10-29.md` | Fachliches und technisches Konzept der Vereins-/Mannschaftsanlage |
| `docs/database/archive/PROD_Migrationen_01-43/` | Historische Original-SQL-Dateien, Prüfsummen und Inventar der 43 PROD-Anfragen |
| `docs/archive/` | Historische Projektstände, abgeschlossene DEV-Prüfberichte und alte Arbeitsnotizen |

Die ausführlichen Rollen-/Berechtigungsprüfberichte sind unter `docs/archive/` abgelegt. Sie bleiben als historische Belege erhalten; aktuelle Berechtigungsentscheidungen und offene Punkte sind in den AP-Dokumenten zu pflegen.

## 7. Aktueller Arbeitsstand

### Release 1.5.2
Am 02.11.2026 laut Nutzerbestätigung nach PROD deployed. Die Release Notes dokumentieren den bekannten Umfang und die Grenzen der Nachweise.

### Offener Schwerpunkt: Mitglieder-/Trainer-Einladung
Der Einladungsfehler ist weiterhin offen und nicht Teil von Release 1.5.2:
- Einladungslinks aus DEV führten auf PROD bzw. den normalen Login statt in den erwarteten Passwort-Erstellungsfluss.
- Der Name wurde offenbar trotz Erfolgsmeldung nicht gespeichert.
- Eine Mehrfachzuordnung zu Mannschaften verursachte in einem Fall Loginprobleme; nach Entfernen der zweiten Zuordnung funktionierte die Anmeldung.
- Vor einer neuen Einladung sind vorhandene Auth-Benutzer und Mannschaftszuordnungen zu berücksichtigen.

Erstprüfung: read-only Frontend-Aufruf/Payload, Originalcode der Edge Function `invite-trainer`, DEV Auth Site URL/Redirect-Allowlist, E-Mail-Template sowie Speicherung von Name, Rolle und Mannschaft untersuchen. Keine Änderungen ohne gesonderte Freigabe. Die aktuelle Übergabe liegt in `docs/UEBERGABE_NEUER_CHAT_2026-11-02.md`; der zugehörige Prompt liegt daneben. Die Übergabe ist die ausführliche Fakten-/Arbeitsstandsdokumentation, der Prompt eine kompakte Kopiervorlage für einen Folgechat. Beide bleiben bis zur Fehlerbehebung aktiv und werden danach gemeinsam archiviert.

### AP01–AP03 Multi-Verein
Die Release- und Testzuordnung ist dokumentiert, aber kein ausführbares PROD-Migrationspaket freigegeben. Exakte SQL-Quellen, DEV-/PROD-Objektdifferenzen, Sicherheitsbefunde, Integrationstests und Backup-/Restore-Nachweis müssen vor einer späteren PROD-Freigabe vollständig geprüft werden.

### AP04 Profilverwaltung
Fünf AP04-Migrationen sind in `develop` versioniert. Sie sind nicht automatisch für PROD freigegeben. Frontend-Abhängigkeiten und effektive Berechtigungen sind vor einer Übernahme zu prüfen. Das AP04-Dokument behandelt gemeinsame Profile, Avatare und geschützte Mitglieder-/Rollenbearbeitung; die Anlage neuer Vereine und Mannschaften ist separat im Vereins-/Mannschaftsanlageplan dokumentiert.

### Weitere Produktarbeit
Der Backlog umfasst unter anderem flexible Kaderplanung, Saison- und Vereinsverwaltung, Spielformen je Altersklasse, Dashboard (E09), UI-/Design-System, Navigation, Verfügbarkeitsmanagement, FAQ und Sicherheit. Detaillierte fachliche Anforderungen bleiben in den jeweiligen Epic-/AP-Dokumenten; alte Statusangaben sind vor Umsetzung erneut gegen DEV zu prüfen.

## 8. Datenbankhistorie und Nachweisgrenzen

- Das `DB_CHANGELOG.md` beschreibt technische Änderungen und Prüfungen, ist aber kein vollständiges Ausführungsjournal.
- Das `DB_MIGRATION_LOG.md` enthält 43 historische PROD-Datensätze zu den vom Nutzer bereitgestellten SQL-Anfragen. Der Nutzer bestätigte, dass alle 43 in PROD ausgeführt und damals geprüft wurden. Die Einzelprüfabfragen und Resultate waren nicht Teil des SQL-Archivs und wurden nicht unabhängig erneut eingesehen.
- Die 43 Original-SQL-Dateien liegen im Archiv unter `docs/database/archive/PROD_Migrationen_01-43/`; Inventar und SHA-256-Prüfsummen sind dort dokumentiert.
- Historische Migrationspakete 1–14 sind nicht vollständig mit Original-SQL-Quellen belegt. Keine fehlende Definition aus dem Gedächtnis ergänzen.
- Historische Prüfvermerke sind keine Live-Verifikation. Vor jeder relevanten Änderung den tatsächlichen Stand der jeweiligen Umgebung read-only prüfen.

## 9. Historischer Projektkontext

Die frühere ausführliche Fassung dieses Dokuments wurde unverändert archiviert: [PROJECT_CONTEXT_2026-11-03.md](docs/archive/PROJECT_CONTEXT_2026-11-03.md). Sie enthält ältere Epic-Detailbeschreibungen, Zwischenstände und historische Entscheidungen. Bei Widersprüchen gelten aktuelle, verifizierte Projektdateien und neuere ausdrückliche Nutzerentscheidungen; das Archiv ist kein aktueller Arbeitsauftrag.
