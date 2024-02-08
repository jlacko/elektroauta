# surová data z ČSÚ - regrese bude samostatný krok navazující na tento
# zdroj dat = https://www.czso.cz/csu/czso/prijmy-a-zivotni-podminky-domacnosti-7isum3msez

library(readxl)
library(dplyr)

header <- c("CZ0",
            RCzechia::kraje()$KOD_CZNUTS)

vars_income <- c("gross_monetary_income",
                 "employement_income",
                 "main_employement_income",
                 "self_employement_income",
                 "main_activity_self_employement_income",
                 "social_income",
                 "pensions",
                 "state_support_benefits",
                 "other_income",
                 "social_security_contributions",
                 "income_tax",
                 "tax_bonus",
                 "net_monetary_income",
                 "main_activity_net_income",
                 "income_in_kind",
                 "total_net_income")

vars_distribution <- c("under_6K",
                       "6K_8K",
                       "8K_10K",
                       "10K_12K",
                       "12K_15K",
                       "15K_20K",
                       "20K_30K",
                       "30K_50K",
                       "over_50K")

vars_housing <- c("detached_house",
                  "apartment_house",
                  "other",
                  "own_house",
                  "own_apartment",
                  "cooperative_apartment",
                  "rented",
                  "friends_relatives")

slozeni_prijmu <- read_xlsx("./data/regions_2022_a.xlsx",
                            sheet = "příjmy",
                            range = "D22:R38",
                            col_names = header) %>%
  slice(-10) %>%  # prázdný řádek mezi sekcí A  a B
  t() %>%
  as_tibble(rownames = "NUTS3",
            name.repair = "unique")  

colnames(slozeni_prijmu) <- c("NUTS3", vars_income)

rozdeleni_prijmu <- read_xlsx("./data/regions_2022_b.xlsx",
                              sheet = "rozdělení",
                              range = "D24:R32",
                              col_names = header) %>%
  t() %>%
  as_tibble(rownames = "NUTS3",
            name.repair = "unique")

colnames(rozdeleni_prijmu) <- c("NUTS3", vars_distribution)

bydleni <- read_xlsx("./data/regions_2022_d.xlsx",
                     sheet = "bydlení",
                     range = "D10:R18",
                     col_names = header) %>% 
  t() %>%
  as_tibble(rownames = "NUTS3",
            name.repair = "unique")

colnames(bydleni) <- c("NUTS3", vars_housing)

rm(header, vars_income, vars_distribution, vars_housing)