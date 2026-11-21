# AP-BR02 – Übergabe / aktueller Arbeitscheckpoint

Stand: 21.11.2026
Repo: bautnhaus/jugendmannschaft
Branch: develop
Supabase DEV: pzazqvvoruqnqhcorbwx
Supabase PROD: qdugtpzgefpswnnqbusd

Dieses Dokument ist der Startpunkt für einen Chatwechsel. Bitte fachliche Entscheidungen nicht erneut abfragen und erledigte Prüfungen nicht wiederholen.

## Verbindliche Entscheidungen
- Modell B: Backup nur für Rolle und ausdrücklich ausgewählten Kontext/Umfang; serverseitige Prüfung vor Daten-/Datei-Export; Restore prüft Rolle, Zielkontext und Umfang erneut.
- Superadmin: Verein oder Mannschaft im ausdrücklich gewählten Kontext.
- Vereinsadmin: eigener Verein, Umfang explizit auswählen.
- Mannschaftsadmin: eigene Mannschaft, Umfang explizit auswählen.
- Restore-Regeln: Merge fehlender zulässiger Datensätze; Never-delete vorhandene Datensätze, die im Backup fehlen; Newer-wins bei Konflikten.
- Fachliche Historie einbeziehen; technische Audit-Tabellen nicht automatisch exportieren.

## Bereits erledigt – nicht wiederholen
- Feld-für-Feld-Inventur und fachliche Abstimmung aus vorherigem Chat abgeschlossen.
- DEV-Schemaabgleich der Exportspalten: keine fehlenden Tabellen/Spalten.
- Edge Function create-backup auf develop korrigiert und in DEV als Version 2 deployed; ACTIVE, verify_jwt=true.
- Korrekturen: 500er-Pagination, Recommendation-Players nach Run-ID, Service-Role-JWT-Client, no-store.
- Rollen-RPCs is_team_admin und can_manage_club_context read-only geprüft.
- HTTP-Testmatrix dokumentiert; echte Requests scheiterten aus der Tool-Umgebung an DNS, kein Supabase-Statuscode empfangen. Positivtest braucht DEV-Testkonto.

## Aktueller Funktionsstand
create-backup liefert einen JSON-DB-Snapshot-Prototyp. Storage-Datei-Bytes, verschlüsseltes Archiv und finaler Download-Workflow fehlen. Noch nicht UI-verbinden oder als vollständiges Backup bezeichnen.

## Storage-Inventur DEV (21.11.2026, read-only)
- player-photos: privat, 2 Objekte; 2 exakte Matches zu players.photo_path.
- profile-avatars: privat, 4 Objekte; profiles.avatar_url hat jetzt 2 Referenzen, beide matchen; 2 Objekte sind unreferenziert.
- club-assets: privat, 1 Objekt; exaktes Match zu clubs.crest_path.
- Alle Buckets: 2 MiB, JPEG/PNG/WebP.
Die historische IMG-SEC-Inventur vom 19.11. meldete 0 Avatarreferenzen; das war damaliger Snapshot, nicht der aktuelle Bestand. Keine Storage-Datei verändert oder gelöscht. Details in docs/AP_BR02_BACKUP_EXPORT_INVENTORY_REVIEW_2026-11-21.md Abschnitt 19.

## Nächste Schritte
1. Datei-Backup-Spezifikation: Scope-/Kategorie-Mapping, nur referenzierte Objekte, Orphans dokumentieren und nicht löschen, serverseitiger Download-Allowlist.
2. Archivformat, Verschlüsselung, Schlüssel-/Passwortübergabe, SHA-256-Manifest und Fehlerbehandlung definieren; noch nicht fachlich final beschlossen.
3. Datei-Bytes in begrenztem DEV-Test sicher laden.
4. Paketierung implementieren und DEV testen.
5. HTTP-Auth-/Scope-Negativtests und positiver Snapshot-/Dateitest mit autorisiertem DEV-Konto.
6. Danach UI-Umfangsauswahl/Download vorbereiten; Restore erst nach Backup-Abnahme.

## Arbeitsgrenzen
- Nur develop und Supabase DEV.
- Keine SQL-/DB-/Storage-Schreiboperation, Migration oder PROD-Änderung ohne separate Freigabe.
- Keine Tokens/Secrets in Chat, Git oder Logs.
- Service-Role umgeht RLS; jeder Datei-Download muss über serverseitige Scope-/DB-Referenz-Allowlist laufen.
- Keine automatische Löschung von Orphan-Dateien.
- Bei Chatwechsel dieses Dokument und AP-BR02-Inventory-Review zuerst lesen; nicht von vorn inventarisieren.

## Dokumentationscommits
- e484243 – HTTP-Testgrenze dokumentiert.
- ce4455722e5bf534b0364739d9a2c359da01bc1e – aktuelle Storage-Inventur ergänzt.


## Nachtrag 21.11.2026 – Storage-Entwurf

- Aktuelle Inventur ergänzt: Commit ce4455722e5bf534b0364739d9a2c359da01bc1e.
- Übergabecheckpoint angelegt: Commit 1aa6dd4753ddcf551c37460629ac509d7c770504.
- Storage-/Archiv-Entwurf erstellt: docs/AP_BR02_STORAGE_ARCHIVE_DESIGN_DRAFT_2026-11-21.md, Commit 87dd806e944bfeb8c67982c4dfd152901c960c7a.
- Der Entwurf schlägt eine strikt DB-referenzierte Objekt-Allowlist, Orphan-Ausschluss ohne Löschung, Asset-Scope nach Team/Verein und SHA-256-Dateimanifest vor.
- ZIP-/Archivbibliothek, Verschlüsselungsformat und Schlüsselübergabe sind noch offene fachlich-technische Entscheidungen; kein Code oder Deployment wurde dafür geändert.
- Nächster Schritt: Entwurf mit den vorhandenen Anforderungen vervollständigen und die offene Paket-/Verschlüsselungsentscheidung treffen, dann Implementierung in DEV vorbereiten.


## Nachtrag 21.11.2026 – Paket-/Verschlüsselungsarchitektur

- Technischen Vorschlag in docs/AP_BR02_STORAGE_ARCHIVE_DESIGN_DRAFT_2026-11-21.md, Abschnitt 8 ergänzt (Commit bb2cf40b95654eb9de3b28333637741d2414d531).
- Empfehlung: Edge Function bleibt bei Auth/Scope/Manifest; Browser übernimmt begrenzte ZIP-Paketierung und clientseitige Passwortverschlüsselung; keine Passwörter/Secrets serverseitig speichern.
- Crypto-Vorschlag: Web Crypto PBKDF2-HMAC-SHA-256 + AES-256-GCM, zufälliger Salt und eindeutiger IV; genaue Bibliothek/Containerformat noch zu prüfen.
- Mobile RAM-Risiko dokumentiert; maximale Größe muss auf iPhone/Safari gemessen werden. Keine unverschlüsselte Fallback-Datei.
- Offen und nicht entschieden: clientseitiges Passwortmodell, ZIP-AES vs. versionierter GCM-Container, maximaler Exportumfang. Keine Implementierung/DB-/Storage-/Deploymentänderung.
- Nächster Schritt: diese drei Entscheidungen fachlich bestätigen und anschließend Bibliotheks-/iOS-Kompatibilität prüfen; danach einen kleinen DEV-Prototyp ohne Restore bauen.


## Nachtrag 21.11.2026 – Bibliotheksrecherche

- zip.js (@zip.js/zip.js) als Kandidat für ZIP-AES-256 / ZIP AE-2 und Web-Streams recherchiert; Paketversion 2.24.0 in aktueller Paketmetadatenquelle, vor Integration pinnen/verifizieren.
- fflate unterstützt ZIP/DEFLATE, aber keine ZIP-Verschlüsselung; daher nicht allein für Backup-Verschlüsselung verwenden.
- Vorläufige technische Empfehlung: ZIP-AES-256 mit etablierter zip.js-Implementierung, keine eigene Kryptografie und kein zusätzliches AES-GCM-Containerlayer. Das ist noch keine fachliche Nutzerfreigabe.
- iOS/Safari-Risiko bestätigt: Web Streams/TransformStream sowie temporärer Speicher sind zu testen; zip.js weist bei Blob-Temp-Stream unter Safari auf hohen Spitzen-RAM (mehrere Kopien) hin. OPFS-/Worker-Ansatz prüfen; keine Größenbegrenzung geraten.
- Recherche-/Dokumentationscommit: 862a0dd16eb2d0cb080917ae847357cd8043bcc6.
- Nächster Schritt: vorhandene index.html / Build- und Modulstruktur read-only prüfen, ob zip.js als lokal gepinnte ESM-Abhängigkeit sauber integriert werden kann. Erst danach kleinen isolierten DEV-Prototyp planen; keine PROD-/DB-/Storage-Änderung.


## Nachtrag – Projektintegration zip.js (21.11.2026)

- Read-only Strukturprüfung: index.html ist statische Einzelseite mit großem ESM-Block; nur bisheriger CDN-Import für Supabase JS.
- Kein package.json, package-lock, Bundler oder npm-Build. GitHub Pages/DEV-Workflow deployt Branch-Inhalt ohne Build; develop push synchronisiert automatisch in das separate DEV-Repository.
- Service Worker cached aktuell nur HTML/Manifest. Kein neues Vendor-Asset und keine Cache-Regel hinzugefügt.
- Empfehlung: zip.js exakt versioniert lokal im Repo (Distribution + Lizenz + SHA-256 + Upstream/Version dokumentieren), Backup-Export lazy-loaden und App-Start entkoppeln. Erst Distribution/Worker/WASM-Pfade untersuchen, dann isolierter Test-HTML mit synthetischen Daten.
- npm-Suchstand 21.11. meldet 2.25.0; ältere 2.24.0-Angabe im Abschnitt 9 wurde korrigiert/eingeordnet. Kein Paket importiert oder Code geändert.
- Design-Dokument Commit: 0b83f9629259a6e28cddf359f36169fc689db43c.
- Nächster Schritt: offizielle zip.js Distribution, erforderliche worker/WASM-Assets und Lizenz-/Hash-Handling read-only prüfen; danach den isolierten DEV-Testartefakt vorbereiten.


## Nachtrag – ZIP.js Distribution und Testaufbau

- Offizielle API/Distribution recherchiert: zip.js 2.25.0, WinZIP AES / AE-2, ZipWriter API und OPFS temp streams. Safari-Blob-Temp-Stream vermeiden (dokumentierter peak RAM ungefähr 4x Entry); SyncAccessHandle nur im Dedicated Worker.
- Distribution benötigt Prüfung der zugehörigen Worker-/WASM-Dateien und relativen URL-Pfade; kein Bundle bisher ins Repo übernommen.
- Design-Abschnitt 11 mit Prototypentscheidung ergänzt; Commit dd10dd62c9a160a480f40e9e9d144565e29e6101.
- Nächster konkreter Arbeitsschritt: exakte zip.js Distribution und Lizenzdatei lokal vendorn, SHA-256 festhalten und separate Testseite mit synthetischen Daten anlegen. Noch nicht ausgeführt; keine Produktions-/App-Codeänderung.
