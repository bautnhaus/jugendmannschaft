# E05 – Neuzuordnung offener Sperren nach Spieltagsspeicherung

**Datum:** 16.11.2026  
**Branch:** develop  
**Änderung:** Frontend-only  
**PROD:** Nicht berührt  
**Datenbank / Migrationen:** Unverändert

## Ausgangslage

Eine offene Sperre kann zunächst ohne `intended_matchday_id` bestehen, wenn zum Zeitpunkt der Kartenerfassung noch kein geeigneter zukünftiger Spieltag existiert. Wird später ein Spieltag angelegt oder ein bestehender Spieltag in die Zukunft verschoben, wurde die Zuordnungsfunktion bisher nicht erneut aufgerufen.

Beispiel DEV-Testmannschaft:
- Spieler: TEST C – Regelmäßig, solide
- Rote Karte: aktiv
- Sperre: `open`
- Spieltag 4 nach Verschiebung: 29.11.2026, `planned`
- Sperre hatte weiterhin `intended_matchday_id = NULL`

## Umsetzung in develop

In `index.html` wurde `reassignOpenTeamSuspensions()` ergänzt.

Ablauf:
1. Nach erfolgreichem Anlegen oder Speichern eines Spieltags werden die offenen Sperren der aktuellen Mannschaft geladen.
2. Für jeden betroffenen Spieler wird der bestehende authentifizierte RPC `assign_next_suspension_matchday(p_team_id, p_player_id)` aufgerufen.
3. Die RPC- und E05-Berechtigungsprüfungen bleiben serverseitig maßgeblich.
4. Der Frontend-Cache der Sperrenzuordnung wird invalidiert und für den aktuellen Spieltag neu geladen.
5. Bei einem RPC-Fehler bleibt der bereits gespeicherte Spieltag bestehen; die Oberfläche zeigt ausdrücklich an, dass die Sperren-Neuzuordnung fehlgeschlagen ist.

Die Neuzuordnung wird sowohl nach dem Anlegen eines Spieltags als auch nach dem Bearbeiten eines Spieltags ausgeführt. Damit werden insbesondere Datumsänderungen und Statusänderungen berücksichtigt.

## Sicherheit / Umfang

- Keine neue RPC- oder SQL-Funktion.
- Keine direkte Änderung von `training_suspensions` aus dem Frontend.
- Keine Änderung der E05-Sperrenregeln oder der Spielarten-Konfiguration.
- Der bestehende RPC prüft weiterhin angemeldeten Benutzer und Teamrolle bzw. ausgewählten Teamkontext.
- Es werden nur offene Sperren der aktuellen Mannschaft angefragt.
- Keine Änderung an PROD.

## Teststatus

**Codeänderung committed; Praxistest nach Deploy in DEV ausstehend.**

Zu testen:
1. TEST C hat eine offene rote-Karte-Sperre ohne Spieltagszuordnung.
2. Den bestehenden Spieltag 4 (29.11.2026, geplant) bearbeiten und speichern.
3. Prüfen, dass die Sperre TEST C diesem Spieltag zugeordnet wird.
4. Spieltag neu öffnen und prüfen, dass TEST C als gesperrt erscheint.
5. Kaderempfehlung neu berechnen und prüfen, dass TEST C ausgeschlossen wird.
6. Optional: Ausnahme erteilen und zurücknehmen; prüfen, dass Sperrstatus und Zuordnung erwartungsgemäß wechseln.

Ein erfolgreicher Code-Commit ist noch kein Nachweis eines erfolgreichen DEV-Laufzeittests.
