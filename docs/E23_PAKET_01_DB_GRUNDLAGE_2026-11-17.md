# Epic 23 – Paket 1: Datenbank-Grundlage für Nominierungsvormerkungen

**Stand:** 17.11.2026  
**Zielumgebung:** Supabase DEV (Projekt pzazqvvoruqnqhcorbwx)  
**Status:** SQL vorbereitet, nicht ausgeführt.  
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
