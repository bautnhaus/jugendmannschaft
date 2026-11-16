# Kaderempfehlung – gezielte DEV-Folgetests

**Datum:** 16.11.2026  
**Basis:** Isolierte Testmannschaft `289590ee-16d5-44dd-a8cf-a286ae7b98e2`  
**PROD:** Nicht berührt  
**Codeänderungen:** Keine

## 1. Entscheidung A/B übernommen

Der Vergleich B (76,25) gegen A (73,00) wurde vom Nutzer als knapper, aber ausreichender Vorsprung für B bestätigt.

- Abstand: 3,25 Punkte
- Entscheidung: B vor A
- Gewichtung bleibt 70/30
- Gleichwertigkeitsgrenze bleibt maximal 2 Punkte
- Keine Änderung an Formel oder Grenzwert

## 2. Rollierender Zeitraum

Der Testdatensatz enthält:
- 10 abgeschlossene Trainings vom 22.09. bis 08.11.2026 innerhalb des Fensters 21.09.–16.11.2026
- 1 zusätzliches abgeschlossenes Training am 10.09.2026 außerhalb des Fensters

Für TEST J wurde eine gelbe Karte am 10.09. angelegt und eine weitere am 24.10. Die Simulation zählt für die Score-Bewertung nur die Karte innerhalb des Fensters. Die ältere Karte bleibt historisch vorhanden.

**Ergebnis:** Die 8-Wochen-Abgrenzung ist mit den Testdaten plausibel und in der SQL-Simulation bestätigt.

## 3. Datenbasisfaktor

Die Simulation nutzt den bestätigten Faktor für die Sternbewertung:

| Besuchte Einheiten | Faktor |
|---:|---:|
| 0 | 0,0 |
| 1 | 0,3 |
| 2 | 0,6 |
| ab 3 | 1,0 |

Beispiele bei 10 möglichen Trainings und ohne Kartenabzug:

| Besuche | Sterne | Score |
|---:|---:|---:|
| 1 | 1 | 16,00 |
| 2 | 2 | 32,00 |
| 3 | 0 | 21,00 |
| 3 | 1 | 31,00 |
| 3 | 3 | 51,00 |
| 4 | 0 | 28,00 |
| 4 | 2 | 43,00 |
| 4 | 4 | 58,00 |

Der Faktor reduziert den Einfluss einer sehr kleinen Stern-Datenbasis. Die Anwesenheitskomponente bleibt davon unberührt.

## 4. Kartenabzüge

Die vereinbarten Abzüge wurden rechnerisch geprüft:

| Gelbe Karten im Bewertungszyklus | Score-Abzug |
|---:|---:|
| 0 | 0 |
| 1 | -1 |
| 2 | -3 |
| 3 | -6 |
| 4 | -10 |
| 5 | Sperre, Bewertungs-Kartenkonto danach 0 |
| ab 6 | neue Karten zählen in einem neuen Bewertungs-Kartenkonto |

Die reine Abzugstabelle ist rechnerisch konsistent.

### Wichtige technische Abgrenzung zu E05

Die bestehende E05-Logik zählt aktive gelbe Karten ab dem letzten abgeleisteten gelben Sperrspieltag oder dem letzten angewendeten vorzeitigen Sperrausgleich. Beim fünften aktiven Ereignis wird eine Sperre angelegt. Der bestehende E05-Zählzyklus wird damit nicht schon beim Eintragen der fünften Karte zurückgesetzt, sondern folgt dem dokumentierten Sperr-/Ableistungszyklus.

Für die Kaderempfehlung muss deshalb ein **separates Bewertungs-Kartenkonto** umgesetzt werden, das nach der fünften Karte auf null zurückspringt. Die E05-Sperre selbst bleibt davon unberührt und weiterhin harte Nominierungssperre. So werden Bewertungslogik und tatsächliche Sperrenmechanik nicht vermischt.

Der fünfte-Karte-Übergang wurde in diesem Durchlauf nicht durch den authentifizierten E05-RPC ausgelöst. Es wurde keine künstliche Sperre direkt in die Datenbank geschrieben. Der End-to-End-Test dieses Übergangs steht noch aus.

## 5. Einsatz-Fairness

Die gezielt gleichwertigen Testspieler:
- J: 70,00 Punkte, 3 tatsächliche Einsätze
- K: 68,00 Punkte, 0 tatsächliche Einsätze

Der Abstand beträgt genau 2 Punkte. Damit liegen sie in derselben Gleichwertigkeitsgruppe. K muss innerhalb der Gruppe vor J eingeordnet werden.

Der Testdatensatz enthält keine unbekannten Einsatzstatus für J/K. Zusätzlich bleibt die Regel bestehen: `played = null` ist unbekannt und darf nicht als Nicht-Einsatz gezählt werden.

## 6. Gruppenbildung

Die Gruppe wird am höchsten noch nicht zugeordneten Score verankert. Die maximale Abweichung von 2 Punkten wird gegen diesen Anker gemessen, nicht gegen den jeweils vorherigen Spieler. Damit werden Ketteneffekte verhindert.

Der bestätigte A/B-Abstand von 3,25 Punkten liegt außerhalb der Gleichwertigkeitsgrenze. B bleibt deshalb vor A.

## 7. Status

| Prüfpunkt | Ergebnis |
|---|---|
| A/B-Vergleich | Nutzer bestätigt B knapp vor A |
| 70/30 | Unverändert |
| Gleichwertigkeit max. 2 Punkte | Unverändert |
| 8-Wochen-Fenster | SQL-Simulation plausibel |
| Datenbasisfaktor 0,3/0,6/1,0 | Rechnerisch geprüft |
| Kartenabzüge 0/-1/-3/-6/-10 | Rechnerisch geprüft |
| Bewertungs-Kartenkonto nach 5. Karte zurücksetzen | Als separate Score-Regel spezifiziert |
| E05-Sperre bei fünfter Karte | Codepfad geprüft, End-to-End-RPC-Test offen |
| Einsatz-Fairness | Positiver Testfall vorhanden |
| Frontend-Implementierung | Noch nicht begonnen |
| Datenbankstruktur/RPCs | Unverändert |

## 8. Nächste gezielte Prüfung

1. Authentifizierter DEV-End-to-End-Test des fünften gelben Ereignisses über `award_training_behavior_event` und Prüfung der erzeugten E05-Sperre.
2. Separater Score-Simulationsfall: 4 Karten → 5. Karte/Sperre → Score-Kartenkonto 0 → 6. Karte zählt als erste neue Bewertungs-Karte.
3. Grenzfälle der Gleichwertigkeitsgruppen mit Abständen 1,99 / 2,00 / 2,01.
4. Prüfung, dass die rollierende Fenstergrenze genau acht Wochen umfasst und Ereignisse am Grenztag konsistent behandelt werden.

Keine Datenbank- oder Frontendänderung durch diese Prüfung.
