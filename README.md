# LGCV_Clinics

Cleaner version of previous LGCM scripts. This project assesses the healthcare utilization of SM following mTBI. Utilization subtypes are evaluated and assessed. 

Next Steps:
1. Evaluate random effects model - GMM that will enable a ZIP or ZINB distribution
  a. This will enable each latent group to have its own intercept and slope at each time period
  NOTE: Might need to refactor the research scope to adapt to any limitations within the package/model
  
  
  
Files:

PreProcess.R - clean and format data long
LGCV_Clinics_Final.R - Run and evaluate models (this file sources PreProcess.R and can take some time)
nb_model_flex.R - negative binomial model specs for models 


Resources:
https://psyarxiv.com/m58wx/

Latent Class Growth Analysis - Fixed effects model
Growth Mixture Modeling - Random effects model



