# Epic 23 – Frontend-Korrekturen zur Nominierungsvormerkung

**Branch:** `develop`  
**Datei:** `index.html`  
**Commits:** `ce54b42e25209e2b01eeb44c60cb0dde75d042ec`, `9ade1cb8554267c2f448a560116b9ce5baed764c`

## Umgesetzte Änderungen

- Nach einer Nominierung oder dem Abwählen eines Spielers lädt das Frontend die offenen Nominierungsvormerkungen erneut. Damit wird die serverseitige Erfüllung bzw. Wiederöffnung direkt in der Kachel dargestellt.
- Wird eine neue Vormerkung erstellt und existiert bereits eine gespeicherte Kaderempfehlung, wird diese unmittelbar neu berechnet und gespeichert.
- Die Priorisierung bleibt Bestandteil der Sortierung: vorgemerkte Spieler stehen vor nicht vorgemerkten Spielern; die konfigurierte Kader-Zielgröße begrenzt weiterhin die gespeicherte Empfehlung. Vormerkungen erzeugen keine zusätzlichen Empfehlungsslots.
- Das blaue Vormerkungslabel erhält explizite Farben für Hellmodus, manuell aktivierten Darkmode und systemgesteuerten Darkmode.
- Vormerkungsdialoge verwenden dieselbe 40/60-Buttonaufteilung wie die Sperrdialoge und einen definierten Abstand zwischen Begründungsfeld und Aktionen.

## Noch zu testen in DEV

1. Vormerkung auf der Kachel des Ausgangsspieltags sichtbar.
2. Vormerkung erscheint blau in System-Hell, System-Dunkel, manuellem Hell- und manuellem Dunkelmodus.
3. Nach Erstellung wird eine bereits gespeicherte Empfehlung aktualisiert; Anzahl bleibt exakt die konfigurierte Zielgröße.
4. Nominieren erfüllt die Vormerkung; versehentliches Abwählen öffnet sie erneut und zeigt den Hinweis wieder.
5. Rücknahme über das Optionenmenü entfernt die Vormerkung erst nach Bestätigung und mit Begründung.
6. Buttonbreiten und Abstand zur Textbox auf dem iPhone prüfen.

**PROD:** unverändert. Kein Merge nach `main` und kein PROD-Deploy.
