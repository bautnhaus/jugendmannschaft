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
