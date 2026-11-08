# Jugendmannschaft – SQL-Migrations- und Ausführungsprotokoll

**Stand:** 05.11.2026  
**Führende Fassung:** Branch `develop`  
**Geltungsbereich:** Supabase DEV und PROD – alle tatsächlich ausgeführten schreibenden SQL-Anweisungen und SQL-Eingriffe, unabhängig vom Ausführungsweg.

## 1. Verbindliche Regel

Jede tatsächlich ausgeführte schreibende SQL-Anweisung bzw. jeder schreibende SQL-Eingriff muss hier dokumentiert werden. Das gilt ausnahmslos für:

- SQL aus versionierten Migrationsdateien,
- direkte Ausführung im Supabase SQL Editor,
- administrative SQL-Werkzeuge und sonstige Ausführungswege,
- DDL, DML, Änderungen an Funktionen/RPCs, Triggern, Policies, Grants und Berechtigungen,
- Datenkorrekturen und einmalige manuelle Eingriffe.

Reine Leseabfragen (z. B. `SELECT` ohne schreibende Seiteneffekte) werden nicht als Migration protokolliert. Bei gemischten Skripten mit Lese- und Schreibteilen wird der tatsächlich ausgeführte Schreibumfang erfasst.

**Wichtig:** Dieses Protokoll dokumentiert Ausführungen, nicht nur geplante oder vorhandene SQL-Dateien. Ein SQL-Skript in GitHub ist kein Beleg dafür, dass es in DEV oder PROD ausgeführt wurde. Eine erfolgreiche Ausführung in DEV ist kein Beleg für eine Ausführung in PROD.

## 2. Ablauf vor, während und nach einer Änderung

1. Zielumgebung eindeutig festlegen (DEV oder PROD).
2. Zweck, betroffene Objekte und vollständiges SQL vorlegen.
3. Ausdrückliche Freigabe des Projektverantwortlichen einholen. Ohne Freigabe keine schreibende Ausführung.
4. SQL ausschließlich in der freigegebenen Umgebung ausführen.
5. Unmittelbar danach den tatsächlichen Ausführungsstatus und das Ergebnis protokollieren.
6. Verifikation durchführen und verwendete Prüfungen sowie deren Ergebnis ergänzen.
7. Wenn dieselbe logische Änderung auch in der anderen Umgebung ausgeführt wird, dort einen eigenen Ausführungsnachweis ergänzen. Gleiche Migrations-ID, aber getrennte Umgebungsdatensätze verwenden.
8. Vor jedem PROD-Release dieses Protokoll mit den tatsächlichen DEV- und PROD-Datenbankständen abgleichen. Offene oder nicht belegte Ausführungen dürfen nicht als erledigt gelten.

Fehlgeschlagene, abgebrochene oder teilweise ausgeführte Schreibversuche werden ebenfalls erfasst, sofern eine Ausführung begonnen wurde oder ein möglicher Seiteneffekt nicht sicher ausgeschlossen ist. Sie sind eindeutig als fehlgeschlagen/teilweise/offen zu kennzeichnen und dürfen nicht als erfolgreiche Migration gezählt werden.

## 3. Pflichtangaben je Ausführung

Jeder Eintrag enthält mindestens:

- **Migrations-ID:** dauerhaft eindeutige Kennung der logischen Änderung (z. B. `DB-MIG-2026-001`).
- **Ausführungsdatensatz:** eindeutige Kennung je Umgebung (z. B. `DEV` oder `PROD`).
- **Datum und Uhrzeit:** tatsächlicher Ausführungszeitpunkt einschließlich Zeitzone, soweit verfügbar.
- **Umgebung:** Supabase DEV oder Supabase PROD.
- **Ausführungsweg:** GitHub-Migration, Supabase SQL Editor oder anderes konkret benanntes Werkzeug.
- **Anlass/Zweck:** warum die Änderung vorgenommen wurde.
- **SQL:** vollständiger tatsächlich ausgeführter Schreib-SQL-Text oder eindeutiger Verweis auf eine unveränderliche, versionierte SQL-Datei samt Commit-SHA. Bei manueller Ausführung den tatsächlich verwendeten SQL-Text hier oder in einer sicher referenzierten Datei ablegen.
- **Betroffene Objekte:** Tabellen, Spalten, Daten, Funktionen, RPCs, Trigger, Policies, Grants usw.
- **Ausführender/Freigabe:** wer ausgeführt hat und auf welche ausdrückliche Freigabe sich die Ausführung stützt.
- **Ergebnis:** erfolgreich, fehlgeschlagen, abgebrochen oder teilweise; Fehlermeldung bzw. Ergebnisnotiz.
- **Verifikation:** konkrete read-only Prüfung und Ergebnis; nicht verifiziert ausdrücklich als offen markieren.
- **Rollback/Wiederherstellung:** Rücknahme-SQL oder nachvollziehbare Wiederherstellungsstrategie; wenn nicht vorhanden, ausdrücklich vermerken.
- **Gegenstück/Abgleich:** zugehöriger Ausführungsdatensatz der anderen Umgebung oder Status „noch nicht ausgeführt/nicht zutreffend“.

Keine Secrets, Passwörter, API-Keys oder sonstige Zugangsdaten in dieses Protokoll kopieren. Falls der vollständige SQL-Text sensible Werte enthält, diese sicher auslagern und einen geschützten Verweis sowie eine redigierte Darstellung dokumentieren, ohne die Nachvollziehbarkeit zu verlieren.

## 4. Kennzeichnung des Ausführungsstatus

| Status | Bedeutung |
|---|---|
| Geplant | Noch nicht ausgeführt; kein Ausführungsnachweis |
| Erfolgreich | Ausführung bestätigt; Verifikation separat ausweisen |
| Fehlgeschlagen | Ausführung mit Fehler beendet |
| Teilweise | Teilwirkung möglich oder Skript nur teilweise ausgeführt |
| Verifikation offen | Ausführung erfolgreich gemeldet, Wirkung aber noch nicht ausreichend geprüft |
| Nicht ausgeführt | In dieser Umgebung nicht ausgeführt |

## 5. Historische Datenbankänderungen vor Einführung dieses Protokolls

Dieses Protokoll wird ab seiner Einführung als verbindliches Ausführungsjournal geführt. Es wird **nicht** behauptet, dass die nachfolgenden historischen Änderungen bereits vollständig in dieses Format überführt oder anhand beider Live-Datenbanken nachverifiziert wurden.

Bekannte historische Hinweise bleiben zunächst in `DB_CHANGELOG.md`. Dazu gehören unter anderem frühere DEV-Änderungen, die dokumentierten Migrationspakete 1–14, Migration 15 bzw. die Mannschaftsdeaktivierung sowie ACL-Prüfungen vom 02.11.2026. Für diese Vorgänge fehlen teilweise vollständige Original-SQL-Dateien, exakte Ausführungszeitpunkte oder getrennte Ausführungsnachweise je Umgebung. Sie werden erst dann als vollständige Einträge in dieses Protokoll übernommen, wenn die jeweiligen Belege aus GitHub, Supabase-Migrationshistorie oder den tatsächlichen Datenbankquellen geprüft wurden.

**Keine rückwirkende Rekonstruktion:** Fehlende SQL-Definitionen, Ausführungszeitpunkte, Freigaben oder Prüfergebnisse dürfen nicht erfunden oder aus bloßen Statusformulierungen abgeleitet werden. Fehlende Belege sind ausdrücklich als fehlend zu kennzeichnen.

## 6. Neue Einträge

Für jede neue logische Änderung den folgenden Block kopieren. DEV und PROD erhalten jeweils einen eigenen Ausführungsdatensatz.

### DB-MIG-YYYY-NNN – Kurzbeschreibung

- **Ausführungsdatensatz:** DEV / PROD
- **Datum/Uhrzeit (mit Zeitzone):** 
- **Umgebung:** Supabase DEV / Supabase PROD
- **Ausführungsweg:** 
- **Anlass/Zweck:** 
- **Betroffene Objekte:** 
- **Freigabe:** 
- **Ausführender:** 
- **Status:** Geplant / Erfolgreich / Fehlgeschlagen / Teilweise / Verifikation offen / Nicht ausgeführt
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** 
- **Ergebnis / Fehlermeldung:** 
- **Verifikation (read-only Abfrage und Ergebnis):** 
- **Rollback/Wiederherstellung:** 
- **Gegenstück in der anderen Umgebung:** 
- **GitHub-Datei und Commit-SHA (falls vorhanden):** 
- **Zusätzliche Hinweise / Nachweisgrenzen:** 

------------------------------------------------------------------------

**Release-Gate:** Vor jeder PROD-Datenbankänderung und vor jedem PROD-Release müssen die offenen DEV-/PROD-Ausführungsdatensätze, fehlenden Originaldefinitionen und nicht abgeschlossenen Verifikationen ausdrücklich geprüft werden. Dieses Dokument allein ist kein Beleg für den aktuellen Live-Datenbankzustand.


## 7. Historische PROD-Ausführungen – Migrationen 1–43 (rekonstruiert am 03.11.2026)

Ausführungsblock: DB-PROD-LEGACY-001 bis DB-PROD-LEGACY-043. Die 43 Datensätze sind einzeln im Inventar docs/database/archive/PROD_Migrationen_01-43/MIGRATIONEN_01-43_Inventar.md aufgeführt. Die vollständigen Original-SQL-Texte liegen im verlinkten Archivpaket.

Gemeinsame historische Angaben:
- Umgebung: Supabase PROD – vom Nutzer ausdrücklich für alle 43 Migrationen bestätigt.
- Ausführungsweg: Supabase SQL Editor; die SQL-Anfragen wurden im damaligen Chat zur direkten Ausführung bereitgestellt. Eine separate Werkzeugbestätigung je Migration liegt nicht vor.
- Ausführungszeitpunkt: je Migration nicht einzeln belegt; nicht aus Dateizeitstempeln abgeleitet.
- Ausführender: Nutzer laut damaligem Gesprächsablauf; kein zusätzlicher unabhängiger Ausführungsbeleg.
- Freigabe: SQL wurde im damaligen Chat zur Ausführung bereitgestellt. Einzelne Freigabezeitpunkte werden mangels hier erneut vorliegender Chatbelege nicht ergänzt.
- Status: Für alle 43 Migrationen vom Nutzer als erfolgreich ausgeführt bestätigt.
- Verifikation: Für alle 43 Migrationen vom Nutzer als im damaligen Chat geprüft bestätigt. Die konkreten read-only Prüf-SQLs und Resultate sind nicht Bestandteil der bereitgestellten ZIP und wurden hier nicht unabhängig erneut eingesehen.
- Rollback/Wiederherstellung: Für die einzelnen historischen Ausführungen liegt hier kein dokumentierter Rollback-Nachweis vor.
- DEV-Gegenstück: Mit den vorliegenden Unterlagen nicht je Migration nachgewiesen; keine DEV-Ausführung aus dieser PROD-Bestätigung abgeleitet.
- SQL-Integrität: Alle 43 Originaldateien wurden bytegenau mit den Quelldateien aus der Nutzer-ZIP verglichen. SHA-256 je Datei steht im Inventar.

| Ausführungs-ID | Migration | Kurzbeschreibung | PROD-Ausführung | Verifikation |
|---|---:|---|---|---|
| DB-PROD-LEGACY-001 | 1 | Additive Vereins- und Rollenstruktur | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-002 | 2 | Rollen- und Kontext-Hilfsfunktionen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-003 | 3 | RLS-Leseregeln und Schutz des Superadmin-Kontexts | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-004 | 4 | Rollenhistorie und Schutz des letzten Admins | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-005 | 5 | Mannschaftsrollen verwalten | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-006 | 6 | Kontext auswählen, abrufen und zurücksetzen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-007 | 7 | Vereinsmitgliedschaften und Profilbearbeitung | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-008 | 8 | Storage-Bucket anlegen/konfigurieren | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-009 | 9 | Storage-Policies für Vereinsassets und Profilbilder | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-010 | 10 | Vereinsadmin-Kandidaten und Vereinsanlage | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-011 | 11 | Mannschaftsadmin-Kandidaten und Mannschaftsanlage | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-012 | 12 | Vereinsdetails und Vereinswappen bearbeiten | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-013 | 13 | Mannschaftsdetails und Mitgliederprofil bearbeiten | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-014 | 14 | Fehlende DEV-Funktionen nach PROD übernehmen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-015 | 15 | Mannschaftsdeaktivierung | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-016 | 16 | Vereinskontext-Berechtigung angleichen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-017 | 17 | Leserechte im ausgewählten Mannschaftskontext | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-018 | 18 | Super-Admin-Schreibrechte für Spieler | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-019 | 19 | Super-Admin-Rechte für Spielerpositionen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-020 | 20 | Super-Admin-Rechte für Positionen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-021 | 21 | Vereinsmitgliedschaften an den Kontext koppeln | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-022 | 22 | Super-Admin-Schreibrechte für Trainingsanwesenheit | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-023 | 23 | Super-Admin-Rechte für Spieltagsanwesenheit | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-024 | 24 | Super-Admin-Rechte für Spieltagskader | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-025 | 25 | Super-Admin-Rechte für Empfehlungsläufe | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-026 | 26 | Super-Admin-Rechte für empfohlene Spieler | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-027 | 27 | Super-Admin-Rechte für Traineranwesenheit am Spieltag | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-028 | 28 | Überzähligen Admin-Schutz-Trigger entfernen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-029 | 29 | Super Admin muss den passenden Teamkontext wählen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-030 | 30 | Trigger an den geprüften DEV-Stand angleichen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-031 | 31 | Fehlende Super-Admin-Regeln für Spieltage | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-032 | 32 | Fehlende Super-Admin-Regeln für Saisons | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-033 | 33 | Super-Admin-Regeln für training_players | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-034 | 34 | Super-Admin-Regeln für training_responses | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-035 | 35 | Fehlende Super-Admin-Regeln für training_series | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-036 | 36 | Fehlende Super-Admin-Regeln für training_trainers | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-037 | 37 | Super-Admin-Regeln für trainings | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-038 | 38 | Fehlende Leseregel für Vereins-/Super-Admins | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-039 | 39 | Spieler-Anlage und -Bearbeitung | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-040 | 40 | player_positions an DEV angleichen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-041 | 41 | Spieler-Mannschaft-Zuordnung beim Löschen prüfen | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-042 | 42 | Super Admin im passenden ausgewählten Kontext | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |
| DB-PROD-LEGACY-043 | 43 | REVOKE EXECUTE – Funktionsrechte einschränken | Erfolgreich – Nutzerbestätigung | Im damaligen Chat geprüft – Nutzerbestätigung; Einzelbeleg nicht im Archiv |

Archivdatei: docs/database/archive/PROD_Migrationen_01-43/PROD_Migrationen_01-43_Arbeitsstand.tar.xz  
Archiv-SHA-256: 1fa0aa346d925f130d03c51970e78f3b125003d13511580292f53b5604584138  
Inventar: docs/database/archive/PROD_Migrationen_01-43/MIGRATIONEN_01-43_Inventar.md

Nachweisgrenze: Diese historische Rekonstruktion dokumentiert die ausdrückliche Nutzerbestätigung und die Original-SQL-Texte. Sie ersetzt keine erneute Live-Prüfung der PROD-Datenbank und belegt keine aktuellen Objektdefinitionen. Die 43 SQL-Dateien dürfen nicht ohne gesonderte Prüfung und ausdrückliche Freigabe erneut ausgeführt werden.

### DB-DEV-007 – Gemeinsamer Abschluss der Mitglieder-/Trainer-Einladung

- **Supabase-Migrationsversion:** `20261103203047`
- **Migrationsname:** `r16_member_invitation_transaction_dev`
- **Ausführungsdatensatz:** DEV
- **Datum:** 03.11.2026
- **Uhrzeit:** Vom Ausführungswerkzeug nicht separat mit Zeitzone zurückgegeben. Die Migrationsversion enthält die Zeitkomponente `203047`; sie wird hier nicht als lokale Uhrzeit ausgegeben.
- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`
- **Ausführungsweg:** Verbundenes Supabase-Migrationswerkzeug (`apply_migration`)
- **Anlass/Zweck:** Transaktionaler Abschluss der Profil- und Mitgliedschaftszuordnung als Backend-Grundlage für die drei Einladungskontexte.
- **Betroffene Objekte:** Neue Funktion `public.admin_complete_member_invitation(uuid,text,uuid,text,uuid)`; Ausführungsrechte für `authenticated`; EXECUTE-Rechte für `PUBLIC` und `anon` entzogen.
- **Freigabe:** Ausdrückliche Nutzerfreigabe der korrigierten vollständigen SQL-Fassung am 03.11.2026.
- **Ausführender:** ChatGPT über das verbundene Supabase-Migrationswerkzeug, auf ausdrückliche Nutzerfreigabe.
- **Status:** Erfolgreich ausgeführt; Struktur- und Rechteverifikation erfolgreich. Funktionaler Praxistest noch offen.
- **Ergebnis:** Supabase-Migrationswerkzeug meldete `success: true`. Die DEV-Migrationshistorie enthält Version `20261103203047` mit dem Namen `r16_member_invitation_transaction_dev`.
- **Verifikation (read-only):**
  - `to_regprocedure(...)` bestätigt die Existenz der Funktion.
  - `pg_get_functiondef(...)` bestätigt die gespeicherte Funktionsdefinition.
  - `prosecdef = true` bestätigt `SECURITY DEFINER`.
  - `has_function_privilege`: EXECUTE für `authenticated = true`, `anon = false`, `PUBLIC = false`.
  - Die Migrationshistorie bestätigt die registrierte Migration.
  - Noch nicht getestet: reale Einladungsabläufe für Super Admin, Vereinsadmin und Mannschaftsadmin; Rollen- und Profiländerungen durch tatsächliche RPC-Aufrufe; Parallelitätstest. Diese Prüfungen erfolgen nach Anbindung der Edge Function.
- **Rollback/Wiederherstellung:** Neue Funktion; bei Bedarf nach Prüfung abhängiger Aufrufer: `DROP FUNCTION IF EXISTS public.admin_complete_member_invitation(uuid,text,uuid,text,uuid);`. Es wurden keine bestehenden Tabellen, Daten, Trigger oder Policies verändert.
- **Gegenstück in PROD:** Nicht ausgeführt; PROD unverändert.
- **GitHub-Datei:** `DB_MIGRATION_LOG.md` auf `develop`; Dokumentations-Commit: `cdda7a90e99eb8984e6d16c5a660d080390694f1`.
- **Nachweisgrenze:** Die Funktion legt keine Auth-Benutzer an und versendet keine Einladungs-E-Mails. Sie wird erst durch die nachfolgende Edge-Function-Anbindung verwendet. Bestehende `team_members.admin_label`-Werte wurden nicht verändert.

**Vollständiges SQL der ausgeführten Migration (Funktionsdefinition aus der live gespeicherten Definition sowie die ausgeführten Rechteanweisungen):**

```sql
CREATE OR REPLACE FUNCTION public.admin_complete_member_invitation(p_user_id uuid, p_display_name text, p_club_id uuid, p_invited_role text, p_team_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
DECLARE
    v_email text;
    v_existing_club_id uuid;
    v_team_club_id uuid;
    v_actor_can_manage_club boolean;
    v_actor_can_manage_team boolean := false;
    v_profile_name_before text;
    v_profile_name_after text;
    v_profile_name_updated boolean;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Anmeldung erforderlich'
            USING errcode = '42501';
    END IF;

    IF p_user_id IS NULL OR p_club_id IS NULL THEN
        RAISE EXCEPTION 'Benutzer und Verein müssen angegeben werden'
            USING errcode = '22023';
    END IF;

    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Du kannst dich nicht selbst einladen'
            USING errcode = '42501';
    END IF;

    IF nullif(btrim(p_display_name), '') IS NULL
       OR length(btrim(p_display_name)) > 120 THEN
        RAISE EXCEPTION 'Der persönliche Name fehlt oder ist zu lang'
            USING errcode = '22023';
    END IF;

    IF p_invited_role IS NULL
       OR p_invited_role NOT IN (
           'member', 'club_admin', 'team_admin', 'trainer'
       ) THEN
        RAISE EXCEPTION 'Ungültige Einladungsrolle'
            USING errcode = '22023';
    END IF;

    -- Zielbenutzer sperren: verhindert parallele Zuordnungsprüfungen.
    SELECT u.email
    INTO v_email
    FROM auth.users u
    WHERE u.id = p_user_id
    FOR UPDATE;

    IF NOT FOUND OR nullif(btrim(v_email), '') IS NULL THEN
        RAISE EXCEPTION 'Auth-Benutzer nicht gefunden'
            USING errcode = '22023';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.global_user_roles gur
        WHERE gur.user_id = p_user_id
          AND gur.role = 'super_admin'
    ) THEN
        RAISE EXCEPTION 'Super Admins können nicht als Vereins- oder Mannschaftsmitglieder zugeordnet werden'
            USING errcode = '23514';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.clubs c
        WHERE c.id = p_club_id
    ) THEN
        RAISE EXCEPTION 'Verein nicht gefunden'
            USING errcode = '22023';
    END IF;

    IF p_invited_role IN ('team_admin', 'trainer') THEN
        IF p_team_id IS NULL THEN
            RAISE EXCEPTION 'Für eine Mannschaftsrolle muss eine Mannschaft ausgewählt werden'
                USING errcode = '22023';
        END IF;

        SELECT t.club_id
        INTO v_team_club_id
        FROM public.teams t
        WHERE t.id = p_team_id
          AND t.active = true;

        IF NOT FOUND OR v_team_club_id IS DISTINCT FROM p_club_id THEN
            RAISE EXCEPTION 'Die ausgewählte Mannschaft gehört nicht zum Verein oder ist nicht aktiv'
                USING errcode = '23514';
        END IF;
    ELSE
        IF p_team_id IS NOT NULL THEN
            RAISE EXCEPTION 'Für eine reine Vereinsrolle darf keine Mannschaft angegeben werden'
                USING errcode = '22023';
        END IF;
    END IF;

    -- Berechtigungen des Einladenden.
    v_actor_can_manage_club :=
        public.can_manage_club_context(p_club_id);

    IF p_team_id IS NOT NULL THEN
        v_actor_can_manage_team :=
            public.is_team_admin(p_team_id);
    END IF;

    IF NOT v_actor_can_manage_club
       AND NOT (
           v_actor_can_manage_team
           AND p_invited_role IN ('team_admin', 'trainer')
       ) THEN
        RAISE EXCEPTION 'Keine Berechtigung für diese Einladung oder kein passender Vereins-/Mannschaftskontext'
            USING errcode = '42501';
    END IF;

    -- Bestehende Vereinsmitgliedschaft prüfen.
    SELECT cm.club_id
    INTO v_existing_club_id
    FROM public.club_members cm
    WHERE cm.user_id = p_user_id;

    IF FOUND AND v_existing_club_id IS DISTINCT FROM p_club_id THEN
        RAISE EXCEPTION 'Benutzer ist bereits einem anderen Verein zugeordnet'
            USING errcode = '23514';
    END IF;

    -- Mehrfachzuordnungen verhindern.
    IF p_team_id IS NOT NULL AND (
        EXISTS (
            SELECT 1 FROM public.team_members tm
            WHERE tm.user_id = p_user_id
              AND tm.team_id <> p_team_id
        )
        OR EXISTS (
            SELECT 1 FROM public.team_member_roles r
            WHERE r.user_id = p_user_id
              AND r.team_id <> p_team_id
        )
    ) THEN
        RAISE EXCEPTION 'Benutzer gehört bereits einer anderen Mannschaft an'
            USING errcode = '23514';
    END IF;

    -- Vorhandenes Profil ebenfalls sperren.
    SELECT p.display_name
    INTO v_profile_name_before
    FROM public.profiles p
    WHERE p.id = p_user_id
    FOR UPDATE;

    -- Persönlichen Namen nur bei leerem Profil oder E-Mail-Fallback setzen.
    INSERT INTO public.profiles AS existing_profile (
        id, display_name
    )
    VALUES (
        p_user_id, btrim(p_display_name)
    )
    ON CONFLICT (id) DO UPDATE
    SET display_name = CASE
        WHEN nullif(btrim(existing_profile.display_name), '') IS NULL
          OR lower(btrim(existing_profile.display_name)) = lower(btrim(v_email))
        THEN EXCLUDED.display_name
        ELSE existing_profile.display_name
    END
    RETURNING display_name INTO v_profile_name_after;

    v_profile_name_updated :=
        v_profile_name_before IS DISTINCT FROM v_profile_name_after;

    -- Vereinsmitgliedschaft sicherstellen.
    INSERT INTO public.club_members (user_id, club_id)
    VALUES (p_user_id, p_club_id)
    ON CONFLICT (user_id) DO NOTHING;

    -- Vereinsadmin-Rolle ergänzen.
    IF p_invited_role = 'club_admin' THEN
        INSERT INTO public.club_member_roles (user_id, role)
        VALUES (p_user_id, 'club_admin')
        ON CONFLICT (user_id, role) DO NOTHING;
    END IF;

    -- Mannschaftsrolle ergänzen.
    IF p_invited_role IN ('team_admin', 'trainer') THEN

        INSERT INTO public.team_members AS existing_member (
            team_id, user_id, role
        )
        VALUES (
            p_team_id,
            p_user_id,
            CASE WHEN p_invited_role = 'team_admin'
                THEN 'admin' ELSE 'trainer' END
        )
        ON CONFLICT (team_id, user_id)
        DO UPDATE SET role = CASE
            WHEN existing_member.role = 'admin'
              OR EXCLUDED.role = 'admin'
            THEN 'admin'
            ELSE 'trainer'
        END;

        INSERT INTO public.team_member_roles (
            team_id, user_id, role
        )
        VALUES (
            p_team_id,
            p_user_id,
            CASE WHEN p_invited_role = 'team_admin'
                THEN 'admin' ELSE 'trainer' END
        )
        ON CONFLICT (team_id, user_id, role) DO NOTHING;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'role', p_invited_role,
        'club_id', p_club_id,
        'team_id', p_team_id,
        'profile_name_updated', v_profile_name_updated
    );
END;
$function$
;

REVOKE ALL ON FUNCTION
    public.admin_complete_member_invitation(uuid, text, uuid, text, uuid)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION
    public.admin_complete_member_invitation(uuid, text, uuid, text, uuid)
TO authenticated;
```



------------------------------------------------------------------------

### DB-MIG-2026-002 – Vereinsmitglieder inklusive Profilfeldern auslesen

- **Migrations-ID:** DB-MIG-2026-002
- **Ausführungsdatensatz:** DEV (ausgeführt)
- **Datum:** 04.11.2026. **Supabase-Migrationsversion/Zeitstempel:** `20261104113632` (das Ausführungsergebnis lieferte keinen gesonderten Zeitzonen-Zeitstempel).
- **Umgebung:** Supabase DEV `pzazqvvoruqnqhcorbwx`
- **Ausführungsweg:** Supabase-Migrationswerkzeug über die verbundene Supabase-Aktion.
- **Anlass/Zweck:** Die aktuelle `get_club_members_v2(uuid)` liefert keine Profilfelder. Der Superadmin-Mitgliederbereich zeigt deshalb E-Mail-Adressen statt persönlicher Namen. Der Bearbeitungsdialog liest `profiles` direkt; die bestehende SELECT-Policy erlaubt diesen Zugriff im ausgewählten Vereinskontext nicht. Die Frontend-Abfrage ignoriert den Lesefehler und das Namensfeld bleibt leer.
- **Betroffene Objekte:** Neue read-only RPC `public.get_club_members_v3(uuid)`; lesender Zugriff auf `public.club_members`, `auth.users`, `public.profiles`, `public.club_member_roles`, `public.teams`, `public.team_member_roles` und `public.team_members`.
- **Freigabe:** Ausdrückliche Nutzerfreigabe im Chat am 04.11.2026: „SQL in Supabase DEV ausführen“.
- **Ausführender:** Supabase-Migrationswerkzeug, ausgelöst durch den Assistenten nach ausdrücklicher Nutzerfreigabe.
- **Status:** Erfolgreich ausgeführt; strukturelle und Berechtigungsverifikation erfolgreich. Superadmin-UI-Praxistest für Mitgliederliste und Bearbeitungsdialog am 04.11.2026 bestanden; Vereinsadmin- und Kontext-Negativtests noch offen.
- **Tatsächlich ausgeführtes SQL (identisch mit der versionierten Quelldatei):**

```sql
CREATE FUNCTION public.get_club_members_v3(p_club_id uuid)
RETURNS TABLE (
    user_id uuid,
    email text,
    display_name text,
    avatar_url text,
    is_club_admin boolean,
    teams jsonb
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
BEGIN
    IF auth.uid() IS NULL
       OR NOT public.can_manage_club_context(p_club_id) THEN
        RAISE EXCEPTION 'Nicht berechtigt oder kein ausgewählter Vereinskontext'
            USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT
        cm.user_id,
        au.email::text,
        pr.display_name,
        pr.avatar_url,
        EXISTS (
            SELECT 1
            FROM public.club_member_roles AS cmr
            WHERE cmr.user_id = cm.user_id
              AND cmr.role = 'club_admin'
        ) AS is_club_admin,
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'team_id', team_rows.team_id,
                        'team_name', team_rows.team_name,
                        'roles', team_rows.roles
                    )
                    ORDER BY lower(team_rows.team_name)
                )
                FROM (
                    SELECT
                        t.id AS team_id,
                        t.name AS team_name,
                        COALESCE(
                            (
                                SELECT array_agg(
                                    DISTINCT role_union.role
                                    ORDER BY role_union.role
                                )
                                FROM (
                                    SELECT tmr.role
                                    FROM public.team_member_roles AS tmr
                                    WHERE tmr.team_id = t.id
                                      AND tmr.user_id = cm.user_id

                                    UNION

                                    SELECT tm.role
                                    FROM public.team_members AS tm
                                    WHERE tm.team_id = t.id
                                      AND tm.user_id = cm.user_id
                                ) AS role_union
                            ),
                            ARRAY[]::text[]
                        ) AS roles
                    FROM public.teams AS t
                    WHERE t.club_id = p_club_id
                      AND (
                          EXISTS (
                              SELECT 1
                              FROM public.team_member_roles AS tmr
                              WHERE tmr.team_id = t.id
                                AND tmr.user_id = cm.user_id
                          )
                          OR EXISTS (
                              SELECT 1
                              FROM public.team_members AS tm
                              WHERE tm.team_id = t.id
                                AND tm.user_id = cm.user_id
                          )
                      )
                ) AS team_rows
            ),
            '[]'::jsonb
        ) AS teams
    FROM public.club_members AS cm
    JOIN auth.users AS au
      ON au.id = cm.user_id
    LEFT JOIN public.profiles AS pr
      ON pr.id = cm.user_id
    WHERE cm.club_id = p_club_id
    ORDER BY
        lower(COALESCE(NULLIF(btrim(pr.display_name), ''), au.email, '')),
        cm.user_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_club_members_v3(uuid)
    FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_club_members_v3(uuid)
    TO authenticated;
```

- **Ergebnis / Fehlermeldung:** Supabase-Migrationswerkzeug meldete `success: true`. Die DEV-Migrationshistorie enthält Version `20261104113632` mit dem Namen `club_member_profiles_read_v3_dev`.
- **Verifikation (read-only, nach Ausführung):**
  1. `to_regprocedure('public.get_club_members_v3(uuid)')` bestätigt die Existenz.
  2. `pg_get_functiondef(...)` bestätigt den gespeicherten Funktionskörper.
  3. Metadaten: Owner `postgres`, `SECURITY DEFINER = true`, Volatilität `STABLE`, fester `search_path = pg_catalog, public, auth`.
  4. EXECUTE-Prüfung: `authenticated = true`, `anon = false`, `PUBLIC = false`; ACL zeigt EXECUTE für `authenticated`, `postgres` und `service_role`.
  5. Supabase-Migrationshistorie: Version `20261104113632`, Name `club_member_profiles_read_v3_dev`.
  6. Die beiden bestehenden Policies `profiles_select` und `profiles_update` sind unverändert.
  7. Security Advisor: generische Warnung „Signed-In Users Can Execute SECURITY DEFINER Function“, Anzahl stieg von 37 auf 38. Die Warnung ist dokumentiert und gegen die explizite Kontextprüfung der RPC zu bewerten.
  8. **Manueller DEV-Praxistest mit Superadmin erfolgreich (04.11.2026):** Der persönliche Name wird in der Mitgliederliste statt der E-Mail angezeigt; beim Öffnen von „Bearbeiten“ wird derselbe gespeicherte Name korrekt in das Namensfeld übernommen. Nutzerbestätigung im Chat.
  9. Noch offen: Vereinsadmin-Test im eigenen Verein; negative Tests ohne Anmeldung, ohne Kontext und mit fremdem Verein; Profilbildanzeige; Speichern/erneutes Laden von Namens-/Profiländerungen und Regression der Rollenanzeige.
- **Rollback/Wiederherstellung:** Nach Rücknahme aller Frontend-Aufrufe und Prüfung sämtlicher Abhängigkeiten: `DROP FUNCTION IF EXISTS public.get_club_members_v3(uuid);`. Die Migration hat keine Tabellen, Datensätze oder bestehenden Policies verändert.
- **Gegenstück in PROD:** Nicht ausgeführt; keine PROD-Änderung vorgesehen.
- **GitHub-Datei:** `supabase/migrations/20261104113632_club_member_profiles_read_v3_dev.sql` (identischer SQL-Text); zusammen mit diesem Ausführungsnachtrag committed. Der Commit ist in der Repository-Historie nachvollziehbar.
- **Zusätzliche Hinweise / Nachweisgrenzen:** `get_club_members_v2` bleibt unverändert. Die bestehende RLS-Policy auf `profiles` wird nicht erweitert. Die neue RPC ist `SECURITY DEFINER`, prüft aber vor jeder Rückgabe `auth.uid()` und `can_manage_club_context(p_club_id)`; EXECUTE wird nur an `authenticated` vergeben. Die generische Security-Advisor-Warnung wird bewusst nicht pauschal entfernt; Kontextprüfung, fester Suchpfad und ACL sind Teil der Sicherheitsbegründung. Es wurden keine Nutzerdaten verändert. Frontend-Anbindung in Commit `cb0a5b943e3bb367a9f7c5bfafd693803ec39ea0`; Deploy DEV #41822962197 erfolgreich. Statische Syntaxprüfung der drei geänderten Blöcke bestanden; manuelle UI- und Kontexttests offen.


## DB-MIG-2026-003 – Ein-Mannschaft-Regel mit zusätzlichen Verwaltungsrollen

- **Migrations-ID:** DB-MIG-2026-003 (fachlicher Vorgang DB-DEV-009)
- **Supabase-Migrationsversion:** `20261104143331`
- **Migrationsname:** `db_dev_009_single_team_membership_guard`
- **Ausführungsdatensatz:** DEV
- **Datum:** 04.11.2026
- **Uhrzeit:** Das Supabase-Ausführungswerkzeug gab keinen separaten lokalen Zeitstempel zurück. Die von Supabase registrierte Versions-ID lautet `20261104143331`; deren Zeitkomponente wird hier nicht als lokale Uhrzeit interpretiert.
- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`
- **Ausführungsweg:** Verbundenes Supabase-Migrationswerkzeug (`apply_migration`)
- **Anlass/Zweck:** Zentrale Datenbankabsicherung der fachlich freigegebenen Ein-Mannschaft-Regel; Superadmin und Vereinsadmin bleiben zusätzliche, von der tatsächlichen Mannschaftszuordnung getrennte Rollen.
- **Freigabe:** Ausdrückliche Nutzerfreigabe zur Ausführung von DB-DEV-009 ausschließlich in Supabase DEV am 04.11.2026. Keine Freigabe für PROD.
- **Ausführender:** ChatGPT über das verbundene Supabase-Migrationswerkzeug, auf ausdrückliche Nutzerfreigabe.
- **Status:** Erfolgreich ausgeführt; Struktur-, Rechte- und Read-only-Bestandsprüfung erfolgreich. Funktionale Positiv-/Negativtests über die App stehen noch aus.
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** `supabase/migrations/20261104143331_db_dev_009_single_team_membership_guard.sql`; GitHub-Blob-SHA `b73af4ef0e45ce0d475f0498eb4bf8db31d0a09a`. Die Datei enthält den vollständigen an Supabase übergebenen SQL-Text.
- **Betroffene Objekte:**
  - Neue Triggerfunktion `public.enforce_single_team_membership()`.
  - Neue BEFORE-Trigger `team_members_single_team_guard` auf `public.team_members` und `team_member_roles_single_team_guard` auf `public.team_member_roles`.
  - Neuer Index `idx_team_member_roles_user` auf `public.team_member_roles(user_id)`.
  - Angepasste Funktionen `admin_add_team_role(uuid,uuid,text)`, `admin_create_team(uuid,text,integer,text,text,text,uuid)`, `admin_list_team_admin_candidates(uuid)` und `admin_complete_member_invitation(uuid,text,uuid,text,uuid)`.
- **Ergebnis:** Supabase meldete `success: true`. Die Migrationshistorie enthält Version `20261104143331` mit dem Namen `db_dev_009_single_team_membership_guard`.
- **Verifikation (read-only):**
  1. Beide neuen Trigger sind vorhanden und aktiviert; ihre Definition lautet BEFORE INSERT OR UPDATE OF `user_id, team_id`. Die bestehenden Audit-Trigger und der Schutz der letzten Mannschaftsadmin-Rolle sind weiterhin vorhanden.
  2. Kein Trigger auf `global_user_roles` wurde angelegt. Es existiert kein Gegentrigger, der eine spätere Superadmin-Hochstufung eines Mannschaftsmitglieds verhindert.
  3. `enforce_single_team_membership()` gehört `postgres`, ist SECURITY DEFINER und hat den festen Suchpfad `pg_catalog, public, auth`. EXECUTE für `anon` und `authenticated` ist false. `service_role` besitzt weiterhin EXECUTE; die Funktion ist triggerorientiert und die Anwendung ruft sie nicht als RPC auf.
  4. Die vier angepassten RPCs gehören `postgres`, sind SECURITY DEFINER, verwenden den festen Suchpfad und sind für `authenticated` ausführbar, nicht für `anon`. Die bestehenden EXECUTE-Rechte von `service_role` bleiben erhalten.
  5. Index `idx_team_member_roles_user` ist vorhanden.
  6. Benutzer mit Mehrfachzuordnung über die Vereinigungsmenge von `team_members` und `team_member_roles`: **0**.
  7. Die Einladungs-RPC enthält keine Sperre mehr gegen Superadmins als Zielpersonen. `admin_create_team` lässt einen Superadmin als Mannschaftsadmin-Ziel zu, sofern er Vereinsmitglied und noch keiner Mannschaft zugeordnet ist. Die Kandidatenliste schließt Superadmins nicht allein wegen ihrer globalen Rolle aus, sondern filtert tatsächliche Mannschaftszuordnungen.
  8. Die Migration enthält keine INSERT-/UPDATE-/DELETE-Anweisungen für bestehende Mitgliedschafts- oder Rollendaten und keine Änderungen an RLS-Policies. Die bestehenden Policies wurden read-only nach der Migration ausgelesen.
  9. Read-only Tabellenbestand nach Migration: `team_members` 3 Zeilen, `team_member_roles` 4, `club_members` 4, `club_member_roles` 1, `global_user_roles` 1. Diese Werte sind eine Momentaufnahme nach Ausführung, kein separater Vorher-/Nachher-Datenvergleich.
- **Security-/Performance-Advisor nach Ausführung:** Security: 3 Lint-Gruppen (INFO 1, WARN 2), darunter 38 SECURITY DEFINER-Hinweise, ein RLS-ohne-Policy-Hinweis für die absichtlich RPC-geschützten Kontexttabellen und ein Hinweis zur Passwort-Leak-Protection. Performance: 4 Lint-Gruppen (INFO 2, WARN 2), darunter 65 Mehrfach-Policies und 67 Auth-RLS-Initplan-Hinweise; der neu angelegte Index wird unmittelbar nach Erstellung noch als ungenutzt gemeldet. Diese Advisor-Hinweise sind nicht automatisch durch DB-DEV-009 verursacht und müssen als gesonderte Sicherheits-/Performance-Aufgaben bewertet werden.
- **Rollback/Wiederherstellung:** Ein Zurückbau müsste die beiden neuen Trigger entfernen, die ursprünglichen vier Funktionsdefinitionen aus dem dokumentierten Vorher-Stand wiederherstellen und den neuen Index sowie die Triggerfunktion erst nach Abhängigkeitsprüfung entfernen. Die vorherigen Live-Funktionsdefinitionen sind im Arbeitsverlauf read-only ausgelesen worden; ein automatischer Rollback wurde nicht ausgeführt. Vor einem Rollback ist eine neue, geprüfte Rücknahmemigration erforderlich.
- **Gegenstück in PROD:** Nicht ausgeführt, nicht freigegeben. PROD bleibt unverändert.
- **Zusätzliche Hinweise / Nachweisgrenzen:** Die Migration wurde ausschließlich in DEV ausgeführt. Ein echter App-Aufruf zum Hinzufügen/Entfernen von Rollen und ein Negativtest für eine zweite Mannschaftszuordnung wurden noch nicht ausgeführt. Ebenso sind die aktualisierten Edge Functions noch nicht deployed.


### DB-MIG-2026-004 – Gemeinsamer Abschluss der Mitglieder-/Trainer-Einladung (PROD)

- **Ausführungsdatensatz:** PROD
- **Supabase-Migrationsversion:** `20261105091350`
- **Migrationsname:** `r16_member_invitation_transaction_prod`
- **Datum/Uhrzeit (Europe/Berlin):** 05.11.2026, 10:13:50 (aus Supabase-Migrationsversion 09:13:50 UTC; Berlin = UTC+1).
- **Umgebung:** Supabase PROD – Projekt `qdugtpzgefpswnnqbusd`
- **Ausführungsweg:** Verbundenes Supabase-Migrationswerkzeug (`apply_migration`)
- **Anlass/Zweck:** Transaktionaler Abschluss der Profil- und Mitgliedschaftszuordnung als Backend-Grundlage für die Einladung in Vereins- und Mannschaftskontexten.
- **Betroffene Objekte:** Funktion `public.admin_complete_member_invitation(uuid,text,uuid,text,uuid)`; EXECUTE-Rechte für `authenticated`; EXECUTE für `PUBLIC` und `anon` entzogen.
- **Freigabe:** Ausdrückliche Nutzerfreigabe am 05.11.2026 für DB-DEV-007 auf PROD.
- **Ausführender:** ChatGPT über das verbundene Supabase-Migrationswerkzeug, auf ausdrückliche Nutzerfreigabe.
- **Status:** Erfolgreich ausgeführt; Struktur- und Rechteverifikation erfolgreich. Funktionaler End-to-End-Test noch offen.
- **Tatsächlich ausgeführtes SQL:** `supabase/migrations/20261105091350_r16_member_invitation_transaction_prod.sql` (vollständiger SQL-Text, identisch mit dem lokal bereitgestellten Skript DB-DEV-007).
- **Ergebnis:** Supabase meldete `success: true`. Die PROD-Migrationshistorie enthält Version `20261105091350` mit dem Namen `r16_member_invitation_transaction_prod`.
- **Verifikation (read-only):**
  - Funktion `admin_complete_member_invitation(uuid,text,uuid,text,uuid)` ist vorhanden.
  - `prosecdef = true`; fester `search_path = pg_catalog, public, auth`.
  - ACL: `postgres`, `service_role` und `authenticated` besitzen EXECUTE; `anon` besitzt kein EXECUTE. Kein PUBLIC-EXECUTE-Eintrag vorhanden.
  - `has_function_privilege`: `authenticated = true`, `anon = false`.
  - Die erwartete Prüfung auf eine abweichende Mannschaftszuordnung ist in der gespeicherten Funktionsdefinition vorhanden.
  - Migrationshistorie bestätigt den Eintrag.
- **Rollback/Wiederherstellung:** Neue Funktion. Nach Prüfung abhängiger Aufrufer wäre ein Rückbau über `DROP FUNCTION IF EXISTS public.admin_complete_member_invitation(uuid,text,uuid,text,uuid);` möglich. Vor einem Rollback ist sicherzustellen, dass keine Edge Function oder sonstiger Aufrufer davon abhängt. Kein Rollback ausgeführt.
- **Gegenstück in DEV:** DEV-Migration `20261103203047` / `r16_member_invitation_transaction_dev` ist vorhanden; separate DEV-Funktion und Praxistest bleiben zu beachten.
- **GitHub-Datei und Commit-SHA:** `supabase/migrations/20261105091350_r16_member_invitation_transaction_prod.sql` – Commit `4a4f456246525db0bbaf1489511fc95e503d803e`.
- **Zusätzliche Hinweise / Nachweisgrenzen:** Die Migration verändert keine bestehenden Mitgliedschafts- oder Rollendatensätze und keine RLS-Policies. Sie stellt die Backend-Funktion bereit, versendet aber selbst keine Einladungs-E-Mails und legt keine Auth-Benutzer an. Die spätere Einbindung der Edge Functions und der Ende-zu-Ende-Einladungstest sind nicht Bestandteil dieses Ausführungsschritts. **Historischer Stand zum Zeitpunkt dieser Migration:** DB-DEV-008 und DB-DEV-009 waren noch nicht in PROD ausgeführt. Beide wurden am 05.11.2026 nach separater Prüfung und Freigabe nachgezogen; siehe die folgenden Ausführungsdatensätze DB-MIG-2026-005 und DB-MIG-2026-006.


## DB-MIG-2026-005 – Vereinsmitglieder-RPC mit Profilnamen und Profilbildern (PROD)

- **Migrations-ID:** DB-MIG-2026-005 (fachlicher Vorgang DB-DEV-008)
- **Ausführungsdatensatz:** PROD
- **Datum:** 05.11.2026
- **Uhrzeit:** Vom Ausführungswerkzeug nicht separat und verlässlich zurückgegeben; keine Uhrzeit aus Dateinamen oder Chat-Zeitstempeln abgeleitet.
- **Umgebung:** Supabase PROD – Projekt `qdugtpzgefpswnnqbusd`
- **Ausführungsweg:** Verbundenes Supabase-Migrationswerkzeug (`apply_migration`)
- **Anlass/Zweck:** Vereinsmitgliederliste um Profilnamen und Profilbilder ergänzen, ohne die bestehende RPC `get_club_members_v2` oder die Profile-RLS-Policies zu verändern.
- **Betroffene Objekte:** Neue Funktion `public.get_club_members_v3(uuid)`; Rückgabe `user_id, email, display_name, avatar_url, is_club_admin, teams`.
- **Freigabe:** Ausdrückliche Nutzerfreigabe am 05.11.2026 für DB-DEV-008 auf PROD.
- **Ausführender:** ChatGPT über das verbundene Supabase-Migrationswerkzeug, auf ausdrückliche Nutzerfreigabe.
- **Status:** Erfolgreich ausgeführt; Struktur-, Funktionsmetadaten- und Rechteverifikation erfolgreich. Authentifizierte Positiv-/Negativtests und Frontend-Praxistest bleiben offen.
- **Supabase-Migrationsversion:** Vom Ausführungswerkzeug nicht zuverlässig zurückgegeben; deshalb hier bewusst nicht angegeben.
- **Tatsächlich ausgeführtes SQL bzw. Backup:** Vollständiges SQL-Backup lokal bereitgestellt als `DB-DEV-008_get_club_members_v3.sql`; SHA-256 `e0be1e9b0b04bb064ba921cc43efb6a45541d4b4c6ea5c135ea20eaf6a2a6b00`. Ein GitHub-Migrationsdateipfad wird erst eingetragen, wenn der tatsächlich ausgeführte PROD-SQL-Text bytegenau in `develop` versioniert wurde.
- **Ergebnis:** Supabase-Migrationswerkzeug meldete `success: true`.
- **Verifikation (read-only):**
  1. `to_regprocedure('public.get_club_members_v3(uuid)')` bestätigt die Existenz.
  2. Rückgabetyp enthält die sechs vereinbarten Felder.
  3. Funktion ist `SECURITY DEFINER`, `STABLE`, Owner `postgres`, fester `search_path = pg_catalog, public, auth`.
  4. EXECUTE für `authenticated` vorhanden; `anon` und `PUBLIC` nicht berechtigt; ACL enthält außerdem `postgres` und `service_role`.
  5. Bestehende Funktion `get_club_members_v2` bleibt erhalten.
  6. Keine Tabellen-, Mitgliedschafts- oder Profildatenänderung und keine RLS-Policy-Änderung Bestandteil der Migration.
- **Rollback/Wiederherstellung:** Nach Prüfung aller Aufrufer und Abhängigkeiten könnte die neue Funktion mit `DROP FUNCTION IF EXISTS public.get_club_members_v3(uuid);` entfernt werden. Kein Rollback ausgeführt.
- **Gegenstück in DEV:** DEV-Funktion `get_club_members_v3(uuid)` aus DB-DEV-008 ist vorhanden; der Superadmin-Frontendtest in DEV war bereits erfolgreich. Weitere Vereinsadmin-/Negativ-/Profilbildtests bleiben offen.
- **Zusätzliche Hinweise / Nachweisgrenzen:** Die Funktionsdefinition wurde read-only geprüft. Ein tatsächlicher Aufruf mit authentifizierten Benutzern unterschiedlicher Berechtigungen sowie ein vollständiger UI-Test sind noch nicht erfolgt.

## DB-MIG-2026-006 – Ein-Mannschaft-Absicherung und Rollen-RPCs (PROD)

- **Migrations-ID:** DB-MIG-2026-006 (fachlicher Vorgang DB-DEV-009)
- **Ausführungsdatensatz:** PROD
- **Supabase-Migrationsversion:** `20261105093559`
- **Migrationsname:** `db_dev_009_single_team_membership_guard_prod`
- **Datum/Uhrzeit (Europe/Berlin):** 05.11.2026, 10:35:59 (Migrationsversion 09:35:59 UTC; Berlin = UTC+1).
- **Umgebung:** Supabase PROD – Projekt `qdugtpzgefpswnnqbusd`
- **Ausführungsweg:** Verbundenes Supabase-Migrationswerkzeug (`apply_migration`)
- **Anlass/Zweck:** Serverseitige Durchsetzung der Ein-Mannschaft-Regel in beiden Zuordnungstabellen und Angleichung der Rollen-RPCs an das freigegebene Rollenmodell. Superadmins dürfen zusätzlich Vereins- oder Mannschaftsrollen besitzen; die globale Superadmin-Rolle bleibt erhalten.
- **Freigabe:** Ausdrückliche Nutzerfreigabe am 05.11.2026 nach Vorlage der vollständigen PROD-Release-SQL und der geprüften Bestands-/Definitionsunterschiede.
- **Ausführender:** ChatGPT über das verbundene Supabase-Migrationswerkzeug, auf ausdrückliche Nutzerfreigabe.
- **Status:** Erfolgreich ausgeführt; Struktur-, Funktions-, Rechte-, Index-, Trigger- und Bestandsverifikation erfolgreich. Funktionale Positivtests der Rollen-RPCs und vollständiger Einladungstest stehen noch aus.
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** PROD-Release-Backup `DB-DEV-009_PROD_final_single_team_membership_guard.sql`, 605 Zeilen / 22.897 Bytes, SHA-256 `6bcba806a3c37aff54a67ff59b5337ea8117d9e86ee90eeaee2e3e87e8602fbd`. Das an Supabase übergebene SQL wurde aus dieser geprüften Datei rekonstruiert; die SQL-Anweisungen und ihre Semantik entsprechen dem Backup, Kommentare wurden beim Aufruf nicht vollständig mitübergeben. Die Datei enthält im Kopf noch einen historischen Vorbereitungsvermerk („NICHT ausgeführt“); dieser Vermerk ist kein Statusnachweis und muss vor einer späteren GitHub-Versionierung korrigiert werden. Eine bytegenaue GitHub-Migrationsdatei wird erst nach dieser Korrektur angelegt.
- **Betroffene Objekte:**
  - Neue Triggerfunktion `public.enforce_single_team_membership()`.
  - Neue BEFORE-Trigger `team_members_single_team_guard` und `team_member_roles_single_team_guard` auf `public.team_members` bzw. `public.team_member_roles`.
  - Neuer Index `idx_team_member_roles_user` auf `public.team_member_roles(user_id)`.
  - Überarbeitete RPCs `admin_add_team_role`, `admin_create_team`, `admin_list_team_admin_candidates` und `admin_complete_member_invitation`.
- **Ergebnis:** Supabase meldete `success: true`; Migrationshistorie bestätigt Version `20261105093559`.
- **Verifikation (read-only):**
  1. Beide neuen Trigger sind vorhanden und aktiv; Definition jeweils BEFORE INSERT OR UPDATE OF `user_id, team_id`.
  2. Alle fünf Funktionen (Triggerfunktion plus vier RPCs) sind vorhanden, `SECURITY DEFINER` und besitzen den festen Suchpfad `pg_catalog, public, auth`.
  3. Die vier RPCs sind für `authenticated` ausführbar, nicht für `anon` oder `PUBLIC`; die Triggerfunktion ist nicht für `anon` oder `authenticated` ausführbar und bleibt triggerorientiert.
  4. Index `idx_team_member_roles_user` ist vorhanden.
  5. Bestehender Trigger `prevent_last_team_admin_removal` und Funktion `admin_remove_team_role` sind weiterhin vorhanden.
  6. Die bestehenden RLS-Policies auf `team_members` und `team_member_roles` blieben unangetastet; die geprüfte Policy-Anzahl beträgt zusammen fünf.
  7. Mehrfachzuordnungen über beide Mannschaftstabellen: **0 Benutzer**.
  8. Tabellenbestand nach Migration: `team_members` 5 Zeilen, `team_member_roles` 5 Zeilen.
- **Datenbilanz:** Die Migration führte keine Bereinigung oder Löschung bestehender Mitgliedschaftszeilen aus. Die geprüften Tabellenbestände nach Ausführung sind 5 bzw. 5 Zeilen. Ein eigenständiger Vorher-/Nachher-Datenexport wurde nicht erstellt.
- **Rollback/Wiederherstellung:** Kein automatischer Rollback. Ein Rückbau erfordert eine neue, geprüfte Rücknahmemigration, die die vorherigen vier PROD-Funktionsdefinitionen wiederherstellt und die beiden Trigger sowie den Index und die Triggerfunktion nach Abhängigkeitsprüfung entfernt. Bestehende Admin-Schutz- und Auditmechanismen müssen erhalten bleiben.
- **Gegenstück in DEV:** DEV-Migration `20261104143331` / `db_dev_009_single_team_membership_guard` vorhanden. PROD-Fassung enthält notwendige PROD-Legacy-Synchronisierung und wurde nicht blind aus DEV wiederholt.
- **Zusätzliche Hinweise / Nachweisgrenzen:** Die Migration ersetzt vier Funktionsdefinitionen und ergänzt Trigger/Index; sie ändert keine RLS-Policies. Die tatsächliche Einladung über die Edge Functions sowie positive Rollen- und UI-Tests sind noch offen. Die Einladungsstrecke bleibt bis zum Edge-Function-Deployment und den Praxistests deaktiviert.


## DB-MIG-2026-007 – E05 Schemafundament Trainingsereignisse und Sperren (DEV – geplant)

- **Migrations-ID:** DB-MIG-2026-007 (fachlicher Vorgang E05-SQL-001)
- **Ausführungsdatensatz:** DEV – geplant, nicht ausgeführt
- **Datum:** 08.11.2026 (Entwurfsdatum; kein Ausführungszeitpunkt)
- **Umgebung:** vorgesehen Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`
- **Ausführungsweg:** Noch nicht festgelegt; keine Ausführung
- **Anlass/Zweck:** Technisches Schemafundament für AP05.2/AP05.3: Trainingsereignisse, Sperren, Ausnahmen, Spielart-Konfiguration, vorzeitiger Sperrausgleich und Auditstrukturen.
- **Betroffene Objekte:** Neue Tabellen/Indizes/Constraints/RLS/SELECT-Grants gemäß versionierter SQL-Datei. Keine bestehenden Tabellen, Funktionen oder Policies sollen geändert werden.
- **Freigabe:** **Nicht erteilt.** Der Nutzer hat die Erstellung eines SQL-Entwurfs zur Prüfung/Freigabe beauftragt; dies ist keine Ausführungsfreigabe.
- **Ausführender:** Nicht zutreffend – nicht ausgeführt.
- **Status:** **Geplant / nicht ausgeführt**
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** Kein SQL ausgeführt. Geprüfter Entwurf: `supabase/migrations/20261108000100_e05_training_events_suspensions_foundation.sql`; Commit `b8837c36b4a42ae756c4cc8566dff0b3d6c05db8`.
- **Ergebnis / Fehlermeldung:** Nicht zutreffend.
- **Verifikation (read-only Abfrage und Ergebnis):** DEV-Bestand der relevanten Tabellen/Spalten sowie ausgewählte Rollen-/Kontextfunktionen und bestehende RLS-Policies wurden ausgelesen. Keine neuen Objekte vorhanden, da nicht ausgeführt. Vollständige Post-Migration-Verifikation steht aus.
- **Rollback/Wiederherstellung:** Vor Ausführung noch vollständig festzulegen. Keine Rücknahme erforderlich, da keine Änderung erfolgt.
- **Gegenstück in PROD:** Nicht ausgeführt; keine PROD-Freigabe.
- **GitHub-Datei und Commit-SHA:** SQL-Entwurf in develop, Commit `b8837c36b4a42ae756c4cc8566dff0b3d6c05db8`.
- **Zusätzliche Hinweise / Nachweisgrenzen:** Der Entwurf ist nur die erste Schemaetappe. Audit-Trigger/RPCs und die vollständige Sperren-/Empfehlungslogik fehlen noch. Er ist daher ausdrücklich kein vollständiges, ausführbares E05-Featurepaket und noch nicht zur Ausführung freigegeben.
