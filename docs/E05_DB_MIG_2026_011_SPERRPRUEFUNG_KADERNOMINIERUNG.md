# DB-MIG-2026-011 – Sperrprüfung für Kaderempfehlung und Nominierung

**Stand:** 12.11.2026  
**Branch:** develop  
**Zielumgebung:** Supabase DEV ausschließlich  
**Status:** In Supabase DEV erfolgreich ausgeführt und read-only technisch verifiziert; Praxistest ausstehend  
**PROD / main:** unverändert

## 1. Ziel und verbindliche Fachentscheidung

Ein Spieler mit einer offenen Sperre, deren `intended_matchday_id` dem aktuellen Spieltag entspricht, wird als gesperrt behandelt.

- Regulär gesperrte Spieler dürfen nicht in einer gespeicherten Kaderempfehlung enthalten sein.
- Regulär gesperrte Spieler dürfen nicht in `matchday_players` nominiert werden.
- Eine aktive Ausnahme (`training_suspension_exceptions.revoked_at IS NULL`) für genau diesen Spieltag erlaubt Empfehlung und Nominierung.
- Die Ausnahme hebt die Sperre nicht auf. Die bestehende Ausnahme-RPC protokolliert die Entscheidung und verschiebt die offene Sperre auf den nächsten Spieltag.
- Nach Widerruf greift die Sperrenprüfung wieder, sobald die Sperre diesem Spieltag erneut zugeordnet ist.
- Es werden keine bestehenden Nominierungen automatisch gelöscht.

## 2. DEV-Ausgangsbasis read-only geprüft

Projekt: `pzazqvvoruqnqhcorbwx`.

### Bestehende RPC

`public.save_matchday_recommendation(uuid,uuid[])`:
- PL/pgSQL, SECURITY INVOKER, search_path `pg_catalog, public`.
- Owner: postgres.
- EXECUTE: postgres, authenticated, service_role.
- Prüft Spieltag, Teammitgliedschaft, Duplikate, Spielerexistenz, Mannschaftszugehörigkeit und Aktivität.
- Eine Sperrenprüfung fehlte.

### Bestehende Ausnahmefunktionen

- `grant_suspension_exception(uuid,uuid,text)`
- `revoke_suspension_exception(uuid,text)`

Beide sind SECURITY DEFINER mit search_path `pg_catalog, public, auth`; Owner postgres; EXECUTE für authenticated. Sie bleiben unverändert. Die Grant-Funktion verlangt Begründung und genau den aktuell zugeordneten geplanten Spieltag; sie protokolliert Audit und ordnet danach die offene Sperre neu zu. Die Revoke-Funktion protokolliert den Widerruf und berechnet die Zuordnung neu.

### Bestehende Trigger und RLS

Auf `matchday_players` existieren bereits:
- BEFORE INSERT: `require_active_player_for_new_assignment`
- BEFORE UPDATE OF player_id: derselbe Trigger
- AFTER INSERT OR UPDATE OF matchday_id, player_id: `e05_cancel_early_reset_on_nomination`

Diese Trigger bleiben erhalten. Die Migration ergänzt einen eigenständigen BEFORE-Trigger und ändert keine RLS-Policy. Die aktuellen Policies für `matchday_players` und Empfehlungstabellen erlauben berechtigten Teammitgliedern die jeweiligen Schreiboperationen; deshalb ist die serverseitige Triggerprüfung notwendig.

## 3. Umfang der Migration

### A. Neue Triggerfunktion

`public.e05_assert_matchday_player_not_suspended()`

- SECURITY DEFINER ausschließlich zum zuverlässigen Lesen des Sperr-/Ausnahmestatus unabhängig von der RLS-Sichtbarkeit.
- Fest gesetzter search_path `pg_catalog, public, auth`.
- Liest nur; keine Datenänderungen.
- Wird für beide Tabellen verwendet:
  - `matchday_players`: Zielspieltag direkt aus `NEW.matchday_id`.
  - `matchday_recommendation_players`: Zielspieltag über `matchday_recommendation_runs.matchday_id`.
- Blockiert eine offene Sperre für diesen Spieltag, sofern keine aktive Ausnahme für genau diesen Spieltag existiert.
- Sperrt den gefundenen Sperrdatensatz während der Prüfung, um die Prüfung mit Ausnahmeerteilung/-widerruf zu serialisieren.
- EXECUTE wird für PUBLIC, anon, authenticated und service_role widerrufen; Funktion wird nur durch Trigger aufgerufen.

### B. Trigger

- `e05_guard_matchday_nomination_suspension` auf `matchday_players`, BEFORE INSERT OR UPDATE OF matchday_id, player_id.
- `e05_guard_matchday_recommendation_suspension` auf `matchday_recommendation_players`, BEFORE INSERT OR UPDATE OF recommendation_id, player_id.

Damit sind sowohl die normale RPC als auch direkte Tabellen-Schreibpfade abgesichert.

### C. Bestehende Empfehlungs-RPC

Die bestehende `save_matchday_recommendation(uuid,uuid[])` wird per guarded source transformation erweitert. Vor der Änderung muss der geprüfte Quelltextmarker genau einmal vorhanden sein; andernfalls bricht die Migration ab.

Die bisherige Funktion und alle bestehenden Prüfungen bleiben erhalten. Ergänzt wird die Sperrenprüfung mit Ausnahme für denselben Spieltag. Signatur, SECURITY INVOKER, Owner und EXECUTE-ACLs bleiben erhalten.

## 4. Dateien

- Migration: `supabase/migrations/20261112120000_e05_suspension_nomination_guard.sql`
- Rollback: `supabase/rollback/20261112120000_e05_suspension_nomination_guard_rollback.sql`
- Diese Spezifikation: `docs/E05_DB_MIG_2026_011_SPERRPRUEFUNG_KADERNOMINIERUNG.md`

Die Migration ist transaktional. Das Rollback stellt die vorab gelesene ursprüngliche RPC-Definition wieder her und entfernt nur die beiden neuen Trigger sowie die neue Triggerfunktion.

## 5. Bewusst nicht enthalten

- Keine Änderung an `grant_suspension_exception` oder `revoke_suspension_exception`.
- Keine Änderung an anderen E05-Sperrenfunktionen.
- Keine RLS-Policy- oder Tabellenänderung.
- Keine automatische Entfernung bestehender Nominierungen.
- Keine Frontendänderung.
- Keine Änderung an bestehenden Sperren, Ausnahmen, Empfehlungen oder Nominierungen.
- Keine PROD-Änderung.

## 6. Testplan nach gesonderter Freigabe und Ausführung

1. Migration wird in DEV in einer Transaktion ausgeführt.
2. Funktionsdefinition, Triggerdefinitionen, Owner, SECURITY-Attribut, search_path und ACLs werden vor/nachher verglichen.
3. Regulär gesperrter Spieler: Empfehlungs-RPC lehnt ab.
4. Ungesperrter Spieler: Empfehlungs-RPC funktioniert.
5. Spieler mit aktiver Ausnahme für genau diesen Spieltag: Empfehlungs-RPC funktioniert.
6. Direkter INSERT in `matchday_recommendation_players` für gesperrten Spieler: Trigger lehnt ab.
7. Direkter INSERT in `matchday_players` für gesperrten Spieler: Trigger lehnt ab.
8. Nominierung mit aktiver Ausnahme: funktioniert.
9. Ausnahme widerrufen und Sperre wieder diesem Spieltag zugeordnet: Empfehlung/Nominierung wird abgelehnt.
10. Andere Spieltage ohne dort zugeordnete Sperre bleiben unberührt.
11. Bestehende Trigger `require_active_player_for_new_assignment` und `e05_cancel_early_reset_on_nomination` bleiben aktiv.
12. Bestehende Datensätze werden nicht verändert.

## 7. Rollback

Rollback nur nach gesonderter Freigabe. Er entfernt beide neuen Trigger und die dedizierte Triggerfunktion und stellt die vor Migration geprüfte Definition von `save_matchday_recommendation(uuid,uuid[])` wieder her. Die Migration führt keine Datenänderungen durch; es sind daher keine Daten-Rückkorrekturen vorgesehen.

## 8. Freigabestatus

Dieses Paket ist zur fachlichen und technischen Prüfung bestimmt. Es wurde nicht in Supabase ausgeführt, nicht in der Migrationshistorie registriert und nicht deployed. Eine gesonderte ausdrückliche Freigabe ist vor jeder Ausführung erforderlich.


## 9. Ausführung und technische Nachprüfung (12.11.2026)

- Nach ausdrücklicher Freigabe wurde die Migration in Supabase DEV angewendet. Tool-Rückgabe: `success: true`.
- Registrierte Supabase-Migration: Version `20261112181910`, Name `20261112191000_e05_suspension_nomination_guard`.
- Neuer Trigger `matchday_players_prevent_suspended_nomination` vorhanden: BEFORE INSERT OR UPDATE OF matchday_id, player_id.
- Die drei bisherigen Trigger auf `matchday_players` sind weiterhin vorhanden; insgesamt nun vier nicht-interne Trigger.
- `save_matchday_recommendation(uuid,uuid[])`: SECURITY INVOKER unverändert, search_path `pg_catalog, public`, ursprüngliche EXECUTE-ACL `postgres, authenticated, service_role` erhalten; Funktionsdefinition enthält die Sperrenprüfung.
- Neue Triggerfunktion: SECURITY INVOKER, search_path `pg_catalog, public`; EXECUTE nicht an PUBLIC/anon/authenticated vergeben.
- Die acht bestehenden RLS-Policies auf `matchday_players` sind weiterhin vorhanden. Es wurden keine RLS-Policies geändert.
- Keine Tabellen-/Spaltenänderung und keine bestehenden Sperren, Ausnahmen oder Nominierungen bearbeitet.
- **Noch offen:** Funktionale Negativ-/Positivtests mit kontrollierten DEV-Testdaten sowie Rollen-/Ausnahmepraxistest. Bis dahin gilt die technische Installation als verifiziert, die fachliche Abnahme aber als offen.
- PROD und GitHub `main` unverändert.


## 10. Eigenständige Tests und Frontend-Anbindung (12.11.2026)

### Datenbanktests
- **Negativtest Nominierung:** Direkter INSERT-Versuch für Tom (offene Sperre, Spieltag 14.11.2026) wurde durch `prevent_suspended_matchday_nomination()` mit SQLSTATE `23514` und verständlicher Sperrmeldung abgewiesen. Es wurde kein Datensatz angelegt.
- **Positivtest Nominierung:** Direkter INSERT-Versuch für einen nicht gesperrten aktiven Spieler wurde innerhalb einer Transaktion ausgeführt und sofort zurückgerollt. Trigger ließ den Vorgang passieren; keine Bestandsänderung blieb bestehen.
- **Bestandskontrolle:** Tom und Spieler Dreißig sind weiterhin nicht für den Spieltag nominiert; es existiert weiterhin keine Ausnahme für diesen Spieltag.
- **Nicht automatisiert testbar:** Die Empfehlungs-RPC und die Ausnahme-RPCs benötigen einen authentifizierten Nutzer mit Teamrolle/ausgewähltem Superadmin-Kontext. Ein SQL-Admin-Call kann `auth.uid()` und die echte Benutzerrolle nicht repräsentieren. Diese Tests folgen im Browser.

### Frontend
- Commit auf `develop`: `32afa447a7b6e9baf46d1c55412fd03023c39339`.
- Aktiver Spieltag lädt offene Sperren und Ausnahmen team-/spieltagsbezogen.
- Regulär gesperrte Spieler werden aus `top16Ranking()` ausgeschlossen, bleiben aber in der Spieltagsliste sichtbar.
- Gesperrte Kacheln sind rot markiert und zeigen „Gesperrt · Ausnahme möglich“.
- Klick auf gesperrten Spieler öffnet den begründungspflichtigen Ausnahmedialog; Aufruf von `grant_suspension_exception(p_suspension_id,p_matchday_id,p_reason)`.
- Nach erfolgreicher Ausnahme werden Sperren/Ausnahmen neu geladen; die Kachel bleibt rot und zeigt „Ausnahme erteilt“. Danach ist eine manuelle Nominierung möglich.
- Gespeicherte Empfehlung wird vor Übernahme erneut auf Sperren geprüft.
- JavaScript-Syntaxprüfung der beiden Script-Blöcke erfolgreich.
- **Noch offen:** Browser-Praxistest mit Trainerkonto, Ausnahme/Widerruf, Rollen und iPhone-Layout. Die UI enthält in diesem Schritt noch keine separate Widerrufsaktion; bestehende Widerrufs-RPC bleibt unberührt und kann im nächsten UI-Feinschliff angebunden werden.



### Korrektur nach DEV-Sichtprüfung (12.11.2026)

- Fehlerursache: Die Spieltagsansicht verwendete dieselbe gefilterte Rangliste wie die Empfehlung. Dadurch wurden gesperrte Spieler vollständig aus der sichtbaren Spielerliste entfernt.
- Korrektur-Commit: `33637e3297e97ff3306142cce6492b37e92d760c`.
- Die Ranglistenfunktion akzeptiert jetzt `includeSuspended`. Die Spieltagsansicht zeigt alle Spieler inklusive gesperrter Spieler; die Berechnung/Speicherung der Empfehlung verwendet weiterhin die gefilterte Standardrangliste.
- Gesperrte Spieler erhalten zusätzlich den sichtbaren Hinweis „Gesperrt · Ausnahme möglich“; bei aktiver Ausnahme „Ausnahme erteilt“.
- JavaScript-Syntaxprüfung erneut erfolgreich. Browser-Praxistest weiterhin ausstehend.


### Hotfix Mannschaftsöffnung (12.11.2026)

- Fehlerursache: Bei der vorherigen Korrektur wurde der Spieltagsstatus-Ausdruck versehentlich auch in `renderPlayers()` (aktive und inaktive allgemeine Spielerliste) eingefügt. Dort existiert keine lokale Variable `md`; dadurch entstand beim Öffnen des Mannschaftskontexts „Can't find variable: md“.
- Hotfix-Commit: `66c9619336e9627758956c21aa6543db43263cd0`.
- Die beiden spieltagfremden Ausdrücke wurden aus `renderPlayers()` entfernt. Der Spieltagskader behält die Sperrkennzeichnung. JavaScript-Syntaxprüfung erneut erfolgreich.
- Browser-Retest nach Deployment erforderlich. PROD und `main` unverändert.


### Zweite Korrektur Spieltagsliste (12.11.2026)

- Ursache des weiterhin leeren/verkürzten Kaders: `renderMatchday()` rief weiterhin `top16Ranking()` ohne `includeSuspended=true` auf. Die zuvor ergänzte Option war nur für die allgemeine Spielerverwaltung verwendet worden. Zusätzlich nutzte die Sortierung in `matchdayFilteredPlayers()` weiterhin den gefilterten Rang.
- Korrektur-Commit: `2ddd68328d24282386ef375974f284c93a4e2eea`.
- Spieltagsliste und deren Sortier-Rangliste verwenden nun `top16Ranking(true)`: alle Spieler bleiben sichtbar; die Empfehlungsermittlung nutzt weiterhin standardmäßig `top16Ranking()` und schließt gesperrte Spieler aus.
- JavaScript-Syntaxprüfung beider Script-Blöcke erfolgreich. Browser-Retest nach Deployment erforderlich.


### Sichtbarkeit von Sperre und Ausnahme (12.11.2026)

- Nutzer-Rückmeldung: Spieler korrekt aus Empfehlung ausgeschlossen und sichtbar; Sperrstatus jedoch optisch nicht dargestellt. Nach Ausnahme blieb Kachel optisch unverändert.
- Ursache: Kachel-Markup setzte CSS-Klassen, enthielt aber keinen Sperr-/Ausnahme-Badge. Nach Grant wird die offene Sperre auf den Folge-Spieltag verschoben; der Ausnahme-Datensatz für den ursprünglichen Spieltag bleibt bestehen. Die UI konnte daher die Ausnahme erkennen, zeigte aber keinen Status.
- Korrektur-Commit: `4d9bafc5b6c00d9cf41b5aff685d9300a857c4f1`.
- Kachel enthält jetzt Badge „Gesperrt · Ausnahme möglich“ bzw. „Gesperrt · Ausnahme erteilt“. Rotdarstellung und Badge-Farben sind explizit für Light- und Darkmode definiert. Die Sperre bleibt nach Ausnahme rot gekennzeichnet; manuelle Nominierung bleibt möglich.
- JavaScript-Syntaxprüfung beider Script-Blöcke erfolgreich. Browser-Retest erforderlich.


### Korrektur Statusanzeige / Lade-Reihenfolge (12.11.2026)

- Ursache 1: Beim Öffnen eines Spieltags aus einem anderen Tab-Kontext kehrte `openMatchday()` nach `showTab('matchday')` vor dem Laden des Sperrstatus zurück. Die erste Darstellung erfolgte dadurch ohne Sperrdaten; das anschließende asynchrone Rendern war nicht in allen Navigationspfaden zuverlässig.
- Ursache 2: Nach erfolgreicher Ausnahme wurde der Spieltag neu geladen. Falls die RLS-Lesepolicy den gerade erteilten Exception-Datensatz nicht zurücklieferte, fehlte der sichtbare Status trotz erfolgreicher Grant-RPC.
- Ursache 3: Die Statusklassen waren bereits im Kachel-Markup vorgesehen, aber es fehlte eine robuste, explizite Badge-Darstellung im Darkmode.
- Fix-Commits: `8bcfccf77ef514cb4df386cff9f6aea0800b13e2` und `c1329fa7b326f89cd5ea820ff682240ddd74f37b`.
- `openMatchday()` startet jetzt das Laden auch beim Wechsel aus einem anderen Tab und rendert nach Abschluss erneut. Nach erfolgreicher Grant-RPC wird der bestätigte Ausnahmezustand lokal für die laufende Ansicht erhalten. Gesperrte und ausnahmeberechtigte Kacheln erhalten rote Umrandung/Hintergrund und einen Textstatus: „Gesperrt · Ausnahme möglich“ bzw. „Gesperrt · Ausnahme erteilt“.
- JavaScript-Syntaxprüfung erfolgreich. iPhone-/Browser-Praxistest nach DEV-Deployment noch erforderlich.
