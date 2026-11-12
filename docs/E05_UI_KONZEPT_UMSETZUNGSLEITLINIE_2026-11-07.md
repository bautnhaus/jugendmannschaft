# E05 – Konsolidiertes UI-Konzept und technische Umsetzungsleitlinie

**Stand:** 07.11.2026  
**Branch:** `develop`  
**Status:** UI-Konzept konsolidiert; technische Bestandsaufnahme begonnen; noch keine Code- oder Datenbankänderung  
**Grundsatz:** Bestehende Seiten und Komponenten gezielt erweitern. Keine Trainings-, Spieler- oder Spieltagsseiten neu nachbauen.

## 1. Ziel

Die in AP05.2 und AP05.3 abgestimmten Karten-, Sterne-, Sperren- und Kaderfunktionen werden in die vorhandene KADAssist-Oberfläche integriert. Das vorhandene mobile Layout, die Navigationsstruktur, die bestehenden Listen-/Kachelkomponenten, Such- und Filtermuster sowie die Darkmode-Regeln bleiben die Basis.

Dieses Dokument bündelt die ergänzenden UI-Entscheidungen aus der gemeinsamen Konzeptabstimmung. Bei fachlichen Regeln haben AP05.2 und AP05.3 Vorrang.

## 2. Verbindliche UI-Leitplanken

- iPhone-first und sportartneutral.
- Vorhandene Seiten, Komponenten, Styles und Interaktionsmuster weiterverwenden.
- Bestehende Datensätze und Abläufe nicht ohne fachlichen Grund verändern.
- Keine parallelen Ersatzseiten, keine zweite Spielerliste und keine alternative Spieltagsplanung.
- Neue UI-Elemente werden in die bestehenden Render-/State-Flows integriert.
- Suche und Filter folgen dem vorhandenen Muster: **Tabs → Suche → Filterchips → Liste**.
- Chips für Ereignistypen kompakt halten, damit mehrere Ereignisse auf einer Spielerkachel Platz finden.
- Eine Warnung wird nicht als zusätzlicher Chip dargestellt.
- Farben und Symbole müssen im hellen und dunklen Design verständlich bleiben.

## 3. Trainingsdetail: vier Bereiche

Die vorhandene Trainingsdetailansicht erhält einen vierten Tab. Die Reihenfolge lautet:

1. **Rückmeldungen**
2. **Anwesenheit**
3. **Teams**
4. **Ereignisse**

Die ersten drei Bereiche behalten ihre bisherige Funktion und Darstellung. Der neue Bereich wird in dieselbe bestehende Tab-/Detailstruktur integriert.

### 3.1 Ereignisse – Spielerliste

- Es werden **nur anwesende Spieler** angezeigt.
- Die Liste nutzt die vorhandene Trainings-Spielerzeile mit Avatar, Name und vorhandenen Spielermetadaten.
- Pro Spieler gibt es eine kompakte Aktion zum Erfassen eines Ereignisses.
- Die Aktion bietet gelbe Karte, rote Karte oder positiven Stern.
- Bereits vergebene Ereignistypen werden sichtbar gemacht und für denselben Spieler/dasselbe Training nicht erneut als neue Aktion angeboten.
- Gelbe und rote Karten benötigen eine Begründung; beim positiven Stern ist diese optional.
- Die Vergabe bleibt freiwillig. Es gibt weder eine verpflichtende Trainingsabschlussprüfung noch eine Erinnerung, wenn kein Ereignis erfasst wurde.
- Korrekturen/Stornierungen erfolgen nicht direkt in der Trainingsliste, sondern über die Spielerdetails mit Begründung und Auditspur.

### 3.2 Darstellung im Ereignis-Tab

- Kleine, kompakte Ereigniskennzeichen auf der Spielerzeile.
- Mehrere Kennzeichen (z. B. gelb, rot, Stern) müssen nebeneinander Platz finden, ohne die Zeile zu überladen.
- Die vollständigen Informationen und Begründungen bleiben in den Spielerdetails verfügbar.

## 4. Spielerliste: zwei Ansichten

Die bestehende allgemeine Spielerliste erhält zwei Tabs in dieser Reihenfolge:

1. **Anwesenheit**
2. **Ereignisse**

### 4.1 Anwesenheit

- Zeigt die bisherige Trainingsstatistik wie heute.
- Die vorhandene Sortierung, Suche, Positionsfilter und Trainingsbeteiligungsdarstellung bleiben erhalten.
- Die neue Ereignisfunktion darf die bestehende Anwesenheitsstatistik nicht ersetzen oder verfälschen.

### 4.2 Ereignisse

- Zeigt die zentrale Karten-, Sperren- und Sterneübersicht für die ausgewählte Mannschaft und aktuelle Saison.
- Die vorhandene Spielerkachel/Spielerzeile bleibt die Grundlage; es wird keine neue Listenkomponente aufgebaut.
- Reihenfolge der Bedienung: **Tabs → Suche → Filterchips → Spielerliste**.
- Filterchips sind kompakt und horizontal scrollbar, damit mehrere Ereignistypen/Statusinformationen nicht zu einer überladenen Filterleiste führen.
- Die fachlich abgestimmten Filter sind: **Alle**, **Sperren**, **Warnungen**, **Ohne Auffälligkeiten**.
- Warnungen werden nicht als Chip dargestellt. Stattdessen wird die gesamte Spielerkachel gelb hinterlegt; rechts steht die Information zur Begründung bzw. zum Warnstatus.
- Spieler mit offener Sperre erhalten eine rot hinterlegte Kachel.
- Ereigniskennzeichen für gelbe Karte, rote Karte und positive Sterne erscheinen als kleine, kompakte Symbole/Chips innerhalb der Kachel. Sie dürfen sich bei mehreren Ereignissen nicht gegenseitig verdrängen.
- Sortierung nach Handlungspriorität gemäß AP05.3: offene Sperren, vier aktive gelbe Karten/Warnung, andere aktive gelbe Karten, danach Spieler ohne aktive Auffälligkeit; innerhalb der Gruppen alphabetisch.
- Suche und Filter wirken zusammen. Der Filterzustand bleibt beim Öffnen und Verlassen der Spielerdetails erhalten.

### 4.3 Spielerdetails

Die bestehende Spielercard wird erweitert, nicht ersetzt:
- Aktueller Karten-/Sperrenstatus gut sichtbar.
- Ereignishistorie und Sperrenhistorie als einklappbare Bereiche, neueste Einträge zuerst.
- Korrektur-/Stornierungsaktionen direkt an den betreffenden Einträgen, sofern berechtigt.
- Manuelle Sperrenkorrektur über das in AP05.3 festgelegte separate Formular mit Änderungsübersicht vor dem Speichern.
- Begründung, Benutzer, Zeitpunkt und alte/neue Werte bleiben nachvollziehbar.

## 5. Spieltagsdetail: Kaderplanung

Die vorhandenen vier Spieltag-Tabs bleiben bestehen:
- Kader
- Anwesenheit
- Teams
- Einsatz

Die bestehende Kaderansicht und ihre Spielerkacheln werden erweitert. Keine neue Kaderplanungsseite.

### 5.1 Statusdarstellung auf vorhandenen Kaderkacheln

| Status | Darstellung |
|---|---|
| Empfohlen, noch nicht nominiert | Blau hervorgehoben |
| Nominiert | Grün hervorgehoben, Apparel-Symbol am Avatar |
| Regulär gesperrt | Rot hinterlegt |
| Vorzeitiger Sperrausgleich vorgemerkt | Gelb hinterlegt, gelbes durchgestrichenes Apparel-Symbol |

- Regulär gesperrte Spieler bleiben sichtbar und werden von der regulären Empfehlung ausgeschlossen.
- Bei genehmigter Ausnahme bleibt die Kachel rot und erhält zusätzlich den Hinweis **„Ausnahme erteilt“**.
- Die bestehende direkte Nominierung durch Antippen der Kachel bleibt erhalten.
- Der vorzeitige Sperrausgleich erhält eine zusätzliche Kachelaktion und einen Eintrag im bestehenden Optionsmenü.
- Begründung und Bestätigung sind für Ausnahmen und Vormerkungen verpflichtend.
- Ein Spieler kann für denselben Spieltag nicht gleichzeitig nominiert sein und einen vorzeitigen Sperrausgleich vorgemerkt haben.
- Wird nachträglich nominiert, wird die Vormerkung mit Auditspur aufgehoben.
- Der vorzeitige Sperrausgleich beeinflusst nicht die allgemeine Kaderempfehlung.

## 6. Technische Bestandsaufnahme – bereits verifizierte Anknüpfungspunkte

Der aktuelle `develop/index.html`-Stand wurde frisch abgerufen. Die folgenden vorhandenen Strukturen sind im Bestand erkennbar und bilden die bevorzugten Erweiterungspunkte:

| Bereich | Vorhandene Struktur | Geplante Nutzung |
|---|---|---|
| Trainingsdetail-Tabs | `trainingDetailTabs`, `trainingDetailMode`, `renderTrainingDetail()` | Vierten Tab `events` ergänzen |
| Trainings-Spielerliste | `trainingPlayerList`, `trainingPlayerRow`, `trainingPlayerIdentity` | Anwesenheitsgefilterte Ereignisliste und kompakte Aktionsauswahl |
| Allgemeine Spielerliste | `playerListRow`, `playerListControls`, `playerFilterChip` | Bestehende Liste um Anwesenheit/Ereignisse erweitern |
| Spielercard | `playerCardSection`, bestehender Player-Detail-Flow | Status, Historien und Korrekturzugänge integrieren |
| Spieltagsdetail | `matchdayDetailTabs`, `matchdaySquadTile`, bestehende Kader-/Nominierungslogik | Statusdarstellung und Zusatzaktionen in vorhandenen Kaderkacheln |
| Gemeinsames Design | bestehende CSS-Variablen, Komponentenklassen, Darkmode-Regeln | Erweiterungen konsistent für Light/Dark Mode gestalten |

**Wichtig:** Diese Zuordnung ist eine erste Bestandsaufnahme anhand des aktuellen Frontend-Quellstands, keine Freigabe für Änderungen. Vor jeder konkreten Änderung werden die betroffenen Funktionen, State-Variablen, Event-Handler und Datenzugriffe vollständig im aktuellen `develop`-Stand geprüft.

## 7. Technische Reihenfolge

Die Umsetzung wird in kleinen, prüfbaren Schritten erfolgen:

1. **Datenbank-/Sicherheitsprüfung (read-only):** tatsächliche DEV-Tabellen, Spalten, Constraints, Trigger, Policies und RPCs gegen AP05.2 prüfen. Keine SQL-Ausführung.
2. **Frontend-Abhängigkeitsprüfung:** betroffene Funktionen und Datenflüsse in `index.html` vollständig nachvollziehen; insbesondere Trainingsereignisse, Spielercard, Spielerliste und Spieltagskader.
3. **Umsetzungsplan je Teilbereich:** konkrete Änderungen und Abhängigkeiten beschreiben, bevor Code angepasst wird.
4. **DEV-Implementierung:** zuerst die kleinste vertikale Funktionseinheit, anschließend Integration in die bestehenden Seiten.
5. **Praxistest in DEV:** Berechtigungen, Mehrfachaktionen, Korrekturen, Sperrenlebenszyklus, Ausnahmen, Kaderempfehlung, Light/Dark Mode und iPhone-Layout prüfen.

## 8. Read-only DEV-Datenbank-Erstbefund (07.11.2026)

Die Supabase-DEV-Struktur wurde ausschließlich lesend geprüft (Projekt `pzazqvvoruqnqhcorbwx`):

- Vorhandene Kernobjekte für Training und Spieltag sind vorhanden, darunter `trainings`, `attendance`, `training_responses`, `matchdays`, `matchday_players`, `matchday_attendance` und `matchday_recommendation_runs` / `matchday_recommendation_players`.
- Die geprüften Tabellen im Schema `public` haben RLS aktiviert. Es bestehen bereits teambezogene Policies sowie gesonderte Policies für ausgewählte Superadmin-/Teamkontexte und Club-Admins. Diese Sicherheitslogik ist bei jeder Erweiterung zu erhalten und im Detail für neue Objekte abzugleichen.
- In der Tabellenübersicht wurden keine AP05-Ereignis-/Sperrentabellen wie `training_behavior_events`, `training_behavior_event_audit`, `training_suspensions`, `training_suspension_exceptions` oder `training_suspension_audit` gefunden.
- In den gezielt nach Ereignis-/Sperrenbegriffen gefilterten Routinen und Triggern wurden keine passenden AP05-Funktionen oder Trigger gefunden. Vorhanden sind u. a. `save_matchday_recommendation` sowie bestehende Aktualisierungs- und Aktivspieler-Trigger.
- Die Bestandsaufnahme ist ein read-only Erstbefund, keine vollständige Freigabeprüfung aller Policies/Funktionen und keine Änderung an der Datenbank.

**Folgerung:** Die AP05-Ereignis- und Sperrenlogik ist in der DEV-Datenbank nach diesem Erstbefund noch nicht angelegt. Vor einer Frontend-Integration müssen das tatsächliche Ziel-Datenmodell, die RLS-/Rollenregeln, serverseitigen Funktionen und Audit-/Duplikatmechanismen im Detail geprüft und als vollständiger Vorschlag vorgelegt werden. Es wurde kein SQL ausgeführt, das Daten oder Schema verändert.

## 8.1 Vertiefte read-only Prüfung der DEV-Datenbank (07.11.2026)

### Relevante Bestandsstruktur
- `trainings`: Team-/Saisonbezug, Datum, Status (`planned`, `done`, `cancelled`), Trainingsserie und Notiz.
- `attendance`: zusammengesetzter Primärschlüssel aus `training_id` und `player_id`, boolesches Feld `present`.
- `training_responses`: Rückmeldestatus `open`, `yes`, `no`; getrennt von tatsächlicher Anwesenheit.
- `matchdays`: Team-/Saisonbezug, Datum, Gegner, Spielart, Status (`planned`, `done`, `cancelled`).
- `matchday_players`: Kaderzuordnung; `matchday_attendance`: tatsächliche Anwesenheit; Empfehlung wird getrennt über `matchday_recommendation_runs` und `matchday_recommendation_players` gespeichert.
- `players.team_id` ist durch `prevent_player_team_change` gegen direkte Teamänderung geschützt. Das ist für die AP05-Regel wichtig, dass Ereignisse/Sperren historisch an ihrem ursprünglichen Team hängen bleiben.

### Relevante bestehende Regeln
- Die geprüften Trainings-, Anwesenheits-, Spieltags-, Spieler- und Teamtabellen haben RLS aktiviert.
- Bestehende Policies verwenden u. a. `is_team_member(team_id)`, `is_team_admin(team_id)` und `has_selected_team_context(team_id)`; Superadmins arbeiten damit nur im gewählten Teamkontext. Club-Admins haben gezielte Leserechte, nicht pauschal dieselben Schreibrechte wie Trainer/Admins.
- Trainings-/Spieltagstabellen haben bestehende teambezogene Policies. Anwesenheits- und Zuordnungs-Policies prüfen teils zusätzlich, dass Training/Spieltag und Spieler derselben Mannschaft angehören.
- `save_matchday_recommendation(uuid, uuid[])` prüft Teammitgliedschaft, aktive Spieler, Teamzugehörigkeit und doppelte IDs. Die Funktion ist aktuell keine SECURITY DEFINER-Funktion; sie speichert die Empfehlung über die vorhandenen Tabellen.
- Bestehende Trigger schützen u. a. aktive Spielerzuordnungen, Aktualisierungszeitstempel und Spieler-Teamwechsel. Die neuen AP05-Regeln müssen diese Schutzmechanismen respektieren.
- Die aktuellen Primär-/Fremdschlüssel enthalten an mehreren Stellen `ON DELETE CASCADE`. AP05-Audit-/Historienobjekte dürfen deshalb nicht unbedacht an Spieler-/Trainings-/Teamobjekte mit Cascade gebunden werden, wenn die beschlossene Historienaufbewahrung dadurch verloren gehen könnte. Lösch- und Archivierungsverhalten muss ausdrücklich spezifiziert werden.

### Auswirkungen für AP05 – offene technische Klärpunkte
1. **Anwesenheit als Voraussetzung:** Ereignisse im Trainingsbereich `Ereignisse` dürfen nur für tatsächlich anwesende Spieler erfasst werden. Server-seitig muss die Anwesenheit zum Schreibzeitpunkt geprüft werden; eine reine UI-Filterung reicht nicht.
2. **Training abgeschlossen / Status:** Der Status `done` ist vorhanden. Es muss geklärt werden, ob Ereignisse vor/nach Abschluss bearbeitbar sind und wie spätere Korrekturen revisionssicher erfolgen. AP05 verlangt kontrollierte Korrektur/Storno statt Hard Delete.
3. **Team-/Saisonbezug:** Ereignis- und Sperrenzeilen müssen den ursprünglichen Team- und Saisonbezug dauerhaft speichern; ein Join ausschließlich über die aktuelle Spieler-Teamzuordnung wäre fachlich falsch.
4. **Sperrrelevante Spieltage:** `matchdays.status` kennt `planned`, `done`, `cancelled`. Die Zuordnung erlaubter Spielarten muss konfigurierbar sein (Club-Standard mit vollständigem Team-Override), wie in AP05.2 beschlossen.
5. **Empfehlung:** Sperren müssen vor der Empfehlung serverseitig in die Eligibility einfließen. Die bestehende Speicherfunktion allein implementiert diese Eligibility nicht; der konkrete Berechnungsort im aktuellen Frontend/Backend ist separat zu prüfen.
6. **Berechtigungen:** Bestehende Teamrollen liegen in `team_member_roles` und `team_members`. Schreibrechte für Trainer müssen serverseitig explizit validiert werden; Club-Admins dürfen keine Ereignisse vergeben oder Sperren bearbeiten, sofern AP05 nichts anderes vorsieht.
7. **Audit und Integrität:** DB-seitige Eindeutigkeit (maximal eine Karte gesamt und maximal ein Stern pro Spieler/Training), atomare Vergabe, Audit vor/nach Änderung, reason-required Korrekturen und Verhinderung von Hard Deletes sind zwingend zu planen.

### Befund zu Grants / Triggern
- Für die geprüften Kernobjekte besitzen `authenticated` und `service_role` die üblichen Tabellenprivilegien; RLS-Policies bleiben die maßgebliche zeilenbezogene Kontrolle. Jede neue Tabelle braucht eine explizite Minimalvergabe und RLS-Policies.
- Bestehende Trigger umfassen u. a. `set_updated_at()`, `require_active_player_for_new_assignment()`, `prevent_player_team_change()`, `protect_player_active_status()` und die Bereinigung der Kaderempfehlung vor Spieler-Löschung.
- Dies ist eine gezielte Prüfung der E05-relevanten Tabellen/Objekte, kein vollständiger Sicherheits-Audit der gesamten Datenbank.

## 9. Sicherheits- und Freigabegrenzen

- Ausschließlich `develop` und Supabase DEV als Arbeitsumgebung.
- `main`, PROD, Produktivdaten, DNS und Registrar bleiben unverändert.
- Keine SQL-Schreiboperation und keine Migration ohne vorherige Vorlage des vollständigen SQL, Zweck, Zielumgebung und ausdrückliche Freigabe.
- Keine Änderungen an Auth-/Edge-Funktionen oder Supabase-Konfiguration ohne separate Freigabe.
- Datenmodell und Geschäftsregeln aus AP05.2 bleiben maßgeblich; UI-Dokumente ändern diese nicht.
- Bestehende RLS- und Rollenregeln dürfen nicht durch Frontend-Logik ersetzt oder umgangen werden.

## 9. Quellen und Abgrenzung

- Fachliche Ereignis-, Sperren- und Empfehlungsregeln: AP05.2.
- Userflows und Kaderplanungs-UI: `docs/AP05_3_USERFLOWS_UI_KONZEPT_2026-11-07.md`.
- Dieses Dokument: ergänzende UI-Konsolidierung und technische Umsetzungsleitlinie vom 07.11.2026.

**Status bei Erstellung:** Dokumentation und read-only Frontend-Bestandsaufnahme begonnen. Noch keine Code-, SQL-, Datenbank-, Supabase- oder PROD-Änderung.


## 10. Verbindliche Präzisierung – Sperrstatus nach erteilter Ausnahme (12.11.2026)

Für die Spieltagskachel gelten ab sofort folgende visuelle und funktionale Zustände:

1. **Regulär gesperrt, keine Ausnahme:** Die gesamte Kachel erhält eine sanfte, aber klar erkennbare rote Hinterlegung mit passender Kontur. Ein einheitlicher Status-Chip lautet „Gesperrt · Ausnahme möglich“. Der Spieler bleibt sichtbar, wird aus der regulären Kaderempfehlung ausgeschlossen und kann nicht regulär nominiert werden. Durch Antippen kann der Trainer den begründungspflichtigen Ausnahmeprozess starten.
2. **Ausnahme für genau diesen Spieltag erteilt:** Die rote Hinterlegung und rote Sperrkontur entfallen vollständig. Die Kachel erhält wieder ihre normale Grunddarstellung bzw. die unabhängig davon geltende Empfehlungs-/Nominierungsdarstellung. Ein Status-Chip „Ausnahme erteilt“ bleibt sichtbar. Der Spieler ist für diesen konkreten Spieltag wieder empfehlungs- und nominierungsfähig.
3. **Folgender relevanter Spieltag:** Die offene Sperre bleibt bestehen und wird gemäß AP05.2 auf den nächsten relevanten Spieltag verschoben. Dort erscheint der Spieler wieder im Zustand „Gesperrt · Ausnahme möglich“, sofern für diesen neuen Spieltag keine eigene Ausnahme erteilt wurde.

Die Ausnahme ist keine endgültige Aufhebung oder Löschung der Sperre. Sie gilt ausschließlich für den konkreten Spieltag; Sperrhistorie und offene Sperre bleiben erhalten.

### Einheitliche Status-Chips
- Beide Chips („Gesperrt · Ausnahme möglich“ und „Ausnahme erteilt“) verwenden dieselbe Komponente bzw. dieselben Gestaltungsparameter.
- Identisch sind insbesondere Höhe, Schriftgröße, Schriftgewicht, Zeilenhöhe, Innenabstände, Außenabstände, Eckenradius und Position innerhalb der Spielerkachel.
- Der Chip steht immer unmittelbar unter dem Spielernamen. Unterschiedliche Textlängen dürfen die Chip-Höhe und die vertikalen Abstände nicht verändern.
- Der Status-Chip darf die Kachelhöhe nicht durch uneinheitliche Margins oder Padding verändern.

**Abgrenzung:** Gelb bleibt für den in AP05.3 dokumentierten vorgemerkten vorzeitigen Sperrausgleich reserviert. Es wird nicht als Ersatzfarbe für eine reguläre Sperre oder eine erteilte Ausnahme verwendet.

Diese Präzisierung ersetzt für den Ausnahmespieltag die zuvor dokumentierte Darstellung „weiterhin rote Kachel nach Ausnahme“. Sie ändert keine DB-Sperrlogik, keine Berechtigungen und keine fachlichen AP05.2-Regeln.
