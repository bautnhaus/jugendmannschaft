# E05 – Korrekturen nach iPhone-Praxistest der Ereignisübersicht

- **Datum:** 14.11.2026
- **Branch:** `develop`
- **Ziel:** DEV
- **Status:** Umsetzung committed; DEV-Deploy und erneuter iPhone-Praxistest ausstehend

## Rückmeldungen und Umsetzung

1. **Spielerbereich an Trainingsbereich angleichen**
   - Die separate Kartenkontur zwischen Spieler-Überschrift und Listeninhalt wurde entfernt.
   - Überschrift, Hinzufügen-Schaltfläche, Tabs, Suche, Filter und Liste liegen jetzt in derselben `trainingPageCard`, analog zum Trainingsbereich.

2. **Tabs / Darkmode**
   - Die Tabs „Anwesenheit“ und „Ereignisse“ erhalten eine eigene, explizite Gestaltung mit zurückhaltender Umrandung, klarer aktiver Fläche und passenden Farben für Light-/Darkmode.
   - Die Regeln verwenden die vorhandene Theme-Kennung `data-theme` und berücksichtigen außerdem die systemabhängige dunkle Darstellung.

3. **Filter „Ohne Auffälligkeiten“**
   - Umbenannt in **„Highlights“**.
   - Der Filter zeigt Spieler mit mindestens einem aktiven positiven Sternereignis (`positive_star`).
   - Damit wird die Kategorie fachlich für herausragende Leistungen genutzt.

4. **Doppelte Warnung bei bereits offener Sperre**
   - Eine Warnung ab vier aktiven gelben Karten wird nur noch angezeigt, wenn keine offene Sperre für den Spieler vorliegt.
   - Der Filter „Warnungen“ verwendet dieselbe Abgrenzung.
   - Bei Tom Achtzehn Jahre werden damit die offene Sperre und die Zahl von fünf aktiven gelben Karten angezeigt; der zusätzliche Warnhinweis „4 gelbe Karten“ entfällt. Die fünf Karten bleiben als Ereigniszahl sichtbar und werden nicht künstlich auf vier begrenzt.

## Technische Prüfung

- `index.html` vor Änderung frisch aus `develop` abgerufen.
- Beide Inline-JavaScript-Blöcke erfolgreich syntaktisch geprüft.
- Keine SQL-/Datenbank-/RLS-/RPC-Änderung und keine Testdaten.
- Keine Änderung an `main` oder PROD.
- DEV-Deploy und erneute visuelle Prüfung auf iPhone stehen aus.

## Commit

- `014bc1d86804cb894d18b12c5c5be1eec82342c5` – Layout, Tabs, Filter und Warnlogik.


## Nachkorrektur Abstände (14.11.2026)

Der obere und untere Außenabstand der Tabs „Anwesenheit / Ereignisse“ wurde auf `10px` gesetzt und entspricht damit dem vertikalen Abstand der `.trainingSegmented`-Bedienelemente im Trainingsbereich. Commit: `5c4949f746331d5f3d7ebbe8d54c5a112f383f7e`. DEV-Deploy/Praxistest noch ausstehend.


## Ereignis-Chips – dezente Kontur (14.11.2026)

Die Ereignis-Chips erhalten analog zu den Positions-Chips eine feine Kontur (`1px solid #0000000a`). Im Darkmode wird eine dezente helle Kontur (`#ffffff14`) verwendet. Ziel ist eine bessere Abgrenzung und Lesbarkeit ohne stärkere visuelle Gewichtung. Commit: `4046d40ab25864332b40182db277f3d19a62872d`. DEV-Deploy/Praxistest ausstehend.


## Sortierung Ereignisliste und Rechtsfuß-Icon (14.11.2026)

- In der Ereignisansicht ist neben dem Suchfeld nun eine Sortierauswahl mit **Name A–Z** und **Name Z–A** vorhanden. Die bisherige Prioritätssortierung der Ereignisansicht wurde durch die gewünschte alphabetische Sortierung ersetzt. Die Sortierauswahl der Anwesenheitsansicht bleibt unverändert.
- Das Rechtsfuß-Symbol in der Spielercard erhält jetzt die CSS-Klassen `footIcon mirrored`; damit greift die vorhandene horizontale Spiegelung auch in der Spielkarten-Metazeile. Die Auswahl im Spielerformular verwendete die Spiegelung bereits korrekt.
- Beide Inline-JavaScript-Blöcke erfolgreich syntaktisch geprüft. DEV-Deploy und iPhone-Praxistest ausstehend.
- Commits: `9511e1f`, `303fe8d`, `5a3b82c`.


## Handlungspriorität als Sortieroption (14.11.2026)

Die Ereignisansicht bietet jetzt drei Sortieroptionen: **Handlungspriorität**, **Name A–Z** und **Name Z–A**. Die Handlungspriorität ordnet offene Sperren zuerst, danach Spieler mit mindestens vier aktiven gelben Karten ohne offene Sperre, anschließend Spieler mit sonstigen aktiven gelben Karten und zuletzt Spieler ohne diese Auffälligkeiten. Innerhalb einer Prioritätsgruppe wird alphabetisch sortiert. Die Auswahl wird im UI-Footer benannt. Commit: `dd55071bb7f6b8e065479cb0c8a3cd6e23c07c9f`.


## Standard-Sortierung festgelegt (14.11.2026)

Beim initialen Öffnen der Spielerliste gelten jetzt diese Voreinstellungen:
- **Anwesenheit:** Kaderempfehlung (`top16`).
- **Ereignisse:** Handlungspriorität (`priority`).

Die Auswahl bleibt während der laufenden Ansicht durch die vorhandenen Sortier-Controls änderbar. Es wird keine zusätzliche Persistenz in Datenbank oder Local Storage eingeführt; nach einem vollständigen Neuaufbau der Seite greifen wieder die definierten Standardwerte. JavaScript-Syntaxprüfung beider Inline-Scripts erfolgreich. Commit: `54ac055c73d3e4622289a15efc373793af9224cd`.


## Abstand Kaderstatus-Tabs (14.11.2026)

Die Tabs „Aktiver Kader / Inaktive Spieler“ erhalten jetzt `margin:10px 0 10px` und damit denselben vertikalen Außenabstand wie die übrigen segmented controls. Änderung in `develop/index.html`, Commit `352f76cd9a1ed82029c6f5814c7ccf016fc3fee3`. Syntaxprüfung der Inline-Scripts: Script 0: PASS; Script 1: PASS.
