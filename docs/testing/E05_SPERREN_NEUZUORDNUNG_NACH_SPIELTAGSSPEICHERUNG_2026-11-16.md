# E05 – Neuzuordnung offener Sperren nach Spieltagsspeicherung

**Datum:** 16.11.2026  
**Branch:** develop  
**Änderung:** Frontend-only  
**PROD:** Funktion nach erfolgreichem Release in PROD enthalten  
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

**Bestanden (16.11.2026).** Der Test wurde in der regulären DEV-Mannschaft durchgeführt:

1. Für Spieler Vier wurde am Training vom 03.12.2026 regulär über die App eine rote Karte erfasst, als noch kein späterer Spieltag existierte.
2. Danach wurde der Spieltag am 06.12.2026 (Gegner „Testgegner“) angelegt und gespeichert.
3. Die zuvor offene Sperre wurde automatisch diesem Spieltag zugeordnet. Read-only wurde `intended_matchday_id`, Snapshot-Datum 06.12.2026, Gegner-Snapshot „Testgegner“ und `manual_target_locked = false` bestätigt.
4. Nach erneutem Öffnen und Neuberechnen blieb Spieler Vier rot gesperrt und aus der Kaderempfehlung ausgeschlossen.

**Ergebnis:** Die automatische Neuzuordnung und der anschließende Sperrenausschluss sind praktisch und anhand des Datenbankzustands bestätigt. Keine SQL-Schreiboperation und keine manuelle Änderung an Karte oder Sperre. PROD blieb während der DEV-Prüfung unverändert.

**PROD-Nachweis:** Die Änderung wurde später gemeinsam mit dem Kaderempfehlungs-Frontend über den bestehenden Workflow `Deploy PROD` erfolgreich ausgerollt. Der anschließende PROD-Smoke-Test wurde vom Nutzer mit „Sieht gut aus“ bestätigt.
