# E05 PROD Paket 11 – Sperrprüfung bei Kaderempfehlung und Nominierung

- **Status:** Technisch vorbereitet; PROD-Freigabe steht aus.
- **Ziel:** Supabase PROD, Projekt `qdugtpzgefpswnnqbusd`.
- **Entwicklungs-/Dokumentationsbranch:** `develop`.
- **Vorgesehene Katalognummer:** DB-MIG-2026-022.
- **PROD-Migration:** `20261115100000_e05_prod_paket_11_suspension_aware_recommendation_nomination`.
- **PROD-Ausführung:** Noch nicht erfolgt.

## 1. Abgleich DEV zu PROD

Read-only verglichene Supabase-Migrationshistorien und Live-Funktionen zeigen:

| DEV-Änderung | PROD-Stand | Behandlung |
|---|---|---|
| DB-MIG-2026-009 – Read-RPCs für Spielarten-Einstellungen | Nicht vorhanden | Nicht übernehmen: Nach der bestätigten Vereinfachung „jeder geplante Spieltag zählt“ nicht mehr benötigt |
| DB-MIG-2026-010 – alle geplanten Spieltage sind Sperrziele | Paket 10 | Bereits in PROD enthalten |
| DB-MIG-2026-011 – Sperrprüfung Kaderempfehlung/Nominierung | Teilweise vorhanden | Bestandteil Paket 11 |
| DEV-Version 20261113035705 – atomarer Ausnahme-Widerruf | PROD Paket 6 | Bereits funktional enthalten; keine zusätzliche Migration erforderlich |

**Wichtig zur DEV-Migration 20261113035705:** Die aktuelle PROD-Funktion `revoke_suspension_exception` und der bestehende Nominierungstrigger enthalten bereits die maßgeblichen DEV-Schutzmechanismen: spielerbezogene Advisory Locks, erneute Sperrenzuordnung, bedingte Entfernung einer dadurch unzulässigen Nominierung, Abbruch bei `played = true` und Audit-Snapshot `nomination_removed` / `removed_nomination_snapshot`. Diese Funktionalität kam mit PROD Paket 6. Paket 11 ersetzt diese bereits vorhandene Logik nicht.

Damit ist **DB-MIG-2026-011 die einzige noch ausstehende DEV-Funktionalität für den PROD-Abgleich**. In DEV ist keine weitere Migration auszuführen.

## 2. Fachregel

- Eine offene Sperre blockiert die gespeicherte Kaderempfehlung, wenn ihr `intended_matchday_id` dem Zielspieltag entspricht.
- Eine aktive Ausnahme für exakt dieselbe Sperre und denselben Spieltag erlaubt die Empfehlung.
- Eine offene Sperre blockiert außerdem eine direkte Nominierung in `matchday_players`.
- Eine aktive Ausnahme für genau diesen Spieltag erlaubt die Nominierung.
- Widerrufene Ausnahmen (`revoked_at IS NOT NULL`) erlauben weder Empfehlung noch Nominierung.
- Sperren für andere Spieltage blockieren den aktuellen Spieltag nicht.
- Die bestehende atomare Ausnahme-Rücknahme aus Paket 6 bleibt erhalten. Bei Widerruf wird eine unzulässige Nominierung nur dann entfernt, wenn sie tatsächlich wieder unter die Sperre fällt; ein bereits dokumentierter Einsatz führt zum vollständigen Abbruch.

## 3. PROD-Ausgangslage

Read-only festgestellt:

- `save_matchday_recommendation(uuid,uuid[])` existiert, ist SECURITY INVOKER und hat die bisherigen Prüfungen für Spieltag, Teammitgliedschaft, Duplikate, Spielerexistenz, Teamzugehörigkeit und Aktivität. Die Sperrenprüfung fehlt.
- Trigger `matchday_players_prevent_suspended_nomination` ist bereits vorhanden und mit `prevent_suspended_matchday_nomination()` verbunden.
- Die Triggerfunktion enthält bereits die spielerbezogene Advisory-Lock-Logik und die Prüfung offener Sperren/Ausnahmen.
- Die direkte EXECUTE-Berechtigung auf die Triggerfunktion ist in PROD noch für PUBLIC, anon und authenticated vorhanden; DEV hat diese Rechte entzogen. service_role bleibt in DEV und PROD ausführbar.
- `revoke_suspension_exception` enthält bereits die atomare Widerrufs-/Nominierungsentfernungslogik aus Paket 6.
- Paket 10 ist bereits in PROD registriert.

## 4. Migrationsumfang

Die Paket-11-Migration:

1. ersetzt ausschließlich `save_matchday_recommendation(uuid,uuid[])` durch die aktuelle live aus DEV ausgelesene Definition mit Sperren-/Ausnahmeprüfung;
2. entzieht `prevent_suspended_matchday_nomination()` die direkte EXECUTE-Berechtigung für PUBLIC, anon und authenticated; service_role bleibt unverändert;
3. erhält den vorhandenen Nominierungstrigger unverändert;
4. erhält `revoke_suspension_exception` und seine atomare Widerrufslogik unverändert.

Keine Tabellen, Spalten, Daten, Trigger, RLS-Policies oder sonstigen Funktionen werden verändert. Die Migration ist transaktional und bricht bei abweichendem Ausgangsstand im Preflight ab.

## 5. Dateien

- Migration: `supabase/migrations/20261115100000_e05_prod_paket_11_suspension_aware_recommendation_nomination.sql`
- Rollback: `supabase/rollback/20261115100000_e05_prod_paket_11_suspension_aware_recommendation_nomination_rollback.sql`
- CI-Fixture/Assertions: `docs/prod-release/test-package-11/`
- CI-Workflow: `.github/workflows/e05-prod-package-11-ci.yml`

## 6. Tests und Rollback

Die isolierte PostgreSQL-17-CI prüft:
- Migration gegen den dokumentierten Paket-6-PROD-Ausgangsstand;
- gesperrte Kaderempfehlung wird abgewiesen;
- ungesperrte bzw. mit exakt passender aktiver Ausnahme versehene Empfehlung wird zugelassen;
- direkte Nominierung ohne Ausnahme wird abgewiesen;
- direkte Nominierung mit aktiver Ausnahme wird zugelassen;
- nach Widerruf der Ausnahme werden Empfehlung und direkte Nominierung wieder abgewiesen;
- eine Sperre für einen anderen Spieltag blockiert den Zielspieltag nicht;
- Triggerbestand und EXECUTE-ACLs entsprechen dem erwarteten DEV-Stand;
- guarded Rollback stellt die ursprüngliche PROD-RPC und ACLs wieder her, ohne den bereits vorhandenen Trigger zu entfernen.

Der Rollback ist nur nach gesonderter Freigabe auszuführen. Er entfernt nicht den vorhandenen Trigger, sondern stellt den Zustand vor Paket 11 wieder her; damit entfällt die Sperrenprüfung in der Empfehlungs-RPC und die alte direkte Triggerfunktions-EXECUTE-Freigabe wird wiederhergestellt.

## 7. Freigabestatus

- DEV-Live-Stand read-only geprüft; DB-MIG-2026-011 ist in DEV registriert und die Tests sind laut Projektstand durchgeführt.
- DB-MIG-2026-009 wird aufgrund der späteren Fachentscheidung nicht übertragen.
- DB-MIG-2026-010 ist durch PROD Paket 10 abgedeckt.
- Die DEV-Änderung 20261113035705 ist bereits funktional durch PROD Paket 6 abgedeckt.
- Paket-11-Migration und Rollback liegen auf `develop`.
- Supabase PROD wurde für diese Vorbereitung ausschließlich lesend geprüft; Paket 11 wurde nicht ausgeführt.
- GitHub `main` und Frontend bleiben unverändert.
- **Benötigt wird die ausdrückliche PROD-Freigabe für Paket 11.**
