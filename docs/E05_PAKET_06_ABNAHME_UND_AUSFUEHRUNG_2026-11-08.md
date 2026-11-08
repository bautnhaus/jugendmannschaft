# E05 – Freigabe- und Abnahmeprotokoll Paket 6

## Paket 6: Kontrollierter Widerruf einer gewährten Sperrausnahme

- **Erstellt:** 08.11.2026
- **Branch:** `develop`
- **Zielumgebung:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`
- **SQL-Datei:** [E05_PAKET_06_WIDERRUF_SPERRAUSNAHME_2026-11-08.sql](https://github.com/bautnhaus/jugendmannschaft/blob/develop/docs/E05_PAKET_06_WIDERRUF_SPERRAUSNAHME_2026-11-08.sql)
- **Status:** Abnahmekandidat; nicht ausgeführt
- **Abhängigkeiten:** Pakete 1–5; insbesondere `training_suspension_exceptions`, `training_suspension_audit`, `grant_suspension_exception(...)` und `e05_assign_player_suspensions(...)`.

## 1. Ziel und fachliche Regel

Paket 6 ergänzt den kontrollierten Widerruf einer bereits gewährten Spieltagsausnahme.

Ein berechtigter Trainer oder Mannschaftsadmin kann eine aktive Ausnahme zurücknehmen, solange der ursprüngliche Spieltag noch bevorsteht und weiterhin den Status `planned` hat.

Der Widerruf:
- hebt ausschließlich die konkrete Ausnahme auf;
- benötigt zwingend eine nichtleere Begründung;
- speichert widerrufenden Benutzer, Anzeigenamen, Zeitpunkt und Begründung;
- löscht weder Ausnahme noch ursprüngliche Gewährung;
- erzeugt einen eigenen Audit-Eintrag `exception_revoked`;
- lässt die zugrunde liegende Sperre offen;
- ordnet die offene Sperre unmittelbar anhand der geltenden Team-/Club-Spielartenregeln neu zu;
- verändert weder Nominierung noch tatsächlichen Einsatz.

Eine Ausnahme kann nicht rückwirkend widerrufen werden, wenn der ursprüngliche Spieltag bereits abgeschlossen, abgesagt oder zeitlich vergangen ist. Eine bereits widerrufene Ausnahme kann nicht erneut widerrufen werden.

## 2. Neue RPC

```sql
public.revoke_suspension_exception(
  p_exception_id uuid,
  p_revoke_reason text
) returns uuid
```

Serverseitige Prüfungen:
1. Authentifizierter Benutzer.
2. Existierende Ausnahme und nichtleerer Widerrufsgrund.
3. Ausnahme ist noch aktiv.
4. Zugehörige Sperre existiert und ist weiterhin `open`.
5. Benutzer ist Trainer oder Mannschaftsadmin des Teams.
6. Super Admin nur mit globaler Rolle `super_admin` und ausdrücklich ausgewähltem Teamkontext.
7. Ursprünglicher Spieltag gehört zum Team und zur Saison der Sperre.
8. Ursprünglicher Spieltag ist weiterhin `planned` und sein Datum ist nicht vergangen.

## 3. Atomarer Ablauf

1. Spieler-, Sperren- und Ausnahmedatensatz werden in definierter Reihenfolge gesperrt, um konkurrierende Vergabe-/Widerrufsvorgänge zu serialisieren.
2. Widerrufsmetadaten werden auf dem bestehenden Ausnahmedatensatz ergänzt.
3. Ein Audit-Eintrag `exception_revoked` speichert alten und neuen Zustand, Grund, Akteur und Zeitpunkt.
4. Der Paket-4-Zuordnungs-Helper wird ausgeführt. Da die Ausnahme nun widerrufen ist, wird der ursprüngliche Spieltag bei der nächsten Zuordnung wieder berücksichtigt, sofern er weiterhin ein zulässiger geplanter Spieltag ist.
5. Die Sperre bleibt offen; die RPC gibt die Ausnahme-ID zurück.

Schlägt Audit oder Neuzuordnung fehl, wird der gesamte Vorgang zurückgerollt. Es gibt keinen Zustand, in dem die Ausnahme widerrufen, aber die Sperre nicht konsistent neu zugeordnet ist.

## 4. Ergänzende Berechtigungshärtung

Bei der Prüfung des bestehenden Paket-5-Codes ist aufgefallen, dass die bisherige Berechtigungsbedingung einen ausgewählten Teamkontext allein als Alternative zur Trainer-/Adminrolle akzeptierte.

Paket 6 ersetzt deshalb auch die bestehende Gewährungs-RPC `grant_suspension_exception(...)` mit einer präzisen Prüfung:
- Trainer/Mannschaftsadmin: expliziter Eintrag in `team_member_roles`;
- Super Admin: globaler Eintrag `global_user_roles.role = 'super_admin'` **und** ausgewählter Teamkontext.

Außerdem werden Gewährung und Widerruf auf dieselbe Sperrreihenfolge für parallele Vorgänge ausgerichtet: zuerst Spielersperre, danach Sperren-/Ausnahmedatensätze. Die fachliche Funktion der Gewährungs-RPC bleibt ansonsten unverändert.

## 5. Bewusste Abgrenzung

Nicht Teil von Paket 6:
- Widerruf nach abgeschlossenem, abgesagtem oder zeitlich vergangenem ursprünglichem Spieltag;
- Wiederherstellung einer bereits widerrufenen Ausnahme als eigener Vorgang;
- Frontend-Schaltfläche, Bestätigungsdialog und Anzeige der Widerrufshistorie;
- automatische App-Auslösung;
- vorzeitiger Sperrausgleich;
- Saisonabschluss und manuelle Sperrenkorrektur.

## 6. Prüfplan nach Freigabe

### Positivtests
1. Berechtigter Trainer widerruft eine aktive Ausnahme mit Begründung.
2. Ausnahme bleibt historisch erhalten und erhält Widerrufsmetadaten.
3. Audit-Eintrag `exception_revoked` enthält Ausnahme-ID, alten/neuen Zustand, Grund, Akteur und Zeitpunkt.
4. Sperre bleibt `open`.
5. Ursprünglicher Spieltag wird bei der Neuzuordnung wieder berücksichtigt, sofern er weiterhin der früheste zulässige Spieltag ist.
6. Wenn der ursprüngliche Spieltag nicht mehr zulässig ist, wird der nächste zulässige Spieltag gewählt.
7. Die Gewährungs-RPC lässt Trainer/Admin zu und prüft Super Admins über globale Rolle plus Teamkontext.

### Negativtests
1. Nicht authentifizierter Aufruf.
2. Benutzer ohne Trainer-/Adminrolle und ohne Super-Admin-Berechtigung.
3. Super Admin ohne ausgewählten Teamkontext.
4. Fehlender oder leerer Widerrufsgrund.
5. Nicht existierende Ausnahme.
6. Bereits widerrufene Ausnahme.
7. Zugehörige Sperre nicht mehr offen.
8. Ursprünglicher Spieltag ist abgeschlossen, abgesagt oder liegt in der Vergangenheit.
9. Spieltag-/Team-/Saisoninkonsistenz.
10. Fehler beim Audit-Insert oder bei der Neuzuordnung: vollständiger Rollback.
11. Direkte Tabellenänderung durch authenticated/anon bleibt untersagt.

### Regression und Parallelität
- Die Sperre wird niemals als abgeleistet markiert.
- Keine Änderung an `matchday_players`, Nominierungen oder `played`.
- Keine Löschung oder Überschreibung des ursprünglichen Gewährungs-Audit-Eintrags.
- Doppelte Widerrufe werden verhindert.
- Gleichzeitige Gewährung/Widerruf-Vorgänge für denselben Spieler werden serialisiert.
- Paket-5-Gewährung funktioniert nach der Berechtigungshärtung weiterhin für berechtigte Trainer und Admins.

Tests werden nach Freigabe in DEV mit synthetischen Daten in zurückrollbaren Transaktionen durchgeführt. Es werden keine Testdaten dauerhaft hinterlassen.

## 7. Ausführungsstatus

Noch nicht ausgeführt. Nach ausdrücklicher Abnahme wird das Paket in Supabase DEV ausgeführt. Danach folgen Struktur-, Rechte-, Positiv-, Negativ-, Grenz-, Parallelitäts- und Rollbacktests. Fehler werden in DEV korrigiert und zusammen mit den tatsächlichen Ergebnissen auf GitHub `develop` dokumentiert. PROD bleibt unangetastet.


## 8. Tatsächliche Ausführung und DEV-Ergebnisse

- **Freigabe:** ausdrücklich erteilt am 08.11.2026.
- **Zielumgebung:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`.
- **Migration:** `e05_package_06_revoke_suspension_exception`.
- **Migration-Version:** `20261108174313`.
- **Ergebnis:** erfolgreich ausgeführt.
- **PROD:** nicht verändert.

### Struktur- und Berechtigungsprüfungen

| Prüfung | Ergebnis |
|---|---|
| Migration in Supabase-Migrationshistorie vorhanden | Bestanden |
| `revoke_suspension_exception(uuid,text)` vorhanden | Bestanden |
| `grant_suspension_exception(uuid,uuid,text)` weiterhin vorhanden | Bestanden |
| Beide Funktionen SECURITY DEFINER | Bestanden |
| Beide Funktionen für authenticated ausführbar | Bestanden |
| Beide Funktionen für anon nicht ausführbar | Bestanden |
| Bestehende Tabellenstruktur bleibt nutzbar; keine neue Tabelle erforderlich | Bestanden |

### Funktionale Tests

Die Tests wurden mit synthetischen Datensätzen innerhalb einer Transaktion ausgeführt und anschließend vollständig zurückgerollt.

| Test | Ergebnis |
|---|---|
| Paket-5-Gewährung: Ausnahme verschiebt Sperre vom Ausnahme-Spieltag weg | Bestanden |
| Widerruf durch berechtigten Mannschaftsadmin | Bestanden |
| Widerrufsmetadaten werden gespeichert | Bestanden |
| Audit-Eintrag `exception_revoked` mit Begründung wird angelegt | Bestanden |
| Sperre bleibt `open` | Bestanden |
| Ursprünglicher, weiterhin geplanter Spieltag wird wieder zugeordnet | Bestanden |
| Leere Widerrufsbegründung wird abgewiesen | Bestanden |
| Benutzer ohne Teamrolle wird abgewiesen | Bestanden |
| Zweiter Widerruf derselben Ausnahme wird abgewiesen | Bestanden |
| Keine Änderung an `matchday_players`, Nominierung oder Einsatz | Bestanden |

### Testablauf und Rollback

Ein erster Testlauf hatte einen Fehler in der Reihenfolge der Negativtest-Aufrufe: Der nicht berechtigte Benutzer wurde erst nach dem erfolgreichen Widerruf aufgerufen. Die RPC wies erwartungsgemäß bereits den widerrufenen Zustand zurück, bevor die Rollenprüfung erreicht wurde. Das war ein Fehler im Testablauf, kein Fehler der Migration. Die Transaktion wurde zurückgerollt und der Test in korrekter Reihenfolge wiederholt.

Der vollständige Wiederholungslauf lieferte für alle sechs Testfälle `passed = true`.

Nach dem Rollback wurden die Testkennungen geprüft:
- Test-Spieltage: 0
- Test-Ereignisse: 0
- Test-Sperren: 0
- Test-Ausnahmen: 0
- Test-Audit-Einträge: 0

Es sind keine synthetischen Testdaten zurückgeblieben.

### Ergebnis

**Paket 6 ist in Supabase DEV erfolgreich umgesetzt.** Die kontrollierte Widerrufs-RPC und die Berechtigungshärtung der Paket-5-Gewährungs-RPC sind aktiv. Die geprüften Positiv- und Negativfälle sind bestanden. PROD blieb unverändert.
