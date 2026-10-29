# Vereins- und Mannschaftsanlage – Umsetzungsplan

**Stand:** 29.10.2026  
**Arbeitsbranch:** `develop` im Repository `bautnhaus/jugendmannschaft`  
**Supabase:** ausschließlich DEV, Projekt `pzazqvvoruqnqhcorbwx`  
**PROD:** unverändert  
**Status:** SQL-Migration in DEV ausgeführt; Frontendformulare ergänzt; Praxistest ausstehend

## 1. Bestehende Dokumentation als Grundlage

Diese Arbeit baut auf den bereits vorhandenen AP02-/AP03-Unterlagen im Repository `bautnhaus/jugendmannschaft-dev` auf, insbesondere:

- `docs/AP03_BESTANDSAUFNAHME_ROLLEN_BERECHTIGUNGEN_2026-10-26.md`
- `docs/AP03_SECURITY_ADVISOR_18_WARNINGS_DECISIONS_2026-10-27.md`
- `docs/AP02_P0_EXECUTION_READINESS.md`
- `docs/AP02_P0_DEV_TEST_MATRIX.md`
- `docs/AP02_P0_VALIDATION_REPORT.md`
- `DB_CHANGELOG_DEV_updated.md`
- `PROJECT_CONTEXT_updated.md`

Die Feature-Branches sind gegenüber `main` teils stark auseinanderentwickelt. Sie werden als Dokumentations- und Prüfquellen verwendet, aber nicht ungeprüft zusammengeführt. Die aktuelle Frontendbasis bleibt `develop` im Repository `bautnhaus/jugendmannschaft`.

## 2. Read-only-Befunde aus DEV

- `public.clubs` enthält aktuell nur `id`, `name`, `created_at` und `updated_at`.
- `public.teams` enthält `id`, `name`, `created_at`, `updated_at`, `recommended_squad_size` und `club_id`.
- `public.seasons` ist bereits teambezogen und wird von Trainings und Spieltagen referenziert.
- `public.admin_create_team(p_club_id uuid, p_name text, p_recommended_squad_size integer)` ist vorhanden. Die Funktion prüft derzeit `is_club_admin(p_club_id)`; diese Hilfsfunktion gewährt Super Admins globalen Zugriff und bindet die Erstellung daher noch nicht an einen explizit ausgewählten Vereinskontext. Die Funktion fügt den Aufrufer außerdem als Mannschaftsadmin hinzu, was für den neutralen Super Admin nicht übernommen werden soll.
- Eine `admin_create_club`-RPC wurde nicht gefunden.
- In Supabase Storage ist derzeit kein Bucket für Vereinswappen vorhanden.
- `clubs` und `teams` haben RLS aktiviert. Für `clubs` wurde keine direkte INSERT-Berechtigung für `authenticated` festgestellt. Die Vereinserstellung muss daher über eine serverseitig abgesicherte RPC laufen.
- Keine Tabellen, Daten, Policies, Storage-Buckets oder Funktionen wurden geändert.

## 3. Fachliches Datenmodell

### Verein

Bestehendes Pflichtfeld:
- `name` – Vereinsname.

Zusätzliche Felder:
- `short_name` – optionaler Kurzname.
- `crest_path` – optionaler Storage-Pfad des Wappens; PNG-Transparenz bleibt erhalten, weil die Datei unverändert gespeichert wird.
- Heimspielstätte: `home_venue_name`, `home_venue_street`, `home_venue_postal_code`, `home_venue_city`, `home_venue_country`.
- `training_location_differs` – Kennzeichen, ob der Trainingsort abweicht.
- Separater Trainingsort: `training_venue_name`, `training_venue_street`, `training_venue_postal_code`, `training_venue_city`, `training_venue_country`.

Wenn `training_location_differs = false`, werden keine doppelten Trainingsadressdaten gespeichert. Die Oberfläche verwendet dann die Heimspielstätte als Trainingsort. Wenn die Checkbox aktiviert ist, müssen Name und Adresse des abweichenden Trainingsorts vollständig angegeben werden. Wappen-Dateien werden auf PNG/JPEG/WebP und eine angemessene Dateigröße begrenzt; für transparente Wappen wird PNG empfohlen.

### Mannschaft

Zusätzliche Felder:
- `birth_cohorts` – optionaler Jahrgangstext, z. B. `2019/2020`.
- `abbreviation` – optionale Kurzbezeichnung, z. B. `F1`.
- Die Saison wird nicht redundant in `teams` gespeichert. Wenn bei der Anlage eine Saison angegeben wird, wird dafür ein Datensatz in der bestehenden Tabelle `seasons` angelegt und als aktiv markiert. So bleibt die vorhandene Verknüpfung zu Trainings und Spieltagen konsistent.
- Die empfohlene Kadergröße bleibt wie bisher standardmäßig 16, sofern kein anderer Wert angegeben wird.

## 4. Sicherheits- und Kontextkonzept

Die bisherigen Entscheidungen bleiben verbindlich:
- Super Admin ist neutral und wird nicht automatisch Vereinsmitglied oder Mannschaftsadmin.
- Super Admin darf Verwaltungsaktionen nur in einem ausdrücklich ausgewählten Kontext ausführen.
- Vereinsadmins dürfen nur ihren eigenen Verein verwalten.
- Direkte Frontend-Schreibzugriffe auf `clubs` werden nicht eingeführt.
- RLS bleibt aktiviert; serverseitige Berechtigungsprüfungen ergänzen die UI-Sichtbarkeit, nicht umgekehrt.

Vorgesehene SQL-Bausteine:
1. Tabelle `public.user_club_context` für den ausdrücklich ausgewählten Vereinskontext (pro Benutzer maximal ein aktiver Kontext).
2. RPCs zum Auswählen, Abrufen und Löschen des Vereinskontexts.
3. Serverseitig abgesicherte `admin_create_club(...)`-RPC für Super Admins. Sie speichert die Vereinsstammdaten und setzt den neuen Verein als ausgewählten Kontext, ohne eine Vereinsmitgliedschaft anzulegen.
4. Erweiterung der Mannschaftserstellung um Jahrgänge, Kürzel und optionale Saison. Super Admins benötigen den passenden ausgewählten Vereinskontext und erhalten keine künstliche Teammitgliedschaft; echte Vereinsadmins werden wie bisher beim neu angelegten Team als Teamadmins eingetragen.
5. Geschützter Storage-Bucket `club-assets` mit Upload-/Änderungsregeln für Super Admins im ausgewählten Vereinskontext bzw. Vereinsadmins ihres eigenen Vereins. Der öffentliche Abruf ist auf Vereinswappen beschränkt, die bewusst als öffentliche Vereinsdarstellung dienen.
6. Funktionsrechte werden explizit auf `authenticated` begrenzt; `anon` und `PUBLIC` erhalten keine Ausführungsrechte für administrative RPCs.

## 5. Geplante Umsetzung und Abnahme

1. SQL-Migration mit vollständigem SQL-Release-Eintrag vorbereiten und reviewen.
2. Vor der Ausführung die ausdrückliche Freigabe des Nutzers einholen.
3. Nach Freigabe ausschließlich in DEV ausführen.
4. Schema, Funktionsdefinitionen, EXECUTE-Rechte, RLS-Policies und Storage-Regeln read-only nachprüfen.
5. Frontend-Formulare ergänzen:
   - Verein anlegen: Vereinsname, Kurzname, Wappen-Upload, Heimspielstätte, Checkbox und Felder für abweichenden Trainingsort.
   - Mannschaft anlegen: Name, Jahrgänge, Saison, Kürzel.
   - Nach erfolgreicher Anlage Listen aktualisieren und den neuen Datensatz direkt anzeigen.
6. In DEV testen: erfolgreicher und fehlerhafter Formularversuch, fehlende Pflichtfelder, falscher Rollen-/Kontextzugriff, Wappen-Upload und PNG-Transparenz, Saisonverknüpfung, Teamadmin-Zuordnung, Super-Admin-Neutralität.
7. Dieses Dokument sowie den bestehenden DB-Changelog/SQL-Release-Katalog mit Migration-ID, Prüfergebnissen und offenem PROD-Cutover aktualisieren.
8. PROD bleibt bis zu einer separaten Freigabe unverändert.

## 6. Ausführung und aktueller Status

- Die DEV-Migrationen `20261029045927_club_team_creation_and_club_context_20261029` und `20261029050011_club_team_creation_20261029` wurden in der Supabase-Migrationshistorie bestätigt.
- Die Schema- und Rechte-Nachprüfung ist abgeschlossen; Details stehen in `DB_CHANGELOG_DEV_updated.md` unter DB-DEV-005.
- `index.html` in `develop` enthält jetzt ein Formular zur Vereinsanlage einschließlich Adressen, optionalem Wappen und bedingtem Trainingsort sowie ein Formular zur Mannschaftsanlage mit Jahrgängen, Saison, Kürzel und Kadergröße.

- Nachtrag: Vereinswappen werden nach dem Upload auch in der Vereinsliste und im Vereinsdetail angezeigt; PNG-Transparenz wird durch `object-fit: contain` und transparenten Hintergrund erhalten.
- Die Inline-JavaScript-Syntaxprüfung ist bestanden. Der interaktive Praxistest im Browser steht noch aus.
- **PROD bleibt unverändert.**
