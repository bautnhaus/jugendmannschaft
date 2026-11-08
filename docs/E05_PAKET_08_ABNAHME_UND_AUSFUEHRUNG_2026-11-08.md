# E05 – Paket 8: Vorzeitiger Sperrausgleich

- **Status:** SQL-Paket zur Freigabe vorbereitet; noch nicht ausgeführt
- **Zielumgebung:** Supabase DEV, Projekt pzazqvvoruqnqhcorbwx
- **Branch:** develop
- **PROD:** ausdrücklich ausgeschlossen

## 1. Fachlicher Zweck

Ein Trainer kann einen Spieler, der für einen konkreten Spieltag nicht nominiert wurde, freiwillig für einen vorzeitigen Sperrausgleich vormerken. Das ist unabhängig von der Anzahl seiner gelben Karten und keine reguläre Sperre.

Der Reset wird erst wirksam, wenn genau dieser Spieltag tatsächlich durchgeführt wurde. Die Ereignishistorie bleibt unverändert; nur das aktive gelbe Kartenkonto beginnt ab dem Anwendungszeitpunkt neu.

## 2. Enthaltene Datenbankobjekte

- Tabelle matchday_early_suspension_resets mit Status pending/applied/cancelled und vollständigen Snapshots.
- Tabelle matchday_early_suspension_reset_audit als append-only Historie.
- RPC schedule_early_suspension_reset(matchday_id,player_id,reason).
- RPC cancel_early_suspension_reset(reset_id,reason).
- Interne Statusübergangsfunktion e05_transition_early_reset(...).
- Trigger für automatische Stornierung bei späterer Nominierung.
- Trigger für automatische Stornierung bei Spieltagsabsage.
- Trigger für automatische Anwendung nach Statuswechsel des Spieltags auf done.
- Anpassung der Gelbkarten-Zählung in award_training_behavior_event, damit der letzte angewendete Sperrausgleich als neuer Startpunkt des aktiven Kontos gilt.

## 3. Verbindliche Regeln

1. Nur Trainer/Admin des Teams oder Super Admin im ausdrücklich ausgewählten Teamkontext.
2. Pflichtbegründung beim Vormerken und bei manueller Stornierung.
3. Nur aktiver Spieler der Mannschaft und konkreter, geplanter Spieltag derselben aktiven Saison.
4. Der Spieler darf für diesen Spieltag noch nicht in matchday_players nominiert sein.
5. Eine normale Nichtnominierung erzeugt keinen Reset.
6. Spätere Nominierung storniert einen pending Reset automatisch und revisionssicher.
7. Spieltagsabsage storniert einen pending Reset automatisch.
8. Status done wendet einen pending Reset genau einmal an.
9. Ein bereits angewendeter Reset wird nicht rückwirkend aufgehoben.
10. Ein Reset verändert weder Ereignishistorie noch Nominierung/Einsatz und ist kein reguläres Ableisten einer Sperre.
11. Bestehende offene gelbe oder rote Sperren bleiben unberührt. Der Reset hebt keine bereits ausgelöste Sperre auf.
12. Rote Karten und rote Sperren bleiben vollständig unberührt.
13. Keine Hard Deletes; jede Zustandsänderung wird mit Vorher-/Nachherwerten, Grund, Akteur und Zeitpunkt auditiert.
14. Ein Reset wirkt nur auf die gelbe Kartenbilanz desselben Spielers, Teams und derselben Saison ab applied_at.

## 4. Automatische Abläufe

### Vormerkung
- Trainer wählt einen nicht nominierten Spieler im bestehenden Spieltags-Kaderplan.
- Die RPC prüft Berechtigung, Team, aktive Saison, Spieltagsstatus und fehlende Nominierung.
- Reset wird als pending gespeichert.

### Spätere Nominierung
- Ein INSERT oder eine relevante UPDATE-Änderung in matchday_players storniert den zugehörigen pending Reset automatisch.
- Die Stornierung wird mit Grund und Akteur auditiert.
- Die normale Nominierung bleibt unverändert.

### Spieltagsabsage
- Wechsel des Spieltagsstatus auf cancelled storniert alle zugehörigen pending Resets.
- Kein gelber Kartenstand wird verändert.

### Tatsächliche Durchführung
- Wechsel des Spieltagsstatus auf done wendet alle zugehörigen pending Resets an.
- applied_at markiert den exakten Zeitpunkt.
- Ab diesem Zeitpunkt zählen ältere gelbe Ereignisse nicht mehr zum aktiven gelben Kartenkonto.
- Die Ereignisse bleiben in der Historie sichtbar.

## 5. Nicht enthalten

- Keine Änderung der allgemeinen Kaderempfehlung.
- Keine automatische Nominierung oder Abmeldung.
- Keine Änderung an roten Sperren.
- Keine Aufhebung bereits offener Sperren.
- Keine automatische Rücknahme eines bereits angewendeten Resets.
- Keine Änderung an PROD.

## 6. DEV-Prüfplan

### Positiv
1. Trainer merkt nicht nominierten Spieler mit Grund vor.
2. Reset steht auf pending.
3. Durchführung des Spieltags setzt Reset auf applied und schreibt Audit.
4. Aktives gelbes Konto beginnt ab applied_at neu.
5. Historische gelbe Ereignisse bleiben erhalten.

### Negativ
1. Nicht authentifizierter Aufruf.
2. Benutzer ohne Trainer-/Adminrolle.
3. Super Admin ohne ausgewählten Teamkontext.
4. Leere Begründung.
5. Spieler aus anderem Team oder inaktiver Spieler.
6. Spieltag aus anderer oder inaktiver Saison.
7. Bereits nominierter Spieler.
8. Spieltag nicht geplant oder bereits vergangen.
9. Unbekannte Reset-ID.
10. Manuelle Stornierung eines bereits angewendeten Resets.

### Automatische Grenzfälle
1. Nachträgliche Nominierung storniert pending Reset automatisch.
2. Absage storniert pending Reset automatisch.
3. Spieltag done wendet pending Reset genau einmal an.
4. Wiederholtes Statusupdate erzeugt keinen zweiten Audit-/Anwendungsdatensatz.
5. Reset hebt keine offene gelbe oder rote Sperre auf.
6. Gleichzeitige Nominierung und Vormerkung wird über Zeilensperren/Eindeutigkeitsindex serialisiert.

### Regression
- Bestehende award_training_behavior_event-Validierung bleibt erhalten.
- Gelbe Sperre entsteht weiterhin exakt bei fünf aktiven gelben Karten seit dem letzten Reset oder der letzten abgeleisteten gelben Sperre.
- Rote Karte löst weiterhin sofort eine rote Sperre aus.
- Kartenhistorie, Nominierungen, Einsätze und allgemeine Kaderempfehlung bleiben unverändert.
- RLS, ACL und append-only Audit werden geprüft.

Alle Tests werden in DEV mit synthetischen Daten und zurückrollbaren Transaktionen durchgeführt. Testresultate werden nach Ausführung in diesem Dokument ergänzt.

## 7. Technischer DEV-Abgleich

Der read-only Abgleich hat bestätigt:
- Die Tabellen matchday_early_suspension_resets und matchday_early_suspension_reset_audit existieren in DEV noch nicht.
- award_training_behavior_event existiert bereits und erzeugt rote bzw. fünfte gelbe Sperren atomar.
- Die Gelbkarten-Zählung verwendet aktuell den letzten served_at-Zeitpunkt einer gelben Sperre als Untergrenze.
- matchday_players wird über INSERT/UPDATE beschrieben; matchdays verwendet die Statuswerte planned, done und cancelled.
- Die Migration ergänzt deshalb die beiden fehlenden Tabellen, Audit/RLS/ACL, die Vormerkungs- und Storno-RPCs, automatische Trigger für Nominierung/Absage/Durchführung und ersetzt award_training_behavior_event vollständig auf Basis der aktuellen DEV-Fassung. Die einzige fachliche Erweiterung dieser RPC ist die zusätzliche Berücksichtigung des letzten applied_at eines Sperrausgleichs bei der Gelbkarten-Zählung.

## 8. Ausführungsgrenzen

- Das SQL enthält die vollständige CREATE OR REPLACE-Fassung der bestehenden award_training_behavior_event-RPC; bestehende Validierungen, Berechtigungsprüfungen, Ereignis-Audits sowie die atomare Erzeugung gelber/roter Sperren bleiben erhalten.
- Ein bereits ausgelöster offener gelber oder roter Sperrfall wird durch den Sperrausgleich nicht aufgehoben.
- Die Trigger wenden nur pending-Resets an. Ein zweiter Statuswechsel kann denselben Reset nicht erneut anwenden.
- Tests und synthetische Testdaten werden ausschließlich nach Freigabe in DEV ausgeführt. PROD bleibt unverändert.

**Dieses Paket ist vollständig zur fachlichen und technischen Freigabe vorbereitet, wurde aber noch nicht in Supabase ausgeführt.**


## 8. Tatsächliche Umsetzung in DEV

- **Freigabe:** ausdrücklich erteilt.
- **Ausführung:** 08.11.2026 in Supabase DEV, Projekt \`pzazqvvoruqnqhcorbwx\`.
- **Methode:** direkte SQL-Ausführung in DEV innerhalb einer Transaktion; bei SQL-Fehlern wäre die Transaktion abgebrochen worden.
- **PROD:** nicht verändert.

### Implementierte Objekte

- Tabellen \`matchday_early_suspension_resets\` und \`matchday_early_suspension_reset_audit\`
- RPCs \`schedule_early_suspension_reset\` und \`cancel_early_suspension_reset\`
- interne Statusübergangsfunktion \`e05_transition_early_reset\`
- automatische Stornierung bei späterer Nominierung
- automatische Stornierung bei Spieltagsabsage
- automatische Anwendung bei Spieltagsstatus \`done\`
- Erweiterung von \`award_training_behavior_event\`: Das aktive gelbe Kartenkonto berücksichtigt jetzt sowohl den Zeitpunkt der letzten abgeleisteten gelben Sperre als auch den Zeitpunkt des letzten angewendeten Sperrausgleichs.

### Zusätzliche Berechtigungskorrektur

Die beiden Triggerfunktionen wurden nach der ersten Berechtigungsprüfung zusätzlich von direkter Ausführung durch \`PUBLIC\`, \`anon\`, \`authenticated\` und \`service_role\` ausgeschlossen. Sie sind ausschließlich als Datenbanktrigger vorgesehen. Die beiden fachlichen RPCs sind nur für \`authenticated\` ausführbar; \`anon\` und \`PUBLIC\` haben keine Ausführungsrechte. Direkte Schreibrechte auf den beiden neuen Tabellen sind für \`authenticated\` nicht erteilt.

### Positivtests – alle bestanden

| Test | Ergebnis |
|---|---|
| Vormerkung erzeugt Status \`pending\` | Bestanden |
| Spieltag wechselt auf \`done\`; Reset wird \`applied\` | Bestanden |
| Vier historische gelbe Karten bleiben Historie und zählen nach Reset nicht mehr zum aktiven Konto | Bestanden |
| Vier neue gelbe Karten nach Reset lösen keine Sperre aus | Bestanden |
| Fünfte neue gelbe Karte nach Reset löst genau eine gelbe Sperre aus | Bestanden |
| Spätere Nominierung storniert den pending Reset | Bestanden |
| Spieltagsabsage storniert den pending Reset | Bestanden |
| Audit für Vormerken, Anwenden und Stornieren | Bestanden |

### Negativ- und Berechtigungstests – alle bestanden

| Test | Ergebnis |
|---|---|
| Benutzer ohne Teamrolle kann keinen Reset vormerken | Abgewiesen |
| Leere Begründung | Abgewiesen |
| Bereits nominierter Spieler | Abgewiesen |
| \`anon\` kann die fachlichen RPCs nicht ausführen | Abgewiesen |
| Direkte INSERT/UPDATE/DELETE-Rechte auf Reset- und Audit-Tabellen fehlen | Bestanden |
| Audit-Manipulation wird durch den Append-only-Trigger verhindert | Abgewiesen |
| Triggerfunktionen sind nicht direkt ausführbar | Bestanden |

### Testdaten und Rollback

Alle Positiv- und Negativtests wurden mit synthetischen Spielern, Trainings, Spieltagen und Karten innerhalb von Transaktionen ausgeführt und zurückgerollt. Die anschließende DEV-Kontrolle ergab:
- Reset-Datensätze: 0
- Reset-Audit-Datensätze: 0
- synthetische Spieler: 0
- synthetische Trainings: 0
- synthetische Spieltage: 0

Die ersten Testläufe zeigten zwei Anpassungsbedarfe im Testskript: PostgreSQLs \`now()\` bleibt innerhalb einer Transaktion konstant, weshalb der Testzeitpunkt des angewendeten Resets für die Kartenkonto-Regressionsprüfung angepasst werden musste; außerdem umfasst das erwartete Audit sechs Einträge (jeweils Vormerken plus Statusübergang). Nach diesen Testkorrekturen liefen sämtliche Prüfungen erfolgreich. An der produktiven Funktionslogik war dafür keine weitere Änderung erforderlich.

### Ergebnis

**Paket 8 ist in DEV umgesetzt. Die positiven, negativen, Berechtigungs- und Regressionstests sind bestanden.** PROD blieb unangetastet.
