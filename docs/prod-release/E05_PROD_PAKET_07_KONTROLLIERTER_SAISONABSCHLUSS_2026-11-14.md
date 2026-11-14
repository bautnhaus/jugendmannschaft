# E05 PROD Paket 7 – Kontrollierter Saisonabschluss

**Status:** Zur Freigabe vorbereitet; nicht ausgeführt  
**Ziel:** Supabase PROD `qdugtpzgefpswnnqbusd`  
**DEV:** `pzazqvvoruqnqhcorbwx`  
**GitHub:** ausschließlich Branch `develop`  
**PROD/main:** bis zur separaten Freigabe unverändert

## 1. Nachgewiesene DEV-Quellen

- `docs/E05_PAKET_07_SAISONABSCHLUSS_2026-11-08.sql` – Blob SHA `2626c07c212a84481fe532f4b83083bc2aac90f5`.
- `docs/E05_PAKET_07_FIX_AUDIT_RLS_SUPERADMIN_2026-11-08.sql` – Blob SHA `0b94492f3c30133107f2b328ef8328e0317f51f0`.
- `docs/E05_PAKET_07_ABNAHME_UND_AUSFUEHRUNG_2026-11-08.md` – Blob SHA `eeb5febee8c9816a8a760e2c1c9dda982462e1e7`.

Die DEV-Abnahme dokumentiert bestandene Positiv-, Negativ-, RLS-/ACL- und Rollbacktests. Die erste Audit-Policy wurde in DEV korrigiert; PROD-Paket 7 verwendet direkt die finale Policy `is_team_member(team_id) OR has_selected_team_context(team_id)`.

## 2. Fachlicher Umfang

RPC `public.close_team_season(p_season_id uuid,p_reason text)` schließt genau eine aktive Saison. In einer atomaren Transaktion:

1. Saison wird mit `FOR UPDATE` gesperrt und Berechtigung geprüft.
2. Alle offenen Sperren derselben Team-/Saisonkombination werden auf `expired` gesetzt.
3. Jede abgelaufene Sperre erhält einen `expired`-Audit-Eintrag mit Vorher-/Nachherzustand, Grund, Akteur und Zeitpunkt.
4. Saison wird inaktiv gesetzt.
5. `team_season_closure_audit` erhält einen eindeutigen Abschlussdatensatz.

Karten-, Trainings-, Sperren- und Ausnahmehistorie bleibt erhalten. Keine Folgesaison wird angelegt; Karten werden nicht übertragen. Nominierungen und tatsächliche Einsätze werden nicht verändert.

## 3. Berechtigungen und Schutz

- Authentifizierter Aufruf und nichtleere Begründung erforderlich.
- Nur Mannschaftsadmin (`team_member_roles.role='admin'`) oder Super Admin mit globaler Rolle und ausdrücklich ausgewähltem Teamkontext.
- Doppelte Saisonabschlüsse werden abgewiesen.
- Audit-Tabelle mit RLS; Lesen für Teammitglieder oder Benutzer mit ausgewähltem Teamkontext.
- Keine direkten Schreibrechte für `authenticated` oder `anon`.
- Append-only-Trigger verhindert UPDATE, DELETE und TRUNCATE.
- Fehler in einem Teil des Vorgangs rollen alle Änderungen zurück.

## 4. PROD-Baseline (read-only geprüft)

- Pakete 1–6 sind in der PROD-Migrationshistorie registriert; letzte Version: `20261114211343`.
- `seasons`, `training_suspensions`, `training_suspension_audit`, `team_member_roles`, `global_user_roles` und `profiles` sind vorhanden; die benötigten Spalten stimmen mit dem DEV-SQL überein.
- `is_team_member(uuid)` und `has_selected_team_context(uuid)` sind vorhanden.
- `team_season_closure_audit`, `close_team_season(uuid,text)` und `e05_reject_season_closure_audit_mutation()` fehlen erwartungsgemäß.
- PROD-Datenstand zum Prüfzeitpunkt: 1 Saison, davon 1 aktiv; 0 offene Sperren.
- Keine Daten wurden verändert.

## 5. PROD-Migration und Rollback

- Migration: `supabase/migrations/20261114220000_e05_prod_paket_07_controlled_season_closure.sql`.
- Rollback: `supabase/rollback/20261114220000_e05_prod_paket_07_controlled_season_closure_rollback.sql`.
- Die Migration enthält die finale DEV-RLS-Policy direkt und vermeidet die zwischenzeitliche, unvollständige Policy.
- Der Rollback ist absichtlich streng: Er bricht ab, sobald ein Saisonabschluss-Auditdatensatz existiert. Es werden keine Auditdaten oder abgelaufenen Sperren gelöscht oder zurückgesetzt.

## 6. Prüfplan nach Ausführung

### Struktur / ACL / RLS
- Migration registriert.
- Tabelle, RLS, finale SELECT-Policy und Append-only-Trigger vorhanden.
- RPC SECURITY DEFINER mit festem Search Path.
- EXECUTE für `authenticated`, nicht für `anon`/PUBLIC.
- Keine direkten Tabellen-Schreibrechte für `authenticated`/anon.

### Positivtests – ausschließlich DEV oder isolierte Testbasis
- Admin schließt aktive Saison mit Begründung.
- Offene gelbe und rote Sperren derselben Saison werden `expired`.
- Je Sperre genau ein `expired`-Audit; Saisonabschluss-Audit zählt korrekt.
- Bereits `served`-/`voided`-Sperren und andere Teams/Saisons bleiben unverändert.
- Historische Ereignisse, Ausnahmen, Nominierungen und Einsätze bleiben erhalten.

### Negativtests – ausschließlich DEV oder isolierte Testbasis
- anon/nicht authentifiziert; Trainer ohne Adminrolle; Super Admin ohne ausgewählten Kontext.
- Leere Begründung; unbekannte oder bereits geschlossene Saison.
- Audit-Manipulation und direkte Schreibversuche.
- Fehler beim Audit-Insert führt zum vollständigen Rollback.

**PROD wird nicht mit Test-Saisons oder Test-Sperren belastet.** Die PROD-Nachkontrolle beschränkt sich auf Struktur, ACL/RLS/Trigger, Migrationseintrag und unveränderte Bestandsdaten.

## 7. Grenzen

Die DEV-Abnahme ist dokumentiert. Die Paket-7-Funktion wurde in PROD noch nicht ausgeführt. Ein isolierter PostgreSQL-CI-Lauf für das neue PROD-Paket ist noch nicht eingerichtet/ausgeführt. Vor Ausführung ist dieser Testschritt noch abzuschließen. Keine Behauptung eines PROD-End-to-End-Tests.

## 8. Freigabestatus

**Paket 7 ist fachlich dokumentiert und als SQL-/Rollback-Paket vorbereitet.** Vor Ausführungsfreigabe wird der isolierte PostgreSQL-CI-Test ergänzt und ausgewertet. Es wurde weder in DEV noch PROD ausgeführt. GitHub `main` und Frontend bleiben unverändert.
