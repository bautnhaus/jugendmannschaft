# Jugendmannschaft – Projektkontext

**Dokumenttyp:** Zentrale Projektdokumentation  
**Stand:** 04.11.2026  
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
9. **Dokumentationsführung erfolgt zentral in `develop`:** Fachliche Entscheidungen, Konzepte, Vorschläge, technische Umsetzung, DEV-Prüfungen, offene Punkte und Releasevorbereitung werden dort dokumentiert – nicht erst nach Umsetzung. Feature-Branches dienen der isolierten Codearbeit und dürfen nicht der einzige Ablageort maßgeblicher Projektinformationen sein. Vor einer Übernahme werden Code und Dokumentation gezielt mit `develop` abgeglichen; ein kompletter Branch wird nicht blind gemerged.

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
| `docs/SUPABASE_CHANGE_CONTROL.md` | Verbindlicher Ablauf und Dokumentationspflicht für alle Supabase-Änderungen |
| `docs/proposals/single-team-membership-guard/README.md` | Führende Spezifikation des freigegebenen Rollenmodells, der ausgeführten DEV-Migration und der offenen Edge-/Praxistests |
| `DB_CHANGELOG.md` | Technische Datenbankobjekte, Änderungen, Definitionen und Prüfungen |
| `DB_MIGRATION_LOG.md` | Chronologischer Ausführungsnachweis aller schreibenden SQL-Eingriffe |
| `SUPABASE_CHANGELOG.md` | Chronologischer Nachweis tatsächlicher nicht-SQL-basierter Supabase-Laufzeit- und Konfigurationsänderungen |
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

### Release 1.6 – Mitglieder-/Trainer-Einladung (DEV-Implementierung, Praxistests offen)
Die read-only Bestandsaufnahme ist abgeschlossen und die erste Umsetzung wurde nach ausdrücklicher Nutzerfreigabe ausschließlich in DEV begonnen:
- Zentrale DEV-Datenbankfunktion `admin_complete_member_invitation()` wurde als Migration `20261103203047` ausgeführt und in `DB_MIGRATION_LOG.md` / `DB_CHANGELOG.md` dokumentiert (DB-DEV-007).
- Neue Edge Function `invite-member` ist in Supabase DEV ACTIVE (Version 3, JWT-Prüfung aktiv); der Redirect wird über die Supabase-Projektkennung DEV-/PROD-getrennt bestimmt.
- Die Einladungswege für Super Admin, Vereinsadmin und Mannschaftsadmin verwenden im aktuellen Frontend den gemeinsamen Einladungspfad.
- `profiles.display_name` ist die einzige maßgebliche Quelle des persönlichen Namens. Frontend-Verwendungen von `team_members.admin_label` sind entfernt; bestehende Daten in diesem Feld bleiben unverändert.
- Ein reines Vereinsmitglied ohne Mannschaft erhält einen eingeschränkten App-Einstieg statt eines Login-Abbruchs.
- `develop` und das DEV-Repository `jugendmannschaft-dev/main` wurden nach dem Push auf denselben Commit gespiegelt; die ausgelieferte `index.html` stimmt im SHA überein.

**Praxistest 04.11.2026:** Ein realer DEV-End-to-End-Fall für eine Trainer-Einladung wurde erfolgreich durchgeführt: E-Mail empfangen, DEV-Link geöffnet, Passwort vergeben und Dashboard erreicht. Eine read-only Datenbankprüfung bestätigte Auth-Bestätigung, Profilname, Vereinsmitgliedschaft und Trainerrolle. Weitere Rollen-/Kontextfälle und Wiederholungs-/Fehlerfälle bleiben offen.

**Historischer Folgefehler – behoben am 04.11.2026:** In der Superadmin-Mitgliederliste erschien zunächst die E-Mail statt des gespeicherten Profilnamens; das Namensfeld im Bearbeitungsdialog war leer. Ursache war, dass `get_club_members_v2` keine Profilfelder lieferte und ein direkter Profil-SELECT durch die damalige RLS-Regel im ausgewählten Superadmin-Vereinskontext blockiert wurde. Die kontextgebundene read-only RPC `get_club_members_v3` wurde als DB-DEV-008 erfolgreich ausgeführt und die Frontend-Anbindung wurde im DEV-Spiegel manuell bestätigt. Die genaue Ausführung und verbleibende Profilbild-/Speicher-/Kontextprüfungen sind in `DB_MIGRATION_LOG.md`, `DB_CHANGELOG.md` und `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md` dokumentiert.

Weitere Rollen-/Kontextfälle, bestehende bestätigte und unbestätigte Auth-Benutzer sowie Fehler- und Wiederholungsfälle bleiben offen. Custom SMTP wurde nicht geändert.

Ausführlicher Umsetzungsstand und Testmatrix: `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md`. Die Übergabe vom 02.11.2026 und der damalige Prompt bleiben historische Ausgangsdokumente, nicht der aktuelle technische Status. **PROD und `main` bleiben unangetastet; ein PROD-Release erfordert eine separate ausdrückliche Freigabe.**

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


**Datenbank-Folgekorrektur 04.11.2026:** Die neue read-only RPC `public.get_club_members_v3(uuid)` wurde ausschließlich in Supabase DEV als Migration `20261104113632_club_member_profiles_read_v3_dev` erfolgreich ausgeführt. Sie liefert Profilname und Avatar im explizit berechtigten Vereinskontext. Funktionsdefinition, SECURITY DEFINER/search_path, EXECUTE-Rechte und unveränderte `profiles`-RLS-Policies wurden geprüft. SQL-Quelldatei: `supabase/migrations/20261104113632_club_member_profiles_read_v3_dev.sql`; Ausführungsnachweis: `DB_MIGRATION_LOG.md`, DB-MIG-2026-002; Objektbeschreibung: `DB_CHANGELOG.md`, DB-DEV-008. **Frontend-Integration 04.11.2026:** Commit `cb0a5b943e3bb367a9f7c5bfafd693803ec39ea0` bindet beide Mitgliederlisten und den Bearbeitungsdialog an die neue RPC an; Name/Avatar kommen aus dem RPC-Datensatz. Drei geänderte JavaScript-Blöcke wurden syntaktisch erfolgreich geprüft. Deploy DEV #41822962197 erfolgreich und DEV-Spiegel-Blob-SHA identisch. **Noch offen:** manueller UI-Praxistest und Positiv-/Negativtests zum Vereinskontext. PROD bleibt unangetastet.


**Praxistest 04.11.2026 – Superadmin-Profilanzeige:** Nach dem DEV-Deployment hat der Nutzer beide Prüfungen bestätigt: In der Vereinsmitgliederliste erscheint der persönliche Name statt der E-Mail-Adresse; beim Öffnen von „Mitglied bearbeiten“ wird der gespeicherte Name korrekt übernommen. Der Folgefehler ist im Superadmin-Kontext behoben. Weiterhin offen sind Profilbildanzeige, Speichern/Neuladen, Vereinsadmin-Kontext und negative Kontexttests. Keine weitere SQL-Änderung; PROD unverändert.


## 10. Rollenmodell – Ein-Mannschaft-Regel und zusätzliche Verwaltungsrollen (04.11.2026)

**Fachlich freigegeben:** Ein Benutzer kann höchstens einer Mannschaft tatsächlich zugeordnet sein. Superadmin und Vereinsadmin sind zusätzliche, davon getrennte Berechtigungen.

- Ein bestehendes Mannschaftsmitglied kann nachträglich Superadmin, Vereinsadmin oder beides werden.
- Vorhandene Zeilen in `team_members` und `team_member_roles` sowie bestehende Mannschaftsrollen bleiben bei der Vergabe oder Entfernung dieser zusätzlichen Rollen vollständig erhalten.
- Ein Mannschaftsmitglied darf weiterhin keiner zweiten Mannschaft zugeordnet werden.
- Superadmins und Vereinsadmins können in den Mannschaftskontexten ihres ausgewählten/eigenen Berechtigungsbereichs administrieren, ohne dort jeweils Mitglied zu sein.
- Die Regel gilt für die zugeordnete Zielperson; sie beschränkt nicht die Kontextrechte des handelnden Administrators.
- Die Vereinsadmin-Rolle kann über `admin_set_club_member_role` ergänzt werden, ohne die Mannschaftszuordnung zu verändern. Die globale Superadmin-Rolle ist in der aktuellen App nicht über den Mitgliedereditor vergebbar; für `global_user_roles` besteht für angemeldete Nutzer kein Schreibrecht. Die Ein-Team-Regel blockiert eine vertrauenswürdige spätere Vergabe nicht; der Vergabeprozess ist separat zu klären.

**Technischer Status (04.11.2026):** DB-DEV-009 wurde ausschließlich in Supabase DEV erfolgreich ausgeführt (Migrationsversion `20261104143331`); beide Teamzuordnungstabellen haben aktive Ein-Mannschaft-Trigger, Index und vier angepasste RPCs sind read-only verifiziert. Es bestehen 0 Benutzer mit Mehrfachzuordnungen; keine RLS-Policies und keine vorhandenen Mitgliedschaftsdaten wurden durch die Migration verändert. Vollständige Nachweise: `DB_MIGRATION_LOG.md` (DB-MIG-2026-003) und `DB_CHANGELOG.md` (DB-DEV-009). Das Frontend in `develop/index.html` wurde in den DEV-Spiegel `jugendmannschaft-dev/main` synchronisiert; Blob-SHA `ebf7363aa2df1f5b3fc465934e2fab8cea3ef0c1`; manueller Browser-/Praxistest offen. Die Supabase-Edge-Function-Quellen liegen in `develop`, live sind `invite-member` und `invite-trainer` aber weiterhin Version 3; keine Edge Function wurde aktualisiert. Für die beiden Edge-Deployments ist separate ausdrückliche Freigabe erforderlich. PROD ist unverändert.

**Zentrale Ablage in `develop`:**
- Spezifikation und Status: `docs/proposals/single-team-membership-guard/README.md`
- Ausgeführte SQL-Migration: `supabase/migrations/20261104143331_db_dev_009_single_team_membership_guard.sql`
- Konzept-/Review-Entwurf: `docs/proposals/single-team-membership-guard/migration.sql`
- Read-only Nachprüfung: `docs/proposals/single-team-membership-guard/after_apply_verification.sql`
- Ausführungsnachweis: DB-MIG-2026-003 in `DB_MIGRATION_LOG.md`; technische Objektbeschreibung: DB-DEV-009 in `DB_CHANGELOG.md`
- Supabase-Änderungsprozess: `docs/SUPABASE_CHANGE_CONTROL.md`; tatsächliche Nicht-SQL-Ausführungen in `SUPABASE_CHANGELOG.md`

Der Feature-Branch `feature/dev-single-team-membership-guard-review` ist ein historischer Review-Arbeitsstand und keine führende Quelle. Die gezielt geprüften Frontend-/Edge-Änderungen sind inzwischen nach `develop` übernommen. Weitere Änderungen erfolgen in `develop`; der Feature-Branch wird nicht als zweite Dokumentationsbasis gepflegt und nicht vollständig ohne Prüfung gemerged.
