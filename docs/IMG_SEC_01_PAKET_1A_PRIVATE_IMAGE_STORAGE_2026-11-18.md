# KADAssist – IMG-SEC-01 / Paket 1A: Fundament private Bildspeicherung

- Datum: 18.11.2026
- Branch: develop
- Zielumgebung: Supabase DEV – pzazqvvoruqnqhcorbwx
- Status: In DEV ausgeführt; strukturelle Postflight-Prüfung bestanden
- PROD: Nicht ausgeführt, unverändert
- Frontend: Nicht geändert
- Freigabe: ausdrückliche Nutzerfreigabe am 18.11.2026

## 1. Ziel und Abgrenzung

Paket 1A schafft das Datenbank- und Storage-Fundament für den späteren Wechsel von öffentlichen Bild-URLs auf private Storage-Buckets mit Signed URLs.

Die bestehenden Buckets profile-avatars und club-assets bleiben vorerst public=true. Dadurch wird die bestehende App nicht vor der Frontend-Umstellung ausgesperrt. Vorhandene Upload-/Update-/Delete-Policies dieser Buckets blieben unverändert. Es wurden keine Bilddateien verschoben, gelöscht oder umbenannt. Keine photo_data-, avatar_url- oder crest_path-Werte wurden migriert.

## 2. Berechtigungsentscheidungen

### Spielerfotos
- Lesen, Hochladen, Ersetzen und Löschen: alle Mitglieder der betreffenden Mannschaft (Trainer und Mannschaftsadmins).
- Superadmin-Zugriff nur im ausdrücklich ausgewählten Mannschaftskontext gemäß is_team_member().
- Pfad: team_id/player_id/dateiname.
- Storage-Policies prüfen, dass player_id existiert und zu genau team_id gehört.

### Profilbilder
- Eigener Nutzer: eigenes Profilbild.
- Trainer und Mannschaftsadmins: Profilbilder der Mitglieder derselben Mannschaft.
- Vereinsadmins: Profilbilder der Mitglieder ihres Vereins.
- Superadmins: nur im ausdrücklich ausgewählten Mannschafts- oder Vereinskontext.
- profiles_select blieb unverändert; Profilbildzugriff wird separat über Storage SELECT gesteuert.

### Vereinsassets
- Die neue Lesefunktion erlaubt Vereinsmitgliedern und Vereinsadmins das Lesen.
- Verwaltungs-/Schreibrechte blieben unverändert.
- club_assets_select_scoped wurde auf die neue Lesefunktion umgestellt. Der Bucket selbst bleibt bis zum Frontend-Cutover öffentlich.

## 3. Ausgeführte Migrationen

### 3.1 Storage-Fundament
- Ledger-Version: 20261118180946
- Name: img_sec_01_private_player_photo_storage_v1_0_0
- Datei: supabase/migrations/20261118180946_img_sec_01_private_player_photo_storage_v1_0_0.sql
- Ergebnis: success=true.

Angelegt bzw. geändert:
- players.photo_path text.
- Privater Bucket player-photos, 2 MiB, JPEG/PNG/WebP.
- Guard gegen stillschweigende Umkonfiguration eines bereits existierenden öffentlichen Buckets.
- Vier Berechtigungsfunktionen.
- Profilbild-SELECT-Policy und Vereinsasset-SELECT-Policy.
- Spielerfoto-Policies für SELECT, INSERT, UPDATE und DELETE.

### 3.2 Härtung der Policy-Helper
- Ledger-Version: 20261118181010
- Name: img_sec_01_harden_private_policy_helpers
- Datei: supabase/migrations/20261118181010_img_sec_01_harden_private_policy_helpers.sql
- Ergebnis: success=true.
- Schema private angelegt; PUBLIC/anon entzogen; authenticated erhält USAGE.
- Drei benötigte SECURITY DEFINER Helper in private verschoben.
- public.can_view_player_photo entfernt.

## 4. Read-only Postflight

| Prüfung | Ergebnis |
|---|---|
| player-photos.public | false |
| Objekte in player-photos | 0 |
| players.photo_path vorhanden | Ja |
| profiles_select vorhanden | Ja, unverändert |
| club_assets_select_scoped vorhanden | Ja |
| player_photos Policies | 4 |
| private Helper | 3 |
| entsprechende öffentliche Helper | 0 |

Security Advisor: projektweite Warnungen zu anderen SECURITY DEFINER-Funktionen bestehen weiterhin. Die Zahl der entsprechenden Warnungen sank von 60 auf 56. Keine globale Advisor-Bereinigung wurde vorgenommen.

## 5. Rollback

Datei: supabase/rollback/20261118180946_img_sec_01_private_player_photo_storage_rollback.sql.

Der Rollback bricht ab, sobald photo_path Werte oder player-photos Dateien enthält. Er entfernt die vier Spielerfoto-Policies und die neue Profilbild-SELECT-Policy, stellt club_assets_select_scoped mit der live aus DEV ausgelesenen Originaldefinition wieder her, entfernt die Paket-Helper und photo_path und löscht den Bucket nur im leeren Zustand. profiles_select bleibt unangetastet, weil es nicht geändert wurde. Rollback nicht ausgeführt.

## 6. Nicht Bestandteil

- profile-avatars und club-assets wurden nicht auf privat gestellt.
- Bestehende Bilder wurden nicht migriert.
- save_player_with_positions wurde nicht geändert; die App schreibt weiter photo_data.
- Keine Frontend-, main- oder PROD-Änderung.
- Keine Backup-/Restore-Implementierung.

## 7. Grenzen und nächste Schritte

Die Policies sind strukturell geprüft, aber noch nicht mit echten authentifizierten Sitzungen aller Rollen getestet. Das Frontend verwendet weiterhin getPublicUrl(), photo_data und Public-URL-Werte. Daher bleiben die bestehenden Buckets öffentlich, bis der Frontend-Cutover und die Datenmigration abgeschlossen und in DEV getestet sind.

Signed URLs sind zeitlich begrenzte Bearer-URLs und können bis zum Ablauf weiter funktionieren, auch wenn die Berechtigung zwischenzeitlich entzogen wird.

## 8. Artefakte

- Migration 1 und 2 in supabase/migrations/
- Guarded Rollback in supabase/rollback/
- Read-only Postflight in docs/IMG_SEC_01_PAKET_1A_POSTFLIGHT_2026-11-18.sql
- Paketdossier in docs/IMG_SEC_01_PAKET_1A_PRIVATE_IMAGE_STORAGE_2026-11-18.md
- Paket-2-Vorbereitung in docs/IMG_SEC_02_FRONTEND_PRIVATE_IMAGES_PLAN_2026-11-18.md
