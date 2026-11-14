# E05 PROD Paket 8 – Vorzeitiger Sperrausgleich

- **Stand:** 14.11.2026
- **Status:** Technischer Freigabekandidat vorbereitet auf `develop`; nicht ausgeführt.
- **Zielprojekt:** Supabase PROD `qdugtpzgefpswnnqbusd`.
- **DEV-Projekt:** `pzazqvvoruqnqhcorbwx`.
- **DEV-Quelle:** `docs/E05_PAKET_08_VORZEITIGER_SPERRAUSGLEICH_2026-11-08.sql` (Blob-SHA `f20ecda513a29269462a2eabd3bbd831b6d478ba`).
- **DEV-Abnahme:** `docs/E05_PAKET_08_ABNAHME_UND_AUSFUEHRUNG_2026-11-08.md`; Positiv-, Negativ-, Berechtigungs- und Regressionstests bestanden.
- **PROD-Voraussetzung:** Pakete 1–7 sind in PROD registriert; Paket 7 wurde am 14.11.2026 nachkontrolliert.
- **PROD-Ausführung:** nicht erfolgt. Keine Ausführungsfreigabe erteilt.

## 1. Fachlicher Umfang

Paket 8 ergänzt den freiwilligen vorzeitigen Sperrausgleich:
- Vormerkung für einen aktiven, nicht nominierten Spieler an einem konkreten zukünftigen geplanten Spieltag derselben aktiven Saison.
- Pflichtbegründung und Snapshot-Daten.
- Manuelle Stornierung mit Begründung.
- Automatische Stornierung bei nachträglicher Nominierung oder Spieltagsabsage.
- Einmalige Anwendung erst bei tatsächlichem Spieltagsstatus `done`.
- Beginn eines neuen aktiven gelben Kartenkontos ab dem Anwendungszeitpunkt.
- Ereignis- und Sperrenhistorie bleibt erhalten; offene gelbe/rote Sperren werden nicht aufgehoben.

## 2. Verbindliche DEV-Abnahme

Die DEV-Abnahme vom 08.11.2026 dokumentiert:
- Tabellen `matchday_early_suspension_resets` und `matchday_early_suspension_reset_audit`.
- RPCs `schedule_early_suspension_reset` und `cancel_early_suspension_reset`.
- Interne Statusübergangsfunktion und Trigger für Nominierung, Absage und Durchführung.
- Erweiterung des gelben Kartenkontos.
- Erfolgreiche Positiv-, Negativ-, ACL-, RLS-, Audit- und Regressionstests.
- Alle synthetischen Testdaten wurden zurückgerollt; in DEV verblieben keine Paket-8-Testdatensätze.

## 3. Read-only PROD-Ausgangszustand (14.11.2026)

### Migrationshistorie
- PROD enthält E05 Pakete 1–7.
- Paket 8 ist nicht registriert.
- Paket 9/10 und DB-MIG-2026-010/011 sind in PROD nicht registriert.

### Objektbestand
- Basistabellen aus Paketen 1–7 vorhanden: `players`, `teams`, `seasons`, `matchdays`, `matchday_players`, `training_suspensions`, `training_suspension_audit`, `training_behavior_events`, `profiles`, `team_member_roles`, `global_user_roles`.
- Teamkontext-Helper `is_team_member(uuid)` und `has_selected_team_context(uuid)` vorhanden.
- Paket-8-Tabellen und -Funktionen fehlen.
- Bestehende Nominierungstrigger auf `matchday_players` bleiben unberührt, insbesondere `matchday_players_prevent_suspended_nomination` aus Paket 6.
- `award_training_behavior_event(uuid,uuid,text,text)` ist die PROD-Paket-2-Fassung, SECURITY DEFINER, Owner `postgres`, search_path `pg_catalog, public, auth`, EXECUTE nur für `authenticated` (neben Owner). Sie zählt gelbe Karten nach `awarded_at` und berücksichtigt bisher nur `served_at`.

### Abgrenzung zu späteren DEV-Paketen
Der aktuelle DEV-Funktionsstand ist nach Paket 9/10 und DB-MIG-2026-010/011 weiterentwickelt. Diese späteren Änderungen sind in PROD noch nicht vorhanden. Paket 8 darf deshalb **nicht** die aktuelle DEV-`award_training_behavior_event`-Funktion vollständig nach PROD kopieren: Das würde spätere Kartenkorrektur-/Chronologie-Logik vorziehen und Paketgrenzen verletzen.

Die PROD-Migration ergänzt daher ausschließlich die vorhandene PROD-Paket-2-RPC um den zusätzlichen Zeitanker `max(applied_at)` aus angewendeten Sperrausgleichen. Der bestehende Paket-2-Funktionscode, die bestehende Zählung nach `awarded_at`, die rote Sperrenlogik, die Audit-Erstellung und die übrigen Prüfungen bleiben unverändert. Die spätere trainingsdatumsbasierte Chronologie bleibt Aufgabe der dafür dokumentierten Folgepakete.

## 4. Migration und Rollback

- Migration: `supabase/migrations/20261114230000_e05_prod_paket_08_early_suspension_reset.sql`
- Rollback: `supabase/rollback/20261114230000_e05_prod_paket_08_early_suspension_reset_rollback.sql`
- Nachkontrolle: `docs/prod-release/E05_PROD_PAKET_08_VORZEITIGER_SPERRAUSGLEICH_TESTQUERIES_2026-11-14.sql`

Die Migration:
1. Prüft die Pakete-1-bis-7-Baseline und die erwartete Paket-2-Quelltextfassung.
2. Bricht bei bereits vorhandenen Paket-8-Objekten oder späteren E05-Kartenkorrektur-/Reconciliation-Funktionen ab.
3. Legt Reset- und Audit-Tabellen, Indizes, RLS/SELECT-Policies und Append-only-Schutz an.
4. Legt Vormerkungs-/Storno-RPC und interne Statusübergangs-/Triggerfunktionen an.
5. Erweitert die bestehende PROD-`award_training_behavior_event`-Funktion über eine exakte, einmalige Source-Transformation. Owner, SECURITY-Attribut, search_path und übriger Funktionscode bleiben erhalten; EXECUTE wird ausdrücklich auf `authenticated` begrenzt.

Das Rollback:
- prüft, dass Reset- und Audit-Tabellen leer sind;
- verweigert den Rückbau bei späteren abhängigen E05-Funktionen;
- stellt nur den exakt veränderten Source-Block der Paket-2-RPC wieder her;
- entfernt anschließend ausschließlich Paket-8-Objekte;
- verwendet kein `CASCADE` und löscht keine fachlichen Datensätze.

**Wichtige Grenze:** Nach Nutzung des Features ist dieses Rollback absichtlich gesperrt. Vor einem Rückbau müssen Reset-/Auditdaten fachlich gesichert und ein eigener Daten-/Abhängigkeitsplan erstellt werden.

## 5. Test- und Freigabegates

Vor PROD-Ausführung:
1. Aktuellen Backup-/PITR-Wiederherstellungspunkt gemäß Betriebsprozess bestätigen.
2. Zielprojekt-ID `qdugtpzgefpswnnqbusd` unmittelbar vor Ausführung verifizieren.
3. Paket-1-bis-7-Migrationshistorie und Objektbestand erneut read-only prüfen.
4. Exakte Migration-/Rollback-Datei und Blob-SHA mit dem freigegebenen Stand vergleichen.
5. Isolierte PostgreSQL-17.6-Prüfung der Migration und des guarded Rollbacks erfolgreich abschließen.

Nach PROD-Ausführung:
1. Nachkontroll-SQL ausführen.
2. RLS, Policies, Tabellenrechte, Indizes, Trigger, Funktionsdefinitionen, Owner, SECURITY DEFINER, search_path und ACL prüfen.
3. Sicherstellen, dass die Migration selbst keine Reset-/Audit-Fachdaten angelegt hat.
4. Fachliche Browser-Praxistests ausschließlich in DEV/isolierter Umgebung durchführen; keine synthetischen Testdaten in PROD.
5. Testfälle aus der DEV-Abnahme vollständig nachvollziehen, einschließlich Nominierung, Absage, `done`, einmaliger Anwendung, gelbem Kartenkonto, roten Sperren und Audit.

## 6. Teststatus und Freigabegrenze

- [x] DEV-Quelle und DEV-Abnahme identifiziert.
- [x] PROD-Migrationshistorie 1–7 read-only bestätigt.
- [x] PROD-Paket-2-`award_training_behavior_event` live ausgelesen.
- [x] Paket-8-Objekte in PROD nicht vorhanden.
- [x] PROD-spezifische Abgrenzung zu Paket 9/10 und DB-MIG-2026-010/011 dokumentiert.
- [x] Migration und guarded Rollback erstellt.
- [x] Read-only Nachkontrollabfragen erstellt.
- [x] Isolierter PostgreSQL-17.6-CI-Test der exakten Migration und des guarded Rollbacks.
- [x] SQL-/Syntaxprüfung in isolierter Datenbank.
- [ ] Finale fachliche/technische PROD-Freigabe.
- [ ] Backup-/PITR-Preflight unmittelbar vor Ausführung.
- [ ] PROD-Ausführung.
- [ ] Read-only PROD-Nachkontrolle.


## 7. Isolierter PostgreSQL-17.6-CI-Test

- **Workflow:** `.github/workflows/e05-prod-package-08-ci.yml`
- **Lauf:** [GitHub Actions 43645581297](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43645581297)
- **Commit:** `8b45a76aa23f77f452ec38c70ea1219d0468209a`
- **Ergebnis:** `success`.
- **Testumgebung:** kurzlebiger PostgreSQL-17.6-Container mit synthetischer Minimal-Baseline; keine Verbindung zu Supabase DEV oder PROD.
- **Erfolgreich geprüft:** exakte Paket-8-Migration; Tabellen/RLS/Policies; öffentliche RPC-EXECUTE-Rechte und gesperrte interne Helfer; Source-Transformation der bestehenden Paket-2-Award-RPC; Anwendung bei `done`; automatische Stornierung bei nachträglicher Nominierung; automatische Stornierung bei Spieltagsabsage; Ablehnung eines bereits nominierten Spielers; genau einmaliger Anwendungs-Audit; leerer Datenbestand nach Rollback der Testtransaktion; guarded Paket-8-Rollback und Rückkehr des ursprünglichen Award-Source-Blocks.
- **Testgrenze:** Die CI-Baseline bildet die für Paket 8 erforderlichen Datenbankobjekte minimal nach. Sie ersetzt weder einen vollständigen Supabase-Auth-/RLS-End-to-End-Test noch die unmittelbare Live-Preflight-Prüfung in PROD. Die fachlichen DEV-Tests aus der Paket-8-Abnahme bleiben die maßgebliche Praxistestgrundlage.

## 8. Unveränderliche Artefakt-Referenzen

- Migration: `supabase/migrations/20261114230000_e05_prod_paket_08_early_suspension_reset.sql`, Blob-SHA `0a302bf476aea108e44e9c7287f9a45944f296cc`.
- Rollback: `supabase/rollback/20261114230000_e05_prod_paket_08_early_suspension_reset_rollback.sql`, Blob-SHA `7c8f358ded8e1f077addfa1d96b6bee3f7f98337`.
- Dossier liegt auf `develop`; CI-Workflow-Blob-SHA `03dc5438cc95b48a2820f2feff38661cd71bb856`.

**Aktueller Status:** Technisch vorbereitet und isoliert erfolgreich getestet; zur abschließenden Prüfung und ausdrücklichen PROD-Ausführungsfreigabe vorgelegt. Noch nicht ausgeführt. Keine Änderung an Supabase DEV, Supabase PROD oder GitHub `main` im Rahmen dieser Vorbereitung.


## 9. PROD-Freigabe und Live-Preflight (14.11.2026)

- **Ausführungsfreigabe:** vom Benutzer ausdrücklich erteilt.
- **Zielprojekt live verifiziert:** `qdugtpzgefpswnnqbusd`, Projektname `Jugendmannschaft`, Region `eu-west-1`, Status `ACTIVE_HEALTHY`, PostgreSQL `17.6.1.166`.
- **DEV-Projekt gegengeprüft:** `pzazqvvoruqnqhcorbwx`; nicht als Ausführungsziel verwendet.
- **Migrationshistorie live:** sieben E05-Pakete (1–7) vorhanden; Paket 8 fehlt; keine Paket-9/10- oder DB-MIG-2026-010/011-Migrationen registriert.
- **Objekt-Preflight:** Paket-8-Tabellen, RPCs und Trigger fehlen vollständig.
- **Quelltext-Preflight:** erwarteter Paket-2-Source-Block in `award_training_behavior_event` exakt einmal vorhanden; Owner `postgres`, SECURITY DEFINER, search_path `pg_catalog, public, auth`, EXECUTE für `authenticated` bestätigt.
- **Datenbestand:** 1 aktive Saison, 0 offene Sperren. Die Abfrage war read-only.
- **Supabase-Organisation:** Plan `free`. Laut offizieller Supabase-Dokumentation sind Datenbank-Backups auf dem Free Plan nicht zum Download verfügbar; PITR ist ein kostenpflichtiges Add-on. Über die verfügbaren Projektinformationen konnte kein bestätigter, wiederherstellbarer Backup-/PITR-Punkt nachgewiesen werden. Referenz: https://supabase.com/docs/guides/platform/backups und https://supabase.com/docs/guides/deployment/going-into-prod.
- **Entscheidung:** Migration **nicht gestartet**. Der im Freigabedossier definierte Backup-/PITR-Preflight ist nicht erfüllt. Die Benutzerfreigabe liegt vor, ersetzt aber nicht den ausdrücklich dokumentierten Wiederherstellbarkeits-Gate.
- **Keine schreibenden Datenbankaktionen:** weder `apply_migration` noch sonstige schreibende SQL-Ausführung erfolgte. DEV, PROD-Schema und PROD-Daten blieben unverändert.
- **Advisor-Ausgangsbefund:** Security Advisor meldet 50 bestehende SECURITY DEFINER-Warnungen, eine mutable-search_path-Warnung (`public.set_updated_at`) und deaktivierten Leaked-Password-Schutz; Health Advisor ohne Findings. Diese bestehenden Hinweise wurden nicht verändert.

**Nächster notwendiger Schritt:** Vor Migration einen belastbaren Wiederherstellungsweg für PROD bereitstellen und bestätigen (z. B. passender Supabase-Plan/Backup- bzw. PITR-Verfügbarkeit oder ein verifizierter externer Datenbank-Backup- und Restore-Prozess). Danach Live-Preflight erneut durchführen. Bis dahin bleibt Paket 8 freigegeben, aber nicht ausgeführt.


## 10. PROD-Ausführung und Nachkontrolle (14.11.2026)

**<badge>Erfolgreich ausgeführt</badge>**

- **Freigabe:** Benutzerfreigabe liegt vor; der Benutzer hat nach Klärung ausdrücklich bestätigt, dass PROD-Releases weiterhin wie bisher ohne kostenpflichtiges Backup/PITR durchgeführt werden. Die zusätzliche Backup-/PITR-Bedingung aus Abschnitt 9 wurde daher nicht als verbindliches Release-Gate angewendet. Das Free-Plan-Wiederherstellungsrisiko bleibt bekannt.
- **Ausführung:** Supabase PROD `qdugtpzgefpswnnqbusd`; Supabase `apply_migration`; Ergebnis `success: true`.
- **Ledger:** Version `20261114222833`, Name `e05_prod_paket_08_early_suspension_reset`.
- **Ausgeführte Datei:** `supabase/migrations/20261114230000_e05_prod_paket_08_early_suspension_reset.sql`, Blob-SHA `0a302bf476aea108e44e9c7287f9a45944f296cc`.
- **Read-only Nachkontrolle:** beide Tabellen vorhanden und RLS aktiviert; beide SELECT-Policies vorhanden; PK/FK/CHECK-Constraints und erwartete Indizes vorhanden; alle drei Trigger vorhanden; alle Paket-8-Funktionen vorhanden.
- **ACL/RPC:** `authenticated` hat ausschließlich SELECT auf beiden Tabellen; `anon` hat keine Tabellenrechte. Die beiden öffentlichen RPCs sind für `authenticated` ausführbar und für `anon`/ `service_role` nicht; interne Helfer sind für API-Rollen nicht ausführbar. `service_role` behält seine privilegierten Supabase-Tabellenrechte.
- **Award-RPC:** Paket-8-Source-Erweiterung nachgewiesen; Owner `postgres`, SECURITY DEFINER, fester search_path `pg_catalog, public, auth`; EXECUTE nur für `authenticated` unter den geprüften API-Rollen.
- **Daten:** 0 Reset-Zeilen, 0 Audit-Zeilen, 1 aktive Saison, 0 offene Sperren. Keine fachlichen Daten durch die Migration erzeugt oder verändert.
- **Advisor:** Health ohne Findings. Security Advisor 52 SECURITY DEFINER-Warnungen (zuvor 50; zwei neue, beabsichtigte Paket-8-RPCs), eine bestehende mutable-search_path-Warnung (`public.set_updated_at`) und deaktivierter Leaked-Password-Schutz.
- **Rollback:** nicht ausgeführt; guarded Rollback bleibt unter den dokumentierten Leerstands-/Abhängigkeitsbedingungen verfügbar.
- **Keine Änderungen:** DEV, GitHub `main` und Frontend-Index blieben unverändert.

**Maßgeblicher Status:** Paket 8 ist in PROD erfolgreich installiert und strukturell/berechtigungsseitig nachkontrolliert. Fachliche Browser-/Session-Praxistests sind weiterhin getrennt durchzuführen; die isolierte CI ersetzt diese nicht.
