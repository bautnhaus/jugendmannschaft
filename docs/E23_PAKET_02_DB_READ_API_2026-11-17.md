# Epic 23 – Paket 2: Datenbank-Read-API

**Datum:** 17.11.2026  
**Ziel:** Supabase DEV  
**Status:** SQL-Migration ausgeführt und Funktionstests bestanden.  
**Frontend:** ausdrücklich nicht verändert.  
**PROD:** unverändert.

## Ziel

Das Frontend soll für einen ausgewählten Spieltag die offenen Nominierungsvormerkungen derselben Mannschaft abrufen können. Die API liefert die Begründung für die Detail-/Optionsansicht sowie die Spieler-ID und den Hinweisstatus. Sie verändert weder die Kaderempfehlung noch Nominierungen.

## Datenbankobjekt

RPC: public.get_matchday_nomination_reminders(p_matchday_id uuid)

Rückgabefelder:
- reminder_id
- player_id
- player_name
- reason
- source_matchday_date
- created_at

## Fachliche Filter

Die RPC liefert ausschließlich Vormerkungen, die:
- zum Team des angefragten Spieltags gehören,
- den Status pending haben,
- einen noch verknüpften Spieler besitzen,
- von einem zeitlich früheren Ausgangsspieltag stammen,
- für den Zielspieltag noch keine Nominierungszeile in matchday_players haben.

Dadurch wird der Spieler nicht zusätzlich als Empfehlungshinweis ausgegeben, wenn er für den Zielspieltag bereits nominiert ist. Die Abfrage erfüllt oder storniert keine Vormerkung.

## Sicherheit

- SECURITY DEFINER mit festem search_path.
- Authentifizierung verpflichtend.
- Trainer und Mannschaftsadmins nur für die eigene Mannschaft.
- Superadmin nur mit explizitem user_team_context.
- EXECUTE nur für authenticated; anon und PUBLIC haben kein EXECUTE.
- Keine direkten Schreiboperationen und keine Änderung bestehender Tabellen/Policies.

## Abgrenzung zum Frontend

Die RPC liefert Daten, keine sortierte Kaderempfehlung. Die bestehende Empfehlung wird in index.html berechnet. In der späteren Frontend-Integration gilt:
1. Reminder-Spieler erhalten einen Vorrang vor Spielern ohne Vormerkung.
2. Innerhalb beider Gruppen bleibt die bestehende Empfehlungsreihenfolge erhalten.
3. Die bestehende Kadergröße bleibt unverändert.
4. Es erfolgt keine automatische Nominierung.
5. Auf der Kachel erscheint nur der Hinweis „Nominierung vorgemerkt“; die Begründung ist in den Trainerdetails/Optionen einsehbar.
6. Die Rücknahme verwendet die bereits vorhandene cancel_matchday_nomination_reminder-RPC.
7. Wird ein Spieler für den Zielspieltag bereits nominiert, erscheint er nicht zusätzlich als Reminder-Kandidat.

## Migration

supabase/migrations/20261117160000_epic23_nomination_reminder_read_api_dev.sql

## Testergebnis

- Offene Vormerkung auf späterem Spieltag geliefert und Begründung zurückgegeben: PASS.
- Ausgangsspieltag selbst liefert keine Vormerkung: PASS.
- Bereits für den Zielspieltag nominierter Spieler wird nicht zusätzlich geliefert: PASS.
- Nicht berechtigter Cross-Team-Aufruf wird abgelehnt: PASS.
- Postflight: SECURITY DEFINER, Owner postgres, fester search_path, EXECUTE authenticated ja, anon/PUBLIC nein.

Alle Testdaten wurden transaktional zurückgerollt. Keine Frontend- oder PROD-Änderung.

## Abnahmekriterien

- Migration in DEV ausgeführt.
- Alle vier API-Tests bestanden.
- Sicherheits-Postflight bestanden.
- Frontend bleibt unverändert, bis die getrennte Frontendfreigabe erfolgt.
