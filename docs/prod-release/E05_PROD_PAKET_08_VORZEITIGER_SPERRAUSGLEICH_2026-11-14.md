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
- **Lauf:** [GitHub Actions 43645493709](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43645493709)
- **Commit:** `3a11540baede304fb69c484a47272a6c7da4560e`
- **Ergebnis:** `success`.
- **Testumgebung:** kurzlebiger PostgreSQL-17.6-Container mit synthetischer Minimal-Baseline; keine Verbindung zu Supabase DEV oder PROD.
- **Erfolgreich geprüft:** exakte Paket-8-Migration; Tabellen/RLS/Policies; öffentliche RPC-EXECUTE-Rechte und gesperrte interne Helfer; Source-Transformation der bestehenden Paket-2-Award-RPC; Anwendung bei `done`; automatische Stornierung bei nachträglicher Nominierung; automatische Stornierung bei Spieltagsabsage; Ablehnung eines bereits nominierten Spielers; genau einmaliger Anwendungs-Audit; leerer Datenbestand nach Rollback der Testtransaktion; guarded Paket-8-Rollback und Rückkehr des ursprünglichen Award-Source-Blocks.
- **Testgrenze:** Die CI-Baseline bildet die für Paket 8 erforderlichen Datenbankobjekte minimal nach. Sie ersetzt weder einen vollständigen Supabase-Auth-/RLS-End-to-End-Test noch die unmittelbare Live-Preflight-Prüfung in PROD. Die fachlichen DEV-Tests aus der Paket-8-Abnahme bleiben die maßgebliche Praxistestgrundlage.

## 8. Unveränderliche Artefakt-Referenzen

- Migration: `supabase/migrations/20261114230000_e05_prod_paket_08_early_suspension_reset.sql`, Blob-SHA `898ded0944f7dcf175765f0b700f89f8cfdbf4b2`.
- Rollback: `supabase/rollback/20261114230000_e05_prod_paket_08_early_suspension_reset_rollback.sql`, Blob-SHA `3068e34095c3fd28d1ecf58842394baddb58bae6`.
- Dossier liegt auf `develop`; CI-Workflow-Blob-SHA `03dc5438cc95b48a2820f2feff38661cd71bb856`.

**Aktueller Status:** Technisch vorbereitet und isoliert erfolgreich getestet; zur abschließenden Prüfung und ausdrücklichen PROD-Ausführungsfreigabe vorgelegt. Noch nicht ausgeführt. Keine Änderung an Supabase DEV, Supabase PROD oder GitHub `main` im Rahmen dieser Vorbereitung.
