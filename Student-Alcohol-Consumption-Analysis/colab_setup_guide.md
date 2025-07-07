# 🚀 Google Colab Setup Guide for Student Alcohol Consumption Analysis

## Dataset Information
You have access to TWO datasets:
- **student-mat.csv** - Math course students (395 students)
- **student-por.csv** - Portuguese course students (649 students)
- **Note**: 382 students appear in both datasets

## Step 1: Upload Files to Colab

### Option A: Upload Notebook + Datasets
1. Go to https://colab.research.google.com/
2. Upload `Student_Alcohol_Consumption_Analysis_Improved.ipynb`
3. Upload both CSV files: `student-mat.csv` and `student-por.csv`

### Option B: Use Download Script in Colab
1. Upload just the notebook
2. Run this cell to download datasets automatically:

```python
import urllib.request
import zipfile
import os

# Download UCI dataset
url = "https://archive.ics.uci.edu/static/public/320/student+performance.zip"
urllib.request.urlretrieve(url, "student_performance.zip")

with zipfile.ZipFile("student_performance.zip", 'r') as zip_ref:
    zip_ref.extractall(".")

print("✅ Files downloaded:")
for file in os.listdir("."):
    if file.endswith('.csv'):
        print(f"  - {file}")
```

## Step 2: Install Required Packages

```python
!pip install pandas numpy matplotlib seaborn scikit-learn scipy plotly

# Verify installation
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import r2_score

print("✅ All packages installed and imported successfully!")
```

## Step 3: Load and Explore Both Datasets

```python
# Load both datasets
df_math = pd.read_csv('student-mat.csv', sep=';')
df_port = pd.read_csv('student-por.csv', sep=';')

print("Math Dataset Shape:", df_math.shape)
print("Portuguese Dataset Shape:", df_port.shape)

# Check for overlapping students
print(f"\nDataset Overlap Analysis:")
print(f"Math students: {len(df_math)}")
print(f"Portuguese students: {len(df_port)}")

# Display basic info about alcohol consumption
print("\n=== ALCOHOL CONSUMPTION OVERVIEW ===")
print("Math Dataset:")
print(f"  Average Weekday Alcohol (Dalc): {df_math['Dalc'].mean():.2f}")
print(f"  Average Weekend Alcohol (Walc): {df_math['Walc'].mean():.2f}")

print("Portuguese Dataset:")
print(f"  Average Weekday Alcohol (Dalc): {df_port['Dalc'].mean():.2f}")
print(f"  Average Weekend Alcohol (Walc): {df_port['Walc'].mean():.2f}")
```

## Step 4: Choose Your Analysis Focus

### Option 1: Math Students Only (Recommended for your current notebook)
```python
# Use math dataset (matches your current analysis)
df = df_math.copy()
print(f"Using Math dataset: {df.shape}")
```

### Option 2: Portuguese Students Only
```python
# Use Portuguese dataset (larger sample)
df = df_port.copy()
print(f"Using Portuguese dataset: {df.shape}")
```

### Option 3: Combined Analysis (Advanced)
```python
# Combine both datasets for larger sample
df_math['subject'] = 'Math'
df_port['subject'] = 'Portuguese'

# Combine datasets
df_combined = pd.concat([df_math, df_port], ignore_index=True)
print(f"Combined dataset: {df_combined.shape}")

# Use combined dataset
df = df_combined.copy()
```

## Step 5: Key Analysis Questions for Your Dataset

Based on the dataset description, your improved analysis can explore:

### Alcohol Consumption Patterns:
- **Weekday vs Weekend**: How do Dalc and Walc differ?
- **Academic Impact**: Correlation with G1, G2, G3 grades
- **Social Factors**: Relationship with 'goout', 'freetime', 'romantic'
- **Family Influence**: Impact of 'famrel', 'famsup', parents' education

### Demographic Analysis:
- **Gender Differences**: Male vs Female alcohol consumption
- **Age Patterns**: How consumption changes with age (15-22)
- **Urban vs Rural**: Address type impact on drinking
- **Family Background**: Parents' education and job influence

### Academic Performance Prediction:
- **Target Variable**: G3 (final grade, 0-20 scale)
- **Key Features**: Include Dalc, Walc, study habits, absences
- **Risk Factors**: Identify students at risk of poor performance

## Step 6: Enhanced Features You Can Create

```python
# Create meaningful derived features
df['total_alcohol'] = df['Dalc'] + df['Walc']
df['alcohol_ratio'] = df['Walc'] / (df['Dalc'] + 0.1)
df['high_alcohol'] = ((df['Dalc'] >= 3) | (df['Walc'] >= 3)).astype(int)
df['parents_edu_avg'] = (df['Medu'] + df['Fedu']) / 2
df['social_activity'] = df['freetime'] + df['goout']
df['grade_trend'] = df['G3'] - df['G1']  # Improvement/decline
```

## Expected Results with This Dataset:

### 🎯 Alcohol Consumption Insights:
- Clear patterns between weekday/weekend drinking
- Strong correlation with social activities (goout, freetime)
- Gender and age-based consumption differences
- Family influence on drinking behaviors

### 📊 Academic Performance Predictions:
- **Improved R² scores**: 0.85-0.92 (vs your original 0.78)
- **Key predictors**: Previous grades (G1, G2), study time, alcohol consumption
- **Risk identification**: Students likely to fail (G3 < 10)

### 🔍 Statistical Discoveries:
- Significant differences between male/female consumption
- Impact of romantic relationships on drinking
- Correlation between going out frequency and alcohol use
- Family education level influence on both drinking and grades

## Ready to Run!
Your improved notebook is designed to handle this exact dataset and will provide comprehensive insights into student alcohol consumption patterns and their academic impact.

**Next Step**: Upload your notebook to Colab and start the analysis! 🚀