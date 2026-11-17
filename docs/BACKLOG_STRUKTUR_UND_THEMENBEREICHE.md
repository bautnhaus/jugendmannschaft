# KADAssist – Backlog-Struktur und Themenbereiche

**Beschlossen am 17.11.2026.** Diese Systematik gilt für die weitere Pflege des Produkt-Backlogs. Bestehende Epic-IDs und bereits getroffene fachliche Entscheidungen bleiben erhalten.

## 1. Verbindliche Backlog-Ebenen

1. **Themenbereich:** Langfristiges fachliches Produktgebiet. Themenbereiche bleiben bestehen und werden nicht abgeschlossen.
2. **Epic:** Eigenständiges, fachlich abgegrenztes Vorhaben mit konkretem Ziel und Abnahmekriterien. Ein Epic kann abgeschlossen werden.
3. **Anforderung / Feature:** Fachliche Beschreibung einer oder mehrerer konkreter Funktionen innerhalb eines Epics.
4. **Arbeitspaket:** Konkrete technische Umsetzung, Prüfung und Tests.

## 2. Regeln für Ideen und Epics

- Neue Ideen dürfen zunächst nur einem Themenbereich zugeordnet und dort ohne Epic-ID gesammelt werden.
- Eine Epic-ID wird erst vergeben, wenn die Idee ausreichend konkretisiert und als eigenständiges Vorhaben abgegrenzt ist.
- Jedes Epic erhält ein eigenes Ziel und überprüfbare Abnahmekriterien.
- Abgeschlossene Epics bleiben abgeschlossen. Neue Ideen oder spätere Erweiterungen werden grundsätzlich als neue Epics im passenden Themenbereich geführt; abgeschlossene Epics werden deswegen nicht wieder geöffnet.
- Bestehende Epic-Nummern und fachliche Entscheidungen werden durch die neue Struktur nicht umnummeriert oder aufgehoben.
- Abhängigkeiten zwischen Epics werden separat dokumentiert und ändern nicht automatisch deren Status.
- Themenbereich und Epic-Zuordnung sind fachliche Backlog-Metadaten; sie behaupten nicht, dass eine Funktion bereits umgesetzt oder getestet ist.

## 3. Themenbereiche und Zuordnung des bestehenden Backlogs

| Themenbereich | Zugeordnete Epics | Schwerpunkt |
|---|---|---|
| Vereins- und Mannschaftsverwaltung | E04a, E04 | Vereinsstruktur, Mannschaften, Saisonverwaltung und Saisonübergänge |
| Benutzer-, Trainer- und Rechteverwaltung | E02, E16, E12 | Benutzer, Trainer, Rollen, Berechtigungen; perspektivisch Elternkonten |
| Spielerverwaltung | E03, E20 | Spielerstammdaten, Profile und perspektivisch Spielerentwicklung |
| Kaderplanung und Kaderempfehlung | E05, E23 | Kaderauswahl, Empfehlungen und Vormerkung für kommende Spieltage |
| Mannschaftsbildung und Spielformen | E06 | Ausgewogene Teams, Altersklassen, Spielformen und Formationen |
| Trainingsverwaltung | E07 | Trainingsplanung und Trainingsdurchführung |
| Verfügbarkeit und Rückmeldungen | E11 | Zu-/Absagen und Rückmeldungen zu Trainings und Spieltagen |
| Spieltagsorganisation und Einsätze | E08, E18, E19 | Spieltagsplanung, tatsächliche Einsätze und Spieltagsabschluss |
| Historie und Auswertungen | E17 | Mannschaftshistorie und mannschaftsübergreifende Einsätze |
| Dashboard und Benutzerorientierung | E09, E14, E15 | Dashboard, Navigation und FAQ/Hilfebereich |
| Benutzeroberfläche und Designsystem | E10, E13 | UI-Konsistenz, Bedienbarkeit und Icon-Bibliothek |
| Benachrichtigungen | E22 | In-App-Information über relevante Ereignisse und Änderungen |
| Rechtliches und Datenschutz | E21 | Rechtliche Grundlagen und Datenschutz |
| Entwicklung und Releaseverwaltung | E01 | DEV-/PROD-Prozess und Releases |

**Hinweise zur Einordnung:**
- E04a (Vereins- und Mannschaftsmodell) ist bereits in PROD; E04 (Saisonverwaltung und Saisonübergänge) bleibt ein eigenständiges Epic.
- E12 (Elternkonten) ist eine perspektivische Idee und nicht Bestandteil der aktuellen ersten Benachrichtigungs- oder Funktionsiteration.
- E22 (Benachrichtigungen) ist neu und fachlich noch in Ausarbeitung. Die erste Iteration soll sich auf den aktuellen KADAssist-Umfang konzentrieren; Push und E-Mail sind zunächst nicht vorgesehen.
- E23 ist als Epic für „Nominierung für einen kommenden Spieltag vormerken“ zugeordnet. Die Anforderung wurde fachlich beschrieben; technische Prüfung und Umsetzung stehen noch aus.
- Die Zuordnung ist keine neue Statusabnahme. Statusangaben bleiben in den jeweiligen Epic-Dokumentationen maßgeblich.

## 4. Neue Idee ohne Epic-ID erfassen

Für eine neue Idee genügt zunächst:
- Titel / Kurzbeschreibung
- zugeordneter Themenbereich
- optionaler Nutzen oder Anlass
- Status „Idee – noch nicht konkretisiert“

Erst nach fachlicher Klärung wird entschieden, ob daraus ein eigenständiges Epic, eine Anforderung innerhalb eines bestehenden offenen Epics oder eine bewusst zurückgestellte Idee wird.

## 5. Beispiel

Themenbereich **Kaderplanung und Kaderempfehlung** bleibt dauerhaft bestehen. E05 kann seinen eigenen Abschlussstatus behalten. Die später ergänzte Funktion „Nominierung für einen kommenden Spieltag vormerken“ wird als eigenständiges E23 geführt und öffnet E05 nicht erneut.
