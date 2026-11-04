# DEV-Korrekturpaket: Ein-Mannschaft-Regel und kontextbasierte Rollen

**Status:** fachlich freigegeben; DB-DEV-009 in Supabase DEV erfolgreich ausgeführt und read-only verifiziert (Version `20261104143331`). Das Frontend ist im DEV-Spiegel synchronisiert. invite-member und invite-trainer wurden am 04.11.2026 ausschließlich in Supabase DEV auf Version 4 deployed; beide sind ACTIVE und behalten verify_jwt=true. Die Live-Quelltexte stimmen bytegenau mit develop überein. Browser-/Rollen-Praxistests stehen noch aus. PROD ist unverändert. Der Login-/Kontextstart für Vereinsadmins mit zusätzlicher Mannschaftsrolle wurde im Frontend-Commit `81f9ca9cc0294177e89910b0b8ffa158bdc02c44` korrigiert und nach DEV gespiegelt; Praxistest noch offen.  
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

## 2. Umgesetzte Datenbankmigration

Ausgeführt: `supabase/migrations/20261104143331_db_dev_009_single_team_membership_guard.sql` (Version `20261104143331`). Konzeptentwurf: `docs/proposals/single-team-membership-guard/migration.sql`.

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

**Ausführung und Read-only Nachprüfung (04.11.2026):** Supabase meldete `success: true`; Migrationshistorie bestätigt Version `20261104143331`. Beide Trigger sind vorhanden und aktiviert, der Index ist vorhanden, und die Mehrfachzuordnungsprüfung über beide Teamtabellen ergibt 0 Benutzer. Die vier angepassten RPCs wurden mit festem Suchpfad und den erwarteten EXECUTE-Rechten zurückgelesen. RLS-Policies wurden nicht geändert. Der vollständige Nachweis steht in `DB_MIGRATION_LOG.md` (DB-MIG-2026-003) und `DB_CHANGELOG.md` (DB-DEV-009). Die Security-/Performance-Advisor-Hinweise sind dort ebenfalls zusammengefasst.

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

Datei: `index.html` in `develop`; nach dem Push ist der DEV-Spiegel `jugendmannschaft-dev/main` mit identischem Blob-SHA synchronisiert. Manuelle Frontend-Prüfung noch offen.

- Bei der bearbeiteten Person bleiben die Rollenfelder anderer Mannschaften gesperrt, sobald diese Person bereits einer Mannschaft zugeordnet ist.
- Ein bislang nicht zugeordnetes Vereinsmitglied kann höchstens einer Mannschaft zugeordnet werden.
- Ein Mannschaftswechsel erfolgt bewusst in zwei Schritten: bisherige Rollen entfernen und speichern; anschließend erneut öffnen und der neuen Mannschaft zuordnen.
- Bereits widersprüchliche Mehrfachzuordnungen werden nicht stillschweigend verändert; der Dialog zeigt einen Hinweis und blockiert die Rollenänderung.
- Diese UI-Regel betrifft nur die tatsächliche Zuordnung der bearbeiteten Zielperson. Sie sperrt **nicht** die Arbeit des aktuellen Superadmins oder Vereinsadmins in anderen Mannschaftskontexten.
- Der unerreichbare Altaufruf `admin_add_club_member_by_email` wurde aus `saveClubMemberEditor` entfernt. Neue Konten werden weiterhin über „Mitglied einladen“ angelegt.

### Vergabe der übergeordneten Rollen

- **Vereinsadmin:** Die vorhandene Funktion `admin_set_club_member_role` ergänzt oder entfernt `club_admin` in `club_member_roles`. Sie löscht oder ändert keine Datensätze in `team_members` oder `team_member_roles`. Damit kann ein bestehendes Mannschaftsmitglied Vereinsadmin werden und seine Mannschaftszuordnung behalten.
- **Superadmin:** Die Live-Tabelle `global_user_roles` ist für `authenticated` nur lesbar; direkte INSERT-/UPDATE-/DELETE-Rechte sind nicht vergeben. In den geprüften öffentlichen Datenbankfunktionen wurde kein Schreibweg zum Vergeben der globalen Superadmin-Rolle gefunden. Die Hochstufung wird durch die Ein-Mannschaft-Trigger nicht blockiert, ist aber aktuell kein Ablauf im Vereinsmitglied-Dialog. Dafür ist ein gesonderter, privilegierter und sicher freizugebender Vergabeprozess nötig. Eine UI/RPC für die globale Superadmin-Verwaltung ist nicht Teil dieses Korrekturpakets.


## 5. Alte Edge Function invite-trainer

Der Frontend-Code verwendet ausschließlich invite-member. Die alte Edge Function bleibt aus Gründen der Nachvollziehbarkeit technisch ACTIVE, ist aber seit dem DEV-Deployment am 04.11.2026 in Version 4 nur noch ein Legacy-Ersatzendpunkt.

- OPTIONS-Anfragen werden für CORS beantwortet.
- Jede Nicht-OPTIONS-Anfrage erhält HTTP **410 Gone** und den Hinweis auf invite-member.
- verify_jwt bleibt aktiviert.
- Die alte Einladungslogik ist damit nicht mehr ausführbar.

## 6. Dateien

- `supabase/migrations/20261104143331_db_dev_009_single_team_membership_guard.sql` – tatsächlich in Supabase DEV ausgeführte Migration.
- `migration.sql` – Konzept-/Review-Entwurf der Migration.
- `after_apply_verification.sql` – rein lesendes Verifikationsskript; nach Ausführung in DEV verwendet.
- `supabase/functions/invite-member/index.ts` – angepasste Quelle in `develop` und in Supabase DEV deployed (Version 4, JWT aktiv).
- `supabase/functions/invite-trainer/index.ts` – 410-Gone-Ersatz in `develop` und in Supabase DEV deployed (Version 4, JWT aktiv).
- `index.html` – Frontend-Anpassung in `develop`, bereits in den DEV-Spiegel synchronisiert; Browser-/Praxistest offen.
- `DB_MIGRATION_LOG.md`, `DB_CHANGELOG.md`, `PROJECT_CONTEXT.md`, `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md` und `docs/AP04-profile-management.md` – Befund und fachlich korrigierter Vorschlag.

## 7. Noch ausstehende funktionale Tests

1. Bestehendes Mitglied mit Trainerrolle in Team A kann dort weiterhin bearbeitet werden; Zuweisung zu Team B wird im UI verhindert. **UI-Negativtest bestanden (04.11.2026):** Das Einladungsformular stoppt bereits Vereinsmitglieder; der Bearbeitungsdialog deaktiviert die Rollenfelder einer anderen Mannschaft. Die read-only Datenprüfung bestätigt weiterhin genau eine Mannschaftszuordnung und 0 Mehrfachzuordnungen. Der serverseitige Negativpfad wurde durch diesen UI-Test nicht aufgerufen und bleibt als eigener Laufzeittest offen.
2. Mannschaftsadmin aus Team A kann über seinen eigenen Team-Kontext in Team A arbeiten; keine Mitgliedschaft in Team B wird dafür angelegt.
3. Vereinsadmin kann im eigenen Vereinskontext Verwaltungsaufgaben in mehreren Teams durchführen, ohne selbst in jedem Team Mitglied zu sein.
4. Superadmin kann nach Auswahl eines anderen Team-Kontexts dort Verwaltungsaufgaben durchführen, ohne in diesem Team Mitglied zu sein.
5. Superadmin, der noch keiner Mannschaft zugeordnet ist, kann als Zielperson Vereinsadmin, Mannschaftsadmin oder Trainer werden. **Teiltest bestanden (04.11.2026):** Ein bestehender, bestätigter Superadmin wurde als Trainer in genau einer Mannschaft zugeordnet; globale Superadmin-Rolle blieb erhalten. Die weiteren Zielrollen sind noch offen.
6. Superadmin, der bereits einer Mannschaft zugeordnet ist, kann zusätzliche Vereinsrollen erhalten und bleibt in dieser einen Mannschaft berechtigt; eine zweite Mannschaftszuordnung wird abgewiesen.
7. Ein bestehender Mannschaftsadmin/Trainer wird nicht als Kandidat für die Anlage einer weiteren Mannschaft angeboten.
8. Ein bereits in Team A zugeordneter Benutzer wird durch `admin_create_team`, `admin_add_team_role` oder `invite-member` nicht zusätzlich Team B zugeordnet.
9. Ein bestehendes Mannschaftsmitglied erhält nachträglich die Rolle Superadmin; alle bestehenden Mannschaftszuordnungen und Teamrollen bleiben unverändert.
10. Ein bestehendes Mannschaftsmitglied erhält nachträglich die Rolle Vereinsadmin; alle bestehenden Mannschaftszuordnungen und Teamrollen bleiben unverändert. **Teiltest bestanden (04.11.2026):** Bestehender Superadmin wurde zusätzlich Vereinsadmin; globale Superadmin-Rolle und Trainerrolle in der bisherigen Mannschaft blieben erhalten, genau eine Mannschaftszuordnung. Die unmittelbare Aktualisierung der sichtbaren Mitgliederliste nach Speichern ist separat in Abschnitt 16 der Release-Dokumentation nachzubesten.
11. Ein bestehendes Mannschaftsmitglied erhält nachträglich Superadmin und Vereinsadmin; beide zusätzlichen Rollen bleiben unabhängig von der bestehenden Mannschaftszuordnung bestehen.
12. Das Entfernen von Superadmin und/oder Vereinsadmin verändert ebenfalls keine bestehende Mannschaftszuordnung.
13. Die aktualisierte invite-member-Version ist in DEV deployed und der Live-Quelltext entspricht develop. **Teiltest bestanden (04.11.2026):** Ein bestehendes, bestätigtes Superadmin-Konto wurde als Trainer zugeordnet; Datenbankprüfung bestätigt unveränderte Superadmin-Rolle und genau eine Mannschaftszuordnung. Weitere Rollenfälle bleiben offen.
14. Der alte Edge-Endpunkt invite-trainer ist in DEV auf Version 4 deployed; der Live-Quelltext enthält HTTP 410. Ein authentifizierter Request-Level-Test steht noch aus.
15. Ein Vereinsadmin mit zusätzlicher Mannschaftsrolle startet zuerst in der Vereinsverwaltung; ein ausdrücklich ausgewählter Teamkontext überschreibt eine Mitgliedschaft in einer anderen Mannschaft. Frontend-Fix am 04.11.2026 in DEV deployed; manueller Browser-Test steht noch aus.

## 8. Freigabe- und Ausführungsreihenfolge

1. Fachliches Rollenmodell und technische Umsetzung read-only prüfen. **Erledigt.**
2. DB-DEV-009 versionieren, separat freigeben und ausschließlich in DEV ausführen. **Erledigt; Version 20261104143331.**
3. Migrationsergebnis, ACLs, Trigger, Index und Datenintegrität nachprüfen und dokumentieren. **Erledigt; DB-MIG-2026-003.**
4. Frontend in develop übernehmen und mit dem DEV-Spiegel abgleichen. **Erledigt; Blob-SHA identisch.**
5. invite-member aktualisieren und invite-trainer auf 410 Gone umstellen. **Erledigt; beide DEV-Funktionen Version 4, JWT-Prüfung aktiv.**
6. Deployment-Metadaten und Live-Quelltexte zurücklesen und in SUPABASE_CHANGELOG.md dokumentieren. **Erledigt; Live-Quellen bytegenau mit develop identisch.**
7. Browser-/Rollen-Praxistests sowie Einladung eines bestehenden Superadmins durchführen. **Offen.**

**Status am 04.11.2026:** Datenbankmigration DB-DEV-009 ausgeführt und read-only verifiziert. Frontend im DEV-Spiegel synchronisiert. Beide Edge Functions in Supabase DEV auf Version 4 deployed, ACTIVE, verify_jwt=true; Live-Quellen stimmen bytegenau mit develop überein. Die funktionalen Praxistests bleiben offen. PROD ist unverändert.
