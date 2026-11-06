# AP05 – Mitgliedereinladung: DEV-Domainanpassung und PROD-Bereitstellung

**Änderungsdatum:** 05.11.2026  
**Testabschluss:** 06.11.2026  
**Umgebung:** Supabase DEV und PROD  
**Edge Function:** `invite-member`  
**Status:** DEV Version 5 und PROD Version 1 bereitgestellt; DEV- und PROD-Standardablauf erfolgreich getestet; PROD-Web-Deploy und Einladungstest vom Nutzer bestätigt.

## Ziel

Die Einladungsfunktion ist für DEV und PROD jeweils domain- und projektbezogen konfiguriert. DEV verwendet `https://dev.kadassist.de`, PROD verwendet `https://kadassist.de`. Die produktiven Änderungen sind in Abschnitt „PROD-Erweiterung“ dokumentiert.

## Durchgeführte Änderung

### 1. CORS

Die Funktion verwendet jetzt eine explizite Origin-Allowlist:

- `https://dev.kadassist.de` – neue DEV-Domain
- `https://bautnhaus.github.io` – bisheriger Origin bleibt während der Übergangsphase zugelassen

Der CORS-Header `Access-Control-Allow-Origin` wird nur für eine exakt freigegebene Origin zurückgegeben. Zusätzlich wird `Vary: Origin` gesetzt. Nicht freigegebene Origins erhalten keine CORS-Freigabe.

### 2. Einladungsweiterleitung

Die projektbezogene Redirect-Zuordnung lautet:

| Supabase-Projekt | Redirect URL |
|---|---|
| DEV (`pzazqvvoruqnqhcorbwx`) | `https://dev.kadassist.de/` |
| PROD (`qdugtpzgefpswnnqbusd`) | `https://kadassist.de/` (eigener PROD-Quelltext; siehe unten) |

Die DEV-Auth-URL-Konfiguration wurde separat angepasst:

- **Site URL:** `https://dev.kadassist.de/`
- **Redirect URLs:** `https://dev.kadassist.de/` ergänzt
- Bisherige GitHub-Pages-Redirect-URL bleibt vorerst erhalten.

### 3. Unveränderte Sicherheits- und Fachlogik

- JWT-Verifikation bleibt aktiviert (`verify_jwt = true`).
- Authentifizierung des aufrufenden Benutzers bleibt bestehen.
- Berechtigungsprüfungen für Vereins- und Mannschaftskontext bleiben bestehen.
- Prüfung bestehender Vereins- und Mannschaftszuordnungen bleibt bestehen.
- Die zentrale Datenbank-RPC `admin_complete_member_invitation` bleibt unverändert.
- Es wurden keine Datenbankobjekte, RLS-Policies oder PROD-Funktionen geändert.
- Es wurden keine Supabase-Secrets geändert oder ausgegeben.

## Deployment-Nachweis

- Supabase-Projekt: DEV (`pzazqvvoruqnqhcorbwx`)
- Funktion: `invite-member`
- Vorherige Version: 4
- Veröffentlichte Version: **5**
- Status laut Deployment-Antwort: `ACTIVE`
- `verify_jwt`: `true`
- SHA-256 des veröffentlichten Quellcodes: `4746862f9dd3d214acb778b6cb7b2c5f1b1028f0a303672e12b3835f8e8904b0`

## DEV-Praxistest – Ergebnis vom 06.11.2026

Der Nutzer hat den vollständigen Einladungsablauf in DEV praktisch getestet und bestätigt:

| Prüfschritt | Ergebnis |
|---|---|
| Einladung eines neuen Trainers über `https://dev.kadassist.de` auslösen | Bestanden |
| Einladungs-E-Mail erhalten | Bestanden |
| Einladungslink öffnen | Bestanden |
| Rückkehr auf `https://dev.kadassist.de` | Bestanden |
| Passwortvergabe durchführen | Bestanden |
| Anmeldung mit dem neuen Trainerkonto | Bestanden |
| Name korrekt gespeichert | Bestanden |
| Vorgesehene Rolle korrekt zugewiesen | Bestanden |
| Mannschaftszuordnung korrekt | Bestanden |

**Ergebnis:** Der grundlegende Einladungs- und Registrierungsprozess über die neue DEV-Domain funktioniert.

### Noch nicht separat geprüfte Randfälle

1. Erneute Einladung eines Benutzers mit bereits bestehender Mannschaftszuordnung; die zweite Mannschaftszuordnung muss abgewiesen werden.
2. CORS-Verhalten bei einer nicht freigegebenen Origin.
3. Optional: Kompatibilität der alten GitHub-Pages-Origin während der Übergangsphase.

Diese Randfälle sind nicht Bestandteil des oben bestätigten erfolgreichen Standardablaufs und bleiben offen.

## Rollback-Hinweis

Bei Problemen kann die vorherige Version 4 der Funktion als Referenz wiederhergestellt werden. Vor einem Rollback ist zu prüfen, ob dadurch die neue Domain wieder aus CORS und Einladungsweiterleitung entfernt würde. Ein Rollback darf nur nach gesonderter Abstimmung erfolgen.

## Geltungsbereich

Dieser Abschnitt dokumentiert die ursprüngliche DEV-Anpassung vom 05.11.2026. Die danach erfolgte PROD-Bereitstellung ist im ergänzten PROD-Abschnitt weiter unten dokumentiert. Aussagen zu PROD, die hier ausdrücklich als unverändert oder nicht betroffen bezeichnet werden, beziehen sich ausschließlich auf den damaligen DEV-Änderungsschritt und nicht auf den späteren PROD-Cutover.


## DEV-GitHub-Pages-Korrektur (05.11.2026)

Ursache: Die gemeinsame Quelle `develop` enthält `CNAME = kadassist.de`. Der DEV-Spiegelworkflow übertrug diesen Wert unverändert nach `jugendmannschaft-dev/main` und überschrieb dadurch die DEV-Domainzuordnung.

Korrektur: `.github/workflows/deploy-dev.yml` setzt vor dem Spiegeln `CNAME = dev.kadassist.de` und erstellt dafür einen temporären Commit. Der Quellbranch `develop` bleibt unverändert (`CNAME = kadassist.de`), damit PROD seine eigene Domain behält.

Technisch wirksamer Workflow-Commit: `a91f7fddadd76a974605eac794332859d27b7452`.
Erfolgreicher DEV-Lauf: `42097376832`.
Verifiziert: `jugendmannschaft-dev/main/CNAME` enthält `dev.kadassist.de`; `jugendmannschaft/develop/CNAME` bleibt `kadassist.de`. PROD wurde nicht geändert.

Hinweis: GitHub Pages Settings > Pages muss geprüft werden. Falls Custom domain noch leer ist, `dev.kadassist.de` dort eintragen und speichern.


---

## PROD-Erweiterung – Mitgliedereinladung (06.11.2026)

**Status:** Edge Functions und Web-App in PROD bereitgestellt. Der Nutzer hat den vollständigen PROD-Einladungsablauf nach dem Web-Deploy erfolgreich durchgeführt und bestätigt.

### 1. PROD-spezifischer Quelltext

Für PROD wird ein eigener Quelltext verwendet:

- Datei: `supabase/functions/invite-member-prod/index.ts`
- Quellbasis: DEV `invite-member` Version 5
- Git-Commit mit PROD-Variante: `0fd6bab357cbb31e8715d745b672f4091e5ca658`
- PROD-Origin-Allowlist: ausschließlich `https://kadassist.de`
- Projektbezogene Weiterleitung: PROD-Projekt `qdugtpzgefpswnnqbusd` → `https://kadassist.de/`
- DEV- und GitHub-Pages-Origins bzw. -Weiterleitungen sind in dieser PROD-Variante nicht freigegeben.
- JWT-Verifikation: aktiviert (`verify_jwt = true`)

Die fachliche Einladungslogik basiert auf der getesteten DEV-Version 5. Die Domain- und Redirect-Konfiguration ist bewusst auf PROD begrenzt.

### 2. Deployment-Nachweis – PROD `invite-member`

- Supabase-Projekt: PROD (`qdugtpzgefpswnnqbusd`)
- Funktion: `invite-member`
- Bereitgestellte Version: **1**
- Status nach Deployment-Prüfung: **ACTIVE**
- `verify_jwt`: `true`
- Deployment erfolgte nach ausdrücklicher Freigabe.
- Der bereitgestellte PROD-Quelltext liegt unter `supabase/functions/invite-member-prod/index.ts`.

### 3. Stilllegung der alten Funktion `invite-trainer`

Die bisherige Funktion `invite-trainer` ist nicht mehr für Einladungen zu verwenden. Die zentrale Einladung läuft ausschließlich über `invite-member`.

PROD-Nachweis:

- Supabase-Projekt: PROD (`qdugtpzgefpswnnqbusd`)
- Funktion: `invite-trainer`
- Bereitgestellte Version: **3**
- Status nach Deployment-Prüfung: **ACTIVE**
- `verify_jwt`: `true`
- Verhalten: OPTIONS-Preflight wird beantwortet; andere Aufrufe liefern HTTP **410 Gone** mit Verweis auf `invite-member`.
- Die frühere direkte Schreiblogik dieser Legacy-Funktion ist damit nicht mehr aktiv.

Die DEV-Funktion `invite-trainer` liefert ebenfalls HTTP 410, verwendet dort aber die DEV-/Alt-Domain-CORS-Konfiguration. Die PROD-Konfiguration ist eigenständig.

### 4. Supabase Auth – PROD-URL-Konfiguration

Der Nutzer hat die PROD-Auth-Konfiguration im Supabase-Dashboard angepasst und anschließend bestätigt:

- Site URL: `https://kadassist.de`
- Redirect URL: `https://kadassist.de/`

**Nachweisstatus:** vom Nutzer im Dashboard vorgenommen und im Chat bestätigt; nicht durch einen separaten API-/Dashboard-Readback technisch ausgelesen.

### 5. Datenbank- und Sicherheitsumfang

Im Rahmen dieser Edge-Function-Bereitstellungen wurden keine SQL-Migrationen ausgeführt und keine Datenbankobjekte geändert.

Insbesondere wurden in diesem Arbeitsschritt nicht geändert:

- Tabellen oder Daten
- RLS-Policies
- Datenbankfunktionen/RPCs
- Trigger
- Supabase-Secrets

Die PROD-Funktion ruft weiterhin die vorhandene RPC `admin_complete_member_invitation` auf. Die tatsächliche Verfügbarkeit und das Verhalten dieser RPC werden nicht durch das Edge-Function-Deployment neu hergestellt oder verändert.

Daher ist für diese Bereitstellungen kein neuer Eintrag im SQL-Migrationsprotokoll und kein Datenbank-Changelog-Eintrag erforderlich.

### 6. PROD-Web-Deploy und End-to-End-Test

Der Nutzer hat den PROD-Web-Deploy über GitHub Actions selbst ausgeführt und dessen erfolgreichen Abschluss am 06.11.2026 im Chat bestätigt. Anschließend hat der Nutzer auch den vollständigen Einladungsablauf über die PROD-Oberfläche erfolgreich getestet und bestätigt.

| Prüfschritt | Ergebnis |
|---|---|
| Trainer-Einladung aus `https://kadassist.de` auslösen | Vom Nutzer als erfolgreich bestätigt |
| Einladungs-E-Mail erhalten | Vom Nutzer als erfolgreich bestätigt |
| Einladungslink öffnen und Rückkehr auf `https://kadassist.de/` | Vom Nutzer als erfolgreich bestätigt |
| Passwortvergabe und anschließende Anmeldung | Vom Nutzer als erfolgreich bestätigt |
| Einladungsvorgang über die PROD-Oberfläche abschließen | Vom Nutzer als erfolgreich bestätigt |

**Nachweisgrenze:** Die Ergebnisse beruhen auf der praktischen Durchführung und Bestätigung durch den Nutzer. Ein unabhängiger technischer Readback des GitHub-Actions-Laufs oder eine Einsicht in das neu angelegte Konto wurde nicht vorgenommen.

### Noch offene optionale Randfalltests

1. Erneute Einladung eines Benutzers mit bereits bestehender Mannschaftszuordnung; eine zweite Mannschaftszuordnung muss abgewiesen werden.
2. CORS-Ablehnung einer nicht freigegebenen Origin.
3. Erneute Einladung eines bereits bestätigten Benutzers.

Diese Randfälle sind keine Voraussetzung für die dokumentierte erfolgreiche Standardabnahme. Sie bleiben als separate Prüfungen offen.

### 7. Rollback- und Betriebsgrenzen

- Keine automatische Rücksetzung der Edge Functions im Rahmen des Website-Deploys.
- Bei Problemen zuerst Fehlerbild und Logs prüfen; nicht pauschal auf ältere Funktionsversionen zurückrollen.
- `invite-trainer` bleibt stillgelegt. Eine Reaktivierung der alten Schreiblogik ist nicht vorgesehen.
- PROD-Daten, Rollen und RLS-Regeln wurden durch diese Funktionsbereitstellungen nicht verändert.


## Aktueller Abschlussstatus und Referenz (06.11.2026)

- DEV `invite-member`: Version 5 ACTIVE, `verify_jwt=true`; Standard-Einladungsablauf vom Nutzer erfolgreich getestet.
- PROD `invite-member`: Version 1 ACTIVE, `verify_jwt=true`; eigener PROD-Quelltext mit ausschließlich `https://kadassist.de` als erlaubter Origin und PROD-Redirect.
- PROD `invite-trainer`: Version 3 ACTIVE, `verify_jwt=true`; Legacy-Endpunkt beantwortet Nicht-OPTIONS-Aufrufe mit HTTP 410 und verweist auf `invite-member`.
- Der GitHub-Actions-Workflow „Deploy PROD“ wurde vom Nutzer nach den Änderungen ausgeführt; der vollständige PROD-Einladungsablauf wurde anschließend vom Nutzer erfolgreich bestätigt.
- Am 06.11.2026 wurde `main` gegen `develop` verglichen. Ergebnis: `identical`, 0 Commits voraus/zurück, keine abweichenden Dateien. Beide Branches standen auf `dd0cd8f405673e488ed20c2daf724d2583f7be0d`.
- Nach der jetzt folgenden Dokumentationsaktualisierung auf `develop` entsteht erwartungsgemäß wieder ein temporärer Dokumentationsvorsprung von `develop`. Ein erneuter regulärer PROD-Deploy ist erforderlich, wenn `main` wieder identisch sein soll.

Die Standardabläufe gelten als abgeschlossen. Die optionalen Randfalltests aus Abschnitt 6 bleiben separat offen; sie sind kein Anlass, den erfolgreichen Standardablauf erneut zu testen.
