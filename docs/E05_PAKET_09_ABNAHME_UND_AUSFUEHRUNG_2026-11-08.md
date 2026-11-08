# E05 – Paket 9: Manuelle Sperren- und Kartenkorrektur

- **Status:** In Supabase DEV umgesetzt; Funktionstests bestanden
- **Zielumgebung:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`
- **Branch:** `develop`
- **PROD:** ausdrücklich nicht ausgeführt
- **Fachliche Freigabe:** Nutzerfreigabe zur Umsetzung in DEV erteilt
- **Abnahme:** DEV-Funktionstests einschließlich Korrekturmigrationen erfolgreich

## 1. Zweck und Umfang

Paket 9 ergänzt die manuelle Korrektur einer offenen Spielersperre sowie die Korrektur (Stornierung/Wiederherstellung) fehlerhafter gelber und roter Kartenereignisse.

Enthalten sind:
- `correct_suspension(uuid,uuid,text)`: manuelle Umzuordnung einer offenen Sperre auf einen anderen zulässigen zukünftigen Spieltag derselben Mannschaft und Saison.
- `correct_training_behavior_event(uuid,text,text)`: Stornierung eines Kartenereignisses (`voided`) bzw. Wiederherstellung (`active`).
- Interne Berechtigungs- und Abstimmungsfunktionen.
- Erweiterung der automatischen Sperrenzuordnung, damit gültige manuelle Zielzuordnungen erhalten bleiben.
- Audit-Snapshots des handelnden Trainers.

## 2. Verbindliche Regeln

1. Nur Trainer/Admin des betroffenen Teams oder Superadmin im ausgewählten Teamkontext.
2. Begründung ist Pflicht.
3. Nur offene Sperren können manuell umgeordnet werden.
4. Zielspieltag muss geplant, zukünftig, derselben Mannschaft und Saison zugeordnet und nach Vereins-/Teamkonfiguration sperrenrelevant sein.
5. Aktive Sperrausnahme für den Zielspieltag schließt diesen aus.
6. Eine zweite offene Sperre desselben Spielers darf nicht bereits demselben Zielspieltag zugeordnet sein.
7. Gültige manuelle Zuordnungen bleiben bei automatischen Neuberechnungen bestehen.
8. Wird eine manuelle Zielzuordnung ungültig (z. B. Absage oder nicht mehr relevante Spielart), wird sie beim nächsten regulären Aufruf des kanonischen Zuordnungs-RPC freigegeben und neu zugeordnet.
9. Kein zusätzlicher Matchday-Trigger: Vermeidung einer umgekehrten Zeilensperren-Reihenfolge und möglicher Deadlocks.
10. Bereits abgeleistete Sperren werden nicht rückwirkend geändert oder wieder geöffnet.
11. Kartenereignisse werden nicht gelöscht. Statuswechsel und Audit erfolgen atomar.
12. Keine direkten Tabellen-Schreibrechte werden erteilt.

## 3. Tatsächliche DEV-Migrationen

| Supabase-Version | Migrationsname | Inhalt | Status |
|---|---|---|---|
| `20261108212745` | `e05_package_09_manual_suspension_and_card_correction_v6` | Paket 9 v6 – Spalten, interne Helfer, Zuordnungs-RPC, Korrektur-RPCs | Erfolgreich |
| `20261108213035` | `e05_package_09_fix_card_correction_player_lock` | Fehlerkorrektur: Spielerzeilensperre in Kartenkorrektur von SELECT auf PERFORM geändert | Erfolgreich |
| `20261108213211` | `e05_package_09_fix_card_correction_authenticated_grant` | EXECUTE-Recht für `authenticated` nach Funktionskorrektur ausdrücklich wiederhergestellt | Erfolgreich |

Alle drei Versionen sind in der DEV-Migrationshistorie vorhanden. Die erste Übermittlung von v6 schlug mit einem Syntaxfehler fehl und wurde nicht registriert; die vollständige erneute Übermittlung war erfolgreich. Der fehlgeschlagene Versuch hinterließ keine Paket-9-Änderungen.

## 4. Fehlerkorrekturen während der DEV-Tests

### Korrektur 9.1 – Spielerzeilensperre

Der erste Funktionstest deckte auf, dass die Spielerzeile in `correct_training_behavior_event` mit einem normalen SELECT ohne Ergebnisziel gesperrt wurde. PostgreSQL meldete `query has no destination for result data`.

Die Abfrage wurde zu `PERFORM p.id ... FOR UPDATE OF p` korrigiert. Die Korrektur wurde als eigene Migration `20261108213035` eingespielt.

### Korrektur 9.2 – EXECUTE-Recht

Bei der Nachkontrolle wurde festgestellt, dass die Ersetzung der Funktion in Korrektur 9.1 das vorherige REVOKE wiederholte, ohne den vorgesehenen EXECUTE-Grant erneut zu setzen. Die Berechtigung für `authenticated` wurde deshalb in einer separaten Migration ausdrücklich wiederhergestellt. Migration `20261108213211`.

Die abschließende ACL-Prüfung bestätigt:
- beide öffentlichen Paket-9-RPCs: `authenticated = true`
- `anon = false`
- `service_role = false`
- `PUBLIC = false`
- interne Helfer: für API-Rollen nicht ausführbar.

## 5. DEV-Testprotokoll

Alle folgenden Funktionstests wurden mit synthetischen Datensätzen innerhalb expliziter Transaktionen ausgeführt und anschließend zurückgerollt.

| Test | Prüfinhalt | Ergebnis |
|---|---|---|
| Gelbe Karte stornieren | Fünf aktive Karten; Stornierung senkt aktives Konto unter fünf und storniert offene gelbe Sperre | Bestanden |
| Gelbe Karte wiederherstellen | Wiederherstellung hebt Kartenkonto auf fünf; offene Sperre wird wiederhergestellt | Bestanden |
| Karten-Audit | Beide Statuswechsel mit Akteur-Snapshot in Audit | Bestanden |
| Rote Karte stornieren | Offene rote Sperre wird storniert | Bestanden |
| Rote Karte wiederherstellen | Rote Sperre wird wieder geöffnet/neu angelegt und dem nächsten zulässigen Spieltag zugeordnet | Bestanden |
| Rote Karte erneut stornieren | Offene rote Sperre wird erneut storniert | Bestanden |
| Manuelle Sperrenkorrektur | Offene Sperre von Spieltag A auf Spieltag B verschoben; Ziel und Lock-Flag geprüft | Bestanden |
| Schutz manueller Zuordnung | Regulärer Zuordnungsaufruf überschreibt gültiges manuelles Ziel nicht | Bestanden |
| Ungültiges manuelles Ziel | Absage des Zielspieltags; nächster regulärer Zuordnungsaufruf gibt Lock frei und ordnet neu zu | Bestanden |
| Unzulässiger Spieltyp | Zielspieltag außerhalb der konfigurierten relevanten Spielarten wird abgewiesen | Bestanden |
| Berechtigung – fremdes Team | Benutzer ohne Rolle im Zielteam kann Kartenereignis nicht korrigieren | Bestanden |
| Berechtigung – nicht authentifiziert | Aufruf ohne Auth-Identität wird abgewiesen | Bestanden |
| Schutz abgeleisteter Sperren | Kartenstornierung ändert eine bereits abgeleistete Sperre nicht; manuelle Korrektur wird abgewiesen | Bestanden |
| Audit-Snapshot Sperre | Manuelle Korrektur und Statuswechsel schreiben Actor-Snapshot | Bestanden |
| Rollback-Kontrolle | Keine synthetischen Trainings, Kartenereignisse, Spieltage, Sperren oder Testeinstellungen verblieben | Bestanden |

### Testiterationen / aufgedeckte Fehler

- Ein erster Test-Fixture-Versuch verwendete mehrere Karten desselben Spielers im selben Training. Der bestehende Unique-Index `training_behavior_events_one_card_per_player_training` blockierte dies korrekt. Das Test-Fixture wurde auf ein eigenes synthetisches Training je Karte umgestellt.
- Der nächste Funktionstest deckte den SELECT/PERFORM-Fehler auf; Korrektur 9.1.
- Die ACL-Nachprüfung deckte den fehlenden authenticated-Grant nach Korrektur 9.1 auf; Korrektur 9.2.
- Nach beiden Korrekturen wurden die relevanten Funktionstests erneut ausgeführt und bestanden.

## 6. Abschließende Read-only-Verifikation

- Die drei Paket-9-Migrationen sind in `supabase_migrations.schema_migrations` registriert.
- Die drei neuen Spalten sind vorhanden:
  - `training_behavior_event_audit.changed_by_snapshot`
  - `training_suspension_audit.changed_by_snapshot`
  - `training_suspensions.manual_target_locked` (NOT NULL, Default false)
- Beide Audit-Tabellen haben weiterhin RLS aktiviert.
- Beide Audit-Tabellen behalten ihre bestehenden UPDATE/DELETE- und TRUNCATE-Schutztrigger.
- Beide Paket-9-RPCs sind SECURITY DEFINER mit festem `search_path = pg_catalog, public, auth`.
- ACL wie in Abschnitt 4 beschrieben.
- Funktionsdefinition von `correct_training_behavior_event` enthält die korrigierte Spielerzeilensperre mittels PERFORM.
- Restbestand der Testdaten: 0 Test-Trainings, 0 Test-Kartenereignisse, 0 Test-Spieltagseinträge, 0 Test-Sperren und 0 Test-Vereinseinstellungen.

## 7. Rollback / PROD

- Die Testdaten wurden zurückgerollt; die Paket-9-Migrationen selbst sind produktive DEV-Schemaänderungen und wurden nicht zurückgerollt.
- Ein Schema-Rollback ist nicht vorbereitet und darf nicht durch einfaches DROP der neuen Funktionen/Spalten erfolgen, ohne vorherige Abhängigkeits- und Datenprüfung.
- PROD wurde nicht verändert und ist nicht freigegeben.
- Für einen späteren PROD-Release sind die drei ausgeführten DEV-Migrationen sowie die vollständigen SQL-Dateien und diese Abnahme-Dokumentation als Release-Grundlage zu verwenden.

## 8. Verbindliche Nachweisgrenze

Die Funktionstests belegen die in Abschnitt 5 aufgeführten Fälle. Nicht behauptet werden vollständige parallele Last-/Race-Condition-Tests oder ein End-to-End-Frontendtest. Die Frontend-Anbindung und manuelle Praxistests sind der nächste Arbeitsschritt.
