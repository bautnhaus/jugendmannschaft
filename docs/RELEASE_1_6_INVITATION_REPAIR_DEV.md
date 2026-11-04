# Release 1.6 – Mitglieder-/Trainer-Einladung (DEV-Arbeitsstand)

**Stand:** 04.11.2026  
**Status:** Ein erster Trainer-Einladungs-End-to-End-Test ist erfolgreich; bestehender Superadmin wurde zusätzlich als Trainer und Vereinsadmin zugeordnet, ohne vorhandene Rollen zu verlieren. DB-DEV-009 ist in DEV ausgeführt; beide korrigierten Edge Functions sind in DEV Version 4 deployed. Die Frontend-Korrekturen für Vereinsadmin-Kontext, Mitgliederlisten und Mannschaftsübersicht sind im DEV-Browser nachgetestet und bestanden. Offen sind nur die gezielten Release-1.6-Abschlussprüfungen in Abschnitt 18.  
**Geltungsbereich:** ausschließlich Supabase DEV und GitHub `develop` / DEV-Deployment  
**PROD:** unverändert; kein PROD-SQL, keine PROD-Konfiguration, kein PROD-Deployment.

## 1. Fachliche Entscheidungen

### Einladungskontexte

1. **Super Admin und Vereinsadmin:** dürfen im ausdrücklich ausgewählten Vereinskontext ein Vereinsmitglied, einen Vereinsadmin, einen Mannschaftsadmin oder einen Trainer einladen.
2. **Mannschaftsadmin:** darf innerhalb der eigenen Mannschaft einen Mannschaftsadmin oder Trainer einladen. Die Vereinsmitgliedschaft im Verein der Mannschaft wird automatisch hergestellt.

Ein Mannschaftsmitglied wird derzeit höchstens einer Mannschaft zugeordnet, weil der normale App-Einstieg Mehrfachzuordnungen ausdrücklich noch nicht unterstützt.

### Persönlicher Name

Variante A ist beschlossen: `profiles.display_name` ist die einzige maßgebliche Quelle für den persönlichen Namen. Es gilt für Mein Bereich, Dashboard-Begrüßung, Vereins-/Mannschaftslisten sowie Trainings-/Spieltags-Traineranzeigen.

`team_members.admin_label` wird nicht mehr für Anzeigen oder neue Einladungen verwendet. Vorhandene Werte bleiben zunächst unverändert und werden nicht automatisch gelöscht oder migriert.

Bei der Einladung:
- neues Profil: persönlicher Name wird initial gespeichert;
- bestehendes Profil mit leerem Namen oder E-Mail-Fallback: persönlicher Name wird ergänzt;
- bestehender persönlicher Name: wird nicht ungefragt überschrieben.

## 2. Technischer Stand in DEV

### Datenbank

Migration:
- Version: `20261103203047`
- Name: `r16_member_invitation_transaction_dev`
- Funktion: `public.admin_complete_member_invitation(p_user_id uuid, p_display_name text, p_club_id uuid, p_invited_role text, p_team_id uuid DEFAULT NULL)`
- Ausführung: Supabase DEV erfolgreich
- Verifikation: Funktion vorhanden; `SECURITY DEFINER`; EXECUTE für `authenticated`, nicht für `anon` oder `PUBLIC`.
- Vollständiger Ausführungsnachweis: `DB_MIGRATION_LOG.md`, Eintrag DB-DEV-007.
- Objekt-/Funktionsbeschreibung: `DB_CHANGELOG.md`, Eintrag DB-DEV-007.

### Edge Function

Neue Funktion: invite-member
- Quelldatei: supabase/functions/invite-member/index.ts
- Aktueller DEV-Status (Nachtrag 04.11.2026): ACTIVE, Version 4; JWT-Prüfung aktiviert.
- Aufgabe: Anmeldenden und Kontext prüfen, bestehende Auth-Benutzer ermitteln, existierende Vereins-/Mannschaftszuordnungen prüfen, DEV-Redirect aus Projektkennung wählen, Einladungsversand bzw. bestehendes Konto behandeln und danach die transaktionale Datenbankfunktion aufrufen.
- Die vorherige Sperre gegen bestehende Superadmin-Konten als Zielpersonen ist entfernt. Die zentrale Datenbankfunktion prüft die Ein-Mannschaft-Regel transaktional.
- Die alte Funktion invite-trainer ist ebenfalls Version 4 und liefert für Nicht-OPTIONS-Anfragen HTTP 410 Gone. Beide Funktionen behalten verify_jwt=true.

### Frontend

Datei: `index.html`
- die drei Einladungseinstiege rufen jetzt `invite-member` auf;
- Vereinsmaske bietet Vereinsmitglied, Vereinsadmin, Mannschaftsadmin und Trainer; bei Mannschaftsrollen wird genau eine Mannschaft verlangt;
- Mannschaftsmaske bietet Mannschaftsadmin und Trainer;
- das Dashboard und die Mitglieder-/Traineranzeigen verwenden `profiles.display_name`;
- verbliebene Frontend-Verwendungen von `admin_label` wurden entfernt;
- ein reines Vereinsmitglied ohne Mannschaft erhält einen eingeschränkten Einstieg mit Hinweis auf die fehlende Mannschaftszuordnung;
- der Passwort-Abschluss unterscheidet „Passwort gespeichert“ von einem späteren Fehler beim Laden des App-Kontexts.

## 3. Deployment-Nachweise

- Der Code-/Frontend-Stand wurde auf Commit `1da3a179299c9059d5414078dc9d8ba93863bfa9` durch [Deploy DEV #348](https://github.com/bautnhaus/jugendmannschaft/actions/runs/41716381902) erfolgreich nach `jugendmannschaft-dev/main` gespiegelt; das Job-Log bestätigt `af3ab5d..1da3a17 HEAD -> main`.
- Die anschließende Dokumentationsaktualisierung auf Commit `fa9d978566686153052ea4b251e8cadb065fa7de` wurde durch [Deploy DEV #349](https://github.com/bautnhaus/jugendmannschaft/actions/runs/41716616554) ebenfalls erfolgreich gespiegelt.
- Bei beiden Abgleichen hatte `index.html` in `develop` und `jugendmannschaft-dev/main` denselben Blob-SHA: `2f6d90cf79cf235d4c82489dd693517f88a50785`.
- Historischer Zwischenstand vor der Rollenmodell-Korrektur: Supabase DEV invite-member Version 3. Der aktuelle Deployment-Stand (Version 4) und der Live-Quelltextabgleich sind im Nachtrag 12 dokumentiert.
- Die DEV Auth-Site-URL und Redirect-Allowlist wurden read-only anhand der vom Nutzer bereitgestellten Screenshots geprüft und enthalten die DEV-App-Adresse.
- Für den E-Mail-Versand ist Brevo bereits als SMTP-Lösung eingerichtet. Eine SMTP-Anbietereinrichtung ist kein offener Punkt dieses Releases. Die tatsächliche Zustellung bleibt Teil der End-to-End-Abschlussprüfung.

## 4. Grenzen und noch offene Praxistests

**End-to-End-Nachweis vom 04.11.2026:** Eine echte DEV-Einladung für die Rolle Trainer wurde aus der Vereinsverwaltung ausgelöst. Die Einladungs-E-Mail kam an, der Link öffnete DEV, die Passwortvergabe war erfolgreich und anschließend wurde das Dashboard mit dem eingeladenen Namen angezeigt. Eine read-only Prüfung bestätigte den Auth-Benutzer mit gesetztem `email_confirmed_at`, den gespeicherten `profiles.display_name`, die Vereinsmitgliedschaft sowie die Trainerrolle in `team_members` und den korrespondierenden Eintrag in `team_member_roles`. Dieser erfolgreiche Fall deckt ausschließlich einen Trainer-Testfall in einer Mannschaft ab; weitere Rollen- und Kontextkombinationen bleiben offen. Ein Folgefehler in der Superadmin-Mitgliederliste und im Mitglied-bearbeiten-Dialog ist separat identifiziert und unten dokumentiert.

Mindestens folgende Tests sind noch auszuführen:

| Test | Kontext/Rolle | Erwartung | Status |
|---|---|---|---|
| Neue E-Mail einladen | Super Admin → Vereinsmitglied | Auth-Einladung, Vereinsmitgliedschaft, persönlicher Name | Offen |\n| Neue E-Mail einladen | Vereinsverwaltung → Trainer (G-Junioren) | E-Mail, Passwort, Vereinsmitgliedschaft und Trainerrolle | Erfolgreich (04.11.2026; ein Testfall) |
| Neue E-Mail einladen | Super Admin → Vereinsadmin | Vereinsmitgliedschaft + Vereinsadminrolle | Offen |
| Neue E-Mail einladen | Vereinsadmin → Vereinsmitglied | Zuordnung im ausgewählten Verein | Offen |
| Neue E-Mail einladen | Vereinsadmin → Mannschaftsadmin | Vereinsmitgliedschaft + Mannschaftsadminrolle | Offen |
| Neue E-Mail einladen | Vereinsadmin → Trainer | Vereinsmitgliedschaft + Trainerrolle | Offen |
| Neue E-Mail einladen | Mannschaftsadmin → Mannschaftsadmin | Automatische Vereinsmitgliedschaft + Mannschaftsadminrolle | Offen |
| Neue E-Mail einladen | Mannschaftsadmin → Trainer | Automatische Vereinsmitgliedschaft + Trainerrolle | Offen |
| Einladungslink | DEV | Öffnet DEV und zeigt Passwort-Erstellung | Erfolgreich (04.11.2026; ein Testfall) |
| Passwort setzen und Login | neue Einladung | Passwort wird gespeichert; anschließend Dashboard mit korrektem Kontext | Erfolgreich (04.11.2026; ein Testfall) |
| Persönlicher Name | Einladung / Dashboard / Mein Bereich sowie Mitgliederliste/Bearbeitungsdialog | Im erfolgreichen Trainer-Einladungstest gespeichert und im Dashboard angezeigt; Mitgliederliste und Bearbeitungsdialog separat nachgetestet | Erfolgreich (04.11.2026) |
| Bestehendes bestätigtes Konto | Vereinsadmin lädt vorhandenen Superadmin als Trainer ein | Bestehendes Konto wird zugeordnet; globale Superadmin-Rolle bleibt erhalten; keine zweite Mannschaft | Erfolgreich (04.11.2026; Datenbank read-only verifiziert) |
| Offenes/unbestätigtes Auth-Konto | alle Kontexte | Bestehendes Konto übernehmen; keine neue Mail behaupten, wenn Supabase keine bestätigt; ursprünglichen Link prüfen | Offen |
| Abweichender Verein | alle Kontexte | Kontrollierte Ablehnung | Offen |
| Andere Mannschaft vorhanden | Bestehendes Superadmin-Konto mit Trainerrolle in DEV Mannschaft soll zusätzlich G-Junioren erhalten | Einladung wird durch vorhandene Vereinsmitgliedschaft auf UI-Ebene gestoppt; Bearbeitungsdialog zeigt andere Mannschaft, deaktiviert deren Rollenfelder und erklärt den zweistufigen Wechsel | UI-Schutz bestätigt (04.11.2026); serverseitiger Negativaufruf nicht ausgelöst |
| Wiederholte Einladung | gleicher Empfänger | Keine doppelten Konten/Rollen; Warnung bei Teilfehlern | Offen |
| Nicht autorisierte externe E-Mail | Standard-SMTP | Verständlicher Versandfehler; kein falscher Erfolg | Offen |

### SMTP / E-Mail-Zustellung

Brevo ist bereits als SMTP-Lösung eingerichtet. Es ist daher weder eine SMTP-Anbieterauswahl noch eine neue SMTP-Einrichtung als offener Release-Punkt zu führen. Die vorhandene Brevo-Konfiguration wird nicht im Rahmen dieser Abschlussrunde verändert. Im End-to-End-Test wird lediglich geprüft, dass eine Einladung an einen externen Testempfänger zugestellt wird und der Link den DEV-Passwortfluss korrekt öffnet.

### Offene/unbestätigte Einladungen

Bei einer bereits vorhandenen, noch nicht bestätigten Auth-Identität versucht die Edge Function erneut den Supabase-Einladungsaufruf. Wenn Supabase keine neue E-Mail bestätigt, wird das vorhandene Konto erneut gelesen und die erlaubte Zuordnung kontrolliert verarbeitet. Die Antwort enthält nun ausdrücklich die Warnung, dass keine neue Einladungs-E-Mail bestätigt wurde und der ursprüngliche Link geprüft werden muss. Ein automatischer Ersatz für einen abgelaufenen Invite-Link ist derzeit nicht implementiert. Dieses Szenario bleibt ein offener Praxistest; ein zuverlässiger Resend ist nicht bestätigt.

Die Supabase-Dokumentation weist darauf hin, dass Invite-Links entsprechend der Einstellung `Email OTP Expiration` ablaufen (Standardwert: eine Stunde). Der tatsächliche DEV-Wert wurde nicht ausgelesen. Siehe [Supabase – Users / Inviting users](https://supabase.com/docs/guides/auth/users).

### Wiederherstellung / Rollback

- Die neue Datenbankfunktion kann nach Prüfung aller Abhängigkeiten mit `DROP FUNCTION IF EXISTS public.admin_complete_member_invitation(uuid,text,uuid,text,uuid);` entfernt werden.
- Die neue Edge Function kann deaktiviert/entfernt werden, sobald keine Frontend-Version sie mehr aufruft.
- Das Frontend kann durch Rücknahme der DEV-Commits wieder auf den vorherigen Stand gesetzt werden.
- Keine bestehenden Auth-Benutzer oder Mitgliedschaftsdaten wurden durch diese Implementierung geändert.

## 5. Nächster Schritt

Mit dem Nutzer die DEV-Praxistests durchführen. Vor jedem echten E-Mail-Test Empfänger, Rolle und Verein/Mannschaft eindeutig bestimmen. Keine Testeinladung an reale externe Adressen ohne geeigneten Versandweg. PROD bleibt bis zu einer späteren separaten ausdrücklichen Freigabe unangetastet.


## 6. Nachtrag 04.11.2026 – Profilnamen in der Superadmin-Mitgliederverwaltung

### Beobachtung
Der erste Einladungs-End-to-End-Test ist erfolgreich. Der eingegebene Name wird in `profiles.display_name` gespeichert und im Dashboard sowie unter „Mein Bereich“ angezeigt. In der Superadmin-Mitgliederliste wird dagegen noch die E-Mail-Adresse als Haupttext gezeigt; im Dialog „Mitglied bearbeiten“ ist das Namensfeld leer.

### Read-only-Ursache
- `get_club_members_v2(uuid)` gibt keine Profilfelder zurück.
- Die Superadmin-Kartenansicht verwendet `m.email` als Haupttext und fragt Profile nicht ab.
- Der Bearbeitungsdialog fragt `profiles` direkt ab. Die bestehende `profiles_select`-Policy deckt den ausgewählten Superadmin-Vereinskontext nicht ab; der Frontend-Code ignoriert den Fehler.
- Das Profil selbst ist vorhanden. Es ist keine Datenkorrektur oder erneute Einladung erforderlich.

### Umgesetzter Fix
Neue read-only RPC `get_club_members_v3(uuid)` mit Profilname und Avatar, abgesichert über `auth.uid()` und `can_manage_club_context(p_club_id)`. Die bestehende RPC v2 und die RLS-Policies bleiben unverändert. Beide Mitgliederlisten und der Bearbeitungsdialog wurden auf die neue RPC umgestellt; der direkte Profil-SELECT im Bearbeitungsdialog entfällt.

**SQL-Status:** DB-MIG-2026-002 wurde in Supabase DEV erfolgreich ausgeführt (Version `20261104113632`). Vollständiger Ausführungsnachweis und SQL-Quelle stehen in `DB_MIGRATION_LOG.md` und `supabase/migrations/20261104113632_club_member_profiles_read_v3_dev.sql`. Die Frontend-Integration ist in `develop` umgesetzt und nach DEV deployed. Der Superadmin-Praxistest für Mitgliederliste und Bearbeitungsdialog ist am 04.11.2026 bestanden; weitere Kontext- und Profiltests bleiben offen. PROD bleibt unverändert.


## 7. Datenbank-Folgekorrektur – DB-DEV-008 (04.11.2026)

- **Migration:** `20261104113632_club_member_profiles_read_v3_dev`
- **Datei:** `supabase/migrations/20261104113632_club_member_profiles_read_v3_dev.sql`
- **Status:** In Supabase DEV erfolgreich ausgeführt und strukturell/rechtlich verifiziert.
- **Zweck:** Profilnamen und Avatare für die berechtigte Vereinsmitgliederverwaltung bereitstellen.
- **Sicherheitsgrenzen:** `auth.uid()` und `can_manage_club_context(p_club_id)` werden vor jeder Rückgabe geprüft. `PUBLIC` und `anon` besitzen kein EXECUTE-Recht. Die bisherige RPC v2 und die `profiles`-RLS-Policies bleiben unverändert.
- **Umgesetzt:** Frontend-Aufrufe auf v3 umgestellt; Namen und Avatare in beiden Mitgliederlisten dargestellt; Bearbeitungsdialog übernimmt die bereits geladenen Profilfelder.
- **Manuell bestanden (04.11.2026):** Superadmin-Mitgliederliste zeigt den Profilnamen; „Mitglied bearbeiten“ übernimmt denselben Namen korrekt.
- **Noch offen:** Vereinsadmin im eigenen Vereinskontext sowie positive/negative Berechtigungs- und Kontexttests, Profilbild und Speichern/erneutes Laden.
- **PROD:** Unverändert.


## 8. Frontend-Integration und DEV-Deployment (04.11.2026)

- **Commit:** `cb0a5b943e3bb367a9f7c5bfafd693803ec39ea0`.
- **Datei:** `index.html`, Blob-SHA `d58642e6a2903cd37722c161e34dcaff32e2d1e1`.
- **Änderungen:** Die Superadmin- und Vereinsadmin-Mitgliederlisten verwenden `get_club_members_v3`. Der Superadmin sieht den Profilnamen als Hauptzeile und die E-Mail darunter. Vorhandene Profilbilder werden verwendet. Der Bearbeitungsdialog bezieht Name und Avatar aus dem bereits geladenen Mitgliedsdatensatz; eine separate direkte Profilabfrage wird dort nicht mehr ausgeführt.
- **Statische Syntaxprüfung:** Die drei geänderten JavaScript-Blöcke (Superadmin-Mitgliederansicht, Vereinsmitgliederansicht und Mitglied-Bearbeiten-Dialog) wurden separat kompiliert; alle drei erfolgreich.
- **Automatischer Deploy:** [Deploy DEV #41822962197](https://github.com/bautnhaus/jugendmannschaft/actions/runs/41822962197) erfolgreich. DEV-Repository `bautnhaus/jugendmannschaft-dev/main` enthält denselben Commit. Der `index.html`-Blob-SHA stimmt zwischen `develop` und DEV-Spiegel überein.
- **Manuell bestätigt (04.11.2026):** Name statt E-Mail in der Superadmin-Mitgliederliste; gespeicherter Name wird beim Öffnen des Bearbeitungsdialogs korrekt angezeigt.
- **Noch offen:** Profilbildanzeige, Speichern/erneutes Laden von Profiländerungen sowie Vereinsadmin- und Kontext-Negativtests.
- **PROD:** Unverändert.


## 9. Manueller Praxistest – Superadmin-Profilanzeige (04.11.2026)

Der Nutzer hat nach dem DEV-Deployment beide Prüfpunkte bestätigt:

| Test | Erwartung | Ergebnis |
|---|---|---|
| Superadmin → Vereinsmitglieder | Persönlicher Name als Haupttext; E-Mail darunter | Bestanden |
| Superadmin → Mitglied bearbeiten | Gespeicherter persönlicher Name wird im Namensfeld angezeigt | Bestanden |

Damit ist der gemeldete Folgefehler im Superadmin-Kontext behoben.

**Noch offen:** Vereinsadmin im eigenen Vereinskontext, Profilbildanzeige, Speichern/erneutes Laden einer Profiländerung und negative Kontexttests (kein Kontext bzw. fremder Verein). PROD wurde nicht verändert.


## 10. Fachlich freigegebenes Rollenmodell – Ein-Mannschaft-Regel und Zusatzrollen (04.11.2026)

Das Rollenmodell wurde am 04.11.2026 fachlich freigegeben. Die führende Spezifikation und der technische Vorschlag liegen in `develop` unter `docs/proposals/single-team-membership-guard/README.md`.

Verbindlich gilt:
- Ein Benutzer darf höchstens einer Mannschaft tatsächlich zugeordnet sein.
- Ein bestehendes Mannschaftsmitglied kann nachträglich zusätzlich Superadmin und/oder Vereinsadmin werden.
- Vorhandene Einträge und Rollen in `team_members` und `team_member_roles` bleiben dabei unverändert.
- Superadmins und Vereinsadmins können in den Mannschaftskontexten ihres Berechtigungsbereichs administrieren, ohne dort tatsächliche Mitglieder zu sein.
- Die Ein-Team-Regel beschränkt nur die Zuordnung der Zielperson, nicht den Handlungskontext des aufrufenden Administrators.

**Technischer Status nach DB-DEV-009 (04.11.2026):** Die Datenbankmigration wurde ausschließlich in Supabase DEV erfolgreich ausgeführt: Version `20261104143331`, Name `db_dev_009_single_team_membership_guard`. Die Ein-Mannschaft-Trigger, die angepassten RPCs, ACLs, Index und Datenintegrität wurden read-only geprüft. Der vollständige Ausführungsnachweis steht in `DB_MIGRATION_LOG.md` (DB-MIG-2026-003); technische Beschreibung in `DB_CHANGELOG.md` (DB-DEV-009). Die angepasste Frontend-Quelle liegt in `develop` und im DEV-Spiegel; manueller Browser-/Praxistest offen. Die Quellen für invite-member und den 410-Gone-Ersatz invite-trainer sind in develop versioniert und wurden nach ausdrücklicher Freigabe am 04.11.2026 ausschließlich in Supabase DEV auf Version 4 deployed. Beide sind ACTIVE, verify_jwt=true; die Live-Quelltexte stimmen bytegenau mit develop überein.

**Dokumentationsführung:** `develop` ist führend. Der SQL-Entwurf und die Nachprüfung liegen unter `docs/proposals/single-team-membership-guard/`; die geplante Datenbankänderung ist in `DB_CHANGELOG.md` beschrieben. Tatsächliche SQL-Ausführung und Supabase-Deployments werden erst nach Durchführung in den jeweiligen Protokollen dokumentiert.


## 11. DEV-Spiegelstand für Rollenmodell (04.11.2026)

Die angepasste `index.html` liegt in `develop`. Der aktuelle DEV-Spiegel `bautnhaus/jugendmannschaft-dev`, Branch `main`, enthält denselben Blob-SHA wie `develop/index.html`:

- `develop/index.html`: `ebf7363aa2df1f5b3fc465934e2fab8cea3ef0c1`
- `jugendmannschaft-dev/main/index.html`: `ebf7363aa2df1f5b3fc465934e2fab8cea3ef0c1`

Damit ist die Frontend-Quelle im DEV-Spiegel angekommen. Ein manueller Browser-/Praxistest dieser Rollenänderung ist noch offen. Die SQL-Migration DB-DEV-009 wurde am 04.11.2026 in Supabase DEV erfolgreich ausgeführt (Version `20261104143331`); der Ausführungsnachweis ist in `DB_MIGRATION_LOG.md` dokumentiert. Die Supabase-Edge-Functions sind inzwischen separat auf Version 4 deployed; Details stehen im Nachtrag 12 und im SUPABASE_CHANGELOG.md. PROD und main bleiben unverändert.


## 12. Nachtrag 04.11.2026 – Edge Functions nach Freigabe in DEV deployed

Am 04.11.2026 hat der Nutzer das Deployment beider vorbereiteten Edge Functions ausschließlich in Supabase DEV (Projekt pzazqvvoruqnqhcorbwx) ausdrücklich freigegeben. Es wurden keine SQL-Änderungen ausgeführt und PROD sowie GitHub main blieben unangetastet.

| Funktion | DEV-Version | Status | JWT | Ergebnis |
|---|---:|---|---|---|
| invite-member | 4 | ACTIVE | aktiviert | Superadmin-Zielperson wird nicht mehr pauschal abgewiesen; bestehende Ein-Team-Prüfung bleibt bestehen; DEV-/PROD-Redirect erfolgt anhand der Projektkennung |
| invite-trainer | 4 | ACTIVE | aktiviert | Legacy-Endpunkt; Nicht-OPTIONS-Anfragen erhalten HTTP 410 Gone und den Verweis auf invite-member |

**Live-Nachprüfung:** Beide Edge Functions wurden unmittelbar nach dem Deployment erneut aus Supabase ausgelesen. Beide Live-Quelltexte stimmen bytegenau mit den Dateien in develop überein.

- invite-member: GitHub-Blob-SHA 23234ab65ae1c9ba85067cf8d72d1a290f5a486e; aktiver Deployment-SHA 84dd949d0952615cb59bd2e661d0c722de738bd94751d0989695e5d050f6e0ea.
- invite-trainer: GitHub-Blob-SHA 004499fe27bef85d9896fd1f1c35883dd12ee0bc; aktiver Deployment-SHA 0f2e6e69caa730a80220e4e1f959ade5f1f218d00eb6d0a26f325e7608a323a7.

**Erledigt am 04.11.2026:** Ein bestehendes, bestätigtes Superadmin-Konto wurde durch einen Vereinsadmin als Trainer eingeladen. Die read-only Prüfung bestätigte: globale Superadmin-Rolle weiterhin vorhanden, genau eine Mannschaftszuordnung, Rolle trainer konsistent in `team_members` und `team_member_roles`, Vereinsmitgliedschaft passend zur Mannschaft. Der Auth-Benutzer war bereits bestätigt. **Noch offen:** authentifizierter HTTP-Aufruf des Legacy-Endpunkts sowie weitere Rollen-/Kontext- und Ein-Mannschaft-Negativtests.

**PROD:** unverändert; kein PROD-SQL, kein PROD-Deployment und keine Änderung an GitHub main.


## 13. Nachtrag 04.11.2026 – Vereinsadmin mit zusätzlicher Mannschaftsrolle: Kontextstart korrigiert

**Beobachtung:** Ein Benutzer mit Vereinsadmin-Berechtigung und zusätzlicher Trainer-/Mannschaftsadminrolle wurde beim normalen Login direkt in seine Mannschaft geladen. Erwartet wird zunächst die Vereinsverwaltung mit bewusster Auswahl des Arbeitskontexts.

**Ursache:** In `loadApp()` wurden zuerst die eigenen Zeilen aus `team_member_roles` ausgewertet. Sobald eine Mannschaftsrolle vorhanden war, wurde der normale Mannschaftsstart ausgeführt. Die Prüfung der Vereinsadmin-Berechtigung lag erst im Zweig ohne Mannschaftszuordnung und wurde daher für Benutzer mit beiden Berechtigungen übersprungen.

**Korrektur in `develop/index.html`:**
- Beim normalen Login wird die Vereinsadmin-Berechtigung auch dann geprüft, wenn Mannschaftsrollen vorhanden sind.
- Vereinsadmins starten zunächst in der Vereinsverwaltung und erhalten dort die Mannschaftsauswahl. Ein gespeicherter Mannschaftskontext wird bei diesem normalen Einstieg nicht automatisch wiederhergestellt.
- Beim ausdrücklich geöffneten Mannschaftskontext hat die ausgewählte Mannschaft Vorrang vor einer Mitgliedschaft in einer anderen Mannschaft.
- Ist der Benutzer Mitglied der ausgewählten Mannschaft, werden seine dortigen tatsächlichen Rollen verwendet. Ist er dort kein Mitglied, wird der berechtigte Vereinsadmin-Kontext als Nur-Lese-Kontext geladen.

**Technischer Nachweis:**
- Commit: `81f9ca9cc0294177e89910b0b8ffa158bdc02c44` – `fix: prioritize club context for dual-role members`.
- Datei: `index.html`, GitHub-Blob-SHA `aa682da4c8d528239b06513fafa3b20eacf36d53`.
- DEV-Deployment: [Deploy DEV #397](https://github.com/bautnhaus/jugendmannschaft/actions/runs/41859993637), erfolgreich.
- DEV-Spiegel: `jugendmannschaft-dev/main/index.html` hat denselben Blob-SHA `aa682da4c8d528239b06513fafa3b20eacf36d53`.
- JavaScript-Syntaxprüfung des Modulskripts: bestanden.
- Keine Datenbankmigration, keine Änderung an Mitgliedschafts- oder Rollendaten, keine Änderung an PROD oder GitHub `main`.

**Noch offen – manueller DEV-Praxistest:**
1. Mit einem Konto anmelden, das Vereinsadmin und zusätzlich Trainer oder Mannschaftsadmin einer Mannschaft ist.
2. Erwartung: Start in der Vereinsverwaltung; keine automatische Öffnung der eigenen Mannschaft.
3. Eine Mannschaft auswählen, in der das Konto selbst Mitglied ist. Erwartung: Die tatsächliche eigene Mannschaftsrolle wird verwendet.
4. Eine andere Mannschaft desselben Vereins auswählen, in der das Konto kein Mitglied ist. Erwartung: Der ausgewählte Kontext wird korrekt und nur lesend geladen.
5. Abmelden und erneut anmelden. Erwartung: Der normale Einstieg beginnt wieder in der Vereinsverwaltung und übernimmt nicht ungefragt den vorherigen Mannschaftskontext.

Der Code ist im DEV-Spiegel angekommen; das fachliche Verhalten ist erst nach diesem Browser-Praxistest als bestanden zu markieren.


## 14. Nachtrag 04.11.2026 – Bestehenden Superadmin als Trainer eingeladen: erfolgreich

Der Nutzer bestätigte den erfolgreichen Einladungsvorgang über die DEV-App. Anschließend wurden die relevanten Daten in Supabase DEV ausschließlich lesend geprüft.

**Nachgewiesenes Ergebnis:**
- Das globale Recht `super_admin` ist weiterhin vorhanden.
- Der Auth-Benutzer ist bereits E-Mail-bestätigt.
- Es besteht genau eine Mannschaftszuordnung.
- Die Rolle `trainer` ist konsistent in `team_members` und `team_member_roles` für dieselbe Mannschaft gespeichert.
- Die Vereinsmitgliedschaft passt zur Vereinszuordnung dieser Mannschaft.
- Es wurde keine zusätzliche Mannschaftszuordnung gefunden.

**Teststatus:** Erfolgreich für den konkreten Fall „Vereinsadmin ordnet ein bestehendes, bestätigtes Superadmin-Konto als Trainer in einer Mannschaft zu“. Die weiteren Einladungsrollen und der Negativtest gegen eine zweite Mannschaft bleiben separat offen.

Die Prüfung hat keine Daten verändert. PROD und GitHub `main` blieben unangetastet.


## 15. Nachtrag 04.11.2026 – Versuch einer zweiten Mannschaftszuordnung: UI-Schutz greift

Der Nutzer versuchte, das bereits als Trainer in „DEV Mannschaft“ geführte Superadmin-Konto zusätzlich „G-Junioren“ zuzuordnen.

**Beobachtetes Frontend-Verhalten:**
- Der Einladungsdialog meldet: „Dieses Konto ist bereits Vereinsmitglied. Bitte öffne den vorhandenen Eintrag über ‚Bearbeiten‘.“ Der Frontend-Vorabcheck erkennt die E-Mail in der bereits geladenen Vereinsmitgliederliste und ruft invite-member in diesem Fall nicht auf.
- Im Dialog „Mitglied bearbeiten“ werden die Rollenoptionen der anderen Mannschaft angezeigt, sind aber deaktiviert. Der aktuelle Code setzt `disabled`, sobald das Mitglied bereits genau einer anderen Mannschaft zugeordnet ist.
- Der Hinweistext erklärt den vorgesehenen zweistufigen Mannschaftswechsel: bisherige Rollen entfernen und speichern; danach den Dialog erneut öffnen und der anderen Mannschaft zuordnen.

**Read-only Datenbankkontrolle nach dem Versuch:**
- Globale Rolle super_admin weiterhin vorhanden.
- Trainerrolle weiterhin ausschließlich in „DEV Mannschaft“.
- Entsprechende Zeilen in `team_members` und `team_member_roles` weiterhin konsistent.
- Keine Zuordnung zu „G-Junioren“.
- Mehrfachzuordnungen über die beiden Mannschaftstabellen: 0 Benutzer.

**Testbewertung:** Der Frontend-Schutz gegen eine zweite Mannschaftszuordnung ist im konkreten Fall bestätigt; es wurde keine schreibende Änderung vorgenommen. Der serverseitige Negativpfad (Aufruf von `admin_add_team_role` bzw. des Datenbanktriggers mit einer zweiten Mannschaft) wurde durch diesen UI-Test nicht ausgeführt. Quelltext und Triggerdefinition sind technisch geprüft; ein authentifizierter Laufzeittest des serverseitigen Ablehnungswegs bleibt separat offen.

Der Nutzer soll für diesen Test keine bestehende Mannschaftsrolle entfernen. Ein echter Mannschaftswechsel wäre eine Datenänderung und ist nicht Teil dieses Negativtests.


## 16. Nachtrag 04.11.2026 – Bestehendes Mannschaftsmitglied wird Vereinsadmin; Mitgliederliste aktualisiert sich nach Speichern

**Rollenänderung des Nutzers:** Der bestehende Superadmin wurde über „Bearbeiten“ zusätzlich zum Vereinsadmin gemacht. Der Nutzer bestätigte, dass die Trainerrolle weiterhin angezeigt wurde.

**Read-only Nachprüfung in Supabase DEV:**
- globale Rolle super_admin weiterhin vorhanden;
- Vereinsrolle club_admin vorhanden;
- bisherige Trainerrolle in „DEV Mannschaft“ weiterhin vorhanden;
- genau eine Mannschaftszuordnung;
- keine Änderung der bestehenden Mannschaftszuordnung.

**Zusätzlich gemeldeter UX-Fehler:** Nach Bestätigung des Bearbeitungsdialogs zeigte die sichtbare Seite „Mitglieder und Rollen“ die neue Vereinsrolle nicht sofort an. Ein manuelles Neuladen aktualisierte zwar die Daten, führte aber aus der Unterseite eine Ebene höher.

**Ursache:** Der Bearbeitungsdialog wird in der neuen Vereinsverwaltung aus einer dynamisch erzeugten Liste im Bereich superAdminClubSubView geöffnet. Nach dem Speichern rief saveClubMemberEditor bislang renderClubMembers() auf. Diese Funktion aktualisiert die alte, ausgeblendete Mitgliederliste (clubMemberList), nicht die gerade sichtbare dynamische Liste in superAdminClubSubContent.

**Korrektur in develop/index.html:**
- Neue Funktion refreshClubMemberView() erkennt, ob die aktive Unterseite „Vereinsmitglieder“ geöffnet ist.
- In diesem Fall wird die aktuelle Vereinsmitgliederansicht erneut über openSuperAdminClubSection('members') aus Supabase geladen und an derselben Stelle neu aufgebaut.
- Die aktive Rollenfilter-Auswahl bleibt erhalten.
- In anderen Ansichten wird weiterhin die bisherige Mitgliederlisten-Aktualisierung verwendet.
- Bei einem Aktualisierungsfehler wird ausdrücklich gemeldet, dass die Rollenänderung gespeichert wurde, aber die Liste nicht aktualisiert werden konnte; der Fehler wird nicht als fehlgeschlagene Speicherung ausgegeben.

**Technischer Nachweis:**
- Commit: `70c7226cf02147e348265afb0e8407188fe9e5c4` – `fix: refresh club members view after role edits`.
- Datei: `index.html`, Blob-SHA `55cc89958375a5d4d1bac2ed61e1c3fcae75b23c`.
- DEV-Deployment: [Deploy DEV #407](https://github.com/bautnhaus/jugendmannschaft/actions/runs/41884009756), erfolgreich.
- DEV-Spiegel `jugendmannschaft-dev/main/index.html`: identischer Blob-SHA `55cc89958375a5d4d1bac2ed61e1c3fcae75b23c`.
- JavaScript-Syntaxprüfung: bestanden.
- Keine SQL-Änderung, keine PROD-Änderung, keine Änderung an GitHub `main`.

**Manueller Browser-Nachtest bestanden (04.11.2026):** Nach erneutem Laden der DEV-App wurde der Bearbeitungsdialog in „Mitglieder und Rollen“ geöffnet und ohne weitere Rollenänderung gespeichert. Der Dialog schloss sich, die sichtbare Mitgliederliste wurde sofort aktualisiert und zeigte die bestehenden Rollen direkt an. Die App blieb auf „Mitglieder und Rollen“; ein weiteres Neuladen war nicht erforderlich. Der Test bestätigt den Refresh-/Navigationspfad. Die vorherige tatsächliche Rollenänderung (club_admin zusätzlich zur Trainerrolle) ist separat read-only in Supabase bestätigt.


**Abschluss des manuellen Nachtests (04.11.2026):** Nutzer bestätigt, dass die Mitgliederliste nach Speichern des Bearbeitungsdialogs sofort aktualisiert wird und die Seite „Mitglieder und Rollen“ geöffnet bleibt. Kein manuelles Neuladen nötig. Abschnitt 16 ist damit für DEV abgeschlossen.


## 17. Mannschaftsübersicht – direkte Aktualisierung und Vereinsinformationen auf den Mannschaftskacheln (04.11.2026)

**Ausgangsfehler:** Beim Bearbeiten der Mannschaftsstammdaten wurde im Vereinsadmin-Kontext nach dem Speichern nur die Mannschaftsauswahl aktualisiert. Die sichtbare Mannschaftsübersicht blieb auf dem alten Stand, bis die Seite manuell neu geladen wurde.

**Umsetzung in `develop/index.html`:**
- Nach dem Speichern wird geprüft, welche Mannschaftsansicht gerade aktiv ist.
- Die geöffnete Mannschaftsübersicht wird direkt neu aufgebaut. Bei Bearbeitung aus der Mannschaftsdetailansicht bleibt diese Ansicht geöffnet; Name, Saison und Informationsblock werden dort aktualisiert.
- Die bisherige Mannschaftsauswahl des Vereinsadmins wird weiterhin neu geladen und behält die bearbeitete Mannschaft als Auswahl.
- Die Mannschaftskacheln zeigen jetzt zusätzlich:
  - Spielstätte und Trainingsstätte aus den Vereinsinformationen. Wenn beide gleich sind, erscheint eine gemeinsame Angabe.
  - Anzahl der aktiven Spieler der jeweiligen Mannschaft.
  - Zielkadergröße der Mannschaft.
- Der Informationsblock der Mannschaftsdetailansicht verwendet dieselben konkreten Angaben statt des allgemeinen Hinweises, dass die Standorte aus dem Verein übernommen werden.

**Datenbasis und Sicherheitsgrenzen:**
- Standorte werden lesend aus `clubs` geladen.
- Die aktiven Spielerzahlen werden über die bestehende berechtigungsgeschützte RPC `get_club_players(p_club_id)` ermittelt und nach Mannschaft gruppiert.
- Die Zielkadergröße stammt aus `teams.recommended_squad_size`.
- Es wurde keine Datenbankstruktur geändert und keine SQL-Migration ausgeführt.

**Technischer Nachweis:**
- Commit: `f8563de25be67b127884464f2c77a3eaa97ce677` – `fix: refresh team overview and show club team facts`.
- Datei: `index.html`, Blob-SHA `38e0b7c950ed3c2f424b817359b920a2530799c4`.
- DEV-Deployment: [Deploy DEV #414](https://github.com/bautnhaus/jugendmannschaft/actions/runs/41899212678), erfolgreich.
- DEV-Spiegel `jugendmannschaft-dev/main/index.html`: identischer Blob-SHA `38e0b7c950ed3c2f424b817359b920a2530799c4`.
- JavaScript-Syntaxprüfung des Hauptmoduls nach Herausnahme des einzelnen externen ESM-Imports: bestanden.
- `main` und PROD unverändert.

**Manueller DEV-Praxistest bestanden (04.11.2026):** Der Nutzer hat die DEV-App mit einem Vereinsadmin ohne Mannschaftszuordnung geprüft und bestätigt: „Ja funktioniert“. Damit ist die Korrektur zur direkten Aktualisierung nach dem Speichern sowie die Anzeige der gewünschten Mannschafts- und Vereinsinformationen im tatsächlichen Browser-Praxistest bestätigt. Der Nutzer musste die Seite nicht manuell neu laden. Der Test wurde vom Nutzer durchgeführt; es wurde kein automatisierter Browser-Test behauptet.


## 18. Release-1.6-Abschlussprüfungen – aktueller Status (04.11.2026)

Die Rollen- und Einladungstests wurden anhand der Rückmeldung des Nutzers aktualisiert. Der serverseitige Negativtest zur Ein-Mannschaft-Regel wurde nach ausdrücklicher Freigabe ausschließlich in DEV ausgeführt. Die Ergebnisse dieses Abschnitts ersetzen die zuvor offenen Statusangaben.

| Nr. | Abschlussprüfung | Ergebnis | Status |
|---|---|---|---|
| 1 | Rollenkombinationen: Superadmin → Vereinsmitglied/Vereinsadmin; Vereinsadmin → Vereinsmitglied/Mannschaftsadmin/Trainer; Mannschaftsadmin → Mannschaftsadmin/Trainer | Nutzer bestätigt alle Kombinationen als erfolgreich. Die Zuordnungen und Rollen funktionieren in den geprüften Einladungskontexten. | Bestanden |
| 2 | Bereits vorhandenes, unbestätigtes Auth-Konto | Getestet wurde der Fall einer Zieladresse, die bereits als Vereinsmitglied geführt wird. Die App verhindert eine erneute Einladung und weist auf den vorhandenen Eintrag unter „Bearbeiten“ hin. Der davon getrennte Fall eines unbestätigten Auth-Kontos ohne bestehende Vereinsmitgliedschaft wurde dadurch nicht nachgewiesen. | Teilweise geprüft |
| 3 | Wiederholungseinladung | Beim erneuten Versuch wird derselbe Hinweis auf die bereits bestehende Vereinsmitgliedschaft angezeigt; der Nutzer soll den bestehenden Eintrag bearbeiten. | App-Verhalten bestätigt |
| 4 | Abweichender Verein | In DEV existiert aktuell nur ein Verein. Eine zweite Vereinsanlage ist in der App noch nicht verfügbar; deshalb kann die Abweisung einer vereinsübergreifenden Zuordnung derzeit nicht praktisch getestet werden. | Derzeit nicht testbar |
| 5 | Ein-Mannschaft-Regel serverseitig | Nach ausdrücklicher Freigabe wurden direkte INSERT-Versuche in beide Zuordnungstabellen gegen eine zweite Mannschaft ausgeführt. Beide wurden durch den aktiven Trigger mit SQLSTATE 23514 und der erwarteten Fehlermeldung abgewiesen. Die anschließende read-only Prüfung bestätigte, dass das Testkonto weiterhin ausschließlich der „DEV Mannschaft“ zugeordnet ist. | Bestanden |
| 6 | Legacy-Endpunkt `invite-trainer` | Supabase DEV meldet den Endpoint ACTIVE, Version 4, `verify_jwt=true`. Der zurückgelesene Live-Quelltext liefert für Nicht-OPTIONS-Aufrufe HTTP 410 Gone und verweist auf `invite-member`; OPTIONS liefert 200. Ein authentifizierter HTTP-Aufruf wurde nicht ausgeführt, daher ist die 410-Antwort im Laufzeitaufruf nicht separat protokolliert. | Live-Code/Deployment geprüft; HTTP-Laufzeittest offen |
| 7 | E-Mail-Zustellung über Brevo | Die Brevo-Zustellung, der DEV-Einladungslink und die Passwortvergabe waren bereits im erfolgreichen Trainer-End-to-End-Test bestätigt. | Bestanden für den bisherigen E2E-Test |

### Nachweis S4 – serverseitige Ein-Mannschaft-Sperre (04.11.2026)

**Umgebung:** ausschließlich Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`.

**Testaufbau:** Das vorhandene DEV-Testkonto war in beiden Tabellen jeweils genau der Mannschaft „DEV Mannschaft“ zugeordnet. Als zweite Mannschaft wurde „G-Junioren“ desselben Vereins verwendet.

**Ausgeführte Prüfung:** Innerhalb eines anonymen PL/pgSQL-Testblocks wurde je ein INSERT-Versuch in `public.team_member_roles` und `public.team_members` mit der Zielmannschaft „G-Junioren“ ausgelöst. Die erwartete Trigger-Ausnahme wurde je in einem eigenen Exception-Block abgefangen. Ein unerwartet erfolgreicher INSERT hätte den Test mit einem Fehler abgebrochen. Damit wurden keine Testzuordnungen dauerhaft gespeichert.

**Ergebnis:** Beide Versuche wurden durch `enforce_single_team_membership()` mit SQLSTATE `23514` und der Meldung „Benutzer gehört bereits einer anderen Mannschaft an. Eine zweite Mannschaftszuordnung ist nicht möglich.“ abgewiesen. Die nachfolgende read-only Abfrage zeigte in beiden Tabellen weiterhin genau die bestehende Zuordnung zur „DEV Mannschaft“ und keine Zeile für „G-Junioren“.

**Änderungsumfang:** Keine Schemaänderung, keine Migration, keine Änderung an Rollen oder Mitgliedschaftsdaten. Es handelte sich um einen kontrollierten Negativtest; der SQL-Test und die Nachprüfung sind zusätzlich in `DB_CHANGELOG.md` unter DB-TEST-2026-004 dokumentiert.

### Einordnung der noch nicht vollständig nachgewiesenen Fälle

- **Unbestätigtes Auth-Konto ohne Vereinsmitgliedschaft:** bleibt als eigener Auth-Sonderfall offen. Der getestete Hinweis „Dieses Konto ist bereits Vereinsmitglied“ verhindert den erneuten Einladungsweg bereits vor diesem Sonderpfad.
- **Abweichender Verein:** bleibt mangels zweitem Verein und mangels Vereinsanlage-Funktion nicht testbar. Es wurde hierfür keine künstliche zweite Vereinsstruktur erzeugt.
- **Legacy-Endpunkt:** Live-Version, JWT-Einstellung und Quelltext sind geprüft. Ein authentifizierter HTTP-Laufzeitaufruf ist mangels verfügbarer authentifizierter Testmöglichkeit nicht erfolgt. Die erwartete HTTP-410-Antwort wird daher nicht als Laufzeittest bestanden ausgegeben.

### Aktueller Abschlussstand

Die vier zusätzlichen Rollenkombinationen, die bestehenden Superadmin-Fälle, der Wiederholungsschutz und die serverseitige Ein-Mannschaft-Sperre sind bestätigt. Brevo ist eingerichtet und der Einladungs-E2E-Fluss wurde bereits erfolgreich durchlaufen.

Es bleiben nur:
1. der eigenständige Sonderfall eines unbestätigten Auth-Kontos ohne Vereinsmitgliedschaft,
2. der authentifizierte HTTP-Laufzeittest für `invite-trainer`,
3. der vereinsübergreifende Negativtest, sobald eine zweite Vereinsanlage in DEV verfügbar ist.

**Arbeitsgrenzen:** Keine neue SQL-Migration wurde erstellt. Es gab keine Änderung an Supabase-Auth-/SMTP-Konfigurationen, keine Änderung an PROD und keine Änderung an GitHub `main`.  
