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
