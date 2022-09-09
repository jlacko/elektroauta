# stahne data z https://www.mdcr.cz/ do /data
# tečka, to je vše :)

library(dplyr)

mesice <- stringr::str_pad(1:12, width = 2, side = "left", pad = "0")

aktualni_rok <- paste0('REG22',mesice)

historie <- expand.grid(paste0('REG',18:21), mesice) %>% 
  mutate(Var3 = paste0(Var1, Var2)) %>% 
  pull(Var3)

# stahnout historii - je úplná (seběhne vždy 4 roky × 12 měsíců = 48 souborů)

for (soubor in historie) {
  
  # formát na zdrojí není zcela konzistentní; je třeba zkusit dvě možnosti a uvidět...
  zipak <- paste0("https://www.mdcr.cz/getattachment/Statistiky/Silnicni-doprava/Centralni-registr-vozidel/Mesicni-statistiky-2018/", 
                  soubor, ".zip.aspx?lang=cs-CZ")
  excel <- paste0("https://www.mdcr.cz/getattachment/Statistiky/Silnicni-doprava/Centralni-registr-vozidel/Mesicni-statistiky-2018/", 
                  soubor, ".xlsx.aspx?lang=cs-CZ")
  
  # když soubor již existuje >> přeskočit
  if(!file.exists(paste0("./data/", soubor, ".xlsx"))) { 
    
    # zkusit zipák, jestli je na zdroji - pokud ano, stahnout a odzipovat
    if(!httr::http_error(zipak)) {
      
      curl::curl_download(url = zipak, destfile = paste0("./data/", soubor, ".zip"))
      unzip(zipfile = paste0("./data/", soubor, ".zip"), exdir = "./data")
      file.remove(paste0("./data/", soubor, ".zip"))
      
    }
    
    # nezávisle na úspěchu stahování zipáku zkusit na zdroji excel
    if(!httr::http_error(excel)) curl::curl_download(url = excel, destfile = paste0("./data/", soubor, ".xlsx"))
  }
  
}

# stahnout běžný rok - není garance 12 souborů ročně

for (soubor in aktualni_rok) {
  
  zipak <- paste0("https://www.mdcr.cz/getattachment/Statistiky/Silnicni-doprava/Centralni-registr-vozidel/Mesicni-statistiky-2022,/", 
                  soubor, ".zip.aspx?lang=cs-CZ")
  excel <- paste0("https://www.mdcr.cz/getattachment/Statistiky/Silnicni-doprava/Centralni-registr-vozidel/Mesicni-statistiky-2022,/", 
                  soubor, ".xlsx.aspx?lang=cs-CZ")

  
  if(!file.exists(paste0("./data/", soubor, ".xlsx"))) {
    
    if(!httr::http_error(zipak)) {
      
      curl::curl_download(url = zipak, destfile = paste0("./data/", soubor, ".zip"))
      unzip(zipfile = paste0("./data/", soubor, ".zip"), exdir = "./data")
      file.remove(paste0("./data/", soubor, ".zip"))
 
     }
  
    if(!httr::http_error(excel)) curl::curl_download(url = excel, destfile = paste0("./data/", soubor, ".xlsx"))
  }
  
}

