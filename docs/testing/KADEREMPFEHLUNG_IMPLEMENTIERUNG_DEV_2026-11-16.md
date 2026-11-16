# Kaderempfehlung – Implementierung in DEV

**Datum:** 16.11.2026  
**Branch:** `develop`  
**Umgebung:** Frontend / Supabase DEV  
**PROD:** Nicht verändert  
**Datenbank:** Keine Migration, keine SQL-Änderung

## 1. Umgesetzte Bewertungslogik

Die bisherige rein lexikografische Sortierung nach Anwesenheitsquote, Trainingsaktualität und Nominierungshistorie wurde für die Kaderempfehlung durch den beschlossenen Score ersetzt.

```
Grundscore = 70 × Anwesenheitsquote
           + 30 × (Sternquote × Datenbasisfaktor)

Endscore = Grundscore − Gelbkartenabzug
```

- Bewertungszeitraum: rollierende acht Wochen, inklusive Grenztag (`Datum >= heute − 56 Tage`).
- Anwesenheitsquote: besuchte / mögliche, abgeschlossene und nicht abgesagte Trainingseinheiten im Fenster.
- Sternquote: positive Sterne / besuchte Trainingseinheiten im Fenster.
- Datenbasisfaktor: 0 bei 0 Besuchen, 0,3 bei 1 Besuch, 0,6 bei 2 Besuchen, 1,0 ab 3 Besuchen.
- Gelbkartenabzug: 0 / 1 / 3 / 6 / 10 Punkte für 0 / 1 / 2 / 3 / mindestens 4 Karten im aktuellen Bewertungs-Kartenkonto.
- Das Bewertungs-Kartenkonto wird nach jeder fünften aktiven gelben Karte zurückgesetzt. Die sechste Karte beginnt das neue Konto.
- Die Score-Kartenlogik ist getrennt vom bestehenden E05-Sperrenzyklus. E05 bleibt unverändert.

## 2. Gleichwertigkeits- und Fairnesslogik

- Scores werden zunächst absteigend sortiert.
- Eine Gleichwertigkeitsgruppe wird jeweils am höchsten noch nicht zugeordneten Score verankert. Alle Spieler mit maximal 2,00 Punkten Abstand zum Gruppenanker gehören in diese Gruppe. Dadurch entstehen keine Ketteneffekte.
- Innerhalb einer Gruppe werden Spieler mit weniger tatsächlichen Einsätzen zuerst gereiht.
- Als tatsächlicher Einsatz zählt ausschließlich `matchday_players.played = true`; `false` und `null` werden nicht als Einsatz gezählt.
- Bei gleicher Einsatzanzahl bleiben die vorhandenen sekundären Fairness-Kriterien (Nominierungshistorie, Trainingsaktualität) und zuletzt der stabile Zufalls-Tie-Breaker erhalten.

## 3. Sperren

Die bisherige E05-Sperrprüfung bleibt als harte Filterbedingung der speicherbaren Empfehlung erhalten. Eine aktive Sperre ohne gültige Ausnahme schließt den Spieler aus. Eine gültige spieltagbezogene Ausnahme hebt den Ausschluss für diesen Spieltag auf.

## 4. Datenladen und gespeicherte Empfehlung

- Aktive Ereignisse der aktuellen Mannschaft und Saison werden beim Laden des Mannschaftskontexts geladen, einschließlich `training_date_snapshot`.
- Damit stehen Sterne und gelbe Karten für die Scoreberechnung bereit, ohne dass zuvor die zentrale Ereignisübersicht geöffnet werden muss.
- Die Empfehlung wird weiterhin erst durch „Neu berechnen“ neu berechnet und über den bestehenden RPC gespeichert. Eine gespeicherte Empfehlung ändert sich nicht automatisch.
- Es wurden keine Tabellen, RPCs, Policies oder Trigger verändert.

## 5. UI-Korrektur aus dem iPhone-Screenshot

Die dunkelgrüne Nominierungskachel erhält für Positions- und Leveltexte einschließlich der untergeordneten Textspans eine explizite helle Textfarbe. Die goldene Sternfarbe bleibt erhalten. Dies ist eine reine CSS-Korrektur.

## 6. Abgleich mit den dokumentierten Testdaten

Die implementierte Formel reproduziert die zuvor bestätigten Simulationswerte:

| Testspieler | Erwarteter Score |
|---|---:|
| C | 84,00 |
| B | 76,25 |
| A | 73,00 |
| J | 70,00 |
| K | 68,00 |
| D | 65,00 |
| F | 45,00 |
| E | 40,00 |
| G | 32,00 |
| H | 16,00 |
| I | 0,00 |

J/K liegen genau 2,00 Punkte auseinander und gehören damit in dieselbe Gruppe. K wird wegen 0 tatsächlicher Einsätze vor J mit 3 tatsächlichen Einsätzen eingeordnet. B bleibt mit 76,25 Punkten vor A mit 73,00 Punkten.

Die Werte sind ein rechnerischer Abgleich der implementierten Formel mit den dokumentierten SQL-Simulationen; sie sind kein Ersatz für den anschließenden Praxistest in der DEV-Oberfläche.

## 7. Noch ausstehend

1. DEV-Frontend laden und die gespeicherte Empfehlung mit „Neu berechnen“ neu erzeugen.
2. Ergebnis mit den dokumentierten Testspielern vergleichen.
3. Grenzfälle 1,99 / 2,00 / 2,01 in der tatsächlichen Frontend-Rangfolge prüfen.
4. 4 → 5 → 6 gelbe Karten anhand echter aktiver Ereignisdaten nachvollziehen; den E05-End-to-End-Test der fünften Karte weiterhin mit berechtigtem Trainerkonto ausführen.
5. Sicherstellen, dass ein aktiver E05-Sperrstatus ohne Ausnahme ausgeschlossen und mit Ausnahme wieder berücksichtigt wird.

**Freigabestatus:** Implementierung in `develop`; DEV-Praxistest ausstehend. Keine PROD-Freigabe.
