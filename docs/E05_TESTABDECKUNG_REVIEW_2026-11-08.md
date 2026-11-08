# E05 / AP05 – Testabdeckungs- und Schema-Review

**Prüfdatum:** 08.11.2026  
**Branch:** `develop`  
**Geprüfter Schemaentwurf:** `docs/E05_SCHEMA_MIGRATION_DRAFT_2026-11-08.sql`, Revision 4  
**Geprüfte Assertions:** `docs/e05-test/assertions.sql`  
**Testumgebung:** isolierter GitHub-Actions-Container, PostgreSQL 17.6; keine Verbindung zu Supabase  
**Ergebnis:** Schemafundament technisch erfolgreich getestet; fachliche AP05-Abdeckung noch unvollständig  
**Freigabestatus:** Review-Dokumentation, keine Migrationsfreigabe

## 1. Verifizierter Testlauf

Der dedizierte Workflow „E05 schema draft – isolated PostgreSQL test“ lief als Run **#17** auf Commit `b9b33c29d1ba8380c1c8fe28ba71d2a7855f6953` erfolgreich durch.

- Job `postgres-17`: `success`
- PostgreSQL-Dienst: `postgres:17.6`
- Test-Fixture aufgebaut: erfolgreich
- SQL-Entwurf angewendet: erfolgreich
- Assertions ausgeführt: erfolgreich
- Workflow: [Run #17](https://github.com/bautnhaus/jugendmannschaft/actions/runs/42471593970)

Der spätere Commit `ce9e2badd572944cdbb84f132cd988016ec463c3` ergänzt die DEV-Abgleich-/Review-Dokumentation. Der Commit änderte nicht den getesteten SQL-Entwurf oder die Assertions. Der erfolgreiche Run #17 bleibt damit für den unveränderten SQL- und Assertion-Stand aussagekräftig.

## 2. Was der aktuelle PostgreSQL-Test tatsächlich abdeckt

| Bereich | Geprüfter Inhalt | Ergebnis |
|---|---|---|
| Schema | Vorhandensein aller 10 AP05-Tabellen | Bestanden |
| RLS | RLS auf allen 10 Tabellen aktiviert | Bestanden |
| Policies | Genau eine SELECT-Policy je Tabelle; Rolle/Operation geprüft | Bestanden |
| ACL | authenticated: SELECT, keine direkten Schreibrechte; anon: kein Zugriff; service_role: SELECT, keine direkten Schreibrechte | Bestanden |
| Triggerfunktion | Keine direkte EXECUTE-Berechtigung für API-Rollen | Bestanden |
| Ereignis-Constraints | Karte und Stern dürfen koexistieren; doppelte aktive Karte bzw. doppelter aktiver Stern je Spieler/Training werden verhindert | Bestanden |
| Sperr-Referenz | Eine Sperre je Quellereignis | Bestanden |
| Ausnahmen | Aktive Ausnahme je Sperre/Spieltag eindeutig; widerrufene Ausnahme kann ersetzt werden | Bestanden |
| Historische Snapshots | Matchday-, Trainings-, Spieler- und Actor-Snapshots überstehen Löschung der operativen Datensätze | Bestanden |
| Audit | UPDATE/DELETE/TRUNCATE auf den drei Audit-Tabellen werden blockiert | Bestanden |
| Team- und Vereinskontext | Teammitglied, Nichtmitglied, Vereinsadmin ohne/mit ausgewähltem Vereinskontext | Bestanden im vereinfachten Test-Fixture |

Die Test-Fixture bildet Supabase-Funktionen und Rollen nur vereinfacht nach. Sie ist kein Ersatz für einen Live-DEV-RLS-Test gegen die echten Rollenfunktionen und Policies.

## 3. Abgleich mit den freigegebenen AP05-Entscheidungen

| Fachliche Entscheidung | Status im aktuellen Schema/Test | Bewertung |
|---|---|---|
| Gelb/Rot mit Pflichtbegründung; Stern mit optionaler Begründung | Tabellen-Constraint vorhanden; Pflichtfeld-Positiv-/Negativfälle nicht vollständig separat getestet | Teilweise |
| Maximal eine Karte (Gelb oder Rot) je Spieler/Training; ein Stern je Spieler/Training; Karte + Stern möglich | Durch Unique-Indizes und Tests abgedeckt | Abgedeckt |
| Ereignisse einzeln speichern; Storno statt Löschen; Historie erhalten | Ereignisstatus/Snapshot und Audit-Grundlage vorhanden; vollständiger Korrektur-/Reaktivierungsprozess fehlt | Teilweise |
| Fünf aktive gelbe Karten lösen eine Sperre aus; nach Erfüllung gelbe Bilanz auf null | Keine Zähl-/Auslöse-/Rücksetzlogik im Schemafundament; nicht getestet | Offen |
| Rote Sperre unabhängig von gelber Bilanz | Datentypen vorhanden; fachlicher Ablauf nicht implementiert/getestet | Offen |
| Mehrere Sperren nacheinander bedienen, Gelb vor Rot | Mehrere offene Sperren speicherbar; keine Serving-Orchestrierung oder Reihenfolgelogik | Offen |
| Nur tatsächlich durchgeführte relevante Spieltage bedienen Sperren; Absage zählt nicht | Matchday-Snapshot vorhanden; Status-/Spielart-Lifecycle fehlt | Offen |
| Teamwechsel belässt Historie bei ursprünglichem Team/Saison | Team-/Saison-Snapshots vorhanden; Verhalten bei Teamwechsel nicht fachlich getestet | Teilweise |
| Saisonwechsel setzt aktive gelbe Bilanz zurück und lässt Historie bestehen; offene Sperren verfallen | Keine Lifecycle-Funktion; nicht getestet | Offen |
| Ausnahme für einen konkreten Spieltag, Pflichtgrund, Sperre bleibt offen und verschiebt sich | Ausnahmetabelle vorhanden; Verschiebungslogik und Berechtigungsprüfung fehlen | Teilweise |
| Manuelle Sperrenkorrektur mit Audit, keine Rücknahme bereits bedienter Sperren | Audit-Tabelle vorhanden; Korrektur-RPC und Zustandsregeln fehlen | Offen |
| Vereinsvorgabe für relevante Spielarten; vollständiger Team-Override inkl. leerer Liste | Datenmodell für Club-Default und Team-Override vorhanden; leerer Override im Test abgebildet | Teilweise |
| Vorzeitiger Sperrausgleich unabhängig von gelber Kartenanzahl; nur für konkreten nicht nominierten Spieler/Spieltag | Pending-/Applied-/Cancelled-Grundstruktur vorhanden; Regelprüfung, Ausführung und Storno-Lifecycle fehlen | Teilweise |
| Vorzeitiger Sperrausgleich wird erst nach tatsächlich durchgeführtem Spieltag wirksam | Keine Ausführungslogik; nicht getestet | Offen |
| Bei Nominierung oder Absage wird vorgemerkter Ausgleich storniert; Historie bleibt | Statusfelder vorhanden; automatische Stornoauslöser fehlen | Offen |
| Empfehlung: Teilnahme, Aktualität, Nominierungshistorie, Sterne aus letzten sechs durchgeführten Trainings; Sperren ausschließen | Kein Bestandteil des Schemafundaments; muss im bestehenden Empfehlungsalgorithmus umgesetzt und separat getestet werden | Nicht Bestandteil dieses SQL-Tests |
| Trainerberechtigungen, serverseitige Schreibautorisierung, atomare Audit-Schreibvorgänge | Direkte API-Schreibrechte entzogen; künftige RPCs noch nicht enthalten | Offen |
| Korrekturen/Storno mit Pflichtgrund, Nutzer, Zeitpunkt und alten/neuen Werten | Audit-Struktur vorhanden; vollständige RPC-/Audit-Kopplung fehlt | Teilweise |

## 4. Technische Review-Befunde und Grenzen

1. **Das geprüfte SQL ist ein Schemafundament, keine vollständige AP05-Implementierung.** Es legt Tabellen, Constraints, Indizes, SELECT-RLS und Audit-Schutz an. Die fachlichen Abläufe müssen über gesondert geprüfte serverseitige Funktionen/RPCs ergänzt werden.
2. Die Test-Fixture ersetzt die produktiven Hilfsfunktionen `is_team_member`, `has_selected_team_context` und `can_manage_club_context` durch vereinfachte Testfunktionen. Daher belegt der Test nicht die vollständige Integration mit dem realen DEV-Rollenmodell.
3. Die Testdatei prüft Tabellen-/Policy-Anzahlen und ausgewählte ACL-Eigenschaften. Sie ist keine vollständige Prüfung aller Spalten-Constraints, Triggerdefinitionen, Fremdschlüssel, Funktionen oder tatsächlichen RLS-Pfade.
4. Die Schemaentwurfsdatei enthält `BEGIN`/DDL, ist aber weiterhin ein Review-Artefakt unter `docs/`, keine ausführbare Supabase-Migration. Sie wurde ausschließlich im wegwerfbaren PostgreSQL-Container getestet.
5. Es gab frühere fehlgeschlagene Workflow-Runs während der Syntax-/Assertion-Korrekturen. Maßgeblich ist Run #17 mit vollständig erfolgreichem Job und allen sieben erfolgreichen Arbeitsschritten.

## 5. Nächste notwendige Schritte – ohne Wiederholung bereits bestandener Tests

1. Die fehlenden fachlichen Regeln in konkrete serverseitige Zustandsübergänge/RPC-Verträge übersetzen: Ereignisvergabe/Korrektur, Sperrenauslösung und -bedienung, Ausnahme, Saisonabschluss, Spieltagsabschluss/Absage und vorzeitiger Sperrausgleich.
2. Für jede Zustandsübergangsregel Positiv-, Negativ-, Grenz- und Wiederholungs-/Parallelitätsfälle definieren.
3. Erst danach die notwendigen Schema-/RPC-Ergänzungen als neue Review-Revision erstellen; bestehende geprüfte Tabellen und Tests nicht unnötig neu aufbauen.
4. Syntaxprüfung vor dem PostgreSQL-Lauf ausführen; anschließend den isolierten PostgreSQL-17.6-Workflow erneut laufen lassen.
5. Echte DEV-Rollen-/RLS-Prüfungen separat read-only vorbereiten. Keine Supabase-Schreiboperation ohne vorherige explizite Freigabe.

## 6. Änderungs- und Freigabegrenze

- Keine SQL-Ausführung in Supabase DEV oder PROD im Rahmen dieses Reviews.
- Keine Änderung an `main`, PROD, Auth, Edge Functions oder bestehenden Daten.
- Keine Migration ist freigegeben.
- Die vorhandenen SQL- und Testdateien bleiben unverändert; dieses Dokument ergänzt ausschließlich den Review-Nachweis.
