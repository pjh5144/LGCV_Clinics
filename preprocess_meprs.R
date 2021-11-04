#Preprocess - Updated

#Updated for the mapping to meprs rather than PRODLINE
#For File LGCM_MEPRS

#Libraries
library(tidyverse)

#Global Scripts
'%ni%' <- Negate('%in%')

#Encounters 
enc<-read.csv("/Users/peterhoover/Documents/Analysis_Projects/R_Scripts/LGCV_Clinics/Data/Processed/enc_db.csv")

#Pt List 
pts<-read.csv("/Users/peterhoover/Documents/Analysis_Projects/R_Scripts/LGCV_Clinics/Data/Processed/pt_updated_demo.csv")
pts<-pts%>%
  mutate(tbi_index=lubridate::ymd(tbi_index))%>%
  filter(tbi_index<'2019-01-01')%>%
  select(-X)

#Data
meprs<-read.csv("/Users/peterhoover/Documents/Analysis_Projects/Global_data/mapping_files/clinics/MEPRS3_Groups_LGCM.csv")%>%
  mutate(Clinic = gsub("Outpatient ","",Classification))%>%
  mutate(Clinic = gsub(" |\\-","_",Clinic))%>%
  mutate(Clinic = gsub("Physucal_Rehabilitation","Physical_Rehab",Clinic))
  
pt_encs<-enc%>%
  filter(pseudo_personid %in% pts$pseudo_personid)%>%
  mutate(meprs3 = substr(meprs4,1,3))%>%
  left_join(meprs[,c("Code","Clinic",'Description')],by=c("meprs3"="Code"))%>%
  mutate(tbi_index_date = lubridate::ymd(tbi_index_date),
         servicedate = lubridate::ymd(servicedate))%>%
  mutate(Month = ceiling(lubridate::time_length(difftime(servicedate,tbi_index_date),"months")))%>%
  filter(tbi_index_date<servicedate)%>%
  filter(!grepl("^A",meprs4))%>% #Remove inpatient MEPRS
  mutate(Clinic = case_when(is.na(Clinic)~"Other",
                            TRUE ~ paste(Clinic)))
  
#Quick Counts

# enc_cnts<-pt_encs%>%
#   group_by(Clinic)%>%
#   summarise(n=n(),pt=length(unique(pseudo_personid)))
# 
# meprs_miss<-read.csv("/Users/peterhoover/Documents/Analysis_Projects/Global_data/mapping_files/clinics/meprs_3.csv")
# 
# pt_encs%>%
#   filter(is.na(Clinic))%>%
#   group_by(meprs3)%>%
#   summarise(n=n())%>%
#   left_join(meprs_miss,by="meprs3")%>%View()
# 
# pt_encs%>%
#   filter(meprs3=="")%>%
#   View()

write.csv(pt_encs,file="/Users/peterhoover/Documents/Analysis_Projects/R_Scripts/LGCV_Clinics/Data/Clean/enc_clean.csv")

## Obtain Long Patient List 

#Every Combination of clinic, pt, month (to obtain blanks)
clinic_cnts<-expand.grid(pseudo_personid=unique(pts$pseudo_personid),Clinic=unique(pt_encs$Clinic),Month=unique(pt_encs$Month))

clinic_pt_cnt<-pt_encs%>%
  group_by(pseudo_personid,Clinic,Month)%>%
  summarise(n=n())%>%
  ungroup()%>%
  right_join(clinic_cnts,by=c("pseudo_personid","Month","Clinic"))%>%
  mutate_at(vars(n), ~replace(.,is.na(.),0))

write.csv(clinic_pt_cnt,file="/Users/peterhoover/Documents/Analysis_Projects/R_Scripts/LGCV_Clinics/Data/Clean/clinic_long.csv")  
write.csv(pts,file="/Users/peterhoover/Documents/Analysis_Projects/R_Scripts/LGCV_Clinics/Data/Clean/pts_filtered.csv")  





