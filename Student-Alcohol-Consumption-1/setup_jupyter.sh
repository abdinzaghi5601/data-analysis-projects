#!/bin/bash
# Jupyter Setup Script for WSL

echo "Setting up Jupyter Notebook environment..."

# Update package list
sudo apt update

# Install pip
echo "Installing pip..."
sudo apt install -y python3-pip

# Install Jupyter and required packages
echo "Installing Jupyter and data science packages..."
pip3 install --user jupyter notebook pandas numpy matplotlib seaborn scikit-learn scipy plotly

# Add pip user bin to PATH if not already there
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "Setup complete!"
echo ""
echo "To start Jupyter Notebook:"
echo "1. Run: source ~/.bashrc"
echo "2. Run: jupyter notebook"
echo "3. Open the URL in your browser (usually http://localhost:8888)"
echo ""
echo "To run this setup script:"
echo "chmod +x setup_jupyter.sh"
echo "./setup_jupyter.sh"