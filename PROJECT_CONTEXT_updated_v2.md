# Kaderkompass -- Projektkontext

**Dokumenttyp:** Zentrale Projektdokumentation / Übergabekontext\
**Stand:** 03.10.2026\
**Status:** Arbeitsdokument -- vor dem Einchecken in GitHub mit dem
aktuellen DEV-Stand abgleichen

> Zweck: Dieses Dokument hält Architektur, bestätigten Projektstand,
> offene Prüfungen, Sicherheitsbefunde und Backlog-Kontext fest. Es soll
> als verlässliche Ausgangsbasis für weitere Arbeit und neue
> Chat-Unterhaltungen dienen. Unbestätigte oder noch nicht vollständig
> geprüfte Punkte sind ausdrücklich als offen gekennzeichnet.

------------------------------------------------------------------------

## 1. Projektüberblick

**Projektname:** Jugendmannschaft\
**Produktname:** Kaderkompass\
**Untertitel:** Orientierung für die Kaderplanung

Der Kaderkompass ist eine mobile, insbesondere für iPhones optimierte
Web-App zur Organisation einer Jugendfußballmannschaft. Sie unterstützt
Trainer bei der Verwaltung von Spielern, Trainings, Anwesenheiten,
Spieltagen und der Kaderplanung.

Der Nutzer ist Trainer einer Jugendmannschaft in Deutschland. Ein großer
Spielerkader macht die Auswahl für Spieltage anspruchsvoll. Die App soll
die Planung nachvollziehbarer machen und historische Daten sinnvoll
berücksichtigen.

## 2. Architektur und Entwicklungsumgebung

  -----------------------------------------------------------------------
  Bereich                             Bekannter Stand
  ----------------------------------- -----------------------------------
  Frontend                            Einzelne `index.html` mit HTML, CSS
                                      und JavaScript; Single-Page-App

  Backend                             Supabase (Datenbank und
                                      Authentifizierung)

  Hosting                             GitHub Pages

  Versionsverwaltung                  GitHub; Branches `main` und
                                      `develop` wurden verwendet

  Umgebungen                          Getrennte DEV-/Staging- und
                                      PROD-Umgebung
                                      vorgesehen/eingerichtet

  Mobile Nutzung                      Mobile-first, insbesondere iPhone

  Datenübernahme                      JSON-Export/Backup und
                                      Import/Restore vorhanden
  -----------------------------------------------------------------------

**Arbeitsregel:** Änderungen zuerst in DEV entwickeln und testen. PROD
wird erst nach Prüfung und ausdrücklicher Freigabe aktualisiert. Keine
ungeprüften SQL- oder Frontend-Änderungen direkt in PROD vornehmen.

**Noch abzugleichen:** Die konkreten Repository-URLs, GitHub-Pages-URLs,
Supabase-Projektkennungen, Branch-Zuordnung und aktuellen
Deploy-Workflows sollten bei der finalen Ablage aus der aktuellen
GitHub-/Supabase-Konfiguration ergänzt werden. Zugangsdaten, Tokens,
Passwörter und Service-Role-Keys gehören nicht in diese Datei.

## 3. Funktionsumfang

### 3.1 Spieler

-   Spielerliste mit Name, Foto, Positionen und Level
-   Zuordnung von Spielern zu Positionen
-   Spielerstammdaten in DEV umfassen Geburtsjahr (kein vollständiges
    Geburtsdatum) und bevorzugten Fuß (links/rechts/beidfüßig); die
    zugehörigen Constraints sind im DEV-Schemaüberblick dokumentiert.
    Vereinsvergangenheit bleibt als Erweiterungsidee gesondert zu prüfen.
-   Level-Skala im aktuellen Datenmodell: `Einsteiger`,
    `Fortgeschritten`, `Stark`, `Profi`
-   Historische UI-Bezeichnungen wie „schwach", „mittel", „stark" und
    „herausragend" wurden im Projektkontext erwähnt; die genaue
    Zuordnung im aktuellen Frontend ist vor weiteren Änderungen gegen
    den tatsächlichen Code zu prüfen.

### 3.2 Training und Anwesenheit

-   Trainings anlegen und anzeigen
-   Anwesenheit von Spielern je Training dokumentieren
-   Trainingshistorie als Grundlage für die Kaderempfehlung
-   Trainer können als Trainingsteilnehmer dokumentiert werden
-   Gewünschte UX: Anwesenheit bearbeiten, ohne dass die Ansicht
    unerwartet auf ein anderes/neueres Training springt; „Alle
    auswählen" und „Alle abwählen"; kompakte, vertikale Darstellung ohne
    horizontales Scrollen

### 3.3 Spieltage und Kaderplanung

-   Spieltage anlegen und verwalten
-   Kaderempfehlung anhand von Trainingsanwesenheit und historischen
    Daten
-   Frühere Spieltagsauswahlen sollen bei der Empfehlung berücksichtigt
    werden, damit Einsätze möglichst ausgewogen verteilt werden
-   Kaderanzeige, bisher unter anderem als „Top 16" beschrieben;
    Kadergröße soll perspektivisch administrativ flexibel sein
-   Teambildung mit Berücksichtigung von Positionen und Spielstärken;
    bisher wurde unter anderem die Einteilung in Teams mit vier
    Feldspielern plus Torwart betrachtet
-   Weitere geplante Möglichkeiten: Spieltagsarten, Anstoßzeit,
    Formationsvorlagen und Dokumentation verfügbarer, aber nicht
    eingesetzter Spieler

### 3.4 Trainer, Konten und Administration

-   Trainer-/Adminrollen und Teammitgliedschaften
-   Trainerverwaltung und Einladungsablauf
-   Konto- und Passwortverwaltung
-   JSON-Backup, Export und Wiederherstellung
-   Admin-Bereich für administrative Aufgaben

**Bekannter Einladungsstatus:** Die Trainer-Einladung funktionierte
grundsätzlich und die Einladungs-E-Mail konnte versendet werden. Weitere
Tests waren durch Supabase-Fehler `Email rate limit exceeded`
eingeschränkt. Eine gesonderte Testdatei für das Passwort-Setup
eingeladener Trainer wurde zuvor erstellt; ihr aktueller Integrations-
und Teststatus ist zu verifizieren.

## 4. Datenbank -- dokumentierter Bestand

Folgende Tabellen wurden im Projekt untersucht bzw. benannt:

-   `attendance`
-   `matchday_players`
-   `matchday_trainers`
-   `matchdays`
-   `player_positions`
-   `players`
-   `positions`
-   `profiles`
-   `seasons`
-   `team_members`
-   `teams`
-   `training_players`
-   `training_trainers`
-   `trainings`

### 4.1 Wichtige Constraints und Beziehungen

-   `attendance`: zusammengesetzter Schlüssel aus Training und Spieler;
    Fremdschlüssel mit Cascade-Verhalten
-   `matchday_players`: zusammengesetzter Schlüssel aus Spieltag und
    Spieler; `team_number` ist nullable oder im Bereich 1--4
-   `matchday_trainers`: zusammengesetzter Schlüssel aus Spieltag und
    Nutzer
-   `matchdays`: Teambezug; Saisonbezug kann bei Löschung der Saison auf
    `NULL` gesetzt werden
-   `player_positions`: Zuordnungstabelle mit zusammengesetztem
    Schlüssel aus Spieler und Position
-   `players`: Teambezug; Constraints für Geburtsjahr, Level und
    bevorzugten Fuß
-   `positions`: Teambezug und eindeutiger Positionsname je Team
-   `profiles`: Profil-ID ist an `auth.users` gebunden
-   `seasons`: Teambezug und eindeutiger Saisonname je Team
-   `team_members`: zusammengesetzter Schlüssel aus Team und Nutzer;
    Rollen `admin` oder `trainer`
-   `teams`: zentrale Teamtabelle
-   `training_players`: zusammengesetzter Schlüssel aus Training und
    Spieler; `team_number` mindestens 1, sofern gesetzt
-   `training_trainers`: Zuordnung von Trainern zu Trainings
-   `trainings`: Teambezug; Saisonbezug kann bei Löschung der Saison auf
    `NULL` gesetzt werden

Die Datenbank wurde mit aktivierter RLS auf den genannten Tabellen
beschrieben. RLS war nicht als `FORCE ROW LEVEL SECURITY` gesetzt. Das
allein ist kein Beweis für eine Sicherheitslücke; Eigentümer-,
Funktions- und Bypass-Rechte müssen im jeweiligen Kontext betrachtet
werden.

**Hinweis:** Diese Übersicht ist ein komprimierter Bestandsauszug, kein
Ersatz für einen aktuellen Schema-Dump oder versionierte
SQL-Migrationsdateien.

### 4.2 DEV-Änderungsnachweis – E16.2 Schutz des letzten Administrators

**Umgebung:** ausschließlich Supabase DEV  
**Status:** implementiert und funktional im DEV getestet; nicht nach PROD übertragen  
**Betroffene Tabelle:** `public.team_members`  
**Neue Funktion:** `public.prevent_last_team_admin_removal()`  
**Neuer Trigger:** `prevent_last_team_admin_removal`

Die Funktion wird als `SECURITY DEFINER` mit festgelegtem Suchpfad
(`pg_catalog, public`) ausgeführt. Der Constraint-Trigger ist ein
`AFTER DELETE OR UPDATE`-Trigger auf `public.team_members`,
`DEFERRABLE INITIALLY DEFERRED` und wird je betroffener Zeile ausgeführt.
Die Funktion prüft Änderungen an Admin-Mitgliedschaften und verhindert,
dass die letzte Admin-Mitgliedschaft eines bestehenden Teams entfernt
oder herabgestuft wird. Bei vollständiger Löschung des Teams wird die
Entfernung der Mitgliedschaften nicht durch diesen Schutz blockiert.
EXECUTE-Rechte wurden für `PUBLIC`, `anon` und `authenticated` entzogen;
der Trigger ruft die Funktion intern auf.

**Verifikation und Testnachweis:**
- Triggerabfrage bestätigte genau einen Trigger mit aktiviertem Status,
  verzögerter Ausführung und `SECURITY DEFINER`-Funktion.
- SQL-Testtransaktionen für Admin-Entfernung/-Herabstufung wurden
  ausgeführt und zurückgerollt; der Adminbestand blieb erhalten.
- Echter Löschversuch des einzigen Admin-Kontos über die DEV-App wurde
  mit der Datenbankmeldung „Die letzte Admin-Mitgliedschaft einer
  Mannschaft kann nicht entfernt oder herabgestuft werden“ blockiert.
- Nachkontrolle bestätigte, dass die Mitgliedschaften den Löschversuch
  überstanden haben. Die Testrollen wurden anschließend auf den
  beabsichtigten Zustand zurückgesetzt: zwei Admins und ein Trainer.
- Kein Test der konkurrierenden, zeitgleichen Änderungen in getrennten
  Datenbanktransaktionen durchgeführt.

**Wichtige Rollout-Einschränkung:** Der vollständige, exakt ausgeführte
DDL-Text der Funktion und des Triggers ist in diesem Änderungsnachweis
nicht als ausführbare Migration hinterlegt. Vor einer PROD-Übernahme muss
der tatsächliche Funktions-/Trigger-DDL-Stand aus DEV exportiert bzw.
gegen die hier beschriebene Implementierung abgeglichen und als
versionierte SQL-Migration ergänzt werden. Diesen Abschnitt nicht als
SQL zum direkten Ausführen in PROD verwenden. Rollenänderungen an den
Testkonten waren Testdatenänderungen und sind keine Schema-Migration.

## 5. Berechtigungen und Sicherheitsbestand

### 5.1 RLS -- bekannte Beobachtungen

-   Teambezogene SELECT- und Schreibrechte werden häufig über
    `is_team_member(...)` bzw. Admin-Prüfungen gesteuert.
-   `players` besitzt permissive INSERT-/UPDATE-Richtlinien für
    Teammitglieder sowie zusätzliche Admin-Richtlinien. Da permissive
    Policies grundsätzlich per OR wirken, können Trainer dadurch
    ebenfalls Spieler einfügen oder ändern. Zu klären ist, ob das
    fachlich beabsichtigt ist.
-   `player_positions` wurde zuletzt als SELECT für Teammitglieder sowie
    INSERT/DELETE nur für Admins beschrieben; beim INSERT wird die
    Teamzugehörigkeit von Spieler und Position geprüft.
-   Bei UPDATE-Richtlinien für `attendance`, `matchday_players` und
    `training_players` wurde festgestellt, dass die
    `WITH CHECK`-Bedingung die Mitgliedschaft am zugehörigen Team prüft,
    aber die Teamkonsistenz der verknüpften Spieler-ID nicht in gleicher
    Weise erneut validiert wie die INSERT-Richtlinie. Das ist als
    gezielter Prüf- und Härtungspunkt zu behandeln.
-   `team_members`, `seasons` und `positions` haben Admin-beschränkte
    Schreiboperationen gemäß der zuletzt bereitgestellten
    Policy-Übersicht.
-   Profilzugriff ist eingeschränkt; Nutzer können das eigene Profil
    aktualisieren, während Admins im Teamkontext weitere Profile
    einsehen können.

### 5.2 Datenbankfunktionen

Im bisherigen Bestand wurden unter anderem folgende Funktionen
untersucht:

-   `add_team_member_by_email(...)`
-   `admin_set_trainer_label(...)`
-   `delete_my_account()`
-   `get_team_trainers(...)`
-   `handle_new_user()`
-   `is_team_admin(...)` (mehrere Überladungen)
-   `is_team_member(...)` (mehrere Überladungen)
-   `set_updated_at()`

Einige Funktionen sind `SECURITY DEFINER`; ihre Ausführung und internen
Prüfungen sind daher sicherheitsrelevant. Bei der bisherigen Prüfung
wurden `PUBLIC`- und `anon`-EXECUTE-Rechte auf Funktionen als möglicher
Härtungspunkt identifiziert. Erforderliche Aufrufe durch
authentifizierte Nutzer und Trigger-Abhängigkeiten müssen vor Änderungen
genau berücksichtigt werden.

Die zweiparametrige Hilfsfunktion `is_team_admin(p_user_id, p_team_id)`
wurde intern durch weitere Funktionen verwendet. Sie darf daher nicht
als ungenutzt behandelt werden, ohne die Abhängigkeiten vorher zu ändern
und zu prüfen. Auch die Verwendung der entsprechenden
`is_team_member`-Überladung ist vor einem Rechteentzug zu überprüfen.

### 5.3 Frontend-Sicherheitsgrenzen

-   `adminGuard()` prüft die lokal verfügbare Rolle im Frontend. Eine
    solche UI-Prüfung verbessert die Bedienung, ersetzt aber keine
    serverseitige Berechtigungsprüfung.
-   In der Trainerverwaltung gibt es Frontend-Prüfungen, die verhindern
    sollen, dass der letzte Admin über die Oberfläche entfernt oder
    herabgestuft wird. Diese Prüfung muss zusätzlich serverseitig
    abgesichert sein.
-   Die Funktion `delete_my_account()` löscht die Mitgliedschaft und das
    Konto des aufrufenden Nutzers. Im bisherigen Funktionsstand war kein
    Schutz vor dem Löschen des letzten Team-Admins erkennbar.
-   Der JSON-Restore führt Datenbankoperationen schrittweise aus. Es
    gibt eine Sicherheitskopie und einen Rollback-Versuch bei Fehlern,
    aber der gesamte Restore ist keine einzelne atomare Transaktion;
    auch ein Rollback kann scheitern.

### 5.4 Sicherheitsstatus

**Als offene Härtungspunkte festhalten:**

1.  Letzten Admin serverseitig vor Entfernung, Herabstufung und
    Kontolöschung schützen.
2.  UPDATE-RLS-Richtlinien für Zuordnungstabellen auf erneute Team- und
    Fremdschlüssel-Konsistenz prüfen und bei Bedarf korrigieren.
3.  Rollenmodell fachlich festlegen: Dürfen Trainer Spieler anlegen und
    bearbeiten?
4.  EXECUTE-Rechte für RPCs/Funktionen nach dem Prinzip der minimal
    erforderlichen Rechte prüfen; `PUBLIC`/`anon` nicht pauschal
    entziehen, sondern Abhängigkeiten berücksichtigen.
5.  `SECURITY DEFINER`-Funktionen, Suchpfade, Schemaqualifizierung und
    tatsächliche Aufrufwege überprüfen.
6.  Trigger auf `auth.users` für `handle_new_user()` gezielt
    verifizieren; die bisherige Triggerprüfung auf öffentlichen Tabellen
    genügt dafür nicht.
7.  JSON-Restore hinsichtlich Transaktionssicherheit und
    Wiederherstellbarkeit konzeptionell verbessern.
8.  Sicherheitsrelevante Änderungen in DEV mit positiven und negativen
    Berechtigungstests prüfen, bevor sie für PROD freigegeben werden.

**Wichtig:** Die oben genannten Punkte sind Prüf- bzw. Härtungsaufgaben,
keine pauschale Aussage, dass jede davon bereits eine ausnutzbare
Sicherheitslücke darstellt.

## 6. Produkt- und UX-Leitlinien

-   iPhone-taugliche, kompakte und responsive Oberfläche
-   Klare, konsistente Abstände, Icons und Badges
-   Lange Namen dürfen das Layout nicht sprengen
-   Spieler- und Trainerlisten möglichst ohne horizontales Scrollen
-   Spielerinformationen sollen bearbeitbar sein
-   Fotoauswahl soll Kamera und Fotomediathek unterstützen und Fotos
    entfernbar machen
-   Nächstes anstehendes Training bzw. nächster Spieltag soll visuell
    hervorgehoben werden
-   Historische Trainings- und Einsatzdaten sollen für Empfehlungen
    nutzbar sein
-   Empfehlungen sollen für Trainer leicht verständlich und
    nachvollziehbar erklärt werden

## 7. Spielformen nach Altersklasse

Als Produktanforderung wurde ein Epic „Spielform je Altersklasse"
aufgenommen. Im bisherigen Projektkontext wurden die seit 2024/25
geltenden Kinderfußball-Spielformen wie folgt zusammengefasst:

  Altersklasse            Im Projektkontext genannte Spielformen
  ----------------------- --------------------------------------------------
  G-Jugend (U6/U7)        2v2 oder 3v3, ohne Torwart
  F-Jugend (U8/U9)        3v3, 3+1 oder 5v5 in den beschriebenen Varianten
  E-Jugend (U10/U11)      5v5 oder 7v7
  D-Jugend (U12/U13)      9v9
  Ab C-Jugend (U14/U15)   11v11

Die App soll anhand der gewählten Spielform relevante Kaderparameter
ableiten können, etwa Feldspieler, Torhüter, Teamgröße, benötigte
Teamanzahl, mögliche Kadergröße und passende Formationsvarianten.

**Offen:** Konkrete Vorgaben und Umsetzungen des zuständigen
Fußballkreises bzw. FLVW für den jeweiligen Wettbewerb müssen vor einer
verbindlichen Regelabbildung geprüft werden. Die Tabelle ist eine
bisherige Projektzusammenfassung und keine aktuelle Verbandsfreigabe.

## 8. Backlog -- Themenübersicht

Der Backlog wird als laufende Produktdokumentation geführt.
Statusangaben einzelner Tickets müssen vor dem Einchecken mit der
zuletzt gepflegten Backlog-Liste abgeglichen werden.

### Bereits als umgesetzt bzw. weitgehend umgesetzt besprochene Themen

-   Level-Abgleich zwischen App und Datenbank
-   Saisonwechsel-Grundlagen bzw. Saisonbezug
-   Flexible Kadergröße (Status laut älterer Backlog-Angabe als
    umgesetzt genannt; aktuelle Implementierung gegen DEV prüfen)
-   Trainer-/Adminverwaltung und Einladung -- Einladung grundsätzlich
    funktionsfähig, Passwort-Setup weiter zu verifizieren
-   Anpassung des Datumsfelds bei Trainingserstellung
-   DEV-/PROD-Struktur und zugehöriger Deployment-Ablauf
-   weitere frühere Backlog-Punkte 1--11 wurden zeitweise als umgesetzt
    bezeichnet; genaue Ticket-zu-Status-Zuordnung vor Veröffentlichung
    prüfen

### Weitere bekannte Epics und Ideen

-   Saisonübergang zwischen Altersklassen und Mannschaften
-   Mehrere Teams und Trainerzuordnung zu mehreren Teams
-   Änderungshistorie für Spieler- und Stammdaten
-   Schutz vor paralleler Bearbeitung
-   Spielerprofil um Geburtsjahr, bevorzugten Fuß und
    Vereinsvergangenheit erweitern
-   Verfügbarkeit und Zu-/Absagen für Training und Spieltag
-   Soll-/Ist-Anwesenheit und optionaler Fehlgrund
-   Elternkonto und Eltern-Kind-Verknüpfung
-   verfügbare, aber nicht eingesetzte Spieler auf Spieltagen markieren
-   Trainer als Trainingsteilnehmer dokumentieren
-   Formationsvorlagen für die Teambildung
-   Spieltagsarten (Meisterschaft, Freundschaftsspiel, Turnier) und
    Anstoßzeit
-   nächstes Training / nächster Spieltag hervorheben
-   Trainingshistorie ab Vereinsbeitritt und saisonbezogene
    Einsatzstatistik
-   Trainingsserien und Notizen zu Trainings und Spieltagen
-   Dashboard auf Basis des aktuellen und zukünftigen Funktionsstands
-   Spielerentwicklung und Spielernotizen (zunächst zurückgestellt)
-   Spielerwechsel zwischen Vereinen bzw. Mannschaften
-   Icons, kompaktere UI und responsive Darstellung
-   Spielform je Altersklasse
-   Sicherheit und Rechteverwaltung härten

## 9. Arbeitsweise für weitere Epics

Für jedes Epic möglichst einheitlich festhalten:

1.  **Ziel und Problem:** Welchen konkreten Bedarf löst das Epic?
2.  **Nutzer und Ablauf:** Wer nutzt es und in welchem Prozess?
3.  **Fachliche Regeln:** Welche Entscheidungen, Grenzen und Sonderfälle
    gelten?
4.  **Datenmodell:** Welche Tabellen, Spalten, Beziehungen oder
    Migrationen sind betroffen?
5.  **UI/UX:** Welche Ansichten und Interaktionen ändern sich?
6.  **Berechtigungen:** Welche Rollen dürfen lesen, erstellen, ändern
    oder löschen?
7.  **Akzeptanzkriterien:** Woran erkennen wir, dass das Epic fertig
    ist?
8.  **Testfälle:** Normalfälle, Grenzfälle, Berechtigungen und
    Fehlerbehandlung
9.  **Rollout:** DEV-Test, Freigabe und erst danach PROD

Vor jeder Änderung: - aktuelle DEV-Datei und relevante Datenbankstruktur
identifizieren - betroffene Funktionen und Policies ermitteln - Änderung
klein und nachvollziehbar halten - Tests und erwartetes Ergebnis
dokumentieren - keine PROD-Übernahme ohne ausdrückliche Freigabe

## 10. Offene Dokumentations- und Abgleichaufgaben

-   [ ] Aktuelle DEV-`index.html` eindeutig benennen und
    Versionsstand/Commit erfassen.
-   [ ] Aktuelle DEV-Datenbankstruktur und Policies mit diesem Überblick
    abgleichen.
-   [ ] GitHub-Repository, Branches, Pages-URLs und Deploy-Workflows
    ergänzen (keine Geheimnisse dokumentieren).
-   [ ] Backlog-Status der einzelnen Epics anhand der zuletzt gepflegten
    Liste aktualisieren.
-   [ ] Sicherheitsbefunde als „bestätigt", „Verdacht/Prüfpunkt" oder
    „erledigt" markieren.
-   [ ] Dokumentation in `develop` ablegen und Änderungen dort reviewen.
-   [ ] Nach erfolgreichem Abgleich einen kurzen Versionshinweis
    ergänzen.

## 11. Übergabehinweis für neue Chats

Bei Fortsetzung des Projekts zuerst diese Datei und die aktuelle
DEV-`index.html` als maßgebliche Ausgangsbasis verwenden. Anschließend
gezielt klären, welches Epic bearbeitet wird und ob aktuelle
SQL-/Frontend-Dateien oder Ergebnisse neuer Tests vorliegen.

Nicht ungeprüft annehmen, dass frühere Dateien, temporäre Links oder
ältere Codeausschnitte dem aktuellen DEV-Stand entsprechen. Bei
Widersprüchen gilt der aktuell verifizierte DEV-Code und die aktuelle
DEV-Datenbank; Unterschiede zur Dokumentation werden hier nachgeführt.

------------------------------------------------------------------------

**Pflegehinweis:** Nach jeder größeren Änderung an Architektur,
Datenmodell, Sicherheitsmodell, Deployment oder Backlog-Status diese
Datei aktualisieren.

## 8. Vollständiger Epic-Backlog

**Dokumentierter Stand:** 3. Oktober 2026 · 16 Epics. Die Detailanforderungen stammen aus der vom Nutzer bereitgestellten Backlog-Beschreibung. Wo der Einzelstatus nicht eindeutig ausgewiesen wurde, bleibt er offen und wird nicht erschlossen.

| ID | Epic | Status | Priorität |
|---|---|---|---|
| E01 | Entwicklungsumgebung & Release-Prozess | Erledigt | – |
| E02 | Trainerverwaltung & Zusammenarbeit | Nicht einzeln ausgewiesen | Normal |
| E03 | Spielerprofil & Spielerstammdaten | Erledigt in DEV; PROD separat | – |
| E04 | Saison-, Vereins- & Mannschaftsverwaltung | Umsetzungsbereit | Normal |
| E05 | Kaderplanung & Spieltagsauswahl | Umsetzungsbereit | Normal |
| E06 | Teambildung & Aufstellungen | Umsetzungsbereit | Normal |
| E07 | Training erweitern | Umsetzungsbereit | Normal |
| E08 | Spieltag erweitern | Offen / in Ausarbeitung* | Normal |
| E09 | Übersicht & Orientierung | Idee* | Normal |
| E10 | UI & Design-System | Idee* | Normal |
| E11 | Termin- & Verfügbarkeitsmanagement | Idee* | Normal |
| E12 | Elternkonto & Eltern-Kind-Verknüpfung | Idee* | Normal |
| E13 | Icon-Bibliothek & Positionsverwaltung | Idee* | Normal |
| E14 | Übergreifendes Navigationskonzept | Idee* | Normal |
| E15 | Hilfebereich & FAQ | Idee* | Normal |
| E16 | Sicherheit & Rechteverwaltung härten | Teilweise umgesetzt; E16.2 in DEV funktional getestet, weitere Teilaufgaben offen | Hoch |

*Die Gesamtübersicht nennt 2 erledigte, 4 umsetzungsbereite, 3 offene/in Ausarbeitung befindliche und 7 Ideen. Die Einzelzuordnung ist nicht für alle Epics explizit; vor GitHub-Veröffentlichung anhand der gepflegten Backlog-Ansicht abgleichen. E01 ist erledigt, E03 in DEV getestet, E04–E07 sind umsetzungsbereit. E16.2 (Schutz des letzten Administrators) ist in DEV funktional getestet; weitere E16-Aufgaben und die PROD-Übernahme sind offen.

### E01 – Entwicklungsumgebung & Release-Prozess
**Status: Erledigt.** Getrennte App- und Supabase-Umgebungen für DEV und PROD. GitHub-Repository `jugendmannschaft` mit `main` als PROD und `develop` als DEV sowie eigenständiges `jugendmannschaft-dev` mit eigener Pages-Bereitstellung. Neue Funktionen zuerst in DEV umsetzen, testen und Fehler beheben; Release-Notizen nur für tatsächlich umgesetzte und getestete Änderungen; erst nach ausdrücklicher Freigabe nach PROD übernehmen. Keine ungetestete automatische Übernahme, keine Vermischung von DEV-/PROD-Daten und keine Veröffentlichung ohne bewusste Freigabe. Datumsfeldanpassung ebenfalls als erledigt dokumentiert.

### E02 – Trainerverwaltung & Zusammenarbeit
**Priorität: Normal.** Mehrere Trainer sollen eine oder mehrere Mannschaften verwalten können. Eigene Konten und Rollen (Trainer/Admin); Admins laden per E-Mail ein und verwalten Trainer; Trainer können Anzeigenamen ändern sowie Spieler ihrer Mannschaft anlegen/bearbeiten und sehen grundsätzlich nur zugewiesene Mannschaften. Trainer können als Trainingsteilnehmer über Benutzer-ID erfasst werden, nicht als Spieler und nicht in Kaderempfehlung/Teambildung; Namensänderungen dürfen Historie nicht verändern; Admins sind nicht automatisch Trainingsteilnehmer. Einladung über E-Mail-Link mit Passwort-Setup über Bestätigungslink; Teamzuweisungsfehler verständlich behandeln und Teilausfälle nachvollziehbar auffangen. Später: feinere Rollen, Änderungshistorie/Audit-Logs, mehrere Mannschaftszuweisungen, Schutz vor paralleler Bearbeitung. V1 ohne detaillierte Trainerstatistiken, komplexe Trainer-Abwesenheitsplanung oder unnötig komplexe Rollenstruktur. **Abhängigkeiten:** E04, E07, E16.

### E03 – Spielerprofil & Spielerstammdaten
**Status: Erledigt in DEV; DEV-Testcheckliste vollständig, keine automatische PROD-Freigabe.** Datensparsame Profile mit Vor-/Nachname, Foto, Geburtsjahr (kein vollständiges Geburtsdatum), starkem Fuß (links/rechts/beidfüßig), Positionen und qualitativer Stärke: Einsteiger, Fortgeschritten, Stark, Profi; Darstellung mit farbigen Sternen und Text, nicht numerisch/FIFA-basiert. Spieler sind unabhängig von Verein/Mannschaft angelegt und über Mitgliedschaften mit Mannschaft und Saison verbunden; mehrere Teams im selben Verein möglich; Historie bleibt bei Wechseln erhalten. Geburtsjahr leitet keine Mannschaftszugehörigkeit automatisch ab; Positionen sind Fähigkeit/Präferenz, nicht zwingend tatsächliche Spieltagsposition. Spielerkarte enthält persönliche/sportliche Infos, aktuelle Zugehörigkeit und abgeleitete Statistiken: Trainingsbeteiligung, Spieltagsteilnahmen, Nominierungen, tatsächliche Einsätze, Torwarteinsätze. Statistiken nicht manuell editierbar; Quoten innerhalb Mannschafts-/Mitgliedschaftsperiode berücksichtigen. UI: kompakte vertikale Liste, umbrechende Positionschips, Nominierungsmarkierung (grüne Umrandung/Trikotsymbol), Beteiligungsring, Empfehlungen zuerst und vollständige Reserveliste in Empfehlungsreihenfolge, Sortierung (Empfehlung/Nachname/Vorname/Beteiligung), kombinierbare Suche/Positionsfilter, iPhone Portrait/Landscape. Keine vollständigen Geburtsdaten, numerische Bewertung, detaillierte Entwicklung oder umfassende Positionshistorie in V1.

### E04 – Saison-, Vereins- & Mannschaftsverwaltung
**Priorität: Normal · Umsetzungsbereit.** Modell: Verein als Organisation, Mannschaft als Trainings-/Spielgruppe, Saison als Zeitraum, Spieler als eigenständiger Datensatz, Mitgliedschaft als Spieler-Mannschaft-Saison-Verknüpfung. Mehrere Mannschaften pro Spieler innerhalb eines Vereins; Trainerzuweisung kann Mannschaft/Saison berücksichtigen; Spieler separat oder direkt bei Anlage zuordnen; Eintrittsdatum dokumentieren. Saisonwechsel als kontrollierte Übergabe: bisheriger Trainer schlägt Spieler vor, neuer Trainer bestätigt aktiv; nicht bestätigte bleiben historisch erhalten, aber ohne aktive Mannschaft; keine automatische Zuordnung nach Geburtsjahr. Vereinswechsel: Freigabe und Bestätigung durch aufnehmenden Trainer; Wechsel innerhalb desselben Vereins kann Mehrfachzugehörigkeit erlauben; bei bestätigtem Vereinswechsel endet alte Zugehörigkeit und neue beginnt, Historie/Statistiken bleiben. Statistiken sind saison- und mannschaftsbezogen und durch Eintrittsdatum begrenzt. Kein öffentliches Spielerregister, Transfermarktplatz, automatische Mannschaftsoptimierung oder komplexe Berechtigungsverwaltung für Saisonwechsel in V1. **Abhängigkeiten:** E02, E03, E05, E16.

### E05 – Kaderplanung & Spieltagsauswahl
**Priorität: Normal · Umsetzungsbereit.** Leitprinzip: App empfiehlt, Trainer entscheidet. Kadergröße durch Trainer, Mannschaftsstandard mit Spieltagsabweichung, keine starre 16er-Grenze. Verfügbarkeit: „Nimmt teil“, „Nimmt nicht teil“, „Nicht verfügbar“; neue Spieltage starten standardmäßig nicht verfügbar; „Alle verfügbar/nicht verfügbar“; verfügbar bedeutet nicht automatisch nominiert. Nur verfügbare Spieler fließen in Empfehlung ein. Trainingsbeteiligung ist zentrales Fairnesskriterium; zusätzlich frühere Nominierungen, tatsächliche Einsätze, Aktualität/zeitliche Nähe und Zufall bei Gleichstand. Eine spätere Erläuterung nennt bei gleicher Trainingsbeteiligung jüngere Trainingshistorie, danach weniger bisherige Nominierungen, dann Zufall. **Offen:** die exakte Reihenfolge und Gewichtung, insbesondere Verhältnis Nominierungen zu tatsächlichen Einsätzen, vor Implementierung vereinheitlichen. Relevante Quoten innerhalb der Mitgliedschaftsperiode verwenden. Nach Auswahl tatsächliche Einsätze markierbar, „Alle eingesetzt“, einzelne Abwahl und separate Torwarteinsätze; Statistiken unterscheiden Spieltage, Nominierungen, tatsächliche Einsätze und Torwarteinsätze. Keine endgültige automatische Entscheidung, Spielminuten/Auswechslungen, Gleichsetzung von Verfügbarkeit und Anwesenheit oder starre Kadergröße. **Abhängigkeiten:** E03, E04, E06, E11.

### E06 – Teambildung & Aufstellungen
**Priorität: Normal · Umsetzungsbereit.** Altersgerecht: G/F ohne klassische Formationen und Fokus auf ausgeglichene Teams; E/D vereinfachte Positionsmöglichkeiten; C–A klassische Formationslogik. Spielformen als bisherige Orientierung: G 2v2/3v3 ohne Torwart; F 3v3, 3+1 oder 5v5 mit zulässigen Torvarianten; E 5v5/7v7; D 9v9; C–A grundsätzlich 11v11. Vor verbindlicher Umsetzung aktuelle DFB-/FLVW- und Kreisregeln prüfen. Automatische Balance über Anzahl der Spieler je qualitativer Stärkestufe (Profi, Stark, Fortgeschritten, Einsteiger), keine numerischen 1–4-Punkte. Torwartqualifikation berücksichtigen; bei ausreichender Zahl möglichst ein Torwart je Team; Torwarte können Feldspieler sein; bei Mangel entscheidet Trainer. Jüngere Altersklassen primär nach Stärke/Ausgewogenheit, Positionen kein Hauptkriterium außer Torwart. Formationen passend zur Spielform anbieten (Beispiel 7v7: 2-2-2 plus Torwart). Trainer kann Spieler/Positionen/Teams/Formationen manuell ändern; danach keine automatische Neuoptimierung; Aufstellung als Spieltags-Momentaufnahme speichern. Kein taktischer Optimierer, keine „beste“ Formation, Chemie-/Synergiewertung, numerische Bewertung, Spielminuten/Auswechslungen oder automatische Strategie. **Abhängigkeiten:** E03, E05, E08, Spielform je Altersklasse.

### E07 – Training erweitern
**Priorität: Normal · Umsetzungsbereit.** Trainingsserien mit Start-/Enddatum, Uhrzeit und einem oder mehreren Wochentagen erzeugen einzelne, eigenständig bearbeitbare Termine. V1 einfach halten: Bei Rhythmusänderung alte Serie beenden und neue anlegen; keine komplexe Wahl für einzelnen/alle künftigen/alle Serientermine. Training enthält Datum, Uhrzeit, Ort (Freitext), Status, Notiz, Teilnehmer/Anwesenheit, Trainerzuordnung und optional Serienbezug. Serie kann Standardort setzen, Einzeltermin abweichen. Status: Geplant, Durchgeführt, Abgesagt; abgesagte Termine zählen nicht zur Trainingsbeteiligung. Freitextnotiz je Termin; strukturierte Pläne/Vorlagen später. Tatsächliche Anwesenheit bleibt von geplanter Verfügbarkeit getrennt; Trainerteilnahme gemäß E02. Keine komplexe Serienverwaltung, umfangreiche Planbibliothek, Karte/Navigation oder automatische Trainerstatistik in V1. **Abhängigkeiten:** E02, E03, E11, E15.

### E08 – Spieltag erweitern
**Priorität: Normal.** Spielart: Meisterschaft, Freundschaftsspiel, Turnier. Angaben: Datum, Anstoßzeit, Spielort als Freitext und Notiz. Ergebnis zunächst in Notiz; separate Ergebnisfunktion später denkbar. Verknüpfung zu Kader/Verfügbarkeit (E05), Aufstellungen (E06), Zu-/Absagen (E11), Elternmeldungen (E12) sowie Orts-/Notizlogik aus E07. V1 ohne Liga-/Tabellenverwaltung, umfangreiche Ergebnisstatistik, komplexe Turnierverwaltung oder Karten-/Navigation. Offen: genaue Übersicht, Pflichtfelder, mehrere Spiele eines Turniers und spätere Ergebnisauswertung.

### E09 – Übersicht & Orientierung
**Priorität: Normal.** Zentrales Dashboard mit echtem Nutzen statt bloßer Listenaggregation. Bisher zwei Ansätze: Dashboard aus bestehenden Funktionen und zukünftiges Dashboard mit Backlog-Funktionen. Nächstes Training und nächster Spieltag visuell hervorheben; vergangene und künftige Termine unterscheiden. Kompakt, smartphonefreundlich, klare Hierarchie und E10-konform. Später Benachrichtigungen, Erinnerungen, weitere Kennzahlen und rollenbezogene Übersichten. Erste Ausbaustufe ohne Erinnerungen/Benachrichtigungen, Überladung oder unnötige Doppelungen. **Abhängigkeiten:** E07, E08, E10, E11, E14.

### E10 – UI & Design-System
**Priorität: Normal.** E10.1-Leitlinien sind abgestimmt: Smartphone-first (iPhone als zentrales Testgerät, aber auch Tablet/Desktop); klare Informationshierarchie; kompakt und touchfreundlich mit ausreichenden Touchzielen und Ellipsen für lange Texte; wiederverwendbare, konsistente Buttons, Karten, Badges, Listen, Felder, Statusanzeigen und Icons; sportartneutrales Grunddesign, Fußballgrün nicht als Markenbasis, Farben gezielt und dezent; Barrierefreiheit mit ausreichendem Kontrast, Farbe nicht als einzigem Merkmal, Light-/Dark-Mode von Anfang an; einheitliche Begriffe, Navigation/Zurück-Logik, Aktionsplatzierung, Status-/Stärke-/Rollendarstellung und Datums-/Uhrzeit-/Zahlenformate. Noch offen: genaue Farben, Schriften, Maße, Icon-Auswahl, Komponentenvarianten, Animationen und vollständige Screens. E10.1 setzt Leitlinien, konkrete Screens werden schrittweise festgelegt. **Abhängigkeiten:** E13, E14, alle funktionalen Epics.

### E11 – Termin- & Verfügbarkeitsmanagement
**Priorität: Normal.** Geplante Zu-/Absagen für Training und Spieltag durch Spieler bzw. perspektivisch Eltern; unbeantwortete Anfrage als eigener Status; Absagegrund optional später. Grundzustände: Zugesagt, Abgesagt, Keine Rückmeldung. Soll-/Ist-Vergleich macht zugesagte, aber nicht erschienene Spieler erkennbar. E11 dokumentiert Planung, E05 nutzt Status zur Spieltagsplanung, E07/Spieltagsdokumentation erfasst tatsächliche Teilnahme/Einsatz. Zusage wird nie automatisch als Anwesenheit gewertet. V1 ohne verpflichtenden Grund oder umfangreiche Benachrichtigungsabläufe. Offen: Änderungsrechte, Vorlaufzeit, kurzfristige Anpassung und Benachrichtigungen. **Abhängigkeiten:** E05, E07, E08, E12.

### E12 – Elternkonto & Eltern-Kind-Verknüpfung
**Priorität: Normal.** Eltern erhalten eigenes Konto ohne Trainerzugang; Konto kann mit mehreren Kindern verbunden werden, Verknüpfung eindeutig und sicher. Eltern melden Verfügbarkeit für Training/Spieltage; Trainer sehen die Meldungen. Keine unnötigen internen Trainerrechte. Zusammenarbeit mit E03–E05, E07, E08 und E11. Offen: Verknüpfungs-/Bestätigungsprozess, Konten beider Elternteile, sichtbare Daten, mehrere Kinder in verschiedenen Teams, Benachrichtigungen. Keine umfassende Kommunikationsplattform, Chat oder endgültige Rollenstruktur bisher definiert.

### E13 – Icon-Bibliothek & Positionsverwaltung
**Priorität: Normal.** Zentrale Icon-Bibliothek auf Basis Google Material Symbols. Neue Icons werden bei Entwicklung registriert; Admins wählen ausschließlich vorhandene Icons, keine freie Eingabe von Icon-Namen. Bestehende Zuordnungen bleiben stabil. Admins können Positionen anlegen/bearbeiten und ein Icon zuweisen; Farben und Löschen wurden als weitere Wünsche genannt. Bibliothek funktionsübergreifend und visuell einheitlich. Keine eigenen Admin-Grafiken, freie Icon-Namenseingabe oder vollständiges Redesign im Epic. **Abhängigkeiten:** E10, E14.

### E14 – Übergreifendes Navigationskonzept
**Priorität: Normal.** Hauptbereiche bisher Spieler, Training, Spieltag, Einstellungen. Einheitliche Hauptnavigation mit sichtbarem aktivem Bereich und responsiver Nutzung. Detailansichten brauchen klares, vorhersehbares Zurück-Verhalten; nicht nur außerhalb einer Karte tippen oder eine einzelne Schließen-Aktion als Ausweg. Wenige Navigationsebenen, erweiterbar für neue Bereiche, Rollenrechte, konsistente Begriffe/Icons, smartphonefreundlich und E10-konform. Keine tiefen Menüstrukturen oder ausschließlich versteckte/gestenbasierte Aktionen. **Abhängigkeiten:** E10, E15, alle App-Bereiche.

### E15 – Hilfebereich & FAQ
**Priorität: Normal.** Integrierter, thematisch gegliederter FAQ-Bereich mit aufklappbaren Inhalten; Suche und kontextbezogene Hilfe später möglich. Themen: Kaderempfehlung/Reservefolge, Beteiligung/Statistiken, Spielerpflege/Positionen/Stärke, Suche/Filter/Sortierung, Teambildung/Aufstellungen, Saisonwechsel, Trainerverwaltung, Backup/Restore. Texte müssen dem realen App-Verhalten entsprechen, praxisnah sein und bei Änderungen aktualisiert werden; auch fachliche Gründe erläutern. Beispieltext zur Kaderempfehlung (Trainingsbeteiligung, jüngere Trainingshistorie, weniger Nominierungen, Zufall) ist mit E05 abzugleichen, insbesondere tatsächliche Einsätze. Kein Ticketsystem, Support-Chat, umfangreiche Videobibliothek oder große Infobox in der Spielerliste. **Abhängigkeit:** E14 und erklärte Funktionsepics.

### E16 – Sicherheit & Rechteverwaltung härten
**Priorität: Hoch · teilweise umgesetzt.** E16.2 „Schutz des letzten Administrators“ wurde in DEV implementiert und funktional getestet (siehe Abschnitt 4.2). Die übrigen Aufgaben sowie die gesonderte Prüfung paralleler Transaktionen bleiben offen. Serverseitige Sicherheit stärken, ungültige Admin-Konstellationen verhindern, Datenänderungen zuverlässig ausführen/rollbacken. Aufgaben:
1. EXECUTE-Rechte der zweiparametrigen `is_team_admin`-/`is_team_member`-Varianten prüfen; nur nötige Rollen zulassen, RLS und Funktionsrechte zusammen bewerten und direkte unberechtigte RPC-Aufrufe verhindern.
2. Letzten Admin serverseitig vor Entfernen, Herabstufen und Kontolöschung schützen; Frontend-Prüfung reicht nicht.
3. JSON-Restore in atomare Datenbanktransaktion überführen; keine Teilwiederherstellung bei Fehlern, Beziehungen berücksichtigen, Adminnutzung erhalten.
4. Einladungsfehler, insbesondere Teamzuweisung und Teilausfälle, nachvollziehbar behandeln; inkonsistente Konten vermeiden.
5. Klären und serverseitig umsetzen, ob Trainer Spielerpositionen zuweisen/entfernen dürfen.
6. Nutzersuche auch über 1.000 Konten zuverlässig und vollständig gestalten.
7. DEV-Sicherheits- und Regressionstests für RLS, Rollen, direkte Funktionsaufrufe, Einladungen/Teamzuweisungen, Rollenänderung, Nutzerentfernung/-löschung, letzten Admin, JSON-Backup/Restore und bestehende Admin-/Trainerfunktionen durchführen.

**Akzeptanz:** Teamdaten nur für Berechtigte; keine unberechtigten Adminaktionen; Team bleibt nicht versehentlich ohne Admin; fehlgeschlagener Restore hinterlässt keinen Teilbestand; Einladungsfehler sind behandelbar; bestehende Funktionen bleiben erhalten; Änderungen sind vor PROD in DEV erfolgreich getestet.

Sicherheitsaufgaben haben Vorrang vor der nächsten betroffenen PROD-Veröffentlichung. Featurearbeit darf parallel in DEV stattfinden; Sicherheitsänderungen kontrolliert und möglichst getrennt halten. PROD bleibt bis zu erfolgreichen Tests und ausdrücklicher Freigabe unverändert. **Abhängigkeiten:** E01–E04.

## 9. Übergreifende Produktentscheidungen

- Die App empfiehlt, der Trainer entscheidet.
- Trainingsbeteiligung ist ein zentrales Fairnesskriterium der Kaderempfehlung.
- Saison-, Mannschafts- und Vereinswechsel löschen keine Historie.
- Datensparsamkeit: nur tatsächlich benötigte Angaben erfassen.
- Technische und visuelle Basis soll perspektivisch sportartneutral erweiterbar sein.
- Smartphone-first, aber nicht ausschließlich für ein Gerät.
- DEV-Test und ausdrückliche Freigabe vor jeder PROD-Übernahme.

## 10. Offene Abgleiche vor GitHub-Ablage

- [ ] Statuskategorien der Gesamtübersicht abschließend einzelnen Epics zuordnen.
- [ ] Aktuelle DEV-`index.html` und Commit-/Versionsstand eindeutig erfassen.
- [ ] DEV-Schema, RLS-Policies, Funktionen und Trigger mit der technischen Bestandsaufnahme abgleichen.
- [ ] Exakten DDL-Text von `prevent_last_team_admin_removal()` und dem Constraint-Trigger aus DEV exportieren, als versionierte SQL-Migration ablegen und vor PROD gegen den tatsächlichen DEV-Stand prüfen.
- [ ] Für DEV und PROD getrennte Datenbank-Änderungsprotokolle führen; je Umgebung den angewendeten Migrationsstand und Prüfstatus festhalten.
- [ ] PROD-Dokumentation erst nach eigenständiger Bestandsaufnahme der PROD-Datenbank erstellen; DEV-Änderungen nicht als bereits in PROD vorhanden kennzeichnen.
- [ ] Repositorys, Branches, Pages-Bereitstellungen und Deploy-Workflows in GitHub verifizieren.
- [ ] E05-Reihenfolge/ Gewichtung der Empfehlungsfaktoren fachlich vereinheitlichen.
- [ ] Spielformen anhand aktueller DFB-/FLVW- und Kreisregelungen prüfen.
- [ ] E03-DEV-Teststatus klar vom PROD-Veröffentlichungsstatus trennen.
- [ ] Nach Abgleich in `develop` ablegen und dort reviewen.

## 11. Arbeitsweise für weitere Epics

Für jedes Epic festhalten: Ziel/Problem; Nutzer und Ablauf; fachliche Regeln/Sonderfälle; Datenmodell/Migrationen; UI/UX; Rollen/Berechtigungen; Akzeptanzkriterien; positive, negative und Regressionstests; DEV-Test, Freigabe und PROD-Rollout.

Vor Änderungen aktuelle DEV-Datei und relevante Datenbankstruktur identifizieren. Änderungen klein und nachvollziehbar halten. Keine Datenbankänderung vor Prüfung und Besprechung konkreter Notwendigkeit. Keine PROD-Übernahme ohne erfolgreiche Tests und ausdrückliche Freigabe.

## 12. Übergabehinweis für neue Chats

Diese Datei zusammen mit der aktuellen DEV-`index.html` als Ausgangsbasis verwenden. Zuerst gewünschtes Epic und tatsächlichen Stand betroffener Dateien/Datenbank klären. Frühere Codeausschnitte und temporäre Dateien nicht ungeprüft als aktuell behandeln. Bei Abweichungen gilt der verifizierte DEV-Stand; Dokumentation anschließend aktualisieren.

**Pflegehinweis:** Nach wesentlichen Änderungen an Architektur, Datenmodell, Sicherheit, Deployment oder Epic-Status diese Datei aktualisieren.
