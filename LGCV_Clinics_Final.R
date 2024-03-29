#Finalized LGCV For Clinic Utilization Following mTBI
#3.17.21

source("PreProcess.R")

library(ggplot2)

#Subset data for quick modeling
set.seed(111)
sam<-sample(unique(clinic_cnts$pseudo_personid),1000) #Sample population for testing 
sample_df<-clinic_cnts%>%
  filter(pseudo_personid %in% sam)

#sample_df<-clinic_cnts #whole population

sample_df$Mon_Flag<-as.numeric(sample_df$Mon_Flag)

#Quick graph of distribution
#ggplot(sample_df,aes(x=n))+geom_histogram()+facet_wrap(~prodline)

#sample_df%>%
#  group_by(prodline,Mon_Flag)%>%summarise(mean=mean(n),med=median(n),sd=sd(n)^2)%>%
#  head()

#######################
###Model Evaluations###
#######################

flxctrl<-list(classify="hard")

library(countreg)
library(pscl)
library(flexmix)
source("nb_model_flex.R")

zip<-FLXMRziglm(family = "poisson")
zinb<-FLXMRziglm(family = "binomial")

nb=FLXMRnegbin()

#1a  Unconditional means (UM) model to verify distribution
# Intercept-only model (no time)
# Baseline for unconditional growth model

models<-c(FLXMRglm(family="poisson"),FLXMRziglm(family = "poisson"),nb=FLXMRnegbin())
models<-c(FLXMRglm(family="poisson"),FLXMRziglm(family = "poisson"),FLXMRnegbin(),zinb)#set models to test 

m0<-flexmix(n~Mon_Flag|pseudo_personid,data=sample_df,model=models[1],k=2)

m1<-flexmix(n~Mon_Flag|pseudo_personid,data=sample_df,model=models[2],k=2)

table(m0@cluster)


un_review<-data.frame()

for(i in 1:length(models)){
  m0<-flexmix(n~1,data=sample_df,model=models[i],k=1)
  if(length(un_review)==0){
    un_review<-cbind(AIC(m0),BIC(m0),ICL(m0))
  }
  else{
    un_review<-rbind(un_review,cbind(AIC(m0),BIC(m0),ICL(m0)))
  }
}

un_review #NB appears to fit unconditional model best 



#2a Unconditional with time 

unt_reviewa<-data.frame()

for(i in 1:length(models)){
  m0<-flexmix(n~Mon_Flag,data=sample_df,model=models[i],k=1)
  if(length(unt_reviewa)==0){
    unt_reviewa<-cbind(AIC(m0),BIC(m0),ICL(m0))
  }
  else{
    unt_reviewa<-rbind(unt_reviewa,cbind(AIC(m0),BIC(m0),ICL(m0)))
  }
}

unt_reviewa


#2b Unconditional quad time 
unt_reviewb<-data.frame()

for(i in 1:length(models)){
  m0<-flexmix(n~Mon_Flag+I(Mon_Flag^2),data=sample_df,model=models[i],k=1)
  if(length(unt_reviewb)==0){
    unt_reviewb<-cbind(AIC(m0),BIC(m0),ICL(m0))
  }
  else{
    unt_reviewb<-rbind(unt_reviewb,cbind(AIC(m0),BIC(m0),ICL(m0)))
  }
}

unt_reviewb


#2c Unconditional poly time 
unt_reviewc<-data.frame()

for(i in 1:length(models)){
  m0<-flexmix(n~Mon_Flag+I(Mon_Flag^3),data=sample_df,model=models[i],k=1)
  if(length(unt_reviewc)==0){
    unt_reviewc<-cbind(AIC(m0),BIC(m0),ICL(m0))
  }
  else{
    unt_reviewc<-rbind(unt_reviewc,cbind(AIC(m0),BIC(m0),ICL(m0)))
  }
}

unt_reviewc



#3 Conditional Models

con_reviewa<-data.frame()

for(i in 1:length(models)){
  m0<-flexmix(n~Mon_Flag|pseudo_personid,data=sample_df,model=models[i],k=1)
  if(length(con_reviewa)==0){
    con_reviewa<-cbind(AIC(m0),BIC(m0),ICL(m0))
  }
  else{
    con_reviewa<-rbind(con_reviewa,cbind(AIC(m0),BIC(m0),ICL(m0)))
  }
}

con_reviewa

con_reviewb<-data.frame()

for(i in 1:length(models)){
  m0<-flexmix(n~prodline|pseudo_personid,data=sample_df,model=models[i],k=1)
  if(length(con_reviewa)==0){
    con_reviewb<-cbind(AIC(m0),BIC(m0),ICL(m0))
  }
  else{
    con_reviewb<-rbind(con_reviewb,cbind(AIC(m0),BIC(m0),ICL(m0)))
  }
}

con_reviewb

#Finalized Model from flexmix auto

nb_model1<-stepFlexmix(n~(Mon_Flag+prodline)|pseudo_personid,data=sample_df,model=nb,k=2:7)
getModel(nb_model1)
getModel(nb_model1)@components

class_ass<-cbind(sample_df,getModel(nb_model1)@cluster)
class_ass%>%
  distinct(pseudo_personid,`getModel(nb_model1)@cluster`)%>%
  group_by(`getModel(nb_model1)@cluster`)%>%
  summarise(n=n())%>%
  mutate(prop=n/sum(n))



nb_model2<-stepFlexmix(count~variable+Time|PersonID,data=sample_df,model=nb,k=2:7,control=list(minprior=0,classify="hard"))


# zip_model1new<-stepFlexmix(n~prodline+Mon_Flag|pseudo_personid,data=sample_df,model=zip,k=2:7)
# getModel(zip_model1new)@components
# getModel(zip_model1new)
# 
# 
# class_ass<-cbind(sample_df,getModel(zip_model1new)@cluster)
# class_ass%>%
#   distinct(pseudo_personid,`getModel(zip_model1new)@cluster`)%>%
#   group_by(`getModel(zip_model1new)@cluster`)%>%
#   summarise(n=n())%>%
#   mutate(prop=n/sum(n))
# 
# 
# p_model1new<-stepFlexmix(n~prodline+Mon_Flag|pseudo_personid,data=sample_df,model=FLXMRglm(family="poisson"),k=2:7)
# getModel(p_model1new)@components
# getModel(p_model1new)
# BIC(getModel(p_model1new))
# 
# class_ass<-cbind(sample_df,getModel(p_model1new)@cluster)
# class_ass%>%
#   distinct(pseudo_personid,`getModel(p_model1new)@cluster`)%>%
#   group_by(`getModel(p_model1new)@cluster`)%>%
#   summarise(n=n())%>%
#   mutate(prop=n/sum(n))



save(nb_model1new,file="Stored_Models/nb_model1new.rda")
load("Stored_Models/nb_model1new.rda")

nb_model1new2<-stepFlexmix(count~variable+Time|PersonID,data=sample_df,model=nb,k=2:7,nrep=5,control=list(minprior=0))
save(nb_model1new2,file="Stored_Models/nb_model1new2.rda")
load("Stored_Models/nb_model1new2.rda")
refit(getModel(nb_model1new2))

pos_model1new3<-stepFlexmix(count~variable+Time|PersonID,data=sample_df,model=FLXMRglm(family="poisson"),k=1:7)
save(pos_model1new3,file="Stored_Models/pos_model1new3.rda")
load("Stored_Models/pos_model1new3.rda")

plot(p_model1new)
summary(getModel(p_model1new))
plot(getModel(p_model1new))

nb_model1
getModel(nb_model1)
plot(logLik(nb_model1))

nb_model1new
getModel(nb_model1new)
plot(BIC(nb_model1new))

nb_model1new2
getModel(nb_model1new2)
plot(ICL(nb_model1new2))


###############################
### Final Class Comparisons ###
###############################

names(class_ass)[5]<-"cluster"
class_sum<-class_ass%>%
  group_by(prodline,Mon_Flag,cluster)%>%
  summarise(min=min(n),max=max(n),mean=mean(n),med=median(n))

ggplot(class_sum,aes(x=Mon_Flag,y=mean))+
  geom_point(aes(color=as.factor(cluster)))+facet_wrap(~prodline)+
  geom_line(aes(color=as.factor(cluster)))

ggplot(class_sum,aes(x=Mon_Flag,y=median))+
  geom_point(aes(color=as.factor(cluster)))+facet_wrap(~prodline)+
  geom_line(aes(color=as.factor(cluster)))


class_distinct<-class_ass%>%
  distinct(pseudo_personid,cluster)

pts_final<-pts%>%
  select(pseudo_personid,gender,ethnicity,age,sponservice)%>%
  inner_join(class_distinct,by="pseudo_personid")%>%
  mutate(sponservice=case_when(sponservice==""~"X",
                               TRUE ~ paste(sponservice)))

#Gender
pts_final%>%
  group_by(cluster,gender)%>%
  summarise(n=n())%>%
  mutate(Prop=round(n/sum(n)*100,2))%>%
  reshape2::dcast(gender~cluster,value.var="Prop")

prop.test(table(pts_final$cluster,pts_final$gender))

#Age

pts_final%>%
  group_by(cluster)%>%
  summarise(min=min(age),mean=mean(age),max=max(age))

aov_1<-aov(age~as.factor(cluster),data=pts_final)

summary(aov_1)

TukeyHSD(aov_1)

#Ethnicity

pts_final%>%
  group_by(cluster,ethnicity)%>%
  summarise(n=n())%>%
  ungroup()%>%
  group_by(cluster)%>%
  #group_by(ethnicity)%>%
  mutate(Prop=round(n/sum(n)*100,2))%>%
  reshape2::dcast(ethnicity~cluster,value.var="Prop")

#prop.test(table(pts_final$cluster,pts_final$ethnicity))


#BoS

pts_final%>%
  group_by(cluster,sponservice)%>%
  summarise(n=n())%>%
  ungroup()%>%
  group_by(cluster)%>%
  #group_by(sponservice)%>%
  mutate(Prop=round(n/sum(n)*100,2))%>%
  reshape2::dcast(sponservice~cluster,value.var="Prop")







