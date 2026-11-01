# AP01–AP03: Migrations- und Testzuordnung für minimales PROD-Release

**Stand:** 01.11.2026  
**Zielbranch:** `develop` in `bautnhaus/jugendmannschaft`  
**Status:** Arbeitsdokument – keine PROD-Freigabe, keine Datenbankänderung  
**Grundlage:** Live-Migrationslisten DEV/PROD, Feature-Branch-Dokumentation AP02/AP03 und Release-Katalog vom 01.11.2026.

## 1. Zielentscheidung

Das erste Multi-Verein-Release soll nur die für Vereinszuordnung, Mitgliedschaften, Rollen und sichere Verwaltungsansichten notwendigen Änderungen enthalten. Kein pauschales Kopieren von DEV nach PROD, keine Übernahme von DEV-Daten und keine erneute Ausführung historischer Kandidaten.

**Wichtige Einschränkung:** Die Supabase-Migrationsliste zeigt, welche Migrationen registriert wurden, aber sie liefert nicht den Original-SQL-Text. Für mehrere tatsächlich ausgeführte AP01–AP03-Migrationen fehlt der exakte, unverändert angewendete SQL-Text im kanonischen Repository. Solange diese Lücke nicht geschlossen ist, ist noch kein reproduzierbares PROD-Migrationspaket freigabefähig.

## 2. Live-Migrationsdelta

### PROD – registriert
- `20261022212442 ap01_migration_c_fix_player_positions_insert_policy`
- `20261022214552 ap01_players_member_permissions_cleanup_prod`
- `20261022215006 ap01_training_players_team_consistency_prod`

### DEV – AP01 / vorbereitende Konsistenz- und Berechtigungsänderungen
- `20261022195046 ap01_migration_b_revoke_unneeded_function_execute`
- `20261022213929 ap01_align_attendance_matchday_rls_with_prod`
- `20261022214357 ap01_players_member_permissions_cleanup_dev`
- `20261022214623 ap01_training_players_team_consistency_dev`
- `20261023032020 ap01_membership_helpers_revoke_anon_public_dev`

### DEV – AP02
- `20261023203742 ap02_foundation_v1_0_0_dev`
- `20261025192324 ap02_p0_team_role_cutover_dev`
- `20261025210259 ap02_club_security_and_membership_backfill_dev`
- `20261025211108 ap02_club_admin_functions_v1_dev`
- `20261025211116 ap02_club_member_cross_club_guard_dev`
- `20261025212113 ap02_club_member_add_by_email_dev`
- `20261026053205 ap02_revoke_unsafe_truncate_grants_dev`
- `20261026150017 ap02_club_member_management_and_players_dev`

### DEV – AP03 / Rollen, Sicherheit und expliziter Kontext
- `20261026210356 ap03_security_fixes_v1_dev`
- `20261026210440 ap03_security_fixes_hardening_v1_dev`
- `20261026221728 ap03_set_updated_at_search_path_hardening`
- `20261026222403 ap03_restrict_internal_team_role_helpers_dev`
- `20261026225811 ap03_restrict_log_team_role_change_execute_dev`
- `20261027051456 ap03_revoke_anon_table_access_and_truncate_dev`
- `20261027051509 ap03_restrict_trigger_function_execute_dev`
- `20261027182210 ap03_allow_super_admin_save_players_in_selected_team_dev`
- `20261028111728 role_permissions_club_read_and_team_role_history`
- `20261028112204 restrict_team_role_history_rpc_to_authenticated`
- `20261028140403 selected_team_context_read_access`
- `20261028140426 selected_team_context_reader`
- `20261028162542 selected_team_context_related_reads`
- `20261028182151 super_admin_selected_context_attendance_write`
- `20261028182424 super_admin_full_team_support_permissions`
- `20261028182444 super_admin_full_team_support_writes`
- `20261028182728 super_admin_selected_context_full_write_trigger`
- `20261028182741 super_admin_context_full_team_support_permissions`
- `20261028182749 super_admin_context_full_club_member_support`
- `20261028183552 allow_super_admin_selected_context_team_role_list`
- `20261029045927 club_team_creation_and_club_context_20261029`
- `20261029050011 club_team_creation_20261029`
- `20261029051752 add_admin_selection_to_club_and_team_creation`
- `20261029085544 admin_edit_club_and_team_details`

DEV hat zusätzlich fünf AP04-Migrationen vom 31.10.2026 für Profil/Avatar und Rollenänderungen im Vereinskontext. Sie werden nicht automatisch in den ersten Multi-Verein-Release aufgenommen.

## 3. Zuordnung nach Releasepaket

| Paket / Migrationengruppe | DEV-Nachweis | PROD-Status | SQL-Quelle im kanonischen `develop` | Releaseentscheidung |
|---|---|---|---|---|
| AP01: Berechtigungen für Spieler/Positionen/Trainingskonsistenz | DEV-Migrationseinträge vorhanden | Teilweise durch drei AP01-PROD-Einträge abgedeckt; exaktes Delta muss objektweise verglichen werden | Originalquellen AP01–AP03 nicht vollständig im aktuellen Migrationsverzeichnis | Nicht blind erneut ausführen. Exakte Definitionen/Policies und Grants DEV↔PROD vergleichen, dann idempotentes, auf PROD zugeschnittenes SQL erstellen |
| AP02 Foundation: `clubs`, `club_members`, Rollen- und Kontexttabellen | `ap02_foundation_v1_0_0_dev` registriert; Tabellen existieren in DEV, fehlen in PROD | Nicht vorhanden laut Schema-Inventar | Feature-Branch/Dokumentationspaket enthält Foundation-/Cutover-Unterlagen; exakte ausgeführte Foundation-SQL-Datei noch gegen DEV-Objekte verifizieren | Zwingender Bestandteil des Multi-Verein-Releases |
| AP02 Teamrollen-Cutover | `ap02_p0_team_role_cutover_dev` registriert; DEV hat `team_member_roles` | Nicht in PROD nachgewiesen | `feature/ap02-additive-team-roles` enthält `AP02_P0_TEAM_ROLE_CUTOVER_CANDIDATE.sql`, ausdrücklich nicht freigegeben; später ausgeführte Migration muss separat rekonstruiert/abgeglichen werden | Nur die tatsächlich angewendete und nachgeprüfte finale Variante verwenden. Historischen Kandidaten nicht ausführen |
| AP02 Mitgliedschaften/Vereinsfunktionen | Mehrere AP02-Migrationen vom 25.–26.10. registriert | Vereinsobjekte/Funktionen fehlen in PROD nach Inventar | Feature-Branch-Dokumentation und SQL-Quellen vorhanden, aber vollständige exakte Zuordnung aller registrierten Migrationen noch offen | Zwingend, soweit für Vereinsadmin, Ein-Verein-pro-Benutzer und Mitgliedsverwaltung erforderlich |
| AP03 Sicherheits-Härtungen | AP03-Migrationen vom 26.–27.10. registriert | In PROD nicht als dieselbe Migrationenfolge nachgewiesen | `feature/ap03-security-fixes` enthält u. a. `20261026210356_ap03_security_fixes_v1_dev.sql` und `20261027051456_ap03_revoke_anon_table_access_and_truncate_dev.sql` | Sicherheitskorrekturen nur nach objektweisem Diff und Prüfung der App-Abhängigkeiten übernehmen; PROD-spezifische Grants nicht blind überschreiben |
| AP03 Kontext- und Super-Admin-Support | 17+ Kontext-/Supportmigrationen vom 27.–29.10. registriert | Nicht in PROD nachgewiesen | In DEV-Migrationsliste dokumentiert; exakte Originalquellen im kanonischen Repo noch nicht vollständig belegt | Nur die für den ersten Release benötigten Kontext-/Supportfunktionen aufnehmen. UI-/RPC-Abhängigkeiten und Schreibrechte gezielt testen |
| AP04 Profil/Avatar/Rolleneditor | Fünf Migrationen vom 31.10. registriert | Nicht nachgewiesen | Fünf AP04-Dateien im aktuellen `develop`-Migrationsverzeichnis vorhanden | Standardmäßig zurückstellen; nur aufnehmen, wenn die gewählte Vereinsmitgliederoberfläche zwingend davon abhängt und Security-Advisor-Befund geklärt ist |

## 4. Relevante Quellen aus Feature-Branches

- [AP02 P0 Execution Readiness](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap02-additive-team-roles/docs/AP02_P0_EXECUTION_READINESS.md)
- [AP02 P0 Validierungsbericht](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap02-additive-team-roles/docs/AP02_P0_VALIDATION_REPORT.md)
- [AP02 P0 DEV-Testmatrix](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap02-additive-team-roles/docs/AP02_P0_DEV_TEST_MATRIX.md)
- [AP02 Cutover-Kandidat – ausdrücklich nicht freigegeben](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap02-additive-team-roles/supabase/migrations/AP02_P0_TEAM_ROLE_CUTOVER_CANDIDATE.sql)
- [AP02 Vereinsverwaltung-Testprotokoll 26.10.](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap02-club-frontend-dev/docs/AP02_TESTPROTOKOLL_2026-10-26.md)
- [AP03 Rollen-/Berechtigungsinventar](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap03-roles-permissions-inventory/docs/AP03_BESTANDSAUFNAHME_ROLLEN_BERECHTIGUNGEN_2026-10-26.md)
- [AP03 Security-Advisor-Entscheidungen](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap03-security-fixes/docs/AP03_SECURITY_ADVISOR_18_WARNINGS_DECISIONS_2026-10-27.md)
- [AP03 Sicherheitsmigration](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap03-security-fixes/supabase/migrations/20261026210356_ap03_security_fixes_v1_dev.sql)
- [AP03 Anon-/TRUNCATE-Härtung](https://github.com/bautnhaus/jugendmannschaft-dev/blob/feature/ap03-security-fixes/supabase/migrations/20261027051456_ap03_revoke_anon_table_access_and_truncate_dev.sql)

## 5. Offene Tests und Freigabeblocker

### AP02-T01 bis T07 – dokumentiert bestanden
- Vereinsadmin kann Mitgliederliste öffnen.
- Spieleranzeige und Mannschaftsfilter funktionieren.
- Vereinsrolle kann geändert und nach Neuladen verifiziert werden.
- Entfernen eines Mitglieds mit Mannschaftsrollen wird blockiert.
- Super Admin erhält keinen implizit ausgewählten Verein.
- Vereinsadmin erhält nach vorheriger Super-Admin-Sitzung keine Super-Admin-Ansicht.

Diese Tests sind historische, nutzerbestätigte DEV-Nachweise. Sie müssen nicht pauschal wiederholt werden; Regressionstests sind nur bei betroffenen Änderungen erforderlich.

### AP02-T08 bis T10 – offen
- **T08 – Fremdverein-Zugriff:** nicht praktisch getestet; DEV hatte zum Dokumentationszeitpunkt nur einen Verein. Vor PROD ist ein negativer Zugriffstest erforderlich, z. B. mit zwei isolierten Testvereinen in DEV oder einem gleichwertigen sicheren Testaufbau.
- **T09 – letzter Vereinsadmin:** Schutzlogik wurde im Code geprüft, aber nicht als echter Integrationstest bestätigt. Test mit isolierten Testkonten durchführen; der letzte Admin darf nicht herabgestuft oder entfernt werden.
- **T10 – Mitglied ohne Teamrollen entfernen:** nicht praktisch getestet, da kein entbehrliches Testkonto vorlag. Mit einem eigens dafür angelegten Testkonto prüfen; keine bestehenden Nutzerdaten zu Testzwecken löschen.

### Zusätzliche Mindestprüfungen vor PROD
1. RLS-/RPC-Negativtests mit authentifizierten Sitzungen für Super Admin, Vereinsadmin, Mannschaftsadmin und Trainer.
2. Teamrollen: additive Rollen bleiben erhalten; direkte Schreibpfade und alte RPCs können das neue Rollenmodell nicht umgehen.
3. Regression: Spieler/Positionen, Trainings, Spieltage, Anwesenheit und Kaderplanung funktionieren nach den neuen Policies unverändert.
4. Ein-Verein-pro-Benutzer: Hinzufügen zu einem zweiten Verein wird serverseitig abgelehnt.
5. Super Admin: kein impliziter Kontext; Aktionen nur im explizit ausgewählten Verein/Team.
6. Backup-/Restore-Nachweis und dokumentierter Rollback-Plan vor jeder PROD-Migration.

## 6. Gesonderter Sicherheitsblocker: AP04-Funktion

Im DEV-Release-Katalog wurde `admin_update_club_member_profile(...)` als `SECURITY DEFINER`-Funktion mit möglichem `anon EXECUTE`-Grant markiert. Da die Funktion zur AP04-Profil-/Avatar-Erweiterung gehört, wird sie nicht automatisch in den ersten Release übernommen. Vor einer Übernahme sind effektive Grants, Funktionstext und die tatsächlichen Frontend-Aufrufer zu verifizieren; falls `anon` nicht benötigt wird, muss der Grant in DEV gezielt entfernt und getestet werden.

Die dokumentierte AP03-Entscheidung zu 18 anderen `authenticated_security_definer_function_executable`-Warnungen bleibt gültig und darf nicht pauschal neu bewertet werden. Eine Warnung für eine bewusst angemeldeten Nutzern zugängliche Funktion ist nicht allein eine Schwachstelle.

## 7. Empfohlene nächste Arbeit – weiterhin ohne PROD-Änderung

1. Pro benötigtem DEV-Migrationseintrag den exakten angewendeten SQL-Inhalt bzw. die resultierenden Objektdefinitionen sichern und mit den Feature-Branch-Dateien abgleichen.
2. Für jede Tabelle, Policy, Funktion, Trigger und jedes EXECUTE-Grant die Differenz zu PROD feststellen.
3. Daraus einen neuen, geordneten und reviewbaren Release-Satz im kanonischen Repo erstellen. Keine Migration darf nur aus dem Namen des Migrationseintrags rekonstruiert werden.
4. R1 und R2 nach Abhängigkeitsreview ggf. als ein zusammenhängendes Release bündeln.
5. AP02-T08 bis T10 sowie die notwendigen Regressionstests in DEV nachweisen.
6. Erst danach Review/Freigabe des konkreten SQL-Releasepakets anfordern.

**Status:** Zuordnung erstellt, aber noch keine ausführbare PROD-Migration freigegeben. Keine Datenbank-, Frontend- oder PROD-Änderung wurde vorgenommen.
