# PROD-SQL-Migrationen 1–43 – Inventar

Stand: 03.11.2026  
Quelle: Nutzerdatei Sql.zip (SHA-256: ca258b5fa738427ce38a5d4f43a956b04c69ad5d2295f5cdf0e4408e11406a7f).  
Umgebung: PROD – vom Nutzer ausdrücklich für alle 43 Migrationen bestätigt.  
Ausführung/Prüfung: Der Nutzer bestätigt, dass alle 43 SQL-Anfragen in PROD erfolgreich ausgeführt und im damaligen Chat geprüft wurden. Die konkreten Prüf-SQLs und Resultate sind nicht Bestandteil der ZIP und wurden hier nicht unabhängig erneut eingesehen.

| Nr. | Quelldatei | Beschreibung aus SQL | SHA-256 der Originaldatei |
|---:|---|---|---|
| 1 | Migration01.txt | Additive Vereins- und Rollenstruktur | 0491e99c1360060189a63a114a1bf8698d07d3117f632cc772257d086cb16b5b |
| 2 | Migration02.txt | Rollen- und Kontext-Hilfsfunktionen | ac26c0e7dfc088a4e92d201f0633f05d903e0991871960a6ddc2ce932493ab63 |
| 3 | Migration03.txt | RLS-Leseregeln und Schutz des Superadmin-Kontexts | 4f4989d425ea3fd0f7d700028c5fa8c6b4a2e7705613bb9fd4591fcfca8a1e5c |
| 4 | Migration04.txt | Rollenhistorie und Schutz des letzten Admins | 2a2c34b7f51f7113946b3261ece58afd9facb6ce3212ed5348f7a6c5f3edae7d |
| 5 | Migration05.txt | Mannschaftsrollen verwalten | 8e727021df7ede15e2075d59ea6cb65c089fa4d2fc8965daaddbbee7d09e79ee |
| 6 | Migration06.txt | Kontext auswählen, abrufen und zurücksetzen | 68c34fe54d45b3388a5594d2c1c3fc87acbfa659d2bcf1c51a32483fd232a326 |
| 7 | Migration07.txt | Vereinsmitgliedschaften und Profilbearbeitung | bc1d5a4a40388788076dd5dd3c44cf645506ee35ddc3d03794c69ba86572b261 |
| 8 | Migration08.txt | Storage-Bucket anlegen/konfigurieren | 3b857f20daaa34c4e9b81fe5911089d311bd4c5e1eafa3a48c2f6ba0218e90e6 |
| 9 | Migration09.txt | Storage-Policies für Vereinsassets und Profilbilder | 79ee6e6a99d56e1bae176f8c635289c0ee89396d4cf09afe70f6e06f0a972d1d |
| 10 | Migration10.txt | Vereinsadmin-Kandidaten und Vereinsanlage | afdbd938dada333951ecb8c020dbd9d54426a370507a64aa4640dab6e9d61d87 |
| 11 | Migration11.txt | Mannschaftsadmin-Kandidaten und Mannschaftsanlage | 29a3087b6a3bb1134016e5a4255ef4ae9d876840d240063322de681817bfe9bf |
| 12 | Migration12.txt | Vereinsdetails und Vereinswappen bearbeiten | 411846c7b26bc9081729879c130813fcd77ffcb97524254cbf20f3182086839c |
| 13 | Migration13.txt | Mannschaftsdetails und Mitgliederprofil bearbeiten | b315b741d82e18fb324bb1a84b3e37b77dae8744ad8e42d4b9f89828ef40e55c |
| 14 | Migration14.txt | Fehlende DEV-Funktionen nach PROD übernehmen | a7c53b91e1db41295668b130baf8c1e7d8399254966a4b9a6c37a6dafe21f8ea |
| 15 | Migration15.txt | Mannschaftsdeaktivierung | 8d47efda085efead3ee3a2212128444f21748896f78fd5e10501af6972c8eed5 |
| 16 | Migration16.txt | Vereinskontext-Berechtigung angleichen | 0bad1c340dac3072b9905b550cf6d854cd170ab0d070f7e97448468aa7c64647 |
| 17 | Migration17.txt | Leserechte im ausgewählten Mannschaftskontext | 794e8eb014b3297a9babc9cda1d995c45e70b17fdbb724a0a6752307d37581bc |
| 18 | Migration18.txt | Super-Admin-Schreibrechte für Spieler | c086a2f9ce3bb299a6ae7170d7965916c1f595fc0e79a9d108817264ee9e32d1 |
| 19 | Migration19.txt | Super-Admin-Rechte für Spielerpositionen | d6c002c500fb8631b6ba899576af164c816259f21216f701fa5d8d112d5c62cc |
| 20 | Migration20.txt | Super-Admin-Rechte für Positionen | 25ea8f87ef11f503378e46a10c6ced575d8faa1bfa43f2cf7d183c4596fcc6b5 |
| 21 | Migration21.txt | Vereinsmitgliedschaften an den Kontext koppeln | 21790f5aada8694dbab40ee954fe994ce348fee1070a76ca333418193e1f41ed |
| 22 | Migration22.txt | Super-Admin-Schreibrechte für Trainingsanwesenheit | a5178864a3b0f8c899cabb962e92a76b75918f3e6bbb4e46bb2bf0a68245115b |
| 23 | Migration23.txt | Super-Admin-Rechte für Spieltagsanwesenheit | 18f032cc725bec785aab3423431dff8338a807248e82ca3f16f2d51f2234b924 |
| 24 | Migration24.txt | Super-Admin-Rechte für Spieltagskader | 24b94f704fa89945bdf356c9ea196000eb7888c5af4c653ec6e02a93b4051888 |
| 25 | Migration25.txt | Super-Admin-Rechte für Empfehlungsläufe | be8a649fe30ee4d7f4b0717a08e4ba9cde0683063bf8b60066e52c1476d1bc21 |
| 26 | Migration26.txt | Super-Admin-Rechte für empfohlene Spieler | a246abd28914dd9b40efca0cc7ec78bb22df62c1bf5241e2dd0d157e662084ed |
| 27 | Migration27.txt | Super-Admin-Rechte für Traineranwesenheit am Spieltag | 56b595fd853ad2aaca1f7a8c4466755533ac8d56857c5b7cb9703d2ad777f6cd |
| 28 | Migration28.txt | Überzähligen Admin-Schutz-Trigger entfernen | e98c1a4788fefb81dcd40d01f9936afae83de3219b58bb7b9e3b52472dd1d0a2 |
| 29 | Migration29.txt | Super Admin muss den passenden Teamkontext wählen | ded745053ef974e07067ff8bc7be8985473cf27bcd547c61a83266f365ec0f56 |
| 30 | Migration30.txt | Trigger an den geprüften DEV-Stand angleichen | 9bde6b06ccb950cf33d9dc5494cb365f4eac162cf27cc89ea9abc947572d2363 |
| 31 | Migration31.txt | Fehlende Super-Admin-Regeln für Spieltage | 6ffefedcbe79f818060edd92f5f30aaf7fe7636b5fae6edd28ca1bf1f400bd71 |
| 32 | Migration32.txt | Fehlende Super-Admin-Regeln für Saisons | 7e9ccff9a911037bcfa6f341a2524dbc444db25e70d6e6138e1a8153d94c4b2f |
| 33 | Migration33.txt | Super-Admin-Regeln für training_players | b31381c62141ff401e71eba493ef5466a6075341004c5118930aa526424dc3d4 |
| 34 | Migration34.txt | Super-Admin-Regeln für training_responses | 8b0c4068ec09aeafdd4107d9a31eb0dfc4513869b23cc0a51c344716c901904c |
| 35 | Migration35.txt | Fehlende Super-Admin-Regeln für training_series | e19adc1adb3b9d6c4d4f9625252e6359064bc5939ab8d8a9b80988dae6d21974 |
| 36 | Migration36.txt | Fehlende Super-Admin-Regeln für training_trainers | 697cd49b40ac57a7bddb493664f68c0836c3733d96e3182242977bbdbd8c32e1 |
| 37 | Migration37.txt | Super-Admin-Regeln für trainings | 2fac47ff862b157716cccb892dd73f454ccdb78d26b797e980ca675e6ada1b52 |
| 38 | Migration38.txt | Fehlende Leseregel für Vereins-/Super-Admins | 72022160e06e2fd4bc2529bd5243255fc2da16c97d660af08025c77d1c05f322 |
| 39 | Migration39.txt | Spieler-Anlage und -Bearbeitung | 8930cdec15b352ac6a3b377e0c9f770d0a87689b99427706ff7e990710ce571f |
| 40 | Migration40.txt | player_positions an DEV angleichen | 7a5ad38108f37864e359be64fbf017e0bebd0daa3df2e5b4e38fc34a7489d55b |
| 41 | Migration41.txt | Spieler-Mannschaft-Zuordnung beim Löschen prüfen | 5631f242b5f75577135e673b72fad4de50ef2cac73c0589b9b4ef98b4a45a88c |
| 42 | Migration42.txt | Super Admin im passenden ausgewählten Kontext | 2b2e3d82ad834d36190cb279f2874633095aac66ee65b4d5e9bc676bf35a354e |
| 43 | Migration43.txt | REVOKE EXECUTE – Funktionsrechte einschränken | b739c75b9a986850ca1a0e88430b11b5d511e97e0e192381c71983564cdf21f6 |

## Integrität und Nachweisgrenzen

- Alle 43 SQL-Dateien wurden bytegenau mit den Einträgen Sql/MigrationNN.txt aus der bereitgestellten ZIP verglichen; alle 43 Inhalte stimmen überein.
- Die SHA-256-Werte beziehen sich auf die unveränderten Originalbytes jeder SQL-Datei.
- Migrationen 1–42 enthalten BEGIN und COMMIT; Migration 43 enthält keine expliziten Transaktionsklammern.
- Die PROD-Ausführung und erfolgreiche Prüfung beruhen auf ausdrücklicher Nutzerbestätigung. Exakte Zeitpunkte, einzelne Prüfabfragen und Resultate werden nicht erfunden.
- Dieses historische Archiv ist kein freigegebenes Wiederholungs- oder Rolloutpaket. Nicht erneut ausführen, ohne den aktuellen PROD-Datenbankstand und mögliche Überschneidungen zu prüfen.

Archiv-SHA-256: 1fa0aa346d925f130d03c51970e78f3b125003d13511580292f53b5604584138
