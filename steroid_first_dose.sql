-- patients administered steroids; select for 1st dose in each hadm_id
-- adds a column "steroid_first_dose_time" which is a duplicate of "starttime"; more intuitive to understand

CREATE TABLE mimiciv_derived.steroid_first_dose AS
SELECT s1.*, s1.starttime AS steroid_first_dose_time
FROM mimiciv_derived.steroid s1
INNER JOIN (
  SELECT hadm_id, MIN(starttime) AS earliest_starttime
  FROM mimiciv_derived.steroid
  GROUP BY hadm_id
) s2 ON s1.hadm_id = s2.hadm_id AND s1.starttime = s2.earliest_starttime;
