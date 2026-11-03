# Release 1.6 – Mitglieder-/Trainer-Einladung (DEV-Arbeitsstand)

**Stand:** 03.11.2026  
**Status:** DEV-Implementierung vorhanden; Praxistests noch offen  
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

- GitHub Branch `develop` und DEV-Repository `bautnhaus/jugendmannschaft-dev` Branch `main` stehen nach dem Push auf demselben Commit.
- Der SHA von `index.html` in `develop` stimmt mit dem SHA in `jugendmannschaft-dev/main` überein.
- Der GitHub-Actions-Lauf `deploy-dev` für Commit `f96e9382e2cdc0ecf6ac6e83e0acde5ac074c788` wurde mit `completed / success` abgeschlossen; `jugendmannschaft-dev/main` stand anschließend auf diesem Commit.
- Supabase DEV `invite-member` ist ACTIVE, Version 3; die live ausgelesene Quelltextdatei stimmt bytegenau mit `supabase/functions/invite-member/index.ts` in `develop` überein.
- Die DEV Auth-Site-URL und Redirect-Allowlist wurden read-only anhand der vom Nutzer bereitgestellten Screenshots geprüft und enthalten die DEV-App-Adresse.
- Das Invite-User-Template ist das Supabase-Standardtemplate. Custom SMTP wurde nicht aktiviert oder geändert.

## 4. Grenzen und noch offene Praxistests

**Wichtig:** Bisher wurde keine echte Einladungs-E-Mail versendet und kein neuer Auth-Benutzer für diesen Release-Test angelegt. Die Backend-/Frontend-Implementierung ist statisch, über Deploymentstatus und Datenbankobjekte verifiziert; End-to-End-Verhalten ist noch nicht bestätigt.

Mindestens folgende Tests sind noch auszuführen:

| Test | Kontext/Rolle | Erwartung | Status |
|---|---|---|---|
| Neue E-Mail einladen | Super Admin → Vereinsmitglied | Auth-Einladung, Vereinsmitgliedschaft, persönlicher Name | Offen |
| Neue E-Mail einladen | Super Admin → Vereinsadmin | Vereinsmitgliedschaft + Vereinsadminrolle | Offen |
| Neue E-Mail einladen | Vereinsadmin → Vereinsmitglied | Zuordnung im ausgewählten Verein | Offen |
| Neue E-Mail einladen | Vereinsadmin → Mannschaftsadmin | Vereinsmitgliedschaft + Mannschaftsadminrolle | Offen |
| Neue E-Mail einladen | Vereinsadmin → Trainer | Vereinsmitgliedschaft + Trainerrolle | Offen |
| Neue E-Mail einladen | Mannschaftsadmin → Mannschaftsadmin | Automatische Vereinsmitgliedschaft + Mannschaftsadminrolle | Offen |
| Neue E-Mail einladen | Mannschaftsadmin → Trainer | Automatische Vereinsmitgliedschaft + Trainerrolle | Offen |
| Einladungslink | DEV | Öffnet DEV und zeigt Passwort-Erstellung | Offen |
| Passwort setzen und Login | neue Einladung | Passwort wird gespeichert; nachgelagerter Kontextfehler wird nicht als Passwortfehler ausgegeben | Offen |
| Persönlicher Name | alle Rollen | `profiles.display_name` wird an allen Stellen verwendet | Offen |
| Bestehendes bestätigtes Konto | alle Kontexte | Keine zweite Einladung; zulässige Zuordnung wird ergänzt | Offen |
| Offenes/unbestätigtes Auth-Konto | alle Kontexte | Wiederholungs-/Resend-Verhalten prüfen; keine falsche Erfolgsmeldung | Offen |
| Abweichender Verein | alle Kontexte | Kontrollierte Ablehnung | Offen |
| Andere Mannschaft vorhanden | Teamrolle | Kontrollierte Ablehnung ohne zweite Mannschaftszuordnung | Offen |
| Wiederholte Einladung | gleicher Empfänger | Keine doppelten Konten/Rollen; Warnung bei Teilfehlern | Offen |
| Nicht autorisierte externe E-Mail | Standard-SMTP | Verständlicher Versandfehler; kein falscher Erfolg | Offen |

### SMTP-Hinweis

Custom SMTP ist nicht aktiviert. Supabase dokumentiert, dass der Standard-SMTP-Versand auf Mitglieder der Supabase-Organisation beschränkt ist. Ein Test an eine externe E-Mail-Adresse kann daher mit `email_address_not_authorized` scheitern, ohne dass die neue App-Weiterleitung falsch ist. Für echte externe Einladungen wäre später ein eigener SMTP-Anbieter nötig; das ist nicht Teil dieser bereits ausgeführten DEV-Änderungen und bedarf einer gesonderten Entscheidung.

### Wiederherstellung / Rollback

- Die neue Datenbankfunktion kann nach Prüfung aller Abhängigkeiten mit `DROP FUNCTION IF EXISTS public.admin_complete_member_invitation(uuid,text,uuid,text,uuid);` entfernt werden.
- Die neue Edge Function kann deaktiviert/entfernt werden, sobald keine Frontend-Version sie mehr aufruft.
- Das Frontend kann durch Rücknahme der DEV-Commits wieder auf den vorherigen Stand gesetzt werden.
- Keine bestehenden Auth-Benutzer oder Mitgliedschaftsdaten wurden durch diese Implementierung geändert.

## 5. Nächster Schritt

Mit dem Nutzer die DEV-Praxistests durchführen. Vor jedem echten E-Mail-Test Empfänger, Rolle und Verein/Mannschaft eindeutig bestimmen. Keine Testeinladung an reale externe Adressen ohne geeigneten Versandweg. PROD bleibt bis zu einer späteren separaten ausdrücklichen Freigabe unangetastet.
