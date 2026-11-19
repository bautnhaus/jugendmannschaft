# IMG-SEC-03 – DEV-Testplan: Private Profilbilder und Vereinsassets

**Status:** vorbereitet, nicht ausgeführt.  
**Umgebung:** ausschließlich Supabase DEV / DEV-Web-App.  
**Migration:** `20261119163443_img_sec_03_private_profile_and_club_asset_buckets_dev`.

## 1. Ziel

Die Buckets `profile-avatars` und `club-assets` werden privat. Bilder werden in der App ausschließlich über kurzlebige Signed URLs geladen. Die bestehenden Storage-Policies bestimmen, wer die Bilder lesen und verwalten darf.

## 2. Vorbedingungen und Bestandsaufnahme

Vor Migration erneut prüfen:
- Beide Buckets existieren und stehen auf `public=true`.
- Profilbild-SELECT-Policy `profile_avatars_select_authorized` ist vorhanden.
- Vereinsasset-SELECT-Policy `club_assets_select_scoped` ist vorhanden.
- Alle Profilbildobjekte haben einen Pfad, der dem IMG-SEC-02-Format entspricht.
- Vereinsassetobjekte verwenden den Vereins-UUID-Pfad.
- Vereinslogo-Pfad in `clubs.crest_path` stimmt mit dem Storage-Objekt überein.
- Keine Änderung an Objektanzahl, Pfaden oder Dateiinhalten ist geplant.

Bestandsaufnahme vom 19.11.2026:
- `profile-avatars`: zwei Objekte; beide Pfade entsprechen dem Benutzer-UUID-/Avatar-Dateinamen-Format.
- `profiles.avatar_url`: derzeit keine gespeicherten Referenzen. Die vorhandenen Objekte sind daher nicht als aktiv referenzierte Profilbilder belegt und dürfen nicht gelöscht werden.
- `club-assets`: ein Objekt unter `<club-uuid>/crest.png`; der Pfad stimmt mit `clubs.crest_path` des vorhandenen Vereins überein.
- Beide Buckets aktuell `public=true`.
- App-Code in `develop/index.html` verwendet für diese Buckets den gemeinsamen Signed-URL-Resolver; kein `getPublicUrl()`-Aufruf im aktuellen Frontend gefunden.

## 3. Praxistests nach Migration

### Profilbilder
- P01: eigenes Profilbild anzeigen.
- P02: eigenes Profilbild hochladen, ändern und entfernen.
- P03: Profilbild eines Mitglieds durch berechtigten Mannschaftsadmin anzeigen.
- P04: Profilbild eines Vereinsmitglieds durch berechtigten Vereinsadmin anzeigen.
- P05: Superadmin sieht Profilbild nur im ausdrücklich ausgewählten Kontext.
- N01: Trainer ohne Adminrolle kann kein fremdes Profilbild über Storage abrufen.
- N02: Benutzer ohne Berechtigung kann kein fremdes Profilbild abrufen.
- N03: direkte öffentliche Objekt-URL darf keinen Bildinhalt mehr ausliefern.

### Vereinslogo
- C01: Vereinsmitglied sieht das Vereinslogo in der App.
- C02: Vereinsadmin sieht das Vereinslogo im Vereinskontext.
- C03: Superadmin sieht das Vereinslogo nur im ausgewählten Vereinkontext.
- N04: Nichtmitglied ohne passenden Kontext kann das Vereinslogo nicht über Signed URL beziehen.
- N05: direkte öffentliche Objekt-URL darf keinen Bildinhalt mehr ausliefern.

### Regression
- R01: Dashboard, Vereinsauswahl, Vereinsverwaltung und Profilansichten laden Bilder ohne sichtbare Fehler.
- R02: Login, Logout und Kontextwechsel zeigen keine Bilder aus dem vorherigen Kontext.
- R03: abgelaufene Signed URL wird einmal erneuert; Bild lädt anschließend.
- R04: Upload, Ersetzen und Entfernen von Profilbildern bleiben funktionsfähig.
- R05: Spielerfotos im bereits privaten Bucket `player-photos` bleiben unverändert funktionsfähig.
- R06: Vereinslogo und Profilbild werden auf iPhone/Safari korrekt dargestellt.

## 4. Datenbank-Postflight

- Beide Buckets haben `public=false`.
- SELECT-Policies sind unverändert vorhanden.
- INSERT-/UPDATE-/DELETE-Policies sind unverändert vorhanden.
- Objektanzahl und Pfade sind identisch zum Preflight.
- `clubs.crest_path` bleibt unverändert.
- `profiles.avatar_url` bleibt unverändert.
- Keine Datei wurde verschoben oder gelöscht.

## 5. Abnahme

IMG-SEC-03 gilt erst als bestanden, wenn:
- Datenbank-Postflight vollständig bestanden ist.
- öffentliche URLs den Zugriff verweigern.
- berechtigte Rollen Bilder weiterhin über die App sehen.
- unberechtigte Rollen keinen Zugriff erhalten.
- iPhone-/Kontextwechsel-/Retry-Regressionen bestanden sind.

Ein Fehler bei der Bildanzeige oder eine unberechtigte Sichtbarkeit ist ein Blocker. Keine PROD-Freigabe, solange ein Blocker offen ist.

## 6. Rollback

Rollback nur nach ausdrücklicher gesonderter Freigabe:
`supabase/rollback/20261119163443_img_sec_03_private_profile_and_club_asset_buckets_rollback_dev.sql`.

Der Rollback stellt `public=true` wieder her und macht die Dateien dadurch wieder öffentlich abrufbar. Er verändert keine Dateien, Pfade oder Policies.


## 7. Automatisierter DEV-Postflight nach Ausführung (19.11.2026)

- Supabase-Migration `img_sec_03_private_profile_and_club_asset_buckets_dev` erfolgreich ausgeführt; tatsächliche Ledger-Version `20261119163443`.
- `profile-avatars.public=false` und `club-assets.public=false`.
- Bucket-Konfigurationen (2 MiB und erlaubte Bild-MIME-Typen) unverändert.
- Storage-Objekte unverändert: 2 Profilbilddateien und 1 Vereinslogo; Dateipfade, Besitzer, MIME-Typen und Größen unverändert.
- `profiles.avatar_url`: weiterhin 0 nicht-null Referenzen.
- `clubs.crest_path`: unverändert und stimmt mit dem vorhandenen Vereinslogo-Objekt überein.
- Sämtliche vorhandenen SELECT-/INSERT-/UPDATE-/DELETE-Policies für beide Buckets sind vorhanden und wurden von der Migration nicht geändert.
- Direkte anonyme HTTP-Abrufversuche sowie echte Signed-URL-/Rollen-/iPhone-Praxistests stehen noch aus.


## 8. Manueller DEV-Abschlusstest (19.11.2026)

Nutzerbestätigung: **„Klappt“**.

Damit wurden in der DEV-App erfolgreich bestätigt:
- Profilbild wird angezeigt.
- Vereinslogo wird in der App angezeigt.
- Profilbild kann weiterhin hochgeladen, geändert und entfernt werden.
- Bilder funktionieren nach erneutem Login.

Die Bestätigung deckt die genannten UI-/Self-Service-Fälle ab. Die dedizierten Negativtests mit direkter öffentlicher URL und rollenbasierte Fremdzugriffsversuche sind nicht separat bestätigt und bleiben als formale Sicherheitsprüfung offen.
