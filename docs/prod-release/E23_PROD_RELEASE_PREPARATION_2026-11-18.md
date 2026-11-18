# E23 – PROD-Releasevorbereitung (18.11.2026)

**Status:** Alle sechs DB-Pakete in PROD ausgeführt und im Ledger bestätigt; abschließender DB-Preflight bestanden  
**Ziel:** Supabase PROD `qdugtpzgefpswnnqbusd`  
**DEV-Referenz:** `pzazqvvoruqnqhcorbwx`  
**GitHub-Quelle:** `develop`  
**PROD-/main-Änderung:** keine

## 1. Releaseumfang

Das E23-Datenbankrelease wird bewusst in sechs einzeln ausführbaren Schritten bereitgestellt. Jeder Schritt ist eine eigenständige Migration und muss nach Ausführung einzeln verifiziert und im `DB_MIGRATION_LOG.md` dokumentiert werden.

| Reihenfolge | PROD-Migration | Inhalt | DEV-Referenz |
|---|---|---|---|
| 1 | `20261118100000_epic23_nomination_reminder_foundation_prod` | Reminder-/Audit-Tabellen, RLS, RPC Create/Cancel, Fulfillment-Trigger und Audit-Schutz | `20261117120000_epic23_nomination_reminder_foundation_dev` |
| 2 | `20261118101000_epic23_nomination_reminder_fulfillment_hotfix_prod` | Zeitstempelkorrektur für Fulfillment | `20261117140000_epic23_nomination_reminder_fulfillment_hotfix_dev` |
| 3 | `20261118102000_epic23_nomination_reminder_concurrency_hotfix_prod` | gemeinsamer spielerbezogener Advisory Lock für Create/Fulfillment | `20261117150000_epic23_nomination_reminder_concurrency_hotfix_dev` |
| 4 | `20261118103000_epic23_nomination_reminder_read_api_prod` | geschützte Read-API | `20261117160000_epic23_nomination_reminder_read_api_dev` |
| 5 | `20261118104000_epic23_nomination_reminder_reopen_prod` | Anzeige am Ausgangsspieltag und Wiederöffnung nach Abwahl | `20261117180000_epic23_nomination_reminder_reopen_dev` |
| 6 | `20261118105000_epic23_reopened_audit_action_hotfix_prod` | Audit-Constraint um `reopened` erweitern | `20261117193000_epic23_reopened_audit_action_hotfix_dev` |

Die PROD-Dateien sind separate Release-Kopien der in DEV ausgeführten Migrationen. Die fachlichen SQL-Anweisungen wurden nicht neu entworfen; Zielkommentare und Migrationsnamen sind auf PROD ausgerichtet.

## 2. Live-Abgleich vor Release

Initialer Preflight vor Paket 1 erfolgte read-only am 18.11.2026. Nach Ausführung aller sechs Pakete wurde der abschließende PROD-Preflight erneut read-only durchgeführt:

- Alle sechs Migrationen sind im Supabase-Produktiv-Ledger vorhanden: `20261118070757`, `20261118071012`, `20261118102300`, `20261118104708`, `20261118104831`, `20261118105730`.
- Beide Tabellen `matchday_nomination_reminders` und `matchday_nomination_reminder_audit` sind vorhanden; RLS ist aktiviert und jeweils eine Policy vorhanden.
- Create-, Cancel- und Read-RPC sowie Fulfillment- und Reopen-Triggerfunktionen sind vorhanden.
- Fulfillment- und Reopen-Trigger sind jeweils genau einmal vorhanden.
- Audit-Constraint erlaubt exakt `created`, `fulfilled`, `cancelled`, `reopened`.
- Alle fünf Funktionen verwenden den festen search_path `pg_catalog, public, auth`. Create-/Cancel-/Read-RPC sind für `authenticated`, nicht für `anon` oder PUBLIC ausführbar; Triggerfunktionen sind nicht direkt für Clientrollen ausführbar.
- Reminder- und Audit-Tabellen enthalten jeweils 0 Zeilen.
- Die Basisobjekte und Teamkontext-Hilfsfunktionen wurden im initialen Preflight geprüft und blieben Voraussetzung der Migrationen.

## 3. Kritische Release-Voraussetzungen

1. **Preflight:** Vor jedem weiteren Schritt die relevanten Zielobjekte und Abhängigkeiten read-only prüfen. Bei Abweichungen stoppen.
2. **Einzelschritte:** Immer nur eine Migration ausführen. Erst nach erfolgreichem Supabase-Ergebnis und bestandenem Postflight den nächsten Schritt beginnen.
3. **Reihenfolge:** Die Reihenfolge 1–6 ist verbindlich. Schritt 2/3 ersetzen die Funktion aus Schritt 1; Schritt 5 ersetzt die Read-API aus Schritt 4; Schritt 6 erweitert die Audit-Constraint für den in Schritt 5 angelegten Reopen-Trigger.
4. **Daten:** Paket 1 hat keine bestehenden Spieler-, Spieltags- oder Nominierungsdaten verändert. Beide neuen E23-Tabellen starteten leer.
5. **Rollback:** Kein pauschales Rückwärts-Rollback. Nach Anlage von Vormerkungs-/Audit-Historie ist die Historie append-only und muss erhalten bleiben. Bei Fehlern stoppen und gezielt vorgehen.
6. **Frontend:** Erst nach vollständigem DB-Postflight aller sechs Schritte wird der reguläre PROD-Deploy von `develop` nach `main` durchgeführt. Es wird keine E23-Frontendänderung separat isoliert.

## 4. Postflight je Schritt

### Schritt 1
- beide Tabellen vorhanden, erwartete Spalten/Constraints/Indizes vorhanden;
- RLS aktiv und SELECT-Policies vorhanden;
- Create-/Cancel-RPC SECURITY DEFINER, Owner `postgres`, fester search_path;
- EXECUTE nur `authenticated`; keine direkten Client-Schreibrechte;
- Audit-Schutztrigger und Fulfillment-Trigger aktiv.

### Schritt 2
- `epic23_fulfill_nomination_reminder()` enthält `clock_timestamp()` und inklusive Zeitbedingung `created_at <= v_now`;
- ACL bleibt eingeschränkt, Trigger aktiv.

### Schritt 3
- Fulfillment-Funktion enthält denselben `pg_advisory_xact_lock(hashtextextended(new.player_id::text,0))` wie Create;
- ACL bleibt eingeschränkt.

### Schritt 4
- Read-API vorhanden, SECURITY DEFINER, fester search_path;
- EXECUTE nur `authenticated`;
- API-Rollen- und Filtertests.

### Schritt 5
- Read-API liefert Vormerkungen am Ausgangsspieltag;
- Reopen-Trigger aktiv, Funktion SECURITY DEFINER und nicht direkt für Clientrollen ausführbar.

### Schritt 6
- Audit-Constraint erlaubt exakt `created`, `fulfilled`, `cancelled`, `reopened`;
- vorhandene Audit-Daten unverändert.

## 5. Nachgelagerte Release-Schritte

Nach vollständiger DB-Ausführung und Verifikation:
- regulären PROD-Deploy des geprüften `develop`-Stands nach `main` durchführen;
- iPhone-/PROD-Smoke-Test;
- Release Notes/Change Notification veröffentlichen;
- DB_MIGRATION_LOG.md für jede PROD-Ausführung mit tatsächlicher Ledger-Version, Zeit, Ergebnis und Postflight ergänzen.

## 6. Ausführungsstand

- Alle sechs Pakete wurden am 18.11.2026 erfolgreich in PROD ausgeführt und nachkontrolliert. Die tatsächlichen Ledger-Versionen sind oben dokumentiert.
- Der abschließende DB-Preflight bestätigt Tabellen, RLS/Policies, RPCs, Trigger, ACLs und Audit-Constraint; die beiden E23-Tabellen sind leer.
- `main` und das PROD-Frontend sind unverändert.
- GitHub-Vergleich `main...develop`: `develop` liegt 126 Commits vor `main`, ohne Commits auf `main`, die in `develop` fehlen. Der vereinbarte reguläre Deploy ist der vollständige Stand `develop` → `main`; damit werden neben E23 auch die weiteren Änderungen des Branches Teil des PROD-Releases.
- Security-/Performance-Advisor wurden geprüft. Die Hinweise sind im Release-Preflight dokumentiert; sie umfassen projektweite bestehende Warnungen und sind nicht alle durch E23 verursacht.
- PROD-Deploy, PROD-Frontend-Smoke-Test und Veröffentlichung der Release Notes sind noch nicht erfolgt.
