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
