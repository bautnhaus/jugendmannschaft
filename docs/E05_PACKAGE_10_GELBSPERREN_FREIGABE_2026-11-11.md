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