# DEV-Umsetzung: expliziter Mannschaftskontext für Vereinsadmin und Super Admin

Datum: 28.10.2026  
Branch: `develop`  
Supabase-Projekt: DEV (`pzazqvvoruqnqhcorbwx`)  
PROD: nicht verändert

## Umgesetzt

- Neue Tabelle `public.user_team_context` speichert den ausdrücklich ausgewählten Mannschaftskontext je angemeldetem Benutzer. Direkter Tabellenzugriff ist für `anon` und `authenticated` entzogen; RLS ist aktiviert.
- RPC `select_team_context(p_team_id)` prüft serverseitig, ob der angemeldete Benutzer Super Admin ist oder Vereinsadmin des Vereins, zu dem die ausgewählte Mannschaft gehört.
- RPC `get_selected_team_context()` liefert nur den gespeicherten Kontext zurück, wenn die Berechtigung weiterhin besteht.
- RPC `clear_team_context()` löscht den eigenen Kontext; der Logout ruft sie auf.
- `has_selected_team_context(team_id)` ist die serverseitige Grundlage für zusätzliche SELECT-Policies. Die neuen Policies geben kontextgebundenen Lesezugriff auf Spieler, Positionen, Spieltage, Trainings, Serien, Anwesenheit, Rückmeldungen und zugehörige Planungsdaten.
- Es wurden keine INSERT-, UPDATE- oder DELETE-Policies für den ausgewählten Kontext ergänzt. Bestehende Schreibregeln bleiben bestehen; Vereins-/Super-Admins im Nur-Lese-Kontext erhalten dadurch keine Mannschaftsmitgliedschaft.
- Frontend: Mannschaftsauswahl in Vereins- und Plattformverwaltung ergänzt. Beim Öffnen einer Mannschaft wird der Kontext über die RPC geprüft und anschließend die reguläre Navigation geladen.
- Frontend: Der ausgewählte Admin-Kontext wird als „Nur Ansicht (Vereinsadmin/Superadmin)“ gekennzeichnet; Admin-Einstellungen für Mannschaftsänderungen werden ausgeblendet. Der allgemeine Schreibschutz meldet, wenn eine Funktion aus dem Nur-Lese-Kontext heraus aufgerufen wird.

## Technische Verifikation durchgeführt

- Migrationen in DEV erfolgreich angewendet.
- Existenz der neuen SELECT-Policies verifiziert.
- Ausführungsrechte der Kontext-RPCs geprüft: `anon` hat keine EXECUTE-Rechte; `authenticated` hat EXECUTE-Rechte.
- Vollständige `index.html` erneut über GitHub gelesen; die Mannschaftsauswahl, Kontext-RPC-Aufrufe und Read-only-Guard sind in der gespeicherten Datei vorhanden.

## Noch offen – Praxistests erforderlich

Es wurden keine authentifizierten End-to-End-Tests mit den drei realen Kontotypen ausgeführt. Daher ist die fachliche Integration noch nicht als vollständig bestanden zu markieren.

1. Super Admin: Verein auswählen, danach Mannschaft auswählen; Navigation und Datenansichten laden.
2. Vereinsadmin: Mannschaft des eigenen Vereins auswählen; Navigation und Datenansichten laden.
3. Vereinsadmin/Super Admin: Versuch, Spieler, Training, Anwesenheit oder Spieltag zu ändern, muss abgewiesen werden.
4. Fremder Verein / fremde Mannschaft: Auswahlversuch muss serverseitig abgewiesen werden.
5. Trainer/Mannschaftsadmin: reguläre Navigation und bisherige Schreibrechte unverändert testen.

Keine Mitgliedschaften, Rollen oder Spielerdaten wurden zu Testzwecken geändert.


## Nachbesserung nach Video-Praxistest

Nach dem ersten Praxistest zeigte sich, dass der Frontend-Start im ausgewählten Kontext wegen einer unveränderlichen Variablendeklaration abbrach, wenn die Teammitgliedschaften leer waren. Die Deklaration wurde auf `let` umgestellt, damit die serverseitig geprüfte Kontextmannschaft in den Ladepfad übernommen werden kann.

Zusätzlich:
- Die SELECT-Policies für `training_trainers` und `matchday_trainers` wurden für den ausdrücklich ausgewählten, berechtigten Kontext ergänzt.
- Die Mannschaftsauswahl in Einstellungen wird nach dem Laden der Kontextmannschaft erneut befüllt und auf den aktuell ausgewählten Verein/die Mannschaft gesetzt, damit ein Wechsel möglich bleibt.
- DEV-Frontend-Commit: `29d303b66d66f59fdd530bda2f1892044668c1a4`.
- Die Korrekturen wurden strukturell im gespeicherten HTML und in den DEV-Policies geprüft. Ein erneuter Live-Praxistest durch den Nutzer steht noch aus.


## Nachbesserung: volle Super-Admin-Schreibrechte im ausgewählten Kontext

Nach verbindlicher Klarstellung der Support-Rolle wurden in DEV zusätzliche Berechtigungen ergänzt:

- Super Admin kann im ausdrücklich ausgewählten Mannschaftskontext die bisherigen Team-Schreibaktionen verwenden, die durch vorhandene `*_super_admin_context_*` RLS-Policies abgedeckt werden.
- Der Trigger `protect_player_active_status` erlaubt Statusänderungen nun auch für Super Admins, aber nur bei passendem ausgewähltem Mannschaftskontext.
- `admin_add_team_role` und `admin_remove_team_role` akzeptieren Super Admins nur bei passendem ausgewähltem Mannschaftskontext; Schutz des letzten Mannschaftsadmins bleibt bestehen.
- `admin_add_club_member` und `admin_remove_club_member` akzeptieren Super Admins nur, wenn der ausgewählte Mannschaftskontext zu diesem Verein gehört; Ein-Verein-pro-Benutzer-Regel und Schutz des letzten Vereinsadmins bleiben bestehen.
- Die Frontend-Guards erlauben Schreibaktionen für Super Admins im ausgewählten Kontext, während Vereinsadmins weiterhin schreibgeschützt bleiben.

Die Funktionsdefinitionen wurden nach Anwendung der DEV-Migrationen geprüft. Authentifizierte End-to-End-Tests für sämtliche Schreibfunktionen sind noch ausstehend. PROD wurde nicht geändert.


## Aktueller Praxistest – Super-Admin-Kontext bleibt nach Speichern aktiv

Der Nutzer hat am 28.10.2026 in DEV bestätigt:
- Nach dem Bearbeiten und Speichern eines Spielernamens bleibt die App in der ausgewählten Mannschaft.
- Nach dem Ändern und Speichern von Trainingsdaten bleibt die App ebenfalls im ausgewählten Mannschaftskontext.
- Der aktive Kontext muss weiterhin bis zum bewussten Wechsel oder Verlassen erhalten bleiben.

Zuletzt bestätigter Frontend-Commit: `9bf1ad8e5fad169e086d0265966b15d23ac85dc2`.

Noch nicht als vollständig abgenommen gelten alle Super-Admin-Schreibfunktionen (insbesondere Anwesenheiten, Spieltag, Aktivieren/Deaktivieren/Löschen von Spielern sowie Vereins- und Mannschaftsrollen). Diese sind gezielt zu testen. PROD wurde nicht verändert.


## Praxistest: Spielerstatus und Spieltagsstatus

Der Nutzer bestätigte in DEV:
- Spieler deaktivieren funktioniert; Bestätigung erscheint und die App kehrt zur Spielerliste zurück.
- Spieler reaktivieren speicherte den Status, ließ die Spielercard aber offen, sodass die Erfolgsbestätigung erst nach manuellem Schließen sichtbar wurde.
- Spieltagsstatus konnte im Super-Admin-Kontext geändert werden.

Ursache für das abweichende Reaktivierungsverhalten: Der Erfolgszweig von `reactivatePlayer` aktualisierte Listen und zeigte eine Meldung, schloss aber nicht die geöffnete Spielercard. Das wurde durch `closeModal()` vor dem erneuten Rendern korrigiert.

Frontend-Commit: `174579788a830ef4fc442b4b9555af0b454f6ada`. Noch zu testen: Reaktivierung sollte nach Bestätigung direkt zur aktualisierten Spielerliste zurückkehren und die Erfolgsnachricht unmittelbar anzeigen. PROD unverändert.


### Nachtest bestanden: Spielerreaktivierung

Der Nutzer hat bestätigt, dass die korrigierte Reaktivierung jetzt funktioniert. Die Spielercard schließt sich nach erfolgreicher Reaktivierung, die Spielerliste wird aktualisiert und die Bestätigung erscheint direkt. Damit ist der UI-Ablauf für Deaktivierung/Reaktivierung im DEV-Praxistest bestätigt. PROD unverändert.


## Paket-Testabschluss – Stand 28.10.2026

Der Nutzer hat den folgenden Praxistest in DEV bestätigt:

- **Paket 1 – Anwesenheit und Rückmeldungen im Super-Admin-Mannschaftskontext: bestanden.** Die vorgesehenen Funktionen wurden erfolgreich getestet.
- **Paket 2 – Rollenverwaltung: derzeit nicht testbar.** Es fehlt ein geeigneter zusätzlicher Testaccount. Das ist als offene Testeinschränkung zu dokumentieren, blockiert die weitere Umsetzung aber nicht. Sobald ein passender Testaccount verfügbar ist, soll der Test nachgeholt werden.
- **Paket 3 – Vereinsadmin und Abgrenzung zwischen Mannschaften: teilweise nicht testbar.** Es gibt aktuell keine zweite Mannschaft, mit der sich der Kontextwechsel bzw. die Abgrenzung praktisch prüfen ließe. Der Vereinsadmin bleibt bis zu einer späteren fachlichen/technischen Änderung im Nur-Lese-Modus. Die fehlende zweite Mannschaft blockiert die weitere Umsetzung nicht; der Test ist nachzuholen, sobald eine geeignete Testkonstellation vorhanden ist.

PROD wurde nicht verändert.

## UX-Backlog: Schreibfunktionen für Nur-Lese-Rollen ausblenden

**Status:** Für spätere Umsetzung vorgemerkt – nicht Bestandteil des aktuellen Testabschlusses.

### Problem
Im Nur-Lese-Kontext werden Nutzern derzeit teilweise Bedienelemente angezeigt, die wie ausführbare Schreibfunktionen wirken. Teilweise lassen sie sich sogar öffnen oder betätigen, bevor die Aktion mit einer Berechtigungsfehlermeldung abgewiesen wird. Das ist irreführend: Die Oberfläche sollte die tatsächlich verfügbaren Rechte direkt widerspiegeln und Nutzer nicht erst nach einer Aktion über fehlende Schreibrechte informieren.

### Vorgesehene UX-Anpassungen
Für Rollen/Kontexte ohne Schreibrechte sollen nicht verfügbare Aktionen **gar nicht erst angezeigt** werden. Stattdessen sollen Informationen in einer Darstellung erscheinen, die optisch der bisherigen Anzeige entspricht, aber keine Bearbeitung suggeriert. Beispiele:

- Spielercard: Bearbeiten-Aktion und editierbare Eingabefelder ausblenden bzw. als reine Anzeige darstellen.
- Rückmeldungen und Anwesenheit: Dropdowns durch reine Status-/Wertanzeigen in derselben visuellen Gestaltung ersetzen.
- Aktionen wie „Alle Zusagen als anwesend markieren“ ausblenden.
- Aktionen wie „Team bilden“ ausblenden, wenn die jeweilige Rolle sie nicht ausführen darf.
- Weitere Schreibaktionen im Nur-Lese-Kontext systematisch prüfen und ausblenden, statt erst beim Ausführen einen Berechtigungsfehler zu zeigen.

### Leitlinie
Die Oberfläche muss rollen- und kontextabhängig nur die Aktionen anbieten, die der Nutzer tatsächlich ausführen darf. Serverseitige Berechtigungsprüfungen bleiben trotzdem zwingend erforderlich; das Ausblenden von UI-Elementen ersetzt keine RLS-Policies oder RPC-Prüfungen.

### Umsetzung
Nicht jetzt umsetzen. Als eigenständigen UX-/Frontend-Backlogpunkt für eine spätere Überarbeitung aufnehmen und dabei alle Bereiche des Vereinsadmin-Nur-Lese-Kontexts systematisch prüfen. Super Admins mit ausdrücklich ausgewähltem Mannschaftskontext sind davon nicht betroffen, soweit sie dort die entsprechenden Schreibrechte besitzen.


## Bestandsaufnahme vor UI-Überführung – 28.10.2026

Branch: `develop`  
Supabase: DEV (`pzazqvvoruqnqhcorbwx`)  
PROD: unverändert. Diese Bestandsaufnahme hat keine App- oder Datenbankänderungen vorgenommen.

### Vorhandene UI-Bausteine zur Wiederverwendung

- **Listenzeilen:** Die Spielerliste verwendet `.playerListRow` mit Avatar, Identität/Metadaten und Chevron. Diese Komponente bzw. ihr Markup/CSS ist der erste Ausgangspunkt für Vereins- und Mannschaftskacheln/-listen; keine separate Designwelt einführen.
- **Karten und Aktionen:** Die bestehenden `.card`, `.btn`, `.primary`, `.notice`, `.formrow` und Modal-Komponenten können für Verwaltungsübersichten, Aktionen und Eingabemasken wiederverwendet werden.
- **Navigation:** Der vorhandene „Mehr“-Bereich und die bestehende Bottom-Navigation bleiben bestehen. Vereins-/Mannschaftsverwaltung soll dort rollenabhängig einsortiert werden, statt eine zweite Navigation einzuführen.
- **Spieler-/Personendetails:** Vorhandene Spielercard und Personen-/Mitgliederlisten sind Referenz für Detailansichten und Rollenbadges.

### Bereits vorhandene Datenbank- und RPC-Grundlagen (DEV)

- Tabellen `clubs`, `teams`, `club_members`, `club_member_roles`, `team_members`, `team_member_roles` und `user_team_context` sind vorhanden.
- `select_team_context(p_team_id)` speichert einen ausgewählten Mannschaftskontext und prüft serverseitig Super-Admin- oder Vereinsadmin-Berechtigung.
- `admin_create_team(p_club_id, p_name, p_recommended_squad_size)` legt eine Mannschaft an, erstellt für den aufrufenden Benutzer Mannschaftsadmin-Zuordnungen und liefert die neue Team-ID zurück.
- `admin_add_club_member_by_email(...)` und `admin_add_club_member(...)` sind vorhanden.
- Es wurde in der Bestandsaufnahme **keine passende `admin_create_club`-RPC** gefunden. Ein neuer Verein darf deshalb nicht einfach per Frontend-INSERT angelegt werden; dafür braucht es einen bewusst entworfenen, serverseitig abgesicherten Weg.
- Die aktuelle `index.html` enthält Vereinsauswahl über `#superAdminClubSelect` und Mannschaftsauswahl über `#superAdminTeamSelect` bzw. `#clubAdminTeamSelect`. Diese Dropdowns entsprechen nicht dem bestätigten UI-Konzept und sollen durch Kachellisten ersetzt werden.

### Vor der Implementierung zu beachten

1. **Kachel-Auswahl:** Vereine und Mannschaften mit bestehenden Listen-/Kartenmustern darstellen. Ein Klick auf die Kachel bestätigt die Auswahl und führt in den gewählten Kontext; keine Dropdown-Frage als Zwischenschritt.
2. **Neue Mannschaft:** Das bestehende `admin_create_team` ist die bevorzugte Grundlage. Nach erfolgreichem Speichern die Mannschaftsliste aktualisieren und die neue Mannschaft als Kachel anzeigen; Klick darauf öffnet den Kontext.
3. **Neuer Verein:** Erst eine dedizierte, serverseitig abgesicherte Erstellfunktion und deren Berechtigungsmodell festlegen. Für Super Admins muss die Aktion zum explizit gewählten Plattform-/Verwaltungskontext passen. Keine ungeschützten direkten Schreibzugriffe aus dem Frontend hinzufügen.
4. **Super-Admin-Kontext bei Team-Erstellung:** Die vorhandene `admin_create_team` prüft aktuell `is_club_admin(p_club_id)`; diese Hilfsfunktion erkennt Super Admin global. Vor Verwendung für den neuen Kachel-Flow ist zu prüfen bzw. anzupassen, dass die Erstellaktion dem bestätigten Kontextprinzip entspricht und nicht beliebige Vereine außerhalb des bewusst ausgewählten Kontexts adressiert.
5. **Testkonstellation:** Eine neue Mannschaft kann für Paket 3 als zweite Testmannschaft dienen. Das Anlegen eines neuen Vereins ist ein separater Schritt und soll nicht automatisch Testmitgliedschaften oder Testrollen erzeugen.

### Nächster Umsetzungsschnitt

- Zuerst die vorhandene Super-Admin-Vereinsauswahl von Dropdown/Bestätigungsbutton auf Kacheln umstellen und den Klick als bewusste Auswahl verwenden.
- Danach Mannschaftsauswahl im gewählten Verein auf Kacheln umstellen und die vorhandene Kontext-RPC weiterverwenden.
- Anschließend die Mannschaftserstellung an das bestehende Eingabe-/Button-Muster anschließen, einschließlich Kontextprüfung und unmittelbarer Aktualisierung der Liste.
- Die Vereins-Erstellung erst nach Bereitstellung einer sicheren Erstell-RPC ergänzen.
- Nach jedem Schnitt in DEV testen; PROD bleibt unangetastet.


## UI-Umsetzung – Super-Admin-Vereinsauswahl als Kacheln (28.10.2026)

- In `index.html` auf `develop` wurde die bisherige Dropdown-Auswahl des Super Admins durch anklickbare Vereinskacheln ersetzt.
- Die Darstellung verwendet vorhandene Spielerliste-Komponenten und -Klassen (`.playerListRows`, `.playerListRow`, Avatar-/Identitätsbereich und Chevron), damit das UI konsistent bleibt.
- Das Antippen einer Kachel ruft die bestehende Auswahl-/Berechtigungslogik für den Verein auf. Der ausgewählte Verein wird visuell hervorgehoben.
- Die Mannschaftsauswahl wird erst nach Auswahl eines Vereins eingeblendet.
- Die vorhandene serverseitige Berechtigungsprüfung über `is_club_admin` und die bestehende Vereinsdatenanzeige bleiben bestehen.
- Verifiziert: Dropdown-Element `superAdminClubSelect` ist entfernt; `superAdminClubCards`, Kachel-Klick und nachgelagerter Mannschaftskontext sind vorhanden.
- Commit: `eaedff90b19b3825bebea03fe8718eb4a0a745f7`.
- Status: Code auf DEV aktualisiert; Live-Praxistest durch den Nutzer steht noch aus. PROD wurde nicht verändert.


## UI-Umsetzung – Vereinsdetailansicht und Einstiegskacheln (28.10.2026)

- In `index.html` auf `develop` wurde die Super-Admin-Vereinsauswahl um eine eigene Vereinsdetailansicht erweitert.
- Klick auf eine Vereinskachel öffnet nun die Detailansicht mit Vereinsname, allgemeinem Informationsbereich und zwei Einstiegskacheln: **Mannschaften** und **Vereinsmitglieder**.
- Die Detailansicht besitzt eine Rücknavigation zur Vereinsliste. Die vorherige eingeblendete Mannschaftsauswahl und das separate Vereinsverwaltungs-Panel werden beim Öffnen eines Vereins ausgeblendet, um doppelte Wege zu vermeiden.
- Die Mannschaftskachel lädt die Mannschaften des ausgewählten Vereins als Liste mit den vorhandenen `.playerListRow`-Komponenten. Klick auf eine Mannschaft nutzt die vorhandene RPC `select_team_context` und wechselt in den Mannschaftskontext.
- Die Mitgliederkachel lädt die vorhandenen Vereinsmitgliedsdaten über `get_club_members_v2` und zeigt Filter für Alle, Vereinsadmins und Trainer. Es wurden keine neuen Spieler-Login-Rollen erfunden; weitere Filter wie „Spieler“ werden anhand der vorhandenen Datenstruktur in einem späteren Schritt präzisiert.
- Vereinsstammdaten sind aktuell bewusst nur ein Platzhaltertext, bis die Felder für die Vereinsanlage definiert sind.
- Verifiziert: die neue Detailansicht, beide Einstiegskacheln, Teamlistenabfrage, Mitglieder-RPC und Rücknavigation sind im Branch vorhanden. Live-Praxistest steht noch aus.
- Commit: `a3e0f33e2621d5c072a6df4024cd54dba2a0cb1b`.
- PROD wurde nicht verändert.


## Nachtest – Teamkontext nicht mit Vereinsverwaltung vermischen (28.10.2026)

- Nutzerrückmeldung: Nach dem Öffnen einer Mannschaft wurde zusätzlich der alte Vereinsverwaltungsbereich mit Mannschafts-Kontextauswahl, Vereinsmitgliedern und „Spieler nach Mannschaft“ eingeblendet. Das widerspricht der neuen Trennung von Verein → Mannschaften / Vereinsmitglieder.
- Korrektur in `index.html`: Der Bereich `clubAdminPanel` wird im ausgewählten Mannschaftskontext jetzt ausgeblendet (`contextReadOnly` aktiv). Damit bleibt die Vereinsverwaltung in der Vereinsansicht und wird nicht zusätzlich in die Mannschafts-App eingeblendet.
- Commit: `5f06612f97e1a8f02d4a92752f99a618244ef3d2`.
- Noch durch den Nutzer zu prüfen: Mannschaft aus der Vereinskachel öffnen und kontrollieren, dass die alte Vereinsverwaltung, die zweite Kontextauswahl und „Spieler nach Mannschaft“ nicht mehr erscheinen.
- Bekannter UI-Punkt: Zurück-Navigation der neuen Detailansichten entspricht noch nicht vollständig dem Standard der übrigen App; wird als eigener Konsistenzschritt nach dem Funktionscheck angepasst.
- PROD wurde nicht verändert.


## Nachkorrektur nach Nutzerprüfung – Kontextanzeige und sichtbares „\\n“ (28.10.2026)

- Nutzer meldete, dass die vorherige Korrektur im Live-Test nicht sichtbar war und die Vereinsverwaltung weiterhin im Mannschaftskontext erschien.
- Ursache im Frontend: `loadApp()` setzte `contextReadOnly` bei jedem Laden wieder auf `false`. Das übersteuerte den gesetzten Kontextzustand, wenn der Super Admin bereits eine Mannschaftsrollen-Zuordnung hatte. Korrektur: Im bewusst geöffneten Super-Admin-Kontext bleibt `contextReadOnly` jetzt aktiv, auch wenn eine eigene Rollen-Zuordnung existiert. Damit kann die Sichtbarkeitsregel `!canManageClub || contextReadOnly` den separaten Vereinsverwaltungsbereich ausblenden.
- Zusätzlich wurde ein versehentlich als Text gerendertes literales `\\n` aus dem HTML-Markup entfernt.
- Commit: `e5f536a533cdf3d51abc098f34cb1428110b62e0`.
- Weitere UX-Anforderung für den Umbau festgehalten: Mitgliederkacheln müssen bei vorhandenen Bearbeitungsrechten anklickbar sein und eine Personendetailansicht mit den erlaubten Aktionen öffnen. Die aktuelle Mitgliederliste enthält nicht interaktive Zeilen; dies darf beim Umbau nicht unverändert übernommen werden.
- Status: Code auf DEV aktualisiert; erneuter Live-Praxistest steht aus. PROD unverändert.


## Zweite Korrektur – nachgewiesene spätere Wiedereinblendung des alten Panels (28.10.2026)

- Nutzer meldete: `\\n` entfernt, aber der alte Verwaltungsbereich blieb sichtbar.
- Erneute Quelltextprüfung ergab zwei weitere Stellen, die `clubAdminPanel` nach der vorherigen Sichtbarkeitsprüfung erneut einblendeten: den Abschluss von `loadApp()` und den `showTab('settings')`-Pfad. Diese Überschreibungen ignorierten `contextReadOnly`.
- Beide Stellen wurden angepasst, sodass das alte Vereinsverwaltungs-Panel auch dort verborgen bleibt, wenn ein Super Admin im explizit ausgewählten Mannschaftskontext arbeitet.
- Commit: `cd11e8556fe46b40b7139459b3488f23d6f8727a`.
- Der Hinweis zu nicht anklickbaren Mitgliederkacheln bleibt als Folgearbeit festgehalten: Mitgliederzeilen müssen bei zulässigen Rechten zur bearbeitbaren Personendetailansicht führen.
- Status: erneuter Live-Test ausstehend. PROD unverändert.


## UI-Folgearbeit – Mannschaftsdetail statt Sprung in die bisherige App (28.10.2026)

- Nutzerfeedback: Nach Auswahl einer Mannschaft sprang die Ansicht kurz zur Kaderplanung und anschließend zurück. Erwartet wird – analog zur Vereinsauswahl – eine eigene Detailansicht für genau die ausgewählte Mannschaft, ohne die vorherige Liste daneben.
- In `index.html` wurde der Mannschaftsklick geändert: Er setzt den ausgewählten Teamkontext per bestehender RPC, öffnet aber nicht mehr sofort `loadApp()`. Dadurch bleibt der Nutzer in der Verwaltungsnavigation und der unerwünschte Scrollsprung entfällt.
- Neue Mannschaftsdetailansicht mit Mannschaftsname, kompakter Infozeile und drei wiederverwendeten Listen-/Kachel-Einstiegen: Trainerverwaltung, Kadergröße und Positionen. Zusätzlich gibt es eine explizite Aktion „Mannschaft öffnen“ für den eigentlichen Arbeitsbereich.
- Die Einstiege zu Trainerverwaltung, Kadergröße und Positionen öffnen weiterhin die vorhandenen Settings-Komponenten und scrollen direkt zum jeweiligen Abschnitt. Dafür wurden IDs an die bestehenden Einstellungs-Cards ergänzt; keine parallelen Bearbeitungsformulare wurden neu erfunden.
- Rücknavigation: Mannschaftsdetail → Mannschaftsliste → Vereinsdetail.
- Commits: `d02e197181216e18a3b7e811f9eca8606413b0f4`, `c68f8a7eefc0388ffe444ce2f70805c4660450af`.
- Status: Code auf DEV aktualisiert; Live-Praxistest steht aus. Noch offene UX-Verdichtung: Die bestehenden Settings-Abschnitte selbst können anschließend kompakter gemacht werden, insbesondere Trainer- und Positionszeilen mit Optionsmenü. PROD unverändert.


## Korrektur nach Nutzertest – echte Unteransichten für Mannschaftseinstellungen (28.10.2026)

- Nutzer bestätigte, dass Mannschaftsdetailansicht und Rücknavigation grundsätzlich funktionieren, bemängelte aber, dass die drei Einstellungskacheln lediglich zur vollständigen bisherigen Einstellungsseite scrollten.
- Der Button „Mannschaft öffnen“ wurde aus der Mannschaftsdetailansicht entfernt. Die Mannschaftsliste und deren Zurücknavigation sind der Weg zum Wechseln der Mannschaft; der normale Arbeitsbereich bleibt über die Hauptnavigation erreichbar.
- Die Einstellungskacheln öffnen nun eine fokussierte Unteransicht innerhalb der Plattformverwaltung. Dafür wird jeweils die bestehende Einstellungs-Card in die Unteransicht verschoben (keine neue parallele Formularimplementierung); die zugehörigen bestehenden IDs und Aktionen bleiben erhalten.
- In der fokussierten Unteransicht wird nur der gewählte Bereich angezeigt: Trainerverwaltung, Kadergröße oder Positionen. Eine Zurück-Aktion bringt den Nutzer zur Mannschaftsdetailansicht.
- Commit: `49bbc92a3e396c493e00c4f50f346e041ff1fce7`.
- Status: DEV aktualisiert, Live-Test ausstehend. PROD unverändert.


## Fehlerkorrektur nach Screenrecording – Teamkontext und leere Einstellungsansicht (28.10.2026)

- Nutzer meldete, dass der Mannschaftsklick den Kontext nicht mehr wie erwartet öffnete und die Einstellungskacheln einen leeren dunklen Bildschirm zeigten.
- Ursache: Die vorherige Änderung rief `loadApp()` erst beim Öffnen einer einzelnen Einstellung auf und blendete anschließend `appView` aus. Die Einstellungskarten lagen zu diesem Zeitpunkt noch in der normalen App-Ansicht und wurden durch den Navigationszustand nicht zuverlässig sichtbar gehalten.
- Korrektur:
  - Beim Öffnen einer Mannschaft wird der ausgewählte Kontext serverseitig gesetzt und `loadApp()` einmal ausgeführt, damit die Daten und bestehenden Einstellungsfunktionen der ausgewählten Mannschaft geladen werden. Danach wird die fokussierte Mannschaftsdetailansicht wiederhergestellt.
  - Die Einstellungskacheln öffnen anschließend die bereits geladene vorhandene Einstellungs-Card, ohne einen weiteren App-Neuladevorgang auszulösen.
- Commit: `c95fdabe6c7f86f9f93a6a0304982a79a61b7b98`.
- Status: DEV aktualisiert, Live-Nachtest erforderlich. PROD unverändert.


## Sofortkorrektur – schwarzer Bildschirm durch ausgeblendeten App-Container (28.10.2026)

- Nutzer meldete nach dem letzten Fix einen schwarzen Bildschirm bereits beim Öffnen einer Mannschaft.
- Ursache im DOM: `superAdminPanel` liegt innerhalb von `appView`. Die Navigation blendete `appView` aus und versuchte anschließend, nur das darin enthaltene Panel wieder einzublenden. Ein Kind-Element kann jedoch nicht sichtbar sein, solange sein Elterncontainer ausgeblendet bleibt.
- Korrektur: `appView` bleibt sichtbar; die Navigation wechselt auf den Einstellungen-Tab und zeigt innerhalb dessen die passende Plattform-/Mannschaftsunteransicht.
- Commit: `7b108a35ebf09cb80bfbc7eefe2a7fe398737fb0`.
- Status: DEV aktualisiert, Live-Test steht aus. PROD unverändert.
