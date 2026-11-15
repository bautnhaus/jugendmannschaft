# DB-MIG-2026-026 – Sichere Superadmin-Vereinsauswahl (PROD)

**Datum:** 15.11.2026  
**Umgebung:** Supabase PROD – Projekt `qdugtpzgefpswnnqbusd`  
**Status:** in PROD erfolgreich ausgeführt und read-only verifiziert (15.11.2026).  
**Frontend:** unverändert; kein Commit auf `main`, kein Deploy.

## Ziel

Die aktuelle Frontend-Version in `develop` verwendet `get_super_admin_clubs()`, damit ein neutraler Superadmin die Vereinskacheln laden kann, ohne direkten pauschalen SELECT-Zugriff auf `public.clubs` zu erhalten.

## Live-PROD-Ausgangsstand (read-only, 15.11.2026)

- `get_super_admin_clubs()` ist nicht vorhanden.
- `is_super_admin()` entspricht der geprüften PROD-Definition (MD5 `cffa76d7f45b67cb7c7add371df764bd`), SECURITY DEFINER, Owner `postgres`, `search_path=pg_catalog, public`.
- `clubs_select_member_or_superadmin` ist bereits kontextgebunden: `is_club_member(id) OR is_club_admin(id)`; genau eine SELECT-Policy auf `clubs`.
- `is_club_admin(uuid)` bindet Superadmin-Zugriff an den explizit ausgewählten Vereinskontext.
- Beide Kontext-SELECT-Policies sind vorhanden.
- AP03 PROD-Härtung (set_updated_at und teams-Kontext) wurde bereits als Ledger `20261115134422` ausgeführt.
- Tabellen, Policies, Trigger und Storage werden durch dieses Paket nicht verändert.

## Änderungsumfang

Eine neue Funktion `public.get_super_admin_clubs()` mit Rückgabe ausschließlich `id, name, short_name, crest_path`.

- `SECURITY DEFINER`, `STABLE`, fester `search_path=pg_catalog, public`.
- Explizite Authentifizierungsprüfung und `public.is_super_admin()`.
- EXECUTE ausschließlich für `authenticated`; `PUBLIC` und `anon` erhalten kein EXECUTE.
- Keine Anpassung bestehender Funktionen, Policies, Tabellen, Daten, Trigger, Buckets oder Storage-Policies.

## Dateien

- Migration: `supabase/migrations/20261115170000_superadmin_club_picker_rpc_prod.sql`
- Rollback: `supabase/rollback/20261115170000_superadmin_club_picker_rpc_prod_rollback.sql`
- Erwarteter Ledger-Name: `superadmin_club_picker_rpc_prod`
- Erwartete Ledger-Version: `20261115170000`

Die Migration enthält einen strikten Preflight auf die tatsächliche PROD-`is_super_admin()`-Definition, deren Sicherheitsattribute, die kontextgebundene `clubs`-SELECT-Policy sowie die benötigten Spalten. Bei Abweichung wird vor der Änderung abgebrochen. Der Postflight prüft Sicherheitsattribute und EXECUTE-Rechte.

Der Rollback entfernt ausschließlich die neu hinzugefügte RPC und verweigert die Ausführung, falls die Funktion nicht mehr den erwarteten Sicherheitsattributen entspricht.

## Ausführung und Abnahme

**Erfolgreich ausgeführt und verifiziert:**

1. Supabase meldete `success: true`.
2. Die PROD-Migrationshistorie enthält `20261115151239 – superadmin_club_picker_rpc_prod`.
3. Die Funktion ist vorhanden und liefert `TABLE(id uuid, name text, short_name text, crest_path text)`.
4. SECURITY DEFINER = true; Owner = `postgres`; `search_path=pg_catalog, public`.
5. EXECUTE: `authenticated` = ja; `anon` = nein; `PUBLIC` = nein.
6. Die bestehende `clubs_select_member_or_superadmin`-Policy blieb unverändert kontextgebunden: `is_club_member(id) OR is_club_admin(id)`; genau eine SELECT-Policy.
7. Ein Verein ist in PROD vorhanden. Der Funktionsaufruf mit echten Benutzerrechten wird nach dem Frontend-Deploy im Superadmin-UI praktisch geprüft.

Die fachliche UI-Abnahme erfolgt erst nach dem späteren GitHub-Workflow **Deploy PROD**.

## Abgrenzung

- Keine Änderung an `index.html`, weder in `develop` noch `main`.
- Keine manuelle Änderung an `main`.
- Kein GitHub-Pages-Deploy in diesem Arbeitsschritt.
- Keine erneute Ausführung bereits registrierter E05-Pakete 01–11 oder AP04-Paket 12.
- AP03 PROD-Härtung ist bereits abgeschlossen und wird nicht erneut ausgeführt.
