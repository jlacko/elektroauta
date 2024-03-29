
library(dplyr)

activity <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/209565602/sldb2021_aktivita_vek10_pohlavi.csv/8ee8f36e-7c65-4d3d-85cb-3b4a644e706d?version=1.1")

age <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/183907242/sldb2021_vek5_pohlavi.csv/4049985d-4126-4e7b-abf1-875d6c7722f7?version=1.1")

edu <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/205988586/sldb2021_vzdelani_vek2_pohlavi.csv/5d7a6d5c-a7b1-468f-aa48-80560fbce267?version=1.1")

commute_freq <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/212564536/dojizdka_obce.csv/873e7231-1344-499f-b9b4-1f6782595af9?version=1.1")

commute_means <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/210716438/sldb2021_vyjizdka_vsichni_prostredek_pohlavi.csv/0b464e82-b8e4-4661-9a4e-3b7cb11757de?version=1.1")

houses <- readr::read_csv(file = "https://www.czso.cz/documents/62353418/202188093/sldb2021_obybyty_vlastnik_druhdomu.csv/8c5fbc6e-2e60-4702-b4c7-d541f9476c72?version=1.1")

fine_houses <-  readr::read_csv(file = "https://www.czso.cz/documents/62353418/202188093/sldb2021_byty_obydlenost_druhdomu.csv/cd614cdd-b3f5-4049-897c-ba509807bfc0?version=1.5")

fine_population <-  readr::read_csv(file = "https://www.czso.cz/documents/62353418/192056095/sldb2021_obyv_byt_cob_zsj.csv/2c58e839-6cfa-42d8-9458-797ba567ea9f?version=1.3")