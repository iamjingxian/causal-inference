-- patients administered steroids; select for 1st dose in each hadm_id

CREATE TABLE mimiciv_derived.steroid_first_dose AS
SELECT *
FROM mimiciv_derived.steroid s1
INNER JOIN (
  SELECT hadm_id, MIN(starttime) AS earliest_starttime
  FROM mimiciv_derived.steroid
  GROUP BY hadm_id
) s2 ON s1.hadm_id = s2.hadm_id AND s1.starttime = s2.earliest_starttime;
