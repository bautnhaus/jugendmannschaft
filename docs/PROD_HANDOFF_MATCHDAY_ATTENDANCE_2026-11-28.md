# PROD-Handoff – Hotfix Spieltags-Teambildung nach Anwesenheit
**Datum:** 28.11.2026  
**Status:** PROD erfolgreich deployed und bestätigt durch Nutzer

## Ablauf
- DEV-Korrektur umgesetzt und durch Nutzer erfolgreich getestet: Spieltagsteams enthalten nur tatsächlich anwesende Spieler.
- Isolierter Hotfix-Branch auf Basis von `main` erstellt: `hotfix/matchday-attendance-2026-11-28`.
- PR #8 gezielt in `main` gemergt: `844536a3a01d55a83d7d608fd63f961689607519`.
- Historischen `Main Deploy`-Workflow aus Git-Historie wiedergefunden (Commit `471596887dd71ecf9ded70a8fdcd1f43344bfa05`) und mit PR #9 wiederhergestellt.
- PR #9 in `main` gemergt: `6d8881831e08042a630d7f5d1a11c592565860ba`.
- Nutzer hat `Main Deploy` manuell gestartet und erfolgreichen Lauf bestätigt.

## Ergebnis / Sicherheitsgrenze
- PROD veröffentlicht den aktuellen freigegebenen `main`-Stand mit Attendance-Hotfix.
- Kein Backup-/Restore-Stand aus `develop` wurde übernommen.
- Kein Supabase-SQL, keine Migration und keine DB-Änderung im Hotfix.
- Der `Main Deploy`-Workflow checkt explizit `main` aus und veröffentlicht GitHub Pages; er merged oder verändert keine Branches.

## Prozesshinweis
Für künftige gezielte PROD-Hotfixes: PR auf Basis von `main`, nur den gewünschten Code isoliert übernehmen, anschließend `Main Deploy` verwenden. Nicht `Deploy PROD` verwenden, solange dieser Workflow `develop` als Quelle hat.

## Nächster Entwicklungsstand
Backup-/Restore-Implementierung bleibt in `develop` und ist weiterhin nicht für PROD freigegeben.
