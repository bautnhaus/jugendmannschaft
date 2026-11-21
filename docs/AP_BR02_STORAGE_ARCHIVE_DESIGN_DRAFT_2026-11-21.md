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
