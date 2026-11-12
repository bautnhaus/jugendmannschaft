# AP05.3 – Userflows und UI-Konzept: Trainingsereignisse, Sperren und Kaderplanung

**Stand:** 07.11.2026  
**Status:** Fachliches Konzept AP05.3 abgestimmt; keine technische Umsetzung erfolgt  
**Führender Branch:** `develop`  
**Zugehöriges Vorhaben:** E05 – Kaderplanung und Kaderempfehlung  
**Abgrenzung:** Dieses Dokument ergänzt AP05.2. Es ersetzt weder die dort beschlossenen Datenmodelle und Geschäftsregeln noch die bestehenden technischen Sicherheits- und Freigabevorgaben.

---

## 1. Ziel und Geltungsbereich

AP05.3 beschreibt die Bedienabläufe und die UI-Darstellung für:

- Vergabe von Trainingskarten und positiven Sternen (AP05.3a),
- zentrale Karten- und Sperrenübersicht (AP05.3b),
- Sperren, Ausnahmen und vorzeitigen Sperrausgleich in der Kaderplanung (AP05.3c),
- Transparenz der Kaderempfehlung (AP05.3d).

Die App bleibt sportartneutral und iPhone-first. Bestehende Bedienmuster und Komponenten sollen möglichst weiterverwendet werden. Die Kaderplanung soll nicht durch unnötige Erklärtexte oder zusätzliche Verwaltungsbereiche überladen werden.

**Wichtige Abgrenzung:** Die folgenden Punkte sind fachliche/UI-Entscheidungen. Es wurden im Rahmen von AP05.3 keine Änderungen an Code, Datenbank, SQL, Supabase-Konfiguration oder PROD vorgenommen.

## 2. AP05.3a – Trainingsworkflow: Karten und Sterne vergeben

### 2.1 Zugriff auf Aktionen
- In der Teilnehmerliste eines Trainings gibt es je Spieler eine kompakte Aktionsmöglichkeit.
- Die gleichen Aktionen sind über die Spielerdetails erreichbar.
- Beim Öffnen der Aktion wählt der Trainer zwischen gelber Karte, roter Karte und positivem Stern.

### 2.2 Anzeige bereits vergebener Ereignisse
- In der Teilnehmerliste erscheint ein kleines Symbol.
- Vollständige Bezeichnung und Details sind in den Spielerdetails sichtbar.
- Eine bereits vergebene Aktion wird für denselben Spieler und dasselbe Training nicht erneut angeboten.

### 2.3 Korrektur
- Korrektur oder Stornierung erfolgt ausschließlich über die Spielerdetails.
- In der Teilnehmerliste gibt es keine direkte Korrekturfunktion.
- Eine Korrektur/Stornierung erfordert eine Begründung; ursprüngliches Ereignis und Änderung bleiben in der Historie/Auditierung nachvollziehbar.

### 2.4 Freiwilligkeit
- Es gibt keine verpflichtende Abschlussprüfung und keine Erinnerung, dass Karten oder Sterne vergeben werden müssen.
- Nur tatsächlich vergebene Karten/Sterne erzeugen einen Ereigniseintrag.

### 2.5 Bereits abgestimmte fachliche Grenzen
- Maximal eine Karte je Spieler und Training: gelb oder rot.
- Maximal ein positiver Stern je Spieler und Training.
- Karte und Stern dürfen für denselben Spieler im selben Training nebeneinander bestehen.
- Gelbe/rote Karte benötigen eine Begründung; beim positiven Stern ist sie optional.
- Serverseitige Berechtigungsprüfung und DB-seitige Verhinderung konkurrierender Duplikate bleiben verbindlich.

## 3. AP05.3b – Karten- und Sperrenübersicht

### 3.1 Zugang und Listenstruktur
- Kombination aus zentraler Mannschaftsübersicht und direktem Zugang über die Spielerdetails.
- Eine kompakte, gemeinsame Spielerliste; keine getrennten Gruppenbereiche.
- Sortierung nach Handlungspriorität:
  1. Spieler mit offenen Sperren,
  2. Spieler mit vier aktiven gelben Karten (Warnung),
  3. Spieler mit anderen aktiven gelben Karten,
  4. Spieler ohne aktive Auffälligkeit.
- Innerhalb der jeweiligen Gruppe alphabetisch.

### 3.2 Suche und Filter
- Suchfeld plus kompakte Filterchips: **Alle**, **Sperren**, **Warnungen**, **Ohne Auffälligkeiten**.
- Es ist jeweils nur ein Filter aktiv; Standard ist **Alle**.
- **Sperren:** mindestens eine offene Sperre.
- **Warnungen:** vier aktive gelbe Karten.
- **Ohne Auffälligkeiten:** keine offene Sperre und keine Warnung.
- Suche und Filter wirken zusammen. Beim Zurückkehren aus den Spielerdetails bleibt der vorherige Such-/Filterzustand erhalten.
- Die Ansicht bezieht sich auf die ausgewählte Mannschaft und die aktuelle Saison.

### 3.3 Spielerdetails
- Der aktuelle Status ist immer sichtbar.
- Ereignishistorie und Sperrenhistorie sind jeweils einklappbar und standardmäßig nach Datum absteigend sortiert (neueste zuerst).
- Aktueller Status umfasst insbesondere aktiven gelben Kartenstand, Warnung bei vier Karten, offene gelbe/rote Sperren, aktuelle Ausnahmen und den nächsten vorgesehenen Sperrspieltag.
- Ereignishistorie zeigt Typ, Datum/Training, Begründung, verantwortlichen Trainer sowie Korrektur-/Stornierungskennzeichen.
- Sperrenhistorie zeigt Auslöser, Sperrentyp, vorgesehenen und tatsächlich absolvierten Spieltag, Ausnahmen, manuelle Korrekturen und abgelaufene Sperren.

### 3.4 Korrektur und Stornierung
- Berechtigte Trainer erhalten direkt am jeweiligen Ereignis einen Menüpunkt zum Korrigieren oder Stornieren.
- An Sperreneinträgen gibt es direkt die passenden Verwaltungsaktionen: manuelle Korrektur, vorgesehenen Spieltag ändern, im zulässigen Rahmen als fehlerhaft aufheben sowie Ausnahmen für einen konkreten Spieltag verwalten.
- Für jede Änderung sind Begründung, Benutzer, Zeitpunkt und alte/neue Werte zu protokollieren.
- Manuelle Sperrenkorrekturen erfolgen über ein **eigenes Korrekturformular**:
  1. Sperreneintrag öffnen und „Sperre korrigieren“ auswählen.
  2. Bisherige Werte werden angezeigt und können angepasst werden.
  3. Begründung ist verpflichtend.
  4. Vor dem Speichern wird eine Zusammenfassung der Änderungen angezeigt.
  5. Nach dem Speichern werden Alt-/Neuwert, Begründung, Benutzer und Zeitpunkt auditiert.
- Bereits absolvierte Sperren werden durch spätere Korrekturen nicht rückwirkend aufgehoben. Abgeschlossene Spieltage und tatsächliche Einsätze werden nicht rückwirkend verändert.

### 3.5 Stornierte Ereignisse
- Stornierte Ereignisse bleiben an ihrem ursprünglichen Datum in der chronologischen Historie sichtbar.
- Sie werden eindeutig als storniert gekennzeichnet und zählen weder zum aktiven gelben Kartenkonto noch zur Kaderempfehlung.
- Ursprüngliches Ereignis und Stornierung bleiben im Audit erhalten.
- Eine Wiederherstellung ist nur über eine kontrollierte, auditierte Korrektur möglich.

### 3.6 Sperrausnahmen
- Eine Ausnahme kann sowohl aus den Spielerdetails als auch später direkt aus der Kaderplanung angestoßen werden.
- Beide Einstiege verwenden dieselbe serverseitige Funktion und dieselbe fachliche Logik.
- Die Ausnahme gilt nur für einen konkreten Spieltag und benötigt eine Begründung.
- Mit Genehmigung wird die Sperre unmittelbar auf den nächsten relevanten Spieltag verschoben – unabhängig davon, ob der Spieler am Ausnahmespieltag tatsächlich eingesetzt wird.
- Die Sperre bleibt offen und sichtbar. In den Details werden der konkrete Ausnahmespieltag sowie genehmigender Trainer, Zeitpunkt und Begründung angezeigt.
- Die Ausnahme ist keine Sperrenableistung und verändert weder Nominierung noch tatsächliche Einsätze.

## 4. AP05.3c – Kaderplanung: Sperren, Ausnahmen und vorzeitiger Sperrausgleich

### 4.1 Ausgangslage und bisheriger Ablauf
- Spielerzusagen kommen derzeit über einen separaten Kanal außerhalb der App.
- Der Trainer stellt den Kader auf Basis dieser Zusagen wie bisher direkt in der Kaderplanung zusammen.
- Es wird keine neue Rückmeldeverwaltung als Voraussetzung für diesen Ablauf eingeführt.
- Die bestehende Nominierung durch Antippen der Spielerkachel bleibt erhalten.

### 4.2 Statusfarben und optische Signale

| Status | Darstellung | Bedeutung |
|---|---|---|
| Für Kader vorgeschlagen | Blau hervorgehoben | Spieler gehört zur Kaderempfehlung, ist noch nicht nominiert |
| Für Kader nominiert | Grün hervorgehoben und Apparel-Icon am Avatar | Trainer hat den Spieler nominiert |
| Regulär für den nächsten Spieltag gesperrt | Rot hervorgehoben | Spieler wird aus der Kaderempfehlung ausgeschlossen |
| Vorzeitiger Sperrausgleich vorgemerkt | Gelb hervorgehoben; Apparel-Icon gelb und durchgestrichen | Trainer hat den vorzeitigen Sperrausgleich für diesen konkreten Spieltag vorgemerkt |

Eine genehmigte Sperrausnahme hebt die reguläre Sperre nicht auf: Die Kachel bleibt rot und erhält zusätzlich den Hinweis **„Ausnahme erteilt“**. So bleibt erkennbar, dass die Sperre offen ist, der Spieler aber für genau diesen Spieltag berücksichtigt werden darf.

### 4.3 Regulär gesperrte Spieler und Ausnahmen
- Regulär gesperrte Spieler bleiben in der Kaderplanung sichtbar und rot hervorgehoben.
- Sie werden bei der Kaderempfehlung nicht berücksichtigt.
- Über die Spielerdetails sieht der Trainer Sperrgrund und betroffenen Spieltag.
- Dort kann er **„Ausnahme genehmigen“** auswählen.
- Eine Begründung ist verpflichtend.
- Vor dem Speichern erscheint eine zusätzliche Sicherheitsabfrage mit dem Hinweis, dass der Spieler trotz offener Sperre für diesen Spieltag berücksichtigt werden darf und die Sperre bestehen bleibt.
- Nach Bestätigung bleibt die Kachel rot und erhält zusätzlich **„Ausnahme erteilt“**.
- Die Ausnahme gilt ausschließlich für diesen Spieltag. Die offene Sperre wird auf den nächsten relevanten Spieltag verschoben.

### 4.4 Vorzeitiger Sperrausgleich – Zweck und Auslöser
Der vorzeitige Sperrausgleich ist eine zusätzliche, freiwillige Trainerentscheidung im Rahmen der Kaderzusammenstellung. Er ist **nicht** an eine bestimmte Anzahl gelber Karten gebunden.

Ausgangssituation: Für einen Spieltag können beispielsweise 16 Spieler nominiert werden, es liegen aber mehr Zusagen vor. Der Trainer stellt den Kader zusammen und kann zusätzlich für einzelne nicht nominierte Spieler einen vorzeitigen Sperrausgleich vormerken.

Regeln:
- Unabhängig davon, ob ein Spieler null, eine oder mehrere aktive gelbe Karten hat.
- Eine Nichtnominierung allein löst keinen Sperrausgleich aus.
- Die Vormerkung ist eine ausdrückliche, zusätzliche Entscheidung des Trainers.
- Die Vormerkung wird mit Spieler, Mannschaft, Spieltag, Trainer, Zeitpunkt und Begründung dokumentiert.
- Sie wird erst wirksam, wenn der konkrete Spieltag tatsächlich stattgefunden hat.
- Bei abgesagtem/nicht stattgefundenem Spieltag wird sie automatisch aufgehoben; das aktive gelbe Kartenkonto bleibt unverändert.
- Es erfolgt keine automatische Übertragung auf einen anderen Spieltag.
- Historische Kartenereignisse bleiben unverändert.
- Bereits ausgelöste reguläre gelbe oder rote Sperren können dadurch nicht aufgehoben werden; rote Karten/rote Sperren bleiben unberührt.

### 4.5 Bedienung: Nominierung und Sperrausgleich
Es gelten zwei direkte Bedienwege:

**Nominierung – unverändert**
- Trainer tippt die Spielerkachel an.
- Der Spieler wird nominiert.
- Die Kachel wechselt auf Grün und das Apparel-Icon am Avatar wird angezeigt.

**Vorzeitigen Sperrausgleich vormerken – zusätzliche Kachelaktion**
- Auf der Spielerkachel gibt es eine zusätzliche Aktion/ein Aktionssymbol für den vorzeitigen Sperrausgleich.
- Die Aktion öffnet den Vormerkungsablauf mit Begründung und Bestätigung.
- Nach erfolgreicher Vormerkung wird die Kachel gelb; das Apparel-Icon wird gelb und durchgestrichen.

**Optionsmenü – beide Aktionen**
- Das Optionsmenü bietet beide Aktionen:
  - **„Empfehlen / nominieren“**
  - **„Sperrausgleich vormerken“**
- Die direkte Nominierung durch Antippen der Kachel bleibt zusätzlich bestehen.
- Der zusätzliche Kachelkurzbefehl für den Sperrausgleich bleibt ebenfalls bestehen.
- Alle Einstiege verwenden dieselbe fachliche Logik; es gibt keine abweichenden parallelen Abläufe.

### 4.6 Gegenseitiger Ausschluss und Aufhebung
- Ein Spieler kann für denselben Spieltag nicht gleichzeitig nominiert sein und einen vorzeitigen Sperrausgleich erhalten.
- Wird ein Spieler nachträglich nominiert, wird eine bestehende Vormerkung automatisch aufgehoben.
- Gelbe Hervorhebung und durchgestrichenes gelbes Apparel-Icon verschwinden; der Spieler erhält den grünen Nominierungsstatus.
- Das aktive gelbe Kartenkonto bleibt unverändert.
- Die Aufhebung wird mit Zeitpunkt und verantwortlichem Trainer protokolliert.
- Wird der Spieltag abgesagt, wird die Vormerkung ebenfalls automatisch aufgehoben. Keine Übertragung auf einen Folgespieltag.
- Eine wirksam gewordene Vormerkung setzt nach tatsächlich stattgefundenem Spieltag das aktive gelbe Kartenkonto gemäß AP05.2 auf null; die Ereignishistorie bleibt erhalten. Dies ist keine regulär abgeleistete Sperre.

### 4.7 Einfluss auf die Kaderempfehlung
- Regulär gesperrte Spieler werden vor der Empfehlung aus der Menge der berücksichtigungsfähigen Spieler ausgeschlossen.
- Die Empfehlung wird aus den übrigen berücksichtigungsfähigen Spielern berechnet.
- Ein vorgemerkter vorzeitiger Sperrausgleich hat **keinen Einfluss** auf die allgemeine Kaderempfehlung, deren Berechnung oder Reihenfolge.
- Die gelbe Kennzeichnung dokumentiert ausschließlich die zusätzliche manuelle Trainerentscheidung.
- Nominierung bleibt eine manuelle Entscheidung des Trainers; die App empfiehlt, der Trainer entscheidet.

## 5. AP05.3d – Transparenz der Kaderempfehlung

Die Empfehlung wird nicht bei jedem Spieltag individuell begründet.

- Keine individuellen Begründungstexte pro Spieler (z. B. warum Spieler X empfohlen und Spieler Y nicht empfohlen wurde).
- Keine zusätzliche Erklärungsbox oder Detailansicht je Spieltag/Spieler.
- Die vereinbarten Statusfarben und Symbole reichen für die operative Kaderplanung aus.
- Die Empfehlungslogik wird einmalig in der FAQ erläutert.

Die FAQ soll die grundsätzlichen Einflussfaktoren und Regeln verständlich beschreiben, insbesondere:
- Trainingsbeteiligung und Aktualität,
- bisherige Kadernominierungen bzw. faire Berücksichtigung,
- positive Sterne aus den letzten sechs tatsächlich durchgeführten Trainings der aktuellen Saison mit begrenztem Einfluss,
- Ausschluss regulär gesperrter Spieler,
- manuelle Entscheidungshoheit des Trainers.

Es gibt weiterhin kein Gesamtpunktesystem, kein OVR und kein automatisches Spielerranking. Gelbe Karten unterhalb der Sperrschwelle sind Information/Warnung und beeinflussen die Empfehlung nicht. Der vorzeitige Sperrausgleich verändert die Empfehlung ebenfalls nicht.

**Dokumentationsfolge:** Die Ergänzung der FAQ ist als separate Dokumentationsaufgabe im Backlog zu berücksichtigen. Sie ist keine zusätzliche Funktion der Kaderplanungsoberfläche.

## 6. Übergreifende Abhängigkeiten und bereits beschlossene Regeln

AP05.3 baut auf den fachlichen Beschlüssen aus AP05.2 auf. Insbesondere bleiben verbindlich:
- Trainingsereignisse sind trainingsbezogen und freiwillig; Abwesenheit oder Trainingsausfall erzeugt keine Karte.
- Ereignisse und Sperren sind historisch nachvollziehbar und auditierbar.
- Sperren sind an ursprüngliche Mannschaft und Saison gebunden.
- Saisonwechsel, Mannschaftswechsel, Spieltagsausfall/-verschiebung und sequenzielle Sperren folgen den in AP05.2 beschlossenen Regeln.
- Ausnahmen gelten für einen konkreten Spieltag und verschieben die offene Sperre; sie löschen sie nicht.
- Bereits absolvierte Sperren und abgeschlossene Spieltage werden durch spätere Korrekturen nicht rückwirkend verändert.
- Nominierung und tatsächlicher Einsatz bleiben getrennte Sachverhalte.
- Server-/Datenbankberechtigungen sind maßgeblich; die UI darf keine unzulässigen Aktionen anbieten.
- Konkurrierende Vergaben müssen server-/datenbankseitig gegen Duplikate abgesichert sein.

Für technische Details, Tabellen-/Auditmodelle, Sperrlogik und Empfehlungseinfluss ist AP05.2 maßgeblich. Dieses AP05.3-Dokument ändert diese Regeln nicht.

## 7. Abschlussstatus und nächste Schritte

| Teilpaket | Ergebnis |
|---|---|
| AP05.3a – Trainingsworkflow | Fachlich abgestimmt |
| AP05.3b – Karten- und Sperrenübersicht | Fachlich abgestimmt |
| AP05.3c – Kaderplanung | Fachlich abgestimmt |
| AP05.3d – Transparenz der Empfehlung | Fachlich abgestimmt; FAQ-Aufgabe bleibt separat |

**AP05.3 ist fachlich abgeschlossen.**

Vor einer Umsetzung gelten weiterhin die verbindlichen Projektregeln:
1. Anforderungen/Konzept mit dem aktuellen DEV-Stand abgleichen.
2. Bestehende Komponenten und tatsächliche Datenbankdefinitionen gezielt prüfen.
3. UI-Flow/Wireframe und High-Fidelity-Konzept bei Bedarf gesondert abstimmen.
4. Erst nach separater Freigabe Codeänderungen in DEV beginnen.
5. SQL-Änderungen nur nach Vorlage des vollständigen SQL, Zweck und Zielumgebung sowie ausdrücklicher Freigabe.
6. DEV praktisch testen; PROD bleibt bis zu einer gesonderten Freigabe unverändert.

**Umsetzungsstatus:** Keine Code-, SQL-, Datenbank-, Supabase-, Auth-, Edge-Function-, DNS- oder PROD-Änderung im Rahmen von AP05.3.


## 8. Ergänzende verbindliche UI-Entscheidung – Ausnahme zur regulären Sperre (12.11.2026)

Die Darstellung der regulären Sperre und einer erteilten Spieltagsausnahme wird wie folgt präzisiert:

- **Ohne Ausnahme:** gesamte Spieltagskachel sanft rot hinterlegt und rot konturiert; Chip „Gesperrt · Ausnahme möglich“. Keine reguläre Empfehlung oder Nominierung. Trainer kann über die Kachel den begründungspflichtigen Ausnahmeprozess öffnen.
- **Ausnahme erteilt:** rote Hinterlegung und rote Kontur werden entfernt. Die Kachel zeigt wieder ihre normale bzw. unabhängig davon bestehende Empfehlungs-/Nominierungsdarstellung. Der Chip „Ausnahme erteilt“ bleibt an derselben Position sichtbar. Für diesen Spieltag ist der Spieler wieder für Empfehlung und Nominierung zugelassen.
- **Folgender relevanter Spieltag:** die offene Sperre besteht fort und wird gemäß AP05.2 auf den nächsten relevanten Spieltag verschoben. Dort gilt wieder die reguläre rote Sperrdarstellung, solange keine neue Ausnahme für genau diesen Spieltag erteilt wurde.

Die Ausnahme gilt ausschließlich für den konkreten Spieltag und löscht/erledigt die Sperre nicht. Historie und Datenbank-Sperrstatus bleiben erhalten.

### Einheitliche Chip-Geometrie
Beide Status-Chips müssen dieselbe Höhe, Schriftgröße, Schriftstärke, Zeilenhöhe, Innen-/Außenabstände, Rundung und Position direkt unter dem Spielernamen verwenden. Unterschiedliche Chiptexte dürfen keine abweichende Höhe oder vertikale Kachelgeometrie erzeugen.

Gelb bleibt dem vorgemerkten vorzeitigen Sperrausgleich vorbehalten (Abschnitte 4.4–4.6). Diese UI-Präzisierung ändert die fachliche Sperr- und Ausnahme-Logik aus AP05.2 nicht.
