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

## 6. UI-Sortierung nach Neuberechnung

Nach erfolgreichem Speichern einer neu berechneten Kaderempfehlung wird die Sortierung der Spieltags-Kaderliste automatisch auf „Kaderempfehlung“ gesetzt. Die gespeicherte Empfehlungsreihenfolge steht damit unmittelbar sichtbar oben. Nicht empfohlene Spieler folgen darunter anhand der bestehenden Rangfolge.

Die Änderung betrifft ausschließlich den Sortierzustand der Ansicht. Nominierungen und sonstige Spieltagsdaten bleiben unverändert. Eine manuelle Sortierauswahl bleibt weiterhin möglich.

## 7. Abgleich mit den dokumentierten Testdaten

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


## 9. Ergänzender Praxistest mit regulärer DEV-Mannschaft (16.11.2026)

**Testumgebung:** reguläre DEV-Mannschaft, Spieltage 21.11. und 29.11.2026. Die isolierte [TEST]-Mannschaft wurde für diesen Praxistest nicht verwendet.

### Durchführung und Ergebnis

- Beide Spieltage wurden in der DEV-Oberfläche geöffnet und die Kaderempfehlung jeweils neu berechnet.
- Die Screenshots zeigen die Spielerliste bereits in der Sortierung „Kaderempfehlung“.
- Nach der Neuberechnung standen die empfohlenen Spieler in der gespeicherten Empfehlungsreihenfolge; gesperrte Spieler wurden separat unterhalb der regulären Liste dargestellt.
- Am 21.11. wurde „Spieler Vorsicht“ als „Gesperrt · Ausnahme möglich“ angezeigt und nicht in die reguläre Empfehlung aufgenommen.
- Am 29.11. wurde „Spieler Elfenbeine“ als „Gesperrt · Ausnahme möglich“ angezeigt und nicht in die reguläre Empfehlung aufgenommen.
- Die für den 21.11. vorhandene Ausnahme bei „Spieler Dreißig“ führte dazu, dass dieser Spieler regulär angezeigt und in der Empfehlung berücksichtigt wurde.
- Die sichtbaren Sperrzuordnungen entsprachen den zuvor lesend ausgelesenen DEV-Sperrdaten.

### Einsatz-Fairness – Datenabgleich

Die gespeicherte Rangfolge des Spieltags 21.11. wurde mit den tatsächlichen Einsätzen im rollierenden Zeitraum verglichen. Als tatsächlicher Einsatz zählt ausschließlich `played = true`; `false` und `null` zählen nicht.

Die Rangfolge und Einsatzanzahlen waren mit der implementierten Regel vereinbar: Die Einsatz-Fairness wirkt nur innerhalb einer am höchsten Score verankerten Gleichwertigkeitsgruppe (maximal 2,00 Punkte Abstand). Ein Spieler mit mehr Einsätzen darf deshalb vor einem Spieler mit weniger Einsätzen stehen, wenn er außerhalb dessen Gleichwertigkeitsgruppe liegt.

**Nachweisgrenze:** Die gespeicherten Scores sind nicht als eigene Werte in der Datenbank abgelegt. Die zusätzlich ausgeführte SQL-Rekonstruktion der Scores war eine lesende Näherung und reproduzierte nicht in allen Fällen die vollständigen clientseitigen Eligibility-/Zeitbedingungen. Sie wird daher nicht als exakter Score-Nachweis gewertet. Der erfolgreiche Fairnessbefund stützt sich auf die geprüfte App-Reihenfolge, die Einsatzdaten und die dokumentierte Implementierungslogik; eine vollständige numerische Score-Auditspur liegt nicht vor.

### Status

- Regulärer DEV-Praxistest der Neuberechnung und Sortierung: bestanden.
- Sperrenausschluss und spieltagbezogene Ausnahme: für die beiden geprüften Fälle bestanden.
- Einsatz-Fairness: anhand vorhandener Daten und App-Reihenfolge plausibilisiert; keine Abweichung festgestellt.
- Authentifizierter E05-End-to-End-Test des Übergangs bei der fünften gelben Karte: weiterhin offen.
- Es wurden keine Spieler-, Trainings-, Ereignis-, Spieltags- oder Sperrdaten verändert.
- Keine SQL- oder Schemaänderung; PROD nicht verändert.
