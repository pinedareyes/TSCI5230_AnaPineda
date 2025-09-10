#' title: "TSCI 5230 Processing a Data Set"
#' Author: Ana Pineda
##Copy over the init section
debug <- 0;seed <-22;#See is to generate a random number but in a different way. You will have a random number and reproducibility.

knitr::opts_chunk$set(echo=debug>-1, warning=debug>0, message=debug>0, class.output="scroll-20", attr.output='style="max-height: 150px; overflow-y: auto;"');

library(ggplot2); # visualization
library(DataExplorer) #? is use to help file available
library(GGally);
library(rio);# simple command for importing and exporting
library(pander); # format tables
#library(printr); # set limit on number of lines printed
library(broom); # allows to give clean dataset
library(dplyr);#add dplyr library
library(tidymodels);
library(ggfortify);
#init---- 
#(the 4 dashes after a comment will help you colapse information on your screen. devide it by sections)
options(max.print=500);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf)
datasource <- "../output/csv/"
#data0<-import(list.files(datasource,full.names = T) [9]) is to name files to identify/ specific files
data0<-sapply(list.files(datasource,full.names = T),import) %>% #%>% it is a pipe expression form left to right to continue a command in a new line
  #rename all the objects in data0 to get rid of the prefix "../output/csv/" and suffix ".csv"
  setNames(gsub(paste0("^",datasource,"/{0,1}|\\.csv$"),"",names(.))) #paste0 takes several variable and put them together. "gsubs" sub patterns
#Notes:create_report(dataname ie data0[[file that you want the report from]])
#inside a code a period is interpreted as . Therefore to be interpreted as a period (ie .com) you need to ad \\
#data elements of interest for this project are: patient id, encounter class, description, encounter cost, reason description, type of treatment, type of insurance, from procedure: description, base cost, reason description
#HW what columns you wish to have to be able to analyse (mainly from the encounter table) and add them to a new data frame using ?left_join----
data1<-full_join(data0[["encounters"]], data0[["procedures"]], data0[["conditions"]], by = c("PATIENT", "START", "STOP"), relationship = "many-to-many")
# keep only specific columns
#data1 <- data1 %>%
#  select(PATIENT, START, STOP, PROCEDURE_CODE)
fu<-data0[["conditions"]] %>%View # to view a data frame
#How to find and extract data from a data frame----
# Find matches for diabetes from a data set & extract it to create a new data
filter(data0[["conditions"]], grepl("\\bdiab",DESCRIPTION, ignore.case = TRUE))%>%#grep will let you know the row number were the value is true
    with(data=.,list(patient=unique(PATIENT), encounter=unique(ENCOUNTER)))%>%View()

