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


## 6. Tatsächliche Ausführung und DEV-Ergebnisse

- **Freigabe:** ausdrücklich erteilt.
- **Umgebung:** Supabase DEV, Projekt \`pzazqvvoruqnqhcorbwx\`.
- **PROD:** nicht verändert.
- **Ergebnis:** Paket 7 und die anschließende RLS-Korrektur erfolgreich ausgeführt.

### Ausgeführte Migrationen

| Migration | Version | Ergebnis |
|---|---:|---|
| \`e05_package_07_controlled_season_closure\` | \`20261108180535\` | Erfolgreich |
| \`e05_package_07_fix_season_audit_context_rls\` | \`20261108180944\` | Erfolgreich |

### Positivtests

Alle Positivtests wurden in einer Transaktion mit synthetischer Saison, synthetischen Ereignissen und synthetischen Sperren durchgeführt. Die Transaktion wurde zurückgerollt.

| Test | Ergebnis |
|---|---|
| Saison wird geschlossen (\`is_active=false\`) | Bestanden |
| Offene gelbe Sperre wird auf \`expired\` gesetzt | Bestanden |
| Offene rote Sperre wird auf \`expired\` gesetzt | Bestanden |
| \`expired_at\` wird gesetzt | Bestanden |
| Bereits abgeleistete Sperre bleibt \`served\` | Bestanden |
| Für jede abgelaufene Sperre entsteht ein \`expired\`-Audit | Bestanden |
| Saisonabschluss-Audit speichert Begründung | Bestanden |

Ergebnis der Kernprüfung: zwei offene Sperren abgelaufen, eine bereits abgeleistete Sperre unverändert.

### Negativtests

| Test | Ergebnis |
|---|---|
| Trainer ohne Adminrolle (ohne Super-Admin-Sonderrecht) | Abgewiesen |
| Leere Begründung | Abgewiesen |
| Zweiter Abschluss derselben Saison | Abgewiesen |
| Unbekannte Saison-ID | Abgewiesen |
| Änderung eines Saisonabschluss-Auditdatensatzes | Abgewiesen |

Für den Trainer-Negativtest wurde die Super-Admin-Rolle des Testbenutzers ausschließlich innerhalb der zurückrollbaren Testtransaktion temporär entfernt. Nach Rollback war sie unverändert vorhanden.

### Berechtigungs- und RLS-Prüfungen

| Prüfung | Ergebnis |
|---|---|
| RPC ist SECURITY DEFINER | Bestanden |
| RPC für \`authenticated\` ausführbar | Bestanden |
| RPC für \`anon\` nicht ausführbar | Bestanden |
| RLS auf \`team_season_closure_audit\` aktiviert | Bestanden |
| \`authenticated\` darf lesen | Bestanden |
| \`authenticated\` darf nicht direkt INSERT/UPDATE/DELETE ausführen | Bestanden |
| \`anon\` darf nicht lesen | Bestanden |
| Teammitglieder und Benutzer mit zulässigem ausgewähltem Teamkontext können Audit lesen | Policy geprüft |

Die erste RLS-Fassung erlaubte Audit-Lesezugriff nur über \`is_team_member(team_id)\`. Das entsprach nicht vollständig der Vorgabe für Super Admins im ausdrücklich ausgewählten Teamkontext. Deshalb wurde die Policy in einer separaten Korrekturmigration auf \`is_team_member(team_id) OR has_selected_team_context(team_id)\` erweitert. Diese Korrektur ist eingespielt und geprüft.

### Testdatenkontrolle

Nach Rollback wurden alle synthetischen Kennungen abgefragt:
- Test-Saisons: 0
- Saisonabschluss-Audits: 0
- Trainingsevents: 0
- Sperren: 0
- Sperren-Audits: 0

Die temporär entfernte Super-Admin-Rolle wurde durch Rollback wiederhergestellt. Es sind keine Testdaten oder Testberechtigungsänderungen zurückgeblieben.

### Supabase Security Advisor

Der Advisor meldet weiterhin bestehende allgemeine Hinweise zu SECURITY DEFINER-Funktionen (insgesamt 46) sowie zwei bereits vorhandene Tabellen ohne RLS-Policy (\`user_club_context\`, \`user_team_context\`) und deaktivierten Leaked-Password-Schutz. Die neue RPC \`close_team_season\` erscheint in der SECURITY DEFINER-Warnliste, weil sie – wie die bestehenden geschützten Schreib-RPCs – für authentifizierte Benutzer ausführbar sein muss. Die Funktion prüft die Teamadmin- bzw. Super-Admin-Berechtigung serverseitig. Die übrigen Advisor-Hinweise wurden durch Paket 7 nicht verändert und sind nicht Teil dieses Pakets.

### Ergebnis

**Paket 7 ist in DEV umgesetzt und die geprüften Positiv-, Negativ-, Berechtigungs- und Rollbacktests sind bestanden.** Der erste Testdatensatz für eine bereits abgeleistete Sperre erfüllte zunächst nicht die vorhandene Datenbank-Constraint für Ableistungsmetadaten. Der Testdatensatz wurde korrigiert; das war kein Fehler der Paket-7-Migration. PROD blieb unangetastet.
