#' title: "TSCI 5230 Data Model Tutorial"
#' Author: Ana Pineda
debug <- 0;seed <-22;#Seed is to generate a random number but in a different way. You will have a random number and reproducibility.

knitr::opts_chunk$set(echo=debug>-1, warning=debug>0, message=debug>0, class.output="scroll-20"
                      , attr.output='style="max-height: 150px; overflow-y: auto;"');

library(rio);# simple command for importing and exporting
library(pander); # format tables
#library(printr); # set limit on number of lines printed
library(broom); # allows to give clean dataset
library(dplyr);#add dplyr library
library(tidymodels);
library(ggfortify);
#init----
options(max.print=500);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf)
# Data Modeling----
library(dm)
library(nycflights13)
flights_dm_no_keys <- dm(airlines, airports, flights, planes, weather)
flights_dm_no_keys 
# a dm function create a list of data frame 
#primary key is what identify a unique row in a table, foreign key is to connect an outside key to a row in a table.
#Primary Keys (PK)----
PK <- sapply(names(flights_dm_no_keys), function(xx)
  dm_enum_pk_candidates(flights_dm_no_keys, table = !!xx) %>% 
    subset(candidate) %>% 
    select(columns) %>% mutate(tab = xx), simplify = F) %>% 
  bind_rows()
flights_dm_only_pks<-dm_add_pk(flights_dm_no_keys, planes, tailnum)%>% 
  dm_add_pk(airports, faa) %>% dm_add_pk(airlines, carrier)%>%  dm_add_pk(weather,columns = c(origin,time_hour) )

flights_dm_all_keys <-
  flights_dm_only_pks %>%
  dm_add_fk(table = flights, columns = tailnum, ref_table = planes) %>%
  dm_add_fk(flights, carrier, airlines) %>%
  dm_add_fk(flights, origin, airports)%>%
  dm_add_fk(flights,c(origin,time_hour), weather)#%>%
  #dm_add_fk(weather,origin,airports)

flights_dm_all_keys

flights_dm_all_keys %>%
  dm_draw()

dm_flatten_to_tbl(flights_dm_all_keys,flights)
dm_enum_fk_candidates(flights_dm_all_keys, weather, airports)

dm_flatten_to_tbl(flights_dm_all_keys,flights)
dm_enum_fk_candidates(flights_dm_all_keys, flights, weather)

#Plot----
#ggplot used for plotting 

set.seed(42)
dm_flatten_to_tbl(flights_dm_all_keys,flights) %>% 
  ggplot(aes(x=origin, y=dep_delay))+ #+ you are adding layers to a plot
  geom_point(position = "jitter", alpha=.5)

dm_flatten_to_tbl(flights_dm_all_keys,flights) %>% 
  ggplot(aes(x=origin, y=dep_delay))+ #+ you are adding layers to a plot
  geom_violin() #distribution
