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
