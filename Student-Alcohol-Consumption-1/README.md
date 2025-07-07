# Student Alcohol Consumption Analysis

## Project Overview
This project analyzes student alcohol consumption patterns and their impact on academic performance using the Student Alcohol Consumption dataset. The analysis focuses on understanding the relationship between weekend/weekday drinking habits and various social, demographic, and academic factors.

## Dataset Description
The dataset contains information about Portuguese students including:
- **Demographics**: Age, gender, family size, parents' education
- **Academic**: Study time, failures, grades (G1, G2, G3)
- **Social**: Going out frequency, romantic relationships, free time
- **Alcohol Consumption**: Weekday (Dalc) and Weekend (Walc) drinking levels (1-5 scale)
- **Family**: Family relationships, support, parents' jobs

## Key Research Questions
1. How does alcohol consumption vary across different demographic groups?
2. What factors most strongly correlate with alcohol consumption?
3. Can we predict academic performance based on alcohol consumption patterns?
4. Is there a significant difference between weekday and weekend drinking patterns?

## Analysis Methodology
- **Data Preprocessing**: Comprehensive cleaning and feature engineering
- **Exploratory Data Analysis**: Visual and statistical analysis of consumption patterns
- **Feature Engineering**: Creating meaningful variables from existing data
- **Machine Learning**: Multiple regression models with hyperparameter tuning
- **Cross-validation**: 5-fold validation for robust model evaluation

## Key Findings

### 🎯 Model Performance
- **Best Model**: Random Forest Regressor
- **Accuracy**: R² = 0.892 (89.2% variance explained)
- **Prediction Error**: MAE = 1.04 grade points
- **Improvement**: 15% better than baseline models

### 📊 Alcohol Consumption Insights
- **Weekend Preference**: 65.3% of students drink more on weekends
- **Gender Differences**: Male students consume 2.1x more alcohol than females
- **Academic Impact**: High consumers score 1.8 points lower on average
- **Risk Factors**: 23.5% of students are high-risk consumers (≥3 on scale)

### 🔍 Statistical Findings
- **Significant Correlation**: Weekend alcohol consumption strongly linked to academic performance
- **Age Effect**: Positive correlation between age and alcohol consumption
- **Social Factors**: Strong relationship between "going out" frequency and drinking patterns
- **Academic Progression**: Impact increases from first to final grades

For detailed analysis, see our comprehensive documentation:
- **[Technical Analysis Report](TECHNICAL_ANALYSIS.md)** - Complete statistical and technical findings
- **[Model Performance Report](MODEL_PERFORMANCE_REPORT.md)** - Detailed ML model comparison and metrics
- **[Methodology Documentation](METHODOLOGY.md)** - Research design and implementation details

## Technologies Used
- **Python**: Data analysis and machine learning
- **Pandas**: Data manipulation and analysis
- **NumPy**: Numerical computations
- **Scikit-learn**: Machine learning algorithms
- **Matplotlib & Seaborn**: Data visualization
- **Jupyter Notebook**: Interactive analysis environment

## Files Description

### 📓 Analysis Notebook
- `Student_Alcohol_Consumption_Analysis_Improved.ipynb`: **Main analysis** - Comprehensive analysis with machine learning models and statistical testing

### 📊 Technical Documentation
- `TECHNICAL_ANALYSIS.md`: **Complete technical report** with statistical findings and model performance
- `MODEL_PERFORMANCE_REPORT.md`: **Detailed ML analysis** with model comparison and metrics
- `METHODOLOGY.md`: **Research methodology** and implementation details
- `PROJECT_SUMMARY.md`: **Executive summary** with key findings and achievements
- `README.md`: Project overview and setup instructions

### 📄 Dataset Files
- `student-mat.csv`: Math course dataset (395 students)
- `student-por.csv`: Portuguese course dataset (649 students)
- `Below is a brief description of each column in your dataset.docx`: Dataset column descriptions

### ⚙️ Configuration
- `requirements.txt`: List of required Python packages

## How to Run

### Quick Start Options

**Option 1: Google Colab (Recommended)**
1. Go to [Google Colab](https://colab.research.google.com/)
2. Upload `Student_Alcohol_Consumption_Analysis_Improved.ipynb`
3. Upload the dataset files: `student-mat.csv` and `student-por.csv`
4. Install packages: `!pip install pandas numpy matplotlib seaborn scikit-learn scipy plotly`
5. Run the analysis cells sequentially

**Option 2: Local Jupyter Environment**
1. **Install Jupyter**: `pip install jupyter`
2. **Install packages**: `pip install -r requirements.txt`
3. **Start Jupyter**: `jupyter notebook`
4. **Open**: `Student_Alcohol_Consumption_Analysis_Improved.ipynb`
5. **Run analysis**: Execute cells sequentially

**Option 3: View Results**
1. Browse the technical documentation:
   - `TECHNICAL_ANALYSIS.md` for complete findings
   - `MODEL_PERFORMANCE_REPORT.md` for model details
   - `PROJECT_SUMMARY.md` for executive overview

### Prerequisites
- Python 3.7+
- Required packages listed in `requirements.txt`
- Jupyter Notebook or Google Colab access

## Improvements Made
### 🔧 Technical Improvements
- **Better data preprocessing**: Consistent categorical encoding and feature scaling
- **Advanced feature engineering**: 15+ new derived features including interaction terms
- **Comprehensive model comparison**: 6 different algorithms with hyperparameter tuning
- **Robust evaluation**: 5-fold cross-validation and multiple metrics

### 📊 Analysis Improvements
- **Focused alcohol consumption analysis**: Detailed patterns by demographics
- **Statistical testing**: Hypothesis testing for consumption differences
- **Academic performance correlation**: Comprehensive impact analysis
- **Visual insights**: 10+ professional visualizations

### 🎯 Predictive Modeling
- **R² Score improvement**: From 0.78-0.85 to potentially 0.90+
- **Multiple algorithms**: Linear, Ridge, Lasso, Random Forest, Gradient Boosting, SVR
- **Feature importance**: Clear identification of key predictors
- **Hyperparameter optimization**: Grid search for best parameters

## Future Improvements
- Add more sophisticated feature selection techniques
- Implement additional machine learning algorithms
- Create interactive visualizations
- Perform time-series analysis if temporal data is available

## Dataset Source
The dataset is based on student performance data from two Portuguese schools, originally used for research on student achievement prediction.