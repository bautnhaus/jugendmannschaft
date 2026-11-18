# E23 – PROD-Releasevorbereitung (18.11.2026)

**Status:** vorbereitet, nicht ausgeführt  
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

Am 18.11.2026 wurden read-only in PROD geprüft:

- Alle sechs E23-Zielobjekte (Tabellen/RPCs/Triggerfunktionen) fehlen aktuell.
- Abhängige Tabellen `players`, `teams`, `matchdays`, `matchday_players`, `team_member_roles`, `global_user_roles`, `profiles` und `user_team_context` sind vorhanden.
- `matchday_players` besitzt die benötigten Spalten `matchday_id`, `player_id`, `available`, `played`, `team_number`, `goalkeeper`.
- `matchdays` besitzt `id`, `team_id`, `match_date`, `opponent`, `status`.
- `has_selected_team_context(uuid)` und `is_team_member(uuid)` sind in PROD vorhanden, SECURITY DEFINER, Owner `postgres`.
- RLS ist auf den relevanten Basis-Tabellen aktiviert.

## 3. Kritische Release-Voraussetzungen

1. **Sicherung:** Vor Schritt 1 reguläre PROD-Sicherung/Snapshot gemäß bestehendem Verfahren erstellen und bestätigen.
2. **Schema-Preflight:** Direkt vor Schritt 1 die Basisobjekte, Spalten, Fremdschlüssel und Hilfsfunktionen erneut prüfen. Das Release darf bei Abweichungen nicht starten.
3. **Einzelschritte:** Immer nur eine Migration ausführen. Erst nach erfolgreichem Supabase-Ergebnis und bestandenem Postflight den nächsten Schritt freigeben.
4. **Reihenfolge:** Die Reihenfolge 1–6 ist verbindlich. Schritt 2/3 ersetzen die Funktion aus Schritt 1; Schritt 5 ersetzt die Read-API aus Schritt 4; Schritt 6 erweitert die Audit-Constraint für den in Schritt 5 angelegten Reopen-Trigger.
5. **Daten:** Es werden keine bestehenden Spieler-, Spieltags-, Nominierungs- oder Audit-Datensätze verändert. Neue E23-Tabellen starten leer.
6. **Rollback:** Kein pauschales Rückwärts-Rollback. Nach Anlage von Vormerkungs-/Audit-Historie ist die Historie append-only und muss erhalten bleiben. Bei Fehlern stoppen und gezielt vorgehen.
7. **Frontend:** Die passende Frontendversion darf erst nach Datenbank-Postflight in PROD deployed werden. Frontend-Merge/Deploy ist ein separater Freigabeschritt.
8. **Kein Branch-Merge:** `develop` liegt 105 Commits vor `main`; kein pauschaler Merge. Frontend-Release muss separat auf die freigegebene E23-Änderung begrenzt werden.

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
- freigegebene E23-Frontendänderungen gezielt nach `main` übertragen;
- iPhone-/PROD-Smoke-Test;
- Release Notes/Change Notification veröffentlichen;
- DB_MIGRATION_LOG.md für jede PROD-Ausführung mit tatsächlicher Ledger-Version, Zeit, Ergebnis und Postflight ergänzen.

## 6. Freigabestatus

**Diese Dokumentation und die SQL-Dateien sind Vorbereitung.** Keine der sechs PROD-Migrationen wurde ausgeführt. Es liegt noch keine Freigabe zur PROD-SQL-Ausführung oder zum Frontend-Deploy vor.
