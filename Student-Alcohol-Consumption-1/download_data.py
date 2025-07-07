#!/usr/bin/env python3
"""
Data Download Script for Student Alcohol Consumption Analysis
This script downloads the required dataset from the UCI Machine Learning Repository.
"""

import os
import urllib.request
import zipfile
import pandas as pd

def download_dataset():
    """Download and extract the student performance dataset."""
    
    # UCI dataset URL
    url = "https://archive.ics.uci.edu/static/public/320/student+performance.zip"
    zip_filename = "student_performance.zip"
    
    print("Downloading Student Performance dataset from UCI repository...")
    
    try:
        # Download the dataset
        urllib.request.urlretrieve(url, zip_filename)
        print(f"✓ Downloaded {zip_filename}")
        
        # Extract the zip file
        with zipfile.ZipFile(zip_filename, 'r') as zip_ref:
            zip_ref.extractall(".")
        print("✓ Extracted dataset files")
        
        # Clean up the zip file
        os.remove(zip_filename)
        print("✓ Cleaned up zip file")
        
        # Check if the required files exist
        required_files = ['student-mat.csv', 'student-por.csv']
        for file in required_files:
            if os.path.exists(file):
                print(f"✓ Found {file}")
                
                # Display basic info about the dataset
                df = pd.read_csv(file, sep=';')
                print(f"  - Shape: {df.shape}")
                print(f"  - Columns: {len(df.columns)}")
            else:
                print(f"✗ Missing {file}")
        
        print("\nDataset download completed successfully!")
        print("You can now run the analysis notebook: Student_Alcohol_Consumption_Analysis_Improved.ipynb")
        
    except Exception as e:
        print(f"Error downloading dataset: {e}")
        print("Please manually download the dataset from:")
        print("https://archive.ics.uci.edu/ml/datasets/Student+Performance")

if __name__ == "__main__":
    download_dataset()