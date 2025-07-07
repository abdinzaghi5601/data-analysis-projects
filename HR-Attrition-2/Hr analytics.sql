Create Database HrAnalytics;

USE HrAnalytics;SELECT `hr_analytics cleaned`.`EmpID`,
    `hr_analytics cleaned`.`Age`,
    `hr_analytics cleaned`.`AgeGroup`,
    `hr_analytics cleaned`.`Attrition`,
    `hr_analytics cleaned`.`BusinessTravel`,
    `hr_analytics cleaned`.`DailyRate`,
    `hr_analytics cleaned`.`Department`,
    `hr_analytics cleaned`.`DistanceFromHome`,
    `hr_analytics cleaned`.`Education`,
    `hr_analytics cleaned`.`EducationField`,
    `hr_analytics cleaned`.`EmployeeCount`,
    `hr_analytics cleaned`.`EmployeeNumber`,
    `hr_analytics cleaned`.`EnvironmentSatisfaction`,
    `hr_analytics cleaned`.`Gender`,
    `hr_analytics cleaned`.`HourlyRate`,
    `hr_analytics cleaned`.`JobInvolvement`,
    `hr_analytics cleaned`.`JobLevel`,
    `hr_analytics cleaned`.`JobRole`,
    `hr_analytics cleaned`.`JobSatisfaction`,
    `hr_analytics cleaned`.`MaritalStatus`,
    `hr_analytics cleaned`.`MonthlyIncome`,
    `hr_analytics cleaned`.`SalarySlab`,
    `hr_analytics cleaned`.`MonthlyRate`,
    `hr_analytics cleaned`.`NumCompaniesWorked`,
    `hr_analytics cleaned`.`Over18`,
    `hr_analytics cleaned`.`OverTime`,
    `hr_analytics cleaned`.`PercentSalaryHike`,
    `hr_analytics cleaned`.`PerformanceRating`,
    `hr_analytics cleaned`.`RelationshipSatisfaction`,
    `hr_analytics cleaned`.`StandardHours`,
    `hr_analytics cleaned`.`StockOptionLevel`,
    `hr_analytics cleaned`.`TotalWorkingYears`,
    `hr_analytics cleaned`.`TrainingTimesLastYear`,
    `hr_analytics cleaned`.`WorkLifeBalance`,
    `hr_analytics cleaned`.`YearsAtCompany`,
    `hr_analytics cleaned`.`YearsInCurrentRole`,
    `hr_analytics cleaned`.`YearsSinceLastPromotion`,
    `hr_analytics cleaned`.`YearsWithCurrManager`,
    `hr_analytics cleaned`.`IncomeCategory`
FROM `hranalytics`.`hr_analytics cleaned`;


RENAME TABLE hranalysis TO employees;


Select * from hranalysis;

Select  DISTINCT(BusinessTravel) from  Hr_Analytics;

Select count(Gender) from Hr_Analytics where Gender like 'Female%';


-- Check for duplicate EmpIDs
SELECT EmpID, COUNT(*) as duplicate_count
FROM employees
GROUP BY EmpID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

SELECT * FROM  hr_analytics cleaned;

-- Method 1: Using ROW_NUMBER() 
CREATE TABLE employees_clean AS
SELECT 
EmpID,
Age,
AgeGroup,
Attrition,
BusinessTravel,
DailyRate,
Department,
DistanceFromHome,
Education,
EducationField,
EmployeeCount,
EmployeeNumber,
EnvironmentSatisfaction,
Gender,
HourlyRate,JobInvolvement,JobLevel,JobRole,JobSatisfaction,MaritalStatus,MonthlyIncome,SalarySlab,MonthlyRate,NumCompaniesWorked,Over18,
OverTime,PercentSalaryHike,PerformanceRating,RelationshipSatisfaction,StandardHours,StockOptionLevel,TotalWorkingYears,TrainingTimesLastYear,
WorkLifeBalance,YearsAtCompany,YearsInCurrentRole,YearsSinceLastPromotion,YearsWithCurrManager
   
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY EmpID ORDER BY EmpID) as row_num
    FROM employees
) t
WHERE row_num = 1;

-- Check for remaining duplicates (should return 0 rows)
SELECT EmpID, COUNT(*) 
FROM employees_clean 
GROUP BY EmpID 
HAVING COUNT(*) > 1;

-- Compare record counts
SELECT COUNT(*) FROM employees; -- Original count
SELECT COUNT(*) FROM employees_clean; -- Should be 10 fewer

-- Backup original table (safety first!)
RENAME TABLE employees TO employees_old;

-- Make clean table the new main table
RENAME TABLE employees_clean TO employees;

-- Verify new table works
SELECT * FROM employees LIMIT 5;



-- Standardize Gender (Male/Female)
UPDATE employees
SET Gender = CASE 
    WHEN UPPER(TRIM(Gender)) IN ('M', 'MALE', 'MALE ') THEN 'Male'
    WHEN UPPER(TRIM(Gender)) IN ('F', 'FEMALE', 'FEMALE ') THEN 'Female'
    ELSE Gender -- keeps original if not matched
END;

set sql_safe_updates=0;

-- Standardize MaritalStatus (Single/Married/Divorced)
UPDATE employees
SET MaritalStatus = CASE 
    WHEN UPPER(TRIM(MaritalStatus)) LIKE 'S%' THEN 'Single'
    WHEN UPPER(TRIM(MaritalStatus)) LIKE 'M%' THEN 'Married'
    WHEN UPPER(TRIM(MaritalStatus)) LIKE 'D%' THEN 'Divorced'
    ELSE MaritalStatus
END;

-- Standardize JobRole (consistent capitalization)
UPDATE employees
SET JobRole = TRIM(
    CONCAT(
        UPPER(LEFT(JobRole, 1)),
        Lower(SUBSTRING(JobRole, 2))
    )
);

Select Jobrole from employees;

-- Standardize Boolean-like fields (Yes/No)
UPDATE employees
SET 
    Attrition = CASE WHEN UPPER(TRIM(Attrition)) IN ('Y', 'YES') THEN 'Yes'
                    WHEN UPPER(TRIM(Attrition)) IN ('N', 'NO') THEN 'No'
                    ELSE Attrition END,
    OverTime = CASE WHEN UPPER(TRIM(OverTime)) IN ('Y', 'YES') THEN 'Yes'
                   WHEN UPPER(TRIM(OverTime)) IN ('N', 'NO') THEN 'No'
                   ELSE OverTime END;

-- Convert Age to integer (whole numbers)
UPDATE employees
SET Age = CAST(Age AS UNSIGNED);

-- Format MonthlyIncome as decimal with 2 places
UPDATE employees
SET MonthlyIncome = ROUND(CAST(MonthlyIncome AS DECIMAL(10,2)), 2);

-- Format DailyRate consistently
UPDATE employees
SET DailyRate = CAST(DailyRate AS DECIMAL(10,2));

-- Create standardized income categories
ALTER TABLE employees ADD COLUMN IncomeCategory VARCHAR(20);
UPDATE employees
SET IncomeCategory = CASE 
    WHEN MonthlyIncome < 3000 THEN 'Low'
    WHEN MonthlyIncome BETWEEN 3000 AND 6000 THEN 'Medium'
    WHEN MonthlyIncome BETWEEN 6001 AND 10000 THEN 'High'
    ELSE 'Very High'
END;

-- Create age groups for analysis
ALTER TABLE employees ADD COLUMN AgeGroup VARCHAR(20);
UPDATE employees
SET AgeGroup = CASE 
    WHEN Age < 25 THEN 'Under 25'
    WHEN Age BETWEEN 25 AND 34 THEN '25-34'
    WHEN Age BETWEEN 35 AND 44 THEN '35-44'
    WHEN Age BETWEEN 45 AND 54 THEN '45-54'
    ELSE '55+'
END;



select * from employees;


-- Check categorical values are standardized
SELECT DISTINCT Gender FROM employees;
SELECT DISTINCT MaritalStatus FROM employees;
SELECT DISTINCT JobRole FROM employees;
SELECT DISTINCT Attrition FROM employees;
SELECT DISTINCT OverTime FROM employees;

-- Verify numerical transformations
SELECT 
    MIN(Age), MAX(Age), AVG(Age),
    MIN(MonthlyIncome), MAX(MonthlyIncome), AVG(MonthlyIncome),
    MIN(DailyRate), MAX(DailyRate), AVG(DailyRate)
FROM employees;

-- Check derived columns
SELECT DISTINCT IncomeCategory FROM employees; 
SELECT DISTINCT AgeGroup FROM employees;


-- Attrition by Department
SELECT 
    Department,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS attrition_rate
FROM employees
GROUP BY Department
ORDER BY attrition_rate DESC;

-- Attrition by Job Role
SELECT 
    JobRole,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS attrition_rate
FROM employees
GROUP BY JobRole
ORDER BY attrition_rate DESC;

-- Attrition by Age Group
SELECT 
    Agegroup,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS attrition_rate
FROM employees
GROUP BY Agegroup
ORDER BY attrition_rate DESC;	


Drop Table employees_old;

-- Analysis of attrition drivers
SELECT 
    Department,
    JobRole,
    ROUND(AVG(JobSatisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(MonthlyIncome), 2) AS avg_salary,
    ROUND(AVG(WorkLifeBalance), 2) AS avg_work_life_balance,
    ROUND(AVG(JobInvolvement), 2) AS avg_job_involvement,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS attrition_count,
    ROUND(COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS attrition_rate
FROM employees
GROUP BY Department, JobRole
ORDER BY attrition_rate DESC;

-- Salary comparison across departments and job levels
SELECT 
    Department,
    JobLevel,
    COUNT(*) AS employee_count,
    ROUND(MIN(MonthlyIncome), 2) AS min_salary,
    ROUND(AVG(MonthlyIncome), 2) AS avg_salary,
    ROUND(MAX(MonthlyIncome), 2) AS max_salary,
    ROUND(AVG(PercentSalaryHike), 2) AS avg_salary_hike
FROM employees
GROUP BY Department, JobLevel
ORDER BY Department, JobLevel;

-- Overtime analysis
SELECT 
    OverTime,
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS attrition_count,
    ROUND(COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS attrition_rate,
    ROUND(AVG(JobSatisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(WorkLifeBalance), 2) AS avg_work_life_balance
FROM employees
GROUP BY OverTime
ORDER BY attrition_rate DESC;

-- Department-specific attrition drivers
SELECT 
    Department,
    AVG(CASE WHEN Attrition = 'Yes' THEN MonthlyIncome ELSE NULL END) AS avg_salary_leavers,
    AVG(CASE WHEN Attrition = 'No' THEN MonthlyIncome ELSE NULL END) AS avg_salary_stayers,
    AVG(CASE WHEN Attrition = 'Yes' THEN YearsAtCompany ELSE NULL END) AS avg_tenure_leavers,
    AVG(CASE WHEN Attrition = 'No' THEN YearsAtCompany ELSE NULL END) AS avg_tenure_stayers
FROM employees
GROUP BY Department;

-- Job satisfaction distribution by attrition status
SELECT 
    JobSatisfaction,
    COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) AS attrition_yes,
    COUNT(CASE WHEN Attrition = 'No' THEN 1 END) AS attrition_no,
    ROUND(COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) * 100.0 / 
          (COUNT(CASE WHEN Attrition = 'Yes' THEN 1 END) + COUNT(CASE WHEN Attrition = 'No' THEN 1 END)), 2) AS attrition_rate
FROM employees
GROUP BY JobSatisfaction
ORDER BY JobSatisfaction;
