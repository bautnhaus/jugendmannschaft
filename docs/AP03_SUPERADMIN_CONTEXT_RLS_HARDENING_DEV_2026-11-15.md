# AP03 – Superadmin-Kontext und RLS-Härtung (DEV)

**Datum:** 15.11.2026  
**Umgebung:** ausschließlich Supabase DEV  
**Projekt-ID:** `pzazqvvoruqnqhcorbwx`  
**PROD:** nicht verändert; separate Freigabe erforderlich  
**Branch:** `develop`

## Ziel

Die vereinbarte Rollenregel technisch durchsetzen: Superadmins bleiben vereinsneutral und erhalten Zugriff auf Vereins- und Mannschaftsdaten nur innerhalb eines ausdrücklich ausgewählten Vereins-/Teamkontexts. Vereinsadmins behalten ihren Zugriff auf den eigenen Verein. Benutzer dürfen ihre eigenen Kontextdatensätze lesen; direkte Kontext-Schreibrechte werden nicht neu vergeben.

## Freigegebener Umfang

1. `public.is_club_admin(uuid)`: Superadmin-Zugriff wird an `user_club_context` für genau die angefragte Vereins-ID gebunden.
2. `club_members_select_member_or_admin`: direkter pauschaler Superadmin-Bypass entfällt.
3. `club_member_roles_select_member_or_admin`: direkter pauschaler Superadmin-Bypass entfällt; Vereinsrollen fremder Mitglieder nur über den ausgewählten Verein.
4. `teams_select_context_admin`: Superadmin-Lesezugriff wird über `can_manage_club_context(club_id)` auf den ausgewählten Verein beschränkt.
5. `user_club_context_select_self`: Benutzer darf nur den eigenen Kontextdatensatz lesen.
6. `user_team_context_select_self`: Benutzer darf nur den eigenen Kontextdatensatz lesen.

Keine Tabellen, Spalten, Daten, Fremdschlüssel, Trigger, Storage-Buckets oder Storage-Policies werden geändert. Keine neuen Tabellen- oder Funktionsrechte werden vergeben. Die bestehende EXECUTE-ACL von `is_club_admin(uuid)` bleibt erhalten.

## Ausgangsbefund

Read-only geprüft am 15.11.2026:
- DEV-Funktion `is_club_admin(uuid)` gab für jeden Superadmin unabhängig vom ausgewählten Verein `true` zurück.
- Die beiden SELECT-Policies auf `club_members` und `club_member_roles` enthielten ebenfalls einen unbedingten `is_super_admin()`-Bypass.
- `teams_select_context_admin` ließ Superadmins alle Mannschaften lesen.
- DEV hatte noch keine eigenen SELECT-Policies auf `user_club_context` und `user_team_context`.
- RLS war auf allen fünf betroffenen Tabellen bereits aktiviert.
- Die Funktion war `SECURITY DEFINER`, Owner `postgres`, `search_path=pg_catalog, public`; EXECUTE für `authenticated` und `service_role`, nicht für `anon` oder `PUBLIC`.
- `can_manage_club_context(uuid)` erzwingt bereits den ausgewählten Vereinskontext für Superadmins und wird für die Mannschafts-Policy wiederverwendet.

## Ausführung und Verifikation

**Status:** erfolgreich in DEV ausgeführt und strukturell read-only nachkontrolliert.

- **Supabase-Migrationsversion:** `20261115114440`
- **Migrationsname:** `ap03_superadmin_context_rls_hardening_dev`
- **Ausführungszeitpunkt:** 15.11.2026, 12:44:40 Uhr MEZ (aus Supabase-Ledger-Zeitstempel)
- **Ausführungsweg:** verbundenes Supabase-Migrationswerkzeug (`apply_migration`)
- **Ergebnis:** `success: true`
- **Migrationsdatei:** `supabase/migrations/20261115130000_ap03_superadmin_context_rls_hardening_dev.sql`
- **Migrationsdatei Blob-SHA:** `dccd8b43e3b009a75cf960a76566ae7d17176b76`
- **Migrationsänderungs-Commit:** `c3fcb32509332623e3bac480d22c0606ffc83098`
- **Rollback-Datei:** `supabase/rollback/20261115130000_ap03_superadmin_context_rls_hardening_dev_rollback.sql`
- **Rollback Blob-SHA:** `4df263a7ed9321f19d4ce442c5587dc3d5f784aa`

**Read-only Postflight:**
- `is_club_admin(uuid)` enthält jetzt die explizite Prüfung auf `user_club_context.club_id = p_club_id`, wenn der Aufrufer Superadmin ist.
- Funktion weiterhin `SECURITY DEFINER`, Owner `postgres`, `search_path=pg_catalog, public`.
- EXECUTE-ACL unverändert: `authenticated` und `service_role` dürfen ausführen; `anon` und `PUBLIC` nicht.
- Die drei Vereins-/Mannschafts-Policies sind kontextgebunden; die direkten pauschalen Superadmin-Bypässe sind entfernt.
- Beide Kontext-SELECT-Policies sind vorhanden und auf `user_id = auth.uid()` beschränkt.
- RLS ist auf allen fünf betroffenen Tabellen weiterhin aktiviert.
- Keine Tabellen, Spalten, Daten, Trigger, Storage-Buckets oder Storage-Policies wurden geändert.

**Advisor-Nachkontrolle:** Health Advisor ohne Findings. Security Advisor meldet 52 projektweite Hinweise zu ausführbaren SECURITY-DEFINER-Funktionen und einen Hinweis auf deaktivierten Schutz vor kompromittierten Passwörtern. Diese Hinweise sind nicht automatisch Schwachstellen dieser Migration; die EXECUTE-ACL von `is_club_admin` blieb unverändert. Eine gesonderte Funktions-/ACL-Prüfung bleibt Bestandteil des weiteren Sicherheitsabgleichs.

**Nicht durchgeführte Tests:** Authentifizierte Positiv-/Negativtests mit echten Benutzer-Sitzungen wurden nicht simuliert. Insbesondere müssen Superadmin ohne Kontext, Superadmin mit passendem/falschem Vereinskontext, Vereinsadmin eigener/fremder Verein sowie Trainer/Teamadmin in der DEV-App geprüft werden. Bis dahin ist die strukturelle Migration erfolgreich, die vollständige fachliche Sicherheitsabnahme aber noch offen.


## Testgrenzen

Die Struktur-/Funktions-/Policy-Nachkontrolle belegt die installierte Regel. Authentifizierte Positiv-/Negativtests mit echten Sitzungen (Superadmin ohne Kontext, Superadmin mit passendem/falschem Kontext, Vereinsadmin eigener/fremder Verein, Trainer/Teamadmin) müssen zusätzlich in der DEV-Oberfläche bzw. mit realen Auth-Sitzungen ausgeführt und dokumentiert werden. Es werden keine Testrollen, Mitgliedschaften oder fachlichen Daten künstlich angelegt.

## Rollback

`supabase/rollback/20261115130000_ap03_superadmin_context_rls_hardening_dev_rollback.sql` stellt den dokumentierten Ausgangszustand wieder her. Dieser Ausgangszustand enthält den zuvor festgestellten pauschalen Superadmin-Bypass. Rollback daher nur bei technischem Bedarf und nach ausdrücklicher Entscheidung; nicht als regulärer Abschluss ausführen.
