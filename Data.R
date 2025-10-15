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
datasource <- "./output/csv/"
check_unique <- function(xx){xx} == {nrow(unique(xx))}

rxnorm <- "./output/Metformin_RxNav_6809_table.csv"
rxnorm_lookup<-import(rxnorm,skip=2) %>% 
  filter(.,termType %in% c("BN","IN","MIN","PIN","SBD","SBDC","SBDF","SBDFP","SBDG","SCD","SCDC","SCDF","SCDG"))
#data0<-import(list.files(datasource,full.names = T) [9]) is to name files to identify/ specific files
data0<-sapply(list.files(datasource,full.names = T),import) %>% #%>% it is a pipe expression form left to right to continue a command in a new line
  #rename all the objects in data0 to get rid of the prefix "../output/csv/" and suffix ".csv"
  setNames(gsub(paste0("^",datasource,"/{0,1}|\\.csv$"),"",names(.))) #paste0 takes several variable and put them together. "gsubs" sub patterns
#Notes:create_report(dataname ie data0[[file that you want the report from]])
#inside a code a period is interpreted as . Therefore to be interpreted as a period (ie .com) you need to ad \\
#data elements of interest for this project are: patient id, encounter class, description, encounter cost, reason description, type of treatment, type of insurance, from procedure: description, base cost, reason description
#HW what columns you wish to have to be able to analyse (mainly from the encounter table) and add them to a new data frame using ?left_join----
#data1<-full_join(data0[["encounters"]], data0[["procedures"]], data0[["conditions"]], by = c("PATIENT", "START", "STOP"), relationship = "many-to-many")
# keep only specific columns
#data1 <- data1 %>%
#  select(PATIENT, START, STOP, PROCEDURE_CODE)
#How to find and extract data from a data frame----
# Find matches for diabetes from a data set & extract it to create a new data---- 
#grep will let you know the row number were the value is true & grepl will just give you TRUE or FALSE
criteria <- filter(data0[["conditions"]], grepl("\\bdiab",DESCRIPTION, ignore.case = TRUE)) %>% 
    with(data=.,list(patient_diabetes=unique(PATIENT ), encounter_diabetes=unique(ENCOUNTER)))
#Id <- data0$patients$Id 
#Id %in% criteria$patient_diabetes
data_diab_patients <- data0[["patients"]] %>% 
  filter(Id %in% criteria$patient_diabetes)
data_diab_encounters <- data0[["encounters"]] %>% 
  filter(Id %in% criteria$encounter_diabetes)
setdiff(criteria$patient_diabetes,data_diab_encounters$PATIENT) #this is a way to validate if there is not data missing
setdiff(data_diab_encounters$PATIENT,criteria$patient_diabetes)
data_diab_patient_encounters <- left_join(data_diab_patients, data_diab_encounters, by=c("Id"="PATIENT")) %>%
  mutate(ENCOUNTER=Id.y) 
# this a way to validate your join and stop the script if the result isn’t what you expect ----
if (nrow(data_diab_patient_encounters) != nrow(data_diab_encounters)) {
  stop("Join rows do not match the patient dataset")
} else {
  message("All clear")
}
med_met <- filter(data0$medications, CODE %in% rxnorm_lookup$rxcui)
data_diab_encountersmet<-left_join(data_diab_patient_encounters,med_met,by=c("ENCOUNTER"="ENCOUNTER")) #table with medication, demographics & encounters

#age distribution (average, min, max)
data0$patients %>% mutate(DEATHDATE=as.Date(DEATHDATE),BIRTHDATE=as.Date(BIRTHDATE),
                            alive=is.na(DEATHDATE),
                          enddate=(pmin(Sys.Date(),DEATHDATE,na.rm = TRUE)),
                            age=as.numeric(enddate-BIRTHDATE)/365.25)%>%
  group_by(alive) %>% 
      summarize(
      avg_age = mean (age, na.rm=TRUE), 
      min_age=min(age,na.rm=TRUE), 
      max_age=max(age,na.rm=TRUE),
      count=n())
#criteria1 <- data0[["encounters"]], grepl("\\bdiab",REASONDESCRIPTION, ignore.case = TRUE))%>%
#    with(data=.,list(patient=unique(PATIENT), id=unique(Id)));%>%
#  (data0[["medications"]], grepl("\\bdiab",REASONDESCRIPTION, ignore.case = TRUE))%>%
#    with(data=.,list(patient=unique(PATIENT), encounter=unique(ENCOUNTER)));
#.criteria4<-filter(data0[["observations"]], grepl("\\bdiab",DESCRIPTION, ignore.case = TRUE))%>%
#    with(data=.,list(patient=unique(PATIENT), encounter=unique(ENCOUNTER)))
#.criteria5<-filter(data0[["procedures"]], grepl("\\bdiab",REASONDESCRIPTION, ignore.case = TRUE))%>%
#    with(data=.,list(patient=unique(PATIENT), encounter=unique(ENCOUNTER)))
#.diabetesjunk<-Reduce(intersect,list(.criteria1 & .criteria2 & .criteria3 & .criteria4 & .criteria5))
