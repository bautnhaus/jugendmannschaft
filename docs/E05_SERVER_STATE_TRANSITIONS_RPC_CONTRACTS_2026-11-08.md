# E05 – Serverseitige Zustandsübergänge und RPC-Verträge

**Stand:** 08.11.2026  
**Branch:** `develop`  
**Zielumgebung später:** ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`)  
**Status:** Technische Spezifikation – keine SQL-Migration, keine Ausführung, keine Freigabe  
**Grundlage:** AP05.2, AP05.3a–d, `docs/E05_TECHNISCHES_ZIELDATENMODELL_2026-11-08.md`, SQL-Schemaentwurf Revision 4 und aktueller DEV-Abgleich.

## 1. Zweck und Abgrenzung

Dieses Dokument definiert die serverseitigen Verträge, die das Schemafundament mit den fachlich freigegebenen Abläufen verbinden. Es ist die Vorstufe zur Implementierung der RPCs und ihrer Tests.

Bereits erledigt und hier nicht erneut ausgeführt:
- konsolidiertes technisches Zieldatenmodell Revision 3;
- Schemafundament-Entwurf und DEV-Abgleich;
- statische Prüfung und isolierter PostgreSQL-17.6-Lauf für den ACL-abgeglichenen Schemaentwurf (Workflow #17, Commit `b9b33c2`, erfolgreich).

Dieses Dokument legt keine neue fachliche Regel fest. Wo ein technisches Detail aus dem vorhandenen DEV-Schema oder den freigegebenen AP05-Regeln nicht eindeutig folgt, ist es ausdrücklich als Implementierungs-Prüfpunkt markiert.

## 2. Übergreifende RPC-Sicherheits- und Transaktionsregeln

1. Schreibende RPCs werden ausschließlich für authentifizierte Benutzer angeboten. `anon` und `PUBLIC` erhalten kein EXECUTE.
2. Jede RPC ermittelt den Akteur ausschließlich serverseitig über `auth.uid()`; Akteur-IDs aus Clientparametern werden nicht akzeptiert.
3. Jede RPC prüft Team-/Saison-/Objektzugehörigkeit und die konkrete Berechtigung serverseitig. Ein UI-Filter oder ausgeblendeter Button ist keine Berechtigungsprüfung.
4. Für die Foundation gibt es keine direkten Client-Schreibrechte auf die E05-Tabellen. Alle Domänenänderungen und Audit-Einträge erfolgen innerhalb derselben Datenbanktransaktion über RPCs.
5. Falls `SECURITY DEFINER` erforderlich ist, dann mit Owner `postgres`, festem `search_path = pg_catalog, public, auth`, vollständig qualifizierten Objektbezügen und enger EXECUTE-ACL. Kein dynamisches SQL, sofern nicht zwingend erforderlich.
6. Jeder Schreibvorgang schreibt den vollständigen Vorher-/Nachher-Snapshot, Aktion, Grund (wo vorgeschrieben), Akteur-Snapshot und Zeitpunkt in die passende Append-only-Audittabelle. Scheitert das Audit-INSERT, muss die gesamte Transaktion zurückrollen.
7. RPCs verwenden Zeilensperren (`FOR UPDATE`) für konkurrierend änderbare Quell-/Zieldatensätze. Eindeutige Indizes bleiben die letzte Integritätssicherung bei parallelen Requests.
8. Keine RPC führt Hard Deletes auf Ereignis-, Sperren-, Ausnahme-, Reset- oder Audithistorien aus.
9. Keine automatische Änderung an Nominierung oder tatsächlichem Einsatz, wenn eine Karte/Sperre entsteht. Diese Vorgänge bleiben getrennt.
10. Fehlerfälle müssen stabil und testbar sein. Vorgesehene SQLSTATEs: `42501` unberechtigt, `22023` ungültige Eingabe, `P0002` Referenzobjekt nicht gefunden, `23514` fachlicher Zustands-/Konsistenzverstoß, `23505` Duplikat/Konkurrenz. Keine internen SQL-/Tabellendetails an den Client leaken.

## 3. Ereignisvergabe und Ereigniskorrektur – erste Implementierungsetappe

### 3.1 `award_training_behavior_event`

**Zweck:** Gelbe Karte, rote Karte oder positiven Stern für einen Spieler in einem konkreten Training vergeben.

**Vorgesehener Vertrag:**
```sql
public.award_training_behavior_event(
  p_training_id uuid,
  p_player_id uuid,
  p_event_type text,
  p_reason text default null
) returns uuid
```

Rückgabe ist die ID des neu angelegten Ereignisses. Keine clientseitige Vorgabe von Team, Saison, Actor, Zeitpunkt oder Snapshot-Werten.

**Serverseitige Vorbedingungen – alle müssen in derselben Transaktion erfüllt sein:**
- `auth.uid()` ist vorhanden.
- Training existiert und ist einem Team zugeordnet.
- Spieler existiert, ist aktiv und gehört genau diesem Team.
- Akteur besitzt die freigegebene Trainerberechtigung für dieses Team. Die Implementierung verwendet die bestehende Rollen-/Kontextlogik und prüft die tatsächliche Trainerrolle; Superadmin-Rechte gelten nur im ausdrücklich ausgewählten Teamkontext.
- `attendance` enthält für genau dieses Training und diesen Spieler `present = true`. `training_responses` und bloße Rückmeldungen gelten ausdrücklich nicht als Anwesenheitsnachweis.
- Die aktive Saison dieses Teams ist eindeutig bestimmbar. `trainings.season_id` darf bei Bestandsdaten NULL sein; in diesem Fall wird die aktive Saison über die bestehende Team-/Saisonstruktur ermittelt. Keine oder mehrere aktive Saisons: Abbruch ohne Ereignisanlage.
- Ereignistyp ist exakt `yellow_card`, `red_card` oder `positive_star`.
- Gelbe/rote Karte: nichtleerer Grund verpflichtend. Stern: Grund optional.
- Pro Spieler/Training höchstens eine aktive Karte insgesamt (gelb ODER rot) und höchstens ein aktiver Stern. Karte und Stern dürfen koexistieren.

**Atomare Schreibfolge:**
1. Trainings-/Spielerzuordnung und Anwesenheit prüfen; relevante Zeilen gegen parallele Änderungen sperren.
2. aktive Saison und Snapshotwerte serverseitig bestimmen.
3. Ereignis mit `status='active'`, Akteur und Zeitstempel anlegen.
4. `training_behavior_event_audit` mit `action='created'`, vollständigem `new_values`, Akteur und Zeitpunkt anlegen.
5. Ereignis-ID zurückgeben.

Ein konkurrierender zweiter Karten- oder Sternversuch muss durch die Unique-Indizes abgewiesen werden. Es darf niemals ein stilles Überschreiben oder automatisches Zusammenführen geben.

### 3.2 `correct_training_behavior_event`

**Zweck:** Ein bestehendes Ereignis fachlich berichtigen, ohne Historie zu verlieren.

**Vorgesehener Vertrag:**
```sql
public.correct_training_behavior_event(
  p_event_id uuid,
  p_new_event_type text,
  p_new_reason text,
  p_correction_reason text
) returns uuid
```

- Nur aktive Ereignisse dürfen berichtigt werden.
- Korrekturgrund ist immer Pflicht.
- Bei Karten muss der neue Ereignisgrund nichtleer sein; beim Stern darf er NULL/leer sein.
- Korrektur darf Typ und/oder Ereignisgrund ändern. Die Karten-/Stern-Eindeutigkeitsregeln gelten auch für den Zielzustand.
- Ereignis wird unter `FOR UPDATE` geladen; Berechtigung wird gegen das historische Team geprüft.
- Ein Wechsel zwischen Karte und Stern wird gegen beide partiellen Unique-Indizes abgesichert.
- Auditaktion `corrected` speichert den vollständigen alten und neuen Ereigniszustand sowie den verpflichtenden Korrekturgrund.
- Eine Korrektur darf bereits bediente Sperren, abgeschlossene Spieltage oder tatsächliche Einsätze nicht rückwirkend ändern. Ist aus dem Ereignis bereits eine Sperre entstanden, muss die RPC die Korrektur entweder atomar mit einer fachlich zulässigen Sperrenkorrektur behandeln oder den Vorgang ablehnen. Bis die Sperren-RPCs implementiert sind, gilt: **Korrektur eines sperrauslösenden Ereignisses wird abgewiesen**; kein inkonsistenter Zwischenzustand.

### 3.3 `void_training_behavior_event`

**Zweck:** Fälschlich vergebenes Ereignis auditierbar stornieren.

**Vorgesehener Vertrag:**
```sql
public.void_training_behavior_event(
  p_event_id uuid,
  p_void_reason text
) returns uuid
```

- Stornogrund ist Pflicht.
- Nur aktive Ereignisse dürfen storniert werden.
- Team-Trainerberechtigung wird serverseitig geprüft.
- Status wechselt auf `voided`; die Ereigniszeile bleibt erhalten.
- Auditaktion `voided` mit altem/neuem Snapshot und Grund.
- Storno eines Ereignisses, das bereits eine offene oder bediente Sperre ausgelöst hat, wird zunächst abgewiesen. Eine spätere integrierte Sperrenkorrektur darf nur offene Sperren ändern; bediente Sperren bleiben unveränderbar.
- Stornierte Ereignisse zählen weder zum aktiven gelben Kartenkonto noch zur Empfehlung.

### 3.4 `reinstate_training_behavior_event`

**Zweck:** Ein storniertes Ereignis kontrolliert wiederherstellen.

**Vorgesehener Vertrag:**
```sql
public.reinstate_training_behavior_event(
  p_event_id uuid,
  p_reinstatement_reason text
) returns uuid
```

- Wiederherstellungsgrund ist Pflicht.
- Nur `voided` darf reaktiviert werden.
- Team-Trainerberechtigung wird erneut geprüft.
- Die Unique-Indizes müssen den Zielzustand zulassen. Besteht bereits ein anderes aktives Ereignis desselben Karten-/Stern-Typs im Training, wird abgebrochen.
- Auditaktion `reinstated` mit Vorher-/Nachher-Snapshot und Grund.
- Eine Wiederherstellung darf keine bereits bediente Sperre rückwirkend erzeugen. Falls die Wiederherstellung die Fünf-Karten-Schwelle oder eine rote Sperre auslösen würde, muss die RPC im späteren integrierten Lifecycle atomar eine neue offene Sperre erzeugen oder bis dahin mit fachlichem Fehler abbrechen. Keine stille Teilwiederherstellung.

## 4. Sperren-Lifecycle – nach Freigabe und Abschluss der Ereignis-RPCs

Die folgenden RPCs sind die Zielverträge der zweiten Etappe. Sie werden nicht mit der Ereignisvergabe vermischt.

| RPC | Zweck | zentrale Integritätsbedingung |
|---|---|---|
| `reconcile_player_suspensions` | Kartenkonto neu auswerten und erforderliche offene Sperre erzeugen | 5 aktive gelbe Karten erzeugen eine gelbe Sperre; rote Karte sofort rote Sperre; max. eine Sperre je Quellevent |
| `assign_next_suspension_matchday` | offene Sperre dem nächsten relevanten Spieltag zuordnen | nur tatsächlich konfigurierte Spielart; Team-/Saisonbezug; gelb vor rot |
| `serve_matchday_suspensions` | Sperren nach tatsächlich durchgeführtem Spieltag bedienen | Matchday muss `done` sein; pro relevantem Spieltag maximal eine offene Sperre je Spieler; Ausnahme ist keine Ableistung |
| `grant_suspension_exception` | Ausnahme für konkrete Sperre und konkreten Spieltag | Trainerberechtigung, Pflichtgrund; Sperre bleibt offen und wird sofort weitergeschoben |
| `correct_suspension` | offene Sperre manuell berichtigen | Pflichtgrund, Vorher-/Nachher-Audit; bediente Sperre nicht rückwirkend änderbar |
| `expire_season_suspensions` | Saisonabschluss | offenes gelbes Konto zurücksetzen; offene Sperren auslaufen lassen; Historie erhalten |
| `set_club_suspension_game_types` | Club-Standard-Spielarten pflegen | nur erlaubte Spielarten; Clubkontext-Prüfung |
| `set_team_suspension_game_types` | vollständigen Team-Override setzen/entfernen | vorhandener Override-Kopf + leere Kindliste ist gültiger leerer Override; Entfernen des Kopfes aktiviert Club-Standard |

**Lifecycle-Regeln:**
- Fünf aktive gelbe Karten lösen eine gelbe Sperre aus; vier sind Warnung.
- Nach Ableistung einer gelben Sperre beginnt das aktive gelbe Konto neu. Gelbe Karten während einer offenen gelben Sperre werden nicht in das nächste Konto übernommen.
- Rot erzeugt sofort eine rote Sperre und ändert das gelbe Konto nicht.
- Nur tatsächlich durchgeführte und nach Club-/Teamkonfiguration relevante Spieltage zählen. Absage zählt nicht; Verschiebung zählt erst bei Durchführung.
- Mehrere offene Sperren werden nacheinander bedient: gelb vor rot, je eine pro relevantem Spieltag.
- Eine Ausnahme ist an einen konkreten Spieltag gebunden, benötigt Grund und verschiebt die offene Sperre sofort zum nächsten relevanten Spieltag – unabhängig davon, ob der Spieler tatsächlich eingesetzt wurde.
- Team-Override ersetzt die Clubliste vollständig; ohne Override gilt die Clubliste. Änderungen gelten nur für zukünftige Zuordnungen und lösen keine rückwirkende Neubewertung aus.
- Saisonwechsel setzt das aktive gelbe Konto zurück und lässt offene Sperren auslaufen; Historie bleibt erhalten.
- Bediente Sperren und abgeschlossene Spieltage werden nicht rückwirkend geändert.

## 5. Vorzeitiger Sperrausgleich – dritte Etappe

| RPC | Zweck | verbindliche Prüfung |
|---|---|---|
| `schedule_early_suspension_reset` | Reset für einen nicht nominierten Spieler und einen konkreten Spieltag vormerken | Pflichtgrund; Trainerberechtigung; atomare Prüfung, dass Spieler nicht in `matchday_players` nominiert ist |
| `cancel_early_suspension_reset` | Vormerkung bei späterer Nominierung oder Absage stornieren | nur `pending`; Grund und Audit; keine Änderung am gelben Konto |
| `apply_early_suspension_reset` | Reset nach tatsächlicher Durchführung anwenden | konkreter Spieltag `done`; nur `pending`; aktives gelbes Konto ab Anwendungszeitpunkt neu beginnen |
| `reconcile_early_suspension_reset` | Zustandsabgleich nach Nominierungs-/Spieltagänderung | Nominierung storniert Vormerkung; Absage storniert; keine Übertragung auf anderen Spieltag |

Der Reset ist unabhängig von der Zahl gelber Karten, kein reguläres Sperrenereignis und kein Einflussfaktor der allgemeinen Kaderempfehlung. Rote Karten und bereits ausgelöste Sperren bleiben unberührt.

## 6. Read-Verträge und Frontend-Verbrauch

Read-RPCs werden separat nach den Schreib-RPCs entworfen. Sie müssen mindestens folgende Informationen liefern:
- aktueller aktiver gelber Kartenstand und Warnstatus (vier Karten);
- offene gelbe/rote Sperre und nächster vorgesehener Spieltag;
- aktuelle Ausnahme für den konkreten Spieltag;
- Ereignis- und Sperrenhistorie einschließlich Storno-/Korrekturkennzeichen;
- offene/frühere Sperrausgleich-Vormerkungen und deren Status.

Lesen erfolgt im ausgewählten Teamkontext über bestehende Berechtigungshelfer. Das Frontend nutzt die bereits abgestimmten bestehenden Listen-/Detailkomponenten; es wird keine parallele Ersatzliste eingeführt.

## 7. Prüfmatrix – vor Implementierung jeder RPC

| Prüfklasse | Ereignisvergabe/-korrektur | Sperren-Lifecycle | Sperrausgleich |
|---|---|---|---|
| Positiv | anwesender Spieler; gültiger Trainer; je erlaubter Ereignistyp | gelbe Schwelle; rot; relevanter durchgeführter Spieltag | nicht nominierter Spieler; konkreter Spieltag |
| Negativ | nicht anwesend; falsches Team; inaktiver Spieler; fehlende Trainerrolle; fehlende/mehrdeutige aktive Saison; leerer Kartengrund | falsche Saison/Team; nicht relevante Spielart; abgesagter Spieltag; fehlende Rolle | bereits nominiert; falsches Team; fehlende Rolle; abgesagter Spieltag |
| Grenze | 4→5 gelbe Karten; Karten-/Stern-Kombination; Storno/Wiederherstellung | mehrere Sperren; gelbe vor roter; Ausnahme ohne Einsatz; Saisonwechsel | Nominierung nach Vormerkung; Absage; Durchführung |
| Parallelität | zwei Karten-Requests; zwei Stern-Requests; Korrektur gegen Storno | zwei Lifecycle-Aufrufe; gleichzeitige Ableistung/ Ausnahme | Vormerkung gegen Nominierung; Absage gegen Anwendung |
| Regression | Anwesenheit bleibt unverändert; keine automatische Nominierung/Einsatzänderung | historische Spieltage/Einsätze bleiben unverändert | Empfehlung und Reihenfolge bleiben unverändert |

Jeder Test muss neben dem RPC-Ergebnis den Datenzustand und den zugehörigen Audit-Eintrag prüfen. Bei Fehlern muss die Transaktion vollständig zurückrollen; es darf weder ein Ereignis ohne Audit noch ein Audit ohne passende Zustandsänderung verbleiben.

## 8. Noch zu klärende technische Prüfdetails (keine neuen Fachentscheidungen)

1. Aktive-Saison-Abfrage: tatsächliche Constraints und Kardinalität von `seasons` in DEV vor RPC-Implementierung read-only verifizieren.
2. Trainerberechtigung: konkrete bestehende DEV-Rollenstruktur für Trainer und Superadmin-im-ausgewählten-Teamkontext verwenden; keine neue Rollenquelle anlegen.
3. Ereigniskorrektur nach Sperrenentstehung: bis zur atomaren Lifecycle-Implementierung abweisen, nicht teilweise ausführen.
4. Matchday-Reihenfolge und Gleichzeitigkeit: vorhandene Termin-/Statusfelder und eindeutige Reihenfolge aus DEV prüfen, bevor `assign_next_suspension_matchday` implementiert wird.
5. Actor-Namenssnapshots: dieselbe vorhandene Profilnamensquelle nutzen, die in der App maßgeblich ist; keine E-Mail als Ersatz für einen verfügbaren Anzeigenamen.
6. Rückgabevertrag: UUID für reine Schreibaktionen; Read-RPCs erhalten später explizite tabellarische Rückgabetypen. Keine unnötigen JSON-Schnittstellen.

## 9. Nächster technischer Schritt

Nach diesem Vertragsentwurf folgt eine gezielte read-only Prüfung der konkret verwendeten DEV-Tabellen und Rollenhelfer für die Ereignis-RPCs. Danach wird ausschließlich der Ereignis-RPC-SQL-Entwurf erstellt, statisch geprüft (einschließlich Syntax), im isolierten PostgreSQL-17.6-Test ausgeführt und mit Positiv-/Negativ-/Grenz-/Parallelitätstests ergänzt.

**Keine SQL-Ausführung in Supabase DEV oder PROD ist durch dieses Dokument autorisiert.** Jede spätere schreibende SQL-Anfrage muss vollständig dokumentiert und vor Ausführung ausdrücklich freigegeben werden.
