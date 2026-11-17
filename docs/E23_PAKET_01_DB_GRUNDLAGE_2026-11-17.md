# Epic 23 – Paket 1: Datenbank-Grundlage für Nominierungsvormerkungen

**Stand:** 17.11.2026  
**Zielumgebung:** Supabase DEV (Projekt pzazqvvoruqnqhcorbwx)  
**Status:** Migration erfolgreich in Supabase DEV ausgeführt und strukturell read-only verifiziert. Funktionstests stehen noch aus.  
**PROD:** ausdrücklich nicht betroffen.

## Enthaltene Dateien

- Migration: `supabase/migrations/20261117120000_epic23_nomination_reminder_foundation_dev.sql`
- Guarded Rollback: `supabase/rollback/20261117120000_epic23_nomination_reminder_foundation_rollback.sql`
- Read-only Postflight: `docs/E23_PAKET_01_VERIFICATION_2026-11-17.sql`
- DEV-Testplan: `docs/E23_PAKET_01_DEV_TESTPLAN_2026-11-17.md`

## Paketumfang

1. `matchday_nomination_reminders`: Status-/Historientabelle für pending, fulfilled und cancelled.
2. `matchday_nomination_reminder_audit`: append-only Audit mit Actor, Zeitstempel, Begründung und Zustandsübergang.
3. RLS: Teammitgliedschaft oder expliziter Superadmin-Teamkontext für SELECT; keine direkten Client-Schreibrechte.
4. Create-RPC `create_matchday_nomination_reminder(uuid,uuid,text,boolean)`.
5. Cancel-RPC `cancel_matchday_nomination_reminder(uuid,text)`.
6. Trigger zur Erfüllung bei einer nach Erstellung erfolgenden tatsächlichen Nominierung auf einem späteren Spieltag derselben Mannschaft.

## Fachliche Semantik

- Spieler muss aktiv sein und derselben Mannschaft angehören wie der Ausgangsspieltag.
- Trainer bestätigt die Verfügbarkeit im Dialog; der RPC-Parameter muss ausdrücklich TRUE sein.
- Falls am Ausgangsspieltag bereits eine Nominierungszeile existiert, prüft der RPC zusätzlich deren `available`-Feld auf TRUE. Eine vorhandene Zeile mit `available=false` wird abgelehnt.
- Falls keine Nominierungszeile existiert, ist die Verfügbarkeitsbestätigung eine ausdrückliche manuelle Bestätigung durch den Trainer; die aktuelle Datenbank hält für nicht nominierte Spieler an dieser Stelle keinen separaten Verfügbarkeitsdatensatz vor.
- Spieler muss am Ausgangsspieltag nicht nominiert sein.
- Ist er dort nominiert und noch nicht als gespielt markiert, wird genau diese Nominierungszeile innerhalb derselben Transaktion entfernt und vorher als JSON-Snapshot gesichert.
- Ist er dort nicht nominiert, erfolgt keine Löschung.
- Eine Nominierung auf einem anderen zukünftigen Spieltag verhindert die Vormerkung nicht und erfüllt sie nicht rückwirkend.
- Ein tatsächlich neu angelegter Nominierungseintrag auf einem späteren Spieltag derselben Mannschaft erfüllt eine offene Vormerkung.
- Rücknahme benötigt eine Begründung; eine entfernte Ausgangsnominierung wird nicht automatisch wiederhergestellt.
- Pro Spieler und Mannschaft ist maximal eine offene Vormerkung vorgesehen.

## Sicherheits- und Transaktionshinweise

- Create/Cancel sind eng begrenzte SECURITY DEFINER-RPCs mit festem search_path, Authentifizierungsprüfung und expliziter Trainer-/Admin-/Superadmin-Kontextprüfung.
- PUBLIC/anon erhalten kein EXECUTE; authenticated erhält nur EXECUTE auf den beiden Nutzer-RPCs.
- Tabellen haben RLS; Client erhält nur SELECT. Direkte INSERT/UPDATE/DELETE-Rechte werden entzogen.
- Create sperrt denselben spielerbezogenen Advisory-Lock wie der bestehende Sperren-/Nominierungs-Guard.
- Reminder-INSERT, optionale Ausgangsnominierungs-DELETE und Audit-INSERT liegen in einer PostgreSQL-Transaktion. Ein Fehler rollt alles zurück.
- Das Erfüllungs-Triggerereignis ist auf INSERT bzw. Änderung von matchday_id/player_id beschränkt. Änderungen an team_number, goalkeeper oder played erfüllen nicht.
- Audit-UPDATE/DELETE/TRUNCATE wird blockiert.

## Bekannte Prüfgrenzen vor Ausführung

- Das SQL ist statisch gegen den aktuell ausgelesenen DEV-Schema- und Funktionsstand erstellt. Es wurde nicht in PostgreSQL ausgeführt oder syntaktisch durch den Zielserver validiert.
- SECURITY DEFINER-Owner und ACL müssen nach Ausführung per Postflight kontrolliert werden.
- Das Triggerverhalten unter echter Konkurrenz ist erst nach Paket-1-Test nachgewiesen.
- Die Frontendintegration, Empfehlungsvorrang und Backup-Version 13 sind nicht Teil dieses Pakets. Diese folgen nach erfolgreicher Datenbankabnahme in getrennten Paketen.
- Es wurde keine bestehende E05-Funktion, Policy oder Tabelle geändert.

## Ausführungsnachweis

- Supabase DEV Migration: erfolgreich am 17.11.2026.
- Ledger-Version: `20261117123114`; Name: `epic23_nomination_reminder_foundation_dev`.
- Read-only Postflight: beide Tabellen vorhanden, RLS aktiv, zwei SELECT-Policies vorhanden, beide Trigger aktiv, Create-/Cancel-RPCs SECURITY DEFINER mit Owner `postgres` und festem `search_path`; EXECUTE nur für `authenticated` (nicht `anon`/PUBLIC).
- Tabellenrechte: `authenticated` hat SELECT; keine direkten Client-Schreibrechte. Service role behält administrative Rechte.
- Datenbestand nach Migration: 0 Vormerkungen und 0 Audit-Einträge.
- Funktionale RPC-/Trigger- und RLS-Negativtests sind noch offen.

## Ausführungsreihenfolge

1. DEV-Snapshot/aktuellen Schema-Stand sichern.
2. Migration Paket 1 in Supabase DEV ausführen.
3. Read-only Postflight ausführen und Ergebnisse dokumentieren.
4. DEV-Testplan vollständig abarbeiten.
5. Fehler korrigieren, Migration/Tests aktualisieren und Paket erneut verifizieren.
6. Erst nach Paket-1-Abnahme Paket 2 (Empfehlungsintegration/Frontend) vorbereiten.

## Rollback

Der Rollback ist absichtlich guarded und bricht ab, sobald Reminder- oder Auditdaten vorhanden sind. Historie wird nicht automatisch gelöscht. Bei Datenbestand ist zuerst ein gesonderter Export-/Wiederherstellungsplan erforderlich.

**Keine Ausführung:** Die Dateien in diesem Dossier sind Vorbereitungsartefakte. Die DEV-Ausführung erfolgt erst nach gesonderter ausdrücklicher Freigabe.


## Testergebnis

Die isolierten DEV-Funktionstests und RLS-Tests vom 17.11.2026 sind nach Hotfix 1 mit 14/14 Assertions erfolgreich. Die Testdaten wurden in jeder Testtransaktion zurückgerollt. Nicht getestet wurden echte parallele Sessions, gezielte RPC-Rollback-Fehler sowie alle Superadmin-/Nichtberechtigten-Rollenvarianten. Details: `docs/E23_PAKET_01_DEV_TESTPLAN_2026-11-17.md`.


## Ergänzende technische Tests – 17.11.2026, Runde 2

- **Parallele Create-Aufrufe:** zwei getrennte Supabase-SQL-Aufrufe für denselben Spieler wurden zeitlich überlappend gestartet. Genau ein Create wurde erfolgreich; der zweite wurde wegen bereits offener Vormerkung abgelehnt. PASS.
- **Create parallel zu späterer Nominierung:** erster Versuch mit vertauschter Reihenfolge der Testspieltage war nicht aussagekräftig und wurde als Testaufbaufehler verworfen. Nach Korrektur (Ausgangsspieltag 18.11.2026, späterer Spieltag 25.11.2026) wurde die Vormerkung bei parallelem Create/INSERT korrekt auf fulfilled gesetzt. Dafür war Hotfix 2 nötig: der Fulfillment-Trigger nimmt jetzt denselben spielerbezogenen Advisory-Lock wie die Create-RPC. PASS nach Hotfix 2.
- **Hotfix 2:** `supabase/migrations/20261117150000_epic23_nomination_reminder_concurrency_hotfix_dev.sql`, erfolgreich in DEV ausgeführt.
- **Audit DELETE:** blockiert durch append-only-Trigger. PASS.
- **Audit TRUNCATE:** blockiert durch append-only-Trigger. PASS.
- **Unberechtigter Cross-Team-RPC-Aufruf:** mit einem Benutzer aus einer anderen Mannschaft getestet; Create wurde mit „Keine Berechtigung für diese Mannschaft“ abgelehnt. PASS.
- **Wichtige Testkorrektur:** ein zunächst verwendeter Testaccount war bereits Mitglied der temporären Testmannschaft und war daher nicht unberechtigt. Der negative Berechtigungstest wurde mit einem anderen Account wiederholt.
- **RPC-Fehler-/Rollback mitten in der Transaktion:** nicht gezielt provoziert. Das erfordert einen kontrollierten Fehler zwischen Reminder-INSERT, optionalem Nominierungs-DELETE und Audit-INSERT; ohne temporäre Test-Trigger-/DDL-Manipulation lässt sich dieser Zwischenzustand über die öffentliche RPC nicht deterministisch auslösen. Keine temporäre DDL-Manipulation vorgenommen.
- **Superadmin mit explizitem Teamkontext:** nicht separat getestet; erfordert einen Testaccount mit Superadmin-Rolle und kontrolliertem ausgewähltem Teamkontext. Kein Frontend-Test wurde durchgeführt.

### Testdaten

Die Testmannschaften/Spieler/Spieltag-Datensätze wurden in DEV angelegt. Ein Teil der Reminder hat append-only Audit-Historie und kann deshalb nicht durch einfaches Löschen entfernt werden. Die Datensätze sind eindeutig als `E23 ... TEMP` markiert und wurden nicht für reale App-Abläufe verwendet. Sie bleiben isoliert in DEV, bis ein kontrollierter Testdaten-Bereinigungsweg unter Wahrung der Audit-Unveränderlichkeit festgelegt ist.


## Abschließende Prüfungen – 17.11.2026, Runde 3

- **Gezielter RPC-Rollbacktest:** In einer vollständig zurückgerollten Testtransaktion wurde ein temporärer BEFORE INSERT Testtrigger auf der Audit-Tabelle eingerichtet, der den Audit-INSERT absichtlich fehlschlagen lässt. Die Create-RPC wurde mit einem bereits nominierten Testspieler aufgerufen. Erwartung bestätigt: Der Reminder-INSERT und das vorherige DELETE der Ausgangsnominierung wurden gemeinsam zurückgerollt; die Ausgangsnominierung blieb erhalten. PASS. Testtrigger und Testdaten wurden durch äußeres ROLLBACK entfernt.
- **Superadmin mit explizitem Teamkontext:** Test mit vorhandenem global_user_roles-Eintrag super_admin und temporär gesetztem user_team_context für die Zielmannschaft. Create-RPC erfolgreich. PASS. Transaktion zurückgerollt.
- **Superadmin ohne expliziten Teamkontext:** Kontext entfernt und derselbe Zugriff erneut versucht. RPC wurde mit „Keine Berechtigung für diese Mannschaft“ abgelehnt. PASS. Transaktion zurückgerollt.

**Paket 1 – Datenbanktests abgeschlossen:** die zuvor offenen Punkte sind damit geprüft. Die getesteten Vorgänge waren isolierte DEV-Tests; keine Frontend-Interaktion und keine PROD-Änderung.
