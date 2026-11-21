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


## 7. Ergänzender Abgleich mit vorhandenen Sicherheits- und Fachentscheidungen (21.11.2026)

Die erneute Dokumentenprüfung bestätigt folgende bereits verabschiedete Grundlagen. Sie werden nicht erneut als offene Entscheidungen geführt:

### 7.1 Rollen- und Kontextgrenzen

IMG-SEC-01/03 dokumentiert bereits die fachlichen Bildzugriffsgrenzen:
- Spielerfotos: Mannschaftsmitglieder der zugehörigen Mannschaft; Superadmin nur im ausdrücklich ausgewählten Mannschaftskontext.
- Profilbilder: eigener Nutzer; Trainer/Mannschaftsadmins im gemeinsamen Mannschaftskontext; Vereinsadmins im eigenen Verein; Superadmin nur im ausdrücklich ausgewählten Mannschafts- oder Vereinskontext.
- Vereinsassets: Vereinsmitglieder und berechtigte Vereinsadmins; Superadmin nur im ausdrücklich ausgewählten Kontext.

Diese Berechtigungen gelten für den laufenden Bildzugriff. **Sie sind keine fertige Backup-Autorisierung** und dürfen nicht ungeprüft als Export-Policy übernommen werden. Der Backup-Service muss zusätzlich festlegen, welche Datenkategorien die jeweilige Rolle ausdrücklich exportieren darf.

### 7.2 Storage-Bestand und Status aus IMG-SEC-03

Die dokumentierte Bestandsaufnahme vom 19.11.2026 nennt:
- DEV: player-photos 2 Objekte; profile-avatars 4 Objekte (2 referenziert, 2 nicht referenziert); club-assets 1 referenziertes Objekt.
- PROD: player-photos-Bucket damals noch nicht vorhanden; players.photo_path fehlte; photo_data war leer; profile-avatars ohne Objekte/Referenzen; ein Vereinsasset war vorhanden und passend referenziert.

Diese Werte sind ein datierter Prüfstand und kein aktueller Live-Bestand. Vor Export-Freigabe muss der aktuelle DEV-Bestand erneut read-only geprüft werden. Nicht referenzierte Profilbildobjekte dürfen nicht stillschweigend aufgenommen oder gelöscht werden; Auswahl und Berechtigung sind zu klären.

### 7.3 Historische Daten und Audit-Trennung

Das E05-Zieldatenmodell unterscheidet fachlich aufzubewahrende Historie von technischen Audit-Tabellen. Die fachlichen Snapshot-Felder (z. B. damaliger Spieler-/Team-/Saisonname, Ereigniszeitpunkt, Status und Grund) sind bei den verabschiedeten Business-Datensätzen relevant. Die technischen append-only Audit-Tabellen wie `training_behavior_event_audit`, `training_suspension_audit` und `matchday_early_suspension_reset_audit` sind nicht automatisch Teil eines Mannschafts-Backups; ihre Einbeziehung würde ein separates, rollen- und datenschutzbezogenes Konzept erfordern.

### 7.4 Korrigierte Statusbewertung

- Die bisherigen AP-BR02-Exportfelder und Datenbereiche bleiben als bereits implementierter Exportstand dokumentiert.
- Die obigen IMG-SEC-Rollenregeln und Storage-Prüfungen sind bereits dokumentierte Sicherheitsgrundlagen.
- Nicht erledigt bleibt die **backup-spezifische** Autorisierung und explizite Umfangsauswahl sowie der vollständige Feld-/Relationsabgleich.
- Nicht erledigt bleibt die Einbeziehung tatsächlicher Storage-Dateien bzw. ein nachvollziehbarer, sicherer Datei-Export.
- Restore bleibt ausdrücklich nachgelagert.


## 8. Read-only DEV-Schemaabgleich – tatsächlicher Tabellenkatalog (21.11.2026)

Quelle: Supabase DEV-Projekt `pzazqvvoruqnqhcorbwx`, read-only `information_schema.columns` und FK-Metadaten. Keine Datenzeilen wurden gelesen oder verändert. Alle unten genannten Tabellen liegen im Schema `public`; die Abfrage lieferte für alle RLS aktiviert.

### 8.1 Tabellen nach Backup-Relevanz

**Fachliche Teamdaten – gehören in den zugehörigen Team-Backup-Katalog:**
`teams`, `positions`, `players`, `player_positions`, `seasons`, `training_series`, `trainings`, `attendance`, `training_players`, `training_responses`, `training_trainers`, `matchdays`, `matchday_players`, `matchday_attendance`, `matchday_trainers`, `matchday_recommendation_runs`, `matchday_recommendation_players`, `training_behavior_events`, `training_suspensions`, `training_suspension_exceptions`, `matchday_early_suspension_resets`, `matchday_nomination_reminders`, `team_suspension_game_type_settings`, `team_suspension_game_types`, `team_season_closure_audit`.

**Vereinsdaten/-konfiguration – nur bei explizitem Club-Scope und eigener Rollenfreigabe:**
`clubs`, `club_suspension_settings`. Der Clubdatensatz enthält auch Vereins- und Trainingsstättenfelder sowie `crest_path`; diese Felder und das Vereinsasset dürfen nicht unbesehen in einen Teamexport gelangen.

**Identitäts-, Mitgliedschafts- und Berechtigungsdaten – nicht als gewöhnliche Backup-Nutzdaten exportieren oder zurückspielen:**
`profiles`, `club_members`, `club_member_roles`, `global_user_roles`, `team_members`, `team_member_roles`, `team_role_change_log`, `user_club_context`, `user_team_context`. Diese Tabellen können personenbezogene Daten, Rollen und aktive Kontextauswahl enthalten. Sie dürfen keine Möglichkeit schaffen, Rollen/Mitgliedschaften oder den ausgewählten Kontext durch Import zu vergeben. Falls ein späteres Admin-Backup einzelne dieser Informationen benötigt, muss es separat autorisiert, minimiert und als nicht automatisch restaurierbare Information definiert werden.

**Technische Audit-Historie – standardmäßig ausgeschlossen aus Team-Backup:**
`training_behavior_event_audit`, `training_suspension_audit`, `matchday_early_suspension_reset_audit`, `matchday_nomination_reminder_audit`. Die zugehörigen fachlichen Datensätze und deren Snapshot-Felder sind dagegen im Team-Backup-Katalog enthalten. `team_season_closure_audit` bleibt gemäß der bereits getroffenen fachlichen Entscheidung enthalten.

### 8.2 Schemafelder, die der Export bislang nicht oder nicht vollständig auswählt

- `trainings`: tatsächliches Schema enthält `season_id`, `created_at`, `updated_at`; der aktuelle Export-Select lässt diese drei Spalten aus.
- `matchdays`: tatsächliches Schema enthält `season_id`, `created_at`, `updated_at`; der aktuelle Export-Select lässt diese drei Spalten aus.
- `matchday_attendance`: tatsächliches Schema enthält `updated_at`; der aktuelle Export-Select exportiert nur `matchday_id,player_id,present`.
- `training_responses`: tatsächliches Schema enthält `created_at`; der aktuelle Export-Select exportiert nur `training_id,player_id,status`.
- `training_trainers` und `matchday_trainers`: beide enthalten `created_at`; die aktuellen Export-Selects lassen es aus.
- `teams`: tatsächliches Schema enthält `updated_at`, `club_id`, `active`, `birth_cohorts`, `abbreviation`, `recommended_squad_size`; Export enthält diese Spalten bereits, jedoch ist für Club-Backup zusätzlich ein eigener, kontrollierter Clubdatensatz-/Teamscope erforderlich.
- `players`: aktuelles Schema bestätigt `photo_data` und `photo_path` gleichzeitig. Der Export enthält beide. Die Backup-Regel muss künftig festlegen, ob `photo_data` nur als Legacy-/Übergangsfeld mitgenommen wird oder bei privater Storage-Nutzung ausgeschlossen bleibt.
- `training_series`: Schema enthält `created_at` und `updated_at`; der Export enthält beide.
- `seasons`: Schema enthält `created_at` und `updated_at`; der Export enthält beide.
- `positions`: Schema enthält `created_at`; der Export-Select lässt es aus. Fachlich ist zu entscheiden, ob das Erstellungsdatum für Wiederherstellung/Conflict-Resolution benötigt wird oder bewusst nicht Teil des Datenpakets ist.

### 8.3 Relations- und Sicherheitsbefunde aus dem tatsächlichen FK-Katalog

- `player_positions` ist über `player_id → players.id` und `position_id → positions.id` verbunden. Export darf diese Relation nur aus den bereits autorisierten Spieler-/Positions-IDs ableiten; keine globale Clientabfrage mit anschließendem Filter.
- Teilnahme-/Kader-/Rückmelde-Tabellen sind über Training bzw. Spieltag und Spieler verknüpft. Eine reine Parent-ID-Auswahl reicht nicht als serverseitiger Berechtigungsnachweis; jeder Parent muss zuvor im genehmigten Team-/Clubscope liegen.
- `teams.club_id → clubs.id` bestätigt die Club-Team-Beziehung. Für Club-Backup muss die autorisierte Teamliste serverseitig aus dem ausgewählten Club ermittelt werden.
- `team_suspension_game_types.team_id → team_suspension_game_type_settings.team_id`: die Settings-Kopfzeile repräsentiert das Override; die Kindzeilen sind nicht unabhängig ohne Kopfkontext zu exportieren.
- FK-Beziehungen der Business-Historie verweisen auf Spieler, Events, Sperren oder Spieltage. Weil Snapshotfelder historische Identität erhalten sollen, muss der Export gelöschte/NULL referenzierte Parent-IDs erhalten und darf historische Datensätze nicht anhand aktueller Parent-Verfügbarkeit verlieren.
- `club_members`, `team_members` und Rollen-Tabellen sind keine Bestandteil-Relationen, die beim Restore als Berechtigungsquelle übernommen werden dürfen.

### 8.4 Status nach diesem Abgleich

- [x] DEV-Public-Schema und Spaltenkatalog read-only ausgelesen.
- [x] FK-Beziehungen read-only ausgelesen.
- [x] Fachliche, Club-, Identitäts-/Berechtigungs- und technische Audit-Tabellen klassifiziert.
- [ ] Abgleich jeder fachlichen Tabellen-/Spaltenliste mit den verabschiedeten Backup-Kategorien und Export-Selects abschließen.
- [ ] Rollen-/Scope-Matrix für Team-, Club- und Superadmin-Export finalisieren.
- [ ] Storage-Objektinventur und Exportpaketentscheidung abschließen.
- [ ] Serverseitige Exportautorisierung umsetzen und testen.
- [ ] Backup-Freigabe; Restore bleibt bis dahin gesperrt.


## 9. Fortsetzung aus dem vorherigen Arbeitschat – Statuskorrektur und nächster Umsetzungsschritt (21.11.2026)

**Verbindlicher Hinweis des Nutzers:** Der regelmäßig dokumentierte Zwischenstand aus dem vorherigen AP-BR02-Chat ist maßgeblich. Die fachliche Feld-für-Feld-Abstimmung wurde dort bereits durchgeführt. Sie wird nicht erneut als offene Inventur oder Entscheidungsrunde gestartet. Die in Abschnitt 8 notierten Schemaabweichungen sind beim technischen Mapping gegen die verabschiedete Feldliste zu prüfen; sie eröffnen keine erneute fachliche Feldentscheidung.

### Bereits beschlossene Leitplanken, hier nicht erneut zu entscheiden

- Exportmodell B: maximal rollenberechtigter, ausdrücklich ausgewählter Kontext und Umfang.
- Superadmin: Verein oder Mannschaft nur im ausdrücklich gewählten Kontext; Umfang explizit auswählen.
- Vereinsadmin: eigener Verein, mit expliziter Umfangsauswahl.
- Mannschaftsadmin: eigene Mannschaft, mit expliziter Umfangsauswahl.
- Autorisierung und Scope müssen serverseitig vor dem Lesen/Exportieren der Daten erzwungen werden.
- Restore-Regeln (nur als spätere Zielvorgabe): fehlende Backup-Datensätze mergen/wiederherstellen; vorhandene Datensätze, die im Backup fehlen, niemals löschen; Konfliktregel „newer“ anhand des Änderungszeitpunkts. Restore bleibt gesperrt, bis Backup abgeschlossen und abgenommen ist.
- Private Bild-/Storage-Zugriffsregeln sind in IMG-SEC dokumentiert; sie ersetzen nicht die gesonderte Backup-Autorisierung.

### Aktueller technischer Einstieg – verifiziert am develop-Stand

Die Funktion `buildBackupSnapshot()` in `index.html` lädt die Teamdaten direkt über den Supabase-Client. `player_positions` wird zunächst teamübergreifend abgefragt und erst im Browser anhand der Spieler-IDs gefiltert. Das Manifest enthält zwar Rollen-/Kontextinformationen, aber diese werden nicht serverseitig als Exportberechtigung durchgesetzt.

Der Export wird als unverschlüsseltes JSON im Browser heruntergeladen und in der UI ausdrücklich als „Prototyp; kein vollständiges Backup“ bezeichnet. Die Storage-Dateien werden nicht in das Paket aufgenommen; bei Spielern werden nur Datenbankfelder wie `photo_path`/`photo_data` transportiert. Der aktuelle Export ist daher noch kein freigabefähiges Backup.

### Nächster Umsetzungsschritt – ohne Wiederholung der fachlichen Feldrunde

1. Die bereits beschlossene Rollen-/Scope-Matrix in einen serverseitigen Exportvertrag übersetzen (zulässiger Kontext, explizit ausgewählte Kategorien, keine clientseitige Autorisierungsentscheidung).
2. Export-Backend in DEV vorbereiten: Berechtigung prüfen, Scope auflösen, ausschließlich die freigegebenen Datensätze und Relationen serverseitig lesen.
3. Storage-Dateien und Referenzen gemäß den bereits dokumentierten IMG-SEC-Pfad-/Bucket-Regeln kontrolliert einbeziehen; verwaiste Objekte nicht automatisch aufnehmen oder löschen.
4. Manifest, Schema-/Formatversion, Integrität und verschlüsseltes Paket verbindlich umsetzen.
5. Negativtests für fremden Verein/Team und nicht ausgewählte Kategorien sowie positive Tests für die erlaubten Rollen durchführen.
6. Erst nach erfolgreicher DEV-Abnahme Backup als abgeschlossen markieren; Restore danach als separaten Umsetzungsschritt beginnen.

**Arbeitsgrenze:** Diese Statuskorrektur und Planung ist Dokumentation auf `develop`. Keine Änderung an `index.html`, keine Supabase-Schreiboperation, keine Migration und keine PROD-Aktion wurde durch diesen Eintrag ausgelöst.


## 10. Technischer Exportvertrag – Backend-Grenze und Request-Validierung (21.11.2026)

Dieser Abschnitt konkretisiert den nächsten Entwicklungsschritt aus den bereits verbindlichen Rollen-/Scope-Entscheidungen. Er führt keine neue fachliche Entscheidung ein.

### 10.1 Backend-Ansatz

- Der vorhandene Edge-Function-Ordner und die Einladungsfunktion zeigen das Projektmuster: Edge Function, Benutzeridentität über Bearer-Token und auth.getUser(), getrennte Benutzer- und privilegierte Clients.
- Dieses Muster ist nur technische Referenz. Die Einladungsfunktion ist keine Exportberechtigung und wird nicht wiederverwendet.
- Geplante Funktion: dedizierte Backup-Edge-Function (Arbeitsname create-backup).
- Der Benutzer-Client mit JWT dient zur Identitätsbestätigung und Berechtigungsprüfung. Ein privilegierter Client darf erst nach erfolgreicher Autorisierung und nur für den exakt freigegebenen Scope eingesetzt werden.
- Keine privilegierte Datenabfrage vor der Berechtigungsentscheidung; keine Berechtigung allein aus Request-Body, UI, Manifest oder gespeicherten Client-Kontexten ableiten.

### 10.2 Request-Vertrag (Implementierungsentwurf)

Der Request enthält ausdrücklich:
- scope_type: team oder club
- scope_id: UUID des ausgewählten Teams bzw. Vereins
- categories: nichtleere Liste ausdrücklich ausgewählter, unterstützter Backup-Kategorien

Serverseitige Validierung:
1. JWT authentifizieren; fehlender/ungültiger Benutzer führt zu 401.
2. Scope, UUID und Kategorien validieren; ungültige Eingaben führen zu 400.
3. Rolle und Zugehörigkeit für genau diesen Kontext prüfen; unberechtigt führt zu 403.
4. Bei Club-Scope die zugehörigen Teams serverseitig bestimmen und ausschließlich diese IDs zulassen.
5. Kategorien gegen feste Allowlist prüfen; unbekannte oder nicht freigegebene Kategorien ablehnen.
6. Daten und Relationen anhand des autorisierten Scope laden; clientseitige Nachfilterung ist keine Sicherheitsgrenze.
7. Manifest aus serverseitig bestätigten Werten erstellen; keine clientseitig behaupteten Rollen-/Kontextdaten übernehmen.

### 10.3 Berechtigungsprüfung je Kontext

- Mannschaftsadmin: bestehende Teamadmin-Prüfung für genau die angeforderte Mannschaft; keine andere Mannschaft.
- Vereinsadmin: bestehende Vereins-Kontextberechtigung für genau den Verein; nur Teams mit passender club_id.
- Superadmin: globale Superadmin-Rolle serverseitig bestätigen und den ausdrücklich angeforderten Vereins-/Mannschaftskontext validieren. Die neutrale Superadmin-Rolle erweitert nicht automatisch den Umfang.
- Rollenpriorität oder Mehrfachmitgliedschaften dürfen nicht aus einer vom Client übermittelten Rollenliste abgeleitet werden.

Vor Codefreigabe ist der konkrete bestehende Superadmin-Kontexthelfer (Team-/Vereinskontext) im DEV-Schema zu verifizieren. Falls er keinen sicheren expliziten Kontextnachweis liefert, braucht es einen eng begrenzten Export-Berechtigungsvertrag; keine improvisierte Clientprüfung.

### 10.4 Daten- und Relationsgrenze

- Die verabschiedete Fachfeldliste bleibt Quelle für Select-Felder. Schemaabweichungen sind technisches Mapping, keine erneute Fachentscheidung.
- Teamdaten werden über die serverseitig ermittelte Team-ID begrenzt.
- Clubdaten dürfen nur im Club-Scope und nach entsprechender Rollenfreigabe ausgegeben werden.
- player_positions und abhängige Anwesenheits-, Rückmelde-, Trainer-, Kader- und Historienrelationen werden erst nach Ermittlung autorisierter Parent-IDs geladen.
- Identitäts-, Rollen-, Mitgliedschafts- und technische Audit-Tabellen bleiben gemäß Abschnitt 8 ausgeschlossen.
- Historische Snapshot-Datensätze werden nicht allein wegen fehlender aktueller Parent-Zeilen oder NULL-FKs verworfen.

### 10.5 Ergebnis und Paketgrenze

Die Edge Function soll zunächst einen validierten serverseitigen Snapshot und ein nachvollziehbares Manifest liefern. Verschlüsselte ZIP-/Dateipaketbildung und tatsächliche Storage-Dateiübernahme bleiben getrennte Umsetzungspunkte, bis Format, Verschlüsselung und Größenlimits umgesetzt und geprüft sind. Ein JSON-Snapshot allein darf nicht als vollständiges Backup bezeichnet oder freigegeben werden.

### 10.6 Status

- [x] Edge-Function-Muster und Berechtigungs-RPCs als technische Referenz read-only geprüft.
- [x] Backend-Grenze, Request-Validierung und Scope-Filter dokumentiert.
- [x] Bestehende Superadmin-Kontextprüfung anhand dokumentierter AP02/AP03-DEV-Migrationen gegen diesen Vertrag abgeglichen.
- [ ] Export-Edge-Function implementieren (DEV-Code; vor Bereitstellung gesondert prüfen).
- [ ] Feldmapping aus der bereits verabschiedeten Feldliste serverseitig übernehmen.
- [ ] Storage-Dateien und sichere Paketbildung ergänzen.
- [ ] Autorisierungs- und Scope-Negativtests in DEV durchführen.

**Änderungsumfang:** Dokumentation auf develop. Kein Frontend-/Edge-Code, keine SQL-Migration, keine Datenbankausführung, kein Deployment und keine PROD-Änderung.


## 11. Superadmin-Kontextprüfung – dokumentierte DEV-Funktionen abgeglichen (21.11.2026)

Read-only Abgleich der auf develop dokumentierten und in DEV angewendeten AP02/AP03-Migrationen:

- public.can_manage_club_context(club_id) prüft bei Superadmins auf einen passenden Datensatz in user_club_context des angemeldeten Benutzers. Der Superadmin ist damit nicht pauschal Vereinsadmin; der ausgewählte Verein ist erforderlich.
- public.is_team_admin(team_id) prüft bei Superadmins über public.has_selected_team_context(team_id). Für normale Nutzer wird die Teamrolle geprüft.
- Die AP03-RLS-Härtung bindet Vereins- und Teamzugriffe an den gewählten Kontext.
- Die Club-Picker-RPC get_super_admin_clubs() ist als gesonderter, authentifizierter Superadmin-Read dokumentiert; sie erteilt keinen pauschalen Zugriff auf sämtliche Vereinsdaten.
- Die AP02-Migration unterscheidet ausdrücklich die rollenbezogene Verwaltungsprüfung vom Superadmin-Kontext und hält den Superadmin vereinsneutral.

**Konsequenz für AP-BR02:** Die bestehenden Kontextfunktionen sind geeignete Autorisierungsbausteine für den Exportvertrag. Die Edge Function muss sie mit dem angemeldeten JWT für exakt die angeforderte Scope-ID aufrufen. Club-Scope muss die zugehörigen Team-IDs anschließend serverseitig aus dem autorisierten Verein ableiten. Team-Scope darf nur die geprüfte Team-ID verwenden. Die Funktionen ersetzen weder Kategorie-Allowlist noch Umfangsauswahl.

**Prüfgrenze:** Dieser Abgleich erfolgte anhand der versionierten Migrationsdokumente auf develop; es wurde in dieser Runde keine Live-Datenbankabfrage ausgeführt. Vor einer Implementierung oder Migration ist der tatsächliche DEV-Funktionsstand erneut read-only mit den dokumentierten Definitionen abzugleichen.

**Statusfortschritt:** Die offene Dokumentationsprüfung des Superadmin-Kontexthelpers ist abgeschlossen. Nächster technischer Arbeitspunkt ist die Edge-Function-Implementierung auf develop, anschließend gezielte DEV-Prüfung. Keine SQL-Ausführung, kein Deployment und keine PROD-Änderung.


## 12. Erste serverseitige Exportfunktion – Code auf develop (21.11.2026)

Neu angelegt: \`supabase/functions/create-backup/index.ts\`

Commits:
- \`32aa3e9\` – erster serverautorisierter Snapshot-Prototyp
- \`c9e98c2\` – paginierte Datenabfrage und Empfehlungseinträge ergänzt
- \`474201f\` – Empfehlungsdetails korrekt auf Recommendation-Run-IDs begrenzt

### Implementiert im DEV-Quellcode (noch nicht deployed)

- Bearer-JWT und Benutzerprüfung mit Auth.
- Ausschließliche serverseitige Rollen-/Kontextprüfung über die vorhandenen \`is_team_admin(team_id)\`- und \`can_manage_club_context(club_id)\`-RPCs.
- Expliziter Team- oder Vereins-Scope; Club-Teams werden nach erfolgreicher Vereinsautorisierung serverseitig ermittelt.
- Feste Kategorie-Allowlist und Ablehnung unbekannter, leerer oder doppelter Kategorien.
- Tabellenfelder als explizite Select-Allowlist; keine Berechtigungsdaten oder Membership-Tabellen im Snapshot.
- Teamfilter sowie Parent-ID-basierte Filter für abhängige Tabellen; \`player_positions\` wird anhand autorisierter Spieler-IDs abgefragt.
- Paginierung in 500er-Blöcken, damit der übliche API-Zeilenlimit nicht unbemerkt den Snapshot abschneidet.
- Manifest enthält serverbestätigte Benutzer-/Scope-Informationen und kennzeichnet das Ergebnis ausdrücklich als Prototyp ohne Storage und verschlüsseltes Archiv.

### Noch nicht freigabefähig / bewusst offen

- Die Funktion wurde nur in GitHub \`develop\` erstellt und angepasst. Sie wurde nicht in Supabase deployed oder ausgeführt.
- Die UI ruft sie noch nicht auf; der bestehende Export bleibt unangetastet.
- Storage-Dateien, Foto-/Asset-Bytes, ZIP-Bildung, Verschlüsselung und Integritäts-Hash sind nicht enthalten.
- Die Kategorie-IDs und Auswahloberfläche müssen noch an die bereits dokumentierte Umfangsauswahl gekoppelt werden; der Request allein stellt keine UI-Freigabe dar.
- Laufzeit-/Deno-Validierung und vollständige positive/negative Scope-Tests stehen aus.
- Die Feldlisten sind aus dem dokumentierten Snapshot übernommen; ein automatischer schema-basierter Test auf fehlende/ungültige Spalten ist vor DEV-Ausführung erforderlich.

**Nächster Schritt:** Quellcode statisch auf Reihenfolge und Relationstypen prüfen, dann DEV-Schema-Kompatibilität und Edge-Function-Deployment separat vorbereiten. Vor dem Deployment erfolgt eine ausdrückliche Freigabe; PROD bleibt unangetastet.


## 13. Read-only DEV-Schemaabgleich und technische Korrektur (21.11.2026)

Das aktuelle DEV-Projekt \`pzazqvvoruqnqhcorbwx\` wurde ausschließlich lesend über \`information_schema.columns\` geprüft. Für alle 25 im Exportprototyp definierten Tabellen wurden sämtliche expliziten Select-Spalten gegen das reale Schema abgeglichen: **keine fehlenden Tabellen-/Spaltennamen im geprüften Feldmapping**.

Dabei wurde außerdem das relationale Mapping der Empfehlungsdetails geprüft: \`matchday_recommendation_players.recommendation_id\` referenziert die im Snapshot geladenen Recommendation-Run-IDs, nicht die Matchday-IDs. Die Codefassung begrenzt diese Tabelle entsprechend.

Weitere technische Korrektur:
- Publishable-Key-Fallback und JSON-Fehlerbehandlung für Secret Keys an das bestehende Edge-Function-Projektmuster angepasst.
- Response mit \`Cache-Control: no-store\` versehen, da der Export personenbezogene Spieler- und Historieninformationen enthält.

Commits:
- \`7cc3104\` – DEV-Schema-/Relationskorrekturen
- \`0ea609f\` – Key-Konfiguration und Cache-Schutz

**Noch kein Deployment oder Funktionstest:** Der Schemaabgleich bestätigt die Select-Felder, nicht sämtliche Laufzeit- oder Berechtigungsfälle. Vor dem DEV-Deployment ist noch der statische Review der Scope-Verzweigungen und die Testmatrix abzuschließen. Keine SQL-Schreiboperation und keine PROD-Änderung.
