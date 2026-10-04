# Kaderkompass – Datenbankänderungsprotokoll DEV

**Stand:** 04.10.2026  
**Umgebung:** Supabase DEV  
**Zweck:** Nachweis der in DEV vorgenommenen Datenbankänderungen als Grundlage für einen späteren kontrollierten PROD-Rollout. Dieses Dokument beschreibt nur den hier nachvollziehbar belegten Änderungsumfang; es ersetzt keinen vollständigen Schema-/Policy-Abgleich.

## Änderung DB-DEV-001 – Schutz des letzten Administrators (E16.2)

- **Status:** in DEV implementiert und funktional getestet
- **Betroffene Tabelle:** `public.team_members`
- **Neue Funktion:** `public.prevent_last_team_admin_removal()`
- **Neuer Trigger:** `prevent_last_team_admin_removal`
- **Triggerereignisse:** `AFTER DELETE OR UPDATE`, je Zeile
- **Ausführung:** `DEFERRABLE INITIALLY DEFERRED`
- **Funktionseigenschaften:** `SECURITY DEFINER`; Suchpfad `pg_catalog, public`
- **Rechte:** EXECUTE für `PUBLIC`, `anon` und `authenticated` entzogen

### Zweck und Verhalten

Verhindert auf Datenbankebene, dass die letzte Admin-Mitgliedschaft eines bestehenden Teams gelöscht oder herabgestuft wird. Die Schutzregel berücksichtigt, dass eine vollständige Teamlöschung die zugehörigen Mitgliedschaften ebenfalls entfernen kann. Der Schutz ist nicht allein von der Frontend-Prüfung abhängig.

### Verifikation / Tests

1. Trigger-Metadatenabfrage bestätigte einen aktiven Trigger, `DEFERRABLE`, `INITIALLY DEFERRED` und eine `SECURITY DEFINER`-Funktion.
2. Testtransaktionen zur Entfernung bzw. Herabstufung von Admin-Mitgliedschaften wurden in DEV durchgeführt und zurückgerollt; der Adminbestand blieb bestehen.
3. Ein realer Löschversuch des einzigen Admin-Kontos über die DEV-App wurde von der Datenbank mit der erwarteten Meldung abgewiesen: „Die letzte Admin-Mitgliedschaft einer Mannschaft kann nicht entfernt oder herabgestuft werden“.
4. Die anschließende Kontrolle bestätigte, dass alle drei Teammitgliedschaften erhalten blieben. Die Testrollen wurden anschließend wieder auf zwei Admins und einen Trainer gesetzt.
5. Kein gesonderter Parallelitätstest mit gleichzeitig laufenden Transaktionen erfolgt.

### PROD-Rollout – ausdrücklich noch nicht erfolgt

- Diese Änderung wurde ausschließlich in Supabase DEV vorgenommen.
- Vor PROD muss der exakte, tatsächlich in DEV ausgeführte DDL-Text der Funktion und des Triggers aus der Datenbankdefinition exportiert und als versionierte SQL-Migration abgelegt werden. Der vorliegende Eintrag ist eine technische Beschreibung, **kein ausführbares SQL-Migrationsskript**.
- Vor Anwendung in PROD ist der dortige Schema-, Funktions-, Trigger- und Rechtebestand separat zu prüfen. Erst nach DEV-Abgleich, Review und ausdrücklicher Freigabe darf die Migration kontrolliert in PROD umgesetzt und getestet werden.

## Änderung DB-DEV-002 – Erweiterung der Spielerstammdaten (E03)

- **Umgebung:** ausschließlich Supabase DEV
- **Status:** als Bestandteil des in DEV umgesetzten Spielerprofils dokumentiert; konkrete DDL-/Migrationshistorie noch nicht vollständig rekonstruiert
- **Betroffenes Datenbankobjekt:** `public.players`
- **Fachliche Erweiterungen:** Geburtsjahr und bevorzugter Fuß (links/rechts/beidfüßig)
- **Datenvalidierung:** Für `players` sind Constraints für Geburtsjahr und bevorzugten Fuß im bisherigen DEV-Schemaüberblick dokumentiert.
- **PROD:** nicht als nach DEV geprüfte Migration bestätigt; PROD-Schema muss separat geprüft werden.

### Zweck und Verhalten

Die Spielerstammdaten wurden um das **Geburtsjahr** (nicht das vollständige Geburtsdatum) und den **bevorzugten Fuß** (links, rechts oder beidfüßig) erweitert. Diese Angaben gehören zum Epic E03 „Spielerprofil & Spielerstammdaten“. Die Dokumentation des DEV-Datenmodells nennt entsprechende Constraints auf `public.players`.

### Nachweisgrenze und nächste Schritte

Die bisher vorliegenden Arbeitsnotizen bestätigen die fachlichen Felder und die DEV-Umsetzung des Spielerprofils, enthalten aber nicht den exakten SQL-Änderungstext bzw. die vollständige Reihenfolge der damaligen Schemaänderungen. Daher ist dieser Eintrag ein **Bestands- und Änderungsnachweis, keine ausführbare SQL-Migration**. Vor einer PROD-Übernahme müssen die tatsächliche DEV-Tabellendefinition, Datentypen, NULL-Regeln, erlaubte Werte und Constraint-Definitionen aus Supabase ausgelesen und als versioniertes SQL festgehalten werden. Anschließend ist der PROD-Bestand separat abzugleichen.

## Änderungsregister

| ID | Änderung | Umgebung | Status | PROD |
|---|---|---|---|---|
| DB-DEV-001 | Letzten Team-Admin gegen Entfernen/Herabstufen absichern | DEV | Funktional getestet | Nicht übertragen |

## Pflegekonvention

Jede Datenbankänderung erhält eine eindeutige ID, Datum, Umgebung, betroffene Objekte, Zweck, vollständiges versioniertes SQL, Ausführungsergebnis, Tests und Rolloutstatus. DEV und PROD erhalten getrennte Bestandsdokumente bzw. klar getrennte Umgebungsabschnitte. Eine DEV-Migration gilt nie automatisch als in PROD angewendet. Keine Zugangsdaten, Tokens oder Service-Role-Keys dokumentieren.
