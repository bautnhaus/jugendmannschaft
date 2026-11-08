# E05 – Verbindliche Teststrategie für Datenbankpakete

**Stand:** 08.11.2026  
**Führender Branch:** `develop`

## 1. Grundsatz

Für die laufenden E05-Datenbankpakete 1–9 ist **Supabase DEV die verbindliche Integrations- und Testumgebung**. Eine separate isolierte PostgreSQL-Instanz ist keine verpflichtende Vorbedingung für die Ausführung eines freigegebenen Pakets.

Die bisherige Arbeitsweise bleibt maßgeblich: SQL wird vorab statisch und gegen den tatsächlichen DEV-Schema-/Berechtigungsstand geprüft. Nach ausdrücklicher Freigabe wird es in DEV ausgeführt. Funktionale Fehler, die erst bei der Ausführung oder bei den DEV-Tests sichtbar werden, werden korrigiert, als eigene schreibende SQL-Änderung dokumentiert und erneut getestet.

## 2. Einordnung des isolierten PostgreSQL-Workflows

Der vorhandene GitHub-Actions-Workflow mit PostgreSQL 17.6 dient dem isolierten Test des E05-Schemafundaments und seiner Fixture/Assertions (siehe `docs/E05_TESTABDECKUNG_REVIEW_2026-11-08.md`, Run #17).

Dieser Test ist ein ergänzender Nachweis für genau den dort geprüften Schemaentwurf. Er ist **kein allgemeines Release-Gate** und ersetzt weder den Live-DEV-Schemaabgleich noch die realen Funktions-, Rollen-, RLS- und Integrationsprüfungen in Supabase DEV.

## 3. Verbindlicher Ablauf je Paket

1. Fachliche Anforderungen und Freigabeumfang klären.
2. Tatsächlichen DEV-Schema- und Funktionsstand read-only auslesen.
3. SQL statisch prüfen: Syntax, Objektabhängigkeiten, Funktionssignaturen, Suchpfad, RLS, ACL, Trigger, Constraints und mögliche Seiteneffekte.
4. Vollständige SQL-Datei und Ausführungs-/Testdokumentation auf `develop` bereitstellen.
5. Ausdrückliche Nutzerfreigabe für die konkrete DEV-Ausführung einholen.
6. SQL in Supabase DEV ausführen und Migrationsergebnis kontrollieren.
7. Positiv-, Negativ-, Grenz- und Regressionstests mit synthetischen Daten durchführen. Wo möglich Transaktionen zurückrollen; sonst Testdaten gezielt bereinigen und Bestand kontrollieren.
8. Fehlerkorrekturen als separate SQL-Dateien/Migrationen dokumentieren und nach Freigabe in DEV ausführen.
9. Funktionsdefinitionen, ACL, RLS, Trigger, Audit und Testdatenbestand read-only verifizieren.
10. Alle schreibenden Ausführungen einschließlich fehlgeschlagener Versuche und Korrekturen im `DB_MIGRATION_LOG.md` dokumentieren.
11. PROD bleibt unangetastet, bis ein gesondertes Releasepaket geprüft und ausdrücklich freigegeben ist.

## 4. Dokumentationspflicht

Jede tatsächlich ausgeführte schreibende SQL-Änderung erhält:
- unveränderliche SQL-Datei auf `develop`,
- Supabase-Migrationsversion und -name (falls registriert),
- Zielumgebung und Ausführungsstatus,
- Anlass, Freigabe und betroffene Objekte,
- Ergebnis und Fehlermeldung,
- konkrete read-only Verifikation,
- Testfälle und Resultate,
- Rollback-/Wiederherstellungsnotiz,
- Eintrag in `DB_MIGRATION_LOG.md`.

Fehlgeschlagene Versuche werden nicht als erfolgreich gezählt. Wenn keine Migration registriert und keine Seiteneffekte vorhanden sind, wird dies ausdrücklich so dokumentiert.

## 5. Geltungsbereich

Diese Strategie gilt für E05 und vergleichbare Datenbankarbeiten am Projekt Jugendmannschaft. Eine isolierte Testdatenbank kann zusätzlich eingesetzt werden, wenn sie einen konkreten Mehrwert bietet (z. B. Schemaentwurf, Upgrade-Kompatibilität oder reproduzierbare Regression), ist aber keine Voraussetzung, wenn die fachlich freigegebene DEV-Teststrategie ausreichend ist.
