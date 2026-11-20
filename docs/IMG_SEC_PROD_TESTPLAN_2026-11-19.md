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



## Vorab validierte technische Tests (DEV, 20.11.2026)

Die folgenden Tests wurden vor der PROD-Freigabe in vollständig zurückgerollten DEV-Transaktionen ausgeführt:
- IMG-SEC-01b Migration einschließlich Preflight, Schemawechsel, Rechte- und Policy-Postflight: bestanden.
- IMG-SEC-02 Migration einschließlich Preflight, Helper, Trigger, Profil-RPCs, Storage-Schreibpolicies und Postflight: bestanden.
- IMG-SEC-03 Migration einschließlich Preflight, Bucket-Cutover und Postflight: bestanden.
- IMG-SEC-03-Rollback nach simuliertem Cutover: bestanden; profile-avatars und club-assets wurden wieder public, player-photos blieb privat.
- Profilbildpfad-Validierung: korrekte JPG-/WEBP-Pfade akzeptiert; falsche User-ID, falsche Zeitstempel-Länge, SVG und Traversal abgewiesen.
- Profilbild-Trigger: ungültiger Pfad abgewiesen; gültiger Pfad und reine Namensänderung akzeptiert.
- Rollenmatrix: Trainer nur Selbstverwaltung, Teamadmin für Mitglieder derselben Mannschaft, Superadmin nur mit ausgewähltem Vereins-/Mannschaftskontext.

Die IMG-SEC-01- und IMG-SEC-02-Rollbacks wurden im bestehenden DEV-Datenbestand nicht vollständig ausgeführt, weil ihre Sicherheits-Preflights aufgrund vorhandener neuer Bilddaten korrekt abbrechen. Es wurden keine Objekte oder Referenzen gelöscht, um diese Gates zu umgehen.

## Zusätzlicher AP02-Freigabeblock

Vor jeder PROD-Ausführung muss die separate AP02-Superadmin-Kontextkorrektur abgeschlossen sein. Der aktuelle PROD-Bestand enthält direkte Vereins- und Teamadmin-Zuweisungen für einen Superadmin. IMG-SEC härtet die Bild-/Asset-Wege, aber nicht sämtliche übrigen Vereins-/Mannschaftsfunktionen und RLS-Policies. Die PROD-Abnahme beginnt daher erst nach separater AP02-Migration, kontrollierter Datenbereinigung und bestandenem AP02-DEV-Praxistest.
