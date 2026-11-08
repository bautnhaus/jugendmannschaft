# E05 – Technisches Zieldatenmodell

**Stand:** 08.11.2026  
**Branch:** `develop`  
**Status:** Technischer Entwurf, intern geprüft; nicht ausgeführt und nicht zur Ausführung freigegeben  
**Zielumgebung für den ersten Rollout:** ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**Fachliche Grundlage:** AP05.2 und AP05.3; UI- und Umsetzungsleitlinie in `docs/E05_UI_KONZEPT_UMSETZUNGSLEITLINIE_2026-11-07.md`.

## 1. Leitentscheidung

Die E05-Daten werden nicht in vorhandene Anwesenheits- oder Kaderzeilen hineingeschrieben. Sie erhalten eigene, historisierte Tabellen. Die vorhandenen Trainings-, Spieler-, Saison-, Team- und Spieltagsobjekte bleiben bestehen und werden referenziert. Die bestehende UI und ihre Datenflüsse werden später erweitert; dieses Datenmodell erzeugt keine Ersatzseiten und verändert keine vorhandenen Daten.

**Wichtig:** Diese erste Migration ist bewusst eine reine Foundation-Migration. Sie legt Tabellen, Indizes, Constraints, RLS-Read-Policies und minimale Leserechte an. Sie enthält noch keine schreibenden RPCs, keine automatische Sperrenfortschreibung, keine Saisonabschlussroutine und keine Änderung an `save_matchday_recommendation()`. Diese Funktionen werden nach Prüfung des tatsächlichen Frontend-/Backend-Datenflusses in eigenen SQL-Änderungen vorbereitet und separat freigegeben.

## 2. Vorhandene Datenbasis (DEV read-only geprüft)

- `trainings`: enthält `team_id`, optional `season_id` und Status `planned / done / cancelled`. In DEV haben derzeit 12 von 14 Trainings keinen `season_id`. Die spätere Vergabe-RPC muss deshalb die aktive Saison der Mannschaft ermitteln und als historischen Ereigniskontext speichern; sie darf nicht blind `trainings.season_id` übernehmen. Wenn keine aktive Saison existiert, muss die Vergabe mit verständlicher Meldung abgewiesen werden.
- `attendance`: Primärschlüssel `(training_id, player_id)`, Feld `present boolean`.
- `players`: enthält aktuelle `team_id` und `active`; Teamwechsel werden bereits durch einen bestehenden Trigger geschützt.
- `seasons`: Mannschaftsbezogene Saisons.
- `matchdays`: enthält `team_id`, optional `season_id`, `game_type`, `status planned / done / cancelled`.
- `matchday_players` und `matchday_attendance`: Kaderzuordnung und tatsächliche Teilnahme sind getrennt.
- `matchday_recommendation_runs` und `matchday_recommendation_players`: gespeicherte Empfehlung ist getrennt.
- `team_member_roles`: Teamrollen `trainer` und `admin`; `is_team_member(team_id)` schließt bestehende Teammitglieder und Superadmins im ausgewählten Teamkontext ein. Vereinsadmins haben keinen automatischen Schreibzugriff auf Teamereignisse.
- Bestehende relevante Policies sind teambezogen. Bestehende Kernobjekte haben RLS aktiviert.

## 3. Tabellen und Beziehungen

### 3.1 `training_behavior_events` – einzelne Trainingsereignisse

Eine Zeile pro vergebenem Ereignis.

| Feld | Bedeutung |
|---|---|
| `id` | UUID |
| `team_id`, `season_id` | unveränderlicher historischer Kontext bei Vergabe |
| `training_id`, `player_id` | konkretes Training und Spieler |
| `event_type` | `yellow_card`, `red_card`, `positive_star` |
| `reason` | Karte verpflichtend, Stern optional |
| `awarded_by`, `awarded_at` | vergebende Person und Zeitpunkt |
| `voided_at/by/reason` | kontrolliertes Storno, kein Hard Delete |
| `reinstated_at/by/reason` | kontrollierte Reaktivierung nach Audit |

Constraints:
- maximal eine aktive Karte (gelb **oder** rot) pro Spieler/Training;
- maximal ein aktiver Stern pro Spieler/Training;
- Karte braucht Begründung;
- Storno/Reaktivierung braucht jeweils Begründung;
- historische Zeile wird nicht gelöscht.

Die eindeutigen Teilindizes berücksichtigen stornierte Ereignisse nicht. Damit kann nach einem Storno ein neues Ereignis angelegt werden; die Historie bleibt erhalten.

### 3.2 `training_behavior_event_audit` – Ereignisänderungen

Pro Anlage, Korrektur, Storno oder Reaktivierung wird ein Auditdatensatz mit Aktion, alten/neuen Werten, Begründung, Benutzer und Zeit gespeichert. Direkte Client-Schreibrechte werden nicht erteilt.

### 3.3 `training_suspensions` – Sperren

Eine Sperre wird als eigenständiger Vorgang geführt und über `triggering_event_id` mit der auslösenden Karte verbunden.

- `suspension_type`: gelb oder rot.
- `status`: offen, verbüßt oder abgelaufen.
- `intended_matchday_id`: nächster vorgesehener relevanter Spieltag.
- `served_matchday_id`: tatsächlich verbüßender Spieltag.
- Historischer Team-/Saisonbezug bleibt gespeichert.

Gelbe und rote Sperren sind getrennte Datensätze. Gelb- und Rot-Sperren können nacheinander offen sein. Die fachliche Reihenfolge (gelb vor rot) wird von der späteren Lebenszykluslogik durchgesetzt, nicht durch einen fragilen Datenbank-Constraint.

### 3.4 `training_suspension_exceptions` – spieltagsspezifische Ausnahmen

Eine Ausnahme bindet eine offene Sperre an einen konkreten Spieltag. Sie enthält zwingend Grund, erteilende Person und Zeitpunkt. Widerruf ist ebenfalls begründungspflichtig. Die Ausnahme verbraucht die Sperre nicht; die offene Sperre wird auf den nächsten relevanten tatsächlich stattfindenden Spieltag verschoben.

### 3.5 `training_suspension_audit` – Sperren-Audit

Pro Anlage, Zuweisungsänderung, Verbüßung, Ablauf, manueller Korrektur und Ausnahmeänderung wird der Vorher-/Nachher-Zustand nachvollziehbar protokolliert.

### 3.6 Spielart-Konfiguration

- `club_suspension_game_type_settings`: Vereinsstandard der sperrenrelevanten Spielarten.
- `team_suspension_game_type_overrides`: vollständiger Mannschafts-Override.
- Existiert ein Team-Override-Datensatz, ersetzt dessen Liste den Vereinsstandard vollständig. Eine leere Liste bedeutet bewusst: keine Spielart zählt. Ohne Team-Override gilt der Vereinsstandard.
- Zulässige technische Werte: `championship`, `friendly`, `tournament`. Die aktuell vorhandenen Werte sind `Meisterschaft`, `Freundschaftsspiel`, `Turnier` und `NULL` (4 von 9 Spieltagen). Die Lifecycle-Logik muss diese drei Werte eindeutig auf `championship`, `friendly`, `tournament` abbilden; `NULL` zählt nicht automatisch als sperrenrelevant und muss bei Bedarf vor einer späteren Verbüßungsentscheidung fachlich behandelt werden.

### 3.7 `matchday_early_suspension_resets` – vorzeitiger Sperrausgleich

- Konkreter Spieler, Mannschaft, Saison und Spieltag.
- Pflichtbegründung, erstellende Person und Zeitpunkt.
- Status `pending / applied / cancelled`.
- Wird nur nach tatsächlicher Durchführung genau dieses Spieltags angewendet.
- Bei Absage wird storniert; keine Übertragung auf einen anderen Spieltag.
- Ist unabhängig von der Zahl gelber Karten und kein regulär verbüßter Sperrtermin.
- Eine offene rote oder bereits ausgelöste Sperre wird nicht aufgehoben.

### 3.8 `training_behavior_audit_log` – Querschnitts-Audit

Zusätzliches Team-Audit für Konfigurationsänderungen und Aktionen, die mehrere E05-Objekte betreffen. `entity_id` ist polymorph; die konkrete Fachreferenz liegt in den jeweiligen Tabellen/Audit-Tabellen. Es ersetzt nicht die direkten Event- und Suspension-Audits.

## 4. Historien- und Löschschutz

Die bestehenden Trainings-/Spieler-/Teamtabellen enthalten teils `ON DELETE CASCADE`. Das wäre für E05-Historien gefährlich. Deshalb verwenden E05-Historientabellen auf ihre Elternbezüge `ON DELETE RESTRICT`. Ein Spieler, Training, Team oder eine Saison mit E05-Historie kann nicht versehentlich durch Cascade gelöscht werden. Nutzerreferenzen verwenden `ON DELETE SET NULL`, damit Audit-/Ereignisdaten bei Kontolöschung erhalten bleiben.

## 5. RLS, Rollen und Rechte

- Alle neuen Tabellen erhalten RLS.
- Leserechte für `authenticated` sind teambezogen über die vorhandene Funktion `public.is_team_member(team_id)` begrenzt; Superadmins benötigen weiterhin den ausgewählten Teamkontext.
- Vereinsadmins erhalten nicht automatisch Zugriff auf Ereignisvergabe oder Sperrenkorrektur.
- Die Foundation-Migration erteilt keine direkten INSERT-/UPDATE-/DELETE-Rechte an `authenticated`. Schreibzugriffe erfolgen später ausschließlich über geprüfte RPCs mit expliziter Rollen- und Teamkontextprüfung, Begründungs- und Auditpflicht.
- `SECURITY DEFINER` wird nicht pauschal verwendet. Wenn eine spätere RPC es wegen atomarer Mehrtabellenoperationen benötigt, wird sie mit festem `search_path`, `auth.uid()`-Prüfung, expliziter EXECUTE-ACL und Security-Advisor-Prüfung entworfen.

## 6. Noch getrennt zu implementierende Logik

Diese Foundation allein löst noch keine fachlichen Abläufe aus. Separate Migrationen/RPCs sind erforderlich für:

1. Vergabe eines Ereignisses nur durch berechtigte Trainer/Teamadmins; serverseitige Prüfung der tatsächlichen Anwesenheit und desselben Teams/Saisonbezugs.
2. Atomare Ereignisvergabe inkl. Audit und DB-Duplikatvermeidung.
3. Fünf aktive gelbe Karten → gelbe Sperre; gelbe Zählung wird erst nach tatsächlicher Verbüßung oder bestätigtem vorzeitigem Sperrausgleich zurückgesetzt.
4. Rote Karte → sofortige rote Sperre; gelber Kontostand bleibt unverändert.
5. Relevante Spielarten: Team-Override vor Vereinsstandard; nur tatsächlich durchgeführte Spieltage zählen; abgesagte Spieltage zählen nicht.
6. Mehrere offene Sperren werden nacheinander bedient, gelb vor rot.
7. Ausnahme verschiebt eine offene Sperre sofort weiter, unabhängig von tatsächlichem Einsatz.
8. Saisonwechsel: aktive gelbe Zählung zurücksetzen; offene Sperren verfallen; Historie bleibt.
9. Teamwechsel: historische Ereignisse/Sperren bleiben dem ursprünglichen Team zugeordnet.
10. Vorzeitiger Sperrausgleich: nur auf konkretem Spieltag, nur bei Nichtnominierung, keine gleichzeitige Nominierung; bei späterer Nominierung oder Absage automatisch stornieren; nur nach tatsächlichem Stattfinden anwenden.
11. Kaderempfehlung: Sperrprüfung vor Berechnung; Stern-Einfluss der letzten sechs tatsächlich durchgeführten Trainings der aktuellen Saison mit begrenztem Gewicht; genaue numerische Gewichtung bleibt vor Implementierung zu validieren.

## 7. Prüfmatrix für die Foundation-Migration

| Prüffeld | Prüfung |
|---|---|
| Idempotenz | Migration nur einmal ausführbar; keine stillen `IF NOT EXISTS`-Umgehungen für unerwartete Altobjekte |
| Datenbestand | Keine UPDATE-/DELETE-/TRUNCATE-Anweisung; keine Bestandsdatenmigration |
| Constraints | Pflichtgründe, Ereignistypen, Statuswerte, eindeutige aktive Karten/Sterne |
| Historie | Fremdschlüssel verhindern Cascade-Löschung |
| RLS | RLS auf allen neun neuen Tabellen aktiv |
| ACL | `anon` keine Rechte; `authenticated` ausschließlich SELECT |
| Rollen | Teammitgliedschaft erforderlich; Superadmin nur im ausgewählten Kontext; Clubadmin nicht automatisch schreibberechtigt |
| Transaktion | gesamte Migration in einer Transaktion |
| Bestehende Objekte | keine Änderung an bestehenden Tabellen, Policies, Funktionen, Triggern oder Empfehlungen |

## 8. Prüfhinweise / offene technische Prüfpunkte vor Ausführung

- Die Existenz und Spalten von `public.user_club_context` wurden in DEV bestätigt (`user_id`, `club_id`, `selected_at`). Die Club-Settings-Policy muss Vereinsadmins im ausgewählten Vereinskontext und Teammitglieder der Vereinsmannschaften lesen lassen; die SQL-Datei wird entsprechend begrenzt.
- Die tatsächlichen `matchdays.game_type`-Werte müssen vor der Lifecycle-Implementierung vollständig ausgelesen und kanonisch zugeordnet werden.
- Der aktuelle Frontend-Datenfluss der Kaderempfehlung ist noch nicht vollständig aufgerufen; die bestehende Speicher-RPC validiert Teammitgliedschaft und Spieler, nicht die Sperrenberechtigung.
- Vor Ausführung müssen die Migrationsdatei und der vollständige SQL-Text gegen den tatsächlichen aktuellen Migrationsordner und die Projektregeln gegengeprüft werden.

## 9. Freigabestatus

**Technisch vorbereitet – noch nicht freigegeben und nicht ausgeführt.**  
Diese Datei ist kein Nachweis einer Datenbankänderung. Der Nutzer muss die konkrete SQL-Migration ausdrücklich freigeben. PROD bleibt vollständig ausgeschlossen.
