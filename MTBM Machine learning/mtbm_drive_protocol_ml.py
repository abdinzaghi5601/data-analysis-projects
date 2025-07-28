#!/usr/bin/env python3
"""
MTBM Drive Protocol Machine Learning Framework
Comprehensive ML solution for micro-tunneling drive performance optimization
Extends beyond steering to include excavation efficiency, ground conditions, and risk prediction
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier, GradientBoostingRegressor
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import mean_squared_error, r2_score, mean_absolute_error, classification_report
from sklearn.neural_network import MLPRegressor
import matplotlib.pyplot as plt
import seaborn as sns
from typing import Tuple, Dict, Any, List
import warnings
warnings.filterwarnings('ignore')

class MTBMDriveProtocolML:
    """
    Comprehensive Machine Learning framework for MTBM drive protocol optimization
    
    Features:
    1. Steering Accuracy Prediction
    2. Excavation Efficiency Optimization  
    3. Ground Condition Classification
    4. Risk Assessment and Early Warning
    5. Drive Performance Analytics
    """
    
    def __init__(self):
        # Model components
        self.steering_model = None
        self.efficiency_model = None
        self.ground_classifier = None
        self.risk_model = None
        
        # Data processing
        self.scaler = StandardScaler()
        self.label_encoder = LabelEncoder()
        
        # Feature tracking
        self.feature_columns = []
        self.steering_targets = []
        self.efficiency_targets = []
        
        # Performance metrics storage
        self.model_performance = {}
    
    def load_protocol_data(self, csv_path: str) -> pd.DataFrame:
        """Load and structure MTBM drive protocol data"""
        
        # Extended column mapping for comprehensive protocol
        columns = [
            'date', 'time', 'tunnel_length', 'hor_dev_machine', 'vert_dev_machine',
            'hor_dev_drill_head', 'vert_dev_drill_head', 'yaw', 'pitch', 'roll',
            'temperature', 'survey_mode', 'sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03',
            'sc_cyl_04', 'advance_speed', 'interjack_force', 'interjack_active',
            'working_pressure', 'revolution_rpm', 'earth_pressure', 'total_force'
        ]
        
        df = pd.read_csv(csv_path, names=columns, skiprows=1)
        
        # Data cleaning and preprocessing
        df['datetime'] = pd.to_datetime(df['date'] + ' ' + df['time'], errors='coerce')
        df = df.dropna(subset=['datetime']).sort_values('datetime').reset_index(drop=True)
        
        # Fill missing values with forward fill method
        numeric_columns = df.select_dtypes(include=[np.number]).columns
        df[numeric_columns] = df[numeric_columns].fillna(method='ffill')
        
        return df
    
    def engineer_comprehensive_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Create comprehensive feature set for all ML models"""
        
        # 1. STEERING & ALIGNMENT FEATURES
        df['total_deviation_machine'] = np.sqrt(df['hor_dev_machine']**2 + df['vert_dev_machine']**2)
        df['total_deviation_drill_head'] = np.sqrt(df['hor_dev_drill_head']**2 + df['vert_dev_drill_head']**2)
        df['deviation_difference'] = df['total_deviation_drill_head'] - df['total_deviation_machine']
        df['alignment_quality'] = 1 / (1 + df['total_deviation_machine'])  # Higher = better alignment
        
        # 2. STEERING SYSTEM FEATURES
        cylinder_cols = ['sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04']
        df['steering_cylinder_range'] = df[cylinder_cols].max(axis=1) - df[cylinder_cols].min(axis=1)
        df['avg_cylinder_stroke'] = df[cylinder_cols].mean(axis=1)
        df['cylinder_variance'] = df[cylinder_cols].var(axis=1)
        df['steering_asymmetry'] = abs(df[cylinder_cols].mean(axis=1))
        
        # 3. EXCAVATION EFFICIENCY FEATURES
        df['specific_energy'] = df['total_force'] / (df['advance_speed'] + 0.1)  # Energy per unit advance
        df['cutting_efficiency'] = df['advance_speed'] / (df['revolution_rpm'] + 0.1)
        df['pressure_efficiency'] = df['advance_speed'] / (df['working_pressure'] + 0.1)
        df['power_utilization'] = (df['total_force'] * df['advance_speed']) / 1000  # kW equivalent
        
        # 4. GROUND CONDITION INDICATORS
        df['ground_resistance'] = df['earth_pressure'] / (df['advance_speed'] + 0.1)
        df['penetration_rate'] = df['advance_speed'] / (df['total_force'] + 0.1)
        df['pressure_ratio'] = df['earth_pressure'] / (df['working_pressure'] + 0.1)
        df['excavation_difficulty'] = df['total_force'] / (df['revolution_rpm'] + 0.1)
        
        # 5. MACHINE PERFORMANCE FEATURES
        df['operational_efficiency'] = df['advance_speed'] / df['specific_energy']
        df['system_stability'] = 1 / (1 + df['cylinder_variance'])  # Higher = more stable
        df['drive_consistency'] = df['advance_speed'].rolling(window=5, min_periods=1).std()
        df['force_consistency'] = df['total_force'].rolling(window=5, min_periods=1).std()
        
        # 6. TEMPORAL AND TREND FEATURES
        window = 5
        df['deviation_trend'] = df['total_deviation_machine'].rolling(window=window, min_periods=1).apply(
            lambda x: np.polyfit(range(len(x)), x, 1)[0] if len(x) > 1 else 0
        )
        df['efficiency_trend'] = df['cutting_efficiency'].rolling(window=window, min_periods=1).apply(
            lambda x: np.polyfit(range(len(x)), x, 1)[0] if len(x) > 1 else 0
        )
        df['pressure_trend'] = df['earth_pressure'].rolling(window=window, min_periods=1).apply(
            lambda x: np.polyfit(range(len(x)), x, 1)[0] if len(x) > 1 else 0
        )
        
        # 7. MOVING AVERAGES FOR STABILITY
        for col in ['advance_speed', 'total_force', 'earth_pressure', 'working_pressure']:
            df[f'{col}_ma3'] = df[col].rolling(window=3, min_periods=1).mean()
            df[f'{col}_ma5'] = df[col].rolling(window=5, min_periods=1).mean()
        
        # 8. TIME-BASED FEATURES
        df['time_diff'] = df['datetime'].diff().dt.total_seconds() / 3600  # Hours
        df['progress_rate'] = df['tunnel_length'].diff() / df['time_diff']  # m/hour
        df['hour_of_day'] = df['datetime'].dt.hour
        df['day_of_week'] = df['datetime'].dt.dayofweek
        df['shift'] = df['hour_of_day'].apply(lambda x: 'night' if x < 6 or x > 18 else 'day')
        
        # 9. LAG FEATURES (Previous actions and conditions)
        lag_cols = ['advance_speed', 'total_force', 'earth_pressure'] + cylinder_cols
        for col in lag_cols:
            df[f'{col}_prev'] = df[col].shift(1)
            df[f'{col}_change'] = df[col] - df[f'{col}_prev']
            df[f'{col}_change_rate'] = df[f'{col}_change'] / (df['time_diff'] + 0.1)
        
        # 10. RISK INDICATORS
        df['deviation_risk'] = (df['total_deviation_machine'] > df['total_deviation_machine'].quantile(0.8)).astype(int)
        df['efficiency_risk'] = (df['cutting_efficiency'] < df['cutting_efficiency'].quantile(0.2)).astype(int)
        df['pressure_risk'] = (df['earth_pressure'] > df['earth_pressure'].quantile(0.9)).astype(int)
        df['combined_risk_score'] = df['deviation_risk'] + df['efficiency_risk'] + df['pressure_risk']
        
        return df
    
    def create_ml_targets(self, df: pd.DataFrame) -> pd.DataFrame:
        """Create target variables for different ML models"""
        
        # STEERING TARGETS
        df['next_hor_deviation'] = df['hor_dev_machine'].shift(-1)
        df['next_vert_deviation'] = df['vert_dev_machine'].shift(-1)
        df['next_total_deviation'] = df['total_deviation_machine'].shift(-1)
        df['required_hor_correction'] = df['next_hor_deviation'] - df['hor_dev_machine']
        df['required_vert_correction'] = df['next_vert_deviation'] - df['vert_dev_machine']
        df['deviation_improvement'] = df['total_deviation_machine'] - df['next_total_deviation']
        
        # EFFICIENCY TARGETS
        df['next_advance_speed'] = df['advance_speed'].shift(-1)
        df['next_cutting_efficiency'] = df['cutting_efficiency'].shift(-1)
        df['efficiency_improvement'] = df['next_cutting_efficiency'] - df['cutting_efficiency']
        df['optimal_advance_speed'] = df['advance_speed'] * (1 + df['efficiency_improvement'].clip(-0.5, 0.5))
        
        # GROUND CONDITION CLASSIFICATION
        # Classify ground conditions based on resistance and pressure patterns
        ground_conditions = []
        for _, row in df.iterrows():
            if row['ground_resistance'] > df['ground_resistance'].quantile(0.8):
                condition = 'hard'
            elif row['ground_resistance'] < df['ground_resistance'].quantile(0.3):
                condition = 'soft'
            else:
                condition = 'medium'
            ground_conditions.append(condition)
        df['ground_condition'] = ground_conditions
        
        # RISK CLASSIFICATION
        df['risk_level'] = df['combined_risk_score'].apply(
            lambda x: 'high' if x >= 2 else ('medium' if x == 1 else 'low')
        )
        
        return df
    
    def prepare_feature_sets(self, df: pd.DataFrame) -> Dict[str, Tuple[np.ndarray, np.ndarray]]:
        """Prepare different feature sets for specialized models"""
        
        # Common features used across all models
        common_features = [
            'tunnel_length', 'hor_dev_machine', 'vert_dev_machine', 'total_deviation_machine',
            'yaw', 'pitch', 'roll', 'advance_speed', 'total_force', 'working_pressure', 
            'earth_pressure', 'revolution_rpm', 'temperature'
        ]
        
        # STEERING MODEL FEATURES
        steering_features = common_features + [
            'hor_dev_drill_head', 'vert_dev_drill_head', 'deviation_difference',
            'sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04',
            'steering_cylinder_range', 'avg_cylinder_stroke', 'cylinder_variance',
            'deviation_trend', 'alignment_quality', 'steering_asymmetry'
        ]
        
        steering_targets = ['required_hor_correction', 'required_vert_correction', 'deviation_improvement']
        
        # EFFICIENCY MODEL FEATURES  
        efficiency_features = common_features + [
            'specific_energy', 'cutting_efficiency', 'pressure_efficiency', 'power_utilization',
            'operational_efficiency', 'drive_consistency', 'efficiency_trend',
            'advance_speed_ma3', 'total_force_ma3', 'advance_speed_change'
        ]
        
        efficiency_targets = ['next_advance_speed', 'efficiency_improvement', 'optimal_advance_speed']
        
        # GROUND CLASSIFICATION FEATURES
        ground_features = common_features + [
            'ground_resistance', 'penetration_rate', 'pressure_ratio', 'excavation_difficulty',
            'pressure_trend', 'earth_pressure_ma5', 'total_force_change'
        ]
        
        # RISK PREDICTION FEATURES
        risk_features = steering_features + efficiency_features + [
            'combined_risk_score', 'system_stability', 'pressure_risk'
        ]
        
        # Remove duplicates and prepare datasets
        def prepare_dataset(features, targets=None, is_classification=False):
            # Remove duplicates while preserving order
            features = list(dict.fromkeys(features))
            
            if targets is None:  # Classification case
                available_features = [f for f in features if f in df.columns]
                clean_df = df[available_features].dropna()
                X = clean_df.values
                
                if is_classification:
                    y = df.loc[clean_df.index, 'ground_condition' if 'ground_resistance' in features else 'risk_level'].values
                    return X, y
                else:
                    return X, None
            else:  # Regression case
                all_cols = features + targets
                available_cols = [f for f in all_cols if f in df.columns]
                clean_df = df[available_cols].dropna()
                
                available_features = [f for f in features if f in clean_df.columns]
                available_targets = [f for f in targets if f in clean_df.columns]
                
                X = clean_df[available_features].values
                y = clean_df[available_targets].values
                
                return X, y
        
        # Prepare all datasets
        datasets = {}
        
        try:
            X_steering, y_steering = prepare_dataset(steering_features, steering_targets)
            datasets['steering'] = (X_steering, y_steering)
            self.feature_columns = [f for f in steering_features if f in df.columns]
            self.steering_targets = [f for f in steering_targets if f in df.columns]
        except Exception as e:
            print(f"Warning: Could not prepare steering dataset: {e}")
        
        try:
            X_efficiency, y_efficiency = prepare_dataset(efficiency_features, efficiency_targets)
            datasets['efficiency'] = (X_efficiency, y_efficiency)
            self.efficiency_targets = [f for f in efficiency_targets if f in df.columns]
        except Exception as e:
            print(f"Warning: Could not prepare efficiency dataset: {e}")
        
        try:
            X_ground, y_ground = prepare_dataset(ground_features, is_classification=True)
            datasets['ground'] = (X_ground, y_ground)
        except Exception as e:
            print(f"Warning: Could not prepare ground classification dataset: {e}")
        
        try:
            X_risk, y_risk = prepare_dataset(risk_features, is_classification=True)
            datasets['risk'] = (X_risk, y_risk)
        except Exception as e:
            print(f"Warning: Could not prepare risk dataset: {e}")
        
        return datasets
    
    def train_steering_model(self, X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
        """Train steering accuracy prediction model"""
        
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train Random Forest with hyperparameter tuning
        param_grid = {
            'n_estimators': [100, 200],
            'max_depth': [10, 15, 20],
            'min_samples_split': [2, 5]
        }
        
        rf = RandomForestRegressor(random_state=42, n_jobs=-1)
        grid_search = GridSearchCV(rf, param_grid, cv=3, scoring='r2', n_jobs=-1)
        grid_search.fit(X_train_scaled, y_train)
        
        self.steering_model = grid_search.best_estimator_
        
        # Evaluate model
        y_pred_train = self.steering_model.predict(X_train_scaled)
        y_pred_test = self.steering_model.predict(X_test_scaled)
        
        results = {}
        for i, target in enumerate(self.steering_targets):
            results[target] = {
                'train_r2': r2_score(y_train[:, i], y_pred_train[:, i]),
                'test_r2': r2_score(y_test[:, i], y_pred_test[:, i]),
                'train_mae': mean_absolute_error(y_train[:, i], y_pred_train[:, i]),
                'test_mae': mean_absolute_error(y_test[:, i], y_pred_test[:, i])
            }
        
        self.model_performance['steering'] = results
        print(f"Steering model trained with best params: {grid_search.best_params_}")
        
        return results
    
    def train_efficiency_model(self, X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
        """Train excavation efficiency optimization model"""
        
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Use same scaler (already fitted on steering data)
        X_train_scaled = self.scaler.transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train Gradient Boosting for efficiency prediction
        self.efficiency_model = GradientBoostingRegressor(
            n_estimators=150,
            max_depth=8,
            learning_rate=0.1,
            random_state=42
        )
        
        self.efficiency_model.fit(X_train_scaled, y_train)
        
        # Evaluate
        y_pred_train = self.efficiency_model.predict(X_train_scaled)
        y_pred_test = self.efficiency_model.predict(X_test_scaled)
        
        results = {}
        for i, target in enumerate(self.efficiency_targets):
            results[target] = {
                'train_r2': r2_score(y_train[:, i], y_pred_train[:, i]),
                'test_r2': r2_score(y_test[:, i], y_pred_test[:, i]),
                'train_mae': mean_absolute_error(y_train[:, i], y_pred_train[:, i]),
                'test_mae': mean_absolute_error(y_test[:, i], y_pred_test[:, i])
            }
        
        self.model_performance['efficiency'] = results
        print("Efficiency model trained successfully")
        
        return results
    
    def train_ground_classifier(self, X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
        """Train ground condition classification model"""
        
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Scale features
        X_train_scaled = self.scaler.transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train Random Forest Classifier
        self.ground_classifier = RandomForestClassifier(
            n_estimators=100,
            max_depth=12,
            random_state=42,
            n_jobs=-1
        )
        
        self.ground_classifier.fit(X_train_scaled, y_train)
        
        # Evaluate
        train_score = self.ground_classifier.score(X_train_scaled, y_train)
        test_score = self.ground_classifier.score(X_test_scaled, y_test)
        
        y_pred = self.ground_classifier.predict(X_test_scaled)
        
        results = {
            'train_accuracy': train_score,
            'test_accuracy': test_score,
            'classification_report': classification_report(y_test, y_pred)
        }
        
        self.model_performance['ground'] = results
        print(f"Ground classification model - Test accuracy: {test_score:.3f}")
        
        return results
    
    def train_risk_model(self, X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
        """Train risk assessment model"""
        
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Scale features
        X_train_scaled = self.scaler.transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train risk classifier
        self.risk_model = RandomForestClassifier(
            n_estimators=150,
            max_depth=10,
            random_state=42,
            n_jobs=-1
        )
        
        self.risk_model.fit(X_train_scaled, y_train)
        
        # Evaluate
        train_score = self.risk_model.score(X_train_scaled, y_train)
        test_score = self.risk_model.score(X_test_scaled, y_test)
        
        results = {
            'train_accuracy': train_score,
            'test_accuracy': test_score
        }
        
        self.model_performance['risk'] = results
        print(f"Risk assessment model - Test accuracy: {test_score:.3f}")
        
        return results
    
    def comprehensive_predict(self, current_data: Dict) -> Dict:
        """Make predictions using all trained models"""
        
        predictions = {}
        
        # Prepare feature vector
        feature_vector = np.array([current_data.get(col, 0) for col in self.feature_columns]).reshape(1, -1)
        feature_vector_scaled = self.scaler.transform(feature_vector)
        
        # Steering predictions
        if self.steering_model is not None:
            steering_pred = self.steering_model.predict(feature_vector_scaled)[0]
            predictions['steering'] = {
                'required_horizontal_correction': steering_pred[0],
                'required_vertical_correction': steering_pred[1],
                'expected_deviation_improvement': steering_pred[2]
            }
        
        # Efficiency predictions
        if self.efficiency_model is not None:
            efficiency_pred = self.efficiency_model.predict(feature_vector_scaled)[0]
            predictions['efficiency'] = {
                'optimal_advance_speed': efficiency_pred[0],
                'efficiency_improvement': efficiency_pred[1],
                'recommended_speed_adjustment': efficiency_pred[2]
            }
        
        # Ground condition prediction
        if self.ground_classifier is not None:
            ground_pred = self.ground_classifier.predict(feature_vector_scaled)[0]
            ground_prob = self.ground_classifier.predict_proba(feature_vector_scaled)[0]
            predictions['ground'] = {
                'condition': ground_pred,
                'confidence': max(ground_prob)
            }
        
        # Risk assessment
        if self.risk_model is not None:
            risk_pred = self.risk_model.predict(feature_vector_scaled)[0]
            risk_prob = self.risk_model.predict_proba(feature_vector_scaled)[0]
            predictions['risk'] = {
                'level': risk_pred,
                'confidence': max(risk_prob)
            }
        
        return predictions
    
    def generate_drive_recommendations(self, predictions: Dict, current_data: Dict) -> Dict:
        """Generate actionable recommendations based on predictions"""
        
        recommendations = {
            'steering': [],
            'efficiency': [],
            'operations': [],
            'risk_mitigation': []
        }
        
        # Steering recommendations
        if 'steering' in predictions:
            steering = predictions['steering']
            if abs(steering['required_horizontal_correction']) > 5:
                direction = "right" if steering['required_horizontal_correction'] > 0 else "left"
                recommendations['steering'].append(f"Apply {direction} steering correction of {abs(steering['required_horizontal_correction']):.1f}mm")
            
            if abs(steering['required_vertical_correction']) > 5:
                direction = "up" if steering['required_vertical_correction'] > 0 else "down"
                recommendations['steering'].append(f"Apply {direction} steering correction of {abs(steering['required_vertical_correction']):.1f}mm")
        
        # Efficiency recommendations
        if 'efficiency' in predictions:
            efficiency = predictions['efficiency']
            current_speed = current_data.get('advance_speed', 0)
            optimal_speed = efficiency['optimal_advance_speed']
            
            if optimal_speed > current_speed * 1.1:
                recommendations['efficiency'].append(f"Increase advance speed to {optimal_speed:.1f} mm/min for better efficiency")
            elif optimal_speed < current_speed * 0.9:
                recommendations['efficiency'].append(f"Reduce advance speed to {optimal_speed:.1f} mm/min to optimize performance")
        
        # Operational recommendations based on ground conditions
        if 'ground' in predictions:
            condition = predictions['ground']['condition']
            if condition == 'hard':
                recommendations['operations'].append("Hard ground detected - consider reducing advance speed and increasing cutting power")
            elif condition == 'soft':
                recommendations['operations'].append("Soft ground detected - optimize speed for maximum progress rate")
        
        # Risk mitigation
        if 'risk' in predictions:
            risk_level = predictions['risk']['level']
            if risk_level == 'high':
                recommendations['risk_mitigation'].append("High risk conditions - implement enhanced monitoring and reduce advance speed")
            elif risk_level == 'medium':
                recommendations['risk_mitigation'].append("Medium risk conditions - maintain vigilant monitoring")
        
        return recommendations
    
    def plot_comprehensive_analysis(self, df: pd.DataFrame):
        """Create comprehensive analysis plots"""
        
        fig, axes = plt.subplots(3, 2, figsize=(20, 15))
        
        # 1. Deviation analysis
        axes[0,0].plot(df['tunnel_length'], df['total_deviation_machine'], label='Machine', alpha=0.7)
        axes[0,0].plot(df['tunnel_length'], df['total_deviation_drill_head'], label='Drill Head', alpha=0.7)
        axes[0,0].set_title('Alignment Deviation Analysis')
        axes[0,0].set_xlabel('Tunnel Length (m)')
        axes[0,0].set_ylabel('Total Deviation (mm)')
        axes[0,0].legend()
        axes[0,0].grid(True, alpha=0.3)
        
        # 2. Efficiency trends
        axes[0,1].plot(df['tunnel_length'], df['cutting_efficiency'], label='Cutting Efficiency', alpha=0.7)
        axes[0,1].plot(df['tunnel_length'], df['operational_efficiency'], label='Operational Efficiency', alpha=0.7)
        axes[0,1].set_title('Excavation Efficiency Trends')
        axes[0,1].set_xlabel('Tunnel Length (m)')
        axes[0,1].set_ylabel('Efficiency Index')
        axes[0,1].legend()
        axes[0,1].grid(True, alpha=0.3)
        
        # 3. Ground conditions
        ground_counts = df['ground_condition'].value_counts()
        axes[1,0].pie(ground_counts.values, labels=ground_counts.index, autopct='%1.1f%%')
        axes[1,0].set_title('Ground Condition Distribution')
        
        # 4. Risk analysis
        risk_counts = df['risk_level'].value_counts()
        axes[1,1].bar(risk_counts.index, risk_counts.values, alpha=0.7)
        axes[1,1].set_title('Risk Level Distribution')
        axes[1,1].set_ylabel('Count')
        
        # 5. Feature importance (if models are trained)
        if self.steering_model is not None:
            importance = self.steering_model.feature_importances_[:10]
            features = self.feature_columns[:10]
            axes[2,0].barh(features, importance)
            axes[2,0].set_title('Top 10 Feature Importance (Steering)')
            axes[2,0].set_xlabel('Importance')
        
        # 6. Performance correlation
        correlation_features = ['advance_speed', 'total_force', 'earth_pressure', 'cutting_efficiency']
        available_features = [f for f in correlation_features if f in df.columns]
        if len(available_features) >= 2:
            corr_matrix = df[available_features].corr()
            sns.heatmap(corr_matrix, annot=True, ax=axes[2,1], cmap='coolwarm')
            axes[2,1].set_title('Performance Correlation Matrix')
        
        plt.tight_layout()
        plt.show()
    
    def export_model_summary(self, output_path: str = 'mtbm_model_summary.txt'):
        """Export comprehensive model performance summary"""
        
        with open(output_path, 'w') as f:
            f.write("MTBM Drive Protocol ML Framework - Model Performance Summary\n")
            f.write("=" * 70 + "\n\n")
            
            for model_name, performance in self.model_performance.items():
                f.write(f"{model_name.upper()} MODEL PERFORMANCE:\n")
                f.write("-" * 40 + "\n")
                
                if model_name in ['steering', 'efficiency']:
                    for target, metrics in performance.items():
                        f.write(f"\n{target}:\n")
                        for metric, value in metrics.items():
                            f.write(f"  {metric}: {value:.4f}\n")
                else:
                    for metric, value in performance.items():
                        if metric != 'classification_report':
                            f.write(f"  {metric}: {value:.4f}\n")
                        else:
                            f.write(f"\n{value}\n")
                
                f.write("\n" + "=" * 70 + "\n\n")
        
        print(f"Model summary exported to {output_path}")


def main():
    """Demonstrate comprehensive MTBM Drive Protocol ML framework"""
    
    print("Initializing MTBM Drive Protocol ML Framework...")
    ml_framework = MTBMDriveProtocolML()
    
    # Load and process data
    print("Loading protocol data...")
    df = ml_framework.load_protocol_data('measure_protocol_original_.xls.csv')
    
    print("Engineering comprehensive features...")
    df = ml_framework.engineer_comprehensive_features(df)
    df = ml_framework.create_ml_targets(df)
    
    print(f"Dataset: {df.shape[0]} readings, {df.shape[1]} features")
    print(f"Drive length: {df['tunnel_length'].max():.1f}m")
    
    # Prepare datasets for all models
    print("Preparing feature sets for specialized models...")
    datasets = ml_framework.prepare_feature_sets(df)
    
    # Train all available models
    print("\nTraining ML models...")
    
    if 'steering' in datasets:
        print("Training steering accuracy model...")
        X_steering, y_steering = datasets['steering']
        ml_framework.train_steering_model(X_steering, y_steering)
    
    if 'efficiency' in datasets:
        print("Training efficiency optimization model...")
        X_efficiency, y_efficiency = datasets['efficiency']
        ml_framework.train_efficiency_model(X_efficiency, y_efficiency)
    
    if 'ground' in datasets:
        print("Training ground condition classifier...")
        X_ground, y_ground = datasets['ground']
        ml_framework.train_ground_classifier(X_ground, y_ground)
    
    if 'risk' in datasets:
        print("Training risk assessment model...")
        X_risk, y_risk = datasets['risk']
        ml_framework.train_risk_model(X_risk, y_risk)
    
    # Display performance summary
    print("\n" + "="*50)
    print("MODEL PERFORMANCE SUMMARY")
    print("="*50)
    
    for model_name, performance in ml_framework.model_performance.items():
        print(f"\n{model_name.upper()} MODEL:")
        if model_name in ['steering', 'efficiency']:
            for target, metrics in performance.items():
                print(f"  {target}: R² = {metrics['test_r2']:.3f}, MAE = {metrics['test_mae']:.2f}")
        else:
            print(f"  Test Accuracy: {performance['test_accuracy']:.3f}")
    
    # Example prediction
    print("\n" + "="*50)
    print("EXAMPLE COMPREHENSIVE PREDICTION")
    print("="*50)
    
    # Use recent conditions for prediction
    current_conditions = df.iloc[-5][ml_framework.feature_columns].to_dict()
    predictions = ml_framework.comprehensive_predict(current_conditions)
    recommendations = ml_framework.generate_drive_recommendations(predictions, current_conditions)
    
    print("\nPredictions:")
    for model_type, pred in predictions.items():
        print(f"\n{model_type.upper()}:")
        for key, value in pred.items():
            print(f"  {key}: {value}")
    
    print("\nRecommendations:")
    for category, recs in recommendations.items():
        if recs:
            print(f"\n{category.upper()}:")
            for rec in recs:
                print(f"  • {rec}")
    
    # Generate visualizations
    print("\nGenerating comprehensive analysis plots...")
    ml_framework.plot_comprehensive_analysis(df)
    
    # Export model summary
    ml_framework.export_model_summary()
    
    return ml_framework, df


if __name__ == "__main__":
    framework, data = main()