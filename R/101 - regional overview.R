# základní vizualizace / few questions asked...

library(dplyr)
library(dbplyr)
library(tidyr)
library(ggplot2)

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

registrace <- tbl(con, 'registrace_pracovni') %>% 
  # osobáky, bez firem a leasingu
  filter(typ_obchodu == 'retail' & kategorie == "M1") %>% 
  filter(rok_registrace >= '2018' & rok_registrace <= '2022') %>% 
  group_by(rok_registrace, KOD_CZNUTS3, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  pivot_wider(names_from = typ, values_from = pocet) %>% 
  collect() %>% 
  mutate(pct_spalovaci = spalovací / (spalovací + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

podklad <- RCzechia::kraje() %>% 
  left_join(registrace, by = 'KOD_CZNUTS3')

ggplot(data = podklad,
       aes(fill = pct_friendly)) +
  geom_sf(col = NA) +
  facet_wrap(~ rok_registrace) +
  theme_void()