# AP04 PROD Paket 12 – Profilpflege und Mitglieder-/Rollenverwaltung

- **Status:** Technisch vorbereitet; manuelle DEV-Abnahme der Rollen-/Mitgliederfälle vor PROD noch zu bestätigen.
- **Vorgesehene Katalognummer:** DB-MIG-2026-023.
- **Ziel:** Supabase PROD, Projekt `qdugtpzgefpswnnqbusd`.
- **Quelle:** Live-Funktionsdefinitionen DEV und PROD, read-only am 15.11.2026.
- **PROD-Ausführung:** Noch nicht erfolgt; keine PROD-Änderung im Rahmen dieser Vorbereitung.

## 1. Einordnung des nächsten Pakets

Die E05-Migrationspakete 1–11 sind in der aktuellen PROD-Migrationshistorie vorhanden. Das nächste sinnvolle Datenbankpaket ist AP04 (gemeinsame Profile und geschützte Mitglieder-/Rollenverwaltung), nicht ein weiteres E05-Paket.

## 2. Live-Abgleich DEV ↔ PROD

Read-only geprüft:

| Objektgruppe | DEV | PROD | Ergebnis |
|---|---:|---:|---|
| Public-Spalten | 288 | 288 | identisch |
| Public-Tabellen mit RLS | 38 | 38 | RLS überall aktiv |
| Public-Trigger | 27 | 27 | Definitionen identisch |
| Storage-Buckets | 2 | 2 | Konfiguration identisch |
| Storage-Policies | 7 | 7 | Definitionen identisch |

Die Unterschiede der allgemeinen Public-RLS-Policies und anderer Funktionen sind nicht Teil dieses AP04-Pakets und werden nicht pauschal überschrieben.

## 3. Enthaltene sechs Funktionsangleichungen

Die sechs Funktionen sind in beiden Umgebungen vorhanden, unterscheiden sich aber in ihrer Live-Definition. Paket 12 ersetzt ausschließlich die PROD-Definitionen durch die aktuelle DEV-Definition:

| Funktion | DEV MD5 | PROD MD5 |
|---|---|---|
| `admin_update_member_profile(uuid,uuid,text,text)` | `3a9eb766e1cbc357b16a25677b725577` | `5a240ebe05fcf7ea01048dc429b6bad6` |
| `admin_update_club_member_profile(uuid,uuid,text,text)` | `6319ff70fc9bcbb00b43c7ec9a5d8570` | `8ebed408aa5700582f034b384527efca` |
| `admin_add_team_role(uuid,uuid,text)` | `72289671afb1f722ed67befa08f9985c` | `e2790dc60b75a6d64c475c480ce26c6c` |
| `admin_remove_team_role(uuid,uuid,text)` | `1e7ba2af3c1cf4c35087943aca95c953` | `558ccda9a6ddc38c9c7625caf4fd84d6` |
| `admin_add_club_member_by_email(uuid,text,text)` | `5fd83e820b2edf50a5da0072c1ff3001` | `c71d52c28787644f7d514dfb71c21d87` |
| `admin_set_club_member_role(uuid,uuid,text)` | `36a81d72b40bdd76d72aa671b08cc121` | `c5bca125f54511e9126f582bc05b873c` |

### Fachliche Wirkung

- Profilname und Profilbild können im passenden Mannschafts- oder Vereinskontext durch berechtigte Admins gepflegt werden.
- Vereinsadmins können Teamrollen nur für Mannschaften ihres ausgewählten Vereins verwalten.
- Superadmins benötigen den ausdrücklich ausgewählten passenden Vereins-/Mannschaftskontext.
- Selbständerungen eigener Team-/Vereinsrollen bleiben gesperrt.
- Ein-Verein-pro-Benutzer-Regel und Schutz des letzten Vereins-/Mannschaftsadmins bleiben bestehen.
- Ungültige Rollen und fremde Vereins-/Mannschaftszuordnungen werden abgewiesen.

## 4. Bewusst nicht enthalten

- Keine Tabellen, Spalten, Constraints oder Datenänderungen.
- Keine RLS-Policy-, Trigger- oder Storage-Policy-Änderungen.
- Keine Bucket-Konfigurationsänderungen: `profile-avatars` und `club-assets` stimmen bereits mit DEV überein.
- Keine Auth-E-Mail-/Passwortänderung und keine Edge-Function-Änderung.
- Keine allgemeinen AP02/AP03-Rollen-/Policy-Abweichungen.
- Keine Frontend-Datei, GitHub `main` oder PROD-Frontend-Deployment.

### Geschützte Funktionsabhängigkeiten

Die sechs aktualisierten Funktionen verwenden bestehende Rollen-/Kontext-Helfer. Diese werden durch Paket 12 **nicht** verändert. Der Preflight und Postflight prüfen ihre PROD-Definitionen zusätzlich gegen den vorab ausgelesenen Stand: `admin_add_club_member`, `can_manage_club_context`, `has_selected_team_context`, `is_club_admin`, `is_super_admin` und `is_team_admin`. Bei einer Abweichung bricht die Migration fail-closed ab.

**Wichtige Sicherheitsabweichung, bewusst nicht übernommen:** `is_club_admin(uuid)` unterscheidet sich fachlich. Die aktuelle PROD-Version begrenzt Superadmins auf den ausdrücklich ausgewählten Vereinskontext. Die aktuelle DEV-Version liefert für Superadmins bereits ohne diesen Kontext `true`. Das widerspricht der verbindlichen Projektregel „Superadmin neutral; Zugriff nur im ausdrücklich ausgewählten Vereins-/Teamkontext“. Paket 12 bewahrt daher die restriktivere PROD-Version und aktualisiert diese Hilfsfunktion nicht. Auch `admin_add_club_member(uuid,uuid,text)` wird nicht ersetzt. Der in Paket 12 aktualisierte Pfad `admin_add_club_member_by_email` prüft vor dem Aufruf zusätzlich `can_manage_club_context(p_club_id)`. Die direkte DEV-RPC `admin_add_club_member` ist als separates DEV-Sicherheitsthema zu korrigieren bzw. zu testen, nicht stillschweigend nach PROD zu übertragen.

## 5. Sicherheits- und Ausführungsdesign

- Alle sechs Funktionen sind in DEV und PROD `SECURITY DEFINER`, Owner `postgres`, mit festem `search_path = pg_catalog, public, auth`.
- EXECUTE-ACLs sind in DEV und PROD bereits gleich: `authenticated` und `service_role` dürfen ausführen; `anon` und `PUBLIC` nicht.
- Die Migration verändert keine Grants. `CREATE OR REPLACE FUNCTION` erhält Owner und bestehende ACLs.
- Der Preflight verlangt exakt die sechs dokumentierten PROD-MD5-Werte und bricht bei jeder Abweichung vor einer Änderung ab.
- Der Postflight prüft die sechs DEV-MD5-Werte, SECURITY DEFINER, Owner, search_path und EXECUTE-ACLs.
- Die Migration ist transaktional. Rollback stellt die sechs exakt gesicherten PROD-Definitionen wieder her und ist separat freigabepflichtig.

## 6. Dateien

- Migration: `supabase/migrations/20261115110000_ap04_prod_paket_12_member_profile_and_role_management.sql`
- Rollback: `supabase/rollback/20261115110000_ap04_prod_paket_12_member_profile_and_role_management_rollback.sql`
- CI-Baseline: `docs/prod-release/test-package-12/bootstrap.sql`
- CI-Assertions: `docs/prod-release/test-package-12/assertions.sql`
- Rollback-Assertions: `docs/prod-release/test-package-12/rollback_assertions.sql`
- CI-Workflow: `.github/workflows/ap04-prod-package-12-ci.yml`

## 7. DEV-Praxistests vor PROD-Freigabe

Die vorhandene AP04-Dokumentation weist Profilname/-bild einzeln und gemeinsam sowie Passwortänderung als erfolgreich getestet aus. Folgende Fälle sind dort noch offen bzw. vor PROD erneut zu bestätigen:

1. Vereinsadmin: Profil eines Mitglieds im eigenen Verein ändern; fremder Verein wird abgewiesen.
2. Mannschaftsadmin: Profil eines Mitglieds der eigenen Mannschaft ändern; fremde Mannschaft wird abgewiesen.
3. Superadmin: Profil-/Rollenänderung nur im ausdrücklich gewählten Vereins-/Mannschaftskontext.
4. Eigene Rollenänderung durch den betroffenen Benutzer wird abgewiesen.
5. Letzter Mannschaftsadmin und letzter Vereinsadmin können nicht entfernt/herabgestuft werden.
6. Ein Benutzer kann nicht einem zweiten Verein zugeordnet werden.
7. Trainer ohne Adminrecht kann keine Mitgliederprofile oder Rollen anderer Mitglieder ändern.
8. Avatar-Dateipfade mit ungültiger UUID sowie falsche Dateitypen/Größen werden sicher behandelt.
9. E-Mail-Änderung/Bestätigung ist nicht Teil dieser DB-Migration; die bestehende Auth-Funktion separat testen, sobald eine geeignete Testadresse verfügbar ist.

**Hinweis:** Die isolierte PostgreSQL-CI prüft die reproduzierbare Migration, Hashes, Sicherheitsattribute, ACLs und Rollback. Sie ersetzt keine authentifizierten Supabase-Rollentests.


## 9. Isolierte PostgreSQL-CI – erfolgreich

- **Workflow:** `.github/workflows/ap04-prod-package-12-ci.yml`
- **Ergebnis:** [GitHub Actions Run 43697270748](https://github.com/bautnhaus/jugendmannschaft/actions/runs/43697270748) – **success**, PostgreSQL 17.6.
- Erfolgreich: exakte PROD-Ausgangsdefinitionen bereitgestellt, Paket-12-Migration angewendet, alle sechs DEV-Funktionshashes sowie SECURITY DEFINER/Owner/search_path/ACL geprüft, guarded Rollback ausgeführt und ursprüngliche PROD-Funktionsdefinitionen samt ACL erneut bestätigt.
- **Testgrenze:** Isolierter PostgreSQL-Test; keine authentifizierten Supabase-Rollensitzungen, keine echten Vereins-/Mitgliederdaten und keine Änderung an DEV oder PROD.

## 10. Freigabestatus

- Paketdateien werden auf `develop` abgelegt.
- PROD wurde ausschließlich read-only geprüft.
- **Noch keine PROD-Freigabe erteilt und keine PROD-Migration ausgeführt.**
- Vor der abschließenden Freigabe ist die DEV-Praxistestmatrix oben zu bestätigen.
