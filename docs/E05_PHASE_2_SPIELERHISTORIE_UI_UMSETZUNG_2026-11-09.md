# E05 Phase 2 – Spielerdetails: Ereignis- und Sperrenhistorie

- **Stand:** 09.11.2026
- **Branch:** `develop`
- **Zielumgebung:** Jugendmannschaft DEV
- **Status:** Erste Frontend-Umsetzung bereit für DEV-Praxistest; fachliche Abnahme ausstehend
- **Datenbank:** Ausschließlich read-only geprüft; keine SQL-Änderung und keine Migration
- **PROD:** Nicht verändert

## 1. Ziel und Einordnung

Die bestehende Spielercard wird erweitert. Die Umsetzung folgt dem E05-UI-Konzept: Ereignishistorie und Sperrenhistorie mit neuesten Einträgen zuerst, Auditdetails und Korrekturzugängen direkt am jeweiligen Eintrag. Es wird keine neue Spieler- oder Verwaltungsseite aufgebaut.

## 2. Read-only Datenbankabgleich

Projekt: Supabase DEV `pzazqvvoruqnqhcorbwx`.

Bestätigte Tabellen und Felder:
- `training_behavior_events`: Spieler-/Team-/Saisonbezug, Trainings-Snapshot, Ereignistyp, Begründung, Status, Erfassungszeitpunkt sowie Storno-Metadaten.
- `training_behavior_event_audit`: Aktion, Vorher-/Nachher-Snapshot, Begründung, Akteur-Snapshot und Zeitpunkt.
- `training_suspensions`: Sperrentyp, Status, Quellereignis, vorgesehener und abgeleisteter Spieltag sowie historische Snapshots.
- `training_suspension_audit`: Aktionen, Vorher-/Nachher-Snapshot, Begründung, Akteur-Snapshot und Zeitpunkt.

Die SELECT-RLS-Policies der vier Tabellen sind teambezogen und bleiben unverändert. Die bestehenden Schreiboperationen sind SECURITY DEFINER-RPCs mit festem `search_path = pg_catalog, public, auth` und EXECUTE für `authenticated`.

Verifizierte RPC-Verträge:
- `correct_training_behavior_event(p_event_id uuid, p_target_status text, p_reason text)`: Kartenereignisse zwischen `active` und `voided` ändern; Sperrenzustand wird in derselben Transaktion abgeglichen.
- `correct_suspension(p_suspension_id uuid, p_target_matchday_id uuid, p_reason text)`: offene Sperre einem zulässigen zukünftigen Spieltag zuordnen.

Wichtige fachliche Einschränkung des vorhandenen DB-Vertrags: Paket 9 erlaubt die Statuskorrektur ausdrücklich nur für gelbe und rote Karten, nicht für positive Sterne. Die UI zeigt positive Sterne in der Historie, bietet dafür aber keine Korrekturaktion an. Eine Erweiterung wäre ein separates Datenbankpaket mit eigener Freigabe.

## 3. Frontend-Umsetzung

Datei: `index.html`.

- In der bestehenden Spielercard wurde ein kompakter Einstieg **„Karten & Sperren“** ergänzt.
- Ereignisse und Sperren werden beim Öffnen aus den vorhandenen Tabellen geladen.
- Ereignisse zeigen Typ, Trainingsdatum/-name, Erfassungszeitpunkt, Status und Begründung.
- Stornierte Karten zeigen zusätzlich den Stornogrund.
- Sperren zeigen Typ, Status und zugeordneten Spieltag.
- Die Änderungsverläufe können je Eintrag aufgeklappt werden. Angezeigt werden Aktion, Zeitpunkt, Akteur-Snapshot und Begründung.
- Aktive gelbe/rote Karten können über die vorhandene RPC mit verpflichtender Begründung storniert werden.
- Stornierte gelbe/rote Karten können über dieselbe RPC mit verpflichtender Begründung wiederhergestellt werden.
- Offene Sperren können über `correct_suspension` einem anderen zukünftigen geplanten Spieltag zugeordnet werden. Die Datenbank bleibt für Spielart, Team/Saison, aktive Ausnahme, Sperrenstatus und Berechtigung maßgeblich.
- Es gibt keine direkten Tabellen-Schreibzugriffe aus dem Frontend.
- UI-Aktionen ersetzen keine serverseitige Berechtigungsprüfung.

## 4. Technische Prüfung und Deploy

- Ausgangsdatei frisch aus `develop` geladen.
- JavaScript-Syntaxprüfung nach Änderung erfolgreich (Supabase-ESM-Import für die lokale Syntaxprüfung ausgeklammert).
- Commit mit UI: `a47d69070eac14e0c6ed27279be25c00cf96adfc`.
- Nachkorrektur des Superadmin-Kontextchecks: `663adc99b4f6791c95a7ddb5de2e9279f9e691e1`.
- Nachkorrektur: Korrekturaktionen werden in der UI nur für Trainer, Mannschaftsadmins und Superadmins im ausgewählten Teamkontext angezeigt: `60a0eb4a972e93bc120b346261c9f7e2aa83ab53`.
- DEV-Deploy-Workflow für den neuesten Commit ist separat zu kontrollieren.
- Keine SQL-Ausführung, keine Datenbankänderung, keine Änderung an `main` oder PROD.

## 5. DEV-Praxistest – noch ausstehend

1. Spielercard öffnen und „Karten & Sperren“ aufrufen.
2. Ereignisse und Sperren erscheinen vollständig und neueste Einträge zuerst.
3. Trainingsname, Datum, Ereignistyp, Status und Begründungen sind korrekt.
4. Änderungsverlauf je Ereignis und Sperre lässt sich öffnen.
5. Aktive gelbe Karte mit Begründung stornieren; nach erneutem Laden Status und Audit prüfen.
6. Stornierte gelbe Karte mit Begründung wiederherstellen; Kartenkonto/Sperrenzustand anschließend kontrollieren.
7. Dasselbe mit roter Karte prüfen, sofern ein geeigneter Testdatensatz vorhanden ist.
8. Positive Sterne werden angezeigt; es wird keine nicht unterstützte Korrekturaktion angeboten.
9. Offene Sperre auf einen zulässigen zukünftigen Spieltag verschieben; Zielzuordnung und Audit prüfen.
10. Ungültiges Ziel, fehlende Begründung, bereits bediente Sperre und fehlende Berechtigung müssen serverseitig abgewiesen werden.
11. Trainer, Mannschaftsadmin und Superadmin im ausdrücklich ausgewählten Teamkontext prüfen.
12. Light/Dark Mode, iPhone-Breite und Scrollverhalten testen.
13. Spielerdetails, Trainings- und Spieltagsansichten außerhalb des neuen Bereichs auf Regression prüfen.

## 6. Abgrenzung / offene Entscheidung

Die aktuelle DB-Funktion kann Ereignisstatus von Karten korrigieren, aber weder Ereignistyp noch Ereignisbegründung bearbeiten und positive Sterne nicht stornieren/wiederherstellen. Die UI bildet exakt den vorhandenen DB-Vertrag ab. Falls fachlich auch positive Sterne oder inhaltliche Kartenkorrekturen geändert werden sollen, ist dafür vor einer Umsetzung ein gesondertes SQL-Paket vorzulegen und freizugeben.

**Abnahme:** Noch nicht erfolgt. DEV-Praxistest durch den Nutzer steht aus.


### UI-Feinkorrektur vor DEV-Praxistest

- Ereignissymbole in der Historie verwenden jetzt Material Symbols für Sterne und die vorhandenen Kartenmarkierungen statt Emoji-Platzhaltern.
- Die Audit-Abfragen lesen nun auch `old_values` und `new_values`; im aufklappbaren Änderungsverlauf werden die verfügbaren Vorher-/Nachher-Zustände zusätzlich zu Aktion, Zeitpunkt, Akteur-Snapshot und Begründung angezeigt.
- JavaScript-Syntaxprüfung erfolgreich.
- Commit: `f5269e46319aae9c45cfcc07faef5ea899a06dcf`.
- DEV-Praxistest weiterhin ausstehend; PROD unverändert.


### DEV-Prüfnachtrag 13.11.2026 – Read-only Daten-/Codeprüfung
- Supabase DEV enthält 19 Ereignisse, 21 Ereignis-Audits, 6 Sperren und 25 Sperren-Audits. Integritätsprüfung: keine fehlenden Trainings-/Spieler-Snapshots, keine verwaisten Quellereignisse und keine fehlenden Audit-Kernfelder.
- Ein vorhandenes storniertes Kartenereignis wurde durch den bisherigen Filter „Karten“ ausgeblendet, weil dieser nur aktive Ereignisse berücksichtigte. Behoben: Filter nutzt jetzt `allEvents` und zeigt auch stornierte gelbe/rote Karten.
- Codecommit `27eb0dd188016418f4625dc801e19a8c923a659e`; DEV-Spiegel-Blob identisch verifiziert.
- Audit-Namensauflösung bleibt eingeschränkt: fehlende Akteur-Snapshots können Trainer aufgrund der bestehenden `profiles_select`-RLS-Policy nicht zuverlässig durch Profil-Lookup ergänzen. Separate SQL-Lösung nicht Teil dieser Prüfung.
- Ausschließlich SELECT-Abfragen; keine Testdaten angelegt, keine Daten verändert, keine SQL-/Schema-/RLS-/PROD-Änderung.
- Browser-/RPC-Praxistests der Storno-/Wiederherstellungs- und Sperrenkorrektur bleiben offen. Details: `docs/E05_AP05_4_SPIELERCARD_READONLY_TEST_2026-11-13.md`.
