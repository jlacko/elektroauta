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
  group_by(rok_registrace, KOD_LAU1, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  collect() %>% 
  pivot_wider(names_from = typ, values_from = pocet, values_fill = 0) %>% 
  mutate(pct_spalovaci = spalovací / (spalovací + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

podklad <- RCzechia::okresy() %>% 
  left_join(registrace, by = 'KOD_LAU1')

ggplot(data = podklad,
       aes(fill = pct_friendly)) +
  geom_sf(col = NA) +
  geom_sf(data = RCzechia::republika(),
          fill = NA, col = "gray75",
          alpha = 1/2) +
  scale_fill_gradient(low = "white",
                      high = "red",
                      na.value = "grey90",
                      breaks = 1:5/500,
                      labels = scales::percent(1:5/500),
                      name = "% friendly") +
  facet_wrap(~ rok_registrace) +
  theme_void() +
  theme(legend.position = c(.85, .25)) +
  labs(title = 'podíl eco-friendly aut z celkových retailových registrací v čase a prostoru')