# IMG-SEC – PROD-Abnahmetestplan

Nur nach separater PROD-Ausführungsfreigabe und nach dem jeweiligen Migrations-Gate.

## Positive Tests
- Mannschaftsmitglied/Trainer sieht Spielerfotos seiner Mannschaft.
- Berechtigter Teamadmin kann Spielerfoto hochladen, ersetzen und entfernen.
- Benutzer sieht eigenes Profilbild.
- Gemeinsame Teammitglieder sehen Profilbilder gemäß DEV-Regel.
- Vereinsmitglied sieht das Vereinslogo.
- Vereinsadmin kann Vereinslogo verwalten.
- Superadmin sieht Vereinslogo/Profilbilder ausschließlich im ausdrücklich ausgewählten Vereins-/Teamkontext.
- Alle Bilder laden über Signed URLs; Ablauf/Retry funktioniert.

## Negative Tests
- Anonymer Benutzer erhält kein Bild über Storage-RLS oder direkte öffentliche URL.
- Authentifizierter Benutzer ohne gemeinsame Mannschaft sieht kein fremdes Spielerfoto.
- Benutzer ohne Berechtigung sieht kein fremdes Profilbild.
- Nichtmitglied eines Vereins sieht kein Vereinslogo.
- Superadmin ohne passenden ausgewählten Kontext sieht keine Vereins-/Teamdateien.
- Manipulierte Profilbildpfade und fremde Benutzerordner werden abgewiesen.

## Regression
- Dashboard, Spielerlisten, Mitgliederlisten, Vereinsauswahl und Profilansichten.
- Login/Logout und Vereins-/Mannschaftskontextwechsel.
- iPhone/Safari: Profilbild, Spielerfoto, Vereinslogo.
- Backup/Restore: Pfade werden entsprechend dem bestehenden Backupumfang gesichert; keine ungeplante Löschung oder Objektverschiebung.

## Abnahme
Alle positiven und negativen Tests müssen bestanden sein. Ein unerlaubter Zugriff ist ein Sicherheitsblocker. Ein nicht ladendes Bild für berechtigte Benutzer ist ein Funktionsblocker. Kein PROD-Abschluss, bis alle Gates dokumentiert sind.
