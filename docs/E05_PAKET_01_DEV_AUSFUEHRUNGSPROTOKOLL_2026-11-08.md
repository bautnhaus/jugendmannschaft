# E05 – DEV-Ausführungsprotokoll

## Paket 1: Trainingsereignisse und Ereignis-Audit

- **Datum:** 08.11.2026
- **Zielumgebung:** Supabase DEV
- **Supabase-Projekt:** `pzazqvvoruqnqhcorbwx`
- **SQL-Datei:** [E05_PAKET_01_TRAINING_EVENTS_2026-11-08.sql](https://github.com/bautnhaus/jugendmannschaft/blob/develop/docs/E05_PAKET_01_TRAINING_EVENTS_2026-11-08.sql)
- **Freigabe:** ausdrücklich durch den Nutzer erteilt
- **Ausführung:** erfolgreich; SQL-Transaktion abgeschlossen
- **PROD:** nicht verändert

### Inhalt der Migration

Angelegt wurden:

1. `public.training_behavior_events`
2. `public.training_behavior_event_audit`

Zusätzlich angelegt:

- Unique Index für maximal eine aktive Karte (gelb oder rot) je Spieler/Training.
- Unique Index für maximal einen aktiven positiven Stern je Spieler/Training.
- Zwei Suchindizes für Spieler/Saison und Training.
- Audit-Index für Ereignisverlauf.
- Trigger zum Schutz des Audit-Protokolls vor UPDATE und DELETE sowie ein Statement-Trigger für TRUNCATE.
- RLS auf beiden Tabellen und jeweils eine SELECT-Policy.
- API-Rechte: SELECT für `authenticated` und `service_role`; keine direkten Schreibrechte für diese Rollen.

### Nachkontrollen in DEV

Die folgenden Abfragen wurden nach Ausführung separat ausgeführt:

| Prüfung | Ergebnis |
|---|---|
| Beide Tabellen vorhanden | Bestanden |
| Erwartete Indizes vorhanden | Bestanden – 5 Indizes auf Ereignistabelle, einschließlich PK |
| SELECT-Policies vorhanden | Bestanden – je eine pro Tabelle |
| Audit-Trigger für UPDATE und DELETE vorhanden | Bestanden |
| `authenticated`: SELECT erlaubt | Bestanden |
| `authenticated`: INSERT nicht erlaubt | Bestanden |
| `anon`: SELECT nicht erlaubt | Bestanden |

Die Berechtigungsprüfung ergab konkret: `auth_select=true`, `auth_insert=false`, `anon_select=false`.

### Datenbestand / Auswirkungen

- Es wurden ausschließlich neue E05-Objekte angelegt.
- Bestehende Tabellen, bestehende Datensätze, Rollen, bestehende Funktionen und bestehende Policies wurden durch dieses Paket nicht geändert.
- Die beiden neuen Tabellen sind nach der Migration leer; die Erfassung von Ereignissen erfolgt erst mit den nachfolgenden, gesondert geprüften RPC-Schreibfunktionen.
- Es wurden keine Änderungen an PROD vorgenommen.

### Ergebnis

**Paket 1 in DEV erfolgreich ausgeführt und die aufgeführten Struktur-, Policy- und Rechteprüfungen bestanden.**

### Nächster Schritt

Paket 2: serverseitige RPCs für das Erfassen von Trainingsereignissen einschließlich Rollenprüfung, Teilnahmeprüfung, Duplikatkontrolle und Audit-Eintrag. Die Auslösung von Sperren wird als separates kleines Folgepaket umgesetzt, sobald die Ereigniserfassung zuverlässig getestet ist.
