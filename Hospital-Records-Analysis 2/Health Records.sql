-- =====================================================
-- HEALTHCARE ANALYTICS PROJECT - HOSPITAL RECORDS ANALYSIS
-- SQL Script for Medical Data Processing & Business Intelligence
-- =====================================================

-- DATASET COMPATIBILITY: This script works with CSV files containing Title Case columns
-- Original CSV columns: Name, Age, Gender, Blood Type, Medical Condition, Date of Admission, 
-- Doctor, Hospital, Insurance Provider, Billing Amount, Room Number, Admission Type, 
-- Discharge Date, Medication, Test Results
-- 
-- The script includes automatic column mapping and data transformation
-- to convert from CSV format to standardized database format

CREATE DATABASE IF NOT EXISTS PatientRecords;
USE patientrecords;

-- =====================================================
-- TASK 01: DATABASE SETUP & HEALTHCARE DATA STRUCTURE
-- =====================================================
-- 
-- TASK DESCRIPTION: Initialize database, create table structure, and import CSV data
-- BUSINESS PURPOSE: Establish foundation for healthcare analytics and reporting
-- EXPECTED OUTCOME: Clean, structured database ready for analysis

-- Create table structure for processed healthcare data
CREATE TABLE IF NOT EXISTS hospitalrecords (
    name VARCHAR(255),
    age INT,
    gender VARCHAR(10),
    blood_type VARCHAR(5),
    medical_condition VARCHAR(100),
    admission_date DATE,
    doctor VARCHAR(255),
    hospital VARCHAR(255),
    insurance_provider VARCHAR(100),
    billing_amount DECIMAL(10,2),
    room_number VARCHAR(10),
    admission_type VARCHAR(20),
    discharge_date DATE,
    medication VARCHAR(100),
    test_results VARCHAR(20),
    stay_days INT,
    age_group VARCHAR(30),
    cost_category VARCHAR(50),
    admission_year INT,
    admission_month INT
);

-- Load data from processed CSV file
-- NOTE: Use MySQL's LOAD DATA INFILE or similar import method
-- LOAD DATA LOCAL INFILE 'healthcare_dataset_processed.csv' 
-- INTO TABLE hospitalrecords 
-- FIELDS TERMINATED BY ',' 
-- OPTIONALLY ENCLOSED BY '\"' 
-- LINES TERMINATED BY '\\n' 
-- IGNORE 1 ROWS;

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

-- =====================================================
-- TASK 02: DATA STANDARDIZATION & QUALITY ASSURANCE
-- =====================================================
-- 
-- TASK DESCRIPTION: Standardize column names, validate data quality, and create derived fields
-- BUSINESS PURPOSE: Ensure data consistency and prepare calculated metrics for analysis
-- EXPECTED OUTCOME: Standardized dataset with quality validation and derived healthcare metrics

-- Verify table structure with all standardized columns
SHOW COLUMNS FROM hospitalrecords;

-- Confirm all required columns exist (should show 20 columns)
SELECT COUNT(*) as total_columns
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'patientrecords' 
  AND TABLE_NAME = 'hospitalrecords';

-- Table structure is now standardized with snake_case column names:
-- name, age, gender, blood_type, medical_condition, admission_date, doctor, 
-- hospital, insurance_provider, billing_amount, room_number, admission_type, 
-- discharge_date, medication, test_results, stay_days, age_group, cost_category, 
-- admission_year, admission_month

-- Comprehensive data quality assessment
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

-- Standardize patient names (Title Case) - Commented out if name column doesn't exist
/*
UPDATE hospitalrecords
SET name = CONCAT(
    UPPER(SUBSTRING(TRIM(name), 1, 1)),
    LOWER(SUBSTRING(TRIM(name), 2))
);
*/

-- Handle missing critical data
UPDATE hospitalrecords 
SET 
    billing_amount = IFNULL(billing_amount, 0),
    room_number = IFNULL(room_number, 'Unknown'),
    insurance_provider = IFNULL(insurance_provider, 'Self-pay'),
    discharge_date = IFNULL(discharge_date, admission_date);

-- 5. Create or update derived healthcare metrics
-- Note: stay_days and age_group columns already exist in your table

-- Update stay_days if needed (in case some records don't have this calculated)
UPDATE hospitalrecords
SET stay_days = DATEDIFF(
    IFNULL(discharge_date, CURDATE()), 
    admission_date
)
WHERE stay_days IS NULL OR stay_days = 0;

-- Update age_group if needed or if format needs standardization
UPDATE hospitalrecords
SET age_group = 
    CASE 
        WHEN age < 18 THEN '0-17 (Pediatric)'
        WHEN age BETWEEN 18 AND 30 THEN '18-30 (Young Adult)'
        WHEN age BETWEEN 31 AND 50 THEN '31-50 (Adult)'
        WHEN age BETWEEN 51 AND 65 THEN '51-65 (Senior)'
        ELSE '66+ (Elderly)'
    END
WHERE age_group IS NULL OR age_group NOT LIKE '%(%';

-- Add cost_category column only if it doesn't exist
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'patientrecords' 
       AND TABLE_NAME = 'hospitalrecords' 
       AND COLUMN_NAME = 'cost_category') = 0,
    'ALTER TABLE hospitalrecords ADD COLUMN cost_category VARCHAR(30)',
    'SELECT "cost_category column already exists" AS status'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Update cost_category
UPDATE hospitalrecords
SET cost_category = 
    CASE 
        WHEN billing_amount < 5000 THEN 'Low Cost (<$5K)'
        WHEN billing_amount BETWEEN 5000 AND 20000 THEN 'Medium Cost ($5K-$20K)'
        WHEN billing_amount BETWEEN 20000 AND 50000 THEN 'High Cost ($20K-$50K)'
        ELSE 'Very High Cost (>$50K)'
    END
WHERE cost_category IS NULL;

-- Add temporal columns only if they don't exist
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'patientrecords' 
       AND TABLE_NAME = 'hospitalrecords' 
       AND COLUMN_NAME = 'admission_year') = 0,
    'ALTER TABLE hospitalrecords ADD COLUMN admission_year INT',
    'SELECT "admission_year column already exists" AS status'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'patientrecords' 
       AND TABLE_NAME = 'hospitalrecords' 
       AND COLUMN_NAME = 'admission_month') = 0,
    'ALTER TABLE hospitalrecords ADD COLUMN admission_month INT',
    'SELECT "admission_month column already exists" AS status'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Extract temporal components
UPDATE hospitalrecords
SET 
    admission_year = YEAR(admission_date),
    admission_month = MONTH(admission_date)
WHERE admission_year IS NULL OR admission_month IS NULL;

-- =====================================================
-- TASK 03: EXPLORATORY DATA ANALYSIS (EDA)
-- =====================================================
-- 
-- TASK DESCRIPTION: Analyze patient demographics, medical conditions, and treatment patterns
-- BUSINESS PURPOSE: Understand patient population characteristics and healthcare utilization
-- EXPECTED OUTCOME: Comprehensive insights into patient demographics and medical condition trends

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
    GROUP_CONCAT(DISTINCT medical_condition ORDER BY medical_condition SEPARATOR ', ') AS common_conditions
FROM hospitalrecords
WHERE blood_type IS NOT NULL
GROUP BY blood_type
ORDER BY patient_count DESC;

-- =====================================================
-- TASK 04: FINANCIAL HEALTHCARE ANALYTICS
-- =====================================================
-- 
-- TASK DESCRIPTION: Analyze healthcare costs, insurance coverage, and financial trends
-- BUSINESS PURPOSE: Understand cost drivers and optimize financial performance
-- EXPECTED OUTCOME: Financial insights for cost management and revenue optimization

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

-- =====================================================
-- TASK 05: HOSPITAL OPERATIONS & PERFORMANCE ANALYSIS
-- =====================================================
-- 
-- TASK DESCRIPTION: Evaluate hospital efficiency, resource utilization, and operational metrics
-- BUSINESS PURPOSE: Optimize hospital operations and improve patient care delivery
-- EXPECTED OUTCOME: Operational insights for resource allocation and performance improvement

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
    GROUP_CONCAT(DISTINCT hospital ORDER BY hospital SEPARATOR ', ') AS treating_hospitals
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
    GROUP_CONCAT(DISTINCT medical_condition ORDER BY medical_condition SEPARATOR ', ') AS primary_specialties
FROM hospitalrecords
GROUP BY doctor
HAVING patient_count >= 10
ORDER BY patient_count DESC
LIMIT 15;

-- =====================================================
-- TASK 06: MEDICATION AND TREATMENT ANALYSIS
-- =====================================================
-- 
-- TASK DESCRIPTION: Analyze medication patterns, prescription trends, and treatment effectiveness
-- BUSINESS PURPOSE: Optimize treatment protocols and medication management
-- EXPECTED OUTCOME: Treatment effectiveness insights and medication optimization recommendations

-- 1. Most prescribed medications analysis
SELECT 
    'Medication Prescription Analysis' AS analysis_type,
    medication,
    COUNT(*) AS prescription_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords WHERE medication IS NOT NULL), 2) AS prescription_percentage,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    GROUP_CONCAT(DISTINCT medical_condition ORDER BY medical_condition SEPARATOR ', ') AS common_conditions
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

-- =====================================================
-- TASK 07: RISK ASSESSMENT & PREDICTIVE ANALYTICS
-- =====================================================
-- 
-- TASK DESCRIPTION: Identify high-risk patients and predict healthcare outcomes
-- BUSINESS PURPOSE: Enable proactive care management and risk mitigation
-- EXPECTED OUTCOME: Risk stratification model and predictive healthcare insights

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

-- =====================================================
-- TASK 08: BUSINESS INTELLIGENCE VIEWS & DASHBOARD PREPARATION
-- =====================================================
-- 
-- TASK DESCRIPTION: Create comprehensive views and prepare data for dashboard integration
-- BUSINESS PURPOSE: Enable real-time healthcare analytics and executive reporting
-- EXPECTED OUTCOME: Dashboard-ready views and executive KPI summaries

-- Create comprehensive view for dashboard integration
CREATE OR REPLACE VIEW healthcare_analytics_dashboard AS
SELECT 
    -- name,  -- Commented out if name column doesn't exist
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

-- Check which columns actually exist in your table
SHOW COLUMNS FROM hospitalrecords;

-- Executive healthcare summary for dashboard KPIs
-- Note: If 'name' column doesn't exist, we'll use total records instead of unique patients
SELECT 
    'Executive Healthcare Dashboard Summary' AS report_type,
    COUNT(*) AS total_patient_records,
    -- COUNT(DISTINCT name) AS unique_patients,  -- Commented out if name column doesn't exist
    COUNT(DISTINCT medical_condition) AS total_conditions_treated,
    COUNT(DISTINCT hospital) AS healthcare_facilities,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(SUM(billing_amount), 2) AS total_healthcare_revenue,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_admission_rate,
    ROUND(AVG(age), 1) AS avg_patient_age;

-- Alternative version if you have a patient ID column instead of name:
-- Replace 'name' with your actual patient identifier column
/*
SELECT 
    'Executive Healthcare Dashboard Summary' AS report_type,
    COUNT(*) AS total_patient_records,
    COUNT(DISTINCT patient_id) AS unique_patients,  -- Use your actual patient ID column
    COUNT(DISTINCT medical_condition) AS total_conditions_treated,
    COUNT(DISTINCT hospital) AS healthcare_facilities,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(SUM(billing_amount), 2) AS total_healthcare_revenue,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_admission_rate,
    ROUND(AVG(age), 1) AS avg_patient_age;
*/

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

-- Task 04: Data Analysis & Key Business Questions
-- =====================================================

-- ✅ Question 1: What are the top 5 diagnoses contributing to high medical costs?
SELECT 
    'Top 5 Diagnoses Contributing to High Medical Costs' AS business_question,
    medical_condition AS diagnosis,
    COUNT(*) AS patient_count,
    ROUND(SUM(billing_amount), 2) AS total_medical_cost,
    ROUND(AVG(billing_amount), 2) AS avg_cost_per_patient,
    ROUND(SUM(billing_amount) * 100.0 / (SELECT SUM(billing_amount) FROM hospitalrecords), 2) AS percentage_of_total_costs,
    ROUND(AVG(stay_days), 1) AS avg_hospital_stay_days,
    'High-cost diagnosis requiring cost optimization strategies' AS business_insight
FROM hospitalrecords
GROUP BY medical_condition
ORDER BY total_medical_cost DESC
LIMIT 5;

-- ✅ Question 2: How does hospital stay duration vary by treatment type?
SELECT 
    'Hospital Stay Duration by Treatment Type' AS business_question,
    medical_condition AS treatment_type,
    COUNT(*) AS total_cases,
    ROUND(AVG(stay_days), 1) AS avg_stay_duration_days,
    ROUND(MIN(stay_days), 1) AS min_stay_days,
    ROUND(MAX(stay_days), 1) AS max_stay_days,
    ROUND(STDDEV(stay_days), 1) AS stay_duration_variability,
    CASE 
        WHEN AVG(stay_days) > 10 THEN 'Long-term treatment requiring resource planning'
        WHEN AVG(stay_days) > 5 THEN 'Medium-term treatment with moderate resource needs'
        ELSE 'Short-term treatment suitable for outpatient optimization'
    END AS treatment_category_insight,
    ROUND(AVG(billing_amount), 2) AS avg_cost_per_stay
FROM hospitalrecords
WHERE discharge_date IS NOT NULL  -- Only include completed stays
GROUP BY medical_condition
HAVING total_cases >= 10  -- Only conditions with sufficient data
ORDER BY avg_stay_duration_days DESC
LIMIT 15;

-- ✅ Question 3: What is the average out-of-pocket expense for different patient groups?
-- Note: Assuming self-pay patients represent out-of-pocket expenses
SELECT 
    'Out-of-Pocket Expenses by Patient Demographics' AS business_question,
    age_group AS patient_group,
    gender,
    COUNT(*) AS patient_count,
    
    -- Self-pay patients (out-of-pocket)
    SUM(CASE WHEN insurance_provider = 'Self-pay' THEN 1 ELSE 0 END) AS self_pay_patients,
    ROUND(AVG(CASE WHEN insurance_provider = 'Self-pay' THEN billing_amount ELSE NULL END), 2) AS avg_out_of_pocket_expense,
    
    -- All patients average
    ROUND(AVG(billing_amount), 2) AS avg_total_expense,
    
    -- Insurance coverage analysis
    ROUND(SUM(CASE WHEN insurance_provider != 'Self-pay' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS insurance_coverage_percentage,
    
    CASE 
        WHEN AVG(CASE WHEN insurance_provider = 'Self-pay' THEN billing_amount ELSE NULL END) > 15000 
        THEN 'High out-of-pocket burden requiring financial assistance programs'
        WHEN AVG(CASE WHEN insurance_provider = 'Self-pay' THEN billing_amount ELSE NULL END) > 8000 
        THEN 'Moderate financial burden requiring payment plan options'
        ELSE 'Manageable out-of-pocket expenses'
    END AS financial_burden_insight
FROM hospitalrecords
GROUP BY age_group, gender
ORDER BY avg_out_of_pocket_expense DESC;

-- Additional Analysis: Regional Insurance Coverage Impact
SELECT 
    'Regional Insurance Coverage vs Out-of-Pocket Expenses' AS business_question,
    hospital AS region,
    COUNT(*) AS total_patients,
    
    -- Insurance coverage by region
    ROUND(SUM(CASE WHEN insurance_provider != 'Self-pay' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS insurance_coverage_rate,
    
    -- Out-of-pocket analysis
    SUM(CASE WHEN insurance_provider = 'Self-pay' THEN 1 ELSE 0 END) AS uninsured_patients,
    ROUND(AVG(CASE WHEN insurance_provider = 'Self-pay' THEN billing_amount ELSE NULL END), 2) AS avg_out_of_pocket_cost,
    ROUND(AVG(billing_amount), 2) AS avg_total_cost,
    
    CASE 
        WHEN SUM(CASE WHEN insurance_provider != 'Self-pay' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 80 
        THEN 'High insurance coverage region with lower financial burden'
        WHEN SUM(CASE WHEN insurance_provider != 'Self-pay' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 60 
        THEN 'Moderate insurance coverage requiring targeted assistance'
        ELSE 'Low insurance coverage region requiring urgent intervention'
    END AS regional_insight
FROM hospitalrecords
GROUP BY hospital
ORDER BY insurance_coverage_rate DESC;

-- Business Insights Analysis
-- =====================================================

-- Insight 1: Chronic Conditions vs Hospital Stay Duration
SELECT 
    'Chronic Conditions Analysis - Stay Duration Patterns' AS insight_analysis,
    medical_condition,
    COUNT(*) AS total_cases,
    ROUND(AVG(stay_days), 1) AS avg_stay_days,
    ROUND(AVG(age), 1) AS avg_patient_age,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    SUM(CASE WHEN stay_days > 7 THEN 1 ELSE 0 END) AS extended_stays,
    ROUND(SUM(CASE WHEN stay_days > 7 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS extended_stay_percentage,
    CASE 
        WHEN medical_condition IN ('Diabetes', 'Hypertension', 'Arthritis', 'Asthma') 
        THEN 'Chronic condition - tends to have longer stays and higher costs'
        ELSE 'Acute condition - typically shorter duration'
    END AS condition_type_insight
FROM hospitalrecords
GROUP BY medical_condition
HAVING total_cases >= 20
ORDER BY avg_stay_days DESC
LIMIT 15;

-- Insight 2: Insurance Coverage Impact on Financial Burden
SELECT 
    'Insurance Coverage Impact Analysis' AS insight_analysis,
    insurance_provider,
    COUNT(*) AS patients_covered,
    ROUND(AVG(billing_amount), 2) AS avg_claim_amount,
    ROUND(AVG(stay_days), 1) AS avg_stay_duration,
    
    -- Calculate presumed out-of-pocket (simplified assumption)
    CASE 
        WHEN insurance_provider = 'Self-pay' THEN ROUND(AVG(billing_amount), 2)
        WHEN insurance_provider LIKE '%Medicare%' THEN ROUND(AVG(billing_amount) * 0.20, 2)  -- 20% copay
        WHEN insurance_provider LIKE '%Medicaid%' THEN ROUND(AVG(billing_amount) * 0.05, 2)  -- 5% copay
        ELSE ROUND(AVG(billing_amount) * 0.15, 2)  -- 15% average copay
    END AS estimated_out_of_pocket,
    
    CASE 
        WHEN insurance_provider = 'Self-pay' 
        THEN 'No insurance - 100% out-of-pocket burden requiring financial assistance'
        WHEN insurance_provider LIKE '%Medicaid%' 
        THEN 'Low-income insurance with minimal out-of-pocket expenses'
        WHEN insurance_provider LIKE '%Medicare%' 
        THEN 'Senior coverage with moderate out-of-pocket expenses'
        ELSE 'Private insurance with manageable out-of-pocket costs'
    END AS coverage_impact_insight
FROM hospitalrecords
WHERE insurance_provider IS NOT NULL
GROUP BY insurance_provider
ORDER BY estimated_out_of_pocket DESC;

-- Insight 3: Elderly Patients - Higher Costs and Longer Stays
SELECT 
    'Elderly Patient Healthcare Utilization Analysis' AS insight_analysis,
    age_group,
    COUNT(*) AS patient_count,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(AVG(stay_days), 1) AS avg_hospital_stay,
    SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_admissions,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_rate,
    GROUP_CONCAT(DISTINCT medical_condition ORDER BY medical_condition SEPARATOR ', ') AS common_conditions,
    CASE 
        WHEN age_group = '66+ (Elderly)' 
        THEN 'Elderly patients show significantly higher treatment costs and longer stays, requiring specialized geriatric care programs'
        WHEN age_group = '51-65 (Senior)' 
        THEN 'Senior patients beginning to show increased healthcare utilization patterns'
        ELSE 'Younger demographics with lower healthcare utilization and costs'
    END AS demographic_insight
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

-- Task 05: Strategic Recommendations Based on Data Analysis
-- =====================================================

-- ✅ Recommendation 1: Optimize Resource Allocation
SELECT 
    'Resource Allocation Optimization Strategy' AS recommendation_type,
    hospital AS healthcare_facility,
    COUNT(*) AS total_patient_volume,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitalrecords), 2) AS facility_market_share,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_volume,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_rate,
    ROUND(SUM(billing_amount), 2) AS total_revenue,
    COUNT(DISTINCT medical_condition) AS conditions_diversity,
    CASE 
        WHEN COUNT(*) > (SELECT AVG(patient_count) FROM (SELECT COUNT(*) as patient_count FROM hospitalrecords GROUP BY hospital) as subq) * 1.5
        THEN 'HIGH PRIORITY: Focus additional resources - above average hospitalization rate'
        WHEN COUNT(*) > (SELECT AVG(patient_count) FROM (SELECT COUNT(*) as patient_count FROM hospitalrecords GROUP BY hospital) as subq)
        THEN 'MEDIUM PRIORITY: Monitor capacity and consider expansion'
        ELSE 'STANDARD: Maintain current resource allocation'
    END AS resource_allocation_recommendation
FROM hospitalrecords
GROUP BY hospital
ORDER BY total_patient_volume DESC;

-- ✅ Recommendation 2: Improve Insurance Coverage
SELECT 
    'Insurance Coverage Improvement Strategy' AS recommendation_type,
    age_group AS target_demographic,
    gender,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN insurance_provider = 'Self-pay' THEN 1 ELSE 0 END) AS uninsured_patients,
    ROUND(SUM(CASE WHEN insurance_provider = 'Self-pay' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS uninsured_rate,
    ROUND(AVG(CASE WHEN insurance_provider = 'Self-pay' THEN billing_amount ELSE NULL END), 2) AS avg_uninsured_cost,
    ROUND(SUM(CASE WHEN insurance_provider = 'Self-pay' THEN billing_amount ELSE 0 END), 2) AS total_uncompensated_care,
    CASE 
        WHEN SUM(CASE WHEN insurance_provider = 'Self-pay' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 25
        THEN 'URGENT: Implement targeted insurance enrollment programs and financial assistance'
        WHEN SUM(CASE WHEN insurance_provider = 'Self-pay' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 15
        THEN 'HIGH PRIORITY: Develop payment plan options and insurance navigation services'
        ELSE 'MONITOR: Continue current coverage support programs'
    END AS insurance_improvement_recommendation
FROM hospitalrecords
GROUP BY age_group, gender
HAVING total_patients >= 50
ORDER BY uninsured_rate DESC;

-- ✅ Recommendation 3: Enhance Early Diagnosis Programs
SELECT 
    'Early Diagnosis & Preventive Care Strategy' AS recommendation_type,
    medical_condition,
    COUNT(*) AS total_cases,
    SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_cases,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_rate,
    ROUND(AVG(stay_days), 1) AS avg_stay_duration,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(AVG(CASE WHEN admission_type = 'Emergency' THEN billing_amount ELSE NULL END), 2) AS avg_emergency_cost,
    CASE 
        WHEN SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 40
        THEN 'CRITICAL: Implement aggressive early screening and prevention programs'
        WHEN SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 25
        THEN 'HIGH PRIORITY: Develop targeted prevention and early intervention programs'
        ELSE 'MAINTAIN: Continue current preventive care protocols'
    END AS prevention_recommendation,
    CONCAT('Potential savings: $', ROUND((AVG(CASE WHEN admission_type = 'Emergency' THEN billing_amount ELSE NULL END) - 
                                          AVG(CASE WHEN admission_type != 'Emergency' THEN billing_amount ELSE NULL END)) * 
                                         SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 0.3, 2)) AS estimated_cost_savings
FROM hospitalrecords
GROUP BY medical_condition
HAVING total_cases >= 30
ORDER BY emergency_rate DESC
LIMIT 10;

-- ✅ Recommendation 4: Cost Optimization Strategies
SELECT 
    'Cost Optimization & Control Strategy' AS recommendation_type,
    medical_condition,
    medication,
    COUNT(*) AS treatment_frequency,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    ROUND(MAX(billing_amount), 2) AS max_treatment_cost,
    ROUND(STDDEV(billing_amount), 2) AS cost_variability,
    ROUND(SUM(billing_amount), 2) AS total_treatment_costs,
    CASE 
        WHEN AVG(billing_amount) > 30000 AND STDDEV(billing_amount) > 15000
        THEN 'HIGH COST + HIGH VARIABILITY: Implement treatment protocols and cost standards'
        WHEN AVG(billing_amount) > 30000
        THEN 'HIGH COST: Review treatment efficiency and negotiate better supplier rates'
        WHEN STDDEV(billing_amount) > 15000
        THEN 'HIGH VARIABILITY: Standardize treatment protocols to reduce cost variations'
        ELSE 'MONITOR: Continue current cost management practices'
    END AS cost_optimization_recommendation,
    CASE 
        WHEN AVG(billing_amount) > 30000
        THEN CONCAT('Potential annual savings: $', ROUND(SUM(billing_amount) * 0.15, 2), ' (15% cost reduction)')
        WHEN AVG(billing_amount) > 15000
        THEN CONCAT('Potential annual savings: $', ROUND(SUM(billing_amount) * 0.10, 2), ' (10% cost reduction)')
        ELSE 'Focus on maintaining current efficiency'
    END AS savings_potential
FROM hospitalrecords
WHERE medication IS NOT NULL
GROUP BY medical_condition, medication
HAVING treatment_frequency >= 10
ORDER BY avg_treatment_cost DESC
LIMIT 15;

-- Executive Summary of Business Insights and Recommendations
SELECT 
    'EXECUTIVE SUMMARY - Key Business Insights & Recommendations' AS summary_type,
    (SELECT GROUP_CONCAT(medical_condition ORDER BY total_cost DESC SEPARATOR ', ') 
     FROM (SELECT medical_condition, SUM(billing_amount) as total_cost 
           FROM hospitalrecords 
           GROUP BY medical_condition 
           ORDER BY total_cost DESC 
           LIMIT 5) AS top_conditions
    ) AS top_cost_drivers,
    CONCAT('$', 
        ROUND((SELECT AVG(billing_amount) 
               FROM hospitalrecords 
               WHERE insurance_provider = 'Self-pay'), 2)
    ) AS avg_out_of_pocket_expense,
    CONCAT('$', 
        ROUND((SELECT AVG(billing_amount) FROM hospitalrecords WHERE age_group = '66+ (Elderly)') - 
              (SELECT AVG(billing_amount) FROM hospitalrecords WHERE age_group != '66+ (Elderly)'), 2),
        ' higher costs for elderly'
    ) AS elderly_cost_premium,
    'RECOMMENDATIONS: 1) Target high-cost conditions with prevention programs, 2) Expand insurance coverage for uninsured populations, 3) Implement geriatric care optimization, 4) Focus resources on high-volume facilities' AS key_recommendations;

-- Display view verification
SELECT 'Healthcare Analytics View Verification' AS check_type, COUNT(*) AS total_records FROM healthcare_analytics_dashboard;