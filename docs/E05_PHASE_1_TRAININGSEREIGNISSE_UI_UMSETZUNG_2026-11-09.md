# E05 Phase 1 – Trainingsereignisse: UI-Umsetzung

- **Stand:** 09.11.2026
- **Branch:** `develop`
- **Zielumgebung:** Jugendmannschaft DEV
- **Status:** Implementiert und DEV-Deploy angestoßen; iPhone-Praxistest/Abnahme ausstehend
- **Datenbank:** Keine Änderung; vorhandene E05-RPCs und Tabellen werden verwendet
- **PROD:** Nicht verändert

## 1. Umfang

Die bestehende Trainingsdetailansicht wurde erweitert. Die drei vorhandenen Bereiche bleiben erhalten; ein vierter Tab **Ereignisse** wurde ergänzt.

Reihenfolge:
1. Rückmeldungen
2. Anwesenheit
3. Teams
4. Ereignisse

## 2. Bedienung

- Es werden ausschließlich aktive Spieler angezeigt, die im ausgewählten Training als anwesend markiert sind.
- Die vorhandene Trainings-Spielerzeile mit Avatar, Name und Metadaten wird wiederverwendet.
- Pro Spieler können eine gelbe Karte, eine rote Karte oder ein positiver Stern erfasst werden.
- Gelbe und rote Karten erfordern eine nicht leere Begründung. Beim positiven Stern ist die Begründung optional.
- Bereits erfasste aktive Ereignisse werden mit kompakten Material-Symbolen dargestellt.
- Pro Spieler und Training wird die vorhandene Datenbankregel berücksichtigt: höchstens eine aktive Karte (gelb oder rot) sowie höchstens ein aktiver positiver Stern.
- Suche filtert die anwesenden Spieler.
- Bei abgesagten Trainings und in reinen Lese-Kontexten werden keine Erfassungsaktionen angeboten.
- Die Ereignisliste wird beim Öffnen des Tabs aus der Datenbank geladen und beim erneuten Öffnen aktualisiert.

## 3. Technische Umsetzung

### Lesen
Die UI liest ausschließlich aktive Datensätze aus `public.training_behavior_events`, gefiltert auf die aktuelle `training_id`. Die bestehende SELECT-RLS-Policy erlaubt Teammitgliedern bzw. Superadmins im ausgewählten Teamkontext die Einsicht.

### Schreiben
Die Erfassung erfolgt ausschließlich über den bestehenden RPC:

```sql
public.award_training_behavior_event(
  p_training_id uuid,
  p_player_id uuid,
  p_event_type text,
  p_reason text
)
```

Es gibt keine direkten INSERTs in `training_behavior_events` und keine Schreibzugriffe auf die Audit-Tabelle aus dem Frontend. Die serverseitige Funktion prüft Authentifizierung, Teamrolle, Trainingsstatus, aktive Spielersaison, Anwesenheit und Pflichtbegründung und erstellt Ereignis sowie Audit atomar.

Die UI prüft Anwesenheit und Pflichtbegründung zusätzlich clientseitig. Die Datenbank bleibt die maßgebliche Instanz.

## 4. Geänderte Dateien

- `index.html` – Trainingsdetail-Tab, Ereignisliste, Erfassungsdialog, RPC-Aufruf und responsive Styles.

Keine SQL-Datei und keine Datenbankmigration wurde für Phase 1 erstellt oder ausgeführt.

## 5. Technische Prüfungen

- Aktueller Ausgangsstand aus `develop` abgerufen und gezielt erweitert.
- Vorhandene Trainings-Tabs und Renderfunktionen weiterverwendet.
- JavaScript-Syntaxprüfung des Hauptscripts erfolgreich (Supabase-ESM-Import für die Syntaxprüfung ausgeklammert).
- DEV-Deploy-Workflow wird bei jedem Push auf `develop` automatisch gestartet.
- GitHub Actions Deploy DEV Run #623 für den aktuellen UI-Code wurde gestartet; Ergebnis zum Zeitpunkt dieser Dokumentation noch ausstehend.

## 6. Noch ausstehende Praxistests

Auf dem iPhone in Jugendmannschaft DEV prüfen:

1. Ereignis-Tab erscheint an vierter Stelle; die drei bisherigen Tabs funktionieren unverändert.
2. Nur anwesende Spieler erscheinen.
3. Gelbe Karte ohne Begründung wird clientseitig verhindert.
4. Gelbe Karte mit Begründung wird gespeichert und nach erneutem Öffnen angezeigt.
5. Rote Karte mit Begründung wird gespeichert und angezeigt.
6. Positiver Stern lässt sich ohne Begründung speichern.
7. Zweite Karte bzw. zweiter Stern desselben Typs/Spielers wird nicht als neue Aktion angeboten.
8. Suche funktioniert und bleibt auf anwesende Spieler begrenzt.
9. Absagestatus und reine Lese-Kontexte bieten keine Schreibaktion.
10. Helles und dunkles Design sowie schmale iPhone-Bildschirmbreiten prüfen.
11. Rückmeldungen, Anwesenheit und Teams funktionieren weiterhin unverändert.

## 7. Abgrenzung

Korrektur und Stornierung bereits erfasster Ereignisse sind bewusst nicht Bestandteil dieses Trainings-Tabs. Gemäß UI-Konzept erfolgen diese Aktionen später in den Spielerdetails mit Begründung und Auditspur (Folgephase).

Die zentrale Ereignisübersicht in der Spielerliste sowie Sperren-, Ausnahme- und Sperrausgleichsaktionen in der Spieltagsplanung folgen in den nächsten Phasen.
