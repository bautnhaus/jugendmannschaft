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
- Datum / Version: 08.11.2026 / Entwurf 1.0
- Fachlicher Bezug: AP05.2, AP05.3a–d
- Zielumgebung: Supabase DEV (`pzazqvvoruqnqhcorbwx)); PROD ausgeschlossen
- Betroffene Objekte: neun neue Tabellen (Trainingsereignisse, Event-Audit, Sperren, Sperrausnahmen, Sperren-Audit, Club-/Team-Spielartkonfiguration, vorzeitiger Sperrausgleich und Audit)
- Zweck: Historien- und Datenmodellfundament für E05; noch keine ausführbaren Lebenszyklus-/Empfehlungs-RPCs
- Datenbestand betroffen?: keine bestehenden Zeilen; nur neue leere Tabellen/Indizes/Policies/Grants vorgesehen
- Sicherheits-/RLS-Auswirkungen: RLS auf allen neuen Tabellen; SELECT-Policies anhand vorhandener Team-/Kontextfunktionen; explizite SELECT-Grants; noch keine Client-Schreib-Policies. Schreiboperationen folgen erst mit geprüften, eng begrenzten RPCs.
- SQL-Datei: `supabase/migrations/20261108000100_e05_training_events_suspensions_foundation.sql`
- Erwartetes Ergebnis: neue Tabellen/Indizes/Constraints/RLS-Policies und minimale Lese-Grants; keine Änderung bestehender Tabellen, Funktionen oder Policies
- Prüfplan: Migration zunächst nicht ausführen; vor Freigabe Syntax-/Abhängigkeitsreview, tatsächliche FKs/Policies/Grants gegen DEV, RLS-Negativ-/Positivtests und Prüfung der Löschblockaden; nach Freigabe read-only Schema-/ACL-/Policy-Verifikation plus funktionale Rechte-Tests
- Rückfallplan: vor Ausführung zu konkretisieren; da noch keine Ausführung erfolgt, keine Rücknahme ausgeführt. Ein Rollback müsste die neuen Objekte in Abhängigkeitsreihenfolge entfernen und darf keine Auditdaten enthalten.
- Freigabestatus: **NICHT FREIGEGEBEN**
- Ausführung: **NICHT AUSGEFÜHRT**
- Ergebnis / Migration-ID / Commit: Entwurf liegt in develop; Commit nach Aktualisierung: `b8837c36b4a42ae756c4cc8566dff0b3d6c05db8`
- Nachprüfung: nur statischer Review und read-only Bestandsabgleich; keine Ausführung, keine Schemaänderung.
- Nachweisgrenze / offene Punkte: Lebenszyklusfunktionen, automatische Sperrenerzeugung/-ableistung, Ausnahmen, Saisonwechsel, vorzeitiger Sperrausgleich, Audit-Trigger und Empfehlungseinbindung sind nicht Teil dieser ersten Strukturmigration. Die technische Freigabe wird erst nach Klärung der im Zieldatenmodell benannten Punkte empfohlen.
