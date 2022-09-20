# Elektroauta
inspirováno Nory...

## Obsah:

- `./data` = podkladová data
- `./R` = vlastní skripty

V rámci `/data`

- REG*.xlsx = stažená data z Ministerstva (hnus fialovej); staženo skriptem dle potřeby
- popis položek.txt = dává základní logiku datům z Ministerstva
- auta.sqlite = databáze naplněná začištěnými daty z Ministerstva; v archivu prázdné, naplněno skriptem z excelů
- modely.csv = vazba mobily + hybridy vs. značky a modely (codebookový vstup)
- stanice.gpkg = nabíjecí stanice z OpenStreetMap.org; vytvořeno a naplněno skriptem 

v rámci `/R`

- řada skriptů 0 = naplnění podkladových dat; musí být odpáleny všechny (a to sekvenčně)
- řada skriptů 1 = základní vizualizace; nemusí být odpalovány všechny (ani vůbec)
- řada skriptů 2 = modely; nemusí být odpalovány všechny (ani vůbec)

struktura databáze `auta.sqlite`

- registrace = hlavní tabulka, obsahuje registrace z Ministerstva
- modely = číselník, obsahuje číselník značek a modelů dle typu
- obce_okresy = číselník, obsahuje vazbu orp >> okres >> kraj ve standardní struktuře
- registrace_prvni = pomocná tabulka, ukazuje zda je daná kombinace VIN a PČV první výskyt v ČR (+ počet)
- registrace_pracovni = pracovní view poskládané z výše uvedeného

