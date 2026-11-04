# DEV-Korrekturpaket: Ein-Mannschaft-Regel und alte Einladungsschnittstelle

**Status:** vorbereitet auf Feature-Branch; noch nicht in develop, nicht deployed und nicht in Supabase ausgeführt.  
**Stand:** 04.11.2026  
**Zielumgebung:** ausschließlich Supabase DEV (pzazqvvoruqnqhcorbwx)  
**PROD:** ausdrücklich unverändert.

## Anlass

Die read-only Prüfung vom 04.11.2026 zeigte, dass die aktuelle Einladung über invite-member und admin_complete_member_invitation eine zweite Mannschaftszuordnung verhindert. Andere Schreibwege hatten diese Prüfung nicht durchgängig:

- admin_add_team_role prüfte die bestehende Mannschaftszuordnung des Zielbenutzers nicht.
- admin_create_team schloss Superadmins aus, prüfte aber nicht, ob der ausgewählte Mannschaftsadmin bereits einer Mannschaft angehört.
- admin_list_team_admin_candidates zeigte Vereinsmitglieder auch dann an, wenn sie bereits einer Mannschaft zugeordnet waren.
- Der Vereinsmitglied-Bearbeitungsdialog zeigte Rollenfelder für alle Mannschaften.
- Die alte Edge Function invite-trainer war in Supabase DEV weiterhin ACTIVE (Version 3), obwohl das aktuelle Frontend sie nicht mehr aufruft.

Die aktuelle DEV-Datenbank weist bei der Bestandsprüfung keine Benutzer mit mehreren Mannschaftszuordnungen und keine Superadmins mit Mannschaftszuordnung auf. Die Korrektur muss daher keine bestehenden Mitgliedschaftsdaten bereinigen.

## Umfang des Pakets

### A. Datenbank – migration.sql

Die vorgeschlagene Migration:

1. bricht vor Änderungen ab, falls bereits Mehrfachzuordnungen oder Mannschaftszuordnungen von Superadmins gefunden werden;
2. ergänzt einen Index auf team_member_roles(user_id);
3. setzt eine zentrale SECURITY-DEFINER-Triggerfunktion mit festem search_path auf beide Zuordnungstabellen;
4. sperrt bei jeder neuen/verschobenen Zuordnung die betroffene Auth-Benutzerzeile mit FOR UPDATE, damit konkurrierende Schreibwege desselben Benutzers serialisiert werden;
5. weist Superadmins und bereits anderweitig zugeordnete Benutzer ab;
6. ergänzt klare Vorabprüfungen in admin_add_team_role und admin_create_team;
7. filtert bereits zugeordnete Personen aus admin_list_team_admin_candidates.

admin_complete_member_invitation enthält bereits eine Sperre der Auth-Benutzerzeile und eine Prüfung auf eine andere Mannschaft. Die neuen Trigger schützen diesen Weg zusätzlich und sichern auch ältere bzw. direkte Schreibwege ab.

add_team_member_by_email hat nach Live-Prüfung kein EXECUTE-Recht für authenticated und wird vom aktuellen Frontend nicht aufgerufen. Die zentralen Trigger schützen die Tabellen dennoch, falls ein privilegierter interner/administrativer Aufrufer diese alte Funktion verwendet.

### B. Frontend – index.html

- Bei einem Mitglied mit bestehender Mannschaftszuordnung bleiben die Rollenfelder anderer Mannschaften gesperrt.
- Ein Mitglied ohne Mannschaft kann über den Vereinsdialog höchstens einer Mannschaft zugeordnet werden.
- Vor dem Speichern wird geprüft, dass nicht mehrere Mannschaften ausgewählt wurden.
- Ein Mannschaftswechsel erfolgt bewusst in zwei Schritten: zunächst alle Rollen der bisherigen Mannschaft entfernen und speichern, dann den Dialog erneut öffnen und eine neue Mannschaft wählen.
- Bereits widersprüchliche Mehrfachzuordnungen werden nicht stillschweigend verändert; die Oberfläche zeigt einen Hinweis und blockiert die Rollenbearbeitung.
- Der unerreichbare Altaufruf admin_add_club_member_by_email wurde aus saveClubMemberEditor entfernt. Neue Konten werden weiter ausschließlich über „Mitglied einladen“ angelegt.

### C. Alte Edge Function – invite-trainer

Ein Lösch-/Deaktivierungswerkzeug für Edge Functions steht im verbundenen Supabase-Werkzeugbestand nicht zur Verfügung. Der vorbereitete sichere Stilllegungsweg ist daher ein Ersatz der alten Funktion durch einen kleinen HTTP-Endpunkt, der außer OPTIONS jede Anfrage mit **410 Gone** und dem Hinweis auf invite-member beantwortet.

Technisch bleibt die Edge Function im Dashboard als ACTIVE sichtbar; die alte Funktionalität ist nach Deploy aber nicht mehr nutzbar. Die JWT-Prüfung bleibt aktiviert. Die neuere Funktion invite-member bleibt unverändert aktiv.

## Dateien

- migration.sql – vollständiger SQL-Vorschlag, nicht ausgeführt.
- after_apply_verification.sql – rein lesende Prüfungen für einen später freigegebenen DEV-Lauf.
- supabase/functions/invite-trainer/index.ts – vorbereiteter 410-Gone-Ersatz für den alten Endpunkt.
- index.html – Frontend-Anpassung im Feature-Branch.
- DB_MIGRATION_LOG.md, DB_CHANGELOG.md, PROJECT_CONTEXT.md, docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md und docs/AP04-profile-management.md – nachgeführte Vorschlags-/Befunddokumentation.

## Reihenfolge nach ausdrücklicher Freigabe

1. Migration in DEV anwenden.
2. Definitionen, Trigger, ACLs, Index und Bestandsintegrität mit after_apply_verification.sql read-only prüfen.
3. Neue index.html nach develop übernehmen und DEV deployen.
4. invite-trainer durch den 410-Gone-Ersatz ersetzen.
5. Supabase Security Advisor erneut prüfen.
6. DEV-Praxistests durchführen: ein vorhandenes Mitglied; ein bisher nicht zugeordnetes Vereinsmitglied; Neuanlage einer Mannschaft mit zulässigem/ungeeignetem Mannschaftsadmin; Versuch einer zweiten Mannschaftszuordnung über den Mannschaftsbereich; alter Endpunkt liefert 410; Einladung über invite-member funktioniert weiterhin.
7. Tatsächliche Migration-ID, Deploy-Commit, Edge-Version und alle Prüfergebnisse in den laufenden Dokumenten nachtragen.

**Wichtig:** Die Reihenfolge für Frontend und Datenbank ist bewusst so zu koordinieren, dass die UI erst nach aktiver DB-Absicherung freigegeben wird. Kein PROD-Schritt ist Teil dieses Pakets.


### Ergänzung: Superadmin-Neutralität in beide Richtungen

Zusätzlich zur Sperre bei Mannschaftszuordnungen eines bestehenden Superadmins enthält die Migration einen Trigger auf `global_user_roles`. Er verhindert, dass ein bereits einer Mannschaft zugeordnetes Konto nachträglich die Rolle `super_admin` erhält. Auch diese Triggerfunktion sperrt die Auth-Benutzerzeile mit `FOR UPDATE` und besitzt keine EXECUTE-Freigabe für `PUBLIC`, `anon` oder `authenticated`.

Die Live-Prüfung ergab, dass `global_user_roles` derzeit keine INSERT-/UPDATE-/DELETE-Rechte für `authenticated` besitzt und keine öffentliche RPC zum Schreiben dieser Tabelle existiert. Der zusätzliche Trigger sichert trotzdem künftige privilegierte Änderungen ab.
