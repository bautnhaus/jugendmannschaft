# AP-BR02 – Backup-Export: Feld- und Berechtigungsprüfung

- Datum: 21.11.2026
- Branch: develop
- Basis: aktueller `index.html` auf develop (Blob 387d02b55072b0d585fb0acddcc1a8194dcf7357)
- Status: Prüfprotokoll / Umsetzungsvorbereitung
- Keine SQL-Ausführung, keine DEV-/PROD-Schreibzugriffe, keine Restore-Änderung

## 1. Zweck und Reihenfolge

AP-BR02 wird in dieser Reihenfolge fortgeführt:

1. Exportumfang und rollenbasierte Autorisierung abschließen.
2. Fachliche Tabellen, Felder, Beziehungen und Storage-Objekte vollständig inventarisieren.
3. Exportpaket (Manifest, Versionierung, sichere Datei-/Verschlüsselungsstrategie) abschließen.
4. Erst danach Restore implementieren.

Restore bleibt bis zum Abschluss der Backup-Prüfung unangetastet.

## 2. Verbindliche fachliche Restore-Ziele (nur als Zieldefinition)

- Restore-Scope muss ausdrücklich durch den berechtigten Nutzer gewählt werden.
- Superadmins dürfen Vereine und Mannschaften sichern/wiederherstellen, aber nur im ausdrücklich ausgewählten Kontext und Umfang.
- Vereinsadmins dürfen ihren Verein sichern/wiederherstellen; Umfang muss ausdrücklich gewählt werden.
- Mannschaftsadmins dürfen ihre Mannschaft sichern/wiederherstellen; Umfang muss ausdrücklich gewählt werden.
- Rollen- und Scope-Prüfung erfolgt serverseitig. Ein Rollenwert im Exportmanifest ist kein Berechtigungsnachweis.
- Diese Ziele gelten zunächst als Architektur-/Berechtigungsanforderungen; aktueller Export erfüllt sie noch nicht.

## 3. Aktueller Exportcode – bestätigte Fakten

Die Funktion `buildBackupSnapshot()` führt direkte Supabase-Client-Abfragen durch. Der Export ist aktuell Team-bezogen (Variable `team`) und enthält im Manifest lediglich:
- `scope.type = team`
- `scope.teamId = team`
- `selectedContext = current-team`
- `authorization.role`, `teamRoles`, `clubContext`

Im geprüften Code ist keine serverseitige Export-RPC/Edge-Function erkennbar, die vor Datenabfrage und Paketbildung den zulässigen Rollen-/Scope-Umfang erzwingt. Das Manifest dokumentiert Kontext, begrenzt aber den Zugriff nicht.

### Tabellen und Felder, die der aktuelle Snapshot explizit abfragt

- `positions`: `id,name,sort_order,color` (team_id Filter)
- `players`: `id,team_id,name,first_name,last_name,birth_year,preferred_foot,level,photo_data,photo_path,notes,active,created_at,updated_at` (team_id Filter)
- `player_positions`: `player_id,position_id` (ohne serverseitigen Teamfilter; anschließend clientseitig auf Player-IDs gefiltert)
- `trainings`: `id,training_date,name,start_time,duration_minutes,location,status,note,series_id,overrides` (team_id Filter)
- `training_series`: `id,team_id,start_date,end_date,start_time,duration_minutes,weekdays,location,name` (team_id Filter)
- `matchdays`: `id,match_date,name,opponent,location,notes,kickoff_time,duration_minutes,game_type,status` (team_id Filter)
- `seasons`: `id,team_id,name,start_date,end_date,is_active,created_at,updated_at` (team_id Filter)
- `teams`: `id,name,club_id,active,birth_cohorts,abbreviation,recommended_squad_size,created_at,updated_at` (exact team)
- `training_behavior_events`: `id,team_id,season_id,training_id,training_date_snapshot,training_name_snapshot,player_id,player_name_snapshot,event_type,reason,status,awarded_by,awarded_at,voided_by,voided_at,void_reason,created_at,updated_at`
- `training_suspensions`: `id,team_id,season_id,player_id,player_name_snapshot,source_event_id,suspension_type,status,intended_matchday_id,intended_matchday_date_snapshot,intended_matchday_opponent_snapshot,served_matchday_id,served_matchday_date_snapshot,served_matchday_opponent_snapshot,created_by,created_at,served_at,expired_at,voided_by,voided_at,void_reason,manual_target_locked`
- `training_suspension_exceptions`: `id,suspension_id,team_id,team_name_snapshot,player_id,player_name_snapshot,matchday_id,matchday_date_snapshot,matchday_opponent_snapshot,reason,granted_by,granted_by_snapshot,granted_at,revoked_by,revoked_by_snapshot,revoked_at,revoke_reason`
- `matchday_early_suspension_resets`: `id,team_id,team_name_snapshot,season_id,season_name_snapshot,player_id,player_name_snapshot,matchday_id,matchday_date_snapshot,matchday_opponent_snapshot,status,reason,created_by,created_by_snapshot,created_at,applied_at,cancelled_by,cancelled_by_snapshot,cancelled_at,cancel_reason`
- `matchday_nomination_reminders`: `id,team_id,team_name_snapshot,player_id,player_name_snapshot,source_matchday_id,source_matchday_date_snapshot,source_matchday_opponent_snapshot,source_nomination_snapshot,status,reason,created_by,created_by_snapshot,created_at,fulfilled_matchday_id,fulfilled_matchday_date_snapshot,fulfilled_at,cancelled_by,cancelled_by_snapshot,cancelled_at,cancel_reason`
- `team_suspension_game_type_settings`: `team_id,updated_at,updated_by`
- `team_suspension_game_types`: `team_id,game_type,created_at`
- `team_season_closure_audit`: `id,team_id,season_id,closed_by,closed_at,reason,expired_suspensions_count,season_name_snapshot`

Zusätzliche abhängige Datensätze werden anhand der Team-Trainings- und Spieltags-IDs abgefragt:

- `attendance`: `training_id,player_id,present`
- `training_players`: `training_id,player_id,team_number,goalkeeper`
- `training_trainers`: `training_id,user_id,present`
- `training_responses`: `training_id,player_id,status`
- `matchday_players`: `matchday_id,player_id,team_number,goalkeeper,played`
- `matchday_trainers`: `matchday_id,user_id,present`
- `matchday_attendance`: `matchday_id,player_id,present`
- `matchday_recommendation_runs`: `id,matchday_id,created_at,created_by`
- `matchday_recommendation_players`: `recommendation_id,player_id,rank`

## 4. Bereits festgestellte Exportlücken / Sicherheitsrisiken

1. **Rollenbasierter Export nicht umgesetzt:** Der Snapshot nutzt direkte Client-Abfragen. Manifest-Rollenfelder erzwingen keine Berechtigung.
2. **Scope-Auswahl nicht umgesetzt:** Snapshot ist auf `current-team` fixiert. Expliziter Club-/Team-Umfang und Kategorienauswahl fehlen.
3. **Beziehungsabfrage zu breit:** `player_positions` wird unbeschränkt abgefragt und erst im Client gefiltert. Muss serverseitig kontextbegrenzt werden.
4. **Trainingsfelder:** Die aktuelle Select-Liste enthält kein `season_id` und keine `created_at/updated_at`-Felder. Schema- und Fachabgleich erforderlich, bevor Feldlücken final bewertet werden.
5. **Spieltagsfelder:** Die aktuelle Select-Liste enthält kein `season_id` und keine Änderungsmetadaten. Schema- und Fachabgleich erforderlich.
6. **Storage:** `photo_path` wird bei Spielern exportiert; Storage-Dateien werden nicht in das Backup-Paket aufgenommen. Private Bucket `player-photos` existiert in DEV/PROD gemäß IMG-SEC-01, aber Export-/Restore-Verfahren für die Dateien fehlt.
7. **Weitere Bild-/Assetfelder:** Profilbilder und Vereinsassets sowie Datenquellen/Pfade müssen rollen- und scopebezogen inventarisiert werden; keine pauschale Vollausgabe von Profil-/Vereinsdaten.
8. **Version 15 / Import:** Der Export erzeugt Formatversion 15; die vorhandene Importvalidierung akzeptiert laut Codeprüfung nur Versionen 5–12. Dies ist ein dokumentierter Restore-Kompatibilitätsmangel und wird erst nach Abschluss des Exportes bearbeitet.

## 5. Noch erforderliche Prüfschritte vor Export-Freigabe

- [ ] Vollständiges Tabellen-/Spalteninventar gegen das aktuelle DEV-Schema und das verabschiedete fachliche Datenmodell abgleichen.
- [ ] Alle FK-/Relationspfade, nullable Referenzen und historischen Snapshot-Felder für jede Datenkategorie festhalten.
- [ ] RLS/Policies/RPCs und Rollenberechtigungen je Rolle und ausgewähltem Club-/Teamkontext prüfen.
- [ ] Vereinsadmin- und Superadmin-Scopes sowie explizite Auswahl aller Backup-Kategorien spezifizieren.
- [ ] Storage-Inventar: Spielerfotos, Profilbilder, Vereinsassets; Dateiobjekte, Pfadkonvention, Zugriff und Exportfähigkeit.
- [ ] Serverseitige Exportgrenze entwerfen (RPC oder Edge Function); keine vollständigen Daten im Browser laden, bevor die Autorisierung erfolgt.
- [ ] Verschlüsselung, Manifest, Integritätsprüfung, Versionierung und Datenschutz des fertigen Backup-Archivs festlegen.
- [ ] Rollen-/Scope-Testmatrix und negative Tests (kein Zugriff auf fremden Verein/Team) dokumentieren.

## 6. Freigabegrenze

Dieses Dokument ist ein read-only Code-Review und eine Umsetzungsvorbereitung. Es enthält keine Migration und keine SQL-Ausführung. Es ändert weder DEV noch PROD. Restore-Implementierung wird erst nach Abschluss und Abnahme der Backup-Funktion begonnen.
