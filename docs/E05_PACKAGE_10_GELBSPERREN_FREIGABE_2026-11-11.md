# E05 Package 10 – Trainingsdatumsbasierte Gelbsperren

**Status:** Entwurf zur fachlichen und technischen Freigabe – NICHT AUSFÜHRBAR
**Zielumgebung:** Supabase DEV. **PROD:** ausdrücklich ausgeschlossen.
**SQL-Ausführung:** gesperrt bis zu gesonderter Zustimmung.
**Stand:** 11.11.2026

## 1. Zweck
Korrektur der Ermittlung der fünften aktiven gelben Karte, der automatischen Zuordnung einer daraus entstehenden Sperre zu einem Spieltag sowie der manuellen Korrektur dieser Zuordnung.

## 2. Verbindliche Fachregeln
1. Gelbe Karten werden je Spieler, Mannschaft und Saison anhand des Datums des zugehörigen Trainings (training_date_snapshot) chronologisch ausgewertet.
2. Der technische Erfassungszeitpunkt (awarded_at) bestimmt weder Reihenfolge noch Schwellenübertritt.
3. Nur aktive Karten zählen. Stornierte Karten zählen nicht; Wiederherstellungen zählen wieder.
4. Die fünfte aktive gelbe Karte in dieser Trainingschronologie löst eine eigenständige gelbe Sperre aus.
5. Maßgeblicher Ausgangszeitpunkt ist das Trainingsdatum der fünften Karte.
6. Ziel ist der erste danach liegende, zukünftige, geplante Spieltag, dessen Spielart gemäß bestehender Vereins-/Mannschaftseinstellung sperrenrelevant ist und für den keine aktive Ausnahme besteht.
7. Trainings sind niemals Sperrziel.
8. Jede weitere erreichte Fünfer-Schwelle erzeugt eine eigene Sperre. Bestehende offene, erfüllte oder historische Sperren werden nicht überschrieben.
9. Manuelle Zuordnungen bleiben bei automatischer Neuberechnung geschützt (manual_target_locked).
10. Trainer, Mannschaftsadmins und Super Admins im ausgewählten Mannschaftskontext dürfen die Zuordnung manuell ändern. Begründung und Audit-Eintrag mit Benutzer-Snapshot und Zeitstempel sind Pflicht.
11. Keine RLS- oder Rollenänderung in diesem Paket, sofern die Read-only-Prüfung nicht eine konkrete Abweichung nachweist. Eine solche Abweichung wäre separat freizugeben.

## 3. DEV-Befund
award_training_behavior_event zählt aktive gelbe Karten derzeit über awarded_at und bestimmt die fünfte Karte ebenfalls anhand dieses Zeitstempels. Das widerspricht den Regeln 1 und 2.
e05_reconcile_suspensions_after_event_correction verwendet dieselbe Erfassungszeitpunkt-Logik bei Stornierung/Wiederherstellung.
e05_assign_player_suspensions ist die zentrale automatische Zielzuordnung und muss das fünfte Trainingsdatum als frühesten Zielzeitpunkt verwenden. Bestehende Spielart-Konfigurationen und manuelle Sperren müssen respektiert werden.
correct_suspension prüft bereits Rollen, Zielspieltag, Spielart, Ausnahme und Auditierung. Die Frontend-Auswahl lädt derzeit Spieltage ab current_date; sie muss stattdessen das Auslöserdatum der Sperre berücksichtigen. RPC-Fehler müssen sichtbar ausgegeben werden.

## 4. Konfigurationshinweis – Freigabepunkt
In der DEV-Mannschaft sind aktuell keine expliziten Team-Spielarten hinterlegt; auch die Vereins-Einstellung liefert für diese Mannschaft keine relevanten Spielarten. Der nächste geplante Spieltag am 14.11.2026 ist als Freundschaftsspiel angelegt.
Die bestehende Regel lautet: Nur konfigurierte Spielarten sind sperrenrelevant. Package 10 darf diese Einstellung nicht stillschweigend erweitern.
**Vor Ausführung ist zu klären:** Soll Freundschaftsspiel für diese Mannschaft als sperrenrelevant gelten? Falls ja, muss die zuständige Einstellung separat und ausdrücklich freigegeben werden. Diese Migration ändert keine Spielarten-Konfiguration.

## 5. Vorgesehene SQL-Objekte
| Objekt | Änderung |
|---|---|
| award_training_behavior_event(uuid,uuid,text,text) | Zählung und Auswahl der fünften Karte nach training_date_snapshot; Sperre anlegen und Zuordnung auslösen |
| e05_reconcile_suspensions_after_event_correction(uuid,uuid,text) | Gleiche Chronologie bei Storno/Wiederherstellung; Quelle der offenen Sperre neu bestimmen; abgeschlossene Sperren nicht wieder öffnen |
| e05_assign_player_suspensions(uuid,uuid,uuid) | Je offener Sperre das Auslöser-Trainingsdatum ermitteln und ersten zulässigen Spieltag danach auswählen; manuelle Ziele schützen |
| correct_suspension(uuid,uuid,text) | Zielspieltag muss nach dem Auslöser-Trainingsdatum liegen; Rollen-, Spielart-, Ausnahme- und Auditprüfungen erhalten |
| Frontend index.html | Auswahl nicht mehr allein ab current_date, sondern anhand des Auslöserdatums; RPC-Fehler verständlich anzeigen |

Die finalen Funktionsdefinitionen müssen auf den vollständigen DEV-Definitionen basieren. Es werden keine Funktionen verkürzt neu angelegt und keine bestehenden Sicherheitsprüfungen entfernt.

## 6. Daten- und Rückwärtskompatibilität
- Keine Tabellen oder Spalten werden gelöscht oder umbenannt.
- Keine vorhandenen Karten, Sperren oder Audit-Einträge werden gelöscht.
- Bestehende source_event_id-Beziehungen bleiben erhalten.
- Bereits manuell gesperrte Ziele bleiben geschützt.
- Bereits erledigte Sperren bleiben erledigt und werden nicht erneut geöffnet.
- Bestehende Constraints und Indizes bleiben erhalten.
- Die Migration muss transaktional laufen und bei Fehler vollständig zurückrollen.

## 7. Prüfplan
Vorher: aktive/stornierte Karten je Spieler und Saison zählen; Trainingsdatum und Erfassungszeitpunkt gegenüberstellen; Sperrenstatus, Quelle, Ziel und manual_target_locked sichern; Spielarten-Einstellungen und Ausnahmen dokumentieren; Originaldefinitionen, Trigger, Grants und Abhängigkeiten sichern.

Funktionstests:
1. Fünfte Karte wird nachträglich erfasst, hat aber ein früheres Trainingsdatum.
2. Erfassungsreihenfolge weicht vollständig von Trainingschronologie ab.
3. Storno senkt die aktive Anzahl unter fünf; Wiederherstellung hebt sie wieder auf fünf.
4. Weitere Fünfer-Schwelle erzeugt eine separate Sperre.
5. Ein Training nach der fünften Karte darf keine Sperre erfüllen.
6. Nicht relevanter Spieltag vor relevantem Spieltag: der relevante Spieltag wird gewählt.
7. Manuelle Zieländerung bleibt nach Neuberechnung erhalten.
8. Trainer, Mannschaftsadmin und Super Admin korrigieren jeweils erfolgreich.
9. Unberechtigte Rolle und Super Admin ohne ausgewählten Mannschaftskontext werden abgewiesen.
10. Fehlende Begründung, falsche Mannschaft/Saison, nicht geplanter oder nicht relevanter Spieltag werden abgewiesen.
11. Audit enthält alten/neuen Zielwert, Begründung, Benutzer-Snapshot und Zeitstempel.

Abnahme: fünfte Karte ausschließlich nach Trainingsdatum; Sperre ausschließlich auf zulässigem zukünftigen Spieltag; keine Trainingszuordnung; manuelle Ziele geschützt; keine Datenverluste; alle drei Rollen bestehen die Tests.

## 8. Rollback
Vor Ausführung werden vollständige Originaldefinitionen aller betroffenen Funktionen als Rollback-Skript archiviert. Funktionsänderungen werden transaktional angewendet. Bei Fehlern erfolgt ROLLBACK; für eine spätere Rücksetzung werden die gesicherten Originaldefinitionen verwendet. Keine automatische Rücksetzung fachlicher Daten, sofern nicht nachgewiesen ist, dass die Migration solche Daten verändert hat.

## 9. Freigabe-Gates
**Gate A – fachliche Freigabe:** Regeln 1–11 und insbesondere die Konfiguration relevanter Spielarten bestätigen.
**Gate B – SQL-Freigabe:** Vollständiges ausführbares SQL inklusive Originaldefinitionen/Rollback und Prüfabfragen separat vorlegen. Erst nach ausdrücklicher Zustimmung ausführen.
**Gate C – DEV-Abnahme:** Praxistest mit Trainer, Mannschaftsadmin und Super Admin.
**Gate D – PROD:** Eigenständiges Release-Paket, SQL-Release-Katalogeintrag und gesonderte PROD-Freigabe.

## 10. Dokumentationspflicht
Vor SQL-Ausführung: versioniertes Migrationsskript unter supabase/migrations/ gemäß Repository-Schema; SQL-Release-Katalogeintrag mit Paketnummer, Datum, Zweck, Objekten, DEV-/PROD-Status, Freigabe und Commit; Vorher-/Nachher-Prüfungen; Rollback-Skript und Ausführungsprotokoll.

**Aktueller Status:** Entwurf und Befund dokumentiert. Noch kein ausführbares SQL freigegeben oder ausgeführt. Noch keine Frontend-Änderung vorgenommen.
## 11. Entscheidung zur Spielarten-Konfiguration (11.11.2026)

**Nutzerentscheidung:** Die bisherige Vereins-/Mannschaftseinstellung bleibt unverändert.

Konsequenzen für Package 10:
- Es werden keine Spielarten ergänzt, entfernt oder umkonfiguriert.
- Die automatische Sperrenzuordnung berücksichtigt ausschließlich Spieltage, deren Spielart nach der bestehenden Vereins-/Mannschaftseinstellung bereits sperrenrelevant ist.
- Ein Freundschaftsspiel wird nicht allein durch Package 10 sperrenrelevant. Ob der Spieltag vom 14.11.2026 als Ziel infrage kommt, ergibt sich ausschließlich aus der bestehenden Konfiguration.
- Wenn die bestehende Konfiguration keine zulässige Spielart enthält, bleibt die Sperre ohne automatische Zielzuordnung und muss als Konfigurations-/Datenproblem sichtbar gemeldet werden. Die Funktion darf die Einstellung nicht umgehen.
- Die manuelle Korrektur muss dieselbe Spielartenregel respektieren; ein nicht relevanter Spieltag darf nicht als Ziel gewählt werden.

**Freigabestatus:** Fachliche Entscheidung zu diesem Punkt liegt vor. SQL-Ausführung weiterhin nicht freigegeben.
## 12. Vertiefte technische Prüfung und Umsetzungsspezifikation

### 12.1 Bestätigte Signaturen und Sicherheitskontext

Die aktuellen DEV-Definitionen bestätigen folgende Signaturen:

- `award_training_behavior_event(p_training_id uuid, p_player_id uuid, p_event_type text, p_reason text DEFAULT NULL)`
- `e05_reconcile_suspensions_after_event_correction(p_event_id uuid, p_actor_id uuid, p_reason text)`
- `e05_assign_player_suspensions(p_team_id uuid, p_player_id uuid, p_actor_id uuid)`
- `correct_suspension(p_suspension_id uuid, p_target_matchday_id uuid, p_reason text)`
- `e05_assert_suspension_correction_permission(p_team_id uuid, p_actor_id uuid)`

Die Funktionen verwenden SECURITY DEFINER und den festgelegten search_path `pg_catalog, public, auth`. Diese Eigenschaften, bestehende Berechtigungsprüfungen, Grants und Audit-Schreibvorgänge müssen in den vollständigen Ersatzdefinitionen erhalten bleiben.

### 12.2 Präzise fachliche Korrektur

**Gelbe Kartenfolge:** Die aktive Kartenfolge wird nach `training_date_snapshot ASC, id ASC` sortiert. Der Erfassungszeitpunkt `awarded_at` darf nicht in Zählung, Reihenfolge oder Auswahl der fünften Karte verwendet werden.

**Schwellen und Resets:** Die vorhandene Regel für den Beginn einer neuen Zählperiode (zuletzt erfüllte gelbe Sperre bzw. angewandter vorzeitiger Reset) muss erhalten bleiben. Vor der Umsetzung ist der fachliche Vergleich zwischen den bestehenden Zeitstempeln `served_at` / `applied_at` und den Trainingsdaten ausdrücklich zu validieren. Ein stiller Vergleich von DATE mit TIMESTAMPTZ wäre fachlich nicht hinreichend. Die Migration darf keine neue Reset-Regel erfinden.

**Quelle der Sperre:** `training_suspensions.source_event_id` muss auf genau die aktive Karte zeigen, die nach Trainingsdatum die fünfte Karte der aktuellen Zählperiode ist.

**Reconciliation:** Nach Storno oder Wiederherstellung wird dieselbe Trainingsdatum-Chronologie neu ausgewertet. Eine offene Sperre darf nur dann storniert/umgehängt werden, wenn die zugrunde liegende aktive Fünfer-Schwelle dies verlangt. Erfüllte oder abgelaufene Sperren bleiben unverändert. Bestehende Sperren-Audit-Einträge bleiben unverändert erhalten.

### 12.3 Automatische Zielzuordnung

Die aktuelle Zuordnungsfunktion verwendet `current_date` als frühesten Spieltag. Das ist zu ersetzen durch das jeweilige Auslöserdatum der Sperre:

- Gelbe Sperre: `training_date_snapshot` des `source_event_id`.
- Rote Sperre: Datum des Trainingsereignisses, das die rote Sperre ausgelöst hat.

Es wird der erste Spieltag mit `match_date > trigger_training_date` ausgewählt, der:
- derselben Mannschaft und Saison angehört,
- `status = 'planned'` hat,
- nach den bereits bestehenden Vereins-/Mannschaftseinstellungen relevant ist,
- nicht durch eine aktive Ausnahme ausgeschlossen ist,
- nicht bereits für eine andere offene Sperre desselben Spielers reserviert ist.

Die bereits vorhandene Vorreservierung gültiger manueller Ziele und die Auditierung automatischer Änderungen bleiben bestehen. Eine manuelle Zuordnung wird nicht überschrieben, solange sie gültig bleibt.

### 12.4 Manuelle Korrektur

Die bestehende RPC-Funktion prüft bereits:
- Rolle Trainer/Admin bzw. Super Admin mit ausgewähltem Teamkontext,
- Team- und Saisonübereinstimmung,
- geplanten zukünftigen Spieltag,
- Spielart anhand der unveränderten Vereins-/Mannschaftseinstellung,
- aktive Ausnahmen,
- doppelte Zielbelegung,
- Begründung und Audit.

Die Berechtigungsfunktion `e05_assert_suspension_correction_permission` ist im aktuellen DEV-Stand bereits für `trainer`, `admin` und Super Admin im ausgewählten Teamkontext formuliert. Package 10 ändert diese Rollenregeln nicht.

Zusätzliche fachliche Validierung: Das Datum des Zielspieltags muss strikt nach dem Trainingsdatum des auslösenden Ereignisses liegen. Die Frontend-Auswahlliste muss die verfügbaren zukünftigen Spieltage nach demselben Triggerdatum filtern und die RPC-Fehlermeldung sichtbar darstellen.

### 12.5 Konfigurationsentscheidung bestätigt

Am 11.11.2026 hat der Nutzer festgelegt: **Die bisherige Vereins-/Mannschaftseinstellung bleibt unverändert.**

Daraus folgt: Package 10 ändert weder `club_suspension_settings`, `team_suspension_game_type_settings` noch `team_suspension_game_types`. Freundschaftsspiele werden nur dann berücksichtigt, wenn die bestehende Einstellung sie bereits enthält. Bei leerer/fehlender Konfiguration wird kein Spieltag erzwungen; die Sperre bleibt ohne Zielzuordnung und die Oberfläche muss diesen Zustand erklären.

### 12.6 Datenbankmigrationen im DEV-Projekt

Die vorhandene DEV-Migrationshistorie enthält E05 Packages 04–07 sowie Package 09 und dessen Korrekturen vom 08.11.2026. Package 10 muss als neue, eigenständige Migration mit neuer Zeitstempelversion ergänzt werden. Der tatsächliche Migrationsname und Versionsstempel werden erst beim finalen SQL-Artefakt festgeschrieben; keine bestehende Migration wird geändert.

### 12.7 Noch erforderliche technische Artefakte vor Gate B

Vor einer ausführbaren Freigabe müssen folgende Dateien gemeinsam vorliegen:

1. Vollständige `CREATE OR REPLACE FUNCTION`-Definitionen der vier betroffenen Funktionen, direkt aus dem geprüften DEV-Stand abgeleitet und mit Trainingsdatum-Logik angepasst.
2. Rollback-Skript mit den vollständigen, unveränderten DEV-Originaldefinitionen.
3. Read-only Vorher-/Nachher-Prüfabfragen einschließlich Kartenchronologie, Sperrenstatus, Zielspieltag, Konfiguration und Audit.
4. Migrationseintrag im vorhandenen SQL-Release-Katalog. Der Katalogpfad und sein aktuelles Format müssen vor Änderung anhand des Repository-Inhalts verifiziert werden; bis dahin wird kein neuer Katalog unter einem geratenen Pfad angelegt.
5. Frontend-Diff auf `develop`, der die Zielspieltag-Auswahl nach Auslöserdatum ausrichtet und Fehlerzustände des RPC sichtbar macht.

**Status nach dieser Prüfung:** Fachliche Spezifikation und Funktionssignaturen sind präzisiert. Die vollständigen Ersatzdefinitionen, Rollback-Datei und der Katalogeintrag sind noch nicht als ausführbare Artefakte abgelegt. Daher ist Gate B noch nicht erreicht. Keine SQL-Ausführung, keine DEV-Datenänderung, keine Frontend-Änderung und keine PROD-Änderung.

## 13. Arbeitsstand der Artefakte – technische Nachprüfung

Am 11.11.2026 wurden auf `develop` drei Entwurfsdateien angelegt:

- `supabase/migrations/20261111090000_e05_package_10_training_date_suspensions.sql`
- `supabase/rollback/20261111090000_e05_package_10_training_date_suspensions_rollback.sql`
- `docs/E05_PACKAGE_10_TEST_QUERIES.sql`

**Alle drei Dateien sind ausdrücklich Entwürfe und NICHT AUSZUFÜHREN.** Sie wurden aus den aktuellen DEV-Funktionsdefinitionen abgeleitet. Die Rücksetzdatei enthält die gesicherten Originaldefinitionen. Die Read-only-Prüfabfragen enthalten keine schreibenden Statements.

### 13.1 Bei der Gegenprüfung erkannte Restlücke

Die einfache Neuberechnung in `award_training_behavior_event` prüft beim Eintragen einer weiteren gelben Karte zwar die Schwelle, aktualisiert aber nicht in jedem Fall die Quelle einer bereits offenen Sperre, wenn eine nachträglich erfasste Karte die chronologische fünfte Karte verändert. Diese Konstellation muss vor Gate B mit derselben Reconciliation-Logik wie Storno/Wiederherstellung vereinheitlicht werden.

Zusätzlich ist zu prüfen, ob die automatische Zielzuordnung nach der Neuberechnung unmittelbar für neu angelegte Sperren ausgelöst wird. Die Triggerprüfung auf den betroffenen Tabellen zeigte keine entsprechenden Trigger auf `training_behavior_events` oder `training_suspensions`; der Aufrufpfad muss daher explizit in den Funktionsdefinitionen sichergestellt werden.

### 13.2 Noch offene Arbeiten vor Freigabefähigkeit

1. Gelbe-Karten-Neuanlage und Reconciliation in eine einzige konsistente Chronologie-/Sperrenlogik überführen, ohne doppelte Audit-Einträge.
2. Sicherstellen, dass nach Neuanlage, Storno und Wiederherstellung die automatische Zielzuordnung aufgerufen wird.
3. Datumsgrenze für bereits erfüllte Sperren und vorzeitige Resets fachlich gegen alle bestehenden E05-Regeln verifizieren.
4. Frontend-Änderung separat auf `develop` vorbereiten und testen; bislang kein Frontend-Code geändert.
5. Vorhandenen SQL-Release-Katalogpfad im Repository verifizieren und dort Package 10 ergänzen.
6. Migration und Rollback statisch sowie anhand der vollständigen Funktionsdefinitionen gegenprüfen.

**Gate B bleibt gesperrt.** Die Entwurfsdateien sind nicht ausführungs- oder freigabefertig. Es erfolgte keine SQL-Ausführung und keine Datenänderung in DEV oder PROD.
