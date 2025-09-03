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
data0<-sapply(list.files(datasource,full.names = T),import) %>% #%>% it pipes form left to right
  #rename all the objects in data0 to get rid of the prefix "../output/csv/" and suffix ".csv"
  setNames(gsub(paste0("^",datasource,"/{0,1}|\\.csv$"),"",names(.))) #paste0 takes several variable and put them together. "gsubs" sub patterns
#Notes:create_report(dataname ie data0[[file that you want the report from]])
#inside a code a period is interpreted as . Therefore to be interpreted as a period (ie .com) you need to ad \\
#data elements of interest for this project are: ----