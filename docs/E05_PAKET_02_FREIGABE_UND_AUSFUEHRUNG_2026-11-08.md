# E05 – Freigabe- und Ausführungsprotokoll Paket 2

## Paket 2: Trainingsereignis vergeben (RPC)

- **Datum der Erstellung:** 08.11.2026
- **Zielumgebung nach Freigabe:** Supabase DEV
- **Supabase-Projekt:** `pzazqvvoruqnqhcorbwx`
- **SQL-Datei:** [E05_PAKET_02_AWARD_TRAINING_BEHAVIOR_EVENT_2026-11-08.sql](https://github.com/bautnhaus/jugendmannschaft/blob/develop/docs/E05_PAKET_02_AWARD_TRAINING_BEHAVIOR_EVENT_2026-11-08.sql)
- **Branch:** `develop`
- **Status:** erstellt, Freigabe ausstehend; noch nicht in Supabase ausgeführt
- **Abhängigkeit:** Paket 1 muss in DEV vorhanden sein.

### Umfang

Paket 2 erstellt bzw. ersetzt ausschließlich die Funktion:

`public.award_training_behavior_event(uuid, uuid, text, text)`

Die Funktion vergibt gelbe Karte, rote Karte oder positiven Stern und schreibt Ereignis und Audit-Eintrag atomar.

### Serverseitige Prüfungen

- Authentifizierung über `auth.uid()`.
- Teamzugehörigkeit des Trainings und Spielers.
- Spieler muss aktiv sein.
- Akteur muss im konkreten Team Trainer oder Mannschaftsadmin sein; Superadmin nur mit ausgewähltem Teamkontext.
- Anwesenheit muss über `attendance.present = true` bestätigt sein.
- Abgesagte Trainings werden abgewiesen.
- Aktive Saison muss eindeutig bestimmbar und teamgleich sein.
- Karten benötigen einen nichtleeren Grund; beim Stern ist der Grund optional.
- Ereignistyp ist auf `yellow_card`, `red_card`, `positive_star` begrenzt.
- Doppelte aktive Karten/Sterne werden durch die Unique-Indizes aus Paket 1 verhindert.

### Bewusste Abgrenzung

Dieses Paket erzeugt noch keine Sperre. Die automatische rote Sperre bzw. gelbe Sperre bei fünf aktiven gelben Karten wird in einem separaten Folgepaket ergänzt. Vor Abschluss dieses Lifecycle-Schritts ist die Funktion nur für DEV-Tests und nicht für einen produktiven Trainerworkflow vorgesehen.

Keine bestehenden Tabellen, Daten, Rollen oder Policies werden geändert. Keine Änderungen an PROD.

### Geplante Prüfungen nach Freigabe und Ausführung

1. Funktionssignatur und SECURITY DEFINER-Eigenschaft vorhanden.
2. EXECUTE für `authenticated` vorhanden; für `anon`, `PUBLIC` und `service_role` nicht vorhanden.
3. Positivtest: gültiger Trainer, aktiver Spieler, anwesend, aktive Saison, gültiger Ereignistyp.
4. Negativtest: unauthentifiziert, fehlende Rolle, falsches Team, inaktiver Spieler, nicht anwesend, abgesagtes Training, fehlende/mehrdeutige aktive Saison, ungültiger Ereignistyp, fehlender Kartengrund.
5. Duplikattest: zweite aktive Karte bzw. zweiter aktiver Stern für denselben Spieler/dasselbe Training wird abgewiesen; Karte plus Stern ist zulässig.
6. Atomarität: Ereignis und Audit entstehen gemeinsam; bei Fehler bleibt kein Teilzustand zurück.

### Ausführungsstatus

Noch nicht ausgeführt. Dieses Dokument wird nach Freigabe und DEV-Ausführung um Ergebnis, Prüfergebnisse, ggf. Korrekturen und Commitreferenz ergänzt.


## DEV-Ausführung und Testergebnis

- **Ausgeführt am:** 08.11.2026
- **Ziel:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`
- **Freigabe:** ausdrücklich durch den Nutzer erteilt
- **Ergebnis:** Funktion erfolgreich angelegt/ersetzt; SQL-Ausführung ohne Fehler.

### Technische Nachkontrollen

| Prüfung | Ergebnis |
|---|---|
| Funktionssignatur `award_training_behavior_event(uuid,uuid,text,text)` vorhanden | Bestanden |
| SECURITY DEFINER | Bestanden |
| EXECUTE für `authenticated` | Erlaubt |
| EXECUTE für `anon` | Nicht erlaubt |
| EXECUTE für `service_role` | Nicht erlaubt |
| Positivtest mit bestehendem Trainer, aktivem Spieler, bestätigter Anwesenheit und aktiver Saison | Bestanden |
| Ereignis und Audit-Eintrag gemeinsam erzeugt | Bestanden – jeweils eine Zeile innerhalb der Testtransaktion |
| Testdaten nach ROLLBACK dauerhaft gespeichert | Nein – 0 Testereignisse verblieben |
| Negativtest: gelbe Karte ohne Begründung | Abgewiesen (SQLSTATE 22023) |

### Testverfahren

Der Positivtest wurde innerhalb einer expliziten Transaktion mit simuliertem authentifiziertem Trainerkontext ausgeführt. Ereignis und Audit-Eintrag waren innerhalb der Transaktion vorhanden; anschließend wurde die Transaktion zurückgerollt. Eine separate Nachkontrolle bestätigte, dass kein Testereignis dauerhaft gespeichert blieb.

Der Negativtest für einen fehlenden Kartengrund wurde ebenfalls transaktional ausgeführt und erwartungsgemäß abgewiesen.

### Grenzen des aktuellen Tests

Noch nicht praktisch getestet wurden alle weiteren Negativfälle (falsches Team, fehlende Rolle, inaktiver Spieler, fehlende Anwesenheit, abgesagtes Training, fehlende/mehrdeutige aktive Saison) sowie konkurrierende parallele Vergaben. Diese Fälle werden in der weiteren DEV-Testphase bzw. mit den Folgepaketen geprüft.

### Ergebnis

**Paket 2 ist in DEV ausgeführt. Funktionssignatur, SECURITY-DEFINER-Eigenschaft, EXECUTE-Rechte, Positivpfad, atomarer Audit-Eintrag und Ablehnung eines fehlenden Kartengrunds wurden geprüft.** Keine Änderungen an PROD.


## Ergänzende DEV-Negativtests (nachträglich)

- **Ausgeführt:** 08.11.2026
- **Methode:** Testtransaktion mit anschließendem ROLLBACK; keine Testdaten dauerhaft gespeichert.
- **Ergebnisse:**

| Negativ-/Grenzfall | Ergebnis |
|---|---|
| Aufruf ohne Teamrolle | Abgewiesen (42501) |
| Spieler nicht im Trainingsteam / unbekannte Spieler-ID | Abgewiesen (P0002) |
| Spieler nicht anwesend | Abgewiesen (23514) |
| Inaktiver Spieler | Abgewiesen (23514) |
| Abgesagtes Training | Abgewiesen (23514) |
| Training ohne eindeutig aktive Saison | Abgewiesen (23514) |
| Gelbe Karte ohne Begründung | Abgewiesen (22023; bereits im ersten Paket-2-Test) |
| Zweite aktive Karte im selben Training | Abgewiesen (Unique-Verletzung) |
| Zweiter aktiver Stern im selben Training | Abgewiesen (Unique-Verletzung) |
| Karte und Stern im selben Training | Zulässig |

Nachkontrolle: 0 verbliebene Paket-2-Testereignisse und 0 zugehörige Audit-Einträge. Spielerstatus und Saisonstatus waren unverändert aktiv.

**Hinweis:** Der Fall „Akteur besitzt ausschließlich eine Rolle in einem anderen Team“ wurde nicht separat mit einem zweiten Teammitglied-Datensatz getestet; die serverseitige Prüfung verlangt explizit eine Rolle für die konkrete `team_id`.


## Ergänzende Negativtests in DEV

- **Nachgetestet am:** 08.11.2026
- **Umgebung:** Supabase DEV
- **Verfahren:** Alle Schreibtests in einer Transaktion; abschließendes ROLLBACK. Testdaten wurden nicht dauerhaft gespeichert.

| Testfall | Erwartetes Verhalten | Ergebnis |
|---|---|---|
| Nicht authentifizierter Aufruf | Ablehnung, SQLSTATE 42501 | Bestanden |
| Benutzer ohne Rolle im Zielteam | Ablehnung, SQLSTATE 42501 | Bestanden |
| Spieler ohne bestätigte Anwesenheit | Ablehnung, SQLSTATE 23514 | Bestanden |
| Abgesagtes Training | Ablehnung, SQLSTATE 23514 | Bestanden |
| Gelbe Karte ohne Grund | Ablehnung, SQLSTATE 22023 | Bestanden |
| Ungültiger Ereignistyp | Ablehnung, SQLSTATE 22023 | Bestanden |
| Zweite aktive Karte im selben Training | Unique-Index lehnt ab | Bestanden |
| Zweiter aktiver Stern im selben Training | Unique-Index lehnt ab | Bestanden |
| Karte und Stern im selben Training | Beide dürfen nebeneinander bestehen | Bestanden |

**Nicht separat testbar mit den vorhandenen DEV-Testdaten:** Es gab keinen inaktiven Spieler im betreffenden Team und keinen zweiten bzw. fehlenden aktiven Saison-Datensatz, mit dem die entsprechenden Zweige ohne Änderung der bestehenden Stammdaten hätten ausgelöst werden können. Diese Fälle bleiben als offene Testfälle dokumentiert.

**Ergebnis Paket 2:** Alle mit vorhandenen Testdaten ausführbaren Negativ- und Grenztests bestanden. Sämtliche Schreibtests wurden zurückgerollt; keine Testereignisse verblieben in DEV.
