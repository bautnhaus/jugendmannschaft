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
