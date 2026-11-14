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


### Visuelle Priorisierung Sperrstatus (12.11.2026)

- Rückmeldung im iPhone-Darkmode: Badge korrekt, aber Kachelfläche blieb dunkel und unterschied sich zu wenig.
- Ursache: nachfolgende CSS-Regeln für normale, empfohlene und nominierte Kacheln überschrieben die früher definierten Sperrfarben. Die Sperrfarbe hatte keine durchgängige visuelle Priorität.
- Fix-Commit: `8fe45438bdf30a25261a6ad8b4e66081b6e8cd7b`.
- Am Ende von `index.html` wird jetzt ein abschließender CSS-Block geladen, der für `.isSuspended` und `.hasSuspensionException` eine deutlich rote Kachelfläche, rote Umrandung und helle Textfarbe erzwingt – unabhängig von Light-/Darkmode sowie Empfehlungs-/Nominierungsstatus. Der Hinweis-Chip bleibt separat sichtbar.
- JavaScript-Syntaxprüfung erfolgreich; CSS-Visualtest im iPhone-Browser steht nach Deployment aus.


### Verbindliche UI-Entscheidung: Kachel nach erteilter Ausnahme (12.11.2026)

- Nutzerentscheidung: Bei regulärer Sperre ohne Ausnahme wird die gesamte Kachel sanft rot hinterlegt und zeigt den Chip „Gesperrt · Ausnahme möglich“.
- Nach Erteilung einer Ausnahme für genau diesen Spieltag entfällt die rote Hinterlegung vollständig. Die Kachel zeigt wieder ihre normale bzw. unabhängig davon geltende Empfehlungs-/Nominierungsdarstellung; der Chip „Ausnahme erteilt“ bleibt sichtbar. Der Spieler ist für diesen Spieltag wieder empfehlungs- und nominierungsfähig.
- Die offene Sperre wird nicht gelöscht oder endgültig aufgehoben. Sie bleibt gemäß AP05.2 für den nächsten relevanten Spieltag bestehen/zugeordnet und erscheint dort wieder als reguläre rote Sperre, sofern keine neue Ausnahme erteilt wird.
- Beide Chips müssen identische Höhe, Schriftgröße, Schriftgewicht, Zeilenhöhe, Innen-/Außenabstände, Rundung und Position direkt unter dem Spielernamen besitzen.
- Gelb bleibt für den vorgemerkten vorzeitigen Sperrausgleich reserviert.
- Diese Änderung ist eine verbindliche UI-Präzisierung. Noch keine Umsetzung in `index.html`; keine SQL-, DB-, RLS-, Auth- oder PROD-Änderung.


### Frontend-Umsetzung Ausnahme-Kachelstatus (12.11.2026)

- Commit: `03b353d7e43ee8146a2c23aafd417b4c698241c2` auf `develop`, ausschließlich `index.html`.
- Bei offener regulärer Sperre wird die Kachel sanft rot hinterlegt und rot konturiert; Chip „Gesperrt · Ausnahme möglich“.
- Bei erteilter Ausnahme für den aktuellen Spieltag wird die rote Hinterlegung/Umrandung entfernt. Die normale Kacheldarstellung greift wieder; Empfehlungs- und Nominierungsfarben bleiben unabhängig davon erhalten. Chiptext lautet nur „Ausnahme erteilt“.
- Beide Chiptexte verwenden dieselbe CSS-Klasse `.matchdayStatusChip` und damit identische Geometrie (min-height, Schrift, Zeilenhöhe, Padding, Margin, Radius, Position im Markup).
- Die Ausnahme-Klasse überschreibt nicht mehr den normalen Status; die rote Gestaltung gilt ausschließlich für `.isSuspended`.
- Beide JavaScript-Scriptblöcke wurden syntaktisch geprüft. DEV-Browser-/iPhone-Praxistest steht noch aus.
- Keine SQL-, Datenbank-, RLS-, Auth-, PROD- oder `main`-Änderung.


### Fachliche Entscheidung Optionsmenü / Rücknahmen (12.11.2026)

- Nutzerentscheidung: Drei-Punkte-Optionsmenü auf allen Spielerkacheln.
- Jede Erteilung und jede Rücknahme benötigt eine verpflichtende Begründung.
- Ausnahme zurücknehmen: sofortige Wiederherstellung der regulären Sperre für den konkreten Spieltag. Der Spieler muss sofort aus einer ggf. bestehenden Nominierung entfernt bzw. deren Fortbestand sicher verhindert werden.
- Vorzeitigen Sperrausgleich erteilen/zurücknehmen ebenfalls im Optionsmenü; Rücknahme muss die offene Sperrzuordnung sofort anhand der bestehenden AP05.2-Regeln neu bewerten. Abgeschlossene Vorgänge bleiben unverändert.
- Keine Hard Deletes; Audit-Historie bleibt erhalten.
- Technische Bestandsaufnahme der bereits dokumentierten DEV-Pakete: revoke_suspension_exception(uuid,text) ist in Paket 6 vorhanden; schedule_early_suspension_reset(...) und cancel_early_suspension_reset(...) sind in Paket 8 vorhanden. Vor Frontend-Integration sind deren exakte Signaturen, Rückgabewerte, Berechtigungen und Seiteneffekte gegen den aktuellen DEV-Datenbankstand zu verifizieren.
- Kritischer offener Prüfpunkt: Der dokumentierte Widerrufs-RPC muss darauf geprüft werden, ob eine bereits bestehende matchday_players-Nominierung unmittelbar und atomar entfernt/verhindert wird. Falls nicht, ist vor Umsetzung ein separater DB-Änderungsentwurf inkl. Audit, Rollback und Tests vorzulegen. Noch keine DB-Änderung freigegeben.

## Read-only Prüfung der sofortigen Ausnahme-Rücknahme (12.11.2026)

**Live-DEV-Befund:** Die RPCs grant_suspension_exception(uuid,uuid,text), revoke_suspension_exception(uuid,text), schedule_early_suspension_reset(uuid,uuid,text) und cancel_early_suspension_reset(uuid,text) sind vorhanden. Die vier RPCs verlangen jeweils eine Begründung und prüfen Teamrolle Trainer/Admin oder Superadmin im ausgewählten Teamkontext. Die RPC-Execute-Rechte liegen für die vier Nutzeraktionen bei authenticated; interne Helfer sind nicht als öffentliche Nutzer-RPCs freigegeben.

**Kritischer Befund:** revoke_suspension_exception widerruft die Ausnahme, schreibt den Audit-Eintrag und stößt die Neuzuordnung der offenen Sperre an. Die Funktion entfernt jedoch keine vorhandene Zeile aus matchday_players. Der bestehende Trigger prevent_suspended_matchday_nomination() blockiert nur INSERT/UPDATE einer Nominierung, wenn keine aktive Ausnahme vorliegt. Er entfernt keine bereits vorhandene Nominierung und sperrt derzeit auch nicht zuerst die Spielerzeile, um konkurrierende Nominierung und Ausnahme-Widerruf zu serialisieren.

**Tabellenbefund:** matchday_players hat den Primärschlüssel (matchday_id,player_id), eine Delete-RLS-Policy für berechtigte Teammitglieder und einen separaten Trigger zur Stornierung vorgemerkter vorzeitiger Sperrausgleiche bei Nominierung. Es gibt keinen Trigger, der eine bestehende Nominierung bei Ausnahme-Widerruf entfernt.

**Folgerung:** Sofortige Rücknahme ist mit dem aktuellen DB-Stand nicht vollständig gewährleistet. Ein Frontend allein kann dies nicht sicher lösen. Vor der UI-Integration ist eine atomare DB-Erweiterung notwendig: Widerrufs-RPC entfernt innerhalb derselben Transaktion eine vorhandene Nominierung für exakt den betroffenen Spieltag und ergänzt den Audit-Payload um die Information, ob eine Nominierung entfernt wurde. Der Nominierungs-Guard muss die Spielerzeile vor seiner Sperrprüfung mit demselben Lock-Order sperren, damit parallele Nominierungen nicht nach dem Widerruf durchrutschen.

**Entwurf:** docs/drafts/DB-MIG-DRAFT_E05_EXCEPTION_REVOKE_IMMEDIATE_2026-11-12.sql auf develop. Dieser Entwurf ist nicht als Supabase-Migration angelegt, nicht ausgeführt und benötigt vor Ausführung vollständige Prüfung und separate ausdrückliche Freigabe.

**Frontend-Read-only-Befund:** index.html enthält derzeit den Ablauf zur Ausnahme-Erteilung, aber noch keinen Widerrufs- oder Sperrausgleich-Optionsflow auf den Spielerkacheln. Spielerkacheln werden derzeit als Button gerendert; das Optionsmenü muss deshalb als Geschwisterelement in einem Wrapper umgesetzt werden, nicht als verschachtelter Button. Die vorhandenen Klassen .matchdayOptionsWrap und .matchdayOptionsMenu aus den Trainingskomponenten können als Stil-/Interaktionsbasis dienen.

**Status:** Datenbankprüfung und Frontend-Bestandsaufnahme abgeschlossen. Keine SQL-Ausführung und keine Frontend-Codeänderung. Frontend-Umsetzung bleibt bis zur Freigabe und erfolgreichen DEV-Prüfung der DB-Erweiterung zurückgestellt.

## 11. Konsolidierter Live-Abgleich Supabase DEV (14.11.2026)

Dieser Abschnitt hat Vorrang vor älteren Entwurfs- und Zwischenstandsformulierungen in den Abschnitten 1–10.

### Tatsächlich registrierter Migrationsstand

- DB-MIG-2026-011 ist in Supabase DEV unter Version `20261112181910`, Name `20261112191000_e05_suspension_nomination_guard`, registriert.
- Die tatsächlich registrierte Fassung ist die Migration `supabase/migrations/20261112191000_e05_suspension_nomination_guard.sql`. Die frühere Datei mit Präfix `20261112120000` ist ein älterer Entwurfsstand und nicht die registrierte Fassung.
- Live vorhanden ist `public.save_matchday_recommendation(uuid,uuid[])` als SECURITY INVOKER mit search_path `pg_catalog, public`; die Funktion enthält die Sperrenprüfung.
- Live vorhanden ist `public.prevent_suspended_matchday_nomination()` als SECURITY INVOKER mit search_path `pg_catalog, public`.
- Live vorhanden ist der Trigger `matchday_players_prevent_suspended_nomination` auf `matchday_players` für BEFORE INSERT OR UPDATE OF `matchday_id, player_id`.
- Die drei bestehenden Trigger auf `matchday_players` sind ebenfalls vorhanden. Der neue Guard verwendet einen transaktionsbezogenen Advisory Lock auf der Spieler-ID, damit er mit der Ausnahme-Rücknahme synchronisiert werden kann.
- Die ältere Entwurfsbeschreibung in Abschnitt 3 (dedizierte SECURITY DEFINER-Funktion und zwei Trigger einschließlich `matchday_recommendation_players`) beschreibt nicht die tatsächlich registrierte Fassung und ist nicht als Live-Architektur zu verwenden.

### Nachfolgende Migration zur atomaren Ausnahme-Rücknahme

- Die Supabase-DEV-Migrationshistorie enthält zusätzlich Version `20261113035705`, Name `e05_atomic_exception_revocation_20261113`.
- Die Live-Definition von `revoke_suspension_exception(uuid,text)` bestätigt: Spielerbezogener Advisory Lock und Players-Zeilensperre; Widerruf und Sperren-Neuzuordnung innerhalb derselben Transaktion; Entfernung einer bestehenden Nominierung nur dann, wenn die Sperre nach Neuzuordnung wieder genau diesem Spieltag zugeordnet ist; tatsächlicher Einsatz (`played=true`) verhindert den Widerruf; Audit-Payload enthält `nomination_removed` und den Snapshot der entfernten Nominierung.
- Der Live-Nominierungs-Trigger verwendet denselben Advisory-Lock-Mechanismus. Die Prüfung auf parallele Nominierung und Widerruf ist damit in der aktuellen DEV-Definition synchronisiert.
- **Nachweisgrenze:** Die zu Version `20261113035705` gehörende Original-Migrationsdatei und ein zugehöriges Rollback konnten im GitHub-Verzeichnis `supabase/migrations` bzw. `supabase/rollback` nicht gefunden werden. Die Live-Definition belegt den aktuellen Funktionsstand, ersetzt aber nicht den fehlenden unveränderlichen Nachweis des tatsächlich ausgeführten SQL-Texts. Dieser Nachweis ist vor einem PROD-Rollout zu ergänzen oder ausdrücklich als nicht verfügbar zu akzeptieren und separat freizugeben.

### Aktueller Test-/Abnahmestatus

Die manuellen DEV-Abnahmen der Sperren-/Ausnahmefälle, der Spielercard und der Rollen (A1–A6 sowie T1–T8) sind in den E05-Abnahmeunterlagen dokumentiert. Die sechs Spieltagskader-/Sperrenfälle wurden ebenfalls vom Nutzer bestätigt. Die Migration 011 ist damit nicht mehr als „Praxistest ausstehend“ zu führen. Eine vollständige automatisierte Prüfung sämtlicher RLS-Policies und RPC-Berechtigungsgrenzfälle wurde jedoch nicht durchgeführt.

PROD und GitHub `main` wurden durch diesen Abgleich nicht verändert.


## 12. Nachweis der nachfolgenden atomaren Ausnahme-Rücknahme (14.11.2026)

Der Original-SQL-Nachweis wurde im Repository gefunden. Die vorherige Aussage, die Original-Migrationsdatei sei nicht vorhanden, war falsch; sie lag unter `docs/` und nicht unter `supabase/migrations/`.

- Original-SQL: `docs/E05_SQL_ENTWURF_WIDERRUF_AUSNAHME_MIT_NOMINIERUNGSENTFERNUNG_2026-11-12.sql` (Git-Blob-SHA `5b5ac4fd8c14be5bc00ff8d4774ad1d1ac9800b0`).
- Rollback-Entwurf: `docs/E05_SQL_ROLLBACK_ENTWURF_WIDERRUF_AUSNAHME_2026-11-12.sql` (Git-Blob-SHA `630c6949faa6e45daf9c758364cb11eb86b09a65`); nicht ausgeführt.
- Ausführungs-/Testnachweis: `docs/E05_UMSETZUNGSVORSCHLAG_SPERRMASSNAHMEN_OPTIONSMENUE_2026-11-12.md`, Abschnitte 10.7–10.10. Dort sind DEV-Migrationseintrag `20261113035705`, Live-Verifikation, isolierte Funktionstests und ein bestandener Zwei-Session-Konkurrenztest dokumentiert.
- Das PROD-Gate ist daher nicht mehr das Wiederfinden des SQL, sondern die Erstellung einer sauber versionierten PROD-Migration und die Prüfung des Rollback-/Wiederherstellungsplans. Die bestehende Rollback-Datei ist nur ein Review-Entwurf.
