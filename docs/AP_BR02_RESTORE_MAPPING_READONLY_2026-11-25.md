# AP-BR02 – Read-only Restore-Mapping / Scope / Konfliktregeln

Stand: 25.11.2026  
Branch: `develop`  
Status: **Analyse und Spezifikation; kein Restore-Code, keine DB-/Storage-Schreiboperation**

## Ausgangspunkt und Abnahmegrenze

- Nutzerprüfung des DEV-Backup-Prüfdialogs erfolgreich: Backup lokal entschlüsselt und Paketprüfung bestanden; 10 Datentabellen, 0 Assets / 0 Asset-Bytes im getesteten Paket. Es wurde nichts wiederhergestellt.
- Die neun isolierten Restore-Preflight-Fixtures einschließlich ZIP-Asset-Bytes und falscher deklarierter Asset-Größe sind bestanden.
- Diese Prüfungen belegen Paket-/Preflight-Verhalten, nicht den Datenbank- oder Storage-Restore.
- Der alte Legacy-Import `replaceTeamDataWithBackup()` ist destruktiv und bleibt gesperrt. Die vorhandene Rücksicherungs-/Rollback-Logik darf nicht als Freigabe für den neuen Paket-Restore interpretiert werden.

## 1. Vertrauensgrenzen und Scope-Prüfung

1. KADB-Datei lokal entschlüsseln; Passwort bleibt im Browser.
2. ZIP und Manifest vollständig prüfen: Format-/Snapshot-Version, Kategorien, Tabellen-Allowlist, Schlüssel, Referenzen, Asset-Pfade, ZIP-Einträge und tatsächliche Asset-Bytes.
3. **Vor jedem späteren Restore** Berechtigung erneut serverseitig gegen die aktuelle Sitzung und den aktuellen Zielkontext prüfen. Manifestwerte sind keine Autorisierung.
4. Zielkontext muss explizit ausgewählt sein. Scope aus dem Paket (`team`, `club`, `platform`) und IDs mit dem autorisierten Ziel abgleichen; fremde oder nicht mehr zulässige Kontexte ablehnen.
5. Paket mit unbekannter Version, unbekannter Kategorie/Tabelle, doppelten Schlüsseln, ungültiger FK-Referenz, Asset-Pfadabweichung oder unvollständigem Inhalt fail-closed ablehnen.
6. Keine globalen Profile, Rollen-, Mitgliedschafts- oder Auditdaten aus Paketmetadaten ableiten. Kein unscoped Storage-Pfad, keine Signed URL als Restore-Ziel.

**Offene Freigabeentscheidung:** Ob Restore ausschließlich in denselben Ursprungs-Kontext erlaubt wird oder eine kontrollierte Wiederherstellung in einen anderen, ausdrücklich gewählten Zielkontext unterstützt werden soll. Ein Team-/Vereinswechsel erfordert ID-/FK-Remapping und ist nicht durch die aktuelle Preflight-Prüfung abgedeckt. Bis zur Entscheidung: keine Cross-Scope- oder Neu-Ziel-Restore-Funktion.

## 2. Datenkategorien und Tabellen-Mapping

Das Mapping entspricht der aktuellen `restore-planner.js` Allowlist. Nur Tabellen, die im Manifest über eine ausgewählte Kategorie enthalten sind, werden überhaupt betrachtet.

| Kategorie | Tabellen | Schlüssel / Referenzbeziehungen |
|---|---|---|
| `team_core` | `teams`, `positions`, `players`, `player_positions` | Einzel-ID: `id`; `player_positions`: zusammengesetzt `player_id + position_id`, verweist auf `players.id` und `positions.id` |
| `training` | `training_series`, `trainings`, `attendance`, `training_players`, `training_trainers`, `training_responses` | `id` bei Eltern; Children: `training_id + player_id` bzw. `training_id + user_id`; `trainings.series_id → training_series.id` |
| `matchday` | `matchdays`, `matchday_players`, `matchday_attendance`, `matchday_trainers`, `matchday_recommendation_runs`, `matchday_recommendation_players` | `id` bei Spieltag/Run; Children: `matchday_id + player_id/user_id`; Empfehlungsspieler: `recommendation_id + player_id`; Run `matchday_id → matchdays.id` |
| `season_history` | `seasons`, `team_season_closure_audit` | `id`; Team-/Saisonbezug muss zum Zielscope passen |
| `discipline_history` | `training_behavior_events`, `training_suspensions`, `training_suspension_exceptions`, `matchday_early_suspension_resets`, `matchday_nomination_reminders`, `team_suspension_game_type_settings`, `team_suspension_game_types` | `id`; alle fachlichen Team-, Spieler-, Saison- und Spieltagsreferenzen müssen im Zielscope gültig sein |
| `files_images` | keine DB-Tabelle; Dateien gemäß Manifest | Asset-Pfad/Bytes und Quellenbezug aus geprüftem Manifest; kein freier Pfad |

### Scope-/FK-Prüfung pro Tabellenfamilie

- Team-/Elterndatensätze (`teams`, `players`, `positions`, `seasons`, `training_series`, `trainings`, `matchdays`, Recommendation-Runs): Scope-ID und Zugehörigkeit zum autorisierten Ziel prüfen.
- Child-/Join-Datensätze: Eltern-IDs **und** zweite Beziehung (z. B. Spieler, Position) prüfen. Ein einzelner FK reicht nicht.
- Saisonreferenzen: null ist im aktuellen Exportvertrag zulässig; vorhandene Saison muss dem Zielteam/-verein zugeordnet sein.
- Trainer-Teilnahmezeilen: nur die ausgewählten Teilnahme-Datensätze; keine Profil-/Rollen-/Mitgliedschaftsdaten mitimportieren.
- Referenzen auf nicht ausgewählte Kategorien: aktuelle Preflight-Regel lässt eine Referenz zu, wenn die Eltern-Tabelle im Paket fehlt, mit dem Hinweis auf eine spätere Prüfung gegen die aktuelle DB. Ein späterer Restore muss diese Referenzen gegen den autorisierten Zielbestand auflösen; andernfalls abbrechen und keine Teiländerung schreiben.

## 3. Assets – Restore-Zuordnung

Aktueller Exportmanifest-Eintrag enthält `bucket`, `object_path`, `archive_path`, `bytes`, `source`. Archiveinträge liegen unter:

- `assets/player-photos/<player-id>/...` – `players.photo_path`, Bucket `player-photos`
- `assets/player-legacy/<player-id>.<ext>` – Legacy `players.photo_data` (inline Data-URI)
- `assets/profile-avatars/<user-id>/...` – `profiles.avatar_url`, Bucket `profile-avatars`
- `assets/club-crest/<club-id>/...` – `clubs.crest_path`, Bucket `club-assets`

Restore darf nur diese bekannten Quellen und die im geprüften Paket deklarierte Datei verwenden. Der Ziel-Bucket/-Pfad muss aus dem autorisierten Zielkontext und der gültigen Datensatzreferenz neu abgeleitet werden; `object_path` aus dem Paket allein ist keine Schreibberechtigung. Bestehende Datei niemals automatisch löschen. Bei bereits belegtem Zielpfad: Hash-/Inhaltsvergleich und Konfliktregel erforderlich; andernfalls Konflikt melden und unverändert lassen.

**Offen:** Verhalten bei Asset-Zielkonflikt, Dateinamenskollision, fehlendem Datensatz (z. B. Avatar-User nicht mehr Mitglied) und möglichem Orphan nach Daten-Merge. Keine automatische Orphan-Löschung.

## 4. Merge / Never-delete / Newer-wins

Verbindliche Grundregel aus AP-BR02:

- **Merge:** Im Ziel fehlende, zulässige Datensätze ergänzen.
- **Never-delete:** Ziel-Datensätze, die im Backup fehlen, niemals löschen.
- **Newer-wins:** Bei gleicher Datensatzidentität nur dann Update vorschlagen, wenn Backup-Zeitstempel eindeutig neuer ist.
- **Gleich, fehlend oder nicht parsebar:** aktuellen Ziel-Datensatz behalten.
- Keine implizite Löschung aufgrund einer nicht ausgewählten oder leeren Kategorie.

Aktueller `buildMergePreview()` nutzt pro Tabelle die definierten Schlüssel. Zeitstempelpriorität: `updated_at`, dann `modified_at`, dann `created_at`. Update wird nur bei gültigen Zeitstempeln auf beiden Seiten und `backup > current` vorgeschlagen; Gleichstand/unklar führt zu `keep`. Die Vorschau meldet `deletes: 0`.

**Noch nicht implementiert/freigegeben:** Feld-Whitelist und Update-Strategie, Schutz unveränderlicher Identitäts-/Scopefelder, Abhängigkeitssortierung, transaktionale atomare Anwendung, Konfliktbericht, Wiederanlauf/Idempotenz. Die Preview ist keine ausführbare Restore-Migration.

## 5. Noch notwendige Entscheidungen und technische Gates

1. Same-scope-only oder Zielkontextwechsel/Remapping.
2. Für jede Tabelle: Insert-/Update-Feld-Whitelist; insbesondere `team_id`, `club_id`, User-IDs, Created-/Updated-Zeitstempel und serververwaltete Felder.
3. Referenzen zu nicht im Paket enthaltenen Parent-Tabellen: gegen Zielbestand auflösen oder Paket ablehnen.
4. Reihenfolge und atomare Transaktionsstrategie für Parent-/Child-Tabellen; Supabase REST-Aufrufe allein bieten keinen paketweiten Rollback.
5. Asset-Zielpfade, Hash-/Byte-Verifikation, bestehende Datei und fehlende/obsolete Referenz; kein automatisches Löschen.
6. Rollen-/Scope-Negativtests, Preview vor Bestätigung, explizite Nutzerfreigabe und getrennte Abnahme.

## Status

Read-only Mapping abgeschlossen als Arbeitsgrundlage. Keine Supabase-Verbindung im Preflight, keine DB-/Storage-Schreiboperation, kein tatsächlicher Restore und keine PROD-Änderung. Nächster Schritt ist die gezielte fachliche Entscheidung zu den offenen Restore-Gates; erst danach darf eine isolierte DEV-Implementierung geplant werden.


## 6. Feld-Whitelist – read-only Ableitung aus dem Exportvertrag (25.11.2026)

**Status: Entwurf/Analyse, keine freigegebene Schreib-Whitelist.** Quelle ist die aktuelle Export-Edge-Function auf develop (Export-Selects). Die Listen definieren, welche Felder das Paket aktuell überhaupt enthält; sie sind ausdrücklich noch keine pauschale Erlaubnis, jedes Feld beim Restore zu schreiben.

### Feldklassen und vorläufige Restore-Regeln

| Feldklasse | Beispiele aus Exportvertrag | Vorschlag für Restore |
|---|---|---|
| Datensatz-/Verknüpfungsschlüssel | id; zusammengesetzte Keys wie training_id + player_id, matchday_id + user_id, recommendation_id + player_id | Für Match/Idempotenz verwenden. Bei Insert ursprüngliche Identität erhalten, damit Beziehungen/Historie konsistent bleiben. Niemals per Update ändern. |
| Scope-/Besitzfelder | team_id, club_id | Vor jedem Plan gegen autorisierten Zielscope prüfen. In einem Same-scope-Ansatz nicht remappen und nicht aktualisieren. Abweichung führt zum Abbruch, nicht zu stiller Zuordnung. |
| Fachliche Nutzdaten | Namen, Termine, Spiel-/Trainingsdaten, Notizen, Status, Spielerattribute, Zuordnungswerte | Kandidaten für Insert; Update nur nach feldbezogener Whitelist und fachlicher Validierung. |
| Zeit-/Versionsfelder | created_at, updated_at, modified_at (falls im künftigen Schema vorhanden) | Zeitstempel dienen der Newer-wins-Entscheidung. created_at bei Insert ggf. als historische Metadaten erhalten; Update-Zeitstempelstrategie muss festgelegt werden, damit Restore keinen Datensatz künstlich veraltet oder neuer erscheinen lässt. Nicht blind überschreiben. |
| Personen-/Akteur-Referenzen | user_id, created_by, awarded_by, voided_by, granted_by, revoked_by, closed_by, updated_by | Keine Benutzer-, Rollen-, Mitgliedschafts- oder Profilanlage aus dem Backup. Referenzen gegen existierende Benutzer/FKs im autorisierten Zielkontext prüfen. Fehlende Pflichtreferenz: vor Anwendung als Konflikt melden. |
| Fachliche Historie / Snapshotfelder | *_snapshot, awarded_at, served_at, expired_at, voided_at, applied_at, cancelled_at, fulfilled_at | Fachliche Historie, nicht mit technischen Audit-/Auth-Daten gleichsetzen. Für Event-/Historientabellen Insert-only als sichere Ausgangshypothese prüfen; Updates nur, wenn das Datenmodell ausdrücklich veränderlichen Status erlaubt. |
| Storage-/Asset-Verweise | photo_path, photo_data, Manifest bucket/object_path/archive_path | DB-Verweise erst nach Asset-Preflight und sicherer Zielpfadableitung aktualisieren. Paketpfad nie als Schreibziel vertrauen. Asset-Merge ist ein eigener Planabschnitt. |

### Tabelle-spezifische Prüfpunkte aus den tatsächlichen Selects

- teams: id und club_id sind Identität/Scope; fachliche Teamattribute können Kandidaten sein. Vereins-/Teamzuordnung nicht verändern.
- positions, players, seasons, training_series, trainings, matchdays: Primär-ID und Teambezug schützen; alle sonstigen Felder erst nach Schema-/Constraint-Abgleich freigeben.
- Join-/Teilnahmetabellen (player_positions, attendance, training_players, training_trainers, training_responses, matchday_players, matchday_attendance, matchday_trainers, matchday_recommendation_players): zusammengesetzte Identität ist unveränderlich; beide Seiten der Beziehung müssen im Paket oder im autorisierten Zielbestand auflösbar sein.
- matchday_recommendation_runs: created_by ist Personenreferenz; Run und abhängige Empfehlungsspieler müssen gemeinsam bzw. referenzsicher verarbeitet werden.
- Disziplin-/Sperren-/Reset-/Reminder-Tabellen: direkte IDs, Akteur-FKs, Status- und Ereigniszeitpunkte sowie Snapshotfelder getrennt prüfen. Nicht als generische „alle Spalten aktualisieren“-Tabellen behandeln.
- team_suspension_game_type_settings und team_suspension_game_types: team_id ist Scope-/Schlüsselbestandteil; updated_by ist Akteurreferenz.
- team_season_closure_audit: fachliche Saisonabschluss-Historie, aber closed_by ist eine Akteurreferenz. Insert-only/Append-Verhalten und Existenzprüfung sind vor Restore festzulegen.

### Noch nicht beantwortet – nächste fachlich-technische Freigaben

1. Same-scope-only für die erste Restore-Version (keine Team-/Vereins-ID-Neuzuordnung) oder kontrolliertes Remapping. Der sichere technische Vorschlag ist Same-scope-only.
2. Exakte Insert- und Update-Spalten pro Tabelle, einschließlich unveränderlicher bzw. serververwalteter Felder.
3. Umgang mit fehlenden oder nicht mehr gültigen Akteur-/Benutzerreferenzen.
4. Insert-only-/Update-Regeln für fachliche Historien- und Ereignistabellen.
5. DB-Atomarität: ein paketweiter RPC/Transaktionspfad statt sequenzieller Client-REST-Schreiboperationen mit möglichem Teil-Restore.

Bis diese Punkte bestätigt und spezifiziert sind, bleibt buildMergePreview() ausschließlich Vorschau; kein DB-/Storage-Executor und kein Restore.

## 7. Scope-Gate und Tabellenstrategie – fachliche Fortführung (25.11.2026)

### 7.1 Entscheidung: Same-scope-only für Restore V1

Festgelegt im Arbeitsverlauf am 25.11.2026: Die erste Restore-Version arbeitet ausschließlich im selben Ursprungsscope. Kein Wechsel von Verein/Mannschaft, kein Team-/Club-ID-Remapping, keine automatische Umdeutung von IDs.

Ein Paket muss mit dem aktuell explizit gewählten und serverseitig erneut autorisierten Zielkontext exakt übereinstimmen. Die Backup-Manifestangabe ist nur Vergleichsgrundlage, keine Berechtigung. Bei Scope-Abweichung: Restore-Plan stoppen, keine Teilanwendung.

Für Vereins-Backups mit ausgewählten Mannschaften muss zusätzlich die konkrete Mannschaftsauswahl dem ursprünglichen Paketumfang entsprechen. Plattformumfang bleibt Plattformumfang; keine implizite Teilwiederherstellung über diesen Gate-Schritt.

### 7.2 Vorläufige Tabellenstrategie (Planungs-Allowlist, noch kein Executor)

| Tabellenfamilie | Tabellen | Insert-Verhalten | Konflikt-/Update-Verhalten |
|---|---|---|---|
| Stammdaten | teams, positions, players, seasons, training_series, trainings, matchdays | Fehlende Datensätze mit stabiler Backup-ID ergänzen; nur exportierte, schema-validierte Felder | Newer-wins als Vorschlag für fachlich mutable Felder; Schlüssel, Scope und serververwaltete Felder nie aktualisieren |
| Zuordnungen / Teilnahmen | player_positions, attendance, training_players, training_trainers, training_responses, matchday_players, matchday_attendance, matchday_trainers | Fehlende Relation anhand vollständigem zusammengesetztem Schlüssel ergänzen | Relations-Keys unveränderlich; Updates nur für explizit mutable Status-/Fachfelder, nicht generisch für alle Spalten |
| Empfehlungsdaten | matchday_recommendation_runs, matchday_recommendation_players | Als zusammengehörige fachliche Berechnungshistorie ergänzen, Referenzen und Parent-Run vorher auflösen | Keine automatische Änderung bestehender Runs oder ihrer Rang-/Spielerlisten; bei Identitätskonflikt behalten und Konflikt ausweisen |
| Fachliche Ereignis-/Historientabellen | training_behavior_events, training_suspensions, training_suspension_exceptions, matchday_early_suspension_resets, matchday_nomination_reminders, team_season_closure_audit | Append-/Insert-only als sichere V1-Hypothese; IDs und historische Snapshots erhalten | Bestehende Historienereignisse nicht per Newer-wins überschreiben. Gleich-ID-Konflikt: behalten und melden, nicht aktualisieren |
| Team-Konfiguration | team_suspension_game_type_settings, team_suspension_game_types | Fehlende zulässige Einstellungen/Typen ergänzen | Settings können fachlich mutable sein, jedoch nur eng definierte Nutzfelder; team_id, Schlüssel und updated_by nicht überschreiben. Zeitstempel nicht als alleinige fachliche Autorisierung behandeln |

### 7.3 Globale Feldregeln für jede Tabellen-Allowlist

- Insert: Nur Felder aus dem versionierten Exportvertrag und nach Prüfung gegen das aktuelle DEV-/Zielschema. Keine unbekannten Paketfelder weiterreichen.
- Identity: Primär- und zusammengesetzte Schlüssel bleiben original und unveränderlich; Update-Statements enthalten sie ausschließlich in der WHERE-/Conflict-Bedingung.
- Scope: team_id/club_id müssen den Same-scope-Gate passieren und sind keine Update-Felder.
- Akteure: user_id- und *_by-Referenzen dürfen keine Auth-, Profil-, Rollen- oder Mitgliedschaftsdatensätze erzeugen. FK-Ziel muss im autorisierten Zielbestand existieren; sonst vor Anwendung als Konflikt blockieren.
- Server-/Auditfelder: Keine pauschale Übernahme von created_at, updated_at oder Trigger-/Auditfeldern in Updates. Insert-Erhalt historischer Zeitstempel ist noch pro Tabelle zu bestätigen; Update-Zeitstempel sollen vom Zielsystem/Trigger stammen, sofern das Schema dies vorsieht.
- Historische Snapshots: *_snapshot sind fachliche Daten und dürfen bei Insert erhalten bleiben; bei bestehendem Ereignis nicht als gewöhnliche mutable Felder überschreiben.
- Asset-Referenzen: photo_path, photo_data, Avatar-/Crestpfade bleiben vom Daten-Restore getrennt und werden erst in einem eigenständigen, konfliktgeprüften Asset-Plan gesetzt.

### 7.4 Vor Implementierung noch zu spezifizieren

Diese Tabelle ist eine Planungs-Allowlist, keine technisch ausführbare Spaltenliste. Vor jedem Executor müssen pro Tabelle die exakten Insert- und Update-Spalten gegen das tatsächliche DEV-Schema, Constraints, Trigger und FK-Aktionen dokumentiert werden. Besonders zu prüfen: Zeitstempel/Trigger, User-FKs bei Historie, nullable Referenzen, Eventstatus mit späterer Änderung und Asset-Datenspalten.

Keine DB-/Storage-Schreiboperation, keine RPC-/SQL-Migration und keine Restore-Implementierung wurde durch diese Dokumentation freigegeben.


## 8. Schema-Abgleich DEV und tabellenbezogene Insert-/Update-Kandidaten (25.11.2026)

**Quelle / Methodik:** Read-only Abfrage des aktuellen Supabase-DEV-Projekts `Jugendmannschaft DEV` (Projektref `pzazqvvoruqnqhcorbwx`): `information_schema.columns`, `information_schema.table_constraints`, `pg_get_constraintdef` und `information_schema.triggers`. Abgleich gegen die Select-Allowlist in `supabase/functions/create-backup-package/index.ts` auf `develop`. Keine Datenzeilen verändert.

Dies ist eine **schema-geprüfte Restore-Planungs-Allowlist**, noch keine Executor-Freigabe. Exportfelder und DB-Spalten sind zunächst nur die maximale Kandidatenmenge. Jede Anwendung muss vorab gegen Same-scope, Beziehungen, Constraints und bestehende Datensätze geprüft werden.

### 8.1 Globale Insert-/Update-Regel

- **Insert:** stabile Paket-ID bzw. vollständiger zusammengesetzter Schlüssel erhalten; nur die im Exportvertrag vorhandenen und im aktuellen Ziel-Schema vorhandenen Spalten berücksichtigen. Werte validieren; Scope/FKs vorab prüfen.
- **Update:** nur wenn ein belastbarer fachlicher Newer-wins-Zeitvergleich existiert UND die Tabelle unten ausdrücklich als updatefähig markiert ist. Keys, Scope, Akteurreferenzen, Triggerfelder und historische Status-/Auditfelder nie als generische Update-Payload.
- **Kein verlässlicher Update-Zeitstempel / Join-Key-Konflikt:** bestehende Zeile behalten und Konflikt anzeigen; kein Update.
- **Never-delete:** kein DELETE, kein Ersetzen einer kompletten Kategorie/Tabelle, kein Entfernen fehlender Relationen.
- `created_at` ist kein allgemeiner Änderungsmarker. `updated_at`-Trigger setzen den Zielzeitpunkt; Backup-`updated_at` darf nicht blind als Zielwert geschrieben werden.

### 8.2 Tabellenfamilien – konkrete V1-Kandidaten

| Tabelle(n) | Insert-Kandidaten (Export + DEV-Schema) | Update-Kandidat | V1-Konfliktverhalten |
|---|---|---|---|
| `teams` | `id,name,created_at,updated_at,recommended_squad_size,club_id,birth_cohorts,abbreviation,active` | Nur mutable Team-Fachfelder nach Same-scope; `id/club_id` ausgeschlossen. `updated_at` Trigger-verwaltet. | Scopeabweichung blockiert. Kein Wechsel/Neuaufbau der Teamidentität. |
| `positions` | `id,team_id,name,sort_order,created_at,color` | **Kein Newer-wins-Update**: kein `updated_at` im Schema; vorhandene Position behalten. | Unique `team_id,name` kann Paket-ID-Kollision erzeugen: Konflikt melden, nicht umbenennen/überschreiben. |
| `players` | `id,team_id,name,first_name,last_name,birth_year,preferred_foot,level,notes,active,created_at,updated_at`; Foto-/Asset-Felder separat | `name,first_name,last_name,birth_year,preferred_foot,level,notes` nur als fachliche Kandidaten; `active` nicht restore-updaten (Schutztrigger); `id/team_id` gesperrt; `updated_at` Trigger. | Bei aktiven Status-/Teamkonflikten blockieren bzw. behalten; kein Deaktivieren/Reaktivieren. Foto getrennt. |
| `player_positions` | `player_id,position_id` | Keine Updates (nur Relation). | Vollständiger zusammengesetzter Key; fehlende Relation ergänzen, bestehende behalten. |
| `seasons` | `id,team_id,name,start_date,end_date,is_active,created_at,updated_at` | Fachfelder nur nach festgelegter Saisonregel; `id/team_id` gesperrt, `updated_at` Trigger. | Unique `team_id,name`; mehrere aktive Saisonwerte/Abschluss-Audit vor Insert validieren. |
| `training_series` | `id,team_id,start_date,end_date,start_time,duration_minutes,weekdays,location,name,created_at,updated_at` | `start_date,end_date,start_time,duration_minutes,weekdays,location,name` Kandidaten; IDs/Scope gesperrt, Zeitstempel Trigger. | Check date-range, duration, weekdays prüfen; keine Serie löschen oder bestehende Trainingseinträge entfernen. |
| `trainings` | `id,team_id,training_date,name,start_time,duration_minutes,location,status,note,series_id,overrides,season_id,created_at,updated_at` | `training_date,name,start_time,duration_minutes,location,status,note,series_id,overrides,season_id` Kandidaten nach Newer-wins; ID/Scope geschützt, `updated_at` Trigger. | FK auf Saison/Serie auflösen; Status nur validiert, keine indirekte Status-/Sperren-Neuberechnung durch Restore zulassen. |
| `attendance`, `training_players`, `training_trainers`, `training_responses` | Exportfelder je Tabelle; zusammengesetzte Schlüssel | Keine Newer-wins-Updates mangels stabiler Änderungszeit; `training_responses.created_at` ist Erstellung, nicht Änderung. | Fehlende Relationszeile einfügen; bestehende Relation behalten. Auth-User FK bei Trainerzeilen vorab auflösen. |
| `matchdays` | `id,team_id,match_date,name,opponent,location,notes,kickoff_time,duration_minutes,game_type,status,season_id,created_at,updated_at` | Fachliche Matchday-Felder Kandidaten; ID/Scope gesperrt; `updated_at` Trigger. | FK Saison, Status-/Constraints und Matchday-abhängige Triggerwirkungen vor Restore prüfen. |
| `matchday_players`, `matchday_trainers` | Exportfelder, vollständige Join-Keys | Kein Update (kein Änderungsmarker); Trainer-Teilnahme zusätzlich Auth-FK. | Fehlende Relation ergänzen; bestehende Nominierung/Spiel-/Anwesenheitsdaten nicht überschreiben. |
| `matchday_attendance` | `matchday_id,player_id,present,updated_at` | `present` ist Kandidat für Newer-wins, `updated_at` als Vergleichsmarker; Zielzeitstempel Trigger-/Serverregel prüfen. | Vor Update Matchday/Spieler und Scope prüfen; Zeitstempel nicht aus Backup direkt setzen. |
| `matchday_recommendation_runs` / `matchday_recommendation_players` | Runs: `id,matchday_id,created_at,created_by`; Child: `recommendation_id,player_id,rank` | Kein Update. Run ist einmalig je Matchday (Unique `matchday_id`); child hat Unique `recommendation_id,rank`. | Run samt Kindern konsistent planen; vorhandener anderer Run für Matchday ist Konflikt, niemals ersetzen. `created_by` muss existierender Auth-User sein oder Paket blockieren. |
| `training_behavior_events` | Alle Exportfelder einschließlich fachlicher Snapshot-/Void-Daten | **Insert-only** in V1; kein Update von Ereignis-/Voidstatus, auch wenn `updated_at` existiert. | IDs beibehalten; FK auf Training/Spieler/Season und Akteure prüfen; vorhandenes Ereignis unverändert. |
| `training_suspensions` | Alle Exportfelder inkl. Snapshot, Status, served/expired/void und `manual_target_locked` | **Insert-only**; keine Statusfortschreibung durch Newer-wins. | Source event, Saison, Spieltage, Spieler und Akteure auflösen; CHECK-Statusmetadaten als zusammenhängenden Satz validieren. |
| `training_suspension_exceptions` | Alle Exportfelder inkl. grant/revoke history | **Insert-only**; keine Überschreibung bestehender Ausnahme oder Widerrufshistorie. | Suspension FK (RESTRICT), Matchday/Spieler und Akteure prüfen; vollständige revoke metadata validieren. |
| `matchday_early_suspension_resets`, `matchday_nomination_reminders` | Alle Exportfelder inkl. Status-/Snapshot-/Fulfillment-/Cancellation-Daten | **Insert-only**; Status- und Verlauf nicht per Newer-wins überschreiben. | FK und Status-Metadaten vollständig validieren; bestehende ID behalten. Prüfen, ob INSERT Trigger Audit-/Fachfolgen auslösen würde. |
| `team_suspension_game_type_settings` | `team_id,updated_at,updated_by` | Kein Backup-Update auf `updated_by`; Zeitstempel Zielsystem. | Team-Scope und optionalen Akteur prüfen; Settings-Row vor Types bereitstellen. |
| `team_suspension_game_types` | `team_id,game_type,created_at` | Kein Update (Relation/Set). | Fehlende erlaubte Game-Type-Relationen ergänzen; niemals bestehende entfernen; Settings-Parent-FK beachten. |
| `team_season_closure_audit` | `id,team_id,season_id,closed_by,closed_at,reason,expired_suspensions_count,season_name_snapshot` | **Insert-only**, niemals Newer-wins. | Unique `season_id` und FK `ON DELETE RESTRICT`: bereits vorhandener Abschluss ist Konflikt; keine Duplikat-/Ersetzungsstrategie. |

### 8.3 Reale DEV-Schema-Funde, die Restore-Verhalten beeinflussen

- `players`: Trigger `prevent_player_team_change` und `protect_player_active_status`; Team-/Aktivstatus darf nicht durch Restore umgangen werden.
- `teams`, `players`, `seasons`, `trainings`, `matchdays`: `set_updated_at()`-Trigger vorhanden. Ziel-`updated_at` ist serverseitig.
- `matchdays`: AFTER UPDATE-Trigger `e05_reconcile_early_resets_on_matchday_status()`; Matchday-Statusänderungen können fachliche Folgen auslösen. Restore-Update darf diese nicht unkontrolliert auslösen; V1 daher Matchday-Status-Updates besonders behandeln/standardmäßig konfliktbehalten.
- `matchday_recommendation_runs`: Unique auf `matchday_id`, nicht nur Primär-ID.
- `team_season_closure_audit`: Unique auf `season_id`, Saison-/Team-FKs mit `ON DELETE RESTRICT`.
- Join-/Trainer-Tabellen referenzieren `auth.users`; Backup darf weder Benutzer noch Rollen/Mitgliedschaften rekonstruieren. Fehlende erforderliche Benutzerreferenz muss vor der Anwendung im Plan sichtbar werden.
- Historische Tabellen enthalten optionale Akteur-FKs mit `ON DELETE SET NULL` sowie Snapshotfelder. V1 erhält Snapshottext, erzeugt aber keine Auth-Identität; konkrete null-/block-Policy muss im finalen RPC verbindlich sein.

### 8.4 Reihenfolge für die reine Plan-/Validierungsphase

1. Same-scope Paket- und Mannschaftsauswahl bestätigen.
2. Tabellen-/Spalten-Allowlist gegen Paketversion und aktuelles Schema prüfen.
3. Parent-Datensätze: Team-Kontext (bereits vorhanden), Spieler/Positionen, Saison/Serie, Training/Matchday.
4. Child-Relationen und Recommendation-Run/-Children gegen Parent-IDs prüfen.
5. Historische Event-/Sperren-/Ausnahme-/Reset-/Reminder-Datensätze in FK-Abhängigkeitsfolge validieren; Insert-only.
6. Team-Settings vor Game-Type-Relations.
7. Assetplan separat nach Byte-/Hashprüfung und sicherer Zielpfadableitung.

Die Reihenfolge ist **nur die Preflight-/Merge-Planreihenfolge**, noch keine freigegebene SQL-Transaktionsimplementierung. Die atomare Anwendung, triggerneutrale Strategie, Konfliktbericht und die endgültige User-FK-Null-/Blockregel bleiben gesonderte technische Gates.

### 8.5 Sicherheitsstatus

Read-only DEV-Schemaanalyse abgeschlossen für die 24 exportierten Restore-Tabellen. Keine Tabellen-/Schemaänderung, keine Migration, keine Edge-Function-Änderung oder Deployment, keine DB-/Storage-Schreiboperation, kein Restore und keine PROD-Änderung.


## 9. Preview-Abgleich gegen DEV-Constraints – gefundene Lücken (25.11.2026)

Quelle: aktuelle pure planner-Datei `src/backup/restore-planner.js` auf develop im Vergleich zum live abgefragten DEV-Schema (Abschnitt 8). Dieser Schritt ist Review; der Planner wurde hierbei **nicht geändert**.

### 9.1 Kritischer Schlüssel-Mismatch

Die aktuelle `TABLE_KEYS`-Map stimmt für zwei Tabellen nicht mit dem realen Primärschlüssel überein:

- `team_suspension_game_type_settings`: Planner erwartet `id`; DEV-PK ist `team_id`.
- `team_suspension_game_types`: Planner erwartet `id`; DEV-PK ist `team_id + game_type`.

Folge: Merge-Preview identifiziert Zeilen nicht zuverlässig (bei fehlendem `id` kann der Key zu `undefined` kollabieren). Vor einer belastbaren Preview müssen diese Key-Definitionen korrigiert und Fixtures für gleiche/verschiedene Team-/Game-Type-Schlüssel ergänzt werden.

### 9.2 TABLE_REFS deckt nicht alle exportierten FK-Beziehungen ab

Der Preflight prüft aktuell nur einen Teil der Elternreferenzen (primär Joins, Trainingsserie, Spieltag/Recommendation). Aus DEV-Schema und Exportvertrag fehlen unter anderem:

- `teams.club_id → clubs.id` (Scope-/Club-Abgleich)
- `seasons.team_id`, `trainings.season_id`, `matchdays.season_id`
- Historie: `training_behavior_events` → Team/Saison/Training/Spieler; `training_suspensions` → Team/Saison/Source-Event/Spieltag; `training_suspension_exceptions` → Suspension/Team/Spieler/Matchday
- `matchday_early_suspension_resets` → Team/Saison/Spieler/Matchday; `matchday_nomination_reminders` → Team/Spieler/Quell- und Fulfillment-Matchday
- `team_season_closure_audit` → Team/Saison; `team_suspension_game_type_settings` → Team; `team_suspension_game_types` → Settings-Parent
- erforderliche Trainer-/Akteur-FKs zu `auth.users` (DB-Bestand, nicht Paket-Parent)

V1 muss diese Beziehungen gegen Paket-IDs oder den ausdrücklich autorisierten Same-scope-Zielbestand auflösen. Pflichtreferenz nicht auflösbar: Preview muss den gesamten Plan vor Anwendung als blockiert markieren; keine stillen Teilimporte.

### 9.3 Unique-Constraints zusätzlich zum Primärschlüssel

Der Planner matcht bisher ausschließlich über `TABLE_KEYS`. DEV enthält weitere Unique-Konflikte, die vor dem Insert zu berücksichtigen sind:

- `positions(team_id,name)`
- `seasons(team_id,name)`
- `matchday_recommendation_runs(matchday_id)`
- `matchday_recommendation_players(recommendation_id,rank)`
- `team_season_closure_audit(season_id)`

Bei Kollision über einen anderen Unique-Key darf die Preview nicht einfach `add` ausweisen. Sie muss einen expliziten Constraint-Konflikt anzeigen und niemals bestehende Historie/Recommendation/Closure ersetzen.

### 9.4 Newer-wins ist derzeit zu generisch

Die Funktion `timestamp()` fällt von `updated_at` auf `modified_at` und schließlich `created_at` zurück. Die Preview kann daher für Tabellen ohne Änderungszeit oder für append-only Historie Updates vorschlagen. Das widerspricht der V1-Tabellenstrategie aus Abschnitt 8:

- Relations ohne Änderungsmarker: Insert-only bei fehlendem Key; vorhandene Zeile behalten.
- Recommendation-Runs/Children und Event-/Suspension-/Exception-/Reset-/Reminder-/Closure-Historie: Insert-only; gleicher Schlüssel mit abweichendem Inhalt als Konflikt, kein Update.
- Mutable Stammdaten: Newer-wins nur auf expliziter per-table Update-Allowlist; serverseitige `updated_at`-Trigger nicht mit Backup-Wert überschreiben.
- Matchday-Status-Update kann den realen AFTER-Trigger zur frühen Sperren-Reconciliation auslösen; daher nicht als generisches Newer-wins-Feld behandeln.

### 9.5 Umsetzungsgates vor Preview-Freigabe

1. Tabellen-Key-Metadaten gegen tatsächliche PKs vervollständigen (insbesondere beide Game-Type-Tabellen).
2. FK-/Scope-Referenzmetadaten vervollständigen; externe Auth-User-FKs gesondert als existent/fehlend/nullable klassifizieren.
3. Unique-Constraint-Kollisionsprüfung ergänzen.
4. Per-table merge policy definieren: insert-only vs. mutable update; niemals allgemeiner timestamp fallback.
5. Preview-Ausgabe um blockierende Konflikte erweitern; der gesamte Plan muss vor einer späteren Anwendung vollständig validiert sein.
6. Fixtures für jeden gefundenen Sonderfall ergänzen; bestehende neun PASS-Fixtures bleiben als Baseline bestehen, aber eine neue Preview-Version benötigt eigene Regressionstests.

**Status:** Lücken identifiziert und dokumentiert. Kein Planner-Code geändert, keine Tests neu ausgeführt, keine DB-/Storage-Schreiboperation, kein Restore/Executor und keine PROD-Änderung.


## 12. Export-Vertrag ↔ Restore-Preflight-Abgleich – 25.11.2026

**Quellen direkt geprüft:** `supabase/functions/create-backup-package/index.ts` und `src/backup/restore-planner.js` im Repository-Branch `develop`. Beide Quellstände entsprechen den im DEV-Mirror geprüften Dateien (Edge Function SHA `fd45da0f8431c117e954701986d2459001477e0e`; Planner SHA `ae6ea68df0fd7ce499ffbb382043d52c0e8ff56f`). Der Paketvertrag setzt `format_version: 1` und Snapshot `KADAssist-Teamdaten-JSON` Version `16`; dies stimmt mit dem Preflight-Konstantenstand überein. Die ältere direkte JSON-Exportfunktion in `index.html` erzeugt dagegen ein anderes, legacy/prototype-only Format (Version 15) und ist **nicht** der AP-BR02-KADB-Paketvertrag. Diese Formate nicht vermischen.

### Bestätigte Exportfelder und Preview-Regeln

- Die serverseitige Function enthält eine explizite Tabellen-/Spalten-Allowlist. Die in `UPDATE_FIELDS` des Preview-Planners genannten Felder sind im jeweiligen Export-Select enthalten; keine Allowlist-Feldreferenz fehlt im Exportvertrag.
- Der Export liefert in `players` zusätzlich `active`, `photo_data`, `photo_path`, `created_at` und `updated_at`. Diese Felder sind bewusst nicht Teil der bestehenden Newer-wins-Update-Allowlist: Status-/Storage-/Zeitfelder werden nicht durch einen normalen Update-Vorschlag überschrieben.
- Der Export von `teams` enthält `club_id` und `active`; diese sind nicht in der Update-Allowlist. Der Restore bleibt strikt am selben Scope; Club-/Teamidentität wird nicht neu zugeordnet.
- Tabellen mit Actor-/User-Referenzen exportieren neben fachlichen Daten auch IDs und Snapshots der handelnden Personen. Diese sind keine Auth-/Profilanlage und dürfen nicht dazu führen, Nutzerkonten, Rollen oder Mitgliedschaften aus dem Backup anzulegen.

### Kritischer offener Punkt: Bilder im DB-Snapshot versus Asset-Kategorie

Der Export fragt `players.photo_data` und `players.photo_path` auch im normalen Player-Datensatz ab. Die Kategorie `files_images` steuert zusätzlich die Extraktion tatsächlicher Storage-Objekte/Legacy-Inline-Bilder in den ZIP-Assetbereich. Daraus folgt für eine spätere Restore-Implementierung:

1. Wenn `files_images` nicht gewählt oder ein Asset nicht verifiziert/wiederherstellbar ist, dürfen `photo_path` und `photo_data` nicht blind aus dem Snapshot in die Zieldatenbank übernommen werden.
2. Wenn die Kategorie gewählt ist, müssen Datenbank-Bildreferenzen erst nach erfolgreicher Asset-Planung und -Wiederherstellung gesetzt werden; Storage bleibt ein eigener, separat freizugebender Schritt.
3. Keine signed URL, temporäre URL oder rohe Inline-Base64-Nutzlast als dauerhafte Restore-Referenz übernehmen. `photo_data` ist als legacy-inline Quelle gesondert zu behandeln, nicht als normales Spielerfeld.

### FK-Prüflücke für User-/Trainer-Beziehungen

Der Export enthält `training_trainers.user_id`, `matchday_trainers.user_id`, `matchday_recommendation_runs.created_by` sowie mehrere Actor-Felder in Disziplin-/Historientabellen. Der aktuelle Preflight `TABLE_REFS` validiert interne Domain-Referenzen, aber nicht sämtliche User-/Actor-Referenzen gegen einen bestehenden, autorisierten Zielkontext. Die DB-FK allein verhindert zwar unbekannte Auth-IDs, sie belegt jedoch nicht, dass der Nutzer im exakt gewählten Team-/Vereinskontext zulässig ist.

**Vor Restore-Freigabe erforderlich:** ein feldgenauer User-/Actor-Plan:
- Trainer-Teilnahmen nur gegen bereits bestehende und im Zielkontext berechtigte Trainerkonten prüfen.
- Actor-IDs niemals erzeugen oder auf eine andere Person mappen.
- Fehlende optionale Actor-Referenzen nach dokumentierter Entscheidung entweder als Konflikt/Deferred behandeln oder explizit nullen; keine stillschweigende Änderung.
- Für jeden relevanten Export-FK (einschließlich `intended_matchday_id`, `served_matchday_id`, Reminder-/Exception-Matchdays) Fixtures für vorhanden, fehlend und außerhalb des Scope ergänzen.

**Ergebnis:** Export-Feld-Allowlist und Update-Feld-Allowlist sind in der geprüften Quelle konsistent. Bildreferenzen und User-/Actor-FKs sind jedoch noch nicht restore-ready und benötigen eine eigene sichere Feld-/Referenzregel. Keine Planner-Codeänderung vorgenommen; keine Testausführung wiederholt; keine DB-/Storage-Schreiboperation, kein Restore/Executor, keine PROD-Änderung.


## 13. DEV-UI-Abgrenzung – Paketprüfung vs. Restore-Vorschau

Quellprüfung von `index.html` im Branch `develop`:

- Die aktuelle Aktion **„Backup prüfen“** entschlüsselt lokal und ruft `inspectRestoreArchive()` auf. Die sichtbare Ergebnisansicht zeigt Paket-/Scope-/Kategorie-/Tabellen-/Asset-Zusammenfassung. Sie liest keine Zieltabellen und ruft `buildMergePreview()` nicht auf.
- Damit ist die Benutzeroberfläche eine **Paket-Preflight-/Verifikationsansicht**, keine echte Zielzustands-Merge-Vorschau. Add/Update/Keep/Conflict und Never-delete-Zielbestände werden im UI aktuell nicht angezeigt.
- Die alte Funktion `replaceTeamDataWithBackup()` ist im `index.html` weiterhin vorhanden und wird vom Legacy-JSON-Importpfad verwendet. Sie löscht vorhandene Teamdaten vor dem Einspielen und besitzt einen eigenen Safety-/Rollback-Pfad. Sie ist ein separates Altformat-/Altverfahren, **kein AP-BR02-KADB-Restore** und darf nicht als Ausweichweg für das neue Paket benutzt werden.
- Die Browser-Fixtures testen die reine Planner-Funktion isoliert mit synthetischen aktuellen Zielzeilen; sie belegen weder eine Integration in die UI noch echte Zielzustandsabfrage. Die erfolgreiche 17er Fixture-Abnahme bleibt gültig, ist aber nicht gleichbedeutend mit einer visuellen Merge-Preview-Abnahme.

**Konsequenz / Gate:** Vor einem späteren Restore-Executor braucht es zuerst eine ausdrücklich read-only Zielzustands-Preview, die serverseitig den exakten Scope erneut autorisiert, erlaubte Tabellen/Zielzeilen abfragt, Konflikte einschließlich Unique-/FK-/Actor-/Asset-Regeln sichtbar macht und klar `0 writes` garantiert. Die Legacy-Importoberfläche muss dabei als eigener Pfad klar getrennt bleiben. Keine UI-/Planner-Codeänderung in dieser Prüfung; keine DB-/Storage-Schreiboperation, kein Restore, kein PROD.
