# Release Notes – 1.5.2 (PROD)

**Datum:** 02.11.2026  
**Status:** PROD-Deployment laut Nutzer erfolgt. Der Post-Deploy-Smoke-Test und der aktuelle PROD-Commit-SHA sind hier nicht unabhängig bestätigt.

## Frontend-Änderungen
- Mannschaftslisten berücksichtigen nur aktive Mannschaften (`active = true`).
- Hinweis-/Bestätigungstext zur Mannschaftsdeaktivierung angepasst.
- Guard in `openEditTeamForm` korrigiert: gültiger Vereinskontext und passende Berechtigung sind Voraussetzung.
- Bekannte Commits aus der Vorarbeit: `ce75777434fb0ef119b53204ab7767b86bb0f551` und `e5bbcf0b233f3c166c09f91c8d72f4684e5afef7`.
- Vor Deployment bekannter `develop/index.html`-SHA: `4a07dd8221669e2919e77317bca3ebec6c1b2a9c` (kein bestätigter Post-Deploy-SHA).

## Umgesetzte SQL-/Datenbankänderungen im dokumentierten Verlauf

### Migration 15 – Soft-Deaktivierung von Mannschaften
Laut Projektverlauf in DEV und PROD ausgeführt und verifiziert.

```sql
ALTER TABLE public.teams
  ADD COLUMN IF NOT EXISTS active boolean NOT NULL DEFAULT true;
```

Zusätzlich wurde `public.remove_team(p_team_id uuid)` zur Soft-Deaktivierung eingeführt/verwendet. Die vollständige Originaldefinition ist nicht in dieser Release-Notiz eingebettet und muss vor künftigen Änderungen direkt aus Supabase ausgelesen werden.

### ACL-Bereinigung interner Funktionen in PROD
Laut Projektverlauf ausgeführt:

```sql
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.log_team_role_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.prevent_last_team_admin_removal() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
```

Laut damaliger Prüfung wurden die Ausführungsrechte für diese Rollen entzogen. Ein vollständiger Runtime-Test aller betroffenen Trigger ist nicht als abgeschlossen dokumentiert.

### Weitere dokumentierte DB-Prüfungen
- Pakete/Migrationen 1–9 und 10–14 wurden laut Projektverlauf manuell in PROD angewendet; Migration 14 wurde als ausgeführt/verifiziert gemeldet. Die exakten SQL-Inhalte sind nicht in dieser Release-Notiz rekonstruiert.
- `admin_update_club_member_profile(uuid,uuid,text,text)`: `anon` ohne EXECUTE, `authenticated` mit EXECUTE in DEV und PROD.
- `save_player_with_positions`: PROD-Definition geprüft und als passend beurteilt.
- 25 Frontend-RPCs, relevante RLS-Policies und Storage-Buckets `club-assets`/ `profile-avatars` wurden laut vorherigem Abgleich geprüft.

## Zurückgestellt
Die Mitglieder-/Trainer-Einladung ist nicht Teil dieses Releases. DEV-Einladungslinks führten auf PROD/normalen Login; der Name wurde offenbar trotz Erfolgsmeldung nicht gespeichert; bestehende Benutzer und Mannschaftszuordnungen müssen vor einer Einladung geprüft werden.

## Empfohlene Post-Deploy-Prüfung
1. PROD-App lädt und Login funktioniert.
2. Mannschaftskontext öffnet korrekt.
3. Deaktivierte Mannschaften erscheinen nicht in der aktiven Liste.
4. Mannschaftsdetails und eine harmlose berechtigte Bearbeitung funktionieren.
5. Spieler, Training und Spieltage sind erreichbar.
Keine Testdaten in PROD erzeugen.


## Ergänzende SQL-Änderungen aus dem dokumentierten Verlauf

Die folgenden ACL-Anweisungen wurden laut Projektverlauf in PROD ausgeführt:

```sql
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.log_team_role_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.prevent_last_team_admin_removal() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
```

Laut damaliger Verifikation war EXECUTE für diese Funktionen für `PUBLIC`, `anon` und `authenticated` entzogen. Trigger-Runtime-Tests sind nicht als vollständig abgeschlossen dokumentiert. Für Migration 15 ist die bekannte DDL-Ergänzung `teams.active boolean NOT NULL DEFAULT true`; die vollständige Originaldefinition von `remove_team(p_team_id uuid)` muss direkt aus Supabase gelesen werden. Die genauen Original-SQL-Inhalte der historischen Pakete 1–14 sind nicht vollständig in dieser Release-Notiz rekonstruiert.
