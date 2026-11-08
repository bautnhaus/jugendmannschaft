# E05 – Freigabe- und Abnahmeprotokoll Paket 5

## Paket 5: Sperrausnahme für einen konkreten Spieltag

- **Erstellt:** 08.11.2026
- **Branch:** `develop`
- **Zielumgebung:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`
- **SQL-Datei:** [E05_PAKET_05_SPERRAUSNAHME_SPIELTAG_2026-11-08.sql](https://github.com/bautnhaus/jugendmannschaft/blob/develop/docs/E05_PAKET_05_SPERRAUSNAHME_SPIELTAG_2026-11-08.sql)
- **Status:** Abnahmekandidat; nicht ausgeführt
- **Abhängigkeiten:** Pakete 1–4; insbesondere `training_suspensions`, `training_suspension_audit`, Spielarten-Konfiguration und Zuordnungs-Helper aus Paket 4.

## 1. Ziel und fachliche Grundlage

Paket 5 bildet die bereits fachlich beschlossene Ausnahme für einen konkreten Spieltag ab.

Ein berechtigter Trainer kann eine offene gelbe oder rote Sperre für genau den Spieltag freigeben, dem diese Sperre aktuell zugeordnet ist. Die Sperre wird dadurch **nicht abgeleistet, nicht aufgehoben und nicht gelöscht**. Sie bleibt offen und wird unmittelbar auf den nächsten relevanten Spieltag verschoben.

Die Ausnahme:
- bezieht sich auf genau eine Sperre und genau einen Spieltag;
- benötigt zwingend eine Begründung;
- speichert Team-, Spieler- und Spieltags-Snapshots sowie Trainer und Zeitpunkt;
- verändert weder Nominierung noch tatsächlichen Einsatz;
- lässt die Sperre offen, unabhängig davon, ob der Spieler tatsächlich eingesetzt wird;
- zählt nicht als reguläre Ableistung.

## 2. Datenbankänderungen

### Neue Tabelle `training_suspension_exceptions`

Speichert Ausnahme-ID, Sperre, Team, Spieler, konkreten Spieltag, Snapshots, Pflichtgrund, freigebenden Trainer und Zeitpunkt. Die Tabelle enthält außerdem vorbereitete Widerrufs-Metadaten für eine spätere kontrollierte Widerrufs-RPC.

Ein partieller Unique-Index verhindert mehr als eine aktive Ausnahme derselben Sperre für denselben Spieltag.

RLS ist aktiv. Authentifizierte Teammitglieder bzw. Benutzer mit ausgewähltem berechtigtem Teamkontext dürfen lesen. Direkte Schreibrechte werden nicht erteilt.

### Erweiterung `training_suspension_audit`

Die Audit-Tabelle erhält `exception_id` als alternative Referenz. Eine neue Check-Constraint stellt sicher, dass ein Audit-Eintrag genau einen Gegenstand referenziert: entweder eine Sperre oder eine Ausnahme. Bestehende Sperren-Audit-Einträge bleiben gültig.

Die Audit-Historie bleibt append-only. Die Ausnahmedatensätze selbst sind für API-Rollen nicht direkt beschreibbar; spätere Änderungen müssen über eine kontrollierte SECURITY-DEFINER-RPC erfolgen.

## 3. Neue RPC

```sql
public.grant_suspension_exception(
  p_suspension_id uuid,
  p_matchday_id uuid,
  p_reason text
) returns uuid
```

Serverseitige Prüfungen:
1. Authentifizierter Akteur und nichtleerer Begründungstext.
2. Sperre existiert und ist noch offen.
3. Akteur ist Trainer oder Mannschaftsadmin des Ursprungsteams oder besitzt den ausdrücklich ausgewählten berechtigten Teamkontext.
4. Spieltag existiert, gehört zum selben Team und derselben Saison.
5. Spieltag ist exakt der aktuell zugeordnete Spieltag dieser Sperre und hat noch Status `planned`.
6. Doppelte aktive Ausnahme für dieselbe Sperre und denselben Spieltag wird durch den Unique-Index verhindert.

Atomare Ausführung:
1. Ausnahme mit Snapshots anlegen.
2. `training_suspension_audit` mit Aktion `exception_granted`, Ausnahme-ID, Begründung, Akteur und Zeitpunkt ergänzen.
3. Den Paket-4-Zuordnungs-Helper ausführen. Dieser schließt den Ausnahme-Spieltag für genau diese Sperre aus und weist ihr den nächsten passenden relevanten Spieltag zu.
4. Ausnahme-ID zurückgeben.

Scheitert das Audit oder die Neuzuordnung, rollt die gesamte Transaktion zurück. Es bleibt weder eine Ausnahme ohne Audit noch eine Ausnahme ohne korrekte Verschiebung zurück.

## 4. Anpassung des Paket-4-Zuordnungs-Helpers

`e05_assign_player_suspensions(...)` wird ersetzt. Die bestehende Logik bleibt erhalten:
- Team-/Saisonbezug;
- Club-Standard und vollständiger Team-Override;
- nur zukünftige geplante relevante Spieltage;
- gelbe Sperren vor roten Sperren;
- höchstens eine Sperre je Spieler und Spieltag;
- Audit bei Zieländerungen;
- keine stillschweigende Überspringung eines bereits abgeschlossenen zugeordneten Spieltags.

Neu: Ein Spieltag mit aktiver Ausnahme wird nur für die betreffende Sperre ausgeschlossen. Andere Sperren des Spielers können diesem Spieltag weiterhin nach den normalen Reihenfolgeregeln zugeordnet werden.

## 5. Bewusste Abgrenzung

Nicht Teil von Paket 5:
- Widerruf einer bereits gewährten Ausnahme über eine eigene RPC;
- automatische Auslösung beim Ändern des Matchday-Status;
- Frontend-Schaltfläche, Detailansicht und Anzeige der Ausnahme;
- vorzeitiger Sperrausgleich;
- Saisonabschluss;
- manuelle Sperrenkorrektur und Ereignis-Korrektur/Storno nach Sperrenentstehung.

Die Ausnahme-Daten und die Schreib-RPC werden in diesem Paket vorbereitet. Die UI-Anbindung folgt als eigener Arbeitsschritt.

## 6. Prüfplan nach Freigabe

### Positivtests
1. Berechtigter Trainer gewährt Ausnahme für aktuell zugeordneten Spieltag.
2. Ausnahme-Datensatz enthält korrekte Team-/Spieler-/Spieltag-Snapshots, Grund, Akteur und Zeitpunkt.
3. Audit-Eintrag `exception_granted` referenziert die Ausnahme und enthält den Grund.
4. Die offene Sperre wird unmittelbar dem nächsten relevanten Spieltag zugeordnet.
5. Eine rote Sperre wird nicht vor einer offenen gelben Sperre eingeplant.
6. Andere Sperren des Spielers werden durch die Ausnahme nicht fälschlich vom Ausnahme-Spieltag ausgeschlossen.

### Negativtests
1. Nicht authentifizierter Aufruf.
2. Benutzer ohne Trainer-/Adminberechtigung.
3. Fehlender oder leerer Grund.
4. Nicht existierende Sperre oder Spieltag.
5. Sperre ist bereits bedient, abgelaufen oder storniert.
6. Spieltag gehört zu einem anderen Team oder einer anderen Saison.
7. Spieltag ist nicht mehr der aktuell zugeordnete Spieltag.
8. Spieltag ist bereits abgeschlossen oder abgesagt.
9. Doppelte aktive Ausnahme.
10. Fehler beim Audit-Insert oder bei der anschließenden Neuzuordnung: vollständiger Rollback.

### Regression
- Sperre bleibt `open`.
- Keine Änderung an `matchday_players`, Nominierungen oder `played`.
- Keine Änderung an Ereignis-/Gelbkartenhistorie.
- Kein Einfluss auf die allgemeine Kaderempfehlung.
- Andere Sperren und historische Audit-Einträge bleiben unverändert.

Tests werden nach Freigabe in DEV in zurückrollbaren Transaktionen durchgeführt. Testdaten dürfen nicht dauerhaft bestehen bleiben.

## 7. Ausführungsstatus

Noch nicht ausgeführt. Nach ausdrücklicher Abnahme/Freigabe wird das Paket in Supabase DEV ausgeführt. Danach folgen Struktur-, Rechte-, Positiv-, Negativ-, Grenz- und Rollbacktests. Korrekturen werden in DEV durchgeführt und zusammen mit den tatsächlichen Testergebnissen auf `develop` dokumentiert. PROD bleibt unangetastet.
