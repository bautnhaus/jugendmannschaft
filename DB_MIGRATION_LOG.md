# Jugendmannschaft – SQL-Migrations- und Ausführungsprotokoll

**Stand:** 04.11.2026  
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


## DB-MIG-2026-003 – Ein-Mannschaft-Regel zentral absichern (Vorschlag, nicht ausgeführt)

- **Status:** Vorbereitung zur Prüfung; keine SQL-Ausführung und keine Freigabe zur Ausführung erfolgt.
- **Umgebung:** ausschließlich vorgesehen für Supabase DEV `pzazqvvoruqnqhcorbwx`.
- **PROD:** nicht geprüft, nicht geändert und nicht freigegeben.
- **Vorgeschlagene SQL-Quelle:** `docs/proposals/single-team-membership-guard/migration.sql`.
- **Read-only Verifikationsskript:** `docs/proposals/single-team-membership-guard/after_apply_verification.sql`.
- **Migrationsversion:** noch nicht vergeben. Nach einer späteren Freigabe wird die finale Version/Datei mit der tatsächlichen Ausführung synchronisiert.
- **Ausführungshistorie:** keine. Dieses Vorbereitungsdokument ist ausdrücklich kein Ausführungsnachweis.

### Anlass und Live-Befund vom 04.11.2026

Die Prüfung der tatsächlichen DEV-Definitionen ergab:
1. `admin_add_team_role(uuid,uuid,text)` prüft die Berechtigung des Handelnden, die Zielmitgliedschaft aber nicht auf eine bereits bestehende Zuordnung zu einer anderen Mannschaft und nicht auf die globale Rolle `super_admin`.
2. `admin_create_team(...)` verhindert bereits die Zuweisung eines Superadmins als Mannschaftsadmin, kontrolliert aber nicht, ob der ausgewählte Admin schon einer anderen Mannschaft angehört.
3. `admin_list_team_admin_candidates(uuid)` bietet auch bereits Mannschaftsmitgliedern die Auswahl als Admin einer neu anzulegenden Mannschaft an.
4. Der Vereinsmitglied-Bearbeitungsdialog zeigt die Rollenfelder mehrerer Mannschaften gleichzeitig.
5. `invite-trainer` ist in Supabase DEV weiterhin ACTIVE (Version 3), wird vom aktuellen Frontend aber nicht mehr aufgerufen. Der Endpunkt verwendet noch den älteren Einladungsablauf.
6. `add_team_member_by_email(text,text,uuid)` wird im aktuellen Frontend nicht aufgerufen und hat nach aktueller ACL-Prüfung kein EXECUTE-Recht für `authenticated`.

Die read-only Bestandsprüfung ergab aktuell:
- Benutzer mit Zuordnungen zu mehreren Mannschaften: **0**.
- Superadmins mit Mannschaftszuordnung: **0**.
- Widersprüchliche Vereins-/Mannschaftszuordnungen: **0**.

### Vorgeschlagene Änderung

- Neue SECURITY-DEFINER-Triggerfunktion `public.enforce_single_team_membership()` mit festem `search_path = pg_catalog, public, auth`. Sie prüft ausschließlich die Ein-Mannschaft-Regel und schließt Superadmins als Zielpersonen nicht aus.
- Trigger auf `team_members` und `team_member_roles` für INSERT sowie Änderungen an `user_id`/ `team_id`.
- Vor der Prüfung wird die Auth-Benutzerzeile mit `FOR UPDATE` gesperrt. Damit werden konkurrierende Schreibwege für denselben Benutzer serialisiert.
- Superadmins dürfen auf beiden Tabellen ebenfalls als Mannschaftsmitglieder geführt werden; ihre globalen Verwaltungsrechte bleiben davon getrennt.
- Bereits bestehende Zuordnungen in einer anderen Mannschaft werden auf beiden Tabellen abgewiesen.
- `admin_add_team_role` und `admin_create_team` erhalten zusätzliche Vorabprüfungen und verständliche Fehlermeldungen. Sie dürfen Superadmins als Zielpersonen berücksichtigen, wenn diese noch keiner anderen Mannschaft angehören.
- `admin_list_team_admin_candidates` bietet Vereinsmitglieder ohne Mannschaftszuordnung an. Ein globaler Superadmin wird nicht allein wegen seiner globalen Rolle ausgeschlossen.
- Ein Index auf `team_member_roles(user_id)` unterstützt die benutzerbezogene Prüfung.
- Der Vereinsmitglied-Dialog sperrt Rollenfelder anderer Mannschaften und prüft vor dem Speichern, dass höchstens eine Mannschaft ausgewählt ist.
- Die Edge Function `invite-member` soll bestehende Superadmin-Konten als Zielpersonen zulassen; die bisherige Ein-Mannschaft-Prüfung bleibt. Die alte Edge Function `invite-trainer` soll durch einen 410-Gone-Endpunkt ersetzt werden. Das verbundene Werkzeug kann Edge Functions nicht physisch löschen; der vorbereitete Endpunkt bleibt daher im Dashboard als ACTIVE sichtbar, nimmt aber keine Einladungsanfragen mehr an. Die JWT-Prüfung bleibt aktiviert.

### Sicherheits- und Datenabgrenzung

- Die zentrale Regel gilt für beide Zuordnungstabellen und schützt dadurch auch ältere oder interne Schreibwege, selbst wenn sie nicht vom Frontend aufgerufen werden.
- `admin_complete_member_invitation` besitzt bereits eine Zielbenutzer-Sperre und prüft eine zweite Mannschaft. Die bisherige Sperre gegen Superadmins als Zielperson wird im Vorschlag entfernt. Die neuen Trigger bilden zusätzlich eine gemeinsame Rückfallebene.
- Die Migration enthält eine Vorabprüfung und bricht ab, falls bereits Benutzer mehreren unterschiedlichen Mannschaften zugeordnet sind. Superadmins mit einer Mannschaftszuordnung sind ausdrücklich zulässig. Bestehende Datensätze werden nicht bereinigt.
- Bestehende RLS-Policies werden nicht geändert.
- Die Triggerfunktion erhält keine EXECUTE-Freigabe für `PUBLIC`, `anon` oder `authenticated`; sie ist ausschließlich trigger-intern.
- SQL, Frontend, Edge-Stub und Dokumentation liegen nur auf dem Review-Feature-Branch. Kein DEV-Deployment, keine Edge-Function-Aktualisierung und keine Datenbankänderung.

### Freigabe- und Ausführungsreihenfolge

1. Vollständiges SQL und Quellcode prüfen und ausdrücklich freigeben lassen.
2. Finale Migrationsdatei mit realer Migrationsversion anlegen und SQL in DEV ausführen.
3. SQL-Ausführung und Ergebnis sofort als echten Ausführungsnachweis dokumentieren.
4. Funktionsdefinitionen, Trigger, ACLs, Index und Bestandsintegrität read-only prüfen.
5. Frontend in `develop` übernehmen und DEV deployen.
6. Legacy Edge Function durch den vorbereiteten 410-Gone-Code ersetzen.
7. Security Advisor erneut prüfen und die vorgesehenen DEV-Praxistests durchführen.

**Bis zu einer separaten Freigabe bleibt der Status „Vorschlag – nicht ausgeführt“.**


### Fachliche Präzisierung 04.11.2026 – Mitgliedschaft und Verwaltungsrecht trennen

Die zuvor ergänzte vollständige Superadmin-Neutralität war zu weit gefasst und ist durch die ausdrückliche Nutzerentscheidung zurückgenommen. Verbindlich gilt jetzt:

- Höchstens eine tatsächliche Mannschaftszuordnung pro Benutzer, unabhängig von globalen/vereinsbezogenen Rollen.
- Ein Superadmin kann zugleich Vereinsmitglied, Vereinsadmin, Mannschaftsadmin und Trainer derselben Mannschaft sein.
- Ein Mannschaftsmitglied darf nicht zusätzlich einer zweiten Mannschaft zugeordnet werden – auch dann nicht, wenn es Superadmin oder Vereinsadmin ist.
- Superadmins und Vereinsadmins dürfen andere Mannschaften ihres ausgewählten/eigenen Berechtigungsbereichs verwalten, ohne dort selbst als Mitglied eingetragen zu sein.
- Die bisherige Live-Sperre in `invite-member` und `admin_complete_member_invitation` für Superadmins als Zielperson wird im Korrekturvorschlag entfernt. Die aktuelle DEV-Laufzeit bleibt bis zu einer späteren Freigabe unverändert.
- Es gibt keinen Trigger, der eine spätere Vergabe der Superadmin-Rolle an ein bereits zugeordnetes Mannschaftsmitglied verhindern soll.

Die korrigierte Umsetzung ist weiterhin nur Vorschlag im Review-Feature-Branch. Keine SQL-Ausführung, kein DEV-Deployment und keine PROD-Änderung.

