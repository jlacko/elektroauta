# vytvoří pomocnou tabulku první registrace (VIN + PČV)

library(dplyr)
library(DBI)
library(RSQLite)

ddl_registrace_prvni <- "CREATE TABLE registrace_prvni (
                            	vin TEXT NOT NULL,
                              pcv INTEGER NOT NULL,
                            	pocet_registraci INTEGER DEFAULT 1 NOT NULL, 
                            	CONSTRAINT registrace_prvni_PK PRIMARY KEY (vin)
                            );"

con <- DBI::dbConnect(RSQLite::SQLite(), "./data/auta.sqlite") # připojit databázi

# zahodit co bylo...
dbExecute(con, "drop table if exists registrace_prvni;")

# vytvořit novou, čistou tabulku prvních registrací
dbExecute(con, ddl_registrace_prvni)
dbExecute(con, "CREATE INDEX registrace_prvni_vin_IDX ON registrace_prvni (vin);")
dbExecute(con, "CREATE INDEX registrace_prvni_pcv_IDX ON registrace_prvni (pcv);")

# naplnit tabulku prvních registrací daty
dbExecute(con, "insert into registrace_prvni(vin, pcv) 
                select vin, pcv from registrace where vin is not null order by datum_registrace_cr asc
                on CONFLICT (vin)
                do update set pocet_registraci = pocet_registraci + 1;")

DBI::dbDisconnect(con) # poslední zhasne...


