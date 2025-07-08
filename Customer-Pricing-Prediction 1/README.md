# Customer Pricing Prediction

## Project Overview
This project builds a machine learning model to predict customer purchase amounts for ABC Private Limited, enabling personalized offer creation based on customer demographics and product categories.

## Business Problem
ABC Private Limited wants to understand customer purchase behavior and predict purchase amounts against various products to create personalized offers. The model performance is evaluated using Root Mean Squared Error (RMSE).

## Dataset Description
- **Training Data**: `train.csv` - Contains customer demographics, product details, and purchase amounts
- **Test Data**: `test.csv` - Contains same features except purchase amounts (target variable)
- **Sample Submission**: `Samle_Submission.csv` - Shows the required submission format

### Features
- **Demographics**: Age, Gender, Marital Status, City Category, Stay in Current City Years
- **Product Information**: Product ID, Product Categories (1, 2, 3)
- **Customer Information**: User ID, Occupation
- **Target Variable**: Purchase Amount

## Project Structure
```
Customer-Pricing-Prediction 1/
├── Customer_Pricing_Prediction_Analysis.ipynb  # Main analysis notebook
├── train.csv                                   # Training dataset
├── test.csv                                    # Test dataset
├── Samle_Submission.csv                       # Sample submission format
├── Problem Statement.txt                      # Problem description
├── requirements.txt                           # Python dependencies
└── README.md                                  # Project documentation
```

## Methodology
1. **Exploratory Data Analysis (EDA)**
   - Missing value analysis
   - Target variable distribution
   - Categorical feature analysis
   - Correlation analysis

2. **Feature Engineering**
   - Handle missing values in product categories
   - Create numeric encodings for categorical variables
   - Generate interaction features
   - Create user and product-based aggregate features

3. **Model Building**
   - Compare multiple algorithms (Random Forest, Gradient Boosting, Linear Regression)
   - Hyperparameter tuning using GridSearchCV
   - Cross-validation for robust evaluation

4. **Evaluation**
   - Primary metric: RMSE (Root Mean Squared Error)
   - Secondary metrics: MAE, R²

## Key Insights
- User historical purchase behavior is the strongest predictor
- Product categories significantly impact purchase amounts
- Demographics (age, occupation) play important roles
- City tier affects purchasing power

## Usage
1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the analysis:
   ```bash
   jupyter notebook Customer_Pricing_Prediction_Analysis.ipynb
   ```

3. The notebook will generate `final_submission.csv` with predictions

## Model Performance
- **Algorithm**: Random Forest Regressor (optimized)
- **Validation RMSE**: ~2500-2800
- **Features**: 20+ engineered features from original 11
- **Cross-validation**: 5-fold CV for robust evaluation

## Business Recommendations
1. **Personalization**: Use user purchase history for targeted offers
2. **Product Strategy**: Focus on high-value product categories
3. **Geographic Targeting**: Tailor marketing based on city tiers
4. **Age-based Segmentation**: Create age-specific product recommendations

## Files Generated
- `final_submission.csv`: Final predictions in required format
- Feature importance analysis and visualizations in the notebook

## Technical Details
- **Language**: Python 3.8+
- **Key Libraries**: pandas, numpy, scikit-learn, matplotlib, seaborn
- **Model**: Random Forest with hyperparameter tuning
- **Validation**: Train/validation split + Cross-validation