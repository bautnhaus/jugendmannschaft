# Release 1.6 – Mitglieder-/Trainer-Einladung (DEV-Arbeitsstand)

**Stand:** 04.11.2026  
**Status:** DEV-Einladungsablauf im ersten End-to-End-Fall erfolgreich; Profilanzeige in Superadmin-Mitgliederverwaltung noch offen  
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

Neue Funktion: `invite-member`
- Quelldatei: `supabase/functions/invite-member/index.ts`
- DEV-Status: ACTIVE, Version 3
- JWT-Prüfung: aktiviert
- Aufgabe: Anmeldenden und Kontext prüfen, bestehende Auth-Benutzer ermitteln, existierende Vereins-/Mannschaftszuordnungen prüfen, DEV-Redirect aus Projektkennung wählen, Einladungsversand bzw. bestehendes Konto behandeln und danach die transaktionale Datenbankfunktion aufrufen.
- Ein Zielkonto mit globaler Rolle `super_admin` wird vor dem Versand anhand `global_user_roles` abgelehnt.
- Die alte Funktion `invite-trainer` (DEV Version 3) bleibt vorerst aktiv, wird aber vom aktualisierten Frontend nicht mehr aufgerufen. Sie wird erst nach abgeschlossener Testphase separat stillgelegt.

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
- Supabase DEV `invite-member` ist ACTIVE, Version 3, mit JWT-Prüfung aktiviert. Die live ausgelesene Quelltextdatei stimmt bytegenau mit `supabase/functions/invite-member/index.ts` in `develop` überein. GitHub-Datei-SHA: `fa4792d84b58db5e2a5145f71214cf34011c6bc4`; aktiver Supabase-Deployment-SHA: `c1d9ccbd2480dcfc35a46a118fda4187c8fd9311601bd302e2956bcf72093c53`.
- Die DEV Auth-Site-URL und Redirect-Allowlist wurden read-only anhand der vom Nutzer bereitgestellten Screenshots geprüft und enthalten die DEV-App-Adresse.
- Das Invite-User-Template ist das Supabase-Standardtemplate. Custom SMTP wurde nicht aktiviert oder geändert.

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
| Persönlicher Name | Einladung / Dashboard / Mein Bereich | Name wird gespeichert und dort angezeigt; Superadmin-Mitgliederliste/Bearbeitungsdialog noch fehlerhaft | Teilweise |
| Bestehendes bestätigtes Konto | alle Kontexte | Keine zweite Einladung; zulässige Zuordnung wird ergänzt | Offen |
| Offenes/unbestätigtes Auth-Konto | alle Kontexte | Bestehendes Konto übernehmen; keine neue Mail behaupten, wenn Supabase keine bestätigt; ursprünglichen Link prüfen | Offen |
| Abweichender Verein | alle Kontexte | Kontrollierte Ablehnung | Offen |
| Andere Mannschaft vorhanden | Teamrolle | Kontrollierte Ablehnung ohne zweite Mannschaftszuordnung | Offen |
| Wiederholte Einladung | gleicher Empfänger | Keine doppelten Konten/Rollen; Warnung bei Teilfehlern | Offen |
| Nicht autorisierte externe E-Mail | Standard-SMTP | Verständlicher Versandfehler; kein falscher Erfolg | Offen |

### SMTP-Hinweis

Custom SMTP ist nicht aktiviert. Laut aktueller Supabase-Dokumentation sendet der Standardversand nur an vorab autorisierte E-Mail-Adressen der Supabase-Organisation und ist auf 2 E-Mails pro Stunde begrenzt. Ein Test an eine externe Adresse kann daher mit `email_address_not_authorized` scheitern, ohne dass der neue Einladungs-Code oder die Weiterleitung fehlerhaft ist. Siehe [Supabase – Custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp) und [Test Auth Flows](https://supabase.com/docs/guides/auth/testing-auth-flows). Für externe Einladungen wäre später ein eigener SMTP-Anbieter oder ein Send-Email-Auth-Hook nötig; das ist nicht Teil dieser bereits ausgeführten DEV-Änderungen und bedarf einer gesonderten Entscheidung.



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

### Geplanter Fix
Neue read-only RPC `get_club_members_v3(uuid)` mit Profilname und Avatar, abgesichert über `auth.uid()` und `can_manage_club_context(p_club_id)`. Die bestehende RPC v2 und die RLS-Policies bleiben unverändert. Nach SQL-Freigabe werden Superadmin-Mitgliederliste, Vereinsmitgliederliste und Bearbeitungsdialog auf die neue RPC umgestellt.

**SQL-Status:** Vollständiger Entwurf ist in `DB_MIGRATION_LOG.md`, geplant als DB-MIG-2026-002, dokumentiert. Noch nicht ausgeführt; es liegt noch keine neue Migration in der Supabase-Historie vor. PROD bleibt unverändert.
