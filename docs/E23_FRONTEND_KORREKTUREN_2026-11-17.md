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


## Separate UI-Anpassung E05 – Ausnahme zurücknehmen (17.11.2026)

Auf ausdrücklichen Wunsch wurde ausschließlich der Dialog **„Ausnahme zurücknehmen“** auf eine 40/60-Aufteilung der Aktionsbuttons angepasst.

- Die Änderung ist über die eigene Klasse `e05ExceptionRevokeDialog` und den CSS-Selektor `.e05ExceptionRevokeDialog` isoliert.
- Andere E05-Dialoge (z. B. vorzeitigen Sperrausgleich vormerken / Vormerkung zurücknehmen) bleiben unverändert.
- E23-Dialoge bleiben unverändert.
- Keine Funktions- oder Datenbankänderung.

**Commit:** `323d261f0617cf14c440b1dc8fb95b7ed8bdf8e4`  
**index.html Blob-SHA:** `5dfbbaedcfb0d75a6761cf5428dc4ba22bc46f89`

**DEV-Praxistest:** iPhone-Darstellung des Dialogs prüfen; übrige Dialoge auf unverändertes Layout kontrollieren.
**PROD:** unverändert; keine Übernahme nach `main`.


### Abschließender UI-Test – isolierter E05-Dialog (17.11.2026)

- **Dialog „Ausnahme zurücknehmen“ mit 40/60-Buttonaufteilung:** vom Nutzer auf DEV/iPhone geprüft und bestätigt.
- **Ergebnis:** bestanden.
- Die Änderung bleibt ausschließlich auf diesen Dialog begrenzt; andere E05- und E23-Dialoge sind nicht betroffen.
- **PROD:** unverändert.


## Abgrenzung Backup/Restore – Entscheidung 17.11.2026

**Verbindliche Entscheidung:** Die grundsätzliche Überarbeitung von Backup/Restore ist kein Blocker und kein Abnahmekriterium für Epic 23 (Nominierungsvormerkung).

- Epic 23 wird unabhängig von einer allgemeinen Backup-/Restore-Überarbeitung abgenommen und weitergeführt.
- Die Vormerkungs- und Audit-Historie bleibt regulärer Bestandteil der Datenbank und ihrer Datenbanksicherungen.
- Vor einer späteren PROD-Übernahme sind die für Epic 23 erforderlichen Datenbankmigrationen und die reguläre PROD-Sicherung separat nach dem bestehenden Freigabeprozess zu behandeln.
- Die Backup-/Restore-Funktion der Anwendung wird in einem separaten Vorhaben grundsätzlich analysiert und überarbeitet. Dabei ist insbesondere zu prüfen, ob sämtliche Stammdaten, Zustände, Ereignisse und Historien vollständig und referenziell konsistent exportiert und wiederhergestellt werden.
- Zu prüfen sind unter anderem Trainings/Anwesenheiten, Spieltage/Nominierungen/Einsätze, Sperren/Ausnahmen sowie Vormerkungen/Audit-Historie. Die vollständige fachliche und technische Bestandsaufnahme erfolgt im separaten Vorhaben.

**Status:** Abgrenzung beschlossen; separates Epic/Backlog-Thema zur Anlage und Ausarbeitung vorgesehen. Keine Backup-Code- oder Datenbankänderung im Rahmen von Epic 23.
