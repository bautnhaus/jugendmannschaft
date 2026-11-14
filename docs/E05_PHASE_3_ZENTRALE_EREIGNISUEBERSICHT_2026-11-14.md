# E05 Phase 3 – Zentrale Ereignisübersicht in der Spielerliste

- **Datum:** 14.11.2026
- **Branch:** `develop`
- **Zielumgebung:** Jugendmannschaft DEV
- **Status:** In DEV deployed und manuell abgenommen; letzter visueller Nachtest System-Lightmode/Tabnavigation am 14.11.2026 bestätigt
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
- **Historischer Zwischenstatus:** Die nachfolgenden manuellen DEV-Tests wurden inzwischen durchgeführt und sind in Abschnitt 6 sowie im Konsolidierungsnachtrag dokumentiert.

## 5. Commits

- `a7f37395362598add73e087a951f46597fe5c05c` – zentrale Ereignisübersicht und Tabs.
- `ea41e0c440f21a029b039c21247681b3b92c65b9` – Korrektur der Leveldarstellung im Inaktiv-Kader.
- `e6cd94a918d3fc4a0d0c1cde8ee50d36474e06b0` – Darkmode-Harmonisierung.

**Abgrenzung:** Dies ist die erste Frontend-Umsetzung der zentralen Ereignisübersicht, keine fachliche Abnahme. Die dokumentierten Regeln zu Sortierung, Filtern und Statusdarstellung sind umgesetzt; das tatsächliche Verhalten wird im DEV-Browser geprüft, bevor weitere Anpassungen erfolgen.


## 6. Manueller DEV-Praxistest – Nutzerbestätigung (14.11.2026)

Der Nutzer hat die Funktionen der zentralen Ereignisübersicht anhand der vorhandenen DEV-Testdaten bestätigt:
- Filter und Darstellungen einschließlich Highlights.
- Sortierung nach Handlungspriorität sowie alphabetische Sortierungen.
- Standardsortierung: Anwesenheit = Kaderempfehlung; Ereignisse = Handlungspriorität.
- Superadmin-Fälle wurden anhand der aktuellen Testdaten ebenfalls bestätigt.

**Klarstellung zum Testumfang (14.11.2026):** Der Mannschaftswechsel wurde bereits zuvor getestet und ist kein offener Prüfpunkt. Ein Saisonwechsel ist derzeit kein Bestandteil der App und daher nicht Gegenstand der Phase-3-Abnahme. Die zuvor aufgeführte offene Prüfung entfällt.

**Bewusste Abgrenzung:** Eine Stornierungs-/Korrekturoption für positive Sterne wird vorerst nicht umgesetzt. Der Nutzer hält sie grundsätzlich für konsistent, stellt sie wegen der geringeren Auswirkungen gegenüber Karten aber zurück. Keine Erweiterung von RPCs, Datenbank oder UI in diesem Punkt.

Keine SQL-/Datenbank-/RLS-/RPC-Änderung und keine Testdatenänderung im Rahmen dieser Bestätigung. PROD und GitHub main unverändert.


## Konsolidierungsnachtrag – Abschluss der Phase-3-Praxistests (14.11.2026)

- Die Nutzerbestätigung in Abschnitt 6 deckt Filter/Darstellungen einschließlich Highlights, Handlungspriorität und alphabetische Sortierungen, die Standardsortierungen sowie Superadmin-Fälle ab.
- Der Mannschaftswechsel wurde bereits getestet und ist kein offener Prüfpunkt. Er wird nicht erneut als offene Aufgabe geführt.
- Ein Saisonwechsel ist derzeit kein Feature der App und ausdrücklich nicht Bestandteil dieser Abnahme.
- Der systemabhängige Lightmode der Ereigniskarten wurde korrigiert und visuell geprüft.
- Die Korrektur der Tabnavigation für den systemabhängigen Lightmode wurde am 14.11.2026 nach DEV-Deploy vom Nutzer mit „Passt“ bestätigt. Die Tabnavigation im System-Lightmode ist damit abgenommen.
- Die bewusste Zurückstellung einer Stornierungs-/Korrekturfunktion für positive Sterne bleibt bestehen.

**Status Phase 3:** Die in diesem Dokument beschriebenen und für Phase 3 vorgesehenen manuellen DEV-Praxistests sind abgeschlossen. Nicht Bestandteil der Abnahme sind ein Saisonwechsel (Feature existiert nicht) sowie die bewusst zurückgestellte Korrekturfunktion positiver Sterne. Keine SQL-/Datenbank-/PROD-Änderung durch diese Dokumentationskonsolidierung.
