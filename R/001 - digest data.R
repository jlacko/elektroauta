# projede všechny excely v adresáři data a uloží obsah do 
# databáze typu sqlite pro budoucí zpracování

library(dplyr)
library(DBI)
library(RSQLite)
library(readxl)
library(fs)

sloupce <- c("pcv",
             "kategorie",
             "vin",
             "cislo_tp",
             "novost_ojetost",
             "datum_registrace_cr",
             "datum_registrace_kdekoliv",
             "hmotnost",
             "druh_provozovatele",
             "leasing",
             "ico_provozovatele",
             "ico_vlastnika",
             "cislo_ztp", # problém ve starších datech...
             "okres_registrace",
             "orp_registrace",
             "id_barvy_hlavni",
             "id_barvy_vedlejsi",
             "spis_prestavby",
             "tovarni_znacka",
             "obchodni_oznaceni",
             "znacka_oznaceni")

ddl_registrace <- "CREATE TABLE `registrace` (
                         `pcv` REAL,
                         `kategorie` TEXT,
                         `vin` TEXT,
                         `cislo_tp` TEXT,
                         `novost_ojetost` TEXT,
                         `datum_registrace_cr` TEXT,
                         `datum_registrace_kdekoliv` TEXT,
                         `hmotnost` REAL,
                         `druh_provozovatele` REAL,
                         `leasing` TEXT,
                         `ico_provozovatele` REAL,
                         `ico_vlastnika` REAL,
                         `cislo_ztp` TEXT,
                         `okres_registrace` TEXT,
                         `orp_registrace` TEXT,
                         `id_barvy_hlavni` REAL,
                         `id_barvy_vedlejsi` REAL,
                         `spis_prestavby` TEXT,
                         `tovarni_znacka` TEXT,
                         `obchodni_oznaceni` TEXT,
                         `znacka_oznaceni` TEXT
                  );
                  
                  CREATE INDEX registrace_datum_IDX ON registrace (date(datum_registrace_cr));
                  CREATE INDEX registrace_kategorie_IDX ON registrace (kategorie);
                  CREATE INDEX registrace_okres_registrace_IDX ON registrace (okres_registrace);
                  CREATE INDEX registrace_orp_registrace_IDX ON registrace (orp_registrace);
                  CREATE INDEX registrace_tovarni_znacka_IDX ON registrace (tovarni_znacka);
                  CREATE INDEX registrace_obchodni_oznaceni_IDX ON registrace (obchodni_oznaceni);"

# moderní struktura - včetně ZTP
moderni <- fs::dir_info("./data", glob = "*.xlsx") %>%  # najít všecny excely
  filter(!stringr::str_detect(path, '.REG180.')) 

# data do října '18 - bez čísla ztp
bez_ztp <- fs::dir_info("./data", glob = "*.xlsx") %>%  # najít všecny excely
  filter(stringr::str_detect(path, '.REG180.')) 

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

# zahodit co bylo...
result <- dbSendQuery(con, "drop table if exists registrace;")
dbClearResult(result) 

# vytvořit novou, čistou registraci
result <- dbSendQuery(con, ddl_registrace)
dbClearResult(result) 

for (soubor in moderni$path) {
  
  # načíst excel
  wrk_excel <- read_excel(soubor,
                          col_names = sloupce,
                          range = cell_cols("A:U"),
                          guess_max = Inf) %>% 
    mutate(datum_registrace_cr = as.character(as.Date(as.character(datum_registrace_cr), format = "%Y%m%d"))) %>% 
    mutate(datum_registrace_kdekoliv = as.character(as.Date(as.character(datum_registrace_kdekoliv), format = "%Y%m%d")))

  # uložit do databáze
  DBI::dbAppendTable(con, "registrace", wrk_excel)
  
}


for (soubor in bez_ztp$path) {
  
  # načíst excel
  wrk_excel <- read_excel(soubor,
                          col_names = sloupce[-13],
                          range = cell_cols("A:T"),
                          guess_max = Inf) %>% 
    mutate(datum_registrace_cr = as.character(as.Date(as.character(datum_registrace_cr), format = "%Y%m%d"))) %>% 
    mutate(datum_registrace_kdekoliv = as.character(as.Date(as.character(datum_registrace_kdekoliv), format = "%Y%m%d"))) %>% 
    mutate(cislo_ztp = "nedef.") %>% # označit chybějící data
    relocate(cislo_ztp, .before = okres_registrace)

  # uložit do databáze
  DBI::dbAppendTable(con, "registrace", wrk_excel)
  
}

DBI::dbDisconnect(con) # poslední zhasne...
