# závislost registrací na vysokoškolsky vzdělané populaci

library(dplyr)
library(dbplyr)
library(tidyr)
library(sf)

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

registrace <- tbl(con, 'registrace_pracovni') %>% 
  # osobáky, bez firem a leasingu
  filter(typ_obchodu == 'retail' & kategorie == "M1") %>% 
  # pozor, všechny roky
  filter(rok_registrace == '2022') %>% 
  group_by(rok_registrace, KOD_ORP, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  collect() %>% 
  pivot_wider(names_from = typ, values_from = pocet, values_fill = 0) %>% 
  mutate(pct_spalovaci = spalovaci / (spalovaci + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup() %>% 
  select(KOD_ORP, pct_friendly)

DBI::dbDisconnect(con) # poslední zhasne...

reg_src <- readRDS("./data/orpcka.rds") %>% # skript 250
  inner_join(registrace, by = "KOD_ORP") %>% 
  select(-c(1:6))

fullModel = lm(pct_friendly ~ ., data = reg_src)  # všechno
minModel = lm(pct_friendly ~ 1, data = reg_src) # pouze konstanta

# optimalizace podle {MASS} / AIC
mass_model <- MASS::stepAIC(minModel,
                            direction = 'forward',
                            scope = list(upper = fullModel,
                                         lower = minModel),
                            trace = F)

dredge_variables_mass <- sort(names(coef(mass_model)[-1]))   # bez interceptu

dredge_model <- paste("pct_friendly ~",
                      paste(dredge_variables_mass, 
                                       collapse = " + "))

summary(lm(dredge_model, reg_src))

# interpretace hodnot z číselníků
czso::czso_get_codelist("cis1035") %>% 
  filter(chodnota %in% c("1201009999",
                         "1300250029",
                         "1300450049",
                         "1300850089")) %>% 
  select(chodnota, text) %>% 
  arrange(as.numeric(chodnota))

# ekonomická aktivita
readr::read_csv(file = "https://www.czso.cz/documents/62353418/209565602/sldb2021_aktivita_vek10_pohlavi.csv/8ee8f36e-7c65-4d3d-85cb-3b4a644e706d?version=1.1") %>% 
  select(aktivita_struktura, aktivita_txt) %>% 
  unique()


# cis1294 = vzdělání
readr::read_csv(file = "https://www.czso.cz/documents/62353418/205988586/sldb2021_vzdelani_vek2_pohlavi.csv/5d7a6d5c-a7b1-468f-aa48-80560fbce267?version=1.1") %>% 
  select(vzdelani_cis, chodnota = vzdelani_kod, vzdelani_txt) %>% 
  unique() %>% 
  arrange(as.numeric(chodnota))

# cis3049 = vlastnictví bytu
czso::czso_get_codelist("cis3049") %>% 
  select(chodnota, text) %>% 
  arrange(as.numeric(chodnota))

# druh domu
readr::read_csv(file = "https://www.czso.cz/documents/62353418/202188093/sldb2021_obybyty_vlastnik_druhdomu.csv/8c5fbc6e-2e60-4702-b4c7-d541f9476c72?version=1.1") %>% 
  select(druhdomu_cis, chodnota = druhdomu_kod, druhdomu_txt) %>% 
  unique() %>% 
  arrange(as.numeric(chodnota))

# cis3090 = dopravní prostředek dojíždění
readr::read_csv(file = "https://www.czso.cz/documents/62353418/210716438/sldb2021_vyjizdka_vsichni_prostredek_pohlavi.csv/0b464e82-b8e4-4661-9a4e-3b7cb11757de?version=1.1") %>% 
  select(prostredek_cis, chodnota = prostredek_kod, prostredek_txt) %>% 
  unique() %>% 
  arrange(as.numeric(chodnota))

# overview proč je multikulti problém

testRes <- corrplot::cor.mtest(reg_src, conf.level = 0.95)
corrplot::corrplot(cor(reg_src), 
                   method = "color",
                   p.mat = testRes$p, 
                   sig.level = 0.10,
                   insig='blank',
                   tl.pos = "n")
