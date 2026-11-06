# AP05 – Mitgliedereinladung: DEV-Domainanpassung und PROD-Bereitstellung

**Änderungsdatum:** 05.11.2026  
**Testabschluss:** 06.11.2026  
**Umgebung:** Supabase DEV und PROD  
**Edge Function:** `invite-member`  
**Status:** DEV Version 5 und PROD Version 1 bereitgestellt; DEV-Standardablauf erfolgreich getestet; PROD-End-to-End-Test nach Website-Deploy offen.

## Ziel

Die Einladungsfunktion soll von der neuen DEV-App-Domain `https://dev.kadassist.de` aus aufrufbar sein. Einladungslinks für Benutzer in DEV sollen ebenfalls auf diese Domain führen. PROD bleibt von dieser Änderung unberührt.

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
| PROD (`qdugtpzgefpswnnqbusd`) | `https://bautnhaus.github.io/jugendmannschaft/` (unverändert im DEV-Funktionsquelltext) |

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

Dieser Abschnitt dokumentiert die ursprüngliche DEV-Anpassung vom 05.11.2026. Die danach erfolgte PROD-Bereitstellung ist im ergänzten PROD-Abschnitt weiter unten dokumentiert.


## DEV-GitHub-Pages-Korrektur (05.11.2026)

Ursache: Die gemeinsame Quelle `develop` enthält `CNAME = kadassist.de`. Der DEV-Spiegelworkflow übertrug diesen Wert unverändert nach `jugendmannschaft-dev/main` und überschrieb dadurch die DEV-Domainzuordnung.

Korrektur: `.github/workflows/deploy-dev.yml` setzt vor dem Spiegeln `CNAME = dev.kadassist.de` und erstellt dafür einen temporären Commit. Der Quellbranch `develop` bleibt unverändert (`CNAME = kadassist.de`), damit PROD seine eigene Domain behält.

Technisch wirksamer Workflow-Commit: `a91f7fddadd76a974605eac794332859d27b7452`.
Erfolgreicher DEV-Lauf: `42097376832`.
Verifiziert: `jugendmannschaft-dev/main/CNAME` enthält `dev.kadassist.de`; `jugendmannschaft/develop/CNAME` bleibt `kadassist.de`. PROD wurde nicht geändert.

Hinweis: GitHub Pages Settings > Pages muss geprüft werden. Falls Custom domain noch leer ist, `dev.kadassist.de` dort eintragen und speichern.


---

## PROD-Erweiterung – Mitgliedereinladung (06.11.2026)

**Status:** Edge Functions in PROD bereitgestellt und technisch verifiziert. Der Web-Deploy auf die PROD-Website steht noch aus. Ein vollständiger End-to-End-Test über die PROD-Oberfläche ist deshalb noch offen.

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

### 6. PROD-Web-Deploy und noch ausstehende Tests

Der PROD-Web-Deploy wurde zum Stand dieser Dokumentation **noch nicht ausgeführt**. Der Nutzer führt ihn nach Abschluss der Dokumentation selbst aus.

Nach erfolgreichem Web-Deploy sind mindestens folgende Praxistests durchzuführen:

1. Trainer-Einladung aus `https://kadassist.de` auslösen.
2. Prüfen, ob die E-Mail eintrifft.
3. Einladungslink öffnen und sicherstellen, dass er auf `https://kadassist.de/` zurückführt.
4. Passwortvergabe und anschließende Anmeldung durchführen.
5. Prüfen, ob Name, Rolle, Verein und Mannschaft korrekt gespeichert wurden.
6. Prüfen, dass eine bereits bestehende Zuordnung zu einer anderen Mannschaft eine zweite Mannschaftszuordnung verhindert.
7. Optional: erneute Einladung eines bereits bestätigten Benutzers sowie CORS-Ablehnung einer nicht freigegebenen Origin prüfen.

**Wichtig:** Bis diese Tests erfolgreich abgeschlossen sind, gilt der PROD-Einladungsprozess als bereitgestellt, aber noch nicht vollständig im Frontend end-to-end abgenommen.

### 7. Rollback- und Betriebsgrenzen

- Keine automatische Rücksetzung der Edge Functions im Rahmen des Website-Deploys.
- Bei Problemen zuerst Fehlerbild und Logs prüfen; nicht pauschal auf ältere Funktionsversionen zurückrollen.
- `invite-trainer` bleibt stillgelegt. Eine Reaktivierung der alten Schreiblogik ist nicht vorgesehen.
- PROD-Daten, Rollen und RLS-Regeln wurden durch diese Funktionsbereitstellungen nicht verändert.
