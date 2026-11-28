# DEV-Handoff – Spieltags-Teambildung nach Anwesenheit
**Stand:** 28.11.2026  
**Branch:** `develop`  
**PROD/main:** unverändert

## Anlass
Beim Spieltag wurde die automatische Mannschaftsbildung anhand der Nominierung (`matchdaySelection`) ausgelöst. Die gespeicherte Anwesenheit (`matchday.attendance`) wurde nicht berücksichtigt. Dadurch konnten nominierte, aber als abwesend markierte Spieler in die Teams gelangen.

## Umsetzung in develop
Commit: `8230ebea80bb7e4940095d78f4810e9a42e225a8`

- `balanceTeams()` bildet die Auswahl jetzt aus Spielern, die **nominiert UND ausdrücklich als anwesend markiert** sind.
- `chooseTeamCount()` prüft dieselbe Bedingung erneut unmittelbar vor dem Erzeugen der Teams. So wird auch eine zwischenzeitliche Änderung der Anwesenheit berücksichtigt.
- Weniger als fünf entsprechend markierte Spieler führen zu einer verständlichen Fehlermeldung; es werden keine Teams gebildet.
- Trainings-Teambildung, Nominierungsempfehlung und Nominierungsdaten bleiben unverändert.
- Abwesende nominierte Spieler bleiben nominiert; sie erhalten bei der Teamzuordnung keine Mannschaft.
- Keine SQL-/Supabase-Änderung, keine Migration und keine Änderung an `main`/PROD.

## DEV-Prüfung – noch durchzuführen
1. In DEV einen Spieltag mit mehreren nominierten Spielern öffnen.
2. Mindestens einen nominierten Spieler als abwesend markieren und einige andere als anwesend.
3. „Teams bilden“ starten: Die Auswahlzahl muss nur die nominierten **Anwesenden** zählen.
4. Teams bilden und kontrollieren: Kein als abwesend markierter Spieler darf einem Team zugeordnet sein.
5. Anwesenheit eines Spielers ändern und erneut „Teams bilden“: Die neue Anwesenheit muss maßgeblich sein.
6. Unter fünf nominierten Anwesenden prüfen: verständlicher Hinweis, keine neue Teamzuordnung.
7. Nominierung nach dem Speichern kontrollieren: abwesende Spieler bleiben nominiert; die ursprüngliche Nominierung wird nicht automatisch gelöscht.
8. Training separat kurz prüfen, um sicherzustellen, dass dessen bisherige Anwesenheitslogik unverändert funktioniert.

**Status:** Code in develop committed; DEV-Praxistest durch Nutzer noch offen. Erst nach erfolgreicher DEV-Prüfung über einen separaten Freigabeschritt für PROD sprechen.
