# create table one for original cohorts
library(tableone)
library(tidyverse)

## 0. load and prep data

# load one-hot encoded data from "cohort_matched.ipynb"
full_data <- read.csv('cohort_final_dummies.csv') # renamed from 'final_table_dummies.csv'


# indicate features
features <- c('admission_age','sofa_score','respiration','coagulation','liver','cardiovascular','cns','renal','weight','congestive_heart_failure','cerebrovascular_disease','chronic_pulmonary_disease','rheumatic_disease','renal_disease','malignant_cancer','severe_liver_disease','charlson_comorbidity_index','heart_rate_min','heart_rate_max','heart_rate_mean','sbp_min','sbp_max','sbp_mean','dbp_max','dbp_min','dbp_mean','mbp_max','mbp_min','mbp_mean','resp_rate_min','resp_rate_max','resp_rate_mean','temperature_min','temperature_max','temperature_mean','spo2_min','spo2_max','spo2_mean','glucose_min','glucose_max','glucose_mean','po2','pco2','ph','baseexcess','bun_min','bun_max','creatinine_min','creatinine_max','sodium_min','sodium_max','potassium_min','potassium_max','gcs_min','oasis','oasis_prob','ventilation','gender_F','gender_M','race_AMERICAN.INDIAN.ALASKA.NATIVE','race_ASIAN','race_ASIAN...ASIAN.INDIAN','race_ASIAN...CHINESE','race_ASIAN...KOREAN','race_ASIAN...SOUTH.EAST.ASIAN','race_BLACK.AFRICAN','race_BLACK.AFRICAN.AMERICAN','race_BLACK.CAPE.VERDEAN','race_BLACK.CARIBBEAN.ISLAND','race_HISPANIC.OR.LATINO','race_HISPANIC.LATINO...CENTRAL.AMERICAN','race_HISPANIC.LATINO...COLUMBIAN','race_HISPANIC.LATINO...CUBAN','race_HISPANIC.LATINO...DOMINICAN','race_HISPANIC.LATINO...GUATEMALAN','race_HISPANIC.LATINO...HONDURAN','race_HISPANIC.LATINO...MEXICAN','race_HISPANIC.LATINO...PUERTO.RICAN','race_HISPANIC.LATINO...SALVADORAN','race_MULTIPLE.RACE.ETHNICITY','race_NATIVE.HAWAIIAN.OR.OTHER.PACIFIC.ISLANDER','race_OTHER','race_PATIENT.DECLINED.TO.ANSWER','race_PORTUGUESE','race_SOUTH.AMERICAN','race_UNABLE.TO.OBTAIN','race_UNKNOWN','race_WHITE','race_WHITE...BRAZILIAN','race_WHITE...EASTERN.EUROPEAN','race_WHITE...OTHER.EUROPEAN','race_WHITE...RUSSIAN')
tab <- CreateTableOne(vars = features, strata = 'treatment', data=full_data, argsNormal = list(var.equal=FALSE))
capture.output(tab_df <- tab %>%
  print(smd = TRUE) %>%
  as.data.frame(stringsAsFactors = FALSE) %>%
  select(-test)) %>% invisible
# write.csv(tab_df, "original_tableone.csv")
write.csv(tab_df, "table1_cohort_final.csv")


## 1. doubly robust with unbalanced covariates
full_data <- read.csv('cohort_final_dummies.csv')
outcome = full_data$X28_mortality
treatment = full_data$treatment
weight = full_data$weight
cere = full_data$cerebrovascular_disease
chronic = full_data$chronic_pulmonary_disease
heart = full_data$heart_rate_mean
respmax = full_data$resp_rate_max
respmean = full_data$resp_rate_mean
spomin = full_data$spo2_min
spomax = full_data$spo2_max
spomean = full_data$spo2_mean
glumin = full_data$glucose_min
po2 = full_data$po2
pco2 = full_data$pco2
ph = full_data$ph

dr_model_unbalanced <- glm(outcome~treatment+weight+cere+chronic+heart+respmax+respmean+spomin+spomax+spomean+glumin+po2+pco2+ph, family = binomial(),data=full_data)
summary(dr_model_unbalanced)

exp(cbind(OR = coef(dr_model_unbalanced), confint(dr_model_unbalanced)))

## 2. doubly robust with all covariates

# create tableone for matched data
library(tableone)
library(tidyverse)
matched_data<- read.csv("cohort_matched.csv", header = TRUE)
features <- c('admission_age', 'sofa_score', 'respiration',
              'coagulation', 'liver', 'cardiovascular', 'cns', 'renal', 'weight',
              'congestive_heart_failure', 'cerebrovascular_disease',
              'chronic_pulmonary_disease', 'rheumatic_disease', 'renal_disease',
              'malignant_cancer', 'severe_liver_disease',
              'charlson_comorbidity_index', 'heart_rate_min', 'heart_rate_max',
              'heart_rate_mean', 'sbp_min', 'sbp_max', 'sbp_mean', 'dbp_max',
              'dbp_min', 'dbp_mean', 'mbp_max', 'mbp_min', 'mbp_mean',
              'resp_rate_min', 'resp_rate_max', 'resp_rate_mean', 'temperature_min',
              'temperature_max', 'temperature_mean', 'spo2_min', 'spo2_max',
              'spo2_mean', 'glucose_min', 'glucose_max', 'glucose_mean', 'po2',
              'pco2', 'ph', 'baseexcess', 'bun_min', 'bun_max', 'creatinine_min',
              'creatinine_max', 'sodium_min', 'sodium_max', 'potassium_min',
              'potassium_max', 'gcs_min', 'oasis', 'oasis_prob', 'ventilation',
              'gender_F', 'gender_M', 'race_AMERICAN INDIAN/ALASKA NATIVE',
              'race_ASIAN', 'race_ASIAN - ASIAN INDIAN', 'race_ASIAN - CHINESE',
              'race_ASIAN - KOREAN', 'race_ASIAN - SOUTH EAST ASIAN',
              'race_BLACK/AFRICAN', 'race_BLACK/AFRICAN AMERICAN',
              'race_BLACK/CAPE VERDEAN', 'race_BLACK/CARIBBEAN ISLAND',
              'race_HISPANIC OR LATINO', 'race_HISPANIC/LATINO - CENTRAL AMERICAN',
              'race_HISPANIC/LATINO - COLUMBIAN', 'race_HISPANIC/LATINO - CUBAN',
              'race_HISPANIC/LATINO - DOMINICAN', 'race_HISPANIC/LATINO - GUATEMALAN',
              'race_HISPANIC/LATINO - HONDURAN', 'race_HISPANIC/LATINO - MEXICAN',
              'race_HISPANIC/LATINO - PUERTO RICAN',
              'race_HISPANIC/LATINO - SALVADORAN', 'race_MULTIPLE RACE/ETHNICITY',
              'race_NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER', 'race_OTHER',
              'race_PATIENT DECLINED TO ANSWER', 'race_PORTUGUESE',
              'race_SOUTH AMERICAN', 'race_UNABLE TO OBTAIN', 'race_UNKNOWN',
              'race_WHITE', 'race_WHITE - BRAZILIAN', 'race_WHITE - EASTERN EUROPEAN',
              'race_WHITE - OTHER EUROPEAN', 'race_WHITE - RUSSIAN')
tab <- CreateTableOne(vars = features,
                      strata = "treatment",
                      data = matched_data,
                      argsNormal = list(var.equal = FALSE))
# tab_df is tableone
capture.output(tab_df <- tab %>%
                 print(smd = TRUE) %>%
                 as.data.frame(stringsAsFactors = FALSE) %>%
                 select(-test)) %>% invisible

write.csv(tab_df, "table1_cohort_matched.csv")


# doubly robust estimation with all covariates
dr_model_all <- glm(X28_mortality ~ treatment + admission_age+sofa_score+respiration+coagulation+liver+cardiovascular+cns+renal+weight+congestive_heart_failure+cerebrovascular_disease+chronic_pulmonary_disease+rheumatic_disease+renal_disease+malignant_cancer+severe_liver_disease+charlson_comorbidity_index+heart_rate_min+heart_rate_max+heart_rate_mean+sbp_min+sbp_max+sbp_mean+dbp_max+dbp_min+dbp_mean+mbp_max+mbp_min+mbp_mean+resp_rate_min+resp_rate_max+resp_rate_mean+temperature_min+temperature_max+temperature_mean+spo2_min+spo2_max+spo2_mean+glucose_min+glucose_max+glucose_mean+po2+pco2+ph+baseexcess+bun_min+bun_max+creatinine_min+creatinine_max+sodium_min+sodium_max+potassium_min+potassium_max+gcs_min+oasis+oasis_prob+ventilation+gender_F+gender_M+race_AMERICAN.INDIAN.ALASKA.NATIVE+race_ASIAN+race_ASIAN...ASIAN.INDIAN+race_ASIAN...CHINESE+race_ASIAN...KOREAN+race_ASIAN...SOUTH.EAST.ASIAN+race_BLACK.AFRICAN+race_BLACK.AFRICAN.AMERICAN+race_BLACK.CAPE.VERDEAN+race_BLACK.CARIBBEAN.ISLAND+race_HISPANIC.OR.LATINO+race_HISPANIC.LATINO...CENTRAL.AMERICAN+race_HISPANIC.LATINO...COLUMBIAN+race_HISPANIC.LATINO...CUBAN+race_HISPANIC.LATINO...DOMINICAN+race_HISPANIC.LATINO...GUATEMALAN+race_HISPANIC.LATINO...HONDURAN+race_HISPANIC.LATINO...MEXICAN+race_HISPANIC.LATINO...PUERTO.RICAN+race_HISPANIC.LATINO...SALVADORAN+race_MULTIPLE.RACE.ETHNICITY+race_NATIVE.HAWAIIAN.OR.OTHER.PACIFIC.ISLANDER+race_OTHER+race_PATIENT.DECLINED.TO.ANSWER+race_PORTUGUESE+race_SOUTH.AMERICAN+race_UNABLE.TO.OBTAIN+race_UNKNOWN+race_WHITE+race_WHITE...BRAZILIAN+race_WHITE...EASTERN.EUROPEAN+race_WHITE...OTHER.EUROPEAN+race_WHITE...RUSSIAN, family = quasibinomial, data = matched_data)
summary(dr_model_all)
confint(dr_model_all, parm = "treatment", level = 0.95)


## 2. doubly robust estimation-PSM
ps_matched_model <- glm(X28_mortality ~ treatment, family = binomial(), data = matched_data)
summary(ps_matched_model)
confint(ps_matched_model, parm = "treatment", level = 0.95)



# 3. Propensity score with IPW
library(MatchIt)

ps_model <- glm(treatment ~ admission_age+sofa_score+respiration+coagulation+liver+cardiovascular+cns+renal+weight+congestive_heart_failure+cerebrovascular_disease+chronic_pulmonary_disease+rheumatic_disease+renal_disease+malignant_cancer+severe_liver_disease+charlson_comorbidity_index+heart_rate_min+heart_rate_max+heart_rate_mean+sbp_min+sbp_max+sbp_mean+dbp_max+dbp_min+dbp_mean+mbp_max+mbp_min+mbp_mean+resp_rate_min+resp_rate_max+resp_rate_mean+temperature_min+temperature_max+temperature_mean+spo2_min+spo2_max+spo2_mean+glucose_min+glucose_max+glucose_mean+po2+pco2+ph+baseexcess+bun_min+bun_max+creatinine_min+creatinine_max+sodium_min+sodium_max+potassium_min+potassium_max+gcs_min+oasis+oasis_prob+ventilation+gender_F+gender_M+race_AMERICAN.INDIAN.ALASKA.NATIVE+race_ASIAN+race_ASIAN...ASIAN.INDIAN+race_ASIAN...CHINESE+race_ASIAN...KOREAN+race_ASIAN...SOUTH.EAST.ASIAN+race_BLACK.AFRICAN+race_BLACK.AFRICAN.AMERICAN+race_BLACK.CAPE.VERDEAN+race_BLACK.CARIBBEAN.ISLAND+race_HISPANIC.OR.LATINO+race_HISPANIC.LATINO...CENTRAL.AMERICAN+race_HISPANIC.LATINO...COLUMBIAN+race_HISPANIC.LATINO...CUBAN+race_HISPANIC.LATINO...DOMINICAN+race_HISPANIC.LATINO...GUATEMALAN+race_HISPANIC.LATINO...HONDURAN+race_HISPANIC.LATINO...MEXICAN+race_HISPANIC.LATINO...PUERTO.RICAN+race_HISPANIC.LATINO...SALVADORAN+race_MULTIPLE.RACE.ETHNICITY+race_NATIVE.HAWAIIAN.OR.OTHER.PACIFIC.ISLANDER+race_OTHER+race_PATIENT.DECLINED.TO.ANSWER+race_PORTUGUESE+race_SOUTH.AMERICAN+race_UNABLE.TO.OBTAIN+race_UNKNOWN+race_WHITE+race_WHITE...BRAZILIAN+race_WHITE...EASTERN.EUROPEAN+race_WHITE...OTHER.EUROPEAN+race_WHITE...RUSSIAN, data=full_data)

full_data$ipw <- ifelse(full_data$treatment == 1,
  1 / ps_model$fitted.values,
  1 / (1 - ps_model$fitted.values))

lower_limit <- quantile(full_data$ipw, 0.01)
upper_limit <- quantile(full_data$ipw, 0.99)
# negative weights not allowed
full_data$ipw_truncated <- ifelse(full_data$ipw < lower_limit, lower_limit, ifelse(full_data$ipw > upper_limit, upper_limit, full_data$ipw))

weighted_logistic_model <- glm(outcome ~ treatment, data = full_data, weights = full_data$ipw_truncated, family = "binomial")

summary(weighted_logistic_model)

exp(cbind(OR = coef(weighted_logistic_model), confint(weighted_logistic_model)))

# 4. Propensity score matching

logitstic = glm(outcome~treatment, data = full_data, family="binomial")
summary(logitstic)
exp(cbind(OR = coef(logitstic), confint(logitstic)))












