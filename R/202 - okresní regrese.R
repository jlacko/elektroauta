# závislost registrací na stanicích

library(dplyr)
library(dbplyr)
library(tidyr)
library(sf)

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

registrace <- tbl(con, 'registrace_pracovni') %>% 
  # osobáky, bez firem a leasingu
  filter(typ_obchodu == 'retail' & kategorie == "M1") %>% 
  filter(rok_registrace == '2022') %>% 
  group_by(rok_registrace, KOD_LAU1, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  collect() %>% 
  pivot_wider(names_from = typ, values_from = pocet, values_fill = 0) %>% 
  mutate(pct_spalovaci = spalovací / (spalovací + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

okresni_stanice <- RCzechia::okresy() %>% 
  st_join(st_read('./data/stanice.gpkg')) %>% 
  group_by(KOD_LAU1) %>% 
  summarize(stanic = n_distinct(osm_id, na.rm = T)) %>% 
  mutate(stanic_rel = stanic / st_area(.)) %>% 
  st_drop_geometry()

podklad <- RCzechia::okresy() %>% 
  left_join(registrace, by = 'KOD_LAU1') %>% 
  inner_join(okresni_stanice, by = 'KOD_LAU1')

regrese_prosta <- lm(data = podklad, formula = pct_friendly ~ stanic)

summary(regrese_prosta)

regrese_plosna <- lm(data = podklad, formula = pct_friendly ~ stanic_rel)

summary(regrese_plosna)
