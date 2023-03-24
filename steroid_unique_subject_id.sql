create table mimiciv_derived.steroid_unique_subject_id as
select distinct subject_id
from mimiciv_hosp.pharmacy natural join mimiciv_hosp.prescriptions
where medication like '%hydrocortisone%' 
or medication like '%betamethasone%'
or medication like '%cortisone%' 
or medication like '%dexamethasone%' 
or medication like '%decadron%' 
or medication like '%hydrocortisone%' 
or medication like '%methylprednisolone%' 
or medication like '%prednisolone%' 
or medication like '%prednisone%' 
or medication like '%triamcinolone%'
or medication like '%decadron' -- alternative name for Dexamethasone


