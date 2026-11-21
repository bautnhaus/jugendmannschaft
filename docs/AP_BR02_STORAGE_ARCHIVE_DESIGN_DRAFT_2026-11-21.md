# AP-BR02 – Storage-Datei-Export und Paketierung (technischer Entwurf)

Stand: 21.11.2026  
Status: Entwurf – noch keine Implementierung oder fachliche Abnahme  
Branch: develop

## Zweck

Der bestehende create-backup Endpoint liefert einen scoped JSON-DB-Snapshot. Dieses Dokument beschreibt den noch fehlenden Storage-Datei-Teil und ein sicheres Archiv, ohne Restore zu implementieren.

## 1. Objektquellen und sichere Auswahl

Objekte dürfen **nicht** anhand frei übergebener Client-Pfade geladen werden. Der Server ermittelt die Dateiliste selbst aus den autorisierten DB-Datensätzen und prüft:

- ausgewählter Scope und serverseitig verifizierte Rolle,
- passende Kategorie und Eltern-Datensatz,
- exakter Storage-Pfad-Match im zugehörigen DB-Feld,
- Bucket-Allowlist nur für player-photos, profile-avatars, club-assets,
- Pfadpräfix/Owner-Relation stimmt mit Player-, User- oder Club-ID überein,
- kein Objekt außerhalb des expliziten Scope.

Die drei Buckets sind privat. Der privilegierte Admin-Client umgeht Storage-RLS; deshalb ist diese serverseitige Allowlist eine zwingende Sicherheitsgrenze, kein optionaler Filter.

## 2. Zuordnung nach Scope (Vorschlag zur fachlichen Bestätigung)

### Mannschaftsbackup
- Spielerfoto: ausschließlich players.photo_path von im ausgewählten Team exportierten Spielern; Pfad muss team_id/player_id entsprechen.
- Profilavatar: nur profiles.avatar_url für User, die über die autorisierte Teammitgliedschaft in diesem Team liegen; Owner-/User-ID und Pfad müssen übereinstimmen.
- Vereinslogo/Club-Assets: nicht automatisch alle Dateien des Vereins in ein Teambackup aufnehmen. Nur wenn ein expliziter Assetumfang gewählt und die Rolle diesen Verein/Asset-Kontext verwalten darf.

### Vereinsbackup
- Spielerfotos: referenzierte photo_path-Dateien aller Teams des autorisierten Vereins.
- Profilavatare: nur referenzierte Avatare der im ausgewählten Vereinsumfang enthaltenen Benutzer.
- Club-Assets: referenzierte Objekte des exakt ausgewählten Vereins, unter dessen Club-ID-Prefix.

## 3. Referenzierte und verwaiste Objekte

- Nur DB-referenzierte Dateien in das Backup aufnehmen.
- Nicht referenzierte Storage-Objekte (aktuell DEV: 2 profile-avatars) als Ausschlusszahl/Status im Manifest dokumentieren, aber nicht exportieren und niemals automatisch löschen.
- Bei DB-Referenz ohne Storage-Objekt: Export mit klarer Fehler-/Unvollständigkeitsmeldung abbrechen oder als ausdrücklich fehlende Datei markieren. Kein stilles „vollständiges Backup“ ausgeben.
- Doppelte Referenzen auf dasselbe Objekt deduplizieren; Manifest listet jede Datei genau einmal und alle zugehörigen DB-Referenzen.

## 4. Datei-Manifest

Für jede enthaltene Datei mindestens:
- stabiler interner Asset-Key und Kategorie,
- bucket_id und relativer Storage-Pfad,
- MIME-Typ, Größe, last-modified/created metadata (soweit vertrauenswürdig),
- SHA-256 der tatsächlich heruntergeladenen Bytes,
- zugehörige DB-Referenz/Parent-ID,
- Ergebnisstatus (included / missing / excluded_unreferenced).

Keine Signed URL und keine Auth-/Service-Role-Credentials in das Archivmanifest schreiben.

## 5. Paketaufbau – technischer Vorschlag, noch zu entscheiden

Empfohlene Struktur vor Verschlüsselung:
- manifest.json (Backup-Formatversion, Scope, Kategorien, erzeugter Zeitpunkt, Tabellen-/Dateizählung, Hashliste)
- database/snapshot.json (JSON-Daten)
- assets/<asset-key>.<safe-extension> (Originalbytes; Dateiname nicht direkt aus untrusted Storage-Pfad übernehmen)

Vorgeschlagene sichere Reihenfolge:
1. scoped DB-Snapshot und Allowlist erstellen,
2. erlaubte Storage-Objekte via Storage API downloaden,
3. MIME/Size gegen Bucket- und Manifestgrenzen prüfen,
4. SHA-256 pro Datei berechnen,
5. Manifest vervollständigen,
6. Paket komprimieren,
7. Gesamtpaket verschlüsseln,
8. Download erst nach vollständigem Erfolg bereitstellen; temporäre Bytes bei Fehler verwerfen.

### Noch nicht final festgelegt
- ZIP-Implementierung und kompatible, gepinnte Deno/npm-Version.
- AES-GCM oder ein etabliertes AES-256-ZIP-Verfahren; Schlüssel-/Passwortableitung und Wiederherstellbarkeit.
- Passwort wird nicht serverseitig gespeichert oder in Logs geschrieben.
- Gesamtpaket-Hash/Signatur und Verifikationsablauf.
- Größen-/Speichergrenzen für Edge Function; große Exporte ggf. gestreamt oder in einen privaten temporären Bucket mit Ablauf-/Löschkonzept.

Diese Entwurfsoptionen sind keine bereits bestätigte Nutzerentscheidung. Vor Umsetzung des Verschlüsselungs-/Archivformats ist eine fachliche Freigabe erforderlich.

## 6. Akzeptanztests

- Fremder Team-/Club-Scope wird abgewiesen, auch wenn ein Objektpfad bekannt ist.
- Manipulierte Bucket-/Path-Angaben vom Client werden ignoriert oder abgewiesen.
- Ein Teamexport enthält keine anderen Team-Player-Fotos.
- Ein Teamexport nimmt keine Club-Assets ohne explizite Asset-Auswahl auf.
- Unreferenzierte Avatar-Dateien werden nicht exportiert und nicht gelöscht.
- Manifest-Dateizahl, Bytes, Größen und SHA-256 stimmen nach Download.
- Passwort-/Schlüsselmaterial ist nicht im Serverlog, DB, Git oder Chat.
- Verschlüsseltes Archiv lässt sich nach Download mit dem vorgesehenen Verfahren lokal entschlüsseln und validieren.
- Abgebrochener Export liefert kein scheinbar vollständiges Archiv.

## 7. Verweise

- Aktuelle Live-Inventur und AP-BR02-Status: docs/AP_BR02_BACKUP_EXPORT_INVENTORY_REVIEW_2026-11-21.md, Abschnitt 19.
- Übergabe-/Chatcheckpoint: docs/AP_BR02_STATUS_HANDOFF_2026-11-21.md.
- HTTP-Testmatrix: docs/AP_BR02_CREATE_BACKUP_DEV_HTTP_TESTS.md.
- IMG-SEC-01/02/03 enthält die bereits beschlossenen Storage-Berechtigungen und privaten Bucket-Grundlagen.

Keine Datenbank-, Storage- oder Edge-Function-Änderung in diesem Entwurf. Restore bleibt ausgesetzt.


## 8. Paketierungs- und Verschlüsselungsvorschlag (technische Empfehlung, 21.11.2026)

Nach Abwägung von Edge-Function-Laufzeit/Memory und dem iPhone-Browser wird für die erste sichere Ausbaustufe folgender Ablauf empfohlen. Das ist eine technische Empfehlung, keine bereits vom Nutzer bestätigte fachliche Festlegung.

### 8.1 Verantwortlichkeiten

1. **Edge Function:** Authentifiziert den Nutzer, prüft Rolle und expliziten Scope, erstellt DB-Snapshot und eine serverseitig validierte Liste der exakt referenzierten Storage-Objekte. Sie liefert keine fremden Pfade und keinen privilegierten Schlüssel an den Client.
2. **Dateiübertragung:** Dateien werden aus dem privaten Storage nur über eine serverseitig erzeugte, eng begrenzte Auswahl übertragen. Bevorzugt werden kurzlebige, objektspezifische Download-URLs oder ein kontrollierter Download-Endpunkt. URLs sind Bearer-Geheimnisse, dürfen nicht in Logs/Manifest persistiert werden und müssen kurz ablaufen.
3. **Browser auf dem iPhone:** ZIP-Paketierung und Verschlüsselung erfolgen lokal für einen begrenzten Exportumfang. Der Schlüssel bleibt beim Nutzer; Server und Datenbank speichern das Backup-Passwort nicht.
4. **Manifest:** enthält Format-/Schema-Version, Scope, Kategorieumfang, Erstellzeit, Tabellen-/Dateizahlen, Dateipfade innerhalb des Archivs, Größen und SHA-256-Hashes. Keine Signed URLs, JWTs oder Credentials.
5. **Abschluss:** Der Export wird nur als erfolgreich angezeigt, wenn alle erwarteten Dateien geladen, geprüft, gepackt und verschlüsselt wurden. Teilpakete werden verworfen und nicht als Backup angeboten.

### 8.2 Verschlüsselungs- und Schlüsselmodell (Empfehlung)

- Für den ersten Prototyp: clientseitige Passwortverschlüsselung mit Web Crypto, PBKDF2-HMAC-SHA-256 zur Schlüsselableitung, zufälligem Salt und AES-256-GCM mit eindeutigem zufälligem IV pro Verschlüsselung.
- Salt, IV, KDF-Parameter und Formatversion werden im unverschlüsselten Paketheader abgelegt; Snapshot, Dateien und Manifest bleiben innerhalb des verschlüsselten Payloads.
- Passwort wird weder an die Edge Function gesendet noch serverseitig gespeichert oder protokolliert. Nutzer muss es außerhalb des Backups sicher aufbewahren; Verlust bedeutet keine Wiederherstellung.
- Die Implementierung muss KDF-Parameter versionieren, Zufallswerte über Web Crypto erzeugen und eine lokale Entschlüsselungs-/Integritätsprüfung anbieten.
- Keine selbstentwickelte Kryptografie; etablierte, auditierte ZIP-/Crypto-Bibliotheken mit gepinnten Versionen verwenden und vor Freigabe auf iOS Safari testen.

### 8.3 Größen- und Mobilgrenze

Clientseitiges ZIP und AES können mehrere Kopien im RAM halten. Deshalb muss die erste Stufe einen konfigurierten Gesamtgrößen- und Objektzahl-Grenzwert haben. Wird dieser überschritten, muss der Export vor dem Download klar abbrechen und den Umfang anzeigen; keine automatische unverschlüsselte Ausweichdatei.

Ein konkreter Startgrenzwert (z. B. 50 MiB) ist vor Implementierung mit einem realistischen DEV-Datensatz auf iPhone/Safari zu messen und zu bestätigen. Der Wert ist noch nicht festgelegt.

### 8.4 Offene Entscheidungen vor Code

- Akzeptierst du das vorgeschlagene clientseitige Passwortmodell (Passwort wird nicht serverseitig gespeichert; Verlust = Backup nicht entschlüsselbar)?
- Soll das erste Paket ein verschlüsseltes ZIP mit etabliertem AES-Format sein, oder ein eigenes versioniertes Containerformat mit AES-GCM? ZIP ist einfacher zu öffnen; GCM-Container bietet eine klarere Authentifizierung, braucht aber eine eigene lokale Tooling-/Recovery-Unterstützung.
- Welche maximale Exportgröße soll die erste iPhone-fähige Version zulassen? Empfehlung: zuerst messen und danach begrenzen, nicht vorab willkürlich festsetzen.

Bis diese Punkte bestätigt und die Bibliotheken geprüft sind, keine Verschlüsselungsimplementierung und keine UI-Freigabe.


## 9. Bibliotheksprüfung – ZIP/AES/iOS (21.11.2026)

### 9.1 Ergebnis der Recherche

- **zip.js (@zip.js/zip.js)** ist der derzeit passendste Kandidat für einen kontrollierten Prototyp: Browser-/Deno-Unterstützung, Web-Streams, ZIP64, AES-128/192/256 sowie AES-verschlüsselte ZIP-Einträge. Aktuelle Paketmetadaten zeigen Version 2.24.0; vor Integration muss die konkrete Version geprüft und im Projekt fest gepinnt werden.
- zip.js dokumentiert AES-256 im ZIP-AE-2-Verfahren. Der Bibliothek wird die Passwortverschlüsselung übergeben; keine eigene AES-/PBKDF2-Kryptografie implementieren.
- ZIP-AES ist nicht dasselbe wie ein eigenes AES-GCM-Containerformat. Für die erste Nutzerdatei ist das interoperable ZIP-AES-256 vorzuziehen, sofern Entschlüsselung in den üblichen Desktop-Archivprogrammen und iOS-Workflow praktisch getestet wird.
- **fflate** ist ein guter schneller ZIP-/DEFLATE-Kandidat, unterstützt laut Paketvergleich aber keine ZIP-Verschlüsselung. Deshalb nicht allein für das finale verschlüsselte Backup einsetzen.
- Web Crypto ist breit verfügbar und läuft nur in sicheren Kontexten (HTTPS); es bleibt für zufällige Werte und ggf. Hash-/Integritätsoperationen geeignet. Die ZIP-AES-Schlüsselableitung sollte jedoch ausschließlich von der etablierten ZIP-Bibliothek übernommen werden, um doppelte/inkompatible Verschlüsselungsschichten zu vermeiden.
- zip.js basiert auf Web Streams/TransformStream. Die Projektseite nennt Safari-Unterstützung ab Safari 14.1 für die relevanten Web-Streams, weist aber auf mögliche Geräte-/Runtime-Abweichungen hin. Deshalb bleibt der reale iPhone-/Safari-Test ein Freigabekriterium.
- Besonderer Speicherhinweis aus zip.js: der Blob-Temp-Stream-Helper hält unter Safari beim Erstellen eines Blobs mehrere Kopien (in der Dokumentation etwa vierfacher Spitzenbedarf) und soll dort nicht verwendet werden. Für Safari ist eine OPFS-/dateibasierte Temp-Stream-Strategie oder ein streng begrenzter Prototyp nötig; OPFS-Zugriff mit SyncAccessHandle benötigt einen Dedicated Worker. Diese Architektur muss praktisch getestet werden, bevor wir einen Größenwert festlegen.

### 9.2 Vorläufige technische Empfehlung

**Prototyp-Option A – ZIP-AES-256 (bevorzugt zur Validierung):**
- gepinnte Version von \`@zip.js/zip.js\`;
- AES-256 ZIP-AE-2; Passwort nur lokal im Browser, nicht an Supabase senden;
- Daten und Asset-Bytes zunächst in einen kontrollierten Stream/Temp-Speicher führen;
- keine zweite AES-GCM-Verschlüsselung des gesamten ZIP (vermeidet doppelte Kryptoschicht und erschwerte Dateikompatibilität);
- Hashmanifest im ZIP-Inhalt, Hashwerte der finalen Assets vor dem Einpacken;
- vor Ausgabe mit unabhängiger ZIP-Implementierung/Archiv-App entschlüsseln und prüfen.

**Option B – eigener AES-GCM-Container:** nicht für erste Stufe empfohlen. Erfordert eigene Format-/Recovery-/Tooling-Unterstützung und erhöht Wartungsrisiko; nur wählen, falls ZIP-AES-Interoperabilität oder nachweisbare Sicherheitsanforderungen es erzwingen.

### 9.3 Noch nicht als Nutzerentscheidung festgelegt

Diese Recherche ist keine fachliche Freigabe. Vor Implementierung weiterhin zu bestätigen:
1. ZIP-AES-256 als Backup-Format akzeptieren (gegenüber eigenem GCM-Container).
2. Passwort bleibt ausschließlich beim Nutzer; Verlust macht Backup unlesbar.
3. Maximalgröße und maximale Objektzahl erst nach iPhone-Test festlegen.

### 9.4 Prototyp-Testkriterien

- aktuelle und älteste unterstützte iOS-/Safari-Version prüfen;
- Export in Worker, sofern Temp-/OPFS-Verfahren es erfordert;
- Speicherbedarf und Laufzeit bei Testpaketen verschiedener Größen messen;
- AES-256-ZIP in einer unabhängigen Desktop-Archiv-App und auf iPhone entschlüsseln;
- falsches Passwort und manipuliertes Archiv müssen Fehler liefern, kein Teil-Backup als Erfolg;
- keine Passwort-/Tokenwerte in Logs oder Netzwerkrequests;
- Paketheader, Manifest und Formatversion so gestalten, dass spätere Bibliothekswechsel kontrolliert migrierbar sind.

Quellen:
- zip.js Paket-/Feature-Metadaten und AES-/Web-Streams-Funktionen: https://github.com/gildas-lormeau/zip.js
- zip.js ZIP-AES-Optionen und AE-2: https://github.com/gildas-lormeau/zip.js/blob/master/docs/interfaces/ZipWriterConstructorOptions.md
- zip.js Browser-/Web-Streams-/Safari-Temp-Stream-Hinweise: https://github.com/gildas-lormeau/zip.js
- fflate ZIP-Funktionen und fehlende Verschlüsselung: https://www.npmjs.com/package/fflate
- Web Crypto secure-context availability: https://developer.mozilla.org/en-US/docs/Web/API/Web_Crypto_API
- OWASP Cryptographic Storage Guidance: https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html


## 10. Projektintegration – read-only Prüfung develop (21.11.2026)

### Ist-Aufbau
- Haupt-App ist eine einzelne statische \`index.html\` mit einem großen \`<script type="module">\`-Block.
- Bereits vorhandener ESM-Import: Supabase JS über eine CDN-URL; kein lokales npm-Projekt.
- Im Root gibt es keine \`package.json\`, \`package-lock.json\`, Vite-/Webpack-/Rollup-Konfiguration oder Build-Skript.
- GitHub Pages wird aus Branch/Repository-Inhalt bereitgestellt. \`.github/workflows/deploy-dev.yml\` pusht bei Änderungen an \`develop\` automatisch den Branch in das separate DEV-Repository \`bautnhaus/jugendmannschaft-dev\`; keine Bundling-Stufe.
- Service Worker cached derzeit nur \`./\`, \`./index.html\` und \`./manifest.json\`; eine neue lokale Vendor-Datei würde ohne Cache-Update nicht offline verfügbar sein. Der Backup-Prototyp darf den normalen App-Start dennoch nicht blockieren.

### Konsequenz für zip.js
Ein npm-Install mit Build-/Bundler-Einführung wäre ein größerer Architekturwechsel und ist für diesen Prototyp nicht erforderlich.

Empfohlener Weg zur kontrollierten DEV-Probe:
1. Eine exakt gepinnte zip.js-Version (aktuelle npm-Suche am 21.11.2026 meldet 2.25.0; Versionsstand unmittelbar vor Aufnahme erneut verifizieren) als lokal versionierte Vendor-Assets im Repo bereitstellen, nicht als unversioniertes CDN-\`@2\`.
2. Lizenz-/NOTICE-Datei, Upstream-URL, Paketversion und SHA-256 der übernommenen Distributionsdateien dokumentieren.
3. Erst nach Prüfung der offiziellen Distribution festlegen, ob einzelne minifizierte Datei oder zugehörige Worker-/WASM-Dateien benötigt werden. Worker-/WASM-Pfade müssen relativ zur ausgelieferten Datei korrekt funktionieren; keine Blob-Worker-Annahme ohne iOS-/CSP-Test.
4. Backup-Code als separate lazy-load Funktion/Modul ausführen; keine statische Import-Abhängigkeit am App-Start. Wenn Vendor-Asset fehlt oder nicht lädt, reguläre App bleibt nutzbar und Export zeigt verständlichen Fehler.
5. Der erste Test ist ein isolierter ZIP-AES-Passwort-/Entschlüsselungstest mit ausschließlich synthetischen Text-/Bilddaten. Keine Supabase-Daten, Tokens oder echten Nutzerfotos.
6. Service Worker Cache-Liste nur dann erweitern, wenn die offline Nutzung des Backup-Prototyps ausdrücklich geprüft wird; Backup-Export soll zunächst online-only bleiben.

### Versionshinweis
Der vorherige Abschnitt 9 nannte 2.24.0 als aktuelle Paketversion. npm-Suchergebnis am 21.11.2026 meldet inzwischen 2.25.0. Das ist eine Rechercheaktualisierung, keine Abhängigkeit im Code: Noch wurde kein Paket in das Repo übernommen oder importiert.

### Ergebnis / nächste konkrete Aktion
Projektstruktur ist für einen **isolierten DEV-Test ohne Build-System** geeignet. Nächster Schritt: offizielle zip.js-Distribution und deren Worker-/WASM-Dateien/License prüfen, danach einen separaten Testscreen bzw. Test-HTML mit lokal gepinnten Assets erstellen. Erst nach erfolgreichem ZIP-AES-Interoperabilitäts- und iPhone-Test in die Backup-UI integrieren.


## 11. Distribution-/API-Prüfung und Prototyp-Integrationsentscheidung

Read-only anhand der offiziellen zip.js-Dokumentation und Paket-/Releaseinformationen geprüft (21.11.2026):

- Exakte npm-Version zum aktuellen Recherchezeitpunkt: **2.25.0** (nicht 2.24.0). Diese Versionsnummer ist nur Recherchestand, noch nicht als Dependency im Code installiert.
- zip.js bietet AES-verschlüsselte ZIP-Einträge im WinZIP-AES-Verfahren; mit Passwort wird AES AE-2 verwendet. Der Authentifizierungscode schützt die Einträge; CRC-Feld wird bei AE-2 auf 0 gesetzt, um keinen Klartext-Hash-/Guessing-Hinweis preiszugeben.
- Die API unterstützt \`ZipWriter\`, Reader/Writer und \`createTempStream\`; für große Daten gibt es OPFS-Temp-Streams sowie einen SyncAccessHandle-Temp-Stream, der nur im Dedicated Worker funktioniert.
- Der Blob-Temp-Stream ist für Safari ausdrücklich ungeeignet: laut API-Dokumentation kann er ungefähr das Vierfache der Entry-Größe als Spitzenbedarf halten. Für Safari daher nicht einsetzen.
- Die offizielle Doku beschreibt manuelle Einbindung eines \`dist\`-Bundles, jedoch müssen beim gewählten Bundle die zugehörigen Worker-/WASM-Dateien und relativen URLs mitgeführt werden. Die konkrete distributable Datei samt SHA-256 ist noch nicht in das Repository übernommen/verifiziert.

### Konkrete DEV-Prototyp-Entscheidung (Arbeitsvorschlag)
- Keine npm-/Bundler-Einführung.
- Vendor der exakt gepinnten offiziellen Distribution unter \`vendor/zipjs/2.25.0/\` mit Lizenz, Upstream-/Release-URL und Prüfsummen.
- Eine separate, nicht in der App-Navigation verlinkte Testseite im develop-Repository; ausschließlich synthetische Inhalte (kleine Textdatei und erzeugtes Testbild), keine Supabase-Anmeldung oder App-Daten.
- Testseite prüft ZIP-Erstellung mit Passwort, Öffnen/Entschlüsseln mit derselben Bibliothek, falsches Passwort, beschädigtes Paket und Download einer Testdatei. Anschließend unabhängiger Test mit Desktop-Archivprogramm.
- Erst nach erfolgreicher ZIP-/Crypto-Prüfung ein Worker-/OPFS-Prototyp für RAM-/Laufzeitmessung. Der normale App-Start darf nicht von Vendor-Assets abhängen.
- Diese Testseite ist noch nicht angelegt; bisher nur Dokumentation und Recherche.

Offizielle Quellen:
- ZIP.js Features, AES, Browser-Kompatibilität und manuelle Distribution: https://gildas-lormeau.github.io/zip.js/
- Version 2.25.0 Release: https://newreleases.io/project/npm/%40zip.js/zip.js/release/2.25.0
- ZIP-AES AE-2 / Passwortoption: https://gildas-lormeau.github.io/zip.js/api/interfaces/ZipWriterConstructorOptions.html
- OPFS-/Blob-Temp-Stream- und Safari-Speicherhinweise: https://github.com/gildas-lormeau/zip.js/blob/master/index.d.ts


## 12. ZIP.js vendored und isolierter Test bereitgestellt (21.11.2026)

### DEV-Artefakt
- Exakte Upstream-Tag-Version v2.25.0, Datei `dist/zip.min.js` lokal ins Repository übernommen: `vendor/zipjs/2.25.0/zip.min.js`.
- Upstream BSD-3-Clause-Lizenz beigefügt: `vendor/zipjs/2.25.0/LICENSE`.
- Provenienz dokumentiert: `vendor/zipjs/2.25.0/PROVENANCE.md`.
- GitHub-Upstream-Git-Blob-SHA-1 des exakt übernommenen Bundle-Inhalts: `3eb3136ea6e6699188f89f8c431b10b6b435756f`. Das ist ausdrücklich SHA-1/Git-Objektidentität, **kein SHA-256**. Ein SHA-256 wurde in dieser Laufzeit nicht unabhängig berechnet; keine falsche Prüfsumme behaupten.
- Laut offizieller `dist/README.md` ist `zip.min.js` ein Standalone-Bundle mit eingebettetem Worker und WASM. Daher sind für diesen Bundletyp keine separaten Worker-/WASM-Dateien erforderlich; externe Varianten hätten diese Begleitdateien gebraucht.

### Isolierte Testseite
- `docs/dev-tests/ap-br02-zipjs-test.html` angelegt. Nicht in die App-Navigation eingebunden.
- Nur synthetische Testdateien, keine Supabase-Verbindung, kein Nutzer-/Spieler-/Profilinhalt.
- Prüft Passwort-ZIP-AES-256, lokalen Entschlüsselungsrundlauf und Datei-Download. Die Seite zeigt Browserinformationen und Paketgröße für die manuelle iPhone-Prüfung.
- Unabhängige Desktop-Archivprüfung, iPhone/Safari-RAM-/Laufzeittest und falsches Passwort/Manipulationsprüfung sind noch auszuführen; noch keine Testabnahme.

Commit: `9189d10538386bfdf350a08c6e02add8d94a6023`. Der Commit liegt auf `develop`; der vorhandene DEV-Sync-Workflow wird dadurch ausgelöst. PROD/main wurde nicht geändert. Keine Datenbank-/Storage-Operation.
