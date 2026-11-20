# AP02 – gezielte Superadmin-Kontextkorrektur

**Stand:** vorbereitet, nicht ausgeführt  
**Datum:** 20.11.2026  
**Arbeitszweig:** develop  
**Zielreihenfolge:** DEV-Test und Abnahme, danach separates PROD-Paket  
**Freigabeumfang:** Erstellung dieses Korrekturpakets. Keine Datenbankausführung oder PROD-Änderung.

## Fachlich verbindliche Regeln

1. Superadmins bleiben global Superadmins und vereinsneutral.
2. Superadmin-Zugriffe auf Vereinsverwaltung sind ausschließlich im ausdrücklich ausgewählten Vereinskontext zulässig.
3. Eine zusätzliche Mannschaftsadmin- oder Trainerrolle bleibt als Datensatz erhalten.
4. Diese Mannschaftsrolle begründet für einen Superadmin keinen kontextunabhängigen Zugriff. Der eigene Superadmin-Zugriff auf ein Team wird bereits in der zentralen Funktion `is_team_admin(team_id)` ausschließlich über den ausgewählten Teamkontext geprüft. Die zusätzliche gespeicherte Teamrolle (DEV derzeit `trainer`, PROD derzeit `admin`) eröffnet keinen Bypass. Auch ein ausgewählter Vereinskontext darf bei Teamverwaltungs-RPCs den Mannschaftskontext nicht ersetzen.
5. Normale Vereinsadmins, Mannschaftsadmins und Trainer behalten ihre bisherigen Rollenrechte.
6. Keine DEV-Daten werden nach PROD übernommen.

## Live-Befund PROD (read-only, 20.11.2026)

- Ein globaler Superadmin.
- Eine direkte Zeile in `club_members`.
- Eine `club_admin`-Zuweisung in `club_member_roles`.
- Eine zusätzliche Mannschaftsadmin-Zuweisung in `team_member_roles` sowie die passende Zeile in `team_members`.
- `club_member_roles.user_id` referenziert `club_members.user_id` mit `ON DELETE CASCADE`.
- Keine weiteren Fremdschlüssel verweisen auf `club_members` oder `club_member_roles`; keine eigenen Trigger auf diesen beiden Tabellen.

## Korrekturumfang

- `can_manage_club_context(uuid)`: CASE-Priorität. Wenn der aufrufende Benutzer Superadmin ist, zählt ausschließlich `user_club_context`; die zusätzliche club_admin-Rolle darf keinen OR-Fallback eröffnen.
- Die Ein-Argument-Funktion `is_team_admin(team_id)` erzwingt für Superadmins ausschließlich den ausgewählten Mannschaftskontext; die Zwei-Argument-Funktion bleibt eine allgemeine Zielrollenabfrage.
- `admin_add_team_role` und `admin_remove_team_role` wechseln für die Aufruferprüfung auf `is_team_admin(team_id)`. Die alternative Vereinsadmin-Berechtigung über `can_manage_club_context` bleibt für Nicht-Superadmins erhalten, wird für Superadmins aber ausdrücklich ausgeschlossen. Ein ausgewählter Vereinskontext allein verleiht dem Superadmin somit keine Mannschaftsadmin-Rechte.
- Weitere Verwaltungs-/Read-RPCs wechseln auf die Ein-Argument-Prüfung: `admin_update_member_profile`, `admin_set_trainer_label`, `get_team_trainers`, `get_team_trainers_v2`.
- `is_team_admin(uuid)`: Superadmins werden vor der Rollenprüfung ausschließlich über `has_selected_team_context(team_id)` autorisiert; Nicht-Superadmins behalten die bisherige Rollenprüfung.
- `get_team_role_change_log(uuid)`: direkter Superadmin-Bypass wird an `has_selected_team_context(team_id)` gebunden.
- Die Vereinsadmin-Alternative in `admin_add_team_role` und `admin_remove_team_role` gilt ausdrücklich nur für Nicht-Superadmins; Superadmins benötigen für diese teambezogenen Schreibaktionen den ausgewählten Mannschaftskontext.
- Die Zwei-Argument-Funktion `is_team_admin(user_id, team_id)` bleibt als allgemeine Rollenabfrage für Zielbenutzer unverändert. Sie darf nicht global umgedeutet werden.

## Reversible Rollenbereinigung

Die vorbereitete DEV-Migration sichert die direkte Vereinsmitgliedschaft und alle zugehörigen Vereinsrollen in einem separaten, für Clientrollen gesperrten Schema `ap02_release_private`. Danach wird ausschließlich die Zeile aus `club_members` entfernt; die `club_admin`-Zeile wird durch den vorhandenen CASCADE-Fremdschlüssel entfernt.

Die zusätzlichen Teamrollen und Teammitgliedschaften werden weder gelöscht noch aktualisiert. Die Migration vergleicht deren vollständige Rollen-/Mitgliedschaftslisten im Postflight mit dem Snapshot. Der Snapshot bleibt bis zum Ablauf des Rollback-Fensters erhalten. Der Rollback stellt Vereinsmitgliedschaft und Vereinsrollen aus dem Snapshot wieder her und setzt die vorherigen Funktionsbedingungen zurück.

## Dateien

- Migration: `supabase/migrations/20261120120000_ap02_superadmin_context_hardening_dev.sql`
- Rollback: `supabase/rollback/20261120120000_ap02_superadmin_context_hardening_rollback_dev.sql`

Die Migration ist absichtlich streng und bricht bei abweichendem Bestand ab. Sie ist eine DEV-Fassung. Für PROD wird nach erfolgreichem DEV-Test eine separate, gegen den dann aktuellen PROD-Livebestand geprüfte Fassung erstellt. Die DEV-Migration darf nicht ungeprüft in PROD ausgeführt werden.

## Noch offene Prüfungen vor Ausführung

1. Statische Struktur- und Musterprüfung der zentralen Kontextfunktionen sowie aller neun gezielten Berechtigungstext-Ersetzungen innerhalb von sieben RPCs: bestanden. Formale PostgreSQL-/PLpgSQL-Parse- bzw. Transaktionssimulation bleibt offen.
2. DEV-Transaktionssimulation (inkl. Positiv-/Negativtests für Superadmin ohne Kontext, mit falschem Kontext und mit passendem Kontext).
3. Regression für normalen Vereinsadmin, Mannschaftsadmin und Trainer.
4. Nachweis, dass die zusätzliche Superadmin-Teamrolle unverändert bleibt.
5. Rollback-Simulation in einer kontrollierten DEV-Transaktion und Nachweis der Wiederherstellung.
6. Erst danach separate Freigabe zur tatsächlichen DEV-Ausführung.

## Status / Sicherheitsgrenze

- DEV-Live-Preflight (20.11.2026): genau ein Superadmin, eine direkte Vereinsmitgliedschaft, eine club_admin-Rolle, eine Teamrolle (`trainer`) und eine Teammitgliedschaft; der Vereinskontext ist ausgewählt, ein Teamkontext aktuell nicht; FK `club_member_roles.user_id -> club_members.user_id ON DELETE CASCADE` bestätigt; keine benutzerdefinierten Trigger auf den beiden Vereinsmitgliedschaftstabellen.
- Statische Strukturprüfung: BEGIN/COMMIT und Dollar-Quote-Delimiter ausgeglichen; neun Ersetzungs- und Rücksetzungsregeln gegen die DEV-Live-Definitionen abgeglichen; Teamrollen-Löschbefehle fehlen; Rollback-Snapshot, globale Superadmin-Identitätsprüfung und exakter Abgleich der wiederhergestellten Vereinsrollen vorhanden.
- Formale PostgreSQL-/PLpgSQL-Parse- bzw. Transaktionssimulation und Rollenmatrix bleiben offen.
- Keine SQL-Migration ausgeführt.
- Keine Rollen oder Mitgliedschaften verändert.
- Keine PROD-Änderung.
- Kein Frontend-Deploy.
- IMG-SEC-PROD bleibt bis zur AP02-Abnahme gesperrt.


## Read-only-Kontextabgleich DEV (20.11.2026)

Der aktuelle Datenbestand zeigt einen ausgewählten Vereinskontext, keinen ausgewählten Mannschaftskontext, eine zusätzliche `club_admin`-Rolle und eine zusätzliche `trainer`-Teamrolle. Nach der vorgesehenen Zielsemantik ergibt sich daraus:

- Vereinskontextzugriff: zulässig, weil der Verein ausdrücklich ausgewählt ist.
- Teamadmin-Funktion: nicht zulässig, weil kein Mannschaftskontext ausgewählt ist; die gespeicherte Trainerrolle ändert daran nichts.
- Teamrollen-Schreib-RPCs: nicht zulässig, bis die passende Mannschaft ausdrücklich ausgewählt ist.

Das ist ein read-only Abgleich der erwarteten Zielregeln mit dem aktuellen Kontextbestand, noch kein Laufzeittest der geänderten Funktionen.

## Vorgesehene DEV-Abnahmematrix (nach separater Ausführungsfreigabe)

| Rolle / Kontext | Vereinsverwaltung | Teamverwaltung / Teamrollen |
|---|---|---|
| Superadmin ohne Vereins- und Teamkontext | verweigert | verweigert |
| Superadmin mit Vereinskontext, ohne Teamkontext | im ausgewählten Verein zulässig | teambezogene Admin-RPCs verweigert |
| Superadmin mit passendem Vereins- und Teamkontext | im ausgewählten Verein zulässig | im ausgewählten Team zulässig |
| Superadmin mit Teamrolle, aber ohne Teamkontext | abhängig vom ausgewählten Vereinskontext; keine teambezogene Freigabe allein durch Teamrolle | verweigert |
| Normaler Vereinsadmin im eigenen Vereinskontext | zulässig | bisherige Vereinsadmin-Rechte bleiben erhalten |
| Mannschaftsadmin im eigenen Team | keine zusätzlichen Vereinsrechte | zulässig |
| Trainer | keine Adminrechte | keine Teamadmin-Rechte |

Zusätzlich werden Negativtests mit einem falschen bzw. fremden Teamkontext durchgeführt. Die Tests umfassen `can_manage_club_context`, `is_team_admin`, `admin_add_team_role`, `admin_remove_team_role`, `admin_update_member_profile`, `admin_set_trainer_label`, `get_team_trainers_v2` und `get_team_role_change_log`. Der Trainerzugriff auf die normale App-Funktionalität wird separat regressionsgeprüft.


## Ergänzende statische Prüfung (20.11.2026)

- Alle neun vorgesehenen alten Berechtigungsausdrücke wurden read-only gegen die aktuellen DEV-Funktionsdefinitionen abgeglichen. Jeder Ausdruck kommt in seiner jeweiligen Funktion exakt einmal vor.
- Die zentrale DEV-Ausgangsdefinition von `is_team_admin(uuid)` und `can_manage_club_context(uuid)` stimmt mit den MD5-Preflight-Werten der Migration überein.
- Die sieben betroffenen RPCs sind vorhanden. Ihre bestehenden Eigenschaften (SECURITY DEFINER, Owner, search_path und ACL) wurden read-only erfasst. Die dynamischen Ersetzungen verwenden `CREATE OR REPLACE` auf der bestehenden Funktionsdefinition, sodass die bestehenden Owner-/ACL-Einstellungen nicht absichtlich geändert werden.
- Die Migration und der Rollback prüfen jetzt zusätzlich, dass jeder zu ersetzende Ausdruck exakt einmal vorhanden ist.
- **Rollback-Prüffehler gefunden und korrigiert:** Die vorherige Rollback-Prüfung suchte nach dem nicht passenden Literal `CASE WHEN`. Sie prüft jetzt die tatsächliche Ausgabeform `WHEN public.is_super_admin() THEN EXISTS` sowie den `ELSE EXISTS`-Zweig.
- Der DEV-Datenbestand wurde erneut read-only geprüft und ist unverändert: ein Superadmin, eine direkte Vereinsmitgliedschaft, eine Vereinsadmin-Rolle, eine Mannschaftsrolle und eine Mannschaftsmitgliedschaft. FK-/Trigger-Befund unverändert.
- Keine Migration und kein Rollback ausgeführt.

### Abgrenzung der abgeschlossenen Prüfung

Diese Prüfung ist ein vollständiger statischer Quelltext-/Live-Definitionsabgleich der vorgesehenen Ersetzungen und ihrer Ausgangsbedingungen. Sie ist **keine** PostgreSQL-Ausführungssimulation und kein erfolgreicher Lauf der Migration/des Rollbacks. Eine echte Parser-/Ausführungskontrolle der PL/pgSQL-Blöcke sowie Rollenmatrix-, Transaktions- und Rollback-Praxistests bleiben vor der DEV-Ausführungsfreigabe erforderlich.


## Kontrollierte DEV-Transaktionssimulation – erfolgreich (20.11.2026)

**Umgebung:** Supabase-Projekt `Jugendmannschaft DEV`, PostgreSQL 17.6.  
**Ausführung:** tatsächliche AP02-Migration und tatsächliches AP02-Rollback innerhalb derselben expliziten Datenbanktransaktion; abschließendes `ROLLBACK`. Keine dauerhafte Datenbankänderung.

### Geprüfte Berechtigungsmatrix

| Identität / Kontext | Prüfung | Ergebnis |
|---|---|---|
| Superadmin ohne Vereinskontext | `can_manage_club_context` | verweigert |
| Superadmin mit ausgewähltem Vereinskontext, ohne Teamkontext | Vereinsverwaltung | erlaubt |
| Superadmin mit ausgewähltem Vereinskontext, ohne Teamkontext | `is_team_admin` | verweigert |
| Superadmin ohne Teamkontext | `admin_add_team_role`, `admin_remove_team_role` | verweigert |
| Superadmin ohne Teamkontext | Profil-, Trainerlabel-, Trainerlisten- und Rollenlog-RPCs | verweigert |
| Superadmin mit ausgewähltem Teamkontext | Teamadmin-Prüfung und Teamlisten/Rollenlog | erlaubt |
| Superadmin mit ausgewähltem Teamkontext | Profilaktualisierung und Trainerlabel | erlaubte Schreibpfade erreicht |
| Superadmin mit ausgewähltem Teamkontext | Teamrolle hinzufügen/entfernen | erlaubt; bestehende Adminrolle des Testziels blieb erhalten |
| Regulärer Vereinsadmin | Vereinskontext und Teamrollen-Schreib-RPCs über Vereinsadmin-Fallback | erlaubt |
| Benutzer ohne Adminrolle | Vereinskontext und Teamrollen-Schreib-RPC | verweigert |

Die Tests verwendeten ausschließlich temporäre Änderungen innerhalb der zurückgerollten Transaktion. Der reguläre Vereinsadmin-Test fügte dem Superadmin vorübergehend eine zusätzliche Teamrolle hinzu und entfernte sie wieder; die ursprüngliche Trainerrolle blieb dabei erhalten. Vor dem Rollback wurde die nur testweise erzeugte direkte Vereinsmitgliedschaft bereinigt, damit der Rollback-Preflight seine vorgesehene Konfliktsperre korrekt prüfen konnte.

### Rollback-Nachweis

- Die Migration lief vollständig bis zum Commit-Statement innerhalb der äußeren Testtransaktion.
- Das Rollback lief anschließend vollständig durch, einschließlich Wiederherstellung der direkten Vereinsmitgliedschaft und Vereinsadmin-Rolle.
- Der gesicherte Teamrollenbestand blieb unverändert.
- Das private Backup-Schema wurde durch den Rollback entfernt.
- Abschließende Assertions nach dem Rollback waren erfolgreich.

### Nachkontrolle nach Transaktionsende (read-only)

- Superadmins: 1
- direkte Vereinsmitgliedschaft: 1
- Vereinsadmin-Rolle: 1
- Superadmin-Teamrollen: 1, weiterhin `trainer`
- Superadmin-Teammitgliedschaften: 1
- ausgewählter Mannschaftskontext: keiner
- privates AP02-Backup-Schema: nicht vorhanden
- temporärer Profil-/Trainerlabel-Testwert: nicht vorhanden
- MD5 der zentralen Kontextfunktionen entspricht wieder exakt dem DEV-Ausgangsstand.

### Während der Simulation gefundene und behobene Paketfehler

1. Rollback-Preflight suchte nach einem nicht zutreffenden Literal für die CASE-Funktionsdefinition; Prüfung auf die tatsächliche Ausgabeform umgestellt.
2. Rollback-Ersetzungsprüfung erkannte beim Rollenlog den ursprünglichen Ausdruck als Teilstring des gehärteten Ausdrucks; Teilstring-Sonderfall korrekt berücksichtigt.
3. Migration und Rollback verlangen jetzt für jeden dynamischen Ersetzungsausdruck genau ein Vorkommen.

**Ergebnis:** Die kontrollierte Transaktionssimulation einschließlich Rollenmatrix und Rollback ist erfolgreich. Dies ist keine dauerhafte DEV-Migration. Eine separate Freigabe zur tatsächlichen DEV-Ausführung bleibt erforderlich.
