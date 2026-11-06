# Jugendmannschaft

## Zentrale Dokumentation
- [Projektkontext und verbindliche Arbeitsregeln](PROJECT_CONTEXT.md)
- [Datenbank-Changelog](DB_CHANGELOG.md) – technische Datenbankobjekte, Änderungen und Prüfungen
- [SQL-Migrationsprotokoll](DB_MIGRATION_LOG.md) – tatsächliche Ausführungsnachweise für schreibende SQL-Anweisungen

## Releases und fachliche Dokumentation
- [Release Notes 1.5.2](RELEASE_NOTES_1.5.2_PROD_2026-11-02.md)
- [AP01–AP03 Release-Katalog](docs/AP01-03_RELEASE_KATALOG_2026-11-01.md)
- [AP01–AP03 Migrations- und Testzuordnung](docs/AP01-03_MIGRATION_TEST_MAPPING_2026-11-01.md)
- [AP04 – Profile und geschützte Rollenänderungen](docs/AP04-profile-management.md)
- [AP05 – Mitgliedereinladung: DEV und PROD](docs/AP05_INVITE_MEMBER_DEV_DOMAIN_2026-11-05.md)
- [Vereins- und Mannschaftsanlage](docs/CLUB_TEAM_CREATION_PLAN_2026-10-29.md)

## Deployment und Umgebungen
- `develop` ist die zentrale Quelle für Entwicklung und Dokumentation.
- Der Workflow [Deploy PROD](.github/workflows/deploy-prod.yml) übernimmt den getesteten Stand aus `develop` nur dann nach `main`, wenn `main` ein Vorfahr des ausgewählten `develop`-Commits ist. Bei unabhängigen Commits auf `main` bricht der Workflow ab, statt diese zu überschreiben.
- Der Workflow konfiguriert vor dem Pages-Upload die PROD-Supabase-Projektadresse und den PROD-Publishable-Key in `index.html`.
- Die Datei `CNAME` in `develop` ordnet die PROD-Website der Domain `kadassist.de` zu. Der DEV-Spiegelworkflow muss dagegen `dev.kadassist.de` setzen.
- Ein erfolgreicher Edge-Function-Deploy ist nicht gleichbedeutend mit einem erfolgreichen Website-Deploy oder einem bestandenen End-to-End-Test.

## Aktuell offene Arbeitsübergabe
- [Übergabedokument – Mitglieder-/Trainer-Einladung](docs/UEBERGABE_NEUER_CHAT_2026-11-02.md)
- [Kopierprompt für einen Folgechat](docs/PROMPT_NEUER_CHAT_MITGLIEDEREINLADUNG_2026-11-02.txt)

## Archive
- [Archivübersicht](docs/archive/README.md)
- [Historische PROD-SQL-Anfragen 1–43](docs/database/archive/PROD_Migrationen_01-43/README.md)

Nach einem regulären PROD-Release sollen `develop` und `main` denselben Dokumentationsstand enthalten. Archivierte Dokumente bleiben zur Nachvollziehbarkeit erhalten und gelten nicht automatisch als aktueller Arbeitsstand.
