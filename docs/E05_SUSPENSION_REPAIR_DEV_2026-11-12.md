# E05 – Reparatur bestehender Sperrenzuordnungen (DEV)

**Datum:** 12.11.2026  
**Status:** Datenbankkorrektur ausgeführt und read-only verifiziert  
**Umgebung:** Supabase DEV ausschließlich



## E05 – Reparatur bestehender Sperrenzuordnungen DEV (12.11.2026)

- **Freigabe / Anlass:** Fortsetzung der ausdrücklich beauftragten DEV-Korrektur der Sperrenproblematik.
- **Umgebung:** Supabase DEV Projekt `pzazqvvoruqnqhcorbwx`; Team DEV Mannschaft `4a8830e3-8852-4bb6-be22-279296d0a727`; Saison 2026/2027 `c63eccff-6f0b-4d2f-add2-554e85ae07ef`.
- **Diagnose:** Nach der Saison-Datenkorrektur waren alle Spieltage/Trainings korrekt zugeordnet, aber bestehende offene Sperren hatten weiterhin NULL als intended_matchday_id. Die Datenbankfunktionen für Kartenerfassung/-korrektur und Sperrenzuordnung sind getrennt: `e05_reconcile_suspensions_after_event_correction` korrigiert den fünften Karteneintrag und ruft anschließend `e05_assign_player_suspensions` auf; `e05_assign_player_suspensions` allein ändert keine fünfte-Karte-Quelle.
- **Tom Achtzehn Jahre:** Fünf aktive gelbe Karten mit Trainingsdaten 15.10., 20.10., 05.11., 07.11. und 09.11.2026. Die offene gelbe Sperre verwies zuvor fälschlich auf die Karte vom 20.10. Nach Aufruf von `e05_reconcile_suspensions_after_event_correction` für die aktive Karte vom 09.11. wurde die Quelle auf Ereignis `22486ebf-d39a-4bd9-b8c7-bb6a2c1cc522` (09.11.) korrigiert und die Sperre auf den nächsten geplanten Spieltag 14.11.2026 / Flensburg zugeordnet.
- **Spieler Dreißig:** Die offene rote Sperre vom 15.10.2026 hatte ebenfalls keine Zielzuordnung. Aufruf von `e05_assign_player_suspensions` hat sie auf den 14.11.2026 / Flensburg gesetzt.
- **Ausgeführte DB-Funktionen:**
  ```sql
  select public.e05_reconcile_suspensions_after_event_correction(
    '22486ebf-d39a-4bd9-b8c7-bb6a2c1cc522'::uuid,
    '1c84aee5-0569-4c92-a53b-9237382f2b43'::uuid,
    'DEV-Korrektur: chronologisch fünfte aktive Gelbe Karte und Neuzuordnung nach Saison-Datenkorrektur'
  );
  select public.e05_assign_player_suspensions(
    '4a8830e3-8852-4bb6-be22-279296d0a727'::uuid,
    '90387b6d-8da0-4f11-98bf-0175670d39ec'::uuid,
    '1c84aee5-0569-4c92-a53b-9237382f2b43'::uuid
  );
  ```
- **Nachprüfung:** Beide offenen Sperren zeigen Status `open`, Zielspieltag 14.11.2026, Gegner Flensburg, Spielart Freundschaftsspiel, Status des Spieltags `planned`. Tom-Quelle ist die gelbe Karte vom 09.11.2026. Audit-Einträge dokumentieren die Korrektur der Kartenquelle sowie beide Zielzuordnungen.
- **Art der Änderung:** Aufruf vorhandener, abgesicherter Datenbankfunktionen; keine direkte Tabellenänderung, keine Schemaänderung, keine Migration, keine RLS-/Grant-/Trigger-Änderung.
- **PROD / main:** unverändert.
- **Offen:** Browser-Praxistest in DEV; prüfen, ob Historie die Sperre jetzt beim 09.11.-Ereignis zeigt und ob Tom sowie Spieler Dreißig für den Spieltag 14.11. als gesperrt erscheinen. Der Spieltag wurde nicht abgeschlossen; keine Sperre wurde als abgeleistet markiert.
