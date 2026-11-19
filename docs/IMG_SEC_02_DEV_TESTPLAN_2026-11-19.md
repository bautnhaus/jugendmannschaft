# IMG-SEC-02 – DEV-Testpaket Profilbild-Härtung

**Migration:** `20261119120000_img_sec_02_profile_avatar_hardening_v1_0_0_dev`  
**Umgebung:** ausschließlich Supabase DEV / DEV-Web-App  
**Status:** vorbereitet, nicht ausgeführt und nicht getestet  
**Freigabegrenze:** Dieses Testpaket ist keine Freigabe zur Migration oder zum Rollback.

## 1. Ziel

Nach erfolgreicher Migration wird nachgewiesen, dass Profilbilder nur von den fachlich berechtigten Personen verwaltet werden können, dass neue Profilbildpfade zum Profilinhaber gehören und dass die bestehende Sichtbarkeit von Bildern unverändert bleibt.

## 2. Voraussetzungen

- Migration wurde nach gesonderter Freigabe erfolgreich auf DEV ausgeführt.
- DEV-Web-App zeigt exakt den dazugehörigen develop-Stand.
- Testkonten stehen für folgende Rollen bereit: normales Mitglied, Trainer ohne Adminrolle, Mannschaftsadmin, Vereinsadmin, Superadmin.
- Für negative Tests existieren mindestens zwei voneinander getrennte Mannschaften und – soweit vorhanden – zwei Vereine.
- Testbilder verwenden nur harmlose, eigens dafür vorgesehene Dateien.
- Vor Beginn werden die betroffenen Testkonten und ihre Rollen dokumentiert. Keine echten Nutzerbilder für Negativtests verwenden.

## 3. Positivtests – Verwaltung

| ID | Rolle / Aktion | Erwartetes Ergebnis |
|---|---|---|
| P01 | Mitglied lädt eigenes Profilbild hoch | Erfolgreich |
| P02 | Mitglied ersetzt eigenes Profilbild | Erfolgreich |
| P03 | Mitglied entfernt eigenes Profilbild | Erfolgreich |
| P04 | Mannschaftsadmin lädt Bild für Mitglied der eigenen Mannschaft hoch | Erfolgreich |
| P05 | Mannschaftsadmin ersetzt Bild eines Mitglieds der eigenen Mannschaft | Erfolgreich |
| P06 | Mannschaftsadmin entfernt Bild eines Mitglieds der eigenen Mannschaft | Erfolgreich |
| P07 | Vereinsadmin verwaltet Bild eines Mitglieds des eigenen Vereins | Erfolgreich |
| P08 | Superadmin verwaltet Bild im ausdrücklich ausgewählten Vereinskontext | Erfolgreich |
| P09 | Superadmin verwaltet Bild im ausdrücklich ausgewählten Mannschaftskontext | Erfolgreich |
| P10 | Admin ändert nur den Namen eines Profils mit unverändertem Avatarwert | Namensänderung erfolgreich; vorhandener Avatarwert bleibt unverändert |

## 4. Negativtests – Berechtigungen und Pfadmanipulation

| ID | Rolle / Aktion | Erwartetes Ergebnis |
|---|---|---|
| N01 | Trainer ohne Adminrolle lädt Bild für fremdes Mitglied hoch | Abgewiesen |
| N02 | Trainer ohne Adminrolle ersetzt/löscht fremdes Bild | Abgewiesen |
| N03 | Mannschaftsadmin verwaltet Mitglied einer anderen Mannschaft | Abgewiesen |
| N04 | Vereinsadmin verwaltet Mitglied eines anderen Vereins | Abgewiesen |
| N05 | Superadmin versucht Verwaltung ohne passenden ausgewählten Kontext | Abgewiesen |
| N06 | Benutzer speichert Pfad mit fremder Benutzer-UUID | Abgewiesen |
| N07 | Benutzer speichert vollständige HTTP-/HTTPS-URL oder Data-URL | Abgewiesen |
| N08 | Benutzer speichert Pfad mit zusätzlichem Segment, führendem Slash oder Traversal-Teil | Abgewiesen |
| N09 | Benutzer speichert nicht erlaubte Dateiendung | Abgewiesen |
| N10 | Nicht authentifizierter Benutzer versucht Storage-Schreibzugriff | Abgewiesen |

## 5. Anzeige- und Regressionstests

- V01: Berechtigte Betrachter sehen Profilbilder weiterhin entsprechend der bestehenden SELECT-Regel.
- V02: Ein Trainer erhält durch die neue Verwaltungsregel keine zusätzlichen Leserechte.
- V03: Login, Logout und Vereins-/Mannschaftskontextwechsel zeigen weiterhin die jeweils erlaubten Profilbilder.
- V04: Spielerfotos und Vereinslogo bleiben unverändert funktionsfähig.
- V05: Profilnamen und sonstige Profilfelder lassen sich ohne Änderung des Avatarwertes weiterhin speichern.
- V06: Upload, Ersetzen und Entfernen funktionieren auf iPhone/Safari.

## 6. Datenbank-Postflight

Nach Ausführung:
1. `docs/IMG_SEC_02_POSTFLIGHT_READONLY.sql` ausführen (nur SELECT).
2. Erwartete Helper, Trigger, RPC-Definitionen und drei Storage-Schreibpolicies prüfen.
3. Bestätigen, dass die Profilbild-SELECT-Policy unverändert ist.
4. Bestätigen, dass keine Profilzeile und kein Storage-Objekt durch die Migration verändert oder gelöscht wurde.
5. Security Advisor auf neue IMG-SEC-02-spezifische Findings prüfen.

## 7. Abnahmebedingungen

- Alle P01–P10 bestanden.
- Alle N01–N10 abgewiesen.
- Alle V01–V06 bestanden.
- Keine unerwartete Änderung an Profilen, Storage-Objekten, Bucket-Einstellungen oder Leserechten.
- Keine neuen unberechtigten EXECUTE-Rechte für `PUBLIC` oder `anon`.
- Ergebnisse mit Datum, Testkonto/Rolle und Screenshot/Beleg im Dossier dokumentiert.

Ein fehlgeschlagener Negativtest ist ein Sicherheits-Blocker. Ein fehlgeschlagener Positivtest ist ein Funktions-Blocker. Keine PROD-Freigabe, solange ein Blocker offen ist.

## 8. Rollback-Kriterien

Rollback nur bei ausdrücklicher gesonderter Freigabe, insbesondere wenn:
- unberechtigte Zugriffe möglich sind,
- legitime Rollen unerwartet blockiert werden,
- Profilbildanzeige oder Profilbearbeitung regressiert,
- Datenbank-/Storage-Postflight unerwartete Abweichungen zeigt.

Rollback-Datei: `supabase/rollback/20261119120000_img_sec_02_profile_avatar_hardening_rollback_dev.sql`.

Rollback entfernt keine Profilzeilen oder Storage-Dateien. Danach sind die ursprünglichen RPCs und Storage-Schreibregeln wiederhergestellt; SELECT-Policy und Bucket-Einstellungen bleiben unangetastet.
