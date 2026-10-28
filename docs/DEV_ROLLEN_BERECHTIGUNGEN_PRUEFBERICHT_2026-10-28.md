# DEV-Prüfbericht – Rollen und Berechtigungen

**Datum:** 28.10.2026  
**Umgebung:** Supabase DEV  
**Supabase-Projekt:** `pzazqvvoruqnqhcorbwx`  
**PROD:** nicht verändert  
**Status:** Datenbankänderungen strukturell geprüft; rollenbasierte Integrationstests mit echten Nutzer-Sitzungen noch offen.

## 1. Zusammenfassung

Die freigegebenen Änderungen A und B wurden in DEV angewendet:
- Vereinsadmins erhalten zusätzliche SELECT-Rechte auf Trainings und zugehörige Anwesenheit innerhalb ihres eigenen Vereins.
- Vereinsadmins erhalten SELECT-Rechte auf die Rollenhistorie der Mannschaften ihres Vereins.
- Die Funktion `get_team_role_change_log(p_team_id)` ermöglicht berechtigten Mannschaftsadmins, Vereinsadmins und Super Admins den kontextbezogenen Abruf der Rollenhistorie.
- Eine anschließende Prüfung zeigte, dass `anon` weiterhin EXECUTE-Rechte auf die neue SECURITY DEFINER-Funktion hatte. Diese Rechte wurden entfernt; `authenticated` behält EXECUTE.
- Der vorhandene Trigger zum Schutz des Spieleraktivstatus ist vorhanden und wurde nicht verändert.

Es wurden keine Spieler- oder Mitgliedsdaten geändert. PROD wurde nicht angesprochen.

## 2. Umgesetzte Datenbankänderungen

### 2.1 Neue RLS-Policy: `trainings_select_club_admin`

Erlaubt einem Benutzer mit Rolle `club_admin` das Lesen von Trainings, wenn die zugehörige Mannschaft zum Verein gehört, in dem der Benutzer Mitglied ist.

Die bestehende Policy `trainings_select` bleibt erhalten. Die Policies für INSERT, UPDATE und DELETE wurden nicht verändert.

### 2.2 Neue RLS-Policy: `attendance_select_club_admin`

Erlaubt das Lesen von Anwesenheitsdatensätzen, wenn:
- das Training zur Mannschaft gehört,
- der referenzierte Spieler derselben Mannschaft angehört,
- der Benutzer Mitglied des zugehörigen Vereins und dort Vereinsadmin ist.

Die bestehenden INSERT-, UPDATE- und DELETE-Policies wurden nicht verändert.

### 2.3 Neue RLS-Policy: `team_role_change_log_read_club_admin`

Erlaubt Vereinsadmins, die Rollenhistorie für Mannschaften ihres eigenen Vereins zu lesen. Die bestehende Policy `team_role_change_log_read_admin` bleibt erhalten.

### 2.4 Neue Funktion: `get_team_role_change_log(uuid)`

Die Funktion:
- verlangt einen angemeldeten Benutzer und eine konkrete `p_team_id`,
- autorisiert Super Admins, Mannschaftsadmins der angegebenen Mannschaft oder Vereinsadmins des Vereins dieser Mannschaft,
- gibt ausschließlich Historieneinträge für die angegebene Mannschaft zurück,
- verwendet `SECURITY DEFINER` mit festem `search_path = pg_catalog, public`.

**Zusätzliche Absicherung:** EXECUTE wurde explizit von `PUBLIC` und `anon` entzogen und für `authenticated` erteilt. Nachkontrolle bestätigte:
- `PUBLIC EXECUTE = false`
- `anon EXECUTE = false`
- `authenticated EXECUTE = true`

Die Funktion ist damit strukturell gegen anonyme Aufrufe abgesichert. Der autorisierte Zugriff muss noch mit realen Rollen-Sitzungen getestet werden.

## 3. Prüfergebnisse – Datenbankstruktur

| Prüfung | Ergebnis | Aussage |
|---|---|---|
| SELECT-Policy für Trainings | Bestanden – Policy vorhanden | Vereinsadmin-Leseweg ist gespeichert |
| SELECT-Policy für Anwesenheit | Bestanden – Policy vorhanden | Vereinsadmin-Leseweg ist gespeichert |
| SELECT-Policy für Rollenhistorie | Bestanden – Vereinsadmin-Policy vorhanden | Vereinsbezogener Leseweg ist gespeichert |
| Bestehende Teamadmin-Historienpolicy | Bestanden – weiterhin vorhanden | Bestehender Zugriff bleibt erhalten |
| Schreib-Policies Trainings | Unverändert vorgefunden | Trainer-/Teamrechte nicht durch diese Migration geändert |
| Schreib-Policies Anwesenheit | Unverändert vorgefunden | Trainer-/Teamrechte nicht durch diese Migration geändert |
| Trigger `protect_player_active_status` | Vorhanden | Trigger wurde nicht verändert |
| Funktion `protect_player_active_status()` | Prüflogik vorhanden | Statusänderung wird abgewiesen, wenn Aufrufer kein Teamadmin ist |
| EXECUTE-Rechte neue Historienfunktion | Nach Korrektur bestanden | Nur angemeldete Rolle `authenticated` hat EXECUTE |
| Spielerbestand | 24 Datensätze: 23 aktiv, 1 inaktiv | Nur gezählt; keine Datensätze geändert |

## 4. Noch nicht durchgeführte Integrationstests

Die verfügbaren Datenbankwerkzeuge erlauben hier keine verlässlich nachgewiesenen API-Aufrufe mit echten Trainer-, Mannschaftsadmin- und Vereinsadmin-Sitzungen. Daher sind folgende Punkte **nicht als bestanden** zu markieren:

| Test | Erwartung | Status |
|---|---|---|
| Trainer versucht, Spieler zu deaktivieren | Abgewiesen | Offen – benötigt Trainer-Session |
| Trainer versucht, Spieler zu reaktivieren | Abgewiesen | Offen – benötigt Trainer-Session |
| Mannschaftsadmin aktiviert/deaktiviert Spieler | Erlaubt | Offen – benötigt Teamadmin-Session |
| Vereinsadmin liest Training des eigenen Vereins | Erlaubt | Offen – benötigt Vereinsadmin-Session |
| Vereinsadmin liest Training eines fremden Vereins | Abgewiesen | Offen – benötigt Vereinsadmin-Session und zweiten Verein |
| Vereinsadmin liest Anwesenheit im eigenen Verein | Erlaubt | Offen – benötigt Vereinsadmin-Session |
| Vereinsadmin verändert Anwesenheit | Abgewiesen | Offen – benötigt Vereinsadmin-Session |
| Vereinsadmin liest Rollenhistorie des eigenen Vereins | Erlaubt | Offen – benötigt Vereinsadmin-Session |
| Trainer liest Rollenhistorie | Abgewiesen | Offen – benötigt Trainer-Session |
| Super Admin ruft Historie für konkrete Mannschaft ab | Nur diese Mannschaft wird zurückgegeben | Noch nicht mit echter Sitzung getestet |

## 5. Kontextprüfung: Befunde und offene Risiken

### 5.1 Vereins- und Teamparameter in SECURITY DEFINER-Funktionen

Die geprüften Verwaltungsfunktionen (u. a. `get_club_members_v2`, `get_club_players`, `admin_add_club_member`, `admin_set_club_member_role`) prüfen `is_club_admin(p_club_id)`. Diese Hilfsfunktion erkennt Super Admins für jeden angegebenen Verein als berechtigt an. Das entspricht der globalen Verwaltungsrolle, sofern jede Aktion tatsächlich an einen ausdrücklich gewählten Kontext gebunden ist.

Die Datenbank kann eine rein lokale Frontend-Auswahl nicht direkt erkennen. Die Funktionen müssen deshalb einen konkreten Vereins-/Teamparameter verwenden und ihre Abfrage auf genau diesen Parameter begrenzen. Für `get_team_role_change_log` ist die Ausgabe explizit auf `p_team_id` begrenzt.

### 5.2 Spieler-Speicherfunktion

`save_player_with_positions` ist SECURITY DEFINER und erlaubt Super Admins beim Anlegen einen explizit übergebenen `p_team_id`. Bei der Bearbeitung wird die tatsächliche Teamzugehörigkeit des Spielers gelesen und ein abweichender Teamparameter abgewiesen. Die Positions-IDs werden auf Zugehörigkeit zur Mannschaft geprüft.

Das ist eine erkennbare Kontextprüfung, aber der vollständige Laufzeittest mit angemeldeten Rollen ist noch offen.

### 5.3 Mitgliedschafts- und Rollenfunktionen

Die geprüften Teamrollen-RPCs verlangen eine Mannschaftsadmin-Rolle für die konkrete Mannschaft und beschränken erlaubte Teamrollen auf `admin` und `trainer`. Die Vereinsmitgliedschafts-RPCs prüfen den angegebenen Verein über `is_club_admin(p_club_id)` und schützen die Ein-Verein-Regel. Die Funktionen wurden in dieser Runde nicht geändert.

### 5.4 Abgrenzung der Vereinsadmin-Leserechte

Die neu ergänzten Policies gelten für Trainings, Anwesenheit und Rollenhistorie. Die Rückmeldungen (`training_responses`) wurden **nicht** zusätzlich für Vereinsadmins freigegeben. Das war nicht Teil der Freigabe A/B.

## 6. Rückfallhinweis

Die Änderungen sind als Supabase-Migration `role_permissions_club_read_and_team_role_history` angewendet worden. Eine Rücknahme müsste die drei neuen Policies entfernen und die Funktion `get_team_role_change_log(uuid)` entfernen oder auf ihre vorherige Definition zurücksetzen. Die EXECUTE-Rechtekorrektur ist separat als Migration `restrict_team_role_history_rpc_to_authenticated` angewendet worden; bei einem Rollback darf die anonyme Ausführbarkeit der Funktion nicht versehentlich wiederhergestellt werden.

Vor einem Rückbau ist zu prüfen, ob die neue Funktion bereits vom Frontend verwendet wird. Ein Rollback wurde nicht ausgeführt.

## 7. Nächste Schritte

1. Geeignete DEV-Testkonten oder kontrollierte Test-Sessions für Trainer, Mannschaftsadmin, Vereinsadmin und Super Admin bereitstellen.
2. Die offenen Integrationstests aus Abschnitt 4 mit diesen Sitzungen durchführen.
3. Bei einem Fehlschlag nur die betroffene Regel korrigieren und erneut testen.
4. Erst nach erfolgreicher Abnahme mit Schritt 4 (Frontend und Navigation) fortfahren.

**Gesamtstatus:** Die freigegebenen Backend-Änderungen A und B sind angewendet und strukturell kontrolliert. Der vorhandene Spielerstatus-Trigger ist bestätigt. Die Laufzeit-Berechtigungstests sind offen; deshalb ist die Berechtigungsprüfung noch nicht vollständig abgenommen.
