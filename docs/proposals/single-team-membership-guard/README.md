# DEV-Korrekturpaket: Ein-Mannschaft-Regel und kontextbasierte Rollen

**Status:** fachlich freigegeben am 04.11.2026; diese Spezifikation und die vorbereiteten Frontend-/Edge-Quellen liegen in `develop`. Die Quellen sind noch nicht nach Supabase DEV deployed und die SQL-Migration ist noch nicht ausgeführt.  
**Stand:** 04.11.2026  
**Zielumgebung:** ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**PROD:** unverändert, nicht geändert und nicht freigegeben.

## 1. Verbindliche fachliche Regel

Die Korrektur trennt tatsächliche Mannschaftsmitgliedschaften von Verwaltungsberechtigungen:

1. Ein Benutzer darf höchstens **einer Mannschaft tatsächlich zugeordnet** sein. Die Prüfung umfasst die Tabellen `team_members` und `team_member_roles` gemeinsam.
2. Eine globale Rolle `super_admin` schließt eine Vereinsmitgliedschaft, Vereinsadminrolle oder eine Mannschaftsrolle **nicht** aus.
3. Ein Benutzer kann daher beispielsweise gleichzeitig Superadmin, Vereinsadmin eines Vereins sowie Mannschaftsadmin und Trainer derselben Mannschaft sein.
4. Ein bereits bestehendes Mannschaftsmitglied kann nachträglich zusätzlich Superadmin und/oder Vereinsadmin werden. Die vorhandene Mannschaftszuordnung und alle bestehenden Mannschaftsrollen bleiben dabei erhalten. Das Hinzufügen oder Entfernen dieser übergeordneten Rollen darf die Einträge in `team_members` und `team_member_roles` nicht löschen, ersetzen oder auf eine andere Mannschaft verschieben.
5. Superadmins und Vereinsadmins dürfen in den Mannschaften ihres ausgewählten bzw. eigenen Berechtigungsbereichs Verwaltungsaufgaben übernehmen, ohne dort jeweils als Mannschaftsmitglied eingetragen zu sein.
6. Die Ein-Mannschaft-Regel betrifft ausschließlich die Person, der eine Mannschaftsrolle tatsächlich zugeordnet wird. Sie darf nicht die Handlungsmöglichkeiten des aufrufenden Superadmins oder Vereinsadmins einschränken.
7. Ist eine Person bereits Trainer oder Mannschaftsadmin in Mannschaft A, darf sie nicht zusätzlich Mannschaft B zugeordnet werden. Sie kann in B trotzdem über einen berechtigten Verwaltungs-Kontext handeln, soweit die Rollen-/Kontextregeln das erlauben.

Die frühere Annahme, Superadmins müssten vollständig neutral und ohne Vereins-/Mannschaftsmitgliedschaften bleiben, ist durch die Nutzerentscheidung vom 04.11.2026 ausdrücklich überholt.

## 2. Was die vorbereitete Datenbankmigration macht

Datei: `migration.sql`

- Vorabprüfung: bricht ab, falls ein Benutzer bereits mehreren unterschiedlichen Mannschaften zugeordnet ist. Bestehende Daten werden nicht automatisch bereinigt.
- Ergänzt einen Index auf `team_member_roles(user_id)`.
- Legt die zentrale SECURITY-DEFINER-Triggerfunktion `public.enforce_single_team_membership()` mit festem `search_path` an.
- Setzt die Funktion als BEFORE-Trigger auf INSERT sowie Änderungen an `user_id`/`team_id` in `team_members` und `team_member_roles`.
- Die Triggerfunktion sperrt die Auth-Benutzerzeile mit `FOR UPDATE`, damit konkurrierende Schreibwege desselben Benutzers nicht gleichzeitig unterschiedliche Mannschaftszuordnungen anlegen.
- Sie prüft ausschließlich die Ein-Mannschaft-Regel. Sie weist einen Benutzer **nicht** aufgrund der globalen Rolle `super_admin` ab.
- Überarbeitet `admin_add_team_role` und `admin_create_team`, damit direkte Schreibwege dieselbe Zuordnungsregel prüfen. Ein Superadmin darf Zielperson sein, sofern er noch keiner anderen Mannschaft zugeordnet ist.
- Überarbeitet `admin_list_team_admin_candidates`: Personen mit bestehender Mannschaftszuordnung werden ausgefiltert. Ein Superadmin wird nicht allein wegen seiner globalen Rolle ausgefiltert.
- Überarbeitet `admin_complete_member_invitation`: Superadmins dürfen zusätzlich Vereinsmitglied, Vereinsadmin, Mannschaftsadmin oder Trainer werden. Die bestehende Ein-Verein- und Ein-Mannschaft-Prüfung bleibt erhalten.

Es gibt in dieser korrigierten Fassung **keinen Trigger auf `global_user_roles`**, der die spätere Vergabe der Superadmin-Rolle an ein Mannschaftsmitglied blockieren würde.

## 3. Kontextberechtigungen bleiben eigenständig

Die Live-Definitionen wurden read-only geprüft:

- `can_manage_club_context(p_club_id)`: Superadmin mit genau ausgewähltem Vereinskontext oder Vereinsadmin des betreffenden Vereins.
- `has_selected_team_context(p_team_id)`: Superadmin oder Vereinsadmin mit genau ausgewähltem Mannschaftskontext.
- `is_team_admin(p_team_id)`: tatsächlicher Mannschaftsadmin oder Superadmin mit ausgewähltem Mannschaftskontext.

Die Berechtigungsprüfungen für den handelnden Benutzer bleiben in den RPCs bestehen. Die Migration fügt keine Voraussetzung hinzu, dass der handelnde Superadmin/Vereinsadmin Mitglied jeder verwalteten Mannschaft sein muss.

### Read-only Kontextprüfung in Supabase DEV (04.11.2026)

Die Berechtigungsfunktionen wurden mit vorhandenen Benutzeridentitäten und jeweils ausgewähltem Teamkontext simuliert. In beiden Fällen hatte der handelnde Benutzer **keine tatsächliche Mitgliedschaft in der ausgewählten Mannschaft**:

- **Superadmin:** `has_selected_team_context(team_id) = true`, `can_manage_club_context(club_id) = true`, `is_super_admin() = true` und `is_team_admin(team_id) = true`.
- **Vereinsadmin:** `has_selected_team_context(team_id) = true` und `can_manage_club_context(club_id) = true`; `is_team_admin(team_id)` war erwartungsgemäß false, da diese Person nicht tatsächlich Mannschaftsadmin ist. Die Berechtigung für administrative Schreibwege ergibt sich hier aus `can_manage_club_context`.

Damit bestätigen die vorhandenen Kontextfunktionen bereits, dass Superadmins und Vereinsadmins andere Mannschaften verwalten können, ohne dort Mitglied zu sein. Dies ist ein read-only Funktions-/Kontextnachweis, kein vollständiger Frontend-Praxistest und kein schreibender Rollenänderungstest.

## 4. Einladung und Frontend

### Zentrale Einladung `invite-member`

Die aktuell live ausgeführte DEV-Edge-Function weist ein bestehendes Superadmin-Konto bislang ausdrücklich als Zielperson zurück. Die in `develop` versionierte Quelle entfernt diese Sperre. Die Vorabprüfung auf eine bereits vorhandene andere Mannschaft bleibt bestehen.

Zusammen mit der geänderten RPC `admin_complete_member_invitation` können Superadmins so auch Vereins- oder Mannschaftsrollen erhalten. Die globale Superadmin-Rolle wird nicht verändert.

### Vereinsmitglied-Dialog

Datei: `index.html` in `develop` (Quellstand aktualisiert, DEV-Deployment noch ausstehend).

- Bei der bearbeiteten Person bleiben die Rollenfelder anderer Mannschaften gesperrt, sobald diese Person bereits einer Mannschaft zugeordnet ist.
- Ein bislang nicht zugeordnetes Vereinsmitglied kann höchstens einer Mannschaft zugeordnet werden.
- Ein Mannschaftswechsel erfolgt bewusst in zwei Schritten: bisherige Rollen entfernen und speichern; anschließend erneut öffnen und der neuen Mannschaft zuordnen.
- Bereits widersprüchliche Mehrfachzuordnungen werden nicht stillschweigend verändert; der Dialog zeigt einen Hinweis und blockiert die Rollenänderung.
- Diese UI-Regel betrifft nur die tatsächliche Zuordnung der bearbeiteten Zielperson. Sie sperrt **nicht** die Arbeit des aktuellen Superadmins oder Vereinsadmins in anderen Mannschaftskontexten.
- Der unerreichbare Altaufruf `admin_add_club_member_by_email` wurde aus `saveClubMemberEditor` entfernt. Neue Konten werden weiterhin über „Mitglied einladen“ angelegt.

## 5. Alte Edge Function `invite-trainer`

Der aktuelle Frontend-Code verwendet `invite-member`; `invite-trainer` ist in DEV dennoch weiterhin ACTIVE (Version 3). Ein Lösch-/Deaktivierungswerkzeug für Edge Functions steht im verbundenen Supabase-Werkzeugbestand nicht zur Verfügung.

Vorbereitet ist daher ein Ersatz-Endpunkt, der außer OPTIONS jede Anfrage mit **410 Gone** und dem Hinweis auf `invite-member` beantwortet. Im Dashboard bleibt die Edge Function danach technisch als ACTIVE sichtbar; ihre alte Einladungsfunktionalität ist aber nicht mehr nutzbar. Die JWT-Prüfung bleibt aktiviert.

## 6. Dateien

- `migration.sql` – vollständiger SQL-Vorschlag, nicht ausgeführt.
- `after_apply_verification.sql` – rein lesende Prüfungen nach einer späteren Freigabe.
- `supabase/functions/invite-member/index.ts` – angepasste Edge-Function-Quelle in `develop`, noch nicht deployed.
- `supabase/functions/invite-trainer/index.ts` – 410-Gone-Ersatz in `develop`, noch nicht deployed.
- `index.html` – Frontend-Anpassung in `develop`, noch nicht nach DEV deployed.
- `DB_MIGRATION_LOG.md`, `DB_CHANGELOG.md`, `PROJECT_CONTEXT.md`, `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md` und `docs/AP04-profile-management.md` – Befund und fachlich korrigierter Vorschlag.

## 7. Geplante Tests nach einer Freigabe

1. Bestehendes Mitglied mit Trainerrolle in Team A kann dort weiterhin bearbeitet werden; Zuweisung zu Team B wird im UI und serverseitig abgewiesen.
2. Mannschaftsadmin aus Team A kann über seinen eigenen Team-Kontext in Team A arbeiten; keine Mitgliedschaft in Team B wird dafür angelegt.
3. Vereinsadmin kann im eigenen Vereinskontext Verwaltungsaufgaben in mehreren Teams durchführen, ohne selbst in jedem Team Mitglied zu sein.
4. Superadmin kann nach Auswahl eines anderen Team-Kontexts dort Verwaltungsaufgaben durchführen, ohne in diesem Team Mitglied zu sein.
5. Superadmin, der noch keiner Mannschaft zugeordnet ist, kann als Zielperson Vereinsadmin, Mannschaftsadmin oder Trainer werden.
6. Superadmin, der bereits einer Mannschaft zugeordnet ist, kann zusätzliche Vereinsrollen erhalten und bleibt in dieser einen Mannschaft berechtigt; eine zweite Mannschaftszuordnung wird abgewiesen.
7. Ein bestehender Mannschaftsadmin/Trainer wird nicht als Kandidat für die Anlage einer weiteren Mannschaft angeboten.
8. Ein bereits in Team A zugeordneter Benutzer wird durch `admin_create_team`, `admin_add_team_role` oder `invite-member` nicht zusätzlich Team B zugeordnet.
9. Ein bestehendes Mannschaftsmitglied erhält nachträglich die Rolle Superadmin; alle bestehenden Mannschaftszuordnungen und Teamrollen bleiben unverändert.
10. Ein bestehendes Mannschaftsmitglied erhält nachträglich die Rolle Vereinsadmin; alle bestehenden Mannschaftszuordnungen und Teamrollen bleiben unverändert.
11. Ein bestehendes Mannschaftsmitglied erhält nachträglich Superadmin und Vereinsadmin; beide zusätzlichen Rollen bleiben unabhängig von der bestehenden Mannschaftszuordnung bestehen.
12. Das Entfernen von Superadmin und/oder Vereinsadmin verändert ebenfalls keine bestehende Mannschaftszuordnung.
13. Die Einladung über `invite-member` funktioniert weiterhin für normale Konten und bestehende Superadmins.
14. Der alte Edge-Endpunkt `invite-trainer` antwortet mit HTTP 410.

## 8. Freigabe- und Ausführungsreihenfolge

1. Die freigegebene fachliche Regel gegen die aktuellen Live-Definitionen in DEV und alle betroffenen Schreibwege abschließend technisch prüfen.
2. Vollständigen finalen SQL-Text, Zielprojekt DEV, Auswirkungen und Verifikationsplan vorlegen und eine separate ausdrückliche Freigabe zur SQL-Ausführung einholen.
3. Nach dieser Ausführungsfreigabe eine finale Migrationsdatei mit realer Migrationsversion anlegen und ausschließlich in DEV ausführen.
4. Migrationsergebnis und tatsächliche Versionsnummer unmittelbar in `DB_MIGRATION_LOG.md` nachweisen; technische Objektänderungen in `DB_CHANGELOG.md` aktualisieren.
5. Trigger, Definitionen, ACLs, Index, Mehrfachzuordnungen, Erhalt bestehender Teamzuordnungen und Kontextfunktionen read-only prüfen.
6. Frontend in `develop` übernehmen und nach DEV deployen.
7. `invite-member` aktualisieren, den alten `invite-trainer`-Endpunkt auf 410 Gone umstellen und diese Supabase-Laufzeitänderungen im `SUPABASE_CHANGELOG.md` dokumentieren.
8. Security Advisor erneut prüfen und die Tests aus Abschnitt 7 durchführen.

**Fachlich freigegeben am 04.11.2026:** Rollenmodell einschließlich nachträglicher Vergabe von Superadmin und/oder Vereinsadmin an ein bestehendes Mannschaftsmitglied bei unveränderter Mannschaftszuordnung. **Technischer Status:** SQL-Vorschlag, Frontend und Edge-Function-Quellen sind in `develop` versioniert. Frontend und Edge Functions sind noch nicht nach Supabase DEV deployed; die SQL-Migration ist noch nicht ausgeführt. Für SQL-Ausführung und Deployments in DEV sind separate ausdrückliche Freigaben erforderlich. PROD bleibt unverändert.
