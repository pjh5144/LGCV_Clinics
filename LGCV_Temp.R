#2.3.21

#Begin exploration of LGCM with distributions and functions 
#source("PreProcess.R")


library(ggplot2)

#Subset data for quick modeling
set.seed(111)
 
sam<-sample(unique(clinic_cnts$pseudo_personid),1000) #Sample population for testing 

sample_df<-clinic_cnts%>%
  filter(pseudo_personid %in% sam)

#sample_df<-clinic_cnts #whole population


sample_df$Mon_Flag<-as.numeric(sample_df$Mon_Flag)

#Quick graph of distribution
ggplot(sample_df,aes(x=n))+geom_histogram()+facet_wrap(~prodline)

sample_df%>%
  group_by(prodline,Mon_Flag)%>%summarise(mean=mean(n),med=median(n),sd=sd(n)^2)%>%
  head()

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
#models<-c(FLXMRglm(family="poisson",random=~1),FLXMRziglm(family = "poisson",random=~1),nb=FLXMRnegbin(random=~1))#set models to test 
#models<-c(FLXMRglm(family="poisson",fixed=~Age+Gender),FLXMRziglm(family = "poisson",fixed=~Age+Gender),nb=FLXMRnegbin(fixed=~Age+Gender))#set models to test 

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

save(nb_model1,file="nb_model1.rda")
load("nb_model1.rda")

class_ass<-cbind(sample_df,getModel(nb_model1)@cluster)
class_ass%>%
  distinct(pseudo_personid,`getModel(nb_model1)@cluster`)%>%
  group_by(`getModel(nb_model1)@cluster`)%>%
  summarise(n=n())%>%
  mutate(prop=n/sum(n))

write.csv(class_ass,file="class_assignments.csv")

zip_model1new<-stepFlexmix(n~prodline+Mon_Flag|pseudo_personid,data=sample_df,model=zip,k=2:7)
getModel(zip_model1new)@components
getModel(zip_model1new)


class_ass<-cbind(sample_df,getModel(zip_model1new)@cluster)
class_ass%>%
  distinct(pseudo_personid,`getModel(zip_model1new)@cluster`)%>%
  group_by(`getModel(zip_model1new)@cluster`)%>%
  summarise(n=n())%>%
  mutate(prop=n/sum(n))


p_model1new<-stepFlexmix(n~prodline+Mon_Flag|pseudo_personid,data=sample_df,model=FLXMRglm(family="poisson"),k=2:7)
getModel(p_model1new)@components
getModel(p_model1new)
BIC(getModel(p_model1new))

class_ass<-cbind(sample_df,getModel(p_model1new)@cluster)
class_ass%>%
  distinct(pseudo_personid,`getModel(p_model1new)@cluster`)%>%
  group_by(`getModel(p_model1new)@cluster`)%>%
  summarise(n=n())%>%
  mutate(prop=n/sum(n))



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



test<-class_ass%>%
  group_by(prodline,Mon_Flag,`getModel(nb_model1)@cluster`)%>%
  summarise(min=min(n),max=max(n),mean=mean(n),med=median(n))

names(test)[3]<-"cluster"
ggplot(test,aes(x=Mon_Flag,y=mean))+
  geom_point(aes(color=as.factor(cluster)))+facet_wrap(~prodline)+
  geom_line(aes(color=as.factor(cluster)))












