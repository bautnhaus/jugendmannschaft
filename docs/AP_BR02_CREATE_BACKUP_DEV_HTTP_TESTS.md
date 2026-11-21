# AP-BR02 – DEV-HTTP-Testmatrix für create-backup

Stand: 21.11.2026  
Zielprojekt: Supabase DEV \`pzazqvvoruqnqhcorbwx\`  
Aktive Edge Function: \`create-backup\`, Version 2, \`verify_jwt=true\`

## Sicherheit und Durchführung

Diese Tests sind manuell mit einem eigenen DEV-Testkonto durchzuführen. JWTs niemals in GitHub, Chat, Screenshots oder Logs ablegen. Token nur lokal in einer temporären Shell-Variable verwenden und anschließend löschen. Keine produktiven Daten und keine PROD-URL verwenden.

Endpoint:
\`https://pzazqvvoruqnqhcorbwx.supabase.co/functions/v1/create-backup\`

## Negative Tests

| Fall | Request | Erwartung |
|---|---|---|
| Kein Authorization-Header | POST ohne Bearer | 401 (Gateway oder Function) |
| Ungültiger JWT | POST mit absichtlich ungültigem Token | 401 |
| Kein JSON / kaputtes JSON | gültiger JWT, Body nicht parsebar | 400 |
| Ungültiger Scope-Typ | \`scope_type: "other"\` | 400 |
| Keine UUID | \`scope_id: "abc"\` | 400 |
| Kategorien leer | \`categories: []\` | 400 |
| Kategorie unbekannt | \`categories: ["all"]\` | 400 |
| Kategorie doppelt | \`categories: ["team_core","team_core"]\` | 400 |
| Fremde Mannschaft | gültiger Benutzer, Team ohne Admin-/gewählten Superadmin-Kontext | 403 |
| Fremder Verein | gültiger Benutzer, Verein ohne Admin-/gewählten Superadmin-Kontext | 403 |

## Positiver Test – nur DEV

Mit einem autorisierten Teamadmin-Testkonto eine tatsächlich verwaltete Mannschaft und eine einzelne Kategorie (z. B. \`team_core\`) senden. Danach prüfen:
- HTTP 200 und \`status\` enthält weiterhin den Prototype-Hinweis
- \`scope.id\` entspricht exakt dem ausgewählten Team
- \`scope.team_ids\` enthält ausschließlich diese Mannschaft
- alle Datensätze sind auf den gewählten Scope begrenzt
- Snapshot-JSON ist syntaktisch parsebar und enthält keine Auth-/Membership-Tabellen
- keine Foto-/Storage-Bytes oder verschlüsseltes Archiv behauptet

Danach separat einen Superadmin-Test im explizit ausgewählten Teamkontext und Vereinskontext ausführen. Superadmin ohne ausgewählten Kontext muss 403 erhalten.

## Request-Muster (Token lokal einsetzen)

\`\`\`bash
export DEV_SUPABASE_URL="https://pzazqvvoruqnqhcorbwx.supabase.co"
read -s DEV_USER_JWT
curl -i -X POST "$DEV_SUPABASE_URL/functions/v1/create-backup" \\
  -H "Authorization: Bearer $DEV_USER_JWT" \\
  -H "Content-Type: application/json" \\
  --data '{"scope_type":"team","scope_id":"<DEV-TEAM-UUID>","categories":["team_core"]}'
unset DEV_USER_JWT
\`\`\`

\`<DEV-TEAM-UUID>\` vor Ausführung durch die tatsächliche DEV-Team-ID ersetzen. Nicht hier oder in Git eintragen.

## Freigabekriterien

Die Function ist erst nach erfolgreicher negativer und positiver Matrix für eine UI-Anbindung bereit. Selbst danach bleibt sie ein Snapshot-Prototyp, bis Storage-Inhalte, Archivverschlüsselung und Integritätsprüfung umgesetzt und abgenommen sind. Restore ist nicht Teil dieses Tests.
