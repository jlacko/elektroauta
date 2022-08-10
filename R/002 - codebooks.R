# doplní do databáze doplňující číselníky
# that's it, tečka :)

library(dplyr)
library(DBI)
library(RSQLite)
library(readxl)
library(fs)

ddl_modely <- "CREATE TABLE `modely` (
                  `tovarni_znacka` TEXT,
                  `obchodni_oznaceni` TEXT,
                  `typ` TEXT
              );"

ddl_obce_okresy <- "CREATE TABLE `obce_okresy` (
                      `orp_registrace` TEXT,
                      `okres_registrace` TEXT,
                      `KOD_ORP` TEXT,
                      `NAZ_ORP` TEXT,
                      `KOD_OKRES` TEXT,
                      `KOD_LAU1` TEXT,
                      `NAZ_LAU1` TEXT,
                      `KOD_KRAJ` TEXT,
                      `KOD_CZNUTS3` TEXT,
                      `NAZ_CZNUTS3` TEXT
                  );"

ddl_registrace_elekto <- "CREATE VIEW registrace_elektro AS 
                          select 
                            r.pcv, r.vin, r.novost_ojetost, r.datum_registrace_cr,
                            r.druh_provozovatele, r.leasing, r.okres_registrace, r.orp_registrace,
                            r.tovarni_znacka, r.obchodni_oznaceni, m.obchodni_oznaceni as oznaceni_unif,
                            r.znacka_oznaceni, case when m.typ is null then 'spalovací' else m.typ end typ,
                            case when oo.NAZ_ORP is null then 'nedef.' else oo.NAZ_ORP end as NAZ_ORP,
                            case when oo.KOD_LAU1 is null then 'nedef.' else oo.KOD_LAU1 end as KOD_LAU1,
                            case when oo.KOD_ORP is null then 'nedef.' else oo.KOD_ORP end as KOD_ORP,
                            case when oo.NAZ_LAU1 is null then 'nedef.' else oo.NAZ_LAU1 end as NAZ_LAU1,
                            case when oo.KOD_CZNUTS3 is null then 'nedef.' else oo.KOD_CZNUTS3 end as KOD_CZNUTS3,
                            case when oo.NAZ_CZNUTS3 is null then 'nedef.' else oo.NAZ_CZNUTS3 end as NAZ_CZNUTS3 
                          from 
                            registrace r 
                            left join modely m 
                              on r.tovarni_znacka = m.tovarni_znacka 
                              and r.obchodni_oznaceni like '%' || m.obchodni_oznaceni || '%'
                            left join obce_okresy oo
                              on r.orp_registrace = oo.orp_registrace 
                              and r.okres_registrace = oo.okres_registrace
                           ;"


con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

# zahodit co bylo...
result <- dbSendQuery(con, "drop table if exists modely;")
dbClearResult(result) 

result <- dbSendQuery(con, "drop table if exists obce_okresy;")
dbClearResult(result) 

result <- dbSendQuery(con, "drop view if exists registrace_elektro;")
dbClearResult(result) 


# vytvořit novou, čistou tabulku modelů
result <- dbSendQuery(con, ddl_modely)
dbClearResult(result) 

# načíst z csvčka - editace vedle v Excelu!!
modely <- readr::read_csv("./data/modely.csv")

# uložit do databáze
DBI::dbAppendTable(con, "modely", modely)


# CZSO číselník okresů - #0101
cisokre <- czso::czso_get_codelist("cis101")  %>%
  mutate(CHODNOTA = as.character(CHODNOTA)) %>%
  select(KOD_OKRES = CHODNOTA, KOD_LAU1 = OKRES_LAU, NAZ_LAU1 = TEXT)

# CZSO číselník krajů - #0100
ciskraj <- czso::czso_get_codelist("cis100") %>%
  mutate(CHODNOTA = as.character(CHODNOTA)) %>%
  select(KOD_KRAJ = CHODNOTA, KOD_CZNUTS3 = CZNUTS, NAZ_CZNUTS3 = TEXT)

# vazba obec / okres
vazob <- czso::czso_get_codelist("cis101vaz43") %>%
  mutate(CHODNOTA1 = as.character(CHODNOTA1),
         CHODNOTA2 = as.character(CHODNOTA2)) %>%
  select(KOD_OBEC = CHODNOTA2, KOD_OKRES = CHODNOTA1)

#  vazba okres / kraj
vazokr <- czso::czso_get_codelist("cis100vaz101") %>%
  mutate(CHODNOTA1 = as.character(CHODNOTA1),
         CHODNOTA2 = as.character(CHODNOTA2)) %>%
  select(KOD_OKRES = CHODNOTA2, KOD_KRAJ = CHODNOTA1)

# vazba obec / orp obec
vazorp <- czso::czso_get_codelist("cis65vaz43") %>%
  mutate(CHODNOTA1 = as.character(CHODNOTA1),
         CHODNOTA2 = as.character(CHODNOTA2)) %>%
  select(KOD_OBEC = CHODNOTA2, KOD_ORP = CHODNOTA1, NAZ_ORP = TEXT1)

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
  mutate(orp_registrace = case_when(orp_registrace == "PRAHA" ~ "PRAHA HLAVNÍ MĚSTO",
                                    T ~ orp_registrace)) %>% 
  mutate(okres_registrace = case_when(okres_registrace == "PRAHA" ~ "HLAVNÍ MĚSTO PRAHA",
                                    T ~ okres_registrace)) %>% 
  mutate(okres_registrace = case_when(orp_registrace == "POHOŘELICE" ~ "BŘECLAV", # jsou Brno venkov od roku 2006, ale nešť...
                                      T ~ okres_registrace))  

# DQ rulez!!!  

obce <- obce %>% 
  bind_rows(obce %>% 
              filter(orp_registrace == "PRAHA HLAVNÍ MĚSTO") %>% 
              mutate(orp_registrace = "HLAVNÍ MĚSTO PRAHA"))


# vytvořit novou, čistou tabulku obcí a okresů
result <- dbSendQuery(con, ddl_obce_okresy)
dbClearResult(result) 

# uložit do databáze
DBI::dbAppendTable(con, "obce_okresy", obce)

# vytvořit nové, čisté view nad vším
result <- dbSendQuery(con, ddl_registrace_elekto)
dbClearResult(result) 

DBI::dbDisconnect(con) # poslední zhasne...