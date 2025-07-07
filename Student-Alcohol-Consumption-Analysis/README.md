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
*(Results will be updated after running the improved analysis)*

## Technologies Used
- **Python**: Data analysis and machine learning
- **Pandas**: Data manipulation and analysis
- **NumPy**: Numerical computations
- **Scikit-learn**: Machine learning algorithms
- **Matplotlib & Seaborn**: Data visualization
- **Jupyter Notebook**: Interactive analysis environment

## Files Description
- `Student_Alcohol_Consumption_Analysis_Improved.ipynb`: **NEW** - Comprehensive improved analysis notebook
- `Student_Alcohol_Consumption_Analysis.ipynb`: Original analysis notebook
- `download_data.py`: Python script to automatically download the dataset
- `requirements.txt`: List of required Python packages
- `README.md`: Project documentation
- `Below is a brief description of each column in your dataset.docx`: Dataset column descriptions

## How to Run
1. **Install required packages**: `pip install -r requirements.txt`
2. **Download the dataset**: `python download_data.py`
3. **Run the improved analysis**: Open `Student_Alcohol_Consumption_Analysis_Improved.ipynb` in Jupyter
4. **Alternative**: Use the original notebook: `Student_Alcohol_Consumption_Analysis.ipynb`

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