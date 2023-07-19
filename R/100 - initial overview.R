# základní vizualizace / few questions asked...

library(dplyr)
library(dbplyr)
library(tidyr)
library(ggplot2)

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

registrace <- tbl(con, 'registrace_pracovni') %>% 
  # osobáky, bez firem
  filter(typ_obchodu == 'retail' & kategorie == "M1") %>% 
  filter(rok_registrace >= '2018' & rok_registrace <= '2023') %>% 
  group_by(rok_registrace, kvartal_registrace, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  collect() %>% 
  pivot_wider(names_from = typ, values_from = pocet, values_fill = 0) %>% 
  mutate(pct_spalovaci = spalovaci / (spalovaci + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

ggplot(data = registrace, aes(x = paste(rok_registrace, kvartal_registrace), 
                              y = pct_friendly)) +
  geom_col(fill = "red") +
  scale_y_continuous(labels = scales::percent) +
  theme(axis.title = element_blank()) +
  labs(title = 'podíl eco-friendly aut z celkových retailových registrací v čase')