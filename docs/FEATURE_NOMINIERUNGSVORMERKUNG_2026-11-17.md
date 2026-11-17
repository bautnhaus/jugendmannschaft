# Feature-Spezifikation – Nominierung für einen kommenden Spieltag vormerken

**Stand:** 17.11.2026  
**Status:** Fachlich abgestimmt – technische Vorbereitung, keine Umsetzung  
**Zielbranch:** `develop`  
**Zielumgebung:** Supabase DEV  
**PROD:** unverändert

> **ID-Hinweis:** Die Bezeichnung E05 ist im aktuellen Projektkontext bereits für das Sperren-/Verhaltensereignis-Thema belegt. Diese neue Funktion wird deshalb bis zur Backlog-Zuordnung neutral als „Nominierungsvormerkung“ geführt. Keine bestehende Epic-ID wird überschrieben oder doppelt vergeben.

## 1. Ziel

Trainer können einen Spieler, der bei einem Spieltag verfügbar, aber nicht nominiert war, manuell für eine spätere Nominierung vormerken. Die Vormerkung beeinflusst die Kaderempfehlung der Mannschaft, ersetzt aber niemals die Entscheidung und Nominierung durch den Trainer.

## 2. Fachliche Entscheidungen

| Thema | Verbindliche Entscheidung |
|---|---|
| Auslöser | Trainer wählt bei einem nicht nominierten Spieler im Optionen-Menü „Nominierung vormerken“. |
| Verfügbarkeit | Der Trainer bestätigt im Dialog selbst, dass der Spieler am Ausgangsspieltag verfügbar war. Es wird keine neue allgemeine Verfügbarkeitsverwaltung eingeführt. |
| Begründung bei Erstellung | Pflichtfeld. |
| Kaderempfehlung | Spieler mit offener Vormerkung erhalten Vorrang vor Spielern ohne Vormerkung. |
| Bestehende Rangfolge | Innerhalb der Gruppe mit und ohne Vormerkung bleibt die bestehende Empfehlungslogik erhalten. |
| Kadergröße | Bleibt unverändert. Vormerkungen schaffen keine zusätzlichen Kaderplätze. |
| Mehr Vormerkungen als Kaderplätze | Die bestehende Empfehlungslogik entscheidet über die Reihenfolge innerhalb der vorgemerkten Gruppe; nicht berücksichtigte Vormerkungen bleiben offen. |
| Nominierung | Ausschließlich manuell durch den Trainer. Empfehlung allein erfüllt keine Vormerkung. |
| Erfüllung | Eine tatsächliche Aufnahme des Spielers in den Spieltagskader erfüllt die offene Vormerkung. |
| Nicht nominiert | Die Vormerkung bleibt offen und wird bei weiteren Kaderempfehlungen erneut berücksichtigt. |
| Rücknahme | Trainer können eine offene Vormerkung über das Spieler-Optionen-Menü zurücknehmen. |
| Begründung Rücknahme | Pflichtfeld; die Rücknahme wird analog zur bestehenden Sperrvormerkungsbedienung bestätigt. |
| Kachelhinweis | Nur „Nominierung vorgemerkt“; die ursprüngliche Begründung wird nicht auf der Kachel angezeigt. |
| Historie | Erfüllte und zurückgenommene Vormerkungen bleiben nachvollziehbar erhalten. |
| Automatische Erinnerungen | Nicht Bestandteil der ersten Version. |
| Prioritätspunkte / Gewichtung | Nicht Bestandteil der ersten Version. |
| Statistiken | Nicht Bestandteil der ersten Version. |

## 3. Nutzerabläufe

### 3.1 Vormerkung erstellen

1. Trainer öffnet bei einem Spieler, der am Ausgangsspieltag nicht nominiert wurde, das Optionen-Menü.
2. Aktion „Nominierung vormerken“ wird angeboten.
3. Dialog fordert die Bestätigung der Verfügbarkeit am Ausgangsspieltag und eine verpflichtende Begründung.
4. Nach Bestätigung wird die Vormerkung gespeichert.
5. Der Spieler erhält den Hinweis „Nominierung vorgemerkt“ und wird bei späteren Kaderempfehlungen priorisiert.

Die Aktion darf nicht angeboten werden, wenn der Spieler bereits für den Ausgangsspieltag nominiert ist oder inaktiv ist. Die Verfügbarkeitsbestätigung des Trainers ist Bestandteil des Dialogs.

### 3.2 Vormerkung anzeigen und berücksichtigen

- Offene Vormerkungen gelten mannschaftsbezogen und werden bei späteren Kaderempfehlungen berücksichtigt.
- Vorrang ist ein binäres Sortierkriterium, kein Punktesystem.
- Die bestehende Empfehlung wird nicht automatisch verändert, wenn nachträglich eine Vormerkung erstellt wird. Der Trainer muss die Empfehlung neu berechnen.
- Die Spielerkachel zeigt nur den Statushinweis, nicht die Begründung.
- Die Begründung bleibt für berechtigte Trainer im Detail-/Dialogkontext nachvollziehbar.

### 3.3 Vormerkung erfüllen

- Nur eine tatsächliche Nominierung in `matchday_players` erfüllt eine offene Vormerkung.
- Die Erfüllung speichert den erfüllenden Spieltag und den Erfüllungszeitpunkt.
- Eine bloße Empfehlung oder Auswahl in der Empfehlungsrangliste erfüllt sie nicht.
- Eine bereits erfüllte Vormerkung wird nicht automatisch wieder geöffnet, wenn eine Nominierung später entfernt wird. Eine nachträgliche Korrektur ist nicht Teil v1.

### 3.4 Vormerkung zurücknehmen

- Bei einer offenen Vormerkung bietet das Optionen-Menü die Aktion „Vormerkung zurücknehmen“ an.
- Die Bedienung orientiert sich an der bestehenden Sperrvormerkung.
- Der Trainer muss eine Rücknahmebegründung eingeben.
- Status wechselt auf `cancelled`; die Vormerkung wird nicht mehr priorisiert.
- Rückgenommene Datensätze bleiben als Historie erhalten.
- Für denselben Spieler und dieselbe Mannschaft kann danach wieder eine neue offene Vormerkung angelegt werden.

## 4. Vorgeschlagenes Datenmodell

Neue Tabelle: `matchday_nomination_reminders`.

| Feld | Vorgeschlagener Typ | Zweck |
|---|---|---|
| `id` | UUID PK | Datensatz-ID |
| `team_id` | UUID NOT NULL | Mannschaft |
| `player_id` | UUID NOT NULL | Spieler |
| `source_matchday_id` | UUID NOT NULL | Ausgangsspieltag |
| `reason` | TEXT NOT NULL | Erstellungsbegründung |
| `status` | TEXT NOT NULL | `open`, `fulfilled`, `cancelled` |
| `created_by` | UUID | Erstellender Benutzer |
| `created_at` | TIMESTAMPTZ | Erstellungszeitpunkt |
| `fulfilled_matchday_id` | UUID NULL | Spieltag der Erfüllung |
| `fulfilled_at` | TIMESTAMPTZ NULL | Erfüllungszeitpunkt |
| `cancelled_by` | UUID NULL | Zurücknehmender Benutzer |
| `cancelled_at` | TIMESTAMPTZ NULL | Rücknahmezeitpunkt |
| `cancellation_reason` | TEXT NULL | Begründung der Rücknahme |

Technische Integritätsregeln für die konkrete Migration zu prüfen und auszuarbeiten:

- höchstens eine offene Vormerkung pro Spieler und Mannschaft (partieller Unique Index);
- Spieler, Ausgangsspieltag und Mannschaft müssen konsistent zusammengehören;
- erfüllender Spieltag muss derselben Mannschaft zugeordnet sein;
- Status-/Zeitstempel-Kombinationen durch CHECK-Constraints absichern;
- Fremdschlüssel-Löschverhalten so wählen, dass historische Vormerkungen nicht unbeabsichtigt verloren gehen.

Die Tabelle und Feldnamen sind ein Entwurf, keine ausgeführte Migration.

## 5. Empfehlungssortierung

Die vorhandene Funktion `top16Ranking()` berechnet bereits die Empfehlungsreihenfolge. Die geplante Erweiterung:

1. bestehende Rangfolge unverändert berechnen;
2. offene Vormerkungen der aktuellen Mannschaft laden;
3. Rangfolge stabil in zwei Gruppen aufteilen: offene Vormerkung zuerst, übrige Spieler danach;
4. bestehende Reihenfolge innerhalb beider Gruppen beibehalten;
5. unveränderte Kaderzielgröße anwenden;
6. Sperren-/Eligibility-Prüfungen weiterhin beachten.

Keine zusätzlichen Empfehlungsplätze, keine Gewichtungsparameter und keine Änderung der bestehenden Fairness-/Punkteberechnung.

## 6. UI-Integration

- Bestehendes Spieler-Optionen-Menü in der Spieltagsplanung erweitern.
- Neue Aktionen und Dialogfunktionen mit eigenständigen Namen implementieren; vorhandene `openE05MatchdayAction`-Funktionen sind bereits für Sperraktionen belegt und dürfen nicht überschrieben werden.
- Kachelhinweis „Nominierung vorgemerkt“ ergänzen.
- Begründung nicht auf der Kachel anzeigen.
- Rücknahmeaktion nur für offene Vormerkungen anbieten.
- Bestehende blaue Empfehlungs- und grüne Nominierungsdarstellung erhalten.

## 7. Berechtigungen und Sicherheit

- RLS für die neue Tabelle aktivieren.
- Zugriff auf Teamkontext begrenzen; bestehende Muster `is_team_member(team_id)` und `has_selected_team_context(team_id)` prüfen und passend übernehmen.
- Spieler und Ausgangsspieltag müssen zur gleichen Mannschaft gehören.
- `created_by` / `cancelled_by` dürfen nicht frei durch den Client gesetzt werden.
- Nur berechtigte Mannschaftsmitglieder dürfen lesen/erstellen/zurücknehmen.
- Super-Admin-Zugriff nur im ausdrücklich gewählten Mannschaftskontext.
- Konkrete Rollen- und RLS-Prüfung vor Migration anhand der Live-Definitionen in DEV.

## 8. Erfüllungsmechanismus

Bevorzugt wird eine transaktionssichere Datenbanklösung, die die offene Vormerkung beim tatsächlichen Einfügen einer Nominierung in `matchday_players` erfüllt. Ein Trigger ist dafür ein möglicher Ansatz, muss aber vor Festlegung gegen bestehende Trigger, RPCs, Sperren-Guards und alle Schreibpfade geprüft werden.

Die Erfüllung darf nicht bei bloßer Empfehlung, nicht bei Dialogöffnung und nicht bei bloßer Anzeige des Spielers ausgelöst werden.

## 9. Backup und Restore

Die aktuelle App verwendet Backup-Version 12. Für die neue Tabelle ist eine Erhöhung auf Version 13 vorgesehen:

- Export offener, erfüllter und zurückgenommener Vormerkungen;
- Importvalidierung aller Referenzen und Statuswerte;
- Restore-Reihenfolge nach Spielern und Spieltagen;
- beim Ersetzen von Mannschaftsdaten bestehende Vormerkungen kontrolliert mit löschen;
- Backups Version 5–12 weiterhin unterstützen und fehlendes Feld als leere Liste initialisieren.

## 10. Umsetzungsvorbereitung – technische Bestandsaufnahme

Read-only geprüfter Stand der aktuellen `develop/index.html` und Supabase-DEV-Struktur:

- `top16Ranking()` ist der zentrale Sortierpunkt für die Kaderempfehlung.
- `saveMatchdayRecommendation()` speichert die gekürzte Rangfolge über `save_matchday_recommendation`.
- `renderMatchday()` rendert die Spieltagskacheln und ruft `matchdayPlayerOptionsHtml(player, md)` für das Optionen-Menü auf.
- `matchdayPlayerOptionsHtml()` enthält bereits Sperrausnahme- und Sperrausgleich-Aktionen.
- `openE05MatchdayAction()` / `submitE05MatchdayAction()` gehören zur bestehenden Sperrenfunktion; neue Nominierungsvormerkungsdialoge benötigen separate Funktionsnamen.
- `loadApp()` lädt Spieltage, nominierte Spieler und gespeicherte Empfehlungen.
- `buildBackupSnapshot()` exportiert aktuell `version: 12`; `validateBackup()` akzeptiert Versionen 5–12.
- `replaceTeamDataWithBackup()` löscht und schreibt Spieltagsdaten und muss um Vormerkungen erweitert werden.
- Bestehende Tabellen `matchdays`, `matchday_players`, `matchday_recommendation_runs` und `matchday_recommendation_players` haben RLS und teambezogene Policies.
- In `matchday_players` existiert `available BOOLEAN NOT NULL DEFAULT true`; die aktuelle Frontend-Ladelogik verwendet dieses Feld nicht zur Rückmelde-/Verfügbarkeitsverwaltung. Daher wird die Verfügbarkeit in v1 ausdrücklich vom Trainer im Dialog bestätigt.
- Die bestehenden Empfehlungs- und Nominierungsprüfungen für Sperren dürfen nicht umgangen oder abgeschwächt werden.

**Bestandsaufnahme ist read-only.** Keine SQL-Schreiboperation, keine Schema-/RLS-/RPC-/Triggeränderung und keine Codeänderung wurde für dieses Vorhaben ausgeführt.

## 11. DEV-Umsetzungspakete

1. **Paket A – DB-Konzept finalisieren:** Live-Abhängigkeiten, bestehende Trigger/Schreibpfade, Constraints, RLS, ACL, Integrität, Rollback und Migrationsprotokoll prüfen und spezifizieren.
2. **Paket B – Datenbankmigration:** erst nach separater Freigabe ausführen; neue Tabelle, Constraints, Indizes, Policies und Erfüllungsmechanismus.
3. **Paket C – Frontend:** frische `develop/index.html` holen; Laden, Erstellen, Anzeigen, Rücknehmen und Sortierintegration in DEV.
4. **Paket D – Backup/Restore:** Version 13 und Rückwärtskompatibilität.
5. **Paket E – Tests/Abnahme:** Datenbank-, Rollen-, Konkurrenz-, UI-, Backup- und Regressionstests in DEV.

Keine Ausführung in PROD und keine Änderung an GitHub `main` ohne separate konkrete Freigabe.

## 12. Abnahmetests

1. Erstellen mit leerer Begründung wird verhindert.
2. Erstellen mit Begründung speichert Vormerkung und Ersteller.
3. Bereits nominierte Spieler können nicht vorgemerkt werden.
4. Inaktive Spieler können nicht vorgemerkt werden.
5. Offene Vormerkung erscheint auf der Kachel nur als Statushinweis.
6. Vormerkung priorisiert den Spieler bei der nächsten neu berechneten Empfehlung.
7. Kadergröße bleibt unverändert.
8. Mehr Vormerkungen als Plätze werden innerhalb der Vormerkungsgruppe nach bestehender Rangfolge behandelt.
9. Empfehlung allein erfüllt die Vormerkung nicht.
10. Tatsächliche Nominierung erfüllt die Vormerkung mit Spieltagsreferenz.
11. Nicht nominierte Spieler behalten offene Vormerkung für spätere Spieltage.
12. Rücknahme ohne Begründung wird verhindert.
13. Rücknahme mit Begründung setzt Status `cancelled`; Spieler verliert Vormerkungspriorität.
14. Erfüllte oder zurückgenommene Vormerkung kann nicht erneut zurückgenommen werden.
15. Nach Erfüllung oder Rücknahme kann eine neue offene Vormerkung erstellt werden.
16. Doppelte parallele offene Vormerkungen werden verhindert.
17. Fremde Mannschaften/Spieler sind durch RLS und Integritätsregeln geschützt.
18. Sperrenprüfung und bestehende Nominierungslogik funktionieren unverändert.
19. JSON-Version 13 exportiert und importiert alle Status.
20. Backups Version 5–12 bleiben importierbar.

## 13. Freigabegrenzen und aktueller Status

- Fachliche Entscheidungen: abgestimmt.
- Technische Spezifikation: vorbereitet.
- Nächster Schritt: finale read-only Prüfung der konkreten Datenbank-Schreibpfade, Trigger und RPCs sowie Migrations-/Rollback-Entwurf.
- SQL-Ausführung: **nicht freigegeben**.
- Codeänderung: **nicht freigegeben**.
- Supabase DEV/PROD: unverändert durch dieses Vorhaben.
- GitHub `main`: unverändert.
- Dokumentation: ausschließlich auf `develop`.


## 14. Ergänzende technische Prüfung der DEV-Trigger (17.11.2026)

Read-only ermittelte Trigger auf den relevanten Tabellen:

| Tabelle | Trigger | Zeitpunkt / Ereignis | Bestehende Funktion |
|---|---|---|---|
| `matchday_players` | `matchday_players_cancel_early_reset` | AFTER INSERT oder UPDATE von `matchday_id, player_id` | `e05_cancel_early_reset_on_nomination()` |
| `matchday_players` | `matchday_players_prevent_suspended_nomination` | BEFORE INSERT oder UPDATE von `matchday_id, player_id` | `prevent_suspended_matchday_nomination()` |
| `matchday_players` | `require_active_player_change_matchday` | BEFORE UPDATE von `player_id` | `require_active_player_for_new_assignment()` |
| `matchday_players` | `require_active_player_insert_matchday` | BEFORE INSERT | `require_active_player_for_new_assignment()` |
| `matchdays` | `matchdays_reconcile_early_resets` | AFTER UPDATE von `status` | `e05_reconcile_early_resets_on_matchday_status()` |
| `matchdays` | `matchdays_updated_at` | BEFORE UPDATE | `set_updated_at()` |

Zusätzlich read-only geprüfte Funktionen:

- `save_matchday_recommendation(uuid, uuid[])` ist SECURITY INVOKER, prüft Mannschaftsmitgliedschaft, doppelte/ungültige/inaktive/fremde Spieler und die bestehende Sperrenlogik und speichert anschließend den Empfehlungslauf samt Rangfolge.
- `prevent_suspended_matchday_nomination()` ist SECURITY INVOKER und blockiert eine Nominierung bei einer aktiven Sperre ohne passende Ausnahme.
- `e05_cancel_early_reset_on_nomination()` wird bereits nach einer tatsächlichen Nominierung ausgeführt und gehört zum vorhandenen Sperrausgleichsprozess.

**Konsequenz für die Vorbereitung:** Der neue Erfüllungsmechanismus darf diese bestehenden Trigger nicht ersetzen, deaktivieren oder in ihrer Reihenfolge/Schutzwirkung umgehen. Ein eigener AFTER-Trigger ist technisch denkbar, muss aber in einer isolierten Test-Fixture gegen INSERT, relevante UPDATE-Fälle, bestehende Sperren-Guards, Sperrausgleich und Fehler-Rollback getestet werden. Vor einem Migrationsentwurf sind zusätzlich alle direkten Frontend-Schreibpfade und RPC-Aufrufer für `matchday_players` zu inventarisieren.

**Noch nicht abschließend geklärt:** Verhalten, falls ein Spieler bereits für einen zukünftigen Spieltag nominiert wurde, bevor eine Vormerkung erstellt wird. Der fachliche Kern sagt, dass eine tatsächliche spätere Nominierung erfüllt; die Umsetzung muss diesen zeitlichen Randfall eindeutig behandeln, ohne eine bereits bestehende Nominierung rückwirkend falsch zuzuordnen. Dies ist eine technische Spezifikationsfrage und kein Freibrief für eine Datenänderung.


## 15. Ergänzende Prüfung der Frontend-Schreibpfade (17.11.2026)

In der aktuellen `develop/index.html` wurden folgende direkte Schreibwege auf `matchday_players` gefunden:

- `saveMatchdaySelection()`: direkte DELETE- und INSERT-Operationen beim Ändern der Nominierung.
- Speichern der Teamaufteilung: UPSERT auf `matchday_players` mit `onConflict: 'matchday_id,player_id'`.
- Einsatzstatus: UPDATE auf `played` (Einzelspieler und Sammelaktion).
- Backup-Restore: Löschen bestehender Spieltagsdaten und anschließendes INSERT der Spieltagszuordnungen.

**Konsequenz:** Eine Erfüllungslogik darf nicht nur an einen einzelnen UI-Button gekoppelt werden. Sie muss die tatsächlichen INSERT-/UPSERT-Fälle konsistent abdecken und darf durch ein UPDATE, das nur Teamnummer/Torwart/Einsatzstatus ändert, keine Vormerkung fälschlich erfüllen. Beim Backup-Restore müssen die Reihenfolge und der Umgang mit historischen Reminder-Statuswerten ausdrücklich berücksichtigt werden.

Die Kaderempfehlung wird in `saveMatchdayRecommendation()` vor dem Aufruf der bestehenden RPC mit `top16Ranking()` berechnet und auf die Kaderzielgröße gekürzt. Die Vorrangsortierung muss deshalb vor dieser Kürzung erfolgen. Die RPC `save_matchday_recommendation` bleibt für Berechtigungs-, Mannschafts-, Aktivitäts- und Sperrenvalidierung zuständig; sie soll nicht durch eine Frontendänderung umgangen werden.

## 16. Backlog-/Epic-Zuordnung

Der aktuelle Projektkontext verwendet **E05 bereits für Sperren und Verhaltensereignisse**. Um doppelte Epic-IDs und widersprüchliche Dokumentation zu vermeiden, wurde dieses Vorhaben zunächst unter dem neutralen Dokumenttitel „Nominierungsvormerkung“ dokumentiert. Eine neue Epic-/Feature-ID wird erst vergeben, wenn der bestehende Backlog-Eintrag und die gewünschte eigenständige Einordnung abschließend abgeglichen wurden.
