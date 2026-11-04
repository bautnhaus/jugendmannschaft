# AP04 – Gemeinsame Profile und geschützte Rollenänderungen

Status: DEV-Integration aktiv. Name und Profilbild (einzeln und gemeinsam), erneutes Laden sowie Passwortänderung wurden vom Nutzer manuell erfolgreich getestet. E-Mail-Änderung ist mangels freier Testadresse noch nicht manuell verifiziert. Statische JavaScript-Syntaxprüfung erfolgreich; PROD wurde nicht verändert.

**Dokumentationsabgrenzung:** Dieses Dokument behandelt gemeinsame Profile, Profilbilder sowie die Bearbeitung bestehender Mitglieder und ihrer Rollen. Die eigenständige Anlage von Vereinen und Mannschaften einschließlich der verpflichtenden Admin-Zuweisung ist im [Umsetzungsplan zur Vereins- und Mannschaftsanlage](CLUB_TEAM_CREATION_PLAN_2026-10-29.md) dokumentiert. Überschneidende Rollen-/Kontextregeln sind dort nicht erneut vollständig zu pflegen; maßgeblich sind die jeweils aktuellen fachlichen Entscheidungen und der tatsächliche Datenbankstand.

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
- Statischer JavaScript-Syntaxcheck für den aktualisierten `index.html` auf `develop`: erfolgreich. Die Datei wurde anschließend in `bautnhaus/jugendmannschaft-dev` auf `main` übertragen; der Deploy-Commit ist `a4bed23de0554e871dbc62d68714e00cafe10842`.
- **Noch offen:** manueller Praxistest der Vereinsmitglied-Maske auf dem iPhone mit Vereinsadmin und Superadmin, einschließlich Name/Bild, Vereinsrolle, Teamrollen, eigenem Rollen-Schutz, letztem Vereins-/Mannschaftsadmin und falschem/fehlendem Kontext. Syntax- und Schema-Prüfungen ersetzen diese Laufzeittests nicht.
- **PROD bleibt unverändert.** Diese Umsetzung und die drei Migrationen gelten ausschließlich für DEV.


## Superadmin-Mitgliederliste – Profilfelder im Vereinskontext (04.11.2026, DEV – SQL ausgeführt, Frontend deployed)

### Befund
- Die Live-Funktion `get_club_members_v2(uuid)` liefert `user_id`, `email`, `is_club_admin` und `teams`, jedoch weder `display_name` noch `avatar_url`.
- Die Superadmin-Kartenansicht verwendet deshalb die E-Mail-Adresse als Haupttext und bindet keine Profilfelder ein.
- Der Bearbeitungsdialog fragt `profiles` separat ab. Die aktuelle `profiles_select`-Policy erlaubt Selbstzugriff und Teamadmin-Zugriff, aber keinen allgemeinen Lesezugriff für einen Superadmin im ausgewählten Vereinskontext. Der Abfragefehler wird bisher nicht ausgewertet; das Namensfeld bleibt dadurch leer.
- Der gespeicherte Name selbst ist vorhanden und wird im Dashboard/Mein Bereich korrekt verwendet. Die Daten werden nicht neu geschrieben.

### Umgesetzte Lösung
- Neue read-only RPC `public.get_club_members_v3(p_club_id uuid)` mit den bisherigen Mitglieds-/Rollenfeldern plus `profiles.display_name` und `profiles.avatar_url`.
- Die RPC prüft `auth.uid()` und `can_manage_club_context(p_club_id)`; ein Superadmin benötigt damit weiterhin den ausdrücklich ausgewählten Vereinskontext. Vereinsadmins bleiben auf den eigenen Verein begrenzt.
- `get_club_members_v2` und die bestehende `profiles_select`-Policy bleiben unverändert.
- Beide Frontend-Mitgliederlisten verwenden jetzt die neue RPC. Die Superadmin-Karte zeigt den persönlichen Namen als Hauptzeile, E-Mail darunter und das Profilbild, falls vorhanden. Der Bearbeitungsdialog übernimmt Name und Avatar aus dem geladenen Mitgliedsdatensatz und führt keinen zusätzlichen direkten Profil-SELECT mehr aus.

### SQL-Dokumentation und Status
- **Ausführungs-ID:** `DB-MIG-2026-002`.
- Vollständiges ausgeführtes SQL und Ausführungsnachweis stehen in `DB_MIGRATION_LOG.md`; die Objekt-/Sicherheitsbeschreibung steht in `DB_CHANGELOG.md`, Eintrag DB-DEV-008.
- **SQL ausgeführt:** Migration `20261104113632_club_member_profiles_read_v3_dev`; versionierte SQL-Quelldatei und Verifikation sind im Ausführungsnachtrag unten dokumentiert. Die `profiles`-RLS bleibt unverändert; PROD bleibt unverändert.


### Ausführungsnachtrag 04.11.2026 – DB-DEV-008

- **Migration:** `20261104113632_club_member_profiles_read_v3_dev`
- **Versionierte SQL-Quelle:** `supabase/migrations/20261104113632_club_member_profiles_read_v3_dev.sql`
- **Ausführung:** Supabase DEV meldete `success: true`.
- **Verifiziert:** Rückgabeform der RPC enthält `display_name` und `avatar_url`; Funktion ist `SECURITY DEFINER`, `STABLE`, Owner `postgres`, fester `search_path`; EXECUTE für `authenticated`, nicht für `anon` oder `PUBLIC`.
- **RLS:** Die bestehenden Policies `profiles_select` und `profiles_update` sind unverändert.
- **Security Advisor:** Die generische SECURITY-DEFINER-Warnung umfasst nun 38 statt zuvor 37 Funktionen. Für diese RPC ist der Zugriff durch `auth.uid()` und `can_manage_club_context(p_club_id)` begrenzt; der Warnhinweis bleibt ausdrücklich dokumentiert.
- **Noch offen:** Laufzeittests mit Superadmin/Vereinsadmin und Negativtests für fehlenden bzw. fremden Vereinskontext sowie Frontend-Integration und iPhone-Praxistest.
- **PROD:** Nicht ausgeführt.


### Frontend-Nachtrag 04.11.2026 – DEV / develop

- **Commit:** `cb0a5b943e3bb367a9f7c5bfafd693803ec39ea0` – `fix(dev): load club member profiles through scoped RPC`.
- **Datei:** `index.html`, Blob-SHA `d58642e6a2903cd37722c161e34dcaff32e2d1e1`.
- **Änderungen:** Beide Mitglieder-Ladepfade verwenden `get_club_members_v3`; der Superadmin sieht Name als Hauptzeile und E-Mail darunter; ein vorhandenes Profilbild wird angezeigt; der Vereinsmitgliederbereich nutzt dieselben RPC-Profilfelder; der Bearbeitungsdialog verwendet den bereits geladenen Profildatensatz statt eines direkten Profil-SELECT.
- **Syntaxprüfung:** Die drei geänderten JavaScript-Blöcke wurden separat kompiliert; alle drei Prüfungen erfolgreich.
- **Deployment:** [Deploy DEV #41822962197](https://github.com/bautnhaus/jugendmannschaft/actions/runs/41822962197) erfolgreich. `jugendmannschaft-dev/main` steht auf demselben Commit; `index.html`-Blob-SHA in Quelle und DEV-Spiegel identisch.
- **Noch offen:** visueller Praxistest durch den Nutzer mit Superadmin und Vereinsadmin, Name/Avatar in der Liste, Bearbeitungsdialog, Speichern/erneutes Laden sowie Berechtigungs-Negativtests.
- **PROD:** Nicht verändert.


### Manueller Superadmin-Praxistest 04.11.2026

Der Nutzer hat nach dem DEV-Deployment beide Prüfpunkte bestätigt:
- In der Superadmin-Vereinsmitgliederliste wird der persönliche Name als Haupttext statt der E-Mail-Adresse angezeigt.
- Beim Öffnen von „Mitglied bearbeiten“ wird der gespeicherte persönliche Name korrekt in das Namensfeld übernommen.

**Ergebnis:** Beide Prüfungen bestanden. Damit ist der gemeldete Fehler im Superadmin-Mitgliederbereich behoben.

**Weiterhin offen:** Profilbildanzeige, Speichern und erneutes Laden einer Profiländerung, Prüfung mit Vereinsadmin im eigenen Vereinskontext sowie Negativtests ohne bzw. mit fremdem Vereinskontext. Keine weitere SQL-Änderung vorgenommen.


## Folgeprüfung 04.11.2026 – Ein-Mannschaft-Regel bei unabhängigen Verwaltungsrechten

### Read-only Befund

Der Vereinsmitglied-Bearbeitungsdialog bietet Rollenfelder für alle aktiven Mannschaften des Vereins. `admin_add_team_role` prüfte bislang nicht, ob die Zielperson bereits einer anderen Mannschaft angehört. `admin_create_team` und `admin_list_team_admin_candidates` boten weitere unzureichend abgesicherte Schreib-/Auswahlwege.

Die Einladungs-Edge-Function `invite-member` und `admin_complete_member_invitation` lehnen aktuell bestehende Superadmins als Zielperson ab. Diese Sperre widerspricht der am 04.11.2026 präzisierten Fachregel und wird im Korrekturvorschlag entfernt.

### Verbindliche Fachregel

- Eine Person darf höchstens einer Mannschaft tatsächlich zugeordnet sein.
- Superadmin und Vereinsadmin dürfen zusätzlich Vereins-/Mannschaftsrollen besitzen.
- Ein Superadmin kann Vereinsadmin eines Vereins sowie Mannschaftsadmin und Trainer derselben Mannschaft sein.
- Superadmins und Vereinsadmins dürfen weitere Mannschaften in ihren ausgewählten/eigenen Berechtigungskontexten verwalten, ohne dort Mitglied zu sein.
- Die Ein-Mannschaft-Regel betrifft ausschließlich die Zielperson einer tatsächlichen Zuordnung; sie darf nicht den handelnden Administrator einschränken.
- Eine bereits zugeordnete Person darf keiner zweiten Mannschaft zugeordnet werden, unabhängig von ihren globalen/vereinsbezogenen Rollen.
- Ein bestehendes Mannschaftsmitglied kann nachträglich Superadmin werden.

### Korrigierte Vorbereitung

Im Review-Branch `feature/dev-single-team-membership-guard-review` liegen:
- zentrale Triggerprüfung auf `team_members` und `team_member_roles`, die nur Mehrfachzuordnungen abweist und Superadmins zulässt;
- Vorprüfungen in `admin_add_team_role` und `admin_create_team`;
- Kandidatenfilter, der bereits Mannschaftszugeordnete ausblendet, Superadmins aber nicht allein wegen der globalen Rolle ausschließt;
- angepasste `admin_complete_member_invitation` und Edge-Function-Quelle `invite-member`, die Superadmins als Zielpersonen zulassen;
- UI-Sperre der anderen Mannschaftszuordnungen für eine bereits zugeordnete Zielperson, ohne den Handlungskontext des aktuellen Administrators zu beschränken;
- 410-Gone-Ersatz für den alten, nicht mehr vom Frontend genutzten Endpunkt `invite-trainer`.

### Status und Freigabe

- SQL-Vorschlag: `docs/proposals/single-team-membership-guard/migration.sql`.
- Read-only Prüfung nach einer späteren Freigabe: `docs/proposals/single-team-membership-guard/after_apply_verification.sql`.
- **Keine SQL-Ausführung, kein DEV-Deployment und keine Edge-Function-Aktualisierung erfolgt.**
- Bestehende RLS-Policies und PROD bleiben unangetastet.
- Vor der Umsetzung ist der korrigierte SQL- und Quellcodeumfang ausdrücklich freizugeben.
### Fachliche Präzisierung 04.11.2026 – Ein-Mannschaft-Regel und Verwaltungsrechte

Die frühere Annahme vollständiger Superadmin-Neutralität wurde ausdrücklich korrigiert.

- Höchstens eine tatsächliche Mannschaftsmitgliedschaft pro Benutzer.
- Superadmin und Vereinsadmin schließen Vereins-/Mannschaftsmitgliedschaften nicht aus.
- Ein Superadmin kann Vereinsadmin eines Vereins sowie Mannschaftsadmin und Trainer derselben Mannschaft sein.
- Superadmins und Vereinsadmins dürfen andere Mannschaften im berechtigten ausgewählten/eigenen Kontext verwalten, ohne dort selbst Mitglied zu sein.
- Die Ein-Mannschaft-Regel betrifft die Zielperson einer tatsächlichen Teamzuordnung, nicht die Handlungsmöglichkeiten des aufrufenden Administrators.
- Ein Benutzer, der bereits einer Mannschaft zugeordnet ist, darf keiner zweiten Mannschaft zugeordnet werden – auch nicht als Superadmin oder Vereinsadmin.
- Ein bereits zugeordnetes Mannschaftsmitglied kann nachträglich Superadmin werden; die Teammitgliedschaft bleibt erhalten.

Die Live-Kontextfunktionen wurden geprüft: `can_manage_club_context`, `has_selected_team_context` und `is_team_admin` unterstützen Verwaltung über ausgewählte Vereins-/Mannschaftskontexte, ohne dass der Handelnde jeder Mannschaft angehören muss.

Die aktuelle DEV-Laufzeit lehnt bestehende Superadmins in `invite-member` und `admin_complete_member_invitation` als Zielpersonen noch ab. Die korrigierte Fassung im Review-Branch entfernt diese Ausschlüsse. Keine dieser Änderungen ist bisher deployed oder in Supabase ausgeführt.
