-- =====================================================
-- HEALTHCARE ANALYTICS PROJECT - HOSPITAL RECORDS ANALYSIS
-- SQL Script for Medical Data Processing & Business Intelligence
-- =====================================================

CREATE DATABASE IF NOT EXISTS PatientRecords;
USE patientrecords;

-- Task 01: Database Setup & Healthcare Data Structure
-- =====================================================

-- Display current table structure for assessment
SHOW COLUMNS FROM hospitalrecords;

-- Verify data import and basic statistics
SELECT 
    'Healthcare Data Import Verification' AS analysis_type,
    COUNT(*) AS total_patient_records,
    COUNT(DISTINCT name) AS unique_patients,
    MIN(admission_date) AS earliest_admission,
    MAX(admission_date) AS latest_admission,
    COUNT(DISTINCT medical_condition) AS total_conditions,
    COUNT(DISTINCT hospital) AS total_hospitals,
    COUNT(DISTINCT doctor) AS total_doctors,
    COUNT(DISTINCT insurance_provider) AS total_insurance_providers
FROM hospitalrecords;

-- Task 02: Data Standardization & Quality Assurance
-- =====================================================

-- 1. Standardize column names (remove spaces, use snake_case)
ALTER TABLE hospitalrecords
CHANGE COLUMN `Name` name VARCHAR(100),
CHANGE COLUMN `Age` age INT,
CHANGE COLUMN `Gender` gender VARCHAR(20),
CHANGE COLUMN `Medical Condition` medical_condition VARCHAR(100),
CHANGE COLUMN `Billing Amount` billing_amount DECIMAL(10,2),
CHANGE COLUMN `Blood Type` blood_type VARCHAR(10),
CHANGE COLUMN `Date of Admission` admission_date DATE,
CHANGE COLUMN `Doctor` doctor VARCHAR(100),
CHANGE COLUMN `Hospital` hospital VARCHAR(100),
CHANGE COLUMN `Insurance Provider` insurance_provider VARCHAR(100),
CHANGE COLUMN `Room Number` room_number VARCHAR(20),
CHANGE COLUMN `Admission Type` admission_type VARCHAR(50),
CHANGE COLUMN `Discharge Date` discharge_date DATE,
CHANGE COLUMN `Medication` medication VARCHAR(100),
CHANGE COLUMN `Test Results` test_results VARCHAR(100);

-- 2. Comprehensive data quality assessment
SELECT 
    'Healthcare Data Quality Assessment' AS analysis_type,
    COUNT(*) AS total_records,
    COUNT(*) - COUNT(name) AS missing_names,
    COUNT(*) - COUNT(age) AS missing_ages,
    COUNT(*) - COUNT(gender) AS missing_genders,
    COUNT(*) - COUNT(blood_type) AS missing_blood_types,
    COUNT(*) - COUNT(medical_condition) AS missing_conditions,
    COUNT(*) - COUNT(admission_date) AS missing_admission_dates,
    COUNT(*) - COUNT(discharge_date) AS missing_discharge_dates,
    COUNT(*) - COUNT(billing_amount) AS missing_billing_amounts,
    COUNT(*) - COUNT(insurance_provider) AS missing_insurance,
    COUNT(*) - COUNT(medication) AS missing_medications
FROM hospitalrecords;

-- 3. Data validation checks
SELECT 
    'Data Validation Results' AS analysis_type,
    SUM(CASE WHEN age < 0 OR age > 120 THEN 1 ELSE 0 END) AS invalid_ages,
    SUM(CASE WHEN billing_amount < 0 THEN 1 ELSE 0 END) AS negative_billing,
    SUM(CASE WHEN admission_date > discharge_date THEN 1 ELSE 0 END) AS invalid_date_sequences,
    SUM(CASE WHEN DATEDIFF(discharge_date, admission_date) > 365 THEN 1 ELSE 0 END) AS extremely_long_stays
FROM hospitalrecords;

-- 4. Data cleaning and standardization
SET sql_safe_updates = 0;

-- Standardize gender values
UPDATE hospitalrecords
SET gender = CASE 
    WHEN LOWER(gender) IN ('m', 'male') THEN 'Male'
    WHEN LOWER(gender) IN ('f', 'female') THEN 'Female'
    ELSE 'Other'
END;

-- Standardize patient names (Title Case)
UPDATE hospitalrecords
SET name = CONCAT(
    UPPER(SUBSTRING(TRIM(name), 1, 1)),
    LOWER(SUBSTRING(TRIM(name), 2))
);

-- Handle missing critical data
UPDATE hospitalrecords 
SET 
    billing_amount = IFNULL(billing_amount, 0),
    room_number = IFNULL(room_number, 'Unknown'),
    insurance_provider = IFNULL(insurance_provider, 'Self-pay'),
    discharge_date = IFNULL(discharge_date, admission_date);

-- 5. Create derived healthcare metrics
ALTER TABLE hospitalrecords
ADD COLUMN stay_days INT,
ADD COLUMN age_group VARCHAR(30),
ADD COLUMN cost_category VARCHAR(30),
ADD COLUMN admission_year INT,
ADD COLUMN admission_month INT;

-- Calculate length of stay
UPDATE hospitalrecords
SET stay_days = DATEDIFF(
    IFNULL(discharge_date, CURDATE()), 
    admission_date
);

-- Create age groups for demographic analysis
UPDATE hospitalrecords
SET age_group = 
    CASE 
        WHEN age < 18 THEN '0-17 (Pediatric)'
        WHEN age BETWEEN 18 AND 30 THEN '18-30 (Young Adult)'
        WHEN age BETWEEN 31 AND 50 THEN '31-50 (Adult)'
        WHEN age BETWEEN 51 AND 65 THEN '51-65 (Senior)'
        ELSE '66+ (Elderly)'
    END;

-- Categorize costs for financial analysis
UPDATE hospitalrecords
SET cost_category = 
    CASE 
        WHEN billing_amount < 5000 THEN 'Low Cost (<$5K)'
        WHEN billing_amount BETWEEN 5000 AND 20000 THEN 'Medium Cost ($5K-$20K)'
        WHEN billing_amount BETWEEN 20000 AND 50000 THEN 'High Cost ($20K-$50K)'
        ELSE 'Very High Cost (>$50K)'
    END;

-- Extract temporal components
UPDATE hospitalrecords
SET 
    admission_year = YEAR(admission_date),
    admission_month = MONTH(admission_date);

-- Task 03: Exploratory Data Analysis (EDA)
-- =====================================================

-- 1. Patient Demographics Analysis
SELECT 
    'Patient Demographics Analysis' AS analysis_type,
    age_group,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS percentage,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    ROUND(AVG(stay_days), 1) AS avg_stay_days
FROM hospitalrecords
GROUP BY age_group
ORDER BY 
    CASE age_group
        WHEN '0-17 (Pediatric)' THEN 1
        WHEN '18-30 (Young Adult)' THEN 2
        WHEN '31-50 (Adult)' THEN 3
        WHEN '51-65 (Senior)' THEN 4
        WHEN '66+ (Elderly)' THEN 5
    END;

-- 2. Gender-based healthcare utilization
SELECT 
    'Gender Healthcare Utilization' AS analysis_type,
    gender,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS percentage,
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    ROUND(AVG(stay_days), 1) AS avg_stay_days
FROM hospitalrecords
GROUP BY gender
ORDER BY patient_count DESC;

-- 3. Medical conditions prevalence and impact
SELECT 
    'Top Medical Conditions Analysis' AS analysis_type,
    medical_condition,
    COUNT(*) AS case_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS prevalence_percentage,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(SUM(billing_amount), 2) AS total_healthcare_cost,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    ROUND(AVG(age), 1) AS avg_patient_age
FROM hospitalrecords
GROUP BY medical_condition
ORDER BY case_count DESC
LIMIT 15;

-- 4. Blood type distribution and medical correlations
SELECT 
    'Blood Type Distribution Analysis' AS analysis_type,
    blood_type,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS percentage,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    GROUP_CONCAT(DISTINCT medical_condition ORDER BY medical_condition LIMIT 5) AS common_conditions
FROM hospitalrecords
WHERE blood_type IS NOT NULL
GROUP BY blood_type
ORDER BY patient_count DESC;

-- Task 04: Financial Healthcare Analytics
-- =====================================================

-- 1. Healthcare cost analysis by category
SELECT 
    'Healthcare Cost Distribution' AS analysis_type,
    cost_category,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS percentage,
    ROUND(MIN(billing_amount), 2) AS min_cost,
    ROUND(MAX(billing_amount), 2) AS max_cost,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    ROUND(SUM(billing_amount), 2) AS total_cost
FROM hospitalrecords
GROUP BY cost_category
ORDER BY 
    CASE cost_category
        WHEN 'Low Cost (<$5K)' THEN 1
        WHEN 'Medium Cost ($5K-$20K)' THEN 2
        WHEN 'High Cost ($20K-$50K)' THEN 3
        WHEN 'Very High Cost (>$50K)' THEN 4
    END;

-- 2. Top 5 most expensive medical conditions
SELECT 
    'Top 5 Most Expensive Conditions' AS analysis_type,
    medical_condition,
    COUNT(*) AS patient_count,
    ROUND(SUM(billing_amount), 2) AS total_healthcare_cost,
    ROUND(AVG(billing_amount), 2) AS avg_cost_per_patient,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay
FROM hospitalrecords
GROUP BY medical_condition
ORDER BY total_healthcare_cost DESC
LIMIT 5;

-- 3. Insurance provider analysis and coverage patterns
SELECT 
    'Insurance Provider Analysis' AS analysis_type,
    insurance_provider,
    COUNT(*) AS patients_covered,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS market_share_percentage,
    ROUND(SUM(billing_amount), 2) AS total_claims,
    ROUND(AVG(billing_amount), 2) AS avg_claim_amount,
    ROUND(AVG(stay_days), 1) AS avg_patient_stay
FROM hospitalrecords
WHERE insurance_provider IS NOT NULL
GROUP BY insurance_provider
ORDER BY total_claims DESC
LIMIT 10;

-- 4. Monthly healthcare revenue and utilization trends
SELECT 
    'Monthly Healthcare Trends' AS analysis_type,
    admission_year,
    admission_month,
    MONTHNAME(STR_TO_DATE(admission_month, '%m')) AS month_name,
    COUNT(*) AS monthly_admissions,
    ROUND(SUM(billing_amount), 2) AS monthly_revenue,
    ROUND(AVG(billing_amount), 2) AS avg_cost_per_admission,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay
FROM hospitalrecords
GROUP BY admission_year, admission_month, month_name
ORDER BY admission_year, admission_month;

-- Task 05: Hospital Operations & Performance Analysis
-- =====================================================

-- 1. Hospital performance comparison
SELECT 
    'Hospital Performance Analysis' AS analysis_type,
    hospital,
    COUNT(*) AS total_patients,
    COUNT(DISTINCT medical_condition) AS conditions_treated,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_cases,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_percentage
FROM hospitalrecords
GROUP BY hospital
ORDER BY total_patients DESC;

-- 2. Admission type analysis and resource utilization
SELECT 
    'Admission Type Analysis' AS analysis_type,
    admission_type,
    COUNT(*) AS admission_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS percentage,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    ROUND(AVG(stay_days), 1) AS avg_stay_days,
    ROUND(AVG(age), 1) AS avg_patient_age
FROM hospitalrecords
GROUP BY admission_type
ORDER BY admission_count DESC;

-- 3. Emergency care analysis by medical condition
SELECT 
    'Emergency Care Analysis' AS analysis_type,
    medical_condition,
    COUNT(*) AS emergency_cases,
    ROUND(AVG(billing_amount), 2) AS avg_emergency_cost,
    ROUND(AVG(stay_days), 1) AS avg_emergency_stay,
    GROUP_CONCAT(DISTINCT hospital ORDER BY hospital LIMIT 3) AS treating_hospitals
FROM hospitalrecords
WHERE admission_type = 'Emergency'
GROUP BY medical_condition
HAVING emergency_cases >= 10
ORDER BY emergency_cases DESC
LIMIT 10;

-- 4. Doctor workload and specialization analysis
SELECT 
    'Doctor Performance Analysis' AS analysis_type,
    doctor,
    COUNT(*) AS patient_count,
    COUNT(DISTINCT medical_condition) AS conditions_treated,
    ROUND(AVG(stay_days), 1) AS avg_patient_stay,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    GROUP_CONCAT(DISTINCT medical_condition ORDER BY medical_condition LIMIT 3) AS primary_specialties
FROM hospitalrecords
GROUP BY doctor
HAVING patient_count >= 10
ORDER BY patient_count DESC
LIMIT 15;

-- Task 06: Medication and Treatment Analysis
-- =====================================================

-- 1. Most prescribed medications analysis
SELECT 
    'Medication Prescription Analysis' AS analysis_type,
    medication,
    COUNT(*) AS prescription_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords WHERE medication IS NOT NULL), 2) AS prescription_percentage,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    GROUP_CONCAT(DISTINCT medical_condition ORDER BY medical_condition LIMIT 3) AS common_conditions
FROM hospitalrecords
WHERE medication IS NOT NULL
GROUP BY medication
ORDER BY prescription_count DESC
LIMIT 15;

-- 2. Treatment effectiveness analysis (length of stay vs condition)
SELECT 
    'Treatment Effectiveness Analysis' AS analysis_type,
    medical_condition,
    medication,
    COUNT(*) AS treatment_cases,
    ROUND(AVG(stay_days), 1) AS avg_stay_days,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    ROUND(MIN(stay_days), 1) AS min_stay,
    ROUND(MAX(stay_days), 1) AS max_stay
FROM hospitalrecords
WHERE medication IS NOT NULL AND discharge_date IS NOT NULL
GROUP BY medical_condition, medication
HAVING treatment_cases >= 5
ORDER BY medical_condition, avg_stay_days;

-- Task 07: Risk Assessment & Predictive Analytics
-- =====================================================

-- 1. High-risk patient identification
SELECT 
    'High-Risk Patient Analysis' AS analysis_type,
    CASE 
        WHEN age >= 65 AND billing_amount > 25000 THEN 'High Risk - Elderly + High Cost'
        WHEN stay_days > 14 AND billing_amount > 20000 THEN 'High Risk - Extended Stay + High Cost'
        WHEN admission_type = 'Emergency' AND age >= 60 THEN 'High Risk - Emergency + Senior'
        ELSE 'Standard Risk'
    END AS risk_category,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS percentage,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    ROUND(AVG(stay_days), 1) AS avg_stay
FROM hospitalrecords
GROUP BY risk_category
ORDER BY avg_cost DESC;

-- 2. Preventive care opportunities analysis
SELECT 
    'Preventive Care Opportunities' AS analysis_type,
    medical_condition,
    COUNT(*) AS case_count,
    ROUND(AVG(age), 1) AS avg_patient_age,
    SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_cases,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_percentage,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    'Implement early screening programs' AS recommendation
FROM hospitalrecords
GROUP BY medical_condition
HAVING case_count >= 20 AND emergency_percentage > 30
ORDER BY emergency_percentage DESC
LIMIT 10;

-- Task 08: Business Intelligence Views & Dashboard Preparation
-- =====================================================

-- Create comprehensive view for dashboard integration
CREATE OR REPLACE VIEW healthcare_analytics_dashboard AS
SELECT 
    name,
    age,
    age_group,
    gender,
    blood_type,
    medical_condition,
    hospital,
    doctor,
    insurance_provider,
    admission_type,
    admission_date,
    discharge_date,
    stay_days,
    billing_amount,
    cost_category,
    medication,
    admission_year,
    admission_month,
    MONTHNAME(STR_TO_DATE(admission_month, '%m')) AS month_name,
    
    -- Calculated fields for dashboard
    CASE 
        WHEN stay_days <= 3 THEN 'Short Stay (≤3 days)'
        WHEN stay_days <= 7 THEN 'Medium Stay (4-7 days)'
        WHEN stay_days <= 14 THEN 'Long Stay (8-14 days)'
        ELSE 'Extended Stay (>14 days)'
    END AS stay_category,
    
    CASE 
        WHEN age >= 65 AND billing_amount > 25000 THEN 'High Risk'
        WHEN stay_days > 14 AND billing_amount > 20000 THEN 'High Risk'
        WHEN admission_type = 'Emergency' AND age >= 60 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level,
    
    QUARTER(admission_date) AS admission_quarter,
    DAYNAME(admission_date) AS admission_day_of_week
FROM hospitalrecords;

-- Executive healthcare summary for dashboard KPIs
SELECT 
    'Executive Healthcare Dashboard Summary' AS report_type,
    COUNT(*) AS total_patient_records,
    COUNT(DISTINCT name) AS unique_patients,
    COUNT(DISTINCT medical_condition) AS total_conditions_treated,
    COUNT(DISTINCT hospital) AS healthcare_facilities,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(SUM(billing_amount), 2) AS total_healthcare_revenue,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_admission_rate,
    ROUND(AVG(age), 1) AS avg_patient_age;

-- Healthcare quality metrics
SELECT 
    'Healthcare Quality Metrics' AS report_type,
    medical_condition,
    COUNT(*) AS patient_volume,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    ROUND(STDDEV(stay_days), 1) AS stay_variability,
    ROUND(AVG(billing_amount), 2) AS avg_cost,
    SUM(CASE WHEN stay_days > 14 THEN 1 ELSE 0 END) AS extended_stay_cases,
    'Quality improvement opportunity' AS recommendation
FROM hospitalrecords
GROUP BY medical_condition
HAVING patient_volume >= 50
ORDER BY stay_variability DESC
LIMIT 10;

-- Display view verification
SELECT 'Healthcare Analytics View Verification' AS check_type, COUNT(*) AS total_records FROM healthcare_analytics_dashboard;