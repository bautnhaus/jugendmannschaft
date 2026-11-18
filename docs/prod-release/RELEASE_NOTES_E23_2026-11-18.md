# KADAssist – Release Notes E23: Nominierungsvormerkung

**Release-Status:** vorbereitet, noch nicht veröffentlicht  
**Ziel:** PROD  
**Feature:** E23 – Nominierung für einen kommenden Spieltag vormerken

## Neu in KADAssist

Trainer können Spieler, die an einem Spieltag verfügbar waren, aber aufgrund der Kadergröße nicht berücksichtigt werden konnten, für einen späteren Spieltag vormerken.

- Offene Vormerkungen werden auf dem Ausgangsspieltag sichtbar angezeigt.
- Am späteren Zielspieltag werden vorgemerkte Spieler bei einer ausdrücklichen Neuberechnung der Kaderempfehlung priorisiert.
- Die konfigurierte Kadergröße bleibt unverändert; Vormerkungen erzeugen keine zusätzlichen Plätze.
- Eine tatsächliche Nominierung für einen späteren Spieltag erfüllt die Vormerkung automatisch.
- Wird die erfüllende Nominierung wieder entfernt, wird die Vormerkung erneut geöffnet, sofern keine andere spätere Nominierung besteht.
- Vormerkungen können mit verpflichtender Begründung zurückgenommen werden.
- Statusänderungen bleiben in einer unveränderlichen Audit-Historie nachvollziehbar.
- Sperr-/Ausnahmehinweise und Nominierungsvormerkungen können gleichzeitig angezeigt werden.

## Darstellung und Bedienung

- Vormerkungskennzeichnung mit Unterstützung aller vier Theme-Kombinationen (System-Hell/Dunkel und manuell Hell/Dunkel).
- Dialogdarstellung auf dem iPhone geprüft.
- Anzeige beim Wechsel zwischen Spieltagen geprüft.

## Hinweise

- Die Vormerkung ist keine automatische Nominierung.
- Die Kaderempfehlung des Ausgangsspieltags wird durch das Erstellen einer Vormerkung nicht verändert.
- Die allgemeine Überarbeitung von App-Backup/Restore ist nicht Bestandteil dieses Releases und wird separat behandelt.

## Veröffentlichung

Diese Release Notes sind vorbereitet. Sie dürfen erst nach erfolgreicher PROD-Datenbankmigration, gezieltem Frontend-Deploy und PROD-Smoke-Test veröffentlicht werden.
