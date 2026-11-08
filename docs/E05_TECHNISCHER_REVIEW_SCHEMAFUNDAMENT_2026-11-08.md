# E05 – Technischer Review des Schemafundaments

**Stand:** 08.11.2026, Europe/Berlin  
**Branch:** `develop`  
**Zielumgebung:** Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**Status:** Review durchgeführt; SQL-Entwurf **noch nicht freigabefähig**; nicht ausgeführt  
**Führende Regeln:** `docs/SUPABASE_CHANGE_CONTROL.md`, `DB_MIGRATION_LOG.md`, `DB_CHANGELOG.md`, `docs/E05_TECHNISCHES_ZIELDATENMODELL_2026-11-08.md`

## 1. Prüfauftrag und Ergebnis

Geprüft wurden der vorhandene technische Zieldatenmodell-Entwurf, die SQL-Datei `docs/E05_SCHEMA_MIGRATION_DRAFT_2026-11-08.sql`, die in DEV ausgelesenen Tabellen/Constraints, die bestehenden Team-/Club-Kontextfunktionen sowie die aktuellen Spielartwerte.

**Ergebnis:** Der Entwurf ist eine brauchbare Grundlage, enthält aber noch technische Abweichungen zum fachlich beschlossenen Modell und mehrere Integritätslücken. Er wird deshalb nicht zur Ausführung freigegeben. Die offenen Punkte sind technische Verantwortung des Projekts und müssen vor einer Freigabe im Entwurf korrigiert werden.

## 2. Geprüfte DEV-Fakten

- Projekt ist aktiv und verwendet PostgreSQL 17.6.
- Relevante Bestandsobjekte sind vorhanden und RLS-geschützt: `trainings`, `attendance`, `players`, `seasons`, `matchdays`, `matchday_players`, `matchday_attendance`, `team_member_roles`, `club_members`, `club_member_roles`, `user_club_context`.
- `attendance` hat den Primärschlüssel `(training_id, player_id)`; die Ereignisberechtigung muss `attendance.present = true` prüfen. `training_responses` ist keine Anwesenheitsquelle.
- `trainings.season_id` ist nullable. Im aktuellen DEV-Bestand haben 12 von 14 Trainings keinen Saisonbezug. Die spätere Ereignis-RPC muss die aktive Saison des Teams ermitteln und bei fehlender aktiver Saison abbrechen; sie darf nicht einfach einen NULL-Wert übernehmen.
- `matchdays.game_type` enthält aktuell `Meisterschaft`, `Freundschaftsspiel`, `Turnier` sowie NULL-Werte. Die Lifecycle-Logik muss diese Werte kanonisch zuordnen; NULL darf nicht stillschweigend als sperrenrelevant behandelt werden.
- `is_team_member(uuid)` umfasst Teamrollen und Superadmins nur im ausgewählten Teamkontext. `is_team_admin(uuid)` und `has_selected_team_context(uuid)` sind vorhanden. Diese vorhandenen Regeln sind zu verwenden; keine parallele Rollenlogik.
- Die bestehende Funktion `save_matchday_recommendation(uuid, uuid[])` prüft Teammitgliedschaft, aktive Spieler und doppelte IDs, berücksichtigt aber noch keine Sperren.

## 3. Festgestellte Korrekturen am vorhandenen SQL-Entwurf

### 3.1 Spielerhistorie und Löschverhalten – kritisch

Das Zieldatenmodell verlangt, dass eine historische Ereigniszeile bei einer späteren Spieler-Löschung erhalten bleibt und die damalige Spieleridentität über einen Namens-Snapshot nachvollziehbar ist. Der SQL-Entwurf verwendet aktuell jedoch `player_id NOT NULL ... ON DELETE RESTRICT` und enthält keinen `player_name_snapshot`.

**Erforderliche Korrektur:** `player_id` in den Historientabellen nullable mit `ON DELETE SET NULL`; zusätzlich `player_name_snapshot` (und wo fachlich erforderlich weitere Identitätssnapshots). Team-, Saison- und Trainingsherkunft bleibt als historischer Kontext erhalten. Die App-Regeln zum Deaktivieren/Löschen von Spielern bleiben davon unberührt.

### 3.2 Team-Override der sperrrelevanten Spielarten – kritisch

Die vorhandenen Tabellen `team_suspension_game_types` enthalten nur einzelne Spielartzeilen. Das Modell kann damit einen vollständigen Team-Override mit **bewusst leerer Liste** nicht von „kein Override vorhanden“ unterscheiden.

**Erforderliche Korrektur:** separates Team-Override-Kopfobjekt (z. B. `team_suspension_game_type_settings`) mit explizitem Override-Status. Die Kindtabelle enthält die Spielarten. Vorhandener Override mit null Kindzeilen bedeutet bewusst „keine Spielart zählt“; ohne Override gilt der Club-Standard.

### 3.3 Sperrenursprung und Eindeutigkeit – kritisch

Der Entwurf lässt `source_event_id` bei einer Sperre NULL zu und verhindert nicht eindeutig, dass dasselbe Ereignis mehrere Sperren erzeugt.

**Erforderliche Korrektur:** auslösendes Ereignis muss bei regelbasierten Karten-Sperren verpflichtend referenziert werden; eindeutige Integritätsregel für maximal eine Sperre pro auslösendem Ereignis. Falls spätere manuelle Sperren ohne Karte fachlich benötigt werden, muss dafür ein expliziter, separat auditierter Ursprungstyp vorgesehen werden.

### 3.4 Audit- und Nutzerkonten-Löschverhalten – kritisch

Der SQL-Entwurf verwendet an mehreren Akteursreferenzen `NOT NULL` und `ON DELETE RESTRICT`. Dadurch kann die Löschung eines Auth-Benutzers an historischen Auditverweisen scheitern.

**Erforderliche Korrektur:** Akteurs-UUIDs in Audit-/Historientabellen grundsätzlich nullable mit `ON DELETE SET NULL`; Zeitpunkt, Aktion, Grund und alte/neue Werte bleiben erhalten. Die Benutzerreferenz ist ein Zusatz zur Historie, nicht deren alleiniger Identitätsanker.

### 3.5 Storno/Reaktivierung und aktive Eindeutigkeit

Die Eventtabelle muss einen eindeutigen, nachvollziehbaren Statusfluss besitzen. Die Eindeutigkeitsindizes müssen ausschließlich aktive, nicht stornierte Ereignisse berücksichtigen. Eine Reaktivierung muss die Historie des vorherigen Stornos im Audit erhalten und darf keine zweite aktive Karte/Stern-Doppelbelegung ermöglichen.

**Erforderliche Korrektur:** Statusmodell, Storno-/Reaktivierungsmetadaten, Auditaktionen und partielle Unique-Indizes müssen in einer konsistenten Variante zusammengeführt werden. Keine widersprüchliche Mischung aus Statusfeld und Zeitstempel als konkurrierenden Aktivitätsindikatoren.

### 3.6 Konsistenz über Team, Saison, Training, Spieler und Spieltag

Normale Fremdschlüssel sichern nur die Existenz einzelner IDs, nicht, dass Training, Spieler, Saison und Spieltag zum selben Team gehören.

**Erforderliche Korrektur:** alle schreibenden RPCs müssen diese Beziehungen serverseitig unter Sperre prüfen. Die Foundation darf nicht so dokumentiert werden, als würden einfache Fremdschlüssel diese fachliche Konsistenz bereits garantieren. Soweit ohne unnötige Komplexität möglich, sollen zusätzliche zusammengesetzte Schlüssel/Constraints erwogen werden.

## 4. RLS- und Rechteprüfung

- Der Entwurf verwendet bestehende Teamkontextfunktionen und erteilt keine direkten Client-Schreibrechte. Das ist für die Foundation der richtige Grundsatz.
- Alle neuen Tabellen im exponierten Schema `public` benötigen RLS und minimale Grants.
- Lesepolicies für Club-Konfiguration müssen Club-Admins im ausgewählten Clubkontext und berechtigten Teammitgliedern den benötigten Lesezugriff ermöglichen. Der aktuelle Club-Policy-Ausdruck ist gegen die tatsächliche Club-Kontextlogik abschließend zu prüfen.
- Spätere Schreib-RPCs müssen explizit auf `auth.uid()`, Teamrolle und ausgewählten Kontext prüfen. `SECURITY DEFINER` darf nicht als pauschale Abkürzung dienen; feste `search_path`, eng begrenzte EXECUTE-ACL und Advisor-Prüfung sind Pflicht.
- Audittabellen erhalten keine direkten INSERT-/UPDATE-/DELETE-Rechte für Clients. Auditdatensätze werden ausschließlich atomar durch kontrollierte serverseitige Schreiboperationen erzeugt.

## 5. Migrations- und Teststrategie

Der Entwurf bleibt unter `docs/` ein Review-Artefakt. Er wird nicht vorzeitig als ausführbare Migration unter `supabase/migrations/` abgelegt.

Vor einer späteren Freigabe sind erforderlich:
1. Korrigiertes Zieldatenmodell und abgestimmte Status-/Snapshot-Felder.
2. Korrigierter vollständiger SQL-Entwurf.
3. Statische SQL-Prüfung und Ausführung auf einer isolierten PostgreSQL-Testinstanz bzw. einem isolierten Schema – ohne DEV-/PROD-Daten zu verändern.
4. Review aller Tabellen, Fremdschlüssel, Constraints, Indizes, RLS-Policies und ACLs.
5. Positiv-/Negativtests der Leserechte und Nachweis, dass direkte Client-Schreibzugriffe verweigert werden.
6. Dokumentierter Rollback-/Wiederherstellungsweg.
7. Erst danach Erstellung der finalen Migrationsdatei mit dem im Projekt/Supabase-Change-Control vorgeschriebenen Supabase-CLI-Verfahren.
8. Konkrete Freigabe für genau diese Datei und ausschließlich Supabase DEV.

## 6. Was nicht ausgeführt wurde

- Keine SQL-Migration angewendet.
- Keine Tabellen, Funktionen, Trigger, Policies, Grants oder Daten verändert.
- Keine Frontend-Datei geändert.
- Keine Änderung an Supabase Auth, Edge Functions, GitHub `main` oder PROD.
- Keine Ausführungsfreigabe erteilt oder angenommen.

## 7. Review-Entscheidung

**Nicht freigabefähig in der aktuellen Fassung.**  
Die oben genannten Punkte werden durch den technischen Review verantwortet und müssen vor erneuter Vorlage korrigiert werden. Der Nutzer muss diese technischen Einzelheiten nicht selbst bewerten. Eine spätere Nutzerfreigabe wird erst eingeholt, wenn ein in sich konsistenter, statisch geprüfter SQL-Stand und sein konkreter Ausführungsumfang vorliegen.
