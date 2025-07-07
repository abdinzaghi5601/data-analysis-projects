#!/usr/bin/env python3
"""
System Check Script - Run this to see what's available on your system
"""

import sys
import os
import subprocess

print("=" * 60)
print("SYSTEM CHECK FOR JUPYTER SETUP")
print("=" * 60)

print(f"Python version: {sys.version}")
print(f"Python executable: {sys.executable}")
print(f"Current working directory: {os.getcwd()}")

print("\n" + "=" * 60)
print("CHECKING PACKAGE MANAGERS")
print("=" * 60)

# Check for different package managers
managers = ['pip', 'pip3', 'conda', 'apt']
for manager in managers:
    try:
        result = subprocess.run([manager, '--version'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print(f"✓ {manager}: {result.stdout.strip()}")
        else:
            print(f"✗ {manager}: Not working")
    except (FileNotFoundError, subprocess.TimeoutExpired):
        print(f"✗ {manager}: Not found")

print("\n" + "=" * 60)
print("RECOMMENDATIONS")
print("=" * 60)

print("Based on your system, here are the best options:")
print("1. 🥇 Google Colab: https://colab.research.google.com/")
print("   - Upload your .ipynb file")
print("   - No installation needed")
print("   - Works immediately")

print("\n2. 🥈 Manual installation (if you have sudo access):")
print("   sudo apt update")
print("   sudo apt install python3-pip")
print("   pip3 install jupyter pandas numpy matplotlib seaborn scikit-learn")

print("\n3. 🥉 Windows Python (if available):")
print("   Open Windows Command Prompt")
print("   pip install jupyter pandas numpy matplotlib seaborn scikit-learn")

print("\n4. 🛠️ VS Code with Jupyter extension")
print("   - Install VS Code")
print("   - Install Python and Jupyter extensions")
print("   - Open .ipynb files directly")

print("\n" + "=" * 60)
print("NEXT STEPS")
print("=" * 60)
print("Choose the option that works best for your system!")