# Release 1.7 – Epic 05: Konsolidierter Gesamtstatus

- **Stichtag:** 10.11.2026
- **Repository:** `bautnhaus/jugendmannschaft`
- **Dokumentations- und Entwicklungsbranch:** `develop`
- **PROD-Branch:** `main`
- **Status:** Backend-Fundament in DEV umgesetzt; Frontend-Integration und Gesamtvalidierung noch offen
- **Verbindliche Umgebung:** Änderungen und weitere Tests ausschließlich in DEV/`develop`, bis eine separate PROD-Freigabe erteilt wird.

## 1. Abgleich des tatsächlichen Repository- und Deploy-Stands

Zum Zeitpunkt der Statusaufnahme:

- `develop` HEAD: `c15375c8786de6f3c1eb1eb729293c0a173a24b5`
- `main` HEAD: `471596887dd71ecf9ded70a8fdcd1f43344bfa05`
- Der letzte Deploy-DEV-Lauf für `develop` (Run 667, Commit `c15375c`) ist in GitHub Actions mit **completed / success** dokumentiert.
- `main` liegt auf einem separaten Commit; es wurde im Rahmen dieser Statusaufnahme weder gemergt noch verändert.
- Es wurden keine Datenbankabfragen oder Datenbankänderungen im Rahmen dieser Dokumentationsaktualisierung ausgeführt.

## 2. Fachlicher und technischer Status

### 2.1 Datenbank-Arbeitspakete 1–9

Die Dokumentations- und Ausführungsprotokolle der Pakete 1–9 liegen in `docs/` vor. Sie beschreiben das Ereignisfundament, Vergabe, Sperrenauslösung und -zuordnung, Ausnahmen, Saisonabschluss, vorzeitigen Sperrausgleich sowie manuelle Karten-/Sperrenkorrekturen.

**Statusbewertung:** In DEV umgesetzt und in den jeweiligen Paketprotokollen dokumentiert. Diese Aussage ist keine pauschale Freigabe aller fachlichen Randfälle oder eine PROD-Abnahme. Die noch offenen Frontend- und End-to-End-Tests sind in Abschnitt 4 aufgeführt.

### 2.2 Frontend Phase 1 – Trainingsereignisse

- Ereignisvergabe im bestehenden Trainingsdetail wurde in die vorhandene Trainingsnavigation integriert.
- Ereignisarten: gelbe Karte, rote Karte und positiver Stern.
- Begründungsregeln und Anwesenheits-/Berechtigungskontext sind Bestandteil der UI.
- Ereigniskennzahlen und Ereignismarkierungen wurden fachlich für Light und Dark Mode bestätigt.
- Das Phase-1-Dokument hält die fachliche Abnahme fest.

**Status: Fachlich abgeschlossen.** Regressionstests der übrigen Trainingsfunktionen bleiben Bestandteil des Gesamttests.

### 2.3 Frontend Phase 2 – Spielercard und Historie

Die erste Phase-2-Implementierung enthält:
- Ereignis- und Sperrenhistorie mit neuesten Einträgen zuerst.
- Status, Begründungen, Trainingsbezug und Auditverläufe.
- Stornierung/Wiederherstellung gelber und roter Karten mit Begründung.
- Verschiebung offener Sperren auf zulässige zukünftige Spieltage.
- Rollen- und Teamkontextprüfungen in der Oberfläche.

Die zuletzt ergänzte Ereignisübersicht auf der Spielercard wurde separat überarbeitet:
- Trainingszeit-Normalisierung zur Behebung leerer Historienlisten.
- Trainings-/Ereignisdaten werden je Spieler gecacht; Filterwechsel erfolgen clientseitig.
- Cache-Invalidierung nach Korrekturaktionen.
- Einheitliches Listenlayout anhand der vorhandenen Spieler-/Spieltagshistorie.
- Filter Alle, Karten, Sperren und Sterne.
- Ereigniskachel mit `fact_check`, violetter Gestaltung und Pfeil in der Titelzeile.
- Notizenkachel mit `sticky_note_2` und Pfeil in der Titelzeile.

**Nutzerbestätigung im DEV-Praxistest:**
- Darstellung der Ereigniskachel und Notizenkachel: bestätigt.
- Listenaufbau der Ereignishistorie: bestätigt.
- Funktion der vier Filter: ausdrücklich bestätigt.
- Trainings- und Spieltagskacheln: nach Wiederherstellung bestätigt und sollen unverändert bleiben.

**Wichtige Abgrenzung:** Diese Bestätigung betrifft die Ereignisübersicht/Filter und die Kacheldarstellung. Sie ersetzt nicht den noch ausstehenden End-to-End-Test der Korrekturaktionen und der vollständigen Audit-/Sperrenhistorie aus Phase 2.

## 3. Offene technische/fachliche Einschränkungen

1. **Audit-Namensauflösung:** Die ursprüngliche Benutzer-ID wird gespeichert. Aufgrund der bestehenden RLS-Regel können Trainer fremde Profilnamen nicht zuverlässig lesen. Ein serverseitiger Name-Snapshot bei der initialen Ereignisanlage wäre eine mögliche Lösung und erfordert ein separates SQL-Konzept sowie eine ausdrückliche Freigabe. Bis dahin darf die UI keinen nicht auflösbaren Namen als garantiert anzeigen.
2. **Positive Sterne:** Der dokumentierte RPC-Vertrag aus Paket 9 erlaubt Statuskorrekturen nur für gelbe und rote Karten. Positive Sterne werden angezeigt, haben aber keine Korrekturaktion. Eine Erweiterung ist nicht Bestandteil des aktuellen Vertrags und benötigt ein separates freizugebendes SQL-Paket.
3. **Inhaltliche Kartenkorrektur:** Ereignistyp und ursprüngliche Begründung können mit dem bestehenden Korrektur-RPC nicht editiert werden. Aktuell sind Statuskorrekturen (active/voided) abgebildet.
4. **Spieltag-/Kaderintegration:** Die tatsächliche Anzeige und Durchsetzung von Sperren, Ausnahmen und Sperrausgleich in der Spieltagsplanung muss noch anhand des aktuellen DEV-Codes und durch Praxistests verifiziert werden.
5. **Zentrale Ereignis-Spielerliste:** Ob eine separate zentrale Ereignisansicht außerhalb der Spielercard bereits vollständig integriert und abgenommen ist, ist mit den vorliegenden Abnahmen noch nicht belegt.

## 4. Verbindliche Restarbeiten und Abnahmekriterien

### A. Spielercard – vollständige Historie und Korrekturen
- [ ] Ereignisse und Sperren vollständig, chronologisch korrekt und mit richtigen Status-/Begründungsdaten anzeigen.
- [ ] Auditdetails öffnen; Zeitpunkt, Akteur-Snapshot, Aktion und Vorher-/Nachher-Werte kontrollieren.
- [ ] Gelbe Karte stornieren und wiederherstellen; Kartenkonto und Sperrenzustand danach prüfen.
- [ ] Rote Karte stornieren und wiederherstellen, sofern geeigneter DEV-Testdatensatz vorhanden.
- [ ] Offene Sperre auf zulässigen zukünftigen Spieltag verschieben.
- [ ] Ungültiges Ziel, fehlende Begründung, bereits bediente Sperre und fehlende Berechtigung müssen serverseitig abgewiesen werden.
- [ ] Trainer, Mannschaftsadmin und Superadmin im ausdrücklich ausgewählten Teamkontext testen.
- [ ] Audit-Namensauflösung mit bestehender RLS-Grenze fachlich akzeptieren oder separates SQL-Konzept zur Freigabe vorlegen.

### B. Zentrale Ereignisansicht der Spielerliste
- [ ] Existenz und aktueller Implementierungsstand anhand `develop/index.html` prüfen.
- [ ] Filter, Sortierung, Statusdarstellung und Navigation im DEV-Praxistest abnehmen.
- [ ] Keine neue Parallelansicht bauen, falls bereits eine passende bestehende Komponente existiert.

### C. Spieltagskader und Sperren
- [ ] Gesperrte Spieler im Spieltagskontext korrekt kennzeichnen.
- [ ] Ausnahmen und vorzeitigen Sperrausgleich korrekt berücksichtigen.
- [ ] Unzulässige Nominierung/Einsatzfreigabe verhindern bzw. fachlich klar behandeln.
- [ ] Sperrenzuordnung nach Spieltag, Team, Saison und Spielart verifizieren.
- [ ] Kaderempfehlung mit Sperrenstatus prüfen; keine unzulässige Empfehlung.
- [ ] Bestehende Trainings- und Spieltagsstatistiken unverändert lassen.

### D. Gesamtregression
- [ ] Trainingsablauf, Zu-/Absagen und Anwesenheit.
- [ ] Ereignisvergabe im Trainingsdetail.
- [ ] Spieltagsplanung und Kaderempfehlung.
- [ ] Spielerübersicht und Spielercard.
- [ ] Light/Dark Mode und schmale iPhone-Bildschirmbreiten.
- [ ] Rollen-/Teamkontext und RLS-relevante Ansichten.

## 5. Release-Gate

Epic 05 ist **noch nicht PROD-freigegeben**. Vor einer Freigabe sind erforderlich:

1. Alle oben genannten DEV-Praxistests abschließen und dokumentieren.
2. Offene SQL-Themen (insbesondere Audit-Name-Snapshot) separat beschreiben und nur nach ausdrücklicher Freigabe bearbeiten.
3. SQL-Release-Katalog und ausführbares PROD-Migrationspaket gegen den tatsächlichen PROD-Schema-/Datenstand abgleichen.
4. Migrationsskripte auf Datenerhalt, Rollen, RLS und Wiederholbarkeit prüfen.
5. Explizite PROD-Freigabe des Nutzers einholen.

## 6. Arbeitsregeln

- Ausschließlich `develop` und Supabase DEV für weitere E05-Arbeiten.
- Keine SQL-Ausführung oder Schemaänderung ohne gesonderte Freigabe.
- Keine Änderungen an `main` oder PROD ohne separate Freigabe.
- Vor Codeänderungen aktuelle `develop/index.html` frisch laden.
- Bestehende Komponenten und Referenzlayouts wiederverwenden; keine parallelen UI-Neuentwicklungen.
- Jede Änderung und jeder Test ist in GitHub `develop` zu dokumentieren.

## 7. Quellen innerhalb des Repositories

- `docs/E05_PAKET_01_DEV_AUSFUEHRUNGSPROTOKOLL_2026-11-08.md`
- `docs/E05_PAKET_02_FREIGABE_UND_AUSFUEHRUNG_2026-11-08.md` bis `docs/E05_PAKET_09_ABNAHME_UND_AUSFUEHRUNG_2026-11-08.md`
- `docs/E05_PHASE_1_TRAININGSEREIGNISSE_UI_UMSETZUNG_2026-11-09.md`
- `docs/E05_PHASE_2_SPIELERHISTORIE_UI_UMSETZUNG_2026-11-09.md`
- `docs/E05_UI_KONZEPT_UMSETZUNGSLEITLINIE_2026-11-07.md`
- `docs/E05_TECHNISCHES_ZIELDATENMODELL_2026-11-08.md`
- `docs/E05_TESTABDECKUNG_REVIEW_2026-11-08.md`
- `docs/E05_TESTSTRATEGIE_UND_DEV_VORGEHEN_2026-11-08.md`
- `docs/E05_UI_ANPASSUNGEN_SPIELERKARTE_2026-11-10.md`

---
**Gesamtbewertung:** Backend-Grundlage in DEV umgesetzt; Phase 1 fachlich abgeschlossen; jüngste Ereignis-/Notizenkachel und Ereignisfilter durch Nutzer im DEV bestätigt; Phase 2 Korrektur-/Audit-End-to-End-Abnahme, zentrale Ereignisansicht, Spieltagskaderintegration und Gesamtregression offen.
