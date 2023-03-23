-- mar-2023; adapted from  
-- https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts_postgres/medication/antibiotic.sql

-- THIS SCRIPT IS AUTOMATICALLY GENERATED. DO NOT EDIT IT DIRECTLY.
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