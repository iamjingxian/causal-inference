DROP TABLE IF EXISTS mimiciv_derived.steroid; CREATE TABLE mimiciv_derived.steroid AS
WITH st AS (
    SELECT DISTINCT
        drug
        , route
        , CASE
            WHEN LOWER(drug) LIKE '%betamethasone%' THEN 1
            WHEN LOWER(drug) LIKE '%cortisone%' THEN 1
            WHEN LOWER(drug) LIKE '%dexamethasone%' THEN 1
            WHEN LOWER(drug) LIKE '%decadron%' THEN 1
            WHEN LOWER(drug) LIKE '%hydrocortisone%' THEN 1
            WHEN LOWER(drug) LIKE '%methylprednisolone%' THEN 1
            WHEN LOWER(drug) LIKE '%prednisolone%' THEN 1
            WHEN LOWER(drug) LIKE '%prednisone%' THEN 1
            WHEN LOWER(drug) LIKE '%triamcinolone%' THEN 1
            ELSE 0
        END AS steroid 
    FROM mimiciv_hosp.prescriptions

	-- excludes vials/syringe/normal saline, etc
    WHERE drug_type NOT IN ('BASE')
        -- we exclude routes via the eye, ears, or topically
        AND route NOT IN ('OU', 'OS', 'OD', 'AU', 'AS', 'AD', 'TP')
        AND LOWER(route) NOT LIKE '%ear%'
        AND LOWER(route) NOT LIKE '%eye%'
        -- we exclude certain types of antibiotics: topical creams,
        -- gels, desens, etc
        AND LOWER(drug) NOT LIKE '%cream%'
        AND LOWER(drug) NOT LIKE '%desensitization%'
        AND LOWER(drug) NOT LIKE '%ophth oint%'
        AND LOWER(drug) NOT LIKE '%gel%'
-- other routes not sure about...
-- for sure keep: ('IV','PO','PO/NG','ORAL', 'IV DRIP', 'IV BOLUS')
-- ? VT, PB, PR, PL, NS, NG, NEB, NAS, LOCK, J TUBE, IVT
-- ? IT, IRR, IP, IO, INHALATION, IN, IM
-- ? IJ, IH, G TUBE, DIALYS
-- ?? enemas??
)

SELECT
    pr.subject_id, pr.hadm_id
    , ie.stay_id
    , pr.drug AS steroid 
    , pr.route
    , pr.starttime
    , pr.stoptime
FROM mimiciv_hosp.prescriptions pr
-- inner join to subselect to only *steroid* prescriptions
INNER JOIN st
    ON pr.drug = st.drug
        -- route is never NULL for antibiotics
        -- only ~4000 null rows in prescriptions total.
        AND pr.route = st.route
-- add in stay_id as we use this table for sepsis-3
LEFT JOIN mimiciv_icu.icustays ie
    ON pr.hadm_id = ie.hadm_id
        AND pr.starttime >= ie.intime
        AND pr.starttime < ie.outtime
WHERE st.steroid = 1
;
DROP TABLE IF EXISTS mimiciv_derived.steroid_first_dose;
CREATE TABLE mimiciv_derived.steroid_first_dose AS
SELECT distinct s1.hadm_id, s1.starttime AS steroid_first_dose_time
FROM mimiciv_derived.steroid s1
INNER JOIN (
  SELECT hadm_id, MIN(starttime) AS earliest_starttime
  FROM mimiciv_derived.steroid
  GROUP BY hadm_id
) s2 ON s1.hadm_id = s2.hadm_id AND s1.starttime = s2.earliest_starttime;

select distinct hadm_id
from mimiciv_derived.steroid




with endtime(hadm_id, steroid_first_stop_time) as (select distinct hadm_id, min(stoptime) as steroid_first_stop_time
from mimiciv_derived.steroid_first_dose
group by hadm_id)
select distinct *
from mimiciv_derived.steroid_first_dose, endtime
where mimiciv_derived.steroid_first_dose.hadm_id = endtime.hadm_id and mimiciv_derived.steroid_first_dose.stoptime = endtime.steroid_first_stop_time

DROP TABLE IF EXISTS mimiciv_derived.cohort_steroid;
create table mimiciv_derived.cohort_steroid as
select distinct *
from mimiciv_derived.steroid_first_dose
where hadm_id in (select distinct hadm_id 
				 from mimiciv_derived.cohort)
				 
create table mimiciv_derived.cohort_first_dose as
select cohort.*, steroid.steroid_first_dose_time
from mimiciv_derived.cohort cohort left join mimiciv_derived.cohort_steroid steroid on cohort.hadm_id = steroid.hadm_id

create table mimiciv_derived.temp2 as
select *
from mimiciv_derived.cohort_first_dose
where DATE_PART('day', icu_intime::timestamp - steroid_first_dose_time::timestamp) * 24 + DATE_PART('hour', icu_intime::timestamp - steroid_first_dose_time::timestamp) > 24 

create table mimiciv_derived.final_cohort as
select *
from mimiciv_derived.cohort_first_dose
where hadm_id not in (select hadm_id from mimiciv_derived.temp2) and DATE_PART('day', icu_outtime::timestamp - icu_intime::timestamp) * 24 + DATE_PART('hour', icu_outtime::timestamp - icu_intime::timestamp) > 24 

create table weight as 
select stay_id, weight
from mimiciv_derived.weight_durations
where weight_type = 'admit'
drop table if exists mimiciv_derived.temp3;
create table mimiciv_derived.temp3 as
select fc.*, weight.weight
from mimiciv_derived.final_cohort fc left join weight
on weight.stay_id = fc.stay_id  


create table mimiciv_derived.temp4 as
SELECT *
FROM mimiciv_hosp.diagnoses_icd
WHERE 
  -- ICD-9 codes for CHF
  (icd_code LIKE '428%' OR
   icd_code = '402.01' OR
   icd_code = '402.11' OR
   icd_code = '402.91' OR
   icd_code = '404.01' OR
   icd_code = '404.03' OR
   icd_code = '404.11' OR
   icd_code = '404.13' OR
   icd_code = '404.91' OR
   icd_code = '404.93') OR
  -- ICD-10 codes for CHF
  (icd_code LIKE 'I50%' OR
   icd_code = 'I11.0' OR
   icd_code = 'I13.0' OR
   icd_code = 'I13.2');

drop table if exists mimiciv_derived.temp5;
create table mimiciv_derived.temp5 as
select distinct temp3.*, charlson.congestive_heart_failure, charlson.cerebrovascular_disease, charlson.chronic_pulmonary_disease, charlson.rheumatic_disease, 
charlson.renal_disease, charlson.malignant_cancer, charlson.severe_liver_disease, charlson.charlson_comorbidity_index
from mimiciv_derived.temp3 temp3, mimiciv_derived.charlson charlson
where temp3.hadm_id = charlson.hadm_id

drop table if exists mimiciv_derived.temp6;
create table mimiciv_derived.temp6 as
select distinct temp5.*, vitalsign.heart_rate_min, vitalsign.heart_rate_max, vitalsign.heart_rate_mean, vitalsign.sbp_min, vitalsign.sbp_max, vitalsign.sbp_mean,
vitalsign.dbp_max, vitalsign.dbp_min, vitalsign.dbp_mean, vitalsign.mbp_max, vitalsign.mbp_min, vitalsign.mbp_mean, vitalsign.resp_rate_min, vitalsign.resp_rate_max, vitalsign.resp_rate_mean,
vitalsign.temperature_min, vitalsign.temperature_max, vitalsign.temperature_mean, vitalsign.spo2_min, vitalsign.spo2_max, vitalsign.spo2_mean, vitalsign.glucose_min, vitalsign.glucose_max, vitalsign.glucose_mean
from mimiciv_derived.temp5 temp5, mimiciv_derived.first_day_vitalsign vitalsign
where temp5.stay_id = vitalsign.stay_id

create table mimiciv_derived.temp7 as
select temp6.*, 
CASE 
WHEN hadm_id in (select hadm_id from mimiciv_derived.temp4) THEN 1
WHEN hadm_id not in (select hadm_id from mimiciv_derived.temp4) THEN 0
end CHF
from mimiciv_derived.temp6 temp6

select *
from mimiciv_derived.temp7

drop table if exists first_chart;
create table first_chart as
select distinct hadm_id, min(charttime) charttime from mimiciv_derived.bg group by hadm_id

drop table if exists bg_first;
create table bg_first as 
select distinct bg.hadm_id, bg.po2, bg.pco2, bg.ph, bg.baseexcess, bg.bicarbonate, bg.lactate
from mimiciv_derived.bg bg, first_chart
where bg.hadm_id = first_chart.hadm_id and bg.charttime = first_chart.charttime

drop table if exists mimiciv_derived.temp8;
create table mimiciv_derived.temp8 as
select temp6.*, bg.po2, bg.pco2, bg.ph, bg.baseexcess, bg.bicarbonate, bg.lactate
from mimiciv_derived.temp6 temp6 left join bg_first bg on (temp6.hadm_id = bg.hadm_id)

'''
drop table if exists c_first_chart;
create table c_first_chart as
select distinct hadm_id, min(charttime) charttime from mimiciv_derived.chemistry group by hadm_id

drop table if exists ch_first;
create table ch_first as
select distinct ch.hadm_id, ch.bun, ch.creatinine, ch.sodium, ch.potassium
from mimiciv_derived.chemistry ch, c_first_chart
where ch.hadm_id = c_first_chart.hadm_id and ch.charttime = c_first_chart.charttime
'''
drop table if exists mimiciv_derived.temp9;
create table mimiciv_derived.temp9 as
select temp8.*, ch.bun_min, ch.bun_max, ch.creatinine_min, ch.creatinine_max, ch.sodium_min, ch.sodium_max, ch.potassium_min, ch.potassium_max
from mimiciv_derived.temp8 temp8 left join mimiciv_derived.first_day_lab ch on (temp8.stay_id = ch.stay_id)

select *
from mimiciv_derived.temp9

