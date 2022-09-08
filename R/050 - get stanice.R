# stahne z OSM mapu charging stations a uloží do /data

library(dplyr)   
library(osmdata) 
library(sf) 

search_res <- opq(bbox = RCzechia::republika(), 
                  nodes_only = T,
#                  datetime = "2018-01-01T00:00:00Z",
                  timeout = 300) %>% 
  add_osm_feature(key = "amenity",  
                  value = c("charging_station")) %>%
  osmdata_sf(quiet = F) 

stanice <- search_res$osm_points %>% 
  st_intersection(RCzechia::republika()) %>% 
  mutate(datum = ifelse(is.null(search_res$meta$datetime_to),
                        gsub("\\[ | \\]", "", search_res$meta$timestamp) |> as.Date(format = "%a %d %b %Y"), 
                        search_res$meta$datetime_to |> as.Date())) %>% 
  mutate(datum = as.Date(datum, origin = as.Date('1970-01-01'))) %>% 
  select(datum, osm_id, operator)

rownames(stanice) <- c()

st_write(stanice, "./data/stanice.gpkg",
         append = FALSE) # ie. overwrite
