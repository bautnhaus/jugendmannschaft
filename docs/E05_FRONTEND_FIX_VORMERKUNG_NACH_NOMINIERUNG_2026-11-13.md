# E05 Frontend-Fix – Vormerkungsstatus nach Kadernominierung

**Datum:** 13.11.2026  
**Branch:** `develop`  
**Datei:** `index.html`  
**Commit:** `a7ccf0dd0de4844927962c18acd00cb4aa3121e2`  
**Status:** Codekorrektur umgesetzt; DEV-Browser-Praxistest ausstehend  
**PROD / `main`:** unverändert

## Ausgangslage

Die Datenbank storniert eine offene Vormerkung zum vorzeitigen Sperrausgleich automatisch, sobald derselbe Spieler für den Spieltag nominiert wird. Die Datenbankprüfung für Peter Ording zum Spieltag 14.11.2026 hatte bereits zwei Vormerkungen mit Status `cancelled` und entsprechendem Stornierungsgrund bestätigt.

Die Spieltagskacheln lasen den gelben Chip jedoch aus dem lokalen Array `matchdayEarlyResetRows`. Nach erfolgreicher Nominierung wurde dieses Array nicht erneut aus der Datenbank geladen. Dadurch konnte der Chip „Sperrausgleich vorgemerkt“ trotz korrekter Datenbankstornierung sichtbar bleiben.

## Umsetzung

In `saveMatchdaySelection()` wird nach erfolgreichem Speichern der Nominierung (also nur, wenn tatsächlich Spieler neu hinzugefügt wurden) der bestehende Ladeweg erneut aufgerufen:

```js
if(add.length)await loadMatchdaySuspensions(md.id,true);
```

Die Funktion lädt bereits parallel Sperren, Ausnahmen und Vormerkungen für den konkreten Spieltag. Anschließend wird `renderMatchday()` ausgeführt. Der Chip wird somit anhand des frisch geladenen Datenbankstatus gerendert und verschwindet bei Status `cancelled`.

Die zentrale Stelle deckt sowohl die direkte Kachelnominierung als auch andere Aufrufer von `saveMatchdaySelection()` ab, darunter die Übernahme einer gespeicherten Kaderempfehlung.

## Abgrenzung

- Keine SQL-Ausführung oder Datenbankänderung.
- Keine Änderung an Triggern, RPCs, RLS oder Tabellen.
- Keine Änderung an `main`, PROD oder der Produktivdatenbank.
- Bestehende Sperr- und Vormerkungslogik bleibt unverändert.

## Prüfung und nächster Schritt

- Änderung nach dem aktuellen `develop/index.html`-Stand vorgenommen.
- Commit erfolgreich auf `develop` geschrieben.
- Datei anschließend erneut aus `develop` geladen; die Änderung ist im aktuellen Blob enthalten.
- **Manueller DEV-Praxistest am 13.11.2026: bestanden (Nutzerbestätigung).** Nach der Nominierung verschwindet der gelbe Chip unmittelbar. Die Korrektur ist damit fachlich bestätigt. PROD und `main` bleiben unverändert.
- Kein PROD-Release.
