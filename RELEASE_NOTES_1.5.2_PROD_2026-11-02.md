# Release Notes – 1.5.2 (PROD)

**Datum:** 02.11.2026  
**Status:** PROD-Deployment laut Nutzerbestätigung erfolgt. Ein unabhängiger Post-Deploy-Smoke-Test und der tatsächliche Post-Deploy-Commit-SHA sind nicht dokumentiert.

## Frontend-Änderungen
- Mannschaftslisten berücksichtigen nur aktive Mannschaften (`active = true`).
- Hinweis-/Bestätigungstext zur Mannschaftsdeaktivierung angepasst.
- Guard in `openEditTeamForm` korrigiert: gültiger Vereinskontext und passende Berechtigung sind Voraussetzung.
- Bekannte Commits aus der Vorarbeit: `ce75777434fb0ef119b53204ab7767b86bb0f551` und `e5bbcf0b233f3c166c09f91c8d72f4684e5afef7`.
- Vor Deployment bekannter `develop/index.html`-SHA: `4a07dd8221669e2919e77317bca3ebec6c1b2a9c` (kein bestätigter Post-Deploy-SHA).

## Datenbank- und Berechtigungsänderungen
- Migration 15 – Soft-Deaktivierung von Mannschaften: `public.teams.active boolean NOT NULL DEFAULT true` und `public.remove_team(p_team_id uuid)`; laut Projektverlauf in DEV und PROD ausgeführt/verifiziert. Die vollständige Originaldefinition von `remove_team` ist vor jeder späteren Änderung direkt aus der Zielumgebung auszulesen.
- ACL-Bereinigung interner Funktionen in PROD: EXECUTE-Rechte für `PUBLIC`, `anon` und `authenticated` auf `handle_new_user()`, `log_team_role_change()`, `prevent_last_team_admin_removal()` und `rls_auto_enable()` wurden laut Projektverlauf entzogen. Ein vollständiger Runtime-Test aller betroffenen Trigger ist nicht als abgeschlossen dokumentiert.
- Weitere historische Prüfungen: Pakete/Migrationen 1–9 und 10–14 wurden laut Projektverlauf manuell in PROD angewendet; Migration 14 wurde als ausgeführt/verifiziert gemeldet. `admin_update_club_member_profile(uuid,uuid,text,text)`, `save_player_with_positions`, 25 Frontend-RPCs, relevante RLS-Policies sowie die Storage-Buckets `club-assets` und `profile-avatars` wurden laut früheren Prüfungen untersucht. Diese Angaben sind historische Nachweise, keine aktuelle Live-Verifikation.

Die technischen Einzelheiten und Prüfgrenzen stehen im [Datenbank-Changelog](DB_CHANGELOG.md). Die tatsächlichen Ausführungsnachweise für schreibende SQL-Eingriffe stehen im [SQL-Migrationsprotokoll](DB_MIGRATION_LOG.md). Diese Release-Notiz ist kein Ersatz für die beiden Protokolle.

## Zurückgestellt
Die Mitglieder-/Trainer-Einladung ist nicht Teil dieses Releases. DEV-Einladungslinks führten auf PROD bzw. den normalen Login statt in den erwarteten Passwort-Erstellungsfluss; der Name wurde offenbar trotz Erfolgsmeldung nicht gespeichert. Bestehende Benutzer und Mannschaftszuordnungen müssen vor einer neuen Einladung geprüft werden.

## Empfohlene Post-Deploy-Prüfung
1. PROD-App lädt und Login funktioniert.
2. Mannschaftskontext öffnet korrekt.
3. Deaktivierte Mannschaften erscheinen nicht in der aktiven Liste.
4. Mannschaftsdetails und eine harmlose berechtigte Bearbeitung funktionieren.
5. Spieler, Training und Spieltage sind erreichbar.

Keine Testdaten in PROD erzeugen.
