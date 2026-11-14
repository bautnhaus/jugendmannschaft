# E05 Phase 3 – Zentrale Ereignisübersicht in der Spielerliste

- **Datum:** 14.11.2026
- **Branch:** `develop`
- **Zielumgebung:** Jugendmannschaft DEV
- **Status:** Erste Frontend-Umsetzung committed; DEV-Deploy und manueller Praxistest ausstehend
- **Grundlage:** `docs/E05_UI_KONZEPT_UMSETZUNGSLEITLINIE_2026-11-07.md`, Abschnitt 4; `docs/AP05_3_USERFLOWS_UI_KONZEPT_2026-11-07.md`, Abschnitt 3.2

## 1. Fachliche Umsetzung

Die bestehende allgemeine Spielerliste wurde um zwei Tabs erweitert:
1. **Anwesenheit** – bisherige Ansicht mit Anwesenheitsstatistik, Sortierung und Positionsfiltern bleibt erhalten.
2. **Ereignisse** – zentrale Karten-, Sperren- und Sterneübersicht für das ausgewählte Team und die aktive Saison.

Die vorhandene Spielerkachel, Suche und Navigation in die bestehende Spielercard werden weiterverwendet. Es wurde keine zweite Spielerliste angelegt.

## 2. Ereignisübersicht

- Datenquelle: aktive Ereignisse aus `training_behavior_events` und offene Sperren aus `training_suspensions`.
- Abfrage ist auf ausgewähltes Team und aktive Saison begrenzt.
- Stornierte Ereignisse werden nicht in den aktiven Kennzahlen gezählt.
- Die vier Filter lauten **Alle**, **Sperren**, **Warnungen**, **Ohne Auffälligkeiten**.
- **Sperren:** mindestens eine offene Sperre.
- **Warnungen:** mindestens vier aktive gelbe Karten.
- **Ohne Auffälligkeiten:** keine offene Sperre und weniger als vier aktive gelbe Karten.
- Suche wirkt gemeinsam mit dem ausgewählten Filter.
- Sortierung nach Handlungspriorität: offene Sperren, vier oder mehr aktive gelbe Karten, andere aktive gelbe Karten, anschließend Spieler ohne aktive Auffälligkeit; innerhalb der Gruppen alphabetisch.
- Offene Sperren erhalten eine sanft rote Kachelhinterlegung; die Warnung ab vier gelben Karten eine sanft gelbe Hinterlegung.
- Kleine Ereignismarker zeigen aktive gelbe Karten, rote Karten und positive Sterne.

## 3. Technische Umsetzung

- Ausschließlich bestehende `renderPlayers()`-Spielerliste und `playerListRow`-Kacheln erweitert.
- Neue Zustände für Listenmodus, Ereignisfilter und geladenen Ereignisstatus.
- Daten werden beim ersten Öffnen des Ereignis-Tabs für Team/Saison geladen und für den aktuellen Kontext im Frontend gehalten.
- Die Anwesenheitsansicht behält ihre bisherige Sortierung und Positionsfilter.
- Die Spielercard wird weiterhin über die bestehende Kachelaktion geöffnet; der Listenmodus und Ereignisfilter bleiben als globaler UI-Zustand erhalten.
- Light-/Darkmode-Farben für Sperr- und Warnkacheln ergänzt.

## 4. Prüfung und Grenzen

- Aktueller `develop/index.html`-Stand vor der Änderung frisch abgerufen.
- JavaScript-Syntaxprüfung des Inline-Hauptscripts erfolgreich (statischer ESM-Import für den Parser ausgeklammert); zweites Inline-Script ebenfalls erfolgreich geprüft.
- Keine SQL-Ausführung, keine Datenbank-/Schema-/RLS-/RPC-Änderung.
- Keine Testdaten angelegt oder verändert.
- Keine Änderung an `main` oder PROD.
- **Noch offen:** DEV-Deploy-Status prüfen; manueller Test beider Tabs, Filterdefinitionen, Prioritätssortierung, Team-/Saisonkontext, Light-/Darkmode und iPhone-Breite.

## 5. Commits

- `a7f37395362598add73e087a951f46597fe5c05c` – zentrale Ereignisübersicht und Tabs.
- `ea41e0c440f21a029b039c21247681b3b92c65b9` – Korrektur der Leveldarstellung im Inaktiv-Kader.
- `e6cd94a918d3fc4a0d0c1cde8ee50d36474e06b0` – Darkmode-Harmonisierung.

**Abgrenzung:** Dies ist die erste Frontend-Umsetzung der zentralen Ereignisübersicht, keine fachliche Abnahme. Die dokumentierten Regeln zu Sortierung, Filtern und Statusdarstellung sind umgesetzt; das tatsächliche Verhalten wird im DEV-Browser geprüft, bevor weitere Anpassungen erfolgen.
