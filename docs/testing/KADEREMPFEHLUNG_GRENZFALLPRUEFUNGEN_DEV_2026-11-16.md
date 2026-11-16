# Kaderempfehlung – Abschluss der drei Grenzfallprüfungen

**Datum:** 16.11.2026  
**Umgebung:** Supabase DEV  
**Testmannschaft:** `289590ee-16d5-44dd-a8cf-a286ae7b98e2`  
**PROD:** Nicht berührt  
**App-/DB-Änderungen:** Keine

## 1. Gleichwertigkeitsgrenze: 1,99 / 2,00 / 2,01

Die drei Grenzwerte wurden als reine SQL-Simulation geprüft:

| Score A | Score B | Abstand | Ergebnis |
|---:|---:|---:|---|
| 80,00 | 78,01 | 1,99 | Gleichwertig |
| 80,00 | 78,00 | 2,00 | Gleichwertig |
| 80,00 | 77,99 | 2,01 | Nicht gleichwertig |

**Ergebnis: bestanden.** Die Grenze ist inklusiv: Ein Abstand von genau 2,00 gehört noch zur Gleichwertigkeitsgruppe. Erst ab mehr als 2,00 Punkten bleibt die Score-Reihenfolge maßgeblich.

Innerhalb einer Gleichwertigkeitsgruppe darf die Einsatz-Fairness die Reihenfolge beeinflussen. Die Gruppenbildung muss am höchsten noch nicht zugeordneten Score verankert werden, damit keine Ketteneffekte entstehen.

## 2. Kartenkonto: vier → fünf → sechs

Die Punktefolge wurde als isolierte Score-Simulation geprüft:

| Ereignis im Bewertungszyklus | Score-Kartenkonto | Abzug |
|---|---:|---:|
| 1. gelbe Karte | 1 | -1 |
| 2. gelbe Karte | 2 | -3 |
| 3. gelbe Karte | 3 | -6 |
| 4. gelbe Karte | 4 | -10 |
| 5. gelbe Karte | 0 nach Sperrauslösung | 0 |
| 6. gelbe Karte | 1 im neuen Bewertungszyklus | -1 |

**Ergebnis: rechnerisch bestanden, End-to-End noch offen.**

Wichtig: Dies ist die vorgesehene Bewertungslogik, keine Änderung des bestehenden E05-Sperrenzählers. Die fünfte aktive gelbe Karte muss weiterhin über den vorhandenen E05-Prozess die echte Sperre auslösen. Das separate Bewertungskonto wird danach zurückgesetzt.

Der authentifizierte RPC-Aufruf konnte in diesem Prüfkontext nicht ausgeführt werden, weil die SQL-Prüfschnittstelle keinen angemeldeten Benutzerkontext (`auth.uid()`) bereitstellt. Es wurde daher weder ein Event angelegt noch eine Sperre künstlich in Tabellen geschrieben. Der E05-End-to-End-Test bleibt offen und muss später mit einem berechtigten Trainerkonto in DEV durchgeführt werden.

## 3. Acht-Wochen-Grenze

Für den Stichtag 16.11.2026 wurde die Datumsgrenze berechnet:

- 16.11.2026 minus 56 Tage = 21.09.2026.
- 20.09.2026 liegt außerhalb.
- 21.09.2026 liegt genau auf der Grenze.
- 22.09.2026 liegt innerhalb.
- 16.11.2026 liegt innerhalb.

**Ergebnis: bestanden für die übliche inklusive rollierende Grenze** `event_date >= current_date - interval '8 weeks'`. Das Ereignis am 21.09. muss mitgezählt werden; das Ereignis vom 20.09. nicht.

Hinweis zur Formulierung: Bei reinen Datumswerten umfasst die inklusive Bedingung vom 21.09. bis einschließlich 16.11. insgesamt 57 Kalendertage. Das entspricht einem rollierenden 56-Tage-Abstand zwischen den beiden Grenzzeitpunkten. Die konkrete Implementierung sollte diese Bedingung eindeutig verwenden und nicht versehentlich `>` statt `>=` einsetzen.

## 4. Gesamtstatus

| Prüfung | Ergebnis |
|---|---|
| 1,99 Punkte | Gleichwertig |
| 2,00 Punkte | Gleichwertig |
| 2,01 Punkte | Nicht gleichwertig |
| Kartenkonto 4 → 5 → 6 | Score-Simulation bestanden |
| E05-Sperre bei fünfter Karte | Authentifizierter End-to-End-Test offen |
| 8-Wochen-Grenze 20./21.09. | 20.09. ausgeschlossen, 21.09. eingeschlossen |
| PROD | Unverändert |
| Frontend / Datenbank | Unverändert |

## 5. Nächster sinnvoller Schritt

Die drei angefragten Grenzfallprüfungen sind abgeschlossen. Vor einer Implementierung fehlt als einzige echte Funktionsprüfung noch der authentifizierte DEV-Test der fünften gelben Karte mit dem E05-RPC. Danach kann die fachliche Score-Logik finalisiert und für die Frontend-Umsetzung freigegeben werden.

Keine SQL-Migration, keine Datenänderung und kein Frontend-Commit wurden in diesem Prüfzyklus ausgeführt.
