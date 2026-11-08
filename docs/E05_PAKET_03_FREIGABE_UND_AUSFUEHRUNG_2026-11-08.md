# E05 – Freigabe- und Ausführungsprotokoll Paket 3

## Paket 3: Sperrenfundament und automatische Sperrenauslösung

- **Erstellt:** 08.11.2026
- **Zielumgebung:** Supabase DEV
- **Supabase-Projekt:** `pzazqvvoruqnqhcorbwx`
- **SQL-Datei:** [E05_PAKET_03_SUSPENSION_TRIGGER_2026-11-08.sql](https://github.com/bautnhaus/jugendmannschaft/blob/develop/docs/E05_PAKET_03_SUSPENSION_TRIGGER_2026-11-08.sql)
- **Branch:** `develop`
- **Status:** Freigabekandidat; noch nicht ausgeführt
- **Abhängigkeiten:** Paket 1 (Ereignistabellen) und Paket 2 (Ereignisvergabe-RPC) müssen in DEV vorhanden sein.

## 1. Umfang

Paket 3 enthält zwei neue Tabellen:

- `public.training_suspensions`: offene und historische gelbe/rote Sperren.
- `public.training_suspension_audit`: append-only Audit-Historie für Sperren.

Zusätzlich wird `public.award_training_behavior_event(uuid, uuid, text, text)` durch eine erweiterte Version ersetzt. Die Ereignisvergabe und eine dadurch ausgelöste Sperre werden innerhalb derselben Transaktion gespeichert.

## 2. Verbindliche Auslösebedingungen

### Rote Karte

- Jede gültig vergebene rote Karte erzeugt sofort genau eine offene rote Sperre.
- Die Sperre ist über `source_event_id` eindeutig mit dem roten Ereignis verknüpft.
- Das gelbe Kartenkonto bleibt unberührt.

### Gelbe Karten

- Die fünfte aktive gelbe Karte im aktuellen Kartenkonto erzeugt eine offene gelbe Sperre.
- Vier aktive gelbe Karten erzeugen noch keine Sperre.
- Während eine gelbe Sperre offen ist, wird keine zweite parallele gelbe Sperre erzeugt.
- Nach einer späteren Ableistung beginnt die Zählung anhand von Ereignissen nach `served_at` wieder bei null. Die Historie bleibt bestehen.
- Die Auswertung ist auf Spieler, Team und Saison begrenzt.

## 3. Sicherheit und Datenintegrität

- Die bestehende serverseitige Authentifizierungs-, Teamrollen-, Spieler-, Anwesenheits- und Saisonprüfung aus Paket 2 bleibt erhalten.
- Die Spielerzeile wird während der Vergabe gesperrt, damit parallele Vergaben für denselben Spieler die Fünf-Karten-Schwelle nicht gleichzeitig überschreiten.
- Pro Quellereignis ist höchstens eine Sperre möglich.
- Sperre und Sperren-Audit werden atomar geschrieben.
- Beide neuen Tabellen erhalten RLS und Teamkontext-Leseregeln.
- Direkte Schreibrechte der API-Rollen werden nicht vergeben.
- Sperren-Audit ist gegen UPDATE, DELETE und TRUNCATE geschützt.

## 4. Bewusste Abgrenzung

Dieses Paket legt die Sperren an und löst sie automatisch aus. Es ordnet sie noch keinem Spieltag zu und bedient sie nicht. Ebenfalls nicht enthalten sind Ausnahmen, manuelle Sperrenkorrektur, Saisonabschluss, Spielart-Konfiguration, vorzeitiger Sperrausgleich und die integrierte Korrektur/Stornierung/Wiederherstellung bereits sperrauslösender Ereignisse.

Bis diese Folgefunktionen implementiert und getestet sind, ist der vollständige Trainerworkflow noch nicht produktionsreif. Paket 3 verändert keine bestehenden Datensätze und keine PROD-Umgebung.

## 5. Prüfplan nach Freigabe

1. Tabellen, Constraints, Indizes, RLS, Policies und Audit-Trigger vorhanden.
2. SELECT-Rechte für `authenticated` und `service_role`; keine direkten INSERT-/UPDATE-/DELETE-Rechte für API-Rollen.
3. RPC bleibt SECURITY DEFINER; EXECUTE nur für `authenticated`.
4. Rote Karte: Ereignis + genau eine offene rote Sperre + beide Audit-Einträge.
5. Gelbe Karten 1 bis 4: keine gelbe Sperre.
6. Fünfte aktive gelbe Karte: genau eine offene gelbe Sperre; Quelle ist das fünfte aktive Ereignis des aktuellen Kontos.
7. Sechste gelbe Karte während offener gelber Sperre: keine zweite gelbe Sperre.
8. Karte und Stern im selben Training bleiben zulässig; zweite Karte oder zweiter Stern bleibt durch Paket 1 gesperrt.
9. Fehler beim Sperren-Audit muss Ereignis und Sperre gemeinsam zurückrollen.
10. Negativtests aus Paket 2 bleiben wirksam (Berechtigung, Anwesenheit, Spielerstatus, Saison und Kartengrund).

Die fachlichen Schwellen- und Auditprüfungen werden, soweit möglich, mit DEV-Testdaten innerhalb zurückrollbarer Transaktionen ausgeführt. Keine Testereignisse sollen dauerhaft in den echten DEV-Bestand gelangen.

## 6. Ausführungsstatus

Noch nicht ausgeführt. Nach ausdrücklicher Freigabe werden Ausführung, tatsächliche Testergebnisse, Korrekturen und Abschlussstatus hier ergänzt.


## DEV-Ausführung und Testergebnisse

- **Ausgeführt:** 08.11.2026
- **Ziel:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`
- **Freigabe:** Nutzerfreigabe lag für Paket 3 vor.
- **Ausführung:** erfolgreich; beide Tabellen, Policies, Audit-Trigger und erweiterte RPC wurden angelegt.
- **PROD:** unverändert.

### Struktur- und Rechteprüfungen

| Prüfung | Ergebnis |
|---|---|
| `training_suspensions` vorhanden | Bestanden |
| `training_suspension_audit` vorhanden | Bestanden |
| SELECT-Policies auf beiden Tabellen | Bestanden |
| Audit-Schutztrigger für UPDATE/DELETE | Bestanden |
| RPC SECURITY DEFINER | Bestanden |
| EXECUTE für `authenticated` | Erlaubt |
| EXECUTE für `anon` und `service_role` | Nicht erlaubt |

### Fachliche DEV-Tests

Alle Testdaten wurden in einer Transaktion erzeugt und anschließend zurückgerollt.

| Test | Ergebnis |
|---|---|
| Vier historische aktive gelbe Karten | Noch keine Sperre |
| Fünfte aktive gelbe Karte | Genau eine offene gelbe Sperre |
| Quellereignis der gelben Sperre | Verweist auf das fünfte Ereignis |
| Audit-Eintrag zur gelben Sperre | Genau ein Eintrag |
| Sechste gelbe Karte bei offener gelber Sperre | Keine zweite gelbe Sperre |
| Rote Karte | Genau eine offene rote Sperre |
| Quellereignis der roten Sperre | Verweist auf das rote Ereignis |
| Audit-Eintrag zur roten Sperre | Genau ein Eintrag |
| Rote Karte und positiver Stern im selben Training | Zulässig |
| Fehler beim Schreiben des Sperren-Audits | Ereignis und Sperre gemeinsam zurückgerollt |

### Testkorrektur während der Prüfung

Ein erster Testlauf scheiterte an einer ungeeigneten Aggregation im Testskript (`max(uuid)` wird von PostgreSQL nicht unterstützt). Das war kein Fehler der Migration. Das Testskript wurde korrigiert und anschließend vollständig erfolgreich ausgeführt.

### Datenbereinigung / Rollback-Nachkontrolle

- 0 verbliebene Testereignisse.
- 0 verbliebene Test-Audit-Einträge.
- 0 verbliebene Sperren.
- 0 verbliebene Sperren-Audit-Einträge.
- Teständerungen an Anwesenheitsdaten wurden zurückgerollt.

### Ergebnis

**Paket 3 ist in DEV umgesetzt. Die gelbe Schwelle, das Verhalten bei weiteren gelben Karten während offener Sperre, rote Sperre, Audit-Verknüpfungen und Transaktionsatomarität wurden erfolgreich geprüft.** Die offenen Folgefunktionen aus dem Abschnitt „Bewusste Abgrenzung“ bleiben eigenständige Arbeitspakete.
