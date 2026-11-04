# Supabase-Laufzeit- und Konfigurationsänderungsprotokoll

**Stand:** 04.11.2026  
**Geltungsbereich:** Nicht-SQL-basierte Änderungen in Supabase DEV und Supabase PROD.  
**Führende Prozessdokumentation:** `docs/SUPABASE_CHANGE_CONTROL.md`

## 1. Zweck und Abgrenzung

Dieses Protokoll dokumentiert tatsächliche Änderungen, die nicht vollständig über versionierte SQL-Migrationen abgebildet werden, insbesondere:

- Bereitstellungen und Aktualisierungen von Supabase Edge Functions,
- Auth-Einstellungen, Redirect-URLs, E-Mail-/SMTP-Konfigurationen,
- Storage-Bucket-Konfigurationen und administrative Storage-Einstellungen,
- Projekt-, Laufzeit- und sonstige Supabase-Konfigurationen,
- Änderungen an Secrets oder Umgebungsvariablen (ausschließlich Metadaten, niemals Secret-Werte).

Schreibende SQL-Änderungen bleiben zusätzlich und verbindlich in `DB_MIGRATION_LOG.md` dokumentiert. Datenbankobjekte und Sicherheitszustände werden in `DB_CHANGELOG.md` beschrieben.

## 2. Verbindliche Regeln

- DEV und PROD erhalten getrennte Einträge.
- Ein vorbereiteter Quellcode ist kein Deployment-Nachweis.
- Eine erfolgreiche Deployment-Antwort ist noch kein Funktionsnachweis.
- Jede Änderung muss auf einen GitHub-Commit und die zugehörige Quelle zurückführbar sein.
- Fehlgeschlagene, abgebrochene oder teilweise Änderungen bleiben als solche dokumentiert.
- Secret-Werte, Passwörter, API-Keys und Tokens dürfen niemals eingetragen werden.
- Eine fachliche Freigabe ersetzt nicht die ausdrückliche Freigabe für Deployment oder Konfigurationsänderung.

## 3. Eintragsvorlage

### SUPA-YYYY-NNN – Kurzbeschreibung

- **Datum/Uhrzeit (mit Zeitzone):**
- **Umgebung:** DEV / PROD
- **Supabase-Projektkennung:**
- **Änderungstyp:** Edge Function / Auth / Redirect / E-Mail / Storage / Secret-Metadaten / Sonstiges
- **Anlass/Zweck:**
- **Betroffene Funktion/Einstellung:**
- **Vorheriger Zustand:**
- **Neuer Zustand:**
- **Freigabe:** konkrete Freigabe und Umfang
- **Ausführungsweg:**
- **Quellpfad und Commit-SHA:**
- **Deployment-/Änderungsergebnis:** erfolgreich / fehlgeschlagen / teilweise
- **Aktive Version bzw. Konfigurationsnachweis:**
- **Verifikation:** konkrete Prüfung und Ergebnis
- **Rollback/Wiederherstellung:**
- **Zugehörige DB-Migrationen:** IDs oder „nicht zutreffend“
- **PROD-Gegenstück:** ausgeführt / nicht ausgeführt / gesondert freizugeben
- **Offene Punkte/Nachweisgrenzen:**

---

## 4. Neue Einträge

Für die am 04.11.2026 vorbereitete Rollenmodell-Korrektur wurde keine Supabase-Laufzeit- oder Konfigurationsänderung ausgeführt. Die geänderte Quelle für `invite-member` und der 410-Gone-Ersatz für `invite-trainer` befinden sich ausschließlich im Review-Feature-Branch und sind nicht deployed. Die aktuelle Live-Version bleibt unverändert; der ausführlichere Status steht in `docs/proposals/single-team-membership-guard/README.md` und `docs/RELEASE_1_6_INVITATION_REPAIR_DEV.md`.

Künftige tatsächliche Deployments und Konfigurationsänderungen werden ab diesem Protokoll mit dem Eintragsmuster aus Abschnitt 3 dokumentiert. Historische Änderungen werden nicht ohne Beleg rückwirkend rekonstruiert.
