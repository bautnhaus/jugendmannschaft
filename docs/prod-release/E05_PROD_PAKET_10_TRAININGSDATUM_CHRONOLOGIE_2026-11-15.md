# E05 PROD Paket 10 – Trainingsdatumsbasierte Kartenchronologie und Sperrenziele

- **Status:** Technisch vorbereitet; PROD-Freigabe steht aus.
- **Ziel:** Supabase PROD, Projekt qdugtpzgefpswnnqbusd.
- **Entwicklungs-/Dokumentationsbranch:** develop.
- **Vorgesehene Katalognummer:** DB-MIG-2026-021.
- **PROD-Migration:** 20261115090000_e05_prod_paket_10_training_date_suspension_chronology.
- **PROD-Ausführung:** Noch nicht erfolgt.
- **Backup:** Kein Backup-/PITR-Schritt vorgesehen; der bisherige PROD-Release-Prozess ohne Backupoption wird fortgeführt.

## 1. Abgrenzung des Pakets

Die Bezeichnung „Paket 10“ bündelt die finalen DEV-Funktionsstände aus:
- DB-MIG-2026-008 / DEV-Migration 20261111161403: Trainingsdatumsbasierte Gelbkartenchronologie.
- DB-MIG-2026-010 / DEV-Migration 20261112055415: Alle geplanten Spieltage als Sperrziele, unabhängig von game_type.

Die aktuelle DEV-Live-Definitionen wurden am 15.11.2026 ausgelesen und als vollständige Funktionsdefinitionen in eine einzige atomare PROD-Migration übernommen.

**Nicht enthalten:**
- DB-MIG-2026-009: zwei read-only RPCs für die Spielarten-Verwaltungsoberfläche. Im aktuellen develop/index.html gibt es keine Aufrufe dieser RPCs; nach der späteren fachlichen Entscheidung, alle geplanten Spieltage unabhängig von game_type zu berücksichtigen, sind sie für die Sperrenlogik nicht erforderlich. Sie werden nicht als ungenutzte API-Oberfläche nach PROD übertragen.
- DB-MIG-2026-011: Sperrprüfung bei Kaderempfehlung/Nominierung. Das ist ein separates Paket. Die PROD-Bestandsprüfung zeigt bereits einen Trigger namens matchday_players_prevent_suspended_nomination, aber save_matchday_recommendation enthält in PROD noch keine Sperrenprüfung. Diese gemischte Ausgangslage wird separat behandelt und nicht mit Paket 10 vermischt.

## 2. Verbindliche Fachregeln

**Maßgebliche spätere Fachentscheidung:** Die am 12.11.2026 mit DB-MIG-2026-010 umgesetzte Vereinfachung wurde vom Projektverantwortlichen im Nachgang ausdrücklich bestätigt, um die Komplexität zu reduzieren. Sie ersetzt entgegenstehende frühere Entwürfe und Freigabetexte: Jeder geplante Spieltag ist sperrenrelevant, unabhängig von der Spielart (einschließlich NULL). Vereins- und Mannschaftseinstellungen zu sperrenrelevanten Spielarten werden für die Sperrenlogik nicht mehr ausgewertet.


1. Aktive gelbe Karten werden je Spieler, Mannschaft und Saison nach training_date_snapshot ASC, id ASC chronologisch ausgewertet.
2. awarded_at ist ausschließlich Erfassungs-/Auditzeitpunkt und bestimmt nicht die Kartenreihenfolge.
3. Stornierte Karten zählen nicht; wiederhergestellte Karten zählen wieder.
4. Die fünfte aktive Karte nach Trainingsdatum löst eine gelbe Sperre aus.
5. Gelbe Sperre und rote Sperre erhalten das Trainingsdatum des auslösenden Ereignisses als Chronologie-Anker.
6. Zielspieltag muss strikt nach dem Auslösertraining liegen: match_date > training_date_snapshot.
7. Automatische Zuordnung wählt den ersten geplanten Spieltag derselben Mannschaft und Saison nach dem Auslösertraining, der noch nicht anderweitig reserviert und nicht durch eine aktive Ausnahme ausgeschlossen ist.
8. Alle geplanten Spieltage sind zulässig – unabhängig von game_type, einschließlich NULL.
9. Manuelle Zielzuordnungen bleiben geschützt, solange sie gültig sind.
10. Die manuelle Korrektur prüft weiterhin Berechtigung, Team, Saison, Datum, aktive Ausnahme, doppelte Zielbelegung, Begründung und Audit.
11. Die bestehende Reset-Untergrenze bleibt erhalten: zuletzt abgeleistete gelbe Sperre bzw. zuletzt angewandter vorzeitiger Sperrausgleich. Der Vergleich erfolgt nun konsistent anhand der Spieltags-/Trainingsdaten.
12. Bereits abgeleistete oder abgelaufene Sperren werden durch die Kartenkorrektur nicht rückwirkend wieder geöffnet.
13. Ein abgeschlossener Spieltag kann Sperren ableisten, unabhängig von game_type; nach Ableistung werden verbleibende offene Sperren neu zugeordnet.

## 3. DEV-Befund

Supabase DEV Migrationshistorie:
- 20261111161403 – e05_package_10_training_date_suspensions.
- 20261111180619 – e05_suspension_game_type_settings_read_rpcs.
- 20261112055415 – e05_all_matchdays_suspension_targets.
- 20261112181910 – 20261112191000_e05_suspension_nomination_guard.
- 20261113035705 – e05_atomic_exception_revocation_20261113.

Die fünf für Paket 10 relevanten Funktionsdefinitionen wurden live aus DEV gelesen:
- award_training_behavior_event(uuid,uuid,text,text)
- e05_assign_player_suspensions(uuid,uuid,uuid)
- e05_reconcile_suspensions_after_event_correction(uuid,uuid,text)
- correct_suspension(uuid,uuid,text)
- serve_matchday_suspensions(uuid)

Aktuelle DEV-Datenprüfung (read-only, 15.11.2026):
- 23 Trainingsereignisse, darunter 11 aktive und 1 stornierte gelbe Karte.
- 7 Sperren, alle offen.
- 3 manuell geschützte Zielzuordnungen.
- 0 offene Sperren ohne Ziel.
- 0 offene Zielzuordnungen, deren Spieltag fehlt, nicht geplant ist oder nicht strikt nach dem Trainingsdatum liegt.
- 0 Abweichungen zwischen der berechneten fünften aktiven gelben Karte und source_event_id der offenen gelben Sperre.

Damit ist der aktuelle DEV-Datenbestand mit der finalen Trainingsdatum-Chronologie konsistent. Dies ist eine Read-only-Diagnose, kein Ersatz für einen kontrollierten Funktions-/End-to-End-Test.

## 4. PROD-Live-Preflight (15.11.2026)

Supabase PROD nach Paketen 1–9:
- E05-Paket-8-Früh-Sperrausgleich vorhanden.
- Paket-9-Spalte manual_target_locked und Audit-Snapshot-Spalten vorhanden.
- Die fünf Zielsignaturen sind vorhanden.
- award_training_behavior_event ist noch Paket-8-Verhalten und verwendet die bisherige Erfassungszeit-Chronologie; es integriert die spätere gemeinsame Reconciliation noch nicht.
- e05_assign_player_suspensions und correct_suspension enthalten noch die Spielartenfilterung aus Paket 9.
- e05_reconcile_suspensions_after_event_correction verwendet noch awarded_at für die gelbe Kartenfolge.
- serve_matchday_suspensions enthält noch die Spielartenprüfung.
- PROD hat 0 Trainingsereignisse, 0 Sperren und 0 offene Sperren.
- DB-MIG-008 und DB-MIG-010 sind in PROD nicht registriert.

Der Preflight in der Migration bricht ab, wenn diese erwartete Paket-8-/Paket-9-Baseline nicht mehr vorliegt. Er führt keine Datenänderung aus.

### Aktueller technischer Abgleich (15.11.2026)

- Die fünf Live-Funktionsdefinitionen in DEV wurden erneut read-only ausgelesen. Ihre Längen stimmen mit den fünf in der PROD-Migration enthaltenen DEV-Zieldefinitionen überein: 6.436 / 6.797 / 16.506 / 6.042 / 3.903 Zeichen.
- Alle fünf DEV-Funktionen sind weiterhin `SECURITY DEFINER`, gehören `postgres` und verwenden den festen `search_path = pg_catalog, public, auth`.
- Der PROD-Preflight wurde read-only gegen die fünf aktuellen PROD-Funktionen geprüft: Alle fünf erwarteten Paket-8-/Paket-9-Ausgangsmerkmale treffen zu.
- Die PROD-Migrationshistorie enthält Paket 1 bis 9; Paket 10 ist dort noch nicht registriert.
- PROD enthält derzeit 0 Trainingsereignisse, 0 Sperren und 0 offene Sperren. Die erforderlichen Ausnahme-/Früh-Reset-Tabellen und Paket-9-Spalten sind vorhanden.
- Der Funktions-/Sicherheitsabgleich bestätigt: PROD-Funktionen sind `SECURITY DEFINER`, Eigentümer `postgres`, fester `search_path`; EXECUTE ist für `authenticated` nur auf den drei vorgesehenen öffentlichen RPCs vorhanden, nicht für `anon` und nicht auf den internen Hilfsfunktionen.

## 5. Migrationsumfang

Die PROD-Migration ersetzt ausschließlich die vollständigen Definitionen der fünf vorhandenen Funktionen. Keine Tabellen, Spalten, Daten, Trigger, Policies, RLS-Einstellungen oder Grants werden geändert.

Die CREATE OR REPLACE FUNCTION-Operationen erhalten die bestehenden Funktions-Owner und ACLs. Preflight und Postflight kontrollieren SECURITY DEFINER, festen search_path und EXECUTE-Rechte.

## 6. Rollback

Die Rollback-Datei enthält die am 15.11.2026 read-only aus PROD ausgelesenen Originaldefinitionen der fünf Funktionen vor Paket 10. Sie ist funktionsbezogen und ändert keine Tabellen oder Daten.

Rollback nur nach gesonderter Freigabe und nur, wenn die fünf Funktionen seit Paket 10 nicht durch spätere Migrationen verändert wurden. Die Rücknahme stellt die alte Spielartenfilterung und Erfassungszeit-Chronologie wieder her; sie ist daher keine neutrale technische Aktion.

## 7. Isolierte PostgreSQL-CI

Workflow: .github/workflows/e05-prod-package-10-ci.yml

**Finaler Lauf:** [GitHub Actions Run 43681502047](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43681502047) – **success** (PostgreSQL 17.6).

Erfolgreich durchlaufen:
- Isolierte Paket-8-PROD-Baseline.
- Exakte Paket-8-Migration.
- Exakte Paket-9-Migration.
- Exakte Paket-10-Migration.
- Chronologie-, Zielspieltag-, ACL-, RLS-, Trigger-/Policy- und Datenerhalt-Assertions.
- Guarded function-only rollback.
- Rollback-Assertions: Paket-9-Verhalten vollständig wiederhergestellt.

Zwei vorherige CI-Anläufe scheiterten ausschließlich an der Testhülle: zunächst fehlte die Paket-8-/Paket-9-Migrationsbaseline; anschließend wurden persistente CI-Snapshots nicht mit ihrem Schema-Präfix referenziert. Beides wurde korrigiert. Der finale Lauf bestand vollständig; die Migration selbst wurde in der finalen CI erfolgreich angewendet.

Testsequenz:
1. Isolierte PostgreSQL-17.6-Testdatenbank.
2. Paket-8-PROD-Baseline anwenden.
3. Paket-9-PROD-Baseline ergänzen und Paket-9-Migration anwenden.
4. Paket-10-Migration anwenden.
5. Trainingsdatums-Chronologie, Zielspieltaggrenzen, all-matchday-Regel, SECURITY DEFINER, search_path, ACLs, RLS, Trigger-/Policy-Unverändertheit und Datenerhalt prüfen.
6. Guarded Rollback anwenden.
7. Prüfen, dass die Paket-9-Funktionslogik vollständig wiederhergestellt wurde.

**Testgrenze:** Der CI-Lauf ist ein isolierter PostgreSQL-Struktur-/Funktionsdefinitions-/ACL-Test. Er führt keine authentifizierten Supabase-Nutzer-Sessions durch und ersetzt keine DEV-Praxistests.

## 8. Noch offene Punkte

- Frontend-Auswahlliste für manuelle Sperrenkorrektur: aktuell lädt sie geplante Spieltage ab current_date, nicht erst strikt nach dem Trainingsdatum des auslösenden Ereignisses. Die Datenbank weist unzulässige Ziele korrekt zurück; die UI sollte die Liste nach dem Auslöserdatum filtern. Diese Frontendänderung erfolgt separat auf develop, nachdem die Datenbankmigrationen abgeschlossen sind.
- **DEV-Praxistests:** Der Projektverantwortliche hat am 15.11.2026 bestätigt, dass die vorgesehenen Paket-10-Tests in DEV durchgeführt wurden. Die frühere Kennzeichnung als offen in den älteren Paket-10-Unterlagen ist damit überholt. Die Testergebnisse sind als DEV-Abschluss zu behandeln; PROD bleibt davon getrennt.
- DB-MIG-2026-011 bleibt als separates Paket zu prüfen; PROD hat bereits einen Nominierungs-Trigger, aber keine Sperrprüfung in save_matchday_recommendation.

## 9. Ausführungsreihenfolge nach Freigabe

1. Unmittelbar vor Ausführung den PROD-Preflight erneut vollständig read-only prüfen.
2. Ausschließlich die Datei `supabase/migrations/20261115090000_e05_prod_paket_10_training_date_suspension_chronology.sql` einmalig in Supabase PROD ausführen.
3. Bei einem Fehler die Transaktion vollständig abbrechen lassen; keine Teilmigration nacharbeiten, bevor Ursache und Live-Stand geprüft wurden.
4. Postflight und die Read-only-Prüfungen aus `docs/prod-release/test-package-10/assertions.sql` sinngemäß gegen PROD ausführen; CI-Testdaten-Snapshot-Assertions werden nicht ungeprüft in PROD übernommen.
5. Migrationshistorie, Funktionssignaturen, SECURITY DEFINER/search_path/Owner/ACLs, RLS, Trigger/Policies und Datenbestand kontrollieren.
6. Ergebnis als DB-MIG-2026-021 in `DB_MIGRATION_LOG.md` protokollieren. Erst danach separat über Frontend-Anpassungen bzw. Release entscheiden.

Rollback ist **kein automatischer Fehlerpfad**. Er benötigt eine neue ausdrückliche Freigabe und darf nur ausgeführt werden, wenn seit Paket 10 keine spätere Migration dieselben fünf Funktionen verändert hat.

## 10. Freigabestatus

- Migration, funktionsbezogener Rollback, Read-only-Testqueries, CI-Testfixture und dieses Dossier liegen auf develop.
- DB-MIG-2026-021 ist die vorgesehene PROD-Katalognummer.
- Supabase DEV wurde im Rahmen dieser Vorbereitung nicht verändert.
- Supabase PROD wurde ausschließlich lesend geprüft; keine Migration ausgeführt.
- GitHub main und Frontend-Index bleiben unverändert.
- **Paket 10 ist fachlich und technisch zur PROD-Freigabe bereit.** Die ausdrückliche Freigabe zur Ausführung der PROD-Migration steht noch aus. Diese Freigabe umfasst ausschließlich die oben genannte Datenbankmigration und die unmittelbare Verifikation. Sie umfasst weder Rollback noch Frontend-/GitHub-main-/PROD-Deployments.
