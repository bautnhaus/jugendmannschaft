# AP04 – Gemeinsame Profile und geschützte Rollenänderungen

Status: Migration in Supabase DEV ausgeführt; Frontend-Integration und vollständige Tests noch offen. PROD wurde nicht verändert.

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
- Noch nicht nachgewiesen: vollständige Post-Migration-Sicherheitsprüfung, Storage-Upload/Änderung/Löschung, Admin-Profiländerung, Selbst-Rollenänderung und Regressionstests.

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
