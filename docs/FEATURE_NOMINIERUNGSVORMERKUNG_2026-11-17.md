# Feature-Spezifikation – Nominierung für einen kommenden Spieltag vormerken

**Stand:** 17.11.2026  
**Backlog-Zuordnung:** Themenbereich „Kaderplanung“ → Epic 23 „Nominierung vormerken“
**Status:** Fachlich abgestimmt – technische Vorbereitung, keine Umsetzung  
**Zielbranch:** `develop`  
**Zielumgebung:** Supabase DEV  
**PROD:** unverändert

> **Backlog-Regel:** Dieses Vorhaben wird als eigenständiges Epic 23 „Nominierung vormerken“ im Themenbereich „Kaderplanung“ geführt. Das bestehende E05 „Kaderempfehlung“ bleibt unverändert und wird nicht wieder geöffnet. Die Backlog-Struktur lautet: Themenbereich → Epic → Anforderung/Feature → Arbeitspaket. Abgeschlossene Epics werden nicht wieder geöffnet.

## 1. Ziel

Trainer können einen Spieler, der bei einem Spieltag verfügbar, aber nicht nominiert war, manuell für eine spätere Nominierung vormerken. Die Vormerkung beeinflusst die Kaderempfehlung der Mannschaft, ersetzt aber niemals die Entscheidung und Nominierung durch den Trainer.

## 2. Fachliche Entscheidungen

| Thema | Verbindliche Entscheidung |
|---|---|
| Auslöser | Trainer wählt beim Spieler im Optionen-Menü „Nominierung vormerken“. Das ist auch möglich, wenn der Spieler zunächst für den Ausgangsspieltag nominiert war. |
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

1. Trainer öffnet beim Spieler das Optionen-Menü.
2. Aktion „Nominierung vormerken“ wird angeboten.
3. Dialog fordert die Bestätigung der Verfügbarkeit am Ausgangsspieltag und eine verpflichtende Begründung.
4. Nach Bestätigung werden Vormerkung und gegebenenfalls Abwahl aus der aktuellen Nominierung atomar gespeichert.
5. Der Spieler erhält den Hinweis „Nominierung vorgemerkt“ und wird bei späteren Kaderempfehlungen priorisiert.

Die Aktion darf nicht für inaktive Spieler angeboten werden. Ist der Spieler auf dem Ausgangsspieltag aktuell nominiert, wird er beim erfolgreichen Anlegen der Vormerkung automatisch aus dieser Nominierung entfernt. Die Vormerkungserstellung und Abwahl müssen in einer einzigen Datenbanktransaktion erfolgen. Bei einem Fehler darf weder die Nominierung entfernt noch eine Vormerkung angelegt werden. Die Verfügbarkeitsbestätigung des Trainers ist Bestandteil des Dialogs.

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

Verbindliche Zuordnung:
- Themenbereich: **Kaderplanung**
- Epic: **E23 – Nominierung vormerken**
- Das Vorhaben ist ein eigenständiges Epic und kein Unterpunkt des bestehenden E05.
- Das bestehende E05 „Kaderempfehlung“ bleibt unverändert und wird nicht wieder geöffnet.
- Backlog-Struktur: Themenbereich → Epic → Anforderung/Feature → Arbeitspaket.
- Abgeschlossene Epics werden nicht wieder geöffnet.

Die technische Spezifikation bleibt unter ihrem bestehenden Dateinamen erhalten; die Backlog-Zuordnung ist verbindlich ergänzt.


## 17. Technisches Zielbild nach vertiefter DEV-Prüfung (17.11.2026)

### 17.1 Tatsächliche Team-/Rollenprüfung

Die aktuelle DEV-Definition von `is_team_member(uuid)` erlaubt:
- reguläre Teammitglieder mit Eintrag in `team_member_roles` (Rollen `trainer` oder `admin`);
- globale Super-Admins nur mit ausdrücklich ausgewähltem Mannschaftskontext.

`has_selected_team_context(uuid)` kann außerdem einen Club-Admin mit passendem ausgewähltem Teamkontext erkennen. Bestehende Tabellen verwenden deshalb getrennte SELECT-Kontext-Policies und Schreib-Policies. Für die Vormerkung wird dieses Muster übernommen:
- SELECT: reguläre Teammitglieder sowie berechtigter, ausgewählter Lese-Kontext;
- CREATE/CANCEL: `is_team_member(team_id)`, damit Trainer/Mannschaftsadmin und Super-Admin im ausgewählten Teamkontext schreiben können;
- Club-Admin ohne Teammitgliedschaft bleibt schreibgeschützt;
- kein Zugriff auf andere Mannschaften.

Die Rollenprüfung erfolgt serverseitig; UI-Ausblendung ist nur Bedienkomfort und keine Sicherheitsgrenze.

### 17.2 Tabellenintegrität

Vorgesehene Constraints/Indizes:
- Primärschlüssel `id`;
- `team_id` NOT NULL;
- `player_id` und `source_matchday_id` NOT NULL im aktiven Datensatz;
- Status-CHECK nur `open`, `fulfilled`, `cancelled`;
- Statusabhängiger CHECK: `open` ohne Abschlussfelder; `fulfilled` mit `fulfilled_matchday_id` und `fulfilled_at`, ohne Rücknahmefelder; `cancelled` mit `cancelled_at`, `cancelled_by`, `cancellation_reason`, ohne Erfüllungsfelder;
- partieller Unique Index auf `(team_id, player_id) WHERE status = 'open'`;
- Index für offene Vormerkungen nach `(team_id, player_id)`;
- FKs auf Team, Spieler, Ausgangsspieltag und erfüllenden Spieltag.

**Integritätsprüfung:** Die bestehenden Tabellen haben jeweils nur einfache Primärschlüssel. Die Gleichheit von `team_id` in Reminder, Spieler, Ausgangsspieltag und Erfüllungsspieltag kann daher nicht allein durch einfache Fremdschlüssel garantiert werden. Ein serverseitiger Validierungstrigger muss diese Beziehungen bei Erstellung und Statuswechsel prüfen. Eine zusätzliche zusammengesetzte FK-Struktur wäre möglich, würde aber neue Unique Constraints auf Bestandstabellen voraussetzen und ist für v1 unnötig invasiv.

### 17.3 Serverseitige Schreibpfade

Vorgeschlagen sind zwei schmale SECURITY INVOKER-RPCs:
- `create_matchday_nomination_reminder(p_source_matchday_id, p_player_id, p_reason)`;
- `cancel_matchday_nomination_reminder(p_reminder_id, p_reason)`.

Sie verwenden `auth.uid()`, prüfen `is_team_member(team_id)`, validieren Team-/Spieler-/Ausgangsspieltag-Zuordnung und schreiben Actor-/Zeitstempel serverseitig. Die Clients dürfen diese Auditfelder nicht selbst bestimmen.

Die Tabelle erhält RLS. Direkte INSERT-/UPDATE-Rechte für `authenticated` sollen nicht zusätzlich breit vergeben werden; die RPCs bilden die kontrollierte Schreibschnittstelle. SELECT erfolgt direkt über die RLS-Policy. Der automatische Erfüllungstrigger ist ein separater, minimaler SECURITY DEFINER-Trigger mit festem `search_path`, ohne öffentlich ausführbare RPC-Oberfläche.

### 17.4 Konkurrenzsicherheit und automatische Erfüllung

Die vorhandene Sperrenprüfung verwendet einen spielerbezogenen Advisory Transaction Lock auf Basis von `hashtextextended(player_id::text, 0)`. Für Erstellen einer Vormerkung und Einfügen einer Nominierung soll derselbe Lock-Schlüssel verwendet werden. Dadurch werden die beiden konkurrierenden Abläufe serialisiert:

- Vormerkung zuerst: spätere Nominierung sieht die offene Vormerkung und erfüllt sie.
- Nominierung zuerst: Erstellung prüft den bereits vorhandenen späteren Spieltag und kann eine nicht mehr sinnvolle Vormerkung ablehnen.
- Parallele doppelte Vormerkungen: zusätzlich schützt der partielle Unique Index.

Der automatische Erfüllungstrigger soll auf `matchday_players` nach INSERT sowie nach tatsächlicher Änderung von `matchday_id/player_id` laufen. Er erfüllt nur eine offene Vormerkung desselben Spielers und Teams, wenn der nominierte Spieltag nach dem Ausgangsspieltag liegt. Reine Änderungen von `team_number`, `goalkeeper` oder `played` lösen keine Erfüllung aus.

Die vorhandenen Trigger `matchday_players_prevent_suspended_nomination` und `matchday_players_cancel_early_reset` bleiben unverändert. Der neue Trigger muss innerhalb derselben Transaktion laufen: schlägt die Erfüllung fehl, wird auch die Nominierung zurückgerollt. Das ist absichtlich sicherer als eine erfolgreiche Nominierung mit inkonsistent offenem Reminder.

### 17.5 Zeitliche Randfälle

- Eine Vormerkung wird ausschließlich durch eine Nominierung erfüllt, die nach ihrer Erstellung als Datenbankereignis eintritt und zu einem späteren Matchdatum als dem Ausgangsspieltag gehört.
- Eine bereits vorher gespeicherte Nominierung desselben Ausgangsspieltags ist kein Hindernis: Der Spieler kann zunächst nominiert und anschließend zugunsten eines anderen Spielers abgewählt werden. Sobald er auf dem Ausgangsspieltag nicht mehr nominiert ist, darf der Trainer für ihn eine Vormerkung anlegen.
- Eine bereits vorher gespeicherte Nominierung eines anderen, späteren Spieltags wird nicht rückwirkend als Erfüllungsereignis behandelt. Ob sie die Anlage einer zusätzlichen Vormerkung blockiert, ist ein davon getrennter, noch offener Randfall.
- Nach erfolgreicher Erfüllung bleibt der Status `fulfilled`, auch wenn die Nominierung später entfernt wird. Die Erfüllung ist ein historisches Ereignis und wird nicht automatisch zurückgenommen.
- Ein späterer Spieltag wird über `match_date > source_match_date` bestimmt. Gleiches Kalenderdatum mit unterschiedlicher Anstoßzeit wird in v1 nicht als „später“ interpretiert, da die Datenbank nur Datum und optionale lokale Anstoßzeit führt und kein verlässlicher Zeitstempel der Nominierungsaktion gespeichert wird.

### 17.6 Löschverhalten und Historie

Die aktuelle App löscht Spieler im Trainer-/Admin-Workflow nicht physisch, sondern setzt `players.active=false`. Die UI-Aktion heißt „Aus aktivem Kader entfernen“ und bestätigt ausdrücklich, dass Spieler und bisherige Trainings-/Spieltagsdaten erhalten bleiben. Die Wiederaufnahme erfolgt über `active=true`.

Daraus folgt für v1:
- `player_id` bleibt NOT NULL und erhält einen FK mit `ON DELETE RESTRICT`; eine spätere physische Löschung darf die Reminder-Historie nicht unbemerkt entfernen.
- `source_matchday_id` und `fulfilled_matchday_id` erhalten ebenfalls `ON DELETE RESTRICT`, damit keine Historienreferenz stillschweigend verloren geht.
- `team_id` kann wie bei den übrigen Teamdaten mit `ON DELETE CASCADE` entfernt werden, wenn eine Mannschaft bewusst gelöscht wird.
- Beim kontrollierten Backup-Restore werden Reminder der Mannschaft explizit gesichert und entfernt, bevor die Elternobjekte gelöscht werden; nach Wiederherstellung der Original-IDs werden sie wieder eingespielt.

Damit sind keine zusätzlichen Namens-/Datums-Snapshots nötig. Die FK-Schutzregeln bewahren die Historie, während die bestehende Soft-Deaktivierung den Spieler erhält. Physische Löschungen sind kein normaler UI-Ablauf.

### 17.7 Backup-/Restore-Auswirkung

Der Restore löscht vorhandene Matchdays und Players, bevor er sie neu einfügt. Deshalb muss die Reihenfolge angepasst werden:
1. Reminder-Datensätze der betroffenen Mannschaft in die Backup-Nutzlast aufnehmen;
2. beim Restore Reminder der betroffenen Mannschaft vor den Elternobjekten entfernen;
3. Spieler und Spieltage mit den Original-IDs wiederherstellen;
4. Nominierungen und Empfehlungsläufe wiederherstellen;
5. Reminder mit den Original-IDs und ihren historischen Statuswerten wieder einfügen;
6. Referenzen und Statuswerte validieren.

Backup-Version 13 bleibt vorgesehen. Der Restore muss außerdem verhindern, dass das Wiedereinfügen historischer Nominierungszeilen den Erfüllungstrigger wie eine neue Nominierung behandelt. Eine pauschale Trigger-Deaktivierung ist ausgeschlossen; vorzusehen ist ein eng begrenzter, nur für den kontrollierten Restore verfügbarer Mechanismus oder eine Restore-Reihenfolge, bei der die Triggersemantik korrekt bleibt.

## 18. Noch offene technische Festlegungen vor finalem SQL-Entwurf

1. **Kurzfristiger Austausch innerhalb des Ausgangsspieltags:** Wird Spieler A zunächst nominiert und anschließend zugunsten von B ersetzt, kann der Trainer direkt bei A „Nominierung vormerken“ wählen. Beim Speichern wird A atomar aus der aktuellen Nominierung entfernt und die Vormerkung angelegt. Ein separater vorheriger Abwahlschritt ist nicht erforderlich.
2. **Bereits bestehende Nominierung auf einem anderen zukünftigen Spieltag:** Sie wird nicht rückwirkend als Erfüllung gewertet. Ob sie eine neue Vormerkung blockiert, ist noch gesondert festzulegen.
3. **UI-Historie:** fachlich ist Historienerhalt beschlossen; für v1 empfehle ich, erfüllte/zurückgenommene Vormerkungen im Spieler-Optionen-/Detaildialog sichtbar zu machen, ohne eine neue globale Übersicht einzuführen.

Die Lösch-/Historienfrage ist durch die aktuelle Soft-Deaktivierung der Spieler geklärt: physische Löschungen werden durch FK-RESTRICT gegen unbeabsichtigten Historienverlust geschützt; Teamlöschung bleibt kaskadierend.

## 19. Prüfung der tatsächlichen Lösch- und Restore-Abläufe (17.11.2026)

### 19.1 Spieler- und Spieltagslöschung

Der aktuelle Backup-Restore löscht vor dem Wiederaufbau:
- vorhandene Spieltagsanwesenheit,
- Empfehlungsläufe (deren Empfehlungsspieler über bestehende FK-Beziehungen mit entfernt werden),
- `matchday_players`,
- Matchday-Trainer,
- anschließend die Spieltage,
- anschließend die Spieler.

Die vorhandenen Fremdschlüssel von `matchday_players` zu `matchdays` und `players` verwenden `ON DELETE CASCADE`. Auch `players.team_id` und `matchdays.team_id` kaskadieren bei Mannschaftslöschung.

Ein allgemeines Spieler-/Spieltags-Löschmenü konnte in der aktuellen Datei mit den gezielten Suchbegriffen nicht als eigener Frontend-DELETE-Pfad nachgewiesen werden; die sichtbaren direkten Löschungen im geprüften Ausschnitt betreffen insbesondere den Backup-Restore. Die Datenbank-FK-Kaskaden sind dagegen eindeutig bestätigt.

### 19.2 Konsequenz für Reminder-Historie

Die tatsächliche Spieleraktion ist eine Soft-Deaktivierung über `dbUpdate('players', {id}, {active:false})`; es gibt in diesem Workflow keine physische Spieler-DELETE-Operation. Die UI bestätigt, dass historische Trainings- und Spieltagsdaten erhalten bleiben. Ein zusätzlicher Namens-Snapshot ist daher nicht erforderlich.

**Technische Empfehlung für v1:**
- FK `player_id ON DELETE RESTRICT`;
- FK `source_matchday_id ON DELETE RESTRICT`;
- FK `fulfilled_matchday_id ON DELETE RESTRICT`;
- FK `team_id ON DELETE CASCADE`, analog zur bewussten Löschung einer Mannschaft;
- Reminder vor dem kontrollierten Backup-Restore explizit sichern und löschen, anschließend mit den wiederhergestellten Original-IDs zurückschreiben.

Damit bleiben Historienreferenzen geschützt, ohne zusätzliche personenbezogene Snapshotfelder einzuführen.

### 19.3 Backup-/Restore

Der Restore muss die Reminder-Daten vor dem Löschen der bestehenden Matchdays/Players auslesen und in der Backup-Nutzlast halten. Danach werden die Reminder der betroffenen Mannschaft explizit gelöscht, bevor die FK-RESTRICT-geschützten Elternobjekte gelöscht werden. Nach dem Wiederaufbau der Spieler, Spieltage und Nominierungen werden Reminder mit den Original-IDs wiederhergestellt.

Das Backup exportiert IDs, Status, Erstellungs-/Erfüllungs-/Rücknahmedaten und Begründungen. Snapshotfelder sind nach der korrigierten Löschstrategie nicht erforderlich. Der Restore darf keine Erfüllungstrigger auslösen, nur weil historische `matchday_players`-Zeilen wiederhergestellt werden. Der Erfüllungstrigger muss deshalb einen kontrollierten Restore-Kontext erkennen oder die Wiederherstellung der Reminder muss so erfolgen, dass bereits gespeicherte historische Nominierungen nicht als neue Erfüllungsereignisse behandelt werden. Eine pauschale Trigger-Deaktivierung ist ausgeschlossen.

## 20. Technische Risiken und geplante Gegenmaßnahmen

| Risiko | Gegenmaßnahme |
|---|---|
| Gleichzeitige Vormerkung und Nominierung | gemeinsamer spielerbezogener Advisory Lock, partielle Unique-Regel und Transaktion |
| Spieler/Spieltag aus anderer Mannschaft | serverseitige Validierung und RLS |
| Super-Admin ohne gewählten Teamkontext | Schreibprüfung über `is_team_member(team_id)` |
| Club-Admin soll nicht nominieren/vormerken | getrennte Lese- und Schreibregeln |
| Sperren-Trigger wird umgangen | bestehende Trigger unverändert; neuer Trigger nur ergänzend |
| Änderung nur an Teamnummer/Torwart/Einsatzstatus | Erfüllung nur bei INSERT oder tatsächlicher Änderung von Matchday/Player |
| Backup-Restore löst falsche Erfüllung aus | kontrollierter Restorepfad, Tests mit historischen Reminder-Status |
| Spieler-/Spieltagslöschung verliert Historie | FK-RESTRICT; Spieler werden regulär soft-deaktiviert; kontrollierter Backup-Restore löscht Reminder explizit vor Elternobjekten |
| Frühere spätere Nominierung wird rückwirkend gezählt | Create-RPC prüft bereits existierende spätere Nominierungen und lehnt Anlage ab |
| Erfüllungstrigger schlägt fehl | gesamte Nominierungstransaktion wird zurückgerollt; sichtbare Fehlermeldung |

## 21. Vorläufige Paket- und Freigabeplanung

1. **Technisches Konzept final:** Tabellen-/RLS-/RPC-/Trigger-Definitionen einschließlich ACL und FK-Verhalten festlegen.
2. **SQL-Paket erstellen:** erst nach ausdrücklicher Freigabe zur Erstellung der versionierten Migration und des guarded Rollbacks. Die aktuelle Projektregel verlangt, dass vollständiges SQL und Zielumgebung vor einer Ausführung vorgelegt werden.
3. **Isolierte Datenbanktests:** Migration und Rollback in einer lokalen/isolierten PostgreSQL-Fixture prüfen; keine Verbindung zu Supabase DEV/PROD.
4. **DEV-Ausführung:** nur nach gesonderter Freigabe mit vollständigem SQL und konkreter Zielumgebung.
5. **DEV-Frontend:** frische `develop/index.html` verwenden und getrennt umsetzen; keine PROD- oder `main`-Änderung.
6. **Backup/Restore und Regression:** separat testen und dokumentieren.
7. **PROD:** nicht Bestandteil dieser Vorbereitung; erfordert eigenes Releasepaket und eigene ausdrückliche Freigabe.

**Aktueller Status nach dieser Prüfung:** Die RLS-/Rollenmuster, FK-Kaskaden und Restore-Reihenfolge sind konkret erfasst. Die Vormerkung eines zunächst nominierten Spielers mit atomarer Abwahl aus dem Ausgangsspieltag ist als verbindlicher Ablauf ergänzt. Offen bleibt der getrennte Randfall einer bereits bestehenden Nominierung auf einem anderen zukünftigen Spieltag sowie die gewünschte Sichtbarkeit der Historie. Eine versionierte Migration wird erst nach separater ausdrücklicher Beauftragung erstellt; SQL-Ausführung bleibt gesondert freigabepflichtig.


## 22. Umsetzungsvorbereitung – konkrete Transaktions- und Frontendintegration (17.11.2026)

### 22.1 Epic-Zuordnung und zentrale Projektübersicht

- Die Zuordnung zu **Epic 23 „Nominierung vormerken“** ist in dieser Spezifikation verbindlich dokumentiert.
- Epic 23 wurde zusätzlich in `PROJECT_CONTEXT.md` als aktuelles Vorhaben ergänzt und im Repository-`README.md` verlinkt.
- Im aktuellen Repository-Baum wurde keine eigenständige zentrale Backlog-Datei gefunden. Bis eine solche Datei eingeführt wird, ist `PROJECT_CONTEXT.md` die zentrale Projektübersicht; diese Spezifikation enthält die fachlichen und technischen Details.
- Das bestehende E05 wird nicht umbenannt, erweitert oder wieder geöffnet.

### 22.2 Aktueller Frontend-Schreibpfad

Die aktuelle Funktion `saveMatchdaySelection()` arbeitet in zwei getrennten Requests:
1. Entfernen nicht mehr ausgewählter Spieler aus `matchday_players`;
2. Einfügen neu ausgewählter Spieler in `matchday_players`.

Die Funktion aktualisiert anschließend `md.selected` und `md.playerRows`. Beim Entfernen wird derzeit kein zusätzlicher Datensatz in `matchday_attendance` gelöscht. Es wurde außerdem read-only kein Fremdschlüssel gefunden, der eine andere Tabelle auf `matchday_players` referenziert.

**Konsequenz:** Die neue Vormerkungsaktion darf nicht zuerst die bestehende Frontend-Funktion zum Abwählen aufrufen und danach separat eine Vormerkung speichern. Das wären zwei getrennte Requests und könnten bei einem Fehler einen inkonsistenten Zustand hinterlassen.

### 22.3 Vorgesehene atomare Create-RPC

Die Create-RPC wird als einzige Schreibschnittstelle für diesen Vorgang vorgesehen:

`create_matchday_nomination_reminder(p_source_matchday_id, p_player_id, p_reason)`

Vorgesehene Reihenfolge innerhalb einer Datenbanktransaktion:

1. `auth.uid()` ermitteln und Team-/Rollenberechtigung prüfen.
2. Spielerbezogenen Advisory Transaction Lock verwenden.
3. Ausgangsspieltag und Spieler laden und prüfen, dass beide zur gleichen Mannschaft gehören und der Spieler aktiv ist.
4. Prüfen, dass noch keine offene Vormerkung für Spieler und Mannschaft existiert.
5. Prüfen, dass der Spieler am Ausgangsspieltag aktuell nominiert ist oder nicht; beide Fälle sind zulässig.
6. Offene Vormerkung mit Pflichtbegründung, `created_by` und `created_at` anlegen.
7. Falls der Spieler auf genau diesem Ausgangsspieltag aktuell in `matchday_players` steht, diese Nominierung innerhalb derselben Transaktion entfernen.
8. Erfolgreich zurückkehren; bei jedem Fehler wird die gesamte Transaktion einschließlich möglicher Abwahl zurückgerollt.

Damit ist der fachliche Ablauf „A war zunächst nominiert, wird kurzfristig durch B ersetzt und für den nächsten Spieltag vorgemerkt“ mit einem einzigen atomaren Vorgang abgedeckt. Die Vormerkung darf auch angelegt werden, wenn A bereits vor dem Dialog aus der aktuellen Nominierung entfernt wurde.

Die Create-RPC darf keine Nominierung auf einem anderen Spieltag entfernen. Das betrifft ausschließlich den als Ausgangsspieltag übergebenen Spieltag.

### 22.4 Empfehlungs- und UI-Aktualisierung

Nach erfolgreichem RPC-Aufruf muss die Frontendansicht:
- den Spieler aus `md.selected` und `md.playerRows` des Ausgangsspieltags entfernen, sofern er dort zuvor nominiert war;
- die offene Vormerkung in den lokalen Zustand übernehmen oder die betroffenen Daten neu laden;
- den Hinweis „Nominierung vorgemerkt“ anzeigen;
- die gespeicherte Kaderempfehlung als möglicherweise veraltet behandeln und dem Trainer eine Neuberechnung ermöglichen.

Die gespeicherte Empfehlung wird durch das Erstellen einer Vormerkung nicht stillschweigend verändert. Die Vorrangsortierung wird erst bei der nächsten Neuberechnung wirksam.

### 22.5 Erfüllungstrigger – Abgrenzung

- Die Abwahl aus dem Ausgangsspieltag ist ein DELETE und darf keine Erfüllung auslösen.
- Das spätere Einfügen des Spielers in einen anderen Spieltag kann die offene Vormerkung erfüllen.
- UPDATEs ausschließlich an `team_number`, `goalkeeper` oder `played` dürfen keine Erfüllung auslösen.
- Ein UPSERT ist anhand des tatsächlichen INSERT-/UPDATE-Ergebnisses zu behandeln; eine Konfliktaktualisierung vorhandener Team-/Einsatzfelder ist kein neues Nominierungsereignis.
- Bestehende Sperren- und Sperrausgleichstrigger bleiben unverändert.

### 22.6 Noch nicht final festgelegter Randfall

Wenn der Spieler zum Zeitpunkt der Vormerkung bereits auf einem anderen zukünftigen Spieltag nominiert ist, wird diese bestehende Nominierung weder entfernt noch rückwirkend als Erfüllung behandelt. Das Verhalten der neuen Vormerkung in diesem Sonderfall bleibt vor dem finalen SQL-Entwurf gesondert zu entscheiden. Der typische kurzfristige Austausch innerhalb des Ausgangsspieltags ist davon ausdrücklich nicht betroffen.

### 22.7 Read-only Datenbankbefund

- Die Prüfung der Fremdschlüssel, die auf `matchday_players` verweisen, ergab keine referenzierenden Tabellen.
- `matchday_attendance` ist eine eigenständige Tabelle mit `matchday_id`, `player_id`, `present` und `updated_at`; es wurde keine FK-Abhängigkeit auf `matchday_players` gefunden.
- Der vorhandene Auswahl-Speicherpfad löscht `matchday_players`-Zeilen, ohne `matchday_attendance` zu löschen. Die neue atomare Vormerkungsaktion soll dieses bestehende Verhalten nicht eigenmächtig ändern.
- Alle Befunde stammen aus read-only Abfragen und der aktuellen Datei `develop/index.html`.

**Freigabegrenze:** Dieses Zielbild ist eine technische Vorbereitung. Es wurde keine Migration-Datei erstellt, kein SQL ausgeführt und keine Frontenddatei verändert.


## 22. Ergänzende technische Vorbereitung – atomare Abwahl des Ausgangskaders (17.11.2026)

### 22.1 Bestehender Frontend-Schreibweg

Die aktuelle Funktion `saveMatchdaySelection()` führt Änderungen in zwei getrennten direkten Supabase-Aufrufen aus:
1. DELETE nicht mehr ausgewählter Zeilen aus `matchday_players`;
2. INSERT neu ausgewählter Zeilen.

Die Funktion aktualisiert danach `md.selected` und `md.playerRows` lokal. Dieser bestehende Weg kann nicht für „Vormerkung erstellen und gleichzeitig Spieler A abwählen“ wiederverwendet werden, weil dadurch zwei getrennte Transaktionen entstünden.

### 22.2 Vorgeschlagener atomarer RPC-Ablauf

Die Aktion „Nominierung vormerken“ soll eine eigene serverseitige RPC verwenden, z. B. `create_matchday_nomination_reminder(p_source_matchday_id, p_player_id, p_reason)`. Innerhalb einer einzigen Datenbanktransaktion:

1. Authentifizierung und Rolle/Teamkontext prüfen.
2. Spieler- und Matchday-Kontext mit Row Locks laden; zusätzlich den bestehenden spielerbezogenen Advisory Lock verwenden.
3. Sicherstellen, dass Spieler aktiv ist und zum Team des Ausgangsspieltags gehört.
4. Sicherstellen, dass der Ausgangsspieltag noch `planned` ist und nicht in der Vergangenheit liegt.
5. Prüfen, ob bereits eine offene Vormerkung für Spieler und Team existiert.
6. Falls eine Nominierungszeile für genau den Ausgangsspieltag existiert:
   - `played=true` führt zum Abbruch der gesamten Aktion;
   - andernfalls wird die vollständige Zeile als JSONB-Snapshot gesichert und anschließend entfernt.
7. Vormerkung mit Pflichtbegründung, Actor und Zeitstempel anlegen; Snapshot der entfernten Ausgangsnominierung mit der Vormerkung verknüpfen.
8. Transaktion committen.

Schlägt ein Schritt fehl, werden sowohl die Nominierungsentfernung als auch die Vormerkung zurückgerollt. Ein separater Frontend-DELETE vor dem RPC-Aufruf ist ausdrücklich ausgeschlossen.

### 22.3 Schutz der tatsächlichen Einsätze und Historie

Die bestehende E05-Ausnahme-Widerrufs-RPC ist ein technisches Muster für atomare Nominierungsentfernung: sie verwendet den spielerbezogenen Advisory Lock, prüft `played=true`, entfernt nur die noch nicht als Einsatz markierte Nominierung und hält einen vollständigen JSONB-Snapshot im Audit fest. Epic 23 soll dieses Muster wiederverwenden, ohne bestehende E05-Funktionen zu verändern oder deren fachliche Sperrenlogik zu übernehmen.

Für Epic 23 wird empfohlen:
- Ausgangsspieltag muss `status='planned'` und `match_date >= current_date` haben;
- ein vorhandener Datensatz mit `played=true` darf nie automatisch entfernt werden;
- ein vorhandener Datensatz mit `played=false` oder `played IS NULL` kann entfernt werden;
- Snapshot der entfernten Nominierungszeile (mindestens `matchday_id, player_id, team_number, goalkeeper, played`) wird unveränderlich gespeichert;
- bei fehlender Nominierungszeile wird trotzdem eine Vormerkung angelegt, sofern der Trainer die Verfügbarkeit bestätigt;
- der Snapshot wird nicht als aktuelle Nominierung wiederhergestellt, wenn die Vormerkung später erfüllt oder zurückgenommen wird.

### 22.4 Frontend-Nachladen nach erfolgreichem RPC-Aufruf

Nach erfolgreichem RPC-Aufruf soll die Anwendung die betroffene Spieltagsauswahl und Reminder-Daten aus der Datenbank neu laden oder die lokalen Strukturen vollständig und konsistent aktualisieren. Ein reines Entfernen aus `md.selected` ohne Neuladen der tatsächlichen Daten ist nicht ausreichend. Bei RPC-Fehler bleibt der vorherige Frontendzustand unverändert und zeigt die Serverfehlermeldung an.

### 22.5 Zusätzliche Testfälle

- A ist auf dem Ausgangsspieltag nominiert, `played=false`: Vormerkung wird angelegt, A wird atomar abgewählt und Snapshot bleibt erhalten.
- A ist auf dem Ausgangsspieltag nominiert, `played IS NULL`: gleiches erwartetes Ergebnis.
- A ist auf dem Ausgangsspieltag mit `played=true` markiert: gesamter Vorgang wird abgelehnt; Nominierung bleibt bestehen; keine Vormerkung entsteht.
- Ausgangsspieltag ist nicht mehr `planned` oder liegt in der Vergangenheit: Vorgang wird abgelehnt.
- Fehler beim Insert der Vormerkung nach vorgesehener Abwahl: Transaktion rollt zurück; A bleibt nominiert.
- Doppelklick/parallel ausgelöste Erstellung: höchstens eine offene Vormerkung; keine doppelte Nominierungsentfernung.
- Nach erfolgreicher Aktion zeigt die UI A nicht mehr als nominiert, aber mit Status „Nominierung vorgemerkt“.
- Bei Rücknahme der Vormerkung wird A nicht automatisch wieder in den Ausgangskader aufgenommen; eine erneute Nominierung bleibt eine bewusste Trainerentscheidung.

**Hinweis:** Der JSONB-Snapshot und die konkrete RPC-Signatur sind technische Vorschläge für den späteren SQL-Entwurf, keine ausgeführte oder freigegebene Datenbankänderung.
