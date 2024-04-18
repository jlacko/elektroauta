library(sf)
library(dplyr)

cesko <- RCzechia::republika("low") %>% 
  st_transform(5514)

kraje <- RCzechia::kraje("low") %>% 
  st_transform(5514)

zsj <- st_read("~/Documents/ev-chargers/data/zsj_census_2021.gpkg") %>% 
  st_transform(5514) %>% 
  st_join(kraje, largest = T)

chargers_all <- st_read("~/Documents/ev-chargers/data/chargers.gpkg") %>% 
  st_transform(5514)

chargers_cesko <- chargers_all[st_intersects(chargers_all, cesko, sparse = F)[,1], ] %>% 
  st_join(kraje)

isochrony <- st_read("~/Documents/ev-chargers/data/isolines_r5r.gpkg") %>% 
  mutate(nice_range = as.factor(isochrone)) %>% 
  st_transform(5514) %>% 
  st_make_valid()

isochrony$kraj <- chargers_cesko$KOD_CZNUTS3[match(isochrony$charger_id, chargers_cesko$id)]

# isochrony vysčítané po krajích, obohacené o počet obyvatel kraje
sumiso <- isochrony %>% 
  group_by(nice_range, kraj) %>% 
  summarise(.groups = "drop") %>%
  inner_join(zsj %>% 
               st_drop_geometry() %>%
               group_by(KOD_CZNUTS3) %>%
               summarise(obyvatele_kraje = sum(obyvatele)),
             by = c("kraj" = "KOD_CZNUTS3"))

# interpolace obyvatel ze ZSJ do isochron
for (kraj in kraje$KOD_CZNUTS3) {
  sumiso$obyvatele[sumiso$kraj == kraj] <- st_interpolate_aw(x = zsj[zsj$KOD_CZNUTS3 == kraj, "obyvatele"],
                                                             to = st_geometry(sumiso[sumiso$kraj == kraj, ]),
                                                             extensive = T) %>% 
    pull(obyvatele)
  
}

# absolutní číslo dobrý, ale relativní vypadá dobře v grafech...
sumiso$pct_obyvatel <- sumiso$obyvatele / sumiso$obyvatele_kraje

dostupnost_fyzicka <- sumiso %>% 
  st_drop_geometry() %>% 
  rename(NUTS3 = kraj) %>% 
  select(-c(obyvatele_kraje, obyvatele))

rm(cesko, kraje, zsj, chargers_all, chargers_cesko, isochrony, kraj, sumiso)