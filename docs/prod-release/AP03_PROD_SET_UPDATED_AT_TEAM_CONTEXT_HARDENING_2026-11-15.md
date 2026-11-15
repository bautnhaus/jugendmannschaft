# AP03 – PROD-Härtung: set_updated_at und Team-Kontext-RLS

**Datum:** 15.11.2026  
**Zielumgebung:** Supabase PROD  
**Projekt-ID:** `qdugtpzgefpswnnqbusd`  
**Status:** in PROD erfolgreich ausgeführt und read-only verifiziert (15.11.2026; Ledger `20261115134422`)  
**Quelle:** DEV-Praxistest der Superadmin-Kontextkorrektur erfolgreich

## Ziel und fachlicher Hintergrund

Die DEV-Korrektur wurde durch den Nutzer in den Fällen Superadmin ohne Kontext sowie Superadmin mit ausgewähltem Kontext erfolgreich getestet. In PROD bestehen die selbstbezogenen Kontext-SELECT-Policies und die kontextgebundenen Policies auf `club_members` und `club_member_roles bereits. Zwei konkrete Abweichungen bleiben:

1. `public.set_updated_at()` hat in PROD keinen festgelegten `search_path`. Die Funktion wird von sechs bestehenden Update-Triggern verwendet.
2. `teams_select_context_admin` enthält weiterhin einen unbedingten Superadmin-Zweig und erlaubt so das Lesen von Mannschaften ohne ausgewählten Vereinskontext.

## Geprüfter PROD-Ausgangsstand (read-only, 15.11.2026)

- `set_updated_at()`: SECURITY INVOKER, Owner `postgres`, kein `proconfig`/kein fester search_path.
- Ausgangsdefinition MD5: `8de7ae383447503e8949149bfb3f0efb`.
- ACL: `PUBLIC`, `anon`, `authenticated`, `service_role` und `postgres` besitzen EXECUTE. Die Migration verändert diese ACL ausdrücklich nicht.
- Sechs bestehende Trigger verwenden `set_updated_at()`: `matchday_attendance`, `matchdays`, `players`, `seasons`, `teams`, `trainings`.
- `teams_select_context_admin` enthält einen direkten Superadmin-Zweig. Ausgangs-Policyqualifier MD5: `26656e900f10c80db415ed9cf321f812`.
- `can_manage_club_context(uuid)` bindet Superadmin-Zugriff bereits an `user_club_context` für den angefragten Verein.
- `is_club_admin(uuid)` ist bereits kontextgebunden.
- `club_members_select_member_or_admin` und `club_member_roles_select_member_or_admin` verwenden bereits `is_club_admin` und `can_manage_club_context`.
- `user_club_context_select_self` und `user_team_context_select_self` sind vorhanden und auf `user_id = auth.uid()` beschränkt.
- RLS bleibt in diesem Paket unverändert aktiviert.

## Geplanter Änderungsumfang

A. `public.set_updated_at()`: identischen Funktionskörper und INVOKER-Verhalten beibehalten; `search_path=pg_catalog, public` fest setzen. Keine ACL-Änderung, keine Triggeränderung.

B. `teams_select_context_admin`: pauschalen Superadmin-Zweig entfernen und stattdessen `public.can_manage_club_context(club_id)` verwenden. Bestehende Teammitglied-Policy `teams_select` und alle übrigen Policies bleiben unverändert.

**Nicht enthalten:** Änderung an anderen Funktionen, Tabellen, Spalten, Datensätzen, Triggern, Grants, Storage-Objekten oder Auth-Einstellungen.

## Dateien

- Migration: `supabase/migrations/20261115140000_ap03_prod_set_updated_at_and_team_context_hardening.sql`
- Rollback: `supabase/rollback/20261115140000_ap03_prod_set_updated_at_and_team_context_hardening_rollback.sql`

Beide Dateien besitzen strenge Preflight-/Postflight-Prüfungen. Die Migration bricht ab, falls der Live-Ausgangsstand nicht dem geprüften Snapshot entspricht.

## Ausführung und Verifikation

**Status:** erfolgreich in PROD ausgeführt und strukturell read-only nachkontrolliert.

- **Supabase-Migrationsversion:** `20261115134422`
- **Migrationsname:** `ap03_prod_set_updated_at_and_team_context_hardening`
- **Ausführungsweg:** verbundenes Supabase-Migrationswerkzeug (`apply_migration`)
- **Supabase-Ergebnis:** `success: true`
- **Migration in develop:** `supabase/migrations/20261115140000_ap03_prod_set_updated_at_and_team_context_hardening.sql`
- **Migration Blob-SHA:** `e70c46db6f7c60f5bc16cc9a490e72e1a1e8b779`
- **Rollback in develop:** `supabase/rollback/20261115140000_ap03_prod_set_updated_at_and_team_context_hardening_rollback.sql`
- **Rollback Blob-SHA:** `04038691bf6ff4c96ca8f0c6d7d6415c2275fd83`

### Read-only Postflight

- `set_updated_at()` besitzt jetzt `search_path=pg_catalog, public`.
- Die Funktion bleibt `SECURITY INVOKER`; Owner bleibt `postgres`.
- Die bestehende EXECUTE-ACL blieb exakt erhalten.
- Alle sechs vorhandenen Update-Trigger sind weiterhin vorhanden und unverändert.
- `teams_select_context_admin` verwendet jetzt `can_manage_club_context(teams.club_id)`; der pauschale Superadmin-Zweig ist entfernt.
- `club_members` und `club_member_roles` behalten ihre bereits vorhandenen kontextgebundenen Richtlinien.
- Beide Self-only-Kontext-Policies bleiben erhalten.
- `is_club_admin()` und `can_manage_club_context()` blieben unverändert und behalten ihren festen search_path.
- Keine fachlichen Daten, Tabellen, Spalten, Trigger, Grants oder Storage-Objekte wurden geändert.

### Advisor-Nachkontrolle

- Health Advisor: keine Findings.
- Security Advisor: 54 projektweite Hinweise zu SECURITY-DEFINER-Funktionen, die für `authenticated` ausführbar sind, sowie ein Hinweis auf deaktivierten Schutz vor kompromittierten Passwörtern. Diese bestehenden Befunde wurden nicht Teil dieser eng begrenzten Migration und nicht pauschal verändert.

### Fachliche Abnahme

DEV wurde zuvor durch den Nutzer in den Fällen Superadmin ohne ausgewählten Verein sowie Superadmin mit ausgewähltem Verein erfolgreich getestet. Die PROD-Migration entspricht diesem getesteten Kontextprinzip. Ein separater authentifizierter PROD-Praxistest ist nicht durch diese strukturelle Postflight-Prüfung ersetzt.

## Rollback

Guarded Rollback liegt unter `supabase/rollback/20261115140000_ap03_prod_set_updated_at_and_team_context_hardening_rollback.sql` (Blob-SHA `04038691bf6ff4c96ca8f0c6d7d6415c2275fd83`). Nicht ausgeführt. Er würde den zuvor bestehenden unbedingten Superadmin-Zweig der Team-Policy und den unfixierten search_path wiederherstellen und darf daher nur nach gesonderter Entscheidung ausgeführt werden.

Nach Freigabe werden Migrationsledger, Funktionsdefinition, search_path, ACL, alle sechs Trigger, Team-SELECT-Policy, übrige Kontext-Policies und Security/Health Advisor read-only nachkontrolliert. Die tatsächliche Ausführung ist in `DB_MIGRATION_LOG.md` (DB-MIG-2026-023) und `DB_CHANGELOG.md` dokumentiert.

## Rollback

Der guarded Rollback stellt die vorgefundenen PROD-Definitionen wieder her. Er ist nicht ausgeführt und darf nur nach gesonderter Entscheidung verwendet werden. Die Wiederherstellung des unbedingten Superadmin-Zweigs würde den festgestellten Sicherheitsmangel wieder einführen.
