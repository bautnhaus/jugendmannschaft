# E05 – Technisches Zielmodell: Trainingsereignisse, Sperren und Sperrausgleich

**Stand:** 08.11.2026  
**Branch:** `develop`  
**Status:** Zielmodell und additive Foundation-Migration erstellt und statisch geprüft. **Keine SQL-Ausführung, keine Datenbankänderung, keine Freigabe.**  
**Vorgesehene erste Zielumgebung:** ausschließlich Supabase DEV (`pzazqvvoruqnqhcorbwx`).

## 1. Verbindliche Quellen und Regeln

Fachliche Grundlage sind AP05.2 und AP05.3a–d sowie das konsolidierte UI-Konzept E05. Für Arbeitsablauf, Datenbanksicherheit und Dokumentation gelten zusätzlich die Regeln in:
- `PROJECT_CONTEXT.md`
- `docs/SUPABASE_CHANGE_CONTROL.md`
- `DB_CHANGELOG.md`
- `DB_MIGRATION_LOG.md`
- `SUPABASE_CHANGELOG.md`
- `docs/E05_SQL_AENDERUNGSPROTOKOLL.md`

Wichtig: `DB_MIGRATION_LOG.md` ist ein tatsächliches Ausführungsjournal, kein Planungsregister. Daher wird die hier vorbereitete, nicht ausgeführte Migration ausschließlich im E05-SQL-Protokoll als Vorschlag geführt. Erst nach einem tatsächlichen Ausführungsversuch wird ein DEV-Ausführungsdatensatz in `DB_MIGRATION_LOG.md` ergänzt. `DB_CHANGELOG.md` wird erst nach erfolgreicher Ausführung und Verifikation um tatsächlich vorhandene Objekte ergänzt.

## 2. Read-only geprüfte DEV-Ausgangslage

Am 08.11.2026 wurden die E05-relevanten Tabellen, Spalten, RLS-Policies und Migrationshistorie erneut abgefragt.

- `trainings`: `team_id`, nullable `season_id`, `training_date`, `status` mit `planned`, `done`, `cancelled`.
- `attendance`: Primärschlüssel `(training_id, player_id)`, Feld `present`.
- `players`: `team_id`, `active`; direkter Teamwechsel ist durch einen bestehenden Trigger gesperrt.
- `matchdays`: `team_id`, nullable `season_id`, `game_type`, `status` mit `planned`, `done`, `cancelled`.
- `clubs` und die Vereins-/Teamrollenstruktur sind vorhanden.
- `is_team_member(uuid)` und `has_selected_team_context(uuid)` sind vorhandene Sicherheitshelfer. Die neuen SELECT-Policies verwenden diese vorhandenen Regeln, statt ein eigenes Rollenmodell einzuführen.
- Die neue Migration wird nach dem aktuell in DEV vorhandenen letzten Migrationsstand `20261104143331_db_dev_009_single_team_membership_guard` eingeordnet.

Das ist eine gezielte E05-Bestandsaufnahme, kein vollständiger Datenbank-Sicherheitsaudit. Vor einer Ausführung muss der Live-Ausgangsstand erneut geprüft werden.

## 3. Technisches Zielmodell

### 3.1 Trainingsereignisse – `training_behavior_events`

Ein Datensatz je vergebener gelber Karte, roter Karte oder positivem Stern.

| Feldgruppe | Inhalt |
|---|---|
| Identität | UUID |
| Herkunft | Ursprungs-Team, Saison, Training |
| Spieler | nullable Spielerreferenz plus verpflichtender Namenssnapshot |
| Ereignis | `yellow_card`, `red_card`, `positive_star` |
| Vergabe | Begründung, vergebender Benutzer, Zeitpunkt |
| Korrektur/Storno | Stornozeitpunkt, Benutzer und Begründung |
| System | Erstellungs-/Änderungszeitpunkt |

**Warum Namenssnapshot und nullable Spielerreferenz?** Historische Ereignisse müssen erhalten bleiben, auch wenn ein Spielerprofil später gelöscht wird. Die Ereigniszeile bleibt lesbar; die optionale Spielerreferenz wird bei einer tatsächlichen Spieler-Löschung auf NULL gesetzt. Team- und Saison-ID werden als historische Werte gespeichert und bewusst nicht kaskadierend an Stammdaten gebunden.

Datenregeln:
- Gelbe/rote Karte benötigen eine Begründung; beim Stern ist sie optional.
- Maximal eine Karte gesamt (gelb oder rot) pro Spieler/Training.
- Maximal ein Stern pro Spieler/Training.
- Stornierte Ereignisse bleiben historisch erhalten und zählen nicht mehr zum aktiven Kartenkonto.
- Parallele Doppelvergaben werden durch partielle Unique-Indizes verhindert.
- Die UI zeigt im Trainings-Tab „Ereignisse“ nur anwesende Spieler. Die spätere serverseitige Vergabe-RPC muss zusätzlich Anwesenheit, aktiven Spieler, Training, Team und Saison prüfen. Eine reine UI-Filterung genügt nicht.

### 3.2 Ereignis-Audit – `training_behavior_event_audit`

Append-only-Protokoll für `created`, `corrected`, `voided`, `reinstated`. Es enthält Vorher-/Nachher-Snapshot, Begründung, Benutzer und Zeitpunkt. Direkte App-Schreibrechte werden nicht vergeben. Änderungen erfolgen später ausschließlich über geprüfte RPCs, die Audit-Einträge in derselben Transaktion schreiben.

### 3.3 Sperren – `training_suspensions`

Eigenständiger Datensatz je Sperre, mit:
- Ursprungs-Team und Saison als historische Werte,
- Spielerreferenz plus Namenssnapshot,
- Typ `yellow` oder `red`,
- Status `open`, `served`, `expired` oder `voided`,
- auslösendem Ereignis,
- vorgesehenem und tatsächlich bedientem Spieltag,
- Erstellungs-/Abschlussinformationen.

Eine Sperre wird nicht automatisch durch bloße Anzeige berechnet. Die Lifecycle-RPCs erzeugen und verwalten sie. Die fachlich beschlossene Reihenfolge (gelb vor rot, nacheinander auf tatsächlich durchgeführten relevanten Spieltagen) wird in dieser ersten Strukturmigration noch nicht aktiviert.

### 3.4 Ausnahmen – `training_suspension_exceptions`

Eine Ausnahme ist an eine konkrete Sperre und einen konkreten Spieltag gebunden. Pflichtfelder: Begründung, genehmigende Person und Zeitpunkt. Pro Sperre/Spieltag ist eine Ausnahme zulässig. Die spätere RPC verschiebt die offene Sperre unmittelbar auf den nächsten relevanten Spieltag – unabhängig davon, ob der Spieler am Ausnahmespieltag eingesetzt wird. Sie ändert weder Nominierung noch tatsächlichen Einsatz und gilt nicht als Sperrenableistung.

### 3.5 Sperren-Audit – `training_suspension_audit`

Protokolliert Erstellung, Zielspieltagänderung, Ableistung, Ablauf, Korrektur, Aufhebung und genehmigte Ausnahme jeweils mit Vorher-/Nachher-Werten, Begründung, Benutzer und Zeitpunkt.

### 3.6 Spielart-Konfiguration – `club_suspension_settings` und `team_suspension_settings`

- Clubdatensatz enthält den Standard als vollständige Liste relevanter Spieltagtypen.
- Existiert ein Teamdatensatz, ersetzt dessen Liste den Clubstandard vollständig.
- Fehlt ein Teamdatensatz, gilt der Clubstandard.
- Eine Änderung wirkt nur auf die zukünftige Sperrenberechnung, nicht rückwirkend.
- Die in der aktuellen UI verwendeten Spielarten sind Meisterschaft, Freundschaftsspiel und Turnier.

### 3.7 Vorzeitiger Sperrausgleich – `matchday_early_suspension_resets`

Separater, optionaler Trainerentscheid für einen Spieler, der für den konkreten Spieltag nicht nominiert wurde. Unabhängig von der Zahl gelber Karten. Er benötigt eine Begründung und ist zunächst `pending`. Nur wenn genau dieser Spieltag tatsächlich stattfindet, wird das aktive gelbe Kartenkonto auf null gesetzt. Bei Absage wird die Vormerkung storniert. Die Ereignishistorie bleibt unverändert; es handelt sich nicht um eine reguläre Sperrenableistung. Die spätere RPC muss Nominierung und Vormerkung atomar gegeneinander absichern.

### 3.8 Sperrausgleich-Audit – `matchday_early_suspension_reset_audit`

Append-only-Historie für Vormerkung, Anwendung, Stornierung und Korrektur inklusive Vorher-/Nachher-Snapshot und Pflichtbegründung bei Korrektur/Stornierung.

## 4. Rollen, RLS und Datenbankrechte

- Alle neun Tabellen liegen in `public` und erhalten RLS.
- Lesen folgt den vorhandenen Teammitgliedschafts- und ausgewählten Kontextregeln.
- In dieser Foundation-Migration gibt es bewusst **keine Client-Schreib-Policies**. Das verhindert, dass App-Clients vor Implementierung der vollständigen Geschäftslogik Sperren, Ausnahmen, Auditdaten oder Konfiguration direkt verändern.
- Die Vergabe, Korrektur und Stornierung von Ereignissen sowie sämtliche Sperren-/Ausnahme-/Reset-Operationen erfolgen in einer nachgelagerten Phase über eng begrenzte, geprüfte RPCs.
- Vereinsadmins bleiben lesend. Superadmins handeln nur im ausdrücklich ausgewählten Teamkontext.
- Audit- und Historienbezüge blockieren keine Löschung eines Auth-Kontos: Benutzer-IDs werden als historische UUID-Werte gespeichert, nicht als Fremdschlüssel auf `auth.users`.
- Historische Ereignisse/Sperren werden nicht per `ON DELETE CASCADE` gelöscht. Trainings- und Spieltagsreferenzen verwenden RESTRICT, um die Quelle nicht unbemerkt zu entfernen.

## 5. Lifecycle- und Empfehlungsschicht (separate Folgephase)

Die Foundation ist nur die Datenstruktur. Die folgende Geschäftslogik wird nicht vorgetäuscht und ist nicht Teil der vorbereiteten Migration:

1. Gelbe Karte: fünf aktive gelbe Karten lösen eine gelbe Sperre aus; nach Ableistung wird das aktive gelbe Kartenkonto auf null gesetzt. Vier Karten sind Warnung.
2. Rote Karte: sofortige rote Sperre; gelbes Konto bleibt unverändert.
3. Relevante Spieltage: Clubstandard mit vollständigem Team-Override; nur tatsächlich durchgeführte Spieltage zählen. Absagen zählen nicht; Verschiebungen zählen erst bei tatsächlicher Durchführung.
4. Mehrere Sperren: gelb vor rot, jeweils auf separaten relevanten Spieltagen.
5. Ausnahme: nur für konkreten Spieltag; Sperre bleibt offen und verschiebt sich unmittelbar weiter.
6. Saisonwechsel: aktives gelbes Konto zurücksetzen, offene Sperren auslaufen lassen; Historie behalten.
7. Vorzeitiger Sperrausgleich: nur nach tatsächlicher Durchführung des ausgewählten Spieltags anwenden; Absage storniert die Vormerkung.
8. Korrekturen: Grund, Benutzer, Zeitpunkt und alte/neue Werte; keine Hard Deletes; bereits bediente Sperren und abgeschlossene Einsätze werden nicht rückwirkend verändert.
9. Empfehlung: Sperr-Eligibility vor bestehender Berechnung; übrige Empfehlungslogik bleibt bestehen (Teilnahme, Aktualität, Nominierungshistorie/Fairness, begrenzter Sterne-Einfluss, Zufall bei Gleichstand). Gelbe Karten unterhalb der Schwelle und vorzeitiger Sperrausgleich verändern die allgemeine Empfehlung nicht.

## 6. Migrationsumfang und Abgrenzung

Die vorbereitete Migration `20261108000100_e05_training_events_suspensions_foundation.sql` legt neun neue Tabellen, zugehörige Indizes/Constraints, RLS-Policies und minimale SELECT-Grants an. Sie ändert keine bestehenden Tabellen, Policies, Funktionen oder Trigger und schreibt keine bestehenden Daten um.

Sie enthält noch keine:
- Schreib-RPCs und Lifecycle-Trigger,
- automatische Sperrenerzeugung oder Ableistung,
- Ausnahmen-/Saisonwechsel-/Reset-Verarbeitung,
- Sperren-Eligibility in der Kaderempfehlung,
- Frontend-Änderungen.

Diese Trennung ist bewusst: Die fachliche Geschäftslogik muss vor dem Öffnen von Schreibrechten implementiert und getestet sein.

## 7. Technische Prüfung der Migration

Ich habe den SQL-Entwurf statisch gegen die am 08.11.2026 ausgelesenen DEV-Strukturen und Sicherheitsregeln geprüft:

- referenzierte Tabellen/Primärschlüssel existieren im DEV-Bestand;
- die Migration ist additiv und enthält keine DML-Anweisung gegen bestehende Daten;
- keine bestehende Policy/Funktion/Triggerdefinition wird ersetzt;
- RLS wird auf allen neun neuen Tabellen aktiviert;
- SELECT-Policies verwenden vorhandene Sicherheitshelfer;
- es werden keine direkten INSERT-/UPDATE-/DELETE-Rechte für die neuen Historien-/Lifecycle-Tabellen erteilt;
- Ereignis-/Sperrenhistorie hat Namenssnapshots und keine kaskadierende Löschung bei Spieler-/Team-/Saisonwechsel;
- Trainings-/Spieltagquellen werden durch RESTRICT-FKs vor unbeabsichtigter Löschung geschützt;
- Auditbezüge auf Benutzer sind UUID-Snapshots, keine blockierenden Auth-FKs;
- Teamkonfiguration ist als vollständiger Override des Clubstandards modelliert.

**Prüfgrenze:** Eine statische Prüfung ersetzt keinen PostgreSQL-Laufzeittest. Die Migration wurde nicht ausgeführt. Deshalb existieren noch keine Katalog-, RLS-, ACL-, Advisor- oder Funktionstestergebnisse nach DDL. Diese können erst nach ausdrücklicher Freigabe zur DEV-Ausführung erbracht werden.

## 8. Freigabestatus

| Punkt | Status |
|---|---|
| Fachliche Basis | AP05.2 und AP05.3 abgestimmt |
| Technisches Zielmodell | erstellt |
| SQL-Migration | erstellt, statisch geprüft |
| Ziel | Supabase DEV `pzazqvvoruqnqhcorbwx` |
| Nutzerfreigabe zur Ausführung | **nicht erteilt** |
| Ausführung | **nicht erfolgt** |
| PROD | **ausgeschlossen** |
| Rollback | Vor Ausführung ist ein aktueller DEV-Backup-/Restore-Punkt zu bestätigen; kein automatisches DROP-Rollback vorgesehen |

