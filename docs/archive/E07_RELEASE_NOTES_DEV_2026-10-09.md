# Kaderkompass – E07 DEV-Test- und Release-Notiz

**Stand:** 09.10.2026  
**Umgebung:** DEV  
**PROD:** unverändert; keine Freigabe zur Übernahme

## Aktueller Frontendstand

`index01(2)_e07_training_title_fix_v10_DEV.html`

## Erfolgreich getestete Bereiche

- Trainingsserie anlegen und Vorschau anhand Zeitraum, Wochentagen, Startzeit und Dauer aktualisieren.
- Einzeltermine individuell ändern; Overrides bleiben bei Serienänderungen erhalten.
- Zukünftige Serienwerte ändern, Wochentage ändern und Zeitraum verkürzen.
- Nachfolgende Termine löschen, ohne ausgewählten/vorherige Termine aus der Serie zu lösen.
- Rückmeldungen und tatsächliche Anwesenheit speichern und unabhängig voneinander korrigieren.
- Trainer können eigene Teilnahme und Teilnahme der Kollegen erfassen.
- Abgesagte Termine vollständig aus Teilnahmeberechnungen ausschließen.
- Geplante Termine ohne Anwesenheit nicht vorzeitig mitzählen; vorzeitig bestätigte Anwesenheit sofort berücksichtigen.
- Trainingsname in Übersicht/Detail darstellen; ohne eigenen Namen Standardtitel verwenden.

## Offen

- Optionsmenü der Trainingsdetailseite mit Aktionen „Bearbeiten“, „Absagen“, „Als durchgeführt markieren“ und „Löschen“.
- Vorhandensein eines `set_updated_at`-Triggers für `training_series.updated_at` abschließend verifizieren.
- PROD-Schema und SQL-Migrationen separat abgleichen; keine automatische Übernahme aus DEV.

## Datenbankänderungen

- DB-DEV-003: Trainingsserien, Trainingsfelder und persistente Trainings-Rückmeldungen.
- DB-DEV-004: `training_series.name`, `trainings.overrides` (JSONB) und `trainings_overrides_object_chk`.
- Beide Änderungen sind DEV-only und nicht nach PROD übertragen.
