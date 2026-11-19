# KADAssist – IMG-SEC-02 / Paket 2: Frontend-Unterbau private Bilder

- Stand: Vorbereitung 18.11.2026
- Branch-Referenz: develop
- Frontend-Baseline-Commit: 9d0fb6582d2dfb12ba31027b000d0829d8853ea7
- Datei: index.html (606.192 Zeichen beim Abruf)
- Status: Paket 2A – Resolver-Grundlage in develop implementiert; nicht deployed, nicht funktional im Browser getestet
- Abhängigkeit: IMG-SEC-01 Paket 1A in DEV ausgeführt.

## 1. Ist-Stand aus develop/index.html

Die Datei wurde frisch aus develop abgerufen:
- uploadProfileAvatar(userId,dataUrl) lädt nach profile-avatars und gibt aktuell getPublicUrl(path) zurück.
- Profilbilder werden in profiles.avatar_url als URL gespeichert und direkt als img src ausgegeben.
- Vereinswappen liegen als Pfad in clubs.crest_path; die Anzeige verwendet mehrfach getPublicUrl(crest_path).
- Spieler werden mit photo_data geladen; photo_path wird noch nicht gelesen.
- Spielerbilder werden als Data URL über save_player_with_positions(p_photo_data) gespeichert.
- playerAvatarHtml(photo) rendert direkt img src=photo.
- createSignedUrl() wird nicht verwendet.
- Profilbilder erscheinen in Mitglieder-/Trainerlisten, Profilformularen und Eigenprofil.
- Vereinswappen erscheinen im Dashboard, in Vereinslisten/-details und im Team-/Kontextbereich.
- Spielerbilder erscheinen in Spielerliste, Spielerkarte, Trainings-, Spieltags-, Ereignis- und historischen Ansichten.

## 2A. Umgesetzte Resolver-Grundlage (DEV-Branch, noch nicht deployed)

Am 18.11.2026 wurde in `index.html` auf `develop` die erste technische Grundlage ergänzt:

- Allowlist für die Buckets `player-photos`, `profile-avatars` und `club-assets`.
- `resolvePrivateImage(bucket,path)` erzeugt Signed URLs über `createSignedUrl` mit 300 Sekunden Gültigkeit.
- Signed URLs werden nur in einer JavaScript-Map im Arbeitsspeicher zwischengespeichert; es gibt keine localStorage-/sessionStorage-Persistenz.
- Erneuerung erfolgt 30 Sekunden vor dem angenommenen Ablaufzeitpunkt.
- Cache-Key enthält Bucket und Storage-Pfad.
- Ein Kontext-Fingerprint aus Benutzer-, Team-, Vereins- und Admin-Kontext leert den Cache automatisch, sobald ein anderer Kontext beim nächsten Resolver-Aufruf erkannt wird.
- `clearPrivateImageCache()` und `resetImageContext()` stehen für explizite Invalidierung bereit.
- Logout leert den Cache unmittelbar.

### Grenzen / noch nicht erledigt

- Der Resolver ist noch nicht an bestehende Bild-Renderpfade angeschlossen.
- Die Buckets `profile-avatars` und `club-assets` sind weiterhin öffentlich; es wurde kein Bucket-Cutover durchgeführt.
- Es wurde keine SQL-Änderung und keine Storage-Policy-Änderung vorgenommen.
- Fehlerbehandlung mit genau einem erneuten Auflösungsversuch nach Bildladefehler/401/403 ist noch nicht implementiert.
- Team-/Vereinskontext wird derzeit beim nächsten Resolver-Aufruf anhand des Fingerprints erkannt; ein unmittelbarer zentraler Hook bei jedem Kontextwechsel kann in einem Folgeschritt ergänzt werden, falls Tests dies erfordern.
- Kein DEV-Deploy und noch keine Browser-/Rollenprüfung.

## 2B. Profilbilder und Vereinswappen auf Signed URLs umgestellt (develop, noch nicht deployed)

**Commit:** `b86f8726237e567aa58b33d8b2ea3a9512718caf`

Umgesetzt in `index.html`:

- Profilbild-Uploads liefern nun den Storage-Pfad statt einer Public URL zurück.
- Eigene Profilansicht und Profil-Editor verwenden private Bild-Markups.
- Team-Mitglieder-/Trainerlisten und Bearbeitungsdialoge verwenden private Bild-Markups.
- Vereinsmitgliederlisten und Mitgliederkarten verwenden private Bild-Markups.
- Vereinswappen im Dashboard, in der Superadmin-Vereinsliste, im Vereinsbearbeitungsdialog, in der Vereinsdetailansicht und im Teamkontext verwenden den Resolver.
- Alle bisherigen `getPublicUrl()`-Aufrufe in `index.html` wurden entfernt.
- Dynamisch eingefügte Bild-Markups werden über einen `MutationObserver` erkannt und mit Signed URLs geladen.
- Bestehende `avatar_url`-Werte im bisherigen Public-URL-Format werden beim Rendern auf ihren Storage-Pfad zurückgeführt. Neue Uploads speichern direkt den Pfad.

### Technische Hinweise

- Signed URLs werden über den Resolver mit 300 Sekunden Laufzeit erstellt.
- Signed URLs bleiben ausschließlich im Arbeitsspeicher-Cache.
- Ein Bildfehler führt zum Fallback/Verbergen des Bildes; es gibt derzeit noch keinen automatischen zweiten Retry nach 401/403.
- Profilbilder und Vereinswappen können erst erfolgreich geladen werden, wenn ihre Storage-Buckets privat sind und die vorgesehenen SELECT-Policies greifen. Solange die Buckets öffentlich sind, erzeugt die Storage API weiterhin Signed URLs, aber die vollständige Zugriffstrennung ist damit noch nicht bewiesen.
- Die existierenden Profil-RPCs schreiben weiterhin in `profiles.avatar_url`; der Inhalt ist nun als Storage-Pfad vorgesehen. Keine RPC- oder Datenbanksignatur wurde geändert.
- Vereinswappen bleiben in `clubs.crest_path` als Storage-Pfad gespeichert.

### Nicht durchgeführt

- Kein SQL und keine Migration.
- Keine Storage-Policy- oder Bucketänderung.
- Kein DEV-Deploy und kein Browser-/Rollen-Praxistest.
- Keine Änderung an PROD.

## 2. Zielarchitektur

Zentrale Funktionen:
1. resolvePrivateImage(bucket,path,options): liefert eine gültige kurzlebige Signed URL.
2. loadPrivateImage(bucket,path,options): lädt bei Bedarf und behandelt Fehler/Fallback.
3. clearPrivateImageCache(): entfernt alle lokal zwischengespeicherten Signed URLs.
4. resetImageContext({userId,teamId,clubId}): invalidiert Cache bei Login/Logout und Team-/Vereinskontextwechsel.
5. Einheitliche Fallback-Ausgabe für Profilbild, Spielerfoto und Vereinswappen.

Cache:
- Cache-Key: bucket + path + context fingerprint.
- Zielgültigkeit: Signed URL ca. 5 Minuten; Erneuerung mit Sicherheitsabstand vor Ablauf.
- Nur Arbeitsspeicher; keine localStorage/sessionStorage-Persistenz.
- Bei abgelaufener URL, 401/403 oder Bildladefehler Cache-Eintrag einmal löschen und neu auflösen; danach Fallback.
- Cache bei Benutzer-, Team- oder Vereinswechsel vollständig leeren.
- Bereits ausgegebene Signed URLs bleiben bis zum Ablauf nutzbar (Bearer-Token-Eigenschaft).

## 3. Datenmodell und Pfade

### Spielerfotos
- Bucket: player-photos (privat).
- Pfad: team_id/player_id/eindeutiger-dateiname.ext.
- DB-Feld: players.photo_path.
- photo_data bleibt während Migration und Rückwärtskompatibilität erhalten.
- Upload erfolgt mit authentifiziertem Client; Storage-Policies prüfen Teammitgliedschaft und Player-Team-Zuordnung.
- Alle Mannschaftsmitglieder dürfen Storage-Dateien lesen, hochladen, ersetzen und löschen.
- save_player_with_positions muss später photo_path unterstützen; separate DB-Migration und Freigabe erforderlich.

### Profilbilder
- Bucket profile-avatars bleibt vorerst öffentlich.
- profiles.avatar_url muss beim Cutover von vollständiger Public URL auf Storage-Pfad migriert werden.
- Profil-Upload soll künftig den Storage-Pfad speichern, nicht getPublicUrl().
- Admin-RPCs admin_update_member_profile und admin_update_club_member_profile müssen auf Pfadsemantik geprüft und angepasst werden.

### Vereinswappen
- Bucket club-assets bleibt vorerst öffentlich.
- clubs.crest_path enthält bereits einen Storage-Pfad.
- Upload-/Löschrechte bleiben bei den bestehenden Vereinsadmin-/Superadmin-Berechtigungen.
- Alle direkten getPublicUrl()-Fundstellen werden auf den zentralen Resolver umgestellt.

## 4. Geplanter Implementierungsumfang

### 4.1 Bildinfrastruktur
- Zentraler Resolver und Cache mit Ablaufzeit.
- Einheitliche Ladezustände/Fallbacks.
- Kontextbindung und Cache-Invalidierung.
- Keine direkten getPublicUrl()-Aufrufe in finalen privaten Bildpfaden.

### 4.2 Spielerfotos
- Spieler-Queries um photo_path erweitern.
- photo_data schrittweise durch Pfadreferenz und asynchrones Laden ersetzen.
- playerAvatarHtml darf nicht mehr eine synchrone URL voraussetzen; Bildkomponenten müssen asynchron auflösen.
- Formularvorschau lokal halten; Upload nach player-photos; Pfad in photo_path speichern.
- save_player_with_positions braucht eine separat geprüfte Erweiterung für photo_path.
- Drei bestehende Data-URL-Spielerfotos separat migrieren und verifizieren. Alte photo_data-Werte erst danach entfernen.

### 4.3 Profilbilder
- Alle direkten Profilbild-img-src-Stellen asynchron auflösen.
- Upload-Funktion gibt Storage-Pfad zurück.
- Eigenprofil und Mitglieder-/Trainerlisten konsistent umstellen.
- Keine Erweiterung der profiles_select-Policy.

### 4.4 Vereinswappen
- Alle getPublicUrl()-Aufrufe für club-assets ersetzen.
- clubs.crest_path als Pfad beibehalten.
- admin_update_club_crest nur nach Live-Definition-/ACL-Prüfung weiterverwenden.

## 5. Reihenfolge / Paketgrenzen

1. Direkt vor Implementierung develop erneut abrufen und mit Baseline vergleichen.
2. Alle Bildreferenzen und Renderpfade vollständig inventarisieren.
3. Resolver/Cache und Kontextinvalidierung implementieren.
4. Profilbilder und Vereinswappen auf Signed URLs umstellen.
5. Spielerfoto-Pfad-Unterstützung vorbereiten; DB-RPC-Erweiterung separat planen.
6. Syntax-/statische Prüfungen durchführen.
7. DEV-Deploy und echte Rollen-/Kontexttests.
8. Erst nach erfolgreichem DEV-Cutover profile-avatars und club-assets auf privat stellen.
9. Bestehende Bilddaten migrieren/verifizieren; Backup/Restore bleibt Folgepaket.

## 6. Tests

- Eigenes Profilbild laden und ändern.
- Trainer sehen Profilbilder anderer Trainer derselben Mannschaft.
- Trainer anderer Mannschaften sehen diese Profilbilder nicht.
- Mannschaftsadmin sieht Profilbilder des eigenen Teams.
- Vereinsadmin sieht Profilbilder im eigenen Verein.
- Superadmin sieht nur im explizit ausgewählten Kontext.
- Spielerfotos im eigenen Team lesen, hochladen, ersetzen und löschen.
- Cross-Team-Zugriff und falsche Team-/Player-ID-Kombination ablehnen.
- Vereinswappen in Dashboard, Vereinsliste, Vereinsdetail und Teamkontext laden.
- Team-/Vereinswechsel und Logout invalidieren den Signed-URL-Cache.
- Abgelaufene URL einmal erneuern; bei erneutem Fehler Fallback zeigen.
- iPhone Portrait/Landscape sowie Light-/Darkmode prüfen.

## 7. Offene technische Prüfungen vor Codeänderung

- Upload-/Update-/Delete-Policies und Upsert-Verhalten für player-photos nochmals live prüfen.
- save_player_with_positions Signatur/Funktionskörper erneut auslesen und separat spezifizieren.
- Admin-Profil-RPCs prüfen, die avatar_url schreiben.
- Alle getPublicUrl()- und img-src-Fundstellen vollständig inventarisieren.
- Gespeicherte Profil-/Vereinsbildwerte und URL-/Pfadformat vor Normalisierung prüfen.
- Kein SQL, keine Frontendänderung und kein Deploy ohne separate Freigabe.

## 8. Lieferobjekte

- docs/IMG_SEC_02_FRONTEND_PRIVATE_IMAGES_PLAN_2026-11-18.md
- später: eigener DEV-Frontend-Commit und Testnachweis
- ggf. separate DB-Migration für save_player_with_positions
- separates Datenmigrations-/Cutover-Paket für Profilbilder, Spielerfotos und Vereinswappen


## 2C. Spielerfotos auf privaten Storage-Pfad umgestellt (develop)

- Datum: 18.11.2026
- Code-Commits:
  - `f2f56773eb44dcb869e788a0fde3de3b7248bbf4`
  - `c3d53352cbaeeba6ae8084a36d02c3edc5cb27dd`
  - `e5ce07b8517d267817598726714e9e7074b68aaa`
  - `834e5094ea0207962c90beb02f6eb6f7190a89d3`
- Status: in develop implementiert; noch nicht deployed und noch nicht im Browser getestet.
- PROD unverändert.

### Umsetzung

- Aktive und inaktive Spielerabfragen laden zusätzlich `players.photo_path`.
- Spieler-Renderfunktion unterstützt jetzt sowohl ältere Data-URLs als auch Storage-Pfade. Storage-Pfade werden über `privateImageMarkup('player-photos', ...)` und den bestehenden Signed-URL-Resolver angezeigt.
- Die Spielerkarten, Trainings-/Spieltagseinträge und historischen Spieleransichten verwenden `photo_path` vorrangig; `photo_data` bleibt als Rückwärtskompatibilität für alte Data-URLs verfügbar.
- Das Bearbeitungsformular initialisiert seine Vorschau aus `photo_path` (Fallback: `photo_data`).
- Neue Fotos werden nach Verkleinerung in `player-photos` unter `team_id/player_id/UUID.ext` hochgeladen; Upload erfolgt ohne Upsert mit neuem Objektpfad.
- Nach erfolgreichem Upload wird `players.photo_path` direkt über den authentifizierten Supabase-Client aktualisiert und der gespeicherte Wert anschließend geprüft.
- Beim Entfernen wird `photo_path` auf `NULL` gesetzt. Storage-Objekte werden bewusst nicht automatisch gelöscht.
- Bei der Neuanlage wird zuerst der Spieler über die bestehende RPC ohne Bild angelegt; danach wird das Bild hochgeladen und der Pfad gespeichert. Bei einem fehlgeschlagenen Foto-Upload bleibt der Spieler bestehen und die UI meldet den Teilfehler.
- Die bestehende RPC `save_player_with_positions` wurde nicht verändert; sie erhält bei neuen und bearbeiteten Spielern `p_photo_data: null`. Bei älteren Data-URL-Fotos wird die Vorschau beim Speichern in den neuen Storage-Pfad migriert.
- Es wurden keine SQL-, Storage-Policy- oder Bucketänderungen vorgenommen.

### Bewusste Grenzen / Folgearbeiten

- Backup-/Restore-Funktionen verwenden weiterhin `photo_data`; Storage-Dateien und `photo_path` sind noch nicht Bestandteil eines vollständigen Foto-Backups. Backup-/Restore-Anpassung bleibt separat und ist vor einer PROD-Freigabe zu klären.
- Alte Storage-Objekte werden bei Bildwechsel/Entfernen nicht gelöscht; eine gesonderte, kontrollierte Bereinigung bleibt offen.
- Browser-/Praxistests für Upload, Ersetzen, Entfernen, Neuanlage und Rollenberechtigungen stehen aus.
- Kein DEV-Deploy und keine Änderung an PROD.


## 2D. Foto-Aktionsmenü im Spielerformular robust öffnen

- Datum: 18.11.2026
- Commit: `4ac053d57c7c9d56812e2cf926281438343364e3`
- Status: auf develop umgesetzt; DEV-Deployment und iPhone-Browsertest ausstehend.
- PROD unverändert.

### Änderung

- `openPhotoSheet()` öffnet das Aktionsmenü jetzt unabhängig davon, ob bereits ein Bildpfad im Vorschau-Element erkannt wird.
- Bei vorhandenem Bild werden „Foto ändern“, „Foto löschen“ und „Abbrechen“ angeboten.
- Ohne vorhandenes Bild werden „Foto hinzufügen“ und „Abbrechen“ angeboten.
- Fehlt das Menüelement, wird eine sichtbare Fehlermeldung angezeigt, statt stillschweigend abzubrechen.
- Die Fotoauswahl wird weiterhin erst nach bewusster Auswahl der Menüaktion über den Datei-Input gestartet.
- Keine Datenbank-, Storage- oder PROD-Änderungen.


## 2E. Fotoaktion im bestehenden Spieler-Bearbeitungsdialog direkt binden

- Datum: 18.11.2026
- Commit: `5f234f43c4b2a9696914576d5534e5de20f19315`
- Status: auf develop umgesetzt; DEV-Deployment und Praxistest ausstehend.
- PROD und Datenbank unverändert.

### Befund und Korrektur

- Foto hinzufügen bei der Neuanlage und Fotoaktionen bei Profil/Vereinslogo funktionieren; das allgemeine Fotoaktionsmenü ist daher nicht die primäre Fehlerstelle.
- Im bestehenden Spieler-Bearbeitungsdialog wurde der Foto-Button bisher ausschließlich über einen inline `onclick`-Handler aus dem dynamisch erzeugten Formular verdrahtet.
- Nach dem Rendern des Bearbeitungsdialogs wird der Button jetzt explizit über einen direkten Event-Listener gebunden. Der Listener verhindert das Default-Verhalten und stopPropagation und öffnet gezielt `openPhotoSheet('edit')`.
- Die Initialisierung prüft außerdem, ob Vorschau und Datei-Input im Dialog vorhanden sind, und zeigt andernfalls einen sichtbaren Fehler.
- Der Datei-Input bleibt an die bestehende Upload-/Resize-Logik gebunden.
- Keine SQL-, Storage-, Bucket- oder PROD-Änderung.


## 2G. Spielerfoto-Dateiauswahl an funktionierendes Profilbild-Muster angeglichen

- Commit: `d53307eeacb459afad89a77d59b0346d3d7fd6fa`
- Status: auf develop umgesetzt; DEV-Deployment und iPhone-Test ausstehend.
- Profilbild- und Vereinslogo-Code außerhalb der Spielerverwaltung unverändert.

### Vergleich und Umsetzung

- Profilbild-Editor verwendet direktes Inline-`onclick` mit `document.getElementById('profileEditPhotoInput').click()`.
- Das Datei-Input verwendet die CSS-Klasse `hidden`, nicht `style="display:none"`.
- Die Spielerverwaltung verwendet nun dasselbe Muster: direkter Inline-Aufruf auf `newPhotoInput` bzw. `editPhotoInput`, mit identischer Input-Klasse und denselben akzeptierten Bildformaten (PNG/JPEG/WebP).
- Der zusätzliche Event-Listener `bindPlayerPhotoTrigger` wurde entfernt. `bindPhotoInput` bleibt ausschließlich für die Verarbeitung der ausgewählten Datei zuständig.
- Keine Datenbank-, Storage-, SQL- oder PROD-Änderung.


## 2H. Fotoentfernung im Spieler-Bearbeitungsformular ergänzt

- Datum: 18.11.2026
- Code-Commit: `4b6c302efef0a2f5587fb729f47a93a88cad2ce7`
- Status: auf develop umgesetzt; DEV-Deployment und Praxistest ausstehend.
- Keine SQL-, Storage-, Bucket- oder PROD-Änderung.

### Änderung

- Im bestehenden Spieler-Bearbeitungsformular gibt es neben „Foto ändern“ nun eine eigene Aktion „Foto entfernen“.
- Die Aktion wird nur angezeigt, wenn aktuell ein Foto in der Formularvorschau vorhanden ist.
- Nach dem Entfernen wird die Vorschau auf den Avatar-Fallback gesetzt und die Entfernen-Aktion ausgeblendet.
- Wird anschließend ein neues Foto ausgewählt, wird die Entfernen-Aktion wieder eingeblendet.
- Beim Speichern bleibt der bestehende Ablauf erhalten: `photo_path` wird auf `NULL` gesetzt, wenn `photoAction === 'remove'`.
- Der Datei-Auswahlmechanismus für neue und bestehende Fotos wurde nicht verändert.


## 2I. Bildentfernung per X-Kreis in Spieler- und Profilformular

- Datum: 18.11.2026
- Code-Commit: `61e98ad7863916c58eb1b371b33d7ecd461f77cc`
- Status: auf develop committed; Upload-/Ändern-/Entfernen-Praxistests inzwischen vom Nutzer als bestanden bestätigt.
- Keine SQL-, Storage-, Bucket- oder PROD-Änderung.

### Änderung

- Die bisherige separate Schaltfläche „Foto entfernen“ im Spielerformular wurde durch einen kleinen roten Kreis mit weißem X direkt oben rechts am Bild ersetzt.
- Die Funktion gilt für neue und bestehende Spieler. Nach einer Bildauswahl erscheint der X-Kreis; beim Entfernen wird nur die lokale Vorschau geleert.
- Derselbe X-Kreis wurde im Profilbild-Editor ergänzt.
- Der X-Kreis wird nur angezeigt, wenn ein Bild vorhanden ist.
- Bei Spielern markiert `photoAction === 'remove'` weiterhin die gewünschte Entfernung; beim Speichern wird `players.photo_path` auf `NULL` gesetzt. Bei einer Neuanlage wird ein vor dem Speichern entferntes Bild nicht hochgeladen.
- Beim Profilbild wird nach dem Entfernen `avatar_url` beim Speichern auf `NULL` gesetzt.
- Storage-Objekte werden weiterhin nicht automatisch gelöscht.
- Die vorhandene direkte Dateiauswahl über den bewährten Inline-Click-Mechanismus bleibt erhalten.
- Alle Inline-Scripts wurden vor dem Commit syntaktisch geprüft.
- DEV-/Browser-Test der beiden Entfernen-Aktionen steht noch aus.


## 2J. Profilbild-Aktionsbutton nach Entfernen dynamisch aktualisieren

- Datum: 18.11.2026
- Code-Commit: `d1202a20545c83f551ffd172c3b5dcf6f1c67745`
- Status: auf develop committed; DEV-Deployment und Praxistest ausstehend.
- Keine SQL-, Storage-, Bucket- oder PROD-Änderung.

### Befund und Korrektur

- Beim Spielerformular wurde der Aktionsbutton nach dem Entfernen bereits korrekt auf „Foto hinzufügen“ umgestellt.
- Im Profilbild-Editor war der Buttontext dagegen fest auf „Foto ändern“ gesetzt.
- Der Profilbild-Button wird nun abhängig vom tatsächlichen Vorschauzustand aktualisiert:
  - Bild vorhanden: „Foto ändern“
  - Kein Bild vorhanden: „Foto hinzufügen“
- Die Aktualisierung erfolgt beim Öffnen des Editors, nach einer neuen Bildauswahl und unmittelbar nach dem Entfernen per X.
- Die bestehende Speicherung von `avatar_url = NULL` beim Speichern ohne Bild bleibt unverändert.
- Inline-Scripts wurden syntaktisch geprüft.


## 2K. Signed-URL-Fehlerbehandlung und Cache-Invalidierung

- Datum: 19.11.2026
- Code-Commit: `48d8d0f4cefa3ef8670e867d7bd8961d4789ca5d`
- Branch: `develop`
- Status: implementiert, statisch geprüft und automatisch nach DEV deployed; funktionaler DEV-Browsertest steht noch aus.
- Keine SQL-, Storage-Policy-, Bucket- oder PROD-Änderung.

### Umsetzung

- `resolvePrivateImage(bucket, path, forceRefresh)` versucht die Erstellung einer Signed URL bei einem API-Fehler höchstens ein zweites Mal.
- Ein bereits zwischengespeicherter URL-Wert wird bei einem normalen Aufruf weiterverwendet, solange die Sicherheitsfrist von 30 Sekunden vor Ablauf nicht unterschritten ist.
- Bei einem tatsächlichen Bildladefehler (`img.onerror`) wird der Cache-Eintrag für genau dieses Bild entfernt und die Signed URL einmal erzwungen neu erstellt.
- Jeder Bildknoten erhält einen eigenen Retry-Zähler. Scheitert auch der zweite Bildladeversuch, wird das Bild ausgeblendet; es gibt keine Endlosschleife.
- Die Retry-Behandlung ist sowohl an dynamisch hydratisierte Bild-Markups als auch an direkt über `setPrivateImageElement` gesetzte Bilder gebunden.
- `loadApp()` leert den Signed-URL-Cache jetzt zu Beginn jedes App-Aufbaus. Damit werden erneute Anmeldungen sowie erneute Aufbauten nach einem Vereins-/Mannschaftskontextwechsel abgedeckt.
- Logout leert den Cache weiterhin unmittelbar vor dem Abmelden.
- Der bestehende Kontext-Fingerprint bleibt als zusätzliche Absicherung erhalten und leert den Cache, sobald ein abweichender Kontext beim nächsten Resolver-Aufruf erkannt wird.

### Noch offen

- Die Retry- und Cache-Invalidierungslogik ist noch nicht im DEV-Browser geprüft.
- Es muss insbesondere geprüft werden, dass ein abgelaufener bzw. ungültiger Signed-URL-Aufruf genau einmal erneuert wird und nach einem zweiten Fehler der Fallback greift.
- Login, Logout sowie Vereins-/Mannschaftskontextwechsel müssen im Browser getestet werden.
- Die drei Upload-/Ändern-/Entfernen-Funktionstests (Spielerfoto, Profilbild, Vereinslogo) wurden vom Nutzer bereits als bestanden bestätigt und müssen ohne Änderung an diesen Funktionen nicht wiederholt werden.



### 2K.1 Statische Prüfung und DEV-Deployment (19.11.2026)

- JavaScript-Syntaxprüfung der Inline-Scripts: bestanden. Der ES-Module-Import wurde für die Syntaxprüfung entfernt; beide Inline-Script-Blöcke ließen sich anschließend fehlerfrei kompilieren.
- GitHub-Actions-Workflow `Deploy DEV` für Code-Commit `48d8d0f4cefa3ef8670e867d7bd8961d4789ca5d`: erfolgreich (Run `44469136221`).
- Der anschließende Dokumentations-Commit `7f5335615c60f6541a99bfa85c7a40130f3127b5` löste ebenfalls einen erfolgreichen DEV-Deploy aus (Run `44469155117`).
- DEV-Repository `bautnhaus/jugendmannschaft-dev`, Branch `main`: `index.html`-Blob-SHA stimmt exakt mit dem geprüften develop-Stand `cc2ff9534d3847e9e9c343f3da2b741c865c5b9c` überein.
- Damit ist das Frontend auf DEV deployed. Es erfolgte keine Änderung an Supabase-Datenbank, Storage-Konfiguration oder PROD.
- Der funktionale iPhone-/Browser-Praxistest ist noch offen.



## 2L. Read-only-Prüfung Profilbild-RPCs und Pfadsemantik (19.11.2026)

- Branch: `develop`; Supabase-Projekt: DEV (`pzazqvvoruqnqhcorbwx`)
- Status: Bestandsaufnahme abgeschlossen; keine Code-, SQL-, Policy-, Storage- oder PROD-Änderung.
- Alle Abfragen waren reine SELECT-/Metadatenprüfungen.

### Geprüfte RPCs

- `public.admin_update_member_profile(p_team_id, p_user_id, p_display_name, p_avatar_url)`
- `public.admin_update_club_member_profile(p_club_id, p_user_id, p_display_name, p_avatar_url)`

Beide Funktionen:
- sind `SECURITY DEFINER`, Eigentümer `postgres`, und setzen einen festen `search_path` auf `pg_catalog, public, auth`.
- prüfen `auth.uid()` und den passenden ausgewählten Team-/Vereinskontext bzw. die Adminberechtigung.
- prüfen, dass das Zielkonto zur angegebenen Mannschaft bzw. zum Verein gehört.
- prüfen einen nichtleeren Anzeigenamen.
- begrenzen `p_avatar_url` derzeit nur auf maximal 2048 Zeichen.
- haben EXECUTE für `authenticated` und `service_role`; `anon` kann beide RPCs nicht ausführen.

### Befund: Pfadvalidierung fehlt

- Keine der beiden RPCs prüft, ob `p_avatar_url` tatsächlich ein Storage-Pfad im Bucket `profile-avatars` ist.
- Es wird insbesondere nicht geprüft, ob der erste Pfadbestandteil der `p_user_id` entspricht.
- Die normale Frontend-Uploadfunktion erzeugt den Pfad im Format `<user_uuid>/avatar-<timestamp>.<ext>` und speichert diesen Pfad, keine vollständige URL.
- Das eigene Profil wird direkt über `profiles` aktualisiert; die RLS-Policy erlaubt UPDATE nur auf die eigene Profilzeile, enthält aber ebenfalls keine Prüfung des Avatar-Pfads.
- Daher muss die spätere Härtung sowohl die beiden Admin-RPCs als auch den direkten Self-Service-UPDATE-Pfad berücksichtigen. Eine Härtung nur der RPCs wäre unvollständig.

### Befund: Berechtigungsabweichung beim Avatar-Upload

- Die Storage-INSERT-Policy für `profile-avatars` erlaubt Uploads für den Eigentümer des Zielordners oder für einen berechtigten Vereinsadmin.
- Ein Mannschaftsadmin darf laut `admin_update_member_profile` das Profil eines Mitglieds seiner Mannschaft bearbeiten.
- Die aktuelle Storage-INSERT-Policy enthält aber keine entsprechende Mannschaftsadmin-/Teamkontext-Prüfung.
- Damit besteht eine Berechtigungsabweichung: Ein Mannschaftsadmin kann den Profilbildpfad per RPC ändern, kann aber nicht notwendigerweise ein neues Bild für dieses Mitglied in den Storage-Bucket hochladen.
- Vor einer Policy-Anpassung muss die fachliche Berechtigung bestätigt werden. Keine Policy wurde geändert.

### Daten- und Bucket-Befund DEV

- `profiles`: 11 Datensätze, aktuell 0 nichtleere `avatar_url`-Werte.
- `profile-avatars`: Bucket steht noch auf `public = true`; ein Objekt vorhanden.
- Das vorhandene Objekt liegt im erwarteten Benutzerordner `<user_uuid>/avatar-<timestamp>.jpg`; der Objekt-Eigentümer entspricht dem Benutzerordner.
- Der vorhandene Profilbild-Storage-Eintrag ist aktuell nicht in `profiles.avatar_url` referenziert. Er wurde nicht gelöscht oder verändert.
- `club-assets` steht ebenfalls noch auf `public = true`; ein vorhandenes Wappenobjekt liegt im erwarteten Format `<club_uuid>/crest.png`.
- Keine Bucket- oder Objektänderung durchgeführt.

### Empfohlene Härtung – noch nicht umgesetzt

1. Gemeinsame Pfadregel für Profilbilder festlegen: `NULL` zum Entfernen oder ein relativer Pfad im Format `<p_user_id>/avatar-<timestamp>.(jpg|png|webp)`; keine vollständigen URLs, fremden Benutzerordner, führenden Slashes oder Traversal-Segmente.
2. Diese Regel sowohl in `admin_update_member_profile` und `admin_update_club_member_profile` als auch beim direkten eigenen Profil-UPDATE erzwingen (z. B. über eine geeignete zentrale DB-Validierung).
3. Fachlich entscheiden, ob Mannschaftsadmins Profilbilder anderer Mitglieder ihrer Mannschaft hochladen dürfen. Falls ja, muss die Storage-INSERT-Policy exakt auf die bestehende Teamadmin-/Kontextberechtigung abgestimmt werden.
4. Vor IMG-SEC-03 die nicht referenzierte Avatar-Datei inventarisieren; keine automatische Löschung ohne separate Entscheidung.

### Offene fachliche Entscheidung

Fachliche Entscheidung des Nutzers (19.11.2026): Profilbild-Berechtigungen sollen der bestehenden Mitgliederverwaltung folgen. Benutzer dürfen ihr eigenes Profilbild verwalten; Mannschaftsadmins dürfen Profilbilder von Mitgliedern ihrer eigenen Mannschaft verwalten; Vereinsadmins dürfen Profilbilder von Mitgliedern ihres eigenen Vereins verwalten; Superadmins dürfen dies ausschließlich im ausdrücklich ausgewählten Vereins-/Mannschaftskontext. Trainer ohne Adminrolle dürfen keine fremden Profilbilder verwalten.



### 2L.1 Fachliche Entscheidung zu Profilbild-Berechtigungen (19.11.2026)

Der Nutzer hat die technische Empfehlung bestätigt und die Umsetzung dieser fachlichen Regel delegiert:

- Benutzer: eigenes Profilbild hochladen, ändern und entfernen.
- Mannschaftsadmin: Profilbilder von Mitgliedern der eigenen Mannschaft verwalten.
- Vereinsadmin: Profilbilder von Mitgliedern des eigenen Vereins verwalten.
- Superadmin: Profilbilder nur innerhalb eines ausdrücklich ausgewählten Vereins- bzw. Mannschaftskontexts verwalten.
- Trainer ohne Adminrolle: keine Profilbilder anderer Benutzer verwalten.

Technische Umsetzung bleibt offen. Die Storage-Upload-Policy, die Profilbild-RPCs und der direkte Self-Service-Profilupdate müssen dieselbe Rollen-/Kontextlogik durchsetzen. Es wurde keine SQL-, Policy-, Frontend- oder Storage-Änderung ausgeführt.



## 2M. Technischer Soll-Entwurf für Profilbild-Berechtigungen und Pfadprüfung (19.11.2026)

- Status: Entwurf auf Basis ausschließlich lesender DEV-Prüfungen; keine Implementierung.
- Keine SQL-Ausführung mit Schreibwirkung, keine Migration, keine Policy-/Bucketänderung, keine Frontendänderung.

### 1. Einheitliche fachliche Berechtigungslogik

Die Storage-Regeln für INSERT, UPDATE und DELETE im Bucket `profile-avatars` müssen dieselbe Zuständigkeitsgrenze verwenden:

- Eigentümer: darf nur Objekte im eigenen Benutzerordner verwalten.
- Vereinsadmin: darf Objekte von Mitgliedern des Vereins verwalten, für den `can_manage_club_context(club_id)` wahr ist. Damit bleibt der ausgewählte Vereinskontext für Superadmins zwingend.
- Mannschaftsadmin: darf Objekte von Mitgliedern einer Mannschaft verwalten, für die `public.is_team_admin(team_id)` wahr ist. Die Ein-Parameter-Variante prüft den angemeldeten Benutzer und berücksichtigt Superadmins nur mit ausdrücklich ausgewähltem Mannschaftskontext.
- Trainer ohne Adminrolle: keine fremden Profilbildobjekte hochladen, ändern oder löschen.
- Kein Zugriff auf andere Vereine/Mannschaften durch bloße Kenntnis einer Benutzer-ID.

Die Prüfung muss sich auf das Zielkonto beziehen, dessen UUID der erste Ordnerbestandteil des Storage-Objekts ist. Für Teamadmins muss eine tatsächliche Mitgliedschaft des Zielkontos in derselben Mannschaft nachgewiesen werden; für Vereinsadmins eine Mitgliedschaft des Zielkontos im ausgewählten Verein.

Die gleiche Autorisierungsregel ist auf INSERT, UPDATE und DELETE anzuwenden. Die SELECT-Regel bleibt gesondert: Das Anzeigen von Profilbildern folgt der bestehenden `private.can_view_profile_avatar`-Logik und wird durch diese Verwaltungsentscheidung nicht erweitert.

### 2. Einheitliche Pfadvalidierung

Neue Profilbildreferenzen sollen ausschließlich relative Storage-Pfade in diesem Format sein:

`<user-uuid>/avatar-<unix-milliseconds>.(jpg|png|webp)`

Regeln:
- `NULL` bedeutet: Profilbild entfernt.
- Kein vollständiger HTTP-/HTTPS-Link und keine Data-URL.
- Keine führenden oder doppelten Slashes, keine zusätzlichen Pfadsegmente, keine Traversal-Sequenzen.
- Der erste Pfadbestandteil muss exakt der UUID des Profilinhabers entsprechen.
- Dateiendung nur `jpg`, `png` oder `webp`.
- Die bestehende Frontend-Uploadfunktion erzeugt bereits diesen Pfadtyp.

Vorgesehene technische Durchsetzung:
- Eine zentrale, deterministische Validierungsfunktion im nicht exponierten `private`-Schema.
- Ein Trigger auf `public.profiles`, der jede Änderung von `avatar_url` prüft. Das deckt den direkten Self-Service-UPDATE-Pfad ab und schützt auch vor später ergänzten Schreibwegen.
- Zusätzliche identische Prüfung in beiden Admin-RPCs mit Bezug auf `p_user_id`, damit Fehler früh und mit verständlicher Fehlermeldung abgewiesen werden.
- Die Validierungsfunktion darf keine Berechtigung ersetzen; Autorisierung und Pfadformat bleiben getrennte Prüfungen.

### 3. Wichtige Bestandsdaten-/Kompatibilitätsbedingung

- In DEV sind derzeit 0 von 11 Profilen mit einem nichtleeren `avatar_url` vorhanden.
- In DEV existiert ein Profilbildobjekt, dessen Pfad dem erwarteten Format entspricht, das aber derzeit nicht in `profiles.avatar_url` referenziert wird.
- Vor Umsetzung in PROD ist gesondert zu prüfen, ob bestehende Profilwerte vollständige öffentliche URLs oder andere Legacy-Formate enthalten. Die neue Validierung darf bestehende produktive Profile nicht unbeabsichtigt unlesbar machen.
- Es wird kein Storage-Objekt automatisch gelöscht. Verwaiste Objekte bleiben von dieser Pfadvalidierung unberührt.

### 4. Geplante Prüffälle vor Freigabe

Positiv:
1. Benutzer setzt, ändert und entfernt eigenes Profilbild.
2. Mannschaftsadmin lädt Profilbild für ein Mitglied seiner Mannschaft hoch, ändert und entfernt es.
3. Vereinsadmin verwaltet Profilbilder von Vereinsmitgliedern, auch wenn diese in mehreren Mannschaften sind.
4. Superadmin kann dies im ausgewählten Vereins- bzw. Mannschaftskontext.
5. Bestehende zulässige Profilbilder bleiben sichtbar.

Negativ:
1. Trainer ohne Adminrolle versucht fremdes Profilbild hochzuladen, zu ersetzen oder zu löschen.
2. Mannschaftsadmin versucht ein Mitglied einer anderen Mannschaft zu bearbeiten.
3. Vereinsadmin versucht ein Mitglied eines anderen Vereins zu bearbeiten.
4. Superadmin versucht Zugriff ohne passenden ausgewählten Kontext.
5. Ein Benutzer versucht, eine fremde UUID im Pfad zu verwenden.
6. Ein vollständiger URL-Wert, eine Data-URL, zusätzliche Pfadsegmente oder eine ungültige Dateiendung wird als Profilbildreferenz gespeichert.

### 5. Noch nicht umgesetzt

Dieser Entwurf ist eine technische Vorbereitung. Die Umsetzung benötigt später eine freigegebene, versionierte SQL-Migration (Helper, Trigger, RPC-Härtung und Storage-Policies) sowie DEV-Tests. Bis dahin bleiben Datenbank und Storage unverändert.


## 2N. SQL-Entwurf Profilbild-Härtung (19.11.2026)

- Datei: `docs/IMG_SEC_02_PROFILE_AVATAR_HARDENING_DRAFT.sql`
- Commit: `41bf1c08740ac663e7f9d169cc0a8222efe50705`
- Status: Entwurf erstellt und auf `develop` abgelegt; NICHT ausgeführt.
- Die Datei liegt bewusst unter `docs/`, nicht im Supabase-Migrationsverzeichnis.
- Das Skript ist zusätzlich mit einer abschließenden `ROLLBACK;`-Anweisung versehen. Es ist ein Prüfentwurf, keine freigegebene Migration.

### Inhalt des Entwurfs

1. Zentrale Pfadvalidierung für `<user-uuid>/avatar-<13-stellige Date.now()-Millisekunden>.(jpg|png|webp)`.
2. Zentrale Verwaltungsberechtigung, die Eigenverwaltung, Vereinsadmin-Kontext und Mannschaftsadmin-Kontext abbildet. Superadmins werden nur über die vorhandenen ausgewählten Kontextprüfungen zugelassen.
3. Trigger auf `public.profiles`, damit auch direkte Self-Service-Updates abgesichert werden. Unveränderte bestehende Avatarwerte werden bei anderen Profiländerungen nicht neu validiert.
4. Zusätzliche Pfadprüfung in beiden bestehenden Admin-Profil-RPCs.
5. Anpassung der Storage-Policies für INSERT, UPDATE und DELETE. Die SELECT-Policy bleibt unverändert.

### Vor einer späteren Migration zwingend zu prüfen

- Ob die Zielumgebung dieselben Tabellen, Funktionssignaturen, Policy-Namen und Grants aufweist.
- Ob die exakte Pfadform weiterhin dem Frontend entspricht (der aktuelle Upload verwendet `Date.now()` und die Endungen jpg/png/webp).
- Ob die Rechte der neuen Funktionen auf `authenticated` beschränkt sind und keine unbeabsichtigten PUBLIC-/anon-Rechte entstehen.
- Ob bestehende produktive Avatarwerte Legacy-URLs oder andere Formate enthalten. Solche Werte dürfen nicht unabsichtlich bei der Migration blockiert werden.
- Ob Storage-UPDATE-/DELETE-Abläufe mit alten Objekten kompatibel bleiben.
- Vollständige Positiv- und Negativtests sowie Supabase Security Advisors in DEV.

### Wichtige Abgrenzung

Der SQL-Entwurf wurde nicht auf einer Datenbank ausgeführt, nicht als Migration registriert und nicht auf PROD angewendet. Es wurden keine SQL-Schreibbefehle ausgeführt. Vor einer Freigabe ist ein technisches Review des Entwurfs erforderlich; erst danach darf daraus eine ordnungsgemäß versionierte Migration erstellt werden.


## 2O. Technisches Review des SQL-Entwurfs (19.11.2026)

- Status: Review abgeschlossen; Entwurf konsolidiert, weiterhin NICHT ausgeführt.
- Review-Commit für SQL-Datei: `ec5de29ce435427836cd199907cb0a0344f7bccc`.
- Es wurden nur GitHub-Dokumente aktualisiert. Keine SQL-Schreibabfrage, Migration oder Storage-Änderung ausgeführt.

### Review-Ergebnis

1. **Frontend-Pfadformat abgeglichen:** `uploadProfileAvatar()` erzeugt `<userId>/avatar-<Date.now()>.<ext>`; erlaubte Endungen sind `jpg`, `png`, `webp`. Die Validator-Regel mit 13-stelligem Millisekundenwert entspricht dem aktuellen Frontend.
2. **Self-Service abgesichert:** Der Profil-Trigger prüft neue/geänderte Avatarwerte auch bei direktem UPDATE auf `profiles`. Unveränderte bestehende Legacy-Werte werden bei einer reinen Namensänderung nicht erneut validiert.
3. **Adminwege abgesichert:** Beide Admin-RPCs behalten ihre bisherigen Kontext- und Mitgliedschaftsprüfungen und erhalten zusätzlich die Pfadprüfung gegen die UUID des Zielkontos.
4. **Rollenabgrenzung:** Vereinsadmins werden über `can_manage_club_context` geprüft; Mannschaftsadmins über `is_team_admin(team_id)` und die Mitgliedschaft des Zielkontos in derselben Mannschaft. Superadmins benötigen weiterhin den ausgewählten passenden Kontext.
5. **Storage-Policy-Semantik:** INSERT prüft Berechtigung und neuen Pfad. UPDATE prüft die Berechtigung des bestehenden Objekts über `USING` und Berechtigung plus gültiges Format des Zielpfads über `WITH CHECK`. DELETE prüft die Verwaltungsberechtigung des Zielkontos.
6. **Legacy-Kompatibilität:** Bestehende, berechtigte Legacy-Objekte können weiterhin ersetzt bzw. gelöscht werden. Nur neu gespeicherte Avatarreferenzen und neue Storage-Zielpfade müssen das aktuelle Format erfüllen.
7. **Sichtbarkeit getrennt:** Die SELECT-Policy und `private.can_view_profile_avatar` bleiben unverändert. Die neue Verwaltungsberechtigung erweitert nicht den Kreis der Personen, die Profilbilder ansehen dürfen.
8. **Funktionsschutz:** Neue Helper liegen im nicht exponierten `private`-Schema, haben festen `search_path` und keine EXECUTE-Freigabe für `PUBLIC`/ `anon`. Die vorhandene private-Schema-USAGE-Berechtigung für `authenticated` wurde nur lesend geprüft.
9. **DEV-Datenbestand:** 11 Profile, aktuell 0 nichtleere Avatarreferenzen. Damit gibt es in DEV keine bestehenden Profilreferenzen, die durch die neue Formatregel blockiert würden. Der bereits inventarisierte unreferenzierte Storage-Eintrag bleibt unberührt.

### Bewusst zurückgestellte Aufgabe: verwaiste Dateien

Die Frontend-Uploadfunktion erzeugt bei jedem Upload einen neuen eindeutigen Storage-Pfad. Beim Ändern oder Entfernen eines Profilbildes wird der alte Storage-Gegenstand derzeit nicht automatisch gelöscht. Dadurch können nicht mehr referenzierte Dateien verbleiben.

Das ist kein Berechtigungs-Bypass, aber ein Thema für Speicherplatz und Datenminimierung. Es wird nicht im Rahmen dieser Berechtigungsmigration automatisch bereinigt. Dafür ist eine separate, sichere Cleanup-Logik erforderlich, die erst nach erfolgreichem Speichern der neuen Profilreferenz löscht und Fehlerfälle berücksichtigt.

### Ergebnis und nächste Schritte

- Der Entwurf ist nach Review konsolidiert und kann als Grundlage für die Erstellung einer versionierten DEV-Migration dienen.
- Vor der Migration ist noch ein letzter Abgleich der exakten DEV-Funktions-/Policy-Abhängigkeiten sowie der SQL-Ausführungsrechte durchzuführen.
- Anschließend wird eine echte Migration im Supabase-Migrationsverzeichnis erstellt, im SQL-Release-Katalog dokumentiert und dem Nutzer vor jeder Ausführung ausdrücklich zur Freigabe vorgelegt.
- Bis zu einer gesonderten Freigabe bleibt DEV-Datenbank/Storage unverändert; PROD bleibt unangetastet.


## 2P. Versionierte DEV-Migration vorbereitet (19.11.2026)

- Nutzerfreigabe zur Erstellung der versionierten Migrationsdatei erteilt.
- Datei: `supabase/migrations/20261119120000_img_sec_02_profile_avatar_hardening_v1_0_0_dev.sql`.
- GitHub-Commit mit Datei: `82eb42d8003ec07408f653cbf7d2cb4555ae6911`; nachfolgende Klarstellung des Migrationskopfs: `60697a89eb7dd0a54526a067a2923e6d9c00e676`.
- DB-Migrationskatalog: Eintrag DB-MIG-2026-038 in `DB_MIGRATION_LOG.md`.
- DB-Changelog: Eintrag vom 19.11.2026 in `DB_CHANGELOG.md`.
- Die Datei enthält einen Preflight-Block, der bei fehlenden Tabellen/Funktionen/Schema-Rechten oder fehlender bestehender SELECT-Policy abbricht.
- Der Migrationstext wurde nicht ausgeführt. Keine Datenbank-/Storageänderung, keine Änderung an DEV-Ledger und keine PROD-Änderung.
- Die Nutzerfreigabe gilt nur für die Erstellung der Datei. Eine separate Freigabe ist vor der Ausführung erforderlich.
- Nächste Aufgabe: statische Prüfung der Migrationsdatei, Erstellung einer geprüften Rollback-/Wiederherstellungsfassung und eines Positiv-/Negativtestpakets. Danach Vorlage zur ausdrücklichen Ausführungsfreigabe.
