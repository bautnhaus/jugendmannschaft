# Kaderkompass – Datenbankänderungsprotokoll DEV

**Stand:** 09.10.2026  
**Umgebung:** Supabase DEV  
**Zweck:** Dokumentation des nachweislich abgeglichenen DEV-Bestands als Grundlage für einen späteren kontrollierten PROD-Rollout. Dieses Protokoll dokumentiert die bekannten DEV-Änderungen bis 09.10.2026; es ist kein vollständiger Schema-, RLS- oder Policy-Abgleich.

## DB-DEV-001 – Schutz des letzten Administrators (E16.2)

- **Status:** In DEV implementiert und funktional getestet.
- **Tabelle:** `public.team_members`
- **Funktion:** `public.prevent_last_team_admin_removal()`
- **Trigger:** `prevent_last_team_admin_removal`
- **Ereignisse:** `AFTER DELETE OR UPDATE`, je Zeile
- **Triggertyp:** Constraint-Trigger, `DEFERRABLE INITIALLY DEFERRED`
- **Aktivierung:** aktiv (`tgenabled = 'O'`, immer aktiviert)
- **Funktion:** `SECURITY DEFINER`, `search_path` = `pg_catalog, public`
- **Rechte:** EXECUTE für `PUBLIC`, `anon` und `authenticated` nicht gewährt. ACL bestätigt EXECUTE für `postgres` und `service_role`.

### Zweck und Funktionsweise

Die Datenbank verhindert, dass die letzte Admin-Mitgliedschaft eines bestehenden Teams gelöscht oder herabgestuft wird. Die Regel ist unabhängig von Frontend-Prüfungen. Nicht-Admin-Mitgliedschaften werden nicht geprüft. Bei einem UPDATE, bei dem dieselbe Mitgliedschaft im selben Team Admin bleibt, wird die Prüfung übersprungen. Die Funktion sperrt die Teamzeile mit `FOR UPDATE`, prüft, ob das Team noch existiert, und lässt eine vollständige Teamlöschung zu. Andernfalls prüft sie, ob am Transaktionsende noch mindestens ein Admin vorhanden ist. Falls nicht, löst sie eine Exception mit SQLSTATE `23514` und folgender Meldung aus:

> Die letzte Admin-Mitgliedschaft einer Mannschaft kann nicht entfernt oder herabgestuft werden.

### In DEV ausgelesene Triggerdefinition

```sql
CREATE CONSTRAINT TRIGGER prevent_last_team_admin_removal
AFTER DELETE OR UPDATE ON public.team_members
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION prevent_last_team_admin_removal();
```

### In DEV ausgelesene Funktionsdefinition

```sql
CREATE OR REPLACE FUNCTION public.prevent_last_team_admin_removal()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
    v_team_exists boolean;
    v_admin_exists boolean;
BEGIN
    IF OLD.role IS DISTINCT FROM 'admin' THEN
        RETURN NULL;
    END IF;

    IF TG_OP = 'UPDATE'
       AND NEW.role = 'admin'
       AND NEW.team_id = OLD.team_id THEN
        RETURN NULL;
    END IF;

    PERFORM 1
    FROM public.teams
    WHERE id = OLD.team_id
    FOR UPDATE;
    v_team_exists := FOUND;

    IF NOT v_team_exists THEN
        RETURN NULL;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.team_members
        WHERE team_id = OLD.team_id
          AND role = 'admin'
    )
    INTO v_admin_exists;

    IF NOT v_admin_exists THEN
        RAISE EXCEPTION
            'Die letzte Admin-Mitgliedschaft einer Mannschaft kann nicht entfernt oder herabgestuft werden.'
            USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$function$;
```

### Verifikation und Testumfang

1. `pg_get_functiondef()` bestätigte die Funktionsdefinition.
2. Die Triggerabfrage bestätigte `AFTER DELETE OR UPDATE`, Constraint-Trigger, `DEFERRABLE`, `INITIALLY DEFERRED` und Aktivierung `O`.
3. Die Rechteabfrage bestätigte `SECURITY DEFINER`, keine EXECUTE-Rechte für `PUBLIC`, `anon` und `authenticated`; die ACL zeigte `postgres=X/postgres` und `service_role=X/postgres`.
4. Ein realer Löschversuch des einzigen Admin-Kontos über die DEV-App wurde mit der erwarteten Meldung abgewiesen.
5. Die anschließende Kontrolle bestätigte, dass alle drei Teammitgliedschaften erhalten blieben; Testrollen wurden wieder auf zwei Admins und einen Trainer gesetzt.
6. Ein gesonderter Parallelitätstest mit gleichzeitig laufenden Transaktionen wurde **nicht** durchgeführt. Die `FOR UPDATE`-Sperre ist vorhanden, ihre Wirkung unter tatsächlicher Konkurrenz ist aber nicht separat nachgewiesen.

**PROD:** Nicht übertragen. Vor einem Rollout sind Funktions-, Trigger-, Rechte- und Schema-Bestand in PROD separat zu prüfen. Diese Dokumentation ist ein Bestandsnachweis, keine freigegebene ausführbare Migration. Eine spätere Migration benötigt Review, DEV-Abgleich und ausdrückliche Freigabe.

## DB-DEV-002 – Erweiterung der Spielerstammdaten (E03)

- **Umgebung:** DEV
- **Status:** Spalten und Constraints direkt in DEV abgefragt
- **Tabelle:** `public.players`
- **Felder:** `birth_year` (Geburtsjahr, kein vollständiges Geburtsdatum) und `preferred_foot` (bevorzugter Fuß)
- **PROD:** Separat zu prüfen; keine PROD-Migration bestätigt.

### Tatsächliche Spaltenstruktur aus DEV

| Spalte | Datentyp | NULL erlaubt | Standardwert |
|---|---|---|---|
| `id` | `uuid` | Nein | `gen_random_uuid()` |
| `team_id` | `uuid` | Nein | keiner |
| `name` | `text` | Nein | keiner |
| `level` | `text` | Ja | keiner |
| `active` | `boolean` | Nein | `true` |
| `created_at` | `timestamp with time zone` | Nein | `now()` |
| `updated_at` | `timestamp with time zone` | Nein | `now()` |
| `photo_data` | `text` | Ja | keiner |
| `first_name` | `text` | Ja | keiner |
| `last_name` | `text` | Ja | keiner |
| `notes` | `text` | Ja | `''::text` |
| `birth_year` | `integer` | Ja | keiner |
| `preferred_foot` | `text` | Ja | keiner |

### Tatsächliche Constraints aus DEV

| Constraint | Typ | Regel |
|---|---|---|
| `players_birth_year_check` | CHECK | `birth_year IS NULL OR (birth_year >= 1900 AND birth_year <= EXTRACT(year FROM CURRENT_DATE)::integer)` |
| `players_level_check` | CHECK | `level IS NULL OR level = ANY (ARRAY['Einsteiger', 'Fortgeschritten', 'Stark', 'Profi'])` |
| `players_preferred_foot_check` | CHECK | `preferred_foot IS NULL OR preferred_foot = ANY (ARRAY['links', 'rechts', 'beidfüßig'])` |
| `players_team_id_fkey` | FOREIGN KEY | `team_id` → `teams(id) ON DELETE CASCADE` |
| `players_pkey` | PRIMARY KEY | `PRIMARY KEY (id)` |

Die verbindliche Level-Reihenfolge ist **Einsteiger → Fortgeschritten → Stark → Profi**. Diese Begriffe entsprechen der vom Nutzer bestätigten Frontend-Terminologie und dem in DEV ausgelesenen CHECK-Constraint. Eine Datenbankänderung der Level-Bezeichnungen ist daher nicht erforderlich. Die vollständige Prüfung aller Frontend-Verwendungen wurde in diesem Schritt nicht wiederholt.

### Nachweisgrenze

Spalten und Constraints sind als aktueller DEV-Bestand ausgelesen. Die historische Reihenfolge und der exakte DDL-Text der ursprünglichen E03-Migrationen sind damit nicht rekonstruiert. Dieser Abschnitt ist daher ein Bestandsnachweis, kein ausführbares SQL-Migrationsskript. Vor einer PROD-Übernahme sind historische Änderungen soweit verfügbar zu rekonstruieren und DEV und PROD separat abzugleichen.

## Änderungsregister

| ID | Änderung | Umgebung | Status | PROD |
|---|---|---|---|---|
| DB-DEV-001 | Letzten Team-Admin gegen Entfernen/Herabstufen absichern (E16.2) | DEV | Implementiert und funktional getestet; Parallelitätstest offen | Nicht übertragen |
| DB-DEV-002 | Spielerprofil um Geburtsjahr und bevorzugten Fuß erweitert (E03); Spalten und Constraints abgeglichen | DEV | Bestandsdefinitionen abgefragt; historische Migration nicht vollständig rekonstruiert | Separat zu prüfen |

## Pflegekonvention

Jede Datenbankänderung erhält eine eindeutige ID, Datum, Umgebung, betroffene Objekte, Zweck, versioniertes SQL, Ausführungsergebnis, Tests und Rolloutstatus. DEV und PROD sind getrennt zu dokumentieren. Eine DEV-Änderung gilt nie automatisch als in PROD angewendet. Keine Zugangsdaten, Tokens oder Service-Role-Keys dokumentieren.


## DB-DEV-003 – E07 Trainingsverwaltung / Trainingsserien und Rückmeldungen

- **Umgebung:** DEV
- **Status:** Migration ausgeführt; Kernfunktionalität im DEV getestet
- **PROD:** Nicht übertragen

### Zweck

Erweiterung der Trainingsverwaltung um Trainingsserien, zusätzliche Termindaten und die persistente Erfassung geplanter Spieler-Rückmeldungen.

### Betroffene Objekte

- `public.training_series`
- `public.trainings`
- `public.training_responses`

### Ausgeführte Datenbankänderungen

`public.training_series` wurde als eigene Tabelle angelegt. Dokumentiert sind insbesondere:

- `id` als UUID-Primärschlüssel
- `team_id` mit Bezug zu `teams`
- `start_date`, `end_date`
- `start_time`
- `duration_minutes`
- `weekdays`
- `location`
- `created_at`, `updated_at`
- Prüfungen für Datumsbereich, Dauer und Wochentage

`public.trainings` wurde um folgende Felder erweitert:

- `start_time`
- `duration_minutes`
- `location`
- `status` mit Standard `planned`
- `note`
- `series_id` mit Bezug zu `training_series` und `ON DELETE SET NULL`

Für `training_series` wurden RLS sowie Select/Insert/Update/Delete-Policies auf Basis der Teammitgliedschaft eingerichtet und verifiziert.

Zusätzlich wurde `public.training_responses` angelegt mit:

- `training_id`
- `player_id`
- `status` mit `open`, `yes`, `no`
- `created_at`

Der Primärschlüssel besteht aus `training_id` und `player_id`. Für die Tabelle wurden Select/Insert/Update/Delete-Policies eingerichtet.

### Ausführung / Verifikation

Die E07-Migration wurde in DEV erfolgreich ausgeführt. Als sichtbarer Policy-Nachweis wurden die vier Policies von `training_series` für Delete, Insert, Select und Update bestätigt.

Die Spalten und Policies von `training_responses` wurden anschließend kontrolliert.

### Funktionaler DEV-Test

Über die DEV-App wurden Spieler-Rückmeldungen geändert. Anschließend wurde der aktuelle Frontendstand erneut geladen bzw. aktualisiert. Die gespeicherten Zu-/Absagen blieben erhalten.

Der zuletzt dokumentierte Testbestand enthielt 9 gespeicherte Rückmeldungen:

- 5 × `yes`
- 4 × `open`
- 0 × `no`

Dieser Bestand blieb beim anschließenden Frontend-Test unverändert.

Das Suchfeld der Trainings-Spielerliste wurde anschließend hinsichtlich der Darstellung auf iPhone Portrait und Landscape korrigiert und erneut geprüft.

### Offener technischer Punkt

Für `training_series.updated_at` ist weiterhin nicht abschließend verifiziert, ob ein `set_updated_at`-Trigger besteht.

Die Migration ist erfolgreich ausgeführt. Die Constraint-Erstellung ist nicht als beliebig wiederholbare Migration zu behandeln; vor einer erneuten Ausführung muss der tatsächliche DEV-Stand berücksichtigt werden.

- Nachtrag 29.10.2026: Das Vereinswappen wird nun nach erfolgreichem Upload sowohl in der Vereinsliste als auch im Vereinsdetail angezeigt. Die Darstellung verwendet `object-fit: contain` und einen transparenten Hintergrund, damit transparente PNGs nicht zugeschnitten oder mit einer deckenden Fläche überlagert werden. Commit: `0e1ca64e89ff4f56973ff6755b3e3ec01b847ecf` (Anzeige), danach wurden die Formular-Handler im selben Frontend wiederhergestellt und die Inline-JavaScript-Syntax erneut geprüft; Commit `158072225c9aecd071c515fb55eab95b943dc3b6`.

### PROD-Rollout

Keine Änderung an PROD. Vor einer PROD-Übernahme sind die exakten ausgeführten SQL-Anweisungen, der DEV-Teststatus und der PROD-Bestand getrennt abzugleichen.

## Änderungsregister – Ergänzung

| ID | Änderung | Umgebung | Status | PROD |
|---|---|---|---|---|
| DB-DEV-003 | E07: Trainingsserien, zusätzliche Trainingsfelder und persistente Trainings-Rückmeldungen | DEV | Migration ausgeführt; Kernfunktionalität und Persistenz im DEV getestet | Nicht übertragen |


## DB-DEV-004 – E07 Serienname und individuelle Termin-Overrides

- **Datum:** 09.10.2026 (Dokumentationsdatum; SQL-Ausführung zuvor in DEV bestätigt)
- **Umgebung:** Supabase DEV
- **Status:** SQL erfolgreich ausgeführt (`Success. No rows returned` laut Nutzer)
- **PROD:** Nicht übertragen

### Zweck

Seriennamen ermöglichen und individuell abweichende Werte eines Einzeltermins explizit kennzeichnen, damit spätere Serienänderungen individuelle Anpassungen respektieren können.

### Betroffene Objekte

- `public.training_series.name`
- `public.trainings.overrides`
- Constraint `trainings_overrides_object_chk`

### Ausgeführtes SQL

```sql
ALTER TABLE public.training_series
  ADD COLUMN name text;

ALTER TABLE public.trainings
  ADD COLUMN overrides jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.trainings
  ADD CONSTRAINT trainings_overrides_object_chk
  CHECK (jsonb_typeof(overrides) = 'object');
```

### Verifikation und fachliche Verwendung

- Die Ausführung in DEV wurde mit `Success. No rows returned` bestätigt.
- `overrides` ist ein JSONB-Objekt mit Standardwert `{}`; ein Beispiel für einen individuellen Ortswert ist `{"location": true}`.
- Wird ein Feld auf den Serienstandard zurückgesetzt, muss der zugehörige Override entfernt werden.
- Der Name der Serie kann als Standardname der zugehörigen Termine angezeigt werden; ein individuell abweichender Terminname soll bei Serienänderungen erhalten bleiben.
- Die Frontendlogik für Serienänderungen und die Anzeige des Trainingsnamens wurde anschließend mit der DEV-App getestet.

### PROD-Rollout

Nicht übertragen. Vor PROD sind die vorhandenen Spalten/Constraints separat zu prüfen und die Änderungen kontrolliert als Release-Migration zu übernehmen. Nicht blind erneut ausführen, da das `ADD CONSTRAINT` nicht mit `IF NOT EXISTS` abgesichert ist.

## Änderungsregister – Ergänzung

| ID | Änderung | Umgebung | Status | PROD |
|---|---|---|---|---|
| DB-DEV-004 | E07: Serienname und JSONB-Overrides für individuelle Terminwerte | DEV | SQL-Ausführung und anschließender fachlicher DEV-Test bestätigt | Nicht übertragen |


## DB-DEV-005 – Vereins- und Mannschaftsanlage (2026-10-29)

**Umgebung:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`  
**Status:** Migration ausgeführt; Schema-/Rechteprüfung bestätigt.  
**PROD:** Nicht übertragen.

### Ausgeführte Migrationen

- `20261029045927_club_team_creation_and_club_context_20261029`
- `20261029050011_club_team_creation_20261029`

Beide Einträge wurden in `supabase_migrations.schema_migrations` nachgewiesen. Die zweite Ausführung war idempotent ausgelegt und bestätigte denselben Zielzustand.

### Schemaänderungen

**`public.clubs`**
- `short_name`, `crest_path`
- Heimspielstätte: `home_venue_name`, `home_venue_street`, `home_venue_postal_code`, `home_venue_city`, `home_venue_country`
- `training_location_differs`
- Abweichender Trainingsort: `training_venue_name`, `training_venue_street`, `training_venue_postal_code`, `training_venue_city`, `training_venue_country`
- Check-Constraint: bei abweichendem Trainingsort müssen alle Adressfelder vollständig sein.

**`public.teams`**
- `birth_cohorts`
- `abbreviation`

**Kontext und RPCs**
- Neue Tabelle `public.user_club_context`, RLS aktiviert, kein direkter Zugriff für `anon` oder `authenticated`.
- Neue Funktionen: `can_manage_club_context`, `select_club_context`, `get_selected_club_context`, `clear_club_context`, `admin_create_club`, `admin_update_club_crest`.
- `admin_create_team` erweitert um Jahrgänge, Kürzel und optionale Saison. Ein Super Admin wird dabei nicht automatisch als Vereins- oder Mannschaftsmitglied eingetragen; die Erstellung ist auf den ausdrücklich ausgewählten Vereinskontext begrenzt.
- Bei einer angegebenen Saison wird diese als aktive Saison der neuen Mannschaft angelegt.

**Storage**
- Bucket `club-assets`, öffentliches Lesen der Wappen, Dateigrößenlimit 2 MiB, erlaubte MIME-Typen PNG/JPEG/WebP.
- Upload, Lesen durch authentifizierte Nutzer, Aktualisierung und Löschen sind über Policies auf berechtigte Vereinsadmins bzw. den ausgewählten Super-Admin-Vereinskontext begrenzt.

### Nachprüfung

- Spalten in `clubs` und `teams` vorhanden.
- `user_club_context` vorhanden und RLS aktiviert.
- Neue administrative RPCs: EXECUTE für `authenticated`, nicht für `anon` oder `PUBLIC`; Berechtigungsprüfungen sind in den Funktionen enthalten.
- Storage-Bucket und vier Policies für SELECT/INSERT/UPDATE/DELETE vorhanden.
- Keine Vereins- oder Mannschaftsdatensätze wurden durch die Migration angelegt.
- Security Advisor meldet unter anderem den erwarteten Hinweis, dass `user_club_context` RLS ohne direkte Policies hat (Zugriff erfolgt absichtlich nur über SECURITY DEFINER-RPCs). Außerdem gibt es bereits bestehende Hinweise zu SECURITY DEFINER-Funktionen und mehrfach permissiven Policies; diese sind separat zu bewerten und wurden nicht pauschal geändert.

### Frontend

- DEV-Branch `develop`: Vereinsanlage und Mannschaftsanlage ergänzt.
- Syntaxprüfung der beiden Inline-Skripte: bestanden (das externe ES-Modul wurde für die lokale Parserprüfung ausgeklammert).
- Browser-/Praxistest noch ausstehend; insbesondere Formularablauf, Wappen-Upload, Saisonverknüpfung und Rollenverhalten müssen in DEV getestet werden.

### PROD-Rollout

Nicht übertragen. Für PROD ist eine separate, geprüfte Release-Migration erforderlich. Die zwei DEV-Migrationseinträge sind vor einem PROD-Cutover nicht blind auszuführen; das Ziel-Schema und Funktionssignaturen müssen zuerst geprüft werden.
