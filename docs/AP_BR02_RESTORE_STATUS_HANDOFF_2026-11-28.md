# AP-BR02 Restore – Status & nächste Umsetzungsschritte

- Aktualisiert: 28.11.2026
- Branch: `develop`
- PROD: unverändert
- Datenbank/Storage: keine Writes in diesem Arbeitsschritt

## Bestätigter Stand

1. `src/backup/restore-planner.js`: Paket-/Manifest-Preflight, feste Tabellen-/Feld-Allowlists, Relations- und Team-Closure-Prüfung sowie deterministische Merge-Vorschau vorhanden.
2. `src/backup/restore-preview-contract.js`: read-only Zielvorschau-Vertrag mit festen Selects und Team-/FK-Scope-Closure vorhanden. Der Vertrag dokumentiert ausdrücklich, dass serverseitige Auth-/Scope-Prüfung VOR Ziel-SELECTs erfolgen muss.
3. `src/backup/restore-operation-contract.js`: reine synthetische Entscheidungshilfe für INSERT / UPDATE_NEWER / KEEP / CONFLICT / BLOCKED. Kein Executor und keine Authentifizierung.
4. DEV-Browser-Test `tests/backup/ap-br02-operation-contract-v1.html`: am 28.11.2026 durch Nutzer mit **11/11 passed** bestätigt. Der Protected-Field-Regressionstest `team_id → blocked` besteht.
5. Statusdokumentation bestätigt in Commit `81a1624`.

## Noch nicht umgesetzt (entscheidende Sicherheitsgrenze)

- Keine echte Restore-Write-Funktion.
- Keine live serverseitig authentifizierte Rollen-/Scope-Gate-Integration in den Restore-Ablauf.
- Keine autorisierte Zielabfrage als zusammenhängender Serverprozess.
- Kein persistenter Restore-Job, keine Transaktions-/Teilfehlerstrategie und kein finaler Commit-Schritt.
- Kein Rollen-/Konflikt-UI mit expliziter Auswahl und Bestätigung.
- Kein Restore mit realen Teamdaten; kein PROD-Restore.

## Nächster sinnvoller Schritt – vor Writes

**AP-BR02-RS03: Rollen- und Scope-Entscheidungsvertrag als reine, synthetische Funktion plus Negativtests.**

Die Funktion darf ausschließlich trusted serverseitig ermittelte Identität/Rollen/Mitgliedschaften und den vom Nutzer ausdrücklich gewählten Scope entgegennehmen. Manifest-Rollen und clientseitig übermittelte Berechtigungen sind nie Autorität. Die Tests sollen mindestens abdecken:

- Mannschaftsadmin: nur die eigene autorisierte Mannschaft.
- Vereinsadmin: nur den eigenen Verein und nur ausdrücklich ausgewählte, zugehörige Mannschaften/Kategorien.
- Superadmin: nur den ausdrücklich gewählten Verein-/Mannschaftskontext; neutraler globaler Zugriff ohne Kontext wird abgelehnt.
- fehlender oder mehrdeutiger Kontext, nicht zugehörige Team-ID, fremder Club, leere Scope-Auswahl und nicht erlaubte Kategorie: fail-closed.
- Vor jeder Ziel-Datenabfrage muss die serverseitige Prüfung erfolgreich sein.

Diese reine Contract-Stufe ist weiterhin ohne Supabase-Verbindung, SQL, Storage-Zugriff oder Writes. Erst nach bestätigten Negativtests wird die sichere Server-Read-Integration geplant. Write-Executor, Transaktions-/Rollback-Konzept und echte Restore-Praxistests bleiben getrennte spätere Stufen.

## Arbeitsregeln

- Nur `develop`; DEV zuerst.
- Keine SQL-/Schemaänderung ohne gesonderte Freigabe.
- Keine PROD-Änderung ohne gesonderte Freigabe.
- Keine Datenlöschung: Restore V1 bleibt merge/never-delete.
- Vor jeder Zielabfrage: Authentifizierung, Rollen- und Scope-Closure serverseitig.
- Konflikte werden sichtbar und nachvollziehbar gemacht; niemals stillschweigend überschrieben.
