# Epic 23 – Hotfix: Audit-Aktion `reopened` zulassen

**Zielumgebung:** Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**PROD:** ausdrücklich ausgeschlossen; unverändert  
**Freigabe:** Nutzerfreigabe im Chat am 17.11.2026  
**Status:** SQL vorbereitet; Ausführung noch nicht erfolgt

## Ursache

Die Live-Constraint `matchday_nomination_reminder_audit_action_check` erlaubt nur `created`, `fulfilled` und `cancelled`. Die in Paket 3 eingeführte Triggerfunktion `epic23_reopen_nomination_reminder_on_delete()` schreibt beim Wiederöffnen den Aktionswert `reopened`. Der Audit-INSERT wird deshalb durch die CHECK-Constraint abgewiesen und die auslösende Nominierungsänderung scheitert transaktional.

## Umfang

Ausschließlich die CHECK-Constraint auf `public.matchday_nomination_reminder_audit.action` wird ersetzt. Danach sind `created`, `fulfilled`, `cancelled` und `reopened` zulässig.

Unverändert bleiben:
- alle bestehenden Audit-Zeilen;
- Tabellen, Spalten, Indizes, RLS, Policies und Grants;
- RPCs, Trigger und Triggerfunktionen;
- Spieler- und Spieltagsdaten.

## Vorabprüfung

Read-only DEV-Prüfung am 17.11.2026:
- Constraint vorhanden: `matchday_nomination_reminder_audit_action_check`;
- Definition erlaubt aktuell `created`, `fulfilled`, `cancelled`;
- vorhandene Audit-Zeilen: `created=8`, `fulfilled=5`, `cancelled=2`;
- bislang keine `reopened`-Zeile und keine weiteren Aktionswerte.

## Dateien

- Migration: `supabase/migrations/20261117193000_epic23_reopened_audit_action_hotfix_dev.sql`
- Guarded Rollback: `supabase/rollback/20261117193000_epic23_reopened_audit_action_hotfix_rollback.sql`
- Read-only Postflight: `docs/E23_HOTFIX_REOPENED_AUDIT_VERIFICATION_2026-11-17.sql`

## Ausführung und Abnahme

Migration am 17.11.2026 nach ausdrücklicher Freigabe erfolgreich in Supabase DEV ausgeführt. Tatsächliche Ledger-Version: `20261117210545`; Migrationsname: `epic23_reopened_audit_action_hotfix_dev`. Supabase meldete `success: true`.

Postflight PASS:
- Constraintdefinition enthält genau `created`, `fulfilled`, `cancelled`, `reopened`.
- Audit-Bestand unverändert: `created=8`, `fulfilled=5`, `cancelled=2`; bisher noch keine `reopened`-Zeile.
- Keine Datenzeilen wurden durch die Migration verändert.

**Nächster Praxistest:** erfüllte Vormerkung durch Abwählen der späteren Nominierung wieder öffnen. Erwartung: Status `pending`, Audit-Aktion `reopened`, ursprüngliche Historie bleibt erhalten.

## Rollback

Der Rollback ist absichtlich guarded und verweigert die Rücknahme, sobald mindestens eine `reopened`-Audit-Zeile existiert. Damit wird keine Historie durch eine Rückkehr zur Drei-Werte-Constraint unzulässig gemacht.

**Aktueller Stand:** DEV-Migration erfolgreich ausgeführt und Postflight bestanden. Frontend unverändert; PROD unangetastet.
