# E05 – Technisches Zieldatenmodell: Trainingsereignisse, Sperren und Sperrausgleich

**Stand:** 08.11.2026 – Revision 2 nach technischem Review  
**Branch:** `develop`  
**Zielumgebung:** ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**Status:** korrigiertes Zielmodell; SQL-Entwurf in Prüfung; nicht ausgeführt und nicht freigegeben.

## 1. Verbindliche Quellen und Regeln

Fachliche Grundlage sind AP05.2 und AP05.3a–d sowie `docs/E05_UI_KONZEPT_UMSETZUNGSLEITLINIE_2026-11-07.md`. Für Vorgehen, Sicherheit und Dokumentation gelten `PROJECT_CONTEXT.md`, `docs/SUPABASE_CHANGE_CONTROL.md`, `DB_CHANGELOG.md`, `DB_MIGRATION_LOG.md` und `SUPABASE_CHANGELOG.md`.

`DB_MIGRATION_LOG.md` bleibt das tatsächliche Ausführungsjournal. Ein vorbereiteter SQL-Entwurf ist kein Ausführungsnachweis und gehört nicht als ausgeführte Migration in dieses Log. `DB_CHANGELOG.md` beschreibt erst nach erfolgreicher Ausführung die tatsächlich entstandenen Datenbankobjekte.

## 2. Bestätigte DEV-Fakten (read-only)

- PostgreSQL 17.6.
- `trainings`: `team_id`, nullable `season_id`, `training_date`, Status `planned/done/cancelled`.
- `attendance`: Primärschlüssel `(training_id, player_id)`; `present` ist die alleinige Anwesenheitsquelle.
- 12 von 14 aktuellen DEV-Trainings besitzen `season_id = NULL`. Eine Ereignis-RPC darf diesen NULL-Wert nicht übernehmen, sondern muss die aktive Saison der Mannschaft eindeutig ermitteln und bei fehlender/eindeutig nicht bestimmbarer aktiver Saison abbrechen.
- `players`: `team_id`, `active`; direkter Teamwechsel ist durch bestehende Schutzlogik blockiert.
- `matchdays`: `team_id`, nullable `season_id`, `game_type`, Status `planned/done/cancelled`. Aktuelle Spielartwerte: Meisterschaft, Freundschaftsspiel, Turnier und NULL. NULL ist nicht automatisch sperrenrelevant.
- `team_member_roles` enthält `trainer` und `admin`. Bestehende Helfer `is_team_member(uuid)`, `is_team_admin(uuid)`, `has_selected_team_context(uuid)`, `is_club_member(uuid)` und `can_manage_club_context(uuid)` sind vorhanden.
- Club-Admins müssen beim Lesen der Clubkonfiguration auf ihren ausgewählten Clubkontext beschränkt bleiben. `can_manage_club_context(uuid)` allein erzwingt für Club-Admins nicht zwingend einen gespeicherten ausgewählten Kontext; die Policy muss zusätzlich `user_club_context` prüfen.
- Die vorhandene Funktion `save_matchday_recommendation(uuid, uuid[])` berücksichtigt aktuell keine Sperren. Die eigentliche Empfehlung wird nicht vollständig dort berechnet.

Dies ist eine gezielte E05-Bestandsprüfung, kein vollständiger Datenbank-Sicherheitsaudit.

## 3. Tabellenmodell

### 3.1 `training_behavior_events`

Ein Datensatz je tatsächlich vergebener gelber Karte, roter Karte oder positivem Stern.

- `team_id`, `season_id`: historische UUID-Snapshots; `team_name_snapshot` und `season_name_snapshot` bewahren die damaligen Bezeichnungen.
- `training_id`: historische UUID ohne FK; `training_date_snapshot` und `training_name_snapshot` bewahren die damaligen Trainingsdaten.
- Die spätere RPC prüft beim Erstellen, dass Training, Spieler, Team und aktive Saison zusammenpassen.
- `player_id`: nullable FK auf `players` mit `ON DELETE SET NULL`.
- `player_name_snapshot`: Pflicht; erhält die historische Identität bei späterer Spieler-Löschung.
- `event_type`: `yellow_card`, `red_card`, `positive_star`.
- `status`: ausschließlich `active` oder `voided`; ein Statusfeld ist die einzige Quelle für aktive/stornierte Gültigkeit.
- `reason`: bei Karten Pflicht, bei Stern optional.
- `awarded_by`, `voided_by`: nullable FK auf `auth.users` mit `ON DELETE SET NULL`; zusätzlich werden Actor-Namenssnapshots gespeichert.
- Zeitstempel sowie Stornogrund.

Integrität:
- partieller Unique-Index: maximal eine aktive Karte (gelb oder rot) pro Spieler/Training.
- partieller Unique-Index: maximal ein aktiver Stern pro Spieler/Training.
- Karte und Stern dürfen koexistieren.
- Stornierte Ereignisse bleiben erhalten und werden aus aktivem Kartenkonto und Empfehlung ausgeschlossen.
- Wiederherstellung ist eine kontrollierte, auditierte Aktion; der Unique-Index verhindert eine Reaktivierung, wenn bereits ein anderes aktives Ereignis desselben Typs/der Karte existiert.

### 3.2 `training_behavior_event_audit`

Append-only Audit für `created`, `corrected`, `voided`, `reinstated`. Enthält Event-ID, Aktion, vollständigen Vorher-/Nachher-Snapshot, Grund, Akteur und Zeitpunkt. Akteurs-FK ist nullable mit `ON DELETE SET NULL`; Actor-Snapshot und Auditdaten bleiben erhalten. Keine direkten Client-Schreibrechte.

### 3.3 `training_suspensions`

Eigenständiger Datensatz je regelbasierter Sperre:
- historische Team-/Saison-UUIDs mit Namenssnapshots,
- nullable Spieler-FK mit `ON DELETE SET NULL` plus Pflicht-Namenssnapshot,
- verpflichtendes `source_event_id` auf das auslösende Kartenereignis,
- Sperrentyp `yellow` oder `red`,
- Status `open`, `served`, `expired` oder `voided`,
- vorgesehener und tatsächlich bedienter Spieltag,
- Erstellungs-/Abschlusszeitpunkte und Actor-Snapshots.

Ein partieller Unique-Index verhindert mehr als eine Sperre je auslösendem Ereignis. Manuelle Sperren ohne Kartenauslöser sind in AP05 nicht beschlossen und werden nicht stillschweigend ermöglicht.

### 3.4 `training_suspension_exceptions`

Eine Ausnahme referenziert eine konkrete Sperre und einen konkreten Spieltag. Spieler-/Teamidentität wird zusätzlich als Snapshot gespeichert. Pflichtfelder: Grund, genehmigender Trainer, Zeitpunkt. Pro Sperre/Spieltag höchstens eine aktive Ausnahme. Eine Ausnahme lässt die Sperre offen und verschiebt sie sofort auf den nächsten relevanten Spieltag – unabhängig vom tatsächlichen Einsatz. Sie ändert weder Nominierung noch Einsatz.

### 3.5 `training_suspension_audit`

Append-only Audit für Sperrenanlage, Zielspieltagänderung, Ableistung, Ablauf, manuelle Korrektur, Storno/Wiederherstellung und Ausnahme. Vorher-/Nachher-Snapshots, Aktion und Zeitpunkt bleiben erhalten. Actor-ID nullable mit `ON DELETE SET NULL`, zusätzlich Actor-Snapshot.

### 3.6 Spielart-Konfiguration

- `club_suspension_settings`: Club-Standard als vollständige `text[]`-Liste.
- `team_suspension_game_type_settings`: separates Team-Override-Kopfobjekt. Vorhandener Kopfdatensatz bedeutet vollständigen Override.
- `team_suspension_game_types`: Kindtabelle der Team-Spielarten. Ein Override-Kopf ohne Kindzeilen bedeutet bewusst leere Liste (kein Spieltagtyp zählt). Fehlt der Kopfdatensatz, gilt der Club-Standard.
- Club- und Teamlisten erlauben nur die im Produkt definierten Spielarten. NULL-Spielart eines Spieltags zählt nicht automatisch.
- Änderungen wirken nur auf zukünftige Sperrenzuordnungen, keine rückwirkende Neubewertung.

### 3.7 `matchday_early_suspension_resets`

Vormerkung des optionalen vorzeitigen Sperrausgleichs:
- historisches Team/Saison, nullable Spieler-FK mit `ON DELETE SET NULL`, Pflicht-Namenssnapshot,
- konkreter Spieltag,
- Status `pending`, `applied`, `cancelled`,
- Pflichtgrund, vormerkender Trainer, Zeitpunkt und Auflösungsdaten.

Eine Vormerkung ist unabhängig von der Zahl gelber Karten. Sie darf nicht gleichzeitig mit einer Nominierung desselben Spielers für denselben Spieltag bestehen. Diese Konkurrenz wird in einer RPC atomar geprüft und abgesichert. Nur der tatsächlich durchgeführte konkrete Spieltag führt zur Anwendung; Absage oder spätere Nominierung storniert die Vormerkung. Historische Ereignisse bleiben unverändert; rote und bereits ausgelöste Sperren bleiben unberührt.

### 3.8 `matchday_early_suspension_reset_audit`

Append-only Audit für Vormerkung, Anwendung, Stornierung bei Absage/Nominierung und manuelle Korrektur. Actor-ID nullable mit `ON DELETE SET NULL`, zusätzlich Actor-Snapshot.

## 4. Konsistenz und Löschverhalten

- Spieler-Löschung setzt nur die nullable Spieler-FK auf NULL; Snapshot und Historie bleiben.
- Actor-Löschung setzt Actor-FKs auf NULL; Actor-Snapshot, Zeit, Aktion und Grund bleiben.
- Team-, Saison-, Trainings- und Spieltags-IDs werden als historische Snapshots gespeichert; Saison-, Trainings- und Spieltagsbezeichnungen/-daten werden zusätzlich als Text-/Datums-Snapshots gesichert.
- Es gibt keine operativen Fremdschlüssel von der Ereignis-/Sperrenhistorie auf Team, Saison, Training oder Spieltag. So bleiben Historien bei Löschung der Quelldatensätze erhalten, ohne bestehende sequenzielle Löschabläufe teilweise scheitern zu lassen.
- Normale FKs sichern keine teamübergreifende Konsistenz. Jede schreibende RPC muss Team, Spieler, Training, Saison und Spieltag unter Transaktions-/Zeilensperre prüfen. Die aktive Saison wird aus `seasons.is_active` der betreffenden Mannschaft ermittelt; fehlende oder mehrdeutige aktive Saison führt zum Abbruch.
- Sperrenquelle muss eine Karte desselben Spielers/Teams/Saisonkontexts sein. Ein Ereignis darf höchstens eine Sperre auslösen.
- Eine Ausnahme muss auf einen Spieltag derselben Mannschaft und Saison zeigen.
- Ein Reset muss auf einen Spieltag derselben Mannschaft und Saison zeigen; Nominierungskonflikt wird atomar über `matchday_players` geprüft.
- Direkte Hard Deletes der Ereignis-, Sperren-, Ausnahme-, Reset- und Audit-Historie sind ausgeschlossen.

## 5. Lebenszyklusregeln aus AP05.2

- Fünf aktive gelbe Karten lösen eine gelbe Sperre aus; vier aktive gelbe Karten sind Warnung.
- Nach Ableistung der gelben Sperre wird das aktive gelbe Kartenkonto auf null gesetzt; historische Karten bleiben. Weitere gelbe Karten während einer offenen gelben Sperre werden nicht in ein neues Konto übernommen.
- Rote Karte erzeugt sofort eine rote Sperre und verändert das gelbe Konto nicht.
- Nur tatsächlich durchgeführte, konfigurierte relevante Spieltage bedienen Sperren. Absagen zählen nicht; verschobene Termine erst nach Durchführung.
- Mehrere Sperren werden nacheinander bedient, gelb vor rot, je eine pro relevantem Spieltag.
- Ausnahme gilt nur für konkreten Spieltag, benötigt Grund, verschiebt die offene Sperre sofort weiter und ist keine Ableistung.
- Saisonwechsel: aktives gelbes Konto zurücksetzen, offene Sperren auslaufen lassen; Historie bleibt.
- Vorzeitiger Sperrausgleich: unabhängig vom Kartenstand, nur explizite Vormerkung für nicht nominierten Spieler, Anwendung nur nach Durchführung, Storno bei Absage oder späterer Nominierung.
- Bereits bediente Sperren, abgeschlossene Spieltage und tatsächliche Einsätze werden nicht rückwirkend verändert.
- Empfehlung: Sperr-Eligibility vor bestehender Berechnung; bestehende Logik (Trainingsteilnahme, Aktualität, Nominierungshistorie/Fairness, begrenzter Sterne-Einfluss, Zufall bei Gleichstand) bleibt. Gelbe Karten unterhalb der Schwelle und vorzeitiger Sperrausgleich beeinflussen die allgemeine Empfehlung nicht.

## 6. RLS und Rechte

- Alle neuen Tabellen in `public` erhalten RLS.
- Teambezogene SELECT-Policies verwenden vorhandene `is_team_member(team_id)` und `has_selected_team_context(team_id)`.
- Clubkonfiguration darf von Teammitgliedern der betroffenen Mannschaft sowie von Club-Admins/Superadmins im ausgewählten Clubkontext gelesen werden. Dafür ist zusätzlich zur bestehenden `can_manage_club_context(club_id)`-Prüfung ein passender Datensatz in `user_club_context` erforderlich. Keine pauschale Freigabe an alle Clubmitglieder.
- Keine direkten Client-INSERT-/UPDATE-/DELETE-Rechte in der Foundation. Schreiboperationen kommen später über eng begrenzte RPCs mit explizitem `auth.uid()`-/Teamrollen-/Kontextcheck.
- Audittabellen erhalten keine direkten Client-Schreibrechte.
- `SECURITY DEFINER` nur wenn zwingend erforderlich, fester `search_path`, enge EXECUTE-ACL, Security Advisor und konkrete Negativtests.

## 7. Migrationsschnitt

Die Foundation-Migration umfasst zehn neue Tabellen (einschließlich Team-Override-Kopf und Kindtabelle), Indizes, Constraints, RLS und minimale Grants. Sie verändert keine bestehenden Tabellen, Funktionen, Trigger oder Policies und schreibt keine Bestandsdaten um.

Separate Folgeetappen:
1. Ereignis-RPCs mit Anwesenheits-/Saison-/Teamprüfung, atomarer Duplikatverhinderung, Audit und Korrektur/Storno/Wiederherstellung.
2. Sperren-Lifecycle: Schwellen, Reihenfolge, tatsächliche Spieltagableistung, Ausnahmen, Saisonabschluss und Spielartkonfiguration.
3. Vorzeitiger Sperrausgleich mit atomarer Nominierungsprüfung und Absage-/Nominierungsreaktion.
4. Read-RPCs/Views für Kartenkonto, Warnungen, Sperrenhistorie und Spieltags-Eligibility.
5. Integration in vorhandene Trainings-, Spielerliste-, Spielerdetail- und Spieltagskomponenten sowie Empfehlung.
6. DEV-Funktional-, RLS-/ACL-, Parallelitäts- und Regressionstests.

## 8. Prüfstatus und offene Freigabebedingungen

Der Review vom 08.11.2026 hat folgende Punkte identifiziert; diese Revision adressiert sie im Modell:
- Spielerhistorie durch nullable Spieler-FK plus Namenssnapshot.
- Vollständiger Team-Override einschließlich bewusst leerer Liste.
- Pflichtquelle und Eindeutigkeit einer regelbasierten Sperre.
- Actor-FKs nullable mit `ON DELETE SET NULL` plus Snapshot.
- Eindeutiges Event-Statusmodell.
- Team-/Saison-/Training-/Spieltag-Konsistenz ausdrücklich als RPC-Prüfpflicht.
- Clubkonfigurations-Leserecht im ausgewählten Clubkontext.

**Noch offen, bevor die SQL-Fassung technisch freigegeben werden kann:**
- statische Prüfung der überarbeiteten vollständigen SQL-Datei;
- Test auf isolierter PostgreSQL-Instanz oder isoliertem Schema, ohne DEV-/PROD-Daten zu ändern;
- vollständige Prüfung von FK-/Constraint-/Index-/Policy-/Grant-Definitionen;
- Positiv-/Negativtests für Team-/Clubkontext und direkte Schreibverbote;
- dokumentierter Rollback-/Restore-Weg;
- erst danach Erstellung der finalen Datei über das vorgeschriebene Supabase-CLI-Verfahren.

**Status:** Zielmodell Revision 2 erstellt. Noch keine SQL-Ausführung, keine Datenbankänderung, keine Freigabe.
