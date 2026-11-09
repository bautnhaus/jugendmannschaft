# E05 Phase 1 – Trainingsereignisse: UI-Umsetzung

- **Stand:** 09.11.2026
- **Branch:** `develop`
- **Zielumgebung:** Jugendmannschaft DEV
- **Status:** UI-Korrekturrunde umgesetzt; DEV-Deploy/ iPhone-Praxistest und Abnahme ausstehend
- **Datenbank:** Keine Änderung; vorhandene E05-RPCs und Tabellen werden verwendet
- **PROD:** Nicht verändert

## 1. Umfang

Die bestehende Trainingsdetailansicht wurde erweitert. Die drei vorhandenen Bereiche bleiben erhalten; ein vierter Tab **Ereignisse** wurde ergänzt.

Reihenfolge:
1. Zu-/Absagen
2. Anwesenheit
3. Teams
4. Ereignisse

## 2. Bedienung

- Es werden ausschließlich aktive Spieler angezeigt, die im ausgewählten Training als anwesend markiert sind.
- Die vorhandene Trainings-Spielerzeile mit Avatar, Name und Metadaten wird wiederverwendet.
- Pro Spieler gibt es nur eine Aktion „Ereignis hinzufügen“. Ein gemeinsamer, zweistufiger Dialog lässt zunächst zwischen positivem Stern, gelber Karte und roter Karte wählen und fragt anschließend die Begründung ab.
- Gelbe und rote Karten erfordern eine nicht leere Begründung. Beim positiven Stern ist die Begründung optional.
- Bereits erfasste aktive Ereignisse werden mit kompakten Symbolen dargestellt. Die Karten werden als gelbe bzw. rote Farbmarkierung, positive Sterne als Sternsymbol angezeigt.
- Bereits ausgeschöpfte Ereignisarten werden im Dialog deaktiviert: maximal eine aktive Karte (gelb oder rot) sowie maximal ein aktiver Stern je Spieler und Training.
- Der Tab „Rückmeldungen“ wurde in „Zu-/Absagen“ umbenannt; die vier Tabs erhalten eine kompakte, gleichmäßige Darstellung.
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

- `index.html` – Trainingsdetail-Tabs, Ereignisliste, gemeinsamer zweistufiger Erfassungsdialog, RPC-Aufruf und responsive Styles.

Keine SQL-Datei und keine Datenbankmigration wurde für Phase 1 erstellt oder ausgeführt.

## 5. Technische Prüfungen

- Aktueller Ausgangsstand aus `develop` abgerufen und gezielt erweitert.
- Vorhandene Trainings-Tabs und Renderfunktionen weiterverwendet.
- JavaScript-Syntaxprüfung des Hauptscripts erfolgreich (Supabase-ESM-Import für die Syntaxprüfung ausgeklammert).
- DEV-Deploy-Workflow wird bei jedem Push auf `develop` automatisch gestartet.
- JavaScript-Syntaxprüfung nach der UI-Korrekturrunde erfolgreich.
- DEV-Deploy wird automatisch durch Push auf `develop` gestartet; das Ergebnis des aktuellen Laufs ist separat zu kontrollieren.

## 6. Noch ausstehende Praxistests

Auf dem iPhone in Jugendmannschaft DEV prüfen:

1. „Zu-/Absagen“ wird vollständig und ohne Überlappung angezeigt; die drei übrigen Tabs funktionieren unverändert.
2. Ereignis-Tab erscheint an vierter Stelle und zeigt pro Spieler nur eine Aktion „Ereignis hinzufügen“.
3. Der gemeinsame Dialog erlaubt die Auswahl aller drei Ereignisarten und deaktiviert bereits ausgeschöpfte Ereignisarten.
4. Nur anwesende Spieler erscheinen.
5. Gelbe Karte ohne Begründung wird clientseitig verhindert.
6. Gelbe Karte mit Begründung wird gespeichert und nach erneutem Öffnen angezeigt.
7. Rote Karte mit Begründung wird gespeichert und angezeigt.
8. Positiver Stern lässt sich ohne Begründung speichern.
9. Zweite Karte bzw. zweiter Stern desselben Typs/Spielers wird im Dialog nicht angeboten.
10. Suche funktioniert und bleibt auf anwesende Spieler begrenzt.
11. Absagestatus und reine Lese-Kontexte bieten keine Schreibaktion.
12. Helles und dunkles Design sowie schmale iPhone-Bildschirmbreiten prüfen.
13. Zu-/Absagen, Anwesenheit und Teams funktionieren weiterhin unverändert.

## 7. Abgrenzung

Korrektur und Stornierung bereits erfasster Ereignisse sind bewusst nicht Bestandteil dieses Trainings-Tabs. Gemäß UI-Konzept erfolgen diese Aktionen später in den Spielerdetails mit Begründung und Auditspur (Folgephase).

Die zentrale Ereignisübersicht in der Spielerliste sowie Sperren-, Ausnahme- und Sperrausgleichsaktionen in der Spieltagsplanung folgen in den nächsten Phasen.


### UI-Feinkorrektur nach iPhone-Praxistest

- Der iPhone-Praxistest bestätigte den gemeinsamen Dialog und den Ablauf zur Begründungseingabe.
- Pflichtfelder werden nicht mit einem Sternchen markiert. Der bisherige Gestaltungsstandard kennzeichnet ausschließlich optionale Angaben mit „(optional)“.
- Entsprechend wird „Begründung“ bei gelber/roter Karte ohne Sternchen angezeigt; beim positiven Stern bleibt „(optional)“ sichtbar.
- Änderung in `index.html`, Commit `c2e25a9a`; JavaScript-Syntaxprüfung erfolgreich. DEV-Deploy nach Push abzuwarten.


### Ereignis-Kennzahlen

- Oberhalb der Spielerliste werden drei Kennzahlen-Karten angezeigt: positive Sterne, gelbe Karten und rote Karten.
- Die Zahlen zählen ausschließlich aktive Ereignisse des aktuell geöffneten Trainings. Die Datenquelle wird bereits mit `status = 'active'` geladen; stornierte Ereignisse fließen daher nicht ein.
- Die Kennzahlen werden aus dem geladenen Ereignisbestand berechnet und benötigen keine zusätzliche Datenbankabfrage oder Schemaänderung.
- Responsive Darstellung mit drei gleich breiten Karten sowie Anpassungen für Dark Mode.
- Umsetzung in `index.html`, Commit `4cc5d25a`; JavaScript-Syntaxprüfung erfolgreich. DEV-Praxistest ausstehend.


### Farbkorrektur nach iPhone-Praxistest

- Rückmeldung: rote Karte im Dark Mode zu blass; gelbe Karte im Light Mode zu dunkel.
- Gelbe Karte im Light Mode auf ein klareres Gelb (`#FACC15`) mit passender dunklerer Akzentfarbe angepasst.
- Rote Karte im Dark Mode auf ein kräftigeres, kontrastreiches Rot (`#F87171`) angepasst.
- Umsetzung in `index.html`, Commit `da318969`; JavaScript-Syntaxprüfung erfolgreich. Erneuter iPhone-Praxistest ausstehend.
