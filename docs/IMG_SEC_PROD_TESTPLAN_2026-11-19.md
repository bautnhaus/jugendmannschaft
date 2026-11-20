# IMG-SEC – PROD-Abnahmetestplan

Nur nach separater PROD-Ausführungsfreigabe und nach dem jeweiligen Migrations-Gate.

## Positive Tests
- Mannschaftsmitglied/Trainer sieht Spielerfotos seiner Mannschaft.
- Berechtigter Teamadmin kann Spielerfoto hochladen, ersetzen und entfernen.
- Benutzer sieht eigenes Profilbild.
- Gemeinsame Teammitglieder sehen Profilbilder gemäß DEV-Regel.
- Vereinsmitglied sieht das Vereinslogo.
- Vereinsadmin kann Vereinslogo verwalten.
- Superadmin sieht Vereinslogo/Profilbilder ausschließlich im ausdrücklich ausgewählten Vereins-/Teamkontext – auch wenn im Datenbestand zusätzlich Vereins- oder Mannschaftsrollen existieren.
- Superadmin mit zusätzlicher Vereins-/Mannschaftsadmin-Rolle kann Vereinsasset-Upload, -Änderung, -Löschung und Profilbildverwaltung nur im ausgewählten Kontext ausführen.
- Alle Bilder laden über Signed URLs; Ablauf/Retry funktioniert.

## Negative Tests
- Anonymer Benutzer erhält kein Bild über Storage-RLS oder direkte öffentliche URL.
- Authentifizierter Benutzer ohne gemeinsame Mannschaft sieht kein fremdes Spielerfoto.
- Benutzer ohne Berechtigung sieht kein fremdes Profilbild.
- Nichtmitglied eines Vereins sieht kein Vereinslogo.
- Superadmin ohne passenden ausgewählten Kontext sieht keine Vereins-/Teamdateien und kann keine fremden Profilbilder oder Vereinsassets verwalten – auch bei zusätzlichen `club_admin`-/`admin`-Zuweisungen.
- Trainer kann kein fremdes Profilbild hochladen, ersetzen oder löschen.
- Superadmin mit ausgewähltem Vereinskontext kann nicht auf andere Vereine zugreifen; mit ausgewähltem Mannschaftskontext nicht auf andere Mannschaften.
- Manipulierte Profilbildpfade und fremde Benutzerordner werden abgewiesen.

## Regression
- Dashboard, Spielerlisten, Mitgliederlisten, Vereinsauswahl und Profilansichten.
- Login/Logout und Vereins-/Mannschaftskontextwechsel.
- iPhone/Safari: Profilbild, Spielerfoto, Vereinslogo.
- Backup/Restore: Pfade werden entsprechend dem bestehenden Backupumfang gesichert; keine ungeplante Löschung oder Objektverschiebung.

## Abnahme
Alle positiven und negativen Tests müssen bestanden sein. Ein unerlaubter Zugriff ist ein Sicherheitsblocker. Ein nicht ladendes Bild für berechtigte Benutzer ist ein Funktionsblocker. Kein PROD-Abschluss, bis alle Gates dokumentiert sind.


## Rollback-Gate: Frontend-Kompatibilität

Vor einer vollständigen Rückkehr zum alten Frontend zusätzlich read-only prüfen:
- Keine neuen Werte in `players.photo_path`.
- Keine Objekte in `player-photos`.
- Keine neuen Profilbildpfade im Format `<user-uuid>/avatar-<13-stellige Millisekunden>.(jpg|png|webp)` in `profiles.avatar_url`.
- Keine neu hochgeladenen Profilbildobjekte, die vom alten Frontend nicht als öffentliche URL referenziert werden können.

Sind neue Profilbild- oder Spielerfotodaten vorhanden, darf das alte Frontend nicht einfach zurückdeployt und IMG-SEC-01 nicht entfernt werden. Dann ist ein gesonderter Kompatibilitäts-/Migrationsplan erforderlich. Das neue Frontend bleibt bis dahin bestehen.

Für vollständigen Rollback gilt die Reihenfolge: IMG-SEC-03 (Buckets public; Sicherheitsdowngrade) → IMG-SEC-02 → altes Frontend deployen → IMG-SEC-01. Jede Stufe benötigt eine eigene ausdrückliche Freigabe.

