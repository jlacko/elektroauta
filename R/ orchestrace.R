# inicializace dat: protočí všechny skripty nulové řady
# postaví vše na čisté rovině, ale vezme si něco času = nepouštět pod časovým tlakem!!!

# stažení registrací z API Ministerstva - rychlé (protože přírůstky)
source("./R/000 - get registrace.R")

# zpracování stažených registrací do databáze - pomalé (protože full copy)
source("./R/001 - digest registrace.R")

# stažení číselníků ze staťáku - rychlé (protože číselníky jsou malé)
source("./R/002 - codebooks.R")

# příprava tabulky unikátních prvních registrací - rychlé (jsme v SQL)
source("./R/003 - první registrace.R")

# příprava pracovního view pro analýzu - rychlé (pure DDL)
source("./R/010 - pracovní view.R")

# stažení nabíjecích stanic z Overpass API- pomalé (protože rate limited)
source("./R/050 - get stanice.R")
