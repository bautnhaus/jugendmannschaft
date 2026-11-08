# E05 – Freigabe- und Ausführungsprotokoll Paket 2

## Paket 2: Trainingsereignis vergeben (RPC)

- **Datum der Erstellung:** 08.11.2026
- **Zielumgebung nach Freigabe:** Supabase DEV
- **Supabase-Projekt:** `pzazqvvoruqnqhcorbwx`
- **SQL-Datei:** [E05_PAKET_02_AWARD_TRAINING_BEHAVIOR_EVENT_2026-11-08.sql](https://github.com/bautnhaus/jugendmannschaft/blob/develop/docs/E05_PAKET_02_AWARD_TRAINING_BEHAVIOR_EVENT_2026-11-08.sql)
- **Branch:** `develop`
- **Status:** erstellt, Freigabe ausstehend; noch nicht in Supabase ausgeführt
- **Abhängigkeit:** Paket 1 muss in DEV vorhanden sein.

### Umfang

Paket 2 erstellt bzw. ersetzt ausschließlich die Funktion:

`public.award_training_behavior_event(uuid, uuid, text, text)`

Die Funktion vergibt gelbe Karte, rote Karte oder positiven Stern und schreibt Ereignis und Audit-Eintrag atomar.

### Serverseitige Prüfungen

- Authentifizierung über `auth.uid()`.
- Teamzugehörigkeit des Trainings und Spielers.
- Spieler muss aktiv sein.
- Akteur muss im konkreten Team Trainer oder Mannschaftsadmin sein; Superadmin nur mit ausgewähltem Teamkontext.
- Anwesenheit muss über `attendance.present = true` bestätigt sein.
- Abgesagte Trainings werden abgewiesen.
- Aktive Saison muss eindeutig bestimmbar und teamgleich sein.
- Karten benötigen einen nichtleeren Grund; beim Stern ist der Grund optional.
- Ereignistyp ist auf `yellow_card`, `red_card`, `positive_star` begrenzt.
- Doppelte aktive Karten/Sterne werden durch die Unique-Indizes aus Paket 1 verhindert.

### Bewusste Abgrenzung

Dieses Paket erzeugt noch keine Sperre. Die automatische rote Sperre bzw. gelbe Sperre bei fünf aktiven gelben Karten wird in einem separaten Folgepaket ergänzt. Vor Abschluss dieses Lifecycle-Schritts ist die Funktion nur für DEV-Tests und nicht für einen produktiven Trainerworkflow vorgesehen.

Keine bestehenden Tabellen, Daten, Rollen oder Policies werden geändert. Keine Änderungen an PROD.

### Geplante Prüfungen nach Freigabe und Ausführung

1. Funktionssignatur und SECURITY DEFINER-Eigenschaft vorhanden.
2. EXECUTE für `authenticated` vorhanden; für `anon`, `PUBLIC` und `service_role` nicht vorhanden.
3. Positivtest: gültiger Trainer, aktiver Spieler, anwesend, aktive Saison, gültiger Ereignistyp.
4. Negativtest: unauthentifiziert, fehlende Rolle, falsches Team, inaktiver Spieler, nicht anwesend, abgesagtes Training, fehlende/mehrdeutige aktive Saison, ungültiger Ereignistyp, fehlender Kartengrund.
5. Duplikattest: zweite aktive Karte bzw. zweiter aktiver Stern für denselben Spieler/dasselbe Training wird abgewiesen; Karte plus Stern ist zulässig.
6. Atomarität: Ereignis und Audit entstehen gemeinsam; bei Fehler bleibt kein Teilzustand zurück.

### Ausführungsstatus

Noch nicht ausgeführt. Dieses Dokument wird nach Freigabe und DEV-Ausführung um Ergebnis, Prüfergebnisse, ggf. Korrekturen und Commitreferenz ergänzt.
