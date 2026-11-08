# E05 – Technisches Zieldatenmodell (Entwurf)

**Stand:** 08.11.2026  
**Branch:** `develop`  
**Zielumgebung der späteren Umsetzung:** ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**Status:** Technischer Entwurf zur internen Prüfung; nicht ausgeführt und nicht freigegeben  
**Fachliche Quellen:** AP05.2, AP05.3a–d und `docs/E05_UI_KONZEPT_UMSETZUNGSLEITLINIE_2026-11-07.md`

## 1. Zweck und Leitplanken

Dieses Modell bildet Trainingsereignisse (gelbe Karte, rote Karte, positiver Stern), daraus entstehende Sperren, Sperrausnahmen, manuelle Korrekturen, den vorzeitigen Sperrausgleich und die konfigurierbaren sperrrelevanten Spielarten ab.

Verbindliche Leitplanken:
- Historische Ereignisse und Auditdaten werden nicht physisch gelöscht.
- Team- und Saisonbezug wird beim Entstehen gespeichert und bleibt auch nach einem Teamwechsel erhalten.
- Die Spielerzuordnung ist historisch; das Modell darf nicht allein über `players.team_id` ausgewertet werden.
- Eine Karte und ein Stern dürfen im selben Training nebeneinander bestehen; maximal eine Karte insgesamt und maximal ein Stern je Spieler/Training.
- Karten/Sterne können nur von autorisierten Trainern des betroffenen Teams vergeben werden; die Anwesenheit wird serverseitig geprüft.
- Korrekturen/Stornos benötigen eine Begründung und bleiben revisionsfähig.
- Club-Admins erhalten nur Leserechte. Team-Trainer, Team-Admins und Superadmins im ausgewählten Teamkontext erhalten die fachlich beschlossenen Schreibrechte.
- Die vorhandenen Rollen-/Kontextfunktionen werden verwendet; keine neue Parallel-Rollenlogik.
- Kein Eingriff in bestehende Tabellen, Rollen, Policies oder Funktionen in dieser ersten Strukturmigration.

## 2. DEV-Bestand, auf den das Modell aufsetzt

Read-only in DEV geprüft:
- `trainings`: `id`, `team_id`, `season_id`, `training_date`, `status` (`planned/done/cancelled`).
- `attendance`: Primärschlüssel `(training_id, player_id)`, `present` boolean.
- `players`: `id`, `team_id`, `name`, `active`.
- `matchdays`: `id`, `team_id`, `season_id`, `match_date`, `game_type`, `status` (`planned/done/cancelled`).
- `team_member_roles`: `team_id`, `user_id`, `role`; Rollen `trainer` und `admin`.
- Bestehende Sicherheitsfunktionen: `is_team_member(uuid)`, `is_team_admin(uuid)`, `is_super_admin()`, `has_selected_team_context(uuid)`.
- `training_responses` ist Rückmeldung, nicht Anwesenheit. Ereignisberechtigung basiert ausschließlich auf `attendance.present = true`.

## 3. Tabellenmodell

### 3.1 `training_behavior_events` – unveränderliche Ereignisidentität mit kontrollierter Korrektur
Felder:
- `id` UUID PK
- `team_id`, `season_id` (historischer Ursprung)
- `training_id` (Referenz auf Training; bei Löschung nicht kaskadieren)
- `player_id` nullable (bei Spieler-Löschung auf NULL, Historie bleibt)
- `player_name_snapshot` (Name zum Ereigniszeitpunkt)
- `event_type`: `yellow_card`, `red_card`, `positive_star`
- `reason`; für Karten zwingend, Stern optional
- `awarded_by`, `awarded_at`
- `voided_at`, `voided_by`, `void_reason` für kontrollierte Stornierung
- `created_at`, `updated_at`

Integrität:
- Ein eindeutiger partieller Index erlaubt je Training/Spieler maximal eine nicht stornierte Karte über beide Kartentypen hinweg.
- Ein zweiter Index erlaubt maximal einen nicht stornierten Stern.
- Karte/Stern können koexistieren.
- Keine DELETE-Policy; keine ON DELETE CASCADE-Beziehung von Historienobjekten.

### 3.2 `training_behavior_event_audit`
Append-only Audit für Anlage, Korrektur, Storno und Wiederherstellung. Speichert Event-ID, Team, Aktion, vollständige Vorher-/Nachher-Snapshots, Begründung, Akteur und Zeit. Direkte Client-Schreibrechte werden nicht erteilt; Audit-Schreiben erfolgt ausschließlich serverseitig über kontrollierte DB-Logik.

### 3.3 `training_suspensions`
Eine Zeile pro Sperre mit:
- Ursprung: Team, Saison, Spieler-Snapshot, auslösendes Ereignis und Sperrentyp (`yellow`/`red`)
- Status: `open`, `served`, `expired`, `voided`
- `target_matchday_id` und `served_matchday_id`
- `created_at`, `created_by`, Abschlussdaten

Gelb und Rot bleiben getrennte Sperrdatensätze. Mehrere offene Sperren werden getrennt und nacheinander bedient; gelb vor rot. Eine gelbe Sperre entsteht beim Erreichen von fünf aktiven gelben Karten. Gelb unterhalb der Schwelle erzeugt keine Sperre. Rote Sperren verändern das gelbe Konto nicht.

### 3.4 `training_suspension_exceptions`
Eine Ausnahme bezieht sich auf genau eine offene Sperre und einen konkreten Spieltag. Sie speichert Team, Spieler-Snapshot, Begründung, genehmigenden Trainer und Zeitpunkt. Bei Genehmigung wird die Sperre unmittelbar auf den nächsten relevanten Spieltag verschoben, unabhängig vom tatsächlichen Einsatz. Die Sperre bleibt offen.

### 3.5 `training_suspension_audit`
Append-only Audit für Anlage, Zuweisungsänderung, Ableistung, Ablauf, manuelle Korrektur und Ausnahme. Vorher-/Nachher-Snapshot, Begründung, Akteur und Zeitpunkt sind Pflicht, soweit eine manuelle Aktion vorliegt.

### 3.6 `club_suspension_game_types` und `team_suspension_game_types`
Club-Standardliste der spieltagstypen, die eine Sperre bedienen. Team-Einträge bilden bei vorhandener Teamkonfiguration einen vollständigen Override, keine Ergänzung. Ohne Team-Override gilt der Club-Standard. Änderungen wirken nur für zukünftige Zuordnungen; keine rückwirkende Neubewertung.

### 3.7 `matchday_early_suspension_resets`
Vormerkung des freiwilligen vorzeitigen Sperrausgleichs für einen konkreten Spieler/Spieltag. Speichert ursprüngliches Team/Saison, Spieler-Snapshot, Spieltag, Trainer, Zeit, Begründung und Status `pending`, `applied`, `cancelled`. Der Ausgleich ist unabhängig vom gelben Kartenstand und wird nur nach tatsächlich stattgefundenem Spieltag wirksam. Bei Absage wird die Vormerkung aufgehoben. Er verändert keine Kartenhistorie und keine rote Sperre. Er kann keine bereits ausgelöste gelbe/rote Sperre aufheben.

### 3.8 `matchday_early_suspension_reset_audit`
Append-only Audit für Vormerkung, automatische Anwendung, automatische Aufhebung, Stornierung bei späterer Nominierung und manuelle Korrektur.

## 4. Fachliche Lebenszyklusregeln

### Gelbe Karten
- Nur aktive, nicht stornierte gelbe Ereignisse der aktuellen Saison und des ursprünglichen Teams zählen.
- Bei fünf aktiven Karten wird genau eine gelbe Sperre erzeugt.
- Nach Ableistung der gelben Sperre wird der aktive gelbe Zähler auf null gesetzt; Ereignishistorie bleibt.
- Zusätzliche Karten während einer offenen gelben Sperre bleiben historisch, werden nicht in ein neues Konto übernommen.
- Bei Saisonende werden aktive gelbe Konten zurückgesetzt und offene Sperren beendet/abgelaufen; Historie bleibt.

### Rote Karten
- Eine rote Karte erzeugt eine sofortige rote Sperre für den nächsten relevanten, tatsächlich stattfindenden Spieltag.
- Sie verändert den gelben Zähler nicht.

### Spieltage
- Nur relevante Spielarten und Spieltage mit Status `done` können eine Sperre ableisten.
- `cancelled` zählt nie; verschobene Termine zählen erst nach tatsächlicher Durchführung.
- Mehrere offene Sperren werden nacheinander bedient: gelb vor rot.
- Tatsächlicher Einsatz und Nominierung sind getrennte Informationen; Ableistung richtet sich nach dem stattgefundenen Spieltag und der Sperrzuordnung, nicht nach einer automatischen Mutation der Einsatzdaten.

### Ausnahmen
- Gilt für genau einen Spieltag, Begründung verpflichtend.
- Verschiebt die offene Sperre sofort zum nächsten relevanten Spieltag, unabhängig davon, ob der Spieler tatsächlich eingesetzt wird.
- Ausnahme hebt Sperre nicht auf und verändert Nominierung/Einsatz nicht.

### Vorzeitiger Sperrausgleich
- Kein Bezug zu einer bestimmten Anzahl gelber Karten.
- Nur explizite Vormerkung durch Trainer für einen nicht nominierten Spieler.
- Bei tatsächlichem Stattfinden des konkreten Spieltags wird aktiver gelber Zähler auf null gesetzt; Ereignisse bleiben erhalten.
- Bei Absage oder späterer Nominierung wird die Vormerkung storniert; kein Kartenkonto-Reset.
- Keine Aufhebung einer bereits ausgelösten Sperre; rote Sperren unberührt.

## 5. Berechtigungsmodell

- SELECT: Teammitglieder über bestehende `is_team_member(team_id)`; Superadmins und Club-Admins nur über den bereits ausgewählten Teamkontext bzw. die bestehenden Leseregeln. Club-Admins erhalten keine Schreibrechte.
- INSERT Ereignis: eigener Teamrolleneintrag `team_member_roles.role IN ('trainer','admin')`; Superadmin nur bei `has_selected_team_context(team_id)`.
- Korrektur/Storno Ereignis: gleiche autorisierte Teamrollen; Begründung Pflicht.
- Sperren-/Ausnahmen-/Reset-Schreibaktionen: Trainer, Team-Admin, Superadmin im ausgewählten Teamkontext.
- Audit: keine direkten Client-INSERT/UPDATE/DELETE-Rechte. Nur serverseitige DB-Operationen.
- Alle neuen Tabellen in `public` erhalten RLS. API-Grants werden minimal vergeben.

## 6. Integritäts- und Löschstrategie

- Keine kaskadierenden Löschungen aus Trainings-, Spieler-, Team- oder Saisonobjekten in die Historientabellen.
- Spielerreferenzen werden nullable und bei physischer Spieler-Löschung auf NULL gesetzt; Name-Snapshot erhält die historische Identität.
- Team-/Saison-/Training-Referenzen werden als UUID-Snapshots ohne harte Fremdschlüssel oder mit RESTRICT gespeichert, damit Historie nicht versehentlich gelöscht wird. Diese Entwurfsentscheidung muss im SQL-Review mit dem vorhandenen Löschverhalten abgeglichen werden.
- Keine Hard Deletes auf Event-, Suspension-, Exception- oder Reset-Historie.

## 7. Umsetzungsschnitt und offene technische Abhängigkeiten

Dieses Zieldatenmodell ist der vollständige fachliche Zielrahmen. Es bedeutet nicht, dass alle Abläufe in einer einzelnen SQL-Migration umgesetzt werden sollten.

**Erforderliche technische Etappen:**
1. Schema-/Historienfundament, RLS und minimale Grants.
2. Kontrollierte RPCs/Trigger für Eventvergabe, atomare Duplikatverhinderung, Audit, Storno/Korrektur.
3. Sperren-Lifecycle, Zuordnung zu Spieltagen, Ausnahmen, Saisonabschluss und Spielart-Override.
4. Vorzeitiger Sperrausgleich einschließlich Nominierungs-/Absage-Reaktion.
5. Integration in Empfehlung und bestehende Kaderplanung.
6. DEV-Funktionstests, Rechte-/RLS-Tests, Parallelitätstests und Regression.

**Vor SQL-Ausführung noch zu prüfen:**
- Die genaue bestehende Struktur und Policies aller Matchday-Zuordnungs-/Einsatzobjekte sowie Vereinsrollen müssen vor Erteilung der Freigabe erneut gegen DEV abgeglichen werden.
- Die konkrete Ermittlung des nächsten relevanten Spieltags und die aktuelle Saisonwechsel-Logik sind noch nicht als ausführbare DB-Funktionen spezifiziert.
- Die Kaderempfehlung wird derzeit nicht vollständig in `save_matchday_recommendation()` berechnet; tatsächliche Frontend-Berechnungsquelle muss vor Änderung frisch aus `develop/index.html` geprüft werden.
- Lösch-/Archivierungsverhalten bestehender Spieler, Trainings, Teams und Saisons muss in einem separaten Test-/Abgleichschritt geprüft werden.

## 8. Prüf- und Freigabestatus

- Fachliche Anforderungen: aus AP05.2/AP05.3 übernommen.
- DEV-Schema-Grundlage: read-only geprüft.
- Technische Modellprüfung: Entwurf erstellt; keine Live-Änderung.
- SQL-Migration: separater, nicht ausgeführter Entwurf.
- Freigabe: **nicht erteilt**.
