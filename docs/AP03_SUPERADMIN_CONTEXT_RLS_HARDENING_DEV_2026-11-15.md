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

Dieser Abschnitt wird nach dem tatsächlichen Supabase-Ausführungsversuch ergänzt. Eine GitHub-Datei allein ist kein Ausführungsnachweis.

## Testgrenzen

Die Struktur-/Funktions-/Policy-Nachkontrolle belegt die installierte Regel. Authentifizierte Positiv-/Negativtests mit echten Sitzungen (Superadmin ohne Kontext, Superadmin mit passendem/falschem Kontext, Vereinsadmin eigener/fremder Verein, Trainer/Teamadmin) müssen zusätzlich in der DEV-Oberfläche bzw. mit realen Auth-Sitzungen ausgeführt und dokumentiert werden. Es werden keine Testrollen, Mitgliedschaften oder fachlichen Daten künstlich angelegt.

## Rollback

`supabase/rollback/20261115130000_ap03_superadmin_context_rls_hardening_dev_rollback.sql` stellt den dokumentierten Ausgangszustand wieder her. Dieser Ausgangszustand enthält den zuvor festgestellten pauschalen Superadmin-Bypass. Rollback daher nur bei technischem Bedarf und nach ausdrücklicher Entscheidung; nicht als regulärer Abschluss ausführen.
