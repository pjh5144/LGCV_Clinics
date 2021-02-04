#This preprocessing script is used to create features which will be used to explore HC utilization
#Data originally extracted for cost exploration - can expand at later date 

#Libraries
library(tidyverse)
library(ggplot2)

#Global Scripts
'%ni%' <- Negate('%in%')

#Dependencies
comp_mh<-read.csv("/Users/peterhoover/Documents/Analysis_Projects/Global_data/mapping_files/symp/comparre_MH_final.csv")
edc<-read.csv("/Users/peterhoover/Documents/Analysis_Projects/Global_data/mapping_files/symp/edc_merged.csv")

#Data
#Patient with tbi 2016-2017, initial mtbi, no susbsequent tbi, no person hx tbi, and HC utilization > and < 365 from index date 
pts<-data.table::fread("/Users/peterhoover/Documents/Analysis_Projects/Global_data/cost/clean/perPatientTotals_proj.csv")
encs<-data.table::fread("/Users/peterhoover/Documents/Analysis_Projects/Global_data/cost/clean/tbi_enc_proj.csv")

#Recode prodline (SURGSUB)

encs<-encs%>%
  mutate(prodline = case_when(prodline=="SURGSUB"~ "SURG",
                              TRUE ~ paste(prodline)))

#Create Clinic Frequencies Post-mTBI 
clinics<-encs%>%
  filter(enc_flag=="Post")%>%
  mutate(Mon_Flag = floor(daydiff/30))%>%
  group_by(pseudo_personid,Mon_Flag,prodline)%>%
  summarise(n=n())

clinic_cnts<-expand.grid(pseudo_personid=unique(pts$pseudo_personid),prodline=unique(encs$prodline),Mon_Flag=unique(clinics$Mon_Flag))

clinic_cnts<-left_join(clinic_cnts,clinics,by=c("pseudo_personid","Mon_Flag","prodline"))

clinic_cnts$n[is.na(clinic_cnts$n)]<-0

#Verify and explore counts

length(unique(clinic_cnts$pseudo_personid))
unique(clinic_cnts$prodline)

clinic_cnts%>%
  group_by(prodline)%>%
  summarise(min=min(n),mean=mean(n),med=median(n),max=max(n))





