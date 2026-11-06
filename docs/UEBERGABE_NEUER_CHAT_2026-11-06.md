# KADAssist – Übergabedokument für den nächsten Backlog-Chat

**Stand:** 06.11.2026  
**Zweck:** Neues, vom Nutzer noch auszuwählendes Backlog-Thema bearbeiten, ohne abgeschlossene Themen erneut aufzuwärmen oder bereits erfolgte Prüfungen/Abgleiche unnötig zu wiederholen.

## 1. Verbindlicher Einstieg im neuen Chat

Der Nutzer wird das nächste Backlog-Thema selbst benennen. Bis dahin:
- keine Umsetzung starten,
- kein Thema eigenmächtig auswählen,
- keine vollständige Projekt-, Datenbank-, Sicherheits- oder Branchprüfung wiederholen,
- keine abgeschlossenen Themen erneut analysieren.

Nach Nennung des Themas:
1. Thema eindeutig dem bestehenden Backlog/Epic zuordnen.
2. Nur die für dieses Thema maßgeblichen aktuellen GitHub-Dokumente und den betroffenen DEV-Stand gezielt lesen.
3. Bereits getroffene fachliche Entscheidungen und bestandene Prüfungen übernehmen.
4. Nur konkrete Lücken, Widersprüche oder neue Risiken prüfen.
5. Erst Anforderungen und Userflow abstimmen, dann UI-Konzept, dann Umsetzung in DEV.
6. Ergebnisse, Entscheidungen und offene Punkte an der zentralen Dokumentationsstelle in `develop` festhalten.

## 2. Projekt und technische Umgebung

- Repository: https://github.com/bautnhaus/jugendmannschaft
- `develop`: führende Entwicklungs- und Dokumentationsquelle.
- `main`: PROD-Branch; der vorhandene GitHub-Actions-Workflow „Deploy PROD“ übernimmt den geprüften Stand aus `develop` nach `main` (Fast-forward-only) und veröffentlicht die PROD-Website.
- Supabase DEV: Projektkennung `pzazqvvoruqnqhcorbwx`.
- Supabase PROD: Projektkennung `qdugtpzgefpswnnqbusd`.
- Hosting: GitHub Pages.
- PROD-App: https://kadassist.de
- DEV-App: https://dev.kadassist.de

### STRATO und Cloudflare – Zuständigkeiten

- **STRATO** bleibt Domainregistrar für `kadassist.de` (Domainregistrierung/Vertrag/Verlängerung).
- **Cloudflare** verwaltet die DNS-Zone und DNS-Einträge.
- Cloudflare wird im **Free Plan (0 €)** genutzt.
- GitHub Pages ist das Hosting; Supabase stellt Backend/Auth/DB bereit.
- STRATO-Registrar, Cloudflare-DNS, GitHub-Pages-Hosting und Supabase sind getrennte Ebenen. Nicht vermischen.
- Im AP05-Abschluss wurden keine STRATO-, Cloudflare-, Nameserver- oder DNS-Einstellungen geändert.
- Keine DNS-/Registraränderung ohne konkreten Anlass und ausdrückliche Freigabe.

## 3. Aktueller Release- und Branchstatus

- Release 1.5.2 wurde laut Nutzerbestätigung am 02.11.2026 nach PROD deployed.
- AP05 – Mitgliedereinladung und Domainanpassung – ist im Standardablauf für DEV und PROD abgeschlossen.
- DEV `invite-member`: Version 5 ACTIVE, `verify_jwt=true`.
- PROD `invite-member`: Version 1 ACTIVE, `verify_jwt=true`; PROD-spezifische CORS-Origin `https://kadassist.de`, Redirect auf `https://kadassist.de/`.
- PROD `invite-trainer`: Version 3 ACTIVE, `verify_jwt=true`; Legacy-Endpunkt antwortet außerhalb OPTIONS mit HTTP 410 und verweist auf `invite-member`.
- Nutzer hat Site URL `https://kadassist.de` und Redirect URL `https://kadassist.de/` in Supabase PROD Auth konfiguriert und bestätigt.
- Nutzer hat PROD-Web-Deploy über GitHub Actions erfolgreich ausgeführt.
- Nutzer hat anschließend den vollständigen PROD-Einladungsstandardablauf (Einladung, E-Mail, Link, Passwortvergabe, Anmeldung) erfolgreich bestätigt.
- Am 06.11.2026 wurden `main` und `develop` nach dem Deploy verglichen: Status `identical`, 0 Commits voraus/zurück, keine abweichenden Dateien. Gemeinsamer Commit: `dd0cd8f405673e488ed20c2daf724d2583f7be0d`.
- Die in dieser Übergabe beschriebenen Dokumentationsänderungen werden zunächst nur auf `develop` vorgenommen. Daher steht `develop` danach vorübergehend vor `main`. Der Nutzer kann nach Abschluss den bestehenden „Deploy PROD“-Workflow ausführen. Danach Branchvergleich nur auf Wunsch bzw. nach Nutzerrückmeldung durchführen.

## 4. Abgeschlossene Themen – nicht erneut bearbeiten

### AP05 / Einladungsstandardablauf
Als abgeschlossen behandeln:
- DEV-Einladung über `dev.kadassist.de`, E-Mail, Redirect, Passwortvergabe, Anmeldung und korrekte Zuordnung wurden vom Nutzer erfolgreich getestet.
- PROD-Einladung über `kadassist.de`, E-Mail, Redirect, Passwortvergabe und Anmeldung wurden vom Nutzer erfolgreich getestet.
- PROD-Web-Deploy wurde vom Nutzer bestätigt.
- Alte PROD-Funktion `invite-trainer` ist stillgelegt (HTTP 410); Einladungen laufen über `invite-member`.
- GitHub-Branchgleichheit nach dem letzten PROD-Deploy wurde konkret geprüft und bestätigt.

Diese Prüfungen nicht wiederholen, nur weil ein neuer Chat beginnt. Nur bei konkretem Fehlerbild, einer neuen Änderung mit direkter Auswirkung oder belastbarem Widerspruch gezielt nachprüfen.

### AP01–AP04 / Rollen und Profile
- AP01–AP03-Unterlagen, Release-Katalog und Testzuordnung sind vorhanden. Ein vollständiges PROD-Migrationspaket ist nicht pauschal freigegeben.
- AP04-Dokumentation zu Profilverwaltung und geschützten Rollenänderungen liegt vor. Fünf AP04-Migrationen in `develop` sind nicht automatisch PROD-freigegeben.
- Vereins-/Mannschaftsanlage ist separat dokumentiert; Status und noch offene Praxistests stehen im Plan.
- Nicht allein aus älteren Projektkontext-Abschnitten schließen, dass ein damaliger Test noch offen ist. Zuerst den aktuellen fachlichen Hauptnachweis des konkreten Themas lesen.

## 5. Noch offene bzw. optionale Punkte

### Optionale AP05-Randfalltests
Diese sind ausdrücklich getrennt vom bestandenen Standardablauf:
1. Serverseitige Ablehnung einer zweiten Mannschaftszuordnung bei erneuter Einladung.
2. CORS-Ablehnung einer nicht erlaubten Origin.
3. Erneute Einladung eines bereits bestätigten Benutzers.

Sie sind kein Grund, den Standard-Einladungsablauf erneut zu testen. Nur bearbeiten, wenn der Nutzer sie auswählt oder ein konkreter Folgefehler sie relevant macht.

### Weitere Produkt-/Backlog-Arbeit
Der Nutzer wählt das nächste Thema. Bekannte Themenfelder aus dem bisherigen Backlog sind u. a.:
- Dashboard (E09),
- flexible Kadergröße und Kaderplanung,
- Saisonübergang und Historie,
- Mehrmannschafts-/Vereinsfunktionen,
- Spielformen je Altersklasse,
- Verfügbarkeits- und Terminmanagement,
- Elternkonten und Eltern-Kind-Verknüpfung,
- UI-/Designsystem, Navigation und Darkmode,
- Trainer-Einladungsprüfung / Vermeidung doppelter Mannschaftszuordnung,
- FAQ und Dokumentation.

Diese Liste ist Orientierung, keine Priorisierung und kein Auftrag. Das konkrete Thema und sein aktueller Backlog-Eintrag sind nach Auswahl gezielt zu bestimmen.

## 6. Verbindliche Entwicklungs- und Freigaberegeln

1. **DEV zuerst.** Reguläre Entwicklung in `develop`; PROD bleibt unverändert, bis der Nutzer eine konkrete PROD-Aktion ausdrücklich freigibt.
2. **Frische Quellen.** Vor jeder Codeänderung aktuelle Originaldateien aus dem Zielbranch holen. Nicht mit alten Chatkopien arbeiten.
3. **Keine stillschweigende Freigabe.** Konzeptfreigabe, Dokumentationsfreigabe oder Zustimmung zur Analyse ist keine Freigabe für SQL-Ausführung, Edge-Deploy, Auth-Konfiguration, PROD-Deploy, DNS oder Änderungen auf `main`.
4. **SQL nur nach ausdrücklicher Zustimmung.** Vor jeder schreibenden SQL-Ausführung vollständiges SQL, Zielumgebung und Zweck vorlegen. Vorher tatsächliche Definitionen/Abhängigkeiten read-only prüfen. Keine Migration ohne Freigabe.
5. **Daten und Sicherheit schützen.** PROD-Daten, Rollen, RLS, Policies und Synchronisationslogik erhalten. Keine pauschale Wiederholung alter AP01–AP04-Migrationen. Keine Originaldefinitionen aus dem Gedächtnis rekonstruieren.
6. **Nachweise korrekt trennen.** DEV- und PROD-Ausführungen separat dokumentieren. Eine Datei oder ein vorbereitetes SQL ist kein Ausführungsnachweis. Nutzerbestätigungen als solche kennzeichnen, nicht als unabhängig technisch verifiziert ausgeben.
7. **Dokumentation in develop.** Fachliche Entscheidungen, Konzepte, Status, Tests und offene Punkte zentral in `develop` aktualisieren. Nach einem Dokumentationspaket Nutzer informieren, dass `develop` vor `main` liegt und ein regulärer PROD-Deploy zur Synchronisierung nötig ist.
8. **Keine Force-Pushes.** Bestehenden Fast-forward-Deploy-Prozess verwenden. Keine unabhängigen Commits auf `main` erzeugen.
9. **Schrittweise vorgehen.** Dem Nutzer jeweils eine klare nächste Aktion geben. Er ist kein Programmierer und soll keine Code-/SQL-Reviews selbst leisten müssen. Technische Bewertung selbst übernehmen und in verständlichem Deutsch erklären.
10. **Keinen Erfolg behaupten, bevor er belegt ist.** Bei vom Nutzer ausgeführten Aktionen: „laut Deiner Rückmeldung erfolgreich“.
11. **Nur relevante Prüfungen.** Bereits erledigte Abgleiche nicht routinemäßig wiederholen. Nur bei konkretem Anlass erneut prüfen und kurz erklären, warum.

## 7. Produkt- und UX-Leitlinien

- KADAssist ist sportartneutral und für Teamsportgruppen gedacht, nicht nur für Fußball.
- Mobile-/iPhone-first, gleichzeitig responsiv.
- Neutrales Blau als primäre Akzentfarbe; Grün nicht als beliebige Primärfarbe einsetzen.
- Keine maritimen Motive.
- Einheitliche vorhandene Komponenten wiederverwenden, statt ähnliche Varianten neu zu bauen.
- UI-Konzeptionsfolge: Anforderungen → Userflow/Wireframe/Low Fidelity → abgestimmtes High-Fidelity-Konzept → Implementierung → DEV-Test.
- Dashboard heißt **Dashboard**, nicht „Übersicht“.
- Die App unterstützt Entscheidungen; die verantwortliche Person entscheidet.

## 8. Maßgebliche GitHub-Dokumente

Diese Dateien liegen im Repository `bautnhaus/jugendmannschaft`:

| Dokument | Zweck |
|---|---|
| `PROJECT_CONTEXT.md` | Aktueller Projektstatus, Regeln, Domains, Hosting/DNS |
| `README.md` | Dokumentationsindex und Deploy-Workflow |
| `docs/AP05_INVITE_MEMBER_DEV_DOMAIN_2026-11-05.md` | Vollständiger DEV-/PROD-Nachweis AP05 |
| `SUPABASE_CHANGELOG.md` | Tatsächliche Supabase-Laufzeit-/Konfigurationsänderungen; AP05-PROD-Nachweis SUPA-2026-002 |
| `docs/SUPABASE_CHANGE_CONTROL.md` | Freigabe- und Änderungsprozess für Supabase |
| `DB_CHANGELOG.md` | Datenbankobjekte und technische Prüfungen |
| `DB_MIGRATION_LOG.md` | Ausführungsnachweise schreibender SQL-Anweisungen |
| `docs/AP01-03_RELEASE_KATALOG_2026-11-01.md` | AP01–AP03 Releaseumfang |
| `docs/AP01-03_MIGRATION_TEST_MAPPING_2026-11-01.md` | Zuordnung von Migrationen und Tests |
| `docs/AP04-profile-management.md` | AP04 Profilverwaltung |
| `docs/CLUB_TEAM_CREATION_PLAN_2026-10-29.md` | Vereins- und Mannschaftsanlage |
| `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md` | Historische ausführliche Release-1.6-Umsetzung; bei AP05-Statuswidersprüchen ist das neuere AP05-Dokument maßgeblich |

**Wichtig:** Ältere Übergabe `docs/UEBERGABE_NEUER_CHAT_2026-11-02.md` und der damalige Einladungs-Prompt sind historische Artefakte. Sie beschreiben einen inzwischen erledigten Auftrag und dürfen nicht als aktueller Arbeitsauftrag verwendet werden.

## 9. Startanweisung

Warte auf die Benennung des nächsten Backlog-Themas. Sobald der Nutzer es nennt, bestätige kurz das Thema und beginne mit einer gezielten Bestandsaufnahme ausschließlich der dazugehörigen Anforderungen, Dokumente und des relevanten DEV-Stands. Wiederhole keine bereits bestandenen Prüfungen ohne konkreten Anlass.
