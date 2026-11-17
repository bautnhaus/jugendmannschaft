# Epic 23 – Frontend-Korrekturen zur Nominierungsvormerkung

**Branch:** `develop`  
**Datei:** `index.html`  
**Commits:** `ce54b42e25209e2b01eeb44c60cb0dde75d042ec`, `9ade1cb8554267c2f448a560116b9ce5baed764c`

## Umgesetzte Änderungen

- Nach einer Nominierung oder dem Abwählen eines Spielers lädt das Frontend die offenen Nominierungsvormerkungen erneut. Damit wird die serverseitige Erfüllung bzw. Wiederöffnung direkt in der Kachel dargestellt.
- Eine Vormerkung bleibt auf ihrem Ausgangsspieltag als Hinweis sichtbar.
- Die Priorisierung greift ausschließlich bei einem Spieltag, dessen Datum NACH dem Ausgangsspieltag liegt. Am Ausgangsspieltag selbst verändert sie weder Rangfolge noch Kaderempfehlung.
- Beim Erstellen einer Vormerkung wird eine bereits gespeicherte Empfehlung nicht automatisch neu berechnet oder überschrieben. Der Trainer berechnet die Empfehlung am späteren Zielspieltag ausdrücklich neu.
- Die Priorisierung bleibt Bestandteil der Sortierung: vorgemerkte Spieler stehen vor nicht vorgemerkten Spielern; die konfigurierte Kader-Zielgröße begrenzt weiterhin die gespeicherte Empfehlung. Vormerkungen erzeugen keine zusätzlichen Empfehlungsslots.
- Die vorherige automatische Neuberechnung am Ausgangsspieltag wurde entfernt, da sie fachlich nicht der Spezifikation entsprach.
- Das blaue Vormerkungslabel erhält explizite Farben für Hellmodus, manuell aktivierten Darkmode und systemgesteuerten Darkmode.
- Vormerkungsdialoge verwenden dieselbe 40/60-Buttonaufteilung wie die Sperrdialoge und einen definierten Abstand zwischen Begründungsfeld und Aktionen.

## Noch zu testen in DEV

1. Vormerkung auf der Kachel des Ausgangsspieltags sichtbar.
2. Vormerkung erscheint blau in System-Hell, System-Dunkel, manuellem Hell- und manuellem Dunkelmodus.
3. Vormerkung am Ausgangsspieltag verändert dessen gespeicherte Empfehlung nicht.
4. Am späteren Zielspieltag wird die Vormerkung erst nach „Neu berechnen“ priorisiert; die Anzahl bleibt exakt die konfigurierte Zielgröße.
5. Nominieren erfüllt die Vormerkung; versehentliches Abwählen öffnet sie erneut und zeigt den Hinweis wieder.
6. Rücknahme über das Optionenmenü entfernt die Vormerkung erst nach Bestätigung und mit Begründung.
7. Buttonbreiten und Abstand zur Textbox auf dem iPhone prüfen.

**PROD:** unverändert. Kein Merge nach `main` und kein PROD-Deploy.


## Ergänzende Korrektur – zeitliche Trennung von Ausgangs- und Zielspieltag (17.11.2026)

**Ursache:** Die zuvor implementierte Empfehlungslogik verwendete alle für den geöffneten Spieltag gelieferten offenen Vormerkungen auch am Ausgangsspieltag selbst. Außerdem löste das Erstellen einer Vormerkung die automatische Neuberechnung der gespeicherten Empfehlung dieses Ausgangsspieltags aus.

**Korrektur auf develop:**
- `top16Ranking()` priorisiert eine Vormerkung nur, wenn `source_matchday_date < currentMatchday.date`.
- Auf dem Ausgangsspieltag bleibt der Hinweis „Nominierung vorgemerkt“ sichtbar; die Vormerkung fließt dort nicht in die Empfehlungsrangfolge ein.
- Beim Erstellen wird keine vorhandene Empfehlung automatisch neu berechnet oder gespeichert.
- Die Vormerkung wird am späteren Zielspieltag erst nach einer ausdrücklichen Neuberechnung durch den Trainer berücksichtigt.
- Datenbank und Supabase-Migrationen bleiben unverändert.

**Commit:** `e9ae7a436557aa99de602da04565e088b0d6ffef`  
**index.html Blob-SHA:** `1f7492db8f5e21e0eead3e1f934a76ff3a8df2c2`

**DEV-Praxistest erforderlich:** Vormerkung am 21.11. erstellen; prüfen, dass die Empfehlung vom 21.11. unverändert bleibt; am 29.11. „Neu berechnen“ und prüfen, dass der Spieler priorisiert wird. Kaderzielgröße muss unverändert bleiben.

**PROD:** unverändert; keine Übernahme nach `main`.


## DEV-Praxistest-Status – Rückmeldung 17.11.2026

### Theme-Prüfung

- **System-Dunkelmodus:** bestanden.
- **Manueller Hellmodus:** bestanden.
- **Manueller Dunkelmodus:** bestanden.
- **System-Hellmodus:** noch offen; Nutzer prüft zu einem späteren Zeitpunkt.

Die drei geprüften Varianten zeigen das blaue Label „Nominierung vorgemerkt“ gut lesbar. Die Theme-Prüfung ist damit teilweise bestanden, aber noch nicht vollständig abgeschlossen.

### Weitere offene iPhone-Tests

- Vormerkung mit Begründung zurücknehmen.
- Rücknahme ohne Begründung verhindern.
- Dialoggestaltung prüfen (40/60-Buttonaufteilung und Abstand zwischen Begründungsfeld und Buttons).


### Rücknahme-Praxistest – Nutzerergebnis 17.11.2026

- **Rücknahme mit Begründung:** bestanden; Vormerkung konnte erfolgreich zurückgenommen werden.
- **Rücknahme ohne Begründung:** bestanden; die Aktion wurde verhindert.
- **Offen:** Dialoggestaltung auf dem iPhone (40/60-Buttonaufteilung und Abstand zwischen Begründungsfeld und Buttons).
- **Weiterhin offen:** System-Hellmodus.
