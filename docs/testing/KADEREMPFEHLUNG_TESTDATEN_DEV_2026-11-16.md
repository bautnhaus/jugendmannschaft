# DEV-Testdatensatz – Kaderempfehlung

**Datum:** 16.11.2026  
**Projekt:** KADAssist / Supabase DEV  
**Status:** Testdaten angelegt, Simulation rein lesend durchgeführt  
**PROD:** Nicht berührt

## 1. Isolierte Testmannschaft

- **Mannschaft:** [TEST] Kaderempfehlung – Isoliert
- **Mannschafts-ID:** `289590ee-16d5-44dd-a8cf-a286ae7b98e2`
- **Verein:** TuS Hoberge (DEV)
- **Saison:** TEST-Saison Kaderlogik 2026
- **Saison-ID:** `e4e4e943-aa86-4276-800d-859b2a63b2e2`
- **Aktiv:** Ja; eindeutig mit [TEST] gekennzeichnet
- **Kadergröße:** 4

Die Testmannschaft ist eine eigenständige Mannschaft im DEV-Projekt. Es wurden keine bestehenden Mannschaften, Spieler oder Ereignisse verändert.

## 2. Angelegte Daten

| Datentyp | Anzahl |
|---|---:|
| Testspieler | 11 |
| Trainings insgesamt | 11 |
| Davon innerhalb des rollierenden 8-Wochen-Fensters (21.09.–16.11.2026) | 10 |
| Anwesenheitsdatensätze | 112 |
| Positive Sterne | 36 |
| Gelbe Karten insgesamt | 13 |
| Gelbe Karten innerhalb des 8-Wochen-Fensters | 12 |
| Spieltage | 4 |
| Nominierungen | 21 |
| Als tatsächlich gespielt markierte Nominierungen | 12 |

Ein zusätzliches Training vom 10.09.2026 liegt bewusst außerhalb des Acht-Wochen-Fensters. Es dient zur Prüfung, dass ältere Ereignisse den aktuellen Score nicht beeinflussen, aber bei getrennten Zählmechanismen weiterhin historisch vorhanden bleiben.

## 3. Abgedeckte Spielertypen

- Hohe Anwesenheit, geringe Sternquote, keine Karten
- Hohe Sternquote bei geringerer Anwesenheit und mehreren gelben Karten
- Volle Anwesenheit mit mittlerer Sternquote und einer gelben Karte
- Geringere Anwesenheit mit perfekter Sternquote
- Drei besuchte Einheiten mit perfekter Sternquote und mehreren Karten
- Mittlere Teilnahme mit Karten
- Zwei Besuche / zwei Sterne (Faktor 0,6)
- Ein Besuch / ein Stern (Faktor 0,3)
- Kein Trainingsbesuch
- Zwei gezielt gleichwertige Spieler mit unterschiedlicher Einsatzhistorie
- Eine gelbe Karte außerhalb des Acht-Wochen-Fensters

## 4. Erste Simulation

Die Simulation verwendete vorläufig folgende Formel:

`Grundscore = 0,70 × Anwesenheitsquote + 0,30 × (Sternquote × Datenbasisfaktor)`

`Endscore = Grundscore − Kartenabzug`

| Testspieler | Anwesenheit | Sterne | Gelbe Karten im Fenster | Score |
|---|---:|---:|---:|---:|
| C – Regelmäßig, solide | 10/10 | 5/10 | 1 | 84,00 |
| B – Leistungsstark, verwarnt | 8/10 | 7/8 | 3 | 76,25 |
| A – Zuverlässig, unauffällig | 9/10 | 3/9 | 0 | 73,00 |
| J – Gleichwertig, häufiger eingesetzt | 8/10 | 4/8 | 1 | 70,00 |
| K – Gleichwertig, seltener eingesetzt | 8/10 | 4/8 | 2 | 68,00 |
| D – Selten, starke Quote | 5/10 | 5/5 | 0 | 65,00 |
| F – Wenig Teilnahme, viele Karten | 3/10 | 3/3 | 3 | 45,00 |
| E – Mittlere Teilnahme, Karten | 4/10 | 2/4 | 2 | 40,00 |
| G – Zwei Besuche, zwei Sterne | 2/10 | 2/2 | 0 | 32,00 |
| H – Ein Besuch, ein Stern | 1/10 | 1/1 | 0 | 16,00 |
| I – Kein Besuch | 0/10 | 0/0 | 0 | 0,00 |

## 5. Erste Erkenntnisse

### 5.1 Gleichwertigkeitsgruppe J/K

- J: 70,00 Punkte, 3 tatsächliche Einsätze, 4 Nominierungen.
- K: 68,00 Punkte, 0 tatsächliche Einsätze, 1 Nominierung.
- Der Score-Abstand beträgt genau 2,00 Punkte.
- Nach der vereinbarten Fairnessregel muss K innerhalb dieser Gruppe vor J eingeordnet werden, weil K weniger tatsächliche Einsätze hatte.

Dies ist ein gezielt angelegter positiver Testfall für die Gleichwertigkeitslogik.

### 5.2 Vergleich A/B

- B erreicht 76,25 Punkte.
- A erreicht 73,00 Punkte.
- B liegt damit 3,25 Punkte vor A.
- Nach der festgelegten Gleichwertigkeitsgrenze von maximal 2 Punkten wären A und B **nicht** gleichwertig.

Das weicht leicht von der zuvor geäußerten Einschätzung ab, A und B seien gleichwertig mit knappem Vorteil für B. Diese Abweichung muss fachlich bewertet werden, bevor die Gewichtung als endgültig gilt. Es wurde keine Gewichtung eigenmächtig geändert.

### 5.3 Acht-Wochen-Fenster

Das zusätzliche Training vom 10.09.2026 liegt außerhalb des Fensters. Die zugehörige gelbe Karte wird nicht in den aktuellen Acht-Wochen-Score-Abzug einbezogen. Sie bleibt als Ereignis historisch vorhanden und kann – gemäß der getrennten E05-Kartenzykluslogik – weiterhin für die Sperrenzählung relevant sein.

### 5.4 Einsatzhistorie

Die Testdaten unterscheiden zwischen:
- tatsächlichem Einsatz (`played = true`);
- ausdrücklich nicht gespielt (`played = false`);
- nicht gesetztem Einsatzstatus (`played = null`).

Ein nicht gesetzter Status darf nicht als Nicht-Einsatz interpretiert werden.

## 6. Technische Grenzen dieses Testlaufs

- Es wurde eine SQL-Simulation der fachlichen Formel auf den isolierten DEV-Daten durchgeführt.
- Die bestehende Frontend-Funktion `top16Ranking()` wurde nicht geändert.
- Die neue 70/30-Logik ist noch nicht in der App implementiert.
- Die fünfte gelbe Karte und der E05-Sperrenübergang wurden in diesem Seed nicht ausgelöst. Diese Abläufe müssen separat über die bestehende E05-Logik geprüft werden; keine manuelle Sperre wurde erzeugt.
- Es wurden keine Datenbankstruktur, Policies, Trigger oder Funktionen geändert.
- Es wurden keine PROD-Daten berührt.

## 7. Datenbestand behalten oder entfernen

Die Testmannschaft und ihre Daten bleiben zunächst in DEV bestehen. Eine spätere Entscheidung über Beibehaltung oder Entfernung erfolgt separat.

Die Testmannschaft ist über ihre eindeutige ID und das Präfix `[TEST]` identifizierbar. Bei einer späteren Bereinigung müssen alle abhängigen Testdaten kontrolliert und ausschließlich über diese Mannschafts-ID entfernt werden.

## 8. Nächster Prüfpunkt

Vor der Frontend-Implementierung sind insbesondere zu klären:

1. Ist der Abstand von 3,25 Punkten zwischen A und B noch ein „knapper Vorteil“, oder soll die Berechnung so angepasst werden, dass beide in die Zwei-Punkte-Gleichwertigkeit fallen?
2. Soll die Gruppierung weiterhin am höchsten Score der jeweiligen Gruppe verankert werden?
3. E05-Kartenzyklus und fünfte Karte in einem separaten Testfall nachvollziehen.

**Keine Code- oder PROD-Änderung durch diesen Testlauf.**
