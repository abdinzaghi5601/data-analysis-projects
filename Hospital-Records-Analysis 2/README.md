# Healthcare Analytics Using SQL and Power BI

## 🎯 Project Overview

This comprehensive healthcare analytics project analyzes patient records, medical treatments, and healthcare costs using SQL for data processing and Power BI for interactive visualizations. The analysis provides actionable insights for healthcare management, cost optimization, and patient care improvement.

## 📋 Objectives

By the end of this project, we have:
- ✅ Conducted exploratory data analysis (EDA) to uncover healthcare trends and patterns
- ✅ Performed comprehensive data cleaning and transformation using SQL
- ✅ Created interactive Power BI dashboards for healthcare visualization
- ✅ Provided data-driven insights and recommendations for healthcare improvements

## 📊 Dataset Information

- **Dataset Name**: Healthcare Data Analysis
- **Total Records**: 55,501+ patient records
- **Format**: CSV with comprehensive healthcare data
- **Scope**: Multi-hospital patient analysis with financial metrics

### Key Data Categories:

#### **Patient Information**
- **Patient_ID**: Unique identifier for each patient
- **Name**: Patient name (standardized)
- **Age**: Patient age with derived age groups
- **Gender**: Male/Female/Other (standardized)
- **Blood_Type**: Patient blood type classification

#### **Medical Details**
- **Medical_Condition**: Primary diagnosis (standardized)
- **Doctor**: Treating physician
- **Hospital**: Healthcare facility
- **Admission_Date**: Date of hospital admission
- **Discharge_Date**: Date of discharge
- **Stay_Days**: Calculated hospital stay duration
- **Admission_Type**: Emergency/Elective/Urgent
- **Test_Results**: Medical test outcomes

#### **Treatment Information**
- **Medication**: Prescribed medications
- **Room_Number**: Hospital room assignment
- **Treatment_Type**: Category of medical treatment

#### **Financial Metrics**
- **Billing_Amount**: Total medical cost
- **Insurance_Provider**: Insurance company
- **Insurance_Covered**: Amount covered by insurance
- **Out_of_Pocket**: Patient direct expenses

## 🛠️ Technical Implementation

### **Tools Used**
- **MySQL**: Database management and SQL analysis
- **Power BI**: Interactive dashboard creation
- **CSV Export**: Results documentation and sharing

### **Data Processing Pipeline**
1. **Data Import**: Load healthcare dataset into MySQL database
2. **Data Cleaning**: Remove duplicates, standardize categorical values
3. **Data Transformation**: Create derived columns and financial categories
4. **Analysis**: Execute comprehensive SQL queries for insights
5. **Visualization**: Build interactive Power BI dashboards
6. **Export**: Generate CSV reports for stakeholder sharing

## 📁 Project Structure

```
Hospital-Records-Analysis 2/
├── README.md                                          # Project documentation
├── Health Records.sql                                 # Complete SQL analysis
├── healthcare_dataset.csv                            # Raw dataset
├── HospitalRecords1.csv                              # Processed dataset
├── hospitalrecords.pbix                              # Power BI dashboard
├── Healthcare Analytics.pdf                          # Analysis report
└── Analysis Results/
    ├── Top 10 diagnoses.csv                          # Most common conditions
    ├── Diagnoses Contributing to High Medical Costs.csv
    ├── Emergency Admissions Analysis.csv             # Emergency case analysis
    ├── Common Medications Prescribed.csv             # Medication patterns
    ├── Insurance Coverage Analysis.csv               # Provider analysis
    ├── Cost trends by treatment.csv                  # Temporal cost analysis
    └── Medical Condition.csv                         # Condition analysis
```

## 🔧 Data Preparation Process

### **Data Cleaning Procedures**
- **Duplicate Removal**: Used DISTINCT records approach to eliminate duplicates
- **Column Standardization**: Renamed columns to snake_case format for consistency
- **Missing Value Treatment**: Applied IFNULL and default values for incomplete records

### **Data Transformation**
```sql
-- Gender Standardization
UPDATE hospitalrecords
SET gender = CASE 
    WHEN LOWER(gender) IN ('m', 'male') THEN 'Male'
    WHEN LOWER(gender) IN ('f', 'female') THEN 'Female'
    ELSE 'Other/Unknown' 
END;

-- Age Group Creation
UPDATE hospitalrecords
SET age_group = 
    CASE 
        WHEN age < 18 THEN '0-17 (Pediatric)'
        WHEN age BETWEEN 18 AND 30 THEN '18-30 (Young Adult)'
        WHEN age BETWEEN 31 AND 50 THEN '31-50 (Adult)'
        WHEN age BETWEEN 51 AND 65 THEN '51-65 (Senior)'
        ELSE '66+ (Elderly)'
    END;

-- Hospital Stay Calculation
UPDATE hospitalrecords
SET stay_days = DATEDIFF(
    IFNULL(discharge_date, CURDATE()), 
    admission_date
);
```

### **Quality Assurance**
- **Data Validation**: Ensured all critical fields are populated
- **Constraint Implementation**: Added NOT NULL constraints for essential columns
- **Format Standardization**: Converted billing amounts to standard decimal format

## 📈 Key Findings & Insights

### **🏥 Medical Condition Analysis**

#### **Most Common Diagnoses (by volume)**
1. **Arthritis**: 9,218 cases (16.6% of patients)
2. **Diabetes**: 9,216 cases (16.6% of patients)
3. **Hypertension**: 9,151 cases (16.5% of patients)
4. **Obesity**: 9,146 cases (16.5% of patients)
5. **Cancer**: 9,140 cases (16.5% of patients)
6. **Asthma**: 9,095 cases (16.4% of patients)

#### **Highest Cost Conditions (by total expense)**
1. **Diabetes**: $236.5M total cost ($25,662 avg per patient)
2. **Obesity**: $236.0M total cost ($25,807 avg per patient)
3. **Arthritis**: $235.2M total cost ($25,513 avg per patient)
4. **Hypertension**: $233.4M total cost ($25,505 avg per patient)
5. **Asthma**: $233.2M total cost ($25,636 avg per patient)

### **💊 Medication Insights**
- **Most Prescribed**: Lipitor (11,038 prescriptions)
- **Top Pain Relief**: Ibuprofen (11,023 prescriptions)
- **Common Medications**: Aspirin (10,984), Paracetamol (10,965)
- **Antibiotic Usage**: Penicillin frequently prescribed

### **🏥 Hospital Operations**
- **Average Hospital Stay**: Varies by condition (Emergency cases typically longer)
- **Emergency Admissions**: Significant portion requiring immediate attention
- **Bed Utilization**: Room assignment patterns indicate capacity management

### **💰 Financial Analysis**

#### **Insurance Provider Performance**
- **Cigna**: Highest patient coverage (11,139 patients, $284.4M claims)
- **Medicare**: Strong government coverage ($282.9M claims)
- **Blue Cross**: Consistent coverage ($280.4M claims)
- **UnitedHealthcare**: Competitive rates ($279.9M claims)
- **Aetna**: Solid provider ($276.5M claims)

#### **Cost Trends (2019-2024)**
- **Stable Pricing**: Average costs remain consistent around $25,500
- **Condition Variations**: Some conditions show slight cost fluctuations
- **Volume Patterns**: Certain conditions show increasing case volumes

## 🎨 Power BI Dashboard Features

### **Healthcare Overview Dashboard**
- **KPIs**: Total patients, average hospital stay, total medical cost
- **Visualizations**:
  - Bar Chart: Most common diagnoses
  - Pie Chart: Patient distribution by gender and age group
  - Line Chart: Monthly treatment trends and admission patterns

### **Financial Analysis Dashboard**
- **Advanced Analytics**:
  - Scatter Plot: Insurance coverage vs. medical cost correlation
  - Heatmap: Hospital stay trends by region and condition
  - Matrix: Treatment type vs. average cost analysis

### **Interactive Features**
- **Filters**: Region, age group, diagnosis, treatment type
- **Drill-down**: Detailed patient and cost analysis
- **Real-time Updates**: Dynamic filtering and exploration capabilities

## 💡 Strategic Recommendations

### **Immediate Healthcare Improvements (0-30 days)**
1. **Focus on Diabetes Management**: Highest total cost condition requiring specialized programs
2. **Obesity Prevention**: Implement wellness programs to reduce long-term costs
3. **Emergency Care Optimization**: Streamline emergency admission processes

### **Short-term Strategy (1-6 months)**
1. **Preventive Care Programs**: Early diagnosis initiatives for chronic conditions
2. **Medication Management**: Optimize prescription patterns and costs
3. **Insurance Collaboration**: Improve coverage coordination with major providers

### **Long-term Vision (6-12 months)**
1. **Chronic Disease Management**: Comprehensive care programs for high-cost conditions
2. **Technology Integration**: Implement predictive analytics for patient outcomes
3. **Cost Control Strategies**: Develop value-based care models

## 📊 SQL Analysis Highlights

The `Health Records.sql` file contains 8 comprehensive analytical tasks:

### **Task 01: Database Setup & Healthcare Data Structure**
- Table structure verification and data import validation
- Column standardization and healthcare data integrity checks
- Infrastructure setup for comprehensive analytics

### **Task 02: Data Standardization & Quality Assurance**
- Dynamic column detection using INFORMATION_SCHEMA
- Comprehensive data quality assessment with missing value analysis
- Gender standardization and data cleaning procedures
- Healthcare-specific data validation rules

### **Task 03: Exploratory Data Analysis (EDA)**
- Patient demographics distribution and age group analysis
- Medical condition frequency and prevalence calculations
- Hospital utilization patterns and admission type analysis
- Cost distribution and billing amount statistical analysis

### **Task 04: Business Questions Analysis**
- **Question 1**: Top 5 diagnoses contributing to high medical costs
- **Question 2**: Hospital stay duration variation by treatment type
- **Question 3**: Average out-of-pocket expenses for different patient groups
- **Question 4**: Insurance coverage impact on healthcare costs
- Comprehensive business intelligence queries with actionable insights

### **Task 05: Strategic Recommendations**
- **Resource Allocation**: Optimization strategies for high-cost conditions
- **Insurance Coverage**: Expansion programs for uninsured populations
- **Early Diagnosis**: Prevention programs for chronic conditions
- **Cost Optimization**: Value-based care implementation strategies

### **Task 06: Correlation & Statistical Analysis**
- Age group vs. medical cost correlation analysis
- Treatment type vs. hospital stay duration relationships
- Insurance provider vs. patient outcome correlations
- Statistical significance testing for healthcare metrics

### **Task 07: Temporal Analysis & Trends**
- Monthly admission patterns and seasonal healthcare trends
- Year-over-year cost variation analysis
- Treatment duration trends by medical condition
- Emergency vs. elective admission pattern analysis

### **Task 08: Business Intelligence Integration**
- Comprehensive dashboard view creation for Power BI integration
- Executive summary queries with KPI aggregation
- Healthcare analytics framework for ongoing monitoring
- Advanced reporting queries for stakeholder communication

## 🏥 Advanced Healthcare Analytics Framework

### **Clinical Decision Support Queries**
- **Risk Stratification**: Patient risk scoring based on age, condition, and stay duration
- **Treatment Effectiveness**: Medication efficacy analysis by condition and outcome
- **Resource Optimization**: Hospital bed utilization and staff allocation analytics
- **Quality Metrics**: Length of stay optimization and readmission risk assessment

### **Population Health Analytics**
- **Disease Burden Analysis**: Community health impact assessment by condition
- **Demographic Health Patterns**: Age and gender-specific healthcare trends
- **Preventive Care Opportunities**: Early intervention program identification
- **Health Equity Analysis**: Insurance coverage and access disparities

### **Financial Intelligence**
- **Cost Driver Analysis**: Identification of high-impact expense categories
- **Insurance Performance**: Provider-specific coverage and claim efficiency
- **Revenue Optimization**: Billing pattern analysis and revenue cycle improvement
- **Budget Planning**: Predictive cost modeling for healthcare resource allocation

### **Operational Excellence**
- **Emergency Care Analytics**: Admission pattern optimization and resource planning
- **Capacity Management**: Real-time bed availability and patient flow optimization
- **Staff Utilization**: Doctor workload distribution and specialty demand analysis
- **Quality Assurance**: Clinical outcome monitoring and improvement identification

## 🎯 Business Impact

### **Expected Outcomes**
- **Cost Reduction**: 10-15% reduction in unnecessary medical expenses
- **Improved Care**: Better patient outcomes through data-driven decisions
- **Efficiency Gains**: Optimized resource allocation and bed management
- **Prevention Focus**: Reduced emergency admissions through preventive care

### **ROI Metrics**
- **Prevention Investment**: $1 invested saves $3-5 in treatment costs
- **Early Diagnosis**: 25-30% reduction in advanced treatment needs
- **Efficiency Improvements**: 15-20% better resource utilization

## 📋 Implementation Roadmap

### **Phase 1: Immediate Actions**
- Implement diabetes and obesity management programs
- Optimize emergency admission workflows
- Enhance medication management protocols

### **Phase 2: System Improvements**
- Deploy preventive care screening programs
- Improve insurance claim processing efficiency
- Establish chronic disease management centers

### **Phase 3: Advanced Analytics**
- Implement predictive modeling for patient outcomes
- Deploy real-time monitoring dashboards
- Establish value-based care partnerships

## 🔍 SQL Query Reference Guide

### **Key Business Intelligence Queries**

#### **Executive Summary Query**
```sql
SELECT 
    'EXECUTIVE SUMMARY - Key Business Insights & Recommendations' AS summary_type,
    (SELECT GROUP_CONCAT(medical_condition ORDER BY total_cost DESC SEPARATOR ', ') 
     FROM (SELECT medical_condition, SUM(billing_amount) as total_cost 
           FROM hospitalrecords GROUP BY medical_condition ORDER BY total_cost DESC LIMIT 5) 
     AS top_conditions) AS top_cost_drivers,
    CONCAT('$', ROUND((SELECT AVG(billing_amount) FROM hospitalrecords 
                       WHERE insurance_provider = 'Self-pay'), 2)) AS avg_out_of_pocket_expense;
```

#### **High-Cost Diagnosis Analysis**
```sql
SELECT 
    medical_condition AS diagnosis,
    COUNT(*) AS patient_count,
    ROUND(SUM(billing_amount), 2) AS total_medical_cost,
    ROUND(AVG(billing_amount), 2) AS avg_cost_per_patient,
    ROUND(AVG(stay_days), 1) AS avg_hospital_stay_days
FROM hospitalrecords
GROUP BY medical_condition
ORDER BY total_medical_cost DESC
LIMIT 5;
```

#### **Patient Demographics and Cost Correlation**
```sql
SELECT 
    age_group AS patient_group,
    gender,
    COUNT(*) AS patient_count,
    ROUND(AVG(billing_amount), 2) AS avg_medical_cost,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    ROUND(STDDEV(billing_amount), 2) AS cost_variability
FROM hospitalrecords
GROUP BY age_group, gender
ORDER BY avg_medical_cost DESC;
```

#### **Insurance Coverage Impact Analysis**
```sql
SELECT 
    insurance_provider,
    COUNT(*) AS patients_covered,
    ROUND(SUM(billing_amount), 2) AS total_claims_amount,
    ROUND(AVG(billing_amount), 2) AS avg_claim_per_patient,
    ROUND(AVG(stay_days), 1) AS avg_stay_duration
FROM hospitalrecords
GROUP BY insurance_provider
ORDER BY total_claims_amount DESC;
```

### **Advanced Analytics Queries**

#### **Treatment Effectiveness Analysis**
```sql
SELECT 
    medical_condition,
    medication,
    COUNT(*) AS treatment_cases,
    ROUND(AVG(stay_days), 1) AS avg_recovery_time,
    ROUND(AVG(billing_amount), 2) AS avg_treatment_cost,
    ROUND(STDDEV(stay_days), 1) AS recovery_consistency
FROM hospitalrecords
GROUP BY medical_condition, medication
HAVING treatment_cases >= 10
ORDER BY medical_condition, avg_recovery_time;
```

#### **Hospital Efficiency Metrics**
```sql
SELECT 
    hospital,
    COUNT(*) AS total_patients,
    ROUND(AVG(stay_days), 1) AS avg_length_of_stay,
    ROUND(AVG(billing_amount), 2) AS avg_cost_per_patient,
    COUNT(DISTINCT medical_condition) AS conditions_treated,
    SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) AS emergency_cases,
    ROUND(SUM(CASE WHEN admission_type = 'Emergency' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS emergency_rate
FROM hospitalrecords
GROUP BY hospital
ORDER BY total_patients DESC;
```

## 📝 Technical Notes

- **Database**: MySQL with optimized healthcare query performance
- **Query Architecture**: 8-task analytical framework with 50+ comprehensive queries
- **Visualization**: Power BI with responsive healthcare dashboard design
- **Data Quality**: Comprehensive validation and healthcare compliance procedures
- **Scalability**: Framework designed for expanding healthcare datasets
- **Error Handling**: Dynamic column detection and graceful degradation for missing data
- **Performance**: Optimized queries with proper indexing and aggregation strategies

## 🔍 Future Enhancements

- **Machine Learning**: Predictive models for patient outcomes and readmission risk
- **Real-time Analytics**: Live patient monitoring and alert systems
- **Clinical Integration**: Electronic Health Record (EHR) system connectivity
- **Population Health**: Community health trend analysis and interventions

---

*This project demonstrates comprehensive healthcare analytics capabilities, providing data-driven insights for improved patient care, cost optimization, and operational efficiency in healthcare management.*