# E05 – Datenkorrektur Saisonzuordnung in DEV

**Datum:** 12.11.2026  
**Status:** Erfolgreich ausgeführt und read-only verifiziert  
**Umgebung:** Supabase DEV ausschließlich



## E05 – Datenkorrektur Saisonzuordnung DEV (12.11.2026)

- **Freigabe:** Nutzerbestätigung am 12.11.2026, sämtliche bislang saisonlosen Termine der DEV Mannschaft der aktiven Saison 2026/2027 zuzuordnen, auch wenn die Termine vor Anlage der Saison stattfanden.
- **Umgebung:** Supabase DEV, Projekt `pzazqvvoruqnqhcorbwx`. PROD und GitHub `main` nicht berührt.
- **Ziel:** Aktive Saison `2026/2027`, ID `c63eccff-6f0b-4d2f-add2-554e85ae07ef`, Team `DEV Mannschaft`, ID `4a8830e3-8852-4bb6-be22-279296d0a727`.
- **Vorheriger Befund:** 8 von 10 Spieltagen und 12 von 15 Trainings der DEV Mannschaft hatten `season_id IS NULL`. Alle 20 Datensätze gehörten fachlich zur Saison 2026/2027. Ursache: Saison wurde erst am 30.10.2026 angelegt; Frontend-Schreibpfade setzten bei fehlender aktiver Saison `season_id: season?.id || null`. Die Spalten erlauben NULL; auf `trainings` und `matchdays` existiert kein Trigger zur automatischen Saisonzuordnung.
- **Ausgeführte Datenkorrektur:** Ausschließlich Datensätze der DEV Mannschaft mit `season_id IS NULL` wurden auf die oben genannte aktive Saison gesetzt. Ergebnis der UPDATE-CTEs: 8 Spieltage und 12 Trainings aktualisiert.
- **SQL:**
  ```sql
  with target as (
    select '4a8830e3-8852-4bb6-be22-279296d0a727'::uuid as team_id,
           'c63eccff-6f0b-4d2f-add2-554e85ae07ef'::uuid as season_id
  ),
  updated_matchdays as (
    update public.matchdays m set season_id = target.season_id
    from target
    where m.team_id = target.team_id and m.season_id is null
    returning m.id
  ),
  updated_trainings as (
    update public.trainings tr set season_id = target.season_id
    from target
    where tr.team_id = target.team_id and tr.season_id is null
    returning tr.id
  )
  select (select count(*) from updated_matchdays) as matchdays_updated,
         (select count(*) from updated_trainings) as trainings_updated;
  ```
- **Nachprüfung:** 0 Spieltage und 0 Trainings ohne Saisonzuordnung; danach 10/10 Spieltage und 15/15 Trainings der DEV Mannschaft der Saison 2026/2027 zugeordnet. Andere Mannschaft G-Junioren unverändert und bereits vollständig zugeordnet.
- **Art der Änderung:** Datenkorrektur (DML), keine Schemaänderung und keine Migration. Keine Tabellen, Spalten, Funktionen, Trigger, RLS-Policies oder Grants geändert.
- **Offen:** Frontend-Erstellungspfad absichern, damit Spieltage/Trainings nicht mehr stillschweigend ohne aktive Saison angelegt werden können. Einzel-Training, Trainingsserie und Spieltag müssen berücksichtigt werden. Optional serverseitige Absicherung gesondert prüfen und vor Umsetzung freigeben lassen.
