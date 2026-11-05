# AP05 – DEV-Domainanpassung der Mitgliedereinladung

**Datum:** 05.11.2026  
**Umgebung:** Supabase DEV  
**Edge Function:** `invite-member`  
**Status:** Version 5 veröffentlicht; Funktionstests nach Veröffentlichung noch ausstehend.

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

## Noch ausstehende DEV-Praxistests

Die Veröffentlichung ist bestätigt. Folgende Funktionstests müssen noch durchgeführt werden; sie gelten nicht allein durch das Deployment als bestanden:

1. Einladung eines neuen Trainers über `https://dev.kadassist.de`.
2. Prüfen, dass der Einladungslink auf die neue DEV-Domain führt.
3. Einladung abschließen und Name sowie Rollen-/Mitgliedschaftsdaten kontrollieren.
4. Erneute Einladung eines Benutzers mit bereits bestehender Mannschaftszuordnung prüfen; die zweite Mannschaftszuordnung muss abgewiesen werden.
5. CORS-Verhalten für eine nicht freigegebene Origin prüfen.
6. Optional prüfen, dass die alte GitHub-Pages-Origin während der Übergangsphase weiterhin funktioniert.

## Rollback-Hinweis

Bei Problemen kann die vorherige Version 4 der Funktion als Referenz wiederhergestellt werden. Vor einem Rollback ist zu prüfen, ob dadurch die neue Domain wieder aus CORS und Einladungsweiterleitung entfernt würde. Ein Rollback darf nur nach gesonderter Abstimmung erfolgen.

## Geltungsbereich

Diese Dokumentation beschreibt ausschließlich die DEV-Anpassung vom 05.11.2026. Eine entsprechende Änderung in PROD ist **nicht** erfolgt und benötigt eine separate Prüfung und ausdrückliche Freigabe.
