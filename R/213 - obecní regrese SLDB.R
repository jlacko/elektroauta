# závislost registrací na vysokoškolsky vzdělané populaci

library(dplyr)
library(dbplyr)
library(tidyr)
library(sf)

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

registrace <- tbl(con, 'registrace_pracovni') %>% 
  # osobáky, bez firem a leasingu
  filter(typ_obchodu == 'retail' & kategorie == "M1") %>% 
  filter(rok_registrace == '2022') %>% 
  group_by(rok_registrace, KOD_ORP, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  collect() %>% 
  pivot_wider(names_from = typ, values_from = pocet, values_fill = 0) %>% 
  mutate(pct_spalovaci = spalovací / (spalovací + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

obecni_scitani <- czso::czso_get_table("SLDB-VYBER") %>% 
  filter(uzcis == 65 | uzkod == '3018') %>% 
  mutate(uzkod = ifelse(uzkod == '3018', '1000', uzkod)) %>% # Praha jako kraj >> Praha jako ORP
  select(KOD_ORP = uzkod, celkem = vse1111, plus15 = vse2111, vs15 = vse2181) %>% 
  mutate_at(.vars = c(2:4), as.numeric) %>% 
  mutate(podil_vs = vs15 / plus15) # tj. podíl vysokoškolsky vzdělaných 15+ ze všech 15+

podklad <- RCzechia::orp_polygony() %>% 
  left_join(registrace, by = 'KOD_ORP') %>% 
  left_join(obecni_scitani, by = 'KOD_ORP')

regrese_prosta <- lm(data = podklad, formula = pct_friendly ~ podil_vs)

summary(regrese_prosta)

