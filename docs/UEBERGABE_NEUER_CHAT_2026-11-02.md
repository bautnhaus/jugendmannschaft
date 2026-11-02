# Übergabe – Jugendmannschaft

**Stand:** 02.11.2026  
**Release:** 1.5.2 – PROD-Deployment laut Nutzer erfolgt  
**Nächster Fokus:** Mitglieder-/Trainer-Einladung gezielt analysieren

## Systeme und Branches
- Hauptrepository: https://github.com/bautnhaus/jugendmannschaft
- `develop`: Entwicklungs-/Releasequelle
- `main`: PROD-Branch; der Deploy-Workflow überträgt den geprüften Stand aus `develop`, konfiguriert PROD-Supabase und veröffentlicht GitHub Pages.
- DEV-Frontend-Repository: `bautnhaus/jugendmannschaft-dev`, Branch `main`
- PROD-App: https://bautnhaus.github.io/jugendmannschaft/
- Supabase DEV-Projekt-ID: `pzazqvvoruqnqhcorbwx`
- Supabase PROD-Projekt-ID: `qdugtpzgefpswnnqbusd`

## Release 1.5.2 – Stand
Der Nutzer hat bestätigt, dass PROD deployed wurde. Ein unabhängiger Post-Deploy-Smoke-Test und aktueller PROD-Commit-SHA sind noch nicht dokumentiert.

Bekannte Änderungen:
- `public.teams.active boolean NOT NULL DEFAULT true` zur Soft-Deaktivierung.
- `public.remove_team(p_team_id uuid)` als Soft-Deaktivierungsfunktion.
- Frontend filtert aktive Mannschaften mit `active = true`.
- Hinweis-/Bestätigungstext zur Deaktivierung angepasst.
- Guard in `openEditTeamForm` korrigiert, damit Vereinskontext und Berechtigung geprüft werden.
- Bekannte Commits: `ce75777434fb0ef119b53204ab7767b86bb0f551` und `e5bbcf0b233f3c166c09f91c8d72f4684e5afef7`.
- Vor Deployment bekannter `develop/index.html`-SHA: `4a07dd8221669e2919e77317bca3ebec6c1b2a9c`; nicht als Post-Deploy-SHA behandeln.

## SQL-/Datenbankstand aus dem dokumentierten Verlauf
- Pakete 1–9 und 10–14 wurden laut Verlauf manuell in PROD angewendet; Migration 14 wurde als ausgeführt/verifiziert gemeldet. Exakte Original-SQL-Dateien und Namen sind noch anhand der Migrationshistorie zu belegen.
- Migration 15: `teams.active` plus `remove_team(p_team_id uuid)`, laut Verlauf in DEV und PROD ausgeführt/verifiziert.
- In PROD wurden EXECUTE-Rechte für `PUBLIC`, `anon` und `authenticated` auf `handle_new_user()`, `log_team_role_change()`, `prevent_last_team_admin_removal()` und `rls_auto_enable()` entzogen.
- `admin_update_club_member_profile(uuid,uuid,text,text)` wurde mit `anon` ohne EXECUTE und `authenticated` mit EXECUTE geprüft.
- `save_player_with_positions`, 25 Frontend-RPCs, relevante RLS-Policies und Storage-Buckets `club-assets`/ `profile-avatars` wurden laut früherem Abgleich geprüft.
- Ein vollständiger Laufzeittest aller betroffenen Trigger ist nicht als abgeschlossen dokumentiert.
- Vor jeder künftigen Datenbankänderung Originaldefinitionen und aktuellen DEV-/PROD-Bestand read-only abrufen. Keine Migration oder schreibendes SQL ohne ausdrückliche Freigabe.

## Offener Auftrag: Mitglieder-/Trainer-Einladung

Bekannte Symptome:
1. Eine Einladung aus DEV öffnet PROD bzw. den normalen Login statt des Passwort-Erstellungsflusses.
2. Die UI meldete Versand-Erfolg, aber der eingegebene Name wurde offenbar nicht gespeichert.
3. Ein Trainerlogin scheiterte bei Zuordnung zu mehreren Mannschaften; nach Entfernen der zweiten Zuordnung funktionierte er.
4. Vor Einladung sollen bestehende Auth-Benutzer und Mannschaftszuordnungen erkannt werden.

### Erster Schritt im Folgechat – nur read-only
1. Aktuellen Aufruf von `invite-trainer` in der DEV-`index.html` und Payload lesen.
2. Originalcode der Edge Function `invite-trainer` sowie Redirect-URL-Logik lesen.
3. DEV Auth Site URL und Redirect-Allowlist prüfen; PROD nur lesend vergleichen.
4. E-Mail-Template und Passwort-Erstellungsroute prüfen.
5. Speicherung von Name, Rolle und Mannschaft nachverfolgen.
6. Verhalten für bereits vorhandene Auth-Benutzer und bestehende Mannschaftszuordnungen untersuchen.
7. Befunde mit konkreten Dateipfaden/Originaldefinitionen melden und minimalen Fix-/Testplan vorschlagen.

Noch nichts ändern, bevor der Nutzer den Plan freigegeben hat.

## Verbindliche Arbeitsregeln
- Der Nutzer ist kein Programmierer: kurze, klare Schritt-für-Schritt-Anweisungen geben.
- Nur DEV ändern; keine echten PROD-Einladungen.
- Keine SQL-Migration, schreibendes SQL oder Auth-/Edge-Konfigurationsänderung ohne ausdrückliche Zustimmung.
- Vor Codeänderung aktuelle `develop/index.html` frisch holen.
- Keine Originaldefinitionen aus dem Gedächtnis rekonstruieren.
- Keine PROD-Änderung oder PROD-Deploy ohne separate ausdrückliche Freigabe.
- Fokussiert beim Einladungsfehler bleiben; keine anderen Backlog-Themen eröffnen.
