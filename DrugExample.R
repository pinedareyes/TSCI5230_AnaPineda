library(tidyverse)
library(rio)
library(ggplot2)

# 1) Load your CSV ----
startrow<-import("../../output/LabNotebook_00975151_cc3c267c-7dec-4da5-a4ce-aed5e7a11961mito72hrs(AutoRecovered).xlsx",
                 which = 'Summary Series')[,2] %>% grep('^A1$',.)
df<-import("../../output/LabNotebook_00975151_cc3c267c-7dec-4da5-a4ce-aed5e7a11961mito72hrs(AutoRecovered).xlsx",
           which = 'Summary Series',skip=startrow+1) %>% rename( Hours='...1') %>% 
  pivot_longer(
    cols = -Hours,               # all columns except Hours
    names_to = "Condition",
    values_to = "Resistance"
  ) %>%
  mutate(
    Condition = gsub("\\.{3}\\d+$","",Condition)
  ) %>% 
  #take out empty rows (n/a)
  na.omit() 
df_baseline<-subset(df,Hours==25) %>% group_by(Condition) %>% summarise(baseline=median(Resistance)) %>% 
  right_join(df) %>% mutate(normalize=Resistance-baseline) %>% 
  group_by(Condition,Hours) %>% summarise(across(everything(),mean),.groups = "keep")
#plot results

ggplot(df_baseline,aes(x=Hours,y=normalize,color=Condition))+geom_line()