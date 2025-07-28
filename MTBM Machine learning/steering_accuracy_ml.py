#!/usr/bin/env python3
"""
AVN1200 Microtunnelling Steering Accuracy ML Model
Predicts steering corrections and deviation trends for improved tunnel alignment
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error, r2_score, mean_absolute_error
import matplotlib.pyplot as plt
import seaborn as sns
from typing import Tuple, Dict, Any
import warnings
warnings.filterwarnings('ignore')

class SteeringAccuracyPredictor:
    """
    Machine Learning model for predicting steering corrections in microtunnelling
    """
    
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.feature_columns = []
        self.target_columns = []
        
    def load_data(self, csv_path: str) -> pd.DataFrame:
        """Load and preprocess AVN1200 drive data"""
        # Column mapping based on your protocol
        columns = [
            'date', 'time', 'tunnel_length', 'hor_dev_machine', 'vert_dev_machine',
            'hor_dev_drill_head', 'vert_dev_drill_head', 'yaw', 'pitch', 'roll',
            'temperature', 'survey_mode', 'sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03',
            'sc_cyl_04', 'advance_speed', 'interjack_force', 'interjack_active',
            'working_pressure', 'revolution_rpm', 'earth_pressure', 'total_force'
        ]
        
        df = pd.read_csv(csv_path, names=columns, skiprows=1)
        
        # Convert date/time
        df['datetime'] = pd.to_datetime(df['date'] + ' ' + df['time'])
        df = df.sort_values('datetime').reset_index(drop=True)
        
        return df
    
    def engineer_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Create engineered features for steering prediction"""
        
        # 1. DEVIATION METRICS
        df['total_deviation_machine'] = np.sqrt(df['hor_dev_machine']**2 + df['vert_dev_machine']**2)
        df['total_deviation_drill_head'] = np.sqrt(df['hor_dev_drill_head']**2 + df['vert_dev_drill_head']**2)
        df['deviation_difference'] = df['total_deviation_drill_head'] - df['total_deviation_machine']
        
        # 2. STEERING EFFORT INDICATORS
        df['steering_cylinder_range'] = df[['sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04']].max(axis=1) - \
                                       df[['sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04']].min(axis=1)
        df['avg_cylinder_stroke'] = df[['sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04']].mean(axis=1)
        
        # 3. GROUND RESISTANCE FEATURES
        df['pressure_ratio'] = df['earth_pressure'] / (df['working_pressure'] + 0.1)  # Avoid division by zero
        df['force_per_advance'] = df['total_force'] / (df['advance_speed'] + 0.1)
        df['steering_resistance'] = df['total_force'] / (df['steering_cylinder_range'] + 1)
        
        # 4. ALIGNMENT TREND FEATURES (Rolling windows)
        window_size = 5
        df['hor_dev_trend'] = df['hor_dev_machine'].rolling(window=window_size, min_periods=1).apply(
            lambda x: np.polyfit(range(len(x)), x, 1)[0] if len(x) > 1 else 0
        )
        df['vert_dev_trend'] = df['vert_dev_machine'].rolling(window=window_size, min_periods=1).apply(
            lambda x: np.polyfit(range(len(x)), x, 1)[0] if len(x) > 1 else 0
        )
        df['deviation_trend_magnitude'] = np.sqrt(df['hor_dev_trend']**2 + df['vert_dev_trend']**2)
        
        # 5. MOVING AVERAGES
        df['advance_speed_ma'] = df['advance_speed'].rolling(window=3, min_periods=1).mean()
        df['total_force_ma'] = df['total_force'].rolling(window=3, min_periods=1).mean()
        df['earth_pressure_ma'] = df['earth_pressure'].rolling(window=3, min_periods=1).mean()
        
        # 6. TIME-BASED FEATURES
        df['time_diff'] = df['datetime'].diff().dt.total_seconds() / 3600  # Hours
        df['progress_rate'] = df['tunnel_length'].diff() / df['time_diff']  # m/hour
        df['hour_of_day'] = df['datetime'].dt.hour
        
        # 7. LAG FEATURES (Previous steering actions)
        for col in ['sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04']:
            df[f'{col}_prev'] = df[col].shift(1)
            df[f'{col}_change'] = df[col] - df[f'{col}_prev']
        
        return df
    
    def create_targets(self, df: pd.DataFrame) -> pd.DataFrame:
        """Create target variables for steering prediction"""
        
        # 1. NEXT DEVIATION (What we want to predict)
        df['next_hor_deviation'] = df['hor_dev_machine'].shift(-1)
        df['next_vert_deviation'] = df['vert_dev_machine'].shift(-1)
        df['next_total_deviation'] = df['total_deviation_machine'].shift(-1)
        
        # 2. REQUIRED STEERING CORRECTION (Based on next deviation)
        df['required_hor_correction'] = df['next_hor_deviation'] - df['hor_dev_machine']
        df['required_vert_correction'] = df['next_vert_deviation'] - df['vert_dev_machine']
        
        # 3. DEVIATION IMPROVEMENT (Is steering getting better?)
        df['deviation_improvement'] = df['total_deviation_machine'] - df['next_total_deviation']
        
        return df
    
    def prepare_ml_data(self, df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
        """Prepare features and targets for ML model"""
        
        # Select feature columns
        feature_cols = [
            # Current position
            'hor_dev_machine', 'vert_dev_machine', 'hor_dev_drill_head', 'vert_dev_drill_head',
            'yaw', 'pitch', 'roll', 'tunnel_length',
            
            # Steering controls
            'sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04', 'avg_cylinder_stroke', 'steering_cylinder_range',
            
            # Machine conditions
            'advance_speed', 'total_force', 'working_pressure', 'revolution_rpm', 'earth_pressure',
            'interjack_force', 'temperature',
            
            # Engineered features
            'total_deviation_machine', 'deviation_difference', 'pressure_ratio', 'force_per_advance',
            'steering_resistance', 'hor_dev_trend', 'vert_dev_trend', 'deviation_trend_magnitude',
            'advance_speed_ma', 'total_force_ma', 'earth_pressure_ma', 'progress_rate',
            
            # Previous steering actions
            'sc_cyl_01_change', 'sc_cyl_02_change', 'sc_cyl_03_change', 'sc_cyl_04_change'
        ]
        
        # Target columns (what we want to predict)
        target_cols = [
            'required_hor_correction',
            'required_vert_correction', 
            'deviation_improvement'
        ]
        
        # Remove rows with NaN values
        clean_df = df[feature_cols + target_cols].dropna()
        
        X = clean_df[feature_cols].values
        y = clean_df[target_cols].values
        
        self.feature_columns = feature_cols
        self.target_columns = target_cols
        
        return X, y
    
    def train_model(self, X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
        """Train the steering prediction model"""
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train Random Forest model (good for this type of engineering data)
        self.model = RandomForestRegressor(
            n_estimators=100,
            max_depth=15,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42,
            n_jobs=-1
        )
        
        self.model.fit(X_train_scaled, y_train)
        
        # Evaluate model
        y_pred_train = self.model.predict(X_train_scaled)
        y_pred_test = self.model.predict(X_test_scaled)
        
        # Calculate metrics for each target
        results = {}
        for i, target in enumerate(self.target_columns):
            results[target] = {
                'train_r2': r2_score(y_train[:, i], y_pred_train[:, i]),
                'test_r2': r2_score(y_test[:, i], y_pred_test[:, i]),
                'train_mae': mean_absolute_error(y_train[:, i], y_pred_train[:, i]),
                'test_mae': mean_absolute_error(y_test[:, i], y_pred_test[:, i]),
                'train_rmse': np.sqrt(mean_squared_error(y_train[:, i], y_pred_train[:, i])),
                'test_rmse': np.sqrt(mean_squared_error(y_test[:, i], y_pred_test[:, i]))
            }
        
        return results
    
    def get_feature_importance(self) -> pd.DataFrame:
        """Get feature importance rankings"""
        if self.model is None:
            raise ValueError("Model not trained yet!")
            
        # Get feature importances directly (Random Forest provides one value per feature)
        importance_df = pd.DataFrame({
            'feature': self.feature_columns,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        return importance_df
    
    def predict_steering_correction(self, current_data: Dict) -> Dict:
        """Predict required steering corrections for current conditions"""
        if self.model is None:
            raise ValueError("Model not trained yet!")
        
        # Convert input to feature vector (ensure same order as training)
        feature_vector = np.array([current_data.get(col, 0) for col in self.feature_columns]).reshape(1, -1)
        feature_vector_scaled = self.scaler.transform(feature_vector)
        
        # Make prediction
        prediction = self.model.predict(feature_vector_scaled)[0]
        
        return {
            'required_horizontal_correction': prediction[0],
            'required_vertical_correction': prediction[1], 
            'expected_deviation_improvement': prediction[2]
        }
    
    def plot_results(self, df: pd.DataFrame):
        """Create visualization plots for steering analysis"""
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        
        # 1. Deviation over distance
        axes[0,0].plot(df['tunnel_length'], df['total_deviation_machine'], label='Machine Deviation', alpha=0.7)
        axes[0,0].plot(df['tunnel_length'], df['total_deviation_drill_head'], label='Drill Head Deviation', alpha=0.7)
        axes[0,0].set_xlabel('Tunnel Length (m)')
        axes[0,0].set_ylabel('Total Deviation (mm)')
        axes[0,0].set_title('Deviation vs Distance')
        axes[0,0].legend()
        axes[0,0].grid(True, alpha=0.3)
        
        # 2. Steering cylinder usage
        cylinder_cols = ['sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04']
        for col in cylinder_cols:
            axes[0,1].plot(df['tunnel_length'], df[col], label=col, alpha=0.7)
        axes[0,1].set_xlabel('Tunnel Length (m)')
        axes[0,1].set_ylabel('Cylinder Stroke (mm)')
        axes[0,1].set_title('Steering Cylinder Usage')
        axes[0,1].legend()
        axes[0,1].grid(True, alpha=0.3)
        
        # 3. Feature importance (if model is trained)
        if self.model is not None:
            importance_df = self.get_feature_importance().head(10)
            axes[1,0].barh(importance_df['feature'], importance_df['importance'])
            axes[1,0].set_xlabel('Feature Importance')
            axes[1,0].set_title('Top 10 Features for Steering Prediction')
            
        # 4. Deviation trend
        axes[1,1].plot(df['tunnel_length'], df['hor_dev_trend'], label='Horizontal Trend', alpha=0.7)
        axes[1,1].plot(df['tunnel_length'], df['vert_dev_trend'], label='Vertical Trend', alpha=0.7)
        axes[1,1].set_xlabel('Tunnel Length (m)')
        axes[1,1].set_ylabel('Deviation Trend (mm/reading)')
        axes[1,1].set_title('Steering Correction Trends')
        axes[1,1].legend()
        axes[1,1].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.show()


def main():
    """Example usage of the Steering Accuracy Predictor"""
    
    # Initialize predictor
    predictor = SteeringAccuracyPredictor()
    
    # Load and process data
    print("Loading AVN1200 drive data...")
    df = predictor.load_data('measure_protocol_original_.xls.csv')
    
    print("Engineering features...")
    df = predictor.engineer_features(df)
    df = predictor.create_targets(df)
    
    print(f"Data shape: {df.shape}")
    print(f"Drive length: {df['tunnel_length'].max():.1f}m")
    print(f"Total readings: {len(df)}")
    
    # Prepare ML data
    print("Preparing machine learning data...")
    X, y = predictor.prepare_ml_data(df)
    print(f"Features shape: {X.shape}")
    print(f"Targets shape: {y.shape}")
    
    # Train model
    print("Training steering prediction model...")
    results = predictor.train_model(X, y)
    
    # Print results
    print("\n=== MODEL PERFORMANCE ===")
    for target, metrics in results.items():
        print(f"\n{target.upper()}:")
        print(f"  Train R²: {metrics['train_r2']:.3f} | Test R²: {metrics['test_r2']:.3f}")
        print(f"  Train MAE: {metrics['train_mae']:.2f} | Test MAE: {metrics['test_mae']:.2f}")
        print(f"  Train RMSE: {metrics['train_rmse']:.2f} | Test RMSE: {metrics['test_rmse']:.2f}")
    
    # Feature importance
    print("\n=== TOP 10 IMPORTANT FEATURES ===")
    importance_df = predictor.get_feature_importance()
    for i, row in importance_df.head(10).iterrows():
        print(f"{row['feature']}: {row['importance']:.3f}")
    
    # Example prediction
    print("\n=== EXAMPLE STEERING PREDICTION ===")
    # Use current conditions from last reading
    current_conditions = df.iloc[-2][predictor.feature_columns].to_dict()
    prediction = predictor.predict_steering_correction(current_conditions)
    
    print(f"Required horizontal correction: {prediction['required_horizontal_correction']:.2f} mm")
    print(f"Required vertical correction: {prediction['required_vertical_correction']:.2f} mm") 
    print(f"Expected deviation improvement: {prediction['expected_deviation_improvement']:.2f} mm")
    
    # Create plots
    print("\nGenerating analysis plots...")
    predictor.plot_results(df)
    
    return predictor, df


if __name__ == "__main__":
    predictor, data = main()