# FAQ – Wie funktioniert die Kaderempfehlung?

Die Kaderempfehlung ist eine Entscheidungshilfe für das Trainerteam. Sie bewertet die aktuelle Trainingsbeteiligung und positive Trainingsereignisse und berücksichtigt zusätzlich gelbe Karten sowie die bisherige Einsatz- und Nominierungshistorie. Die endgültige Entscheidung über den Kader trifft weiterhin das Trainerteam.

## Welche Daten werden berücksichtigt?

Berücksichtigt werden die relevanten, abgeschlossenen und nicht abgesagten Trainingseinheiten der letzten acht Wochen. Dabei wird die Zeit berücksichtigt, seit der ein Spieler zur Mannschaft gehört.

## Wie wird die Empfehlung berechnet?

Der Grundscore setzt sich aus zwei Teilen zusammen:

- **70 % Anwesenheit:** Anteil der besuchten relevanten Trainingseinheiten.
- **30 % positive Sterne:** positive Sterne im Verhältnis zu den besuchten Trainingseinheiten.

Der Einfluss der Sterne hängt von der Datenbasis ab: Bei 0 besuchten Einheiten beträgt der Faktor 0, bei 1 Einheit 0,3, bei 2 Einheiten 0,6 und ab 3 Einheiten 1,0.

Von diesem Grundscore wird ein zusätzlicher Gelbkartenabzug abgezogen: 0, 1, 3, 6 oder 10 Punkte bei 0, 1, 2, 3 oder mindestens 4 berücksichtigten gelben Karten im aktuellen Karten-Zählzyklus innerhalb des Acht-Wochen-Zeitraums.

## Was passiert bei der fünften gelben Karte?

Die fünfte gelbe Karte löst die bestehende Sperrenregel aus. Anschließend wird das Karten-Zählkonto für die Score-Bewertung zurückgesetzt. Die nächste gelbe Karte beginnt einen neuen Zählzyklus. Die Kartenhistorie bleibt dabei erhalten. Der Sperren-Zählzyklus ist unabhängig vom rollierenden Acht-Wochen-Zeitraum: Auch ältere Karten können weiterhin für die Sperrenauslösung zählen.

## Wie werden gesperrte Spieler behandelt?

Eine aktive Sperre schließt einen Spieler grundsätzlich aus der Kaderempfehlung aus – unabhängig von seinem Score. Eine gültige, spieltagbezogene Ausnahme macht ihn für genau diesen Spieltag wieder nominierbar.

## Was bedeutet „gleichwertig“ und wie wird Fairness berücksichtigt?

Spieler werden zunächst nach ihrem Score sortiert. Spieler mit höchstens 2 Punkten Abstand zum höchsten Score einer Gruppe gelten als gleichwertig. Innerhalb dieser Gruppe werden Spieler mit weniger tatsächlichen Einsätzen bevorzugt. Als tatsächlicher Einsatz zählt nur ein Spieltag mit `played = true`; eine bloße Nominierung zählt nicht als Einsatz. Bei vergleichbarer Einsatzhistorie werden die Nominierungshistorie und anschließend ein Zufalls-Tie-Breaker berücksichtigt.

## Muss ich die Empfehlung übernehmen?

Nein. Die Kaderempfehlung ist eine Orientierung und Entscheidungshilfe. Das Trainerteam kann die Nominierung weiterhin selbst festlegen. Nach einer Neuberechnung wird die gespeicherte Empfehlungsreihenfolge automatisch in der Spieltagsliste angezeigt. Eine bereits gespeicherte Empfehlung ändert sich nicht von selbst; sie wird erst durch eine erneute Berechnung aktualisiert.

---

**Dokumentationsstand:** 16.11.2026. Fachliche Grundlage: `docs/KADEREMPFEHLUNG_FACHLOGIK_V1.1_2026-11-15.md`. Hinweis: Ein authentifizierter End-to-End-Test des Übergangs bei der fünften gelben Karte wurde nicht separat durchgeführt.
