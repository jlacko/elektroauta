# závislost registrací na širším výběru metrik - stepwise regression by AIC

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
  mutate(pct_spalovaci = spalovací / (spalovací + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

obecni_scitani <- czso::czso_get_table("SLDB-VYBER") %>% 
  filter(uzcis == 65 | uzkod == '3018') %>% 
  mutate(uzkod = ifelse(uzkod == '3018', '1000', uzkod)) %>% # Praha jako kraj >> Praha jako ORP
  # metodika = https://www.czso.cz/documents/10180/25233177/sldb2011_vou.xls
  select(KOD_ORP = uzkod, 
         celkem = vse1111, 
         muzi = vse1112,
         zeny = vse1113,
         svobodni = vse1121,
         zenati = vse1131,
         rozvedeni = vse1141,
         ovdoveli = vse1151,
         plus15 = vse2111, 
         vs15 = vse2181,
         zs15 = vse2131,
         ss15 = vse2151,
         deti = vse3121,
         teens = vse3131,
         twenties = vse3141,
         thirties = vse3151,
         fourties = vse3161,
         fifties = vse3171,
         six_lo = vse3181,
         six_hi = vse3191,
         seventies = vse31101,
         eighties = vse31111,
         cesi = vse4121,
         moravci = vse4131,
         slezane = vse4141,
         slovaci = vse4151,
         nemci = vse4161,
         polaci = vse4171,
         romove = vse4181,
         ukrajinci = vse4191,
         vietnamci = vse41101,
         bezverci = vse5121,
         katolici = vse5141,
         husite = vse5151,
         evangelici = vse5161,
         jehovisti = vse5171,
         pravoslavni = vse5181,
         ateisti = vse5191,
         ek_aktivni = vse6111,
         zamestnanci = vse6131,
         icari = vse6151,
         prdusi = vse6161,
         matky = vse6173,
         nezamestnani = vse6181,
         neprdusi = vse61101,
         studenti = vse61111) %>% 
  mutate(across(!KOD_ORP, as.numeric)) %>% # pro vše kromě KOD_ORP: text >> číslo
  mutate(podil_svobodni = svobodni / plus15, # svobodní z 15+ 
         podil_vs = vs15 / plus15, # vysokoškoláci z 15+
         podil_zs = zs15 / plus15, # základní z 15+
         podil_ss = ss15 / plus15, # středoškoláci z 15+
         podil_0_14 = deti / celkem, # děti ze všech
         podil_15_19 = teens / celkem, 
         podil_20_29 = twenties / celkem,
         podil_30_39 = thirties / celkem,
         podil_40_49 = fourties / celkem,
         podil_50_59 = fifties / celkem,
         podil_60_69 = (six_hi + six_lo) / celkem,
         podil_70_79 = seventies / celkem,
         podil_80_plus = eighties / celkem,
         podil_ceska = cesi / celkem,
         podil_moravska = moravci / celkem,
         podil_slezska = slezane / celkem,
         podil_slovenska = slovaci / celkem,
         podil_nemecka = nemci / celkem,
         podil_romska = romove / celkem,
         podil_ukrajinska = ukrajinci / celkem,
         podil_vietnamska = vietnamci / celkem,
         podil_vira_bez = bezverci / celkem,
         podil_katolici = katolici / celkem,
         podil_husite = husite / celkem,
         podil_evangelici = evangelici / celkem,
         podil_jehoviste = jehovisti / celkem,
         podil_pravoslavni = pravoslavni / celkem,
         podil_ateisti = ateisti / celkem,
         podil_aktivni = ek_aktivni / plus15, # ekonomicky aktivní z 15+ (děti nebrat!)
         podil_zam = zamestnanci / ek_aktivni,
         podil_ico = icari / ek_aktivni,
         podil_prduch = prdusi / ek_aktivni,
         podil_matek = matky / ek_aktivni,
         podil_nezam = nezamestnani / ek_aktivni,
         podil_neprduch = neprdusi / plus15,
         podil_studenti = studenti / plus15)

podklad <- RCzechia::orp_polygony() %>% 
  left_join(registrace, by = 'KOD_ORP') %>% 
  left_join(obecni_scitani, by = 'KOD_ORP') %>% 
  select(pct_friendly, starts_with("podil")) %>% 
  st_drop_geometry()


fullModel = lm(pct_friendly ~ ., data = podklad)  # všechno
minModel = lm(pct_friendly ~ 1, data = podklad) # pouze konstanta

# optimalizace podle AIC
optimal_model <- MASS::stepAIC(minModel,
                         direction = 'forward',
                         scope = list(upper = fullModel,
                                      lower = minModel),
                         trace = 0)

summary(optimal_model)


