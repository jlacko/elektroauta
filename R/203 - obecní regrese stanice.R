# závislost registrací na stanicích

library(dplyr)
library(dbplyr)
library(tidyr)
library(sf)

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

registrace <- tbl(con, 'registrace_pracovni') %>% 
  # osobáky, bez firem a leasingu
  filter(typ_obchodu == 'retail' & kategorie == "M1") %>% 
  # pozor! všechny roky...
  filter(rok_registrace >= '2018' & rok_registrace <= '2022') %>% 
  group_by(rok_registrace, KOD_ORP, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  collect() %>% 
  pivot_wider(names_from = typ, values_from = pocet, values_fill = 0) %>% 
  mutate(pct_spalovaci = spalovaci / (spalovaci + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

obecni_stanice <- RCzechia::orp_polygony() %>% 
  st_join(st_read('./data/stanice.gpkg')) %>% 
  group_by(KOD_ORP) %>% 
  summarize(stanic = n_distinct(osm_id, na.rm = T)) %>% 
  mutate(stanic_rel = stanic / st_area(.)) %>% 
  st_drop_geometry()

podklad <- RCzechia::orp_polygony() %>% 
  left_join(registrace, by = 'KOD_ORP') %>% 
  inner_join(obecni_stanice, by = 'KOD_ORP')


regrese_plosna <- lm(data = filter(podklad, rok_registrace == '2022'), formula = pct_friendly ~ stanic_rel)

summary(regrese_plosna)
