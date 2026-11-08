# E05 – Freigabe- und Ausführungsprotokoll Paket 4

## Paket 4: Spieltagszuordnung und Ableistung von Sperren

- **Erstellt:** 08.11.2026
- **Branch:** `develop`
- **Zielumgebung:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`
- **SQL-Datei:** [E05_PAKET_04_SPIELTAG_ZUORDNUNG_UND_ABLEISTUNG_2026-11-08.sql](https://github.com/bautnhaus/jugendmannschaft/blob/develop/docs/E05_PAKET_04_SPIELTAG_ZUORDNUNG_UND_ABLEISTUNG_2026-11-08.sql)
- **Status:** Freigabekandidat; nicht ausgeführt
- **Abhängigkeiten:** Pakete 1–3; vorhandene Tabellen `training_suspensions` und `training_suspension_audit`.

## 1. Ziel

Paket 4 verbindet offene gelbe/rote Sperren mit konkreten relevanten Spieltagen und bildet ihre Ableistung ab. Eine Sperre wird ausschließlich dann als abgeleistet markiert, wenn der zugeordnete Spieltag tatsächlich den Status `done` erreicht hat und die serverseitige Ableistungs-RPC erfolgreich ausgeführt wird.

## 2. Spielarten-Konfiguration

Die fachlich beschlossene Hierarchie wird umgesetzt:

1. Ein vollständiger Team-Override ersetzt die Club-Standardliste.
2. Ohne Team-Override gilt die Club-Standardliste.
3. Ein explizit leerer Team-Override bedeutet: Für dieses Team ist keine Spielart sperrenrelevant.
4. Fehlt eine Club-Konfiguration, wird keine Spielart automatisch als relevant angenommen. Die Club-Standardliste muss zuerst gesetzt werden.

Zulässige Spielarten sind exakt `Meisterschaft`, `Freundschaftsspiel` und `Turnier`.

Dazu werden die Tabellen `club_suspension_settings`, `team_suspension_game_type_settings` und `team_suspension_game_types` angelegt.

Konfigurations-RPCs:
- `set_club_suspension_game_types(p_club_id uuid, p_game_types text[])`: Club-Admin bzw. Superadmin im ausgewählten Clubkontext.
- `set_team_suspension_game_types(p_team_id uuid, p_override_enabled boolean, p_game_types text[])`: berechtigte Teamrolle bzw. berechtigter ausgewählter Teamkontext. `p_override_enabled=false` entfernt den Team-Override und aktiviert wieder die Club-Standardliste.

## 3. Zuordnung offener Sperren

RPC: `public.assign_next_suspension_matchday(p_team_id uuid, p_player_id uuid) returns integer`

- Prüft die Team-Berechtigung serverseitig.
- Berücksichtigt nur offene Sperren des Spielers im angegebenen Ursprungsteam.
- Berücksichtigt nur Spieltage derselben Saison.
- Berücksichtigt nur zukünftige Spieltage mit Status `planned` und einer nach Club-/Teamkonfiguration relevanten Spielart.
- Absagen werden übersprungen; ein verschobener Spieltag bleibt bis zur tatsächlichen Durchführung ein geplanter Spieltag.
- Mehrere offene Sperren werden nacheinander zugeordnet: gelb vor rot, danach chronologisch.
- Pro Spieler wird höchstens eine Sperre je Spieltag zugeordnet.
- Änderungen werden mit Vorher-/Nachherwerten und Systemgrund auditiert.
- Ist ein bereits zugeordneter Spieltag schon `done`, muss zuerst die Ableistungs-RPC ausgeführt werden. Die Zuordnung überspringt ihn nicht stillschweigend.
- Historische bediente, abgelaufene oder stornierte Sperren werden nicht geändert.

Die RPC ordnet alle offenen Sperren eines Spielers in einem konsistenten Schritt neu zu. So wird eine rote Sperre nicht vor einer offenen gelben Sperre eingeplant.

## 4. Ableistung nach tatsächlichem Spieltag

RPC: `public.serve_matchday_suspensions(p_matchday_id uuid) returns integer`

- Nur ein existierender Spieltag mit Status `done` kann Sperren bedienen.
- Die Spielart muss gemäß Club-/Teamkonfiguration relevant sein.
- Nur offene Sperren, die genau diesem Spieltag zugeordnet sind, werden berücksichtigt.
- Gelb wird vor rot bedient; eine spätere Sperre kann keine ältere offene Sperre überspringen.
- Die Sperre erhält Status `served`, Spieltags-ID, Datum, Gegner und Zeitstempel.
- Jeder Zustandswechsel erhält einen Audit-Eintrag.
- Nach der Ableistung werden verbleibende offene Sperren des Spielers unmittelbar neu zugeordnet.
- Nominierungen und tatsächliche Einsätze werden nicht geändert. Eine Ausnahme ist keine Ableistung und wird in einem Folgepaket umgesetzt.

Die App bzw. der serverseitige Matchday-Abschluss muss `serve_matchday_suspensions` nach erfolgreichem Wechsel des Spieltags auf `done` aufrufen. Ein bloßes Datum oder ein geplanter Spieltag reicht nicht aus.

## 5. Sicherheit und Datenintegrität

- Alle Schreibvorgänge laufen über SECURITY-DEFINER-RPCs mit festem `search_path`.
- EXECUTE wird ausschließlich an `authenticated` vergeben; `anon` und PUBLIC erhalten keine Ausführungsrechte.
- Direkte Schreibrechte auf Konfigurationstabellen werden nicht vergeben.
- Audit-Änderungen erfolgen innerhalb derselben Transaktion wie die Zustandsänderung.
- Ein Fehler beim Audit-INSERT rollt den gesamten Vorgang zurück.
- Sperrenhistorien werden nicht gelöscht.
- Die bestehenden Rollen-/Kontextprüfungen werden serverseitig verwendet.
- Keine Änderung an PROD.

## 6. Bewusste Abgrenzung

Nicht Teil dieses Pakets: Sperrausnahmen für einen konkreten Spieltag und sofortiges Weiterschieben, manuelle Sperrenkorrektur, Saisonabschluss, vorzeitiger Sperrausgleich, Korrektur/Storno/Wiederherstellung eines bereits sperrauslösenden Ereignisses sowie Frontend-Anbindung und automatische Auslösung beim Statuswechsel auf `done`. Diese Themen bleiben Folgepakete.

## 7. Prüfplan nach Freigabe

1. Tabellen, Constraints, RLS, Policies und ACLs der Spielarten-Konfiguration.
2. Club-Standard setzen und Team-Override vollständig darüberlegen.
3. Team-Override entfernen und Club-Standard wieder wirksam.
4. Leerer Team-Override führt zu keiner relevanten Spielart.
5. Fehlende Club-Konfiguration führt zu keiner stillschweigenden Standardannahme.
6. Zuordnung berücksichtigt ausschließlich passende Team-/Saison-Spieltage mit Status `planned`.
7. Abgesagte und nicht relevante Spieltage werden übersprungen.
8. Gelbe Sperre wird vor roter Sperre zugeordnet; pro Spieler nur eine Sperre pro Spieltag.
9. Status `planned` oder `cancelled` kann keine Sperre bedienen.
10. Status `done` auf relevanter Spielart bedient nur die genau zugeordneten offenen Sperren.
11. Nach Ableistung wird die nächste offene Sperre dem nächsten passenden Spieltag zugeordnet.
12. Sperre und Audit sind atomar; ein erzwungener Auditfehler muss alle Änderungen zurückrollen.
13. Unberechtigte Aufrufe, falsches Team, falsche Saison und nicht relevante Spielart werden abgewiesen.
14. Regression: Nominierungen und `matchday_players.played` bleiben unverändert.

Tests werden in DEV mit zurückrollbaren Transaktionen ausgeführt. Testdaten dürfen nicht dauerhaft verbleiben.

## 8. Ausführungsstatus

Noch nicht ausgeführt. Nach ausdrücklicher Nutzerfreigabe wird das SQL-Paket in Supabase DEV ausgeführt. Anschließend werden Struktur-, Berechtigungs-, Positiv-, Negativ-, Grenz- und Rollbacktests durchgeführt und die tatsächlichen Ergebnisse hier dokumentiert.
