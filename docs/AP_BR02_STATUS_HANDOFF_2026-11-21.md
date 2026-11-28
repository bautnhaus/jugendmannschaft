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


## Aktueller Chatcheckpoint – ZIP.js-Testartefakt angelegt

- Upstream release/tag geprüft: zip.js v2.25.0; offizielle standalone `dist/zip.min.js` und BSD-3-Clause-Lizenz aus exakt diesem Tag übernommen.
- Dateien auf develop: `vendor/zipjs/2.25.0/zip.min.js`, `LICENSE`, `PROVENANCE.md`.
- Provenienz enthält Upstream-Git-Blob-SHA-1 `3eb3136ea6e6699188f89f8c431b10b6b435756f`; SHA-1 nicht mit SHA-256 verwechseln. SHA-256 wurde nicht berechnet.
- Standalone zip.min.js enthält Worker und WASM laut Upstream dist README; separate Ressourcen nicht nötig für diese Variante.
- Synthetische Testseite: `docs/dev-tests/ap-br02-zipjs-test.html`, nicht in App-Menü; keine Supabase-/Userdaten. Browser-Test erzeugt AES-256 ZIP, entschlüsselt den synthetischen Inhalt lokal und ermöglicht Download.
- Code-/Asset-Commit: `9189d10538386bfdf350a08c6e02add8d94a6023`. Dokumentation folgt mit eigenem Commit.
- Noch NICHT ausgeführt/abgenommen: Test auf tatsächlichem iPhone Safari/DEV-URL, Öffnen in unabhängiger Archiv-App, falsches Passwort/korruptes Archiv, Speicher-/Laufzeitmessung. Die Testseite ist ein Prüfartefakt, noch keine Backup-Funktion.
- DEV deploy/sync ist durch develop-Commit ausgelöst; PROD/main unverändert. Keine DB-/Storage-Operation, kein Restore.
- Nächster Schritt: DEV-Deploy prüfen und Nutzer auf iPhone die isolierte Testseite öffnen lassen; konkrete Ergebnisse in diesem Checkpoint ergänzen. Danach Fehler beheben und Größen-/RAM-Grenze anhand realer Messung festlegen.


## Deployment-Verifikation – isolierter ZIP.js-Test (21.11.2026)

- GitHub Actions Run `44950194219` (Deploy DEV) für Commit `f341124121ddd67ae48ceea7413677dcf161b853`: completed / success.
- Im Zielrepository `bautnhaus/jugendmannschaft-dev`, Branch `main`, read-only verifiziert: Testseite vorhanden und Vendor-Datei vorhanden. Vendor Git blob SHA entspricht exakt Upstream v2.25.0 Distribution (`3eb3136ea6e6699188f89f8c431b10b6b435756f`).
- Test URL: `https://dev.kadassist.de/docs/dev-tests/ap-br02-zipjs-test.html`.
- Die Seite muss vom Nutzer auf einem echten iPhone in Safari aufgerufen werden. Beim Klick den Testpasswortwert nur lokal eingeben, ZIP-Rundlauf ausführen und Datei herunterladen; Testpasswort nicht an Chat/Server schicken. Anschließend ZIP mit einer unabhängigen Archiv-App öffnen und die falsches-Passwort-Prüfung manuell ergänzen.
- Deployment bestätigt, aber **Browser-/iPhone-Test noch nicht bestätigt**. Bitte Testergebnis erst nach tatsächlicher Ausführung als bestanden markieren.


## Nutzerbestätigung – ZIP-AES-Grundtest erfolgreich (22.11.2026)

- Nutzer hat bestätigt: „Hat alles geklappt.“ Damit gilt der auf der DEV-Testseite ausgeführte ZIP-AES-Grundrundlauf samt Download als erfolgreich.
- Status: ZIP.js 2.25.0 Distribution erfolgreich bereitgestellt; synthetischer ZIP-AES-Test auf DEV vom Nutzer erfolgreich bestätigt.
- Diese Bestätigung deckt den Grundtest ab. Sie belegt noch keine belastbare Speicher-/Laufzeitmessung für größere Archive, keine Maximalgröße und keinen produktiven Backup-Export.
- Weiter offen: kontrollierter iPhone-/Safari-Speicher- und Laufzeittest mit stufenweise größeren synthetischen Testpaketen; falsches Passwort/defektes Archiv separat validieren, sofern dies nicht bereits Teil des vom Nutzer bestätigten Testablaufs war; danach die getestete Größen-/Objektgrenze festlegen.
- Kein weiterer Code-/DB-/Storage-/PROD-Eingriff durch diese Statusaktualisierung.


## Ergebnis – synthetischer iPhone-Größen-/ZIP-Rundlauftest (22.11.2026)

- Nutzer bestätigt: alle vier Stufen (1, 5, 10 und 20 MiB) liefen erfolgreich; Safari blieb stabil; Downloads funktionierten.
- Damit ist der einfache Praxistest auf dem verwendeten iPhone bis einschließlich 20 MiB bestanden.
- Es wurden keine Laufzeit-, ZIP-Größen- oder RAM-Messwerte festgehalten; diese werden nicht nachträglich geschätzt oder behauptet.
- Aussagegrenze: Der Test ist ein erfolgreicher synthetischer Browser-Smoke-Test mit Blob-basierter Verarbeitung. Er misst weder den realen RAM-Verbrauch noch validiert er bereits eine streaming-/OPFS-basierte Produktionsarchitektur. Aus 20 MiB wird deshalb kein endgültiges Backupgrößenlimit abgeleitet.
- Nächster technischer Schritt: Architekturprüfung/Prototyp für speicherschonenden Export (Safari/iOS, ZIP.js, OPFS/Worker) durchführen; Nutzer muss keine technischen Messwerte dokumentieren.
- DEV-Testseite: `docs/dev-tests/ap-br02-zipjs-test.html`; letzter Testcode-Commit: `7f3a077f92bdc7ac3d72af1bf55f725ad084fcce`.
- Keine DB-/Storage-/PROD-Änderung im Rahmen dieses Tests.



## Bestandsabgleich – vorhandener Prototyp statt Neuaufbau (22.11.2026)

Read-only-Abgleich von develop `index.html`, Dokumentation und aktiver DEV-Edge-Function `create-backup`:

### Bereits vorhanden / wird nicht neu gebaut
- Der clientseitige JSON-Snapshot `buildBackupSnapshot()` und Download `exportJSON()` bestehen weiterhin; dieser ist ein historischer Prototyp und greift direkt über den Supabase-Client auf Tabellen zu.
- Eine serverseitige Edge Function `create-backup` ist in Supabase DEV aktiv (Version 2, `verify_jwt=true`). Sie authentifiziert den Nutzer, validiert Scope/Kategorien, ruft bestehende Rollen-RPCs auf und liest die ausgewählten Tabellen mit serverseitig begrenzten Team-/Parent-IDs sowie Pagination.
- Tabellen-/Feldinventur und Rollen-RPC-Prüfung sind bereits abgeschlossen; nicht wiederholen.
- ZIP.js 2.25.0 liegt lokal im Repo, isolierte Testseite und Nutzer-bestätigter iPhone-Test (1/5/10/20 MiB) sind erledigt.

### Tatsächliche Lücke, die den nächsten Schritt begründet
- Die sichtbare App-Funktion `exportJSON()` ruft noch `buildBackupSnapshot()` auf und nicht die Edge Function. Der neue serverseitige Snapshot ist daher Backend-Baustein, aber noch nicht der normale Exportablauf.
- Die aktive Edge Function gibt derzeit einen JSON-Snapshot zurück und markiert ausdrücklich `storage_and_encrypted_archive_not_included`. Storage-Bytes, verschlüsseltes Archiv und vollständiger Downloadablauf sind noch nicht verbunden.
- Der Restore `replaceTeamDataWithBackup()` löscht vor dem Einfügen vorhandene Teamdaten und ist damit nicht kompatibel mit den vereinbarten Regeln Merge / Never-delete / Newer-wins. Restore ist im Code noch vorhanden und destruktiv; er ist fachlich nicht als sichere Wiederherstellung freigegeben und darf bis zur späteren Überarbeitung nicht verwendet werden.

### Minimaler nächster Arbeitsumfang
1. Bestehende Edge Function und UI-Aufruf read-only technisch abgleichen; dann den App-Export auf den serverseitig autorisierten Snapshot umstellen – ohne erneute Inventur.
2. Storage-Objekte ausschließlich anhand der bereits ermittelten DB-Referenzen und Scope-Allowlist hinzufügen; Orphans ausschließen und nicht löschen.
3. ZIP.js als bereits getestete Paketierungsbasis verwenden; keine weitere allgemeine ZIP-/iPhone-Testschleife. Nur gezielte DEV-Verifikation des integrierten End-to-End-Exports.
4. Restore erst in einem separaten späteren Schritt nach Export-Abnahme nach Merge/Never-delete/Newer-wins neu konzipieren.

Keine Codeänderung, kein SQL, kein Storage-Schreibzugriff, keine erneute Deployment- oder PROD-Änderung durch diesen Bestandsabgleich.


## Aktueller UI-/Funktionsabgleich (22.11.2026)

Read-only-Prüfung von `develop/index.html` und der aktiven DEV-Edge-Function `create-backup`:

- Die vorhandene App-Backupkarte bietet aktuell nur den Button `JSON sichern` im Mannschafts-Adminbereich; keine explizite Auswahl der Backup-Kategorien und keine Auswahl zwischen Vereins- und Mannschaftsscope.
- Der App-Button ruft weiterhin `buildBackupSnapshot()` auf (clientseitiger JSON-Prototyp).
- Die Edge Function erwartet `scope_type`, `scope_id` und eine ausdrücklich übergebene Liste erlaubter Kategorien. Sie kann serverseitig Team- oder Clubberechtigung prüfen und liefert derzeit einen JSON-Snapshot, aber noch kein Archiv.
- Der bisherige Button darf nicht einfach auf diese Function umgestellt werden: Ein stillschweigend festgelegter Kategorienumfang würde der verbindlichen Umfangsauswahl widersprechen; zudem wäre der JSON-Snapshot ohne Storage-Dateien und Verschlüsselungsarchiv kein vollständiges Backup.

### Konsequenz / nächste konkrete Arbeit
Vor dem Umschalten des produktiven UI-Exportbuttons ist eine Auswahloberfläche erforderlich, die den gewählten Scope (Verein/Mannschaft, soweit für Rolle zulässig) und den Kategorienumfang explizit anzeigt und vom Nutzer auswählen lässt. Danach wird die bestehende DEV-Function an diese Auswahl angeschlossen. Bis das vollständige Paket bereitsteht, bleibt die vorhandene UI als Prototyp kenntlich und wird nicht als vollständiges Backup ausgegeben.

Keine App-Codeänderung oder Supabase-Deployment in dieser Prüfrunde; ausschließlich Abgleich und Dokumentation.


## Design-Workflow: Backup-Auswahloberfläche – Schema (22.11.2026)

Status: Schema zur fachlichen Prüfung; Low-Fidelity und High-Fidelity folgen erst nach Schema-Freigabe. Keine UI-/Codeänderung.

### Zweck
Vor dem Export transparent und explizit festlegen, welcher zulässige Kontext und welche Datenkategorien gesichert werden. Keine voreingestellte, unbemerkte Komplettauswahl.

### Struktur / Reihenfolge
1. **Sicherungsbereich** – Verein oder Mannschaft; nur Kontexte anzeigen/auswählen, die der aktuellen Rolle zugänglich sind. Superadmin wählt ausdrücklich Verein oder Mannschaft und den konkreten Kontext. Vereinsadmin: eigener Verein. Mannschaftsadmin: eigene Mannschaft.
2. **Datenumfang** – Kategorien als unabhängige Auswahl:
   - Mannschaft & Spieler (`team_core`)
   - Training & Anwesenheit (`training`)
   - Spieltage & Kader (`matchday`)
   - Saisonhistorie (`season_history`)
   - Sperren & Disziplinhistorie (`discipline_history`)
   Mindestens eine Kategorie muss ausgewählt sein; Auswahl wird an den bestehenden DEV-Endpoint als `categories` übergeben. Identitäts-/Rollen-/Mitgliedschaftstabellen bleiben außerhalb des normalen Backups.
3. **Dateien / Bilder** – tatsächliche Storage-Dateien sind noch nicht im Endpoint enthalten. Im Schema daher als transparenter, separat gekennzeichneter Umfangspunkt zu behandeln, nicht so darstellen, als wären sie bereits Bestandteil der Datenkategorien. Fachlich festzulegen ist im nächsten Designschritt, ob sie eine eigene Auswahl oder eine klar beschriebene Option bilden.
4. **Prüfen & Starten** – vor Start Zusammenfassung von Kontext und ausgewähltem Umfang; Start nur bei gültiger Auswahl. Während der Erstellung Status; Erfolg erst melden, wenn das vollständige Archiv bereitsteht. Fehler/fehlende referenzierte Dateien dürfen kein scheinbar vollständiges Backup erzeugen.

### Noch nicht Teil dieses Schemas
- Restore-Auswahl oder Restore-Aktion (Restore bleibt zurückgestellt).
- Passwortdialog und konkrete Verschlüsselungsdetails (separat zu gestalten, sobald Archivformat freigegeben).
- High-Fidelity-Farben, Icons, Abstände oder endgültige Komponentenauswahl.
- App-Code, Edge-Function-Änderung oder Deployment.

### Nächster Schritt
Nach fachlicher Freigabe dieses Schemas folgt Low-Fidelity als grober Bildschirm-/Interaktionsentwurf. Erst nach dessen Freigabe wird High-Fidelity im bestehenden KADAssist-Designsystem ausgearbeitet.


## Low-Fidelity-Design – Backup-Erstellung (22.11.2026)

Status: Wireframe-Entwurf; keine produktive UI, keine interaktiven Funktionen implementiert.

### Bildschirmfolge / Inhalte
- Überschrift „Backup erstellen“ mit kurzer Erklärung.
- Schritt 1: Kontextauswahl (Verein/Mannschaft; rollenabhängig und nur zulässige Kontexte).
- Schritt 2: fünf unabhängige, zunächst nicht vorausgewählte Kategorien: Mannschaft & Spieler (`team_core`), Training & Anwesenheit (`training`), Spieltage & Kader (`matchday`), Saisonhistorie (`season_history`), Sperren & Disziplinhistorie (`discipline_history`).
- Schritt 3: eigener Abschnitt „Dateien und Bilder“ für referenzierte Spielerfotos, Profilbilder und zulässige Vereinsdateien. Er wird im Wireframe transparent als noch nicht technisch verfügbar gekennzeichnet; nicht als bereits exportierbare Kategorie aktivieren.
- Schritt 4: Zusammenfassung mit Scope, gewählten Kategorien und Dateiumfang.
- Primäre Aktion „Backup erstellen“ bleibt deaktiviert, bis ein Scope und mindestens eine Datenkategorie ausgewählt sind und die Funktion ein vollständiges Backup erzeugen kann.
- Während des Exports: eindeutiger Fortschritts-/Statusbereich; Erfolg erst nach bereitgestelltem vollständigem Archiv. Bei Fehler: klare Fehlermeldung, kein „Backup erfolgreich“ und kein unvollständiges Archiv als fertig ausgeben.

### UX-Leitlinien
- iPhone-first, vertikaler Ablauf, klare Abschnittsüberschriften, Auswahlzeilen mit großer Touch-Fläche.
- Keine implizite „alles ausgewählt“-Voreinstellung.
- Restore nicht auf diesem Bildschirm.
- Passwort-/Verschlüsselungsdialog ist ein separater späterer Schritt, sobald das Archivformat verbindlich freigegeben wurde.

### Nächster Schritt
High-Fidelity auf Basis des bestehenden KADAssist-Designsystems (neutrales Blau, vorhandene Typografie/Abstände/Material-Symbole) erst nach Freigabe dieses Wireframes. Keine Codeänderung oder Deployment.


## High-Fidelity-Design – Backup-Erstellung (22.11.2026)

Status: visueller Konzeptstand; nicht implementiert und nicht deployed.

### Designrichtung
- Bestehendes KADAssist-Design fortführen: neutrales Blau, helle Kartenflächen, zurückhaltende Umrandungen, klare Typografie und konsistente Material-Symbolsprache.
- Mobile-first, insbesondere iPhone; vertikale Karten-/Abschnittsstruktur mit gut erreichbaren Auswahlflächen.
- Keine grüne, fußballspezifische oder maritime Gestaltung.

### Ausgearbeitete Bildschirmbereiche
1. Kopfbereich mit Zurücknavigation, Kontextpfad „Mehr / Daten“, Backup-Symbol, Titel und kurzer Erklärung.
2. Bereichsauswahl als prominentes Dropdown-/Auswahlfeld.
3. Datenumfang als fünf klar getrennte Auswahlzeilen mit Checkbox-Platz rechts und feinen Trennlinien; zunächst keine Vorauswahl.
4. Dateien & Bilder als separater, sichtbar noch nicht verfügbarer Abschnitt („In Vorbereitung“), damit der Umfang nicht falsch dargestellt wird.
5. Zusammenfassung mit Bereich, Anzahl/Bezeichnung gewählter Kategorien und Dateistatus.
6. Primäre Aktion unten, im Konzept deaktiviert, solange Auswahl oder vollständiger Export nicht bereit ist.

### Statusgrenze
Dieses High-Fidelity-Konzept ist keine fertige Implementierung. Die vorhandene App bleibt unverändert. Vor Codearbeit sind Schema, Low-Fidelity und High-Fidelity fachlich als Gestaltungsvorgabe zu übernehmen; anschließend Umsetzung ausschließlich in DEV nach dem bestehenden Freigabeprozess.


## Nutzerfeedback zur Backup-UX und Passwortschutz (22.11.2026)

Nutzerwünsche, verbindlich in die nächste Designrevision aufzunehmen:
- Neben Einzelauswahl eine Option **„Alle“** anbieten.
- Dateien und Bilder direkt im Backupumfang berücksichtigen, nicht als spätere Ausbaustufe.
- Klar festlegen, an welcher Stelle das Backup-Passwort vergeben wird und welche Sicherheitsregeln das Format einhalten muss.

Umsetzung im Design:
- Master-Checkbox „Alle Datenbereiche“ mit korrekt synchronisiertem Zustand (alle / teilweise / keine); „Alle“ umfasst auch die Asset-Kategorie.
- „Dateien & Bilder“ als eigenständige auswählbare Kategorie. Technisch noch offen: DEV-Edge-Function enthält bisher keine Asset-Kategorie und exportiert keine Storage-Bytes; sie muss vor vollständigem Backup ergänzt werden. Nur referenzierte und scope-authorisierte Objekte; Orphans nicht einschließen.
- Passwortschritt nach Kontext-/Umfangsauswahl und unmittelbar vor Archivierung; Passwort + Bestätigung, sichtbar/verborgen, Passphrase-Hinweis und Warnung, dass Verlust nicht rückgängig gemacht werden kann. Passwort clientseitig, niemals an Backend senden/speichern/loggen.
- Sicherheitsformat als vorläufige Architekturleitplanke dokumentiert: ZIP-Kompression, anschließend vollständiger Outer-Container mit AEAD (AES-256-GCM Kandidat), frischem Nonce und Salt, versioniertem Header und authentifizierten Metadaten. Argon2id bevorzugt, Parameter gemäß geprüfter Empfehlung und iOS-Test; PBKDF2-HMAC-SHA256 >= 600k nur als dokumentierte Fallbackoption. Keine Kryptoprimitiven selbst implementieren; etablierte Bibliothek, Testvektoren und falsches Passwort/Manipulationsprüfungen erforderlich.
- Das genaue Format und die Bibliothek sind noch nicht als Implementierungsentscheidung freigegeben; zunächst aktualisierte Schema-/Low-/High-Fidelity-Artefakte, danach DEV-Plan.

Quelle für KDF-Leitplanken: OWASP Password Storage Cheat Sheet (Argon2id 19 MiB / 2 / p=1 als Mindestprofil; PBKDF2-HMAC-SHA256 600.000 Iterationen bei FIPS-Anforderung) und Chrome Web Crypto Guidance zu AES-GCM mit frischer 12-byte IV und authentifiziertem Additional Data. Die Empfehlungen werden als Designhinweis, nicht als automatische Zertifizierung des Backupformats verstanden.


## Designstand Backup-Auswahl v2 abgeschlossen (22.11.2026)

Schema, Low-Fidelity und High-Fidelity wurden konsolidiert und aktualisiert:
- Master-Auswahl „Alle“ inklusive Tri-State/indeterminate und synchroner Einzelauswahl.
- Dateien & Bilder sind gleichwertige, direkt auswählbare Kategorie; ausschließlich referenzierte, scope-autorisierte Objekte, keine Orphans und keine Löschungen.
- Passwort wird nach Zusammenfassung und direkt vor Exportstart eingegeben/bestätigt; ausschließlich lokal, nicht backendseitig gespeichert/geloggt; Passwortverlust ist nicht rücksetzbar.
- Ablauf: Kontext → Umfang → Review → Passwort → Exportstatus → Download.
- Verschlüsselungsformat weiterhin Designkandidat, nicht final freigegeben: versionierter Container, AEAD/AES-GCM, Argon2id bevorzugt, etablierte Bibliothek und Prüfungen erforderlich; ZIP.js nur Kompressionskandidat.

Designrevision dokumentiert in `docs/AP_BR02_STORAGE_ARCHIVE_DESIGN_DRAFT_2026-11-21.md`, Commit `efacec7`. Noch keine App-/Edge-Function-Codeänderung und kein Deployment. Nächster Schritt: technische DEV-Umsetzungsplanung mit expliziter Reihenfolge (Assets serverseitig scoped, vollständiges Payload, lokale Verschlüsselung, Download und Fehler-/Sicherheitsprüfungen), anschließend Umsetzung nach Freigabeprozess.



## DEV-Umsetzungsplan v1 – Backup-Export (22.11.2026)

Dieser Plan ist die nächste Arbeitsgrundlage; es wurde noch kein Code geändert und keine Function deployed.

### Arbeitspakete und Reihenfolge

**P0 – Vertrags-/Antwortformat festlegen (nur DEV-Code/Plan)**
- Request: ausgewählter `scope_type`, `scope_id`, eindeutige Kategorien inkl. Asset-Kategorie.
- Server prüft Auth, Rollen-/Scope-RPC und jede Auswahl; unbekannte/duplizierte Kategorien und ungültige Scopewerte ablehnen.
- Antwort als versionierter Snapshot mit Daten, Assetmanifest und klarer Vollständigkeits-/Fehlerinformation; keine Erfolgsantwort, die „Storage/Archiv nicht enthalten“ verschweigt.
- Client zeigt nur einen vollständigen Export an; bestehender JSON-Button bleibt unangetastet, bis Ende-zu-Ende bereit und getestet.

**P1 – Asset-Manifest und serverseitiger Storage-Abruf**
- Storage-Objektpfade aus den tatsächlich referenzierten DB-Feldern und bestätigter Asset-Inventur bestimmen; keine beliebigen clientseitig gelieferten Pfade als vertrauenswürdig behandeln.
- Server baut Pfad-Allowlist anhand ausgewählter Tabellen/Datensätze und Rollen-Scope; pro Objekt Eigentümer-/Bucket-/Scope-Bezug prüfen.
- Erlaubte Buckets entsprechend vorhandener KADAssist-Nutzung: Spielerfotos, Profilavatars, Vereinsassets – nur wenn zum gewählten Scope gehörig und referenziert.
- Orphans und fremde/unreferenzierte Objekte nicht einschließen. Dateien lesen/downloaden, niemals löschen oder überschreiben.
- Manifest je Datei: stabiler Backup-Pfad, ursprünglicher Bucket/Objektbezug als Restore-Metadaten, MIME-Typ soweit verfügbar, Größe, Prüfsumme; keine öffentlich zugänglichen Signed URLs im Backup.
- Begrenzungen: Anzahl, Einzelgröße und Gesamtgröße; paginierter DB-Zugriff und kontrollierte Fehler bei fehlenden/unerreichbaren Dateien. Keine stillen Auslassungen.

**P2 – vollständiges Archiv-Payload**
- JSON-Snapshot und Asset-Bytes in einen nachvollziehbaren Paketaufbau bringen; Referenzstruktur dokumentieren, keine externen URL-Abhängigkeiten.
- ZIP.js als Kompression/Archivierung prüfen, aber nicht mit der Verschlüsselung des Gesamtcontainers verwechseln.
- Keine clientseitige unscoped Storage-Abfrage; Backend gibt nur bereits autorisierte Manifest-/Bytes zurück.

**P3 – clientseitige Passwortverschlüsselung**
- Bibliotheks-/Containerentscheidung nach gezieltem Review, nicht automatisch aus dem bisherigen ZIP-AES-Test ableiten.
- Passwort bleibt lokal; KDF/AEAD/Nonce/Salt/format version und Headerauthentifizierung nach freigegebenem Format.
- Verschlüsselung erst nach vollständigem Payload; Abbruch und Bereinigung temporärer Blob-/OPFS-Dateien bei Fehlern.

**P4 – App-UI und Download**
- Auswahlzustände: „Alle“ tri-state; sechs Kategorien; ausgewählter Kontext; Review; Passwort/Bestätigung; Fortschritt; Download/Fehler.
- Erst den bisherigen JSON-Button ersetzen, wenn P0–P3 umgesetzt und der Export in DEV end-to-end bestanden ist. Vorher Prototyp kenntlich halten.

**P5 – gezielte Abnahme (nicht Wiederholung der erledigten Tests)**
- Rollen-/Scope-Negativtests (fremde Mannschaft/Verein, manipulierte IDs/Kategorien).
- Asset-Referenztests: legitime Referenz enthalten, Orphan/fremde Referenz ausgeschlossen, fehlende Datei führt zu Fehler statt unvollständigem Erfolg.
- Vollständigkeit/Pagination; beschädigtes Archiv, falsches Passwort und Manipulation; Passwort wird nicht an Backend gesendet/logged.
- Ein einzelner End-to-End-DEV-Test mit synthetischen Daten/Assets; keine erneute allgemeine 1/5/10/20-MiB-Runde.

### Freigabegrenzen
- Keine SQL-Migration vorgesehen, sofern Schema nicht nachweislich eine Änderung benötigt; Schema-/RLS-Prüfung zuerst.
- Keine Storage-Schreib-/Löschoperation.
- Keine PROD/main-Änderung.
- Deployment oder Aktivierung des neuen Exportbuttons erst nach expliziter Freigabe und DEV-Abnahme.


## Asset-Quellenabgleich aus develop (read-only, 22.11.2026)

Code-/Inventurabgleich identifizierte die derzeitigen privaten Asset-Bezüge:
- Spielerfotos: Bucket `player-photos`, Referenz `players.photo_path`; Legacy-Feld `players.photo_data` kann zusätzlich data-URI/Base64 enthalten und muss separat als Datenfeld behandelt werden, nicht als Storage-Datei.
- Profilavatars: Bucket `profile-avatars`, Referenz `profiles.avatar_url`; auch in Mitgliedsdarstellungen wird Profilreferenz verwendet. Backup muss den zugehörigen Profil-/Mitgliedschaftsdatensatz im gewählten Scope berechtigen und darf nicht pauschal alle Benutzerprofile exportieren.
- Vereinswappen: Bucket `club-assets`, Referenz `clubs.crest_path`; nur für den explizit gewählten Verein bzw. die zugehörige Mannschaft mit berechtigtem Vereinsscope.
- Buckets sind in der App als private Bildressourcen geführt. Gespeicherte Signed URLs gehören nicht ins Backup; stattdessen Originalobjektbytes und sichere, interne Restore-Metadaten.
- Aktuelle Referenzen und Objektbestand sind vor Implementation read-only in DEV abzugleichen; historische Objektzahlen aus der Inventur sind nicht als aktueller Bestand zu verwenden.

Asset-Implementierung darf nur anhand dieser DB-Referenzen und des serverseitig autorisierten Scope erfolgen. Der Request darf keine frei wählbaren Storage-Pfade legitimieren. Kein Objekt wird im Export geändert oder gelöscht. Fehlende Referenzdateien müssen als nachvollziehbarer Exportfehler erscheinen (kein stiller Teilbackup-Erfolg).


## Read-only Scope-/FK-Prüfung DEV – Ergebnis (22.11.2026)

Supabase DEV-Schema wurde über Metadaten (Tabellen, Spalten, FK-Beziehungen) geprüft; keine SQL-Schreiboperation.

### Sichere Ableitung der Datensatz-Scope
- **Direkte Teamzuordnung**: Tabellen mit `team_id` (z. B. teams, players, positions, seasons, trainings, training_series, matchdays, team-scoped Historie) werden ausschließlich über die vom serverseitigen Rollencheck bestätigte `team_id` eingeschränkt. Für Vereinsscope wird zuerst die autorisierte Menge der Team-IDs aus `teams.club_id` ermittelt.
- **Child-/Join-Tabellen**: Tabellen ohne eigenes `team_id` müssen über ihren fachlichen Eltern-Datensatz eingeschränkt werden (z. B. attendance/training_players/training_responses über trainings; matchday_players/matchday_attendance über matchdays; player_positions über players und zusätzlich positions). Bei Tabellen mit zwei Beziehungen müssen beide Seiten konsistent zum ausgewählten Team gehören; ein FK allein darf nicht als Scope-Nachweis gelten.
- **Saisonverknüpfung**: trainings und matchdays besitzen sowohl `team_id` als auch optionale `season_id`. Der Export muss bei vorhandener season_id deren Teamzugehörigkeit ebenfalls verifizieren; widersprüchliche oder verwaiste Beziehungen sind als Datenintegritätsfehler zu behandeln, nicht durch breite Abfrage einzuschließen.
- **Profilavatars**: `profiles` ist über `auth.users` identifiziert und nicht direkt team-scoped. Profil-/Avatarobjekte dürfen daher nur anhand von User-IDs abgeleitet werden, die in der ausdrücklich ausgewählten Team-/Vereinsmitgliedschaft vorkommen und durch die gewählte Backup-Kategorie gedeckt sind. Kein globaler Profile-Export; Rollen-/Mitgliedschaftsdatensätze bleiben gemäß fachlicher Klassifikation aus dem normalen Backup ausgeschlossen.
- **Vereinsassets**: `clubs.crest_path` nur für exakt den ausgewählten und serverseitig autorisierten Club. Beim Mannschaftsscope nur für den Club der ausgewählten Mannschaft und nur, wenn Vereinsasset in diesem Scope fachlich enthalten ist.
- **Storage-Objekte**: Referenzpfad aus DB-Feldern serverseitig auf den erwarteten Bucket und erlaubten Pfad begrenzen; keine clientseitigen Pfade. Signed URL nicht persistieren. Die Funktion liest nur Bytes; keinerlei Storage-Mutation.

### Ergebnis / Konsequenz
Die Grundstruktur der Scope-Kette ist im Schema vorhanden. Die sichere Umsetzung muss jedoch eine explizite Tabellen-/Kategorie-Allowlist mit jeweiliger Scope-Ableitung verwenden und die Mehrfach-FK-Konsistenz prüfen. Nicht jede historische oder auditartige Tabelle darf automatisch aufgrund eines einzelnen FK eingeschlossen werden; sie bleibt gemäß bereits abgeschlossenem fachlichem Inventar zugeordnet.

Diese Prüfung bestätigt noch nicht, dass die aktuelle Edge Function alle Regeln implementiert. Sie ist ein Datenmodellbefund und eine Vorgabe für den nächsten Code-Review. Keine Function-/DB-/Storage-Änderung, kein Deployment.


## Read-only Review der aktiven DEV-Edge-Function create-backup (22.11.2026)

Function-Version 2 / Status ACTIVE wurde nur ausgelesen; kein Deploy und keine Änderung. Review bestätigt: Authentifizierung via `auth.getUser()`, Scope-Prüfung über `is_team_admin` bzw. `can_manage_club_context`, serverseitige Ermittlung der Team-IDs für Clubscope, Kategorie-Allowlist, paginierte Abfragen (500), keine Storage-Bytes und ausdrücklicher Prototypstatus in der Antwort.

### Konkrete Scope-Lücken vor Asset-Erweiterung
1. **Child-Datensätze prüfen nicht beide Beziehungen**: z. B. `attendance`, `training_players`, `training_responses`, `matchday_players`, `matchday_attendance` und Empfehlungseinträge werden aktuell überwiegend nur über Training/Matchday/Run-ID begrenzt. Ihre `player_id` wird nicht zusätzlich gegen die autorisierten Spieler-IDs geprüft. Schema-FKs erzwingen keine gemeinsame Teamzugehörigkeit der beiden verknüpften Datensätze.
2. **player_positions** wird über `player_id` aus dem Snapshot gefiltert, aber `position_id` wird nicht gegen die autorisierten Team-Positions-IDs verifiziert. Eine inkonsistente Kreuz-Team-Zuordnung könnte daher in den Snapshot gelangen.
3. **season_id-Konsistenz**: Trainings und Spieltage werden primär über `team_id` abgefragt; optionale `season_id` wird im Function-Code nicht gegen die zugehörige Team-Saison geprüft.
4. **Trainer-/Benutzerbezüge**: `training_trainers` und `matchday_trainers` enthalten `user_id`. Der Export darf daraus nicht unbeabsichtigt Profil-/Mitgliedschafts-/Rolleninformationen ableiten oder globale Profile aufnehmen; Umfang muss gemäß bestehender fachlicher Klassifikation begrenzt sein.
5. **Assetpfade**: kein Storage-Manifest oder Bucket-/Pfad-Allowlist vorhanden. Die zuvor dokumentierten DB-Referenzen dürfen erst nach serverseitiger Prüfung pro Objekt abgerufen werden.

### Vor Asset-Implementierung erforderliche Korrektur
- Snapshot zuerst auf alle zulässigen Parent-IDs aufbauen, danach Child-Tabellen filtern und zusätzliche Fremdbeziehungen gegen autorisierte ID-Sets validieren.
- Bei inkonsistenten Cross-Team-Referenzen Export mit kontrolliertem Datenintegritätsfehler abbrechen oder nach verbindlicher Regel ausschließen und transparent melden; nicht stillschweigend vollständigen Erfolg behaupten.
- `player_positions`: sowohl player_id als auch position_id innerhalb des ausgewählten Teams prüfen.
- Trainings/Matchdays: season_id null zulassen, andernfalls Season-Team-Zuordnung prüfen.
- Erst nach diesen Scope-Korrekturen Asset-Bytes integrieren; keine beliebigen Storage-Pfade vom Client akzeptieren.

Status: Review-Befund, noch keine Codeänderung. Die Function ist ein serverautorisierter Snapshot-Prototyp, aber noch nicht vollständig scope-integritätsgeprüft und daher nicht als fertiger Backup-Export freizugeben.


## Scope-Korrektur- und Abnahmematrix – create-backup (22.11.2026)

Arbeitsmatrix für die nächste DEV-Codeänderung. Matrix ist aus dem read-only Review der aktiven Function Version 2 abgeleitet. Die Function selbst wurde nicht geändert oder deployed.

| ID | Relation / Daten | Korrekturregel | Negativ-/Positivtest |
|---|---|---|---|
| SC-01 | attendance | training_id muss autorisiert sein UND player_id in ausgewählter players-ID-Menge liegen | gültiger Spieler/Training enthalten; fremder Spieler bei gültigem Training ausgeschlossen bzw. Integritätsfehler |
| SC-02 | training_players | training_id autorisiert UND player_id scope-eigen | Cross-team player nicht exportieren |
| SC-03 | training_responses | training_id autorisiert UND player_id scope-eigen | Fremdspieler-Response blockieren |
| SC-04 | matchday_players | matchday_id autorisiert UND player_id scope-eigen | Fremdspieler im Spieltag blockieren |
| SC-05 | matchday_attendance | matchday_id autorisiert UND player_id scope-eigen | Fremdspieler-Anwesenheit blockieren |
| SC-06 | matchday_recommendation_players | recommendation_id muss zu autorisiertem Run gehören UND player_id scope-eigen | Fremdspieler-Ranking blockieren |
| SC-07 | player_positions | player_id scope-eigen UND position_id in autorisierter positions-ID-Menge | fremde Position bei eigenem Spieler blockieren |
| SC-08 | trainings.season_id / matchdays.season_id | null zulässig; andernfalls Season-ID muss in autorisierter season-ID-Menge liegen und Teamzugehörigkeit übereinstimmen | gültige Saison enthalten; Fremdsaisonbezug als Integritätsfehler behandeln |
| SC-09 | training_trainers / matchday_trainers | Eltern-ID scope-eigen; nur bereits fachlich freigegebene Trainerteilnahmefelder; keine globale profile/member/role-Datenableitung | Export enthält nur zulässige trainer participation rows, keine Benutzerprofile/Rollen |
| SC-10 | Vereinsscope | alle Team-, Player-, Position-, Season- und Parent-ID-Mengen stammen ausschließlich aus autorisierten Teams des Clubscopes | fremder Verein / manipulierte Team-ID liefert 403 oder keine Daten |
| SC-11 | Asset-Referenzen | erst nach Scope-Korrektur: DB-referenzierte Pfade, Bucket-Allowlist, autorisierte IDs; keine vom Client gelieferten Pfade | gültiges Referenzobjekt enthalten; fremder Bucket/Pfad und orphan ausgeschlossen |
| SC-12 | Vollständigkeit | paginierte Parent- und Child-Queries; Fehler nie in leere erfolgreiche Kategorie umwandeln | Query-/Storage-Fehler endet mit Fehlerantwort, nicht mit scheinbar vollständigem Backup |

### Implementierungsnotizen
- Query-/Helper-Ansatz: alle Team-scoped Elternmengen zuerst laden; IDs für players, positions, seasons, trainings, matchdays und recommendation runs separat aufbauen.
- Child-Tabellen werden paginiert und anschließend serverseitig zusätzlich gegen die relevanten ID-Sets validiert; niemals eine fehlende Parent-ID-Menge durch ungefilterte Query ersetzen.
- Für Beziehungen mit mehreren FKs nicht nur query-filter setzen, sondern Ergebnisse zusätzlich validieren. Inkonsistenz führt zu einem definierten Integritätsfehler (vorzugsweise Export abbrechen, damit kein still unvollständiges Backup entsteht).
- Die Funktion behält Status/Prototyp-Markierung, bis Scope-Korrekturen, Asset-Bytes, vollständiges Archiv und Verschlüsselung fertig sowie DEV-abgenommen sind.
- Tests sollen anhand isolierter DEV-Testdatensätze ausgeführt werden; bestehende produktive Nutzerdaten nicht manipulieren. Keine SQL-Schreiboperation ohne separaten Approval; wenn Testfixture benötigt, erst sichere read-only Prüfung und Nutzerfreigabe.


## Scope-Integritätskorrektur DEV – deployed (22.11.2026)

Die Matrix `e2fc802` wurde als begrenzte Korrektur in der DEV-Edge-Function `create-backup` umgesetzt und deployed. Keine PROD-Änderung, keine SQL-Migration, keine Storage-Mutation.

### Änderungen
- Nach dem Snapshot wird ein Integritäts-Gate ausgeführt: `player_positions` muss sowohl auf Scope-Spieler als auch Scope-Positionen verweisen.
- `attendance`, `training_players`, `training_responses` müssen auf autorisierte Trainings und Scope-Spieler verweisen.
- `matchday_players`, `matchday_attendance` müssen auf autorisierte Spieltage und Scope-Spieler verweisen.
- `matchday_recommendation_players` muss auf autorisierte Recommendation-Runs und Scope-Spieler verweisen.
- Trainings-/Spieltags-Saisonreferenzen werden gegen Saison-IDs des ausgewählten Teams/Vereins validiert; null bleibt zulässig.
- Für unabhängig ausgewählte Kategorien werden erforderliche Spieler-IDs intern scope-gefiltert und paginiert geladen, ohne sie ungefragt ins Backup-Payload aufzunehmen.
- Jede unerlaubte Cross-Scope-Referenz bricht den Export kontrolliert ab (kein erfolgreicher, scheinbar vollständiger Snapshot).

### Deploystatus
- GitHub source commits: `037aa5d` (integrity gate), `25d27ca` (independent category player ID handling).
- Supabase DEV Edge Function `create-backup`: deployed, ACTIVE, version 3, verify_jwt=true.
- Deployment SHA-256: `47fce174f28f0dbf27da306f91f256a90e8dab13595796226e398af5a5f27399`.

### Abnahmegrenze
Deployment-/Runtime-Version bestätigt. Der vollständige fachliche Positiv-/Negativtest mit authentifizierten DEV-Datensätzen steht noch aus; dafür sind geeignete isolierte Cross-Team-Testfixtures erforderlich. Bis diese Abnahme erfolgt, bleibt die Function ausdrücklich Snapshot-Prototyp. Keine Asset-Funktion, keine vollständige Archivierung oder Passwortverschlüsselung in dieser Version.


## Follow-up implementation – independent category ID checks (DEV, 22.11.2026)

Scope-validation implementation received a follow-up fix for independent category selections:
- When `player_positions` is selected without `positions`, allowed position IDs are loaded internally, team-scoped and paginated (not added to payload).
- Season validation IDs are paginated when `seasons` is not selected.
- A source formatting issue from the first patch (literal escaped newline sequences) was corrected before successful deployment; no malformed code is serving.

Git commits: `c4d031a` (position IDs), `2edf1d5` (season pagination), `2befc94` (source syntax cleanup).
DEV Edge Function `create-backup`: ACTIVE version 4, verify_jwt=true, deployment SHA-256 `8b8c5fdd37b58f5ace5e645844cc56dbba4c3550c6f80d3ca6d4d36698ba012a`.

Status remains: backend scope guard deployment is in place, but no frontend test requested yet. Full functional validation with authorized DEV fixtures remains required before the next feature phase is treated as accepted.


## Frontend-/Backend-Integrationsabgleich (DEV develop, 22.11.2026)

Read-only Abgleich der aktuellen `index.html` mit Edge Function `create-backup`:
- Der bestehende App-Button `JSON sichern` ruft weiterhin `buildBackupSnapshot()` und `downloadBackup()` auf (clientseitige direkte Datenabfragen und unverschlüsseltes JSON).
- Die neue serverautorisierte Edge Function wird aus diesem Button derzeit **nicht** aufgerufen. Backend-Änderungen allein verändern den bestehenden Exportbutton also nicht.
- Bestehender Restore-Code verwendet destruktives Replace; gemäß verbindlicher Entscheidung bleibt Restore zurückgestellt und darf nicht über die neue Backup-Datei aktiviert/angepasst werden.
- Edge-Function-Payload ist tabellenorientiert (`data` mit DB-Tabellennamen), während das Legacy-JSON ein flaches, camelCase-Objekt ist. Die künftige Integration braucht einen expliziten versionierten Adapter/Archivvertrag; nicht direkt an Restore weiterreichen.
- Designv2 fordert sechs Bereiche: fünf fachliche Kategorien plus `files_images`. Aktive Function akzeptiert bislang nur die fünf Datenkategorien und hat keine Asset-Bytes. Das muss im Backend-Vertrag vollständig ergänzt werden, bevor die UI den neuen Export als vollständig anbietet.

### Nächster Umsetzungsschritt (ohne Frontend-Test)
1. Einen versionierten Exportvertrag definieren: Snapshot, Assetmanifest und Datei-Bytes mit vollständigen Erfolgs-/Fehlerstatus, Größenlimits und eindeutigen Archivpfaden.
2. Assetquellen anhand Schema verifizieren: `players.photo_path` und Legacy `photo_data`; `profiles.avatar_url` mit Profilzugriff ausschließlich über im ausgewählten Scope ermittelte User-IDs; `clubs.crest_path` nur für autorisierten Clubkontext.
3. Serverseitige Datei-Allowlist/URL-Pfadnormalisierung und Storage-Download implementieren; niemals freie Client-Pfade oder fremde Signed URLs vertrauen.
4. Erst danach Browserintegration, lokales Verschlüsselungsformat und finaler Exportablauf; Restore bleibt unberührt.

Keine Codeänderung in `index.html`, kein Restore-/DB-/Storage-Schreibzugriff, kein PROD-Deployment in dieser Prüfung.


## Scoped Backup-Package-Endpoint – DEV Umsetzung (22.11.2026)

Neue, getrennte Edge Function `create-backup-package` erstellt und in DEV deployed. Der bisherige `create-backup`-Snapshot-Endpoint und der Legacy-Frontend-Button wurden nicht ersetzt oder verändert.

### Funktionalität der neuen Stufe
- Serverauthentifizierung und Rollen-/Scope-Prüfung aus dem bestehenden Endpoint übernommen; `verify_jwt=true`.
- Unterstützt zusätzlich die Kategorie `files_images` als eigenständige Auswahl, auch ohne Datenkategorien.
- Daten-Snapshot und Assetmanifest werden in ein versioniertes ZIP-Paket (`manifest.json` plus referenzierte Assets) gepackt.
- Assets werden nur anhand DB-Referenzen aus autorisiertem Scope gesammelt: Spielerfoto Storagepfad, Legacy `players.photo_data` Data-URI, Profilavatar aus scoped Team-/Vereinsmitgliedschaften und Wappen des autorisierten Clubs.
- Storage-URLs werden nur für bekannte Bucket-URL-Muster normalisiert; freie externe URLs, Traversal, falscher Bucket und Pfad außerhalb der erwarteten Team/Player-, User- oder Club-Präfixe werden abgelehnt.
- Export ist read-only. Keine Storage-Mutation.
- Limits: maximal 250 Asset-Einträge, 8 MiB pro Datei, 25 MiB Gesamtbytes. Fehlende referenzierte Datei oder Limitüberschreitung bricht den Export ab; keine stillen Teilerfolge.
- ZIP-Archivierung mit fest gepinnter `fflate@0.8.2`; ZIP ist derzeit noch **nicht verschlüsselt**. Passwort und AEAD-Container werden im nächsten Client-Integrationsschritt umgesetzt.

### Deployment / Abgrenzung
- Source commits: `8879a41` (neuer Package-Endpoint), `5a0f777` (bereinigter Responsepfad).
- Supabase DEV: `create-backup-package` ACTIVE, Version 2, `verify_jwt=true`, deployment SHA-256 `c1082c0f01f390daec3738c293f2a86f58b363301af510fa48216320758b13e1`.
- Bestehende `create-backup` bleibt Version 4; Legacy-Frontend bleibt unverändert; kein Restore, keine SQL-Migration, kein PROD.

### Noch offen vor Frontend-Prüfung
- Authentifizierter DEV-End-to-End-Test für alle Rollen/Scopearten, Kategorie `files_images` solo, Cross-Scope-Negativfälle und tatsächliche Storage-Objekte.
- Browserseitige Verschlüsselung des empfangenen ZIP-Payloads mit versioniertem, authentifiziertem Container; Passwort darf nie an Function übertragen werden.
- Auswahl-/Review-/Passwort-/Progress-/Download-UI und Integration des neuen Endpoints.
- Erst danach wird der neue Ablauf auf DEV zur iPhone-Prüfung freigegeben. Der Endpoint allein ist noch kein vollständiger Backup-Workflow.


## Browser-Kryptomodul und synthetischer Envelope-Test (22.11.2026)

- Neues Modul auf `src/backup/backup-crypto.js`, Commit `ed24ff7`: Passwortbasierte Dateiverschlüsselung ausschließlich im Browser.
- Container `KADB` v1 mit PBKDF2-HMAC-SHA-256 (600.000 Iterationen, 16-Byte-Salt) und AES-256-GCM (12-Byte-IV, 128-Bit-Tag). Header ist als GCM-AAD authentifiziert; Version/KDF/Iterationsbereich werden beim Öffnen geprüft.
- Passwortprüfung: mindestens 12 Zeichen, maximal 1.024 UTF-8-Bytes; kein Speichern/Übertragen des Passworts durch das Modul.
- Synthetische Testseite `docs/dev-tests/ap-br02-crypto-envelope-test.html`, Commit `f9941ed`: 64-KiB Zufallsdaten, Roundtrip/Bytevergleich, Falschpasswort- und Manipulationserkennung, Zeitmessung und Testdatei-Download.
- Noch nicht mit der Export-UI verbunden; keine realen Backup-Daten verarbeitet. Test muss auf DEV bereitgestellt und auf iPhone ausgeführt werden, bevor wir die Kryptostufe als praktisch bestätigt betrachten.
- Bewusste Sicherheits-/Architekturgrenze: Passwort wird niemals an Edge Function gesendet. Das Modul verschlüsselt die ZIP-Antwort im Browser nach Erhalt; daher muss die spätere Frontintegration Größen-/Speicherverhalten berücksichtigen und darf vor erfolgreicher Verschlüsselung keine unverschlüsselte ZIP-Datei speichern.


## iPhone Safari – KADB Crypto Envelope Test bestätigt (22.11.2026)

User bestätigte den synthetischen DEV-Test vollständig bestanden:
- Verschlüsselung: BESTANDEN
- Entschlüsselung + Bytevergleich: BESTANDEN
- Falsches Passwort wird abgewiesen: BESTANDEN
- Manipulierte Datei wird abgewiesen: BESTANDEN
- Format: KADB v1; PBKDF2-SHA-256, 600.000 Iterationen; AES-256-GCM, 128-Bit-Tag
- Eingabe: 64 KiB synthetische Daten; verschlüsselte Ausgabe: 65.590 Bytes
- Laufzeit auf iPhone Safari: encrypt 135 ms, decrypt 96 ms
- Keine echten Daten und kein Passwort an Server übertragen.

Damit ist das Kryptomodul für den nächsten Integrationsschritt praktisch auf dem getesteten Gerät bestätigt. Die Laufzeit gilt nur für 64 KiB; daraus wird keine Aussage über größere Archive oder maximale iPhone-Dateigrößen abgeleitet.


## Frontend-Integration DEV – Export UI verbunden (22.11.2026)

- `index.html` Commit `94113c1`: Legacy-Exportbutton öffnet nun den neuen Backup-Dialog. Der destruktive Restorepfad und die Importfunktion wurden nicht geändert.
- Dialog enthält ausdrücklich wählbaren Scope (aktuelle Mannschaft oder aktueller Verein, soweit vorhanden), sechs Kategorien, Checkbox **Alle Datenbereiche und Dateien/Bilder**, Passwort + Bestätigung, Status-/Fortschrittsanzeige.
- Authentifizierter POST an `create-backup-package` mit aktuellem Session-Access-Token. Passwort bleibt im Browser und wird nicht Teil des Requests.
- Server-ZIP wird im Browser als Blob empfangen und über `encryptBackupBlob` als KADB v1 verschlüsselt. Nur `.kadbackup` wird als Download erzeugt; unverschlüsselte ZIP wird nicht separat heruntergeladen.
- DEV Deploy run `45053559264` completed success. Mirror `bautnhaus/jugendmannschaft-dev` main bestätigt: integrierte UI, Crypto-Modul und import vorhanden.
- Noch keine echte, authentifizierte End-to-End-Ausführung im Team-/Vereinskontext durchgeführt. Funktion ist noch nicht als fachlich abgenommen zu betrachten. Nächster iPhone-Test: in DEV unter Backup-Dialog zunächst eine kleine Kategorie auswählen, ein neues Testpasswort (mind. 12 Zeichen) setzen, Export erstellen; prüfen, dass Download `.kadbackup` erfolgt und keine Fehlermeldung erscheint. Datei nicht in Restore einspielen. Danach erst Scope/Kategorien „Alle“ testen, sofern Safari stabil bleibt.
- Browser muss ZIP-Inhalt vor der Verschlüsselung vorübergehend im Arbeitsspeicher halten. Kein Passwort-/Klartextdownload, aber Geräte-Speicherbelastung für größere reale Archive bleibt zu beobachten; derzeit ist keine Maximalgröße für den kompletten Snapshot zugesichert.


## Login-Reaktionsproblem nach Export-UI-Deploy – Präventivfix (22.11.2026)

- Nutzer meldete: Login reagiert im DEV nach Export-UI-Integration nicht.
- `index.html` aus `develop` und DEV-Repo `main` waren bytegleich (Commit `94113c1`); kein fehlgeschlagener/abweichender Sync.
- Der Export-UI-Commit hatte einen zusätzlichen statischen Import des Kryptomoduls in den zentralen App-Modulscript eingeführt. Dieser Import kann bei einem Modul-Ladefehler die gesamte App-Initialisierung blockieren; eine bestätigte Browser-Console-Ursache lag nicht vor.
- Präventiv geändert: Kryptomodul wird jetzt dynamisch erst beim Start des Backupvorgangs geladen. Login und übrige App hängen damit nicht mehr vom zusätzlichen Modulimport ab.
- Fix commit `9da28db7cf9e7f3f3d4fc1098c612ffa8909e0e2`; DEV workflow run `45054961377` success. DEV-Mirror `index.html` SHA bestätigt `49b4fd09cc81bb2f413e0bf67e2c9b8318f8a087`, statischer Crypto-Import fehlt, Lazy-Import vorhanden.
- Login muss vom Nutzer nach Laden der aktualisierten DEV-Seite erneut geprüft werden. Falls es weiter nicht reagiert, nächster Schritt: Safari-Cache/Tab neu laden und tatsächliche Meldung/Fehlerursache erfassen; keine weitere Vermutung als gesicherte Ursache ausgeben.


## AP-BR02 Export-E2E-Test und Dateierkennung (22.11.2026)

- Nutzer bestätigt DEV-Anmeldung nach Syntaxkorrektur wieder funktionierend.
- Syntaxursache im Backup-Export: überzähliges Quote in `let detail='Serverexport fehlgeschlagen ('+response.status+').';';`, korrigiert in Commit `058f239cb633b2544dafd5601aa2383221dd0c2c`. Gesamter zentraler JavaScript-Hauptscript und isolierte Exportfunktion syntaktisch erfolgreich geprüft. DEV workflow success.
- Nutzer bestätigt Export einer kleinen Auswahl: Download erfolgreich; Dialog schloss zunächst nicht. Abschlussverhalten ergänzt in Commit `ddee3df44ff558df54abc2ddeee5e1e3de8172d9`; nach erfolgreichem Download Passwortfelder leeren, Erfolgsmeldung setzen, Dialog schließen. DEV workflow `45059084181` completed success.
- Nutzer bestätigt anschließend Export mit Umfang „Alles“: Download erfolgreich, Dialog automatisch geschlossen. Dies ist ein erfolgreicher End-to-End-Export im aktuellen Kontext/Rolle; Rollenmatrix und Dateninhalt fachlich noch nicht komplett validiert.
- Datei-Endung `.kadbackup`: erwartete proprietäre Endung, MIME `application/vnd.kadassist.backup`; Datei ist KADB v1 AES-GCM-verschlüsselte Hülle, nicht direkt durch iOS Dateien/ZIP-Vorschau lesbar. Ein erfolgreicher Export ist nicht gleich erfolgreiches Wiederöffnen/Decrypt/Restore.
- Stand: Import-/Entschlüsselungs-UI und Restore sind noch nicht abgenommen bzw. dürfen nicht aktiviert werden. Nächster technischer Arbeitspunkt: sichere lokale Datei-Auswahl und Passwort-Entschlüsselung mit Integritätsprüfung, danach ZIP-Inhalt/Manifest lesbar machen, ohne Restore auszuführen. Benutzer hat aktuell noch keine Rückmeldung zur Prüfung von Dateigröße/Dateikennung; kein Restore und kein PROD.

## Rollenfreigabe Backup-UI – Befund Vereinsadmin (22.11.2026)

- Nutzer hat im DEV auf iPhone den Kontext „Vereinsverwaltung“ geöffnet und den Bereich „Mehr“ geprüft. Screenshot zeigt die drei Vereinsverwaltungsbereiche „Dein Bereich“, „Verein / Mannschaft“ und „Verwaltung“; Backup/Restore-Einstieg wird in diesem Rollen-/Startkontext nicht angeboten.
- Read-only-Abgleich des aktuellen develop-Standes: die Backup-Karte `dataBackupCard` mit dem bisherigen Export-/Restore-Einstieg befindet sich im Mannschaftsverwaltungsbereich. Der Vereinsadmin startet bewusst in `clubOnlyMode` mit `team=null` und Vereinsverwaltung; damit ist die bisherige Mannschaftskarte kein geeigneter Einstieg für den Vereinsbackup-Scope.
- Superadmin startet bewusst in der Plattformverwaltung und wählt Verein bzw. Mannschaft ausdrücklich aus. Auch für diesen Rollen-/Kontextfluss muss ein geeigneter Backup-Einstieg vorgesehen werden.
- Nutzeranforderung: Backup-/Restore-Bereich soll für Vereinsadmin und Superadmin sichtbar/zugänglich werden, entsprechend den bereits vereinbarten Scope-Regeln (Vereinsadmin: eigener Verein und Umfang ausdrücklich wählen; Superadmin: Verein oder Mannschaft sowie Umfang ausdrücklich wählen).
- Technischer Status: `create-backup-package` unterstützt bereits team-/club-Scope und Kategorien; der bestehende UI-Exportdialog ist jedoch noch an den bisherigen Mannschaftsbereich gebunden. Die Berechtigungserweiterung ist daher zunächst eine UI-/Kontextintegration plus anschließende Rollen- und Scope-Prüfung, nicht eine pauschale serverseitige Freigabe.
- **Sicherheitsgrenze:** Sichtbarkeit des Backup-Einstiegs bedeutet nicht, den Legacy-Restore zu aktivieren. Der vorhandene `replaceTeamDataWithBackup()` löscht vorhandene Daten und ist mit den verbindlichen Restore-Regeln Merge / Never-delete / Newer-wins unvereinbar. Restore bleibt deaktiviert/zurückgestellt, bis eine neue sichere Implementierung geprüft und freigegeben wurde.
- Nächster Schritt: read-only den konkreten Rollen-/Menüaufbau für Vereinsadmin und Superadmin im aktuellen develop markieren; danach einen minimalen DEV-UI-Plan für Backupzugang in den passenden Vereins-/Plattformkontexten erstellen. Noch keine Codeänderung, kein SQL, keine Supabase-/Storage-Schreiboperation und kein PROD.

## Backup-Umfang unabhängig vom App-Kontext – fachliche Entscheidung (22.11.2026)

- Nutzer hat den Vorschlag bestätigt („Ok weiter“). Präzisierung: Der Superadmin soll nicht zwingend vor dem Backup einen Verein oder eine Mannschaft als App-Kontext auswählen müssen. Ein solcher Kontextwechsel könnte ein umfassendes Plattform-Backup verhindern oder unnötig einschränken.
- Verbindliches fachliches Leitprinzip für die weitere Konzeption: **Der Backup-Dialog bestimmt den Sicherungsumfang; der aktuelle App-/Arbeitskontext begrenzt den Backup-Umfang nicht automatisch.**
- Backup-Zugang für Superadmin direkt aus der Plattformverwaltung, ohne vorherigen Vereins-/Team-Kontextwechsel.
- Umfangsauswahl im Dialog: gesamte Plattform, ausdrücklich ausgewählter Verein oder ausdrücklich ausgewählte Mannschaft. „Gesamte Plattform“ muss als eigener Umfang wählbar sein.
- Vereinsadmin bleibt auf den eigenen Verein begrenzt; Umfang wird im Dialog ausdrücklich gewählt (Verein bzw. zulässige Teilbereiche/Mannschaften gemäß späterer Scope-Spezifikation). Mannschaftsadmin bleibt auf die eigene Mannschaft begrenzt.
- Sicherheitsanforderung: Auswahl im UI ist keine Autorisierung. Backend/Edge Function muss die Rolle und den ausgewählten Scope unabhängig prüfen; kein Scope darf aus einem zuvor gesetzten App-Kontext ungeprüft übernommen werden.
- Technische Abgrenzung: Der vorhandene Export-Endpunkt hat bislang nachweislich Team- und Club-Scope. Ein vollständiger Plattform-Scope über alle Vereine ist noch nicht umgesetzt/nachgewiesen und erfordert eine eigene sichere serverseitige Scope-Definition und Prüfung.
- Restore: Die Scope-Auswahl gilt als fachliche Zielrichtung für Backup/Restore-Dialoge; sie erteilt keine Freigabe, Restore zu aktivieren oder die bestehende destruktive Legacy-Importfunktion zu verwenden. Restore bleibt bis zur Umsetzung von Merge / Never-delete / Newer-wins und ausdrücklicher Freigabe gesperrt.
- Status: fachliche Konzeptentscheidung dokumentiert. Noch keine App-Codeänderung, kein SQL, keine Supabase-/Storage-Schreiboperation und kein PROD.
- Nächster Umsetzungsschritt: auf develop einen konkreten DEV-UI-/Scope-Plan ausarbeiten und die bestehende Edge-Function-Autorisierung read-only gegen die Zielrollen und Scope-Arten abgleichen, bevor Code geändert wird.


## Chatwechsel-/Arbeitscheckpoint – Fortsetzung Backup-Rollenfreigabe (22.11.2026)

Dieser Abschnitt ergänzt den bisherigen Checkpoint als fortlaufende Übergabe. Die vorangehenden Inventuren, Kryptotests, ZIP-Tests und bestätigten Export-E2E-Schritte bleiben gültig und sind nicht erneut auszuführen, sofern ein konkreter Regression- oder Fehlerhinweis entsteht.

### In dieser Chatfortsetzung geprüft (read-only, develop)

- Nutzer verwies auf Commit `35a96af`; maßgebliche Übergabedokumentation ist `docs/AP_BR02_STATUS_HANDOFF_2026-11-21.md`.
- Aktuelle `index.html` in develop geprüft: `window.openMehrPage()` zeigt, dass „Daten & Sicherung“ (`data`) derzeit in den team-admin- bzw. Vereins-/Plattform-Admin-Pfad eingeschränkt ist. Im reinen Vereinsadmin-/Plattformstart fehlt der passende, direkte Backup-Einstieg wie im Checkpoint beschrieben.
- `exportJSON()` read-only geprüft: Dialog baut seine Optionen derzeit aus `team` und `currentClubId`; ohne einen dieser aktuellen App-Kontexte wird kein Scope angeboten. Das widerspricht der fachlichen Entscheidung, dass der Dialog den Backup-Scope bestimmt und der aktuelle Kontext ihn nicht automatisch begrenzt.
- `create-backup-package` Edge-Function-Quelltext read-only geprüft: Request-Validierung akzeptiert `team` und `club`; entsprechende serverseitige Rollen-RPC-Prüfungen sind vorhanden. Ein eigenständiger `platform`-Scope ist in der geprüften Implementierung nicht enthalten/nachgewiesen.
- Kein Code, keine Dokumentationsdatei und kein SQL in dieser Prüfrunde geändert; kein Commit oder Deployment erstellt. Keine DB-/Storage-Schreiboperation und kein PROD-Zugriff.

### Ergebnis / offene Umsetzung

1. Backup-Einstieg für Vereinsadmin und Superadmin in „Mehr“ bzw. den geeigneten Vereins-/Plattformverwaltungsbereich integrieren.
2. Superadmin muss Backup direkt aus der Plattformverwaltung starten können, ohne vorher einen Vereins-/Mannschaftskontext zu setzen.
3. Scope-Dialog ausdrücklich um Plattform, Verein und Mannschaft erweitern; Optionen rollenbezogen darstellen.
4. Backend-Scope-Vertrag und Autorisierung für Plattform-Scope eigenständig sicher entwerfen und implementieren. UI-Auswahl allein ist keine Berechtigung. Bestehende Team-/Clubprüfungen nicht abschwächen.
5. Anschließend gezielte DEV-Rollen-/Scope-Tests durchführen; bereits bestandene Crypto-/ZIP-/kleine-Auswahl-/„Alles“-Exporttests nicht pauschal wiederholen.
6. Restore bleibt gesperrt/zurückgestellt. Die Legacy-Funktion `replaceTeamDataWithBackup()` ist destruktiv und darf nicht verwendet werden, bevor Merge / Never-delete / Newer-wins sicher umgesetzt, geprüft und separat freigegeben sind.

### Verbindliche Arbeitsgrenzen

- Nur Branch `develop` und Supabase DEV.
- Keine SQL-/DB-/Storage-Schreiboperation, Migration, Deployment oder PROD-Änderung ohne separate ausdrückliche Freigabe, soweit die bestehende Projektregel dies verlangt.
- Keine Secrets, Tokens oder Passwörter in Dokumentation oder Chat.
- Bei nächstem Chat zuerst dieses Dokument und die referenzierten AP-BR02-Inventar-/Design-Dokumente lesen; nur die oben offenen Punkte fortsetzen, keine abgeschlossenen Prüfungen wiederholen.


## Verbindliche Dokumentationsregel – laufende Fortschreibung (22.11.2026)

Die STATUS_HANDOFF ist ein **fortlaufendes Arbeitsprotokoll**, nicht nur eine Abschluss- oder Chatwechsel-Übergabe. Da ein Chatwechsel jederzeit plötzlich notwendig werden kann, darf die Dokumentation nicht auf einen angekündigten Wechsel oder das Ende einer Arbeitssitzung warten.

### Arbeitsweise ab sofort
- Nach jedem relevanten abgeschlossenen Prüfungs-, Analyse-, Entscheidungs- oder Umsetzungsschritt wird dieser Checkpoint zeitnah ergänzt.
- Vor einem größeren nächsten Arbeitsschritt wird der aktuelle Zwischenstand festgehalten, damit auch bei abruptem Abbruch der letzte sichere Stand erkennbar bleibt.
- Festhalten: konkreter Schritt, Ergebnis, Aussagegrenze, offene Punkte und nächster konkreter Schritt.
- Bei Codeänderungen: betroffene Dateien, Commit, Branch und durchgeführte Verifikation.
- Bei Deployments: Zielumgebung, Deploymentstatus und getrennt davon die tatsächliche Nutzer-/End-to-End-Abnahme.
- Klar zwischen geplant, geprüft, umgesetzt, committed, deployed und vom Nutzer bestätigt unterscheiden.
- Keine erledigten Prüfungen erneut ansetzen, sofern kein konkreter Regression-/Fehlerhinweis besteht.
- Wenn eine Sitzung unerwartet endet, muss die Dokumentation bereits den letzten bekannten Stand enthalten; eine separate nachträgliche Übergabedokumentation darf nicht vorausgesetzt werden.

Diese Regel gilt für die gesamte weitere AP-BR02-Arbeit und nach Möglichkeit für alle laufenden KADAssist-Arbeitspakete. Die jeweils maßgebliche STATUS_HANDOFF auf `develop` ist die zentrale Quelle für die Fortsetzung in einem neuen Chat.


## Umsetzung begonnen – Backup-Einstieg und Scope-Dialog (22.11.2026)

Vor dem Codeeingriff aktuelle develop-Dateien erneut gelesen:
- `index.html` Blob `3bdfbd73f00f035dbd93b36bd00982f7434770ad`
- `supabase/functions/create-backup-package/index.ts` Blob `a9da8ed88082f9903cc43c59d3e7cf251575afee`

### Gesicherter Ausgangsbefund
- Backup-Dialog/Export sind bereits integriert und der Nutzer hat Export kleiner Auswahl sowie „Alles“ erfolgreich bestätigt.
- Dialog verlangt derzeit `team` oder `currentClubId`, Optionen werden automatisch aus vorhandenem Kontext gebildet; Superadmin im Plattformstart kann den Dialog nicht öffnen.
- Mehr-Menü blendet den Datenbereich aktuell für Vereinsadmin/Superadmin aus; Seitenrestriktion lässt `data` nur für Teamadmin zu.
- `adminGuard()` ist Mannschaftsadmin-orientiert und blockiert Vereinsadmin/Superadmin außerhalb Mannschaftskontext. Backup-Zugang benötigt daher eine eigene rollen-/kontextgerechte UI-Freigabe, ohne den allgemeinen AdminGuard zu lockern.
- Edge Function `create-backup-package` validiert ausschließlich `team`/`club`; serverseitiger Plattform-Scope fehlt. Plattform-Export darf erst nach expliziter Authentifizierung gegen `global_user_roles.role='super_admin'` und scoped Team-/Club-/Asset-Ermittlung ergänzt werden.

### Umsetzungsgrenze
Die Implementierung wird in kleinen, nachvollziehbaren Änderungen vorgenommen. Vor UI-Anbindung des Plattform-Scope muss der Edge-Function-Backendpfad mit vollständigem Plattform-Scope, Role-deny-Tests und Scope-Integrität ergänzt werden. Keine bloße Client-Option darf als Plattformautorisierung gelten. Keine SQL-/DB-/Storage-Schreiboperation und kein PROD.


## Umsetzung – erster Codeabschnitt committed (22.11.2026)

### GitHub develop
- Frontend Commit `a5abd652eb8cd452a9ec324b24bbae749426117b`:
  - Daten & Sicherung im Mehr-Menü für Vereinsadmin/Superadmin freigeben.
  - Daten-Seite rollenbezogen zugänglich machen.
  - Backup-Dialogrolle vom allgemeinen Mannschafts-`adminGuard()` entkoppelt, aber nur für Teamadmin im eigenen Team, Vereinsadmin im eigenen Club oder Superadmin im Plattformstart.
  - Superadmin kann Scope `platform`, `club`, `team` im Dialog wählen; für Verein/Mannschaft werden konkrete Auswahlfelder angeboten.
  - Restore-Handler zeigt nun explizit Sperre und führt keinen Import aus.
- Edge Function Commit `7095d8ec0a367a47e372df76adedc3e8f72a759b`:
  - Request-Scope `platform` ergänzt.
  - Server prüft Plattform-Scope über Service-Role-Abfrage `global_user_roles` des authentifizierten Users und `role='super_admin'`; unberechtigte Nutzer erhalten 403.
  - Plattform-Team- und Vereins-IDs werden ermittelt; Manifest enthält `club_ids`.
  - Vereinswappen werden für die autorisierten Plattformvereine referenzbasiert aufgenommen.
- Edge Function Follow-up Commit `4b23b08a5bbb9f5ed07850275dfadf5ac2b4b875`:
  - Plattform-/Vereins-Team-, Club-, Player- und Mitgliedschafts-Referenzabfragen paginiert; definierte Scope-Sicherheitsgrenzen ergänzen.

### Status / noch nicht abgenommen
- Quelländerungen committed auf `develop`; **kein Edge-Function-Deployment bestätigt**, kein Browser-/DEV-End-to-End-Test nach diesen Änderungen.
- Vor Deployment: statische Syntax-/Diffprüfung und sicherstellen, dass Plattformumfang bei großen Datenbeständen nicht still abgeschnitten wird; insbesondere Club-/Membership-/Asset-Abfragen und RLS-/RPC-Interaktion.
- Danach DEV-Testmatrix: Teamadmin nur eigenes Team; Vereinsadmin nur eigener Verein; Superadmin Plattform/Club/Team; Nicht-Superadmin Plattformscope muss 403 erhalten; ungültige/fehlende Scope-ID muss kontrolliert scheitern; Paketmanifest und Assets auf Vollständigkeit prüfen.
- Die vorhandenen Crypto-/ZIP-/früheren Exporttests sind kein Ersatz für diese neue Rollen-/Scope-Abnahme und werden nur gezielt für Regression wiederholt.
- Keine SQL-/DB-/Storage-Schreiboperation und kein PROD.


## DEV Deployment und technische Grenzen – 22.11.2026

### Deployment
- Nach dem Frontend-/Edge-Function-Commit wurde `create-backup-package` aus `develop` nach Supabase DEV deployed.
- Supabase meldet: ACTIVE, Version 3, `verify_jwt=true`, Deployment SHA-256 `9a1f628a64b97393e2d1beec6b45ebfa7b9c80e2f7620460223f2debb9c4dbf6`.
- Kein PROD-Deployment, keine SQL-/DB-/Storage-Schreiboperation. Die Edge Function führt nur ihre vorgesehenen scoped Reads und referenzbasierten Storage-Downloads bei einem späteren Export aus.

### Kritische Abnahmegrenzen – noch nicht als vollständig freigeben
- Deploymentstatus ist bestätigt, aber authentifizierte Rollentests und tatsächlicher Paketinhalt wurden nach der Scope-Erweiterung noch nicht ausgeführt.
- Die neue UI bietet Plattform/Verein/Mannschaft für Superadmin; konkrete Datenbank-/RLS-Verfügbarkeit der Auswahlfelder muss im DEV-Browser geprüft werden.
- Plattformscope aggregiert derzeit die in den definierten AP-BR02-Kategorien enthaltenen Team-/Vereinsdaten über alle ermittelten Mannschaften und referenzierten Assets. Er ist **kein vollständiger System-/Administrationsbackup**: globale Rollen, Vereinsmitgliedschafts-/Teammitgliedschaftsverwaltung und weitere nicht in der Kategorie-/Tabellen-Allowlist enthaltene Plattformkonfiguration sind nicht automatisch Teil des Pakets. Der UI-Text „Gesamte Plattform“ ist daher vor fachlicher Freigabe zu präzisieren oder der Datenvertrag muss diese Daten ausdrücklich ergänzen.
- Plattformabfragen haben Sicherheitsgrenzen (bis 5.000 Mannschaften/Vereine); Asset-Endpoint-Limits bleiben 250 Objekte, 8 MiB je Objekt und 25 MiB Gesamtbytes. Das sind implementierte Abbruchgrenzen, keine Zusicherung eines unbegrenzt vollständigen Plattformbackups.
- `club_members`-Mitgliedschaften werden bei Plattformscope mit einer großen `IN`-Liste aller Club-IDs abgefragt; bei sehr vielen Vereinen kann dies API-/URL-Grenzen erreichen. Vor breiter Freigabe in paginierte/Batch-Abfrage umstellen oder mit repräsentativer Größe verifizieren.
- Legacy Restore wurde in der UI blockiert; der destruktive Restore-Code bleibt im Quelltext vorhanden, ist über den UI-Handler aber nicht ausführbar. Keine Restore-Freigabe.

### Nächste Schritte
1. DEV-Frontend-Deploy/Sync für Commit `a5abd652` read-only verifizieren.
2. iPhone-/DEV-UI prüfen: Vereinsadmin sieht Backup-Einstieg und ausschließlich eigenen Verein; Superadmin sieht Dialog direkt in Plattformverwaltung und kann die Scope-Auswahl bedienen.
3. Authentifizierte End-to-End-Tests für Team/Club/Platform durchführen; Plattform-Negativtest mit Nicht-Superadmin (403) nur über sicheren autorisierten Testaccount, keine Tokens im Chat.
4. Paket entpacken/Manifest offline prüfen, Kategorien/Assets und Vollständigkeitsangaben gegen gewählten Scope prüfen; kein Restore.
5. Plattformscope fachlich vollständigkeitsklarstellen (nur AP-BR02-Kategorien oder zusätzlich Plattformrollen/Mitgliedschaften/Club-Stammdaten) und gegebenenfalls Vertrag/Code nach Freigabe ergänzen.
6. Status nach jedem Test sofort in diese Handoff schreiben; keine Wiederholung bereits bestätigter ZIP-/Crypto-Grundtests.



### Frontend-Deploy-Verifikation (22.11.2026)
- GitHub Actions `Deploy DEV` run `45073176783` für Commit `1267b1e0`: completed / success.
- DEV-Mirror `bautnhaus/jugendmannschaft-dev`, Branch `main`, Datei `index.html` read-only abgerufen. Blob SHA `67c5860e539bf74bad13368a6483c5cbe3977f38` stimmt mit dem Frontend-Commit überein.
- Mirror-Inhalt bestätigt: Plattformoption im Dialog, Rollenfreigabe im Mehr-Menü und Restore-Sperrhinweis sind enthalten.
- Damit sind Quellcommit und DEV-Sync technisch verifiziert. Noch nicht verifiziert ist das reale iPhone-/Browserverhalten bzw. die authentifizierte Rollen-/Scope-Funktionalität.


## Testreihenfolge korrigiert – Vereinsadmin vor Superadmin (23.11.2026)

Nutzer hat zu Recht darauf hingewiesen: Vor dem Chatwechsel war der **Backup-Test als Vereinsadmin** der nächste ausstehende Praxistest, weil der UI-Einstieg für diese Rolle damals fehlte. Dieser Test ist noch nicht als bestanden dokumentiert und darf nicht übersprungen werden.

### Verbindliche nächste Reihenfolge
1. **Vereinsadmin zuerst:** Im DEV als Vereinsadmin anmelden, Mehr → Daten & Sicherung öffnen, Scope-Auswahl und Vereinseinschränkung prüfen. Export für den eigenen Verein zunächst mit den zuvor bewährten Kategorien/kleiner Auswahl testen; Manifest und Scope auf korrekte Vereinszuordnung prüfen. Kein Zugriff auf fremde Vereine.
2. Ergebnis sofort hier in dieser STATUS_HANDOFF dokumentieren (bestanden / fehlgeschlagen, genaue Beobachtung, nächster Schritt).
3. Erst nach Abschluss des Vereinsadmin-Tests zum **Superadmin** wechseln: Plattformstart ohne vorherige Vereins-/Mannschaftsauswahl, Dialog öffnen, Scope Plattform/Verein/Mannschaft und Auswahlfelder prüfen.
4. Danach Superadmin-Scope-Export und serverseitige Negativ-/Berechtigungstests gezielt durchführen.

Der Vereinsadmin-Test ist der priorisierte offene Test und geht dem neuen Superadmin-Test vor. Keine bereits abgeschlossenen Crypto-/ZIP-Grundtests wiederholen, außer ein neuer Befund begründet eine Regression.


## Vereinsadmin-UI-Test – Befund und Änderungsbedarf (23.11.2026)

### Nutzerprüfung auf DEV (iPhone, Screenshots im Chat)
- Vereinsadmin kann Mehr → Daten & Sicherung öffnen; der Backup-Dialog ist sichtbar. Der zuvor fehlende UI-Zugang ist damit für diesen Test behoben.
- Im Backup-Umfang wird im praktischen Dialog derzeit nur „Eigener Verein (alle zugehörigen Mannschaften)“ angezeigt/angeboten. Die gewünschte Auswahl einzelner Mannschaften ist damit noch nicht praktisch testbar.
- Auswahl eines vorherigen Mannschaftskontexts verändert den angebotenen Backup-Umfang laut Nutzer nicht.
- Nutzeranforderung: Im Vereinsadmin-Dialog neben dem kompletten Vereinsbackup eine **Multiselect-Auswahl konkreter Mannschaften** anbieten. Der Vereinsadmin soll eine oder mehrere Mannschaften seines eigenen Vereins auswählen können; serverseitig muss jede ID auf die Vereinszugehörigkeit geprüft werden. Fremde Mannschaften dürfen weder UI-seitig angeboten noch über manipulierte Requests exportiert werden.
- Teststatus: Vereinsadmin-Einstieg bestanden; Scope-/Exporttest **noch offen und vor Export pausiert**, bis der Multi-Team-Scope implementiert und deployed ist. Nicht als Export bestanden markieren.

### Rollenübergreifende Überschrift in „Mehr“
- Screenshot-Vergleich: gleicher Bereich zeigt für Vereinsadmin „Vereinsverwaltung“, für Mannschaftsadmin „Einstellungen“.
- Nutzerwunsch: gleiche, rollenunabhängige Überschrift für diesen Bereich.
- Vorschlag für Umsetzung: neutraler Titel **„Verwaltung“**; den konkret ausgewählten Kontext/Rollenbereich nicht als wechselnde Hauptüberschrift verwenden. Vor Codeänderung ggf. bestehende Heading-Quelle in index.html prüfen und einheitlich setzen.

### Nächster Umsetzungsschritt (DEV only)
1. Backup-Dialog: Vereinsadmin kann zwischen „Eigener Verein – alle Mannschaften“ und „Ausgewählte Mannschaften“ wechseln; zweite Option zeigt eine mobil bedienbare Mehrfachauswahl (Checkbox-Liste statt iOS-Select mit Einzelwahl).
2. Requestvertrag um explizite Liste team_ids ergänzen; Edge Function prüft Vereinsadmin-Berechtigung für den eigenen Club und verifiziert **jede** ausgewählte Mannschaft, dass sie exakt zu diesem Club gehört. Keine Client-only-Autorisierung.
3. Manifest weist Scope-Typ und ausgewählte Team-IDs klar aus; vorhandene Vereinsbackup-Semantik unverändert.
4. Mehr-Bereichsüberschrift für Vereinsadmin und Mannschaftsadmin einheitlich „Verwaltung“ (bzw. final abgestimmte neutrale Bezeichnung).
5. Erst nach Commit, DEV-Deploy und Sichtprüfung den Vereinsadmin-Exporttest fortsetzen. Superadmin-Test bleibt danach.


## Korrektur Multi-Team-Backup Vereinsadmin – Umsetzung (23.11.2026)

- Frontend commit `a4bca42987afb58b9cfe1b9bad533cb612acc9bb` in develop: Vereinsadmin-Dialog bietet „Eigener Verein – alle Mannschaften“ und „Ausgewählte Mannschaften“. Bei Auswahl der zweiten Option erscheint eine Checkbox-Multiselect-Liste der Mannschaften des aktuellen Vereins. Mannschaftscontext ist nicht länger Voraussetzung; keine Einzelauswahl per iOS-Select.
- Request sendet `team_ids` zusätzlich zum Club-Scope. Frontend verlangt mindestens eine markierte Mannschaft.
- Edge Function commit `3ffd8c74c118b2738a23b5279b81cde38e905e09`: validiert `team_ids` (Typ, UUID, Duplikate, nur Club-Scope) und prüft serverseitig anhand DB, dass jede ID existiert und `club_id` exakt dem autorisierten Club entspricht. Erst danach wird `authorizedTeamIds` auf die Auswahl begrenzt. Fremd-/manipulierte IDs scheitern mit 403; fehlerhafte Requests 400.
- Edge Function `create-backup-package` deployed in Supabase DEV: ACTIVE, Version 4, `verify_jwt=true`, Deployment SHA-256 `640ff0963103c7487cc879b7ee9f5e8cb9e42ec024cb2fc1cff5cfc9dd9199ba`. Kein PROD-Deployment.
- Neutraler Rollen-Kontexttitel „Verwaltung“ statt „Vereinsverwaltung“ ist in Frontend-Commit `a4bca429` enthalten. Der dynamische Mehr-Unterseiten-Titel `management` war bereits „Verwaltung“.
- Status: Code und Edge Function deployed; Browser-/E2E-Test mit Vereinsadmin nach diesem Update steht noch aus. Vereinsadmin-Backup noch nicht fachlich bestanden; erst im DEV erneut Dialog prüfen und danach Export mit ausgewählten Mannschaften, Manifest-Team-IDs und Negativprüfung (fremde Team-ID) abnehmen. Superadmin-Test bleibt anschließend.


## Vereinsadmin-Multiselect bestätigt / Überschrift rollenübergreifend korrigiert (23.11.2026)

### Nutzer-Test DEV
- Nutzer bestätigt auf iPhone: Multiselect für Backup-Mannschaften wurde korrekt angezeigt und der Backup-Download konnte gestartet werden.
- Damit ist die UI-/Download-Stufe für den ausgewählten Vereinsadmin-Scope praktisch bestanden. **Inhalts-/Manifestprüfung** (enthaltene Team-IDs, Kategorien, Scope-Integrität) ist noch offen; bitte den Download bzw. das Manifest gezielt kontrollieren, bevor Export insgesamt als vollständig abgenommen gilt.
- Nutzer meldet weiterhin unterschiedliche Überschriften auf der Seite „Daten & Sicherung“: Vereinsadmin „Mehr“, Mannschaftsadmin „Einstellungen“, Superadmin „Plattformverwaltung“. Die vorangegangene Änderung hatte nur den Kontexttext getroffen, nicht die tatsächliche gemeinsame Überschrift `#settingsMainHeading`.

### Korrektur tatsächliche gemeinsame Überschrift
- Frontend commit `42b0e5462aa995d71e582b878e38da9ef573c21b` in develop: `#settingsMainHeading` wird in allen Start-/Rollenpfaden (Teamadmin, Vereinsadmin, Superadmin und read-only Kontext) auf **„Verwaltung“** gesetzt; HTML-Fallback ebenfalls vereinheitlicht.
- Änderung ist auf develop committed. DEV-Frontend-Deploy/Synchronisierung und erneute Sichtprüfung auf den drei Rollen stehen noch aus.
- Keine Edge Function, SQL, DB oder PROD-Änderung für diese Überschriftenkorrektur.

### Nächster Ablauf
1. DEV-Frontend-Deploy prüfen und dann Seite „Daten & Sicherung“ mit Vereinsadmin, Mannschaftsadmin und Superadmin auf identische Überschrift „Verwaltung“ kontrollieren.
2. Vereinsadmin-Backup: Manifest-/Paketinhalt der erfolgreich gestarteten Multi-Team-Auswahl prüfen und festhalten; anschließend gezielter Fremdteam-ID-Negativtest nur mit sicherem Testrequest.
3. Danach Superadmin-Scope-Test fortsetzen. Restore bleibt gesperrt.


## Rollenüberschrift „Verwaltung“ – Nutzerbestätigung (23.11.2026)

- Nutzer hat nach DEV-Sichtprüfung bestätigt: Die Überschrift ist jetzt bei allen Rollen korrekt/einheitlich.
- Damit ist der UI-Prüfpunkt „Daten & Sicherung: rollenabhängige Überschrift“ abgeschlossen. Keine erneute Prüfung erforderlich.
- Vereinsadmin-Backup: Einstieg, Multiselect und Start des Downloads zuvor vom Nutzer bestätigt. Paket-/Manifestinhalt und genaue Scope-Prüfung bleiben als separater fachlicher Abnahmepunkt offen.
- Nächster Arbeitsschritt: erfolgreichen Backup-Download bzw. Paket/Manifest prüfen und sicherstellen, dass exakt die ausgewählten Mannschaften und gewählten Kategorien enthalten sind; keine Restore-Ausführung. Anschließend Superadmin-Backup-Scopes testen.


## AP-BR02 – lokaler Backup-Prüfer (23.11.2026)

- Nutzer stimmte dem sicheren Prüfmodus zu: verschlüsselte Datei lokal entschlüsseln, nur `manifest.json` lesen, kein Restore/keine Supabase-Schreiboperation.
- Frontend commit `78e7d6f7d92a5726a2401d251b4a9cf3f6fdef8f`: Datenkarte erhält Aktion „Backup prüfen“. Modal akzeptiert `.kadbackup` + Passwort; verwendet Browsermodul, zeigt Format/Version, Datum, Scope, Vereins-/Mannschafts-IDs, Kategorien, Snapshot-Flag, Dateien-/Bilder-Flag, Asset-Anzahl/-Bytes. Fehler-/Passwortmeldung bleibt lokal. Keine Upload-/API-Anfrage und kein Restore.
- Crypto module commit `4b32c52f5cf86bab26426d67b28b5176e5a89730`: exportiert `readBackupManifestBlob`, sucht Manifest in ZIP (STORE oder DEFLATE via `DecompressionStream('deflate-raw')`) und prüft minimale Paketstruktur. Entschlüsselung bleibt mit vorhandener AES-GCM/PBKDF2-Funktion lokal.
- Status: committed in develop. GitHub Pages DEV deployment und praktische Prüfung (falsches Passwort, gültiges Vereinsadmin-Backup, Scope/Team-IDs/Kategorien) stehen aus. Noch keine Backup-Inhaltsabnahme, kein Restore.
- Hinweis: Der Manifestprüfer bestätigt Paketmanifest/Umfang und Verschlüsselungsintegrität, ersetzt nicht die inhaltliche Validierung aller Datensätze/Assets.

- Nachtrag Deploy: GitHub Actions DEV-Frontend-Deploy für Commit `78e7d6f7d92a5726a2401d251b4a9cf3f6fdef8f` erfolgreich abgeschlossen (Run `45166977676`, conclusion `success`). Crypto-Moduländerung `4b32c52f` ebenfalls erfolgreich verarbeitet. Der Prüfer ist auf DEV verfügbar; Praxistest bleibt offen.


## AP-BR02 – iOS Dateiauswahl für Backup-Prüfer korrigiert (23.11.2026)

- Nutzer-Praxistest meldete: iOS Dateien-App zeigte `.kadbackup`-Dateien ausgegraut, sodass keine Auswahl möglich war; außerdem war der Dateiauswahl-Button visuell zu unauffällig.
- Ursache im Frontend bestätigt: Dateifeld hatte restriktives `accept=".kadbackup,application/vnd.kadassist.backup"`. iOS kann die unbekannte Erweiterung/MIME-Zuordnung als Filter behandeln.
- Änderung in `index.html`, Commit `4e3e36925ccb2f0870ad3217a86789e74670a83b` auf `develop`: `accept`-Filter entfernt (Benutzer kann die Backup-Datei im Dateibrowser auswählen) und Datei-Control mit sichtbarem Rahmen, Mindesthöhe, Kontrast und hervorgehobenem „Datei auswählen“-Systembutton versehen.
- Sicherheit unverändert: Prüfung weiterhin lokal, Entschlüsselung/Manifest-Lesen; kein Import und kein Upload. Auswahl aller Dateitypen bedeutet nicht, dass sie verarbeitet werden: Crypto-Prüfung validiert weiterhin die gewählte Datei und zeigt bei inkompatiblen Dateien einen Fehler.
- Status: Commit auf develop; DEV-Deploy und erneuter iPhone-Test stehen aus. Nach Deployment Datei erneut über „Datei auswählen“ wählen und Manifest prüfen. Danach mit falsch benannter/ungeeigneter Datei testen, dass ein verständlicher Fehler erscheint.


## Fortsetzung Backup-Prüfer / Abschluss verständliche Manifestanzeige (24.11.2026)

### Nutzerbestätigte DEV-Prüfung
- Die iOS-Dateiauswahl wurde erneut praktisch verwendet: Die `.kadbackup`-Datei ließ sich auswählen und öffnen; Passwort wurde eingegeben und der lokale Prüflauf erfolgreich ausgeführt.
- Der Prüfer zeigte zunächst unaufgelöste IDs. Die Anzeige wurde daraufhin um lesbare Bezeichnungen erweitert (Vereins-/Mannschaftsnamen, Kategorien und Datenbereiche sowie verständliche Tabellen-/Datensatzlabels und Zusammenfassungen).
- Nutzer hat die überarbeitete Ergebnisdarstellung anhand der Screenshots geprüft und bestätigt: **„Das sieht gut aus.“** Damit ist die UX-Abnahme der verständlichen Manifest-/Inhaltsübersicht für den getesteten Backup-Fall bestanden.
- Prüfvorgang bleibt strikt lokal: Datei wird entschlüsselt und Paketinhalt/Manifest gelesen; kein Restore und keine Supabase-Schreiboperation.

### Code-/Deploy-Stand
- Commits auf `develop` für Dateiauswahl/Feedback/Labels und lesbare Ergebnisauflösung: `53274eed`, `5ba234ed`, `803573bb`, `798cdb84`, `e615b682` (zusätzlich frühere UX-/Picker-Commits siehe Git-Historie).
- Beim letzten Integrationsschritt blockierten doppelte Deklarationen im zentralen App-Script die App-Initialisierung. Korrektur in Commit `41b50125c5d5d27d348a2ea6f6a17b38f695b33d` (`Fix duplicate declarations blocking app startup`).
- GitHub Actions Deploy DEV Run `45444457116`: completed / success für genau diesen Commit. Das bestätigt den DEV-Deploy; die Wiederherstellung der Anmeldung muss getrennt durch einen aktuellen Login-Test bestätigt werden.
- Die Backup-Prüfung ist damit für den getesteten Datei-/Passwort-/Manifestablauf praktisch bestätigt. Das ist **keine** Restore-Abnahme und auch kein vollständiger Rollen-/Scope-Sicherheitstest für sämtliche Backup-Varianten.

### Noch offen – nicht erneut erledigte Prüfschritte ansetzen
1. Nach dem jüngsten App-Startup-Fix einmal den DEV-Login praktisch bestätigen; bei Erfolg diesen Punkt schließen. Kein allgemeiner Syntaxcheck von Grund auf wiederholen, sofern kein neuer Fehler auftritt.
2. Die verbleibende rollen-/scopebezogene Exportabnahme gezielt vervollständigen: Vereinsadmin-Auswahl mit den konkret gewählten Mannschaften gegen Manifest/Paketinhalt; anschließend Superadmin-Scope (Plattform/Verein/Mannschaft) und autorisierter Negativtest. Bereits bestätigte ZIP-/Crypto-Grundtests und die lesbare Manifestdarstellung nicht wiederholen.
3. Danach Restore als separates Arbeitspaket vorbereiten. Vor Implementierung die vorhandene Legacy-Funktion `replaceTeamDataWithBackup()` nochmals im aktuellen `develop` prüfen und dokumentieren, warum sie wegen Replace/Delete-Verhalten nicht verwendet werden darf.
4. Restore-Konzept auf die verbindlichen Regeln ausrichten: rollen- und zielscopegebundene Prüfung, Vorschau/Dry-run, Merge zulässiger fehlender Datensätze, **Never-delete** für im Backup fehlende vorhandene Datensätze, **Newer-wins** bei Konflikten, FK-/Beziehungsprüfung, Dateien/Bilder und nachvollziehbares Ergebnisprotokoll. Restore erst nach Codeprüfung, DEV-Tests und separater Freigabe aktivieren.

### Arbeits- und Dokumentationsregel
- Dieser Statusnachtrag wird als fortlaufender Checkpoint auf `develop` gepflegt. Nach jedem weiteren relevanten Schritt Ergebnis, Grenzen, Commit/Deploy und den exakt nächsten Schritt ergänzen.
- Weiterhin nur `develop` und DEV. Keine SQL-/DB-/Storage-Schreiboperation, keine PROD-Änderung und keine Aktivierung des Legacy-Restore.


## Read-only Restore-Bestandsprüfung – nächster Arbeitsabschnitt (24.11.2026)

Aktuelle Quelle erneut direkt aus `develop` geprüft:
- `index.html` Blob `e5ab0034714400d0c3ada880d83498e2d7aca3e6` (Branchstand nach Startfix).
- Restore-Implementierung: `replaceTeamDataWithBackup(c, backup)`; Aufrufpfad `window.importJSON`.

### Befund aus dem aktuellen Code
- Der Restore-Handler beginnt mit einem **unbedingten Sperr-Return** und einer Meldung, dass Restore bis zur sicheren Umsetzung von Merge / Never-delete / Newer-wins gesperrt bleibt. Der nachfolgende Legacy-Importcode ist damit über diesen UI-Handler derzeit nicht erreichbar.
- Die Legacy-Funktion selbst ist weiterhin destruktiv: Sie löscht vorhandene teambezogene Player-, Training-, Matchday-, Series- und Position-Datensätze bzw. deren Zuordnungen und fügt anschließend Backup-Datensätze mit IDs erneut ein.
- Sie ist auf den globalen aktuellen Mannschaftskontext `team` zugeschnitten; sie ist kein Restore-Executor für die neuen `.kadbackup`-Pakete mit explizitem Team-/Vereins-/Plattformscope.
- Der alte JSON-Importvertrag (camelCase-Arrays wie `players`, `trainings`, `matchdays`) ist nicht gleich dem neuen verschlüsselten Paket-/Manifestvertrag. Eine direkte Übergabe des geprüften `.kadbackup`-Payloads an die Legacy-Funktion ist nicht zulässig.
- Das automatische „Safety Backup“ und Rollback der Legacy-Funktion sind kein Ersatz für eine transaktionale, konfliktbewusste Restore-Planung; der Ablauf kann bereits mehrere Lösch-/Insert-Operationen ausgeführt haben, bevor ein Fehler auftritt.

### Ergebnis
- [x] Aktuellen Restore-Aufrufpfad und Sperr-Return read-only bestätigt.
- [x] Legacy-Replace-Verhalten als inkompatibel mit den verbindlichen Restore-Regeln bestätigt.
- [x] Kein Restore ausgelöst; keine Daten verändert.
- [ ] Neuer Restore-Vertrag und Dry-run/Preview spezifizieren.
- [ ] Paketdatei lokal validieren und in ein internes, typisiertes Restore-Modell überführen; keine untrusted Manifest-/Datenwerte direkt in DB-Requests verwenden.
- [ ] Konfliktregeln, IDs/FK-Abhängigkeiten, Scope und Datei-/Asset-Restore definieren; fehlende Daten niemals als Löschauftrag interpretieren.
- [ ] Erst nach Review: isolierte DEV-Testdaten, positive/negative Tests, Fehler-/Abbruchverhalten und separate Freigabe für eine Restore-Implementierung.

**Nächster konkreter Schritt:** Restore-Plan/Mapping auf Basis des tatsächlichen aktuellen Paketformats und der bestehenden Tabellen-/Beziehungsinventur ausarbeiten. Bis dahin bleibt der Sperr-Return erhalten; keine SQL-/DB-/Storage-Schreiboperation, kein PROD.


## Restore-Formatabgleich – Paketvertrag read-only (24.11.2026)

Aktuelle develop-Quellen geprüft, keine Änderungen:
- Edge Function `supabase/functions/create-backup-package/index.ts`, Blob `fd45da0f8431c117e954701986d2459001477e0e`.
- Crypto-Modul `src/backup/backup-crypto.js`, Blob `abce8eb2537fb759bb62f16b04db2e1711def30f`.

### Aktueller Container-/Payload-Aufbau
1. Äußere Datei `.kadbackup`: KADB v1 Header + PBKDF2-HMAC-SHA-256 (600.000 Iterationen) + AES-256-GCM; der Header ist authentifiziert. Passwort bleibt lokal.
2. Nach lokaler Entschlüsselung: ZIP-Archiv.
3. `manifest.json`: `format=KADAssist-Backup-Package`, `format_version=1`, Scope (type/id, club_ids/team_ids, display_names), ausgewählte Kategorien, `snapshot` (Datenformat `KADAssist-Teamdaten-JSON`, derzeit Version 16, Tabellen unter `snapshot.data`), `assets` und `completeness`.
4. Asset-Dateien liegen unter internen `archive_path`-Einträgen; Asset-Metadaten enthalten derzeit Bucket, Objektpfad, Archivpfad, Bytezahl und Herkunft. Ein SHA-256-Feld je Asset ist im aktuell geprüften Manifestvertrag nicht vorhanden.

### Restore-Designfolge
- Restore darf nicht den alten JSON-Backup-Parser direkt auf `manifest.snapshot` anwenden. Es braucht einen expliziten versionierten Adapter `Package v1 → geprüfter RestorePlan`.
- Vor jeder Schreiboperation müssen alle erwarteten ZIP-Einträge, Asset-Pfade, Größen, Kategorien, Scope-IDs, Tabellenformen, Datensatz-IDs und FK-Beziehungen vollständig validiert sein. Keine teilweise valide Datei darf bereits DB-Änderungen auslösen.
- GCM authentifiziert den verschlüsselten Container; zusätzlich ist ein semantischer Preflight erforderlich (Manifest-/Payload-Konsistenz, Asset-Count/Bytes, Archive-Pfade ohne Traversal, erlaubte Kategorien und Tabellen, Snapshot-Version-Unterstützung).
- Die neue Prüfung/Restore-Engine muss die ursprüngliche Scope-Autorisierung serverseitig erneut durchsetzen; ein in der Datei enthaltenes `scope`-Objekt ist nur deklarierter Backup-Inhalt und keine Berechtigung.
- Das Paket enthält derzeit keinen bestätigten Restore-Plan, keine Konfliktauflösung und keine Restore-Transaktion. Diese sind vor einer Umsetzung als Design-/Code-Arbeit zu spezifizieren.

Status: nur Quellen-/Vertragsprüfung. Kein Import, kein Restore, keine DB-/Storage-Schreiboperation, kein Deployment.


## Restore-Implementierung – Phase 1: lokaler Paket-Preflight (24.11.2026)

Nutzer bestätigte den DEV-Login; die Startprüfung ist damit für den aktuellen Arbeitsstand geschlossen. Restore-Umsetzung begonnen, weiterhin nur `develop`.

### Neue Codeartefakte
- `src/backup/restore-planner.js`, Commit `9cdf1d40d41399efbbc4082f3e25fd9fc408bb1c`:
  - reiner, nicht schreibender Paketvertrag-Validator (Package v1 / Snapshot v16).
  - Kategorien-/Tabellen-Allowlist, Schema-/ID-Duplikatprüfung, bekannte FK-Prüfungen, Asset-Pfad- und Manifest-Count/Byte-Prüfung.
  - ZIP-Reader-Prüfung über die bereits vendorte zip.js-Bibliothek; jedes deklarierte Asset muss im Archiv liegen und exakt die deklarierte Bytezahl haben.
  - Merge-Vorschau-Helfer: fehlende Datensätze als Additionskandidaten; keine Löschungen; Updatevorschlag nur bei eindeutig neuerem Backup-Zeitstempel, bei Gleichstand/fehlendem Zeitstempel aktuellen Datensatz behalten.
- `docs/dev-tests/ap-br02-restore-preflight.html`, Commit `18a564d3dcebb0dbd973781a064be925b5cb59a8`:
  - synthetische Browser-Fixtures für gültiges Manifest, unbekannte Kategorie, doppelte IDs, Traversal-Pfad, Merge/Never-delete, Newer-wins und unklare Zeitstempel.
  - keine Supabase-Verbindung, keine echten Daten, keine Schreiboperation.

### Sicherheitsgrenze / Status
- Dies ist **Phase 1 – lokaler Preflight und reiner Merge-Planer**, noch kein DB-Restore und keine Aktivierung des alten JSON-Imports.
- Der alte destruktive `replaceTeamDataWithBackup()` bleibt gesperrt und wird nicht wiederverwendet.
- Die Preview-Funktion ist noch nicht mit dem produktiven Dialog oder dem aktuellen Datenbestand verbunden.
- Vor dem nächsten Schritt: JavaScript-/Browser-Fixtures auf DEV ausführen und Syntaxfehler beheben; danach UI-Integration der lokalen Datei-/Passwortprüfung und eines klaren Dry-run-Berichts.
- Danach erst serverseitig autorisierten Scope und aktuelle Daten read-only abgleichen. DB-Schreibpfad/Transaktion, Asset-Restore und tatsächliche Wiederherstellung bleiben getrennte spätere Phasen.
- Kein Edge-Function-Deployment, keine SQL-/DB-/Storage-Schreiboperation, kein PROD-Deployment.


### Deploy-/Mirror-Verifikation Phase 1 (24.11.2026)
- GitHub Actions DEV deploy Run `45449211192` für Commit `64a934ed4fe6a0f3be6b0ec0e44d8a4a49594253`: completed / success.
- DEV-Mirror `bautnhaus/jugendmannschaft-dev`, Branch `main`: `src/backup/restore-planner.js` und synthetische Testseite vorhanden; Mirror-Blob-SHAs geprüft.
- Testseite: `https://dev.kadassist.de/docs/dev-tests/ap-br02-restore-preflight.html`.
- Noch nicht behauptet: tatsächliche Ausführung der Browser-Fixtures oder vollständige ZIP-Preflight-Prüfung auf iPhone. Bitte zunächst nur die isolierte synthetische Testseite öffnen und das Ergebnis bestätigen.
- Der App-Dialog ist noch nicht mit diesem Preflight verbunden; der bestehende Restore bleibt gesperrt. Keine Daten-/Storage-Schreiboperation und kein PROD.


### Restore-Preflight in Backup-Prüfung integriert (24.11.2026)
- Nutzer hat die synthetische AP-BR02-Preflight-Testseite erfolgreich bestätigt: alle Fixture-Tests PASS.
- Nächster Umsetzungsschritt begonnen: Die bestehende lokale Backup-Prüfung ruft nach Entschlüsselung `validatePackageManifest()` aus `src/backup/restore-planner.js` auf. Validiert werden Paket-/Snapshot-Version, erlaubte Kategorien/Tabellen, Datensatzschlüssel und Duplikate, interne Referenzen sowie Asset-Manifest und deklarierte Asset-Summen.
- Bei Erfolg zeigt der Dialog zusätzlich die Anzahl der geprüften Snapshot-Tabellen. Bestehender verständlicher Backup-Inhaltsbericht bleibt erhalten.
- Änderung in DEV-Mirror `bautnhaus/jugendmannschaft-dev`, Branch `main`: Commit `ed0714145a8fd858e086d81806f91ad0d9fb658b`.
- GitHub Pages Build/Deployment Run `45469446521` war bei Dokumentationseintrag noch in Bearbeitung. Keine PROD-Änderung.
- Diese Integration ist weiterhin eine read-only Paket-/Manifestprüfung; sie führt keinen Merge, Restore oder Supabase-Write aus. ZIP-Asset-Bytes und der anschließende Datenbank-Merge-Plan bleiben separate nächste Schritte.


## Backup verifier – Nutzer-Praxistest und Integration korrigiert (25.11.2026)

### Nutzer-Test DEV
- Nutzer hat die Backup-Datei auf dev.kadassist.de erneut lokal entschlüsselt und prüfen lassen. Screenshot bestätigt den erfolgreichen bestehenden Manifest-/Inhaltsbericht; ausdrücklich kein Restore.
- Bericht enthält u. a. 25 Spieler, 4 Positionen, 32 Spieler-Positionen, 1 Mannschaft, 14 Spieltage, 32 Kadernominierungen, 47 Rückmeldungen und 3 Trainer am Spieltag.
- Vereinsname im Manifest-Bericht als nicht verfügbar; Backup enthält keine Dateien/Bilder (0 Assets/0 Bytes). Dies ist für den getesteten Umfang kein Asset-Byte-Test.
- Im Screenshot fehlte der erwartete neue AP-BR02-Preflight-Status bzw. die geprüfte Tabellenanzahl. Daher: alter Manifest-/Inhaltsbericht erfolgreich; Integration durch diesen Screenshot nicht nachgewiesen.

### Read-only Codeabgleich und Korrektur
- develop/index.html und DEV-Mirror main/index.html waren auf Blob e5ab0034714400d0c3ada880d83498e2d7aca3e6 und enthielten noch nicht den Planner-Aufruf.
- DEV-Mirror-Commit ed0714145a8fd858e086d81806f91ad0d9fb658b enthält die Integration, jedoch mit wörtlichen backslash-n-Sequenzen in der JavaScript-Einfügung; außerdem war der Commit nicht im abgefragten Branch-/Deploymentstand enthalten. Nicht als funktional abgenommen.
- Korrekte Integration in develop/index.html vorgenommen: entschlüsseltes ZIP einmal lokal lesen, Manifest extrahieren, restore-planner.js importieren und validatePackageManifest(manifest) aufrufen; Erfolgstext enthält Prüfbereiche und preflight.tableNames.length.
- Commit 3b8fbb158155e312eac31d659ae8fd7dc2e72c2a (develop), Blob d415c62d6b5e51932b56f8c9036259abb95a5dff.
- Änderung ist rein lokal/lesend: kein Restore, Merge, Supabase-/Storage-Write, SQL oder PROD.

### Nächster Schritt
1. Develop→DEV-Synchronisierung und Pages-Deployment für Commit 3b8fbb158155e312eac31d659ae8fd7dc2e72c2a prüfen.
2. Nutzer testet einmal denselben vorhandenen Backup-Dialog. Erfolg muss den expliziten AP-BR02-Prüftext und Tabellenanzahl zeigen; kein erneuter Fixture-/Crypto-Test.
3. Danach getrennt entscheiden/prüfen, ob die tatsächliche ZIP-Asset-Byte-Validierung im Dialog integriert werden soll. Restore bleibt gesperrt.


## Backupprüfung: ZIP-Asset-Bytes + Dialog-UX (25.11.2026)

### Erfolgreicher Nutzer-Praxistest der Paketprüfung
- Nutzer bestätigt auf DEV anhand Screenshot: „Backup entschlüsselt und AP-BR02-Paketprüfung bestanden – es wurde nichts wiederhergestellt.“
- Die Meldung weist 10 Snapshot-Datentabellen aus; Schema, ausgewählte Tabellen, IDs, interne Referenzen und Asset-Manifest wurden gemeldet.
- Der verwendete Backup-Stand hat „Dateien & Bilder: Nicht ausgewählt“, 0 Dateien und 0 Bytes. Das bestätigt den Paket-/Manifestpfad, aber enthält noch keinen realen Asset-Byte-Test mit Assets > 0.

### ZIP- und Asset-Byteprüfung in den lokalen Dialog eingebunden
- src/backup/restore-planner.js enthielt bereits inspectRestoreArchive(zipBlob, zipApi). Diese Funktion liest ZIP-Einträge mit der vendorten zip.js-Bibliothek, prüft sichere/eindeutige Pfade, Manifest, Paketvalidator und die tatsächlichen entpackten Asset-Bytes gegen deklarierte Größe und Gesamtsumme.
- index.html ruft nach lokaler Entschlüsselung jetzt inspectRestoreArchive(decryptedArchive) auf. Der Ergebnisbericht nennt Snapshot-Tabellen, Asset-Anzahl und geprüfte tatsächliche Asset-Bytegröße.
- zip.js 2.25.0 wird aus dem bereits versionierten lokalen vendor/zipjs/2.25.0/zip.min.js geladen; keine externe CDN-Abhängigkeit für diese Prüfung.
- Der aktuell dokumentierte Manifestvertrag enthält pro Asset kein SHA-256. Die aktuelle Byteprüfung bestätigt Pfad-/Vorhandens-/Größenkonsistenz, nicht einen kryptografischen Hash jedes Assets. Hashprüfung erfordert spätere Erweiterung des Export-Manifests.
- Code-Commit fe7a77d52a51f285b7e8eb157ebf1b3f60fffa19, Blob a8e41502541c27174cdcc985a4cb27c31f5633ca (develop).

### Besprochene UI-Anpassungen umgesetzt
- Dateiauswahl: nur der sichtbare „Datei auswählen“-Auslöser öffnet den Picker; der Dateiname ist jetzt ein nicht anklickbares Informationsfeld.
- Dialogaktionen: allgemeine Modal-Toolbar-Regel ergänzt – sekundäre Aktion/Schließen links, primäre Aktion rechts. Im Backup-Dialog steht „Paket prüfen“ rechts und „Schließen“ links.
- Im Code-Commit enthalten; noch nicht vom Nutzer im deployed DEV-Dialog bestätigt.

### ZIP-Byte-Fixtures ergänzt
- docs/dev-tests/ap-br02-restore-preflight.html lädt zip.js lokal und enthält zusätzlich:
  1. gültiges synthetisches ZIP mit Asset-Bytes erfolgreich prüfen,
  2. ZIP mit abweichender tatsächlicher Asset-Größe zurückweisen.
- Testseiten-Commits: e4f471b32e5528b8527aa9f8996d2aa2e435c925 und Formatkorrektur 757df036108fbad652e695d21f3b40db96d085e2 (develop).
- Die neuen Browser-Fixtures wurden in dieser Arbeitssitzung noch nicht live ausgeführt; Ergebnis bleibt offen, bis der DEV-Test bestätigt ist.

### Sicherheit / Scope
- Ausschließlich lokales Lesen und Entpacken im Browser; kein Restore, Merge, DB-/Supabase-/Storage-Write, SQL, Edge-Function-Deployment oder PROD.
- Alter destruktiver JSON-Restore bleibt gesperrt. Restore ist nicht freigeschaltet.

### Nächster Schritt
1. Deployment für die aktuellen develop-Commits abschließen und DEV-Mirror/Pages-Stand verifizieren.
2. Isolierte Preflight-Testseite öffnen und die neuen ZIP-Byte-Fixtures bestätigen.
3. Backup-Prüfdialog auf DEV einmal mit dem vorhandenen Backup testen; Erwartung: neuer Bericht inkl. Asset-Zähler/Bytegröße und UI-Reihenfolge.
4. Da das vorhandene Backup keine Assets enthält, für eine echte >0-Byte-Prüfung ausschließlich ein synthetisches Paket oder ein Backup mit ausdrücklich ausgewählten Testassets verwenden.
5. Danach Restore-Mapping und Scope-/Konfliktregeln read-only spezifizieren. Keine tatsächliche DB-/Storage-Wiederherstellung ohne gesonderte Freigabe.


### Nutzerprüfung Restore-Preflight-Seite – Screenshot 25.11.2026
- Nutzer hat die DEV-Testseite geöffnet und einen erfolgreichen Fixture-Lauf als Screenshot zurückgemeldet.
- Sichtbar bestanden: gültiges versioniertes Fixture; unbekannte Kategorie; doppelte Datensatz-ID; unsicherer Asset-Pfad; Merge ergänzt IDs und löscht nichts; Newer-wins nur bei eindeutig neuerem Zeitstempel; unklare Zeitstempel behalten den aktuellen Datensatz. Anzeige: „ALLE PREFLIGHT-FIXTURES BESTANDEN“.
- Diese sichtbare Ausgabe enthält die 7 bisherigen Schema-/Merge-Fixtures. Die neu ergänzten ZIP-/Asset-Byte-Fixtures (gültiges ZIP mit Asset-Bytes und absichtlicher Asset-Größenabweichung) sind im Screenshot nicht aufgeführt. Daher nicht als durch den Screenshot bestanden dokumentieren; ihr tatsächlicher Browserlauf bleibt separat zu bestätigen.
- Nach Nutzer-Screenshot erneut geprüft: aktueller develop-Code und DEV-Mirror stimmen auf Blob a8e41502541c27174cdcc985a4cb27c31f5633ca überein; Testseite und DEV-Mirror stimmen auf Blob 2348acd1edef76a28f8dc3f1775b7e5b62b16dc7 überein. Aktuelle GitHub Pages Actions für Code-/Test-/Handover-Commits sind erfolgreich.
- Damit ist Deployment/Synchronisierung verifiziert; kein Restore und keine echten Daten wurden verarbeitet.

### Nächster Schritt nach bestandenem Basis-Preflight
1. Testseite einmal neu laden (Cache umgehen, falls nötig) und prüfen, ob die beiden ZIP-Asset-Fixtures als zusätzliche PASS-Zeilen erscheinen.
2. Falls sie fehlen oder Fehler zeigen: Testseite/Console und zip.js-Aufruf untersuchen; noch keine Integration als vollständig byte-getestet abnehmen.
3. Anschließend Backup-Prüfdialog auf DEV testen: ein Picker-Auslöser, Dateiname nicht anklickbar, primäre Aktion rechts, Schließen links, erfolgreicher AP-BR02-Bericht.
4. Restore-Mapping/Scope/Konfliktregeln weiter nur read-only ausarbeiten. Schreib-Restore weiterhin nicht freigegeben.


### Wiederholter DEV-Screenshot: ZIP-Fixtures weiterhin nicht sichtbar (25.11.2026, 07:21)
- Nutzer hat die Preflight-Seite nach dem vorherigen Hinweis erneut geöffnet/abgebildet. Ausgabe ist weiterhin exakt die 7 synchronen Schema-/Merge-Fixtures; die beiden async ZIP-Asset-Byte-Fixtures erscheinen nicht.
- Repositoryprüfung direkt nach Screenshot: Testseiten-Blob in develop und DEV-Mirror ist identisch (2348acd1edef76a28f8dc3f1775b7e5b62b16dc7); aktueller Code-Blob ebenfalls synchron und enthält inspectRestoreArchive(decryptedArchive). GitHub Actions Deploy DEV für Commit 62428ff7fc97d2b70dc7afa0cd94b71eaf8cc115 ist erfolgreich.
- Aktuelle Testseitenquelle in develop enthält die beiden asyncTest-Aufrufe (valid asset bytes; mismatched asset size). Der Nutzer-Browser zeigt jedoch deren Resultate nicht. Das ist ein reproduzierbarer Unterschied zwischen GitHub-Quelle/Deploy-Workflow und tatsächlich ausgelieferter/ausgeführter Seite; Ursache noch nicht belegt. Nicht pauschal als Browsercache behaupten und nicht als bestanden werten.
- Nächster Debug-Schritt: Seite außerhalb des bereits geöffneten In-App-Browser-Tabs neu aufrufen, mit Cache-Buster ?v=2348acd1, idealerweise in Safari; Screenshot erneut prüfen. Wenn weiterhin 7 Zeilen: Seitenquelle/Script-Ausführung gezielt untersuchen (möglicher alter statischer Cache, Script-/Module-Abbruch oder falsche Pages-Origin-Auslieferung). Keine Restore-/DB-Operation.


### ZIP-Asset-Byte-Fixtures im DEV-Browser bestanden (25.11.2026, 07:24)
- Nutzer hat nach erneutem Aufruf mit Cache-Buster den Screenshot der Testseite geliefert. Nun sind alle 9 Fixtures sichtbar PASS.
- Die zwei zuvor fehlenden Tests sind jetzt ausdrücklich bestätigt: (1) ZIP-Preflight prüft tatsächliche synthetische Asset-Bytes; (2) ZIP-Preflight weist falsche tatsächliche Asset-Größe zurück.
- Ergebnisanzeige: „ALLE PREFLIGHT-FIXTURES BESTANDEN“. Das schließt die Schema-/Merge-/Never-delete-/Newer-wins-Fixtures und die synthetische ZIP-Byte-Prüfung ein.
- Damit ist der Browserlauf der isolierten Restore-Preflight-Testseite abgeschlossen. Ausschließlich synthetische Daten; keine Supabase-Verbindung, keine Schreiboperation, kein echter Restore.
- Nächster Schritt: aktualisierten Backup-Prüfdialog in DEV testen (Picker nur über Button, Dateiname nicht anklickbar, primäre Aktion rechts, Schließen links, Paketprüfung erfolgreich). Danach read-only Restore-Mapping/Scope/Konfliktregeln dokumentieren. Tatsächlicher Restore bleibt gesperrt und benötigt separate Freigabe.


## DEV Backup-Prüfdialog bestätigt + Read-only Restore-Mapping (25.11.2026)

- Nutzer hat den aktualisierten Backup-Prüfdialog auf DEV mit dem vorhandenen Backup erneut geprüft. Paketprüfung erfolgreich; 10 Datentabellen, 0 Assets / 0 Asset-Bytes (Dateien/Bilder waren im Backup nicht ausgewählt). Es wurde nichts wiederhergestellt.
- UI-Abnahme: Dateiauswahl nur über den sichtbaren „Datei auswählen“-Button; Dateinamensfeld ist nicht mehr zweiter Picker-Auslöser. In Dialogaktionen steht die primäre Aktion rechts (Daumenreichweite), „Schließen“ links.
- Die neun synthetischen Restore-Preflight-Fixtures sind bestanden; kein echter DB-/Storage-Restore.
- Read-only Restore-Mapping aus aktuellem `restore-planner.js` und dem Paketmanifest erstellt: `docs/AP_BR02_RESTORE_MAPPING_READONLY_2026-11-25.md`, Commit `39ec6709d114570c32a3b1c2c00affbc0f4ddcad`.
- Das Mapping dokumentiert Kategorie-/Tabellen-Allowlist, zusammengesetzte Schlüssel und FK-Prüfung, Scope-Neuprüfung, Asset-Zielzuordnung sowie Merge/Never-delete/Newer-wins. Es benennt ausdrücklich offene Gates (Same-scope vs. Remapping, Feld-Whitelist, atomare Anwendung, Asset-Konflikte, externe Parent-Referenzen).
- Restore bleibt gesperrt. Keine Supabase-Schreiboperation, keine Storage-Mutation, keine Migration und keine PROD-Änderung.
- Nächster Schritt: offene Restore-Gates fachlich einzeln festlegen; danach erst einen isolierten DEV-Restore-Plan/Implementierung vorbereiten. Keine erneute Paket-/Fixture-Runde erforderlich.


## Feld-Whitelist-Analyse Restore – Checkpoint (25.11.2026)

- Read-only Exportvertrag direkt aus develop geprüft: supabase/functions/create-backup-package/index.ts. Die aktuell selektierten Spalten wurden gegen das bestehende Restore-Mapping eingeordnet.
- Restore-Mapping ergänzt: docs/AP_BR02_RESTORE_MAPPING_READONLY_2026-11-25.md, Abschnitt 6. Commit 23bfb68e43cb7b1b0a897a74a2efd7c7383cf095.
- Ergebnis ist ausdrücklich ein **Entwurf**, keine freigegebene Schreib-Whitelist: Identitäts-/Join-Keys unveränderlich; team_id/club_id Scope-Felder validieren und nicht remappen; Akteur-/User-Referenzen vorab auflösen; Historien-/Snapshotfelder nicht generisch überschreiben; Asset-Referenzen erst nach eigenständigem Asset-Plan.
- Keine Code-/Restore-Executor-Änderung, keine Supabase-/DB-/Storage-Schreiboperation, keine SQL-/Migration, kein Deployment und keine PROD-Änderung.
- Bereits abgeschlossene Checks bleiben abgeschlossen: 9 synthetische Restore-Preflight-Fixtures PASS; Backup-Prüfdialog auf DEV erfolgreich; UI-Dateiauswahl und Daumenposition abgenommen; lokaler Paket-Preflight im Dialog erfolgreich. Keine Wiederholung erforderlich.

### Nächster Schritt
Zunächst die Scope-Gate-Entscheidung festhalten: Vorschlag für die erste Restore-Version ist Same-scope-only (Paket und explizit autorisierter Zielkontext müssen exakt übereinstimmen; kein Team-/Vereins-ID-Remapping). Danach die tabellenspezifische Insert-/Update-Allowlist und Akteurreferenz-Regeln spezifizieren. Bis zur Bestätigung bleibt alles read-only und Restore gesperrt.


## AP-BR02 Restore – Scope-Gate und Tabellenstrategie checkpoint (25.11.2026)

- Nutzer hat Same-scope-only für Restore V1 bestätigt: Backup ausschließlich in den gleichen Ursprungsscope, kein Team-/Vereins-ID-Remapping. Zielkontext muss vor Anwendung explizit gewählt und serverseitig erneut autorisiert sein; Scope und ausgewählte Teammenge müssen exakt zum Paket passen. Abweichung blockiert den gesamten Restore-Plan, keine Teilanwendung.
- Read-only Tabellenstrategie ergänzt in docs/AP_BR02_RESTORE_MAPPING_READONLY_2026-11-25.md, Abschnitt 7. Commit 73c0bd868fb7a7b98ca96b16febf1088c04d70a5.
- Vorläufige Familienregeln: Stammdaten/Relations können fehlende IDs ergänzen; fachliche Historie und Empfehlungsruns als Insert-/Append-only Hypothese; Teamsettings nur eng begrenzt mutable. Schlüssel und Scope nicht updaten; Akteur-FKs müssen bereits autorisiert im Ziel bestehen; technische Audit-/Zeitstempel nicht blind überschreiben; Assets bleiben separater Merge.
- Das ist weiterhin Spezifikation/Planungs-Allowlist, keine ausführbare Schreibspaltenliste und keine Restore-Freigabe. Keine Codeänderung, DB-/Storage-Schreiboperation, SQL/RPC, Deployment oder PROD-Änderung.
- Bereits abgenommen: DEV Backup-Dialog, lokaler ZIP-/Asset-Preflight und alle 9 synthetischen Restore-Preflight-Fixtures. Diese Tests nicht erneut durchführen.

### Nächster Arbeitsgang (read-only)
Die exakten Insert-/Update-Spalten tabellenweise gegen aktuelle DEV-Schemaquelle, Constraints, Trigger und FK-Aktionen ableiten. Dabei insbesondere Auth-/Akteur-FKs, Eventstatus und Audit-Zeitstempel prüfen. Danach wird eine konkret versionierte Tabellen-Allowlist dokumentiert und erst zur Nutzerfreigabe vorgelegt. Kein Executor bis separate Freigabe.


## DEV-Schemaabgleich und tabellenbezogene Restore-Allowlist (25.11.2026)

- Nutzer hat den nächsten Schritt freigegeben. Read-only direkt im Supabase-Projekt Jugendmannschaft DEV (Ref pzazqvvoruqnqhcorbwx) abgefragt: exportierte Tabellen-Spalten/Datentypen/Nullbarkeit/Defaults, PK-/Unique-/FK-/Check-Constraints und relevante Trigger. Gegen Export-Selects in create-backup-package Edge Function auf develop abgeglichen.
- Restore-Mapping Abschnitt 8 ergänzt, Commit 2ec8efff145c94256a9a13fd42eb21b9360e12a6. Enthält pro Tabelle Insert-/Update-Kandidaten, Join-/Unique-Konflikte, historische Insert-only-Regeln, Parent-/Child-Planreihenfolge und konkrete DEV-Trigger/FK-Risiken.
- Kritische Live-Schemafunde: Player-Team- und Aktivstatus-Schutztrigger; updated_at-Trigger auf Kernobjekten; Matchday-Status AFTER-Trigger kann frühe Sperren-Resets fachlich reconciliieren; recommendation_runs unique(matchday_id); team_season_closure_audit unique(season_id) und RESTRICT-FKs; Trainer-Relations haben Auth-User-FKs.
- Schemaabgleich ist read-only. Keine Schema-/Tabellenänderung, Migration, Edge-Function-Änderung, Deployment, DB-/Storage-Schreiboperation oder Restore; PROD unberührt.
- Die Allowlist ist noch Planungsgrundlage, kein freigegebener Executor. Vor Implementierung sind insbesondere transaktionale Atomarität/Triggerkontrolle sowie verbindliche nullable-vs-block Behandlung fehlender optionaler Auth-Akteur-FKs zu spezifizieren. Keine erneute Ausführung der bereits bestandenen 9 Fixtures/Dialogtests.

### Nächster Schritt
Read-only prüfen, ob die vorhandene Merge-Preview dieselben tatsächlichen Constraints und Sonderfälle bereits berücksichtigt (Unique-Konflikte jenseits PK, fachliche Triggerwirkung, Historien-Insert-only und Auth-FK-Referenzen). Danach Preview-Lücken und notwendige Erweiterungen dokumentieren; weiterhin kein Restore-Executor.


## Merge-Preview-Abgleich – konkrete Lücken dokumentiert (25.11.2026)

- Planner `src/backup/restore-planner.js` read-only gegen live DEV-Constraints geprüft. Findings in Restore-Mapping Abschnitt 9 dokumentiert, Commit 535e601c32eb227113e777bb84e02797bb9085f3.
- Kritischer Befund: TABLE_KEYS erwartet bei `team_suspension_game_type_settings` und `team_suspension_game_types` jeweils `id`, während DEV echte PKs `team_id` bzw. `team_id + game_type` hat. Preview kann für diese Tabellen nicht korrekt keyen.
- Weiter: TABLE_REFS unvollständig bei Saison-/Team-/historischen FK-Beziehungen und Auth-Akteuren; Preview ignoriert mehrere Unique-Constraints (Position/Season Name, Run pro Matchday, Rang, Season closure); generischer timestamp-Fallback kann Append-only-Historie bzw. nicht-versionierte Relations als Update vorschlagen; Matchday-Status hat fachlichen AFTER-Trigger.
- Das ist Review/Dokumentation. Planner-Code nicht geändert und keine Fixtures erneut ausgeführt. Nächster Umsetzungsschritt ist ein klar abgegrenzter DEV-Code-Fix der reinen Merge-Preview (korrekte Keys, constraint/FK conflict metadata, per-table insert-only/update policy, blocking conflicts) plus neue Regression-Fixtures. Dies ist ausdrücklich kein Restore-Executor und kein DB-/Storage-Schreibpfad.
- Vor Codeänderung weiterhin: aktuelle DEV-Mirror-Quelldatei/Branch synchron prüfen; reine Planner-/Fixture-Änderung, kein SQL/Migration und kein PROD-Deploy. Die bisher bestandenen 9 ZIP-/Preflight-Fixtures nicht wiederholen; gezielt neue Preview-Regressionstests ergänzen.


## Merge-Preview-Härtung – Code und Regression-Fixtures vorbereitet (25.11.2026)

- Auf Basis des DEV-Schema-Reviews die reine Preview-Funktion in `src/backup/restore-planner.js` korrigiert/erweitert:
  - PKs für `team_suspension_game_type_settings` (`team_id`) und `team_suspension_game_types` (`team_id,game_type`) korrigiert.
  - zusätzliche paketinterne FK-Prüfungen für Team-/Saison-/Trainings-/Spieltag- und Historienbeziehungen aufgenommen; Parent-Key `team_id` wird bei Game-Type-Settings unterstützt.
  - bekannte DEV-Unique-Constraints als Preview-Konflikte berücksichtigt und Paketduplikate derselben Unique-Tuple fail-closed abgewiesen.
  - Newer-wins ist nun feld-/tabellenbezogen; `created_at` allein zählt nicht als Änderungsmarker; Append-only Historie/Relations werden nicht als Updates vorgeschlagen; protected player active status ist nicht in der Update-Allowlist.
  - Unique-Konflikt eines Update-Kandidaten mit einer anderen bestehenden Zeile blockiert den Update-Vorschlag.
- Neue acht Regression-Fixtures in `docs/dev-tests/ap-br02-restore-preflight.html` ergänzt (Schema-Keys, Unique-Collision, append-only, protected active, created_at fallback, package FK).
- Source auf develop: Planner commit `1b10de73`, `b66b65e6`, `1283e83b`, `fadacb5c`; Fixture commit `5d95df43`.
- DEV-Mirror planner ist inhaltlich identisch mit develop; DEV-Fixture aktualisiert und committed: `3d97f2f2`. GitHub Pages Build/Browserlauf dieser neuen 17-Fixture-Suite ist noch ausstehend.
- Keine DB-/Storage-Schreiboperation, Migration oder Restore. Kein PROD-Deploy. Der DEV-Code ist weiterhin nur Preflight-/Merge-Preview, kein Executor.
- Bereits bestandene neun ZIP-/Preflight-Fixtures werden nicht erneut als neue Abnahme gezählt; die neuen Preview-Regressionen müssen nach Deploy gezielt im Browser laufen.

### Nächster Schritt
Auf DEV-Testseite nach abgeschlossenem GitHub Pages Deployment die nun 17 Fixtures ausführen. Erwartung: alle PASS. Bei einem Fehler zuerst Fixture-/Planner-Fehler beheben, nicht in Richtung Restore-Executor weitergehen. Danach die Preview-Konfliktdarstellung (blockierende Fälle, nie-delete und update/add/keep) im UI prüfen.


## DEV Merge-Preview Regression Deployment Checkpoint (25.11.2026)

- GitHub Pages workflow DEV run 45656881384 completed successfully: build, report-build-status and deploy all SUCCESS. Deployed commit on DEV mirror main: f9aa3e5ff2fd645cd377c0e5cec3bc37df1708de.
- Test page docs/dev-tests/ap-br02-restore-preflight.html and src/backup/restore-planner.js were fetched from DEV mirror main and confirmed content-identical to develop at checkpoint.
- Current test page contains 17 executable fixture cases: 15 synchronous manifest/merge regression cases plus 2 asynchronous ZIP asset-byte cases. These include protected player active status, created_at not qualifying as Newer-wins, append-only history, unique-key collisions, internal team FK validation, actual asset-byte verification and size mismatch rejection.
- Workflow/deployment success confirms publication only; browser execution of the fixture page has not yet been observed in this assistant session. Do not claim the 17 cases have passed on this deployed page until the page output is inspected. User can open the test page and report the visible PASS/FAIL summary.
- No restore executor, DB/Storage writes, SQL/RPC migration or PROD action. Restore remains disabled.
- Next: inspect the deployed test page's output. If all 17 PASS, mark the merge-preview regression gate complete and proceed to the next documented read-only review; do not rerun the earlier 9 package-preflight cases.


## AP-BR02 Fortsetzung – Exportvertrag / Feldregeln abgeglichen (25.11.2026)

- Nutzer hat die DEV-Testseite geöffnet und Screenshots des tatsächlichen Browserergebnisses geliefert: 17 Fixture-Ausgaben PASS, Abschluss **ALLE PREFLIGHT-FIXTURES BESTANDEN**. Damit ist der 17er Merge-Preview-Regressions-Gate im Browser bestätigt. Die vorherigen neun Paket-/ZIP-Preflight-Tests werden nicht erneut ausgeführt.
- Read-only Live-Schema-Prüfungen in Supabase DEV (Projektref `pzazqvvoruqnqhcorbwx`) dokumentiert: Tabellen/PK/Unique/FK/Trigger; insbesondere Audit append-only, serverseitige updated_at-Trigger, fachliche Side-Effect-Trigger, CASCADE/RESTRICT/SET NULL und Auth-/Actor-FKs. Details in Restore-Mapping §8–11.
- Quellabgleich auf Repository `bautnhaus/jugendmannschaft`, Branch `develop`: `supabase/functions/create-backup-package/index.ts` und `src/backup/restore-planner.js`. Quellen stimmen mit DEV-Mirror-Stand überein. KADB-Paket hat format v1 / Snapshot v16; alte JSON-Exportfunktion in `index.html` ist ein anderes Legacy-/Prototype-Format (v15), nicht mit AP-BR02 verwechseln.
- Restore-Feld-Allowlist gegen Serverexport-Selects abgeglichen: UPDATE_FIELDS sind im Export vorhanden; geschützte Felder wie `players.active`, `photo_path`, `photo_data`, Team-/Club-Identität und Zeitstempel sind nicht Newer-wins-Updatefelder.
- Neue sicherheitsrelevante offene Punkte: (1) DB-Spielerbildfelder werden unabhängig von der files_images-Kategorie mit exportiert, Assets jedoch separat – Restore muss Bildfelder bei fehlendem/ungültigem Assetpaket zurückhalten und DB-Referenzen erst nach sicherem Asset-Plan setzen. (2) Trainer-/Actor-User-FKs werden nicht sämtlich im Preflight gegen vorhandene berechtigte Zielkontext-Nutzer geprüft; keine User/Role/Auth-Anlage oder Actor-Remapping aus Backup zulassen. (3) gezielte Fixtures für fehlende/außerhalb-Scope Trainer/Actor-Referenzen und weitere historische Matchday-Refs erforderlich.
- Dokumentation: Restore-Mapping §12 ergänzt, Commit `de3823ce55b781e1e5cf42cdeffd30b1e30e9125`.
- Status: keine Planner-Codeänderung in dieser Prüfrunde; keine Tests erneut ausgeführt; keine DB-/Storage-Schreiboperation, Migration, Restore/Executor oder PROD-Aktion.

### Nächster Schritt
Die zuvor definierte Preview-UI-Abnahme (blockierende Konflikte, Add/Keep/Update-Zählung, Never-delete-Ausweisung) anhand der tatsächlich bereitgestellten DEV-Ansicht prüfen. Danach – falls UI-Gate abgeschlossen – die nun identifizierten User-/Actor- und Asset-Feldregeln in eine präzise Restore-Planung und gezielte neue synthetische Regression-Fixtures überführen. Vor jeder Restore-Executor- oder DB-/Storage-Schreibarbeit ist weiterhin separate Freigabe erforderlich.


## DEV-UI-Status nach Quellenprüfung (25.11.2026)

- Aktuelle UI-Funktion „Backup prüfen“ wurde im `index.html` geprüft: lokale Entschlüsselung + `inspectRestoreArchive()`; kein Zielzustandsabruf, keine Integration von `buildMergePreview()`, keine Add/Update/Keep/Conflict- oder Never-delete-Zielübersicht.
- Daher ist die bestehende Oberfläche Paketverifikation, keine Merge-Preview. Die 17 erfolgreichen Fixtures prüfen isolierte synthetische Planner-Szenarien, nicht eine UI-/DB-Integration.
- Legacy `replaceTeamDataWithBackup()` bleibt in `index.html` und wird durch den alten JSON-Importpfad aufgerufen. Dieser Altpfad ist destruktiv und bleibt strikt getrennt/gesperrt für AP-BR02-KADB; nicht als Ersatzweg nutzen.
- Restore-Mapping §13 ergänzt, Commit `5d5f154e828044a40cd547f1fbabeba9a2b3be8f`.

### Nächster Schritt – klarer Scope
Eine **read-only Zielzustands-Merge-Preview** spezifizieren/umsetzen: exakter Scope und Server-Autorisierung, nur erlaubte Zielzeilen lesen, Preview-Planner an tatsächliche Daten binden, Add/Update/Keep/Conflict/Never-delete darstellen und die zuvor offenen Actor-/Asset-Regeln blockierend abbilden. Vor Codearbeiten Branch-/DEV-Stand prüfen; keine DB-/Storage-Schreiboperation, kein Restore-Executor, keine Migration und keine PROD-Aktion.


## 26.11.2026 – Read-only Preview-Architektur auf RLS geprüft

- Live Supabase DEV `pg_policies` für Restore-Domain-Tabellen abgefragt. Policies verwenden `is_team_member`, `has_selected_team_context`, Superadmin-Rollen und bei Child-Tabellen Parent-Joins; eine pauschale Client-Abfrage darf daher nicht als Auth-Gate gelten.
- Bestehende Edge Function `create-backup-package/index.ts` als Auth-/Scope-Muster geprüft: Bearer via `auth.getUser()`, Team-Admin `is_team_admin`, Vereinskontext `can_manage_club_context`, Plattform-Superadmin; Auswahlteams werden serverseitig dem Verein zugeordnet und bestätigt. Diese Function ist kein Restore-Preview-Endpunkt.
- Restore-Zielpreview-Architektur in Mapping §14 dokumentiert: serverauthentifiziert, exact manifest+selected scope, same-scope, fixed SELECT-only allowlist, Parent-ID-basiert/paginiert, alle Fehler fail-closed, Actor-FK-/Asset-Gates, Planner rein read-only, UI zeigt Add/Update/Keep/Conflict/Never-delete und „0 Änderungen“.
- Commit Restore-Mapping §14: `2abdad26bce58256f1ff7a10e4b9eebc428fa88b`.
- Noch kein Edge-Function-Code angelegt/geändert oder deployed; keine SQL-/Schema-/Storage-Schreiboperation, kein Restore-Executor und keine PROD-Aktion.

### Nächster Schritt
DEV-only Codevorbereitung für den neuen read-only Preview-Endpunkt (keine Migration): zuerst die Server-Handler-/Query-Spezifikation als festes Table/Column-/Parent-ID-Mapping und Fail-closed Response-Schema erstellen, dann isolierte Autorisierungs-/Scope-/Actor-/Asset-Fixtures. Erst nach lokalem Review/Tests und separater Deployment-Freigabe die DEV Function veröffentlichen.


## 26.11.2026 – Preview-Contract DEV-Codevorbereitung

- Aktuelle `develop`-Quellen vor Änderung neu eingelesen: Edge-Export v1/snapshot v16, Pure Planner, Status-Handover und Mapping. Keine erledigten Fixture-/Schema-Prüfungen wiederholt.
- Neue reine Moduldatei `src/backup/restore-preview-contract.js` angelegt. Sie enthält:
  - feste, serverseitig zu verwendende SELECT-Allowlist;
  - Request-Validierung für Restore-V1 `team`-Scope: Manifest-Scope == ausgewählter Scope, Team-ID exakt gleich, keine Team-ID-Mappings/Mehrteam-Expansion;
  - fail-closed Envelope bei unvollständigem Zielread;
  - Status-/Antwortvertrag mit explizitem `write_count: 0`.
- Zuerst wurden die SELECT-Felder aus dem tatsächlichen `create-backup-package/index.ts` abgeglichen. Eine initiale manuelle Tabellenfeldliste zeigte Abweichungen und wurde korrigiert. Der endgültige Whitelist-Abgleich wurde maschinell durchgeführt: 25 Exporttabellen, 25 Preview-Selects, **kein Feld-/Tabellenmismatch**. Final Contract commit `524d60310e048eb8cb52cd587a1a89105ad7488a`.
- Synthetische Browser-Fixture-Datei `docs/dev-tests/ap-br02-preview-contract.html` ergänzt (7 Fälle: feste Whitelist, gültiger Scope, gewählter Scope-Mismatch, Manifest-Mismatch, Mehrteamblock, incomplete read fail-closed, read-only success envelope). Commit `c769f9f86a6d219474d8304aca2de4b10c6d8a77`. Diese neuen Contract-Fixtures sind **noch nicht vom Nutzer im Browser ausgeführt**; nicht als PASS verbuchen.
- Contract initial commit `63bbe51db98b7a866d24be9b1ed1dc3baea52b4d` wurde durch Korrekturcommit abgelöst; maßgeblich ist der korrigierte Commit.
- Keine Edge Function / Serverhandler implementiert oder deployed; Contract allein autorisiert keine Datenabfrage und ersetzt keine Serverprüfung. Die RLS-/Auth-Architektur bleibt Pflicht. Keine SQL-/Schema-/Storage-Schreiboperation, kein Restore-Executor, keine PROD-Aktion.

### Nächster Schritt
1. Nutzer führt neue isolierte Preview-Contract-Fixtures in DEV Pages aus und zeigt tatsächliche Ausgabe.
2. Danach erst den Server-Handler als **SELECT-only** implementieren: Auth-Token validieren, RPC/Role und Team-Kontext erneut serverseitig prüfen, Package/Manifest scope vergleichen, nur fixe Allowlist und Parent-ID-Filter lesen, paginieren/limitieren, read errors vollständig blockieren. Keine Schreibmethoden/Storage.
3. Serverhandler nicht deployen ohne separate Zustimmung; keine Datenmigration erforderlich.


## 27.11.2026 – Preview-Contract Browsernachweis und Serverhandler-Vorstufe

- Nutzer hat die veröffentlichte DEV-Testseite geöffnet und Screenshot mit **ALLE CONTRACT-FIXTURES BESTANDEN** übermittelt. 7/7 Contract-Fixtures bestätigt; dieser Schritt ist abgeschlossen.
- Read-only Edge-Function-Entwurf neu angelegt: `supabase/functions/ap-br02-restore-preview/index.ts`.
  - Bearer-Authentifizierung via `auth.getUser()`, Team-Adminprüfung via `is_team_admin(p_team_id)`, Zielteam wird serverseitig verifiziert.
  - Team-only exact same-scope; Manifest + Snapshot werden validiert, ausgewählte Kategorien auf feste Export-Allowlist begrenzt.
  - SELECT-only mit Service-Role nach Autorisierung; feste Spalten, team_id-Filter oder Parent-ID-Filter, paginierte Abfragen, 5.000 Zeilen pro Tabelle, 4 MiB Requestlimit.
  - Prüft bekannte Ziel-FKs gegen autorisierte Parent-Zeilen, Profile für referenzierte Actor-IDs; bei Fehlern blockiert die Preview. Planner liefert Add/Update/Keep/Conflict/Never-delete, Antwort enthält keine vollständigen Datenzeilen und `write_count: 0`.
  - Asset-Wiederherstellung/Storage bleibt ausdrücklich außerhalb des Endpunkts; bei im Paket ausgewählten Bildern wird Asset-Gate als deferred ausgewiesen.
- Initiale Serverhandler-Erstellung: commit `5fac1f48592d88b45c65b8040328f4ecac3ab8a0`. Scope-/FK-Reviewkorrekturen: `4b9c5a1caee7e638a11e16e09e5df41bc8feb63e` und `360e3f04326a016529e2d1fc996a6787e1d2a62f`.
- **Status: Source vorbereitet, nicht deployt und nicht kompiliert/live getestet.** Kein Frontend-Aufruf integriert; noch keine Ende-zu-Ende-Preview. Die Funktion enthält keine Insert/Update/Delete-/Storage-Aufrufe. Service-Role SELECT-only Verhalten muss vor Deployment anhand Code/Tests geprüft werden.
- Keine Supabase Function deployed, keine SQL-/Schema-/Storage-Schreiboperation, kein Restore-Executor, keine PROD-Aktion.

### Nächste Prüfung vor Integration
1. Deno/Supabase Edge Function compile/test und statische Prüfung: tatsächlich ausschließlich SELECT, keine Seiteneffekte, Importpfade korrekt.
2. Ergänzende isolierte Tests für jede Tabellen-Parent-Beziehung, fehlende Tabellen/Read-Fehler, Actor-Profil fehlt, Body-/Row-Limits und Cross-Team FK.
3. Danach Frontend DEV-Integration in den lokalen Backup-Verify-Dialog: verschlüsseltes Backup lokal entschlüsseln, validiertes Manifest/Snapshot an den Endpunkt senden, nur aggregierte Preview zeigen; keinerlei Restore-Button oder Write-Route.
4. Vor Function-Deployment separat um Zustimmung bitten; bis dahin nicht deployen.


### 27.11.2026 – Preview-Handler statische Review-Runde

- Source-Review von `ap-br02-restore-preview/index.ts` fortgesetzt. Keine `.insert(`, `.update(`, `.upsert(`, `.delete(` oder Storage-Aufrufe gefunden.
- Parent-/FK-Regeln aus dem Handler in `src/backup/restore-preview-contract.js` als feste, clientunabhängige `PREVIEW_PARENT_REFS` zentralisiert. Endpoint bindet diese gemeinsame Map ein; Browser-Testseite ergänzt eine Fixture, die alle Exporttabellen gegen SELECT-Allowlist und Parent-Scope-Regel prüft.
- Während der Änderungen wurde ein kurzzeitig leerer Handler-Map-Stand erkannt und vor Abschluss korrigiert. Aktueller GitHub-Readback bestätigt `const REFS = PREVIEW_PARENT_REFS` und den Import. Die Browser-Testseite hatte zunächst einen fehlerhaften literal escaped newline im Modulimport; ebenfalls korrigiert. Der aktuelle HTML-Readback zeigt gültige getrennte Importzeilen.
- Aktuelle relevante Commits: Contract/Parent-Map `c5784dd4207027a24b8b8b6f8dbafda3df56318f`; Handler bindet zentrale Map `0553caed6ed68472227a48f4a10bfca617a30c90`; Scope-Map-Test `3eddfb6f1ff6ecc6cc1c7f2210817f6da66b63ee`; HTML-Importkorrektur `d23229454095a16747dbb6171854ffa9aa514aaa`.
- **Aktualisierte 8-Fixture-Browserseite muss nach DEV-Pages-Deploy erneut ausgeführt werden.** Vorherige 7/7 Contract-Fixtures bleiben als historischer Nachweis bestehen; sie decken die neue Parent-Map-Fixture nicht ab.
- Edge Function weiterhin nicht kompiliert, nicht deployed und nicht live getestet. Deployment-Freigabe nicht erteilt. Kein SQL/Schema-/Storage-Write, kein Restore-Executor, keine PROD-Aktion.
- Nächster Schritt: Pages-Deploy der aktuellen develop-Testdatei prüfen; den tatsächlichen Browseroutput der nun 8 Fixtures abwarten. Danach Deno-/Edge-Function Compile- und Mock-Read-Tests (Auth, exact team scope, Parent closure, actor refs, fail-closed read errors, bounds), erst danach Frontend-Anbindung planen.


### 27.11.2026 – Handler-Sicherheits-/Payloadreview

- Zusätzliche Codeprüfung hat zwei Punkte identifiziert und korrigiert:
  1. Das Preview-Requestformat verwendet jetzt nur das validierte Manifest mit `manifest.snapshot.data`; es verlangt nicht länger eine zweite, byte-/reihenfolgeabhängig identische Kopie `snapshot_data`. Body-Limit auf 32 MiB gesetzt, weiterhin harte Begrenzung.
  2. Entfernt wurde die direkte Service-Role-Abfrage `profiles` mit frei aus dem Backup übernommenen Actor-UUIDs. Diese Abfrage hätte einem autorisierten Teamadmin potenziell einen Profile-Existenz-Orakelpfad eröffnet. Preview weist Actor-Referenzen jetzt als `manual_review_required_no_user_lookup` aus; keine automatische Identitätsauflösung oder Remapping.
- Aktueller Readback: Parent-Map-Import vorhanden, Manifest-only Snapshotzugriff vorhanden, keine `body.snapshot_data`-Referenz, keine Profile-Abfrage, keine Insert/Update/Upsert/Delete/Storage-Aufrufe. Zwei versehentlich literal escaped Newline-Sequenzen im Handler wurden vor Abschluss korrigiert; aktueller Quellreadback zeigt sie nicht mehr.
- Letzter Handler-Fix-Commit: `df45c630e5dde68cc3e516671770fa35ff2f7aef`.
- Browser-Testseite aktuell auf 8 Fixtures erweitert, aber nach diesen Source-/Teständerungen noch nicht erneut im Browser bestätigt. DEV Pages-Sync/Deployment ist abzuwarten.
- Handler bleibt unkompiliert/un-deployed. Keine SQL-/Schema-/Storageänderung, kein Restore-Executor, keine PROD-Aktion.


### 27.11.2026 – Browser-Preflight bleibt bei Ladeplatzhalter; Diagnoseausgabe ergänzt

- Nutzer-Screenshot zeigt weiterhin `Tests werden ausgeführt …`, ohne PASS/FAIL-Ende. Daher **kein aktueller Testnachweis** und Fixture-Gate bleibt offen.
- Quellprüfung der DEV-Spiegelseite ergab: statische ES-Modulimporte standen vor dem Testcode. Bei einem Import-/Parsefehler bricht das Modul vor der Ausgabe ab; die HTML-Fallbackzeile blieb unbegrenzt sichtbar und zeigte keine Diagnose.
- Testseite in `docs/dev-tests/ap-br02-preview-contract.html` angepasst: Module werden dynamisch innerhalb eines `try/catch` geladen; Startstatus wird sofort aktualisiert; Importfehler sollen nun sichtbar als `BLOCKIERT – Testmodul konnte nicht geladen werden` inklusive Stack/Fehlertext erscheinen. Erfolgreiche/fehlgeschlagene Fixtures werden weiterhin einzeln ausgegeben.
- Commit: `6f363125a7dbc39a665fa88c3d275d1b38bbed42`. Eine nachfolgende identische Commit-Anfrage ergab keine neue Änderung (GitHub gab denselben Content SHA zurück).
- **Nächster Schritt:** auf Mirror/Pages-Sync dieses neuen Commits warten, Seite im Browser mit Aktualisieren neu laden und den nun sichtbaren Status/Fehlertext ablesen. Noch keine Live-Tests des Edge-Handlers, kein Deployment, keine Supabase-/PROD-Änderungen.


### 27.11.2026 – Preview Contract PASS und DEV-Schemaabgleich

- Nutzer-Screenshot bestätigt alle 8 Contract-Fixtures mit Schlussmeldung `ALLE CONTRACT-FIXTURES BESTANDEN`. Gate für den reinen Client-/Contract-Test ist damit geschlossen. Ausgabe hatte sichtbare literal `\\n`; reine Anzeige, keine Fixture-Fehler.
- Anzeige korrigiert, damit die Ergebniszeilen echte Zeilenumbrüche verwenden. Commit `7cbf14cf6eb33c526cf9355828fd74d5bf34b88e`; GitHub-Readback geprüft.
- Read-only Supabase DEV-Schemaabgleich (Projekt `pzazqvvoruqnqhcorbwx`, gesund/aktiv): alle 25 SELECT-Allowlist-Tabellen existieren, sämtliche aktuell definierten SELECT-Spalten stimmen mit dem DEV-Schema überein; kein Feld-/Tabellenmismatch gefunden. Keine SQL-Abfrage mit Schreibwirkung und keine Schemaänderung.
- Supabase DEV Edge-Function-Liste geprüft: `ap-br02-restore-preview` ist **nicht deployed**. Live-Function-Readback gab NotFound; bestätigt Status „nur Git-Source“.
- Statische Handlerprüfung: Request/Auth-/Teamadmin-Gate vor Service-Role-Reads; feste Select-Allowlist; Team- oder Parent-ID-gebundene, paginierte SELECTs; kein Insert/Update/Upsert/Delete/Storage. Handler-Source SHA `755c399759b56df7bae2c5870585944c252f8fc5`.
- **Wichtiger offener Reviewpunkt vor Compile/Mock-Abnahme:** Der Handler prüft Manifest-Scope und die Ziel-FK-Beziehungen, aber es ist noch nicht belegt, dass jede untrusted Backup-Zeile (insbesondere `team_id`) strikt auf die gewählte Team-ID beschränkt wird und Backup-FKs bei ausgelassenen Kategorien gegen erlaubte Ziel-Parent-IDs validiert werden. Dies in einem adversarialen Mock-Read-Test gezielt prüfen und ggf. fail-closed korrigieren; keine Bereitstellung bis abgeschlossen.
- Kompilierung wurde in dieser Runde nicht ausgeführt: Deno nicht im Tool-Container vorhanden; externer Downloadversuch zur Beschaffung des Quelltexts war wegen fehlender DNS-/Netzwerkverbindung nicht möglich. Kein Deno-Compile-Ergebnis behaupten.
- Nächster Schritt: isolierte adversarial Mock-Read-Testmatrix für backup-row scope / backup-FK closure / permission denial / target-read error / pagination bounds, dann Deno compile in einer verfügbaren lokalen DEV-Umgebung. Erst danach separater Deployment-Freigabeschritt.
- Keine Edge Function deployed, kein Frontend angebunden, kein SQL/Storage-Write, kein Restore-Executor, keine PROD-Aktion.


### 27.11.2026 – Preview Contract bestanden; transitive Parent-Closure behoben

- Nutzer-Screenshot bestätigt alle 8 bisherigen Contract-Fixtures mit `ALLE CONTRACT-FIXTURES BESTANDEN`. Sichtbares `\\n` war ein Zeilenumbruch-Darstellungsfehler; Testausgabe wurde danach auf echte Zeilenumbrüche umgestellt.
- Read-only Schemaabgleich gegen aktuelles Supabase DEV (`pzazqvvoruqnqhcorbwx`, `public`, verbose metadata): alle 25 festen SELECT-Allowlist-Tabellen vorhanden; jedes in `PREVIEW_SELECTS` genannte Feld existiert aktuell in der jeweiligen Tabelle. Zusätzlich 52 Parent-/FK-Felder und Parent-Key-Spalten im Mapping geprüft: keine Schema-Fehlreferenz.
- Supabase DEV Edge-Function-Liste zeigt `ap-br02-restore-preview` **nicht deployed**. Nur die vorhandenen Funktionen sind aktiv; Preview-Handler wurde nicht deployed/ausgeführt. PROD wurde nicht angesprochen.
- Review fand einen fail-closed Funktionsfehler: Handler fügte nur direkte Eltern in `required` ein. Bei verschachtelten Beziehungen (z. B. recommendation_players → recommendation_runs → matchdays → seasons/teams) konnte die Abhängigkeitskette unvollständig bleiben und den Preview-Read blockieren.
- Neue pure Helper-Funktion `resolvePreviewReadClosure()` ergänzt; Handler nutzt nun transitive Parent-Closure. Neue 9. Browser-Fixture prüft exemplarisch die gesamte Kette bis teams/seasons/players. Fixture-Seite korrigiert die Ausgabe auf echte Newline-Zeichen.
- Commits: Contract closure `14853dd8f6636f991d185bd1ef35ed19bead6785`; Handler `3bcd651cc8bf4c9d62a8014c7f71873b7dcd79f3`; Fixture `ac99ac056cc1c2b2f377ae79beaddbf9a18a7fad`; newline rendering `880dc99b99b2d57d9508ef609d0e46dfb1fd7f97`.
- **Nächster Schritt:** DEV mirror/Pages deployment auf die neueste develop-Version prüfen und Browser-Fixtures erneut laufen lassen (jetzt 9). Danach Handler isoliert kompilieren und Mock-Read-Tests für Auth, exakt gleichen Teamkontext, transitive Parent-Reads, Pagination/Row-Limits und fail-closed Fehlerausgänge vorbereiten.
- Weiterhin kein Deployment der Preview-Edge-Function, keine Datenänderung, kein Restore-Executor, keine SQL-/Storage-/PROD-Aktion.


## 27.11.2026 – Preview Contract browser gate bestanden (9 Fixtures)

- Nutzer-Screenshot bestätigt **9/9 PASS** und `ALLE CONTRACT-FIXTURES BESTANDEN`, einschließlich der neuen transitiven Parent-Closure-Fixture. Der Test ist auf der tatsächlichen DEV-Seite ausgeführt.
- DEV-Deploy/Synchronisierung read-only geprüft: Mirror `bautnhaus/jugendmannschaft-dev`, Branch `main`, enthält die aktuelle Contract-Testseite, `resolvePreviewReadClosure()` und die aktualisierte Edge-Handler-Referenz. GitHub Actions letzter relevanter Deploy-Run `45976495995` completed/success; DEV-Mirror-Head zum Abgleich `4669be942c34b4da2a1e4826e46b61eaa178376a`.
- Contract-Gate ist abgeschlossen. Das bestätigt ausschließlich die browserseitigen reinen Fixture-Tests, nicht die Ausführung des Edge-Handlers.
- Nächste technische Schranke: Handler statisch auf Auth/Scope-before-service-read, transitive Team-Scope-Abhängigkeiten, Paging/Max-Row und fail-closed Verhalten reviewed. Ein echter Deno/Supabase-Edge-Compile und isolierter Mock-Read des Handler-Runtimes sind in dieser Umgebung noch nicht ausgeführt; nicht als bestanden markieren.
- Preview-Function `ap-br02-restore-preview` bleibt nicht deployed. Kein SQL, keine Daten-/Storage-Schreiboperation, kein Restore, keine PROD-Änderung.
- Nächster Schritt: lokale/CI-fähige Handler-Prüfung vorbereiten (Deno type-check oder isolierte Testhülle, ausschließlich synthetische Mock-Requests/Mock-Reads). Erst nach bestandenem Compile/Mock-Gate wird ein separates DEV-Deployment zur manuellen Auth-/Scope-Prüfung erwogen – mit expliziter Freigabe, da es eine neue Edge Function wäre.


### 27.11.2026 – Isolierter Deno-Typecheck eingeführt und bestanden

- Nach dem 9/9 Browser-Contract-Gate wurde ein dedizierter GitHub-Actions-Workflow angelegt: `.github/workflows/ap-br02-preview-handler-check.yml`.
- Der Workflow führt nur `deno check` für den Preview-Handler und den reinen Contract aus. Er startet weder `Deno.serve` noch einen Request, verbindet sich nicht mit Supabase und deployt keine Edge Function.
- Der erste Typecheck fand tatsächliche TS-Typfehler im Handler (Category-/Table-Allowlist-Indexierung und zu eng inferierte Fehlerarrays). Diese wurden mit Runtime-Validierung und expliziten Typen korrigiert. In weiteren Läufen wurden von mir eingeführte Syntax-/JSDoc-Duplikate entdeckt und bereinigt.
- Aktueller endgültiger CI-Lauf: **success**, Run `46007975262`, Commit `6f2b0f4108b5fc0786f69a9689380d53aadeadbb`. Beide Schritte – Handler und Contract – sind erfolgreich.
- DEV-Deploy zu diesem Commit ebenfalls **success** (Run `46007975207`). Das ist ein Code-/Dokumentationsdeploy auf DEV Pages, kein Supabase-Edge-Function-Deployment.
- Contract-Helfer bleiben reine JS-Funktionen; JSDoc-Typen statt TypeScript-Syntax in `.js`.
- **Noch offen / nächster Schritt:** isolierte Mock-Read-/Request-Tests des Handler-Ablaufs. Dafür muss die Request-Logik testbar vom `Deno.serve`-Start getrennt werden bzw. eine kontrollierte Mock-Hülle entstehen. Testfälle: OPTIONS/Method, Auth fehlt/ungültig, Permission-RPC deny/error, falscher Team-Scope, SELECT-Abhängigkeiten/Parent-Closure, Paging/Max-Rows, Read-Failure → blocked/0-write und keine unautorisierte Service-Read vor Auth+Scope.
- Kein Preview-Function-Deployment, keine echte Request-Ausführung, keine Daten-/Storage-Schreiboperation, kein Restore, keine PROD-Änderung.


### 27.11.2026 – Mockbare Team-Autorisierung für Preview-Handler ergänzt

- Request-Handler verwendet jetzt isoliertes Modul `supabase/functions/ap-br02-restore-preview/restore-preview-auth.ts` für Bearer-/User-Auth und `is_team_admin(p_team_id)`. Das Modul hat keine Service-Role-Client-Erstellung und keine Tabellen-/Netzwerkreads außerhalb des übergebenen Client-Mocks.
- Synthetische Deno-Tests ergänzt: fehlender Bearer (kein Clientaufruf), ungültiger User (kein Permission-RPC), Permission-RPC-Fehler (fail-closed), Nicht-Admin (403) und erfolgreicher Teamadmin mit exakt gebundener Team-ID.
- GitHub-Actions-Workflow erweitert, sodass nach Typecheck/Contract-Check die synthetischen Auth-Gate-Tests ausgeführt werden.
- Refactor- und Fixture-Dateien sind auf `develop`; zuletzt dokumentierter Testcommit `20eea0b33961150d09348760f8471837ee27cc1d`. Der dazugehörige Actions-Lauf wurde beim Handover-Update noch nicht final abgelesen.
- Zwischenläufe deckten zunächst TypeScript-Typfehler in der Auth-Injection und in den Mock-Callbacks auf. Diese wurden mit expliziten Typen korrigiert. Frühere fehlgeschlagene Runs sind historische Fehler, nicht als PASS zählen.
- Diese Tests beweisen bislang nur die isolierte Autorisierungsfunktion. Der vollständige Handler mit Mock-Query-Builder (Service-Role-SELECT-Reihenfolge, Parent-FK/Paging/Read-Failure) bleibt offen.
- Kein Edge-Function-Deployment, keine Request-Ausführung gegen Supabase, keine Daten-/Storage-Schreiboperation, kein Restore-Executor, keine PROD-Aktion.


- CI-Abschluss nach dem Checkpoint: Run `46025949067` **success** am Commit `20eea0b33961150d09348760f8471837ee27cc1d`. Deno-Handler-Typecheck, Contract-Typecheck und alle 5 synthetischen Auth-Gate-Tests sind grün. Reiner CI-Test; keine Function deployed oder ausgeführt.


### 27.11.2026 – Backup-Team-/FK-Closure-Guard mit adversarial Fixtures

- Offenen Sicherheitsreview umgesetzt: vor Planner-Erstellung ruft der Handler nun `validateBackupTeamClosure` auf. Jede ausgewählte Backup-Zeile wird geprüft:
  - explizites `team_id` muss exakt der autorisierten Team-ID entsprechen;
  - FK-Ancestry muss entweder über ausgewählte Backup-Parent-Zeilen rekursiv auf dasselbe Team oder über bereits scope-gefilterte Ziel-Parent-Zeilen aufgelöst werden;
  - nicht auflösbare Parent-Referenz oder Scope-/FK-Widerspruch blockiert die Preview fail-closed mit `write_count: 0`.
- Reine Contract-Funktion in `src/backup/restore-preview-contract.js`, vom Handler nach erfolgreichem, autorisiertem Zielread aufgerufen. Keine Änderungen an DB/Schema/RLS.
- Vier neue adversarial Fixtures ergänzt (Cross-team direct `team_id`, gültige Parent-Kette aus Backup, unbekannte FK wird blockiert, Child-FK nur aus scoped target parents). Zusammen mit fünf Auth-/Permission-Fixtures jetzt **9 Deno-Tests PASS**.
- Finaler isolierter CI-Lauf: Run `46026265656`, Commit `90070c159d3f807866ea6814e298a767bbcb61a7`, **success**: Handler-Typecheck, Contract-Typecheck, 9/9 Tests.
- DEV Pages Deploy ist ein statischer Code-/Testseiten-Deploy; keine Supabase Edge Function bereitgestellt oder ausgeführt.
- Dazwischenliegende CI-Fehler wurden durch den Workflow aufgedeckt und behoben (TS-Signatur versehentlich in JS-Modul; auf JSDoc umgestellt). Nicht als erfolgreiche Tests zählen.
- **Nächster Schritt:** isolierte Mock-Query-Builder-/Handler-Tests für tatsächliche SELECT-Reihenfolge, Teamfilter/Parent-ID-Filters, Paging/Row-Limits, Read-Fehler → blocked und keine Service-Role-Abfrage vor Auth/Team-Admin-Gate. Aktuell sind Auth-/Backup-Scope-Helfer getestet, noch nicht die komplette Request-Route.
- Kein Edge-Function-Deployment, kein Supabase-Request, keine Daten-/Storage-Schreiboperation, kein Restore-Executor, keine PROD-Aktion.


## Restore – erste nutzbare Zielvorschau im lokalen Backup-Prüfer verbunden (27.11.2026)

- Nutzer hat die Fortsetzung ausdrücklich gestartet mit Ziel, funktionalen Fortschritt zu priorisieren und weitere isolierte Tests nicht als Selbstzweck zu wiederholen.
- Aktueller develop-Code `index.html` read-only geprüft: lokaler Prüfer entschlüsselt die Datei und validiert Manifest/ZIP/Asset-Bytes; noch kein Zielvergleich im Dialog.
- Neue UI-Stufe committed: `index.html`, Commit `95495d68fd35305d9da92e450ff50815af5f2c3e`.
  - Nach erfolgreichem lokalem Paket-Preflight kann der Nutzer **„Nur Vorschau erstellen“** auswählen.
  - Die UI ruft die getrennte Edge Function `ap-br02-restore-preview` mit dem geprüften Manifest und expliziter Team-ID auf.
  - Nur exakter Same-Team-Scope (Paket `scope.type=team`, Paket-ID = angemeldeter Teamkontext) wird angeboten; Club-/Plattformpakete werden nicht umgedeutet.
  - Ergebnis wird als Ergänzungen, Aktualisierungskandidaten, Beibehalten, Konflikte und Never-delete angezeigt; tabellarische Counts ebenfalls.
  - Die Oberfläche akzeptiert nur `read_only_ready`, `complete=true`, `write_count=0`; bei Fehler/blocked wird keine erfolgreiche Vorschau dargestellt.
- GitHub Actions DEV Deploy für Commit `95495d68fd35305d9da92e450ff50815af5f2c3e`: Run `46051271339`, completed/success; develop wurde ins DEV-Mirror synchronisiert.
- Backend-Funktion `ap-br02-restore-preview` ist im Supabase DEV-Projekt derzeit noch **nicht deployed** (read-only Function-Liste geprüft). Der Button kann bis zu diesem Deployment noch keine Live-Zielvorschau liefern; Fehler werden in der UI abgefangen.
- Nächster konkreter Schritt: Deploy dieser SELECT-only Preview-Function nach Supabase DEV aus den exakt committed Dateien; anschließend einen einzigen realen DEV-Previewlauf mit dem bereits vom Nutzer geprüften Backup. Keine Restore-Anwendung.
- Grenzen: Preview-Handler liest nur Zielzeilen mit Service-Role nach Auth-/Teamadmin-Gate und Same-scope Prüfung; es gibt keine INSERT/UPDATE/DELETE/Storage-Schreibpfade. Der Legacy-Replace-Restore bleibt gesperrt. Keine SQL/Migration, keine PROD-Aktion.


### 27.11.2026 – Read-only Restore-Zielvorschau jetzt in DEV bereitgestellt

- Frontend-Commit `95495d68fd35305d9da92e450ff50815af5f2c3e`: der vorhandene lokale Backup-Prüfer bietet nach erfolgreichem KADB-/ZIP-/Manifest-Preflight nun die Aktion **„Nur Vorschau erstellen“**.
- Aktion sendet das geprüfte Manifest plus explizite Team-ID an die getrennte Edge Function `ap-br02-restore-preview`. UI zeigt nur einen vollständig erfolgreichen, ausdrücklich schreibfreien Preview-Vertrag an; Fehler/blocked bleiben „keine Änderungen“.
- GitHub Actions DEV Deploy Run `46051271339`: completed/success; DEV-Mirror `bautnhaus/jugendmannschaft-dev/main` wurde synchronisiert. Read-only geprüft: aktuelles `index.html` enthält den Funktionsaufruf und Contract-Datei ist vorhanden.
- Supabase DEV Edge Function `ap-br02-restore-preview` neu deployed: ACTIVE, Version 1, `verify_jwt=true`; SHA `e50b475b46a04083db216609417dbc0592dca81b836af763f6621af695833c85`. Enthaltene Dateien stammen aus develop: Handler, isoliertes Auth-Modul, Preview-Contract und Merge-Planner.
- Funktionalitätsumfang dieser Stufe: authentifizierter Teamadmin, exakter Same-team-Scope, serverseitig erlaubte SELECT-Spalten, team-/parent-gebundene Zielreads mit Paging/Limits, Backup-Team-/FK-Closure-Guard, deterministische Merge-/Never-delete-/Newer-wins-Vorschau. Der Handler enthält keinen DB-Write und keinen Storage-Write.
- **Jetzt notwendiger Praxisschritt:** Nutzer öffnet in DEV „Backup prüfen“, wählt dasselbe bereits geprüfte Mannschaftsbackup und Passwort, führt die lokale Paketprüfung aus und klickt dann „Nur Vorschau erstellen“. Erwartet werden Zahlen für Ergänzen/Aktualisieren/Beibehalten/Konflikte/Never-delete. Bitte den angezeigten Status oder Screenshot zurückmelden; das ist der erste tatsächliche Aufruf dieser neu bereitgestellten Preview-Route.
- Kein Restore wurde ausgeführt. Legacy Replace bleibt gesperrt; keine SQL-/Migration, keine PROD-Änderung.


### 28.11.2026 – Erster echter DEV-Zielabgleich erfolgreich bestätigt

- Nutzer hat die nach lokaler Paketprüfung verfügbare Aktion **„Nur Vorschau erstellen“** ausgeführt und die Ergebnisansicht per Screenshot bestätigt.
- Anzeige: **Vorschau vollständig – keine Änderungen ausgeführt**; Ergänzungen 0, Aktualisierungen 0, Beibehalten 655, Konflikte 0, Never-delete 655. Die sichtbaren Tabellenzeilen weisen Backup- und Zielbestand übereinstimmend aus; alle aufgeführten Zeilen wurden als Beibehalten gezählt.
- Dies ist der erste bestätigte authentifizierte Zielzustands-Previewlauf über die bereitgestellte DEV-Edge-Function. Es wurde kein Restore angewendet; der `write_count=0`-Vertrag und die UI-Sicherheitsprüfung sind erfüllt. Keine DB-/Storage-Schreiboperation und keine PROD-Aktion.
- Zusammen mit dem zuvor bestätigten isolierten Newer-wins-Test (5/5) und den Contract-/Handler-CI-Gates ist die **read-only Zielvorschau als DEV-Praxisschritt abgeschlossen**.
- Nächster Arbeitsschritt: Restore-Executor-Spezifikation und Implementierungsgrenzen für V1 aus dem bereits dokumentierten Same-scope-/Never-delete-/Newer-wins-/Insert-only-Vertrag ableiten. Vor einem Executor sind noch Transaktions-/Atomaritätsstrategie, exakte feldbezogene Insert-/Update-Payloads, Actor-FK-Regel und Asset-Plan verbindlich abzuschließen. Keine Schreibfunktion oder RPC implementieren/deployen, bevor diese Gates und ein separater DEV-Write-Testplan geklärt sind.
