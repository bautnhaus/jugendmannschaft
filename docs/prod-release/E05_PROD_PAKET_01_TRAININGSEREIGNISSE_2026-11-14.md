# KADAssist / E05 – PROD Release Paket 1
## Trainingsereignisse und Ereignis-Audit

- **Status:** Release-Entwurf erstellt – NICHT AUSFÜHREN
- **Zielumgebung:** Supabase PROD
- **Projekt-ID:** `qdugtpzgefpswnnqbusd`
- **Vorbereitung:** 14.11.2026
- **DEV-Referenz:** Supabase DEV `pzazqvvoruqnqhcorbwx`
- **DEV-Ausführungsdatum:** 08.11.2026
- **Tatsächlich ausgeführte DEV-SQL-Datei:** `docs/E05_PAKET_01_TRAINING_EVENTS_2026-11-08.sql`
- **DEV-Ausführungsprotokoll:** `docs/E05_PAKET_01_DEV_AUSFUEHRUNGSPROTOKOLL_2026-11-08.md`
- **PROD-SQL-Entwurf:** `docs/prod-release/E05_PROD_PAKET_01_TRAININGSEREIGNISSE_2026-11-14.sql`
- **PROD:** unverändert; keine Migration ausgeführt.

## 1. Ziel und Umfang

Das Paket legt ausschließlich das Datenbankfundament für Trainingsereignisse und deren Audit-Protokoll an:

1. `public.training_behavior_events`
2. `public.training_behavior_event_audit`
3. Eindeutigkeits- und Suchindizes
4. Append-only-Schutz des Audit-Protokolls
5. RLS und SELECT-Policies
6. Minimale API-Rechte: SELECT für `authenticated` und `service_role`; keine direkten Schreibrechte für API-Rollen

Es enthält keine Schreib-RPCs und löst noch keine Sperren aus. Das entspricht dem Umfang der tatsächlich in DEV ausgeführten Paket-1-SQL.

## 2. Verbindliche Herkunft des SQL

Es existieren zwei ähnlich benannte Paket-1-SQL-Dateien. Maßgeblich ist ausschließlich:

- `docs/E05_PAKET_01_TRAINING_EVENTS_2026-11-08.sql`
- Blob-SHA: `36bcc3969b1b3048757c6df3eda4668fbb1ba2aa`
- Das zugehörige DEV-Ausführungsprotokoll bestätigt die erfolgreiche Ausführung und Nachkontrollen.

Nicht verwenden:

- `docs/E05_PAKET_01_TRAININGSEREIGNISSE_2026-11-08.sql`
- Diese Datei trägt ausdrücklich den Status „Freigabe ausstehend – nicht ausgeführt“ und enthält eine abweichende Schemafassung (zusätzliche Snapshot-Felder sowie einen anderen Audit-Guard).

Der PROD-Entwurf übernimmt die fachlichen DDL-, Trigger-, RLS- und Grant-Anweisungen der tatsächlich ausgeführten DEV-Datei. Ergänzt wurde ein Vorbedingungs-Gate, das bei bereits vorhandenen Tabellen/Funktionen oder fehlenden Rollen-Hilfsfunktionen abbricht.

## 3. Read-only-Prüfung des PROD-Ausgangszustands

Prüfung gegen Supabase PROD am 14.11.2026:

| Prüfpunkt | Ergebnis |
|---|---|
| `training_behavior_events` vorhanden | Nein |
| `training_behavior_event_audit` vorhanden | Nein |
| `e05_reject_event_audit_mutation()` vorhanden | Nein |
| `is_team_member(uuid)` vorhanden | Ja |
| `has_selected_team_context(uuid)` vorhanden | Ja |
| Hilfsfunktionen SECURITY DEFINER | Ja |
| Fester search_path der Hilfsfunktionen | `pg_catalog, public` |
| Bestehende E05-Indizes/Policies/Trigger auf den beiden Tabellen | Keine, da Tabellen nicht vorhanden |
| Bestehende PROD-E05-Migrationsregistrierung | Keine |

Die beiden Hilfsfunktionen wurden anhand ihrer gespeicherten Definitionen und Routine-Rechte geprüft. Sie sind für `authenticated` ausführbar; ihre vorhandenen Definitionen werden von Paket 1 nicht verändert.

## 4. Schemaabgleich und wichtige Abgrenzung

Das tatsächlich ausgeführte Paket 1 legt die Ereignistabellen ohne die später ergänzten Actor-Snapshot-Spalten an.

Insbesondere ist `training_behavior_event_audit.changed_by_snapshot` **nicht Bestandteil dieses Pakets**. Diese Spalte wurde im späteren E05-Verlauf ergänzt und muss im chronologischen Release an der entsprechenden späteren Stelle berücksichtigt werden. Sie wird hier nicht vorgezogen.

Ebenso werden keine Tabellen für Sperren oder Ausnahmen angelegt. Diese gehören zu den nachfolgenden Paketen.

## 5. Datenwirkung und Bestandschutz

- Paket 1 legt zwei neue Tabellen an.
- Es schreibt oder migriert keine bestehenden fachlichen Datensätze.
- Es ändert keine bestehenden Tabellen, Rollen, Funktionen oder Policies.
- Die neuen Tabellen starten leer.
- Die Migration ist absichtlich nicht idempotent. Ein erneuter Lauf darf nicht versucht werden, bevor der tatsächliche Datenbankzustand read-only geprüft wurde.

## 6. Vorbedingungen unmittelbar vor einer späteren Ausführung

Vor einer separaten Freigabe und Ausführung erneut prüfen:

1. Projekt-ID entspricht exakt `qdugtpzgefpswnnqbusd`.
2. Beide E05-Tabellen und die Audit-Guard-Funktion sind weiterhin nicht vorhanden.
3. Die beiden Hilfsfunktionen existieren weiterhin mit erwarteter Signatur und sicherem Ausführungskontext.
4. Es gibt keine unregistrierten oder teilweise angelegten E05-Objekte.
5. Der SQL-Blob/Dateiinhalt entspricht dem freigegebenen Release-Artefakt.
6. Ein aktueller PROD-Backup-/Recovery-Stand ist vorhanden und geprüft.

Das Vorbedingungs-Gate im SQL ist eine zusätzliche Sicherung und ersetzt diese Freigabeprüfung nicht.

## 7. Nachkontrollen nach einer späteren Ausführung

Die Ausführung gilt erst nach dokumentierter Prüfung als erfolgreich. Mindestens zu prüfen:

- Beide Tabellen vorhanden; Spalten, Constraints und Foreign Keys entsprechen dem freigegebenen SQL.
- Alle erwarteten Indizes vorhanden (inklusive Primary-Key-Indizes).
- Audit-Trigger für UPDATE/DELETE und TRUNCATE vorhanden.
- RLS auf beiden Tabellen aktiviert.
- Je Tabelle genau die vorgesehene SELECT-Policy vorhanden.
- `authenticated` hat SELECT, aber kein INSERT/UPDATE/DELETE.
- `anon` hat keine Tabellenrechte.
- `service_role` hat SELECT wie im DEV-Paket vorgesehen.
- Audit-Guard-Funktion ist für `public`, `anon`, `authenticated` und `service_role` nicht ausführbar.
- Die Tabellen sind neu und enthalten keine unerwarteten Datensätze.
- Migrationseintrag und Ausführungsprotokoll sind vorhanden.

Das DEV-Protokoll enthält die konkreten erwarteten Rechteprüfungen (`auth_select=true`, `auth_insert=false`, `anon_select=false`).

## 8. Rollback- und Wiederherstellungsstrategie

Paket 1 ist Grundlage für nachfolgende E05-Pakete. Ein isoliertes Löschen der beiden Tabellen ist nach Installation abhängiger Pakete nicht zulässig.

- Vor nachfolgenden Paketen ist die Rückwärts-Abhängigkeitskette zu berücksichtigen.
- Ein Rückbau von Paket 1 ist nur nach Rückbau aller davon abhängigen E05-Objekte zulässig.
- Vor einem Rückbau sind alle Ereignis- und Auditdaten zu sichern und fachlich zu bewerten.
- Auditdaten dürfen nicht stillschweigend gelöscht werden.
- Ein ausführbares Rollback wird erst zusammen mit dem vollständigen E05-Abhängigkeits- und Datenwiederherstellungsplan finalisiert.

Es wurde kein Rollback ausgeführt oder getestet. Dieser Abschnitt ist ein Wiederherstellungsplan, keine Ausführungserlaubnis.

## 9. Freigabestatus

- [x] Tatsächlich ausgeführte DEV-SQL-Quelle identifiziert
- [x] DEV-Ausführungsprotokoll geprüft
- [x] PROD-Migrationshistorie read-only geprüft
- [x] PROD-Objektbestand read-only geprüft
- [x] PROD-Hilfsfunktionen und Ausführungskontext geprüft
- [x] PROD-spezifisches Vorbedingungs-Gate ergänzt
- [x] Release-SQL-Entwurf erstellt
- [ ] SQL in einer isolierten PostgreSQL-Prüfumgebung ausgeführt/geparst
- [ ] Vollständiger Rollback-/Wiederherstellungsweg ausführbar verifiziert
- [ ] Finale fachliche/technische PROD-Freigabe erteilt
- [ ] In PROD ausgeführt
- [ ] Nachkontrollen bestanden und protokolliert

**Aktueller Status: vorbereitet, aber noch nicht ausführungsbereit und nicht freigegeben.**

Keine Änderung an Supabase DEV, Supabase PROD oder GitHub `main` wurde durch diese Vorbereitung vorgenommen. Die beiden neuen Dokumente liegen ausschließlich auf GitHub `develop`.
