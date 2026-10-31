# AP04 – Gemeinsame Profile und geschützte Rollenänderungen

Status: DEV-Integration aktiv; Namensspeicherung und Profilbild-Upload wurden vom Nutzer erfolgreich manuell getestet. E-Mail-/Passwortänderungen sowie kombinierte Speichervorgänge und weitere Regressionstests stehen noch aus. PROD wurde nicht verändert.

## Fachliche Entscheidungen
- Name und Profilbild sind gemeinsame persönliche Profildaten und gelten in allen Bereichen und Mannschaftskontexten.
- Mannschaftsrollen bleiben auf die jeweilige Mannschaft bezogen.
- Trainer können ihre eigenen Mannschaftsrollen nicht ändern. Rollenänderungen erfolgen durch berechtigte Mannschaftsadmins oder Superadmins im ausdrücklich ausgewählten Mannschaftskontext.
- E-Mail-Adresse wird über Supabase Auth verwaltet, nicht als frei editierbares Feld in `profiles`.

## DEV-Migration
- Name: `ap04_shared_member_profiles_avatar_and_protect_self_role_changes_dev`
- Betroffene Objekte:
  - `public.profiles.avatar_url` (neues optionales Textfeld; `display_name` bestand bereits)
  - Storage-Bucket `profile-avatars` (öffentlich lesbar, maximal 2 MiB, PNG/JPEG/WebP)
  - Storage-RLS-Policies für Upload, Update und Löschen durch Eigentümer oder berechtigte Teamadmins/Superadmins im ausgewählten Teamkontext
  - `public.admin_update_member_profile(uuid, uuid, text, text)`
  - `public.admin_add_team_role(uuid, uuid, text)` und `public.admin_remove_team_role(uuid, uuid, text)`: explizite Sperre für Selbständerung; bisherige Team-/Vereinsprüfungen und Schutz des letzten Admins beibehalten
- Ausführung: Supabase DEV meldete `success: true`.
- Folge-Migration: `ap04_harden_profile_avatar_storage_policy_uuid_casts_dev` (DEV, erfolgreich). Alle UUID-Casts in Storage-Policies sind nun durch UUID-Formatprüfung abgesichert, damit beliebige Objektpfade in anderen Buckets keine Cast-Fehler auslösen.
- Noch nicht nachgewiesen: vollständige Post-Migration-Sicherheitsprüfung, Storage-Upload/Änderung/Löschung, Admin-Profiländerung, Selbst-Rollenänderung und Regressionstests.

## Migrationen im Repository
- `supabase/migrations/20261031000000_ap04_shared_member_profiles_avatar_and_protect_self_role_changes_dev.sql`
- `supabase/migrations/20261031010000_ap04_harden_profile_avatar_storage_policy_uuid_casts_dev.sql`

Die zweite Datei ist zwingend nach der ersten auszuführen.

## PROD-Cutover
1. DEV-Testfreigabe abwarten.
2. Diese Migration als versionierte SQL-Datei aus dem Repository in den Release-Katalog übernehmen.
3. Vor PROD Schema und vorhandene Funktionen/Policies abgleichen; keine blinde Wiederholung, da DEV und PROD-Migrationshistorien abweichen können.
4. SQL einmalig in der dokumentierten Reihenfolge ausführen und Ergebnis protokollieren.
5. Frontend und gegebenenfalls Edge Functions erst nach erfolgreicher DEV-Abnahme gemeinsam releasen.
6. PROD nach Freigabe gezielt verifizieren.

## Offene Frontend-Arbeiten
- `Mein Bereich`: gemeinsames Profil laden/speichern, Name und Bild neben E-Mail/Passwort.
- Mitgliederkarte: Name/Bild aus `profiles`, Bearbeiten und Rollen-Checkboxen, sichere E-Mail-Änderung über Edge Function.
- Optionsmenü nach Vorbild Training/Spieltag; eigener Rollenbereich nicht bearbeitbar.
- Tests mit Mannschaftsadmin, Trainer und Superadmin im ausgewählten Mannschaftskontext.


## Frontend-Integration – DEV / develop

- Commit `39b11d3788598bd586ff9ed483486963bfc57ca1`: Profilname und Profilbild in der Mitgliederliste, Profilbearbeitung in der Mitgliedermaske sowie Profilbereich unter „Mein Konto“ ergänzt.
- Commit `5161f8e7dd672d59eb7b66c84ce42b3525d68791`: Speichern des eigenen Profils auf vorhandene Profilzeilen begrenzt und Rollen-/Letzter-Admin-Validierung vor dem Speichern der Mitgliederdaten ausgeführt.
- Datei: `index.html` im Branch `develop`.
- Mitgliederliste: Name und Profilbild werden aus `profiles.display_name` und `profiles.avatar_url` geladen; E-Mail und mannschaftsbezogene Rollen bleiben separat.
- Mitglied bearbeiten: Name, Profilbild und Checkboxen für Mannschaftsadmin/Trainer. E-Mail bleibt in dieser Maske unverändert und wird nicht durch eine ungesicherte direkte Änderung von Auth-Daten ersetzt.
- Eigenes Profil: Ein gemeinsamer Dialog „Konto bearbeiten“ enthält Name, Profilbild, E-Mail-Adresse und optionale neue Passwortfelder mit Bestätigung. Name/Bild werden im persönlichen Profil gespeichert; E-Mail/Passwort laufen über Supabase Auth. Rollencheckboxen sind für das eigene Konto deaktiviert; die Datenbankfunktionen schützen zusätzlich vor direkter Selbständerung.
- Profilbilder werden auf Clientseite skaliert und im Bucket `profile-avatars` abgelegt. Jedes Bild erhält einen eindeutigen Pfad (`<user-id>/avatar-<timestamp>.<ext>`) und wird ohne `upsert` hochgeladen, um den zusätzlichen UPDATE/SELECT-Berechtigungsweg beim Überschreiben zu vermeiden. Name und Bild werden global im persönlichen Profil gespeichert, Rollen weiterhin pro Mannschaft.

### Verbleibende Prüfung / bekannte Grenzen

- Manuelle DEV-Prüfung auf iPhone: Name allein speichern – erfolgreich; Profilbild auswählen, speichern und nach erneutem Laden sehen – erfolgreich; Name und Profilbild gemeinsam speichern und nach erneutem Laden prüfen – erfolgreich. Noch nicht verifiziert: E-Mail-Änderung, Passwortänderung, Name+Bild zusammen, Kombination mit Auth-Änderung, ungültige Dateitypen/Dateigrößen sowie Abbrechen.
- E-Mail-Änderungen anderer Mitglieder sind absichtlich nicht Bestandteil dieser UI-Integration. Dafür ist eine separat autorisierte serverseitige Auth-Admin-Funktion nötig.
- Noch zu prüfen: E-Mail-Änderung mit Bestätigung, Passwortänderung und Passwortbestätigung, kombinierte Änderungen und Teilfehlerbehandlung, ungültige Dateitypen/Dateigrößen, Abbrechen, sowie vollständige Rollen-/Mitglieder-Regressionsprüfungen. Die Mitgliederbearbeitung wird erst nach Abschluss dieser Tests vereinheitlicht.
- PROD bleibt unverändert. Diese Frontend-Commits und die DEV-Migrationen sind noch kein PROD-Release.
