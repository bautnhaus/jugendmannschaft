# E05 / AP05 – Umsetzungsvorschlag: Sperrmaßnahmen im Spielerkachel-Optionsmenü

**Stand:** 12.11.2026  
**Zielumgebung:** ausschließlich GitHub develop / Supabase DEV  
**Status:** Konzeptvorschlag zur Prüfung – keine Umsetzung freigegeben  
**PROD / main:** ausdrücklich außerhalb des Umfangs

## 1. Verbindliche Nutzerentscheidungen

1. Drei-Punkte-Optionsmenü auf jeder Spielerkachel.
2. Begründung ist bei jeder Erteilung und jeder Rücknahme Pflicht.
3. Ausnahme zurücknehmen wirkt sofort: Spieler wird für den konkreten Spieltag wieder regulär gesperrt.
4. Ausnahme-Chip bleibt nach Erteilung sichtbar; die Kachel übernimmt ansonsten vollständig ihre normale Kontur sowie Empfehlungs-/Nominierungsdarstellung.
5. Sperr- und Audit-Historie wird nie gelöscht.

## 2. Read-only Bestandsbefund aus develop-Dokumentation

| Fachaktion | Dokumentierte Funktion | Paket |
|---|---|---|
| Ausnahme erteilen | grant_suspension_exception(uuid,uuid,text) | 5/6 |
| Ausnahme zurücknehmen | revoke_suspension_exception(uuid,text) | 6 |
| Vorzeitigen Sperrausgleich vormerken | schedule_early_suspension_reset(...) | 8 |
| Vormerkung zurücknehmen | cancel_early_suspension_reset(...) | 8 |

Die Funktionen sind in den SQL-Dokumenten auf develop beschrieben. Ihre aktuelle Existenz, exakten Signaturen und Rechte müssen vor Frontend-Integration direkt im Supabase-DEV-Katalog read-only verifiziert werden. Aus der Dokumentation allein wird keine aktuelle DB-Realität abgeleitet.

## 3. Kritischer Sicherheits- und Fachprüfpunkt

Der dokumentierte Widerrufs-RPC für Ausnahmen setzt den Ausnahme-Datensatz auf widerrufen und stößt die Sperren-Neuzuordnung an. Vor Frontend-Integration ist zwingend die vollständige Funktion zu prüfen:
- Wird bei einer bereits nominierten Person die Zeile in matchday_players atomar entfernt oder anderweitig sicher blockiert?
- Wird die offene Sperre unmittelbar wieder dem aktuellen Spieltag zugeordnet?
- Bleibt die Ausnahmehistorie mit Widerrufsbegründung, Akteur und Zeitstempel erhalten?
- Verhindern Trigger/RPCs, dass eine parallele Nominierung während der Rücknahme bestehen bleibt?

Falls eine bestehende Nominierung nicht konsistent entfernt wird, darf das Frontend den Vorgang nicht als erfolgreich darstellen. Dann ist ein separater DB-Änderungsentwurf mit vollständigem SQL, Berechtigungsprüfung, Audit, Rollback und Testfällen erforderlich. Keine SQL-Ausführung ohne gesonderte Freigabe.

## 4. Optionsmenü – Sichtbarkeit und Aktionen

Das Drei-Punkte-Menü ist auf jeder Spielerkachel verfügbar. Es zeigt ausschließlich Aktionen, die zum Spielerstatus und aktuellen Spieltag passen.

| Zustand | Menüaktion |
|---|---|
| Offene Sperre, aktuelle Zuordnung, keine Ausnahme | Ausnahme erteilen |
| Aktive Ausnahme für aktuellen Spieltag | Ausnahme zurücknehmen |
| Zulässiger vorgemerkter Sperrausgleich | Vorzeitigen Sperrausgleich zurücknehmen |
| Spieler ohne Sperre, für den der vorzeitige Ausgleich fachlich zulässig ist | Vorzeitigen Sperrausgleich erteilen |
| Vorgang bereits angewendet/abgeschlossen oder Spieltag nicht mehr änderbar | Keine unzulässige Änderungsaktion; ggf. nur Status/Verlauf anzeigen |

Die genauen Bedingungen für vorzeitigen Sperrausgleich müssen aus Paket 8 und AP05.2 übernommen werden. Nicht anhand vereinfachter Frontend-Annahmen nachbauen.

## 5. Einheitlicher Bestätigungsdialog

Jede Aktion öffnet einen Bestätigungsdialog mit Spielername, betroffenen Spieltag/Sperrbezug, Pflichtfeld Begründung sowie Abbrechen/Bestätigen.

Bei Rücknahmen muss der Dialog die unmittelbare Auswirkung erklären. Bei Ausnahme-Widerruf darf die UI eine Entfernung einer bestehenden Nominierung nur versprechen, wenn das DB-Verhalten technisch verifiziert und sichergestellt ist.

## 6. Kachelstatus und Kaderplanung

- Offene Sperre ohne Ausnahme: sanft rote gesamte Kachel, Chip „Gesperrt · Ausnahme möglich“, nicht empfehlbar/nominierbar.
- Ausnahme erteilt: normale Kachelkontur und normale Empfehlungs-/Nominierungsdarstellung; Chip „Ausnahme erteilt“ an einheitlicher Position.
- Ausnahme zurückgenommen: sofort wieder sanft rote Kachel; Chip „Gesperrt · Ausnahme möglich“; aus Empfehlung/Nominierung ausgeschlossen.
- Beide Chips nutzen eine gemeinsame Komponente mit identischer Höhe, Schrift, Zeilenhöhe, Padding, Margin und Position.
- Ein Ausnahme-Chip darf die bestehende Empfehlungs- oder Nominierungsdarstellung nicht überschreiben.

## 7. Umsetzungsschritte nach Freigabe

1. Aktuelle DEV-DB-Funktionsdefinitionen und Grants read-only prüfen: vier RPCs sowie abhängige Trigger/Funktionen.
2. Widerrufsauswirkung auf matchday_players und Konkurrenz-/Transaktionsverhalten verifizieren.
3. Falls DB-Lücke: separaten SQL-Entwurf zur Prüfung vorlegen; nicht ausführen.
4. Frontend-Bestand in index.html prüfen: Kachel-Markup, Klickverhalten, vorhandene Drei-Punkte-Menüs/Komponenten, Event-Delegation und mobile Layouts.
5. Frontend-Implementierung auf develop: Optionsmenü für alle Kacheln, statusabhängige Aktionen, einheitlicher Pflichtbegründungsdialog, bestehende RPCs aufrufen.
6. Nach jeder erfolgreichen RPC-Aktion den aktuellen Sperr-/Ausnahmestatus neu laden und Kachel, Empfehlung, Auswahl und Zähler konsistent neu rendern. Bei Fehlern lokalen Zustand nicht optimistisch verändern.
7. DEV-Praxistests mit Trainer und Mannschaftsadmin, inklusive iPhone/Darkmode und Negativtests.
8. Alle SQL-/Frontend-Änderungen und Testergebnisse in den Migration-/Change-Logs und Projektkontext eintragen.

## 8. Mindest-Testfälle

- Menü erscheint auf jeder Spielerkachel und verdeckt nicht den normalen Kachel-Klick.
- Offene Sperre: Ausnahme erteilen nur mit Begründung; danach normale Kachel + Ausnahme-Chip; Empfehlung/Nominierung zulässig.
- Ausnahme zurücknehmen nur mit Begründung; sofort rote Kachel und Sperre wieder aktiv.
- Bereits nominierter Spieler: Widerruf führt atomar zum fachlich korrekten Zustand; kein „gesperrt und dennoch nominiert“.
- Vorzeitigen Sperrausgleich vormerken und zurücknehmen jeweils nur bei zulässigem Status und mit Begründung.
- Bereits angewendeter/abgeschlossener Sperrausgleich kann nicht rückwirkend storniert werden.
- Doppelklick, parallele Requests und wiederholte RPC-Aufrufe erzeugen keine doppelten Vorgänge.
- Nicht berechtigte Rollen können keine RPC-Aktion ausführen.
- Audit enthält Erteilung/Rücknahme, Begründung, Akteur und Zeitstempel.
- Chip-Geometrie bleibt bei beiden Texten gleich; Kachelkontur/-farbe folgt dem jeweiligen Empfehlungs-/Nominierungsstatus.

## 9. Freigabegrenzen

Dieser Vorschlag dokumentiert den geplanten Umfang. Er ist keine Freigabe zur Code- oder Datenbankänderung. Vor Implementierung werden die read-only DB-Prüfung und ggf. ein separater SQL-Entwurf vorgelegt. DEV ist das einzige Ziel; main und PROD bleiben unverändert.
## 10. Ergebnis der tatsächlichen DEV-Prüfung (12.11.2026)

### Datenbank
- Alle vier erwarteten Nutzer-RPCs sind im aktuellen Supabase-DEV-Projekt vorhanden.
- revoke_suspension_exception(uuid,text) entfernt keine bestehende Nominierung aus matchday_players.
- Der aktuelle Nominierungs-Guard blockiert neue/aktualisierte Nominierungen ohne Ausnahme, entfernt aber keine bestehende Nominierung und sperrt die Spielerzeile vor dem Statuscheck nicht. Damit besteht ein Parallelitätsrisiko, das vor einer zuverlässigen Sofortwirkung geschlossen werden muss.
- Die matchday_players-Tabelle besitzt den zusammengesetzten Primärschlüssel (matchday_id,player_id) und eine passende Delete-RLS-Policy. Der Widerrufs-RPC ist SECURITY DEFINER und kann die gezielte Entfernung innerhalb seiner Transaktion durchführen.
- cancel_early_suspension_reset(uuid,text) kann nur eine Vormerkung mit Status pending zurücknehmen. Bereits angewendete Vorgänge sind geschützt und werden nicht rückwirkend verändert.

### Datenbank-Entwurf
Ein SQL-Entwurf liegt unter docs/drafts/DB-MIG-DRAFT_E05_EXCEPTION_REVOKE_IMMEDIATE_2026-11-12.sql. Er ergänzt den Widerrufs-RPC um die transaktionale Entfernung einer vorhandenen Nominierung und erweitert den Nominierungs-Guard um einen Spielerzeilen-Lock in derselben Reihenfolge wie der Widerrufs-RPC. Die Auditdaten sollen festhalten, ob eine Nominierung entfernt wurde.

Der Entwurf ist **nicht ausgeführt** und nicht als Migration registriert. Vor Ausführung sind vollständige SQL-Prüfung, Abgleich gegen den Live-Stand und separate ausdrückliche Freigabe erforderlich.

### Frontend-Bestand
- Die Spielerkacheln werden aktuell als Button gerendert; ein weiteres Options-Button-Element darf nicht darin verschachtelt werden.
- Für das Optionsmenü wird ein Wrapper mit zwei Geschwisterelementen benötigt: bestehende Kachel als Hauptaktion und Drei-Punkte-Optionsbutton mit statusabhängigem Menü.
- Die bestehende Ausnahme-Erteilung ist bereits über grant_suspension_exception angebunden. Widerruf und vorzeitiger Sperrausgleich haben noch keinen Kachel-Optionsflow.

### Reihenfolge / aktueller Stopp
Die Schritte 1 und 2 sind abgeschlossen; Schritt 3 (DB-Entwurf) ist vorbereitet. Schritt 4 (Frontend-Implementierung) wird bewusst erst nach separater Freigabe, Ausführung und erfolgreicher DEV-Prüfung des DB-Entwurfs begonnen. So wird keine Oberfläche ausgeliefert, die eine Sofortwirkung verspricht, die die Datenbank noch nicht garantiert.

## 10. Ergebnisse der technischen Prüfung (12.11.2026)

### 10.1 Supabase DEV – Ist-Stand
Read-only direkt im DEV-Projekt geprüft:

- Die RPC-Signaturen sind vorhanden:
  - `grant_suspension_exception(uuid,uuid,text)`
  - `revoke_suspension_exception(uuid,text)`
  - `schedule_early_suspension_reset(uuid,uuid,text)`
  - `cancel_early_suspension_reset(uuid,text)`
- Alle vier verlangen Authentifizierung, Teamrolle Trainer/Admin oder Superadmin im ausgewählten Teamkontext und eine nicht leere Begründung.
- Die Ausnahme-RPCs schreiben Audit-Ereignisse; der Widerruf erhält den Exception-Datensatz und setzt Widerrufsmetadaten.
- Der Widerruf ruft `e05_assign_player_suspensions` zur Neuzuordnung auf.
- Die vorzeitige Ausgleichsvormerkung ist nur für einen zukünftigen geplanten Spieltag, aktive Spieler und eine aktive Saison möglich; eine bereits bestehende Nominierung verhindert die Vormerkung.
- Die Rücknahme eines vorzeitigen Ausgleichs akzeptiert ausschließlich den Status `pending`. Bereits angewendete Ausgleiche sind damit nicht manuell rücknehmbar.
- `matchday_players` besitzt eine DELETE-RLS-Policy für Teammitglieder; die Widerrufs-RPC ist SECURITY DEFINER. Die tatsächliche Löschung muss trotzdem in der RPC mit Matchday-/Spielerbindung abgesichert sein.

### 10.2 Nachgewiesene Lücke bei Ausnahme-Widerruf
Der aktuell installierte `revoke_suspension_exception(uuid,text)` widerruft die Ausnahme, auditiert den Vorgang und weist die offene Sperre neu zu. Er entfernt jedoch keine bereits vorhandene Zeile aus `matchday_players`.

Der aktuelle Trigger `prevent_suspended_matchday_nomination()` blockiert neue INSERTs bzw. relevante UPDATEs bei einer aktiven Sperre ohne Ausnahme. Er ist kein nachträglicher Bereinigungsmechanismus. Eine schon vorhandene Nominierung bleibt daher ohne Ergänzung bestehen.

### 10.3 Vorgelegter SQL-Entwurf
Für die Lücke wurde ein separater Review-Entwurf erstellt:

- `docs/E05_SQL_ENTWURF_WIDERRUF_AUSNAHME_MIT_NOMINIERUNGSENTFERNUNG_2026-11-12.sql`
- `docs/E05_SQL_ROLLBACK_ENTWURF_WIDERRUF_AUSNAHME_2026-11-12.sql`

Der Entwurf:
- synchronisiert Widerruf und neue/geänderte Nominierungen über einen transaktionsgebundenen Advisory Lock pro Spieler;
- entfernt nur die Nominierungszuordnung des betroffenen Spielers am betroffenen zukünftigen geplanten Spieltag;
- bricht ab, falls `played=true` bereits einen tatsächlichen Einsatz dokumentiert;
- speichert den entfernten `matchday_players`-Datensatz als Snapshot im bestehenden Audit-Eintrag;
- verändert keine Tabellenstruktur, RLS-Policies oder PROD-Daten.

**Wichtige Freigabegrenze:** Beide SQL-Dateien sind ausschließlich Prüfentwürfe. Sie wurden nicht ausgeführt. Der Rollback stellt Funktionsdefinitionen wieder her, rekonstruiert aber keine zuvor entfernte Nominierung automatisch; eine solche Wiederherstellung müsste kontrolliert anhand des Audit-Snapshots erfolgen.

### 10.4 Frontend – Read-only Befund
Die aktuelle `index.html` auf `develop` wurde gelesen (Blob SHA `1f38ceb255b391c9fce7b9d1d04f79fa8dc280ff`):

- Die Kaderplanung rendert Spielerkacheln aktuell als jeweils ein äußeres `button`; das Antippen schaltet die Nominierung um.
- Für eine Ausnahme existiert bereits ein eigener Begründungsdialog und der Aufruf von `grant_suspension_exception`.
- Eine UI für `revoke_suspension_exception`, `schedule_early_suspension_reset` und `cancel_early_suspension_reset` ist in diesem Kaderplanungsflow noch nicht integriert.
- CSS-Klassen für `matchdayOptionsWrap` und `matchdayOptionsMenu` sind bereits vorhanden und werden in anderen Bereichen verwendet. Ein Drei-Punkte-Menü an den Kader-Spielerkacheln ist im geprüften Markup jedoch noch nicht eingebaut.
- Das aktuelle Laden des Sperrstatus lädt offene Sperren und Ausnahmen, aber keine Datensätze aus `matchday_early_suspension_resets`. Für die statusabhängigen Menüaktionen muss dieser Status ergänzt werden.

### 10.5 Konsequenz für die Reihenfolge
Die UI-Implementierung wird noch nicht begonnen, weil die sofortige Rücknahme einer Ausnahme fachlich beschlossen, im installierten DB-Stand aber nicht vollständig abgesichert ist. Zuerst muss der SQL-Entwurf geprüft und separat freigegeben sowie in DEV ausgeführt und getestet werden. Danach kann die Frontend-Integration gegen den verifizierten RPC-Vertrag erfolgen.

### 10.6 Nächste konkrete Schritte nach Freigabe
1. SQL-Entwurf fachlich/technisch prüfen und ausdrücklich zur Ausführung in DEV freigeben.
2. In DEV mit Testdaten positive, negative und konkurrierende Nominierungsfälle testen.
3. Erst nach erfolgreicher DB-Verifikation den Kaderplanungsflow in `index.html` umbauen: Kachelbutton und separates Optionsmenü als Geschwisterelemente, keine verschachtelten Buttons.
4. Frühzeitige Ausgleichsdatensätze je Spieltag laden und Statusaktionen anzeigen.
5. RPC-Aufrufe mit Pflichtbegründung integrieren, nach Erfolg Daten frisch laden und UI neu rendern.
6. iPhone-Light-/Darkmode, Rollen, Mehrfachklicks und parallele Requests testen.


### 10.7 DEV-Migration ausgeführt und verifiziert (13.11.2026)

**Migration:** `e05_atomic_exception_revocation_20261113`
**Supabase-Projekt:** DEV (`pzazqvvoruqnqhcorbwx`)
**Migrationsergebnis:** erfolgreich; Eintrag in `supabase_migrations.schema_migrations` vorhanden (`20261113035705`).

Nach der Ausführung wurden die beiden Funktionsdefinitionen, SECURITY-Attribute, ACLs und die Triggerbindung read-only erneut ausgelesen:

- `revoke_suspension_exception(uuid,text)`: vorhanden, SECURITY DEFINER, EXECUTE weiterhin ausschließlich für `authenticated` (neben Owner postgres).
- `prevent_suspended_matchday_nomination()`: vorhanden, SECURITY INVOKER, bestehende Ausführungsrechte `postgres` und `service_role` unverändert.
- Der bestehende Trigger `matchday_players_prevent_suspended_nomination` bleibt an diese Funktion gebunden.
- Die weiteren bestehenden Trigger auf `matchday_players` sind weiterhin vorhanden.
- Keine Tabellenstruktur, Datensätze, RLS-Policies oder PROD-Objekte wurden durch diese Migration geändert.

**Wichtige Abgrenzung:** Die Migration ist technisch installiert und ihre Katalogdefinitionen wurden verifiziert. Der praktische Positiv-/Negativ- und Konkurrenztest mit isolierten DEV-Testdaten steht noch aus. Die Migration ist deshalb noch nicht als fachlich vollständig abgenommen zu betrachten. Die Frontend-Integration beginnt erst nach diesen Tests.


### 10.8 Isolierte DEV-Praxistests (13.11.2026)

Alle Tests wurden in Supabase DEV innerhalb expliziter Transaktionen ausgeführt und anschließend mit `ROLLBACK` vollständig zurückgesetzt. Es wurden keine Testdatensätze dauerhaft angelegt.

**Ergebnis: bestanden**

1. **Bestehende Nominierung, `played=false`:** Widerruf erfolgreich; Nominierung aus `matchday_players` entfernt; vollständiger JSON-Snapshot im `exception_revoked`-Audit gespeichert.
2. **Trigger-Schutz nach Widerruf:** erneuter INSERT derselben Spieler-/Spieltag-Zuordnung wurde mit Check-Constraint-Fehler abgewiesen.
3. **Tatsächlicher Einsatz, `played=true`:** Widerruf mit SQLSTATE `23514` abgebrochen; Exception blieb aktiv, Nominierung blieb unverändert, kein Widerrufs-Audit wurde geschrieben.
4. **Keine bestehende Nominierung:** Widerruf erfolgreich; Audit dokumentiert `nomination_removed=false` und Snapshot `null`.
5. **Berechtigung:** autorisierter Teamadmin-/Trainer-Kontext konnte den RPC ausführen; ein nicht berechtigter Auth-Kontext wurde mit `42501` abgewiesen.
6. **RPC-Integration:** `grant_suspension_exception` erzeugte Exception und Grant-Audit; automatische Ziel-Neuzuordnung wurde nachvollzogen; anschließender Widerruf ordnete die Sperre zurück zu und entfernte die Nominierung auf dem nun wieder gesperrten Spieltag.

**Rollback-Kontrolle:** anschließende read-only Zählung ergab jeweils 0 Datensätze mit dem Testpräfix in `players`, `training_behavior_events`, `training_suspensions`, `training_suspension_exceptions` und `matchdays`.

**Noch offen / nicht durch diese Tests belegt:**
- Ein echter Konkurrenztest mit zwei gleichzeitig aktiven Datenbank-Sessions (INSERT gegen Widerruf) wurde nicht ausgeführt. Die gemeinsame Advisory-Lock-ID und Sperrreihenfolge sind im installierten Trigger/RPC sichtbar; das ersetzt keinen parallelen Laufzeittest.
- Der Superadmin-only-Zweig wurde nicht unabhängig getestet, da der verfügbare Superadmin im DEV-Team zusätzlich die Trainerrolle besitzt. Der Negativtest für einen nicht berechtigten Auth-Kontext ist bestanden.
- Der Praxistest erfolgte über die Datenbank-RPCs; ein UI-/Frontendtest ist noch nicht erfolgt.

**Abnahmeempfehlung:** Datenbankseitige Funktionsprüfungen für den Widerruf sind bestanden. Vor Frontend-Abnahme bleibt der echte Zwei-Session-Konkurrenztest als gezielter Restpunkt dokumentiert. Keine PROD-Freigabe und keine Änderung an `main`.


### 10.9 Zwei-Session-Konkurrenztest erfolgreich (13.11.2026)

Ein echter paralleler Lauf wurde mit zwei gleichzeitig gestarteten Supabase-SQL-Aufrufen auf isolierten DEV-Testdaten durchgeführt.

**Testaufbau (dritter, sauberer Fixture-Datensatz):**
- Spieler: `E05 CONCURRENCY TEST 3`
- Ausnahme war aktiv und bezog sich auf denselben Spieltag wie die offene Sperre.
- Vor dem Rennen bestand noch keine Nominierung.
- Session A erhielt den spielerbezogenen Advisory Lock, wartete drei Sekunden und führte anschließend den INSERT in `matchday_players` aus.
- Session B startete eine Sekunde später, wartete kurz und rief `revoke_suspension_exception` auf. Damit konkurrierten INSERT-Trigger und Widerrufs-RPC um denselben Advisory Lock.

**Ergebnis:**
- Beide SQL-Aufrufe wurden erfolgreich abgeschlossen.
- Der INSERT konnte unter aktiver Ausnahme zuerst committen.
- Der Widerruf wurde serialisiert danach ausgeführt.
- Der Widerrufs-RPC entfernte die inzwischen bestehende Nominierung innerhalb seiner Transaktion.
- Read-only Nachprüfung: Ausnahme widerrufen, keine Nominierung mehr vorhanden, Audit enthält `nomination_removed=true` und `played=false)-Snapshot.

**Bewertung: BESTANDEN.** Der kritische Konkurrenzfall „Nominierung während gleichzeitigem Ausnahme-Widerruf“ wurde mit zwei echten Datenbanksitzungen nachgewiesen. Der Spieler kann nach dem Widerruf nicht im gesperrten Spieltag nominiert verbleiben.

### 10.10 Testdaten und Audit-Aufbewahrung

Die Testspieler/-ereignisse/-sperren/-ausnahmen wurden mit eindeutigem `E05 CONCURRENCY TEST`-Präfix angelegt. Die unveränderlichen Sperren-Audit-Einträge verhindern eine vollständige Löschung der zugehörigen Testhistorie (FK `ON DELETE RESTRICT` und append-only Trigger). Diese Datensätze bleiben daher als gekennzeichnete DEV-Testartefakte erhalten; es wurde kein Audit-Schutz umgangen und keine Audit-Zeile gelöscht. Keine dieser Testdaten betrifft PROD.


### 10.11 Frontend-Umsetzung – erster struktureller Schritt (13.11.2026)

**Branch:** `develop`  
**Datei:** `index.html`  
**Commit:** `4231b86f3e0370ef0356a77761a582e77bfbc735`

- Die bisherige Kaderkachel bleibt ein eigener Button und behält unverändert `toggleMatchdayNomination(playerId)` als Klickaktion.
- Die Kachel liegt nun in einem umschließenden Container; der separate Drei-Punkte-Button ist ein Geschwisterelement und kein verschachtelter Button.
- Das Optionsmenü kann geöffnet und durch Klick außerhalb geschlossen werden. Der Menübutton verhindert die Weitergabe des Klicks an die Nominierungsaktion.
- Der bestehende Ausnahme-Dialog wird im gesperrten Zustand aus dem separaten Menü aufgerufen.
- CSS ergänzt Positionierung und Touch-Ziel für schmale Ansichten; bestehende Menügestaltung wird wiederverwendet.
- JavaScript-Modul wurde nach der Änderung erfolgreich syntaktisch geparst. Strukturprüfungen bestätigten genau einen neuen Kachel-Wrapper, den separaten Optionsbutton, den Toggle-Handler und den unveränderten Nominierungshandler.

**Abgrenzung:** Dies ist der erste strukturelle Frontend-Schritt, noch keine vollständige Umsetzung aller vier Sperraktionen. Widerruf der Ausnahme sowie Planen/Abbrechen des vorzeitigen Sperrendes sind noch nicht verdrahtet. Ebenso stehen DEV-Browser-/iPhone-Tests (Light-/Darkmode, Menüverhalten und Nominierung) noch aus. Keine Datenbankänderung, kein SQL und keine PROD-Änderung.


### 10.12 Frontend – vier Sperraktionen im Kachel-Optionsmenü (13.11.2026)

**Branch:** `develop`  
**Datei:** `index.html`  
**Commit:** `afd6f11d1d371fc5ecbdad88278419df931e0929`

- Der Sperrstatus-Loader liest zusätzlich `matchday_early_suspension_resets` für den ausgewählten Team-/Spieltagkontext.
- Das Drei-Punkte-Menü zeigt abhängig vom aktuellen Zustand:
  - „Ausnahme erteilen“ bei offener Sperre ohne aktive Ausnahme;
  - „Ausnahme zurücknehmen“ bei aktiver Ausnahme;
  - „Sperrausgleich vormerken“ bei zukünftigem geplantem Spieltag, aktivem und nicht nominiertem Spieler ohne bereits vorgemerkten oder angewendeten Reset;
  - „Vormerkung zurücknehmen“ bei einem noch offenen Reset.
- Die bestehende Ausnahme-Erteilung und die drei weiteren Aktionen verwenden jeweils die vorhandenen RPCs. Für jede Aktion ist eine nicht leere Begründung erforderlich. Die RPCs bleiben die maßgebliche Berechtigungs- und Zustandsprüfung.
- Nach erfolgreichem RPC werden Sperr-/Ausnahmestatus und die tatsächlichen `matchday_players`-Zeilen neu geladen. Die UI übernimmt keine optimistische lokale Nominierungs- oder Ausnahmeänderung.
- Mehrfachausführung wird während eines laufenden Requests im Frontend verhindert.
- Das Menü erhält ergänzende explizite Darkmode-Regeln.

**Statische Prüfung:** Das JavaScript-Modul wurde nach der Änderung erfolgreich syntaktisch geparst. Strukturprüfungen bestätigten den zusätzlichen Reset-Read, genau einen Reset-State, die Menü-Renderingfunktion, die drei neuen RPC-Aufrufe und den anschließenden Daten-Refresh.

**Noch ausstehend:** Browser-/DEV-Praxistest durch den Nutzer, insbesondere iPhone-Bedienung, Klicktrennung zwischen Kachel und Optionsmenü, Light-/Darkmode sowie die vier tatsächlichen RPC-Abläufe mit geeigneten DEV-Testfällen. Es wurde keine Datenbankänderung und kein SQL ausgeführt; `main` und PROD blieben unangetastet.


### 10.13 Frontend-Nachbesserung nach iPhone-Screenshot (13.11.2026)

**Commit:** `c6e1c45a453e081af3ae91e713788fa477f5b0c6`

- Optionsbutton auf der rechten Seite vertikal zentriert.
- Kader-Chip bleibt oben rechts separat sichtbar; nominierte Kacheln erhalten ausreichende Mindesthöhe, damit Chip und Optionsbutton nicht überlappen.
- Helle Sperr-Kachel im Hellmodus auf eine dezente hellrote Fläche mit gut lesbarer dunkler Schrift umgestellt. Darkmode-Regeln bleiben bestehen.
- JavaScript-Modul nach CSS-Änderung erneut syntaktisch geprüft; erfolgreich.
- Noch ausstehend: visueller DEV-/iPhone-Praxistest.


### 10.14 DEV-Testdaten aus aktivem Kader entfernen (13.11.2026)

Die drei im Screenshot sichtbaren Datensätze wurden read-only eindeutig als die dokumentierten E05-Concurrency-Fixtures identifiziert:

- `E05 CONCURRENCY TEST`
- `E05 CONCURRENCY TEST 2`
- `E05 CONCURRENCY TEST 3`

Alle drei gehören zum selben DEV-Team. Jeder Datensatz besitzt bereits je einen Behavior-Event-, Sperr- und Ausnahme-Datensatz. Aufgrund der Audit-/Foreign-Key-Beziehungen werden die Testhistorien nicht physisch gelöscht. Auf ausdrücklichen Wunsch, die Testspieler aus dem aktiven Kader zu entfernen, wird ausschließlich das jeweilige `players.active` auf `false` gesetzt. Dadurch bleiben Audit und Historie nachvollziehbar; die Spieler werden aus der aktiven Kaderplanung herausgenommen und bleiben in der Inaktiv-Liste reaktivierbar.

**Geplante Datenänderung:** ausschließlich `UPDATE public.players SET active=false` für die drei oben genannten IDs im DEV-Projekt `pzazqvvoruqnqhcorbwx`. Keine Löschung von Events, Sperren, Ausnahmen oder Audit-Einträgen. Kein PROD-Zugriff.
