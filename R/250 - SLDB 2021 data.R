library(dplyr)
library(stringr)
library(tidyr)

# CZSO číselník ORP - #0065
cisorp <- czso::czso_get_codelist("cis65") 

# CZSO číselník kraje - #0100
ciskraj <- czso::czso_get_codelist("cis100")

# CZSO vazba kraje ORP
vazkrajorp <- czso::czso_get_codelist("cis100vaz65") 

activity <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/209565602/sldb2021_aktivita_vek10_pohlavi.csv/8ee8f36e-7c65-4d3d-85cb-3b4a644e706d?version=1.1") %>% 
  filter(uzemi_cis == "65") %>%  # pouze ORPčka
  filter(is.na(pohlavi_kod)) %>% # všechny pohlaví
  group_by(uzemi_kod, aktivita_struktura, aktivita_kod) %>% 
  summarize(hodnota = sum(hodnota, na.rm = T)) %>% 
  ungroup() %>% 
  mutate(species = paste0("aktivita_", aktivita_struktura)) %>% # Na = součtový řádek
  select(uzemi_kod, species, hodnota) %>% # jen relevantní sloupce
  pivot_wider(names_from = species, # z dlouhého na široký data frame / chceme n = 206
              values_from = hodnota,
              values_fill = 0) 


age <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/183907242/sldb2021_vek5_pohlavi.csv/4049985d-4126-4e7b-abf1-875d6c7722f7?version=1.1") %>% 
  filter(uzemi_cis == "65") %>%  # pouze ORPčka
  filter(is.na(pohlavi_kod)) %>% # všechny pohlaví
  mutate(species = paste0("cis1035_", ifelse(is.na(vek_txt), "celkem", vek_kod))) %>% # Na = součtový řádek
  select(uzemi_kod, species, hodnota) %>% # jen relevantní sloupce
  pivot_wider(names_from = species, # z dlouhého na široký data frame / chceme n = 206
              values_from = hodnota,
              values_fill = 0) 

edu <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/205988586/sldb2021_vzdelani_vek2_pohlavi.csv/5d7a6d5c-a7b1-468f-aa48-80560fbce267?version=1.1") %>% 
  filter(uzemi_cis == "65") %>%  # pouze ORPčka
  filter(is.na(pohlavi_kod)) %>% # všechny pohlaví
  mutate(species = paste0("cis1294_",vzdelani_kod, "_vs_cis1035_", vek_kod)) %>% 
  select(uzemi_kod, species, hodnota) %>% # jen relevantní sloupce
  pivot_wider(names_from = species, # z dlouhého na široký data frame / chceme n = 206
              values_from = hodnota,
              values_fill = 0) %>% 
  mutate(celkem_1200659999 = rowSums(select(., ends_with("1200659999"))),
         celkem_1300150064 = rowSums(select(., ends_with("1300150064"))))

commute_means <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/210716438/sldb2021_vyjizdka_vsichni_prostredek_pohlavi.csv/0b464e82-b8e4-4661-9a4e-3b7cb11757de?version=1.1") %>% 
  filter(uzemi_cis == "65") %>%  # pouze ORPčka
  filter(is.na(pohlavi_kod)) %>% # všechny pohlaví
  mutate(species = paste0("cis3090_", ifelse(is.na(prostredek_txt), "celkem", prostredek_kod))) %>% # Na = součtový řádek
  select(uzemi_kod, species, hodnota) %>% # jen relevantní sloupce
  pivot_wider(names_from = species, # z dlouhého na široký data frame / chceme n = 206
              values_from = hodnota,
              values_fill = 0) 

flats <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/202188093/sldb2021_obybyty_vlastnik_druhdomu.csv/8c5fbc6e-2e60-4702-b4c7-d541f9476c72?version=1.1") %>% 
  filter(uzemi_cis == "65") %>% 
  mutate(species = paste0("cis", vlastnik_cis, "_", vlastnik_kod, "_vs_", ifelse(is.na(druhdomu_cis), "celkem", paste0("cis", druhdomu_cis, "_", druhdomu_kod)))) %>% 
  select(uzemi_kod, species, hodnota) %>% # jen relevantní sloupce
  pivot_wider(names_from = species, # z dlouhého na široký data frame / chceme n = 206
              values_from = hodnota,
              values_fill = 0) %>% 
  mutate(dr_bytove = rowSums(select(., ends_with("4"))),
         dr_rodinne = rowSums(select(., ends_with("51"))),
         dr_ostatni = rowSums(select(., ends_with("55"))),
         
         fv_druzstvo = cis3049_10_vs_celkem,
         fv_fyzicka = cis3049_1_vs_celkem,
         fv_jina_pravnicka = cis3049_6_vs_celkem,
         fv_kombinace = cis3049_7_vs_celkem,
         fv_nezjisteno = cis3049_9_vs_celkem,
         fv_obec_stat = cis3049_2_vs_celkem,
         fv_svj = cis3049_11_vs_celkem,
         
         grand_total = rowSums(select(., ends_with("celkem"))))

# relativní čísla místo absolutních

akt_rel <- activity %>%
  mutate(aktivita_aktivni = aktivita_1 / (aktivita_1 + aktivita_2 + aktivita_3)) %>% 
  mutate(across(starts_with("aktivita_1"), ~ . / aktivita_1),
         across(starts_with("aktivita_2"), ~ . / aktivita_2),
         across(starts_with("aktivita_3"), ~ . / aktivita_3))  

age_rel <- age %>% 
  mutate(across(where(is.numeric) & !c(uzemi_kod),~ . / cis1035_celkem)) 

edu_rel <- edu %>% 
  mutate(across(ends_with("1200659999"), ~ . / celkem_1200659999),
         across(ends_with("1300150064"), ~ . / celkem_1300150064)) %>% 
  select(-starts_with("celkem"))
  
commute_rel <- commute_means %>% 
  mutate(across(where(is.numeric) & !c(uzemi_kod),~ . / cis3090_celkem)) %>% 
  select(-ends_with("celkem"))

flats_rel <- flats %>% 
  mutate(across(where(is.numeric) & !c(uzemi_kod),~ . / grand_total)) %>% 
  select(-grand_total)

orpcka <- RCzechia::orp_polygony() %>% 
  sf::st_drop_geometry() %>% 
  mutate(uzemi_kod = as.numeric(KOD_ORP)) %>% 
  left_join(akt_rel, by = c("uzemi_kod")) %>% 
  left_join(age_rel, by = c("uzemi_kod")) %>% 
  left_join(edu_rel, by = c("uzemi_kod")) %>% 
  left_join(commute_rel, by = c("uzemi_kod")) %>% 
  left_join(flats_rel, by = c("uzemi_kod")) 


saveRDS(orpcka, "./data/orpcka.rds")