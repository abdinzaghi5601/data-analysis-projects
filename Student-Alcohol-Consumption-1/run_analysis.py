#!/usr/bin/env python3
"""
Student Alcohol Consumption Analysis - Python Script Version
Run this if you can't open Jupyter notebooks
"""

print("Student Alcohol Consumption Analysis")
print("=" * 50)

# Check if required packages are available
required_packages = ['pandas', 'numpy', 'matplotlib', 'seaborn', 'sklearn']
missing_packages = []

for package in required_packages:
    try:
        __import__(package)
        print(f"✓ {package} is available")
    except ImportError:
        missing_packages.append(package)
        print(f"✗ {package} is missing")

if missing_packages:
    print(f"\nMissing packages: {', '.join(missing_packages)}")
    print("Please install them using:")
    print(f"pip3 install {' '.join(missing_packages)}")
    exit(1)

# If all packages are available, import them
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, r2_score

print("\nAll required packages are available!")
print("You can now run the analysis.")

# Basic analysis example
print("\n" + "=" * 50)
print("SAMPLE ANALYSIS (with dummy data)")
print("=" * 50)

# Create sample data since the actual dataset might not be available
np.random.seed(42)
n_students = 100

sample_data = {
    'age': np.random.randint(15, 20, n_students),
    'studytime': np.random.randint(1, 5, n_students),
    'failures': np.random.randint(0, 4, n_students),
    'Dalc': np.random.randint(1, 6, n_students),
    'Walc': np.random.randint(1, 6, n_students),
    'absences': np.random.randint(0, 20, n_students)
}

# Create G3 with some correlation to alcohol consumption
sample_data['G3'] = 15 - (sample_data['Dalc'] + sample_data['Walc']) * 0.5 + \
                   sample_data['studytime'] * 1.5 - sample_data['failures'] * 2 + \
                   np.random.normal(0, 2, n_students)

df_sample = pd.DataFrame(sample_data)

print(f"Sample dataset shape: {df_sample.shape}")
print(f"Average final grade (G3): {df_sample['G3'].mean():.2f}")
print(f"Average weekday alcohol consumption: {df_sample['Dalc'].mean():.2f}")
print(f"Average weekend alcohol consumption: {df_sample['Walc'].mean():.2f}")

# Simple correlation analysis
correlation = df_sample['G3'].corr(df_sample['Dalc'] + df_sample['Walc'])
print(f"Correlation between total alcohol consumption and G3: {correlation:.3f}")

print("\nThis is just a sample analysis with dummy data.")
print("To run the full analysis, you need to:")
print("1. Download the real dataset using: python3 download_data.py")
print("2. Open the Jupyter notebook or use one of the solutions above")

if __name__ == "__main__":
    print("\nScript completed successfully!")