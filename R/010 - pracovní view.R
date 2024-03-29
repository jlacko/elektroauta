# doplní do databáze doplňující číselníky
# that's it, tečka :)

library(dplyr)
library(DBI)
library(RSQLite)

ddl_registrace_pracovni <- "CREATE VIEW registrace_pracovni AS 
                            select 
                              r.rok_registrace, 
                              'Q' || cast(ceil(cast(strftime('%m', date(datum_registrace_cr)) as real)/3) as text) as kvartal_registrace,
                              r.mesic_registrace, 
                              r.datum_registrace_cr, 
                              case when rp.pcv is null then 'N' else 'A' end prvni_registrace,
                              r.pcv, r.vin, r.vds,
                              r.novost_ojetost, r.kategorie,
                              r.druh_provozovatele, r.leasing, r.okres_registrace, r.orp_registrace,
                              r.tovarni_znacka, r.obchodni_oznaceni, m.obchodni_oznaceni as oznaceni_unif,
                              r.znacka_oznaceni, case when m.typ is null then 'spalovaci' else m.typ end typ,
                              case r.druh_provozovatele 
                                when '1' then 'fyzická'
                                when '2' then 'právnická'
                                else 'ostatní'
                              end osoba_provozovatele,
                              case when r.druh_provozovatele = '1' then 'retail' else 'non-retail' end typ_obchodu,
                              case when oo.KOD_ORP is null then 'nedef.' else oo.KOD_ORP end as KOD_ORP,
                              case when oo.NAZ_ORP is null then 'nedef.' else oo.NAZ_ORP end as NAZ_ORP,
                              case when oo.KOD_LAU1 is null then 'nedef.' else oo.KOD_LAU1 end as KOD_LAU1,
                              case when oo.NAZ_LAU1 is null then 'nedef.' else oo.NAZ_LAU1 end as NAZ_LAU1,
                              case when oo.KOD_CZNUTS3 is null then 'nedef.' else oo.KOD_CZNUTS3 end as KOD_CZNUTS3,
                              case when oo.NAZ_CZNUTS3 is null then 'nedef.' else oo.NAZ_CZNUTS3 end as NAZ_CZNUTS3 
                            from 
                              registrace r 
                              left join registrace_prvni rp
                                on r.vin = rp.vin and r.pcv = rp.pcv
                              left join modely m 
                                on r.tovarni_znacka = m.tovarni_znacka 
                                and r.obchodni_oznaceni like '%' || m.obchodni_oznaceni || '%'
                              left join obce_okresy oo
                                on r.orp_registrace = oo.orp_registrace 
                                and r.okres_registrace = oo.okres_registrace
                            ;"
con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

# zahodit co bylo...
dbExecute(con, "drop view if exists registrace_pracovni;")

# vytvořit nové, čisté view nad vším
dbExecute(con, ddl_registrace_pracovni)

DBI::dbDisconnect(con) # poslední zhasne...