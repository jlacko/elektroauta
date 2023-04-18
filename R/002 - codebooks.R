# doplní do databáze doplňující číselníky
# that's it, tečka :)

library(dplyr)
library(DBI)
library(RSQLite)

ddl_modely <- "CREATE TABLE modely (
                  tovarni_znacka TEXT,
                  obchodni_oznaceni TEXT,
                  typ TEXT,
                  PRIMARY KEY (tovarni_znacka, obchodni_oznaceni)
              );"

ddl_obce_okresy <- "CREATE TABLE obce_okresy (
                      orp_registrace TEXT,
                      okres_registrace TEXT,
                      KOD_ORP TEXT,
                      NAZ_ORP TEXT,
                      KOD_OKRES TEXT,
                      KOD_LAU1 TEXT,
                      NAZ_LAU1 TEXT,
                      KOD_KRAJ TEXT,
                      KOD_CZNUTS3 TEXT,
                      NAZ_CZNUTS3 TEXT,
                      PRIMARY KEY (orp_registrace, okres_registrace)
                  );"

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

# zahodit co bylo...
dbExecute(con, "drop table if exists modely;")
dbExecute(con, "drop table if exists obce_okresy;")

# vytvořit novou, čistou tabulku modelů
dbExecute(con, ddl_modely)

# načíst z csvčka - editace vedle v Excelu!!
modely <- readr::read_csv("./data/modely.csv")

# uložit do databáze
DBI::dbAppendTable(con, "modely", modely)


# CZSO číselník okresů - #0101
cisokre <- czso::czso_get_codelist("cis101") %>%
  select(KOD_OKRES = chodnota, KOD_LAU1 = okres_lau, NAZ_LAU1 = text)

# CZSO číselník krajů - #0100
ciskraj <- czso::czso_get_codelist("cis100") %>%
  select(KOD_KRAJ = chodnota, KOD_CZNUTS3 = cznuts, NAZ_CZNUTS3 = text)

# vazba obec / okres
vazob <- czso::czso_get_codelist("cis101vaz43") %>%
  select(KOD_OBEC = chodnota2, KOD_OKRES = chodnota1)

#  vazba okres / kraj
vazokr <- czso::czso_get_codelist("cis100vaz101") %>%
  select(KOD_OKRES = chodnota2, KOD_KRAJ = chodnota1)

# vazba obec / orp obec
vazorp <- czso::czso_get_codelist("cis65vaz43") %>%
  select(KOD_OBEC = chodnota2, KOD_ORP = chodnota1, NAZ_ORP = text1)

# pospojování do zdroje všech zdrojů :)
obce <- vazorp %>%
  inner_join(vazob, by = "KOD_OBEC") %>%
  inner_join(cisokre, by = "KOD_OKRES") %>%
  inner_join(vazokr, by = "KOD_OKRES") %>%
  inner_join(ciskraj, by = "KOD_KRAJ") %>% 
  select(KOD_ORP, NAZ_ORP, KOD_OKRES, 
         KOD_LAU1, NAZ_LAU1, KOD_KRAJ,
         KOD_CZNUTS3, NAZ_CZNUTS3) %>% 
  unique() %>% 
  mutate(orp_registrace = stringr::str_to_upper(NAZ_ORP),
         okres_registrace = stringr::str_to_upper(NAZ_LAU1)) %>% 
  relocate(orp_registrace, okres_registrace) %>% 
  # Praha, to je to město...
  mutate(orp_registrace = case_when(orp_registrace == "PRAHA" ~ "PRAHA HLAVNÍ MĚSTO",
                                    T ~ orp_registrace)) %>% 
  mutate(okres_registrace = case_when(okres_registrace == "PRAHA" ~ "HLAVNÍ MĚSTO PRAHA",
                                    T ~ okres_registrace)) %>% 
  # jsou Brno venkov od roku 2006, ale nešť...
  mutate(okres_registrace = case_when(orp_registrace == "POHOŘELICE" ~ "BŘECLAV", 
                                      T ~ okres_registrace))  

# DQ rulez!!!  
obce <- obce %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "HLAVNÍ MĚSTO PRAHA")) %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "PRAHA 4")) %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "PRAHA 5")) %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "PRAHA 10")) %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "PRAHA 9")) %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "PRAHA 1")) %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "PRAHA 2")) %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "PRAHA 7")) %>%   
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "PRAHA 8"))


# vytvořit novou, čistou tabulku obcí a okresů
dbExecute(con, ddl_obce_okresy)

# uložit do databáze
DBI::dbAppendTable(con, "obce_okresy", obce)

DBI::dbDisconnect(con) # poslední zhasne...