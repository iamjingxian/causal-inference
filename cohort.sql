create table mimiciv_derived.cohort as
select distinct *
from mimiciv_derived.icustay_detail natural join mimiciv_derived.sepsis3
where first_icu_stay = true and first_hosp_stay = true and subject_id in (
select distinct subject_id
from mimiciv_derived.sepsis3) and admission_age >= 18 and hadm_id not in (
select hadm_id
from mimiciv_hosp.services
where curr_service = 'NSURG')

alter table mimiciv_derived.cohort add column days_interval_mortality integer

update mimiciv_derived.cohort set 
days_interval_mortality = dod - admittime::Date

select *
from mimiciv_derived.cohort