# E05 / AP05 – Umsetzungsvorschlag: Sperrmaßnahmen im Spielerkachel-Optionsmenü

**Stand:** 12.11.2026  
**Zielumgebung:** ausschließlich GitHub develop / Supabase DEV  
**Status:** Konzeptvorschlag zur Prüfung – keine Umsetzung freigegeben  
**PROD / main:** ausdrücklich außerhalb des Umfangs

## 1. Verbindliche Nutzerentscheidungen

1. Drei-Punkte-Optionsmenü auf jeder Spielerkachel.
2. Begründung ist bei jeder Erteilung und jeder Rücknahme Pflicht.
3. Ausnahme zurücknehmen wirkt sofort: Spieler wird für den konkreten Spieltag wieder regulär gesperrt.
4. Ausnahme-Chip bleibt nach Erteilung sichtbar; die Kachel übernimmt ansonsten vollständig ihre normale Kontur sowie Empfehlungs-/Nominierungsdarstellung.
5. Sperr- und Audit-Historie wird nie gelöscht.

## 2. Read-only Bestandsbefund aus develop-Dokumentation

| Fachaktion | Dokumentierte Funktion | Paket |
|---|---|---|
| Ausnahme erteilen | grant_suspension_exception(uuid,uuid,text) | 5/6 |
| Ausnahme zurücknehmen | revoke_suspension_exception(uuid,text) | 6 |
| Vorzeitigen Sperrausgleich vormerken | schedule_early_suspension_reset(...) | 8 |
| Vormerkung zurücknehmen | cancel_early_suspension_reset(...) | 8 |

Die Funktionen sind in den SQL-Dokumenten auf develop beschrieben. Ihre aktuelle Existenz, exakten Signaturen und Rechte müssen vor Frontend-Integration direkt im Supabase-DEV-Katalog read-only verifiziert werden. Aus der Dokumentation allein wird keine aktuelle DB-Realität abgeleitet.

## 3. Kritischer Sicherheits- und Fachprüfpunkt

Der dokumentierte Widerrufs-RPC für Ausnahmen setzt den Ausnahme-Datensatz auf widerrufen und stößt die Sperren-Neuzuordnung an. Vor Frontend-Integration ist zwingend die vollständige Funktion zu prüfen:
- Wird bei einer bereits nominierten Person die Zeile in matchday_players atomar entfernt oder anderweitig sicher blockiert?
- Wird die offene Sperre unmittelbar wieder dem aktuellen Spieltag zugeordnet?
- Bleibt die Ausnahmehistorie mit Widerrufsbegründung, Akteur und Zeitstempel erhalten?
- Verhindern Trigger/RPCs, dass eine parallele Nominierung während der Rücknahme bestehen bleibt?

Falls eine bestehende Nominierung nicht konsistent entfernt wird, darf das Frontend den Vorgang nicht als erfolgreich darstellen. Dann ist ein separater DB-Änderungsentwurf mit vollständigem SQL, Berechtigungsprüfung, Audit, Rollback und Testfällen erforderlich. Keine SQL-Ausführung ohne gesonderte Freigabe.

## 4. Optionsmenü – Sichtbarkeit und Aktionen

Das Drei-Punkte-Menü ist auf jeder Spielerkachel verfügbar. Es zeigt ausschließlich Aktionen, die zum Spielerstatus und aktuellen Spieltag passen.

| Zustand | Menüaktion |
|---|---|
| Offene Sperre, aktuelle Zuordnung, keine Ausnahme | Ausnahme erteilen |
| Aktive Ausnahme für aktuellen Spieltag | Ausnahme zurücknehmen |
| Zulässiger vorgemerkter Sperrausgleich | Vorzeitigen Sperrausgleich zurücknehmen |
| Spieler ohne Sperre, für den der vorzeitige Ausgleich fachlich zulässig ist | Vorzeitigen Sperrausgleich erteilen |
| Vorgang bereits angewendet/abgeschlossen oder Spieltag nicht mehr änderbar | Keine unzulässige Änderungsaktion; ggf. nur Status/Verlauf anzeigen |

Die genauen Bedingungen für vorzeitigen Sperrausgleich müssen aus Paket 8 und AP05.2 übernommen werden. Nicht anhand vereinfachter Frontend-Annahmen nachbauen.

## 5. Einheitlicher Bestätigungsdialog

Jede Aktion öffnet einen Bestätigungsdialog mit Spielername, betroffenen Spieltag/Sperrbezug, Pflichtfeld Begründung sowie Abbrechen/Bestätigen.

Bei Rücknahmen muss der Dialog die unmittelbare Auswirkung erklären. Bei Ausnahme-Widerruf darf die UI eine Entfernung einer bestehenden Nominierung nur versprechen, wenn das DB-Verhalten technisch verifiziert und sichergestellt ist.

## 6. Kachelstatus und Kaderplanung

- Offene Sperre ohne Ausnahme: sanft rote gesamte Kachel, Chip „Gesperrt · Ausnahme möglich“, nicht empfehlbar/nominierbar.
- Ausnahme erteilt: normale Kachelkontur und normale Empfehlungs-/Nominierungsdarstellung; Chip „Ausnahme erteilt“ an einheitlicher Position.
- Ausnahme zurückgenommen: sofort wieder sanft rote Kachel; Chip „Gesperrt · Ausnahme möglich“; aus Empfehlung/Nominierung ausgeschlossen.
- Beide Chips nutzen eine gemeinsame Komponente mit identischer Höhe, Schrift, Zeilenhöhe, Padding, Margin und Position.
- Ein Ausnahme-Chip darf die bestehende Empfehlungs- oder Nominierungsdarstellung nicht überschreiben.

## 7. Umsetzungsschritte nach Freigabe

1. Aktuelle DEV-DB-Funktionsdefinitionen und Grants read-only prüfen: vier RPCs sowie abhängige Trigger/Funktionen.
2. Widerrufsauswirkung auf matchday_players und Konkurrenz-/Transaktionsverhalten verifizieren.
3. Falls DB-Lücke: separaten SQL-Entwurf zur Prüfung vorlegen; nicht ausführen.
4. Frontend-Bestand in index.html prüfen: Kachel-Markup, Klickverhalten, vorhandene Drei-Punkte-Menüs/Komponenten, Event-Delegation und mobile Layouts.
5. Frontend-Implementierung auf develop: Optionsmenü für alle Kacheln, statusabhängige Aktionen, einheitlicher Pflichtbegründungsdialog, bestehende RPCs aufrufen.
6. Nach jeder erfolgreichen RPC-Aktion den aktuellen Sperr-/Ausnahmestatus neu laden und Kachel, Empfehlung, Auswahl und Zähler konsistent neu rendern. Bei Fehlern lokalen Zustand nicht optimistisch verändern.
7. DEV-Praxistests mit Trainer und Mannschaftsadmin, inklusive iPhone/Darkmode und Negativtests.
8. Alle SQL-/Frontend-Änderungen und Testergebnisse in den Migration-/Change-Logs und Projektkontext eintragen.

## 8. Mindest-Testfälle

- Menü erscheint auf jeder Spielerkachel und verdeckt nicht den normalen Kachel-Klick.
- Offene Sperre: Ausnahme erteilen nur mit Begründung; danach normale Kachel + Ausnahme-Chip; Empfehlung/Nominierung zulässig.
- Ausnahme zurücknehmen nur mit Begründung; sofort rote Kachel und Sperre wieder aktiv.
- Bereits nominierter Spieler: Widerruf führt atomar zum fachlich korrekten Zustand; kein „gesperrt und dennoch nominiert“.
- Vorzeitigen Sperrausgleich vormerken und zurücknehmen jeweils nur bei zulässigem Status und mit Begründung.
- Bereits angewendeter/abgeschlossener Sperrausgleich kann nicht rückwirkend storniert werden.
- Doppelklick, parallele Requests und wiederholte RPC-Aufrufe erzeugen keine doppelten Vorgänge.
- Nicht berechtigte Rollen können keine RPC-Aktion ausführen.
- Audit enthält Erteilung/Rücknahme, Begründung, Akteur und Zeitstempel.
- Chip-Geometrie bleibt bei beiden Texten gleich; Kachelkontur/-farbe folgt dem jeweiligen Empfehlungs-/Nominierungsstatus.

## 9. Freigabegrenzen

Dieser Vorschlag dokumentiert den geplanten Umfang. Er ist keine Freigabe zur Code- oder Datenbankänderung. Vor Implementierung werden die read-only DB-Prüfung und ggf. ein separater SQL-Entwurf vorgelegt. DEV ist das einzige Ziel; main und PROD bleiben unverändert.
## 10. Ergebnis der tatsächlichen DEV-Prüfung (12.11.2026)

### Datenbank
- Alle vier erwarteten Nutzer-RPCs sind im aktuellen Supabase-DEV-Projekt vorhanden.
- revoke_suspension_exception(uuid,text) entfernt keine bestehende Nominierung aus matchday_players.
- Der aktuelle Nominierungs-Guard blockiert neue/aktualisierte Nominierungen ohne Ausnahme, entfernt aber keine bestehende Nominierung und sperrt die Spielerzeile vor dem Statuscheck nicht. Damit besteht ein Parallelitätsrisiko, das vor einer zuverlässigen Sofortwirkung geschlossen werden muss.
- Die matchday_players-Tabelle besitzt den zusammengesetzten Primärschlüssel (matchday_id,player_id) und eine passende Delete-RLS-Policy. Der Widerrufs-RPC ist SECURITY DEFINER und kann die gezielte Entfernung innerhalb seiner Transaktion durchführen.
- cancel_early_suspension_reset(uuid,text) kann nur eine Vormerkung mit Status pending zurücknehmen. Bereits angewendete Vorgänge sind geschützt und werden nicht rückwirkend verändert.

### Datenbank-Entwurf
Ein SQL-Entwurf liegt unter docs/drafts/DB-MIG-DRAFT_E05_EXCEPTION_REVOKE_IMMEDIATE_2026-11-12.sql. Er ergänzt den Widerrufs-RPC um die transaktionale Entfernung einer vorhandenen Nominierung und erweitert den Nominierungs-Guard um einen Spielerzeilen-Lock in derselben Reihenfolge wie der Widerrufs-RPC. Die Auditdaten sollen festhalten, ob eine Nominierung entfernt wurde.

Der Entwurf ist **nicht ausgeführt** und nicht als Migration registriert. Vor Ausführung sind vollständige SQL-Prüfung, Abgleich gegen den Live-Stand und separate ausdrückliche Freigabe erforderlich.

### Frontend-Bestand
- Die Spielerkacheln werden aktuell als Button gerendert; ein weiteres Options-Button-Element darf nicht darin verschachtelt werden.
- Für das Optionsmenü wird ein Wrapper mit zwei Geschwisterelementen benötigt: bestehende Kachel als Hauptaktion und Drei-Punkte-Optionsbutton mit statusabhängigem Menü.
- Die bestehende Ausnahme-Erteilung ist bereits über grant_suspension_exception angebunden. Widerruf und vorzeitiger Sperrausgleich haben noch keinen Kachel-Optionsflow.

### Reihenfolge / aktueller Stopp
Die Schritte 1 und 2 sind abgeschlossen; Schritt 3 (DB-Entwurf) ist vorbereitet. Schritt 4 (Frontend-Implementierung) wird bewusst erst nach separater Freigabe, Ausführung und erfolgreicher DEV-Prüfung des DB-Entwurfs begonnen. So wird keine Oberfläche ausgeliefert, die eine Sofortwirkung verspricht, die die Datenbank noch nicht garantiert.