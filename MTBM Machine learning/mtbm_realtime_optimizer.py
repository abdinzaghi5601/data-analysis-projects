#!/usr/bin/env python3
"""
MTBM Real-Time Drive Optimization System
Advanced ML-driven optimization for micro-tunneling operations with real-time monitoring
"""

import numpy as np
import pandas as pd
from scipy.optimize import minimize, differential_evolution
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import RBF, WhiteKernel
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
import json
import threading
import time
from typing import Dict, List, Tuple, Optional
import warnings
warnings.filterwarnings('ignore')

class MTBMRealTimeOptimizer:
    """
    Real-time optimization system for MTBM drive parameters
    Uses ML models to continuously optimize tunneling performance
    """
    
    def __init__(self, base_ml_framework):
        self.ml_framework = base_ml_framework
        self.optimization_history = []
        self.real_time_data = []
        self.alert_thresholds = self._set_default_thresholds()
        self.optimization_params = self._set_optimization_bounds()
        
        # Gaussian Process for uncertainty quantification
        kernel = RBF(length_scale=1.0) + WhiteKernel(noise_level=0.1)
        self.gp_model = GaussianProcessRegressor(kernel=kernel, random_state=42)
        
        # Real-time monitoring flags
        self.is_monitoring = False
        self.monitoring_thread = None
        
    def _set_default_thresholds(self) -> Dict:
        """Set default alert thresholds for various parameters"""
        return {
            'max_deviation': 50.0,  # mm
            'min_efficiency': 0.3,
            'max_pressure_ratio': 1.5,
            'max_force': 2000,  # kN
            'min_advance_speed': 10.0,  # mm/min
            'max_advance_speed': 100.0  # mm/min
        }
    
    def _set_optimization_bounds(self) -> Dict:
        """Set parameter bounds for optimization"""
        return {
            'advance_speed': (10, 100),  # mm/min
            'working_pressure': (100, 300),  # bar
            'revolution_rpm': (5, 15),  # rpm
            'cylinder_adjustment': (-20, 20)  # mm adjustment range
        }
    
    def multi_objective_optimization(self, current_state: Dict) -> Dict:
        """
        Perform multi-objective optimization for drive parameters
        Objectives: Minimize deviation, maximize efficiency, minimize risk
        """
        
        def objective_function(params):
            """Combined objective function for optimization"""
            advance_speed, working_pressure, revolution_rpm, cyl_adj = params
            
            # Create hypothetical state with optimized parameters
            test_state = current_state.copy()
            test_state.update({
                'advance_speed': advance_speed,
                'working_pressure': working_pressure,
                'revolution_rpm': revolution_rpm,
                'sc_cyl_01': current_state.get('sc_cyl_01', 0) + cyl_adj,
                'sc_cyl_02': current_state.get('sc_cyl_02', 0) + cyl_adj,
                'sc_cyl_03': current_state.get('sc_cyl_03', 0) + cyl_adj,
                'sc_cyl_04': current_state.get('sc_cyl_04', 0) + cyl_adj
            })
            
            # Get predictions for this configuration
            predictions = self.ml_framework.comprehensive_predict(test_state)
            
            # Calculate multi-objective score
            deviation_penalty = 0
            efficiency_reward = 0
            risk_penalty = 0
            
            if 'steering' in predictions:
                total_correction = abs(predictions['steering']['required_horizontal_correction']) + \
                                 abs(predictions['steering']['required_vertical_correction'])
                deviation_penalty = total_correction / 100.0  # Normalize
            
            if 'efficiency' in predictions:
                efficiency_reward = predictions['efficiency']['efficiency_improvement']
            
            if 'risk' in predictions:
                risk_levels = {'low': 0, 'medium': 0.5, 'high': 1.0}
                risk_penalty = risk_levels.get(predictions['risk']['level'], 0.5)
            
            # Combined objective (minimize)
            objective = deviation_penalty - efficiency_reward + risk_penalty
            
            return objective
        
        # Define parameter bounds
        bounds = [
            self.optimization_params['advance_speed'],
            self.optimization_params['working_pressure'],
            self.optimization_params['revolution_rpm'],
            self.optimization_params['cylinder_adjustment']
        ]
        
        # Use differential evolution for global optimization
        result = differential_evolution(
            objective_function,
            bounds,
            seed=42,
            maxiter=50,
            popsize=15
        )
        
        if result.success:
            optimal_params = {
                'advance_speed': result.x[0],
                'working_pressure': result.x[1],
                'revolution_rpm': result.x[2],
                'cylinder_adjustment': result.x[3],
                'objective_value': result.fun
            }
            
            # Calculate expected improvements
            original_prediction = self.ml_framework.comprehensive_predict(current_state)
            optimized_state = current_state.copy()
            optimized_state.update({
                'advance_speed': optimal_params['advance_speed'],
                'working_pressure': optimal_params['working_pressure'],
                'revolution_rpm': optimal_params['revolution_rpm']
            })
            optimized_prediction = self.ml_framework.comprehensive_predict(optimized_state)
            
            optimal_params['expected_improvements'] = self._calculate_improvements(
                original_prediction, optimized_prediction
            )
            
            return optimal_params
        else:
            return {'error': 'Optimization failed', 'message': result.message}
    
    def _calculate_improvements(self, original: Dict, optimized: Dict) -> Dict:
        """Calculate expected improvements from optimization"""
        improvements = {}
        
        if 'steering' in original and 'steering' in optimized:
            orig_total = abs(original['steering']['required_horizontal_correction']) + \
                        abs(original['steering']['required_vertical_correction'])
            opt_total = abs(optimized['steering']['required_horizontal_correction']) + \
                       abs(optimized['steering']['required_vertical_correction'])
            improvements['deviation_reduction'] = max(0, orig_total - opt_total)
        
        if 'efficiency' in original and 'efficiency' in optimized:
            improvements['efficiency_gain'] = optimized['efficiency']['efficiency_improvement'] - \
                                            original['efficiency']['efficiency_improvement']
        
        return improvements
    
    def adaptive_parameter_tuning(self, historical_data: pd.DataFrame) -> Dict:
        """
        Use Gaussian Process to learn optimal parameter relationships
        and adapt to changing ground conditions
        """
        
        # Prepare training data for GP
        features = ['advance_speed', 'working_pressure', 'revolution_rpm', 'earth_pressure']
        targets = ['cutting_efficiency', 'total_deviation_machine']
        
        available_features = [f for f in features if f in historical_data.columns]
        available_targets = [f for f in targets if f in historical_data.columns]
        
        if len(available_features) < 3 or len(available_targets) < 1:
            return {'error': 'Insufficient data for adaptive tuning'}
        
        X = historical_data[available_features].dropna().values
        y = historical_data[available_targets].dropna().values
        
        if len(X) < 10:
            return {'error': 'Insufficient samples for adaptive tuning'}
        
        # Train Gaussian Process
        self.gp_model.fit(X, y[:, 0])  # Use first target for now
        
        # Find optimal parameters with uncertainty quantification
        def gp_objective(params):
            params_array = np.array(params).reshape(1, -1)
            mean, std = self.gp_model.predict(params_array, return_std=True)
            # Minimize negative efficiency (maximize efficiency) with uncertainty penalty
            return -mean[0] + 0.1 * std[0]  # Penalize uncertainty
        
        bounds = [(X[:, i].min(), X[:, i].max()) for i in range(X.shape[1])]
        
        result = minimize(
            gp_objective,
            x0=X.mean(axis=0),
            bounds=bounds,
            method='L-BFGS-B'
        )
        
        if result.success:
            optimal_params = dict(zip(available_features, result.x))
            
            # Predict performance with uncertainty
            pred_mean, pred_std = self.gp_model.predict(
                result.x.reshape(1, -1), return_std=True
            )
            
            return {
                'optimal_parameters': optimal_params,
                'expected_performance': pred_mean[0],
                'uncertainty': pred_std[0],
                'confidence_interval': (pred_mean[0] - 2*pred_std[0], pred_mean[0] + 2*pred_std[0])
            }
        else:
            return {'error': 'Adaptive tuning optimization failed'}
    
    def real_time_anomaly_detection(self, current_data: Dict, window_size: int = 20) -> Dict:
        """
        Detect anomalies in real-time tunneling data
        Uses statistical and ML-based approaches
        """
        
        # Add current data to monitoring buffer
        self.real_time_data.append({
            'timestamp': datetime.now(),
            'data': current_data.copy()
        })
        
        # Maintain rolling window
        if len(self.real_time_data) > window_size:
            self.real_time_data.pop(0)
        
        if len(self.real_time_data) < 5:
            return {'status': 'insufficient_data'}
        
        # Extract recent values for key parameters
        recent_df = pd.DataFrame([entry['data'] for entry in self.real_time_data])
        
        anomalies = []
        warnings = []
        
        # Statistical anomaly detection
        for param in ['advance_speed', 'total_force', 'earth_pressure', 'total_deviation_machine']:
            if param in recent_df.columns and param in current_data:
                recent_values = recent_df[param].dropna()
                if len(recent_values) >= 3:
                    mean_val = recent_values.mean()
                    std_val = recent_values.std()
                    current_val = current_data[param]
                    
                    # Z-score based anomaly detection
                    if std_val > 0:
                        z_score = abs(current_val - mean_val) / std_val
                        if z_score > 3:
                            anomalies.append({
                                'parameter': param,
                                'current_value': current_val,
                                'expected_range': (mean_val - 2*std_val, mean_val + 2*std_val),
                                'severity': 'high' if z_score > 4 else 'medium'
                            })
                        elif z_score > 2:
                            warnings.append({
                                'parameter': param,
                                'message': f'{param} showing unusual variation'
                            })
        
        # Threshold-based alerts
        threshold_alerts = []
        
        if 'total_deviation_machine' in current_data:
            if current_data['total_deviation_machine'] > self.alert_thresholds['max_deviation']:
                threshold_alerts.append({
                    'type': 'deviation_exceeded',
                    'value': current_data['total_deviation_machine'],
                    'threshold': self.alert_thresholds['max_deviation']
                })
        
        if 'advance_speed' in current_data:
            speed = current_data['advance_speed']
            if speed < self.alert_thresholds['min_advance_speed'] or speed > self.alert_thresholds['max_advance_speed']:
                threshold_alerts.append({
                    'type': 'speed_out_of_range',
                    'value': speed,
                    'range': (self.alert_thresholds['min_advance_speed'], self.alert_thresholds['max_advance_speed'])
                })
        
        return {
            'timestamp': datetime.now().isoformat(),
            'anomalies': anomalies,
            'warnings': warnings,
            'threshold_alerts': threshold_alerts,
            'status': 'normal' if not anomalies and not threshold_alerts else 'alerts_detected'
        }
    
    def predictive_maintenance_analysis(self, historical_data: pd.DataFrame) -> Dict:
        """
        Analyze equipment performance trends for predictive maintenance
        """
        
        maintenance_indicators = {}
        
        # Analyze steering cylinder performance
        cylinder_cols = ['sc_cyl_01', 'sc_cyl_02', 'sc_cyl_03', 'sc_cyl_04']
        available_cylinders = [col for col in cylinder_cols if col in historical_data.columns]
        
        if available_cylinders:
            maintenance_indicators['steering_system'] = {}
            
            for cyl in available_cylinders:
                cylinder_data = historical_data[cyl].dropna()
                if len(cylinder_data) > 10:
                    # Analyze cylinder usage patterns
                    usage_variance = cylinder_data.var()
                    usage_range = cylinder_data.max() - cylinder_data.min()
                    
                    # Detect potential issues
                    issues = []
                    if usage_variance > cylinder_data.mean() * 0.5:
                        issues.append('high_variance_usage')
                    if usage_range > 80:  # Assuming 100mm max stroke
                        issues.append('full_range_usage')
                    
                    maintenance_indicators['steering_system'][cyl] = {
                        'usage_variance': usage_variance,
                        'usage_range': usage_range,
                        'potential_issues': issues,
                        'maintenance_priority': 'high' if len(issues) > 1 else ('medium' if issues else 'low')
                    }
        
        # Analyze cutting system performance
        if 'revolution_rpm' in historical_data.columns and 'total_force' in historical_data.columns:
            rpm_data = historical_data['revolution_rpm'].dropna()
            force_data = historical_data['total_force'].dropna()
            
            if len(rpm_data) > 10 and len(force_data) > 10:
                # Calculate performance trends
                recent_performance = force_data.tail(20).mean() / (rpm_data.tail(20).mean() + 0.1)
                historical_performance = force_data.head(20).mean() / (rpm_data.head(20).mean() + 0.1)
                
                performance_change = (recent_performance - historical_performance) / historical_performance
                
                maintenance_indicators['cutting_system'] = {
                    'performance_change': performance_change,
                    'recommendation': 'inspect_cutterhead' if performance_change > 0.2 else 'normal',
                    'trend': 'deteriorating' if performance_change > 0.1 else 'stable'
                }
        
        # Overall system health score
        health_score = 100
        
        for system, indicators in maintenance_indicators.items():
            if system == 'steering_system':
                high_priority_count = sum(1 for cyl_data in indicators.values() 
                                        if cyl_data.get('maintenance_priority') == 'high')
                health_score -= high_priority_count * 10
            elif system == 'cutting_system':
                if indicators.get('trend') == 'deteriorating':
                    health_score -= 15
        
        maintenance_indicators['overall_health_score'] = max(0, health_score)
        maintenance_indicators['recommended_actions'] = self._generate_maintenance_recommendations(maintenance_indicators)
        
        return maintenance_indicators
    
    def _generate_maintenance_recommendations(self, indicators: Dict) -> List[str]:
        """Generate maintenance recommendations based on analysis"""
        recommendations = []
        
        if 'steering_system' in indicators:
            high_priority_cylinders = [
                cyl for cyl, data in indicators['steering_system'].items()
                if data.get('maintenance_priority') == 'high'
            ]
            if high_priority_cylinders:
                recommendations.append(f"Inspect steering cylinders: {', '.join(high_priority_cylinders)}")
        
        if 'cutting_system' in indicators:
            if indicators['cutting_system'].get('recommendation') == 'inspect_cutterhead':
                recommendations.append("Schedule cutterhead inspection - performance degradation detected")
        
        health_score = indicators.get('overall_health_score', 100)
        if health_score < 70:
            recommendations.append("Schedule comprehensive system maintenance - multiple issues detected")
        elif health_score < 85:
            recommendations.append("Monitor system closely - preventive maintenance recommended")
        
        return recommendations
    
    def generate_optimization_report(self, current_state: Dict, historical_data: pd.DataFrame) -> Dict:
        """Generate comprehensive optimization report"""
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'current_status': {},
            'optimization_results': {},
            'maintenance_analysis': {},
            'recommendations': {}
        }
        
        # Current status analysis
        predictions = self.ml_framework.comprehensive_predict(current_state)
        anomaly_analysis = self.real_time_anomaly_detection(current_state)
        
        report['current_status'] = {
            'predictions': predictions,
            'anomaly_analysis': anomaly_analysis,
            'key_metrics': {
                'tunnel_length': current_state.get('tunnel_length', 0),
                'total_deviation': current_state.get('total_deviation_machine', 0),
                'advance_speed': current_state.get('advance_speed', 0),
                'efficiency_score': self._calculate_efficiency_score(current_state)
            }
        }
        
        # Optimization results
        optimization_result = self.multi_objective_optimization(current_state)
        adaptive_tuning = self.adaptive_parameter_tuning(historical_data)
        
        report['optimization_results'] = {
            'multi_objective': optimization_result,
            'adaptive_tuning': adaptive_tuning
        }
        
        # Maintenance analysis
        report['maintenance_analysis'] = self.predictive_maintenance_analysis(historical_data)
        
        # Generate comprehensive recommendations
        report['recommendations'] = self._generate_comprehensive_recommendations(
            predictions, optimization_result, anomaly_analysis
        )
        
        return report
    
    def _calculate_efficiency_score(self, state: Dict) -> float:
        """Calculate overall efficiency score (0-100)"""
        score = 50  # Base score
        
        # Adjust based on advance speed
        speed = state.get('advance_speed', 0)
        if speed > 30:
            score += min(25, (speed - 30) / 2)  # Bonus for higher speed
        else:
            score -= (30 - speed) / 2  # Penalty for low speed
        
        # Adjust based on deviation
        deviation = state.get('total_deviation_machine', 0)
        if deviation < 20:
            score += 15  # Bonus for good alignment
        else:
            score -= min(25, deviation / 2)  # Penalty for poor alignment
        
        # Adjust based on force efficiency
        force = state.get('total_force', 0)
        if force > 0 and speed > 0:
            force_efficiency = speed / force * 1000  # Normalize
            if force_efficiency > 0.05:
                score += 10
        
        return max(0, min(100, score))
    
    def _generate_comprehensive_recommendations(self, predictions: Dict, optimization: Dict, anomalies: Dict) -> Dict:
        """Generate comprehensive operational recommendations"""
        
        recommendations = {
            'immediate_actions': [],
            'optimization_suggestions': [],
            'monitoring_alerts': [],
            'long_term_planning': []
        }
        
        # Immediate actions based on anomalies
        if anomalies.get('status') == 'alerts_detected':
            for anomaly in anomalies.get('anomalies', []):
                if anomaly.get('severity') == 'high':
                    recommendations['immediate_actions'].append(
                        f"Address {anomaly['parameter']} anomaly - value outside normal range"
                    )
            
            for alert in anomalies.get('threshold_alerts', []):
                recommendations['immediate_actions'].append(
                    f"Correct {alert['type']} - current value: {alert['value']}"
                )
        
        # Optimization suggestions
        if 'optimal_parameters' in optimization:
            for param, value in optimization['optimal_parameters'].items():
                recommendations['optimization_suggestions'].append(
                    f"Adjust {param} to {value:.2f} for optimal performance"
                )
        
        # Monitoring alerts based on predictions
        if 'risk' in predictions and predictions['risk']['level'] != 'low':
            recommendations['monitoring_alerts'].append(
                f"Elevated risk level detected: {predictions['risk']['level']}"
            )
        
        # Long-term planning
        if 'expected_improvements' in optimization:
            improvements = optimization['expected_improvements']
            if improvements.get('deviation_reduction', 0) > 5:
                recommendations['long_term_planning'].append(
                    "Implement systematic steering optimization for improved alignment"
                )
        
        return recommendations
    
    def start_real_time_monitoring(self, data_source_callback, interval: float = 1.0):
        """Start real-time monitoring with continuous optimization"""
        
        def monitoring_loop():
            while self.is_monitoring:
                try:
                    # Get current data from callback
                    current_data = data_source_callback()
                    
                    # Perform real-time analysis
                    anomaly_result = self.real_time_anomaly_detection(current_data)
                    
                    # Log significant events
                    if anomaly_result.get('status') == 'alerts_detected':
                        print(f"[{datetime.now()}] ALERTS DETECTED: {len(anomaly_result.get('anomalies', []))}")
                    
                    # Store optimization history
                    self.optimization_history.append({
                        'timestamp': datetime.now(),
                        'data': current_data,
                        'analysis': anomaly_result
                    })
                    
                    # Maintain history limit
                    if len(self.optimization_history) > 1000:
                        self.optimization_history = self.optimization_history[-500:]
                    
                    time.sleep(interval)
                    
                except Exception as e:
                    print(f"Error in monitoring loop: {e}")
                    time.sleep(interval)
        
        self.is_monitoring = True
        self.monitoring_thread = threading.Thread(target=monitoring_loop)
        self.monitoring_thread.daemon = True
        self.monitoring_thread.start()
        
        print("Real-time monitoring started")
    
    def stop_real_time_monitoring(self):
        """Stop real-time monitoring"""
        self.is_monitoring = False
        if self.monitoring_thread:
            self.monitoring_thread.join(timeout=5)
        print("Real-time monitoring stopped")
    
    def export_optimization_history(self, output_path: str = 'mtbm_optimization_history.json'):
        """Export optimization history to JSON file"""
        
        # Convert datetime objects to strings for JSON serialization
        export_data = []
        for entry in self.optimization_history:
            export_entry = {
                'timestamp': entry['timestamp'].isoformat(),
                'data': entry['data'],
                'analysis': entry['analysis']
            }
            # Convert nested datetime objects
            if 'analysis' in export_entry and 'timestamp' in export_entry['analysis']:
                if isinstance(export_entry['analysis']['timestamp'], str):
                    pass  # Already converted
                else:
                    export_entry['analysis']['timestamp'] = export_entry['analysis']['timestamp'].isoformat()
            
            export_data.append(export_entry)
        
        with open(output_path, 'w') as f:
            json.dump(export_data, f, indent=2, default=str)
        
        print(f"Optimization history exported to {output_path}")


# Example usage demonstration
def demo_real_time_optimizer():
    """Demonstrate the real-time optimization system"""
    
    print("MTBM Real-Time Optimization System Demo")
    print("="*50)
    
    # This would normally be connected to your base ML framework
    # For demo purposes, we'll create a mock framework
    class MockMLFramework:
        def comprehensive_predict(self, data):
            return {
                'steering': {
                    'required_horizontal_correction': np.random.normal(0, 5),
                    'required_vertical_correction': np.random.normal(0, 5),
                    'expected_deviation_improvement': np.random.normal(2, 1)
                },
                'efficiency': {
                    'efficiency_improvement': np.random.normal(0.1, 0.05)
                },
                'risk': {
                    'level': np.random.choice(['low', 'medium', 'high'], p=[0.7, 0.2, 0.1])
                }
            }
    
    # Initialize optimizer
    mock_framework = MockMLFramework()
    optimizer = MTBMRealTimeOptimizer(mock_framework)
    
    # Example current state
    current_state = {
        'tunnel_length': 150.5,
        'hor_dev_machine': 12,
        'vert_dev_machine': -8,
        'total_deviation_machine': 14.4,
        'advance_speed': 45.2,
        'working_pressure': 180,
        'revolution_rpm': 8.5,
        'total_force': 850,
        'earth_pressure': 120,
        'sc_cyl_01': 25,
        'sc_cyl_02': 30,
        'sc_cyl_03': 28,
        'sc_cyl_04': 32
    }
    
    # Demonstrate multi-objective optimization
    print("Performing multi-objective optimization...")
    optimization_result = optimizer.multi_objective_optimization(current_state)
    print("Optimization Result:")
    for key, value in optimization_result.items():
        if key != 'expected_improvements':
            print(f"  {key}: {value}")
    
    # Demonstrate anomaly detection
    print("\nTesting anomaly detection...")
    anomaly_result = optimizer.real_time_anomaly_detection(current_state)
    print(f"Anomaly Detection Status: {anomaly_result['status']}")
    
    # Create mock historical data for adaptive tuning
    dates = pd.date_range(start='2023-01-01', periods=100, freq='H')
    historical_data = pd.DataFrame({
        'advance_speed': np.random.normal(45, 10, 100),
        'working_pressure': np.random.normal(180, 20, 100),
        'revolution_rpm': np.random.normal(8.5, 1, 100),
        'earth_pressure': np.random.normal(120, 15, 100),
        'cutting_efficiency': np.random.normal(0.5, 0.1, 100),
        'total_deviation_machine': np.random.normal(15, 5, 100)
    })
    
    # Demonstrate adaptive parameter tuning
    print("\nPerforming adaptive parameter tuning...")
    adaptive_result = optimizer.adaptive_parameter_tuning(historical_data)
    if 'optimal_parameters' in adaptive_result:
        print("Adaptive Tuning Results:")
        for param, value in adaptive_result['optimal_parameters'].items():
            print(f"  {param}: {value:.2f}")
    
    # Demonstrate predictive maintenance
    print("\nAnalyzing predictive maintenance indicators...")
    maintenance_result = optimizer.predictive_maintenance_analysis(historical_data)
    print(f"Overall Health Score: {maintenance_result.get('overall_health_score', 'N/A')}")
    
    # Generate comprehensive report
    print("\nGenerating comprehensive optimization report...")
    report = optimizer.generate_optimization_report(current_state, historical_data)
    
    print("\nKey Recommendations:")
    for category, recommendations in report['recommendations'].items():
        if recommendations:
            print(f"  {category.upper()}:")
            for rec in recommendations:
                print(f"    • {rec}")
    
    return optimizer

if __name__ == "__main__":
    optimizer = demo_real_time_optimizer()