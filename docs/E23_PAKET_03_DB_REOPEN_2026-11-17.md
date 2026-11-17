# Epic 23 – Paket 3: Vormerkung sichtbar am Ausgangsspieltag und rücknehmbare Erfüllung

**Umgebung:** Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**Migration:** `20261117180000_epic23_nomination_reminder_reopen_dev.sql`  
**Status:** In DEV ausgeführt; Postflight erfolgreich.  
**PROD:** Unverändert.

## Änderungen

1. `get_matchday_nomination_reminders(uuid)` liefert offene Vormerkungen jetzt auch am Ausgangsspieltag (`match_date >= source_matchday_date_snapshot`). Bereits nominierte Spieler bleiben für diesen Spieltag weiterhin ausgeblendet.
2. Neuer AFTER DELETE-Trigger `matchday_players_reopen_nomination_reminder`: Wird die Nominierung entfernt, durch die eine Vormerkung erfüllt wurde, wird sie wieder auf `pending` gesetzt, sofern keine andere spätere Nominierung für den Spieler existiert.
3. Die Wiederöffnung wird als Audit-Aktion `reopened` protokolliert. Audit bleibt append-only.
4. Der Trigger verwendet denselben spielerbezogenen Advisory Lock wie Create und Fulfillment. Die Triggerfunktion ist nicht direkt für Clientrollen ausführbar.

## Postflight

- Migration von Supabase erfolgreich bestätigt.
- Wiederöffnungs-Trigger auf `public.matchday_players` aktiv.
- Read-API und Triggerfunktion: SECURITY DEFINER, Owner `postgres`, fester search_path.
- EXECUTE: Read-API nur `authenticated`; Triggerfunktion weder `authenticated` noch `anon`.
- Keine PROD-Änderung.

## Noch ausstehende fachliche End-to-End-Tests

- Vormerkung am Ausgangsspieltag sichtbar, sofern Spieler dort nicht nominiert ist.
- Nominierung auf späterem Spieltag erfüllt Vormerkung.
- Entfernen genau dieser Nominierung öffnet Vormerkung erneut.
- Besteht eine weitere spätere Nominierung, bleibt die Vormerkung erfüllt.
- Audit enthält jeweils die korrekte Erfüllungs- und Wiederöffnungsaktion.

## Abgrenzung

Diese Migration ändert keine Kadergröße und keine Empfehlungsspeicherung. Die Integration der Vormerkungspriorität in die gespeicherte Empfehlung sowie UI-/Theme-/Dialogkorrekturen sind separate Frontend-Arbeiten.
