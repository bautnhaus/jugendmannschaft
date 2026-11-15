# KADAssist – Fachliche Spezifikation Kaderempfehlung

**Version:** 1.1  
**Stand:** 15.11.2026  
**Status:** Fachliche Leitplanken abgestimmt; technische Detailprüfung/DEV-Validierung ausstehend  
**Geltungsbereich:** DEV zuerst. Keine Code- oder Datenbankänderung durch dieses Dokument.

## 1. Ziel und Grundsatz

Die Kaderempfehlung ist eine nachvollziehbare Entscheidungshilfe für das Trainerteam. Sie bewertet aktuelle Trainingsbeteiligung, positive Trainingsereignisse und Verhalten. Sie ersetzt nicht die abschließende Trainerentscheidung.

## 2. Bewertungszeitraum

- Es gilt ein rollierender Zeitraum von acht Wochen.
- Anwesenheit, positive Sterne und der Score-Abzug für gelbe Karten beziehen sich auf Ereignisse innerhalb dieses Zeitraums.
- Trainings außerhalb des Zeitraums beeinflussen die aktuelle Grundbewertung nicht mehr.
- Die relevante Trainingsbasis berücksichtigt nur nicht abgesagte, bereits vergangene Trainingseinheiten, für die der Spieler teilnahmeberechtigt war (z. B. Eintrittsdatum in die Mannschaft).

## 3. Grundscore: Anwesenheit und positive Sterne

Die Gewichtung ist:

| Kriterium | Gewicht |
|---|---:|
| Anwesenheit | 70 % |
| Positive Sterne | 30 % |

### 3.1 Anwesenheitsquote

Anwesenheitsquote (A) = besuchte relevante Trainingseinheiten / alle relevanten Trainingseinheiten im Acht-Wochen-Zeitraum.

### 3.2 Sternquote

Sternquote (L) = erhaltene positive Sterne / tatsächlich besuchte relevante Trainingseinheiten.

Pro besuchter Trainingseinheit kann maximal ein positiver Stern berücksichtigt werden. Die Sternquote liegt zwischen 0 und 100 %.

### 3.3 Mindestdatenbasis für Sterne

Der Einfluss der Sternquote wird abhängig von der Zahl tatsächlich besuchter Trainingseinheiten abgeschwächt:

| Besuchte Einheiten im Zeitraum | Faktor F für Sternquote |
|---:|---:|
| 0 | 0 |
| 1 | 0,3 |
| 2 | 0,6 |
| Ab 3 | 1,0 |

Bei null Besuchen wird keine Sternquote berechnet; der Sternanteil ist null.

### 3.4 Berechnung des Grundscores

**Grundscore = 0,70 × A + 0,30 × (L × F)**

A und L werden als Prozentwerte zwischen 0 und 100 eingesetzt. Der Datenbasisfaktor F wird ausschließlich auf den Sternanteil angewendet.

## 4. Gelbe Karten: Score-Abzug

Gelbe Karten wirken sich zusätzlich auf den Score aus. Die Abzüge richten sich nach der Anzahl der gelben Karten des aktuellen Karten-Zählzyklus, die innerhalb der letzten acht Wochen liegen:

| Berücksichtigte gelbe Karten im aktuellen Zählzyklus und Acht-Wochen-Zeitraum | Abzug |
|---:|---:|
| 0 | 0 Punkte |
| 1 | −1 Punkt |
| 2 | −3 Punkte |
| 3 | −6 Punkte |
| 4 | −10 Punkte |

Es gibt keine weitere Strafpunkteskala. Der Score vor Einsatz-Fairness ergibt sich aus:

**Endscore = Grundscore − Kartenabzug**

## 5. Karten-Zählzyklus und Sperre – getrennt vom Bewertungszeitraum

Der Karten-Zählzyklus ist ausdrücklich unabhängig vom rollierenden Acht-Wochen-Zeitraum:

- Gelbe Karten werden für die Sperrenauslösung fortlaufend gezählt, auch wenn sie älter als acht Wochen sind.
- Die fünfte gelbe Karte löst die bestehende Sperrenregel aus.
- Nach der fünften Karte wird das aktuelle Kartenkonto auf null zurückgesetzt.
- Bis zur nächsten gelben Karte entsteht kein neuer Kartenabzug aus dem zurückgesetzten Kartenkonto.
- Mit der nächsten gelben Karte beginnt ein neuer Zählzyklus.
- Historische Kartenereignisse bleiben dauerhaft dokumentiert. Der Reset löscht keine Historie.
- Eine ältere Karte kann weiterhin zur fünften Karte und damit zur Sperre beitragen, auch wenn sie keinen Einfluss mehr auf den Acht-Wochen-Score hat.

Für den Score zählen nur Karten aus dem aktuellen Zählzyklus, die zugleich innerhalb des rollierenden Acht-Wochen-Zeitraums liegen. Der Reset nach der fünften Karte beendet den vorherigen Zyklus auch für die Score-Betrachtung.

## 6. Aktive Sperren

- Eine aktive Sperre ist ein eigenständiger harter Ausschluss aus der Kaderempfehlung.
- Eine gültige, spieltagbezogene Ausnahme macht den Spieler für diesen Spieltag wieder nominierbar.
- Ein guter Score hebt keine aktive Sperre auf.
- Die bestehende Sperren- und Ausnahmelogik bleibt erhalten.
- Die fünfte Karte löst die Sperre aus; es gibt keinen zusätzlichen Kartenabzug über die vierte Karte hinaus.

## 7. Gleichwertigkeit und Einsatz-Fairness

Spieler mit einem Score-Abstand von höchstens zwei Punkten sollen als gleichwertig behandelt werden. In dieser Gruppe gilt folgende Reihenfolge:

1. Tatsächliche Einsätze: Spieler mit weniger bzw. länger zurückliegendem tatsächlichem Einsatz erhalten Vorrang.
2. Nominierungen: Bei vergleichbarer Einsatzhistorie erhält der Spieler mit weniger bzw. länger zurückliegender Nominierung Vorrang.
3. Zufall: Bei weiterhin gleichwertigen Spielern entscheidet der vorhandene Zufallsmechanismus.

Nominierung und tatsächlicher Einsatz sind ausdrücklich unterschiedliche Sachverhalte. Eine bloße Nominierung darf nicht als tatsächlicher Einsatz gezählt werden.

Die konkrete technische Aggregation der Einsatzhistorie (z. B. Betrachtung der letzten Spieltage bzw. Einsatzanzahl und Aktualität) wird bei der DEV-Detailprüfung festgelegt, ohne die fachliche Priorität umzukehren.

### Technischer Hinweis zur Gleichwertigkeitsgruppierung

Ein rein paarweiser Vergleich mit einer Zwei-Punkte-Toleranz kann bei mehreren Spielern zu nicht transitiven Sortierergebnissen führen. Die Implementierung muss daher stabile, widerspruchsfreie Gleichwertigkeitsgruppen bilden und innerhalb dieser Gruppen die Einsatz-Fairness anwenden. Die Gruppierungsregel ist vor dem Coding anhand von Grenzfällen zu testen.

## 8. Gesamtablauf der Empfehlung

1. Aktuelle Spieltags-Sperren und gültige Ausnahmen prüfen.
2. Relevante Trainingseinheiten der letzten acht Wochen bestimmen.
3. Anwesenheitsquote berechnen.
4. Sternquote und Datenbasisfaktor berechnen.
5. Grundscore mit 70/30 bilden.
6. Score-Abzug für gelbe Karten des aktuellen Zählzyklus innerhalb des Acht-Wochen-Zeitraums abziehen.
7. Verbleibende Spieler nach Score ordnen und stabile Gleichwertigkeitsgruppen mit maximal zwei Punkten Abstand bilden.
8. Innerhalb gleichwertiger Gruppen tatsächliche Einsätze priorisieren.
9. Bei vergleichbarer Einsatzhistorie Nominierungen berücksichtigen.
10. Verbleibende Gleichstände mit dem vorhandenen Zufallsmechanismus auflösen.
11. Gewünschte Kadergröße anwenden.

## 9. DEV-Testfälle

Vor einer Implementierungsfreigabe sind mindestens folgende Fälle mit erwarteten Ergebnissen zu testen:

1. Hohe Anwesenheit, geringe Sternquote.
2. Geringere Anwesenheit, hohe Sternquote.
3. Gleiche Anwesenheit, unterschiedliche Sternquoten.
4. Gleiche Sternquote, unterschiedliche Anwesenheit.
5. 0, 1, 2 und mindestens 3 besuchte Einheiten (Faktoren 0 / 0,3 / 0,6 / 1).
6. Ein Training fällt durch das rollierende Acht-Wochen-Fenster.
7. Eine gelbe Karte liegt außerhalb der acht Wochen, zählt aber weiterhin zum Sperren-Zählzyklus.
8. Kartenabzug bei 1, 2, 3 und 4 berücksichtigten Karten.
9. Fünfte gelbe Karte löst Sperre aus und setzt das Kartenkonto zurück.
10. Nach dem Reset bleibt die Historie erhalten; bis zur nächsten Karte entsteht kein neuer Kartenabzug.
11. Neue Karte nach dem Reset beginnt einen neuen Zählzyklus.
12. Aktive Sperre ohne Ausnahme.
13. Aktive Sperre mit gültiger Ausnahme.
14. Score-Abstand genau 2 Punkte und knapp über 2 Punkte.
15. Mehrere Spieler in überlappenden Zwei-Punkte-Abständen: stabile Gruppierung ohne widersprüchliche Sortierung.
16. Gleichwertige Spieler mit unterschiedlicher tatsächlicher Einsatzhistorie.
17. Bei vergleichbarer Einsatzhistorie unterschiedliche Nominierungshistorie.
18. Weiterer Gleichstand wird über Zufall aufgelöst.
19. Bereits gespeicherte Spieltagsempfehlungen und bestätigte Nominierungen bleiben unverändert, bis ausdrücklich neu berechnet wird.

## 10. Abgleich mit dem aktuellen DEV-Code (Read-only)

Die am 15.11.2026 geprüfte Datei `develop/index.html` zeigt:

- `attendanceStats(p)` wertet aktuell vergangene, nicht abgesagte Trainings seit Eintritt des Spielers aus, jedoch noch nicht mit einem rollierenden Acht-Wochen-Fenster.
- `top16Ranking()` sortiert derzeit lexikografisch nach Anwesenheitsquote, Trainingsaktualität, bisheriger Nominierung und Zufall. Eine gemeinsame 70/30-Punktebewertung ist noch nicht implementiert.
- Positive Sterne und gelbe Karten werden bereits in `training_behavior_events` erfasst und in der Ereignisübersicht gezählt; die geprüfte Rangierfunktion verwendet sie noch nicht.
- Die aktuelle Ereignisübersicht zählt aktive Ereignisse saisonbezogen, nicht anhand eines rollierenden Acht-Wochen-Fensters.
- `matchday_players.played` ist bereits vorhanden und wird im Frontend zum Markieren tatsächlicher Einsätze verwendet.
- Die aktuell geprüfte `matchdayFairnessCompare()` berücksichtigt die letzte Nominierung über `md.selected`, aber noch nicht das Feld `played` als eigenen Fairnessfaktor.
- Die bestehende spieltagbezogene Sperren- und Ausnahmelogik ist vorhanden und muss erhalten bleiben.
- Gespeicherte Empfehlungsläufe werden separat in `matchday_recommendation_runs` und `matchday_recommendation_players` abgelegt.

Dieser Abgleich war ausschließlich lesend. Es wurden keine Code-, Datenbank- oder PROD-Änderungen vorgenommen.

## 11. Umsetzungsleitplanken

- Ausschließlich DEV für Entwicklung und Praxistests.
- Vor jeder Codeänderung aktuelle Datei aus `develop` laden.
- Bestehende Sperren-, Ausnahme-, Daten- und gespeicherte Empfehlungssysteme erhalten.
- Keine Datenbankänderung, sofern sie nicht nachweislich erforderlich ist.
- Jede erforderliche SQL-Änderung vor Ausführung separat genehmigen lassen und im SQL-Release-Katalog dokumentieren.
- Keine PROD-Änderung ohne ausdrückliche Freigabe.
- Erst nach erfolgreichen DEV-Praxistests eine PROD-Freigabe vorbereiten.

**Diese Spezifikation ist eine fachliche Grundlage und keine Freigabe für Code-, SQL- oder PROD-Änderungen.**
