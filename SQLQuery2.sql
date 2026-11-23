CREATE TABLE dbo.hospital_admissions (
    encounter_id BIGINT,
    patient_nbr BIGINT,
    race VARCHAR(50),
    gender VARCHAR(20),
    age VARCHAR(20),
    admission_type_id INT,
    discharge_disposition_id INT,
    admission_source_id INT,
    time_in_hospital INT,
    num_lab_procedures INT,
    num_procedures INT,
    num_medications INT,
    number_outpatient INT,
    number_emergency INT,
    number_inpatient INT,
    diag_1 VARCHAR(20),
    a1c_result VARCHAR(20),
    max_glu_serum VARCHAR(20),
    change_med VARCHAR(10),
    diabetes_med VARCHAR(10),
    readmitted VARCHAR(10)
);

SELECT COUNT(*) AS total_rows
FROM dbo.diabetic_data;

SELECT
    readmitted,
    COUNT(*) AS encounters,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct_share
FROM dbo.diabetic_data
GROUP BY readmitted
ORDER BY encounters DESC;

SELECT
    SUM(CASE WHEN race = '?' OR race IS NULL THEN 1 ELSE 0 END) AS missing_race,
    SUM(CASE WHEN diag_1 = '?' OR diag_1 IS NULL THEN 1 ELSE 0 END) AS missing_diag_1,
    SUM(CASE WHEN weight = '?' OR weight IS NULL THEN 1 ELSE 0 END) AS missing_weight
FROM dbo.diabetic_data;

select *
from dbo.diabetic_data;

SELECT TOP 10
    d.encounter_id,
    CASE WHEN d.race = '?' OR d.race IS NULL THEN 'Unknown' ELSE d.race END AS clean_race,
    d.age,
    d.time_in_hospital,
    d.readmitted
FROM dbo.diabetic_data AS d
ORDER BY d.encounter_id;

SELECT
    SUM(CASE WHEN payer_code = '?' OR payer_code IS NULL THEN 1 ELSE 0 END) AS missing_payer_code,
    SUM(CASE WHEN medical_specialty = '?' OR medical_specialty IS NULL THEN 1 ELSE 0 END) AS missing_medical_specialty
FROM dbo.diabetic_data;

SELECT TOP 20
    encounter_id,
    patient_nbr,
    CASE WHEN race IS NULL OR LTRIM(RTRIM(race)) = '' OR race = '?' THEN 'Unknown' ELSE race END AS clean_race,
    CASE WHEN payer_code IS NULL OR LTRIM(RTRIM(payer_code)) = '' OR payer_code = '?' THEN 'Unknown' ELSE payer_code END AS clean_payer_code,
    CASE WHEN medical_specialty IS NULL OR LTRIM(RTRIM(medical_specialty)) = '' OR medical_specialty = '?' THEN 'Unknown' ELSE medical_specialty END AS clean_medical_specialty,
    CASE WHEN weight IS NULL OR LTRIM(RTRIM(weight)) = '' OR weight = '?' THEN 'Missing' ELSE weight END AS clean_weight,
    readmitted
FROM dbo.diabetic_data;


CREATE OR ALTER VIEW dbo.vw_hospital_admissions_clean AS
SELECT
    encounter_id,
    patient_nbr,
    CASE WHEN race IS NULL OR LTRIM(RTRIM(race)) IN ('', '?') THEN 'Unknown' ELSE LTRIM(RTRIM(race)) END AS race_clean,
    gender,
    age,
    CASE WHEN weight IS NULL OR LTRIM(RTRIM(weight)) IN ('', '?') THEN 'Missing' ELSE LTRIM(RTRIM(weight)) END AS weight_clean,
    admission_type_id,
    discharge_disposition_id,
    admission_source_id,
    time_in_hospital,
    CASE WHEN payer_code IS NULL OR LTRIM(RTRIM(payer_code)) IN ('', '?') THEN 'Unknown' ELSE LTRIM(RTRIM(payer_code)) END AS payer_code_clean,
    CASE WHEN medical_specialty IS NULL OR LTRIM(RTRIM(medical_specialty)) IN ('', '?') THEN 'Unknown' ELSE LTRIM(RTRIM(medical_specialty)) END AS medical_specialty_clean,
    num_lab_procedures,
    num_procedures,
    num_medications,
    number_outpatient,
    number_emergency,
    number_inpatient,
    diag_1,
    diag_2,
    diag_3,
    number_diagnoses,
    max_glu_serum,
    A1Cresult,
    metformin,
    insulin,
    [change],
    diabetesMed,
    readmitted
FROM dbo.diabetic_data;

SELECT TOP 15
    encounter_id,
    race_clean,
    weight_clean,
    payer_code_clean,
    medical_specialty_clean,
    readmitted
FROM dbo.vw_hospital_admissions_clean;

select *
from dbo.vw_hospital_admissions_clean;


SELECT TOP 20 *
FROM dbo.ids_mapping;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'ids_mapping';

  SELECT TOP 25
    v.encounter_id,
    v.race_clean,
    v.age,
    v.time_in_hospital,
    v.admission_type_id,
    COALESCE(m.column2, 'Unmapped / Unknown') AS admission_type_desc,
    v.readmitted
FROM dbo.vw_hospital_admissions_clean AS v
LEFT JOIN dbo.ids_mapping AS m
    ON v.admission_type_id = CAST(m.column1 AS INT)
   AND m.column1 IS NOT NULL;

WITH joined_admissions AS (
    SELECT
        v.encounter_id,
        v.admission_type_id,
        COALESCE(m.column2, 'Unmapped / Unknown') AS admission_type_desc,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
    LEFT JOIN dbo.ids_mapping AS m
        ON v.admission_type_id = CAST(m.column1 AS INT)
       AND m.column1 IS NOT NULL
)
SELECT
    admission_type_id,
    admission_type_desc,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    CAST(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS pct_readmitted_under_30
FROM joined_admissions
GROUP BY
    admission_type_id,
    admission_type_desc
ORDER BY
    total_encounters DESC;


    WITH enriched_admissions AS (
    SELECT
        v.encounter_id,
        v.admission_type_id,
        COALESCE(adm.column2, 'Unmapped / Unknown') AS admission_type_desc,
        v.discharge_disposition_id,
        COALESCE(dis.column2, 'Unmapped / Unknown') AS discharge_disposition_desc,
        v.time_in_hospital,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
    LEFT JOIN dbo.ids_mapping AS adm
        ON v.admission_type_id = CAST(adm.column1 AS INT)
       AND adm.column1 IS NOT NULL
    LEFT JOIN dbo.ids_mapping AS dis
        ON v.discharge_disposition_id = CAST(dis.column1 AS INT)
       AND dis.column1 IS NOT NULL
)
SELECT TOP 15
    discharge_disposition_desc,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    CAST(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS pct_readmitted_under_30
FROM enriched_admissions
GROUP BY
    discharge_disposition_desc
HAVING COUNT(*) >= 100
ORDER BY
    pct_readmitted_under_30 DESC;

    WITH enriched_admissions AS (
    SELECT
        v.encounter_id,
        COALESCE(dis.column2, 'Unmapped / Unknown') AS discharge_disposition_desc,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
    LEFT JOIN dbo.ids_mapping AS dis
        ON v.discharge_disposition_id = CAST(dis.column1 AS INT)
       AND dis.column1 IS NOT NULL
),
summary_by_discharge AS (
    SELECT
        discharge_disposition_desc,
        COUNT(*) AS total_encounters,
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
        CAST(
            100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
            AS DECIMAL(5,2)
        ) AS pct_readmitted_under_30
    FROM enriched_admissions
    GROUP BY discharge_disposition_desc
    HAVING COUNT(*) >= 100
)
SELECT TOP 10
    DENSE_RANK() OVER (ORDER BY pct_readmitted_under_30 DESC) AS readmission_rate_rank,
    discharge_disposition_desc,
    total_encounters,
    readmitted_under_30_days,
    pct_readmitted_under_30,
    CAST(
        100.0 * total_encounters / SUM(total_encounters) OVER ()
        AS DECIMAL(5,2)
    ) AS pct_of_filtered_volume
FROM summary_by_discharge
ORDER BY readmission_rate_rank, total_encounters DESC;


WITH stay_buckets AS (
    SELECT
        v.encounter_id,
        v.time_in_hospital,
        CASE
            WHEN v.time_in_hospital <= 2 THEN '1-2 Days (Short)'
            WHEN v.time_in_hospital BETWEEN 3 AND 6 THEN '3-6 Days (Moderate)'
            ELSE '7+ Days (Extended)'
        END AS stay_bucket,
        v.num_lab_procedures,
        v.num_medications,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
)
SELECT
    stay_bucket,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    CAST(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS pct_readmitted_under_30,
    CAST(AVG(CAST(num_lab_procedures AS FLOAT)) AS DECIMAL(5,1)) AS avg_lab_procedures,
    CAST(AVG(CAST(num_medications AS FLOAT)) AS DECIMAL(5,1)) AS avg_medications
FROM stay_buckets
GROUP BY stay_bucket
ORDER BY
    CASE stay_bucket
        WHEN '1-2 Days (Short)' THEN 1
        WHEN '3-6 Days (Moderate)' THEN 2
        ELSE 3
    END;

    SELECT
    COALESCE(A1Cresult, 'Not Recorded') AS a1c_result,
    COALESCE(insulin, 'Not Recorded') AS insulin_status,
    COALESCE([change], 'Not Recorded') AS med_change_status,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    CAST(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS pct_readmitted_under_30
FROM dbo.vw_hospital_admissions_clean
GROUP BY
    COALESCE(A1Cresult, 'Not Recorded'),
    COALESCE(insulin, 'Not Recorded'),
    COALESCE([change], 'Not Recorded')
HAVING COUNT(*) >= 500
ORDER BY
    pct_readmitted_under_30 DESC,
    total_encounters DESC;


    WITH stay_and_therapy AS (
    SELECT
        v.encounter_id,
        CASE
            WHEN v.time_in_hospital <= 2 THEN '1-2 Days (Short)'
            WHEN v.time_in_hospital BETWEEN 3 AND 6 THEN '3-6 Days (Moderate)'
            ELSE '7+ Days (Extended)'
        END AS stay_bucket,
        COALESCE(v.[change], 'Not Recorded') AS med_change_status,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
)
SELECT
    stay_bucket,
    med_change_status,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    CAST(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS pct_readmitted_under_30
FROM stay_and_therapy
GROUP BY
    stay_bucket,
    med_change_status
ORDER BY
    CASE stay_bucket
        WHEN '1-2 Days (Short)' THEN 1
        WHEN '3-6 Days (Moderate)' THEN 2
        ELSE 3
    END,
    med_change_status;


    WITH clinical_stay_profile AS (
    SELECT
        v.encounter_id,
        CASE
            WHEN v.time_in_hospital <= 2 THEN '1-2 Days (Short)'
            WHEN v.time_in_hospital BETWEEN 3 AND 6 THEN '3-6 Days (Moderate)'
            ELSE '7+ Days (Extended)'
        END AS stay_bucket,
        COALESCE(v.A1Cresult, 'Not Recorded') AS a1c_result,
        COALESCE(v.insulin, 'Not Recorded') AS insulin_status,
        COALESCE(v.[change], 'Not Recorded') AS med_change_status,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
)
SELECT TOP 15
    stay_bucket,
    a1c_result,
    insulin_status,
    med_change_status,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    CAST(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS pct_readmitted_under_30
FROM clinical_stay_profile
GROUP BY
    stay_bucket,
    a1c_result,
    insulin_status,
    med_change_status
HAVING COUNT(*) >= 300
ORDER BY
    pct_readmitted_under_30 DESC,
    total_encounters DESC;


    WITH clinical_stay_profile AS (
    SELECT
        v.encounter_id,
        CASE
            WHEN v.time_in_hospital <= 2 THEN '1-2 Days (Short)'
            WHEN v.time_in_hospital BETWEEN 3 AND 6 THEN '3-6 Days (Moderate)'
            ELSE '7+ Days (Extended)'
        END AS stay_bucket,
        COALESCE(v.A1Cresult, 'Not Recorded') AS a1c_result,
        COALESCE(v.insulin, 'Not Recorded') AS insulin_status,
        COALESCE(v.[change], 'Not Recorded') AS med_change_status,
        v.time_in_hospital,
        v.num_lab_procedures,
        v.num_medications,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
)
SELECT TOP 10
    stay_bucket,
    a1c_result,
    insulin_status,
    med_change_status,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    CAST(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS pct_readmitted_under_30,
    CAST(AVG(CAST(time_in_hospital AS FLOAT)) AS DECIMAL(5,1)) AS avg_stay_days,
    CAST(AVG(CAST(num_lab_procedures AS FLOAT)) AS DECIMAL(5,1)) AS avg_labs,
    CAST(AVG(CAST(num_medications AS FLOAT)) AS DECIMAL(5,1)) AS avg_meds
FROM clinical_stay_profile
GROUP BY
    stay_bucket,
    a1c_result,
    insulin_status,
    med_change_status
HAVING COUNT(*) >= 300
ORDER BY
    pct_readmitted_under_30 DESC,
    total_encounters DESC;


    USE HealthcareMIS;
GO

WITH clinical_stay_profile AS (
    SELECT
        v.encounter_id,
        CASE
            WHEN v.time_in_hospital <= 2 THEN '1-2 Days (Short)'
            WHEN v.time_in_hospital BETWEEN 3 AND 6 THEN '3-6 Days (Moderate)'
            ELSE '7+ Days (Extended)'
        END AS stay_bucket,
        COALESCE(v.A1Cresult, 'Not Recorded') AS a1c_result,
        COALESCE(v.insulin, 'Not Recorded') AS insulin_status,
        COALESCE(v.[change], 'Not Recorded') AS med_change_status,
        v.time_in_hospital,
        v.num_lab_procedures,
        v.num_medications,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
),
cohort_summary AS (
    SELECT
        stay_bucket,
        a1c_result,
        insulin_status,
        med_change_status,
        COUNT(*) AS total_encounters,
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
        CAST(
            100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
            AS DECIMAL(5,2)
        ) AS pct_readmitted_under_30,
        CAST(AVG(CAST(time_in_hospital AS FLOAT)) AS DECIMAL(5,1)) AS avg_stay_days,
        CAST(AVG(CAST(num_lab_procedures AS FLOAT)) AS DECIMAL(5,1)) AS avg_labs,
        CAST(AVG(CAST(num_medications AS FLOAT)) AS DECIMAL(5,1)) AS avg_meds
    FROM clinical_stay_profile
    GROUP BY
        stay_bucket,
        a1c_result,
        insulin_status,
        med_change_status
    HAVING COUNT(*) >= 300
)
SELECT TOP 10
    DENSE_RANK() OVER (ORDER BY pct_readmitted_under_30 DESC) AS risk_rank,
    stay_bucket,
    a1c_result,
    insulin_status,
    med_change_status,
    total_encounters,
    readmitted_under_30_days,
    pct_readmitted_under_30,
    CAST(
        100.0 * total_encounters / NULLIF(SUM(total_encounters) OVER (), 0)
        AS DECIMAL(5,2)
    ) AS pct_of_filtered_volume,
    avg_stay_days,
    avg_labs,
    avg_meds
FROM cohort_summary
ORDER BY
    risk_rank,
    total_encounters DESC;


    USE HealthcareMIS;
GO

SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'ids_mapping'
ORDER BY ORDINAL_POSITION;



USE HealthcareMIS;
GO

WITH mapped_encounters AS (
    SELECT
        v.encounter_id,
        COALESCE(NULLIF(LTRIM(RTRIM(dm.Column2)), ''), CAST(v.discharge_disposition_id AS VARCHAR(50))) AS discharge_disposition_desc,
        CASE
            WHEN v.time_in_hospital <= 2 THEN '1-2 Days (Short)'
            WHEN v.time_in_hospital BETWEEN 3 AND 6 THEN '3-6 Days (Moderate)'
            ELSE '7+ Days (Extended)'
        END AS stay_bucket,
        v.time_in_hospital,
        v.num_lab_procedures,
        v.num_procedures,
        v.num_medications,
        v.readmitted
    FROM dbo.vw_hospital_admissions_clean AS v
    LEFT JOIN dbo.ids_mapping AS dm
        ON TRY_CAST(LTRIM(RTRIM(dm.Column1)) AS INT) = v.discharge_disposition_id
)
SELECT TOP 10
    discharge_disposition_desc,
    stay_bucket,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30_days,
    CAST(
        100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS pct_readmitted_under_30,
    CAST(AVG(CAST(num_lab_procedures AS FLOAT)) AS DECIMAL(5,1)) AS avg_labs,
    CAST(AVG(CAST(num_procedures AS FLOAT)) AS DECIMAL(5,1)) AS avg_procedures,
    CAST(AVG(CAST(num_medications AS FLOAT)) AS DECIMAL(5,1)) AS avg_meds
FROM mapped_encounters
GROUP BY
    discharge_disposition_desc,
    stay_bucket
HAVING COUNT(*) >= 500
ORDER BY
    pct_readmitted_under_30 DESC,
    total_encounters DESC;
    

