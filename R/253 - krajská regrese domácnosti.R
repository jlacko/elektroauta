# závislost registrací průzkumu domácností po krajích

library(dplyr)
library(dbplyr)
library(ggplot2)


con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

registrace <- tbl(con, 'registrace_pracovni') %>% 
  # osobáky, bez firem a leasingu
  filter(typ_obchodu == 'retail' & kategorie == "M1") %>% 
  filter(rok_registrace >= '2023' & rok_registrace <= '2023') %>% 
  group_by(KOD_CZNUTS3, typ) %>% 
  summarise(pocet = count(vin)) %>% 
  collect() %>% 
  tidyr::pivot_wider(names_from = typ, values_from = pocet, values_fill = 0) %>% 
  mutate(pct_spalovaci = spalovaci / (spalovaci + elektro + hybrid)) %>% 
  mutate(pct_friendly = 1 - pct_spalovaci) %>% 
  ungroup()

DBI::dbDisconnect(con) # poslední zhasne...

source("./R/251 - příjmy a životní podmínky domácností.R")
source("./R/252 - dostupnost nabíječek.R")

reg_src <- registrace %>% 
  mutate(je_praha = KOD_CZNUTS3 == "CZ010") %>%
  inner_join(slozeni_prijmu, by = c("KOD_CZNUTS3" = "NUTS3")) %>% 
  inner_join(rozdeleni_prijmu, by = c("KOD_CZNUTS3" = "NUTS3")) %>%
  inner_join(bydleni, by = c("KOD_CZNUTS3" = "NUTS3")) %>% 
  inner_join(subset(dostupnost_fyzicka, nice_range == 10), by = c("KOD_CZNUTS3" = "NUTS3"))

# hrubé overview
model_income <- lm(pct_friendly ~ total_net_income, data = reg_src) 
summary(model_income)

model_distribution <- lm(pct_friendly ~ vysoky_prijem, data = reg_src)
summary(model_distribution)

model_house <- lm(pct_friendly ~ detached_house, data = reg_src)
summary(model_house)

model_accessibility <- lm(pct_friendly ~ pct_obyvatel, data = reg_src)
summary(model_accessibility)

# obrázek vs tisíc slov
ggplot(reg_src, aes(x = total_net_income, y = pct_friendly)) +
  geom_point(aes(shape = je_praha),
             size = 2) +
  geom_smooth(method = "lm") +
  labs(title = "Registrace elektro a hybridních aut podle příjmů domácností",
       x = "Roční čistý příjem domácnosti na osobu v Kč",
       y = "Podíl elektro a hybridních aut") +
  scale_y_continuous(labels = scales::percent,
                     breaks = seq(0, .018, length.out = 5),
                     limits = c(0, .018)) +
  scale_shape_manual(name = "typ regionu:",
                     values = c(4, 17),
                     labels = c("mimopražský", "Praha")) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  annotate("text", x = 240000, y = 1.5/100, label = paste0("R² = ", round(summary(model_income)$r.squared, 4)))

ggsave("./output/friendly-net_income.png", 
       width = 2500, height = 2000, units = "px")

ggplot(reg_src, aes(x = vysoky_prijem, y = pct_friendly)) +
  geom_point(aes(shape = je_praha),
             size = 2) +
  geom_smooth(method = "lm") +
  labs(title = "Registrace elektro a hybridních aut podle podílu vysokopříjmových domácností",
       x = "Podíl domácností s čistým měsíčním příjmem vyšším, jak 30 tisíc Kč na osobu",
       y = "Podíl elektro a hybridních aut") +
  scale_y_continuous(labels = scales::percent,
                     breaks = seq(0, .018, length.out = 5),
                     limits = c(0, .018)) +
  scale_shape_manual(name = "typ regionu:",
                     values = c(4, 17),
                     labels = c("mimopražský", "Praha")) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  annotate("text", x = 10, y = 1.5/100, label = paste0("R² = ", round(summary(model_distribution)$r.squared, 4)))

ggsave("./output/friendly-high_income.png", 
       width = 2500, height = 2000, units = "px")

ggplot(reg_src, aes(x = detached_house, y = pct_friendly)) +
  geom_point(aes(shape = je_praha),
             size = 2) +
  geom_smooth(method = "lm") +
  labs(title = "Registrace elektro a hybridních aut podle bydlení v domě",
       x = "Podíl domácností bydlících v rodinném domě",
       y = "Podíl elektro a hybridních aut") +
  scale_y_continuous(labels = scales::percent,
                     breaks = seq(0, .018, length.out = 5),
                     limits = c(0, .018)) +
  scale_shape_manual(name = "typ regionu:",
                     values = c(4, 17),
                     labels = c("mimopražský", "Praha")) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  annotate("text", x = 50, y = 1.5/100, label = paste0("R² = ", round(summary(model_house)$r.squared, 4)))

ggsave("./output/friendly-detached_house.png", 
       width = 2500, height = 2000, units = "px")

ggplot(reg_src, aes(x = pct_obyvatel, y = pct_friendly)) +
  geom_point(aes(shape = je_praha),
             size = 2) +
  geom_smooth(method = "lm") +
  labs(title = "Registrace elektro a hybridních aut podle dostupnosti nabíječky",
       x = "Podíl obyvatel v dojezdové vzdálenosti 10 minut od nabíječky",
       y = "Podíl elektro a hybridních aut") +
  scale_y_continuous(labels = scales::percent,
                     breaks = seq(0, .018, length.out = 5),
                     limits = c(0, .018)) +
  scale_shape_manual(name = "typ regionu:",
                     values = c(4, 17),
                     labels = c("mimopražský", "Praha")) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  annotate("text", x = .50, y = 1.5/100, label = paste0("R² = ", round(summary(model_accessibility)$r.squared, 4)))

ggsave("./output/friendly-accessibility.png", 
       width = 2500, height = 2000, units = "px")
