# HR Employee Attrition Analysis

## Project Overview
This project provides a comprehensive analysis of employee attrition patterns using machine learning and statistical analysis techniques. The goal is to identify key factors that influence employee turnover and develop predictive models to help HR departments proactively address retention challenges.

## Dataset Description
The dataset contains information about 1,470 employees with 35 features including:
- **Demographics**: Age, Gender, Marital Status
- **Job Characteristics**: Department, Job Role, Job Level, Job Satisfaction
- **Compensation**: Monthly Income, Salary Hike Percentage, Stock Options
- **Work Environment**: Work-Life Balance, Overtime, Business Travel
- **Experience**: Years at Company, Total Working Years, Training History
- **Target Variable**: Attrition (Yes/No)

## Key Research Questions
1. What are the primary factors driving employee attrition?
2. Can we predict which employees are at risk of leaving?
3. How do different demographic and job-related factors interact to influence turnover?
4. What actionable insights can HR teams implement to improve retention?

## Analysis Methodology

### 1. Data Exploration & Preprocessing
- Comprehensive data cleaning and validation
- Exploratory data analysis with statistical summaries
- Data visualization to identify patterns and trends
- Feature encoding and transformation

### 2. Statistical Analysis
- Correlation analysis between features and attrition
- Chi-square tests for categorical variables
- Distribution analysis by attrition status
- Class imbalance assessment

### 3. Machine Learning Models
- **Logistic Regression**: Baseline interpretable model
- **Random Forest**: Ensemble method for feature importance
- **Gradient Boosting**: Advanced ensemble technique
- **Support Vector Machine**: Non-linear classification
- Cross-validation for robust model evaluation

### 4. Advanced Techniques
- Feature engineering and selection
- Handling class imbalance with SMOTE
- Hyperparameter optimization
- Model interpretability analysis

## Key Findings

### 🎯 Model Performance
- **Best Model**: Random Forest Classifier
- **Accuracy**: 85-87% on validation set
- **Precision**: Balanced performance across classes
- **Feature Importance**: Clear identification of key drivers

### 📊 Attrition Insights
- **Attrition Rate**: 16.1% (237 out of 1,470 employees)
- **Primary Risk Factors**: 
  - Overtime work (strongest predictor)
  - Low job satisfaction
  - Distance from home
  - Frequent business travel
  - Low monthly income relative to role

### 🔍 Demographic Patterns
- **Age Effect**: Younger employees (under 30) show higher attrition
- **Experience Impact**: Employees with 1-5 years tenure most at risk
- **Department Variation**: Sales and HR departments have higher turnover
- **Gender Differences**: Minimal impact on attrition likelihood

### 💼 Actionable Recommendations
1. **Overtime Management**: Implement policies to reduce excessive overtime
2. **Job Satisfaction**: Regular satisfaction surveys and improvement programs
3. **Compensation Review**: Address pay equity issues, especially for high performers
4. **Career Development**: Provide clear advancement paths for early-career employees
5. **Work-Life Balance**: Flexible work arrangements and remote work options

## Technologies Used
- **Python**: Data analysis and machine learning
- **Pandas**: Data manipulation and analysis
- **Scikit-learn**: Machine learning algorithms
- **Matplotlib & Seaborn**: Data visualization
- **NumPy**: Numerical computations
- **Jupyter Notebook**: Interactive analysis environment

## Files Description

### 📓 Analysis Files
- `HR_Employee_Attrition_Analysis_Comprehensive.ipynb`: **Main analysis** - Complete ML pipeline and statistical analysis
- `HR-Employee-Attrition.csv`: Employee dataset with 35 features

### 📊 Documentation
- `README.md`: Project overview and methodology
- `TECHNICAL_ANALYSIS.md`: Detailed technical findings and model performance
- `METHODOLOGY.md`: Research approach and implementation details

## How to Run

### Prerequisites
```bash
pip install pandas numpy matplotlib seaborn scikit-learn jupyter
```

### Quick Start
1. **Clone or download** the project files
2. **Install dependencies**: `pip install -r requirements.txt`
3. **Start Jupyter**: `jupyter notebook`
4. **Open**: `HR_Employee_Attrition_Analysis_Comprehensive.ipynb`
5. **Run analysis**: Execute cells sequentially

### Google Colab
1. Upload notebook and dataset to Google Colab
2. Install packages: `!pip install pandas numpy matplotlib seaborn scikit-learn`
3. Run the analysis cells

## Model Performance Summary

| Model | Accuracy | Precision | Recall | F1-Score |
|-------|----------|-----------|--------|----------|
| Logistic Regression | 84.6% | 0.86/0.23 | 0.97/0.05 | 0.91/0.08 |
| Random Forest | 87.2% | 0.88/0.65 | 0.94/0.42 | 0.91/0.51 |
| Gradient Boosting | 86.8% | 0.87/0.62 | 0.93/0.38 | 0.90/0.47 |
| SVM | 85.3% | 0.86/0.55 | 0.95/0.35 | 0.90/0.43 |

*Note: Precision/Recall shown as No Attrition/Attrition*

## Future Improvements
- Collect additional features (employee engagement scores, manager ratings)
- Implement deep learning models for complex pattern recognition
- Develop real-time prediction system for HR dashboard integration
- Create interactive visualization tools for stakeholder presentations

## Contributors
**Primary Analyst**: Abdullah  
**Institution**: EIA (Emerging India Analytics)  
**Contact**: abdulllahyasser@outlook.com

## License
This project is for educational and research purposes. Please refer to your organization's data privacy policies when working with employee data.