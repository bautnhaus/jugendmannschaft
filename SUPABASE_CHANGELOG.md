# Supabase-Laufzeit- und Konfigurationsänderungsprotokoll

**Stand:** 06.11.2026  
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

### SUPA-2026-001 – Release 1.6: Einladungs-Edge-Functions aktualisiert

- **Datum/Uhrzeit (Europe/Berlin):** 04.11.2026, 16:15:22 (invite-member) und 16:15:24 (invite-trainer).
- **Umgebung:** ausschließlich DEV.
- **Supabase-Projektkennung:** pzazqvvoruqnqhcorbwx.
- **Änderungstyp:** Edge Function.
- **Anlass/Zweck:** Die zentrale Einladung erlaubt bestehende Superadmin-Konten als Zielpersonen, sofern Vereins- und Mannschaftsregeln eingehalten werden. Der historische Endpunkt invite-trainer wird auf einen 410-Gone-Ersatz umgestellt.
- **Betroffene Funktionen:** invite-member, invite-trainer.
- **Vorheriger Zustand:** Beide Funktionen ACTIVE, Version 3, JWT-Prüfung aktiviert. invite-member wies Superadmins als Zielpersonen ausdrücklich ab; invite-trainer enthielt noch den alten Einladungsablauf.
- **Neuer Zustand:** Beide Funktionen ACTIVE, Version 4, JWT-Prüfung weiterhin aktiviert.
- **Freigabe:** Ausdrückliche Nutzerfreigabe am 04.11.2026 ausschließlich für diese beiden Edge-Function-Deployments in DEV. Keine SQL-Änderung, keine PROD-Änderung, keine Änderung an GitHub main.
- **Ausführungsweg:** Supabase Edge-Function-Deployment.
- **Quellpfade und GitHub-Blob-SHAs in develop:**
  - supabase/functions/invite-member/index.ts – 23234ab65ae1c9ba85067cf8d72d1a290f5a486e
  - supabase/functions/invite-trainer/index.ts – 004499fe27bef85d9896fd1f1c35883dd12ee0bc
- **Deployment-/Änderungsergebnis:** Beide Deployments erfolgreich angenommen.
- **Aktive Version / Deployment-SHA:**
  - invite-member: Version 4, 84dd949d0952615cb59bd2e661d0c722de738bd94751d0989695e5d050f6e0ea
  - invite-trainer: Version 4, 0f2e6e69caa730a80220e4e1f959ade5f1f218d00eb6d0a26f325e7608a323a7
- **Verifikation:** Beide Funktionen unmittelbar nach Deployment über Supabase erneut ausgelesen. Beide Live-Quelltexte stimmen bytegenau mit den jeweiligen develop-Dateien überein. invite-member enthält keine Superadmin-Zielpersonen-Sperre mehr und leitet anhand der Supabase-Projektkennung auf die DEV-App weiter. invite-trainer antwortet für Nicht-OPTIONS-Anfragen mit HTTP 410 und verweist auf invite-member. Beide Funktionen melden ACTIVE, Version 4 und verify_jwt=true.
- **Grenze des Nachweises:** Deployment-Metadaten und Live-Quelltexte sind verifiziert. Ein authentifizierter HTTP-Aufruf des Legacy-Endpunkts und der Superadmin-Einladungs-End-to-End-Test in der Browser-App stehen noch aus.
- **Rollback/Wiederherstellung:** Bei Bedarf die zuvor ausgelesenen Version-3-Quellen als neue Deployments wiederherstellen. Das wäre eine neue, separat freizugebende Supabase-Laufzeitänderung.
- **Zugehörige DB-Migrationen:** Keine neue Migration. DB-DEV-009 (20261104143331) war zuvor separat in DEV ausgeführt worden.
- **PROD-Gegenstück:** Nicht ausgeführt und nicht freigegeben. PROD bleibt unverändert.

Künftige tatsächliche Deployments und Konfigurationsänderungen werden ab diesem Protokoll mit dem Eintragsmuster aus Abschnitt 3 dokumentiert. Historische Änderungen werden nicht ohne Beleg rückwirkend rekonstruiert.


### SUPA-2026-002 – PROD: Einladung auf kadassist.de bereitgestellt

- **Datum:** 06.11.2026
- **Umgebung:** ausschließlich Supabase PROD
- **Supabase-Projektkennung:** qdugtpzgefpswnnqbusd
- **Änderungstyp:** Edge Functions und Auth-URL-Konfiguration
- **Anlass/Zweck:** Domaingetrennte Einladung für die PROD-App unter https://kadassist.de; Stilllegung des historischen Einladungsendpunkts.
- **Freigabe:** Ausdrückliche Nutzerfreigabe für die jeweiligen PROD-Deployments und die Auth-URL-Anpassung.
- **Quellpfade und Commits in GitHub develop:**
  - `supabase/functions/invite-member-prod/index.ts` – PROD-Variante auf Basis der getesteten DEV-Version 5; Commit `0fd6bab357cbb31e8715d745b672f4091e5ca658`.
  - `supabase/functions/invite-trainer-prod/index.ts` – dokumentierter Legacy-Ersatz; Commit `acb3a5ca85aefa4e7ab9dd1b5d0778a27ce0c994`.
- **invite-member:** Version 1 ACTIVE, `verify_jwt=true`; CORS-Origin ausschließlich `https://kadassist.de`; Redirect für PROD-Projekt auf `https://kadassist.de/`. Deployment und Status wurden nach dem Deploy read-only zurückgelesen.
- **invite-trainer:** Version 3 ACTIVE, `verify_jwt=true`; OPTIONS-Preflight wird beantwortet, alle anderen Aufrufe liefern HTTP 410 Gone mit Verweis auf `invite-member`. Deployment und Status wurden nach dem Deploy read-only zurückgelesen.
- **Auth-URL-Konfiguration:** Der Nutzer hat Site URL `https://kadassist.de` und Redirect URL `https://kadassist.de/` im Supabase-Dashboard gesetzt und im Chat bestätigt. Kein unabhängiger API-Readback.
- **PROD-Web-Deploy:** Nutzer hat den GitHub-Actions-Workflow „Deploy PROD“ erfolgreich ausgeführt und bestätigt.
- **End-to-End-Verifikation:** Nutzer hat danach den vollständigen Standard-Einladungsablauf über die PROD-Oberfläche (Einladung, E-Mail, Link, Passwortvergabe, Anmeldung) erfolgreich getestet und bestätigt. Keine unabhängige Einsicht in das neu angelegte Konto.
- **Datenbankumfang:** Keine SQL-Migration, keine Tabellen-/Daten-/RLS-/RPC-/Trigger-Änderung und keine Änderung von Supabase-Secrets im Rahmen dieses Arbeitsschritts.
- **Offene optionale Randfälle:** Ablehnung einer zweiten Mannschaftszuordnung bei erneuter Einladung, CORS-Ablehnung einer nicht erlaubten Origin und erneute Einladung eines bereits bestätigten Benutzers. Der Standardablauf ist abgeschlossen; diese optionalen Tests dürfen nicht mit einem offenen Standardablauf verwechselt werden.
- **PROD-Gegenstück:** Dies ist der PROD-Nachweis; DEV ist separat in SUPA-2026-001 und AP05 dokumentiert.
