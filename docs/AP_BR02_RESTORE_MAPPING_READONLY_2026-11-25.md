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
