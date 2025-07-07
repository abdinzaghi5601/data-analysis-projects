# 🚀 COLAB STARTER CELLS - Copy these into your Colab notebook

# =============================================================================
# CELL 1: Install Required Packages
# =============================================================================
!pip install pandas numpy matplotlib seaborn scikit-learn scipy plotly -q

print("✅ All packages installed successfully!")

# =============================================================================
# CELL 2: Import Libraries
# =============================================================================
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import plotly.express as px
import plotly.graph_objects as go

# Machine Learning
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV, KFold
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.linear_model import LinearRegression, Ridge, Lasso
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.svm import SVR
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# Set style
plt.style.use('default')
sns.set_palette("husl")
pd.set_option('display.max_columns', None)

print("✅ All libraries imported successfully!")

# =============================================================================
# CELL 3: Load and Explore Datasets
# =============================================================================
# Load both datasets (upload these files to Colab first)
try:
    df_math = pd.read_csv('student-mat.csv', sep=';')
    print(f"✅ Math dataset loaded: {df_math.shape}")
except:
    print("❌ student-mat.csv not found. Please upload it to Colab.")

try:
    df_port = pd.read_csv('student-por.csv', sep=';')
    print(f"✅ Portuguese dataset loaded: {df_port.shape}")
except:
    print("❌ student-por.csv not found. Please upload it to Colab.")

# Quick dataset comparison
if 'df_math' in locals() and 'df_port' in locals():
    print(f"\n=== DATASET OVERVIEW ===")
    print(f"Math students: {len(df_math)}")
    print(f"Portuguese students: {len(df_port)}")
    print(f"Total unique students: ~{len(df_math) + len(df_port) - 382}")
    print(f"Overlapping students: ~382")
    
    print(f"\n=== ALCOHOL CONSUMPTION COMPARISON ===")
    print(f"Math - Weekday avg: {df_math['Dalc'].mean():.2f}, Weekend avg: {df_math['Walc'].mean():.2f}")
    print(f"Portuguese - Weekday avg: {df_port['Dalc'].mean():.2f}, Weekend avg: {df_port['Walc'].mean():.2f}")

# =============================================================================
# CELL 4: Choose Dataset for Analysis
# =============================================================================
# Option 1: Use Math dataset (recommended for initial analysis)
df = df_math.copy()
dataset_name = "Math"

# Option 2: Use Portuguese dataset (larger sample)
# df = df_port.copy()
# dataset_name = "Portuguese"

# Option 3: Combine both datasets (advanced analysis)
# df_math['subject'] = 'Math'
# df_port['subject'] = 'Portuguese'
# df = pd.concat([df_math, df_port], ignore_index=True)
# dataset_name = "Combined"

print(f"✅ Using {dataset_name} dataset for analysis: {df.shape}")
print(f"Columns: {list(df.columns)}")

# =============================================================================
# CELL 5: Basic Dataset Exploration
# =============================================================================
print("=== BASIC DATASET INFO ===")
print(f"Shape: {df.shape}")
print(f"Missing values: {df.isnull().sum().sum()}")
print(f"Data types:\n{df.dtypes.value_counts()}")

print(f"\n=== ALCOHOL CONSUMPTION STATS ===")
print(f"Dalc (Weekday) - Mean: {df['Dalc'].mean():.2f}, Range: {df['Dalc'].min()}-{df['Dalc'].max()}")
print(f"Walc (Weekend) - Mean: {df['Walc'].mean():.2f}, Range: {df['Walc'].min()}-{df['Walc'].max()}")
print(f"Students with high weekend drinking (Walc >= 3): {(df['Walc'] >= 3).sum()} ({(df['Walc'] >= 3).mean()*100:.1f}%)")
print(f"Students with high weekday drinking (Dalc >= 3): {(df['Dalc'] >= 3).sum()} ({(df['Dalc'] >= 3).mean()*100:.1f}%)")

print(f"\n=== ACADEMIC PERFORMANCE ===")
print(f"Final Grade (G3) - Mean: {df['G3'].mean():.2f}, Range: {df['G3'].min()}-{df['G3'].max()}")
print(f"Students failing (G3 < 10): {(df['G3'] < 10).sum()} ({(df['G3'] < 10).mean()*100:.1f}%)")

# =============================================================================
# CELL 6: Quick Visualization
# =============================================================================
fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# Alcohol consumption distribution
axes[0,0].hist([df['Dalc'], df['Walc']], bins=5, alpha=0.7, label=['Weekday', 'Weekend'])
axes[0,0].set_title('Alcohol Consumption Distribution')
axes[0,0].set_xlabel('Consumption Level (1-5)')
axes[0,0].legend()

# Grade distribution
axes[0,1].hist(df['G3'], bins=20, alpha=0.7, color='green')
axes[0,1].set_title('Final Grade (G3) Distribution')
axes[0,1].set_xlabel('Grade (0-20)')

# Alcohol vs Grades
axes[1,0].scatter(df['Dalc'] + df['Walc'], df['G3'], alpha=0.6)
axes[1,0].set_title('Total Alcohol vs Final Grade')
axes[1,0].set_xlabel('Total Alcohol (Dalc + Walc)')
axes[1,0].set_ylabel('Final Grade (G3)')

# Gender comparison
gender_alcohol = df.groupby('sex')[['Dalc', 'Walc']].mean()
gender_alcohol.plot(kind='bar', ax=axes[1,1])
axes[1,1].set_title('Average Alcohol Consumption by Gender')
axes[1,1].set_ylabel('Average Consumption')
axes[1,1].tick_params(axis='x', rotation=0)

plt.tight_layout()
plt.show()

print("✅ Dataset loaded and ready for comprehensive analysis!")
print("👉 Now run your improved notebook cells for detailed analysis!")