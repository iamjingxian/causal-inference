create table mimiciv_derived.ventilation_cohort as
select *
from mimiciv_derived.ventilation
where stay_id in (
select stay_id from mimiciv_derived.cohort)


alter table mimiciv_derived.ventilation_cohort add column ventilation_day float

update mimiciv_derived.ventilation_cohort set
ventilation_day = round((DATE_PART('day', endtime::timestamp - starttime::timestamp) * 24 + DATE_PART('hour', endtime::timestamp - starttime::timestamp)) / 24)

create table mimiciv_derived.MVfree_cohort as
select stay_id, 28 - sum(ventilation_day) as days28_MVfree
from mimiciv_derived.ventilation_cohort
group by stay_id