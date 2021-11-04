---
title: "LGCM_MEPRS"
author: "P. Hoover"
date: "10/26/2021"
output: 
  html_document:
    keep_md: TRUE
    includes:
      in_header: test.html
    theme: flatly
    highlight: tango
---

Below outlines the expansion of the LGCM with the use of MEPRS3. We will attempt to identify and evaluate latent groups among varying healthcare utilization trajectories. 

# Methodology

## Data Sources:

* Direct Care - Inpatient/Outpatient
* Purchase Care - Inpatient/Outpatient

## Sample Population:

1. Identify those with an initial mTBI within DoD (DC/PC/IN/OUT)
2. Verify AD status on index date
3. Verify no more severe dx of TBI within year following index date
4. Verify HC utilization < -365 & > 365 days since index date (actively using system)

## Analysis:

1. Extract all DC Outpatient encounters 1 year following index mTBI
2. Map MEPRS 3 to clinic categories (e.g., MH, Neurology/Pain, Physical/Rehab, etc.)

  * Removed any A-Meprs (Inpatient)
  
3. For each month following index mTBI, sum total number of encounters specific to each clinic
4. EDA on current clinic and sample population
5. Conduct Latent Growth Curve Modeling
6. Conduct Post-hoc analysis - differences among latent groups 






# Demographics

Sample Population: 15146

Gender: <table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> gender </th>
   <th style="text-align:right;"> n </th>
   <th style="text-align:right;"> Prop </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> F </td>
   <td style="text-align:right;"> 3717 </td>
   <td style="text-align:right;"> 24.5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> M </td>
   <td style="text-align:right;"> 11429 </td>
   <td style="text-align:right;"> 75.5 </td>
  </tr>
</tbody>
</table>



Age: <table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> age_grp </th>
   <th style="text-align:right;"> n </th>
   <th style="text-align:right;"> Prop </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 17to24 </td>
   <td style="text-align:right;"> 8570 </td>
   <td style="text-align:right;"> 56.6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 25to34 </td>
   <td style="text-align:right;"> 4265 </td>
   <td style="text-align:right;"> 28.2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 35to44 </td>
   <td style="text-align:right;"> 1745 </td>
   <td style="text-align:right;"> 11.5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 45to54 </td>
   <td style="text-align:right;"> 519 </td>
   <td style="text-align:right;"> 3.4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 55+ </td>
   <td style="text-align:right;"> 47 </td>
   <td style="text-align:right;"> 0.3 </td>
  </tr>
</tbody>
</table>



Ethnicity: <table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> ethnicity </th>
   <th style="text-align:right;"> n </th>
   <th style="text-align:right;"> Prop </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> American Indian/Alaskan Native </td>
   <td style="text-align:right;"> 213 </td>
   <td style="text-align:right;"> 1.4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Asian or Pacific Islander </td>
   <td style="text-align:right;"> 729 </td>
   <td style="text-align:right;"> 4.8 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Black, not Hispanic </td>
   <td style="text-align:right;"> 2616 </td>
   <td style="text-align:right;"> 17.3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hispanic </td>
   <td style="text-align:right;"> 2290 </td>
   <td style="text-align:right;"> 15.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Other </td>
   <td style="text-align:right;"> 407 </td>
   <td style="text-align:right;"> 2.7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Unknown </td>
   <td style="text-align:right;"> 398 </td>
   <td style="text-align:right;"> 2.6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> White, not Hispanic </td>
   <td style="text-align:right;"> 8493 </td>
   <td style="text-align:right;"> 56.1 </td>
  </tr>
</tbody>
</table>



Service: <table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> sponservice_updated </th>
   <th style="text-align:right;"> n </th>
   <th style="text-align:right;"> Prop </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Air Force </td>
   <td style="text-align:right;"> 3274 </td>
   <td style="text-align:right;"> 21.6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Army </td>
   <td style="text-align:right;"> 7382 </td>
   <td style="text-align:right;"> 48.7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Marines </td>
   <td style="text-align:right;"> 1977 </td>
   <td style="text-align:right;"> 13.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Navy </td>
   <td style="text-align:right;"> 2365 </td>
   <td style="text-align:right;"> 15.6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Other_Unknown </td>
   <td style="text-align:right;"> 148 </td>
   <td style="text-align:right;"> 1.0 </td>
  </tr>
</tbody>
</table>



Rank: <table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> rank_class_updated </th>
   <th style="text-align:right;"> n </th>
   <th style="text-align:right;"> Prop </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Cadet </td>
   <td style="text-align:right;"> 1190 </td>
   <td style="text-align:right;"> 7.9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Enlisted, Junior </td>
   <td style="text-align:right;"> 7968 </td>
   <td style="text-align:right;"> 52.6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Enlisted, Senior </td>
   <td style="text-align:right;"> 4377 </td>
   <td style="text-align:right;"> 28.9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Officer, Junior </td>
   <td style="text-align:right;"> 814 </td>
   <td style="text-align:right;"> 5.4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Officer, Senior </td>
   <td style="text-align:right;"> 466 </td>
   <td style="text-align:right;"> 3.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Officer, Warrant </td>
   <td style="text-align:right;"> 155 </td>
   <td style="text-align:right;"> 1.0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Other_Unknown </td>
   <td style="text-align:right;"> 176 </td>
   <td style="text-align:right;"> 1.2 </td>
  </tr>
</tbody>
</table>



# Healthcare Utilization



Total Encounters: 320646

Average (Med) Encounter: 21.17  ( 10 )

Clinic Summary: <table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> Clinic </th>
   <th style="text-align:right;"> mean </th>
   <th style="text-align:right;"> med </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Emergency_Medicine </td>
   <td style="text-align:right;"> 0.46 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> General_Medicine </td>
   <td style="text-align:right;"> 6.37 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Mental_Health </td>
   <td style="text-align:right;"> 4.93 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Neurology_and_Pain </td>
   <td style="text-align:right;"> 0.87 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Non_Clinical_Expenses </td>
   <td style="text-align:right;"> 1.15 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Other </td>
   <td style="text-align:right;"> 0.50 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Physical_Rehab </td>
   <td style="text-align:right;"> 4.33 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sensory_Health </td>
   <td style="text-align:right;"> 0.65 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Specialty_Medicine </td>
   <td style="text-align:right;"> 1.62 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Surgery </td>
   <td style="text-align:right;"> 0.29 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
</tbody>
</table>



Clinic Mappings: <!--html_preserve--><div id="htmlwidget-581a41ae98d805ab08a8" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-581a41ae98d805ab08a8">{"x":{"filter":"none","data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94"],["","BAA","BAB","BAC","BAE","BAF","BAG","BAJ","BAK","BAL","BAM","BAN","BAO","BAP","BAQ","BAR","BAS","BAT","BAV","BAZ","BBA","BBB","BBC","BBD","BBF","BBG","BBI","BBK","BBL","BBM","BBN","BCA","BCB","BCD","BDA","BDB","BDZ","BEA","BED","BEF","BFA","BFB","BFC","BFD","BFE","BFF","BFZ","BGA","BGZ","BHA","BHB","BHC","BHD","BHE","BHF","BHG","BHI","BHZ","BIA","BJA","BKA","BLA","BLB","CAA","DBA","DCA","DDD","DDE","DDZ","DFA","DFB","DFC","DGA","DGE","DHA","DIA","EKA","ELA","FAD","FAH","FAR","FAS","FAZ","FBB","FBE","FBF","FBI","FBL","FBN","FCC","FCD","FCG","FEA","FED"],[null,"OUTPATIENT INTERNAL MEDICINE CLINIC","OUTPATIENT ALLERGY CLINIC","OUTPATIENT CARDIOLOGY CLINIC","OUTPATIENT DIABETIC CLINIC","OUTPATIENT ENDOCRINOLOGY (METABOLISM) CLINIC","OUTPATIENT GASTROENTEROLOGY CLINIC","OUTPATIENT NEPHROLOGY CLINIC","OUTPATIENT NEUROLOGY CLINIC","OUTPATIENT NUTRITION CLINIC &lt;96&gt; INCLUDES OUTPATIENT AND INPATIENT VISITS","OUTPATIENT HEMATOLOGY AND ONCOLOGY CLINIC","OUTPATIENT PULMONARY DISEASE CLINIC","OUTPATIENT RHEUMATOLOGY CLINIC","OUTPATIENT DERMATOLOGY CLINIC","OUTPATIENT INFECTIOUS DISEASE CLINIC","OUTPATIENT PHYSICAL MEDICINE CLINIC","OUTPATIENT RADIATION THERAPY CLINIC","OUTPATIENT BONE MARROW TRANSPLANT CLINIC","OUTPATIENT HYPERBARIC\nMEDICINE","OUTPATIENT MEDICAL CARE NOT ELSEWHERE CLASSIFIED","OUTPATIENT GENERAL SURGERY CLINIC","OUTPATIENT CARDIOVASCULAR &amp; THORACIC SURGERY CLINIC","OUTPATIENT NEUROSURGERY CLINIC","OUTPATIENT OPHTHALMOLOGY CLINIC","OUTPATIENT OTOLARYNGOLOGY CLINIC","OUTPATIENT PLASTIC SURGERY CLINIC","OUTPATIENT UROLOGY CLINIC","OUTPATIENT PERIPHERAL VASCULAR SURGERY CLINIC","OUTPATIENT PAIN MANAGEMENT CLINIC","OUTPATIENT VASCULAR AND INTERVENTIONAL RADIOLOGY CLINIC","OUTPATIENT BURN CLINIC (BROOKE ARMY MEDICAL CENTER ONLY)","OUTPATIENT FAMILY PLANNING CLINIC","OUTPATIENT OBSTETRICS AND GYNECOLOGY CLINIC","OUTPATIENT BREAST CARE CLINIC","OUTPATIENT PEDIATRIC CLINIC","OUTPATIENT PEDIATRIC SUBSPECIALTY CLINIC","OUTPATIENT PEDIATRIC CARE NOT ELSEWHERE CLASSIFIED","OUTPATIENT ORTHOPEDIC CLINIC","OUTPATIENT CHIROPRACTIC CLINIC","OUTPATIENT PODIATRY CLINIC","OUTPATIENT PSYCHIATRY CLINIC","OUTPATIENT PSYCHOLOGY CLINIC","OUTPATIENT CHILD GUIDANCE CLINIC","OUTPATIENT MENTAL HEALTH CLINIC","OUTPATIENT SOCIAL WORK CLINIC","OUTPATIENT SUBSTANCE ABUSE CLINIC","OUTPATIENT PSYCHIATRIC AND MENTAL HEALTHCARE NOT ELSEWHERE CLASSIFIED","OUTPATIENT FAMILY MEDICINE CLINIC","OUTPATIENT FAMILY MEDICINE CARE NOT ELSEWHERE CLASSIFIED","OUTPATIENT PRIMARY CARE CLINICS","OUTPATIENT MEDICAL EXAMINATION CLINIC","OUTPATIENT OPTOMETRY CLINIC","OUTPATIENT AUDIOLOGY CLINIC","OUTPATIENT SPEECH PATHOLOGY CLINIC","OUTPATIENT COMMUNITY HEALTH CLINIC","OUTPATIENT OCCUPATIONAL HEALTH CLINIC","OUTPATIENT IMMEDIATE CARE CLINIC (FOR SITES NOT AUTHORIZED AN EMERGENCY ROOM (ER))","OUTPATIENT PRIMARY MEDICAL CARE NOT ELSEWHERE CLASSIFIED","OUTPATIENT EMERGENCY MEDICAL CLINIC","OUTPATIENT FLIGHT MEDICINE CLINIC","OUTPATIENT UNDERSEAS MEDICINE CLINIC","OUTPATIENT PHYSICAL THERAPY CLINIC","OUTPATIENT OCCUPATIONAL THERAPY CLINIC","DENTAL CARE","CLINICAL PATHOLOGY","DIAGNOSTIC RADIOLOGY","PULMONARY FUNCTION","CARDIAC CATHETERIZATION","SPECIAL PROCEDURES SERVICES NOT ELSEWHERE CLASSIFIED","ANESTHESIOLOGY","SURGICAL SUITE","POST ANESTHESIA CARE UNIT","AMBULATORY PROCEDURE UNIT (APU)","AMBULATORY NURSING SERVICES","RESPIRATORY THERAPY","NUCLEAR MEDICINE CLINIC","AMBULATORY CARE PATIENT ADMINISTRATION","MANAGED CARE ADMINISTRATION","DOD MILITARY BLOOD PROGRAM","CLINICAL INVESTIGATION PROGRAM","CASE MANAGEMENT","BEHAVIORAL HEALTH PROMOTION AND PREVENTION","SPECIAL HEALTH\u0002RELATED PROGRAMS NOT ELSEWHERE CLASSIFIED","PREVENTIVE MEDICINE","ENVIRONMENTAL HEALTH PROGRAM","EPIDEMIOLOGY PROGRAM","IMMUNIZATIONS","MULTI-DISCIPLINARY TEAM SERVICES (MTS)","HEARING CONSERVATION","SUPPORT TO NON\u0002FEDERAL EXTERNAL PROVIDERS","SUPPORT TO OTHER MILITARY ACTIVITIES","SUPPORT TO NON\u0002MEPRS REPORTING ACTIVITIES","AMBULANCE SERVICES","MILITARY PATIENT PERSONNEL ADMINISTRATION"],["Other","General_Medicine","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Neurology_and_Pain","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Physical_Rehab","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","Surgery","Surgery","Neurology_and_Pain","Surgery","Sensory_Health","Surgery","Surgery","Surgery","Neurology_and_Pain","Surgery","Surgery","Specialty_Medicine","Specialty_Medicine","Specialty_Medicine","General_Medicine","Specialty_Medicine","General_Medicine","Physical_Rehab","Physical_Rehab","Physical_Rehab","Mental_Health","Mental_Health","Mental_Health","Mental_Health","Mental_Health","Mental_Health","Mental_Health","General_Medicine","General_Medicine","General_Medicine","General_Medicine","Sensory_Health","Sensory_Health","Sensory_Health","General_Medicine","General_Medicine","General_Medicine","General_Medicine","Emergency_Medicine","Specialty_Medicine","Specialty_Medicine","Physical_Rehab","Physical_Rehab","Specialty_Medicine","Other","Other","Other","Surgery","Other","Surgery","Surgery","Surgery","Surgery","Surgery","Other","Specialty_Medicine","Non_Clinical_Expenses","Non_Clinical_Expenses","Specialty_Medicine","Specialty_Medicine","Mental_Health","Mental_Health","Specialty_Medicine","Non_Clinical_Expenses","Non_Clinical_Expenses","Non_Clinical_Expenses","Non_Clinical_Expenses","Non_Clinical_Expenses","Non_Clinical_Expenses","Other","Other","Other","Non_Clinical_Expenses","Non_Clinical_Expenses"],[500,553,1048,1302,1,356,1124,33,5740,1071,239,2311,221,1783,259,17849,12,3,4,899,1221,8,243,1933,1617,201,769,107,7187,59,2,4,4929,24,21,17,28,8338,2779,1394,1583,302,378,58631,270,8556,1,19849,31014,11684,3777,6830,1008,427,2345,1089,564,25501,6968,7089,271,30013,5257,116,79,66,1,2,6,46,8,31,5,33,52,1,6,6176,2,1411,4,4914,56,1334,321,189,180,3,7678,90,957,5799,14,1470]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>meprs3<\/th>\n      <th>Description<\/th>\n      <th>Clinic<\/th>\n      <th>n<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"columnDefs":[{"className":"dt-right","targets":4},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->







