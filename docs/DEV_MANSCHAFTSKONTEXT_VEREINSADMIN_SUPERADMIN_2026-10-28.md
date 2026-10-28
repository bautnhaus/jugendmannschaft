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
