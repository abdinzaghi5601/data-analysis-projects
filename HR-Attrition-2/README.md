# HR Analytics Using SQL and Power BI

## 🎯 Project Overview

This comprehensive HR analytics project analyzes employee attrition, satisfaction, and performance metrics using SQL for data processing and Power BI for interactive visualizations. The analysis provides actionable insights to help HR departments improve employee retention and overall job satisfaction.

## 📋 Objectives

By the end of this project, we have:
- ✅ Conducted exploratory data analysis (EDA) to identify trends and factors influencing attrition
- ✅ Used SQL for comprehensive data cleaning, transformation, and aggregation
- ✅ Created interactive dashboards in Power BI to visualize key HR metrics
- ✅ Provided insights and recommendations for improving employee retention and satisfaction

## 📊 Dataset Information

- **Dataset Name**: HR Analytics
- **Total Records**: 1,470+ employees
- **Format**: CSV with comprehensive employee data
- **Scope**: Multi-departmental employee analysis

### Key Data Categories:

#### **Employee Information**
- **EmpID**: Unique identifier for each employee
- **Age**: Employee age with derived age groups
- **Gender**: Male/Female (standardized)
- **MaritalStatus**: Single/Married/Divorced (normalized)
- **Department**: Sales, R&D, Human Resources

#### **Job and Performance Details**
- **Attrition**: Employee departure status (Yes/No)
- **JobSatisfaction**: Satisfaction level (1-4 scale)
- **PerformanceRating**: Performance evaluation (1-4 scale)
- **JobInvolvement**: Level of job involvement (1-4 scale)
- **OverTime**: Overtime work status (Yes/No)

#### **Financial Metrics**
- **MonthlyIncome**: Employee monthly salary
- **DailyRate**: Daily compensation rate
- **HourlyRate**: Hourly compensation rate
- **PercentSalaryHike**: Annual salary increase percentage
- **StockOptionLevel**: Stock option entitlement level

## 🛠️ Technical Implementation

### **Tools Used**
- **MySQL**: Database management and SQL analysis
- **Power BI**: Interactive dashboard creation
- **CSV Export**: Results documentation and sharing

### **Data Processing Pipeline**
1. **Data Import**: Load raw HR dataset into MySQL database
2. **Data Cleaning**: Remove duplicates, standardize categorical values
3. **Data Transformation**: Create derived columns and income categories
4. **Analysis**: Execute comprehensive SQL queries for insights
5. **Visualization**: Build interactive Power BI dashboards
6. **Export**: Generate CSV reports for stakeholder sharing

## 📁 Project Structure

```
HR-Attrition-2/
├── README.md                                           # Project documentation
├── Hr analytics.sql                                    # Complete SQL analysis
├── HR_Analytics.csv                                    # Raw dataset
├── HRAnalytics.pbix                                   # Power BI dashboard
├── HR Analytics.pdf                                    # Analysis report
└── Analysis Results/
    ├── Attrition analysis.csv                         # Complete cleaned dataset
    ├── Attrition by Department.csv                    # Department-wise attrition
    ├── Attrition by Job Role.csv                      # Role-specific analysis
    ├── Attrition by Age Group.csv                     # Age-based attrition
    ├── Analysis of attrition drivers.csv              # Key attrition factors
    ├── Department-specific attrition drivers.csv      # Department insights
    ├── Job satisfaction distribution by attrition status.csv
    ├── Overtime analysis.csv                          # Overtime impact analysis
    └── Salary comparison across departments and job levels.csv
```

## 🔧 Data Preparation Process

### **Data Cleaning Procedures**
- **Duplicate Removal**: Used ROW_NUMBER() function to eliminate duplicate employee records
- **Standardization**: Normalized categorical fields for consistency
  - Gender: Standardized to 'Male'/'Female'
  - MaritalStatus: Normalized to 'Single'/'Married'/'Divorced'
  - Boolean fields: Standardized to 'Yes'/'No' format

### **Data Transformation**
- **Age Groups**: Created categorical age ranges (Under 25, 25-34, 35-44, 45-54, 55+)
- **Income Categories**: Segmented salaries into Low/Medium/High/Very High brackets
- **Data Types**: Converted numerical fields to appropriate formats (integers, decimals)

### **Quality Assurance**
- **Duplicate Check**: Verified zero duplicate EmpIDs after cleaning
- **Data Validation**: Confirmed all categorical values are properly standardized
- **Range Verification**: Validated numerical data ranges and averages

## 📈 Key Findings & Insights

### **🚨 Critical Attrition Patterns**

#### **Department-Level Analysis**
- **Sales Department**: 20.79% attrition rate (Highest risk)
- **Human Resources**: 19.35% attrition rate (High risk)
- **Research & Development**: 13.83% attrition rate (Moderate risk)

#### **Overtime Impact**
- **Overtime Workers**: 30.86% attrition rate
- **Non-Overtime Workers**: 10.32% attrition rate
- **Risk Factor**: Overtime increases attrition likelihood by 3x

#### **Job Satisfaction Correlation**
- **Satisfaction Level 1**: 22.63% attrition rate
- **Satisfaction Level 2**: 16.79% attrition rate  
- **Satisfaction Level 3**: 16.67% attrition rate
- **Satisfaction Level 4**: 11.39% attrition rate

### **💰 Salary Analysis Insights**
- **Department Disparities**: Significant salary variations across departments
- **Level Progression**: Clear salary increases with job level advancement
- **Equity Opportunities**: Potential for salary standardization improvements

### **📊 Performance Metrics**
- **Job Involvement**: Higher involvement correlates with lower attrition
- **Work-Life Balance**: Poor balance significantly impacts retention
- **Training Impact**: Regular training associated with higher satisfaction

## 🎨 Power BI Dashboard Features

### **HR Overview Dashboard**
- **KPIs**: Total employees, attrition rate, average job satisfaction, average monthly income
- **Visualizations**:
  - Bar Chart: Attrition by department and job role
  - Pie Chart: Gender distribution of employees
  - Line Chart: Attrition trends over time

### **Salary and Performance Dashboard**
- **Advanced Analytics**:
  - Scatter Plot: Performance vs. Monthly Income correlation
  - Heatmap: Job satisfaction by department and performance rating
  - Matrix: Salary range analysis by job role and department

### **Interactive Features**
- **Filters**: Department, job role, age group, marital status
- **Drill-down**: Detailed analysis capabilities
- **Real-time Updates**: Dynamic filtering and exploration

## 💡 Strategic Recommendations

### **Immediate Actions (0-30 days)**
1. **Focus on Sales Department**: Implement retention strategies for highest-risk department
2. **Overtime Management**: Establish policies to reduce excessive overtime
3. **Job Satisfaction Survey**: Conduct targeted satisfaction assessments

### **Short-term Strategy (1-6 months)**
1. **Work-Life Balance Programs**: Implement flexible work arrangements
2. **Salary Equity Review**: Address compensation disparities across departments
3. **Manager Training**: Enhance supervisory skills for employee engagement

### **Long-term Vision (6-12 months)**
1. **Career Development**: Create clear advancement pathways
2. **Culture Enhancement**: Build positive work environment initiatives
3. **Predictive Analytics**: Implement early warning systems for attrition risk

## 📊 SQL Analysis Highlights

The `Hr analytics.sql` file contains comprehensive queries covering:
- **Data Cleaning**: Duplicate removal and standardization procedures
- **Attrition Analysis**: Multi-dimensional attrition pattern identification
- **Salary Analytics**: Compensation analysis across various segments
- **Performance Correlation**: Job satisfaction and performance relationships
- **Overtime Impact**: Work-life balance effect on employee retention

## 🎯 Business Impact

### **Expected Outcomes**
- **Attrition Reduction**: 15-25% decrease in employee turnover
- **Cost Savings**: Reduced recruitment and training expenses
- **Satisfaction Improvement**: Enhanced employee engagement scores
- **Productivity Gains**: Better workforce stability and performance

### **ROI Metrics**
- **Recruitment Cost Savings**: $3,000-$5,000 per retained employee
- **Training Investment Protection**: Reduced loss of training investments
- **Knowledge Retention**: Maintained institutional knowledge and expertise

## 📋 Implementation Roadmap

### **Phase 1: Immediate Interventions**
- Address overtime policies
- Implement satisfaction surveys
- Focus retention efforts on high-risk departments

### **Phase 2: Systematic Improvements**
- Salary equity adjustments
- Work-life balance programs
- Enhanced manager training

### **Phase 3: Long-term Strategy**
- Culture transformation initiatives
- Advanced analytics implementation
- Continuous improvement processes

## 📝 Technical Notes

- **Database**: MySQL with optimized query performance
- **Visualization**: Power BI with responsive dashboard design
- **Data Quality**: Comprehensive validation and cleaning procedures
- **Scalability**: Framework designed for growing datasets

## 🔍 Future Enhancements

- **Machine Learning**: Predictive attrition modeling
- **Real-time Monitoring**: Live dashboard updates
- **Advanced Segmentation**: Behavioral pattern analysis
- **Integration**: HRIS system connectivity

---

*This project demonstrates comprehensive HR analytics capabilities, providing data-driven insights for strategic workforce management and employee retention optimization.*