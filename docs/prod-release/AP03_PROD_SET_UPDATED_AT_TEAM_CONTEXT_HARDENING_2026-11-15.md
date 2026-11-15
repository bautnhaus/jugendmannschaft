# AP03 – PROD-Härtung: set_updated_at und Team-Kontext-RLS

**Datum:** 15.11.2026  
**Zielumgebung:** Supabase PROD  
**Projekt-ID:** `qdugtpzgefpswnnqbusd`  
**Status:** vorbereitet; ausdrückliche PROD-Freigabe und Ausführung stehen aus  
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

Noch nicht ausgeführt. Keine PROD-Änderung vorgenommen. Die Ausführung benötigt die ausdrückliche Freigabe des Nutzers.

Nach Freigabe werden Migrationsledger, Funktionsdefinition, search_path, ACL, alle sechs Trigger, Team-SELECT-Policy, übrige Kontext-Policies und Security/Health Advisor read-only nachkontrolliert. Der tatsächliche Ausführungsnachweis wird anschließend in `DB_MIGRATION_LOG.md` und `DB_CHANGELOG.md` dokumentiert.

## Rollback

Der guarded Rollback stellt die vorgefundenen PROD-Definitionen wieder her. Er ist nicht ausgeführt und darf nur nach gesonderter Entscheidung verwendet werden. Die Wiederherstellung des unbedingten Superadmin-Zweigs würde den festgestellten Sicherheitsmangel wieder einführen.
