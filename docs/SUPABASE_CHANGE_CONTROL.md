# Supabase-Änderungssteuerung und Dokumentationspflicht

**Stand:** 04.11.2026  
**Geltungsbereich:** Supabase DEV und Supabase PROD  
**Verbindlichkeit:** Für jede tatsächliche Änderung an einer Supabase-Umgebung

## 1. Grundsatz

Jede Änderung an Supabase muss vor der Ausführung technisch vorbereitet und nach der Ausführung vollständig und wahrheitsgemäß in GitHub dokumentiert werden. Das gilt unabhängig davon, ob die Änderung über SQL, Migrationen, das Supabase-Dashboard, eine Edge-Function-Bereitstellung oder eine andere administrative Schnittstelle erfolgt.

Eine Datei in GitHub ist kein Beleg für eine ausgeführte Änderung. Ein erfolgreicher DEV-Eingriff ist kein Nachweis für PROD. Geplante, freigegebene, ausgeführte und verifizierte Änderungen müssen klar voneinander getrennt bleiben.

## 2. Verbindliche Dokumente

| Änderungstyp | Führendes Dokument | Ergänzende Dokumentation |
|---|---|---|
| SQL-Schreibzugriffe und Migrationen | `DB_MIGRATION_LOG.md` | `DB_CHANGELOG.md`, versionierte SQL-Datei |
| Datenbankobjekte und Sicherheitszustand | `DB_CHANGELOG.md` | `DB_MIGRATION_LOG.md`, Prüf-SQL |
| Edge-Function-Deployments | `SUPABASE_CHANGELOG.md` | Quellcode unter `supabase/functions/`, Release-Dokument |
| Auth-, Redirect-, E-Mail- und Storage-Konfiguration | `SUPABASE_CHANGELOG.md` | Release-/Konzeptdokument; bei SQL zusätzlich beide DB-Dokumente |
| Sonstige Supabase-Laufzeit- oder Projekteinstellungen | `SUPABASE_CHANGELOG.md` | Fachlich passendes Projekt-/Release-Dokument |

`PROJECT_CONTEXT.md` verweist auf diese Regeln und die führenden Dokumente. Fachliche Release Notes ersetzen keinen technischen Ausführungsnachweis.

## 3. Ablauf vor jeder Änderung

1. **Zielumgebung festlegen:** DEV oder PROD sowie die konkrete Supabase-Projektkennung eindeutig benennen.
2. **Ist-Zustand erfassen:** Betroffene Tabellen, Spalten, Constraints, Indizes, Funktionen, Trigger, Grants, RLS-/Storage-Policies, Edge-Function-Versionen oder Konfigurationen read-only prüfen.
3. **Änderungsquelle versionieren:** SQL vollständig unter `supabase/migrations/` ablegen; Edge-Function-Code und sonstige Quelländerungen im Repository versionieren. Keine produktive Änderung allein auf Basis eines flüchtigen Chat- oder Dashboard-Snippets.
4. **Auswirkungen prüfen:** Abhängigkeiten, bestehende Daten, Rollen, RLS, ACLs, Aufrufer, Edge Functions und Rückfallmöglichkeit bewerten.
5. **Freigabe einholen:** Zielumgebung, Änderungsumfang und Ausführungsart ausdrücklich freigeben lassen. Eine fachliche Modellfreigabe ist nicht automatisch eine Freigabe zur SQL-Ausführung oder zum Deployment.
6. **PROD-Schutz:** PROD nur nach separater ausdrücklicher Freigabe ändern. DEV-Ergebnisse werden niemals stillschweigend auf PROD übertragen.

## 4. SQL und Datenbankmigrationen

Für jede schreibende SQL-Änderung gilt:

- Vor der Ausführung eine vollständige, versionierte SQL-Datei mit eindeutiger Migrationsversion und sprechendem Namen erstellen.
- Eine bereits ausgeführte Migrationsdatei niemals nachträglich verändern. Korrekturen erhalten eine neue Migrationsversion.
- Auch direkt im SQL Editor oder über ein administratives Werkzeug ausgeführtes SQL muss vor Ausführung als unveränderliche Quelle in GitHub abgelegt werden.
- Nach jedem tatsächlichen Ausführungsversuch unverzüglich einen eigenen Datensatz für die konkrete Umgebung in `DB_MIGRATION_LOG.md` ergänzen. Das gilt auch bei Fehlern, Abbruch oder möglicher Teilwirkung.
- Der Datensatz enthält mindestens: Migration-ID/-Version, Umgebung und Projektkennung, Zeitpunkt mit Zeitzone soweit verfügbar, Ausführungsweg, Freigabe, ausführende Stelle, Commit-SHA und SQL-Datei, betroffene Objekte, Ergebnis/Fehlermeldung, Verifikation, Rollback-/Wiederherstellungsweg und Gegenstück in der anderen Umgebung.
- `DB_CHANGELOG.md` beschreibt ergänzend die tatsächlich entstandenen Datenbankobjekte, deren Signaturen und Sicherheitsmerkmale sowie die durchgeführten Prüfungen.
- DEV und PROD erhalten getrennte Ausführungsnachweise. Eine gemeinsame Statuszeile wie „in beiden Umgebungen erledigt“ genügt nicht.
- Keine Geheimnisse, Passwörter, Tokens oder Schlüssel in SQL-Dateien oder Logs ablegen.

## 5. Nicht-SQL-basierte Supabase-Änderungen

Für Edge Functions, Auth-/Redirect-/E-Mail-Konfiguration, Storage-Bucket-Einstellungen, Projektparameter und vergleichbare Änderungen gilt:

- Quellcode vor dem Deployment im Repository versionieren.
- Im `SUPABASE_CHANGELOG.md` je Änderung getrennt festhalten: eindeutige Änderungs-ID, Datum/Uhrzeit, DEV oder PROD, Projektkennung, Zweck, betroffene Funktion/Einstellung, vorheriger und neuer Zustand soweit sicher dokumentierbar, Quell-/Commit-SHA, Deployment- oder Änderungsergebnis, aktive Version und Nachprüfung.
- Bei Edge Functions zusätzlich Funktionsname, Deployment-Version, JWT-Verifikationskonfiguration, Quellpfad und einen kurzen Funktionstest dokumentieren.
- Bei Auth-/Redirect-/SMTP-/Storage-Konfigurationen keine Secret-Werte protokollieren. Es genügt, den Namen des geänderten Parameters, den betroffenen Kontext und die Prüfung zu dokumentieren.
- Falls eine solche Änderung zusätzlich SQL ändert (z. B. Tabellen, Policies oder Grants), muss sie auch in `DB_MIGRATION_LOG.md` und `DB_CHANGELOG.md` erfasst werden.

## 6. Nachprüfung nach einer Änderung

Nach einem erfolgreichen SQL-Eingriff werden, soweit betroffen, mindestens die tatsächlichen Definitionen und Rechte read-only zurückgelesen:

- Tabellen/Spalten, Constraints und Indizes,
- Funktionsdefinitionen und Signaturen,
- Trigger und zugehörige Triggerfunktionen,
- EXECUTE-/Tabellenrechte für `PUBLIC`, `anon`, `authenticated`, `service_role`,
- RLS-Status und Policies,
- Storage-Buckets und Storage-Policies,
- Migrationshistorie und tatsächliche Versionsnummer.

Anschließend sind die fachlich relevanten Positiv- und Negativtests auszuführen. Nicht durchgeführte Tests werden ausdrücklich als offen dokumentiert. Ein Syntaxcheck, eine erfolgreiche Migration oder ein erfolgreicher Deployment-Aufruf ersetzt keinen Praxistest.

## 7. Vorbereitung eines späteren PROD-Releases

Vor jedem PROD-Cutover ist ein nachvollziehbares Release-Paket vorzulegen:

1. Tatsächliche DEV- und PROD-Migrationshistorie getrennt abgleichen.
2. Alle DEV-Änderungen den unveränderlichen SQL-Quelldateien und Commit-SHAs zuordnen.
3. Die in PROD fehlenden Änderungen mit Reihenfolge und Abhängigkeiten ausweisen.
4. Tatsächliche Objektdefinitionen, ACLs, RLS-/Storage-Policies und Datenwirkungen in beiden Umgebungen vergleichen.
5. Datenbestand, Rollen und Mitgliedschaften vor und nach dem Eingriff schützen; erforderliche Datenmigrationen separat erläutern.
6. Rollback-/Wiederherstellungsstrategie und Backup-/Restore-Nachweis benennen.
7. Erforderliche Edge-Function- und Konfigurationsänderungen einschließlich ihrer DEV-/PROD-Werte getrennt planen.
8. Post-Deploy-Verifikation und fachliche Smoke-Tests festlegen.

Keine DEV-Migration darf blind erneut ausgeführt oder allein aufgrund ihrer Existenz in GitHub als PROD-bereit betrachtet werden. Nicht belegte Ausführungen, fehlende SQL-Originale oder offene Verifikationen sind vor dem Release als Blocker zu behandeln.

## 8. Statusbegriffe

- **Entwurf:** vorbereitet, weder fachlich noch technisch freigegeben.
- **Fachlich freigegeben:** Produkt-/Rollenregel beschlossen; keine automatische Ausführungsfreigabe.
- **Technisch geprüft:** Implementierung und Auswirkungen überprüft; noch nicht zwingend ausgeführt.
- **Ausführungsfreigabe erteilt:** konkrete Umgebung und konkrete Änderung ausdrücklich freigegeben.
- **Ausgeführt:** Supabase hat die Änderung tatsächlich angenommen; Ergebnis dokumentiert.
- **Verifiziert:** unabhängige Nachprüfungen erfolgreich; offene Grenzen sind genannt.
- **Fehlgeschlagen/Teilweise:** Ausführungsversuch mit Fehler oder möglicher Teilwirkung; nicht als erfolgreich zählen.

**Leitregel:** Was in Supabase tatsächlich geändert wurde, muss in GitHub als tatsächlicher Vorgang mit Umgebung, Quelle, Ergebnis und Verifikation nachgewiesen sein. Was nur vorbereitet oder freigegeben wurde, bleibt als solches gekennzeichnet.
