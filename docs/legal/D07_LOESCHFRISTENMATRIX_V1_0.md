# KadAssist – Datenschutzkonzept: Aufbewahrungs- und Löschfristenmatrix

- **Dokument-ID:** D07
- **Version:** 1.0
- **Beschlussdatum:** 17.11.2026
- **Status:** Fachlich freigegeben; juristische Abschlussprüfung und technische Umsetzung ausstehend
- **Geltungsbereich:** Alle KadAssist-Vereine

## 1. Verbindliche Produktentscheidung

Für alle KadAssist-Vereine gelten einheitliche, zentral vorgegebene Standard-Aufbewahrungs- und Löschfristen. Einzelne Vereine können diese Fristen innerhalb der Anwendung nicht individuell verlängern oder verkürzen.

Die Matrix konkretisiert den Grundsatz der Speicherbegrenzung aus Art. 5 Abs. 1 lit. e DSGVO. Die Fristen sind KadAssist-Produktstandards und keine Behauptung, dass das Gesetz für jede Datenkategorie eine feste Frist vorgibt.

## 2. Standardfristen

| Datenkategorie | Standardfrist | Fristbeginn / Auslöser | Umsetzungshinweis |
|---|---:|---|---|
| Spieler-Stammdaten | 3 volle Kalenderjahre nach Ausscheiden | Ende der Vereins-/Teamzugehörigkeit | Danach personenbezogene Daten löschen, soweit keine dokumentierte Ausnahme greift. |
| Trainingsanwesenheit und Rückmeldungen | 2 Jahre | Ende der jeweiligen Saison | Saisonbezogene Daten löschen oder irreversibel anonymisieren, sofern eine Statistik weiter benötigt wird. |
| Spieltage, Verfügbarkeit und Nominierungen | 3 Jahre | Ende der jeweiligen Saison | Personenbezug entfernen; bloßes Ausblenden des Namens reicht nicht. |
| Tatsächliche Einsätze und sportliche Historie | 3 Jahre | Ende der jeweiligen Saison | Personenbezug entfernen; nur echte Anonymisierung ist zulässig. |
| Spielerfotos und Profilbilder | 30 Tage | Ausscheiden; bei Widerruf/Löschanspruch gesondert unverzüglich prüfen | Bei Wegfall des Zwecks bzw. berechtigtem Löschverlangen früher löschen; alle Bildspeicherorte einbeziehen. |
| Spieler- und Trainer-Notizen | 12 Monate, spätestens 30 Tage nach Ausscheiden | Letzte relevante Aktualisierung bzw. Ausscheiden | Nur zweckbezogene Notizen; unnötige oder besonders sensible Inhalte vermeiden. |
| Trainer- und Mitgliederkonten | 30 Tage nach Ende der letzten Berechtigung | Ende der letzten Vereins-/Teamrolle | Berechtigungen sofort entziehen. Konto nur löschen, wenn keine weitere KadAssist-Mitgliedschaft oder legitime Kontonutzung besteht. |
| Einladungen | 90 Tage | Ablauf oder Abschluss der Einladung | Nicht mehr benötigte Einladungsdaten und Tokens löschen; Tokens bei Abschluss/Ablauf sofort ungültig machen. |
| Rollen- und Berechtigungsänderungen | 12 Monate | Zeitpunkt der Änderung | Nur erforderliche Nachweis- und Sicherheitsinformationen speichern. |
| Sicherheits- und Zugriffsprotokolle | 12 Monate | Zeitpunkt des Logeintrags | Zugriff beschränken; keine unnötigen Inhalts- oder Bewegungsprofile protokollieren. |
| Temporäre Exportdateien auf dem Server | 7 Tage | Erstellung des Exports | Automatisch löschen; heruntergeladene lokale Kopien müssen Nutzer eigenständig schützen und löschen. |
| Datenbank-Backups | maximal 35 Tage | Erstellung des Backups | Nach Ablauf überschreiben/löschen; gelöschte Daten dürfen aus Backups nicht regulär wieder verfügbar gemacht werden. |

## 3. Verbindliche Zusatzregeln

1. Fristen laufen ab dem genannten Auslöser. Für saisonbezogene Daten ist das Saisonende maßgeblich; der Saisonbezug muss zuverlässig gespeichert werden.
2. Beim Ausscheiden bzw. Ende einer Rolle werden nicht mehr benötigte Zugriffsrechte sofort entzogen. Die nachgelagerte Kontolöschfrist erlaubt keinen weiteren Zugriff.
3. Ein Benutzerkonto wird nur vollständig gelöscht, wenn keine weitere KadAssist-Mitgliedschaft, Rolle oder legitime Kontonutzung besteht. Vereins- und Teamzuordnungen sind getrennt vom globalen Benutzerkonto zu behandeln.
4. Ein Löschanspruch, wirksamer Widerruf oder Wegfall des Verarbeitungszwecks kann eine frühere Löschung erfordern. Die Standardfristen schränken Betroffenenrechte nach Art. 17 DSGVO nicht ein.
5. Eine längere Speicherung ist nur als eng begrenzte Ausnahme zulässig, wenn eine konkrete gesetzliche Aufbewahrungspflicht oder die notwendige Geltendmachung, Ausübung oder Verteidigung von Rechtsansprüchen dies rechtfertigt. Die Ausnahme ist zu dokumentieren; betroffene Daten sind zu sperren und vom normalen Sportbetrieb zu trennen.
6. Anonymisierung ist nur zulässig, wenn eine Re-Identifizierung mit vernünftigerweise verfügbaren Mitteln nicht mehr möglich ist. Pseudonymisierung oder das bloße Ausblenden eines Namens genügt nicht.
7. Für heruntergeladene JSON-Exporte auf privaten Geräten kann KadAssist die Löschung nicht technisch erzwingen. Nutzer und Vereine sind über sichere Ablage, Zweckbindung und eigenständige Löschung zu informieren.
8. Sicherungskopien dürfen nur innerhalb des festgelegten Backup-Zyklus fortbestehen. Nach einer Wiederherstellung ist ein Abgleich mit zwischenzeitlich wirksam gewordenen Löschungen vorzusehen.

## 4. Technische Abnahmekriterien

- Für jede Datenart existiert ein eindeutiger Fristauslöser und Zeitstempel (z. B. Austrittsdatum, Saisonende, letzte Aktualisierung, Ablaufdatum).
- Ein zentraler, regelmäßig ausgeführter Löschprozess ermittelt fällige Datensätze, berücksichtigt dokumentierte Ausnahmen und führt Löschungen sicher aus.
- Alle Speicherorte werden einbezogen: relationale Datensätze, Bildspeicher/Buckets, verknüpfte Dateien, Einladungs-Tokens, temporäre Exporte und Backups.
- Fremdschlüssel und abhängige Datensätze werden berücksichtigt; Löschungen dürfen keine ungewollten Datenreste oder inkonsistenten Verweise erzeugen.
- Löschläufe werden datensparsam protokolliert (z. B. Laufzeit, Kategorie, Anzahl, Ergebnis/Fehler), ohne gelöschte Inhalte erneut zu speichern.
- Fehlerfälle, Sperren/Legal Holds und Wiederherstellungen aus Backups erhalten einen dokumentierten Prozess.
- Vor PROD-Einsatz erfolgen DEV-Tests mit Testdaten: Frist noch nicht erreicht, Frist erreicht, frühzeitiger Löschanspruch, Ausnahme/Sperre, verknüpfte Fotos/Dateien, Backup-Wiederherstellung sowie Mehrfachvereins-/Teamkonstellationen.
- Die Umsetzung benötigt eine gesonderte Freigabe. Diese Matrix genehmigt weder SQL-Änderungen noch Migrationen oder PROD-Eingriffe.

## 5. Rechtliche und organisatorische Einordnung

Handels- und steuerrechtliche Aufbewahrungspflichten gelten nur für die jeweils erfassten Unterlagen und nicht pauschal für Trainingsanwesenheiten, Spielerfotos oder sportliche Historien. Die Verantwortlichkeit des jeweiligen Vereins und die Pflichten des Betreibers sind in Datenschutzerklärung und Auftragsverarbeitungsvertrag konsistent abzubilden.

## 6. Freigabestatus

Die fachlichen Standardfristen wurden am 17.11.2026 freigegeben. Die Matrix ist damit die fachliche Zielvorgabe für alle KadAssist-Vereine. Eine abschließende juristische Prüfung, technische Implementierung und DEV-Abnahme stehen noch aus. Bis dahin dürfen die Fristen nicht als automatisiert umgesetzt oder abschließend rechtlich geprüft dargestellt werden.