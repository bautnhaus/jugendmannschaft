# E05 – Ergänzender SQL-Vorbereitungsleitfaden

Stand: 08.11.2026  
Zielumgebung: ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
PROD: ausdrücklich ausgeschlossen, bis eine separate Freigabe vorliegt.

## Verhältnis zu den führenden Projektprotokollen\n\nDieses Dokument ist ein ergänzender E05-Arbeitsleitfaden und **kein paralleles Ausführungsjournal**. Führend für jede tatsächliche schreibende SQL-Ausführung ist `DB_MIGRATION_LOG.md` gemäß `docs/SUPABASE_CHANGE_CONTROL.md`. `DB_CHANGELOG.md` beschreibt ausschließlich tatsächlich entstandene Datenbankobjekte und deren Verifikation. Vorbereitete SQL-Dateien sind dort nur als klar gekennzeichnete Entwürfe zu referenzieren.\n\n## Verbindliche Regel

Jede schreibende SQL-Anfrage im Rahmen von E05 wird vor Ausführung vollständig als unveränderliche SQL-Quelle in GitHub vorbereitet und nach jeder tatsächlichen Ausführung ausschließlich im führenden `DB_MIGRATION_LOG.md` mit eigenem DEV-/PROD-Ausführungsdatensatz dokumentiert. Das gilt für DDL und DML sowie für Änderungen an Funktionen, Triggern, Policies, Grants, RLS, Daten und Migrationen.

**Vor Ausführung** muss ein Eintrag mindestens enthalten:
1. Kennung und Datum
2. Zweck / fachlicher Bezug zu AP05
3. Zielumgebung und betroffene Objekte
4. vollständigen, unveränderten SQL-Text bzw. vollständige Migrationsdatei
5. erwartete Änderungen und mögliche Auswirkungen auf bestehende Daten
6. Auswirkungen auf Rollen, RLS, Policies, Grants, Funktionen und Trigger
7. Prüfplan / erwartete Ergebnisse
8. Rückfall- oder Wiederherstellungsplan
9. Freigabestatus des Nutzers

**Nach Ausführung** wird derselbe Eintrag ergänzt um:
- tatsächliches Ausführungsdatum und ausführendes Verfahren
- Ergebnis / Fehlermeldung
- ausgeführte Migration-ID und Commit-Referenz, sofern vorhanden
- Nachprüfungen (Schema, Policies, Constraints, Funktionen, Trigger, Datenintegrität)
- Abweichungen vom freigegebenen SQL

Es darf ausschließlich exakt der freigegebene SQL-Stand ausgeführt werden. Jede inhaltliche Änderung nach Freigabe erfordert eine neue Prüfung und Freigabe. Kein SQL-Schreibzugriff ohne ausdrückliche Zustimmung des Nutzers. Keine PROD-Ausführung aus diesem Protokoll ableiten.

## Änderungsprotokoll

### E05-SQL-000 – Read-only Bestandsaufnahme
- Datum: 07.11.2026
- Status: abgeschlossen, ausschließlich lesend
- Ziel: Supabase DEV
- Schreibende SQL-Anweisungen: keine
- Ergebnis: siehe `docs/E05_UI_KONZEPT_UMSETZUNGSLEITLINIE_2026-11-07.md`
- Nutzerfreigabe zur Änderung: nicht angefragt / nicht erforderlich, da keine Änderung erfolgte

### Vorlage für jeden künftigen Schreibvorgang

#### E05-SQL-XXX – [kurzer Titel]
- Datum / Version:
- Fachlicher Bezug:
- Zielumgebung:
- Betroffene Objekte:
- Zweck:
- Datenbestand betroffen?:
- Sicherheits-/RLS-Auswirkungen:
- SQL-Datei / vollständiger SQL-Text:
- Erwartetes Ergebnis:
- Prüfplan:
- Rückfallplan:
- Freigabestatus: **NICHT FREIGEGEBEN**
- Ausführung: **NICHT AUSGEFÜHRT**
- Ergebnis / Migration-ID / Commit:
- Nachprüfung:


### E05-SQL-001 – Technisches Schemafundament Trainingsereignisse und Sperren

- **Datum / Version:** 08.11.2026 / `20261108000100`
- **Fachlicher Bezug:** AP05.2, AP05.3a–d
- **Zielumgebung:** ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx)); PROD ausdrücklich ausgeschlossen
- **Betroffene Objekte:** neun neue Tabellen, Indizes, Constraints, RLS-Policies und minimale SELECT-Grants; keine Änderung bestehender Objekte
- **Zweck:** Historien- und Datenmodellfundament für Trainingskarten, Sterne, Sperren, Ausnahmen, Spielart-Konfiguration und vorzeitigen Sperrausgleich
- **Datenbestand betroffen?:** keine bestehenden Zeilen; ausschließlich neue Schemaobjekte
- **Sicherheits-/RLS-Auswirkungen:** RLS auf allen neun Tabellen; SELECT-Policies über vorhandene Team-/Kontexthelfer; keine direkten Client-Schreib-Policies oder Schreib-Grants. Schreiboperationen folgen erst über eng begrenzte, auditierte RPCs.
- **SQL-Datei:** `supabase/migrations/20261108000100_e05_training_events_suspensions_foundation.sql`
- **SQL-Datei-Commit:** `deb9aa8137443353e12bc46ba60a71f4a52b92e1`
- **Erwartetes Ergebnis:** additive Tabellen-/Index-/Constraint-/RLS-Struktur; keine Bestandsdaten werden verändert oder gelöscht
- **Prüfplan nach Freigabe:** Migrationshistorie; Tabellen/Spalten/Constraints/Indizes; RLS-Status/Policies; Tabellen- und Funktions-ACLs; Advisor; danach positive/negative Leserechte- und Teamkontext-Tests. Schreibtests erst nach separater Lifecycle-RPC-Implementierung.
- **Rückfallplan:** bei Fehler innerhalb der Transaktion wird die Migration zurückgerollt. Nach erfolgreicher Ausführung, aber vor produktiver Nutzung, ist ein kontrollierter Rückbau der ausschließlich neu angelegten Objekte möglich. Sobald Daten angelegt wurden, kein DROP-Rollback; dann ist ein gesondertes Daten-/Restore-Konzept erforderlich.
- **Freigabestatus:** **NICHT FREIGEGEBEN**
- **Ausführung:** **NICHT AUSGEFÜHRT**
- **Ergebnis / Migration-ID:** keine Datenbankausführung; die Versionsnummer ist nur der Dateiname und kein Eintrag in Supabase-Migrationshistorie
- **Nachprüfung:** statischer Review und read-only Abgleich mit DEV; kein PostgreSQL-Laufzeittest und keine Advisor-Prüfung nach DDL, da nicht ausgeführt
- **Gegenstück PROD:** nicht freigegeben / nicht ausgeführt
- **Nachweisgrenze:** automatische Sperrenerzeugung/-ableistung, Saisonabschluss, Ausnahmeverschiebung, vorzeitiger Sperrausgleich, Korrektur-RPCs und Empfehlungsintegration sind nicht Bestandteil dieser Foundation-Migration und bleiben separate, ebenfalls freizugebende Arbeitsschritte.
