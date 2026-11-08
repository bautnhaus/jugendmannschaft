# E05 – Technischer Review des Schemafundaments

**Stand:** 08.11.2026, Europe/Berlin  
**Branch:** `develop`  
**Zielumgebung:** Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**Status:** Review durchgeführt; SQL-Entwurf **noch nicht freigabefähig**; nicht ausgeführt  
**Führende Regeln:** `docs/SUPABASE_CHANGE_CONTROL.md`, `DB_MIGRATION_LOG.md`, `DB_CHANGELOG.md`, `docs/E05_TECHNISCHES_ZIELDATENMODELL_2026-11-08.md`

## 1. Prüfauftrag und Ergebnis

Geprüft wurden der vorhandene technische Zieldatenmodell-Entwurf, die SQL-Datei `docs/E05_SCHEMA_MIGRATION_DRAFT_2026-11-08.sql`, die in DEV ausgelesenen Tabellen/Constraints, die bestehenden Team-/Club-Kontextfunktionen sowie die aktuellen Spielartwerte.

**Ergebnis:** Der Entwurf ist eine brauchbare Grundlage, enthält aber noch technische Abweichungen zum fachlich beschlossenen Modell und mehrere Integritätslücken. Er wird deshalb nicht zur Ausführung freigegeben. Die offenen Punkte sind technische Verantwortung des Projekts und müssen vor einer Freigabe im Entwurf korrigiert werden.

## 2. Geprüfte DEV-Fakten

- Projekt ist aktiv und verwendet PostgreSQL 17.6.
- Relevante Bestandsobjekte sind vorhanden und RLS-geschützt: `trainings`, `attendance`, `players`, `seasons`, `matchdays`, `matchday_players`, `matchday_attendance`, `team_member_roles`, `club_members`, `club_member_roles`, `user_club_context`.
- `attendance` hat den Primärschlüssel `(training_id, player_id)`; die Ereignisberechtigung muss `attendance.present = true` prüfen. `training_responses` ist keine Anwesenheitsquelle.
- `trainings.season_id` ist nullable. Im aktuellen DEV-Bestand haben 12 von 14 Trainings keinen Saisonbezug. Die spätere Ereignis-RPC muss die aktive Saison des Teams ermitteln und bei fehlender aktiver Saison abbrechen; sie darf nicht einfach einen NULL-Wert übernehmen.
- `matchdays.game_type` enthält aktuell `Meisterschaft`, `Freundschaftsspiel`, `Turnier` sowie NULL-Werte. Die Lifecycle-Logik muss diese Werte kanonisch zuordnen; NULL darf nicht stillschweigend als sperrenrelevant behandelt werden.
- `is_team_member(uuid)` umfasst Teamrollen und Superadmins nur im ausgewählten Teamkontext. `is_team_admin(uuid)` und `has_selected_team_context(uuid)` sind vorhanden. Diese vorhandenen Regeln sind zu verwenden; keine parallele Rollenlogik.
- Die bestehende Funktion `save_matchday_recommendation(uuid, uuid[])` prüft Teammitgliedschaft, aktive Spieler und doppelte IDs, berücksichtigt aber noch keine Sperren.

## 3. Festgestellte Korrekturen am vorhandenen SQL-Entwurf

### 3.1 Spielerhistorie und Löschverhalten – kritisch

Das Zieldatenmodell verlangt, dass eine historische Ereigniszeile bei einer späteren Spieler-Löschung erhalten bleibt und die damalige Spieleridentität über einen Namens-Snapshot nachvollziehbar ist. Der SQL-Entwurf verwendet aktuell jedoch `player_id NOT NULL ... ON DELETE RESTRICT` und enthält keinen `player_name_snapshot`.

**Erforderliche Korrektur:** `player_id` in den Historientabellen nullable mit `ON DELETE SET NULL`; zusätzlich `player_name_snapshot` (und wo fachlich erforderlich weitere Identitätssnapshots). Team-, Saison- und Trainingsherkunft bleibt als historischer Kontext erhalten. Die App-Regeln zum Deaktivieren/Löschen von Spielern bleiben davon unberührt.

### 3.2 Team-Override der sperrrelevanten Spielarten – kritisch

Die vorhandenen Tabellen `team_suspension_game_types` enthalten nur einzelne Spielartzeilen. Das Modell kann damit einen vollständigen Team-Override mit **bewusst leerer Liste** nicht von „kein Override vorhanden“ unterscheiden.

**Erforderliche Korrektur:** separates Team-Override-Kopfobjekt (z. B. `team_suspension_game_type_settings`) mit explizitem Override-Status. Die Kindtabelle enthält die Spielarten. Vorhandener Override mit null Kindzeilen bedeutet bewusst „keine Spielart zählt“; ohne Override gilt der Club-Standard.

### 3.3 Sperrenursprung und Eindeutigkeit – kritisch

Der Entwurf lässt `source_event_id` bei einer Sperre NULL zu und verhindert nicht eindeutig, dass dasselbe Ereignis mehrere Sperren erzeugt.

**Erforderliche Korrektur:** auslösendes Ereignis muss bei regelbasierten Karten-Sperren verpflichtend referenziert werden; eindeutige Integritätsregel für maximal eine Sperre pro auslösendem Ereignis. Falls spätere manuelle Sperren ohne Karte fachlich benötigt werden, muss dafür ein expliziter, separat auditierter Ursprungstyp vorgesehen werden.

### 3.4 Audit- und Nutzerkonten-Löschverhalten – kritisch

Der SQL-Entwurf verwendet an mehreren Akteursreferenzen `NOT NULL` und `ON DELETE RESTRICT`. Dadurch kann die Löschung eines Auth-Benutzers an historischen Auditverweisen scheitern.

**Erforderliche Korrektur:** Akteurs-UUIDs in Audit-/Historientabellen grundsätzlich nullable mit `ON DELETE SET NULL`; Zeitpunkt, Aktion, Grund und alte/neue Werte bleiben erhalten. Die Benutzerreferenz ist ein Zusatz zur Historie, nicht deren alleiniger Identitätsanker.

### 3.5 Storno/Reaktivierung und aktive Eindeutigkeit

Die Eventtabelle muss einen eindeutigen, nachvollziehbaren Statusfluss besitzen. Die Eindeutigkeitsindizes müssen ausschließlich aktive, nicht stornierte Ereignisse berücksichtigen. Eine Reaktivierung muss die Historie des vorherigen Stornos im Audit erhalten und darf keine zweite aktive Karte/Stern-Doppelbelegung ermöglichen.

**Erforderliche Korrektur:** Statusmodell, Storno-/Reaktivierungsmetadaten, Auditaktionen und partielle Unique-Indizes müssen in einer konsistenten Variante zusammengeführt werden. Keine widersprüchliche Mischung aus Statusfeld und Zeitstempel als konkurrierenden Aktivitätsindikatoren.

### 3.6 Konsistenz über Team, Saison, Training, Spieler und Spieltag

Normale Fremdschlüssel sichern nur die Existenz einzelner IDs, nicht, dass Training, Spieler, Saison und Spieltag zum selben Team gehören.

**Erforderliche Korrektur:** alle schreibenden RPCs müssen diese Beziehungen serverseitig unter Sperre prüfen. Die Foundation darf nicht so dokumentiert werden, als würden einfache Fremdschlüssel diese fachliche Konsistenz bereits garantieren. Soweit ohne unnötige Komplexität möglich, sollen zusätzliche zusammengesetzte Schlüssel/Constraints erwogen werden.

## 4. RLS- und Rechteprüfung

- Der Entwurf verwendet bestehende Teamkontextfunktionen und erteilt keine direkten Client-Schreibrechte. Das ist für die Foundation der richtige Grundsatz.
- Alle neuen Tabellen im exponierten Schema `public` benötigen RLS und minimale Grants.
- Lesepolicies für Club-Konfiguration müssen Club-Admins im ausgewählten Clubkontext und berechtigten Teammitgliedern den benötigten Lesezugriff ermöglichen. Der aktuelle Club-Policy-Ausdruck ist gegen die tatsächliche Club-Kontextlogik abschließend zu prüfen.
- Spätere Schreib-RPCs müssen explizit auf `auth.uid()`, Teamrolle und ausgewählten Kontext prüfen. `SECURITY DEFINER` darf nicht als pauschale Abkürzung dienen; feste `search_path`, eng begrenzte EXECUTE-ACL und Advisor-Prüfung sind Pflicht.
- Audittabellen erhalten keine direkten INSERT-/UPDATE-/DELETE-Rechte für Clients. Auditdatensätze werden ausschließlich atomar durch kontrollierte serverseitige Schreiboperationen erzeugt.

## 5. Migrations- und Teststrategie

Der Entwurf bleibt unter `docs/` ein Review-Artefakt. Er wird nicht vorzeitig als ausführbare Migration unter `supabase/migrations/` abgelegt.

Vor einer späteren Freigabe sind erforderlich:
1. Korrigiertes Zieldatenmodell und abgestimmte Status-/Snapshot-Felder.
2. Korrigierter vollständiger SQL-Entwurf.
3. Statische SQL-Prüfung und Ausführung auf einer isolierten PostgreSQL-Testinstanz bzw. einem isolierten Schema – ohne DEV-/PROD-Daten zu verändern.
4. Review aller Tabellen, Fremdschlüssel, Constraints, Indizes, RLS-Policies und ACLs.
5. Positiv-/Negativtests der Leserechte und Nachweis, dass direkte Client-Schreibzugriffe verweigert werden.
6. Dokumentierter Rollback-/Wiederherstellungsweg.
7. Erst danach Erstellung der finalen Migrationsdatei mit dem im Projekt/Supabase-Change-Control vorgeschriebenen Supabase-CLI-Verfahren.
8. Konkrete Freigabe für genau diese Datei und ausschließlich Supabase DEV.

## 6. Was nicht ausgeführt wurde

- Keine SQL-Migration angewendet.
- Keine Tabellen, Funktionen, Trigger, Policies, Grants oder Daten verändert.
- Keine Frontend-Datei geändert.
- Keine Änderung an Supabase Auth, Edge Functions, GitHub `main` oder PROD.
- Keine Ausführungsfreigabe erteilt oder angenommen.

## 7. Review-Entscheidung

**Nicht freigabefähig in der aktuellen Fassung.**  
Die oben genannten Punkte werden durch den technischen Review verantwortet und müssen vor erneuter Vorlage korrigiert werden. Der Nutzer muss diese technischen Einzelheiten nicht selbst bewerten. Eine spätere Nutzerfreigabe wird erst eingeholt, wenn ein in sich konsistenter, statisch geprüfter SQL-Stand und sein konkreter Ausführungsumfang vorliegen.


## 8. Review Revision 2 – korrigierter Modell- und SQL-Entwurf

**Stand:** 08.11.2026, Revision 2  
**Geprüfte Dateien:**
- `docs/E05_TECHNISCHES_ZIELDATENMODELL_2026-11-08.md`
- `docs/E05_SCHEMA_MIGRATION_DRAFT_2026-11-08.sql`

### 8.1 Korrekturen aus dem Erstreview

Die folgenden Punkte wurden im Modell und SQL-Entwurf korrigiert:

1. **Spielerhistorie:** nullable `player_id` mit `ON DELETE SET NULL`, Pflicht-Namenssnapshot; Historie bleibt bei Spieler-Löschung lesbar.
2. **Akteure:** Auth-FKs sind nullable mit `ON DELETE SET NULL`; Actor-Namenssnapshot bleibt erhalten. Keine historischen Auditverweise blockieren Kontolöschung.
3. **Spielart-Override:** Team-Override-Kopf plus Kindtabelle. Ein vorhandener Kopf ohne Kindzeilen ist ein bewusst leerer vollständiger Override.
4. **Sperrenursprung:** `source_event_id` ist verpflichtend und eindeutig; dasselbe Kartenereignis kann nicht mehrfach eine Sperre auslösen.
5. **Eventstatus:** ein einzelnes Statusfeld `active/voided` steuert Aktivität; partielle Unique-Indizes gelten nur für aktive Karten/Sterne.
6. **Mehrere offene Sperren:** kein Unique-Constraint pro Spieler/Sperrentyp, da mehrere rote Sperren nacheinander offen sein können. Eindeutigkeit wird über das jeweilige Quellereignis gesichert.
7. **Club-Lesepolicy:** `can_manage_club_context(club_id)` wird mit einem passenden Eintrag in `user_club_context` kombiniert. Club-Mitgliedschaft allein gibt keinen Zugriff auf die Konfiguration.
8. **Team-/Saison-/Terminbeziehungen:** werden als Snapshots gespeichert; die schreibenden RPCs müssen Team-, Saison-, Trainings-, Spieler- und Spieltagskonsistenz serverseitig prüfen.

### 8.2 Zusätzliche Prüfung der bestehenden Löschabläufe

Der aktuelle `develop/index.html`-Stand wurde read-only geprüft:
- `deleteTraining()` löscht zuerst `training_players` und anschließend in einem separaten Request das Training.
- `deleteMatchday()` löscht zuerst `matchday_players` und anschließend in einem separaten Request den Spieltag.

Ein `ON DELETE RESTRICT`-FK von Ereignis-/Sperrenhistorie auf Training oder Spieltag könnte deshalb den zweiten Request blockieren, nachdem der erste bereits erfolgreich war. Das würde einen unerwünschten Teilzustand erzeugen.

**Korrektur:** Trainings- und Spieltags-IDs sowie Datum/Name/Gegner werden in der Historie als Snapshots gespeichert, nicht als operative FKs. Die Historie bleibt erhalten, ohne die bestehenden sequenziellen Löschabläufe teilweise scheitern zu lassen. Der Spieler-FK bleibt nullable mit `ON DELETE SET NULL`; Audit-Parentbezüge bleiben `ON DELETE RESTRICT`.

### 8.3 Statische Strukturprüfung des SQL-Entwurfs

Für die aktuelle Revision wurden automatisiert gegen den Text der SQL-Datei geprüft:

| Prüfung | Ergebnis |
|---|---|
| Neue Tabellen | 10 erkannt |
| RLS-Aktivierung | 10 von 10 Tabellen |
| SELECT-Policies | 10; jede Policy verweist auf eine der neuen Tabellen |
| Direkte authentifizierte Schreib-Policies | keine |
| Auth-Akteurs-FKs | nur `ON DELETE SET NULL`; keine `ON DELETE RESTRICT` |
| Historische Kaskaden auf Ereignis-/Sperren-/Resetobjekte | keine |
| Eindeutige Sperrenquelle | vorhanden |
| Vollständiger Team-Override inkl. leerer Liste | Kopf-/Kindmodell vorhanden |
| Club-Admin-Kontext | ausgewählter Clubkontext wird zusätzlich geprüft |

Die statische Prüfung hat außerdem bestätigt, dass die Migration keine bestehenden Tabellen, Funktionen, Trigger oder Policies verändert. Die einzige Kaskade ist die Löschung von Kind-Spielartzeilen bei Entfernung des nicht-historischen Team-Override-Kopfes.

### 8.4 Verbleibende Prüfschranke

**Noch nicht abgeschlossen:** Die SQL-Datei wurde nicht auf einer isolierten PostgreSQL-Instanz ausgeführt. In der aktuellen Arbeitsumgebung steht kein isolierter PostgreSQL-Testserver zur Verfügung; die DEV-Datenbank wird nicht als Syntax-Testumgebung verwendet und es wird kein kostenpflichtiger zusätzlicher Supabase-Testbranch angelegt.

Damit fehlen weiterhin:
- PostgreSQL-Laufzeitsyntax-/DDL-Test,
- tatsächliche Katalogprüfung nach Anlage,
- RLS-/ACL-Positiv- und Negativtests,
- Security Advisor nach DDL,
- geprüfter Rückbau auf einer isolierten Testinstanz.

**Aktuelle Entscheidung:** Die Revision 2 ist statisch deutlich verbessert, aber noch **nicht ausführungsfreigabefähig**. Die Nutzerfreigabe wird nicht eingeholt, solange diese Prüfschranke offen ist. Es wurde kein SQL ausgeführt und keine Datenbank geändert.


### 8.5 Isolierter PostgreSQL-Testlauf vorbereitet

Um die fehlende Testinstanz ohne Änderung an Supabase DEV/PROD zu ersetzen, wurde eine GitHub-Actions-Teststrecke mit einem kurzlebigen PostgreSQL-17.6-Service ergänzt:

- Workflow: `.github/workflows/e05-schema-draft-test.yml`
- Fixture: `docs/e05-test/bootstrap.sql`
- Assertions: `docs/e05-test/assertions.sql`
- Getestet werden sollen: DDL-Anlage, zehn Tabellen, RLS-Aktivierung, Policyanzahl, minimale Grants, Duplikatverhinderung für Karten/Sterne, eine Karte plus Stern, eindeutige Sperrenquelle, mehrere gleichzeitig offene rote Sperren, leere Team-Overrides, Player-/Auth-Löschung mit Snapshot-Erhalt, Training-/Spieltag-Löschung ohne Historieverlust sowie Team-/Clubkontext-Leserechte.

Der Workflow ist auf Push-Änderungen an SQL-Entwurf/Testdateien in `develop` und manuell per `workflow_dispatch` konfiguriert. Der aktuelle GitHub-Statusabruf hat für die Test-Commits noch keine auslesbaren Statusmeldungen geliefert. **Ein erfolgreicher Lauf wird daher ausdrücklich noch nicht behauptet.** Vor einer Freigabe muss ein grüner Lauf in GitHub Actions tatsächlich verifiziert und sein Run-/Commit-Nachweis in diesem Review dokumentiert werden.



---

## 9. Gezielt korrigierte Revision 4 – Audit-Schutz und API-Schreibrechte

**Stand:** 08.11.2026, nach Review Revision 3  
**Branch:** `develop`  
**Status:** Korrekturen committed; isolierter PostgreSQL-Testlauf für Revision 4 noch ausstehend. Weiterhin nicht zur Supabase-Ausführung freigegeben.

### 9.1 Umgesetzte Korrekturen

1. **Audit-TRUNCATE-Schutz:** Für alle drei Audit-Tabellen wurden zusätzliche `BEFORE TRUNCATE`-Statement-Trigger ergänzt. Die vorhandenen `BEFORE UPDATE OR DELETE`-Trigger bleiben bestehen.
2. **Triggerfunktion gekapselt:** Direkte `EXECUTE`-Rechte auf `public.e05_reject_audit_mutation()` werden für `PUBLIC`, `anon`, `authenticated` und `service_role` entzogen.
3. **Keine direkten API-Schreibrechte:** `service_role` erhält auf den zehn Foundation-Tabellen nur noch `SELECT`, kein direktes `INSERT`, `UPDATE` oder `DELETE`. Auch `anon` und `authenticated` erhalten keine Schreibrechte.
4. **Atomare spätere Schreibwege:** Domänenänderungen und Audit-Inserts sind für spätere, separat geprüfte RPCs vorgesehen. Die Foundation selbst stellt noch keine Schreib-RPCs bereit.

### 9.2 Erweiterte Assertions

- ACL-Prüfung erwartet für `service_role` ausschließlich `SELECT`.
- Assertions versuchen `TRUNCATE` auf jeder der drei Audit-Tabellen und erwarten SQLSTATE `55000`.
- Assertions prüfen, dass API-Rollen die Audit-Triggerfunktion nicht direkt ausführen dürfen.

### 9.3 Noch nicht durch diese Korrektur gelöst

- Die Actor-Snapshot-Felder sind nicht durchgängig als `NOT NULL` modelliert. Die späteren Schreib-RPCs müssen bei jeder fachlichen Aktion einen nachvollziehbaren Actor-Snapshot erzwingen; Systemaktionen benötigen eine explizite Systemidentität.
- Die Team-/Saison-/Training-/Spieler-/Spieltag-Konsistenz bleibt Aufgabe der späteren atomaren RPCs gemäß Revision 3 des Zieldatenmodells.
- Die bestehende GitHub-Test-Fixture verwendet weiterhin vereinfachte Ersatzfunktionen für Team-/Clubkontext. Der echte DEV-Kontextabgleich steht separat aus.
- Rollback-/Restore-Nachweis und vollständiger RLS-/ACL-Abgleich mit den realen DEV-Funktionen stehen weiterhin aus.

### 9.4 Änderungen und Ausführungsgrenzen

- Geänderte Dateien: `docs/E05_SCHEMA_MIGRATION_DRAFT_2026-11-08.sql`, `docs/e05-test/assertions.sql`, dieses Review.
- Keine Datei unter `supabase/migrations/` erstellt.
- Keine SQL-Anweisung gegen Supabase DEV oder PROD ausgeführt.
- Keine bestehenden Tabellen, Funktionen, Policies, Trigger oder Daten in Supabase geändert.
- Kein Eintrag als ausgeführte Migration in `DB_MIGRATION_LOG.md` oder `DB_CHANGELOG.md`; dies wäre sachlich falsch.


### 9.5 Isolierter PostgreSQL-17.6-Testlauf – erfolgreich nach Syntaxkorrektur

**Stand:** 08.11.2026  
**Testlauf:** GitHub Actions #16  
**Commit:** `c9ba32c6814e21823d9ab876aace1c6c91599d3b`  
**Ergebnis:** `success`  
**Nachweis:** https://github.com/bautnhaus/jugendmannschaft/actions/runs/42465099465

Der vorherige Lauf #15 war fehlgeschlagen. Die Fehlerursache lag im letzten `DO`-Block von `docs/e05-test/assertions.sql`: Der Blockabschluss war als `end $;` statt `end $$;` geschrieben. Die vorherige Korrektur hatte nicht den tatsächlich fehlerhaften letzten Block getroffen.

Die fehlerhafte Abschlusszeile wurde gezielt korrigiert. Vor dem erneuten Workflow-Lauf wurden die Dollar-Quote-Tags in der vollständigen Assertions-Datei und im SQL-Entwurf auf paarige Abschlüsse geprüft. Zusätzlich wurde sichergestellt, dass kein fehlerhaftes `end $;` mehr vorhanden ist.

Im erfolgreichen Lauf #16 wurden alle Schritte grün abgeschlossen:
- PostgreSQL-17.6-Service initialisiert
- Supabase-ähnliche Test-Fixture vorbereitet
- SQL-Entwurf ausschließlich auf der temporären Testdatenbank angewendet
- Struktur-, Constraint-, Snapshot- und RLS-Assertions vollständig ausgeführt
- Testcontainer erfolgreich beendet

**Einordnung:** Damit ist die bisherige technische Prüfschranke „isolierter PostgreSQL-Laufzeittest“ für den aktuellen Foundation-Entwurf erfolgreich passiert. Das ist keine Freigabe zur Ausführung in Supabase DEV oder PROD und ersetzt nicht die noch offenen Prüfungen aus Abschnitt 9.3 (insbesondere echte DEV-Kontextfunktionen, Actor-Snapshots in späteren RPCs und Rollback-/Restore-Nachweis).

**Änderungsgrenze:** Es wurde ausschließlich die Testdatei in `develop` korrigiert. Keine Supabase-SQL-Ausführung, keine Änderung an DEV-/PROD-Daten, keine Änderung an `main`.


## 10. Read-only-Abgleich mit Supabase DEV

**Stand:** 08.11.2026, 11:00 Uhr Europe/Berlin  
**Projekt:** Jugendmannschaft DEV (`pzazqvvoruqnqhcorbwx`)  
**Datenbank:** PostgreSQL 17.6.1  
**Methode:** ausschließlich Katalog-/Metadatenabfragen und Supabase Advisor; keine schreibenden SQL-Anweisungen.

### 10.1 Foundation-Status

- Alle zehn AP05-Foundation-Tabellen fehlen in DEV: Trainingsereignisse, Event-Audit, Sperren, Sperrausnahmen, Sperren-Audit, Club-Spielartkonfiguration, Team-Override-Kopf/-Werte sowie früher Sperrausgleich und dessen Audit.
- Damit ist bestätigt: Der bisherige AP05-SQL-Entwurf wurde nicht versehentlich in DEV ausgeführt.
- Die DEV-Migrationshistorie enthält AP01–AP04-Migrationen bis einschließlich `20261104143331 db_dev_009_single_team_membership_guard`; keine AP05-Migration.

### 10.2 Bestandsmodell und Rollen-/Kontextfunktionen

- Relevante Tabellen sind vorhanden und RLS-aktiviert: `players`, `trainings`, `attendance`, `seasons`, `matchdays`, `matchday_players`, `team_members`, `team_member_roles`, `clubs`, `club_members`, `club_member_roles`, `global_user_roles`, `user_team_context`, `user_club_context`.
- `attendance` besitzt `training_id`, `player_id`, `present`; die vorhandenen Policies verknüpfen Training und Spieler über dieselbe Mannschaft. Die AP05-Ereignis-RPC muss tatsächliche Anwesenheit (`present = true`) prüfen, nicht die Rückmeldetabelle.
- Rollenwerte sind `trainer` und `admin` in `team_member_roles`; Clubrolle ist `club_admin`; globale Rolle ist `super_admin`.
- `is_team_member(team_id)` erkennt Teamrollen sowie Superadmins nur mit ausgewähltem Teamkontext. `is_team_admin(team_id)` erkennt Mannschaftsadmins sowie Superadmins mit ausgewähltem Teamkontext.
- `has_selected_team_context(team_id)` erlaubt ausgewählten Kontext für Superadmins und Clubadmins des zugehörigen Vereins. `can_manage_club_context(club_id)` prüft den ausgewählten Clubkontext für Superadmins bzw. die Clubadmin-Mitgliedschaft.
- Diese Funktionen sind `SECURITY DEFINER` mit festem `search_path`; die ACLs gewähren `EXECUTE` an `authenticated` und `service_role`. Die AP05-RPCs müssen die bestehenden Helper gezielt verwenden und ihre eigenen EXECUTE-Rechte eng begrenzen; keine neue parallele Rollenlogik einführen.

### 10.3 Daten- und Lifecycle-Fakten

- DEV enthält 14 Trainings, davon 12 ohne `season_id`. Die Ereigniserfassung darf keinen NULL-Saisonbezug übernehmen; sie muss eine eindeutige aktive Saison des Teams ermitteln oder mit verständlichem Fehler abbrechen.
- `matchdays.game_type` enthält `Meisterschaft`, `Freundschaftsspiel`, `Turnier` und NULL. NULL darf nicht stillschweigend als sperrenrelevant gelten.
- Die Spieltagsstatus-Spalte ist vorhanden; Lifecycle-RPCs müssen die tatsächlich durchgeführten Spieltage von abgesagten/geplanten unterscheiden.

### 10.4 Supabase Advisor – vorhandene Befunde

Der aktuelle Security Advisor meldet bereits im Bestand:
- 2 Tabellen mit RLS ohne Policies: `user_club_context`, `user_team_context` (INFO).
- 38 SECURITY DEFINER-Funktionen, die für `authenticated` ausführbar sind (WARN).
- Zusätzlich bestehende Hinweise auf mehrere permissive Policies für einzelne Aktionen/Tabellen.

Diese Befunde sind Bestandszustand und wurden durch AP05 nicht verursacht. Sie dürfen nicht pauschal durch AP05 bereinigt werden; eine Änderung daran wäre ein separates Sicherheits-/Berechtigungsarbeitspaket. Die AP05-Migration darf die bestehenden Funktionen und Policies nicht verändern.

### 10.5 Abgleichbewertung

**Bestanden:** Projektidentität/Version, Fehlen aller AP05-Tabellen und -Migrationen, vorhandene Bestandsobjekte, zentrale Rollen-/Kontextfunktionen, Anwesenheitsquelle sowie reale Saison-/Spielart-Nullfälle sind verifiziert.

**Vor Freigabe zwingend zu präzisieren:**
1. Jede AP05-Schreib-RPC muss Rolle und Kontext entsprechend der fachlichen Aktion explizit prüfen. Für Karten/Sterne sind die freigegebenen Trainer-/Admin-Berechtigungen maßgeblich; bloßes `is_team_member` ist als Schreibautorisierung zu weit.
2. Team-/Saison-/Training-/Spieler-Konsistenz ist in jeder RPC serverseitig atomar zu prüfen; `attendance.present = true` ist Pflicht für Trainingsevents.
3. Club- und Teamkonfigurationen müssen lesbar sein, ohne Clubmitgliedern pauschalen Zugriff auf fremde Teamdaten zu geben.
4. Bestehende Advisor-Warnungen sind als Baseline zu dokumentieren. Neue AP05-spezifische Warnungen sind nach Migration separat zu bewerten.
5. Das aktuelle Foundation-SQL erteilt keine Schreibrechte und enthält noch keine Domänen-RPCs. Es kann daher allein weder Kartenvergabe noch Lifecycle-/Sperrenlogik umsetzen.

### 10.6 Änderungsgrenzen

Es wurden nur read-only SQL-Katalogabfragen sowie Security-/Performance-Advisor-Abfragen ausgeführt. Keine Tabellen, Daten, Funktionen, Trigger, Policies, Grants oder Migrationseinträge wurden verändert. Keine Änderung an PROD oder `main`.


## 11. DEV-Abgleich des SQL-Entwurfs und statische Prüfung

**Stand:** 08.11.2026, nach dem Read-only-Abgleich  
**SQL-Entwurf:** `docs/E05_SCHEMA_MIGRATION_DRAFT_2026-11-08.sql`  
**Ziel:** ausschließlich DEV; Entwurf bleibt nicht freigegeben und wurde nicht ausgeführt.

### 11.1 Abgleich mit tatsächlichem DEV-Bestand

- Die aktuelle DEV-Migrationshistorie endet bei `20261104143331 db_dev_009_single_team_membership_guard`; es existiert weiterhin keine AP05-Migration.
- Die Bestandsstruktur bestätigt `teams`, `players`, `seasons`, `trainings`, `attendance`, `matchdays`, `matchday_players`, `clubs`, `user_club_context` und die Rollen-/Kontexttabellen.
- `trainings.season_id` ist nullable; `matchdays.season_id` ist nullable; `matchdays.game_type` ist nullable. Diese Felder dürfen in späteren Schreib-RPCs nicht ungeprüft übernommen werden.
- Die tatsächlich vorhandenen Kontextfunktionen sind `is_team_member(uuid)`, `has_selected_team_context(uuid)` und `can_manage_club_context(uuid)`. Sie sind `SECURITY DEFINER` mit festem `search_path = pg_catalog, public`. Die Policies im Entwurf referenzieren damit vorhandene Funktionen und keine nur angenommene neue Rollenlogik.
- `is_team_member(team_id)` umfasst Trainer/Mannschaftsadmins und Superadmins nur im ausgewählten Teamkontext; Clubadmins werden über `has_selected_team_context(team_id)` abgedeckt.
- Der tatsächliche DEV-Bestand enthält 12 von 14 Trainings ohne `season_id`; die spätere Ereignis-RPC muss eine eindeutige aktive Saison aus `seasons.is_active` ermitteln und andernfalls abbrechen.

### 11.2 Korrektur am SQL-Entwurf

Der vorherige ACL-Abschnitt entzog Tabellenrechte nur `PUBLIC`, `anon` und `authenticated`, während `service_role` anschließend explizit SELECT erhielt. Damit war nicht sichergestellt, dass eventuell vorhandene Default-/Alt-Schreibrechte von `service_role` entfernt sind.

**Korrektur in Revision 5:** Der Tabellen-`REVOKE ALL` umfasst nun ausdrücklich `PUBLIC, anon, authenticated, service_role`. Anschließend erhält `authenticated` ausschließlich SELECT und `service_role` ebenfalls ausschließlich SELECT. Es gibt keine direkten Schreibrechte für eine API-Rolle in der Foundation. Die Triggerfunktion bleibt für alle vier Rollen explizit gesperrt.

### 11.3 Statische Prüfung der überarbeiteten SQL-Datei

Folgende automatisierte Text-/Strukturprüfungen wurden auf dem vollständigen Entwurf ausgeführt:

| Prüfung | Ergebnis |
|---|---|
| Transaktionsrahmen BEGIN/COMMIT vorhanden | PASS |
| Dollar-Quote-Paare vollständig | PASS |
| Genau zehn Foundation-Tabellen | PASS |
| Für alle zehn Tabellen RLS aktiviert | PASS |
| Zehn SELECT-Policies vorhanden | PASS |
| Tabellen-REVOKE umfasst PUBLIC/anon/authenticated/service_role | PASS |
| service_role erhält nach REVOKE nur SELECT | PASS |
| Keine Änderung bestehender Tabellen durch ALTER TABLE | PASS |
| Bestehende Helper-Funktionen im DEV-Katalog nachgewiesen | PASS |

Die Prüfung ist eine statische Struktur-/Katalogprüfung. Sie ist **kein PostgreSQL-Parserlauf und kein erneuter isolierter PostgreSQL-17.6-Workflow-Test**. Der erfolgreiche bzw. fehlgeschlagene frühere CI-Lauf wird dadurch nicht ersetzt. Ein neuer CI-Lauf auf genau diesem korrigierten Commit bleibt vor technischer Freigabe erforderlich.

### 11.4 Verbleibende technische Risiken / offene Freigabepunkte

1. Die SQL-Datei ist noch ein Review-Artefakt unter `docs/`, keine ausführbare Migration unter `supabase/migrations/`.
2. Die fachlichen Schreib-RPCs fehlen absichtlich noch; die Foundation bildet Tabellen, SELECT-Sicht und Schreibsperre ab.
3. Die zehn Tabellen-/Policy-Definitionen müssen im isolierten PostgreSQL-Test gegen die reale Fixture laufen. Insbesondere sind Policy-Auflösung, FK-/Constraint-Verhalten, Trigger-Append-only und tatsächliche Tabellen-ACLs dort zu testen.
4. Die RLS-Policies für Clubkonfigurationen müssen im isolierten Test mit Teammitglied, Clubadmin im ausgewählten Clubkontext, Clubadmin ohne ausgewählten Kontext und Superadmin ohne/mit passenden Kontexten geprüft werden.
5. Der Rollback-/Restore-Nachweis und die abschließende Prüfung der Test-Fixture gegen DEV-Berechtigungen stehen weiterhin aus.

**Ergebnis:** Der konkrete, im DEV-Abgleich gefundene ACL-Mangel wurde im Review-Entwurf korrigiert. Die statischen Strukturprüfungen sind bestanden. **Keine SQL-Anweisung wurde in Supabase ausgeführt; DEV und PROD sind unverändert. Keine Ausführungsfreigabe erteilt.**
