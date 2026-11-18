# DEV – Bereinigung der Bild-Testdaten

**Datum:** 2026-11-18  
**Projekt:** Supabase DEV `pzazqvvoruqnqhcorbwx`  
**Status:** abgeschlossen und nachgeprüft; PROD ausdrücklich ausgeschlossen.

## Umfang und Ausführung

Die freigegebene DEV-Bereinigung wurde durchgeführt.

### Storage-Dateien

Die vier freigegebenen Testobjekte wurden durch den Benutzer im Supabase Dashboard gelöscht:

- `profile-avatars/1c84aee5-0569-4c92-a53b-9237382f2b43/avatar-1793460014376.jpg`
- `profile-avatars/1c84aee5-0569-4c92-a53b-9237382f2b43/avatar-1793460141532.jpg`
- `club-assets/7f0e09be-2de5-450a-a39b-0061a2c9c56e/crest.jpg`
- `club-assets/7f0e09be-2de5-450a-a39b-0061a2c9c56e/crest.png`

Anschließende Datenbankprüfung ergab **0 Storage-Objekte** in den Buckets `club-assets`, `profile-avatars` und `player-photos`.

### Datenbankreferenzen

Die Datenbankbereinigung wurde ausschließlich in DEV ausgeführt:

- 3 Zeilen in `players`: `photo_data = NULL`
- 1 Zeile in `profiles`: `avatar_url = NULL`
- 1 Zeile in `clubs`: `crest_path = NULL`

Die Ausführung lieferte die Zähler 3, 1 und 1 für die jeweils zurückgesetzten Werte.

## Postflight-Prüfung

| Prüfung | Ergebnis |
|---|---:|
| Storage-Objekte in den drei Bild-Buckets | 0 |
| Spieler mit `photo_data` | 0 |
| Spieler mit `photo_path` | 0 |
| Profile mit `avatar_url` | 0 |
| Vereine mit `crest_path` | 0 |
| Spalte `players.photo_path` vorhanden | Ja |
| Storage-Policies `player_photos_*` vorhanden | 4 |

Die Bereinigung hat die Vorbereitung aus Paket 1A nicht entfernt: `players.photo_path` und die vier `player_photos_*`-Policies sind weiterhin vorhanden.

## Schutzgrenze

- Es wurden keine Änderungen an PROD vorgenommen.
- Es wurden keine Buckets, Policies oder Funktionen geändert.
- Es wurde kein Objekt direkt aus `storage.objects` per SQL gelöscht.
- Die bestehenden Bildspalten bleiben bestehen; lediglich die freigegebenen DEV-Testwerte wurden zurückgesetzt.
