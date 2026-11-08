# E05 – Paket 7: Saisonabschluss

- **Status:** Freigegeben und zur Umsetzung in DEV vorgesehen
- **Zielumgebung:** Supabase DEV, Projekt pzazqvvoruqnqhcorbwx
- **Branch:** develop
- **SQL:** [E05_PAKET_07_SAISONABSCHLUSS_2026-11-08.sql](https://github.com/bautnhaus/jugendmannschaft/blob/develop/docs/E05_PAKET_07_SAISONABSCHLUSS_2026-11-08.sql)
- **PROD:** bleibt unverändert.

## 1. Umfang

Die RPC public.close_team_season(p_season_id uuid,p_reason text) schließt genau eine aktive Saison eines Teams.

Bei erfolgreichem Abschluss:
1. Die Saison wird auf is_active=false gesetzt.
2. Alle offenen Sperren exakt dieser Team-/Saisonkombination werden auf expired gesetzt.
3. Für jede abgelaufene Sperre wird ein expired-Audit mit vorherigem/nachherigem Zustand, Grund, Akteur und Zeitpunkt erzeugt.
4. Ein eigener Saisonabschluss-Auditdatensatz dokumentiert Saison, Team, Benutzer, Zeitpunkt, Begründung und Anzahl abgelaufener Sperren.
5. Karten-, Trainings-, Sperren- und Ausnahmehistorie bleibt erhalten.

Gelbe Karten werden nicht gelöscht. Da Ereignisse saisonbezogen gespeichert sind, beginnt die nächste aktive Saison mit einem separaten Gelbkartenkonto. Es wird keine neue Saison angelegt.

## 2. Berechtigungen und Schutz

- Authentifizierung erforderlich.
- Nur Mannschaftsadmin (team_member_roles.role='admin') oder Super Admin mit explizit ausgewähltem Teamkontext.
- Pflichtbegründung.
- Saison wird vor Prüfung/Änderung gesperrt.
- Doppelte Schließung wird abgewiesen.
- Nur offene Sperren des exakten Teams und der exakten Saison werden abgelöst.
- Die Änderung ist atomar. Fehler bei Sperren-Audit oder Saison-Audit rollen alle Änderungen zurück.
- Saisonabschluss-Audit ist append-only; direkte Änderungen durch anon oder authenticated sind gesperrt.

## 3. Neue Datenbankobjekte

- Tabelle team_season_closure_audit mit eindeutiger Zuordnung pro Saison.
- Append-only Triggerfunktion e05_reject_season_closure_audit_mutation().
- RPC close_team_season(uuid,text).

## 4. Bewusste Abgrenzung

- Keine automatische Anlage einer Folgesaison.
- Keine Übertragung von Gelben Karten.
- Keine Löschung oder Änderung der Ereignishistorie.
- Keine Änderung an Nominierungen oder tatsächlichen Einsätzen.
- Keine rückwirkende Änderung bereits abgeleisteter Sperren.
- Keine Änderung an anderen Teams oder Saisons.
- Bereits bestehende Ausnahmen bleiben als Historie bestehen; die zugehörige Sperre wird bei Saisonabschluss abgelöst.

## 5. DEV-Prüfplan

### Positiv
1. Berechtigter Mannschaftsadmin schließt aktive Saison mit Begründung.
2. Saison wird inaktiv.
3. Offene gelbe und rote Sperren derselben Saison werden abgelöst.
4. Für jede abgelöste Sperre entsteht genau ein expired-Audit.
5. Saisonabschluss-Audit enthält korrekten Grund, Akteur, Zeitpunkt und Anzahl.
6. Sperren anderer Saisons/Teams bleiben unverändert.
7. Ereignis- und Historieneinträge bleiben erhalten.

### Negativ
1. Nicht authentifizierter Aufruf.
2. Trainer ohne Adminrolle.
3. Super Admin ohne ausgewählten Teamkontext.
4. Leere Begründung.
5. Unbekannte Saison.
6. Bereits geschlossene Saison.
7. Fehler bei Auditierung: vollständiger Rollback.

### Regression
- RLS und Leseberechtigung auf Saisonabschluss-Audit.
- Direkte Schreibversuche durch authenticated/anon nicht möglich.
- Audit kann nicht geändert oder gelöscht werden.
- Keine Änderung an Matchdays, Nominierungen, Einsätzen, Trainings oder Spielerzuordnungen.

Testdaten werden ausschließlich in DEV und innerhalb zurückrollbarer Transaktionen verwendet. Die tatsächlichen Ergebnisse werden nach der Ausführung in Abschnitt 6 dokumentiert.
