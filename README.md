# Jugendmannschaft

## Zentrale Dokumentation
- [Projektkontext, aktueller Status, Hosting/DNS und verbindliche Arbeitsregeln](PROJECT_CONTEXT.md)
- [Aktuelle Übergabe für den nächsten Backlog-Chat](docs/UEBERGABE_NEUER_CHAT_2026-11-06.md)
- [Kopierprompt für den nächsten Backlog-Chat](docs/PROMPT_NEUER_CHAT_BACKLOG_2026-11-06.txt)
- [Datenbank-Changelog](DB_CHANGELOG.md) – technische Datenbankobjekte, Änderungen und Prüfungen
- [SQL-Migrationsprotokoll](DB_MIGRATION_LOG.md) – tatsächliche Ausführungsnachweise für schreibende SQL-Anweisungen

## Releases und fachliche Dokumentation
- [Release Notes 1.5.2](RELEASE_NOTES_1.5.2_PROD_2026-11-02.md)\n- [Hotfix 09.11.2026 – Spielerstatistiken ab Mannschaftsbeitritt und Main Deploy](docs/HOTFIX_PLAYER_STATS_JOIN_DATE_2026-11-09.md)
- [AP01–AP03 Release-Katalog](docs/AP01-03_RELEASE_KATALOG_2026-11-01.md)
- [AP01–AP03 Migrations- und Testzuordnung](docs/AP01-03_MIGRATION_TEST_MAPPING_2026-11-01.md)
- [AP04 – Profile und geschützte Rollenänderungen](docs/AP04-profile-management.md)
- [AP05 – Mitgliedereinladung: DEV und PROD](docs/AP05_INVITE_MEMBER_DEV_DOMAIN_2026-11-05.md)
- [Vereins- und Mannschaftsanlage](docs/CLUB_TEAM_CREATION_PLAN_2026-10-29.md)

## Deployment und Umgebungen
- `develop` ist die zentrale Quelle für Entwicklung und Dokumentation.
- Der Workflow [Deploy PROD](.github/workflows/deploy-prod.yml) übernimmt den getesteten Stand aus `develop` nur dann nach `main`, wenn `main` ein Vorfahr des ausgewählten `develop`-Commits ist. Bei unabhängigen Commits auf `main` bricht der Workflow ab, statt diese zu überschreiben.\n- Der ergänzende Workflow [Main Deploy](.github/workflows/deploy-main.yml) deployt manuell ausschließlich den bereits vorhandenen `main`-Stand. Er übernimmt nichts aus `develop` und verändert keine Branches. Er ist für isolierte, bereits gemergte Hotfixes gedacht; kein Ersatz für den regulären Releaseprozess.
- Der Workflow konfiguriert vor dem Pages-Upload die PROD-Supabase-Projektadresse und den PROD-Publishable-Key in `index.html`.
- Die Datei `CNAME` in `develop` ordnet die PROD-Website der Domain `kadassist.de` zu. Der DEV-Spiegelworkflow muss dagegen `dev.kadassist.de` setzen.
- Ein erfolgreicher Edge-Function-Deploy ist nicht gleichbedeutend mit einem erfolgreichen Website-Deploy oder einem bestandenen End-to-End-Test.

## Aktuelle Arbeitsübergabe
- Die Einladungsthematik AP05 ist abgeschlossen; die Dokumente vom 02.11.2026 sind historische Übergaben und kein offener Arbeitsauftrag.
- [Aktuelle Übergabe für den nächsten Backlog-Chat](docs/UEBERGABE_NEUER_CHAT_2026-11-06.md)
- [Kopierprompt für den nächsten Backlog-Chat](docs/PROMPT_NEUER_CHAT_BACKLOG_2026-11-06.txt)

## Archive
- [Archivübersicht](docs/archive/README.md)
- [Historische PROD-SQL-Anfragen 1–43](docs/database/archive/PROD_Migrationen_01-43/README.md)

Nach einem regulären PROD-Release sollen `develop` und `main` denselben Dokumentationsstand enthalten. Die aktuelle Dokumentationspflege erfolgt zunächst ausschließlich in `develop`; danach kann der Nutzer den bestehenden Deploy-PROD-Workflow ausführen. Archivierte Dokumente bleiben zur Nachvollziehbarkeit erhalten und gelten nicht automatisch als aktueller Arbeitsstand. Domainrollen: STRATO ist Registrar, Cloudflare verwaltet die DNS-Zone; Details und URLs stehen in `PROJECT_CONTEXT.md`.
