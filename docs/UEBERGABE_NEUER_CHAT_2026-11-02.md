# Übergabe – Jugendmannschaft
**Stand:** 02.11.2026  
**Release:** 1.5.2 laut Nutzer nach PROD deployed.  
**Nächster Auftrag:** Mitglieder-/Trainer-Einladung analysieren und gezielt korrigieren.

## Systeme
- Hauptrepo: https://github.com/bautnhaus/jugendmannschaft
- `develop` = geprüfte Entwicklungsquelle, `main` = PROD
- separates DEV-Frontend-Repo: `bautnhaus/jugendmannschaft-dev`, Branch `main`
- PROD-App: https://bautnhaus.github.io/jugendmannschaft/
- Supabase DEV: `pzazqvvoruqnqhcorbwx`
- Supabase PROD: `qdugtpzgefpswnnqbusd`

## Release 1.5.2
- `teams.active boolean NOT NULL DEFAULT true` und `remove_team(p_team_id uuid)` für Soft-Deaktivierung; laut Verlauf in DEV und PROD ausgeführt/verifiziert.
- Frontend filtert aktive Teams und aktualisiert Deaktivierungshinweis.
- `openEditTeamForm`-Guard für Vereinskontext/Berechtigung korrigiert.
- In PROD wurden EXECUTE-Rechte für `PUBLIC`, `anon`, `authenticated` bei `handle_new_user()`, `log_team_role_change()`, `prevent_last_team_admin_removal()`, `rls_auto_enable()` entzogen.
- Migrationspakete 1–14 laut Verlauf in PROD angewendet; vollständige Original-SQL-Quellen müssen bei Bedarf read-only geprüft werden.
- Nutzer meldet PROD-Deployment erfolgt; unabhängiger Smoke-Test und Post-Deploy-SHA sind nicht dokumentiert.

## Offener Fehler: Einladung
1. Einladung aus DEV öffnet PROD bzw. normalen Login statt Passwort-Erstellung.
2. Erfolgsmeldung erschien, obwohl der eingegebene Name offenbar nicht gespeichert wurde.
3. Trainerlogin scheiterte bei mehreren Mannschaftszuordnungen; nach Entfernen der zweiten Zuordnung funktionierte er.
4. Vor Einladung bestehende Auth-Benutzer und Mannschaftszuordnungen erkennen.

## Erster Schritt im Folgechat
Read-only prüfen: Frontend-Aufruf/Payload von `invite-trainer`, Originalcode der Edge Function, DEV Auth Site URL/Redirect-Allowlist, E-Mail-Template, Speicherlogik für Name/Rolle/Mannschaft und Behandlung vorhandener Benutzer. Danach Belege/Pfade, Ursache und minimalen Fix-/Testplan nennen. Noch nichts ändern, bis der Nutzer zustimmt.

## Regeln
- Nur DEV; keine echten PROD-Einladungen.
- Keine Migration, schreibendes SQL oder Auth-/Edge-Konfigurationsänderung ohne ausdrückliche Zustimmung.
- Vor Codeänderungen aktuelle `develop/index.html` frisch holen.
- Keine Originaldefinitionen rekonstruieren.
- Kein PROD-Deploy ohne separate Freigabe.
- Fokus ausschließlich auf Einladung, keine anderen Backlog-Themen öffnen.
