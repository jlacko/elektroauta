# základní vizualizace / few questions asked...

library(dplyr)
library(dbplyr)
library(ggplot2)

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

registrace <- tbl(con, 'registrace_pracovni') %>% 
  filter(typ_obchodu == 'retail' & kategorie == "M1") %>% 
  filter(rok_registrace >= '2018' & rok_registrace <= '2022') %>% 
  group_by(rok_registrace, mesic_registrace, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  pivot_wider(names_from = typ, values_from = pocet) %>% 
  collect() %>% 
  mutate(pct_spalovaci = spalovací / (spalovací + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

ggplot(data = registrace, aes(x = mesic_registrace, 
                              y = pct_friendly, col = rok_registrace,
                              group = rok_registrace)) +
  geom_line() +
  scale_y_continuous(labels = scales::percent) +
  theme(axis.title = element_blank()) +
  labs(title = 'podíl eco-friendly aut z celkových retailových registrací',
       color = 'Rok registrace')