# AP-BR02 – Restore-Executor V1: technische Entwurfsgrenzen

Stand: 28.11.2026  
Branch: develop  
Status: **Entwurf / Dokumentation only – kein Executor, kein SQL, keine DB-/Storage-Schreiboperation**

## Ausgangslage und bestätigte Gates

- KADB-Paket lokal entschlüsselt und geprüft; tatsächlicher DEV-Zielabgleich vom Nutzer bestätigt: Ergänzungen 0, Aktualisierungen 0, Beibehalten 655, Konflikte 0, Never-delete 655.
- Read-only Zielpreview antwortete vollständig mit `write_count=0`; kein Restore wurde ausgeführt.
- Isolierter Newer-wins-Browser-Test: 5/5 PASS. Contract-/Handler-CI-Gates und DEV-Deployment sind in den Status-Handoff-Einträgen dokumentiert.
- V1 bleibt Same-scope-only. Legacy-JSON-`replaceTeamDataWithBackup()` ist destruktiv und ausdrücklich kein KADB-Restore-Pfad.

## V1-Sicherheitsinvarianten

1. Vor jedem Schreibversuch: Paketformat/Version, vollständige Archivprüfung, exakter Same-scope-Kontext und aktuelle serverseitige Berechtigung erneut validieren.
2. Den vom Client übermittelten Preview-Plan niemals als vertrauenswürdige Write-Anweisung behandeln. Server muss aus validiertem Manifest und aktuellem Zielbestand einen frischen Plan erzeugen oder einen signierten/kurzlebigen, serverseitig gebundenen Planbeleg prüfen.
3. **Never-delete:** kein DELETE, kein Tabellenersatz, kein Entfernen von Datensätzen/Relationen, die im Paket fehlen.
4. **Insert-only** für Relationen, Empfehlungen und fachliche Historien gemäß Mapping. Identitäts-/Scope-Felder sowie Actor-IDs nie ändern oder remappen.
5. Newer-wins nur auf explizit freigegebenen mutable Tabellen-/Feldgruppen, mit gültigem `updated_at`-Vergleich beider Seiten. `created_at` ist kein Änderungsmarker; Ziel-Updated-At wird durch DB-Trigger/Zielsystem verwaltet.
6. Keine Teilanwendung: Validierungs-/Constraint-/FK-Fehler müssen vor dem ersten Write erkannt werden; Paketänderungen müssen atomar oder mit dokumentierter sicherer Wiederherstellungsstrategie behandelt werden.
7. Assets bleiben separat. Ohne vollständig geprüften Asset-Plan keine Übernahme von `photo_path`/`photo_data`; keine Storage-Schreiboperation in V1-DB-Executor.
8. Keine Auth-User, Profile, Rollen oder Mitgliedschaften aus dem Backup erzeugen.

## Tabellenstrategie – aus dem Restore-Mapping übernommen

- Stammdaten: nur konkrete Insert-Allowlist; Update nur gemäß expliziter V1-Whitelist und Newer-wins.
- Join-/Teilnahmezeilen: fehlende Relation ergänzen, bestehende behalten; keine generischen Updates.
- Recommendation-Runs/-Children: Insert-only; zusätzliche Unique-Keys (insbesondere Matchday/Rank) als Konflikt behandeln, nicht ersetzen.
- Behavior-/Suspension-/Exception-/Reset-/Reminder-/Season-Closure-Historie: Insert-only; vorhandene Ereignisse nicht überschreiben.
- Game-Type-Settings/-Relations: korrekte DEV-Keys `team_id` und `team_id + game_type`; nur nach Scope-/Constraint-Validierung.
- Matchday-Status: Update in V1 standardmäßig sperren bzw. Konflikt behalten, da Status-Trigger fachliche Sperren-Reconciliation auslösen können.
- Player `active` und `team_id`: nicht durch Restore ändern; bestehende Schutztrigger respektieren.

Die vollständigen Exportfelder und schema-basierten Kandidaten stehen im Dokument `AP_BR02_RESTORE_MAPPING_READONLY_2026-11-25.md`. Dieses Dokument ersetzt keine erneute Schema-/Constraintprüfung unmittelbar vor einer späteren Schreibfreigabe.

## Transaktions-/Executor-Architektur – noch zu verifizieren

Supabase-REST-Aufrufe über mehrere Tabellen sind kein paketweiter atomarer Commit. Für einen echten Restore ist deshalb ein serverseitiger, eng begrenzter transaktionaler Anwendungspfad erforderlich. Als Architekturhypothese ist ein einzelner DB-RPC/SQL-Transaktionsaufruf zu prüfen, der:

- den authentifizierten Nutzer und den exakten Teamkontext serverseitig validiert;
- ausschließlich eine fest definierte Tabellen-/Feld-Allowlist akzeptiert;
- alle FK-/Unique-/Actor-/Status-/Asset-Gates vorab prüft;
- Inserts und erlaubte Updates in definierter Parent-Child-Reihenfolge in **einer Transaktion** ausführt;
- bei jedem Fehler vollständig zurückrollt;
- ein Ergebnisprotokoll mit Add/Update/Keep/Conflict und einer stabilen Restore-ID zurückgibt;
- idempotente Wiederholung ohne Doppelimporte ermöglicht.

**Wichtig:** Eine `SECURITY DEFINER`-RPC ist nicht automatisch sicher. Vor Umsetzung müssen Function-Owner, `search_path`, EXECUTE-Rechte, Authentifizierungsprüfung, Scope-Gate und mögliche RLS-Bypasswirkung explizit reviewed werden. Service-Role oder Definer-Rechte dürfen keine clientgesteuerte Tabellen-/Spaltenauswahl ermöglichen.

## Noch offene Pflichtentscheidungen / Validierungen vor Code

1. Exakte Insert- und Update-Spaltenliste pro Tabelle als versionierter Executor-Vertrag; kein blindes `row`-JSON in SQL weiterreichen.
2. Actor-/Trainer-FK: vorhandene Identität und Kontextzugehörigkeit prüfen; fehlende Pflichtreferenz blockiert. Für optionale Actor-Felder muss explizit festgelegt werden, ob Konflikt oder gezieltes NULL zulässig ist.
3. DB-Trigger: insbesondere Player-Schutz, Updated-At-Trigger und Matchday-Status-/Sperren-Trigger. Keine fachliche Nebenwirkung ungeprüft auslösen.
4. Unique-Konflikte anhand PK **und** zusätzlicher Unique-Constraints vollständig vorplanen.
5. Asset-Plan (Hash, Referenz, Zielpfad, bestehende Datei, fehlende Referenz) bleibt separates Gate.
6. Maximaler Payload-/Restore-Umfang und sichere iPhone-UX für Bestätigung/Abbruch.
7. Recovery-/Idempotenzkonzept und nachvollziehbares Ergebnisprotokoll.

## Nächste kontrollierte Umsetzung

1. Read-only Constraint-/Trigger-/FK-Revalidierung für den finalen Tabellenvertrag.
2. Pure, synthetische Write-Plan-Fixtures (Add, Newer-update, Older-keep, Insert-only collision, Unique collision, bad FK, actor missing, scope mismatch, no deletes).
3. RPC-/Transaktionsentwurf einschließlich Security Review und minimalem DEV-Testplan.
4. Erst nach separater Freigabe: SQL-/RPC-Implementierung und ausschließlich isolierter DEV-Write-Test mit synthetischen Fixtures oder ausdrücklich autorisiertem Testteam.
5. Kein PROD-Release ohne separate Freigabe und dokumentiertes Migrations-/Releasepaket.

## Änderungsgrenze dieses Commits

Nur diese Spezifikation auf `develop`. Kein App-Code, kein Edge-Function-Deployment, kein SQL, keine Migration, keine DB-/Storage-Schreiboperation, kein Restore und keine PROD-Änderung.


## DEV-Schema-Gate 1 – Constraints und fachliche Trigger (28.11.2026)

**Read-only in Supabase DEV** (Projekt pzazqvvoruqnqhcorbwx) geprüft; keine Migration, kein DDL und keine Datenänderung. Grundlage: PostgreSQL-Katalogabfrage der AP-BR02-Tabellen sowie verbose Table-Metadaten.

### Bestätigte Schreib-Risiken, die der Planer vorab abfangen muss

- matchday_recommendation_runs: UNIQUE auf matchday_id zusätzlich zum PK. Ein zweiter Run für denselben Spieltag ist kein gewöhnliches Add; als Konflikt behalten.
- matchday_recommendation_players: UNIQUE auf (recommendation_id, rank) zusätzlich zum zusammengesetzten PK. Rang-Kollision darf nicht durch Update/Replace gelöst werden.
- positions: UNIQUE auf (team_id, name); seasons: UNIQUE auf (team_id, name); Namenskonflikte bei abweichender UUID müssen vor Anwendung als Konflikt ausgewiesen werden.
- team_season_closure_audit: UNIQUE auf season_id, FK mit ON DELETE RESTRICT und Mutation-Blocker-Trigger für UPDATE/DELETE/TRUNCATE. Für V1 strikt insert-only; bestehende Saisonabschluss-Auditzeile nicht verändern.
- matchday_players: INSERT/Änderung löst Aktiv-Spieler- und Sperrenprüfung aus; weitere AFTER-Trigger können Early-Reset-/Reminder-Ereignisse reconciliieren. Diese Tabelle bleibt im V1-Executor gesperrt bzw. nur als vorher geprüfte Insert-Operation mit expliziter Trigger-Auswirkungsprüfung.
- matchdays: Status-UPDATE triggert Early-Reset-Reconciliation; zusätzlich updated_at-Trigger. Statusänderungen bleiben im V1-Executor gesperrt.
- players: team_id-Änderung und active-Änderung werden durch Schutztrigger verhindert/geschützt; updated_at wird durch Trigger gesetzt. Diese Felder nicht restore-seitig schreiben.
- training_players und matchday_players: Zuweisungen an inaktive Spieler werden durch Trigger blockiert. Vorab muss der Zielspieler aktiv und dem selben Scope zugeordnet sein.
- matchday_nomination_reminders und matchday_early_suspension_resets: Status-/Snapshot-/Reason-Checks sowie Actor-FKs; bei fehlender Referenz oder inkonsistentem Status als Konflikt blockieren, nicht automatisch umformen.
- Child-Relationen mit ON DELETE CASCADE bekräftigen Never-delete: der Executor darf keine Delete-/Replace-Strategie verwenden, da dies sonst fachliche abhängige Daten entfernen könnte.

### Konsequenz für den nächsten Schritt

Der schema-basierte Gate bestätigt, dass die V1-Whitelist nicht nur nach Tabellen, sondern auch nach **Operation und Triggerwirkung** unterscheiden muss. Der nächste Arbeitsschritt ist deshalb ein reiner, synthetischer Write-Plan-Vertrag mit expliziten Operationen (insert, erlaubtes update, keep, conflict, blocked) und Fixtures für die oben genannten Unique-/FK-/Triggerfälle. Noch kein RPC-/SQL-Executor und keine realen Writes.

### Änderungsgrenze

Diese Ergänzung dokumentiert ausschließlich die read-only DEV-Prüfung. Kein App-Code, kein SQL/DDL, keine Migration, kein DB-/Storage-Write, kein Restore und keine PROD-Änderung.
