# E23 – PROD-Releasevorbereitung (18.11.2026)

**Status:** Paket 1 ausgeführt und nachkontrolliert; Pakete 2–6 vorbereitet  
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

- Paket 1 wurde am 18.11.2026 erfolgreich in PROD ausgeführt und nachkontrolliert. Ledger-Version `20261118070757`.
- Pakete 2–6 sind vorbereitet, aber noch nicht ausgeführt.
- `main` und das PROD-Frontend sind unverändert. Der reguläre Deploy `develop` → `main` erfolgt erst nach erfolgreichem DB-Release aller sechs Schritte.
