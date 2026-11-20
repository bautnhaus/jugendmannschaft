# AP02 – Superadmin-Kontextkorrektur PROD

**Stand:** 20.11.2026  
**Umgebung:** Supabase PROD – `qdugtpzgefpswnnqbusd`  
**Status:** PROD-Paket vorbereitet; ausschließlich Read-only-Liveprüfung und statische Paketprüfung. Nicht ausgeführt.  
**DEV-Referenz:** Migration `20261120212557_ap02_superadmin_context_hardening_dev` erfolgreich angewendet; DEV-Praxistest positiv rückgemeldet.

## 1. Fachliches Ziel

- Superadmins bleiben neutral und erhalten Vereins- bzw. Mannschaftsrechte ausschließlich im ausdrücklich ausgewählten Kontext.
- Eine ausgewählte Vereinskontext darf keine Mannschaftsverwaltung ohne ausgewählten Mannschaftskontext ermöglichen.
- Die vorhandene zusätzliche Superadmin-Teamrolle bleibt unverändert erhalten.
- Die direkte Vereinsmitgliedschaft und die daran gekoppelten Vereinsrollen werden reversibel gesichert und neutralisiert.
- Reguläre Vereinsadmins behalten ihre bisherigen Vereinsadmin-Berechtigungen.

## 2. PROD-Livebestand (read-only, 20.11.2026)

- Supabase-Projekt ist aktiv, PostgreSQL 17.6.
- Eine globale Superadmin-Rolle.
- Eine direkte Vereinsmitgliedschaft des Superadmins und eine `club_admin`-Rolle.
- Eine zusätzliche Teamrolle `admin` und eine Teammitgliedschaft `admin`.
- Ein ausgewählter Vereinskontext und ein ausgewählter Mannschaftskontext.
- `get_super_admin_clubs()` ist bereits vorhanden (DB-MIG-2026-026 / Migration `20261115151239`).
- `public.is_team_admin(uuid)` ist bereits korrekt CASE-/Teamkontext-gebunden (MD5 `f983aaebc7db5fcbb9284ffacc280b2c`). Diese Funktion wird vom AP02-PROD-Paket ausdrücklich nicht verändert.
- `public.can_manage_club_context(uuid)` enthält noch die alte parallele OR-Alternative über die direkte Vereinsmitgliedschaft und Vereinsadmin-Rolle (MD5 `2b114e55a680a0337225bbfbef8f9f7c`).
- Sieben betroffene Verwaltungs-/Lese-RPCs enthalten noch alte Berechtigungsabfragen bzw. einen direkten Superadmin-Bypass.
- FK: `club_member_roles.user_id -> club_members.user_id ON DELETE CASCADE`; genau ein FK verweist auf `club_members`. Der Check-Constraint begrenzt Vereinsrollen auf `club_admin`; beide Rollback-relevanten Constraints sind im Preflight abgesichert.
- Keine benutzerdefinierten Trigger auf `club_members` oder `club_member_roles`.
- Backup-Schema `ap02_release_private` existiert noch nicht.
- AP02 ist nicht in der PROD-Migrationshistorie registriert.

## 3. PROD-spezifische Abweichung zu DEV

Die Superadmin-Teamrolle ist in DEV `trainer`, in PROD dagegen `admin`. Das PROD-Paket verlangt daher im Preflight den geprüften PROD-Ausgangsbestand und sichert die tatsächlichen Teamrollen/Mannschaftsmitgliedschaften im Snapshot. Es löscht oder ändert keine Teamrolle.

Zusätzlich ist `is_team_admin(uuid)` in PROD bereits durch frühere PROD-Arbeiten korrekt gehärtet. Anders als die DEV-Migration wird diese Funktion im PROD-Paket nicht erneut ersetzt. Das verhindert eine unnötige Wiederholung bzw. Überschreibung bereits vorhandener Härtung.

## 4. Geplanter Änderungsumfang

1. `can_manage_club_context(uuid)`: Superadmin-Zweig erhält CASE-Priorität und erlaubt Vereinsverwaltung nur im ausgewählten Vereinskontext; reguläre Vereinsadmins bleiben über `club_admin` berechtigt.
2. Neun gezielte Ersetzungen in sieben RPC-Definitionen:
   - `admin_add_team_role`
   - `admin_remove_team_role`
   - `admin_update_member_profile`
   - `admin_set_trainer_label`
   - `get_team_trainers`
   - `get_team_trainers_v2`
   - `get_team_role_change_log`
3. Vereinskontext-Fallback in `admin_add_team_role` und `admin_remove_team_role` bleibt für Nicht-Superadmins erhalten, ist für Superadmins aber ausgeschlossen.
4. Rollenhistorie wird für Superadmins an den ausgewählten Mannschaftskontext gebunden. Reguläre Team-/Vereinsadmin-Pfade bleiben erhalten.
5. Vor dem Entfernen der direkten Vereinsmitgliedschaft wird ein privater Snapshot von Vereinsrolle, Teamrollen und Mannschaftsmitgliedschaften erstellt.
6. Nur `club_members` wird für den Superadmin gelöscht; `club_member_roles` wird ausschließlich über den bestätigten CASCADE-FK entfernt. `team_members` und `team_member_roles` bleiben unverändert.

## 5. PROD-Dateien auf develop

- Migration: `supabase/migrations/20261120225600_ap02_superadmin_context_hardening_prod.sql`
- Rollback: `supabase/rollback/20261120225600_ap02_superadmin_context_hardening_rollback_prod.sql`
- Dieses Release-Dokument: `docs/prod-release/AP02_SUPERADMIN_CONTEXT_PROD_2026-11-20.md`

Die Migration enthält PROD-spezifische MD5-Preflight-Gates für die zentralen Kontextfunktionen und alle sieben betroffenen RPCs. Alle neun dynamischen Text-Ersetzungen müssen exakt einmal vorhanden sein. Jede Abweichung führt zum Abbruch vor der Datenänderung.

Der Rollback prüft zusätzlich, dass Teamrollen und Mannschaftsmitgliedschaften seit der Migration nicht verändert wurden. Bei zwischenzeitlichen Änderungen bricht er ab, statt neuere Teamdaten zu überschreiben. Die bereits vor AP02 gehärtete `is_team_admin(uuid)` bleibt auch beim Rollback unverändert.

## 6. Statische Prüfung

- Alle neun alten Ersetzungsausdrücke wurden gegen die aktuellen PROD-Live-Funktionsdefinitionen geprüft; jeder Ausdruck kommt exakt einmal vor.
- Die PROD-MD5-Ausgangswerte im Migrations-Preflight stimmen mit dem Livebestand überein.
- Die PROD-Rollen-/Mitgliedschaftsdaten entsprechen den Preflight-Annahmen.
- FK-/CASCADE-Struktur und Triggerbestand entsprechen den geprüften Voraussetzungen.
- Migration und Rollback wurden auf GitHub erneut eingelesen und auf PROD-spezifische Kennzeichnung, neun Ersetzungen, Teamrollen-Schutz und Backup-/Rollback-Guards geprüft.
- Die Migration ist vollständig mit `BEGIN`/`COMMIT` geklammert; auch das Rollback ist transaktional. Der Preflight prüft zusätzlich den konkreten `club_admin`-Check-Constraint.
- Der PROD-Liveabgleich der Tabellen-Constraints bestätigt `club_members(user_id)` als Primärschlüssel und `club_member_roles(user_id, role)` als Primärschlüssel; der Rollback-Upsert adressiert damit einen vorhandenen eindeutigen Schlüssel.

**Nicht durchgeführt:** keine PL/pgSQL-Ausführungssimulation in PROD, keine Transaktionssimulation in PROD, keine Migration, kein Rollback, keine Datenänderung und kein Frontend-Deploy. Die statische Prüfung ersetzt keinen kontrollierten DEV-Test; DEV ist bereits erfolgreich migriert und praktisch getestet. Eine PROD-Ausführung bleibt bis zur separaten ausdrücklichen Freigabe gesperrt.

## 7. Release-Abnahme vor PROD

1. Finaler unabhängiger Review der beiden PROD-SQL-Dateien.
2. Prüfung, dass die DEV-Referenz und PROD-Livebasis unverändert sind (Hashes/Preflight).
3. Freigabe des PROD-Migrationsfensters.
4. Migration ausschließlich auf PROD anwenden.
5. Read-only Postflight: direkte Vereinsmitgliedschaft/Rolle entfernt, Backup genau ein Datensatz, Teamrolle `admin` und Teammitgliedschaft unverändert, Kontext-RPCs korrekt, Backup für Clientrollen nicht erreichbar.
6. Frontend-Praxistest: Vereinsauswahl, Vereinsverwaltung, Mannschaftsauswahl, Mannschaftsverwaltung, Kontextwechsel und Rollenhistorie.
7. Release-Log und Migrationskatalog aktualisieren.

**Freigaberegel:** Dieses Dokument und die SQL-Dateien sind Vorbereitung. Sie stellen ausdrücklich keine PROD-Ausführungsfreigabe dar.


## 8. Abschließender unabhängiger Review – 20.11.2026

### Geprüfte technische Eigenschaften

- Migration und Rollback sind jeweils vollständig mit `BEGIN` / `COMMIT` geklammert.
- Die Migration enthält neun PROD-Ausgangs-Hash-Gates (eine zusätzliche Wiederholung des `is_team_admin(uuid)`-Hashes ist der separate Postflight-Schutz und beabsichtigt).
- Die neun dynamischen Ersetzungen in sieben RPCs wurden zuvor einzeln gegen die PROD-Live-Definitionen geprüft; jeder alte Ausdruck kam exakt einmal vor.
- Der einzige DELETE-Befehl der Migration betrifft `public.club_members`. Es gibt keine DELETE- oder UPDATE-Anweisung gegen `team_members` oder `team_member_roles`.
- PROD-Primärschlüssel: `club_members(user_id)`, `club_member_roles(user_id, role)`. Der Rollback-Konfliktschlüssel `(user_id, role)` ist damit eindeutig abgesichert.
- Der Vereinsrollen-Check-Constraint begrenzt `club_member_roles.role` auf `club_admin`; dieser Constraint ist jetzt ebenfalls Teil des Migrations-Preflights.
- FK `club_member_roles.user_id -> club_members.user_id ON DELETE CASCADE` wurde bestätigt.
- Die vorhandenen SECURITY DEFINER-Eigentümer und EXECUTE-Rechte der betroffenen PROD-Funktionen wurden read-only geprüft. `CREATE OR REPLACE` bzw. das Ersetzen der Funktionsdefinitionen erhält die bestehenden Funktions-ACLs und Eigentümer.
- Das Backup-Schema und die Backup-Tabelle entziehen `PUBLIC`, `anon`, `authenticated` und `service_role` alle Rechte; RLS ist zusätzlich aktiviert und es werden keine Policies angelegt.
- PROD-Migrationshistorie zuletzt: `20261118105730`. Die vorgesehene AP02-Version `20261120225600` liegt chronologisch danach und ist noch nicht registriert.

### Rollback-Review

- Wiederherstellung der Vereinsmitgliedschaft erfolgt vor dem Einspielen der gesicherten `club_admin`-Rolle.
- `ON CONFLICT (user_id, role)` ist durch den bestätigten Primärschlüssel gedeckt.
- Das Rollback bricht ab, wenn der Superadmin inzwischen keine globale Superadmin-Rolle mehr besitzt, wenn eine neue Vereinsmitgliedschaft angelegt wurde oder wenn Teamrollen/Mannschaftsmitgliedschaften seit der Migration verändert wurden.
- Die vor AP02 gehärtete `is_team_admin(uuid)`-Funktion wird weder in Migration noch Rollback ersetzt.
- Das Backup-Schema wird erst nach erfolgreicher Wiederherstellung entfernt.

### Verbleibende Grenze der Prüfung

Der Review war statisch und read-only. Es wurde keine PL/pgSQL-Ausführungssimulation auf PROD durchgeführt. Eine solche Simulation wäre eine Datenbankausführung und ist durch die bisherige Freigabe nicht gedeckt. Der tatsächliche Lauf wird durch die Preflight-Gates innerhalb der Transaktion geschützt; ein Fehler führt zum Abbruch und Rollback.

**Review-Ergebnis:** Kein weiterer statischer Blocker festgestellt. Das Paket ist für die finale Freigabevorlage vorbereitet, aber noch nicht ausgeführt. Die separate ausdrückliche PROD-Ausführungsfreigabe bleibt erforderlich.
