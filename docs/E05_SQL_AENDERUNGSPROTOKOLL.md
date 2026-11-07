# E05 – SQL-Änderungs- und Ausführungsprotokoll

Stand: 07.11.2026  
Zielumgebung: ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
PROD: ausdrücklich ausgeschlossen, bis eine separate Freigabe vorliegt.

## Verbindliche Regel

Jede schreibende SQL-Anfrage im Rahmen von E05 wird hier dokumentiert. Das gilt für DDL und DML sowie für Änderungen an Funktionen, Triggern, Policies, Grants, RLS, Daten und Migrationen.

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
