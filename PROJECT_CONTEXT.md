# Jugendmannschaft – Projektkontext

## Aktueller Stand – E05 Spielartenvereinfachung (12.11.2026)

- DB-MIG-2026-010 `20261112055415_e05_all_matchdays_suspension_targets` wurde nach ausdrücklicher Freigabe erfolgreich ausschließlich in Supabase DEV ausgeführt und read-only verifiziert. Alle Spieltage sind unabhängig von `game_type`, einschließlich NULL, mögliche Sperrziele.
- Die chronologische Gelbkartenermittlung bleibt nach `training_date_snapshot ASC, id ASC`; bei nachgetragenen Karten ist das Trainingsdatum und nicht der Eingabezeitpunkt maßgeblich.
- Frontend-Vereinfachung wurde in `develop/index.html` umgesetzt (Commit `74842c6632b512b57015d78dbdf29da91d4df5cf`): Vereins- und Mannschaftseinstellungen, Navigation, Render-/Save-Handler und die zugehörigen vier Settings-RPC-Aufrufe wurden aus der Oberfläche entfernt. Spielart bleibt als normales Spieltagsfeld erhalten.
- Die vorhandenen Einstellungsdaten, Tabellen und vier Settings-RPCs bleiben in der Datenbank bestehen; keine Datenbereinigung oder zusätzliche SQL-Änderung durchgeführt.
- JavaScript-Syntaxprüfung beider Inline-Scripts erfolgreich; statische Suche nach alten Einstellungsreferenzen ohne Treffer.
- Führende Frontend-Dokumentation: `docs/E05_FRONTEND_SPIELARTEN_ENTKOPPELN_2026-11-12.md`. DB-Nachweis: `docs/E05_DB_MIG_2026_010_SPIELARTENKONFIGURATION_ENTKOPPELN.md`, `DB_MIGRATION_LOG.md` und `DB_CHANGELOG.md`.
- **Noch offen:** DEV-Praxistests der Vereins-/Team-/Superadmin-Ansichten, automatische Sperrenzuordnung bei allen Spielarten einschließlich NULL, manuelle Sperrenkorrektur, normale Spielartpflege sowie iPhone-/Darkmode-Darstellung.
- PROD, GitHub `main` und die PROD-Website wurden nicht verändert. Keine Freigabe für einen PROD-Release erteilt.

**Dokumenttyp:** Zentrale Projektdokumentation  
**Stand:** 09.11.2026  
**Führende Quelle:** Branch `develop` im Repository `bautnhaus/jugendmannschaft`

## Aktueller Stand – verbindliche Aktualisierung vom 09.11.2026

### Hotfix Spielerstatistiken ab Mannschaftsbeitritt / Main Deploy
- Der Hotfix zur zeitlichen Begrenzung der Spielerstatistiken auf den Mannschaftsbeitritt wurde in DEV mit sechs Praxistests erfolgreich geprüft und über PR #5 isoliert nach `main` gemergt.
- Der Nutzer hat den anschließenden PROD-Deploy über den neuen manuellen Workflow `.github/workflows/deploy-main.yml` erfolgreich bestätigt.
- Der Workflow deployt ausschließlich den vorhandenen `main`-Stand mit PROD-Supabase-Konfiguration; er übernimmt keine Änderungen aus `develop` und schreibt nicht in Git.
- Die fachliche Funktionsprüfung in PROD und die Bereinigung des temporären Testspielers in DEV stehen noch aus.
- Detailnachweis: `docs/HOTFIX_PLAYER_STATS_JOIN_DATE_2026-11-09.md`.
- Keine Datenbankänderung und keine SQL-Migration.

## Aktueller Stand – verbindliche Aktualisierung vom 06.11.2026

Dieser Abschnitt hat Vorrang vor älteren datierten Zwischenständen weiter unten in dieser Datei. Historische Einträge bleiben als Verlauf erhalten und sind nicht automatisch der aktuelle Status.

### Aktueller Release- und Branchstand
- PROD Release 1.5.2 wurde am 02.11.2026 vom Nutzer als deployed bestätigt.
- AP05 / Mitgliedereinladung ist in DEV und PROD bereitgestellt. DEV `invite-member` Version 5 ACTIVE; PROD `invite-member` Version 1 ACTIVE; PROD Legacy-Funktion `invite-trainer` Version 3 ACTIVE und liefert HTTP 410 mit Verweis auf `invite-member`. JWT-Verifikation ist jeweils aktiviert.
- Nutzer hat den PROD-Web-Deploy und den vollständigen Standard-Einladungsablauf in PROD erfolgreich bestätigt. Die Auth-Site-URL und Redirect-URL wurden vom Nutzer im Dashboard auf `https://kadassist.de` bzw. `https://kadassist.de/` gesetzt.
- AP05 Standardabläufe DEV und PROD sind abgeschlossen. Optionale Randfalltests (zweite Mannschaftszuordnung, nicht erlaubte CORS-Origin, erneute Einladung bestätigter Konten) bleiben separat offen und blockieren den dokumentierten Standardablauf nicht.
- Am 06.11.2026 wurden `main` und `develop` nach dem PROD-Deploy als vollständig identisch bestätigt: Commit `dd0cd8f405673e488ed20c2daf724d2583f7be0d`, 0 Commits voraus/zurück, keine abweichenden Dateien. Spätere Dokumentationsänderungen auf `develop` erzeugen wieder einen temporären Vorsprung; nach Abschluss der Dokumentation kann der bestehende PROD-Workflow erneut ausgeführt werden, um beide Branches zu synchronisieren.
- Maßgeblicher Detailnachweis: `docs/AP05_INVITE_MEMBER_DEV_DOMAIN_2026-11-05.md` und `SUPABASE_CHANGELOG.md` (SUPA-2026-002).

### Domains, Hosting und DNS
| Zweck | Adresse / Zuständigkeit |
|---|---|
| PROD-App | `https://kadassist.de` |
| DEV-App | `https://dev.kadassist.de` |
| Hosting | GitHub Pages |
| Domainregistrar | STRATO – Domainregistrierung und Vertragsverwaltung für `kadassist.de` |
| DNS-Verwaltung | Cloudflare – DNS-Zone und DNS-Einträge für die Domain |
| Cloudflare-Tarif | Free Plan (0 €); keine kostenpflichtige Cloudflare-Option als Voraussetzung dokumentiert |

STRATO bleibt Registrar; Cloudflare verwaltet die DNS-Zone. Die Rollen nicht verwechseln: Änderungen an DNS-Einträgen erfolgen in Cloudflare, Domainvertrag/Verlängerung beim Registrar STRATO. Die Domain-/DNS-Verwaltung ist von GitHub-Branch-Deployments und Supabase-Konfiguration getrennt. Keine DNS-, Nameserver- oder Registraränderung ohne konkreten Anlass und ausdrückliche Freigabe. Es wurden im Rahmen des AP05-Abschlusses keine STRATO- oder Cloudflare-Einstellungen geändert.

### Abgeschlossene Themen nicht erneut aufrollen
- AP05 Standard-Einladungsablauf DEV/PROD einschließlich Domain-Redirect, Passwortvergabe und Anmeldung: abgeschlossen und vom Nutzer bestätigt.
- PROD-Deployment des Webstands nach der AP05-Funktionsbereitstellung: vom Nutzer bestätigt.
- GitHub-Synchronität nach dem letzten regulären PROD-Deploy: am 06.11.2026 mit `identical` bestätigt.
- Diese Prüfungen nicht routinemäßig wiederholen. Nur bei einem konkreten Fehler, einer neuen Änderung mit direkter Auswirkung oder einem nachvollziehbaren Widerspruch gezielt erneut prüfen.

### E05 / AP05 – Read-only DEV-Abgleich Ereignis-RPCs (08.11.2026)
- Supabase DEV `pzazqvvoruqnqhcorbwx` wurde read-only gegen Rollen-/Kontexthelfer, Trainings-, Spieler-, Anwesenheits-, Saison- und Profilstrukturen abgeglichen.
- Ergebnis und konkrete Implementierungsbedingungen sind in `docs/E05_SERVER_STATE_TRANSITIONS_RPC_CONTRACTS_2026-11-08.md`, Abschnitt 10, dokumentiert.
- Kritische Befunde: `is_team_member()` allein ist keine explizite Trainerrollenprüfung; Rollen liegen in `team_member_roles` (`trainer`/`admin`). Für aktive Saisons existiert kein DB-Unique-Constraint je Team; RPC muss Kardinalität explizit prüfen. `attendance.present=true` ist Anwesenheitsquelle. Profilquelle ist `profiles.display_name`.
- **Status:** nur read-only Abfragen und Dokumentationsänderung; keine SQL-Schreibanfrage, keine Migration, keine Datenbankänderung, kein PROD-Eingriff.
- Nächster Schritt: Ereignis-RPC-SQL-Entwurf erstellen, der Rollen-/Saison-/Anwesenheitsprüfungen, atomare Audits und Sperrenauslösung abdeckt; anschließend Syntax-/statische Prüfung und isolierter PostgreSQL-17.6-Test.

### E05 / AP05 – Serverseitige RPC-Verträge (08.11.2026)
- Nach erfolgreichem isoliertem PostgreSQL-17.6-Workflow #17 auf Commit `b9b33c2` wurde der nächste Umsetzungsschritt ausgeführt: fachliche Zustandsübergänge und serverseitige RPC-Verträge sind spezifiziert.
- Führendes Dokument: `docs/E05_SERVER_STATE_TRANSITIONS_RPC_CONTRACTS_2026-11-08.md`.
- Umfasst Ereignisvergabe/-korrektur/-storno/-wiederherstellung, nachgelagerten Sperren-Lifecycle, Ausnahmen, Saisonwechsel, Spielartkonfiguration, vorzeitigen Sperrausgleich, Read-Verträge und Positiv-/Negativ-/Grenz-/Parallelitätstests.
- **Status:** reine Dokumentation. Keine SQL-Ausführung, keine Supabase-/Datenbankänderung, keine Änderung an `main` oder PROD. Nächster Schritt: gezielte read-only Prüfung der DEV-Rollen-/Tabellenverträge für die Ereignis-RPCs; danach separater SQL-Entwurf mit statischer Syntaxprüfung und isoliertem PostgreSQL-17.6-Test.

### E05 / AP05 – Kaderplanung, Trainingsereignisse und Kaderempfehlung
- AP05.2 (fachliche Daten-/Geschäftsregeln) und AP05.3a–d (Userflows/Kaderplanungs-UI) sind abgestimmt; Detailquelle AP05.3: `docs/AP05_3_USERFLOWS_UI_KONZEPT_2026-11-07.md`.
- UI-Konzept und verbindliche Umsetzungsleitlinie: `docs/E05_UI_KONZEPT_UMSETZUNGSLEITLINIE_2026-11-07.md`. Bestehende Seiten/Komponenten sind 1:1 weiterzuverwenden und gezielt anzupassen; keine Ersatzseiten oder parallelen Listen.
- Technisches Zieldatenmodell Revision 3 (konsolidiert; Anwesenheitsprüfung und Sperrausgleich präzisiert): `docs/E05_TECHNISCHES_ZIELDATENMODELL_2026-11-08.md`.
- SQL-Reviewbericht: `docs/E05_TECHNISCHER_REVIEW_SCHEMAFUNDAMENT_2026-11-08.md`. Die frühere SQL-Fassung war nicht freigabefähig; die korrigierte Revision bleibt bis zum vollständigen statischen und isolierten PostgreSQL-Test ein Review-Entwurf.
- Aktueller SQL-Entwurf: `docs/E05_SCHEMA_MIGRATION_DRAFT_2026-11-08.sql`. Er bleibt unter `docs/` und wird nicht vorzeitig nach `supabase/migrations/` verschoben. Die finale Migrationsdatei wird erst nach erfolgreicher Prüfung gemäß Supabase-CLI-Verfahren erstellt.
- Führende Regeln: `docs/SUPABASE_CHANGE_CONTROL.md`, `DB_MIGRATION_LOG.md` (nur tatsächliche Ausführungsversuche), `DB_CHANGELOG.md` (tatsächlich entstandene Objekte) und `SUPABASE_CHANGELOG.md`. Jede schreibende SQL-Anfrage muss vorab vollständig versioniert und ausdrücklich freigegeben werden; DEV-/PROD-Ausführungen werden getrennt dokumentiert.
- Planungsreferenz: `DB_CHANGELOG.md` / `DB-PLAN-E05-001`. `DB_CHANGELOG.md` führt den E05-Planungsstand; `DB_MIGRATION_LOG.md` bleibt ausschließlich das Journal tatsächlicher SQL-Ausführungsversuche. Es wird kein separates E05-Ausführungsprotokoll parallel geführt. Kein E05-SQL wurde ausgeführt; keine E05-Datenbankobjekte wurden angelegt oder geändert.
- Zielumgebung für die erste spätere Ausführung: ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`). PROD und `main` bleiben ohne separate ausdrückliche Freigabe unberührt.
- Nächste Arbeit: grünen Lauf des isolierten PostgreSQL-17.6-Workflows verifizieren, verbleibende Befunde korrigieren und erst danach nach dem Supabase-CLI-Verfahren eine finale Migrationsdatei erzeugen und zur ausdrücklichen DEV-Freigabe vorlegen.
- UI-Entscheidungen: Trainingsdetail erhält die Tabs Rückmeldungen, Anwesenheit, Teams, Ereignisse; Ereignisse zeigt nur anwesende Spieler. Allgemeine Spielerliste erhält Anwesenheit und Ereignisse; Bedienfolge Tabs → Suche → Filterchips. Warnungen werden über gelbe Kachelhinterlegung mit Begründung rechts dargestellt, offene Sperren über rote Kacheln; Ereigniskennzeichen bleiben kompakt. Spieltags-Kaderplanung erweitert ausschließlich bestehende Kaderkacheln.
- Aktueller Frontend-Bestand in `develop/index.html` wurde frisch gelesen. Identifizierte Anknüpfungspunkte: `renderTrainingDetail()` / `trainingDetailTabs`, `trainingPlayerRow`, `playerListRow` / `playerListControls` / `playerFilterChip`, bestehende Spielercard-`playerCardSection`, `matchdayDetailTabs` und `matchdaySquadTile`.

### Nächstes Vorhaben
E05 ist als nächstes Umsetzungsvorhaben vom Nutzer ausgewählt. Die Umsetzung erfolgt schrittweise nach der Leitlinie `docs/E05_UI_KONZEPT_UMSETZUNGSLEITLINIE_2026-11-07.md`; keine Änderung an PROD oder `main` ohne separate ausdrückliche Freigabe.

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
| `RELEASE_NOTES_*.md` | Fachlicher und technischer Umfang einer veröffentlichten Version |\n| `docs/HOTFIX_PLAYER_STATS_JOIN_DATE_2026-11-09.md` | Hotfix-Nachweis Spielerstatistiken ab Mannschaftsbeitritt, DEV-Tests, PR/Merge, PROD-Deploy und Main-Deploy-Workflow |
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
- Neue Edge Function `invite-member` ist in Supabase DEV ACTIVE (seit 04.11.2026 Version 4, JWT-Prüfung aktiv); der Redirect wird über die Supabase-Projektkennung DEV-/PROD-getrennt bestimmt. Die alte Funktion `invite-trainer` ist Version 4 und liefert HTTP 410 Gone; Details stehen in `SUPABASE_CHANGELOG.md`.
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

**Technischer Status (04.11.2026):** DB-DEV-009 wurde ausschließlich in Supabase DEV erfolgreich ausgeführt (Migrationsversion `20261104143331`); beide Teamzuordnungstabellen haben aktive Ein-Mannschaft-Trigger, Index und vier angepasste RPCs sind read-only verifiziert. Es bestehen 0 Benutzer mit Mehrfachzuordnungen; keine RLS-Policies und keine vorhandenen Mitgliedschaftsdaten wurden durch die Migration verändert. Vollständige Nachweise: `DB_MIGRATION_LOG.md` (DB-MIG-2026-003) und `DB_CHANGELOG.md` (DB-DEV-009). Das Frontend in `develop/index.html` wurde in den DEV-Spiegel `jugendmannschaft-dev/main` synchronisiert; Blob-SHA `ebf7363aa2df1f5b3fc465934e2fab8cea3ef0c1`; manueller Browser-/Praxistest offen. Die Supabase-Edge-Function-Quellen liegen in `develop` und wurden nach ausdrücklicher Freigabe am 04.11.2026 ausschließlich in Supabase DEV auf Version 4 deployed. Beide Funktionen sind ACTIVE, `verify_jwt=true`; die Live-Quelltexte stimmen bytegenau mit `develop` überein. PROD ist unverändert.

**Zentrale Ablage in `develop`:**
- Spezifikation und Status: `docs/proposals/single-team-membership-guard/README.md`
- Ausgeführte SQL-Migration: `supabase/migrations/20261104143331_db_dev_009_single_team_membership_guard.sql`
- Konzept-/Review-Entwurf: `docs/proposals/single-team-membership-guard/migration.sql`
- Read-only Nachprüfung: `docs/proposals/single-team-membership-guard/after_apply_verification.sql`
- Ausführungsnachweis: DB-MIG-2026-003 in `DB_MIGRATION_LOG.md`; technische Objektbeschreibung: DB-DEV-009 in `DB_CHANGELOG.md`
- Supabase-Änderungsprozess: `docs/SUPABASE_CHANGE_CONTROL.md`; tatsächliche Nicht-SQL-Ausführungen in `SUPABASE_CHANGELOG.md`

Der Feature-Branch `feature/dev-single-team-membership-guard-review` ist ein historischer Review-Arbeitsstand und keine führende Quelle. Die gezielt geprüften Frontend-/Edge-Änderungen sind inzwischen nach `develop` übernommen. Weitere Änderungen erfolgen in `develop`; der Feature-Branch wird nicht als zweite Dokumentationsbasis gepflegt und nicht vollständig ohne Prüfung gemerged.


**Deployment-Nachtrag 04.11.2026 – Release 1.6:** Nach ausdrücklicher Nutzerfreigabe wurden invite-member und invite-trainer ausschließlich in Supabase DEV (Projekt pzazqvvoruqnqhcorbwx) auf Version 4 deployed. Beide Funktionen sind ACTIVE und behalten verify_jwt=true. Die Live-Quelltexte wurden zurückgelesen und stimmen bytegenau mit develop überein. Der 410-Gone-Ersatz verweist auf invite-member. Keine SQL-Änderung, keine PROD-Änderung, keine Änderung an GitHub main. Der authentifizierte HTTP-/Browser-Praxistest und die Einladung eines bestehenden Superadmins bleiben offen. Vollständiger Deployment-Nachweis: SUPABASE_CHANGELOG.md, SUPA-2026-001.


**Frontend-Nachtrag 04.11.2026 – Startkontext für Vereinsadmins mit Mannschaftsrollen:** Ein Vereinsadmin mit zusätzlicher Trainer-/Mannschaftsadminrolle wurde beim Login irrtümlich direkt in seine Mannschaft geladen. Ursache war die Reihenfolge in `loadApp()`: Der Zweig für vorhandene Mannschaftsrollen wurde vor der Vereinsadmin-Erkennung ausgeführt. Korrektur in Commit `81f9ca9cc0294177e89910b0b8ffa158bdc02c44`: normaler Login startet zuerst in der Vereinsverwaltung; ein ausdrücklich ausgewählter Mannschaftskontext hat beim Öffnen Vorrang vor einer Mitgliedschaft in einer anderen Mannschaft. DEV-Deploy #397 erfolgreich; `develop/index.html` und `jugendmannschaft-dev/main/index.html` haben Blob-SHA `aa682da4c8d528239b06513fafa3b20eacf36d53`. JavaScript-Syntaxprüfung bestanden. Keine SQL- oder Datenänderung, PROD und `main` unverändert. Manueller Login-/Kontextwechseltest steht noch aus.


**Praxistest 04.11.2026 – bestehender Superadmin als Trainer eingeladen:** Nutzer bestätigte erfolgreiche Einladung über DEV. Read-only Supabase-Prüfung bestätigte: globale Rolle super_admin erhalten, Auth-Konto bereits bestätigt, genau eine Mannschaftszuordnung, Rolle trainer konsistent in team_members und team_member_roles, passende Vereinsmitgliedschaft. Weitere Einladungsrollen und Negativtest auf zweite Mannschaft noch offen. Release-Nachweis: docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md, Abschnitt 14.


**Praxistest 04.11.2026 – zweite Mannschaftszuordnung:** Der Nutzer versuchte, das bestehende Superadmin-Trainerkonto zusätzlich einer zweiten Mannschaft zuzuordnen. Die Einladung stoppte bereits im Frontend wegen bestehender Vereinsmitgliedschaft; im Bearbeitungsdialog waren die Rollenfelder der anderen Mannschaft deaktiviert. Read-only geprüft: Superadmin-Rolle und Trainerzuordnung in DEV Mannschaft unverändert, keine Zuordnung zu G-Junioren, 0 Benutzer mit Mehrfachzuordnungen. UI-Schutz bestätigt; serverseitiger Negativaufruf nicht ausgelöst. Details: docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md, Abschnitt 15.


**Praxistest und UX-Korrektur 04.11.2026 – Vereinsadmin zusätzlich zu Trainer:** Der bestehende Superadmin wurde über „Bearbeiten“ zusätzlich zum Vereinsadmin gemacht. Read-only Prüfung bestätigte: super_admin und club_admin vorhanden, Trainerrolle in der bisherigen Mannschaft erhalten, genau eine Mannschaftszuordnung. Zusätzlich wurde der Fehler behoben, dass die sichtbare Vereinsmitgliederliste nach Speichern nicht aktualisiert wurde: `saveClubMemberEditor` erkennt die aktive Unterseite und lädt sie direkt neu, ohne Navigation eine Ebene höher. DEV-Deploy #407 erfolgreich; `develop/index.html` und DEV-Spiegel identischer Blob-SHA `55cc89958375a5d4d1bac2ed61e1c3fcae75b23c`. Manueller Browser-Nachtest der direkten Aktualisierung noch offen. Details: `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md`, Abschnitt 16.


**UX-Nachtest 04.11.2026 bestanden:** Nach Speichern des Mitglieder-Bearbeitungsdialogs aktualisiert sich die sichtbare Vereinsmitgliederliste sofort; der Nutzer bleibt auf „Mitglieder und Rollen“. Kein Seitenneuladen oder Zurückspringen in die übergeordnete Verwaltung erforderlich. Der Nachtest ist in `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md`, Abschnitt 16, dokumentiert.


**DEV-Änderung 04.11.2026 – Mannschaftsübersicht und Kachelinformationen:** Nach Bearbeitung der Mannschaftsstammdaten aktualisiert sich die gerade sichtbare Mannschaftsübersicht nun direkt; bei Bearbeitung aus der Detailansicht bleibt diese geöffnet und ihre Angaben werden aktualisiert. Mannschaftskacheln zeigen Spiel-/Trainingsstätte aus den Vereinsdaten, Anzahl aktiver Spieler und Zielkadergröße. Daten stammen aus `clubs`, der bestehenden berechtigungsgeschützten RPC `get_club_players` und `teams.recommended_squad_size`; keine SQL- oder Schemaänderung. DEV-Deploy #414 erfolgreich, `develop/index.html` und DEV-Spiegel identischer Blob-SHA `38e0b7c950ed3c2f424b817359b920a2530799c4`. Manueller DEV-Browser-Praxistest am 04.11.2026 vom Nutzer bestätigt („Ja funktioniert“): direkte Aktualisierung und neue Kachelangaben funktionieren. Details: `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md`, Abschnitt 17.


**Klarstellung Release 1.6 – Einladungen (04.11.2026):** Brevo ist bereits als SMTP-Lösung eingerichtet; eine SMTP-Neueinrichtung ist nicht offen. Die Rollenkombinationen Superadmin → Vereinsmitglied/Vereinsadmin, Vereinsadmin → Vereinsmitglied/Mannschaftsadmin/Trainer und Mannschaftsadmin → Mannschaftsadmin/Trainer sind laut Nutzertest erfolgreich. Der Hinweis bei bereits bestehender Vereinsmitgliedschaft und die Wiederholungssperre wurden ebenfalls bestätigt. Der serverseitige Negativtest der Ein-Mannschaft-Regel wurde nach ausdrücklicher Freigabe in DEV in beiden Tabellen erfolgreich ausgeführt; beide INSERT-Versuche wurden mit SQLSTATE 23514 abgewiesen, die bestehende Zuordnung blieb unverändert. Nachweise: `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md`, Abschnitt 18, und `DB_CHANGELOG.md`, DB-TEST-2026-004. Der abweichende Vereinskontext ist derzeit nicht testbar, da DEV nur einen Verein enthält und die Vereinsanlage in der App noch nicht verfügbar ist. Der separate Sonderfall eines unbestätigten Auth-Kontos ohne bestehende Vereinsmitgliedschaft sowie der authentifizierte HTTP-Laufzeittest des Legacy-Endpoints `invite-trainer` bleiben offen; Live-Quelltext und Deployment-Metadaten des Legacy-Endpoints sind geprüft (ACTIVE V4, `verify_jwt=true`, Nicht-OPTIONS-Codepfad liefert 410). PROD und GitHub `main` bleiben unangetastet.


**DEV-Nachtrag 04.11.2026 – mobile UX und Trainer-Anwesenheit:** Commit `94acfccd0f120161643482614b45567659ebaa31` ergänzt Ellipsis für lange E-Mail-Adressen in den Mitglieder-/Rollenlisten, vereinheitlicht den mobilen Einladen-/Abbrechen-Aktionsbereich und filtert die Trainer-Anwesenheit bei Training und Spieltag auf Nutzer mit tatsächlicher `trainer`-Rolle. Reine Mannschaftsadmins ohne Trainerrolle werden nicht angezeigt; kombinierte Admin-/Trainerrollen bleiben sichtbar. Die Speicher-Handler prüfen die Trainerrolle ebenfalls. Bestehende historische Anwesenheitseinträge wurden nicht gelöscht oder verändert. Die vorhandene RPC `get_team_trainers_v2` liefert die Rollen als Array; keine SQL-/Schemaänderung. JavaScript-Syntaxprüfung bestanden; DEV-Deploy #424 erfolgreich; `develop/index.html` und DEV-Spiegel haben identischen Blob-SHA `ba849c4eb8c959df7c7eb3088466e0150e1d4174`. Manueller iPhone-Nachtest steht aus. Header und Begrüßung wurden nicht geändert; dazu erfolgt vor Implementierung eine separate Designabstimmung. PROD und GitHub `main` unverändert.


**DEV-Nachtrag 04.11.2026 – manueller UX-Nachtest bestätigt:** Der Nutzer hat im DEV-Browser bestätigt, dass alle drei Änderungen aus Paket A sichtbar sind und wie vorgesehen funktionieren: Ellipsis bei langen E-Mail-Adressen, kompakter Einladen-Button sowie Trainer-Anwesenheit nur für Personen mit Trainerrolle. Der iPhone-Praxistest wird damit als bestanden geführt.

**Designpräzisierung Header/Begrüßung (04.11.2026, noch nicht implementiert):** Dunkelblauer Header ausschließlich mit „KADAssist“. Im Begrüßungsblock Wappen links; Vereinsname rechts daneben als größere Zeile; Mannschaft und Saison gemeinsam in einer kleineren Zeile; darunter aktive Rolle(n) nochmals kleiner. Kontext muss Trainer, Mannschaftsadmin, kombinierte Rollen, Vereinsadmin ohne Mannschaft und Superadmin-Kontexte abbilden. Finale Frontend-Umsetzung erst nach Bestätigung des Entwurfs. PROD und GitHub `main` unverändert.


**DEV-Nachtrag 04.11.2026 – KADAssist Header und Begrüßung:** Die abgestimmte Variante A ist in `develop` umgesetzt. Header zeigt nur „KADAssist“; im Dashboard folgt „Hallo, [Profilname]!“, darunter Wappen und Vereinsname, Mannschaft und Saison in einer Zeile sowie die aktiven Rollen als dezente Kennzeichnungen. Für Vereinsmitglied-/Vereinsadmin- und Superadmin-Kontexte werden passende Rollen und Nur-Ansicht-Zustände dargestellt. Vereinsdaten kommen über die bestehende clubs-SELECT-Policy, Wappen aus dem öffentlichen `club-assets`-Bucket. Commit `f14fa4e41861a3a24e4906ec5c0e86d23ad81d2e`; JavaScript-Syntaxprüfung bestanden; DEV-Deploy #429 erfolgreich; Blob-SHA in develop und DEV-Spiegel identisch (`22648c3d87f1501852891ea51a7e429811306ab1`). Keine SQL-/Schemaänderung oder RLS/Auth-Anpassung. Manueller iPhone-Nachtest steht aus. PROD und GitHub `main` unverändert.


**DEV-Nachtrag 04.11.2026 – iPhone-Feinschliff Header/Dashboard:** KADAssist-Header auf 24 px vergrößert; Wappenkachel ohne Kontur/Hintergrund, Wappen auf Höhe des gesamten Kontexttextes; der irreführende „Nur Ansicht“-Chip wird für Superadmins im explizit gewählten Teamkontext entfernt. Bei Vereinsadmins in einem tatsächlich read-only Teamkontext erscheint ein kleiner erklärender Text statt eines Chips. Statistik-Kachel (Spieler/Trainings/Spieltage) kompakter (21-px-Zahlen, kleinere Labels, weniger Padding). Berechtigungsprüfung read-only: Frontend `adminGuard()` erlaubt Superadmins im ausgewählten Kontext; DB-Funktion `is_team_admin(uuid)` erkennt Superadmin plus `has_selected_team_context` als Teamadmin. Keine Berechtigungsänderung und keine SQL-/Schemaänderung. Commit `9694f5ab6b4e22a4f431d7042fab6425a7d35e3e`; Syntaxprüfung bestanden; DEV-Deploy #432 erfolgreich; Index und DEV-Spiegel SHA `41dfb3cf6dabcea87a49f4ca6607e81be9f4e469` identisch. Manueller iPhone-Nachtest steht aus. PROD und GitHub `main` unverändert.


**DEV-Nachtrag 04.11.2026 – Mannschaftsübersicht Saison/Jahrgänge:** Die Metazeile unter dem Mannschaftsnamen zeigt jetzt nur „Saison [Jahr]“. In der Kachel „Mannschaftsinformationen“ werden aktive Saison („Saison [Jahr]“) und Jahrgang („Jahrgänge [Werte aus teams.birth_cohorts]“) getrennt beschriftet. Das zusätzliche Mannschaftskürzel wird aus diesen Metazeilen entfernt, bleibt jedoch im Mannschaftsnamen erhalten. Die aktive Saison wird aus dem bereits geladenen `seasons.name` verwendet; keine neue Datenbankabfrage und keine SQL-/Schemaänderung. Commit `bcb35846abf2c2888341b1ac7d2b6014cd8bbf80`, Syntaxprüfung bestanden, DEV-Deploy #435 erfolgreich. Manueller iPhone-Test steht aus. PROD und `main` unverändert.


**Manueller iPhone-Nachtest bestätigt (04.11.2026):** Nutzer hat die aktualisierte Mannschaftsübersicht geprüft und mit „Passt“ freigegeben. Die getrennten Beschriftungen „Saison [Jahr]“ und „Jahrgänge [Werte]“ in Kopfzeile und Informationskachel sind damit fachlich und visuell bestätigt.
