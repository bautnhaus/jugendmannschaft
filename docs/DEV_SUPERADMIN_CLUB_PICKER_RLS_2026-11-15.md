# Sichere Superadmin-Vereinsauswahl – DEV-Korrektur

**Datum:** 15.11.2026  
**Status:** Datenbankkorrektur, Frontend-Anpassung, SQL-Praxistests und manueller Browser-/iPhone-Test erfolgreich abgeschlossen.  
**Umgebung:** ausschließlich Supabase DEV / GitHub `develop`. PROD wurde nicht verändert.

## Ziel und Sicherheitsregel

Ein neutraler Superadmin muss die verfügbaren Vereine sehen können, um einen Vereinskontext auszuwählen. Er darf vor dieser Auswahl jedoch nicht über die normale `clubs`-Tabellenabfrage alle Vereinsdatensätze lesen.

Nach Auswahl des Vereins darf der Superadmin dessen Vereinsdaten im ausgewählten Kontext lesen und verwalten.

## Umsetzung

### 1. Begrenzte Picker-RPC

Neue Funktion `public.get_super_admin_clubs()`:

- Rückgabefelder ausschließlich: `id`, `name`, `short_name`, `crest_path`.
- Prüft `auth.uid() IS NOT NULL` und `public.is_super_admin()`.
- `SECURITY DEFINER` mit festem `search_path=pg_catalog, public`.
- Owner: `postgres`.
- EXECUTE für `authenticated`; EXECUTE für `anon` und `PUBLIC` entzogen.
- Keine Tabellen-, Spalten-, Daten-, Trigger- oder Storage-Änderungen.

Migration:
- Datei: `supabase/migrations/20261115160000_superadmin_club_picker_rpc_dev.sql`
- Blob-SHA: `e0ef73939c66bef6d5c0b03118193a541797963e`
- Supabase-DEV-Ledger-Version: `20261115135639`
- Name: `superadmin_club_picker_rpc_dev`
- Supabase-Ergebnis: `success: true`

Rollback:
- Datei: `supabase/rollback/20261115160000_superadmin_club_picker_rpc_dev_rollback.sql`
- Blob-SHA: `7f706a6356614d30926b6c1d8f5989430d042bea`
- Nicht ausgeführt.

### 2. Direkte SELECT-Policy auf `clubs`

Die bisherige DEV-Policy erlaubte `is_super_admin() OR is_club_member(id)`. Sie wurde auf die bereits in PROD verwendete kontextgebundene Regel umgestellt:

`is_club_member(id) OR is_club_admin(id)`

Damit gilt:
- tatsächliche Vereinsmitglieder sehen ihren Verein,
- Vereinsadmins sehen ihren Verein,
- Superadmins sehen Vereinsdatensätze über direkten SELECT erst nach Auswahl des passenden Vereinskontexts,
- die neutrale Vereinsauswahl erfolgt über die begrenzte Picker-RPC.

Migration:
- Datei: `supabase/migrations/20261115161000_superadmin_club_picker_rls_context_dev.sql`
- Blob-SHA: `17d2bc428c8f71d1dc983e1edeaa0827dd4ff1e4`
- Supabase-DEV-Ledger-Version: `20261115135825`
- Name: `superadmin_club_picker_rls_context_dev`
- Supabase-Ergebnis: `success: true`

Rollback:
- Datei: `supabase/rollback/20261115161000_superadmin_club_picker_rls_context_dev_rollback.sql`
- Blob-SHA: `c16183bd9421d3cb38779a2382d4931b2a08d210`
- Nicht ausgeführt. Der Rollback stellt bewusst den breiten Superadmin-Bypass wieder her und ist nur für eine DEV-Notfallwiederherstellung vorgesehen.

### 3. Frontend

`window.loadSuperAdminClubs()` in `index.html` lädt die Vereinskacheln jetzt über:

`getClient().rpc('get_super_admin_clubs')`

Die Darstellung, Vereinswappen und Auswahlaktion bleiben unverändert. Der eigentliche Vereinskontext wird weiterhin erst beim Öffnen der Vereinskachel über `select_club_context` gesetzt.

- Branch: `develop`
- Commit: `d4b08a39229967177f7cb5c2eabf25783bb1ab9d`
- Neuer Blob-SHA für `index.html`: `799cb91c77af5e390d8ac10326d22f9a150ae963`

## Verifikation

Alle SQL-Tests liefen mit simuliertem JWT-Kontext unter der Rolle `authenticated`. Für den neutralen Superadmin-Test wurden Mitgliedschafts- und Kontextzeilen nur innerhalb einer expliziten Transaktion temporär entfernt. Jede dieser Transaktionen wurde mit `ROLLBACK` beendet; es blieben keine Testdatenänderungen bestehen.

| Test | Ergebnis |
|---|---|
| Superadmin ohne Vereinsmitgliedschaft und ohne ausgewählten Kontext: `get_super_admin_clubs()` | 1 Verein geliefert |
| Normaler authentifizierter Benutzer: `get_super_admin_clubs()` | 0 Vereine geliefert |
| Anonymer Aufruf der RPC | verweigert: fehlende EXECUTE-Berechtigung |
| Neutraler Superadmin: direkter SELECT auf `public.clubs` | 0 Zeilen |
| Neutraler Superadmin: Picker-RPC | 1 Verein |
| Superadmin nach `select_club_context`: direkter SELECT auf `public.clubs` | 1 Zeile |
| RLS-Policy nach Migration | `is_club_member(id) OR is_club_admin(id)` |
| RPC-Sicherheitsattribute | SECURITY DEFINER, Owner postgres, fester search_path |
| EXECUTE-Rechte | authenticated: ja; anon: nein |

**Testkonto-Hinweis:** Das vorhandene DEV-Superadmin-Testkonto besitzt zusätzlich eine Vereinsmitgliedschaft und einen gespeicherten Vereinskontext. Für den Neutralfall wurden diese beiden Zeilen ausschließlich innerhalb der zurückgerollten Testtransaktion entfernt. Der produktive DEV-Datensatz blieb unverändert.

## Advisor-Nachkontrolle

- Health Advisor: keine Findings.
- Security Advisor: 53 Hinweise zu SECURITY-DEFINER-Funktionen, darunter die neue Picker-RPC. Diese neue RPC ist bewusst als eng begrenzte Ausnahme vorgesehen: explizite Superadmin-Prüfung, minimale Rückgabefelder, kein EXECUTE für `anon`/PUBLIC. Die übrigen bestehenden Befunde wurden nicht verändert.
- Ein weiterer Auth-Hinweis betrifft deaktivierten Schutz vor kompromittierten Passwörtern; nicht Teil dieser Korrektur.

## Manueller DEV-Praxistest – erfolgreich bestätigt

Der Nutzer hat nach dem Test auf der tatsächlichen DEV-Webseite bestätigt, dass die Vereinsauswahl und das Öffnen des Vereins erwartungsgemäß funktionieren. Damit ist die Frontend-Funktion fachlich abgenommen.

## PROD-Abgrenzung

Die DEV-Korrektur wird mit DB-MIG-2026-026 für PROD ergänzt. Die PROD-Ausführung ist separat dokumentiert und freigabepflichtig.


## Nach PROD-Deploy: Rücknavigation zur Vereinsauswahl – Korrektur vorbereitet

Beim Superadmin-Praxistest in PROD wurde festgestellt: Das Öffnen des Vereins und das Laden der Vereinsdetails funktionieren; beim Zurücknavigieren landet der Nutzer jedoch auf der Startseite „Mehr“ statt in der neutralen Vereinsauswahl.

Ursache im Frontend: `backToSuperAdminClubs()` schaltete nur die inneren Vereinsansichten um, stellte aber nicht sicher, dass der Navigationsbereich `Mehr > Verein` aktiv ist. Dadurch konnte der zuvor aktive Mehr-Unterbereich sichtbar bleiben.

Korrektur ausschließlich in `develop/index.html` am 15.11.2026:

- Beim Rückweg eines neutralen Superadmins ( `isSuperAdmin && clubOnlyMode` ) wird der Navigationsmodus auf `context` gesetzt.
- `superAdminNextSection` wird zurückgesetzt.
- Anschließend wird explizit `openMehrPage('club')` aufgerufen, das die neutrale Vereinsauswahl anzeigt.
- Andere Rollen-/Vereinsadmin-Navigationswege bleiben unverändert.

**Status:** Änderung in develop committed; DEV-Praxistest dieser Rücknavigation steht noch aus. Nicht nach main übernommen und kein PROD-Deploy dieser Korrektur erfolgt.
