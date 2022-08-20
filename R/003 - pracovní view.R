# doplní do databáze doplňující číselníky
# that's it, tečka :)

library(dplyr)
library(DBI)
library(duckdb)

ddl_registrace_pracovni <- "CREATE or replace VIEW main.registrace_pracovni AS 
                            select 
                              year(r.datum_registrace_cr) rok_registrace, 
                              quarter(r.datum_registrace_cr)  kvartal_registrace,
                              month(r.datum_registrace_cr) mesic_registrace, 
                              r.datum_registrace_cr, r.pcv, r.vin, r.novost_ojetost, 
                              r.druh_provozovatele, r.leasing, r.okres_registrace, r.orp_registrace,
                              r.tovarni_znacka, r.obchodni_oznaceni, m.obchodni_oznaceni as oznaceni_unif,
                              r.znacka_oznaceni, case when m.typ is null then 'spalovací' else m.typ end typ,
                              case when oo.NAZ_ORP is null then 'nedef.' else oo.NAZ_ORP end as NAZ_ORP,
                              case when oo.KOD_LAU1 is null then 'nedef.' else oo.KOD_LAU1 end as KOD_LAU1,
                              case when oo.KOD_ORP is null then 'nedef.' else oo.KOD_ORP end as KOD_ORP,
                              case when oo.NAZ_LAU1 is null then 'nedef.' else oo.NAZ_LAU1 end as NAZ_LAU1,
                              case when oo.KOD_CZNUTS3 is null then 'nedef.' else oo.KOD_CZNUTS3 end as KOD_CZNUTS3,
                              case when oo.NAZ_CZNUTS3 is null then 'nedef.' else oo.NAZ_CZNUTS3 end as NAZ_CZNUTS3 
                            from 
                              main.registrace r 
                              left join main.modely m 
                                on r.tovarni_znacka = m.tovarni_znacka 
                                and r.obchodni_oznaceni like '%' || m.obchodni_oznaceni || '%'
                              left join main.obce_okresy oo
                                on r.orp_registrace = oo.orp_registrace 
                                and r.okres_registrace = oo.okres_registrace
                            ;"

con <- DBI::dbConnect(duckdb::duckdb(), dbdir="./data/auta.duckdb", read_only=FALSE) # připojit databázi

# vytvořit nové, čisté view nad vším
result <- dbSendQuery(con, ddl_registrace_pracovni)
dbClearResult(result) 

DBI::dbDisconnect(con, shutdown=TRUE) # poslední zhasne...