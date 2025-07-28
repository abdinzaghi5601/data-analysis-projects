#!/usr/bin/env python3
"""
Complete MTBM Drive Protocol ML System Demonstration
Shows integration of all components with realistic example
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

# Import our custom modules
from mtbm_drive_protocol_ml import MTBMDriveProtocolML
from mtbm_realtime_optimizer import MTBMRealTimeOptimizer

def generate_demo_data(num_samples=1000):
    """Generate realistic demo data for MTBM operations"""
    
    print("Generating realistic MTBM demo data...")
    
    # Create time series
    start_date = datetime(2023, 7, 1, 8, 0, 0)
    dates = [start_date + timedelta(minutes=i*5) for i in range(num_samples)]
    
    # Simulate tunneling progress
    tunnel_lengths = np.cumsum(np.random.normal(0.08, 0.02, num_samples))  # ~5cm per reading
    tunnel_lengths = np.maximum(tunnel_lengths, 0)  # Ensure positive
    
    # Simulate ground condition changes
    ground_difficulty = np.sin(tunnel_lengths / 50) + np.random.normal(0, 0.3, num_samples)
    ground_difficulty = np.clip(ground_difficulty, -2, 2)
    
    # Base parameters influenced by ground conditions
    base_earth_pressure = 120 + ground_difficulty * 30
    base_total_force = 800 + ground_difficulty * 200
    base_advance_speed = 45 - ground_difficulty * 10
    
    # Add realistic noise and correlations
    data = []
    current_deviation_h = 0
    current_deviation_v = 0
    
    for i in range(num_samples):
        # Steering dynamics - deviations accumulate and are corrected
        steering_correction_h = np.random.normal(0, 2) if abs(current_deviation_h) < 30 else -current_deviation_h * 0.3
        steering_correction_v = np.random.normal(0, 2) if abs(current_deviation_v) < 30 else -current_deviation_v * 0.3
        
        current_deviation_h += steering_correction_h + np.random.normal(0, 1)
        current_deviation_v += steering_correction_v + np.random.normal(0, 1)
        
        # Drill head typically leads machine body
        drill_head_h = current_deviation_h + np.random.normal(0, 3)
        drill_head_v = current_deviation_v + np.random.normal(0, 3)
        
        # Machine orientation
        yaw = np.arctan2(current_deviation_h, 100) * 180 / np.pi + np.random.normal(0, 0.5)
        pitch = np.arctan2(current_deviation_v, 100) * 180 / np.pi + np.random.normal(0, 0.5)
        roll = np.random.normal(0, 0.2)
        
        # Steering cylinder positions (0-100mm range)
        base_cylinder = 50  # Neutral position
        # Cylinders adjust based on required correction
        sc_cyl_01 = base_cylinder - steering_correction_h * 0.5 + np.random.normal(0, 2)
        sc_cyl_02 = base_cylinder + steering_correction_h * 0.5 + np.random.normal(0, 2)
        sc_cyl_03 = base_cylinder - steering_correction_v * 0.5 + np.random.normal(0, 2)
        sc_cyl_04 = base_cylinder + steering_correction_v * 0.5 + np.random.normal(0, 2)
        
        # Clamp cylinder positions
        sc_cyl_01 = np.clip(sc_cyl_01, 0, 100)
        sc_cyl_02 = np.clip(sc_cyl_02, 0, 100)
        sc_cyl_03 = np.clip(sc_cyl_03, 0, 100)
        sc_cyl_04 = np.clip(sc_cyl_04, 0, 100)
        
        # Operating parameters influenced by ground conditions
        advance_speed = max(10, base_advance_speed[i] + np.random.normal(0, 5))
        total_force = max(200, base_total_force[i] + np.random.normal(0, 50))
        earth_pressure = max(50, base_earth_pressure[i] + np.random.normal(0, 10))
        working_pressure = max(100, earth_pressure * 1.5 + np.random.normal(0, 20))
        
        # Other parameters
        revolution_rpm = np.clip(np.random.normal(8.5, 1), 5, 15)
        temperature = np.random.normal(25, 5)
        interjack_force = max(0, np.random.normal(500, 100))
        
        # Create data row
        row = {
            'date': dates[i].strftime('%d-%m-%y'),
            'time': dates[i].strftime('%H:%M:%S'),
            'tunnel_length': tunnel_lengths[i],
            'hor_dev_machine': current_deviation_h,
            'vert_dev_machine': current_deviation_v,
            'hor_dev_drill_head': drill_head_h,
            'vert_dev_drill_head': drill_head_v,
            'yaw': yaw,
            'pitch': pitch,
            'roll': roll,
            'temperature': temperature,
            'survey_mode': 0,
            'sc_cyl_01': sc_cyl_01,
            'sc_cyl_02': sc_cyl_02,
            'sc_cyl_03': sc_cyl_03,
            'sc_cyl_04': sc_cyl_04,
            'advance_speed': advance_speed,
            'interjack_force': interjack_force,
            'interjack_active': 1 if interjack_force > 300 else 0,
            'working_pressure': working_pressure,
            'revolution_rpm': revolution_rpm,
            'earth_pressure': earth_pressure,
            'total_force': total_force
        }
        
        data.append(row)
    
    # Create DataFrame and save to CSV
    df = pd.DataFrame(data)
    demo_csv_path = 'demo_mtbm_data.csv'
    
    # Save with column headers
    with open(demo_csv_path, 'w') as f:
        # Write header row
        f.write(','.join(map(str, range(1, len(df.columns) + 1))) + '\n')
        # Write data
        df.to_csv(f, header=False, index=False)
    
    print(f"Demo data saved to {demo_csv_path}")
    print(f"Generated {len(data)} readings covering {tunnel_lengths[-1]:.1f}m of tunnel")
    
    return demo_csv_path, df

def demonstrate_complete_system():
    """Demonstrate the complete MTBM ML system"""
    
    print("="*60)
    print("COMPLETE MTBM DRIVE PROTOCOL ML SYSTEM DEMONSTRATION")
    print("="*60)
    
    # Step 1: Generate demo data
    demo_csv_path, raw_df = generate_demo_data(800)
    
    # Step 2: Initialize and train ML framework
    print("\n" + "="*50)
    print("INITIALIZING ML FRAMEWORK")
    print("="*50)
    
    ml_framework = MTBMDriveProtocolML()
    
    # Load and process data
    print("Loading and processing drive protocol data...")
    df = ml_framework.load_protocol_data(demo_csv_path)
    df = ml_framework.engineer_comprehensive_features(df)
    df = ml_framework.create_ml_targets(df)
    
    print(f"Processed dataset: {df.shape[0]} readings, {df.shape[1]} features")
    print(f"Drive length: {df['tunnel_length'].max():.1f}m")
    print(f"Max deviation: {df['total_deviation_machine'].max():.1f}mm")
    
    # Step 3: Train all ML models
    print("\n" + "="*50)
    print("TRAINING ML MODELS")
    print("="*50)
    
    datasets = ml_framework.prepare_feature_sets(df)
    
    trained_models = []
    
    if 'steering' in datasets:
        print("Training steering accuracy model...")
        X_steering, y_steering = datasets['steering']
        results = ml_framework.train_steering_model(X_steering, y_steering)
        trained_models.append('steering')
        print(f"✓ Steering model trained - Features: {X_steering.shape[1]}, Samples: {X_steering.shape[0]}")
    
    if 'efficiency' in datasets:
        print("Training efficiency optimization model...")
        X_efficiency, y_efficiency = datasets['efficiency']
        results = ml_framework.train_efficiency_model(X_efficiency, y_efficiency)
        trained_models.append('efficiency')
        print(f"✓ Efficiency model trained - Features: {X_efficiency.shape[1]}, Samples: {X_efficiency.shape[0]}")
    
    if 'ground' in datasets:
        print("Training ground condition classifier...")
        X_ground, y_ground = datasets['ground']
        results = ml_framework.train_ground_classifier(X_ground, y_ground)
        trained_models.append('ground')
        print(f"✓ Ground classifier trained - Features: {X_ground.shape[1]}, Samples: {X_ground.shape[0]}")
    
    if 'risk' in datasets:
        print("Training risk assessment model...")
        X_risk, y_risk = datasets['risk']
        results = ml_framework.train_risk_model(X_risk, y_risk)
        trained_models.append('risk')
        print(f"✓ Risk model trained - Features: {X_risk.shape[1]}, Samples: {X_risk.shape[0]}")
    
    # Step 4: Display model performance
    print("\n" + "="*50)
    print("MODEL PERFORMANCE SUMMARY")
    print("="*50)
    
    for model_name, performance in ml_framework.model_performance.items():
        print(f"\n{model_name.upper()} MODEL:")
        if model_name in ['steering', 'efficiency']:
            for target, metrics in performance.items():
                print(f"  {target}:")
                print(f"    R² Score: {metrics['test_r2']:.3f}")
                print(f"    MAE: {metrics['test_mae']:.2f}")
        else:
            print(f"  Test Accuracy: {performance['test_accuracy']:.3f}")
    
    # Step 5: Initialize real-time optimizer
    print("\n" + "="*50)
    print("INITIALIZING REAL-TIME OPTIMIZER")
    print("="*50)
    
    optimizer = MTBMRealTimeOptimizer(ml_framework)
    
    # Step 6: Demonstrate predictions and optimization
    print("\n" + "="*50)
    print("COMPREHENSIVE PREDICTION DEMONSTRATION")
    print("="*50)
    
    # Use current conditions from recent data
    current_conditions = df.iloc[-10][ml_framework.feature_columns].to_dict()
    
    print("Current Machine State:")
    key_params = ['tunnel_length', 'total_deviation_machine', 'advance_speed', 'total_force', 'earth_pressure']
    for param in key_params:
        if param in current_conditions:
            print(f"  {param}: {current_conditions[param]:.2f}")
    
    # Make comprehensive predictions
    predictions = ml_framework.comprehensive_predict(current_conditions)
    
    print("\nML Predictions:")
    for model_type, pred in predictions.items():
        print(f"\n{model_type.upper()}:")
        for key, value in pred.items():
            if isinstance(value, (int, float)):
                print(f"  {key}: {value:.2f}")
            else:
                print(f"  {key}: {value}")
    
    # Generate recommendations
    recommendations = ml_framework.generate_drive_recommendations(predictions, current_conditions)
    
    print("\nOperational Recommendations:")
    for category, recs in recommendations.items():
        if recs:
            print(f"\n{category.upper()}:")
            for rec in recs:
                print(f"  • {rec}")
    
    # Step 7: Demonstrate optimization
    print("\n" + "="*50)
    print("MULTI-OBJECTIVE OPTIMIZATION")
    print("="*50)
    
    optimization_result = optimizer.multi_objective_optimization(current_conditions)
    
    if 'optimal_parameters' in optimization_result:
        print("Optimization Results:")
        for param, value in optimization_result['optimal_parameters'].items():
            if param != 'expected_improvements':
                print(f"  {param}: {value:.2f}")
        
        if 'expected_improvements' in optimization_result:
            print("\nExpected Improvements:")
            for improvement, value in optimization_result['expected_improvements'].items():
                print(f"  {improvement}: {value:.2f}")
    else:
        print("Optimization encountered issues:")
        print(f"  {optimization_result}")
    
    # Step 8: Demonstrate anomaly detection
    print("\n" + "="*50)
    print("ANOMALY DETECTION DEMONSTRATION")
    print("="*50)
    
    # Test with normal conditions
    normal_result = optimizer.real_time_anomaly_detection(current_conditions)
    print(f"Normal conditions analysis: {normal_result['status']}")
    
    # Test with anomalous conditions
    anomalous_conditions = current_conditions.copy()
    anomalous_conditions['advance_speed'] = 150  # Abnormally high speed
    anomalous_conditions['total_deviation_machine'] = 80  # High deviation
    
    anomaly_result = optimizer.real_time_anomaly_detection(anomalous_conditions)
    print(f"Anomalous conditions analysis: {anomaly_result['status']}")
    
    if anomaly_result['anomalies']:
        print("Detected anomalies:")
        for anomaly in anomaly_result['anomalies']:
            print(f"  • {anomaly['parameter']}: {anomaly['severity']} severity")
    
    # Step 9: Generate comprehensive report
    print("\n" + "="*50)
    print("COMPREHENSIVE SYSTEM REPORT")
    print("="*50)
    
    report = optimizer.generate_optimization_report(current_conditions, df)
    
    print("Report Generation:")
    print(f"  Timestamp: {report['timestamp']}")
    print(f"  Current efficiency score: {report['current_status']['key_metrics']['efficiency_score']:.1f}/100")
    
    # Display key recommendations
    print("\nKey System Recommendations:")
    all_recommendations = []
    for category, recs in report['recommendations'].items():
        all_recommendations.extend(recs)
    
    for i, rec in enumerate(all_recommendations[:5], 1):  # Show top 5
        print(f"  {i}. {rec}")
    
    # Step 10: Demonstrate predictive maintenance
    print("\n" + "="*50)
    print("PREDICTIVE MAINTENANCE ANALYSIS")
    print("="*50)
    
    maintenance_analysis = optimizer.predictive_maintenance_analysis(df)
    
    print(f"Overall System Health Score: {maintenance_analysis['overall_health_score']}/100")
    
    if maintenance_analysis['recommended_actions']:
        print("\nMaintenance Recommendations:")
        for action in maintenance_analysis['recommended_actions']:
            print(f"  • {action}")
    else:
        print("No immediate maintenance actions required")
    
    # Step 11: Create visualizations
    print("\n" + "="*50)
    print("GENERATING ANALYSIS VISUALIZATIONS")
    print("="*50)
    
    print("Creating comprehensive analysis plots...")
    ml_framework.plot_comprehensive_analysis(df)
    
    # Step 12: Export results
    print("\n" + "="*50)
    print("EXPORTING RESULTS")
    print("="*50)
    
    # Export model summary
    ml_framework.export_model_summary('demo_model_summary.txt')
    
    # Export optimization history (if any)
    if optimizer.optimization_history:
        optimizer.export_optimization_history('demo_optimization_history.json')
    
    print("\n" + "="*60)
    print("DEMONSTRATION COMPLETED SUCCESSFULLY")
    print("="*60)
    
    print(f"\nTrained Models: {len(trained_models)} ({', '.join(trained_models)})")
    print(f"Data Processed: {df.shape[0]} readings, {df.shape[1]} features")
    print(f"System Status: All components operational")
    
    return ml_framework, optimizer, df

def quick_prediction_demo(ml_framework):
    """Quick demonstration of making predictions with new data"""
    
    print("\n" + "="*40)
    print("QUICK PREDICTION DEMO")
    print("="*40)
    
    # Simulate real-time data input
    new_reading = {
        'tunnel_length': 200.5,
        'hor_dev_machine': 15,
        'vert_dev_machine': -8,
        'total_deviation_machine': 17.0,
        'advance_speed': 42.3,
        'working_pressure': 185,
        'revolution_rpm': 8.2,
        'total_force': 920,
        'earth_pressure': 135,
        'sc_cyl_01': 28,
        'sc_cyl_02': 32,
        'sc_cyl_03': 25,
        'sc_cyl_04': 35,
        'yaw': 1.2,
        'pitch': -0.8,
        'roll': 0.1,
        'temperature': 23.5
    }
    
    # Fill in any missing engineered features with defaults
    for feature in ml_framework.feature_columns:
        if feature not in new_reading:
            new_reading[feature] = 0
    
    print("New reading received:")
    for key, value in list(new_reading.items())[:8]:  # Show first 8 parameters
        print(f"  {key}: {value}")
    print("  ... (additional parameters)")
    
    # Make prediction
    prediction = ml_framework.comprehensive_predict(new_reading)
    
    print("\nInstant ML Analysis:")
    if 'steering' in prediction:
        h_corr = prediction['steering']['required_horizontal_correction']
        v_corr = prediction['steering']['required_vertical_correction']
        print(f"  Steering: H={h_corr:.1f}mm, V={v_corr:.1f}mm correction needed")
    
    if 'ground' in prediction:
        condition = prediction['ground']['condition']
        confidence = prediction['ground']['confidence']
        print(f"  Ground: {condition} condition detected ({confidence:.1%} confidence)")
    
    if 'risk' in prediction:
        risk = prediction['risk']['level']
        print(f"  Risk Level: {risk}")
    
    return prediction

if __name__ == "__main__":
    # Run complete system demonstration
    ml_framework, optimizer, processed_data = demonstrate_complete_system()
    
    # Run quick prediction demo
    quick_prediction_demo(ml_framework)
    
    print("\n🎯 Demo completed! All components tested successfully.")
    print("📊 Check generated plots and exported files for detailed results.")