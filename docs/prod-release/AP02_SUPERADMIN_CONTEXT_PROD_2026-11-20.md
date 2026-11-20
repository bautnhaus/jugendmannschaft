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
- FK: `club_member_roles.user_id -> club_members.user_id ON DELETE CASCADE`; genau ein FK verweist auf `club_members`.
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
