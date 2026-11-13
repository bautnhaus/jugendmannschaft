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
