# AP04 – Gemeinsame Profile und geschützte Rollenänderungen

Status: DEV-Integration aktiv. Name und Profilbild (einzeln und gemeinsam), erneutes Laden sowie Passwortänderung wurden vom Nutzer manuell erfolgreich getestet. E-Mail-Änderung ist mangels freier Testadresse noch nicht manuell verifiziert. Statische JavaScript-Syntaxprüfung erfolgreich; PROD wurde nicht verändert.

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

- Manuelle DEV-Prüfung auf iPhone: Name allein speichern – erfolgreich; Profilbild auswählen, speichern und nach erneutem Laden sehen – erfolgreich; Name und Profilbild gemeinsam speichern und nach erneutem Laden prüfen – erfolgreich; Passwortänderung – Nutzer bestätigt erfolgreiche Änderung. Noch nicht verifiziert: E-Mail-Änderung (Test aktuell nicht möglich, da keine freie E-Mail-Adresse verfügbar ist), ungültige Dateitypen/Dateigrößen sowie Abbrechen. Kombinationen mit Auth-Änderungen und Teilfehlerbehandlung sind ebenfalls noch nicht vollständig getestet. Die E-Mail-Eingabe wird clientseitig zusätzlich auf ein gültiges E-Mail-Format geprüft; diese Validierung wurde statisch geprüft, aber noch nicht manuell auf dem iPhone getestet.
- E-Mail-Änderungen anderer Mitglieder sind absichtlich nicht Bestandteil dieser UI-Integration. Dafür ist eine separat autorisierte serverseitige Auth-Admin-Funktion nötig.
- Noch zu prüfen: E-Mail-Änderung mit Bestätigung (sobald eine geeignete Testadresse verfügbar ist), Passwortfeld-Validierung am Gerät, kombinierte Änderungen und Teilfehlerbehandlung, ungültige Dateitypen/Dateigrößen, Abbrechen sowie vollständige Rollen-/Mitglieder-Regressionsprüfungen. Die Mitgliederbearbeitung wird erst nach Abschluss dieser Tests vereinheitlicht.
- Automatischer statischer Syntaxcheck der beiden Inline-JavaScript-Blöcke in `index.html` auf `develop`: erfolgreich (Modul-Import für den Parser entfernt; Quelltext selbst nicht verändert). Der Check beweist keine Laufzeit- oder Auth-Funktionalität.
- PROD bleibt unverändert. Diese Frontend-Commits und die DEV-Migrationen sind noch kein PROD-Release.


## Vereinsmitglied-Maske – Implementierung 31.10.2026 (DEV)

- Die Vereinsverwaltung verwendet nun einen gemeinsamen Dialog für **Mitglied hinzufügen** und **Mitglied bearbeiten**.
- Der Dialog umfasst Name, Profilbild, E-Mail-Adresse, Vereinsrolle sowie Mannschaftsadmin-/Trainerrollen für die Mannschaften des ausgewählten Vereins.
- Beim Hinzufügen wird ein bestehendes Konto über die E-Mail-Adresse zugeordnet. Ein neues Auth-Konto wird nicht durch diese Maske angelegt; dafür ist weiterhin der Einladungsablauf vorgesehen.
- Profilname und Profilbild werden über `admin_update_club_member_profile` im Vereinskontext gespeichert. Die Funktion prüft serverseitig `can_manage_club_context(p_club_id)` und verlangt eine bestehende Mitgliedschaft des Zielkontos im selben Verein.
- Die Storage-Policies für `profile-avatars` erlauben Admin-Uploads/Änderungen/Löschungen nur, wenn das Zielkonto zu einem Verein gehört, dessen Kontext der aktuelle Nutzer verwalten darf. Der eigene Avatar bleibt weiterhin erlaubt.
- Rollen-RPCs `admin_add_team_role` und `admin_remove_team_role` erlauben jetzt zusätzlich Vereinsadmins und Superadmins mit ausgewähltem Vereinskontext, begrenzt auf Mannschaften dieses Vereins. Selbständerungen bleiben gesperrt; der Schutz des letzten Mannschaftsadmins bleibt erhalten.
- `admin_add_club_member_by_email` und `admin_set_club_member_role` verlangen nun `can_manage_club_context(p_club_id)`; Superadmins ohne passenden ausgewählten Vereinskontext werden serverseitig abgewiesen. Eigene Vereinsrollen können nicht geändert werden. Der Schutz des letzten Vereinsadmins bleibt erhalten.
- DEV-Migrationen:
  - `20261031020000_ap04_club_member_editor_profile_and_avatar_scope_dev.sql`
  - `20261031030000_ap04_club_context_team_role_editing_dev.sql`
  - `20261031040000_ap04_enforce_selected_club_context_for_member_roles_dev.sql`
- Alle drei Migrationen wurden auf Supabase DEV erfolgreich angewendet. Die Datenbankprüfung bestätigt, dass die sechs betroffenen RPCs als `SECURITY DEFINER` bestehen und `authenticated` Ausführungsrechte besitzt; die drei Avatar-Policies für INSERT/UPDATE/DELETE sind vorhanden.
- Statischer JavaScript-Syntaxcheck für den aktualisierten `index.html` auf `develop`: erfolgreich. Der Quelltext des DEV-Deploy-Repositories entspricht bytegenau der aktualisierten Datei (gleiche Blob-SHA).
- **Noch offen:** manueller Praxistest der Vereinsmitglied-Maske auf dem iPhone mit Vereinsadmin und Superadmin, einschließlich Name/Bild, Vereinsrolle, Teamrollen, eigenem Rollen-Schutz, letztem Vereins-/Mannschaftsadmin und falschem/fehlendem Kontext. Syntax- und Schema-Prüfungen ersetzen diese Laufzeittests nicht.
- **PROD bleibt unverändert.** Diese Umsetzung und die drei Migrationen gelten ausschließlich für DEV.
