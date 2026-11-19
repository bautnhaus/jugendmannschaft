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


## DB-MIG-2026-007 – E05 Paket 9: Manuelle Sperren- und Kartenkorrektur (DEV)

- **Migrations-ID:** DB-MIG-2026-007 (E05 Paket 9)
- **Ausführungsdatensatz:** DEV
- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`
- **Datum:** 08.11.2026
- **Supabase-Migrationsversionen / Namen:**
  - `20261108212745` – `e05_package_09_manual_suspension_and_card_correction_v6`
  - `20261108213035` – `e05_package_09_fix_card_correction_player_lock`
  - `20261108213211` – `e05_package_09_fix_card_correction_authenticated_grant`
- **Ausführungsweg:** Verbundenes Supabase-Migrationswerkzeug (`apply_migration`), nach ausdrücklicher Nutzerfreigabe für Paket 9 in DEV.
- **Anlass/Zweck:** Manuelle Korrektur offener Sperren, Stornierung/Wiederherstellung gelber und roter Kartenereignisse, Erhalt gültiger manueller Zielzuordnungen und revisionssichere Audit-Snapshots.
- **Betroffene Objekte:** Spalten `training_behavior_event_audit.changed_by_snapshot`, `training_suspension_audit.changed_by_snapshot`, `training_suspensions.manual_target_locked`; Funktionen `e05_assert_suspension_correction_permission`, `e05_reconcile_suspensions_after_event_correction`, erweiterte `e05_assign_player_suspensions`, RPCs `correct_suspension` und `correct_training_behavior_event`; EXECUTE-Grants.
- **Freigabe:** Ausdrückliche Nutzerfreigabe am 08.11.2026 zur Umsetzung und Dokumentation ausschließlich in DEV.
- **Ausführender:** ChatGPT über das verbundene Supabase-Migrationswerkzeug, auf ausdrückliche Nutzerfreigabe.
- **Status:** Erfolgreich ausgeführt; DEV-Funktionstests und abschließende Read-only-Verifikation bestanden.
- **Tatsächlich ausgeführtes SQL / versionierte Dateien:**
  - `docs/E05_PAKET_09_MANUELLE_SPERREN_UND_KARTENKORREKTUR_2026-11-08.sql`
  - `docs/E05_PAKET_09_FIX_KARTENKORREKTUR_SPIELERLOCK_2026-11-08.sql`
  - `docs/E05_PAKET_09_FIX_KARTENKORREKTUR_EXECUTE_GRANT_2026-11-08.sql`
- **Ergebnis:** Alle drei Migrationen sind in `supabase_migrations.schema_migrations` registriert. Ein erster Ausführungsversuch der v6-Übermittlung schlug mit SQL-Syntaxfehler fehl, wurde nicht registriert und hinterließ keine Paket-9-Änderungen. Die vollständige erneute Übermittlung war erfolgreich. Während der DEV-Funktionstests wurden zwei Korrekturen erforderlich (Spielerzeilensperre: SELECT → PERFORM; Wiederherstellung des EXECUTE-Grants für authenticated). Beide Korrekturen wurden als eigene Migrationen erfolgreich eingespielt.
- **Verifikation (read-only):**
  1. Alle drei Migrationsversionen vorhanden.
  2. Die drei neuen Spalten sind vorhanden; `manual_target_locked` ist NOT NULL mit Default false.
  3. Beide Paket-9-RPCs sind SECURITY DEFINER mit festem `search_path = pg_catalog, public, auth`.
  4. EXECUTE: beide RPCs `authenticated = true`, `anon = false`, `service_role = false`, `PUBLIC = false`; interne Helfer sind für API-Rollen nicht ausführbar.
  5. RLS bleibt auf `training_behavior_events`, `training_behavior_event_audit`, `training_suspensions` und `training_suspension_audit` aktiviert.
  6. Bestehende append-only Audit-Trigger (UPDATE/DELETE/TRUNCATE-Schutz) sind weiterhin vorhanden.
  7. Korrigierte Spielerzeilensperre mittels `PERFORM p.id ... FOR UPDATE OF p` ist in der gespeicherten Funktionsdefinition vorhanden.
  8. Funktionstests: gelbe Karte stornieren/wiederherstellen und Sperrenstatus neu berechnen; rote Karte stornieren/wiederherstellen/erneut stornieren; manuelle Sperrenzuordnung; Schutz gültiger manueller Zuordnung bei automatischer Neuberechnung; Freigabe und Neuzuordnung nach Absage des Zielspieltags; unzulässiger Spieltyp; fremder Teamkontext; fehlende Authentifizierung; Schutz bereits abgeleisteter Sperren; Audit-Snapshots. Alle aufgeführten Tests bestanden.
  9. Alle Testfälle wurden in Transaktionen mit synthetischen Daten ausgeführt und zurückgerollt. Nachkontrolle: keine Test-Trainings, Test-Kartenereignisse, Test-Spieltagseinträge, Test-Sperren oder Test-Vereinseinstellungen verblieben.
- **Rollback/Wiederherstellung:** Paket-9-Schemaänderungen wurden nicht zurückgerollt. Sie sind Bestandteil des DEV-Entwicklungsstands. Die synthetischen Testdaten wurden zurückgerollt. Für ein Schema-Rollback wäre eine gesonderte, abhängigkeitssichere Rücknahmemigration erforderlich.
- **Gegenstück in PROD:** Nicht ausgeführt, nicht freigegeben. PROD bleibt unverändert.
- **Zusätzliche Hinweise / Nachweisgrenzen:** Keine vollständigen parallelen Last-/Race-Condition-Tests und kein Frontend-End-to-End-Test Bestandteil dieser Abnahme. Die ausführliche Testdokumentation liegt in `docs/E05_PAKET_09_ABNAHME_UND_AUSFUEHRUNG_2026-11-08.md`. Die DEV-first-Teststrategie ist in `docs/E05_TESTSTRATEGIE_UND_DEV_VORGEHEN_2026-11-08.md` festgehalten.



## DB-MIG-2026-008 – E05 Package 10: Trainingsdatumsbasierte Kartenchronologie und Sperrenzuordnung (DEV)

- **Migrations-ID:** DB-MIG-2026-008 (E05 Package 10)
- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`
- **Datum:** 11.11.2026
- **Supabase-Migrationsversion / Name:** `20261111161403` – `e05_package_10_training_date_suspensions`
- **Ausführungsweg:** Verbundenes Supabase-Migrationswerkzeug (`apply_migration`), nach ausdrücklicher Nutzerfreigabe am 11.11.2026 ausschließlich für DEV.
- **Anlass/Zweck:** Fünfte aktive gelbe Karte chronologisch nach Trainingstag bestimmen; gelbe Sperre dem ersten zulässigen, nachfolgenden Spieltag zuordnen; manuelle Korrektur auf Zielspieltag nach Auslösertraining begrenzen; Neuanlage und Kartenkorrektur über denselben Reconciliation-Pfad führen.
- **Betroffene Objekte:** Ersetzt ausschließlich die vier Funktionen `public.award_training_behavior_event(uuid,uuid,text,text)`, `public.e05_assign_player_suspensions(uuid,uuid,uuid)`, `public.e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)` und `public.correct_suspension(uuid,uuid,text)`. Keine Tabellen, Spalten, Trigger, RLS-Policies, Spielarten-Einstellungen oder Grants wurden geändert.
- **Freigabe:** Ausdrückliche Nutzerfreigabe zur Ausführung in DEV und anschließenden Dokumentation am 11.11.2026.
- **Ausführender:** ChatGPT über das verbundene Supabase-Migrationswerkzeug.
- **Status:** Erfolgreich ausgeführt; Supabase meldete `success: true`; die Migrationshistorie bestätigt Version `20261111161403`.
- **Tatsächlich ausgeführtes SQL / versionierte Datei:** `supabase/migrations/20261111161403_e05_package_10_training_date_suspensions.sql`. Der identische Review-Stand verbleibt zusätzlich unter `docs/sql-drafts/E05_PACKAGE_10_MIGRATION_DRAFT.sql`.
- **Ergebnis und Verifikation (read-only):**
  1. Migrationsversion `20261111161403` ist in der Supabase-Migrationshistorie vorhanden.
  2. Alle vier Funktionen sind vorhanden, `SECURITY DEFINER`, mit festem `search_path = pg_catalog, public, auth`.
  3. EXECUTE: `award_training_behavior_event` und `correct_suspension` sind für `authenticated` ausführbar, nicht für `anon`; die internen Funktionen `e05_assign_player_suspensions` und `e05_reconcile_suspensions_after_event_correction` sind für API-Rollen nicht ausführbar.
  4. Die bestehenden Spielarten-Einstellungen wurden nicht verändert. Read-only-Prüfung ergab für beide DEV-Mannschaften keinen Mannschafts-Override und keine befüllte Vereinskonfiguration.
  5. Eine bestehende offene gelbe Sperre ist weiterhin vorhanden und hat wegen der leeren Spielartenkonfiguration keine Zielzuordnung. Dies entspricht der unveränderten Konfiguration; es wurde keine Einstellung automatisch ergänzt.
  6. Eine read-only-Abfrage fand zwei offene Sperren ohne Zielspieltag. Diese sind wegen fehlender konfigurierter relevanter Spielarten nicht automatisch zuordenbar; die zugehörigen Auslöserdaten wurden geprüft.
  7. Supabase Security Advisor meldet weiterhin allgemeine SECURITY DEFINER-Hinweise für mehrere bestehende RPCs, darunter die bereits für `authenticated` freigegebenen öffentlichen RPCs `award_training_behavior_event` und `correct_suspension`. Die Paket-10-Migration hat diese Berechtigungen unverändert übernommen und keine neuen API-Grants vergeben.
- **Fehlgeschlagener Erstversuch:** Ein erster Aufruf der Migration scheiterte mit Syntaxfehler an der fehlenden Statement-Terminierung nach den PL/pgSQL-Funktionsdefinitionen. Die Migration wurde dabei nicht registriert. Die vier Funktionsdefinitionen in Migrations- und Rollbackdatei wurden korrigiert; anschließend war die erneute Ausführung erfolgreich. Die Migrationshistorie enthält nur den erfolgreichen Lauf.
- **Rollback/Wiederherstellung:** Vollständige vor Package 10 gesicherte Originaldefinitionen aller vier Funktionen liegen in `supabase/rollback/20261111090000_e05_package_10_training_date_suspensions_rollback.sql`. Ein Rollback wurde nicht ausgeführt.
- **Gegenstück in PROD:** Nicht ausgeführt, nicht freigegeben. PROD und GitHub `main` bleiben unverändert.
- **Testumfang / Nachweisgrenzen:** Nach der Migration wurden Funktionsdefinitionen, Suchpfade, Grants, Migrationshistorie und Konfiguration read-only verifiziert. Es wurden keine Testkarten, Test-Sperren oder Test-Spieltagzuordnungen erzeugt. Ein vollständiger fachlicher Funktionstest mit synthetischen Daten und ein Frontend-End-to-End-Test stehen noch aus und sind Bestandteil der anschließenden DEV-Praxistests.


## DB-MIG-2026-009 – E05: Berechtigungsgeprüfte Lese-RPCs für sperrenrelevante Spielarten (DEV)

- **Datum:** 11.11.2026
- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`
- **Migrationsversion / Name:** `20261111180619` – `e05_suspension_game_type_settings_read_rpcs`
- **Freigabe:** Ausdrückliche Nutzerfreigabe am 11.11.2026 nach reproduziertem Frontend-Fehler `permission denied for table user_club_context`; DEV ausschließlich.
- **Anlass/Zweck:** Die Verwaltungsoberfläche konnte die bereits vorhandenen Vereins-/Mannschaftseinstellungen für sperrenrelevante Spielarten nicht laden. Statt direkter Tabellenlesezugriffe, deren RLS-/Kontextprüfung auf `user_club_context` scheiterte, werden zwei eng begrenzte, serverseitig berechtigungsgeprüfte Lese-RPCs verwendet.
- **Betroffene Objekte:** Neu: `public.get_club_suspension_game_types(uuid)` und `public.get_team_suspension_game_type_settings(uuid)`. Beide sind `STABLE SECURITY DEFINER`, fester Suchpfad `pg_catalog, public, auth`, Eigentümer `postgres`. Keine Tabellen, Spalten, Daten, Trigger, RLS-Policies oder vorhandenen Funktionen geändert.
- **Berechtigungslogik:** Vereinslesefunktion verlangt Authentifizierung und `can_manage_club_context(p_club_id)`. Mannschaftslesefunktion verlangt Authentifizierung und entweder Mannschaftsrolle `trainer`/`admin` oder den bereits ausgewählten, berechtigten Mannschaftskontext über `has_selected_team_context(p_team_id)`. Beide Funktionen geben ausschließlich die angefragte Konfiguration zurück.
- **Grants:** EXECUTE nur für `authenticated`; EXECUTE für `anon` und `PUBLIC` entzogen. Keine Tabellenrechte erweitert.
- **Ausführungsweg:** Supabase-Migrationswerkzeug (`apply_migration`) nach ausdrücklicher Freigabe. Supabase meldete `success: true`; Migrationshistorie bestätigt Version `20261111180619`.
- **Versionierte SQL-Quelle:** `supabase/migrations/20261111180619_e05_suspension_game_type_settings_read_rpcs.sql`.
- **Rollback:** `supabase/rollback/20261111180619_e05_suspension_game_type_settings_read_rpcs_rollback.sql`. Rückbau erst nach Rücknahme der Frontend-Aufrufe; entfernt ausschließlich die beiden neuen RPCs.
- **Read-only-Verifikation:** Beide Funktionen vorhanden; Eigentümer `postgres`; SECURITY DEFINER; Suchpfad fest; `authenticated` EXECUTE = true; `anon` EXECUTE = false; `PUBLIC` EXECUTE = false. Migration in Supabase-Historie vorhanden.
- **Frontend-Anpassung:** `renderSuspensionGameTypeSettings` ruft nun die beiden RPCs statt direkter SELECTs auf den Einstellungstabellen auf. Commit auf `develop`: `c64a4e2a90be1e48551346d9cf71b523a73c639a`.
- **Dokumentations-Commits:** Migration `b8e83f1f6fb35f01015bc42dfc585c5d3e63b1cb`; Rollback `97fd20d56319372afa39ab8feb46ba0400f94de4`.
- **Testumfang / Nachweisgrenzen:** Bisher statische Prüfung und Metadaten-/Grant-Verifikation. Noch offen sind echte Browser-Ladetests mit Vereinsadmin, Mannschaftsadmin und Trainer sowie Negativtests für unberechtigte Vereins-/Mannschaftskontexte. Speichern über die bestehenden RPCs wurde nicht verändert und muss im Frontend-Praxistest erneut geprüft werden.
- **PROD / GitHub main:** Nicht ausgeführt, nicht freigegeben; unverändert.


## DB-MIG-2026-010 – E05: Alle Spieltage als Sperrziele (DEV – erfolgreich ausgeführt)

- **Freigabe:** Ausdrückliche Nutzerfreigabe am 12.11.2026 zur Umsetzung ausschließlich in Supabase DEV.
- **Ausführungsdatum:** 12.11.2026
- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`
- **Migrationsversion / Name:** `20261112055415` – `e05_all_matchdays_suspension_targets`
- **Ausführungsweg:** Supabase `apply_migration`; Rückmeldung `success: true`.
- **Anlass/Zweck:** Vereins-/Mannschaftskonfiguration sperrenrelevanter Spielarten aus automatischer Zuordnung, manueller Korrektur und Sperrenableistung entfernen. Jeder geplante Spieltag ist unabhängig von `game_type`, einschließlich NULL, zulässig.
- **Betroffene Objekte:** `e05_assign_player_suspensions(uuid,uuid,uuid)`, `correct_suspension(uuid,uuid,text)`, `serve_matchday_suspensions(uuid)`.
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** `supabase/migrations/20261112055415_e05_all_matchdays_suspension_targets.sql` in `develop`. Der Migrationsdienst registrierte die Version `20261112055415`; der Dateiname wurde danach an die registrierte Version angeglichen. Der ausgeführte SQL-Inhalt ist im GitHub-Migrationsfile abgelegt.
- **Rollback/Wiederherstellung:** `supabase/rollback/20261112055415_e05_all_matchdays_suspension_targets_rollback.sql`. Nur vorbereitet; nicht ausgeführt und nicht live getestet.
- **Read-only-Verifikation:** Alle drei Zielfunktionen vorhanden; Signaturen unverändert; Eigentümer `postgres`; `SECURITY DEFINER = true`; Suchpfad `pg_catalog, public, auth`. EXECUTE-ACLs unverändert: `correct_suspension` und `serve_matchday_suspensions` für `authenticated` und Eigentümer; `e05_assign_player_suspensions` nur für Eigentümer. `anon` besitzt für keine der drei Funktionen EXECUTE.
- **Funktionsdefinitionen:** Keine Spielarten-Konfigurationsreferenzen, kein `v_types`, keine Spielartfilter in der automatischen Zuordnung; manuelle Korrektur enthält keine Spielart-Zielprüfung; Sperrenableistung enthält keine Spielartvariable oder -prüfung.
- **Chronologie:** `e05_reconcile_suspensions_after_event_correction` weiterhin mit `training_date_snapshot` und `ORDER BY e.training_date_snapshot, e.id` nachgewiesen. Diese Funktion wurde nicht verändert.
- **Datenumfang:** Keine Tabellen, Spalten, Daten, Trigger, RLS-Policies oder Grants geändert.
- **Tests / Nachweisgrenzen:** Read-only Prüfung der Funktionsdefinitionen, Signaturen, SECURITY DEFINER, Suchpfade und ACLs abgeschlossen. Keine synthetischen Testdaten und keine echten Sperren-/Spieltag-Aktionen ausgeführt; fachliche Funktions-/E2E-Tests bleiben offen.
- **Gegenstück in PROD:** Nicht ausgeführt, nicht freigegeben. PROD und GitHub `main` unverändert.
- **Frontend:** Noch nicht angepasst. Separater Folgeschritt nach DB-Umsetzung.


## E05 – Datenkorrektur Saisonzuordnung DEV (12.11.2026)

- **Freigabe:** Nutzerbestätigung am 12.11.2026, sämtliche bislang saisonlosen Termine der DEV Mannschaft der aktiven Saison 2026/2027 zuzuordnen, auch wenn die Termine vor Anlage der Saison stattfanden.
- **Umgebung:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`. PROD und GitHub `main` nicht berührt.
- **Ziel:** Aktive Saison `2026/2027`, ID `c63eccff-6f0b-4d2f-add2-554e85ae07ef`, Team `DEV Mannschaft`, ID `4a8830e3-8852-4bb6-be22-279296d0a727`.
- **Vorheriger Befund:** 8 von 10 Spieltagen und 12 von 15 Trainings der DEV Mannschaft hatten `season_id IS NULL`. Alle 20 Datensätze gehörten fachlich zur Saison 2026/2027. Ursache: Saison wurde erst am 30.10.2026 angelegt; Frontend-Schreibpfade setzten bei fehlender aktiver Saison `season_id: season?.id || null`. Die Spalten erlauben NULL; auf `trainings` und `matchdays` existiert kein Trigger zur automatischen Saisonzuordnung.
- **Ausgeführte Datenkorrektur:** Ausschließlich Datensätze der DEV Mannschaft mit `season_id IS NULL` wurden auf die oben genannte aktive Saison gesetzt. Ergebnis der UPDATE-CTEs: 8 Spieltage und 12 Trainings aktualisiert.
- **SQL:**
  ```sql
  with target as (
    select '4a8830e3-8852-4bb6-be22-279296d0a727'::uuid as team_id,
           'c63eccff-6f0b-4d2f-add2-554e85ae07ef'::uuid as season_id
  ),
  updated_matchdays as (
    update public.matchdays m set season_id = target.season_id
    from target
    where m.team_id = target.team_id and m.season_id is null
    returning m.id
  ),
  updated_trainings as (
    update public.trainings tr set season_id = target.season_id
    from target
    where tr.team_id = target.team_id and tr.season_id is null
    returning tr.id
  )
  select (select count(*) from updated_matchdays) as matchdays_updated,
         (select count(*) from updated_trainings) as trainings_updated;
  ```
- **Nachprüfung:** 0 Spieltage und 0 Trainings ohne Saisonzuordnung; danach 10/10 Spieltage und 15/15 Trainings der DEV Mannschaft der Saison 2026/2027 zugeordnet. Andere Mannschaft G-Junioren unverändert und bereits vollständig zugeordnet.
- **Art der Änderung:** Datenkorrektur (DML), keine Schemaänderung und keine Migration. Keine Tabellen, Spalten, Funktionen, Trigger, RLS-Policies oder Grants geändert.
- **Offen:** Frontend-Erstellungspfad absichern, damit Spieltage/Trainings nicht mehr stillschweigend ohne aktive Saison angelegt werden können. Einzel-Training, Trainingsserie und Spieltag müssen berücksichtigt werden. Optional serverseitige Absicherung gesondert prüfen und vor Umsetzung freigeben lassen.


## E05 – Reparatur bestehender Sperrenzuordnungen DEV (12.11.2026)

- **Freigabe / Anlass:** Fortsetzung der ausdrücklich beauftragten DEV-Korrektur der Sperrenproblematik.
- **Umgebung:** Supabase DEV Projekt `pzazqvvoruqnqhcorbwx`; Team DEV Mannschaft `4a8830e3-8852-4bb6-be22-279296d0a727`; Saison 2026/2027 `c63eccff-6f0b-4d2f-add2-554e85ae07ef`.
- **Diagnose:** Nach der Saison-Datenkorrektur waren alle Spieltage/Trainings korrekt zugeordnet, aber bestehende offene Sperren hatten weiterhin NULL als intended_matchday_id. Die Datenbankfunktionen für Kartenerfassung/-korrektur und Sperrenzuordnung sind getrennt: `e05_reconcile_suspensions_after_event_correction` korrigiert den fünften Karteneintrag und ruft anschließend `e05_assign_player_suspensions` auf; `e05_assign_player_suspensions` allein ändert keine fünfte-Karte-Quelle.
- **Tom Achtzehn Jahre:** Fünf aktive gelbe Karten mit Trainingsdaten 15.10., 20.10., 05.11., 07.11. und 09.11.2026. Die offene gelbe Sperre verwies zuvor fälschlich auf die Karte vom 20.10. Nach Aufruf von `e05_reconcile_suspensions_after_event_correction` für die aktive Karte vom 09.11. wurde die Quelle auf Ereignis `22486ebf-d39a-4bd9-b8c7-bb6a2c1cc522` (09.11.) korrigiert und die Sperre auf den nächsten geplanten Spieltag 14.11.2026 / Flensburg zugeordnet.
- **Spieler Dreißig:** Die offene rote Sperre vom 15.10.2026 hatte ebenfalls keine Zielzuordnung. Aufruf von `e05_assign_player_suspensions` hat sie auf den 14.11.2026 / Flensburg gesetzt.
- **Ausgeführte DB-Funktionen:**
  ```sql
  select public.e05_reconcile_suspensions_after_event_correction(
    '22486ebf-d39a-4bd9-b8c7-bb6a2c1cc522'::uuid,
    '1c84aee5-0569-4c92-a53b-9237382f2b43'::uuid,
    'DEV-Korrektur: chronologisch fünfte aktive Gelbe Karte und Neuzuordnung nach Saison-Datenkorrektur'
  );
  select public.e05_assign_player_suspensions(
    '4a8830e3-8852-4bb6-be22-279296d0a727'::uuid,
    '90387b6d-8da0-4f11-98bf-0175670d39ec'::uuid,
    '1c84aee5-0569-4c92-a53b-9237382f2b43'::uuid
  );
  ```
- **Nachprüfung:** Beide offenen Sperren zeigen Status `open`, Zielspieltag 14.11.2026, Gegner Flensburg, Spielart Freundschaftsspiel, Status des Spieltags `planned`. Tom-Quelle ist die gelbe Karte vom 09.11.2026. Audit-Einträge dokumentieren die Korrektur der Kartenquelle sowie beide Zielzuordnungen.
- **Art der Änderung:** Aufruf vorhandener, abgesicherter Datenbankfunktionen; keine direkte Tabellenänderung, keine Schemaänderung, keine Migration, keine RLS-/Grant-/Trigger-Änderung.
- **PROD / main:** unverändert.
- **Offen:** Browser-Praxistest in DEV; prüfen, ob Historie die Sperre jetzt beim 09.11.-Ereignis zeigt und ob Tom sowie Spieler Dreißig für den Spieltag 14.11. als gesperrt erscheinen. Der Spieltag wurde nicht abgeschlossen; keine Sperre wurde als abgeleistet markiert.


## DB-MIG-2026-011 – E05 Sperrprüfung Kaderempfehlung und Nominierung (12.11.2026)

- **Status:** Freigabepaket erstellt; NICHT ausgeführt.
- **Umgebung:** ausschließlich Supabase DEV vorgesehen. PROD und GitHub `main` unverändert.
- **Ausgangsbasis:** Read-only-Prüfung der DEV-RPC `save_matchday_recommendation(uuid,uuid[])`, Ausnahme-RPCs `grant_suspension_exception(uuid,uuid,text)` und `revoke_suspension_exception(uuid,text)`, Tabellen/Spalten, RLS-Policies und vorhandener Trigger auf `matchday_players`.
- **Änderungsumfang:** Neue dedizierte SECURITY DEFINER-Triggerfunktion `e05_assert_matchday_player_not_suspended()` mit festem search_path und rein lesender Sperrenprüfung; zwei BEFORE-Trigger auf `matchday_players` und `matchday_recommendation_players`; guarded Erweiterung der bestehenden Empfehlungs-RPC um dieselbe Sperrenprüfung.
- **Fachregel:** Offene Sperre mit `intended_matchday_id` gleich Zielspieltag blockiert Empfehlung und Nominierung. Eine aktive Ausnahme für exakt diesen Spieltag (`revoked_at IS NULL`) erlaubt sie. Ausnahme bleibt dokumentiert; Sperre wird durch bestehende Ausnahme-RPC verschoben. Widerruf macht die Sperre nach erneuter Zuordnung wieder wirksam.
- **Unverändert:** Ausnahme-RPCs, bestehende Trigger, RLS-Policies, Tabellen/Spalten, vorhandene Daten, bestehende Empfehlungen/Nominierungen, übrige E05-Funktionen. Keine automatische Entfernung bestehender Nominierungen. Keine Frontendänderung.
- **Migration:** `supabase/migrations/20261112120000_e05_suspension_nomination_guard.sql`.
- **Rollback:** `supabase/rollback/20261112120000_e05_suspension_nomination_guard_rollback.sql` (stellt die vorab geprüfte ursprüngliche Empfehlungs-RPC wieder her und entfernt ausschließlich die neuen Trigger/Funktion).
- **Spezifikation:** `docs/E05_DB_MIG_2026_011_SPERRPRUEFUNG_KADERNOMINIERUNG.md`.
- **Wichtiger Status:** Dateien liegen auf `develop`; Migration wurde weder ausgeführt noch in Supabase-Migrationshistorie registriert. Rollback nicht ausgeführt. Umsetzung erst nach gesonderter ausdrücklicher Freigabe.


## DB-MIG-2026-011 – E05 Sperrenprüfung für Kaderempfehlung und Nominierung (12.11.2026)

- **Status:** Vollständiges Freigabepaket in `develop` vorbereitet; ausdrücklich NICHT in Supabase ausgeführt.
- **Ziel:** Regulär gesperrte Spieler werden bei der Speicherung der Kaderempfehlung und bei direkter Nominierung in `matchday_players` serverseitig abgewiesen. Eine nicht widerrufene Ausnahme für genau den ursprünglichen Spieltag erlaubt die Teilnahme; die bestehende Ausnahme bleibt begründungspflichtig, auditiert und verschiebt die offene Sperre über die vorhandene RPC auf den nächsten Spieltag.
- **Read-only-Basis:** `save_matchday_recommendation(uuid,uuid[])` war SECURITY INVOKER, Owner postgres, search_path `pg_catalog, public`, EXECUTE für postgres/authenticated/service_role. Bestehende Ausnahme-RPCs `grant_suspension_exception(uuid,uuid,text)` und `revoke_suspension_exception(uuid,text)` bleiben unverändert. Bestehende Trigger und RLS-Policies auf `matchday_players` bleiben erhalten.
- **Migration:** `supabase/migrations/20261112191000_e05_suspension_nomination_guard.sql`.
- **Rollback:** `supabase/rollback/20261112191000_e05_suspension_nomination_guard_rollback.sql` (stellt die vorab gelesene RPC-Definition wieder her und entfernt nur den neuen Trigger/dessen Funktion).
- **Spezifikation:** `docs/E05_DB_MIG_2026_011_SPERRPRUEFUNG_KADERNOMINIERUNG.md`.
- **Änderungsumfang:** CREATE OR REPLACE der Empfehlungs-RPC mit zusätzlicher Sperrenprüfung; neue SECURITY INVOKER Triggerfunktion und BEFORE INSERT/UPDATE-Trigger auf `matchday_players`; keine Tabellen-/Spalten-/Daten-/RLS-Policy-Änderung. Bestehende Nominierungen werden nicht automatisch gelöscht.
- **Wichtige Ausnahmebehandlung:** Die Prüfung akzeptiert ausschließlich einen nicht widerrufenen Ausnahme-Datensatz für genau die betreffende Sperre und den betreffenden Spieltag. Die bestehende Grant-Funktion verschiebt das offene Sperrziel; der Ausnahme-Datensatz bleibt als Nachweis des ursprünglichen Spieltags erhalten.
- **Freigabegrenze:** Nur Entwurf. Keine SQL-Ausführung, keine Migration registriert, keine Frontendänderung. PROD und GitHub `main` unverändert.
- **Nach Freigabe zu testen:** gesperrte Empfehlung abweisen; ungesperrte Empfehlung zulassen; direkte Nominierung ohne Ausnahme abweisen; Nominierung mit Ausnahme zulassen; nach Widerruf erneut abweisen; Team-/Saisonkontext, RLS, ACLs, bestehende Trigger und Audit prüfen.


## DB-MIG-2026-011 – E05 Sperrenprüfung bei Kaderempfehlung und Nominierung (12.11.2026)

- **Status:** Nach ausdrücklicher Freigabe erfolgreich in Supabase DEV ausgeführt; technische Nachprüfung bestanden, Praxistests noch offen.
- **Migration:** `20261112191000_e05_suspension_nomination_guard`; registrierte Supabase-Version `20261112181910`.
- **Änderungen:** `save_matchday_recommendation(uuid,uuid[])` um Sperrenprüfung ergänzt; neue SECURITY INVOKER Triggerfunktion `prevent_suspended_matchday_nomination()`; neuer BEFORE INSERT/UPDATE-Trigger `matchday_players_prevent_suspended_nomination`.
- **Nachprüfung:** Migration registriert; neuer Trigger vorhanden; alle drei bisherigen Trigger auf `matchday_players` erhalten; Empfehlungs-RPC bleibt SECURITY INVOKER mit unveränderter ACL; acht RLS-Policies unverändert vorhanden.
- **Ausnahmeverhalten:** Nur eine nicht widerrufene Ausnahme für exakt die betreffende Sperre und den betreffenden Spieltag erlaubt Empfehlung/Nominierung. Bestehende Grant-/Revoke-RPCs unverändert.
- **Keine Datenkorrektur:** Keine bestehenden Sperren, Ausnahmen oder Nominierungen verändert; keine Tabellen-/Spalten-/RLS-Änderung.
- **Offen:** Kontrollierte DEV-Positiv-/Negativtests und Rollen-/Ausnahmepraxistest.
- **PROD / main:** unverändert.
- **Rollback:** `supabase/rollback/20261112191000_e05_suspension_nomination_guard_rollback.sql`.
- **Details:** `docs/E05_DB_MIG_2026_011_SPERRPRUEFUNG_KADERNOMINIERUNG.md`.


## DB-MIG-2026-011 – Nachtrag Frontend-/DB-Tests (12.11.2026)

- DB-Direktinsert eines regulär gesperrten Spielers für den zugeordneten Spieltag wurde mit SQLSTATE 23514 abgewiesen. Keine Zeile angelegt.
- Positivkontrolle für ungesperrten Spieler innerhalb einer Transaktion erfolgreich; Transaktion zurückgerollt.
- Frontend-Commit `32afa447a7b6e9baf46d1c55412fd03023c39339`: Sperrstatus im Spieltagskader sichtbar, Ausschluss aus Empfehlung, begründungspflichtiger Ausnahmeaufruf und erneute Prüfung gespeicherter Empfehlung.
- JS-Syntaxprüfung erfolgreich. Browser-/Rollen-/Widerrufstest ausstehend.


## E05 DEV-Konsolidierungsnachtrag – DB-MIG-2026-011 und atomare Ausnahme-Rücknahme (14.11.2026)

Dieser Nachtrag korrigiert ältere Zwischenstände in diesem Protokoll. Die Einträge vom 12.11.2026 mit Status „nicht ausgeführt“, „Praxistests ausstehend“ oder „Widerruf nicht atomar“ sind historische Momentaufnahmen und nicht der aktuelle DEV-Stand.

### DB-MIG-2026-011 – Sperrprüfung Kaderempfehlung und Nominierung

- **Status:** In Supabase DEV registriert und live vorhanden.
- **Supabase-Version/Name:** `20261112181910` / `20261112191000_e05_suspension_nomination_guard`.
- **Tatsächlich registrierte Datei:** `supabase/migrations/20261112191000_e05_suspension_nomination_guard.sql`. Die ältere Datei `20261112120000_e05_suspension_nomination_guard.sql` ist ein früher Entwurfsstand, nicht die registrierte Version.
- **Live-Nachweis:** `save_matchday_recommendation(uuid,uuid[])` enthält die Sperrenprüfung und bleibt SECURITY INVOKER. `prevent_suspended_matchday_nomination()` ist SECURITY INVOKER; Trigger `matchday_players_prevent_suspended_nomination` ist auf `matchday_players` aktiv. Die drei zuvor vorhandenen Trigger sind ebenfalls vorhanden.
- **Funktionale Tests:** Direkter gesperrter Nominierungs-INSERT wurde mit SQLSTATE 23514 abgewiesen; ungesperrter Positivtest wurde transaktional zurückgerollt. Die Nutzerabnahme der sechs Sperren-/Spieltagfälle sowie der Rollenfälle A1–A6 und T1–T8 ist in den E05-Testdokumenten festgehalten.
- **PROD:** Nicht ausgeführt; keine Freigabe.

### Nachfolgende DEV-Migration – atomare Ausnahme-Rücknahme

- **Supabase-Version/Name:** `20261113035705` / `e05_atomic_exception_revocation_20261113`.
- **Live-Nachweis:** `revoke_suspension_exception(uuid,text)` sperrt den Spieler über einen Advisory Lock und die Spielerzeile, widerruft die Ausnahme, berechnet die Sperrenzuordnung neu und entfernt eine bestehende Nominierung nur dann, wenn die Sperre danach wieder genau dem ursprünglichen Spieltag zugeordnet ist. Bei bereits dokumentiertem Einsatz (`played=true`) wird der Widerruf abgebrochen. Das Audit enthält den Status `nomination_removed` sowie den Snapshot der entfernten Nominierung.
- **Synchronisierung:** `prevent_suspended_matchday_nomination()` verwendet denselben spielerbezogenen Advisory Lock.
- **Original-SQL-Nachweis:** Die Migrationsversion ist in Supabase DEV registriert, aber die zugehörige Migrationsdatei und ein Rollback konnten im aktuellen GitHub-Baum nicht gefunden werden. Der exakte tatsächlich ausgeführte SQL-Text ist damit derzeit nicht revisionssicher über GitHub referenziert. Nicht rekonstruieren oder als vorhandene Datei ausgeben; als Release-Gate offen halten, bis der Originaltext/Export wiedergefunden oder eine dokumentierte Ausnahmeentscheidung getroffen wurde.
- **PROD:** Nicht ausgeführt; keine Freigabe.

### Release-Gate

Vor einem PROD-Rollout sind mindestens erforderlich:
1. Original-SQL und Rollback für Version `20261113035705` wiederfinden bzw. den fehlenden Nachweis explizit behandeln.
2. DEV- und PROD-Livebestand getrennt read-only vergleichen.
3. Eine konsolidierte, ausführbare PROD-Migrationsreihenfolge mit Vorbedingungen, Prüfabfragen und Rollback-/Wiederherstellungsplan erstellen.
4. Ausdrückliche separate Freigabe einholen.

Keine SQL-Ausführung, keine Supabase-Schreiboperation und keine Änderung an `main` oder PROD im Rahmen dieses Nachtrags.


### Korrektur zum Original-SQL-Nachweis – Migration 20261113035705 (14.11.2026)

Der vorherige Nachtrag in Abschnitt 7 erklärte die Originaldatei irrtümlich für nicht auffindbar. Die vollständige SQL-Fassung war bereits im Repository vorhanden, allerdings unter `docs/` statt unter `supabase/migrations/`.

- **Original-SQL:** `docs/E05_SQL_ENTWURF_WIDERRUF_AUSNAHME_MIT_NOMINIERUNGSENTFERNUNG_2026-11-12.sql`
- **Datei-SHA (Git blob):** `5b5ac4fd8c14be5bc00ff8d4774ad1d1ac9800b0`
- **Inhaltlicher Status im Datei-Header:** „AM 13.11.2026 als Supabase-DEV-Migration ausgeführt“; Migration `e05_atomic_exception_revocation_20261113`.
- **Rollback-Entwurf:** `docs/E05_SQL_ROLLBACK_ENTWURF_WIDERRUF_AUSNAHME_2026-11-12.sql`
- **Rollback-Datei-SHA (Git blob):** `630c6949faa6e45daf9c758364cb11eb86b09a65`
- **Rollback-Status:** Review-Entwurf, ausdrücklich nicht ausgeführt. Er stellt die vorherigen Funktionsdefinitionen wieder her; er rekonstruiert gelöschte Nominierungen nicht automatisch.
- **Ausführungs- und Testnachweis:** `docs/E05_UMSETZUNGSVORSCHLAG_SPERRMASSNAHMEN_OPTIONSMENUE_2026-11-12.md`, Abschnitte 10.7–10.10: Migration erfolgreich registriert unter Version `20261113035705`; read-only Funktions-/ACL-/Triggerprüfung; Positiv-/Negativtests; echter Zwei-Session-Konkurrenztest mit bestandenem Ergebnis.
- **Live-Abgleich:** Die DEV-Definitionen von `revoke_suspension_exception(uuid,text)` und `prevent_suspended_matchday_nomination()` wurden erneut ausgelesen. Die im Original-SQL dokumentierten Änderungen sind im Live-Stand vorhanden.

**Korrektur des Release-Gates:** Der Original-SQL-Text ist in GitHub vorhanden. Das frühere Gate „Original-SQL wiederfinden“ ist damit geschlossen. Die Datei liegt als ausgeführter SQL-Nachweis unter `docs/`, nicht im standardisierten Migrationsordner `supabase/migrations/`. Für das PROD-Paket muss daraus eine sauber versionierte, geprüfte Migration samt Wiederherstellungsplan abgeleitet werden; die vorhandene Rollback-Datei bleibt ein nicht ausgeführter Entwurf und ist vor PROD-Einsatz gesondert zu reviewen.

Keine Supabase-Schreiboperation und keine PROD-Änderung im Rahmen dieser Korrektur.


### DB-MIG-2026-012 – E05 PROD Paket 1: Trainingsereignisse und Ereignis-Audit

- **Ausführungsdatensatz:** PROD
- **Datum/Uhrzeit (mit Zeitzone):** 14.11.2026, 17:26:46 CET (aus Supabase-Migrationsversion abgeleitet)
- **Umgebung:** Supabase PROD `qdugtpzgefpswnnqbusd` – PostgreSQL 17.6
- **Ausführungsweg:** Supabase `apply_migration`
- **Anlass/Zweck:** Chronologischer PROD-Rollout von E05; Datenbankfundament für Trainingsereignisse und append-only Ereignis-Audit.
- **Betroffene Objekte:** `public.training_behavior_events`, `public.training_behavior_event_audit`, zugehörige Indizes/Constraints, Funktion `e05_reject_event_audit_mutation()`, zwei Audit-Trigger, RLS, zwei SELECT-Policies und Tabellen-Grants.
- **Freigabe:** Ausdrückliche Nutzerfreigabe am 14.11.2026 unmittelbar vor Ausführung.
- **Ausführender:** ChatGPT über Supabase-Migrationswerkzeug.
- **Status:** Erfolgreich; read-only Verifikation bestanden.
- **Migrations-ID / Supabase-Version:** `20261114162646` – `e05_prod_paket_01_trainingsereignisse_20261114`.
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** `docs/prod-release/E05_PROD_PAKET_01_TRAININGSEREIGNISSE_2026-11-14.sql`; freigegebener SQL-Inhalt vor Ausführung; historischer Git-Blob-SHA des vor PROD-Ausführung übergebenen, unveränderten SQL-Inhalts `6f39812500ac8ce427d3330a8281af941b259b90`.
- **Ergebnis:** Supabase meldete `success: true`; Migration in PROD-Historie registriert. Neue Tabellen sind leer.
- **Verifikation (read-only):** Beide Tabellen und Audit-Guard vorhanden; RLS auf beiden aktiv; 2 Policies; 5 Ereignisindizes; 2 Audit-Indizes; 2 Audit-Trigger; `authenticated` SELECT ja/INSERT nein; `anon` SELECT nein; `service_role` SELECT ja; 0 Ereignis- und 0 Auditzeilen.
- **Rollback/Wiederherstellung:** Guarded Rollback unter `docs/prod-release/E05_PROD_PAKET_01_TRAININGSEREIGNISSE_2026-11-14_ROLLBACK.sql`; isolierter PostgreSQL-17.6-Test erfolgreich, einschließlich Daten- und Abhängigkeits-Gates. Kein Rollback in PROD ausgeführt. Backup-/PITR-Status konnte mit den verfügbaren Werkzeugen nicht unabhängig ausgelesen werden.
- **Gegenstück in der anderen Umgebung:** DEV-Paket 1 wurde bereits am 08.11.2026 ausgeführt; DEV wurde bei diesem PROD-Lauf nicht verändert.
- **GitHub-Dateien und Commit-SHAs:** Release-SQL `docs/prod-release/E05_PROD_PAKET_01_TRAININGSEREIGNISSE_2026-11-14.sql` – `52d4f13bb5c91d91efc30474eb9e47897331bbdc`; Rollback `..._ROLLBACK.sql` – `98b9341b6bdda96d60c6a57a547ed2e096347339`; Ausführungsdokumentation `...2026-11-14.md` – `39bcb03d3a39820692e1b660b1e7c40b8c749200`; zentrale Projektdokumentation – `b7e48ff52121007b3513dcd7c93a17fd7b722c3c`.
- **Zusätzliche Hinweise:** Keine Änderung an GitHub `main`, Frontend oder bestehenden fachlichen Datensätzen. Nachfolgende E05-Pakete bleiben einzeln freigabepflichtig.


### Ergänzender Nachweis – E05 PROD Paket 1: CI und unveränderlicher SQL-Blob

- **Isolierter PostgreSQL-Test:** GitHub Actions Run `43615149537`, erfolgreich. Getestet wurden Paket-SQL, RLS, Policies, Indizes, Audit-Trigger, Tabellen-/Funktionsrechte, Append-only-Schutz und guarded Rollback einschließlich Daten-/Abhängigkeits-Gates.
- **Exakter SQL-Inhalt, der vor der PROD-Ausführung vorlag:** Git-Blob `6f39812500ac8ce427d3330a8281af941b259b90`. Dieser historische Blob wurde erneut über die GitHub-Git-Blob-API abgerufen und geprüft. Der heute sichtbare Release-Dateikopf wurde nach Ausführung um den Erfolgsstatus ergänzt; daher ist der aktuelle Datei-Blob nicht mit dem historischen ausgeführten Blob gleichzusetzen.
- **Dokumentationsstatus:** Die Freigabe-/Ausführungsdokumentation wurde am 14.11.2026 um diesen unveränderlichen Verweis, den CI-Run und die Nachweisgrenze Backup/PITR ergänzt. Der PROD-Backup-/PITR-Status konnte nicht unabhängig verifiziert werden.

### DB-MIG-2026-013 – E05 PROD Paket 2: Trainingsereignis-Vergabe-RPC

- **Ausführungsdatensatz:** PROD
- **Datum/Uhrzeit:** 14.11.2026, 17:52:13 CET (aus Supabase-Migrationsversion abgeleitet)
- **Umgebung:** Supabase PROD `qdugtpzgefpswnnqbusd` – PostgreSQL 17.6
- **Ausführungsweg:** Supabase `apply_migration`
- **Anlass/Zweck:** Chronologischer E05-Rollout; Bereitstellung der serverseitigen RPC zur Vergabe von gelber Karte, roter Karte und positivem Stern mit atomarem Ereignis-/Audit-Insert.
- **Betroffenes Objekt:** `public.award_training_behavior_event(uuid,uuid,text,text)`.
- **Freigabe:** Ausdrückliche Nutzerfreigabe am 14.11.2026 unmittelbar vor Ausführung.
- **Unmittelbare Vorprüfung:** Paket-1-Tabellen vorhanden; Paket-2-RPC nicht vorhanden; Paket-3-Sperrentabellen nicht vorhanden; erforderliche Bestandsobjekte, Felder, `auth.uid()` und `has_selected_team_context(uuid)` vorhanden.
- **Migrations-ID / Supabase-Version:** `20261114165213` – `e05_prod_paket_02_trainingsevent_rpc_20261114`.
- **Tatsächlich ausgeführtes SQL:** `docs/prod-release/E05_PROD_PAKET_02_TRAININGSEVENT_RPC_2026-11-14.sql`; Git-Blob vor Ausführung `bea5a140587a1e9cee4f49504e7bf983283bdda9`.
- **Ergebnis:** Supabase meldete `success: true`; Migration ist in der PROD-Migrationshistorie registriert.
- **Read-only-Verifikation:** RPC genau einmal vorhanden; Owner `postgres`; SECURITY DEFINER; fester `search_path=pg_catalog, public, auth`; EXECUTE für `authenticated` ja, für `anon`, `service_role` und `PUBLIC` nein; Paket-3-Sperrenlogik nicht enthalten; 0 neue Ereignis- und 0 neue Auditdatensätze im Ausführungszeitraum.
- **Isolierter Test:** GitHub Actions Run `43616072353`, erfolgreich. PostgreSQL 17.6, exaktes SQL, RPC-Sicherheits-/ACL-Assertions, Positiv-/Negativpfade und guarded Rollback vor Paket 3 bestanden.
- **Rollback/Wiederherstellung:** `docs/prod-release/E05_PROD_PAKET_02_TRAININGSEVENT_RPC_2026-11-14_ROLLBACK.sql`; isoliert erfolgreich getestet, kein Rollback in PROD ausgeführt. Nach Paket 3 darf Paket 2 nicht isoliert zurückgebaut werden. Backup-/PITR-Status nicht unabhängig verifiziert.
- **GitHub-Dateien / Commits:** PROD-SQL Commit `5f5135a2eda714710be86a4cf84e2708c792f3e8`; Rollback Commit `8fb7c24d2a35f891135f537bfb7d684185347282`; Test-Fixture `7a32c1ce67dbef2613340df1949585511cec92ad`; Assertions letzte Fassung `36847bc6f8777728c4b8406cb7243b5c6b65fe2e`; Workflow `55ce57043b5cde66a186845ad0ea00f4b2143015`; Ausführungsdokumentation `f2e0f9e5613bfb0db825a9bc25ea8a68086daa8a`.
- **Änderungsgrenzen:** DEV und GitHub `main` unverändert. Keine bestehenden Tabellen, Rollen oder Policies geändert. Paket 3 bleibt separat freigabepflichtig.

- **Zusätzliche Ausführungssicherung:** Ein nachfolgender identischer Ausführungsaufruf wurde durch das SQL-Vorbedingungs-Gate vor DDL abgebrochen, da die Paket-2-RPC bereits existierte. Keine zweite Funktionsänderung; in der PROD-Migrationshistorie steht genau ein Paket-2-Eintrag.


### DB-MIG-2026-014 – E05 PROD Paket 3: Sperrenfundament und automatische Sperrenauslösung (Freigabekandidat)

- **Status:** Technische Abschlussprüfung bestanden; zur ausdrücklichen PROD-Freigabe vorgelegt. **Noch nicht in PROD ausgeführt.**
- **Zielumgebung:** Supabase PROD `qdugtpzgefpswnnqbusd`, PostgreSQL 17.6.
- **Abhängigkeiten:** DB-MIG-2026-012 (Paket 1) und DB-MIG-2026-013 (Paket 2) sind in PROD vorhanden.
- **DEV-Quelle:** `docs/E05_PAKET_03_SUSPENSION_TRIGGER_2026-11-08.sql`, Blob-SHA `74c77a6c3b1f346e404d88254533bf908a469662`; zugehöriges DEV-Ausführungsprotokoll `docs/E05_PAKET_03_FREIGABE_UND_AUSFUEHRUNG_2026-11-08.md`.
- **PROD-Migration:** `supabase/migrations/20261114180000_e05_prod_paket_03_suspension_foundation.sql`, Blob-SHA `7f519980342bcde70379d884144a231a864a9de2`.
- **Rollback:** `supabase/rollback/20261114180000_e05_prod_paket_03_suspension_foundation_rollback.sql`, Blob-SHA `2bef2818bce64fac90ca17c1d27794baeac69255`.
- **CI-Nachweis:** GitHub Actions Run `43620391604`, erfolgreich auf PostgreSQL 17.6. Migration, Rollback, Assertions und Fixture stimmen bytegenau mit den im erfolgreichen CI-Commit `4b36272b781c3afa648abdd3dce7327728ebbdfb` getesteten Dateien überein.
- **Abschlussreview:** PROD-Migrationsfunktion ist identisch mit dem DEV-Paket-3-Funktionsblock; Rollback stellt die Paket-2-PROD-RPC exakt wieder her; keine `CASCADE`-Operation. Aktuelle PROD-Vorbedingungen und benötigte Bestandsfelder read-only bestätigt. Paket-1-Event- und Audit-Tabellen enthalten derzeit 0 Zeilen.
- **Fachlicher Umfang:** rote Karte erzeugt sofort eine rote Sperre; fünfte aktive gelbe Karte erzeugt eine gelbe Sperre. Die spätere Trainingsdatum-Chronologie und Spieltagszuordnung/Ausnahmen sind nicht Teil dieses Pakets, sondern folgen in späteren Paketen.
- **Rollback-Grenze:** Bei vorhandenen Ereignis-/Auditdaten oder installierten Folgepaketen bricht das Rollback ab. Es entfernt nicht selbst einen Eintrag aus Supabase-Migrationshistorie; eine eventuelle Ledger-Abstimmung ist separat über den vorgesehenen Supabase-Migrationsprozess vorzunehmen. Backup-/PITR-Status konnte nicht unabhängig ausgelesen werden und ist vor Ausführung zu prüfen.
- **Freigabe:** Die Freigabe zur Vorbereitung ist erteilt; eine ausdrückliche Freigabe zur PROD-Ausführung steht noch aus.
- **Ausführung:** Nicht ausgeführt. Kein Supabase-DEV-/PROD-Schreibzugriff, keine Änderung an GitHub `main`. Vor tatsächlicher Ausführung erneuter Preflight, Hash-Abgleich und Backup-/PITR-Kontrolle.
- **Vollständiges Freigabedossier:** `docs/prod-release/E05_PROD_PAKET_03_SPERRFUNDAMENT_2026-11-14.md`.


### E05 PROD Paket 3 – Sperrenfundament (Freigabe ausstehend)

- **Status:** technischer Freigabekandidat auf `develop`; nicht in PROD ausgeführt.
- **Migration:** `supabase/migrations/20261114180000_e05_prod_paket_03_suspension_foundation.sql`; SHA `7f519980342bcde70379d884144a231a864a9de2`.
- **Rollback:** `supabase/rollback/20261114180000_e05_prod_paket_03_suspension_foundation_rollback.sql`; SHA `f50eec5491a741138e3a23f7934b36fb05caeeb5`; guarded, ohne CASCADE, Abbruch bei vorhandenem Datenbestand oder installierten E05-Folgeabhängigkeiten.
- **Nachkontrolle:** `docs/prod-release/E05_PROD_PAKET_03_SPERRFUNDAMENT_2026-11-14_TESTQUERIES.sql`; SHA `21f6800801e53c2765a8a46e1ea0b9b55e39ff1e`.
- **Finale CI:** [Run 43620906226](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43620906226), PostgreSQL 17.6, `success`, Commit `b75e1789aafd3d3c68702ff40633e41bae5944fb`.
- **Finale SQL-Prüfung:** Paket-2-Funktionskörper live in PROD mit Paket-2-Release und Rollback-Funktionskörper abgeglichen; Funktionskörper stimmen nach Normalisierung überein. PROD-ACL: EXECUTE nur `authenticated`, nicht `anon`/`service_role`. Paket-3-Objekte/Policies fehlen in PROD wie erwartet.
- **Rollback-Gate:** erweitert um Folgepaket-4-bis-10-Objekte und spätere Nominierungsabhängigkeiten. Isolierter Rollback-Test erfolgreich.
- **Fachliche Grenze:** Paket 3 aktiviert automatische Sperrenauslösung, ist jedoch kein vollständiger Trainerworkflow. Spieltagszuordnung, Ausnahmen, Korrektur und finale Trainingsdatum-Chronologie liegen in späteren separat freizugebenden Paketen.
- **Freigabe:** technische Prüfung abgeschlossen; ausdrückliche Nutzerfreigabe zur PROD-Ausführung steht aus. Unmittelbarer Preflight/Hash-Abgleich erfolgt erst nach Freigabe.
- **Backup/PITR:** Status wurde nicht unabhängig geprüft; vor Ausführung muss ein geeigneter Wiederherstellungspunkt gemäß Betriebsprozess bestätigt werden.


### DB-MIG-2026-014 – E05 PROD Paket 3: Sperrenfundament

- **Ausgeführt:** 14.11.2026 in Supabase PROD.
- **Supabase-Migration:** Version `20261114174854`, Name `e05_prod_paket_03_suspension_foundation_20261114`.
- **SQL-Datei:** `supabase/migrations/20261114180000_e05_prod_paket_03_suspension_foundation.sql`, Blob-SHA `7f519980342bcde70379d884144a231a864a9de2`.
- **Ergebnis:** erfolgreich; Sperren- und Audit-Tabellen vorhanden, RLS aktiv, je eine Policy, 4/2 Indizes, Audit-Guard und zwei Audit-Trigger vorhanden.
- **Rechte:** authenticated SELECT auf Sperren, kein direkter INSERT; anon kein SELECT; Paket-2-RPC EXECUTE nur für authenticated, nicht anon/service_role.
- **Datenbestand nach Ausführung:** 0 Sperren, 0 Sperren-Audit-Einträge.
- **Backup/PITR:** unter Supabase Free nicht unabhängig bestätigt; als dokumentierte Plan-Einschränkung behandelt, kein Release-Blocker.
- **Rollback:** nicht ausgeführt.
- **Vollständige Ausführungsdokumentation:** `docs/prod-release/E05_PROD_PAKET_03_SPERRFUNDAMENT_2026-11-14.md`.


### DB-MIG-2026-015 – E05 PROD Paket 4: Spieltagszuordnung und Ableistung

- **Ausgeführt:** 14.11.2026 in Supabase PROD nach ausdrücklicher Nutzerfreigabe.
- **Supabase-Migration:** Version `20261114184029`, Name `e05_prod_paket_04_matchday_lifecycle_20261114`. Supabase-generierte Version weicht vom lokalen Dateipräfix ab; dies ist der tatsächliche PROD-Ledger-Eintrag.
- **SQL-Datei:** `supabase/migrations/20261114190000_e05_prod_paket_04_matchday_lifecycle.sql`; Git-Blob-SHA `9618e5a3431d88b88eeee5efba6efa94813cbfae`.
- **Rollback-Datei:** `supabase/rollback/20261114190000_e05_prod_paket_04_matchday_lifecycle_rollback.sql`; Git-Blob-SHA `859eb68407373b4a6c8940ed3c8f9c9b640efe0c`. Nicht ausgeführt.
- **Nachkontrolle:** `docs/prod-release/E05_PROD_PAKET_04_SPIELTAGSZUORDNUNG_2026-11-14_TESTQUERIES.sql`; Git-Blob-SHA `bf6707f8b556fb64f5e3938baed5994bb883ac19`.
- **CI:** [Run 43624723426](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43624723426), PostgreSQL 17.6, vollständig erfolgreich.
- **PROD-Struktur:** drei Konfigurationstabellen vorhanden, RLS auf allen aktiv, drei SELECT-Policies, keine direkten Schreibrechte für authenticated, kein SELECT für anon.
- **RPCs:** vier vorgesehene RPCs SECURITY DEFINER mit festem search_path; EXECUTE nur für authenticated (nicht anon). Interner Zuordnungs-Helper nicht für authenticated ausführbar.
- **Audit:** zwei append-only Trigger auf `training_suspension_audit` vorhanden.
- **Datenbestand nach Ausführung:** 1 Club, 1 Team, 0 Sperren, 0 Sperren-Audit-Einträge; keine bestehenden Sperr-/Spieltagdaten verändert.
- **Advisor:** Health ohne Findings. Security-/Performance-Warnungen umfassen überwiegend projektweite bzw. bereits vorhandene Themen; Paket-4-bezogene Details sind im Ausführungsdossier festgehalten. Keine pauschalen Änderungen an anderen Funktionen/Policies.
- **Testgrenze:** isolierter CI-Test prüft Migration, Struktur, ACL/RPC-Verhalten, Konfigurationshierarchie und Rollback. Vollständige Abläufe mit echten offenen Sperren und realen Spieltagen wurden nicht in PROD ausgelöst; diese bleiben durch DEV-Abnahme dokumentiert.
- **Ausführungsdokumentation:** `docs/prod-release/E05_PROD_PAKET_04_SPIELTAGSZUORDNUNG_2026-11-14.md`.
- **Ergebnis:** erfolgreich ausgeführt und read-only nachkontrolliert.


### DB-MIG-2026-016 – E05 PROD Paket 5: Spieltagsausnahmen bei Sperren

- **Ausgeführt:** 14.11.2026 in Supabase PROD nach ausdrücklicher Nutzerfreigabe.
- **Supabase-Migration:** Version `20261114202342`, Name `e05_prod_paket_05_matchday_suspension_exception_20261114`.
- **SQL-Datei:** `supabase/migrations/20261114193000_e05_prod_paket_05_matchday_suspension_exception.sql`; Git-Blob-SHA `5bf9e040b5fb5ba3faf2f1acec9400b3efeb7df3`.
- **CI:** [Run 43635963976](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43635963976), PostgreSQL 17.6; Migration, Struktur-/ACL-/Audit-Assertions und guarded Rollback erfolgreich.
- **PROD-Nachkontrolle:** Ausnahmetabelle, RLS, eine SELECT-Policy, drei Indizes, Audit-Spalten/Constraints/Policy, SECURITY DEFINER-RPC mit festem search_path und EXECUTE-ACL wie vorgesehen.
- **Audit-Trigger:** beide bestehenden append-only Trigger erhalten.
- **Datenbestand:** 0 Ausnahmen, 0 Sperren, 0 Audit-Einträge; keine bestehenden fachlichen Daten verändert.
- **Ausführungsdokumentation:** `docs/prod-release/E05_PROD_PAKET_05_SPIELTAGSAUSNAHMEN_2026-11-14.md`.
- **Ergebnis:** erfolgreich ausgeführt und read-only nachkontrolliert. Funktionaler End-to-End-Praxistest mit echten Sperren/Spieltagdaten steht noch aus.

### DB-MIG-2026-017 – E05 PROD Paket 6: Atomarer Widerruf einer Spieltagsausnahme

- **Status:** Freigabekandidat vorbereitet; nicht ausgeführt.
- **DEV-Quelle:** `docs/E05_SQL_ENTWURF_WIDERRUF_AUSNAHME_MIT_NOMINIERUNGSENTFERNUNG_2026-11-12.sql`; DEV-Ausführung 13.11.2026; SHA `5b5ac4fd8c14be5bc00ff8d4774ad1d1ac9800b0`.
- **PROD-Abweichung:** Nach Paket 5 existiert in PROD weder die Widerrufs-RPC noch der Nominierungsschutz-Trigger. Paket 6 legt daher die synchronisierte Triggerfunktion und den Trigger zusätzlich an.
- **Migration:** `supabase/migrations/20261114210000_e05_prod_paket_06_atomic_exception_revocation.sql`.
- **Rollback:** `supabase/rollback/20261114210000_e05_prod_paket_06_atomic_exception_revocation_rollback.sql`; guarded, entfernt ausschließlich Paket-6-Objekte und bricht ab, sobald Widerrufs-/Nominierungsentfernungs-Auditdaten existieren.
- **CI:** [Run 43638965684](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43638965684), PostgreSQL 17.6; Migration, RPC-/Trigger-/ACL-Assertions und Rollback erfolgreich.
- **Freigabedossier:** `docs/prod-release/E05_PROD_PAKET_06_ATOMARER_AUSNAHMEWIDERRUF_2026-11-14.md`.
- **Testgrenze:** Kein authentifizierter End-to-End-Widerruf und kein echter Paralleltransaktionstest im CI; fachliche DEV-Praxistests bleiben vor Frontend-Rollout erforderlich.
- **Freigabe:** Separate ausdrückliche Freigabe zur PROD-Ausführung erforderlich.

### DB-MIG-2026-017 – E05 PROD Paket 6: Atomarer Widerruf einer Spieltagsausnahme

- **Status:** in PROD ausgeführt und strukturell nachkontrolliert am 14.11.2026 nach ausdrücklicher Freigabe.
- **PROD-Migrationseintrag:** `20261114211343 e05_prod_paket_06_atomic_exception_revocation_20261114`.
- **Projekt:** `qdugtpzgefpswnnqbusd`, PostgreSQL 17.6.1.166.
- **DEV-Quelle:** `docs/E05_SQL_ENTWURF_WIDERRUF_AUSNAHME_MIT_NOMINIERUNGSENTFERNUNG_2026-11-12.sql`; DEV-Ausführung 13.11.2026.
- **PROD-Migration:** `supabase/migrations/20261114210000_e05_prod_paket_06_atomic_exception_revocation.sql`; Blob-SHA vor Ausführung `1f7eac877c6edbc5873617e4118c4721cb1f2bc6`.
- **Nachkontrolle:** Widerrufs-RPC SECURITY DEFINER mit festem search_path; EXECUTE nur authenticated. Triggerfunktion SECURITY INVOKER mit festem search_path. Sperr-Nominierungsschutz-Trigger vorhanden; bestehende Aktivspieler-Trigger erhalten.
- **Produktivdaten:** 0 Ausnahmen, 0 Sperren, 0 Audit-/Widerrufs-Auditzeilen; keine Testdaten erzeugt.
- **Rollback:** nicht ausgeführt.
- **Offen:** authentifizierte End-to-End- und Konkurrenztests nicht in PROD ausgeführt; vor Frontend-Rollout in DEV/isolierter Umgebung erforderlich.
- **Frontend/main:** keine Änderungen; Index-Deploy weiterhin zurückgestellt.
- **Freigabedossier:** `docs/prod-release/E05_PROD_PAKET_06_ATOMARER_AUSNAHMEWIDERRUF_2026-11-14.md`.

### DB-MIG-2026-018 – E05 PROD Paket 7: Kontrollierter Saisonabschluss

- **Status:** Freigabekandidat vorbereitet; nicht ausgeführt.
- **DEV-Ausführungen:** `20261108180535 e05_package_07_controlled_season_closure` und `20261108180944 e05_package_07_fix_season_audit_context_rls`; beide in DEV erfolgreich, siehe `docs/E05_PAKET_07_ABNAHME_UND_AUSFUEHRUNG_2026-11-08.md`.
- **PROD-Bestand:** Audit-Tabelle und Paket-7-RPC/Triggerfunktion fehlen; erforderliche Basistabellen und Teamkontext-Helper sind vorhanden.
- **PROD-Migration:** `supabase/migrations/20261114220000_e05_prod_paket_07_controlled_season_closure.sql`.
- **Rollback:** `supabase/rollback/20261114220000_e05_prod_paket_07_controlled_season_closure_rollback.sql`; guarded, nur bei leerem Saisonabschluss-Audit. Stellt keine bereits geschlossene Saison oder abgelaufene Sperren wieder her.
- **CI:** [Run 43642743485](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43642743485), PostgreSQL 17.6; Migration, Struktur/ACL/RLS, Positiv-/Negativtests und Rollback erfolgreich.
- **Freigabedossier:** `docs/prod-release/E05_PROD_PAKET_07_KONTROLLIERTER_SAISONABSCHLUSS_2026-11-14.md`.
- **Freigabe:** Separate ausdrückliche Freigabe zur PROD-Ausführung erforderlich.

### DB-MIG-2026-018 – E05 PROD Paket 7: Kontrollierter Saisonabschluss

- **Status:** Freigabekandidat vollständig vorbereitet; noch nicht ausgeführt.
- **DEV-Quelle:** `docs/E05_PAKET_07_SAISONABSCHLUSS_2026-11-08.sql` (SHA `2626c07c212a84481fe532f4b83083bc2aac90f5`) und `docs/E05_PAKET_07_FIX_AUDIT_RLS_SUPERADMIN_2026-11-08.sql` (SHA `0b94492f3c30133107f2b328ef8328e0317f51f0`).
- **PROD-Migration:** `supabase/migrations/20261114220000_e05_prod_paket_07_controlled_season_closure.sql`.
- **Rollback:** `supabase/rollback/20261114220000_e05_prod_paket_07_controlled_season_closure_rollback.sql`; guarded, bricht ab sobald ein Saisonabschluss-Audit existiert.
- **CI:** PostgreSQL 17.6, [Run 43642771857](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43642771857), vollständig erfolgreich inkl. Funktions-/Negativtests und Rollback.
- **PROD-Baseline:** Pakete 1–6 registriert; Basistabellen und Kontextfunktionen vorhanden; Paket-7-Objekte fehlen erwartungsgemäß. Read-only Bestand: 1 aktive Saison, 0 offene Sperren.
- **PROD-Freigabe:** separate ausdrückliche Freigabe erforderlich.
- **GitHub main/Frontend:** unverändert.
- **Dossier:** `docs/prod-release/E05_PROD_PAKET_07_KONTROLLIERTER_SAISONABSCHLUSS_2026-11-14.md`.

### DB-MIG-2026-018 – E05 PROD Paket 7: Kontrollierter Saisonabschluss – PROD-Ausführung

- **Ausführungsdatensatz:** PROD
- **Datum/Uhrzeit (mit Zeitzone):** 14.11.2026, 22:37:45 CET (21:37:45 UTC; Supabase-Ledger-Version `20261114213745`).
- **Umgebung:** Supabase PROD, Projekt `qdugtpzgefpswnnqbusd` (PostgreSQL 17.6.1.166, eu-west-1).
- **Ausführungsweg:** Supabase MCP `apply_migration`; Migration atomar ausgeführt.
- **Anlass/Zweck:** Bereitstellung des kontrollierten Saisonabschlusses gemäß ausdrücklicher Freigabe des Projektverantwortlichen vom 14.11.2026.
- **Betroffene Objekte:** `public.team_season_closure_audit`; `public.close_team_season(uuid,text)`; `public.e05_reject_season_closure_audit_mutation()`; SELECT-RLS-Policy `team_season_closure_audit_select_team`; Append-only-Trigger `team_season_closure_audit_no_mutation`.
- **Freigabe:** Ausdrücklich erteilt: „Freigabe erteilt für E05 PROD Paket 7. Bitte Migration ausführen, nachkontrollieren und lückenlos dokumentieren.“
- **Ausführender:** ChatGPT über die verbundene Supabase-Projektintegration im Auftrag des Projektverantwortlichen.
- **Status:** Erfolgreich; anschließende read-only Verifikation bestanden.
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** `supabase/migrations/20261114220000_e05_prod_paket_07_controlled_season_closure.sql`; Git-Blob-SHA `1493cff2a67e2478af7aad6d7c419c353a9dd9ad`. Der ausgeführte SQL-Text entspricht der auf `develop` geprüften Fassung.
- **Supabase-Migrationshistorie:** Eintrag `20261114213745 e05_prod_paket_07_controlled_season_closure` vorhanden; Pakete 1–7 sind damit in PROD registriert.
- **Ergebnis:** `apply_migration` meldete `success: true`. Kein Fehler und kein Teilstatus.
- **Read-only-Verifikation:** Audit-Tabelle vorhanden; alle 8 Spalten vorhanden; RLS aktiviert; eine SELECT-Policy für `authenticated` mit `is_team_member(team_id) OR has_selected_team_context(team_id)`; `authenticated` besitzt ausschließlich SELECT, `anon` besitzt keine Tabellenrechte; PK/FKs/UNIQUE/Checks vorhanden; PK- und UNIQUE-Index auf `season_id`; Append-only-Trigger für UPDATE/DELETE/TRUNCATE vorhanden; Triggerfunktion SECURITY DEFINER mit festem search_path und ohne EXECUTE-Rechte für API-Rollen; Saisonabschluss-RPC SECURITY DEFINER mit festem search_path, EXECUTE für `authenticated` ja und für `anon`, `service_role`, PUBLIC nein.
- **Datenbestand:** 1 Saison insgesamt, 1 aktiv, 0 inaktiv; 0 offene Sperren; 0 Sperren-Auditzeilen; 0 Saisonabschluss-Auditzeilen. Die aktive Saison `2026/2027` blieb aktiv. Die RPC `close_team_season` wurde nicht aufgerufen.
- **Advisor:** Health ohne Findings. Security Advisor zeigt 50 authentifizierbare SECURITY DEFINER-Funktionen (vorher 49; die neue autorisierte Saisonabschluss-RPC ist der zusätzliche Eintrag), eine bereits vorhandene mutable-search_path-Warnung sowie deaktivierten Leaked-Password-Schutz. Keine bestehenden Funktionen/Policies geändert.
- **Rollback/Wiederherstellung:** Guarded Rollback `supabase/rollback/20261114220000_e05_prod_paket_07_controlled_season_closure_rollback.sql`, Blob-SHA `340c69fafc800a80033b57b4967ba698618be23e`, nicht ausgeführt. Bricht ab, sobald Saisonabschluss-Auditdaten existieren; stellt weder Saisonstatus noch Sperrenzustände wieder her.
- **Gegenstück in der anderen Umgebung:** DEV-Paket 7 bleibt mit den Migrationen `20261108180535` und `20261108180944` erfolgreich vorhanden; keine DEV-Änderung in diesem Schritt.
- **CI-Nachweis:** [Run 43642771857](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43642771857), Commit `cc545e9a1a055a29e02600e671c94161403c64a9`, PostgreSQL 17.6, `success` einschließlich Migration, Struktur-/ACL-/RLS-Assertions, Positiv-/Negativtests und guarded Rollback.
- **Abweichung im vorbereitenden Dossier:** Ein älterer Snapshot notierte 2 aktive Saisons. Die unmittelbar vor Ausführung live abgefragte PROD-Basis ergab 1 Saison (`2026/2027`), davon 1 aktiv. Maßgeblich ist der aktuelle Live-Befund; keine Saison wurde verändert.
- **Änderungsgrenzen:** Keine fachlichen Daten angelegt oder verändert; keine Saison geschlossen; keine Sperre abgelöst; kein Frontend-Index, GitHub `main` oder DEV-Projekt verändert.


### DB-MIG-2026-019 – E05 PROD Paket 8: Vorzeitiger Sperrausgleich – PROD-Ausführung

- **Ausführungsdatensatz:** PROD
- **Datum/Uhrzeit (mit Zeitzone):** 14.11.2026, 23:28:33 CET (22:28:33 UTC; Supabase-Ledger-Version `20261114222833`).
- **Umgebung:** Supabase PROD, Projekt `qdugtpzgefpswnnqbusd` (Jugendmannschaft, eu-west-1, PostgreSQL 17.6.1.166).
- **Ausführungsweg:** Supabase MCP `apply_migration`; Migration atomar ausgeführt.
- **Anlass/Zweck:** Bereitstellung des vorzeitigen Sperrausgleichs nach ausdrücklicher Benutzerfreigabe. Die zuvor als zusätzliche Vorsichtsmaßnahme vorgeschlagene Backup-/PITR-Bedingung wurde nach Klärung mit dem Projektverantwortlichen nicht als Release-Gate angewendet; der etablierte PROD-Release-Prozess wurde fortgeführt. Das verbleibende Wiederherstellungsrisiko des Free-Plans ist bekannt.
- **Freigabe:** Bereits ausdrücklich erteilt und im aktuellen Gespräch bestätigt: „Freigabe erteilt“.
- **Migration:** `supabase/migrations/20261114230000_e05_prod_paket_08_early_suspension_reset.sql`; Git-Blob-SHA `0a302bf476aea108e44e9c7287f9a45944f296cc`. Der auf `develop` dokumentierte und CI-geprüfte SQL-Stand wurde unverändert ausgeführt.
- **Ergebnis:** `apply_migration` meldete `success: true`; Migration vollständig und atomar angewendet. Supabase-Migrationshistorie enthält `20261114222833 e05_prod_paket_08_early_suspension_reset`.
- **Read-only Nachkontrolle:** Tabellen `matchday_early_suspension_resets` und `matchday_early_suspension_reset_audit` vorhanden; RLS auf beiden aktiviert; erwartete SELECT-Policies vorhanden; Indizes, PK/FK-/CHECK-Constraints vorhanden; alle drei Trigger vorhanden; alle internen Paket-8-Helfer vorhanden.
- **Berechtigungen:** `authenticated` besitzt auf beiden Tabellen SELECT, aber keine INSERT-/UPDATE-/DELETE-Rechte; `anon` besitzt keine Tabellenrechte. `service_role` behält die Supabase-typischen privilegierten Tabellenrechte. Öffentliche Vormerkungs- und Storno-RPCs sind für `authenticated` ausführbar, nicht für `anon` oder `service_role`; interne Übergangs-/Trigger-/Audit-Helfer sind für API-Rollen nicht ausführbar.
- **Award-RPC-Integration:** `award_training_behavior_event(uuid,uuid,text,text)` enthält die Paket-8-Erweiterung. Owner `postgres`, SECURITY DEFINER, search_path `pg_catalog, public, auth`; EXECUTE für `authenticated` ja, für `anon` und `service_role` nein.
- **Datenbestand nach Migration:** 0 Reset-Datensätze, 0 Audit-Datensätze; 1 aktive Saison; 0 offene Sperren. Die Migration hat keine fachlichen Reset-/Audit-Datensätze angelegt, keine Saison geändert und keine Sperre abgelöst.
- **Advisor:** Health Advisor ohne Findings. Security Advisor: 52 SECURITY DEFINER-Warnungen (vorher 50; zwei neue, beabsichtigte und rollenbeschränkte Paket-8-RPCs), eine bestehende mutable-search_path-Warnung für `public.set_updated_at` und deaktivierter Leaked-Password-Schutz. Keine globale Advisor-Korrektur Bestandteil dieses Pakets.
- **Rollback:** Guarded Rollback `supabase/rollback/20261114230000_e05_prod_paket_08_early_suspension_reset_rollback.sql`, Blob-SHA `7c8f358ded8e1f077addfa1d96b6bee3f7f98337`, nicht ausgeführt. Er bleibt vor einer Feature-Nutzung nur bei leerem Reset-/Auditbestand und ohne spätere Abhängigkeiten möglich; nach Feature-Nutzung absichtlich gesperrt.
- **CI:** PostgreSQL 17.6, [GitHub Actions Run 43645581297](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43645581297), Commit `8b45a76aa23f77f452ec38c70ea1219d0468209a`, success.
- **Änderungsgrenzen:** Keine DEV-Änderung; kein GitHub-`main)-Merge; kein Frontend-Index-Deploy; keine fachliche Nutzung des neuen Features im Rahmen der Migration.
- **Dossier:** `docs/prod-release/E05_PROD_PAKET_08_VORZEITIGER_SPERRAUSGLEICH_2026-11-14.md`.


### DB-MIG-2026-020 – E05 PROD Paket 9: Manuelle Sperren- und Kartenkorrektur

- **Ausführungsdatensatz:** PROD
- **Datum:** 15.11.2026
- **Uhrzeit / Zeitzone:** Der Supabase-Migrationsdatensatz weist die Version 20261115051236 aus. Ein separater, verlässlicher Ausführungszeitstempel mit Zeitzone wurde vom Ausführungswerkzeug nicht zurückgegeben; die Versionszeit wird daher nicht als bestätigte lokale Uhrzeit interpretiert.
- **Umgebung:** Supabase PROD – Projekt qdugtpzgefpswnnqbusd, PostgreSQL 17.6.1.166, eu-west-1.
- **Ausführungsweg:** Supabase apply_migration über die verbundene Supabase-Integration; vollständiger SQL-Text aus der versionierten GitHub-Migration.
- **Anlass/Zweck:** Paket 9 von E05 – kontrollierte manuelle Umordnung offener Sperren und Korrektur (Stornierung/Wiederherstellung) fehlerhafter gelber/roter Kartenereignisse.
- **Betroffene Objekte:** training_behavior_event_audit.changed_by_snapshot; training_suspension_audit.changed_by_snapshot (bereits vorhanden, additiv abgesichert); training_suspensions.manual_target_locked; interne Funktionen e05_assert_suspension_correction_permission und e05_reconcile_suspensions_after_event_correction; Erweiterung e05_assign_player_suspensions; öffentliche RPCs correct_suspension und correct_training_behavior_event.
- **Freigabe:** Ausdrückliche PROD-Freigabe des Projektverantwortlichen am 15.11.2026 im Chat.
- **Ausführender:** ChatGPT über die verbundene Supabase-Integration auf ausdrückliche Freigabe.
- **Status:** Erfolgreich; Post-Deployment-Verifikation erfolgreich.
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** supabase/migrations/20261114235000_e05_prod_paket_09_manual_suspension_card_correction.sql, Branch develop, Blob SHA 4385af6b7789bdcf7fb29167d0339add327ea640; Datei ist im develop-Commit 4ab114a5a98b629109099cbd63290ef8ba248fff enthalten.
- **Supabase-Migrationshistorie:** Version 20261115051236, Name e05_prod_paket_09_manual_suspension_card_correction.
- **Ergebnis / Fehlermeldung:** apply_migration meldete success=true. Keine Fehlermeldung.
- **Verifikation (read-only Abfrage und Ergebnis):**
  - Beide öffentlichen Korrektur-RPCs vorhanden, SECURITY DEFINER, search_path pg_catalog/public/auth.
  - EXECUTE für authenticated: ja; anon, service_role und PUBLIC: nein.
  - Interne Berechtigungs- und Reconciliation-Helfer sowie der interne Allocator nicht direkt für authenticated/anon/service_role ausführbar.
  - manual_target_locked: boolean NOT NULL DEFAULT false.
  - changed_by_snapshot auf beiden Audit-Tabellen vorhanden.
  - RLS auf allen vier Event-/Sperren-Tabellen weiterhin aktiviert.
  - Alle vier bestehenden Append-only-Audit-Trigger unverändert vorhanden.
  - authenticated besitzt weiterhin 0 direkte INSERT/UPDATE/DELETE/TRUNCATE-Rechte auf den vier Event-/Sperren-Tabellen.
  - Allocator enthält manuelle Ziel-Sperre und behält den bestehenden Spielartenfilter; Paket-10-Trainingstaglogik ist nicht enthalten.
  - Korrigierter PERFORM-Spielerzeilenlock vorhanden.
  - Datenbestand nach Migration: 0 Trainingsereignisse, 0 Event-Auditzeilen, 0 Sperren, 0 Sperren-Auditzeilen, 0 offene Sperren, 0 manuelle Zielzuordnungen. Keine vorhandenen fachlichen Datensätze verändert.
- **Rollback/Wiederherstellung:** Kein automatischer DROP-Rollback. Bei Problemen gezielter Forward-Fix; Rückbau nur nach gesonderter datenbewusster Prüfung und Freigabe.
- **Gegenstück in der anderen Umgebung:** DEV-Paket-9-Migrationen 20261108212745, 20261108213035 und 20261108213211 waren bereits erfolgreich vorhanden; keine neue DEV-Ausführung im Rahmen dieses PROD-Releases.
- **GitHub-Datei und Commit-SHA:** supabase/migrations/20261114235000_e05_prod_paket_09_manual_suspension_card_correction.sql; Blob SHA 4385af6b7789bdcf7fb29167d0339add327ea640; develop Commit 4ab114a5a98b629109099cbd63290ef8ba248fff.
- **Zusätzliche Hinweise / Nachweisgrenzen:** Isolierte PostgreSQL-CI erfolgreich (GitHub Actions Run 43648820383). CI ersetzt keine authentifizierten Supabase-End-to-End-Verhaltenstests; DEV-Funktionstests bleiben fachliche Testgrundlage. Der Datenbestand war zum Ausführungszeitpunkt leer, daher konnten keine realen Spieler-/Sperrenkorrekturen in PROD ausgelöst werden.


### DB-MIG-2026-021 – E05 PROD Paket 10: Trainingsdatumsbasierte Kartenchronologie und alle geplanten Sperrziele – PROD-Ausführung

- **Ausführungsdatensatz:** PROD
- **Datum/Uhrzeit (mit Zeitzone):** 15.11.2026, 08:41:17 CET (07:41:17 UTC; Supabase-Ledger-Version `20261115074117`).
- **Umgebung:** Supabase PROD, Projekt `qdugtpzgefpswnnqbusd`.
- **Ausführungsweg:** Supabase `apply_migration` über die verbundene Supabase-Integration; atomare Migration.
- **Anlass/Zweck:** Umsetzung von E05 Paket 10: Trainingsdatumsbasierte Gelbkartenchronologie und Sperrzuordnung auf jeden geplanten Spieltag, unabhängig von `game_type`.
- **Freigabe:** Ausdrücklich erteilt durch den Projektverantwortlichen am 15.11.2026: „Freigabe für Umsetzung erteilt. Bitte Dokumentation aktualisieren.“
- **Ausführender:** ChatGPT über die verbundene Supabase-Projektintegration im Auftrag des Projektverantwortlichen.
- **Status:** Erfolgreich; unmittelbare read-only Postflight-Verifikation erfolgreich.
- **Tatsächlich ausgeführtes SQL / unveränderlicher Verweis:** `supabase/migrations/20261115090000_e05_prod_paket_10_training_date_suspension_chronology.sql`; Branch `develop`; Blob-SHA `bc61c1a380001e2952babd99117b17114a6d5459`. Der vollständige versionierte SQL-Text wurde unverändert an `apply_migration` übergeben.
- **Supabase-Migrationshistorie:** Version `20261115074117`, Name `e05_prod_paket_10_training_date_suspension_chronology`; Paket 10 ist in PROD registriert.
- **Betroffene Objekte:** Ausschließlich die fünf vorhandenen Funktionsdefinitionen `award_training_behavior_event(uuid,uuid,text,text)`, `e05_assign_player_suspensions(uuid,uuid,uuid)`, `e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)`, `correct_suspension(uuid,uuid,text)` und `serve_matchday_suspensions(uuid)`. Keine Tabellen, Spalten, fachlichen Daten, Trigger, Policies, RLS-Einstellungen oder Grants wurden als Paketumfang geändert.
- **Read-only Verifikation der Funktionen:** Alle fünf Funktionsdefinitionen zeigen die erwartete Paket-10-Logik. Definitionlängen: 6.436 / 6.797 / 16.506 / 6.042 / 3.903 Zeichen; identisch mit den zuvor geprüften DEV-Definitionen.
- **Sicherheit und Berechtigungen:** Alle fünf Funktionen bleiben `SECURITY DEFINER`, Owner `postgres`, fester `search_path = pg_catalog, public, auth`. `authenticated` besitzt EXECUTE nur auf den drei vorgesehenen öffentlichen RPCs; `anon` besitzt dort keine EXECUTE-Rechte. Interne Allocator-/Reconciliation-Helfer bleiben für API-Rollen nicht ausführbar.
- **RLS:** RLS ist weiterhin auf allen vier Event-/Sperren-Tabellen aktiviert.
- **Datenbestand nach Migration:** 0 Trainingsereignisse, 0 Sperren, 0 offene Sperren. Keine fachlichen Datensätze durch Paket 10 angelegt oder verändert.
- **Ergebnis / Fehlermeldung:** Supabase `apply_migration` meldete `success: true`. Kein Fehler und kein Teilstatus.
- **Rollback/Wiederherstellung:** `supabase/rollback/20261115090000_e05_prod_paket_10_training_date_suspension_chronology_rollback.sql`, Blob-SHA `c61f2a46b8e148638ba71dca8b1fade25594472a`. Nicht ausgeführt; nur nach gesonderter ausdrücklicher Freigabe und erneuter Prüfung späterer Funktionsänderungen.
- **Gegenstück in der anderen Umgebung:** DEV-Funktionsstand DB-MIG-2026-008 plus DB-MIG-2026-010 war bereits vorhanden und wurde in diesem PROD-Schritt nicht verändert.
- **Änderungsgrenzen:** Kein Frontend-Index, GitHub `main`, PROD-Frontend-Deployment oder DEV-Projekt verändert. Frontend-Filterung der manuellen Sperrenauswahlliste und DB-MIG-2026-011 bleiben separate Arbeitspakete.
- **Dossier:** `docs/prod-release/E05_PROD_PAKET_10_TRAININGSDATUM_CHRONOLOGIE_2026-11-15.md`.


### DB-MIG-2026-022 – E05 PROD Paket 11: Sperrprüfung bei Kaderempfehlung und Nominierung – PROD-Ausführung

- **Ausführungsdatensatz:** PROD
- **Datum:** 15.11.2026
- **Zeit / Zeitzone:** Supabase-Ledger-Version `20261115082224`. Das Ausführungswerkzeug lieferte keinen separaten lokalen Zeitstempel; die Ledger-Version wird nicht als bestätigte lokale Uhrzeit interpretiert.
- **Umgebung:** Supabase PROD, Projekt `qdugtpzgefpswnnqbusd`, PostgreSQL 17.
- **Ausführungsweg:** Supabase `apply_migration` über die verbundene Supabase-Integration; vollständiger SQL-Text aus dem versionierten `develop`-Branch.
- **Freigabe:** Ausdrücklich erteilt am 15.11.2026 im aktuellen Chat: „Freigabe erteilt und Dokumentation ergänzen“.
- **Ausführender:** ChatGPT über die verbundene Supabase-Integration im Auftrag des Projektverantwortlichen.
- **Status:** Erfolgreich; unmittelbare read-only Post-Deployment-Verifikation erfolgreich.
- **Tatsächlich ausgeführtes SQL / unveränderlicher Verweis:** `supabase/migrations/20261115100000_e05_prod_paket_11_suspension_aware_recommendation_nomination.sql`; Branch `develop`; Blob-SHA `f5d9cba62275a090d5138b12505c6bec62f638cc`. Der vollständige, unveränderte Dateiinhalt wurde an `apply_migration` übergeben.
- **Supabase-Migrationshistorie:** Version `20261115082224`, Name `e05_prod_paket_11_suspension_aware_recommendation_nomination`. Der Eintrag ist in der aktuellen PROD-Migrationsliste vorhanden.
- **Betroffene Objekte:** `public.save_matchday_recommendation(uuid,uuid[])` wurde durch die aktuelle live aus DEV ausgelesene Definition ersetzt. Auf `public.prevent_suspended_matchday_nomination()` wurden die direkten EXECUTE-Rechte für PUBLIC, anon und authenticated entzogen; service_role behält EXECUTE. Keine Tabellen, Spalten, fachlichen Datensätze, Trigger, Policies oder RLS-Einstellungen wurden durch Paket 11 verändert.
- **Fachliches Ergebnis:** Eine offene Sperre für genau den Zielspieltag blockiert jetzt auch das Speichern einer Kaderempfehlung. Eine aktive, nicht widerrufene Ausnahme für denselben Spieler und Spieltag erlaubt die Empfehlung. Die direkte Nominierung wird weiterhin durch den vorhandenen Trigger geprüft. Sperren für andere Spieltage blockieren nicht.
- **Read-only Funktionsverifikation:** `save_matchday_recommendation` in PROD: MD5 `4c038919d1c6470633b1229aa2adff06`, Länge 3.586 Zeichen – identisch zur aktuellen DEV-Definition. Die vorhandene Triggerfunktion bleibt SECURITY INVOKER mit festem search_path; EXECUTE: authenticated nein, anon nein, service_role ja, PUBLIC nein. `revoke_suspension_exception` blieb unverändert.
- **Triggerverifikation:** Alle vier bestehenden Trigger auf `matchday_players` sind vorhanden. Insbesondere `matchday_players_prevent_suspended_nomination` ist weiterhin mit `prevent_suspended_matchday_nomination()` verbunden. Kein Trigger wurde neu angelegt oder entfernt.
- **RLS:** RLS weiterhin aktiviert auf `training_suspensions`, `training_suspension_exceptions`, `matchday_players`, `matchday_recommendation_runs` und `matchday_recommendation_players`.
- **Ergebnis / Fehlermeldung:** Supabase `apply_migration` meldete `success: true`. Keine Fehlermeldung.
- **CI:** Isolierte PostgreSQL-17.6-CI erfolgreich: [GitHub Actions Run 43692553123](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43692553123). Migration, Sperr-/Ausnahme-Verhalten, ACLs, Triggererhalt und guarded Rollback wurden erfolgreich geprüft. Die CI ersetzt keinen authentifizierten Supabase-End-to-End-Test.
- **Advisor-Nachkontrolle:** Security Advisor meldet weiterhin projektweite Hinweise, darunter SECURITY-DEFINER-Funktionen und multiple permissive RLS-Policies sowie die mutable-search_path-Warnung für `public.set_updated_at`. Diese projektweiten Hinweise wurden nicht durch Paket 11 eingeführt oder im Rahmen dieses Pakets verändert; keine globale Advisor-Bereinigung Bestandteil der Freigabe.
- **Rollback/Wiederherstellung:** Guarded Rollback `supabase/rollback/20261115100000_e05_prod_paket_11_suspension_aware_recommendation_nomination_rollback.sql`, Blob-SHA `dad4b9c9b3c0fc9664dc719c11be36aa4af299d9`. Nicht in PROD ausgeführt; CI hat ihn ausschließlich in der isolierten Testdatenbank geprüft. Eine PROD-Ausführung erfordert gesonderte Freigabe.
- **Änderungsgrenzen:** Kein DEV-Projekt, GitHub `main`, Frontend-Index oder Frontend-Deployment verändert. Keine fachlichen Daten durch die Migration angelegt oder geändert.
- **Dossier:** `docs/prod-release/E05_PROD_PAKET_11_SPERRPRUEFUNG_KADEREMPFEHLUNG_NOMINIERUNG_2026-11-15.md`.


#### Ergänzende Nachkontrolle Paket 11 – 15.11.2026

- Ein erneuter Ausführungsversuch der Paket-11-Migration wurde vom Preflight vor jeder Änderung abgebrochen, da die Sperrenprüfung in `save_matchday_recommendation` bereits vorhanden war. Der erneute Versuch hat keine Datenbankänderung ausgelöst.
- Die anschließende aktuelle Supabase-Migrationsliste bestätigt weiterhin den vorhandenen Ledger-Eintrag `20261115082224 e05_prod_paket_11_suspension_aware_recommendation_nomination`.
- Live-Postflight: Kaderempfehlungsfunktion MD5 `4c038919d1c6470633b1229aa2adff06`, 3.586 Zeichen – identisch mit DEV. Triggerfunktion mit DEV-identischen EXECUTE-Rechten (nur service_role und postgres); vier bestehende Matchday-Player-Trigger unverändert vorhanden; RLS auf allen fünf relevanten Tabellen aktiviert.
- Die fachlichen Schutzmechanismen in Nominierungstrigger und Ausnahme-Widerruf wurden zusätzlich gegen DEV geprüft. Abweichungen der Funktionsdefinitionen sind textuelle Formatierungs-/Kommentarunterschiede; die geprüften Sperr-, Lock-, Ausnahme-, Einsatzschutz- und Audit-Schritte sind vorhanden.
- Ergebnis: Paket 11 bleibt erfolgreich in PROD registriert. Der abgebrochene Wiederholungsversuch ist ein sicherer Preflight-Abbruch und kein Rollback des bereits registrierten Pakets.


### DB-MIG-2026-022 – AP03 Superadmin-Kontext und RLS-Härtung (DEV)

- **Ausführungsdatensatz:** DEV
- **Datum/Uhrzeit (mit Zeitzone):** 15.11.2026, 12:44:40 MEZ (Supabase-Ledger-Version `20261115114440`)
- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`
- **Ausführungsweg:** verbundenes Supabase-Migrationswerkzeug (`apply_migration`)
- **Anlass/Zweck:** Superadmin-Zugriffe auf Vereins- und Mannschaftsdaten konsequent an den ausdrücklich ausgewählten Vereinskontext binden; eigene Kontextdatensätze lesbar machen.
- **Betroffene Objekte:** Funktion `public.is_club_admin(uuid)`; Policies `club_members_select_member_or_admin`, `club_member_roles_select_member_or_admin`, `teams_select_context_admin`; neue Policies `user_club_context_select_self` und `user_team_context_select_self`.
- **Freigabe:** ausdrückliche Nutzerfreigabe am 15.11.2026 für die sechs Änderungen in DEV. Keine PROD-Freigabe erteilt.
- **Ausführender:** ChatGPT über das verbundene Supabase-Migrationswerkzeug, auf ausdrückliche Nutzerfreigabe.
- **Status:** Erfolgreich ausgeführt; strukturelle/read-only Postflight-Verifikation erfolgreich. Authentifizierte Praxistests noch offen.
- **Tatsächlich ausgeführtes SQL bzw. unveränderlicher Verweis:** `supabase/migrations/20261115130000_ap03_superadmin_context_rls_hardening_dev.sql`, Blob-SHA `dccd8b43e3b009a75cf960a76566ae7d17176b76`, Git-Commit `c3fcb32509332623e3bac480d22c0606ffc83098`.
- **Ergebnis / Fehlermeldung:** Supabase meldete `success: true`; Migrationsledger enthält `20261115114440 ap03_superadmin_context_rls_hardening_dev`. Keine Fehlermeldung.
- **Verifikation (read-only Abfrage und Ergebnis):** Funktionsdefinition enthält die Superadmin-Kontextprüfung; SECURITY DEFINER, Owner postgres und fester search_path erhalten; EXECUTE-ACL unverändert (authenticated/service_role ja, anon/PUBLIC nein); alle fünf Policies wie vorgesehen vorhanden; RLS auf allen fünf Tabellen aktiv. Health Advisor ohne Findings. Security Advisor: 52 Hinweise zu SECURITY-DEFINER-Ausführbarkeit und 1 Hinweis zu deaktiviertem Schutz vor kompromittierten Passwörtern; gesonderte Bewertung erforderlich.
- **Rollback/Wiederherstellung:** `supabase/rollback/20261115130000_ap03_superadmin_context_rls_hardening_dev_rollback.sql`, Blob-SHA `4df263a7ed9321f19d4ce442c5587dc3d5f784aa`. Nicht ausgeführt. Der Rollback stellt absichtlich den zuvor bestehenden pauschalen Superadmin-Bypass wieder her.
- **Gegenstück in der anderen Umgebung:** PROD nicht ausgeführt; separate Freigabe erforderlich.
- **Zusätzliche Hinweise / Nachweisgrenzen:** Keine fachlichen Daten geändert. Authentifizierte End-to-End-Positiv-/Negativtests mit echten Sitzungen stehen noch aus; bis dahin keine vollständige fachliche Sicherheitsabnahme behaupten.
- **Dossier:** `docs/AP03_SUPERADMIN_CONTEXT_RLS_HARDENING_DEV_2026-11-15.md`.


### DB-MIG-2026-023 – AP03 PROD-Härtung set_updated_at und Team-Kontext

- **Umgebung:** Supabase PROD – Projekt `qdugtpzgefpswnnqbusd`.
- **Supabase-Ledger-Version:** `20261115134422`.
- **Migrationsname:** `ap03_prod_set_updated_at_and_team_context_hardening`.
- **Ausführungsweg:** verbundenes Supabase-Migrationswerkzeug (`apply_migration`).
- **Freigabe:** ausdrückliche PROD-Freigabe des Nutzers unmittelbar vor Ausführung am 15.11.2026.
- **Zweck:** festen search_path für `set_updated_at()` setzen und Team-SELECT-Policy an ausgewählten Vereinskontext binden.
- **Änderungen:** `set_updated_at()` bleibt SECURITY INVOKER, Owner postgres und bestehende ACL unverändert; `search_path=pg_catalog, public` gesetzt. `teams_select_context_admin` verwendet `can_manage_club_context(teams.club_id)`.
- **Ergebnis:** Supabase meldete `success: true`; Migration im Ledger nachgewiesen.
- **Postflight:** Funktion/search_path/ACL geprüft; sechs Trigger weiterhin vorhanden; Team-Policy kontextgebunden; übrige Vereins- und Kontext-Policies unverändert; beide Kontext-Helper unverändert. Keine fachlichen Daten oder Tabellenstruktur geändert.
- **Advisor:** Health ohne Findings. Security Advisor weiterhin 54 projektweite SECURITY-DEFINER-Ausführbarkeitshinweise und 1 Hinweis auf deaktivierten Passwort-Leak-Schutz; nicht Bestandteil dieses Pakets.
- **Rollback:** `supabase/rollback/20261115140000_ap03_prod_set_updated_at_and_team_context_hardening_rollback.sql`, Blob-SHA `04038691bf6ff4c96ca8f0c6d7d6415c2275fd83`. Nicht ausgeführt.
- **Migration:** `supabase/migrations/20261115140000_ap03_prod_set_updated_at_and_team_context_hardening.sql`, Blob-SHA `e70c46db6f7c60f5bc16cc9a490e72e1a1e8b779`.
- **Dossier:** `docs/prod-release/AP03_PROD_SET_UPDATED_AT_TEAM_CONTEXT_HARDENING_2026-11-15.md`.


### DB-MIG-2026-024 – Sichere Superadmin-Vereinsauswahl-RPC (DEV)

- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`.
- **Supabase-Ledger-Version:** `20261115135639`.
- **Migrationsname:** `superadmin_club_picker_rpc_dev`.
- **Zweck:** Neutralen Superadmins die Vereinsauswahl ermöglichen, ohne direkten pauschalen Tabellenzugriff zu benötigen.
- **Änderung:** Neue Funktion `public.get_super_admin_clubs()`, Rückgabe ausschließlich `id, name, short_name, crest_path`. SECURITY DEFINER mit festem `search_path=pg_catalog, public`; explizite Prüfung `auth.uid() IS NOT NULL AND public.is_super_admin()`. EXECUTE nur für `authenticated`; PUBLIC und `anon` entzogen.
- **Ergebnis:** Supabase meldete `success: true`; Migration im DEV-Ledger nachgewiesen.
- **Tests:** Authentifizierter Superadmin ohne Vereinsmitgliedschaft und ohne ausgewählten Kontext: RPC liefert 1 Verein. Normales authentifiziertes Konto: RPC liefert 0 Vereine. Anonymer Aufruf: durch fehlendes EXECUTE abgewiesen. Tests liefen in Transaktionen; temporäre Testdaten wurden zurückgerollt.
- **Migration:** `supabase/migrations/20261115160000_superadmin_club_picker_rpc_dev.sql`, Blob-SHA `e0ef73939c66bef6d5c0b03118193a541797963e`.
- **Rollback:** `supabase/rollback/20261115160000_superadmin_club_picker_rpc_dev_rollback.sql`, Blob-SHA `7f706a6356614d30926b6c1d8f5989430d042bea`. Nicht ausgeführt.

### DB-MIG-2026-025 – Direkten Vereins-SELECT an Mitgliedschaft/Kontext binden (DEV)

- **Umgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`.
- **Supabase-Ledger-Version:** `20261115135825`.
- **Migrationsname:** `superadmin_club_picker_rls_context_dev`.
- **Zweck:** Pauschalen Superadmin-Bypass aus der direkten SELECT-Policy auf `public.clubs` entfernen. Die neutrale Vereinsauswahl erfolgt ausschließlich über DB-MIG-2026-024.
- **Änderung:** Policy `clubs_select_member_or_superadmin` ersetzt durch `is_club_member(id) OR is_club_admin(id)`. Damit bleibt direkter Zugriff für Vereinsmitglieder und für den ausdrücklich ausgewählten Vereinskontext bestehen.
- **Abhängigkeiten:** Vorherige Definitionen von `is_club_member(uuid)` und `is_club_admin(uuid)` per Hash geprüft; beide Funktionen bleiben SECURITY DEFINER mit festem search_path.
- **Ergebnis:** Supabase meldete `success: true`; Policy in DEV entspricht dem kontextgebundenen PROD-Prinzip.
- **Tests:** Neutral simulierter Superadmin ohne Mitgliedschaft/Kontext: direkter SELECT auf `clubs` liefert 0 Zeilen, Picker-RPC liefert 1 Verein. Nach `select_club_context`: direkter SELECT liefert 1 Zeile. Alle temporären Mitgliedschafts-/Kontextänderungen erfolgten innerhalb einer zurückgerollten Transaktion; keine Testdaten blieben bestehen.
- **Migration:** `supabase/migrations/20261115161000_superadmin_club_picker_rls_context_dev.sql`, Blob-SHA `17d2bc428c8f71d1dc983e1edeaa0827dd4ff1e4`.
- **Rollback:** `supabase/rollback/20261115161000_superadmin_club_picker_rls_context_dev_rollback.sql`, Blob-SHA `c16183bd9421d3cb38779a2382d4931b2a08d210`. Nicht ausgeführt; der Rollback stellt den pauschalen Bypass wieder her und ist nur als DEV-Notfallwiederherstellung gedacht.

- **Frontend:** `index.html` in `develop` verwendet für `loadSuperAdminClubs()` jetzt `rpc('get_super_admin_clubs')` statt eines direkten `clubs`-SELECT. Commit `d4b08a39229967177f7cb5c2eabf25783bb1ab9d`; Blob-SHA `799cb91c77af5e390d8ac10326d22f9a150ae963`.
- **Security Advisor:** 53 Hinweise zu SECURITY-DEFINER-Funktionen für `authenticated`, darunter die neue bewusst eng begrenzte Picker-RPC; ein Hinweis auf deaktivierten Schutz vor kompromittierten Passwörtern. Health Advisor ohne Findings. Die neue RPC ist eine absichtliche, geprüfte Ausnahme: explizite Superadmin-Prüfung, minimale Rückgabefelder, kein EXECUTE für `anon`/PUBLIC.
- **PROD:** Unverändert. Keine PROD-Migration ausgeführt.


### DB-MIG-2026-026 – Sichere Superadmin-Vereinsauswahl-RPC (PROD) – ausgeführt

- **Umgebung:** Supabase PROD – Projekt `qdugtpzgefpswnnqbusd`.
- **Tatsächliche Ledger-Version:** `20261115151239`; **Migrationsname:** `superadmin_club_picker_rpc_prod` (vom Supabase-Migrationsdienst vergeben).
- **Status:** erfolgreich in PROD ausgeführt und read-only verifiziert am 15.11.2026.
- **Zweck:** Die aktuelle develop-Frontendversion lädt die neutrale Superadmin-Vereinsauswahl über `get_super_admin_clubs()`, ohne direkten pauschalen SELECT auf `clubs`.
- **Live-Preflight-Basis:** PROD `is_super_admin()` MD5 `cffa76d7f45b67cb7c7add371df764bd`; kontextgebundene Policy `clubs_select_member_or_superadmin` mit `is_club_member(id) OR is_club_admin(id)`; genau eine clubs-SELECT-Policy. `is_club_admin()` ist bereits kontextgebunden.
- **Änderungsumfang:** ausschließlich neue RPC mit Rückgabe `id, name, short_name, crest_path`; SECURITY DEFINER, STABLE, fester search_path; EXECUTE nur für authenticated. Keine Änderung bestehender Tabellen, Daten, Funktionen, Policies, Trigger oder Storage-Objekte.
- **Migration:** `supabase/migrations/20261115170000_superadmin_club_picker_rpc_prod.sql`.
- **Rollback:** `supabase/rollback/20261115170000_superadmin_club_picker_rpc_prod_rollback.sql`; entfernt ausschließlich die neue RPC.
- **Dossier:** `docs/prod-release/DB_MIG_2026_026_SUPERADMIN_CLUB_PICKER_PROD_2026-11-15.md`.
- **Ausführung:** Supabase meldete `success: true`. Live-Ledger listet `20261115151239 superadmin_club_picker_rpc_prod`.
- **Postflight:** Funktion vorhanden; Ergebnis `TABLE(id uuid, name text, short_name text, crest_path text)`; SECURITY DEFINER true; Owner `postgres`; `search_path=pg_catalog, public`; EXECUTE authenticated ja, anon nein, PUBLIC nein. Bestehende clubs-SELECT-Policy unverändert kontextgebunden (`is_club_member(id) OR is_club_admin(id)`), genau eine SELECT-Policy.
- **Scope:** ausschließlich neue RPC; keine Tabellen-, Daten-, bestehenden Funktions-, RLS-, Trigger- oder Storage-Änderungen. Der UI-End-to-End-Test folgt nach Deploy PROD.


### DB-MIG-2026-027 – Epic 23 Paket 1: Nominierungsvormerkung (DEV) – geplant, nicht ausgeführt

- **Zielumgebung:** Supabase DEV – Projekt pzazqvvoruqnqhcorbwx.
- **Status:** Geplant / SQL vorbereitet. Keine Ausführung begonnen.
- **Zweck:** Tabellen, append-only Audit, kontrollierte Create-/Cancel-RPCs und Erfüllungstrigger für Nominierungsvormerkungen.
- **Migration:** `supabase/migrations/20261117120000_epic23_nomination_reminder_foundation_dev.sql`.
- **Rollback:** `supabase/rollback/20261117120000_epic23_nomination_reminder_foundation_rollback.sql` (guarded; verweigert Rücknahme bei vorhandener Historie).
- **Postflight:** `docs/E23_PAKET_01_VERIFICATION_2026-11-17.sql`.
- **Testplan:** `docs/E23_PAKET_01_DEV_TESTPLAN_2026-11-17.md`.
- **Dossier:** `docs/E23_PAKET_01_DB_GRUNDLAGE_2026-11-17.md`.
- **Betroffene geplante Objekte:** `matchday_nomination_reminders`, `matchday_nomination_reminder_audit`, zwei Nutzer-RPCs, zwei Triggerfunktionen und zwei Trigger.
- **Freigabe/Ausführung:** Noch keine Ausführungsfreigabe verwendet; keine schreibende SQL-Anweisung ausgeführt.
- **Ergebnis/Verifikation:** Nicht ausgeführt; Postflight und DEV-Tests offen.
- **Rollback/Wiederherstellung:** Guarded Rollback liegt bereit; Ausführung nicht erfolgt.
- **PROD:** Nicht ausgeführt und nicht freigegeben.


### DB-MIG-2026-027 – Epic 23 Paket 1: Nominierungsvormerkung (DEV) – Ausführungsnachweis

- **Umgebung:** Supabase DEV – Projekt pzazqvvoruqnqhcorbwx.
- **Tatsächliche Ledger-Version:** `20261117123114`; **Migrationsname:** `epic23_nomination_reminder_foundation_dev`.
- **Status:** erfolgreich ausgeführt am 17.11.2026. Supabase meldete `success: true`.
- **Ausführungsweg:** Supabase-Migrationsdienst / apply migration.
- **Freigabe:** ausdrückliche Freigabe des Projektverantwortlichen im Chat vom 17.11.2026.
- **Ausgeführte Datei:** `supabase/migrations/20261117120000_epic23_nomination_reminder_foundation_dev.sql`.
- **Änderungsumfang:** zwei Tabellen, Indizes, RLS/Policies/Grants, zwei Nutzer-RPCs, zwei Triggerfunktionen und zwei Trigger.
- **Postflight:** RLS auf beiden Tabellen aktiv; SELECT-Policies vorhanden; Trigger aktiv; Create-/Cancel-RPCs SECURITY DEFINER, Owner postgres, fester search_path; EXECUTE nur authenticated, nicht anon/PUBLIC; Triggerfunktionen nicht direkt ausführbar; authenticated besitzt nur SELECT auf beiden Tabellen.
- **Datenbestand:** 0 Vormerkungen, 0 Audit-Zeilen direkt nach Installation.
- **Ergebnis:** Migration strukturell erfolgreich. Funktionale Positiv-/Negativtests und End-to-End-Verifikation stehen noch aus.
- **Rollback/Wiederherstellung:** guarded Rollback vorbereitet, nicht ausgeführt.
- **PROD:** nicht ausgeführt; unverändert.


### Ergänzung DB-MIG-2026-027 – Hotfix und Testresultat

- **Hotfix-Migration:** `20261117140000_epic23_nomination_reminder_fulfillment_hotfix_dev`, erfolgreich in DEV ausgeführt.
- **Datei:** `supabase/migrations/20261117140000_epic23_nomination_reminder_fulfillment_hotfix_dev.sql`.
- **Korrektur:** Fulfillment verwendet `clock_timestamp()` und inklusive Zeitgrenze `created_at <= v_now`, damit eine spätere Nominierung innerhalb derselben Transaktion die Vormerkung korrekt erfüllt.
- **Tests:** 14/14 ausgeführte Funktions-/RLS-Assertions bestanden nach Hotfix. Testtransaktionen wurden zurückgerollt.
- **Offen:** echte parallele Sessions, künstlich erzwungener Zwischenfehler/RPC-Rollback und separate Superadmin-/Nichtberechtigten-RPC-Rollenfälle.
- **Datenbestand:** keine Testdaten persistiert.


### DB-MIG-2026-027 – Ergänzende Konkurrenz- und Berechtigungstests

- Hotfix 2 `epic23_nomination_reminder_concurrency_hotfix_dev` erfolgreich ausgeführt.
- Zwei parallele Create-Aufrufe: genau eine Vormerkung erstellt; zweiter Aufruf abgelehnt.
- Paralleles Create und spätere Nominierung: nach Hotfix 2 Status korrekt fulfilled.
- Audit DELETE und TRUNCATE blockiert.
- Cross-Team-RPC-Aufruf eines nicht berechtigten Benutzers abgelehnt.
- Nicht durchgeführt: gezielter Fehler mitten in RPC-Transaktion und Superadmin-Kontext-Test.
- DEV-Testdaten mit append-only Audit-Historie verbleiben als klar markierte E23-TEMP-Datensätze in DEV; keine PROD-Daten betroffen.


### DB-MIG-2026-027 – Abschluss der offenen Paket-1-Prüfungen

- Gezielter Fehler im Audit-INSERT provoziert: Create-RPC rollte Reminder-INSERT und vorheriges Nominierungs-DELETE vollständig zurück. PASS.
- Superadmin-Zugriff mit explizitem user_team_context: Create-RPC erlaubt. PASS.
- Superadmin ohne expliziten Teamkontext: Zugriff abgelehnt. PASS.
- Temporärer Testtrigger und Testdaten wurden vollständig durch ROLLBACK entfernt.
- **Paket 1 Datenbankprüfungen abgeschlossen.** Frontend und PROD unverändert.


### DB-MIG-2026-028 – Epic 23 Paket 2: Read-API für offene Nominierungsvormerkungen

- **Migration:** 20261117160000_epic23_nomination_reminder_read_api_dev; erfolgreich in Supabase DEV ausgeführt.
- **RPC:** public.get_matchday_nomination_reminders(uuid).
- **Zweck:** offene Vormerkungen für einen Zielspieltag derselben Mannschaft liefern; Begründung enthalten.
- **Filter:** pending, Spieler noch verknüpft, Ausgangsspieltag liegt vor Zielspieltag, Spieler für Zielspieltag noch nicht nominiert.
- **Sicherheit:** SECURITY DEFINER, fester search_path, Owner postgres, EXECUTE nur authenticated; anon/PUBLIC ausgeschlossen; Mannschaftsrolle bzw. expliziter Superadmin-Teamkontext geprüft.
- **Tests:** spätere offene Vormerkung/Begründung, Ausgangsspieltag ausgeschlossen, bereits nominierter Zielspieler ausgeschlossen, Cross-Team-Aufruf abgelehnt – alle PASS.
- **Frontend:** unverändert. **PROD:** unverändert.
- **Dokumentation:** docs/E23_PAKET_02_DB_READ_API_2026-11-17.md und docs/E23_PAKET_02_DEV_TESTPLAN_2026-11-17.md.


### DB-MIG-2026-029 – Epic 23 Paket 3: Sichtbarkeit und Wiederöffnung (DEV)

- **Umgebung:** Supabase DEV – Projekt pzazqvvoruqnqhcorbwx.
- **Migration:** `20261117180000_epic23_nomination_reminder_reopen_dev`; Supabase meldete `success: true`.
- **Datei:** `supabase/migrations/20261117180000_epic23_nomination_reminder_reopen_dev.sql`.
- **Read-API:** offene Vormerkungen werden jetzt auch auf dem Ausgangsspieltag geliefert; bereits nominierte Spieler bleiben ausgeblendet.
- **Neue Triggerfunktion:** `epic23_reopen_nomination_reminder_on_delete()`; nach Löschen der erfüllenden Nominierung wird die Vormerkung wieder pending, sofern keine andere spätere Nominierung besteht.
- **Audit:** Wiederöffnung wird als `reopened` append-only protokolliert.
- **Sicherheit/Postflight:** Trigger aktiv; Funktionen SECURITY DEFINER, Owner postgres, fester search_path; Read-API EXECUTE nur authenticated; Triggerfunktion nicht direkt ausführbar für authenticated/anon.
- **Dossier:** `docs/E23_PAKET_03_DB_REOPEN_2026-11-17.md`.
- **Noch offen:** fachliche End-to-End-Tests für Sichtbarkeit, Erfüllung, Wiederöffnung und parallele spätere Nominierung.
- **PROD:** unverändert.


### DB-MIG-2026-030 – Epic 23 Hotfix: Audit-Aktion reopened zulassen (DEV)

- **Zielumgebung:** Supabase DEV – Projekt `pzazqvvoruqnqhcorbwx`.
- **Status:** erfolgreich in Supabase DEV ausgeführt am 17.11.2026; Supabase meldete `success: true`.
- **Tatsächliche Ledger-Version:** `20261117210545`; **Migrationsname:** `epic23_reopened_audit_action_hotfix_dev`.
- **Freigabe:** ausdrückliche Ausführungsfreigabe des Projektverantwortlichen im Chat am 17.11.2026.
- **Ursache:** Die bestehende CHECK-Constraint `matchday_nomination_reminder_audit_action_check` erlaubt nur `created`, `fulfilled`, `cancelled`. Paket 3 protokolliert zusätzlich `reopened`; der Audit-INSERT scheitert dadurch.
- **Read-only-Preflight:** Constraintdefinition live geprüft. Audit-Bestand vor Hotfix: `created=8`, `fulfilled=5`, `cancelled=2`; keine `reopened`-Zeilen und keine unbekannten Aktionswerte.
- **Änderungsumfang:** ausschließlich CHECK-Constraint auf vier Werte erweitern: `created`, `fulfilled`, `cancelled`, `reopened`. Keine Daten-, Trigger-, Funktions-, RLS- oder Frontendänderung.
- **Migration:** `supabase/migrations/20261117193000_epic23_reopened_audit_action_hotfix_dev.sql`.
- **Guarded Rollback:** `supabase/rollback/20261117193000_epic23_reopened_audit_action_hotfix_rollback.sql`; verweigert Rollback, sobald eine `reopened`-Historienzeile existiert.
- **Postflight:** `docs/E23_HOTFIX_REOPENED_AUDIT_VERIFICATION_2026-11-17.sql`.
- **Dossier:** `docs/E23_HOTFIX_REOPENED_AUDIT_2026-11-17.md`.
- **Postflight:** PASS. Constraint erlaubt exakt `created`, `fulfilled`, `cancelled`, `reopened`. Audit-Bestand unverändert: `created=8`, `fulfilled=5`, `cancelled=2`; noch keine `reopened`-Zeile.
- **Ergebnis:** Constraint korrigiert; keine bestehenden Audit-Zeilen oder sonstigen Daten geändert. iPhone-End-to-End-Wiederholung steht noch aus.
- **PROD / main:** unverändert; keine PROD-Ausführung oder Übernahme.

## 8. Epic 23 – PROD-Release (18.11.2026)

**Zielumgebung:** Supabase PROD, Projekt `qdugtpzgefpswnnqbusd`.  
**DEV-Referenz:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`.  
**Releaseweg:** sechs einzelne Migrationen in festgelegter Reihenfolge. Nach vollständigem Datenbank-Postflight erfolgt der reguläre PROD-Deploy von `develop` nach `main`; keine separate Frontend-Isolation.

### DB-MIG-2026-031 – E23 Paket 1 Foundation (PROD) – ausgeführt

- **Umgebung:** Supabase PROD (`qdugtpzgefpswnnqbusd`).
- **Freigabe:** ausdrückliche Freigabe des Projektverantwortlichen am 18.11.2026.
- **Migration:** `supabase/migrations/20261118100000_epic23_nomination_reminder_foundation_prod.sql`; Blob-SHA `0b88c8be696c4c251e5347e1d41f432a1452466b`.
- **Supabase-Ergebnis:** `success: true`.
- **Tatsächliche Ledger-Version:** `20261118070757`; **Migrationsname:** `epic23_nomination_reminder_foundation_prod`.
- **Änderungsumfang:** Tabellen `matchday_nomination_reminders` und `matchday_nomination_reminder_audit`, Indizes, RLS/SELECT-Policies, Create-/Cancel-RPCs, Audit-Schutztrigger und Fulfillment-Trigger.
- **Postflight:** beide Tabellen und beide Policies vorhanden; RLS auf beiden Tabellen aktiv; Fulfillment- und Audit-Guard-Trigger aktiv.
- **RPC-ACL:** Create-/Cancel-RPCs SECURITY DEFINER, fester search_path `pg_catalog, public, auth`; EXECUTE für `authenticated`, nicht für `anon` oder PUBLIC. Triggerfunktionen nicht direkt für Clientrollen ausführbar.
- **Datenbestand:** 0 Reminder- und 0 Audit-Zeilen. Keine bestehenden Spieler-, Spieltags- oder Nominierungsdaten verändert.
- **Advisor-Hinweis:** Security Advisor meldet projektweit bestehende SECURITY-DEFINER- und Policy-Warnungen; darunter die erwarteten neuen authentifizierten Create-/Cancel-RPCs. Keine pauschale Änderung bestehender Funktionen oder Policies vorgenommen.
- **Rollback:** nicht ausgeführt; keine automatische Rücknahme. Historie ist append-only zu behandeln.
- **PROD-Frontend / main:** unverändert; der reguläre Deploy folgt erst nach Abschluss aller sechs DB-Schritte.
- **Gegenstück DEV:** `20261117123114 epic23_nomination_reminder_foundation_dev` sowie nachfolgende DEV-Hotfixes erfolgreich.


### DB-MIG-2026-032 – E23 Fulfillment-Zeitkorrektur (PROD) – ausgeführt

- **Umgebung:** Supabase PROD (`qdugtpzgefpswnnqbusd`).
- **Freigabe:** Fortsetzung des ausdrücklich freigegebenen E23-PROD-Einzelreleaseprozesses am 18.11.2026.
- **Migration:** `supabase/migrations/20261118101000_epic23_nomination_reminder_fulfillment_hotfix_prod.sql`; Blob-SHA `b13d319be6644889ebcf48466ee365f2a0e80ba3`.
- **Supabase-Ergebnis:** `success: true`.
- **Tatsächliche Ledger-Version:** `20261118071012`; **Migrationsname:** `epic23_nomination_reminder_fulfillment_hotfix_prod`.
- **Änderungsumfang:** ausschließlich Funktionsdefinition `public.epic23_fulfill_nomination_reminder()` ersetzt. Zeitanker auf `clock_timestamp()`; Fulfillment-Bedingung auf `created_at <= v_now` geändert.
- **Postflight:** Funktionsdefinition enthält `clock_timestamp()` und inklusive Zeitbedingung; alte strikte Bedingung `created_at < v_now` nicht mehr vorhanden. Fulfillment-Trigger weiterhin genau einmal aktiv.
- **Sicherheit:** SECURITY DEFINER und fester search_path `pg_catalog, public, auth` erhalten; EXECUTE für `authenticated`, `anon` und PUBLIC nicht gewährt.
- **Datenbestand:** 0 Reminder- und 0 Audit-Zeilen; keine fachlichen Bestandsdaten verändert.
- **Rollback:** nicht ausgeführt; Wiederherstellung der vorherigen Funktionsdefinition nur nach gesonderter Prüfung.
- **PROD-Frontend / main:** unverändert.
- **Gegenstück DEV:** `20261117133211 epic23_nomination_reminder_fulfillment_hotfix_dev` erfolgreich.

### DB-MIG-2026-033 – E23 Konkurrenz-Hotfix (PROD) – ausgeführt

- **Umgebung:** Supabase PROD (`qdugtpzgefpswnnqbusd`).
- **Freigabe:** Fortsetzung des ausdrücklich freigegebenen E23-PROD-Einzelreleaseprozesses am 18.11.2026.
- **Migration:** `supabase/migrations/20261118102000_epic23_nomination_reminder_concurrency_hotfix_prod.sql`; Blob-SHA `c4f90604cd3081af20ec5f8f7838c580587b6397`.
- **Supabase-Ergebnis:** `success: true`.
- **Tatsächliche Ledger-Version:** `20261118102300`; **Migrationsname:** `epic23_nomination_reminder_concurrency_hotfix_prod`.
- **Änderungsumfang:** Funktionsdefinition `public.epic23_fulfill_nomination_reminder()` um denselben spielerbezogenen Advisory Transaction Lock ergänzt, den die Create-RPC bereits verwendet: `pg_advisory_xact_lock(hashtextextended(player_id::text,0))`.
- **Preflight:** Create-RPC verwendete den erwarteten Lock bereits; Fulfillment-Triggerfunktion hatte ihn vor Paket 3 noch nicht.
- **Postflight:** Beide Funktionen verwenden denselben Lock-Key. `clock_timestamp()` und `created_at <= v_now` aus Paket 2 erhalten. Fulfillment-Trigger weiterhin genau einmal vorhanden.
- **Sicherheit:** Fulfillment-Funktion bleibt SECURITY DEFINER mit festem search_path `pg_catalog, public, auth`; EXECUTE für `authenticated`, `anon` und PUBLIC nicht gewährt.
- **Datenbestand:** 0 Reminder- und 0 Audit-Zeilen; keine fachlichen Bestandsdaten verändert.
- **Rollback:** nicht ausgeführt; Wiederherstellung der vorherigen Funktionsdefinition nur nach gesonderter Prüfung.
- **PROD-Frontend / main:** unverändert.
- **Gegenstück DEV:** `20261117144900 epic23_nomination_reminder_concurrency_hotfix_dev` erfolgreich.

### DB-MIG-2026-034 – E23 Read-API (PROD) – ausgeführt

- **Umgebung:** Supabase PROD (`qdugtpzgefpswnnqbusd`).
- **Freigabe:** Fortsetzung des ausdrücklich freigegebenen E23-PROD-Einzelreleaseprozesses am 18.11.2026.
- **Migration:** `supabase/migrations/20261118103000_epic23_nomination_reminder_read_api_prod.sql`; Blob-SHA `dc5e09dfec258fef7f5c6968a36458917ee6bad9`.
- **Supabase-Ergebnis:** `success: true`.
- **Tatsächliche Ledger-Version:** `20261118104708`; **Migrationsname:** `epic23_nomination_reminder_read_api_prod`.
- **Änderungsumfang:** neue RPC `public.get_matchday_nomination_reminders(uuid)`; liefert offene Vormerkungen für einen Zielspieltag, sofern der Zielspieltag nach dem Ausgangsspieltag liegt und der Spieler dort noch nicht nominiert ist.
- **Berechtigung:** Trainer/Admin der Mannschaft oder Superadmin mit explizit ausgewähltem Teamkontext; fehlende Authentifizierung, ungültiger Spieltag und fehlende Berechtigung werden abgewiesen.
- **Postflight:** Funktion vorhanden; STABLE, SECURITY DEFINER, Owner postgres, fester search_path `pg_catalog, public, auth`; EXECUTE für `authenticated`, nicht für `anon` oder PUBLIC.
- **Datenbestand:** 0 Reminder- und 0 Audit-Zeilen; keine fachlichen Bestandsdaten verändert.
- **Fachliche Abgrenzung:** Anzeige bereits am Ausgangsspieltag ist noch nicht Bestandteil dieses Schritts und folgt in Paket 5.
- **Advisor:** Security Advisor meldet projektweit 58 SECURITY-DEFINER-Warnungen sowie bestehende Multiple-Permissive-Policy-Hinweise. Die neue Read-API ist eine bewusst authentifizierten Nutzern freigegebene SECURITY DEFINER RPC mit interner Teamkontextprüfung. Keine bestehenden Policies oder Funktionen außerhalb des Pakets geändert.
- **Rollback:** nicht ausgeführt; Entfernung der API nur nach Prüfung von Frontendabhängigkeiten.
- **PROD-Frontend / main:** unverändert.
- **Gegenstück DEV:** `20261117150608 epic23_nomination_reminder_read_api_dev` erfolgreich.

### DB-MIG-2026-035 – E23 Wiederöffnung (PROD) – ausgeführt

- **Umgebung:** Supabase PROD (`qdugtpzgefpswnnqbusd`).
- **Freigabe:** Fortsetzung des ausdrücklich freigegebenen E23-PROD-Einzelreleaseprozesses am 18.11.2026.
- **Migration:** `supabase/migrations/20261118104000_epic23_nomination_reminder_reopen_prod.sql`; Blob-SHA `582f8981ef09973419a60a280b8187353b08095e`.
- **Supabase-Ergebnis:** `success: true`.
- **Tatsächliche Ledger-Version:** `20261118104831`; **Migrationsname:** `epic23_nomination_reminder_reopen_prod`.
- **Änderungsumfang:** Read-API schließt jetzt den Ausgangsspieltag ein (`match_date >= source_matchday_date_snapshot`). Neuer AFTER DELETE Trigger auf `matchday_players` öffnet eine erfüllte Vormerkung wieder, wenn die erfüllende Nominierung entfernt wird und keine spätere Nominierung des Spielers verbleibt.
- **Parallelität:** Reopen-Trigger verwendet denselben spielerbezogenen Advisory Transaction Lock.
- **Postflight:** Reopen- und Fulfillment-Trigger jeweils genau einmal vorhanden; Read-API enthält Ausgangsspieltag; Reopen-Logik prüft nur erfüllte Vormerkungen, spätere Nominierungen und den Spieler-Lock. Triggerfunktion SECURITY DEFINER mit festem search_path; keine direkte Client-EXECUTE-Berechtigung.
- **Datenbestand:** 0 Reminder- und 0 Audit-Zeilen; keine fachlichen Bestandsdaten verändert.
- **Wichtige Reihenfolgeabhängigkeit:** Die bestehende Audit-Action-CHECK-Constraint erlaubt derzeit nur `created`, `fulfilled`, `cancelled`. Der neue Trigger schreibt `reopened`; daher ist die Wiederöffnungsfunktion bis zur unmittelbar folgenden Ausführung von Paket 6 noch nicht vollständig betriebsbereit. Bis Paket 6 abgeschlossen ist, keine Nominierungsabwahl auslösen, die eine Wiederöffnung erzeugen würde.
- **Rollback:** nicht ausgeführt; Trigger/Funktion nicht isoliert entfernen, ohne fachliche Historie und Folgeschritt zu prüfen.
- **PROD-Frontend / main:** unverändert.
- **Gegenstück DEV:** `20261117202735 epic23_nomination_reminder_reopen_dev` erfolgreich.

### DB-MIG-2026-036 – E23 Audit-Aktion reopened (PROD) – ausgeführt

- **Umgebung:** Supabase PROD (`qdugtpzgefpswnnqbusd`).
- **Freigabe:** Fortsetzung des ausdrücklich freigegebenen E23-PROD-Einzelreleaseprozesses am 18.11.2026.
- **Migration:** `supabase/migrations/20261118105000_epic23_reopened_audit_action_hotfix_prod.sql`; Blob-SHA `c5919cb7261c394f71bfd34aa2c8ac6b89a908e1`.
- **Supabase-Ergebnis:** `success: true`.
- **Tatsächliche Ledger-Version:** `20261118105730`; **Migrationsname:** `epic23_reopened_audit_action_hotfix_prod`.
- **Änderungsumfang:** ausschließlich CHECK-Constraint `matchday_nomination_reminder_audit_action_check` ersetzt. Zulässige Actions sind jetzt `created`, `fulfilled`, `cancelled`, `reopened`.
- **Preflight:** erwartete Constraint vorhanden; 0 Audit-Zeilen und 0 unerwartete Action-Werte; Reopen- und Fulfillment-Trigger jeweils genau einmal vorhanden.
- **Postflight:** Constraint-Definition enthält alle vier Actions einschließlich `reopened`; 0 unerwartete Action-Werte; 0 Audit- und 0 Reminder-Zeilen; beide Trigger weiterhin genau einmal vorhanden.
- **Datenbestand:** keine bestehenden Audit- oder Reminder-Zeilen verändert.
- **Rollback:** nicht ausgeführt; keine automatische Rücknahme.
- **PROD-Frontend / main:** unverändert.
- **Gegenstück DEV:** `20261117210545 epic23_reopened_audit_action_hotfix_dev` erfolgreich.

**Release-Dossier:** `docs/prod-release/E23_PROD_RELEASE_PREPARATION_2026-11-18.md`.


### DB-MIG-2026-037 – IMG-SEC-01 Paket 1A: Private Bildspeicherung (DEV)

- **Ausführungsdatensatz:** DEV – zwei aufeinanderfolgende Migrationen.
- **Datum/Uhrzeit:** 18.11.2026; Supabase-Ledger-Versionen 20261118180946 und 20261118181010. Eine gesonderte lokale Uhrzeit wurde vom Migrationswerkzeug nicht als Feld geliefert; die Ledger-Versionen werden nicht als bestätigte lokale Uhrzeit interpretiert.
- **Umgebung:** Supabase DEV, Projekt pzazqvvoruqnqhcorbwx.
- **Ausführungsweg:** Supabase-Migrationswerkzeug (apply_migration).
- **Freigabe:** ausdrückliche Nutzerfreigabe am 18.11.2026; vor Ausführung wurde die SQL-/Rollback-Fassung geprüft und die profiles_select-Policy bewusst unangetastet gelassen.
- **Zweck:** Fundament für private Spielerfotos und vorbereitete, kontextbezogene Leserechte für Profilbilder und Vereinsassets; bestehende öffentliche Bildanzeige bleibt bis zum Frontend-Cutover erhalten.
- **Betroffene Objekte:** players.photo_path; privater Storage-Bucket player-photos; Storage-Policies profile_avatars_select_authorized, club_assets_select_scoped, player_photos_select_team/insert/update/delete; Schema private; Helper private.can_manage_player_photo(uuid,uuid), private.can_view_club_asset(uuid), private.can_view_profile_avatar(uuid). Temporärer Helper public.can_view_player_photo(uuid) wurde im Härtungsschritt wieder entfernt.
- **Migration 1:** Version 20261118180946, Name img_sec_01_private_player_photo_storage_v1_0_0; SQL-Archiv: supabase/migrations/20261118180946_img_sec_01_private_player_photo_storage_v1_0_0.sql.
- **Migration 2:** Version 20261118181010, Name img_sec_01_harden_private_policy_helpers; SQL-Archiv: supabase/migrations/20261118181010_img_sec_01_harden_private_policy_helpers.sql.
- **Ergebnis:** beide apply_migration-Aufrufe meldeten success=true; beide Ledger-Einträge wurden read-only bestätigt.
- **Postflight:** player-photos.public=false; 0 Objekte; players.photo_path vorhanden; profiles_select vorhanden und unverändert; club_assets_select_scoped vorhanden; vier player_photos-Policies; drei Helper im private-Schema; keine entsprechenden Helper mehr im public-Schema.
- **Sicherheitsgrenze:** Security Advisor meldete nach Härtung 56 projektweite Warnungen zu ausführbaren SECURITY DEFINER-Funktionen (vorher 60). Die verbliebenen Findings betreffen andere Funktionen und wurden nicht global bearbeitet.
- **Bestehende Daten:** keine Dateien oder fachlichen Bilddaten verschoben, gelöscht oder migriert. profile-avatars und club-assets bleiben public=true. Bestehende Write-Policies dieser Buckets blieben unverändert. save_player_with_positions und photo_data blieben unverändert.
- **Rollback:** supabase/rollback/20261118180946_img_sec_01_private_player_photo_storage_rollback.sql. Guarded: bricht ab, wenn photo_path befüllt oder player-photos nicht leer ist; stellt die ursprüngliche club_assets_select_scoped-Policy aus dem DEV-Livebestand wieder her. Nicht ausgeführt.
- **PROD-Gegenstück:** Nicht ausgeführt; PROD unverändert.
- **Frontend/main:** keine Frontendänderung, kein Deploy, GitHub main unverändert.
- **Dokumentation:** docs/IMG_SEC_01_PAKET_1A_PRIVATE_IMAGE_STORAGE_2026-11-18.md; Postflight-SQL docs/IMG_SEC_01_PAKET_1A_POSTFLIGHT_2026-11-18.sql.
- **Nachweisgrenze:** Die auf develop abgelegten SQL-Dateien sind die versionierte Dokumentations-/Wiederherstellungsfassung der ausgeführten Payloads. Vor einer erneuten Ausführung oder einem PROD-Rollout müssen die Dateien bytegenau mit den tatsächlichen Ausführungs-Payloads abgeglichen und gegen das Ziel-Live-Schema geprüft werden. Keine erneute Ausführung aus dem Archiv heraus.


### DB-MIG-2026-038 – IMG-SEC-02 Profilbild-Berechtigungen und Pfadvalidierung (DEV vorbereitet)

- **Status:** Migrationsdatei erstellt und auf `develop` versioniert; ausdrücklich NICHT ausgeführt.
- **Datum:** 19.11.2026.
- **Zielumgebung:** ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`).
- **Migration:** `20261119120000_img_sec_02_profile_avatar_hardening_v1_0_0_dev`.
- **Datei:** `supabase/migrations/20261119120000_img_sec_02_profile_avatar_hardening_v1_0_0_dev.sql`.
- **Zweck:** einheitliche Profilbild-Pfadvalidierung, Schutz direkter Profiländerungen über Trigger, zusätzliche Prüfung der beiden Admin-Profil-RPCs und einheitliche Storage-Schreibberechtigungen für Eigenverwaltung, Mannschaftsadmins, Vereinsadmins und Superadmins im ausgewählten Kontext.
- **Berechtigungsumfang:** Trainer ohne Adminrolle dürfen keine fremden Profilbilder verwalten. Die SELECT-Policy bleibt unverändert.
- **Preflight:** prüft notwendige Tabellen, Funktionen, private-Schema-USAGE und die vorhandene Profilbild-SELECT-Policy; bei fehlenden Voraussetzungen wird abgebrochen.
- **Legacy-Kompatibilität:** Die Admin-RPCs erlauben einen bereits gespeicherten unveränderten Avatarwert auch dann weiter, wenn er einem älteren Pfadformat entspricht. Neue/geänderte Werte müssen das aktuelle Format erfüllen. Trigger und Storage-UPDATE/DELETE erhalten dieselbe kontrollierte Legacy-Kompatibilität.
- **Datenbestand:** read-only-Prüfung in DEV ergab 11 Profile und 0 nichtleere Avatarreferenzen. Es wurden keine Daten oder Storage-Objekte verändert.
- **Rollback:** keine Rollback-Ausführung; Migration nicht ausgeführt. Vor der späteren Freigabe ist eine passende Rücknahme-/Wiederherstellungsfassung zu erstellen und zu prüfen.
- **Ausführungsfreigabe:** Die Nutzerfreigabe vom 19.11.2026 bezog sich ausdrücklich auf das Erstellen der versionierten Migrationsdatei, nicht auf deren Ausführung.
- **PROD:** nicht betroffen; keine PROD-Migration vorbereitet oder ausgeführt.
- **Nächster Schritt:** statische Review-/Preflight-Prüfung der versionierten Datei und Erstellung des DEV-Testpakets. Vor `apply_migration` ist eine gesonderte ausdrückliche Ausführungsfreigabe einzuholen.
