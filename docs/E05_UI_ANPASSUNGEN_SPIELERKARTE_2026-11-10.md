# E05 – UI-Anpassungen Spielerkarte und Ereignishistorie

**Datum:** 10.11.2026  
**Branch:** `develop`  
**Zielumgebung:** Jugendmannschaft DEV  
**Status:** Implementierung in `develop` mit DEV-Korrektur ergänzt; DEV-Praxistest und visuelle Abnahme ausstehend  
**Datenbank:** Ausschließlich read-only geprüft; keine SQL-Änderung und keine Migration  
**PROD:** Nicht verändert

## 1. Verbindliche fachliche Grundlage

- `players.created_at` ist das Eintrittsdatum des Spielers in die Mannschaft.
- Die Ereignisübersicht umfasst alle nicht abgesagten, bereits stattgefundenen Trainings ab diesem Eintrittszeitpunkt – unabhängig von der tatsächlichen Anwesenheit.
- Ereignisstatistiken zählen nur Ereignisse der aktiven Mannschaftssaison.
- Karten zählen gemeinsam (gelbe und rote Karten), Sperren und Sterne separat.
- Es zählen nur aktive Karten/Sterne sowie nicht aufgehobene Sperren. Abgesessene und abgelaufene Sperren zählen weiterhin, aufgehobene Sperren nicht.
- Eine Sperre zählt nur, wenn ihr auslösendes Kartenereignis aktiv ist.
- Stornierte Ereignisse bleiben in der Historie sichtbar, zählen aber nicht in den Kennzahlen oder Ereignisfiltern.
- Die bestehenden Trainings- und Spieltagsstatistiken sowie ihre Detailansichten bleiben unverändert.

## 2. Umgesetzte Frontend-Anpassungen

Datei: `index.html`.

### 2.1 Ereignisstatistik auf der Spielercard

- Die bisherige schmale Kachel „Karten & Sperren“ wurde durch eine große Kachel „Ereignisse“ ersetzt.
- Die Kachel zeigt drei Kennzahlen: Karten, Sperren und Sterne.
- Karten werden als gemeinsame Summe von gelben und roten Karten dargestellt.
- Kennzahlen werden anhand der aktiven Saison (`season.id`) geladen.
- Bei Sperren werden nur nicht aufgehobene Sperren berücksichtigt, deren Quellkarte aktiv ist.
- Die bestehenden Kacheln „Training“ und „Spieltage“ wurden nicht verändert.

### 2.2 Ereignisübersicht

Dreistufiger Ablauf:

1. Ereigniskachel auf der Spielercard.
2. Trainingsübersicht mit den Hauptfiltern „Alle“, „Karten“, „Sperren“ und „Sterne“.
3. Chronologische Ereignishistorie für das ausgewählte Training.

Die Trainingsübersicht lädt Trainings der Mannschaft ab `players.created_at`. Trainings vor dem Mannschaftsbeitritt, abgesagte Trainings und noch nicht stattgefundene Trainings werden nicht angezeigt. Die tatsächliche Anwesenheit ist keine Voraussetzung.

- „Alle“ zeigt auch Trainings ohne Ereignisse mit dem Hinweis „Keine Ereignisse“.
- Die Filter „Karten“, „Sperren“ und „Sterne“ zeigen nur Trainings mit dem jeweiligen aktiven Ereignistyp.
- Gelbe und rote Karten werden im Filter „Karten“ gemeinsam behandelt.
- Stornierte Ereignisse werden im Filter nicht berücksichtigt; bei Trainings, in denen ausschließlich zurückgenommene Ereignisse vorliegen, wird dies kenntlich gemacht.
- Im Trainingsdetail werden Karten, Sterne und Sperren gemeinsam nach Zeitpunkt sortiert angezeigt.
- Auditdetails, Stornogründe und vorhandene Korrekturaktionen bleiben erhalten.
- Nach einer Korrektur oder Sperrenzuordnung wird wieder die Ereignishistorie des betreffenden Trainings geöffnet.

### 2.3 Audit-Benutzerauflösung

- Die Audit-Abfragen lesen jetzt zusätzlich `changed_by`.
- Für Audit-Einträge ohne `changed_by_snapshot` wird der Anzeigename anhand der gespeicherten Benutzer-ID aus `profiles.display_name` aufgelöst, soweit die bestehende RLS-Regel den Zugriff erlaubt.
- Für den aktuell angemeldeten Nutzer wird ergänzend das bereits geladene eigene Profil verwendet.
- Ein vorhandener Snapshot hat weiterhin Vorrang.
- **Berechtigungsgrenze:** Die aktuelle DEV-RLS-Regel erlaubt das Lesen fremder Profile nur Mannschaftsadmins. Trainer können deshalb fremde Audit-Akteure nicht zuverlässig über `profiles` auflösen.
- Eine vollständige, rollenunabhängige Lösung benötigt einen beim initialen RPC-Aufruf serverseitig gespeicherten `changed_by_snapshot`. Dafür wäre eine separate SQL-Änderung an `award_training_behavior_event` nötig. Diese wurde nicht ausgeführt und bleibt bis zu Deiner gesonderten Freigabe offen.
- Es wurde keine Datenbankfunktion und kein Audit-Datensatz verändert.

### 2.4 Ereignisauswahl

- Die gesamte Ereigniskachel ist auswählbar.
- Die Auswahl führt direkt zum nächsten Dialogschritt.
- Der separate Button „Weiter“ entfällt.
- „Abbrechen“ bleibt erhalten.
- Der sichtbare Auswahlindikator entfällt; die vorhandene Radio-Auswahl bleibt technisch verborgen und zugänglich für die Kachelbedienung.

### 2.5 Überschriften und Navigation

- Training: Hauptüberschrift „Training“, Untertitel „Historie für [Spielername]“.
- Spieltage: Hauptüberschrift „Spieltage“, Untertitel „Historie für [Spielername]“.
- Ereignisse: Hauptüberschrift „Ereignisse“, Untertitel „Historie für [Spielername]“.
- Notizen: Hauptüberschrift „Notizen“, Untertitel „Notizen für [Spielername]“.
- Der Navigationspfeil der Statistik-Kacheln ist absolut positioniert und vertikal auf die gesamte Kachelhöhe zentriert.

### 2.6 Dark Mode

- Für die Ereignisauswahl wurden System-Dark-Mode-Regeln ergänzt, die dieselben dunklen Flächen-, Rahmen- und Textfarben wie die manuelle Dark-Mode-Darstellung verwenden.
- Die Kaderzusammenstellung besitzt bereits parallele Regeln für System-Dark-Mode und explizit gesetzten Dark Mode. Diese wurden im aktuellen Quellstand geprüft und nicht unnötig dupliziert.

## 3. Technische Abgrenzung

- Keine Tabellen, Spalten, Trigger, Policies, RPCs oder Edge Functions geändert.
- Keine SQL-Schreiboperation ausgeführt.
- Keine Änderungen an Supabase-Konfiguration oder Auth.
- Keine Änderungen an `main`, PROD, DNS oder Registrar.
- Es wurden ausschließlich Frontend-Code und diese Dokumentation auf `develop` geändert.

## 4. Technische Prüfung

- Aktuelle `develop/index.html` vor jeder Änderung frisch abgerufen.
- JavaScript-Syntaxprüfung für das vollständige Hauptscript und die geänderten Funktionsblöcke erfolgreich.
- Geprüfte Funktionsblöcke: Ereignisübersicht, Ereignisdetail, kombinierte Ereignis-/Sperrenchronologie, Korrekturhandler, Spielercard und Ereignisauswahl.
- Keine Browser-/iPhone-Visualprüfung und kein vollständiger DEV-Praxistest durch den Nutzer durchgeführt.

## 5. DEV-Praxistest – ausstehend

1. Ereigniskachel auf der Spielercard: Karten-, Sperren- und Sternzahlen stimmen für die aktive Saison.
2. Abgesessene und abgelaufene Sperren zählen; aufgehobene Sperren und Sperren mit zurückgenommener Quellkarte zählen nicht.
3. Stornierte Karten/Sterne zählen nicht, bleiben aber in der Trainingshistorie sichtbar.
4. Trainingsliste beginnt exakt ab `players.created_at`; Trainings vor dem Beitritt werden ausgeschlossen.
5. Trainings ohne Ereignisse erscheinen in „Alle“ mit „Keine Ereignisse“.
6. Alle vier Hauptfilter liefern passende Trainings.
7. Ein Training öffnet die gemeinsame chronologische Liste aus Karten, Sternen und Sperren.
8. Audit-Historie zeigt den Namen des initial erfassenden Nutzers sowie Namen bei späteren Änderungen, sofern ein Profilname vorhanden ist.
9. Stornierung/Wiederherstellung einer Karte und Korrektur einer Sperrenzuordnung führen zurück zum passenden Trainingsdetail.
10. Ereignisauswahl: ganze Kachel reagiert, direkter Wechsel zum Folgeschritt, nur „Abbrechen“ als unterer Button.
11. System-Dark-Mode und manuell aktivierter Dark Mode sehen bei Ereignisauswahl und Kaderzusammenstellung gleich aus.
12. Überschriften und Untertitel in Training, Spieltage, Ereignisse und Notizen prüfen.
13. Pfeile in den Statistik-Kacheln bei unterschiedlichen Textlängen vertikal mittig prüfen.
14. iPhone-Breite, Scrollverhalten und Regression der bestehenden Trainings- und Spieltagsstatistiken prüfen.

## 6. Commit-Stand

Die Frontend-Umsetzung wurde in mehreren kleinen Commits auf `develop` vorgenommen. Letzter Code-Commit zum Zeitpunkt dieser Dokumentation:

- `6593809f9027f87256cee9809b58199c3d77065f`

Die Dokumentation wird separat ergänzt. Der aktuelle Branchvergleich zeigt `develop` weiterhin deutlich vor `main`; die Branches sind divergent. Es wurde kein Merge und kein PROD-Deploy ausgelöst.

**Abnahme:** Ausstehend. Die Implementierung ist bereit für den DEV-Praxistest, nicht für einen PROD-Release.


## 7. DEV-Korrektur nach erstem Praxistest (10.11.2026)

Der erste iPhone-Praxistest nach erfolgreichem DEV-Deploy zeigte zwei Punkte:

1. Beim Öffnen der Ereignisübersicht trat `invalid input syntax for type uuid: "undefined"` auf.
2. Die Kennzahlen der Ereigniskachel sollten – wie Variante A vereinbart – jeweils mittig untereinander stehen.

### Ursache und Korrektur

- Ursache des UUID-Fehlers: Die aktiven und inaktiven Spielerdatensätze wurden ohne `team_id` geladen. Die Ereignisübersicht verwendet anschließend `p.team_id` für die Trainingsabfrage.
- Korrektur: `team_id` wurde in die drei relevanten Spielerdaten-Abfragen (aktive Spieler, inaktive Spieler und Backup-Snapshot) aufgenommen.
- Die drei Kennzahlen der Ereigniskachel bleiben in einer dreispaltigen Anordnung. Jede Zahl und ihre Bezeichnung werden nun horizontal zentriert.
- Die Trainings- und Spieltagsstatistikkacheln wurden nicht angepasst.
- Keine SQL- oder RLS-Änderung.

### Offene Verifikation

- Prüfen, ob die Ereignisübersicht nach dem neuen DEV-Deploy ohne UUID-Fehler lädt.
- Prüfen, ob Zahlen und Bezeichnungen auf dem iPhone jeweils mittig untereinander stehen.
- Prüfen, dass Trainings- und Spieltagskacheln optisch und funktional unverändert geblieben sind.

**Code-Korrektur-Commit:** `06db064c8b66571b89aa7410c449e7d38746656c`


## 8. Wiederherstellung der Trainings- und Spieltagskacheln anhand von main (10.11.2026)

Nach dem erneuten DEV-Praxistest wurde gemeldet, dass Trainings- und Spieltagskacheln weiterhin von der Referenzdarstellung abweichen.

- `main/index.html` wurde als visuelle Referenz herangezogen (Referenz-Blob: `ea65f81d53a48bb9a17a15e18b76bfcc3418f6bc`).
- Das vollständige CSS-Grundlayout der Statistik-Kacheln wurde aus main übernommen.
- Die Ereigniskachel behält ihre eigenen Styles. Die absolute Pfeilpositionierung und der zusätzliche rechte Innenabstand sind jetzt ausdrücklich auf `.playerCardTile.events` begrenzt und beeinflussen Training/Spieltage nicht mehr.
- Markup und Berechnungslogik der Trainings- und Spieltagskacheln wurden nicht verändert.
- Keine SQL- oder PROD-Änderung.

**Code-Commit:** `a7f1d8a5ad42505533e880bd50fe309fcd0c6e42`

**Offene Verifikation:** Nach DEV-Deploy Darstellung der beiden Kacheln auf dem iPhone direkt mit main vergleichen.


## 9. Ereigniskachel – Icon, Farbgebung und Abstand (10.11.2026)

Auf Basis des DEV-Praxistests wurde festgelegt:

- Trainings- und Spieltagskacheln sind wieder korrekt und bleiben unverändert.
- Für die Ereigniskachel wird das Google Material Symbol `fact_check` verwendet.
- Die Ereigniskachel erhält eine dezente violette/lavendelfarbene Hinterlegung, passend zur bestehenden grünen Trainings- und blauen Spieltagskachel.
- Für Dark Mode ist eine dunkle Violettvariante mit zurückhaltendem Lavendelakzent definiert.
- Der Abstand zwischen dem Statistik-Kachelraster und der darunterliegenden Notizenkachel wird auf 9 px vereinheitlicht.
- Ereigniskennzahlen bleiben dreispaltig und jeweils mittig ausgerichtet.

**Code-Commit:** `0fa7f1dc3d9384a19d076dee5c103a7adeabea99`

**Offen:** DEV-Deploy abwarten und auf iPhone Light/Dark Mode sowie Abstand zur Notizenkachel prüfen.


## 10. Ereignishistorie – Datenfehler, Filter-Ladeverhalten und Abstand (10.11.2026)

### Befund

Der DEV-Datensatz des im Praxistest geöffneten Spielers bestätigt drei aktive Kartenereignisse in drei Trainings (05.11., 07.11. und 09.11.2026). Die Ereigniskachel zählte diese korrekt. Die Historienliste blieb leer, weil Supabase-Zeitwerte vom Typ `time` als `HH:MM:SS` geliefert werden können, der bisherige Code aber nochmals `:00` anhängte. Dadurch entstand ein ungültiger Zeitstempel (`HH:MM:SS:00`); die Trainingsfilterung schloss alle betroffenen Trainings aus.

### Umsetzung in develop

- Startzeiten werden vor der Date-Konstruktion auf `HH:MM` normalisiert. Damit werden beide üblichen TIME-Darstellungen unterstützt.
- Die Trainings-/Ereignisdaten werden beim ersten Öffnen einmal geladen und pro Spieler im Arbeitsspeicher zwischengespeichert.
- Filterwechsel (Alle/Karten/Sperren/Sterne) werden anschließend clientseitig aus dem Cache gerendert; keine erneuten parallelen Datenbankabfragen und kein erneuter Ladebildschirm pro Filterwechsel.
- Nach Ereignis- oder Sperrenkorrekturen wird der Cache des Spielers invalidiert, damit beim nächsten Öffnen frische Daten geladen werden.
- Der Abstand oberhalb und unterhalb der Ereigniskachel wurde explizit auf 9 px gesetzt.
- Das Icon `fact_check` und die abgestimmte violette Farbgebung bleiben erhalten.

### Verifikation

- DEV-Datenprüfung erfolgte ausschließlich lesend. Keine SQL-Änderung und keine Datenänderung.
- Beide JavaScript-Blöcke in `index.html` wurden nach der Korrektur erfolgreich syntaktisch geprüft.
- **Code-Commits:** `d0f4b920`, `5e62f04d`, `0f54ef0a`.
- **Offen:** erfolgreicher DEV-Deploy und erneuter iPhone-Praxistest der Historienliste, Filterwechsel und Abstände.

PROD/`main` wurden nicht verändert.


## 11. Ereignis- und Notizenkachel sowie Ereignislisten-Layout (10.11.2026)

### Vereinbarte UI-Anpassungen

- Ereigniskachel: Pfeil rechts in der Überschriftenzeile neben „Ereignisse“, nicht mehr vertikal mittig in der gesamten Kachel. Violette Hinterlegung, `fact_check` und die mittig ausgerichteten drei Kennzahlen bleiben erhalten.
- Notizenkachel: gleicher Kopfzeilenaufbau; links Google Material Symbol `sticky_note_2`, danach „Notizen“, Pfeil rechts in derselben Zeile. Die Vorschau des Notizinhalts bleibt darunter.
- Ereignishistorie: Listenzeilen verwenden den vorhandenen `.playerrow.playerHistoryLink`-Aufbau aus den Spielerstatistiken (insbesondere Spieltagshistorie), statt einer eigenständigen Button-Kartenoptik.
- Filtersteuerung: Filterbuttons rufen nun einen expliziten globalen Callback `window.setPlayerEventFilter` auf und markieren den aktiven Filter zusätzlich mit `aria-pressed`.

### Umsetzung und Prüfung

- Umsetzung ausschließlich in `develop/index.html`.
- Beide JavaScript-Blöcke erfolgreich syntaktisch geprüft.
- **Code-Commit:** `7f51efcea288a7b946c2e2a3bf6977f6c2a734c4`.
- **Offen:** DEV-Deploy und iPhone-Praxistest der Listenoptik, Filterreaktion, Kachelpfeile und Notizenüberschrift.

Keine SQL- oder Datenänderungen. `main`/PROD unverändert.


## 12. Abschließende Nutzerbestätigung Ereignisübersicht und Notizenkachel (10.11.2026)

Nach dem erfolgreichen DEV-Deploy und der Überarbeitung hat der Nutzer bestätigt:

- Die Ereignisliste ist optisch stimmig und orientiert sich am bestehenden Statistik-/Spieltagshistorie-Aufbau.
- Die vier Filter (Alle, Karten, Sperren, Sterne) funktionieren zuverlässig.
- Die Ereigniskachel und Notizenkachel entsprechen der abgestimmten Gestaltung.
- Die Trainings- und Spieltagskacheln sind wieder in Ordnung und bleiben unverändert.

**Status: Dieser UI-/Filter-Teilbereich ist im DEV-Praxistest abgenommen.** Diese Abnahme umfasst ausdrücklich nicht die vollständige End-to-End-Prüfung der Auditdetails und Korrekturaktionen der Phase 2.

Der aktuelle DEV-Code-Stand wurde mit Commit `c15375c8786de6f3c1eb1eb729293c0a173a24b5` deployed; GitHub Actions Deploy DEV Run 667 meldet `completed / success`.

Keine SQL-Änderung, keine Änderung an `main` oder PROD.
