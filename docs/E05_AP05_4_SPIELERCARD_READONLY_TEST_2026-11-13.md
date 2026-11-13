# E05 AP05.4 – Spielercard: automatisierte DEV-Prüfung

**Datum:** 13.11.2026  
**Umgebung:** Supabase DEV `pzazqvvoruqnqhcorbwx`  
**Branch:** `develop`  
**Status:** Read-only Daten-/Codeprüfung abgeschlossen; ein Filterfehler behoben und in DEV-Spiegel verifiziert. Interaktive Browser-/RPC-Praxistests bleiben offen.

## 1. Vorgehen und Datensicherheit

- Ausschließlich SELECT-Abfragen auf Supabase DEV.
- Keine Testdaten angelegt und keine vorhandenen Datensätze verändert.
- Keine SQL-Schreiboperation, keine Migration, keine Schema-/RLS-/RPC-Änderung.
- PROD und GitHub `main` unverändert.
- Da keine Testdaten angelegt wurden, war keine Datenbereinigung erforderlich.

## 2. Datenbestand und Integritätsprüfung

Zum Prüfzeitpunkt:
- 19 Ereignisse und 21 Ereignis-Audit-Einträge.
- 6 Sperren und 25 Sperren-Audit-Einträge.
- 25 aktive Spieler.
- Ereignisstatus: 18 aktiv, 1 storniert.
- Ereignistypen: 10 gelbe Karten, 5 rote Karten, 4 positive Sterne.
- Alle 6 Sperren stehen aktuell auf `open`.

Read-only Integritätschecks:
- 0 Ereignisse ohne zugehöriges Training.
- 0 Ereignisse ohne Trainingsdatum/-name-Snapshot.
- 0 Ereignisse ohne Spielername-Snapshot.
- 0 Sperren mit fehlendem Quellereignis.
- 0 Audit-Einträge ohne Aktion oder Zeitstempel.
- Alle referenzierten Audit-Akteure besitzen ein Profil mit Anzeigenamen.

## 3. Gefundener und behobener Frontendfehler

Ein vorhandenes storniertes Kartenereignis lag in einem Training ohne weitere aktive Karte. Der Filter „Karten“ verwendete bisher ausschließlich `currentEvents` (aktive Ereignisse). Dadurch wurde dieses Training im Kartenfilter ausgeblendet, obwohl die vollständige Historie das stornierte Ereignis korrekt darstellen konnte.

Korrektur in `index.html`:
```js
if(filter==='cards')return t.allEvents.some(e=>e.event_type==='yellow_card'||e.event_type==='red_card');
```

Der Kartenfilter berücksichtigt damit aktive und stornierte gelbe/rote Karten. Die Statusdarstellung innerhalb der Detailhistorie bleibt unverändert.

- Commit: `27eb0dd188016418f4625dc801e19a8c923a659e`
- Neuer `develop/index.html`-Blob: `1c7b23a6e6554548eb840acd9bc4fc92b4300100`
- Der DEV-Spiegel `bautnhaus/jugendmannschaft-dev/main` wurde erneut abgerufen; sein `index.html`-Blob ist identisch und enthält die Korrektur.

## 4. Audit-Namensauflösung – bestätigte Einschränkung

- 16 Ereignis-Audit-Einträge und 12 Sperren-Audit-Einträge besitzen keinen gespeicherten `changed_by_snapshot`.
- Alle betroffenen `changed_by`-IDs lassen sich administrativ einem Profil mit Anzeigenamen zuordnen.
- Die bestehende `profiles_select`-RLS-Policy erlaubt Profil-Lesezugriff jedoch nur auf das eigene Profil oder für Teamadmins auf Profile von Teammitgliedern.
- Trainer können deshalb fremde Akteurprofile nicht zuverlässig nachladen. Die Oberfläche zeigt in diesem Fall „Benutzername nicht hinterlegt“.
- Das ist die bereits dokumentierte Audit-Namensauflösungsgrenze. Eine dauerhafte Lösung über Namens-Snapshots würde ein separates SQL-Konzept und ausdrückliche Freigabe erfordern; wurde hier nicht verändert.

## 5. Noch nicht automatisiert abgenommen

Ohne authentifizierte Browser-Sitzung eines Trainers/Mannschaftsadmins wurden keine Korrektur-RPCs auf bestehenden Datensätzen ausgeführt. Folgende Praxistests bleiben daher offen:
1. Spielercard öffnen; Ereignis- und Sperrenhistorie vollständig und neueste zuerst prüfen.
2. Storniertes Kartenereignis über den Filter „Karten“ finden und Detail-/Auditverlauf öffnen.
3. Gelbe Karte mit Begründung stornieren und wiederherstellen; Kartenkonto und Sperrenzustand prüfen.
4. Rote Karte mit Begründung stornieren und wiederherstellen; Kartenkonto und Sperrenzustand prüfen.
5. Offene Sperre auf einen zulässigen zukünftigen Spieltag verschieben; Audit und Zielzuordnung prüfen.
6. Fehlende Begründung, ungültiges Ziel und fehlende Berechtigung serverseitig abweisen lassen.
7. Trainer-/Mannschaftsadmin-Kontext, Light/Dark Mode, iPhone-Breite und Regression prüfen.

Für diese Schreibtests sollen ausschließlich klar gekennzeichnete Testdatensätze verwendet werden. Falls sie angelegt werden, müssen IDs protokolliert und sämtliche abhängigen Datensätze/Audits nach Abschluss kontrolliert entfernt werden. Keine Änderung an vorhandenen echten DEV-Ereignissen.



## 6. Nutzerbefund und Cachefehler (13.11.2026)

Der Nutzer meldete eine soeben vergebene Karte, die in der Ereignisübersicht fehlte, während die Kennzahl auf der Spielercard aktualisiert war. Die DEV-Datenbank bestätigte das Ereignis als korrekt gespeichert (aktive gelbe Karte, Begründung „Test“, Training 09.11.2026 „Test für dreißig“). Ursache war ein nicht invalidierter `window.playerEventTrainingCache[playerId]` nach erfolgreicher `award_training_behavior_event`-RPC. Die Kennzahlen wurden frisch geladen, die Trainingsliste verwendete dagegen einen alten Cache. Behoben: Cache wird nach erfolgreicher RPC gelöscht und Trainingsereignisse werden neu geladen. Commit `4d127cd39c2ca86e11b7f5c8fbda642f504cdea1`. Der vollständige DEV-Spiegel-`index.html`-Inhalt entspricht exakt dem develop-Inhalt. Keine Datenbank-/Datenänderung und keine Testdaten.


## Nachtrag: Safari-Cache als Ursache der zunächst fehlenden Karte

Der Nutzer hat am 13.11.2026 bestätigt, dass die Karte nach einem vollständigen Neuladen der DEV-Seite in Safari korrekt in der Spielercard-Historie erschien. Die zuvor vermutete Anzeigeursache war somit ein veralteter Browser-Cache. Die Karte war bereits korrekt gespeichert und zugeordnet.

Die Änderung am Filter „Karten“ (Commit `27eb0dd`) ist davon unabhängig: Sie sorgt dafür, dass auch Trainings mit ausschließlich stornierten Kartenereignissen im Kartenfilter auffindbar sind. Sie war nicht die Ursache für das zunächst fehlende aktive Kartenereignis.

Keine Änderung an Datenbank oder PROD.


## Manueller DEV-Test: Gelbe Karte storniert

**Ergebnis: Bestanden (13.11.2026).**

Der Nutzer hat die gelbe Karte von Spieler Nosson bautnhaus im Training vom 09.11.2026 über die Spielercard storniert. Die UI zeigt das Training im Filter „Karten“ weiterhin an und kennzeichnet es mit „Nur zurückgenommene Ereignisse“. Das ist das erwartete Verhalten.

Read-only Datenbankkontrolle bestätigt:
- Ereignis-ID: `a2f1c8c8-23a1-415e-8ed8-528f22d17b7e`
- Ereignistyp: `yellow_card`
- Status: `voided`
- Stornierungsbegründung: `Test`
- Audit-Aktionen: `created`, `voided` (2 Einträge)
- Zugehörige Sperren: keine (0)
- Zugehörige Sperren-Audits: keine (0)

Damit sind Kartenfilter-Auffindbarkeit, Stornierungsstatus und Ereignis-Audit für diesen Fall bestätigt. Da keine Sperre aus diesem Ereignis entstanden ist, gibt es in diesem Testfall keine Sperrenauswirkung zu prüfen.

**Nächster Schritt:** Dasselbe Ereignis wiederherstellen und danach Status, Audit-Aktion `restored`, Kartenkonto und Filterdarstellung erneut kontrollieren. Keine Testdaten wurden angelegt; die bestehende Karte soll in ihren ursprünglichen aktiven Zustand zurückgeführt werden.


## Manueller DEV-Test: Gelbe Karte wiederhergestellt

**Ergebnis: Bestanden (13.11.2026).**

Der Nutzer hat das zuvor stornierte Kartenereignis wiederhergestellt. Die anschließende read-only Datenbankkontrolle bestätigt:
- Ereignis-ID: `a2f1c8c8-23a1-415e-8ed8-528f22d17b7e`
- Typ: `yellow_card`
- Status: `active`
- Stornierungsfelder `voided_at` und `void_reason`: beide `NULL`
- Audit-Aktionen in Reihenfolge: `created`, `voided`, `reinstated` (3 Einträge)
- Zugehörige Sperren: keine

Damit sind Stornierung und Wiederherstellung einschließlich vollständiger Audit-Kette bestätigt. Das Ereignis ist wieder aktiv; es wurde kein künstlicher Testdatensatz angelegt oder gelöscht.


## Manueller DEV-Test: Rote Karte storniert und wiederhergestellt

**Ergebnis: Bestanden (13.11.2026; Nutzerbestätigung plus read-only DB-Prüfung).**

Der Nutzer bestätigte, dass die rote Karte von „Spieler Vorsicht“ bereits storniert und wiederhergestellt wurde. Die Datenbankkontrolle bestätigt den wiederhergestellten Zustand:
- Ereignis-ID: `8004ea0d-0d2b-4085-a5f5-46e967993443`
- Typ: `red_card`
- Ereignisstatus: `active`
- Ereignis-Audit: `created → voided → reinstated` (3 Einträge)
- Zugehörige Sperre: `open`
- Sperrzuordnung: 14.11.2026, Gegner Flensburg
- Sperren-Audit: 5 Einträge; Aktionen `target_changed → created → voided → reinstated → target_changed`

Damit sind Stornierung/Wiederherstellung einer roten Karte und die dazugehörige Sperren-Lebenszyklus-Auditkette im DEV-Fall bestätigt. Die rote Karte und die offene Sperre stehen wieder im aktiven Zustand. Es wurden keine zusätzlichen Testdaten angelegt und keine Datensätze gelöscht.


## Manueller DEV-Test: Sperrenzuordnung geändert

**Ergebnis: Speicherung und Audit bestanden (13.11.2026).**

Der Nutzer hat die offene rote Sperre von „Spieler Vorsicht“ manuell neu zugeordnet. Die anschließende read-only Datenbankprüfung bestätigt:
- Ereignis-ID: `8004ea0d-0d2b-4085-a5f5-46e967993443`, Typ `red_card`, Status `active`.
- Sperren-ID: `e443c3d7-8caf-454b-9f9c-7c97e3415a32`, Status `open`.
- Neue Zielzuordnung: Spieltag am 15.11.2026, Status `planned`.
- Audit-Aktion `corrected` vorhanden (insgesamt 6 Sperren-Audit-Einträge).
- Audit dokumentiert alten Zielspieltag 14.11.2026 gegen Flensburg und neuen Zielspieltag 15.11.2026.
- `manual_target_locked=true` bestätigt die manuelle Zielbindung.
- Sperre blieb während der Korrektur `open`.

Damit sind Speichern, alter/neuer Zielwert, Audit-Nachvollziehbarkeit und Erhalt des offenen Sperrstatus bestätigt. Der neue Zielspieltag hat keinen Gegner-Snapshot; das entspricht dem aktuellen Datensatz des Zielspieltags. Ob die UI die manuelle Zielbindung nach späteren automatischen Neuberechnungen respektiert, ist noch nicht durch einen Folge-/Regressionstest belegt.

Keine Testdaten angelegt oder gelöscht; keine SQL-/Datenbankänderung.


## Manueller DEV-Test: Sperrenzuordnung geändert

**Ergebnis: Speicherung und Audit bestanden (13.11.2026).**

Der Nutzer hat die offene rote Sperre von „Spieler Vorsicht“ manuell neu zugeordnet. Die anschließende read-only Datenbankprüfung bestätigt:
- Ereignis-ID: `8004ea0d-0d2b-4085-a5f5-46e967993443`, Typ `red_card`, Status `active`.
- Sperren-ID: `e443c3d7-8caf-454b-9f9c-7c97e3415a32`, Status `open`.
- Neue Zielzuordnung: Spieltag am 15.11.2026, Status `planned`.
- Audit-Aktion `corrected` vorhanden (insgesamt 6 Sperren-Audit-Einträge).
- Audit dokumentiert alten Zielspieltag 14.11.2026 gegen Flensburg und neuen Zielspieltag 15.11.2026.
- `manual_target_locked=true` bestätigt die manuelle Zielbindung.
- Sperre blieb während der Korrektur `open`.

Damit sind Speichern, alter/neuer Zielwert, Audit-Nachvollziehbarkeit und Erhalt des offenen Sperrstatus bestätigt. Der neue Zielspieltag hat keinen Gegner-Snapshot; das entspricht dem aktuellen Datensatz des Zielspieltags. Ob die UI die manuelle Zielbindung nach späteren automatischen Neuberechnungen respektiert, ist noch nicht durch einen Folge-/Regressionstest belegt.

Keine Testdaten angelegt oder gelöscht; keine SQL-/Datenbankänderung.


## Read-only Analyse: Auslöser der automatischen Sperren-Neuzuordnung

**Datum:** 14.11.2026 · **Umgebung:** Supabase DEV · **Ergebnis:** Mechanismus identifiziert, keine Datenänderung.

- Es existiert kein Trigger auf `matchdays`, `training_behavior_events`, `training_suspensions` oder `training_suspension_exceptions`, der bei beliebigen Spieltagsänderungen automatisch `e05_assign_player_suspensions` ausführt.
- Die zentrale Routine `e05_assign_player_suspensions(p_team_id,p_player_id,p_actor_id)` schützt gültige manuelle Zielbindungen: Sie reserviert zuerst gültige Ziele mit `manual_target_locked=true` und überspringt diese Sperren anschließend unverändert.
- Wird eine manuelle Zielbindung ungültig (z. B. Zielspieltag nicht mehr geplant, nicht mehr zukünftig oder durch aktive Ausnahme ausgeschlossen), wird die Sperre entsperrt und automatisch neu zugeordnet; dies wird auditiert.
- Die Routine wird u. a. von `assign_next_suspension_matchday`, `award_training_behavior_event`, `e05_reconcile_suspensions_after_event_correction`, `grant_suspension_exception`, `revoke_suspension_exception` und `serve_matchday_suspensions` aufgerufen.
- Die manuelle Korrektur selbst erfolgt über `correct_suspension`; sie setzt `manual_target_locked=true`.

**Testdesign:** Für einen kontrollierten Test wird ein isolierter DEV-Testspieler mit eigenem roten Kartenereignis und offener Sperre benötigt. Nach manueller Zielkorrektur wird der bestehende Aufrufweg `assign_next_suspension_matchday` ausgelöst und anschließend geprüft, dass Zielspieltag, `manual_target_locked=true` und Status `open` erhalten bleiben. Danach alle Testdatensätze samt abhängigen Audit-Einträgen vollständig entfernen und per SELECT auf Restbestände prüfen.

Es wurde noch kein Testspieler angelegt und keine Funktion ausgeführt. Ausschließlich Metadaten-/Funktionsdefinitionen lesend geprüft. Keine SQL-Schreiboperation, keine Änderung an DEV-Daten, PROD oder `main`.


## Isolierter DEV-Funktionstest: Schutz manueller Sperrenzuordnung

**Datum:** 14.11.2026 · **Ergebnis:** PASS · **Umgebung:** Supabase DEV

Der Test wurde in einer einzelnen SQL-Transaktion mit fest reservierten Test-UUIDs ausgeführt und am Ende vollständig zurückgerollt.

**Testaufbau**
- Isolierter Testspieler: `ZZ_TEST_E05_MANUAL_TARGET_LOCK`
- Quelle: vorhandenes abgeschlossenes Training vom 09.11.2026 (nur als Referenz; nicht verändert)
- Isoliertes rotes Kartenereignis und offene rote Sperre
- Zunächst automatische Zuordnung auf den nächsten relevanten geplanten Spieltag (14.11.2026)
- Danach manuelle Zielbindung auf den geplanten Spieltag 21.11.2026 mit `manual_target_locked=true`
- Erneuter Aufruf der zentralen Routine `e05_assign_player_suspensions`

**Assertions**
1. Automatische Erstzuordnung erfolgte auf den erwarteten nächsten Spieltag 14.11.2026.
2. Nach erneuter Ausführung der Zuordnungsroutine blieb die manuelle Zielzuordnung auf 21.11.2026 bestehen.
3. `manual_target_locked=true` blieb erhalten.
4. Der Sperrstatus blieb `open`.

Alle Assertions liefen ohne SQL-Exception durch. Die Testtransaktion wurde anschließend mit `ROLLBACK` beendet. Dadurch wurden auch die durch die Routine angelegten Audit-Einträge zurückgerollt. Eine nachgelagerte unabhängige Restbestandsprüfung ergab jeweils **0 Zeilen** für Testspieler, Testereignis, Testsperre und zugehörige Sperren-Audit-Einträge.

**Hinweis zur Ausführung:** Ein erster Testlauf wurde vor Abschluss abgebrochen, weil das Audit-Log append-only ist und DELETE verhindert. Dieser Lauf war nicht erfolgreich abgeschlossen. Der anschließende erfolgreiche Test nutzte deshalb konsequent eine Transaktion mit vollständigem ROLLBACK; die Audit-Schutzregel blieb unverändert.

**Abgrenzung:** Geprüft ist der Schutz gültiger manueller Zielbindungen bei erneutem Aufruf der zentralen Zuordnungsroutine. Nicht geprüft wurden UI-Verhalten, RPC-Berechtigungen unter echten Trainer-/Admin-Sitzungen oder automatische Neuzuordnung nach Ungültigkeit eines manuell gebundenen Spieltags. Keine Änderungen an DEV-Daten nach Testende, keine Migration und keine PROD-Änderung.
