# KadAssist – Entscheidungsregister Datenschutz

Stand: 17.11.2026

Dieses Register hält die fachlichen Datenschutzentscheidungen fest. Es ersetzt weder die vollständigen Rechtsdokumente noch eine juristische Prüfung.

## T01 – Einheitliche private Bildspeicherung

- **Entscheidung:** Alle relevanten Bilder in KadAssist sollen einheitlich in privaten Storage-Buckets gespeichert werden.
- **Zielverhalten:** Kein öffentlicher Dateizugriff; Zugriff nur nach Berechtigungsprüfung, Bildauslieferung bei Bedarf über zeitlich begrenzte signierte URLs.
- **Status:** Fachlich entschieden, technisch nicht umgesetzt.
- **Grenze:** Keine Bucket-, Policy-, Storage- oder Codeänderung durch diese Dokumentation.

## T02 – Einheitliche Standard-Aufbewahrungs- und Löschfristen

- **Entscheidung:** Für alle KadAssist-Vereine gelten einheitliche, zentral vorgegebene Standardfristen.
- **Konfiguration:** Keine vereinsindividuellen Fristabweichungen innerhalb der Anwendung.
- **Konkretisierung:** Die Standardfristen werden je Datenkategorie in D07 geführt.
- **Status:** Fachlich entschieden und durch Freigabe der Matrix Version 1.0 am 17.11.2026 konkretisiert.

## D07 – Löschfristenmatrix Version 1.0

- **Freigabe:** Nutzerfreigabe am 17.11.2026.
- **Geltung:** Einheitliche Zielvorgabe für alle KadAssist-Vereine.
- **Fristen:** Spieler-Stammdaten 3 volle Kalenderjahre nach Ausscheiden; Trainingsanwesenheit/Rückmeldungen 2 Jahre nach Saisonende; Spieltags-/Verfügbarkeits-/Nominierungs- und Einsatzhistorien 3 Jahre nach Saisonende; Fotos/Profilbilder 30 Tage nach Ausscheiden; Notizen 12 Monate seit letzter relevanter Aktualisierung, spätestens 30 Tage nach Ausscheiden; Konten 30 Tage nach Ende der letzten Berechtigung; Einladungen 90 Tage; Rollen-/Berechtigungs- und Sicherheitsprotokolle 12 Monate; temporäre Server-Exporte 7 Tage; Datenbank-Backups maximal 35 Tage.
- **Ausnahmen:** Früheres Löschen bei wirksamem Löschanspruch, Widerruf oder Wegfall des Zwecks; eng begrenzte dokumentierte und gesperrte Ausnahmen bei konkreten gesetzlichen Pflichten oder Rechtsansprüchen.
- **Status:** Fachlich freigegeben; juristische Abschlussprüfung und technische Umsetzung/DEV-Abnahme ausstehend.

## Verbindliche Projektgrenzen

- Dokumentationspflege erfolgt zunächst ausschließlich auf develop.
- main/PROD wird erst nach regulärem, ausdrücklich freigegebenem Releaseprozess aktualisiert.
- Keine SQL-Ausführung, Migration, Supabase-Änderung oder Codeänderung durch die vorliegende Dokumentation.
- Automatische Löschung ist nicht als umgesetzt zu bezeichnen, bevor Implementierung und Tests abgeschlossen sind.