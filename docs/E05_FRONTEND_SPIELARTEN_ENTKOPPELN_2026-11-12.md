# E05 – Frontend-Anpassung: Alle Spieltage als Sperrziele

**Stand:** 12.11.2026  
**Branch:** `develop`  
**Datei:** `index.html`  
**Frontend-Commit:** `74842c6632b512b57015d78dbdf29da91d4df5cf`  
**Voraussetzung:** DB-MIG-2026-010 erfolgreich in Supabase DEV ausgeführt  
**PROD / main:** unverändert

## 1. Ziel

Die Frontend-Verwaltung der individuell sperrenrelevanten Spielarten wird vollständig entfernt. Die Sperrenlogik berücksichtigt jeden Spieltag unabhängig vom Wert von `matchdays.game_type`, einschließlich `NULL`.

## 2. Umgesetzte Änderungen

### Entfernte Verwaltungsoberflächen
- Vereinsdetail: Karte „Sperrenrelevante Spielarten“ einschließlich Vereins-Standardauswahl entfernt.
- Mannschaftseinstellungen: Karte „Sperrenrelevante Spielarten“ einschließlich Mannschafts-Override entfernt.
- Mannschaftsdetail: Verknüpfung „Sperrenrelevante Spielarten einstellen“ entfernt.
- Mehr > Verwaltung: Vereinsweite Spielarten-Auswahl entfernt.
- Mehr > Mannschaften: Spielarten-Auswahl als Unterpunkt entfernt.
- Alte Mehr-Seiten-Routen und zugehörige Sichtbarkeits-/Berechtigungszweige entfernt.

### Entfernte Frontend-RPC-Aufrufe
- `get_club_suspension_game_types`
- `get_team_suspension_game_type_settings`
- `set_club_suspension_game_types`
- `set_team_suspension_game_types`

Die zugehörigen Frontend-Render-/Save-Handler wurden ebenfalls entfernt. Die Datenbanktabellen, gespeicherten Einstellungswerte und RPCs bleiben vorerst bestehen; diese Frontend-Änderung löscht keine Daten und nimmt keine weitere Datenbankänderung vor.

### Sperrenkorrektur
- Die vorhandene Auswahlliste für eine manuelle Sperrenzuordnung enthält weiterhin zukünftige geplante Spieltage der betreffenden Mannschaft und Saison.
- Die Liste wird nicht nach Spielart gefiltert; auch ein Spieltag ohne Spielart bleibt auswählbar.
- Der Hilfetext nennt nun die tatsächlich maßgeblichen Prüfungen: Mannschaft, Saison, Datum, Ausnahme und Berechtigung – nicht mehr Spielart.

### Unveränderte Funktionen
- Spielart bleibt ein normales Feld eines Spieltags und kann weiterhin beim Anlegen/Bearbeiten gepflegt und angezeigt werden.
- Ereignisvergabe, Spielerhistorie, Karten-/Sperrenübersicht, Ausnahmen, Sperrenkorrektur und Kaderplanung bleiben bestehen.
- Es wurde keine neue Seite und keine parallele Listenkomponente eingeführt.

## 3. Technische Prüfung

- JavaScript-Hauptmodul: Syntaxprüfung erfolgreich (Importzeile für den Syntaxcheck isoliert; Quelltext als Funktion geparst).
- Zweites Inline-Script: Syntaxprüfung erfolgreich.
- Statische Suche bestätigt: keine verbliebenen Referenzen auf die entfernten Settings-Cards, Renderer, Save-Handler, RPC-Aufrufe oder Mehr-Seiten-Routen.
- Die verbleibenden `game_type`-Referenzen dienen den normalen Spieltagsfeldern bzw. der lesbaren Spielartbezeichnung; sie bilden keinen Sperrenfilter.
- Geänderter Frontend-Code wurde ausschließlich nach `develop` geschrieben.

## 4. Noch ausstehende DEV-Praxistests

Auf `https://dev.kadassist.de` prüfen:

1. Vereinsadmin: Vereinsverwaltung öffnen; es erscheint keine Spielarten-Einstellung mehr.
2. Mannschaftsadmin: Mannschaftseinstellungen öffnen; es erscheint keine Spielarten-Einstellung mehr.
3. Superadmin: Vereins- und Mannschaftskontext öffnen; keine Spielarten-Einstellung oder entsprechende Navigation mehr.
4. Spieltag mit Spielart Meisterschaft, Freundschaftsspiel und Turnier jeweils als mögliches Sperrziel berücksichtigen.
5. Spieltag ohne Spielart (`game_type IS NULL`) ebenfalls als mögliches Sperrziel berücksichtigen.
6. Manuelle Sperrenkorrektur: zukünftige geplante Spieltage einschließlich `game_type IS NULL` werden angeboten.
7. Prüfen, dass Spielart weiterhin beim Anlegen und Bearbeiten eines Spieltags auswählbar und in der Spieltagsansicht sichtbar ist.
8. Hell-/Dunkelmodus und iPhone-Layout in den betroffenen Verwaltungsansichten prüfen.

Es wurden keine echten Sperren, Spieltage oder Testdatensätze verändert. Diese Praxistests sind noch nicht durchgeführt.

## 5. Änderungsgrenzen

- Nur `develop/index.html` wurde geändert.
- Supabase DEV und PROD wurden durch diese Frontend-Änderung nicht verändert.
- GitHub `main` und die PROD-Website wurden nicht verändert.
- Die Datenbankeinstellungen und die vier bisherigen Settings-RPCs bleiben vorerst als ungenutzter Bestand erhalten. Eine spätere Datenbankbereinigung benötigt einen eigenen read-only Review und eine separate Freigabe.
