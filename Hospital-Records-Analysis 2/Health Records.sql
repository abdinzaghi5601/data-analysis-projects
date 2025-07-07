CREATE database PatientRecords;
use patientrecords;






-- Standardize column names (remove spaces, use snake_case)
-- Check current column names first
SHOW COLUMNS FROM hospitalrecords;
SHOW COLUMNS FROM healthcare_dataset;

SELECT * FROM healthcare_dataset;
select * from hospitalrecords;

RENAME TABLE hospitalrecordspatientdetails TO hospitalrecords;
DROP TABLE hh;
drop table hospitalrecords;

-- If the target table already exists and you want to append data
INSERT INTO hospitalrecords (name)
SELECT Name
FROM healthcare_dataset;

--- Standardize column names (remove spaces, use snake_case)
ALTER TABLE hospitalrecords
CHANGE COLUMN `Name` name VARCHAR(100),
CHANGE COLUMN `Age` age INT,
CHANGE COLUMN `Gender` gender VARCHAR(20),
CHANGE COLUMN `Medical Condition` medical_condition VARCHAR(100),
CHANGE COLUMN `Billing Amount` billing_amount int,
CHANGE COLUMN `Blood Type` blood_type varchar(100) ,
CHANGE COLUMN `Date of Admission` admission_date DATE,
CHANGE COLUMN `Doctor` doctor VARCHAR(100),
CHANGE COLUMN `Hospital` hospital VARCHAR(100),
CHANGE COLUMN `Insurance Provider` insurance_provider VARCHAR(100),
CHANGE COLUMN `Room Number` room_number VARCHAR(20),
CHANGE COLUMN `Admission Type` admission_type VARCHAR(50),
CHANGE COLUMN `Discharge Date` discharge_date DATE,
CHANGE COLUMN `Medication` medication VARCHAR(100),
CHANGE COLUMN `Test Results` test_results VARCHAR(100);




-- Improved missing values analysis query
SELECT 
    COUNT(*) AS total_records,
    COUNT(*) - COUNT(name) AS missing_names,
    COUNT(*) - COUNT(age) AS missing_ages,
    COUNT(*) - COUNT(gender) AS missing_genders,
    COUNT(*) - COUNT(blood_type) AS missing_blood_types,
    COUNT(*) - COUNT(medical_condition) AS missing_conditions,
    COUNT(*) - COUNT(admission_date) AS missing_admission_dates,
    COUNT(*) - COUNT(discharge_date) AS missing_discharge_dates,
    COUNT(*) - COUNT(billing_amount) AS missing_billing_amounts
FROM hospitalrecords;

set sql_safe_updates=0;


-- Standardize gender (Male/Female/Other)
UPDATE hospitalrecords
SET gender = CASE 
    WHEN LOWER(gender) IN ('m', 'male') THEN 'Male'
    WHEN LOWER(gender) IN ('f', 'female') THEN 'Female'
    ELSE 'Other'
END;





SELECT * from hospitalrecords;

-- Create a temporary table with distinct records
CREATE TABLE temp_hospital_records AS
SELECT DISTINCT * FROM hospitalrecords;

-- Drop the original table and rename the temp table
DROP TABLE hospitalrecords;
RENAME TABLE temp_hospital_records TO hospitalrecords;


-- Delete records missing critical fields (adjust threshold as needed)
DELETE FROM hospitalrecords 
WHERE name IS NULL 
   OR medical_condition IS NULL 
   OR admission_date IS NULL;

-- Set default values for non-critical fields
UPDATE hospitalrecords 
SET 
    billing_amount = IFNULL(billing_amount, 0),
    room_number = IFNULL(room_number, 'Unknown'),
    insurance_provider = IFNULL(insurance_provider, 'Self-pay');
    
    UPDATE hospitalrecords
SET gender = CASE 
    WHEN LOWER(gender) IN ('m', 'male') THEN 'Male'
    WHEN LOWER(gender) IN ('f', 'female') THEN 'Female'
    ELSE 'Other/Unknown' 
END;

-- Add a new numeric column
ALTER TABLE hospitalrecords
ADD COLUMN stay_days INT;

-- Calculate days between admission and discharge
UPDATE hospitalrecords
SET stay_days = DATEDIFF(
    IFNULL(discharge_date, CURDATE()), 
    admission_date
);
-- Convert billing amounts to standard currency (e.g., USD)


-- Remove currency symbols (if stored as text)
UPDATE hospitalrecords
SET billing_amount = CAST(
    REGEXP_REPLACE(billing_amount, '[^0-9.]', '') AS DECIMAL(10,2)
);

-- Ensure future data quality
ALTER TABLE hospitalrecords
MODIFY name VARCHAR(100) NOT NULL,
MODIFY admission_date DATE NOT NULL,
MODIFY gender ENUM('Male', 'Female', 'Other/Unknown') NOT NULL,
MODIFY billing_amount DECIMAL(10,2) DEFAULT 0;


Select * from hospitalrecords;

--- standardized names in the name column 

UPDATE hospitalrecords
SET name = CONCAT(
    UPPER(SUBSTRING(name, 1, 1)),
    LOWER(SUBSTRING(name, 2))
);

 SHOW COLUMNS FROM hospitalrecords LIKE '%backup%';

 select * from hospitalrecords;

-- By region
SELECT 
    hospital AS region,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS percentage
FROM hospitalrecords
GROUP BY hospital
ORDER BY patient_count DESC;

-- By age group
SELECT 
    CASE
        WHEN age < 18 THEN '0-17'
        WHEN age BETWEEN 18 AND 30 THEN '18-30'
        WHEN age BETWEEN 31 AND 50 THEN '31-50'
        WHEN age BETWEEN 51 AND 70 THEN '51-70'
        ELSE '70+'
    END AS age_group,
    COUNT(*) AS patient_count
FROM hospitalrecords
GROUP BY age_group
ORDER BY age_group;



-- 	
SELECT 
    medical_condition,
    COUNT(*) AS diagnosis_count,
    ROUND(AVG(billing_amount), 2) AS avg_cost
FROM hospitalrecords
GROUP BY medical_condition
ORDER BY diagnosis_count DESC
LIMIT 10;

-- Most prescribed medications
SELECT 
    medication,
    COUNT(*) AS prescription_count
FROM hospitalrecords
GROUP BY medication
ORDER BY prescription_count DESC
LIMIT 10;

SELECT 
    medical_condition,
    ROUND(AVG(stay_days), 1) AS avg_stay_days,
    MIN(stay_days) AS min_stay,
    MAX(stay_days) AS max_stay
FROM hospitalrecords
WHERE discharge_date IS NOT NULL  -- Only discharged patients
GROUP BY medical_condition
ORDER BY avg_stay_days DESC
LIMIT 15;


-- Cost trends by treatment
SELECT 
    medical_condition,
    YEAR(admission_date) AS year,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    ROUND(MAX(billing_amount), 2) AS max_cost,
    COUNT(*) AS cases
FROM hospitalrecords
GROUP BY medical_condition, YEAR(admission_date)
ORDER BY medical_condition, year;

-- Insurance coverage analysis
SELECT 
    insurance_provider,
    COUNT(*) AS patient_count,
    ROUND(AVG(billing_amount), 2) AS avg_billing,
    ROUND(SUM(CASE WHEN billing_amount > 10000 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS percent_high_cost_cases
FROM hospitalrecords
GROUP BY insurance_provider
ORDER BY patient_count DESC;


-- Doctor workload and outcomes
SELECT 
    doctor,
    COUNT(*) AS patient_count,
    ROUND(AVG(stay_days), 1) AS avg_stay,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    GROUP_CONCAT(DISTINCT medical_condition ) AS common_conditions
FROM hospitalrecords
GROUP BY doctor
ORDER BY patient_count DESC
LIMIT 20;

--- Insurance Coverage Analysis

SELECT 
    insurance_provider,
    COUNT(*) AS patients_covered,
    ROUND(SUM(billing_amount), 2) AS total_claims,
    ROUND(AVG(billing_amount), 2) AS avg_claim_amount
FROM 
    hospitalrecords
WHERE 
    insurance_provider IS NOT NULL
GROUP BY 
    insurance_provider
ORDER BY 
    total_claims DESC;


--- Calculate Total Revenue by Month
SELECT 
    medical_condition,
    COUNT(*) AS patient_count,
    ROUND(AVG(billing_amount), 2) AS avg_billing,
    SUM(billing_amount) AS total_billing
FROM 
    hospitalrecords
GROUP BY 
    medical_condition
ORDER BY 
    total_billing DESC;
    
    SELECT 
    hospital,
    admission_type,
    ROUND(AVG(stay_days), 1) AS avg_stay_days,
    ROUND(AVG(billing_amount), 2) AS avg_cost_per_stay
FROM 
    hospitalrecords
GROUP BY 
    hospital, admission_type
ORDER BY 
    hospital, avg_stay_days DESC;
    
    
    SELECT 
    DATE_FORMAT(admission_date, '%Y-%m') AS month,
    COUNT(*) AS admissions,
    ROUND(SUM(billing_amount), 2) AS total_revenue
FROM 
    hospitalrecords
GROUP BY 
    month
ORDER BY 
    month;
    
   --- Blood Type Distribution
    SELECT 
    blood_type,
    COUNT(*) AS patient_count,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2), '%') AS percentage
FROM 
    hospitalrecords
GROUP BY 
    blood_type
ORDER BY 
    patient_count DESC;
    
    --- Emergency Admissions Analysis
    
SELECT 
    hospital,
    COUNT(*) AS emergency_cases,
    ROUND(AVG(stay_days), 1) AS avg_stay,
    ROUND(AVG(billing_amount), 2) AS avg_cost
FROM 
    hospitalrecords
WHERE 
    admission_type = 'Emergency'
GROUP BY 
    hospital
ORDER BY 
    emergency_cases DESC;
    
    --- Common Medications Prescribed
    SELECT 
    medication,
    COUNT(*) AS prescription_count
FROM 
    hospitalrecords
WHERE 
    medication IS NOT NULL
GROUP BY 
    medication
ORDER BY 
    prescription_count DESC
LIMIT 10;




    
    


SELECT 
    name, 
    age, 
    gender, 
    medical_condition,
    billing_amount
FROM 
    hospitalrecords
WHERE 
    insurance_provider IS NULL
ORDER BY 
    name;
    
    SELECT *
FROM hospitalrecords
WHERE name LIKE '%Bobby%';

--- Top 5 Diagnoses Contributing to High Medical Costs


SELECT 
    medical_condition,
    COUNT(*) AS patient_count,
    ROUND(SUM(billing_amount), 2) AS total_cost,
    ROUND(AVG(billing_amount), 2) AS avg_cost_per_patient
FROM hospitalrecords
GROUP BY medical_condition
ORDER BY total_cost DESC
LIMIT 5;

---  Preventive Care Focus
SELECT 
    medical_condition,
    AVG(stay_days) AS avg_stay,
    COUNT(*) AS cases
FROM hospitalrecords
WHERE admission_type = 'Emergency'
GROUP BY medical_condition
HAVING cases > 20
ORDER BY avg_stay DESC
LIMIT 5;


--- Cost Control

SELECT 
    medication,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    COUNT(*) AS prescriptions
FROM hospitalrecords
GROUP BY medication
HAVING prescriptions > 5
ORDER BY avg_cost DESC
LIMIT 10;

ALTER TABLE hospitalrecords 
ADD COLUMN age_group VARCHAR(20);

--- creating a new column for age group 

UPDATE hospitalrecords
SET age_group = 
    CASE 
        WHEN age < 18 THEN '0-17 (Pediatric)'
        WHEN age BETWEEN 18 AND 30 THEN '18-30 (Young Adult)'
        WHEN age BETWEEN 31 AND 50 THEN '31-50 (Adult)'
        WHEN age BETWEEN 51 AND 65 THEN '51-65 (Senior)'
        ELSE '66+ (Elderly)'
    END;
    
    
    Select * from hospitalrecords;