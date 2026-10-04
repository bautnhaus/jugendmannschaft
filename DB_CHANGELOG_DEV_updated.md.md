# Kaderkompass – Datenbankänderungsprotokoll DEV

**Stand:** 04.10.2026  
**Umgebung:** Supabase DEV  
**Zweck:** Dokumentation des nachweislich abgeglichenen DEV-Bestands als Grundlage für einen späteren kontrollierten PROD-Rollout. Dieses Protokoll ist kein vollständiger Schema-, RLS- oder Policy-Abgleich.

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
