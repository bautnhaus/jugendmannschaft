# DB-MIG-2026-011 – Sperrprüfung für Kaderempfehlung und Nominierung

**Stand:** 12.11.2026  
**Branch:** develop  
**Zielumgebung:** Supabase DEV ausschließlich  
**Status:** Vollständiges Freigabepaket vorbereitet; nicht ausgeführt  
**PROD / main:** unverändert

## 1. Ziel und verbindliche Fachentscheidung

Ein Spieler mit einer offenen Sperre, deren `intended_matchday_id` dem aktuellen Spieltag entspricht, wird als gesperrt behandelt.

- Regulär gesperrte Spieler dürfen nicht in einer gespeicherten Kaderempfehlung enthalten sein.
- Regulär gesperrte Spieler dürfen nicht in `matchday_players` nominiert werden.
- Eine aktive Ausnahme (`training_suspension_exceptions.revoked_at IS NULL`) für genau diesen Spieltag erlaubt Empfehlung und Nominierung.
- Die Ausnahme hebt die Sperre nicht auf. Die bestehende Ausnahme-RPC protokolliert die Entscheidung und verschiebt die offene Sperre auf den nächsten Spieltag.
- Nach Widerruf greift die Sperrenprüfung wieder, sobald die Sperre diesem Spieltag erneut zugeordnet ist.
- Es werden keine bestehenden Nominierungen automatisch gelöscht.

## 2. DEV-Ausgangsbasis read-only geprüft

Projekt: `pzazqvvoruqnqhcorbwx`.

### Bestehende RPC

`public.save_matchday_recommendation(uuid,uuid[])`:
- PL/pgSQL, SECURITY INVOKER, search_path `pg_catalog, public`.
- Owner: postgres.
- EXECUTE: postgres, authenticated, service_role.
- Prüft Spieltag, Teammitgliedschaft, Duplikate, Spielerexistenz, Mannschaftszugehörigkeit und Aktivität.
- Eine Sperrenprüfung fehlte.

### Bestehende Ausnahmefunktionen

- `grant_suspension_exception(uuid,uuid,text)`
- `revoke_suspension_exception(uuid,text)`

Beide sind SECURITY DEFINER mit search_path `pg_catalog, public, auth`; Owner postgres; EXECUTE für authenticated. Sie bleiben unverändert. Die Grant-Funktion verlangt Begründung und genau den aktuell zugeordneten geplanten Spieltag; sie protokolliert Audit und ordnet danach die offene Sperre neu zu. Die Revoke-Funktion protokolliert den Widerruf und berechnet die Zuordnung neu.

### Bestehende Trigger und RLS

Auf `matchday_players` existieren bereits:
- BEFORE INSERT: `require_active_player_for_new_assignment`
- BEFORE UPDATE OF player_id: derselbe Trigger
- AFTER INSERT OR UPDATE OF matchday_id, player_id: `e05_cancel_early_reset_on_nomination`

Diese Trigger bleiben erhalten. Die Migration ergänzt einen eigenständigen BEFORE-Trigger und ändert keine RLS-Policy. Die aktuellen Policies für `matchday_players` und Empfehlungstabellen erlauben berechtigten Teammitgliedern die jeweiligen Schreiboperationen; deshalb ist die serverseitige Triggerprüfung notwendig.

## 3. Umfang der Migration

### A. Neue Triggerfunktion

`public.e05_assert_matchday_player_not_suspended()`

- SECURITY DEFINER ausschließlich zum zuverlässigen Lesen des Sperr-/Ausnahmestatus unabhängig von der RLS-Sichtbarkeit.
- Fest gesetzter search_path `pg_catalog, public, auth`.
- Liest nur; keine Datenänderungen.
- Wird für beide Tabellen verwendet:
  - `matchday_players`: Zielspieltag direkt aus `NEW.matchday_id`.
  - `matchday_recommendation_players`: Zielspieltag über `matchday_recommendation_runs.matchday_id`.
- Blockiert eine offene Sperre für diesen Spieltag, sofern keine aktive Ausnahme für genau diesen Spieltag existiert.
- Sperrt den gefundenen Sperrdatensatz während der Prüfung, um die Prüfung mit Ausnahmeerteilung/-widerruf zu serialisieren.
- EXECUTE wird für PUBLIC, anon, authenticated und service_role widerrufen; Funktion wird nur durch Trigger aufgerufen.

### B. Trigger

- `e05_guard_matchday_nomination_suspension` auf `matchday_players`, BEFORE INSERT OR UPDATE OF matchday_id, player_id.
- `e05_guard_matchday_recommendation_suspension` auf `matchday_recommendation_players`, BEFORE INSERT OR UPDATE OF recommendation_id, player_id.

Damit sind sowohl die normale RPC als auch direkte Tabellen-Schreibpfade abgesichert.

### C. Bestehende Empfehlungs-RPC

Die bestehende `save_matchday_recommendation(uuid,uuid[])` wird per guarded source transformation erweitert. Vor der Änderung muss der geprüfte Quelltextmarker genau einmal vorhanden sein; andernfalls bricht die Migration ab.

Die bisherige Funktion und alle bestehenden Prüfungen bleiben erhalten. Ergänzt wird die Sperrenprüfung mit Ausnahme für denselben Spieltag. Signatur, SECURITY INVOKER, Owner und EXECUTE-ACLs bleiben erhalten.

## 4. Dateien

- Migration: `supabase/migrations/20261112120000_e05_suspension_nomination_guard.sql`
- Rollback: `supabase/rollback/20261112120000_e05_suspension_nomination_guard_rollback.sql`
- Diese Spezifikation: `docs/E05_DB_MIG_2026_011_SPERRPRUEFUNG_KADERNOMINIERUNG.md`

Die Migration ist transaktional. Das Rollback stellt die vorab gelesene ursprüngliche RPC-Definition wieder her und entfernt nur die beiden neuen Trigger sowie die neue Triggerfunktion.

## 5. Bewusst nicht enthalten

- Keine Änderung an `grant_suspension_exception` oder `revoke_suspension_exception`.
- Keine Änderung an anderen E05-Sperrenfunktionen.
- Keine RLS-Policy- oder Tabellenänderung.
- Keine automatische Entfernung bestehender Nominierungen.
- Keine Frontendänderung.
- Keine Änderung an bestehenden Sperren, Ausnahmen, Empfehlungen oder Nominierungen.
- Keine PROD-Änderung.

## 6. Testplan nach gesonderter Freigabe und Ausführung

1. Migration wird in DEV in einer Transaktion ausgeführt.
2. Funktionsdefinition, Triggerdefinitionen, Owner, SECURITY-Attribut, search_path und ACLs werden vor/nachher verglichen.
3. Regulär gesperrter Spieler: Empfehlungs-RPC lehnt ab.
4. Ungesperrter Spieler: Empfehlungs-RPC funktioniert.
5. Spieler mit aktiver Ausnahme für genau diesen Spieltag: Empfehlungs-RPC funktioniert.
6. Direkter INSERT in `matchday_recommendation_players` für gesperrten Spieler: Trigger lehnt ab.
7. Direkter INSERT in `matchday_players` für gesperrten Spieler: Trigger lehnt ab.
8. Nominierung mit aktiver Ausnahme: funktioniert.
9. Ausnahme widerrufen und Sperre wieder diesem Spieltag zugeordnet: Empfehlung/Nominierung wird abgelehnt.
10. Andere Spieltage ohne dort zugeordnete Sperre bleiben unberührt.
11. Bestehende Trigger `require_active_player_for_new_assignment` und `e05_cancel_early_reset_on_nomination` bleiben aktiv.
12. Bestehende Datensätze werden nicht verändert.

## 7. Rollback

Rollback nur nach gesonderter Freigabe. Er entfernt beide neuen Trigger und die dedizierte Triggerfunktion und stellt die vor Migration geprüfte Definition von `save_matchday_recommendation(uuid,uuid[])` wieder her. Die Migration führt keine Datenänderungen durch; es sind daher keine Daten-Rückkorrekturen vorgesehen.

## 8. Freigabestatus

Dieses Paket ist zur fachlichen und technischen Prüfung bestimmt. Es wurde nicht in Supabase ausgeführt, nicht in der Migrationshistorie registriert und nicht deployed. Eine gesonderte ausdrückliche Freigabe ist vor jeder Ausführung erforderlich.
