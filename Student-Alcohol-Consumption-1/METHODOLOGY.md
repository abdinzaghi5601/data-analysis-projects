# Methodology Documentation

## Research Design and Approach

### Research Questions
1. **Primary**: How does alcohol consumption impact student academic performance?
2. **Secondary**: What are the demographic patterns of alcohol consumption among students?
3. **Predictive**: Can we accurately predict academic outcomes using alcohol consumption and demographic data?
4. **Comparative**: What is the difference between weekday and weekend drinking patterns?

### Study Design
- **Type**: Cross-sectional observational study
- **Approach**: Quantitative analysis with machine learning
- **Data Source**: UCI Machine Learning Repository - Student Performance Dataset
- **Population**: Portuguese secondary school students (Math course)
- **Sample Size**: 395 students

## Data Collection and Sources

### Dataset Characteristics
- **Origin**: Two Portuguese schools (Gabriel Pereira and Mousinho da Silveira)
- **Collection Period**: 2005-2006 academic year
- **Collection Method**: Structured questionnaires and academic records
- **Validation**: Cross-verified with school administrative data

### Variable Categories

#### Demographic Variables (8)
- `school`: School affiliation (GP/MS)
- `sex`: Gender (M/F)
- `age`: Student age (15-22 years)
- `address`: Home address type (Urban/Rural)
- `famsize`: Family size (≤3 or >3)
- `Pstatus`: Parent cohabitation status (Together/Apart)
- `Medu`: Mother's education level (0-4 scale)
- `Fedu`: Father's education level (0-4 scale)

#### Family Background Variables (4)
- `Mjob`: Mother's occupation (5 categories)
- `Fjob`: Father's occupation (5 categories)
- `reason`: School choice reason (4 categories)
- `guardian`: Primary guardian (Mother/Father/Other)

#### Academic Variables (6)
- `traveltime`: Home to school travel time (1-4 scale)
- `studytime`: Weekly study time (1-4 scale)
- `failures`: Number of past class failures (0-4)
- `G1`: First period grade (0-20)
- `G2`: Second period grade (0-20)
- `G3`: Final grade (0-20) - **Target Variable**

#### Social and Behavioral Variables (15)
- `schoolsup`: Extra educational support (Yes/No)
- `famsup`: Family educational support (Yes/No)
- `paid`: Extra paid classes (Yes/No)
- `activities`: Extra-curricular activities (Yes/No)
- `nursery`: Attended nursery school (Yes/No)
- `higher`: Wants higher education (Yes/No)
- `internet`: Internet access at home (Yes/No)
- `romantic`: Romantic relationship (Yes/No)
- `famrel`: Family relationship quality (1-5 scale)
- `freetime`: Free time after school (1-5 scale)
- `goout`: Going out with friends (1-5 scale)
- `Dalc`: Workday alcohol consumption (1-5 scale) - **Key Variable**
- `Walc`: Weekend alcohol consumption (1-5 scale) - **Key Variable**
- `health`: Current health status (1-5 scale)
- `absences`: Number of school absences (0-93)

## Data Preprocessing Pipeline

### 1. Data Quality Assessment

#### Missing Value Analysis
```python
# Check for missing values
missing_analysis = df.isnull().sum()
missing_percentage = (missing_analysis / len(df)) * 100

# Result: 0% missing values across all variables
```

#### Outlier Detection
```python
# Identify outliers using IQR method
def detect_outliers(column):
    Q1 = column.quantile(0.25)
    Q3 = column.quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR
    return column[(column < lower_bound) | (column > upper_bound)]

# Outliers found in: absences (7 students), age (3 students)
# Decision: Retained outliers as they represent valid extreme cases
```

#### Data Type Validation
```python
# Ensure appropriate data types
categorical_vars = ['school', 'sex', 'address', 'famsize', 'Pstatus', 
                   'Mjob', 'Fjob', 'reason', 'guardian', 'schoolsup', 
                   'famsup', 'paid', 'activities', 'nursery', 'higher', 
                   'internet', 'romantic']

ordinal_vars = ['Medu', 'Fedu', 'traveltime', 'studytime', 'failures',
               'famrel', 'freetime', 'goout', 'Dalc', 'Walc', 'health']

continuous_vars = ['age', 'absences', 'G1', 'G2', 'G3']
```

### 2. Feature Engineering

#### Binary Variable Encoding
```python
# Convert binary categorical variables to numeric
binary_mapping = {'yes': 1, 'no': 0}
binary_columns = ['schoolsup', 'famsup', 'paid', 'activities', 
                 'nursery', 'higher', 'internet', 'romantic']

for col in binary_columns:
    df[col] = df[col].map(binary_mapping)
```

#### Ordinal Variable Treatment
```python
# Maintain ordinal relationships for ranked variables
# Education levels: 0=none, 1=primary, 2=5th-9th grade, 3=secondary, 4=higher
# Time scales: 1=lowest, 5=highest
# No transformation needed as scales are already numeric and meaningful
```

#### Nominal Variable Encoding
```python
# One-hot encoding for nominal categorical variables
df_encoded = pd.get_dummies(df, columns=categorical_vars, drop_first=True)

# Results in 47 total features after encoding
```

#### Derived Feature Creation
```python
# Alcohol-related features
df['total_alcohol'] = df['Dalc'] + df['Walc']
df['alcohol_ratio'] = df['Walc'] / (df['Dalc'] + 0.1)  # Avoid division by zero
df['high_alcohol'] = ((df['Dalc'] >= 3) | (df['Walc'] >= 3)).astype(int)
df['weekend_drinker'] = (df['Walc'] > df['Dalc']).astype(int)

# Academic features
df['grade_improvement'] = df['G3'] - df['G1']
df['grade_consistency'] = df[['G1', 'G2', 'G3']].std(axis=1)
df['avg_grade'] = df[['G1', 'G2', 'G3']].mean(axis=1)

# Family background features
df['parents_edu_avg'] = (df['Medu'] + df['Fedu']) / 2
df['edu_gap'] = abs(df['Medu'] - df['Fedu'])

# Social features
df['social_score'] = df['freetime'] + df['goout']
df['support_score'] = df['schoolsup'] + df['famsup']

# Interaction features
df['alcohol_x_goout'] = df['total_alcohol'] * df['goout']
df['alcohol_x_freetime'] = df['total_alcohol'] * df['freetime']
df['studytime_x_failures'] = df['studytime'] * df['failures']

# Polynomial features
df['studytime_squared'] = df['studytime'] ** 2
df['total_alcohol_squared'] = df['total_alcohol'] ** 2
```

### 3. Feature Scaling and Normalization

#### Scaling Strategy
```python
# Different scaling for different model types
from sklearn.preprocessing import StandardScaler

# For linear models (Linear, Ridge, Lasso, SVR)
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# For tree-based models (Random Forest, Gradient Boosting)
# No scaling needed - models are scale-invariant
```

#### Feature Selection
```python
# Correlation-based feature selection
correlation_threshold = 0.95
correlation_matrix = df.corr().abs()
upper_triangle = correlation_matrix.where(
    np.triu(np.ones(correlation_matrix.shape), k=1).astype(bool)
)

# Identify highly correlated features
high_corr_pairs = [(column, row) for column in upper_triangle.columns 
                   for row in upper_triangle.index 
                   if upper_triangle.loc[row, column] > correlation_threshold]

# Remove redundant features
features_to_drop = ['G1', 'G2']  # Remove intermediate grades to avoid data leakage
```

## Statistical Analysis Methodology

### 1. Descriptive Statistics

#### Central Tendency and Dispersion
```python
# Calculate comprehensive descriptive statistics
descriptive_stats = df.describe(include='all')

# Custom statistics for alcohol variables
alcohol_stats = {
    'Dalc': {
        'mean': df['Dalc'].mean(),
        'median': df['Dalc'].median(),
        'mode': df['Dalc'].mode()[0],
        'std': df['Dalc'].std(),
        'skewness': df['Dalc'].skew(),
        'kurtosis': df['Dalc'].kurtosis()
    },
    'Walc': {
        'mean': df['Walc'].mean(),
        'median': df['Walc'].median(),
        'mode': df['Walc'].mode()[0],
        'std': df['Walc'].std(),
        'skewness': df['Walc'].skew(),
        'kurtosis': df['Walc'].kurtosis()
    }
}
```

#### Distribution Analysis
```python
from scipy import stats

# Normality tests
def normality_test(data, variable_name):
    statistic, p_value = stats.shapiro(data)
    return {
        'variable': variable_name,
        'statistic': statistic,
        'p_value': p_value,
        'is_normal': p_value > 0.05
    }

# Test key variables for normality
normality_results = [
    normality_test(df['G3'], 'Final Grade'),
    normality_test(df['Dalc'], 'Weekday Alcohol'),
    normality_test(df['Walc'], 'Weekend Alcohol'),
    normality_test(df['total_alcohol'], 'Total Alcohol')
]
```

### 2. Inferential Statistics

#### Hypothesis Testing Framework

**Hypothesis 1: Weekend vs Weekday Consumption**
- H₀: μ(Walc) = μ(Dalc)
- H₁: μ(Walc) ≠ μ(Dalc)
- Test: Paired t-test
- Assumption checks: Normality of differences, no extreme outliers

```python
from scipy.stats import ttest_rel

# Paired t-test for weekend vs weekday alcohol consumption
t_statistic, p_value = ttest_rel(df['Walc'], df['Dalc'])
effect_size = (df['Walc'].mean() - df['Dalc'].mean()) / df[['Walc', 'Dalc']].std().mean()
```

**Hypothesis 2: Alcohol Impact on Grades**
- H₀: μ(G3|high_alcohol) = μ(G3|low_alcohol)
- H₁: μ(G3|high_alcohol) ≠ μ(G3|low_alcohol)
- Test: Independent t-test
- Assumption checks: Normality, equal variances

```python
from scipy.stats import ttest_ind, levene

# Test for equal variances
levene_stat, levene_p = levene(high_alcohol_grades, low_alcohol_grades)

# Independent t-test
t_stat, p_val = ttest_ind(high_alcohol_grades, low_alcohol_grades, 
                         equal_var=(levene_p > 0.05))
```

**Hypothesis 3: Gender Differences in Alcohol Consumption**
- H₀: μ(alcohol|male) = μ(alcohol|female)
- H₁: μ(alcohol|male) ≠ μ(alcohol|female)
- Test: Independent t-test with Cohen's d effect size

```python
# Calculate Cohen's d for effect size
def cohens_d(group1, group2):
    pooled_std = np.sqrt(((len(group1) - 1) * group1.var() + 
                         (len(group2) - 1) * group2.var()) / 
                        (len(group1) + len(group2) - 2))
    return (group1.mean() - group2.mean()) / pooled_std
```

#### Correlation Analysis
```python
# Comprehensive correlation analysis
def correlation_analysis(df, target_var):
    correlations = df.corr()[target_var].sort_values(key=abs, ascending=False)
    
    # Calculate confidence intervals for correlations
    n = len(df)
    conf_intervals = {}
    for var, r in correlations.items():
        if var != target_var:
            # Fisher's z-transformation for CI
            z = 0.5 * np.log((1 + r) / (1 - r))
            se = 1 / np.sqrt(n - 3)
            z_ci = [z - 1.96 * se, z + 1.96 * se]
            r_ci = [(np.exp(2 * z) - 1) / (np.exp(2 * z) + 1) for z in z_ci]
            conf_intervals[var] = r_ci
    
    return correlations, conf_intervals

# Perform correlation analysis
correlations, ci = correlation_analysis(df, 'G3')
```

### 3. Advanced Statistical Methods

#### Multiple Regression Analysis
```python
import statsmodels.api as sm

# Prepare data for regression
y = df['G3']
X = df[feature_columns]
X = sm.add_constant(X)  # Add intercept

# Fit multiple regression model
model = sm.OLS(y, X).fit()

# Comprehensive model diagnostics
diagnostics = {
    'r_squared': model.rsquared,
    'adj_r_squared': model.rsquared_adj,
    'f_statistic': model.fvalue,
    'f_pvalue': model.f_pvalue,
    'aic': model.aic,
    'bic': model.bic,
    'residual_analysis': {
        'normality_test': stats.jarque_bera(model.resid),
        'heteroscedasticity_test': sm.stats.diagnostic.het_breuschpagan(model.resid, model.fittedvalues),
        'autocorrelation_test': sm.stats.diagnostic.acorr_ljungbox(model.resid, lags=1)
    }
}
```

#### ANOVA Analysis
```python
from scipy.stats import f_oneway

# One-way ANOVA for alcohol consumption across age groups
age_groups = [df[df['age'] == age]['total_alcohol'] for age in df['age'].unique()]
f_stat, p_val = f_oneway(*age_groups)

# Post-hoc analysis if significant
if p_val < 0.05:
    from scipy.stats import tukey_hsd
    tukey_result = tukey_hsd(*age_groups)
```

## Machine Learning Methodology

### 1. Model Selection Strategy

#### Cross-Validation Framework
```python
from sklearn.model_selection import KFold, cross_val_score

# 5-fold cross-validation with stratification by grade ranges
def create_grade_bins(grades):
    return pd.cut(grades, bins=[0, 8, 12, 16, 20], labels=['Low', 'Medium', 'High', 'Excellent'])

cv = KFold(n_splits=5, shuffle=True, random_state=42)
```

#### Model Comparison Protocol
```python
models = {
    'Linear Regression': LinearRegression(),
    'Ridge Regression': Ridge(),
    'Lasso Regression': Lasso(),
    'Random Forest': RandomForestRegressor(random_state=42),
    'Gradient Boosting': GradientBoostingRegressor(random_state=42),
    'SVR': SVR()
}

# Evaluation metrics
scoring_metrics = ['r2', 'neg_mean_absolute_error', 'neg_mean_squared_error']
```

### 2. Hyperparameter Optimization

#### Grid Search Strategy
```python
from sklearn.model_selection import GridSearchCV

# Define parameter grids for each model
param_grids = {
    'Ridge': {'alpha': [0.1, 1.0, 10.0, 100.0]},
    'Lasso': {'alpha': [0.01, 0.1, 1.0, 10.0]},
    'Random Forest': {
        'n_estimators': [50, 100, 200],
        'max_depth': [None, 10, 20],
        'min_samples_split': [2, 5, 10]
    },
    'Gradient Boosting': {
        'n_estimators': [50, 100, 200],
        'learning_rate': [0.01, 0.1, 0.2],
        'max_depth': [3, 5, 7]
    },
    'SVR': {
        'C': [0.1, 1.0, 10.0],
        'gamma': ['scale', 'auto'],
        'kernel': ['rbf', 'linear']
    }
}

# Nested cross-validation for unbiased performance estimation
def nested_cv_evaluation(model, param_grid, X, y):
    inner_cv = KFold(n_splits=3, shuffle=True, random_state=42)
    outer_cv = KFold(n_splits=5, shuffle=True, random_state=42)
    
    # Inner loop: hyperparameter optimization
    grid_search = GridSearchCV(model, param_grid, cv=inner_cv, scoring='r2')
    
    # Outer loop: performance estimation
    scores = cross_val_score(grid_search, X, y, cv=outer_cv, scoring='r2')
    
    return scores.mean(), scores.std()
```

### 3. Model Validation and Evaluation

#### Performance Metrics
```python
def calculate_comprehensive_metrics(y_true, y_pred):
    from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error
    
    return {
        'r2': r2_score(y_true, y_pred),
        'mae': mean_absolute_error(y_true, y_pred),
        'mse': mean_squared_error(y_true, y_pred),
        'rmse': np.sqrt(mean_squared_error(y_true, y_pred)),
        'mape': np.mean(np.abs((y_true - y_pred) / y_true)) * 100,
        'bias': np.mean(y_pred - y_true),
        'variance': np.var(y_pred - y_true)
    }
```

#### Residual Analysis
```python
def residual_analysis(y_true, y_pred):
    residuals = y_true - y_pred
    
    # Normality test
    shapiro_stat, shapiro_p = stats.shapiro(residuals)
    
    # Homoscedasticity test
    # Breusch-Pagan test
    bp_stat, bp_p = sm.stats.diagnostic.het_breuschpagan(residuals, y_pred.reshape(-1, 1))
    
    # Independence test (Durbin-Watson)
    dw_stat = sm.stats.diagnostic.durbin_watson(residuals)
    
    return {
        'normality': {'statistic': shapiro_stat, 'p_value': shapiro_p},
        'homoscedasticity': {'statistic': bp_stat, 'p_value': bp_p},
        'independence': {'durbin_watson': dw_stat}
    }
```

#### Feature Importance Analysis
```python
def feature_importance_analysis(model, feature_names):
    if hasattr(model, 'feature_importances_'):
        # Tree-based models
        importances = model.feature_importances_
        indices = np.argsort(importances)[::-1]
        
        return pd.DataFrame({
            'feature': [feature_names[i] for i in indices],
            'importance': importances[indices],
            'rank': range(1, len(indices) + 1)
        })
    
    elif hasattr(model, 'coef_'):
        # Linear models
        coefficients = np.abs(model.coef_)
        indices = np.argsort(coefficients)[::-1]
        
        return pd.DataFrame({
            'feature': [feature_names[i] for i in indices],
            'coefficient_magnitude': coefficients[indices],
            'rank': range(1, len(indices) + 1)
        })
```

## Quality Assurance and Validation

### 1. Data Integrity Checks
- **Completeness**: 100% data availability verification
- **Consistency**: Cross-field validation (e.g., age vs grade level)
- **Accuracy**: Range and logical constraint checking
- **Uniqueness**: Student record deduplication

### 2. Statistical Assumption Testing
- **Normality**: Shapiro-Wilk tests for parametric procedures
- **Homoscedasticity**: Levene's test for equal variances
- **Independence**: Durbin-Watson test for serial correlation
- **Linearity**: Residual plots and partial regression plots

### 3. Model Validation Framework
- **Internal Validation**: 5-fold cross-validation
- **Temporal Validation**: Time-based splits when applicable
- **Sensitivity Analysis**: Robustness to outliers and missing data
- **Calibration Assessment**: Reliability diagrams for predictions

### 4. Reproducibility Measures
- **Random Seed Control**: Fixed seeds for all stochastic processes
- **Version Control**: Git tracking of all code and data changes
- **Environment Documentation**: Complete package version listing
- **Code Documentation**: Comprehensive inline and function documentation

This methodology ensures robust, reproducible, and scientifically sound analysis of the relationship between student alcohol consumption and academic performance.