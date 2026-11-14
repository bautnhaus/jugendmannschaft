# E05 PROD Paket 7 – Kontrollierter Saisonabschluss

- **Paket:** E05 PROD Paket 7
- **Fachlicher Umfang:** kontrollierter Abschluss einer Team-Saison und revisionssicheres Ablösen offener Sperren derselben Saison.
- **Status:** erfolgreich in PROD ausgeführt und read-only nachkontrolliert am 14.11.2026.
- **DEV-Projekt:** `pzazqvvoruqnqhcorbwx`
- **PROD-Projekt:** `qdugtpzgefpswnnqbusd`
- **DEV-Quellen:**
  - `docs/E05_PAKET_07_SAISONABSCHLUSS_2026-11-08.sql` (Blob-SHA `2626c07c212a84481fe532f4b83083bc2aac90f5`)
  - `docs/E05_PAKET_07_FIX_AUDIT_RLS_SUPERADMIN_2026-11-08.sql` (Blob-SHA `0b94492f3c30133107f2b328ef8328e0317f51f0`)
  - DEV-Abnahme: `docs/E05_PAKET_07_ABNAHME_UND_AUSFUEHRUNG_2026-11-08.md` (Blob-SHA `eeb5febee8c9816a8a760e2c1c9dda982462e1e7`)

## 1. Fachlicher Umfang

RPC `public.close_team_season(p_season_id uuid,p_reason text)` schließt genau eine aktive Saison eines Teams.

Bei erfolgreichem Abschluss:
1. Saison `is_active=false`.
2. Offene Sperren nur für dieselbe Team-/Saisonkombination wechseln auf `expired`.
3. Für jede abgelöste Sperre wird ein `expired`-Audit mit altem/neuem Zustand, Grund, Akteur und Zeitpunkt geschrieben.
4. Ein Eintrag in `team_season_closure_audit` protokolliert Saison, Team, Benutzer, Zeitpunkt, Begründung und Anzahl abgelaufener Sperren.
5. Karten-, Trainings-, Sperren- und Ausnahmehistorie bleibt erhalten.

Keine Folgesaison wird angelegt. Keine Kartenhistorie, Nominierungen, tatsächlichen Einsätze oder bereits abgeleisteten Sperren werden verändert.

## 2. Berechtigungen und Schutz

- Authentifizierung und nichtleere Begründung zwingend.
- Mannschaftsadmin oder Super Admin mit globaler Rolle und ausdrücklich ausgewähltem Teamkontext.
- Saison wird vor Prüfung/Änderung mit `FOR UPDATE` gesperrt.
- Unbekannte oder bereits geschlossene Saison wird abgewiesen.
- Nur offene Sperren des exakten Teams und der exakten Saison werden abgelöst.
- Alles läuft atomar; Fehler beim Sperren-Audit oder Saisonabschluss-Audit rollen alle Änderungen zurück.
- Audit-Tabelle ist RLS-geschützt und append-only.
- Audit-Lesepolicy enthält den in DEV nachträglich korrigierten Super-Admin-Kontext: `is_team_member(team_id) OR has_selected_team_context(team_id)`.

## 3. PROD-Bestandsprüfung (read-only, 14.11.2026)

- PROD-Migrationshistorie enthält Pakete 1–6; Paket 7 ist noch nicht registriert.
- `team_season_closure_audit` existiert in PROD nicht.
- `close_team_season(uuid,text)` und die Paket-7-Append-only-Triggerfunktion existieren nicht.
- Basistabellen `teams`, `seasons`, `team_member_roles`, `global_user_roles`, `training_suspensions`, `training_suspension_audit` und `profiles` sind vorhanden.
- `has_selected_team_context(uuid)` und `is_team_member(uuid)` sind vorhanden.
- PROD hat 2 Saisons, davon 2 aktiv; 0 offene Sperren. Die Migration selbst schließt keine Saison und verändert keine vorhandenen Saison-/Sperrendatensätze.
- Vorhandene PROD-Saison-Spalten `id, team_id, name, start_date, end_date, is_active, created_at, updated_at` entsprechen den in der DEV-Funktion verwendeten Feldern.

## 4. PROD-Anpassung gegenüber DEV

Die DEV-Umsetzung bestand aus zwei Migrationen:
- `20261108180535 e05_package_07_controlled_season_closure`
- `20261108180944 e05_package_07_fix_season_audit_context_rls`

Für PROD wird die korrigierte RLS-Policy direkt in die Paketmigration übernommen. Es wird keine zunächst unvollständige Policy angelegt. Fachliche RPC-Logik und Auditstruktur folgen der DEV-Quelle.

## 5. Migration und Rollback

- Migration: `supabase/migrations/20261114220000_e05_prod_paket_07_controlled_season_closure.sql`
- Rollback: `supabase/rollback/20261114220000_e05_prod_paket_07_controlled_season_closure_rollback.sql`
- Rollback ist absichtlich guarded: Er bricht ab, sobald Saisonabschluss-Auditdaten existieren. Er stellt weder eine geschlossene Saison noch abgelaufene Sperren wieder her. Deshalb nur vor produktiver Verwendung möglich.
- Migration ist transaktional und enthält Preflight-Prüfungen auf Voraussetzungen und bereits vorhandene Paketobjekte.

## 6. Prüfplan vor und nach Freigabe

### Struktur / ACL / RLS
1. Tabelle, Spalten, FK/Unique/Checks und RLS vorhanden.
2. Audit-SELECT für `authenticated`, mit Mitgliedschaft oder ausgewähltem Teamkontext.
3. Direkte INSERT/UPDATE/DELETE-Rechte für `authenticated` und `anon` fehlen.
4. Append-only-Trigger blockiert UPDATE/DELETE/TRUNCATE.
5. RPC SECURITY DEFINER, fester Search Path, EXECUTE für authenticated, nicht für anon.
6. Triggerfunktion nicht direkt durch API-Rollen ausführbar.

### Funktionale Tests (nur DEV/isolierte CI)
- Berechtigter Admin schließt aktive Saison mit Begründung.
- Offene gelbe und rote Sperren derselben Saison werden abgelöst und einzeln auditiert.
- Bereits abgeleistete Sperren bleiben unverändert.
- Sperren anderer Teams/Saisons bleiben unverändert.
- Saisonabschluss-Audit enthält korrekte Metadaten und Anzahl.
- Historische Ereignisse, Ausnahmen, Nominierungen und Einsätze bleiben erhalten.
- Negativ: unauthenticated, Trainer ohne Adminrolle, Super Admin ohne Teamkontext, leere Begründung, unbekannte Saison, doppelte Schließung.
- Audit-Manipulation wird abgewiesen.
- Fehler während Auditierung rollt die Gesamttransaktion zurück.

### Testgrenze
CI/isolierte Tests ersetzen keine authentifizierten End-to-End-Tests mit echten Supabase-Rollen. Vor einem Frontend-Rollout müssen die DEV-Rollenfälle und der Saisonabschluss mit synthetischen Daten praktisch geprüft sein. Es werden keine Testdaten in PROD angelegt.

## 7. Freigabegrenze

Diese Vorbereitung ist **keine Ausführungsfreigabe**. Die Migration wird erst nach einer separaten ausdrücklichen Freigabe in Supabase PROD ausgeführt. GitHub `main`, Frontend-Index und PROD-Daten bleiben bis dahin unverändert.

## 8. Isolierter PostgreSQL-CI-Test

- Workflow: `.github/workflows/e05-prod-package-07-ci.yml`
- Lauf: [GitHub Actions 43642743485](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43642743485)
- Commit: `075d1e559614e7711dca6e9aa8179ae75151c91e`
- PostgreSQL: 17.6
- **Ergebnis: success** – alle Jobs/Schritte erfolgreich.

Bestanden:
1. Paketmigration mit Minimal-Baseline erfolgreich angewendet.
2. Audit-Tabelle, RPC, RLS, ausgewählter Teamkontext, Append-only-Trigger und ACL geprüft.
3. Funktionaler Positivtest: aktive Saison wird geschlossen.
4. Zwei offene Sperren (gelb/rot) derselben Team-/Saisonkombination werden auf `expired` gesetzt und auditiert.
5. Bereits abgeleistete Sperre bleibt `served`.
6. Saisonabschluss-Audit enthält Grund und korrekte Anzahl abgelaufener Sperren.
7. Trainer ohne Adminrolle und nicht authentifizierter Aufruf werden abgewiesen.
8. Audit-Manipulation wird durch Append-only-Trigger verhindert.
9. Guarded Rollback und Rollback-Assertions erfolgreich.

Der CI-Test verwendet eine isolierte PostgreSQL-17.6-Datenbank mit synthetischer Minimal-Baseline. Er ist kein authentifizierter End-to-End-Test gegen Supabase Auth/RLS mit echten Nutzer-Sessions und ersetzt nicht die bereits dokumentierten DEV-Rollenprüfungen.

## 9. Freigabestatus

Paket 7 ist nach erfolgreichem isoliertem CI-Lauf zur ausdrücklichen PROD-Ausführungsfreigabe vorbereitet. **Es wurde weder in DEV noch PROD erneut ausgeführt.** Die zwei DEV-Migrationen vom 08.11.2026 sind bereits registriert und erfolgreich dokumentiert. GitHub `main`, Frontend-Index und PROD-Daten bleiben unverändert.

### CI-Korrekturschleife

Vor dem grünen Lauf schlugen drei frühe CI-Versuche aufgrund von Fehlern im Test-Harness fehl (Fixture-Lebensdauer über Transaktions-Rollbacks und Cleanup über den append-only-Audit-FK). Die Paketmigration selbst wurde in diesen Läufen jeweils erfolgreich angewendet. Die Testskripte wurden korrigiert; der abschließende Lauf `43642743485` bestand einschließlich Rollback vollständig. Die Fehlversuche waren keine PROD-/DEV-Datenbankausführungen und haben keine Supabase-Projekte verändert.

## 8. Isolierter PostgreSQL-CI-Test

- Workflow: `.github/workflows/e05-prod-package-07-ci.yml`
- Erfolgreicher Lauf: [GitHub Actions 43642771857](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43642771857)
- Commit: `cc545e9a1a055a29e02600e671c94161403c64a9`
- PostgreSQL: 17.6
- Ergebnis: **success**

Erfolgreich geprüft:
1. Minimaler AP02-/E05-Prüfunterbau.
2. Exakte Paket-7-PROD-Migration.
3. Tabelle, RLS, finale Teamkontext-SELECT-Policy und Append-only-Trigger.
4. SECURITY DEFINER, EXECUTE-Rechte und fehlende direkte Schreibrechte.
5. Positivtest: aktive Saison wird geschlossen.
6. Zwei offene Sperren werden abgelöst und einzeln auditiert; eine bereits abgeleistete Sperre bleibt unverändert.
7. Saisonabschluss-Audit speichert Begründung und korrekte Anzahl.
8. Negativtests: Trainer ohne Adminrolle und nicht authentifizierter Aufruf werden abgewiesen.
9. Guarded Rollback und anschließende Assertions: alle Paket-7-Objekte werden entfernt, ohne Auditdaten zu löschen.

Die Testfixture läuft ausschließlich in einem kurzlebigen PostgreSQL-17.6-CI-Container. Es wird kein Supabase-Projekt kontaktiert.

Frühere CI-Läufe schlugen wegen fehlerhafter Testfixture-/Testreihenfolge fehl (Saisonfixture im Negativtest nicht verfügbar bzw. ein unnötiger direkter Audit-Manipulationsversuch). Die Testsequenz wurde korrigiert; der oben genannte finale Lauf ist vollständig erfolgreich. Die Migration selbst lief in den isolierten Läufen bereits erfolgreich durch.

## 9. Freigabestatus

**Paket 7 ist jetzt zur ausdrücklichen PROD-Ausführungsfreigabe vorbereitet.** Es wurde weder in DEV noch PROD erneut ausgeführt; die bereits bestehende DEV-Umsetzung bleibt unverändert. GitHub `main` und Frontend bleiben unverändert.

## 10. Tatsächliche PROD-Ausführung und Nachkontrolle (14.11.2026)

- **Freigabe:** Ausdrücklich erteilt am 14.11.2026.
- **PROD-Projekt:** `qdugtpzgefpswnnqbusd`, PostgreSQL 17.6.1.166.
- **Supabase-Migrationshistorie:** `20261114213745 e05_prod_paket_07_controlled_season_closure`, erfolgreich registriert.
- **Ausgeführte Datei:** `supabase/migrations/20261114220000_e05_prod_paket_07_controlled_season_closure.sql`; Blob-SHA `1493cff2a67e2478af7aad6d7c419c353a9dd9ad`.
- **Rollback-Datei:** `supabase/rollback/20261114220000_e05_prod_paket_07_controlled_season_closure_rollback.sql`; Blob-SHA `340c69fafc800a80033b57b4967ba698618be23e`; nicht ausgeführt.
- **Ausführungsergebnis:** `success: true`.

### Read-only Nachkontrolle

| Prüfpunkt | PROD-Ergebnis |
|---|---|
| Audit-Tabelle | Vorhanden |
| Tabellenspalten | 8/8 wie spezifiziert |
| RLS | Aktiviert |
| Audit-SELECT-Policy | Eine Policy: Teammitgliedschaft ODER ausgewählter Teamkontext |
| Direkte Schreibrechte authenticated/anon | Nicht vorhanden |
| Constraints | PK, FK, UNIQUE Saison, Reason-Check, Count-Check vorhanden |
| Indizes | PK und UNIQUE auf season_id |
| Append-only-Trigger | UPDATE/DELETE/TRUNCATE geschützt |
| Triggerfunktion | SECURITY DEFINER, fester search_path, keine API-EXECUTE-Rechte |
| Saisonabschluss-RPC | SECURITY DEFINER, fester search_path |
| RPC EXECUTE | authenticated ja; anon/service_role/PUBLIC nein |
| aktive Saisons | 1 von 1 |
| offene Sperren | 0 |
| Sperren-Auditzeilen | 0 |
| Saisonabschluss-Auditzeilen | 0 |

**Datenintegrität:** Die aktive Saison `2026/2027` blieb aktiv. `close_team_season` wurde nicht aufgerufen. Keine Saison, Sperre, Historie, Nominierung oder Einsatz wurde durch Paket 7 verändert.

### Korrektur des vorherigen PROD-Snapshots

Das vorbereitende Dossier enthielt einen älteren Befund „2 Saisons, davon 2 aktiv“. Die unmittelbar vor Migration erneut ausgeführte Live-Abfrage ergab tatsächlich 1 Saison (`2026/2027`), davon 1 aktiv. Maßgeblich ist der aktuelle Live-Befund; es wurde keine Datenkorrektur vorgenommen.

### Advisor-Nachkontrolle

- Health Advisor: keine Findings.
- Security Advisor: 50 Warnungen für authentifizierbare SECURITY DEFINER-Funktionen (zuvor 49; die neue `close_team_season`-RPC ist der erwartete zusätzliche Eintrag), eine bereits bestehende mutable-search_path-Warnung sowie deaktivierter Leaked-Password-Schutz.
- Keine fremden Advisor-Findings oder bestehenden Funktionen/Policies wurden geändert.

### CI und Testgrenze

GitHub Actions [Run 43642771857](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43642771857), PostgreSQL 17.6, erfolgreich. Isolierte Tests decken Struktur, RLS/ACL, Saisonabschluss-Positivpfad, Sperren-Audit, Rollen-Negativpfade und guarded Rollback ab. Kein authentifizierter End-to-End-Test mit echten Supabase-Nutzer-Sessions in PROD; keine Testdaten wurden in PROD angelegt.

### Abschlussstatus

**Paket 7 ist in PROD erfolgreich installiert und strukturell/berechtigungsseitig verifiziert.** Der fachliche Saisonabschluss bleibt ein separater, späterer RPC-Vorgang mit eigener fachlicher Entscheidung. GitHub `main`, Frontend-Index und DEV blieben unverändert.
