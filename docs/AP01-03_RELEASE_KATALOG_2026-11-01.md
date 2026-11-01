# Release-Katalog AP1–AP3 – Multi-Verein-Grundlage

**Stand:** 01.11.2026  
**Arbeitsbranch:** `develop` in `bautnhaus/jugendmannschaft`  
**DEV:** Supabase `pzazqvvoruqnqhcorbwx`  
**PROD:** Supabase `qdugtpzgefpswnnqbusd`  
**Status:** Arbeitsentwurf auf Basis einer read-only Bestandsprüfung. Keine Datenbank-, Frontend- oder PROD-Änderung durch dieses Dokument.

## 1. Ziel und Release-Prinzip

Die Multi-Verein-Funktion soll in einem möglichst kleinen, zusammenhängenden und reproduzierbaren Release nach PROD gelangen. Bestehende Mannschaftsfunktionen müssen erhalten bleiben. DEV-Daten werden nicht nach PROD kopiert. Migrationen werden nicht blind ausgeführt und nicht allein aufgrund ihrer Namen als freigegeben betrachtet.

**Vorgeschlagener Zielumfang für das erste Multi-Verein-Release:**
- AP1: Verein als zusätzliche Datenebene einschließlich der für die Vereinsverwaltung tatsächlich verwendeten Stammdaten.
- AP2: Vereinsmitgliedschaften und vereinbarte Vereinsrollen.
- AP3: nur diejenigen Rollen-, RLS-, RPC-, Trigger- und Kontextregeln, die AP1/AP2 sicher und funktional nutzbar machen.
- Bestehende Teamrollen und die bisherigen Trainings-, Spieltags-, Anwesenheits-, Spieler- und Kaderfunktionen bleiben kompatibel.
- AP4-Profil-/Avatar-Funktionen, vollständige Spielerhistorie (AP4 im ursprünglichen Konzept), umfassende Saisonhistorie (AP5) und weitergehender Mannschaftsauswahl-Komfort (AP6) werden nicht automatisch mit aufgenommen. Ihre tatsächlichen Frontend-Abhängigkeiten müssen vor der endgültigen Scope-Freigabe geprüft werden.

## 2. Verifizierter Ausgangsstand

### 2.1 Supabase-Schema

Read-only-Abgleich am 01.11.2026:

| Merkmal | DEV | PROD |
|---|---:|---:|
| Tabellen im Schema `public` | 27 | 19 |
| In DEV, nicht PROD vorhandene Tabellen | 8 | – |
| In PROD, nicht DEV vorhandene Tabellen | 0 | – |
| Dokumentierte Migrationen in der Supabase-Migrationsliste | 42 | 3 |

DEV-exklusive Tabellen:
- `public.clubs`
- `public.club_members`
- `public.global_user_roles`
- `public.club_member_roles`
- `public.team_member_roles`
- `public.team_role_change_log`
- `public.user_team_context`
- `public.user_club_context`

Zusätzliche DEV-Spalten:
- `public.teams.club_id`
- `public.teams.birth_cohorts`
- `public.teams.abbreviation`
- `public.profiles.avatar_url`

Der Vergleich zeigt einen erheblichen Strukturunterschied, aber nicht automatisch, dass jede DEV-Änderung in PROD benötigt wird. Unterschiedliche Datensätze und Zählwerte zwischen DEV und PROD sind erwartbar und kein Anlass, DEV-Daten zu übertragen.

### 2.2 Migrationsnachweis / wichtigste AP1–AP3-Einträge in DEV

Die aktuelle Supabase-Migrationsliste enthält folgende Einträge. Die Eintragsnamen sind Inventarhinweise, keine Freigabe und kein Ersatz für den exakten SQL-Text.

**AP1 / Vorarbeiten und Datenkonsistenz**
- `20261022195046 ap01_migration_b_revoke_unneeded_function_execute`
- `20261022213929 ap01_align_attendance_matchday_rls_with_prod`
- `20261022214357 ap01_players_member_permissions_cleanup_dev`
- `20261022214623 ap01_training_players_team_consistency_dev`
- `20261023032020 ap01_membership_helpers_revoke_anon_public_dev`

**AP2 – Vereinsmitgliedschaften**
- `20261023203742 ap02_foundation_v1_0_0_dev`
- `20261025192324 ap02_p0_team_role_cutover_dev`
- `20261025210259 ap02_club_security_and_membership_backfill_dev`
- `20261025211108 ap02_club_admin_functions_v1_dev`
- `20261025211116 ap02_club_member_cross_club_guard_dev`
- `20261025212113 ap02_club_member_add_by_email_dev`
- `20261026053205 ap02_revoke_unsafe_truncate_grants_dev`
- `20261026150017 ap02_club_member_management_and_players_dev`

**AP3 – Sicherheit, Rollen und Kontext**
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

Hinweis: Die DEV-Liste enthält weitere fünf AP04-Migrationen (Profil/Avatar und Rollenänderungen im Vereinskontext). Diese sind vorerst nicht automatisch Teil des AP1–AP3-Katalogs; Frontend-Abhängigkeiten werden separat geprüft.

### 2.3 PROD-Migrationsliste

PROD führt derzeit diese drei Migrationen:
- `20261022212442 ap01_migration_c_fix_player_positions_insert_policy`
- `20261022214552 ap01_players_member_permissions_cleanup_prod`
- `20261022215006 ap01_training_players_team_consistency_prod`

Die PROD-Migrationsliste entspricht nicht der DEV-Liste. Die gleichen Zeitstempel oder Namen dürfen nicht als ausreichender Beleg für Schema-Parität gelten.

### 2.4 Versionierte SQL-Quellen

Im aktuellen `develop`-Repository liegen unter `supabase/migrations/` nur fünf versionierte Dateien, alle mit AP04-Präfix. Die konkreten SQL-Quellen der oben aufgeführten AP1–AP3-Migrationen sind dort derzeit nicht vollständig abgelegt.

**Das ist ein Release-Blocker für die Reproduzierbarkeit, nicht automatisch ein Hinweis auf fehlerhafte Datenbankstrukturen.** Vor einer PROD-Übernahme müssen die exakten angewendeten DDL-/Policy-/Funktionsdefinitionen aus DEV ausgelesen, gegen die geplante Migration geprüft und als versionierte, reviewbare Release-Dateien abgelegt werden. Vorhandene PROD-Objekte müssen in jeder Migration berücksichtigt werden, um doppelte oder inkompatible Änderungen zu vermeiden.

## 3. AP0 – nur die tatsächlich offenen Abschlussarbeiten

AP0 wird nicht neu gestartet. Folgende Restpunkte sind aus dem aktuellen Nachweisstand offen:

1. **SQL-Quellen reproduzierbar machen:** Fehlende AP1–AP3-Migrationsquellen rekonstruieren/abgleichen und versioniert im kanonischen Repository ablegen.
2. **Schema-/Sicherheitsdelta finalisieren:** Für die betroffenen Objekte tatsächliche Definitionen aus DEV und PROD vergleichen – mindestens Tabellen/Spalten/Constraints/FKs, RLS-Policies, Funktionen inklusive `SECURITY DEFINER` und `search_path`, EXECUTE-Grants und Trigger.
3. **Backup/Restore-Nachweis:** Aktuellen, zur Verfügung stehenden Sicherungsweg dokumentieren und belegen, dass vor PROD ein Wiederherstellungspfad vorhanden ist. Ein vorhandenes JSON-Exportfeature allein gilt nicht als Datenbank-Backup oder getesteter Restore.
4. **Security-Advisor-Befunde bewerten:** DEV meldet u. a. einen SECURITY DEFINER-Endpunkt `admin_update_club_member_profile(...)`, der laut Advisor auch für `anon` ausführbar ist. Das muss fachlich bewertet und – falls nicht beabsichtigt – in DEV korrigiert und verifiziert werden. Weitere Advisor-Warnungen sind nach Rolle und Absicht zu klassifizieren, nicht pauschal zu ignorieren oder blind zu entfernen.
5. **Rollenintegrationstest abschließen:** Dokumentierte Testberichte nennen echte Integrationstests mit authentifizierten Sitzungen für Vereinsadmin, Mannschaftsadmin, Trainer und Super Admin noch als offen. Die Release-relevanten positiven und negativen Fälle müssen vor PROD nachgewiesen werden.
6. **Datenintegrität für Release-Objekte prüfen:** Verein↔Mannschaft, Mitgliedschaften, Rollen, Teamzugehörigkeiten und die für bestehende Funktionen benötigten Fremdschlüssel/Constraints validieren. Unklare historische Saisonbezüge werden nicht automatisch aufgefüllt.

Abgeschlossen und nicht erneut von vorn zu bearbeiten: grundlegende Architektur-/Rollenkonzeption, vorhandene Dokumentation zu AP02/AP03, dokumentierter Branch-/Deployment-Ablauf und bereits durchgeführte strukturelle Prüfungen. Nur dort nachprüfen, wo der aktuelle Stand oder ein konkreter Release-Blocker es verlangt.

## 4. Vorgeschlagene Release-Pakete

### Paket R0 – AP0-Restpunkte (keine Produktivänderung)
**Ziel:** Nachvollziehbare Release-Basis herstellen.
- SQL-Quellen und aktuelle Objektdefinitionen abgleichen.
- Relevante Advisor-Befunde klassifizieren.
- Backup-/Restore-Plan nachweisen.
- Minimalen Testplan für AP1–AP3 finalisieren.
- Ergebnis: versionierter Release-Katalog und Review-fähige Migrationen.

### Paket R1 – AP1: Verein-/Mannschaftsgrundlage
**Ziel:** Verein als zusätzliche Ebene ohne Bruch bestehender Teamfunktionen.
- `clubs`-Schema einschließlich nur der tatsächlich benötigten Stammdatenfelder.
- `teams.club_id` mit geprüftem Backfill, FK/Constraint und Integritätskontrollen.
- Nur notwendige Policies und Hilfsfunktionen; keine Vereinsmitgliedschafts-UI ohne zugehörige AP2/AP3-Sicherung.
- Regression für Spieler, Positionen, Trainings, Spieltage, Anwesenheit und Kaderplanung.
- Freigabe erst nach Datenintegritätsprüfung.

### Paket R2 – AP2 + erforderlicher Teil von AP3
**Ziel:** Vereinsmitgliedschaften und Vereinsrollen sicher produktiv nutzbar machen.
- Vereinsmitgliedschaften und Ein-Verein-pro-Benutzer-Regel.
- Trennung von Vereinsrollen und Mannschaftsrollen.
- Schutz vor vereinsübergreifendem Lesen/Schreiben.
- Server-seitige Autorisierung für Mitglieder-/Rollenverwaltung und expliziten Kontext.
- Rollen-/RLS-/RPC-Prüfung einschließlich direkter Aufrufe und negativer Fälle.
- Bestehende Mannschaftsrollen und bisherige Trainings-/Spieltagsfunktionen müssen regressionsfrei bleiben.
- R1 und R2 können als ein gemeinsames Release gebündelt werden, falls die Migrationen technisch so eng gekoppelt sind, dass eine Zwischenversion ohne nutzbare Vereinsfunktion keinen Mehrwert hat. Die finale Trennung entscheidet sich nach dem Abhängigkeitsreview, nicht nach AP-Nummern.

### Paket R3 – ausgewählte Verwaltungsoberfläche
**Ziel:** Vereinsadmin-Ansichten und Rollenverwaltung im vorhandenen Design bereitstellen.
- Aktuelle DEV-Frontendbasis gegen DB-/RPC-Abhängigkeiten abgleichen.
- Nur die für Vereinsansicht, Mitgliedschaften und Rollen erforderlichen Oberflächen übernehmen.
- Profil-/Avatar-Funktionen aus AP04 nur aufnehmen, wenn sie für die aktuelle Mitgliederansicht zwingend benötigt und entsprechend abgesichert sind; andernfalls gesondert zurückstellen.
- Keine neue UI nachbauen, wenn vorhandene Super-Admin-Komponenten sicher wiederverwendet werden können.
- iPhone-Praxistest für Vereinsadmin, Mannschaftsadmin, Trainer und Super Admin.

### Später / nicht Bestandteil des ersten Multi-Verein-Releases
- AP4 im ursprünglichen Arbeitsplan: historische Spieler-Mannschafts-/Saisonzugehörigkeiten.
- AP5: umfassende Saison- und Ereignishistorie, soweit nicht zur korrekten Verarbeitung vorhandener Daten nötig.
- AP6: weitergehende Mannschaftsauswahl, sofern der erste Release ohne sie fachlich sicher funktioniert.
- AP04 Profil-/Avatar-Komfort, soweit nicht zwingend für die gewählte Mitgliederoberfläche erforderlich.
- Zusätzliche UI-Politur ohne Einfluss auf Rechte, Datenintegrität oder Release-Funktion.

## 5. Mindest-Abnahmematrix vor PROD

| Bereich | Positivtest | Negativtest / Regression |
|---|---|---|
| Verein/Mannschaft | berechtigte Zuordnung und Anzeige | keine Zuordnung zu falschem Verein; kein unzulässiger Kontextwechsel |
| Vereinsmitgliedschaft | berechtigte Mitgliedschaft/zulässige Rolle | zweiter Verein für denselben Benutzer abgewiesen; keine fremden Vereinsdaten |
| Mannschaftsrollen | Teamadmin kann erlaubte Teamrollen verwalten | Trainer/Vereinsadmin kann keine unzulässigen Rollenänderungen vornehmen |
| Vereinsadmin-Lesezugriff | eigene Vereinsdaten im vereinbarten Umfang sichtbar | fremder Verein nicht lesbar; unzulässige Schreibaktionen abgewiesen |
| Super Admin | Aktionen nur im ausdrücklich gewählten Kontext | kein stiller Kontextwechsel; keine unbegrenzte Kontextüberschreitung |
| Bestehende App | Spieler, Positionen, Trainings, Anwesenheit, Spieltage, Kaderplanung funktionieren | bestehende Trainer-/Teamadminrechte bleiben erhalten |
| Migration/Restore | Migration läuft einmalig und nachvollziehbar | keine doppelten Objekte, kein Datenverlust; Wiederherstellungspfad vorhanden |

**Release-Freigaberegel:** Alle kritischen Positiv- und Negativtests müssen bestanden sein. Offene nichtkritische Funktionen werden ausdrücklich aus dem Release-Scope ausgeschlossen. PROD-Änderungen erfolgen erst nach separater ausdrücklicher Freigabe.

## 6. Noch nicht entschieden – bewusst offen gelassen

1. Ob R1 (AP1) separat veröffentlicht wird oder gemeinsam mit R2 (AP2 + notwendiges AP3) kommt. Entscheidung nach SQL-Abhängigkeitsprüfung.
2. Ob AP04-Profil-/Avatar-Migrationen für den aktuellen Mitglieder-/Rollen-Frontendstand erforderlich sind. Entscheidung nach konkretem Frontend-RPC-/Spalten-Audit.
3. Welche einzelnen Security-Advisor-Befunde echte Blocker sind. Jede Warnung wird gegen Funktionszweck und Berechtigungsmodell bewertet.
4. Ob und welche historischen Saisonbezüge in DEV fachlich zulässig NULL sein dürfen. Keine automatische Ergänzung.
5. Endgültige Migrationsreihenfolge und Rollback-Strategie nach Wiederherstellung der fehlenden SQL-Quellen.

## 7. Nachweise

- Zentrale Projektdokumentation: `PROJECT_CONTEXT_updated.md`
- DEV-Rollen-/Berechtigungsprüfbericht: `docs/DEV_ROLLEN_BERECHTIGUNGEN_PRUEFBERICHT_2026-10-28.md`
- Mannschaftskontext-Bericht: `docs/DEV_MANSCHAFTSKONTEXT_VEREINSADMIN_SUPERADMIN_2026-10-28.md`
- Vereins-/Mannschaftsanlage: `docs/CLUB_TEAM_CREATION_PLAN_2026-10-29.md`
- AP04-Profil-/Avatar-Status: `docs/AP04-profile-management.md`
- DEV-Datenbankänderungsprotokoll: `DB_CHANGELOG_DEV_updated.md`

Diese Dokumente ergänzen einander; keines allein ersetzt die finalen, versionierten SQL-Quellen oder den abschließenden Release-Review.
