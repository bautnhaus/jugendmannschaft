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

**AP-BR02-RS03: Rollen- und Scope-Entscheidungsvertrag als reine, synthetische Funktion plus Negativtests – implementiert, Browserbestätigung ausstehend.**

Die Funktion darf ausschließlich trusted serverseitig ermittelte Identität/Rollen/Mitgliedschaften und den vom Nutzer ausdrücklich gewählten Scope entgegennehmen. Manifest-Rollen und clientseitig übermittelte Berechtigungen sind nie Autorität. Die Tests sollen mindestens abdecken:

- Mannschaftsadmin: nur die eigene autorisierte Mannschaft.
- Vereinsadmin: nur den eigenen Verein und nur ausdrücklich ausgewählte, zugehörige Mannschaften/Kategorien.
- Superadmin: nur den ausdrücklich gewählten Verein-/Mannschaftskontext; neutraler globaler Zugriff ohne Kontext wird abgelehnt.
- fehlender oder mehrdeutiger Kontext, nicht zugehörige Team-ID, fremder Club, leere Scope-Auswahl und nicht erlaubte Kategorie: fail-closed.
- Vor jeder Ziel-Datenabfrage muss die serverseitige Prüfung erfolgreich sein.

Implementiert auf develop: `src/backup/restore-scope-contract.js` und `tests/backup/ap-br02-restore-scope-contract-rs03.html` (synthetische Rollen-/Kontextfälle). Der DEV-Browserlauf wurde am 28.11.2026 vom Nutzer mit **11/11 PASS** bestätigt. Die reine Contract-Stufe bleibt ohne Supabase-Verbindung, SQL, Storage-Zugriff oder Writes. Erst nach bestätigten Tests wird die sichere Server-Read-Integration geplant. Write-Executor, Transaktions-/Rollback-Konzept und echte Restore-Praxistests bleiben getrennte spätere Stufen.

## Arbeitsregeln

- Nur `develop`; DEV zuerst.
- Keine SQL-/Schemaänderung ohne gesonderte Freigabe.
- Keine PROD-Änderung ohne gesonderte Freigabe.
- Keine Datenlöschung: Restore V1 bleibt merge/never-delete.
- Vor jeder Zielabfrage: Authentifizierung, Rollen- und Scope-Closure serverseitig.
- Konflikte werden sichtbar und nachvollziehbar gemacht; niemals stillschweigend überschrieben.


## RS03 – Implementierungsnachtrag

- Commit `69d9954`: erste Scope-Contract-Funktion.
- Commit `41b036d`: Superadmin darf einen Mannschafts-Scope nur bei explizit übereinstimmendem, servervalidiertem Teamkontext prüfen; keine implizite globale Auswahl.
- Commit `0d7bede`: Vereinsadmin-Clubscope basiert auf bestätigter Vereinsmitgliedschaft und den serverermittelten Teams dieses Vereins; nicht auf der zufälligen aktiven Trainer-Teammitgliedschaft.
- Commit `42f127b`: Testfall ergänzt, dass ein Vereinsadmin mehrere ausdrücklich ausgewählte Teams innerhalb des eigenen Vereins sichern/restaurieren darf.
- Browser-Testseite: `tests/backup/ap-br02-restore-scope-contract-rs03.html`.
- Erwartung nach DEV-Deploy: alle 11 synthetischen Fälle PASS. Noch keine Serverintegration oder Writes.


## RS03 – DEV-Browsernachweis und nächste Sicherheitsprüfung (28.11.2026)

- Nutzerbestätigung per Screenshot: `tests/backup/ap-br02-restore-scope-contract-rs03.html` zeigt **11/11 passed**.
- Das bestätigt die reine synthetische Scope-Funktion; es bestätigt ausdrücklich noch keine echte Edge-Function-/Supabase-Rollenintegration.
- Code-Audit der bestehenden `supabase/functions/ap-br02-restore-preview/index.ts` und `restore-preview-auth.ts` ergab: Der aktuelle Preview-Endpunkt autorisiert ausschließlich über `is_team_admin(p_team_id)`. Die RS03-Funktion wird dort noch nicht eingebunden. Die bestehenden SQL-Policies/RPCs kennen außerdem den ausgewählten Vereinskontext über `can_manage_club_context(p_club_id)` und Superadmin-Teamkontext über `is_team_admin(p_team_id)`.
- Daher ist **RS04 – serverseitige Rollen-/Scope-Integration in die bestehende read-only Preview** der nächste sinnvolle Schritt. Vor einer Änderung müssen die Auth-Prüfung, der Kontextwechsel (Team/Verein), Club-Zuordnung und Reihenfolge aller Service-Role-Reads im bestehenden Endpoint als zusammenhängender Ablauf abgestimmt werden.
- Ziel-Rollenmatrix RS04: Mannschaftsadmin im autorisierten Team; Vereinsadmin im ausdrücklich ausgewählten Verein und innerhalb dessen Teamzugehörigkeit; Superadmin nur im explizit ausgewählten Team-/Vereinskontext. Jede Ablehnung muss vor dem ersten privilegierten Ziel-SELECT erfolgen.
- RS04 bleibt read-only: kein Restore-Write, keine Storage-Aktion, keine SQL-/Schemaänderung, kein PROD-Deploy. Zuerst synthetische Unit-Tests für Auth-Reihenfolge und alle drei Rollen, danach isolierter DEV-Preview-Praxistest.


## RS04 – serverseitige Preview-Autorisierung integriert (28.11.2026)

- Commits auf `develop`: `bd083f9` (Auth-Gate), `6d14795` (Einbindung in Preview vor Service-Role-Client/Target-SELECT), `d21b676` (synthetische Club-Gate-Tests).
- Der bestehende JWT-Client prüft zuerst `is_team_admin(selected_team_id)`. Für ein ein-Teamiges Club-Backup kann danach `can_manage_club_context(package_club_id)` greifen; bei erfolgreicher Clubprüfung wird die Mannschafts-/Vereinszugehörigkeit über eine RLS-geschützte Abfrage des Nutzerclients verifiziert.
- Erst nach erfolgreichem Gate wird im Handler der Service-Role-Client erstellt und der erste privilegierte Ziel-SELECT ausgeführt. Auth-/Clubfehler sind fail-closed.
- Tests ergänzen Clubadmin-Erlaubnis, Fremdverein-Mannschaft, fehlende Clubberechtigung und Fehler bei RLS-Zuordnungsprüfung. Bestehende Teamadmin-/Auth-Tests bleiben enthalten.
- **Noch offen:** GitHub Actions/Typecheck-Ausführung und DEV-Deployment/Browsertest stehen aus. Diese Codeintegration ist kein bestätigter Laufzeitnachweis.
- Unverändert: keine SQL-/Schemaänderung, keine Storage-Aktion, keine Writes, kein Restore und kein PROD-Deploy.


### RS04 – Scope-Abschlusskorrektur

- Zusätzlich wird bei **jedem Club-Backup** die Team-/Club-Zugehörigkeit mit dem JWT-/RLS-Client geprüft – auch wenn die Teamadmin-RPC bereits erlaubt. Damit kann ein Teamadmin-Grant keine Fremdverein-Mannschaft in einen Club-Paket-Scope hineinziehen.
- Synthetischer Regressionstest ergänzt: Teamgrant + abweichende Clubzugehörigkeit → deny vor Service-Role-Client.
- Aktuelle relevante Folgecommits: `4f08016` (korrekter Auth-Modulpfad), `3ff0ad4` (Club-Paket-Ancestry auch bei Teamgrant), `fd9f236` (Regressionstest). Versehentlich zunächst angelegter Root-Helfer wurde entfernt (`dc2ff77`).
- Lokales Deno ist in der Arbeitsumgebung nicht installiert; Typecheck/Tests können hier nicht lokal behauptet werden. GitHub Actions muss den bestehenden Workflow `AP-BR02 Preview Handler Check` ausführen. Danach erst DEV-Deploy und realer read-only Rollen-Praxistest.
