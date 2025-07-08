-- =====================================================
-- CUSTOMER SATISFACTION ANALYSIS PROJECT - KASHMIR CAFE
-- SQL Script for Data Processing & Business Intelligence
-- =====================================================

CREATE DATABASE IF NOT EXISTS Feedback;	
USE feedback;

-- Task 01: Database Setup & Table Structure
-- =====================================================

-- Create customer satisfaction survey table
CREATE TABLE IF NOT EXISTS survey_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    delivery_satisfaction INT CHECK (delivery_satisfaction BETWEEN 1 AND 5),
    food_quality_satisfaction INT CHECK (food_quality_satisfaction BETWEEN 1 AND 5),
    delivery_time_satisfaction INT CHECK (delivery_time_satisfaction BETWEEN 1 AND 5),
    order_accuracy VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_delivery_satisfaction (delivery_satisfaction),
    INDEX idx_food_quality (food_quality_satisfaction),
    INDEX idx_delivery_time (delivery_time_satisfaction),
    INDEX idx_created_at (created_at)
);

-- Display table structure
SHOW COLUMNS FROM survey_data;

-- Verify data import
SELECT 
    'Data Import Verification' AS analysis_type,
    COUNT(*) AS total_records,
    COUNT(DISTINCT id) AS unique_records,
    MIN(created_at) AS earliest_feedback,
    MAX(created_at) AS latest_feedback
FROM survey_data;

-- Check distinct order accuracy values
SELECT DISTINCT(order_accuracy) AS accuracy_values FROM survey_data;
 
-- Task 02: Data Quality Assessment & Cleaning
-- =====================================================

-- 1. Comprehensive data quality assessment
SELECT 
    'Data Quality Assessment' AS analysis_type,
    COUNT(*) AS total_records,
    SUM(CASE WHEN delivery_satisfaction IS NULL THEN 1 ELSE 0 END) AS missing_delivery_satisfaction,
    SUM(CASE WHEN food_quality_satisfaction IS NULL THEN 1 ELSE 0 END) AS missing_food_quality,
    SUM(CASE WHEN delivery_time_satisfaction IS NULL THEN 1 ELSE 0 END) AS missing_delivery_time,
    SUM(CASE WHEN order_accuracy IS NULL OR order_accuracy = '' THEN 1 ELSE 0 END) AS missing_order_accuracy,
    SUM(CASE WHEN delivery_satisfaction NOT BETWEEN 1 AND 5 THEN 1 ELSE 0 END) AS invalid_delivery_ratings,
    SUM(CASE WHEN food_quality_satisfaction NOT BETWEEN 1 AND 5 THEN 1 ELSE 0 END) AS invalid_food_ratings,
    SUM(CASE WHEN delivery_time_satisfaction NOT BETWEEN 1 AND 5 THEN 1 ELSE 0 END) AS invalid_time_ratings
FROM survey_data;

-- 2. Order accuracy distribution analysis (including blanks)
SELECT 
    'Order Accuracy Distribution' AS analysis_type,
    COALESCE(order_accuracy, 'blank') AS accuracy_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM survey_data
GROUP BY accuracy_status
ORDER BY count DESC;

-- 3. Data cleaning - Handle missing order accuracy values
UPDATE survey_data
SET order_accuracy = CASE
    WHEN delivery_satisfaction >= 4 AND food_quality_satisfaction >= 4 THEN 'yes' -- High satisfaction likely accurate
    WHEN food_quality_satisfaction <= 2 OR delivery_satisfaction <= 2 THEN 'no' -- Poor experience likely inaccurate
    WHEN delivery_time_satisfaction <= 2 THEN 'no' -- Poor delivery time may indicate issues
    ELSE 'no' -- Default to no for neutral cases
END
WHERE order_accuracy IS NULL OR order_accuracy = '';

-- 4. Verify data cleaning results
SELECT 
    'Post-Cleaning Verification' AS analysis_type,
    order_accuracy,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM survey_data
GROUP BY order_accuracy;
 
-- Task 03: Exploratory Data Analysis (EDA)
-- =====================================================

-- 1. Overall customer satisfaction metrics
SELECT 
    'Overall Customer Satisfaction Metrics' AS analysis_type,
    COUNT(*) AS total_customers,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_delivery_satisfaction,
    ROUND(AVG(food_quality_satisfaction), 2) AS avg_food_quality,
    ROUND(AVG(delivery_time_satisfaction), 2) AS avg_delivery_time_satisfaction,
    ROUND(STDDEV(delivery_satisfaction), 2) AS delivery_satisfaction_stddev,
    ROUND(STDDEV(food_quality_satisfaction), 2) AS food_quality_stddev,
    ROUND(STDDEV(delivery_time_satisfaction), 2) AS delivery_time_stddev
FROM survey_data;

-- 2. Detailed satisfaction level distribution analysis
-- Delivery experience ratings distribution
SELECT 
    'Delivery Experience Distribution' AS analysis_type,
    delivery_satisfaction AS rating,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage,
    CASE 
        WHEN delivery_satisfaction >= 4 THEN 'High Satisfaction'
        WHEN delivery_satisfaction >= 3 THEN 'Moderate Satisfaction'
        WHEN delivery_satisfaction >= 2 THEN 'Low Satisfaction'
        ELSE 'Very Low Satisfaction'
    END AS satisfaction_category
FROM survey_data
GROUP BY delivery_satisfaction, satisfaction_category
ORDER BY delivery_satisfaction DESC;

-- Food quality ratings distribution
SELECT 
    'Food Quality Distribution' AS analysis_type,
    food_quality_satisfaction AS rating,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage,
    CASE 
        WHEN food_quality_satisfaction >= 4 THEN 'High Quality'
        WHEN food_quality_satisfaction >= 3 THEN 'Moderate Quality'
        WHEN food_quality_satisfaction >= 2 THEN 'Low Quality'
        ELSE 'Very Low Quality'
    END AS quality_category
FROM survey_data
GROUP BY food_quality_satisfaction, quality_category
ORDER BY food_quality_satisfaction DESC;

-- Delivery speed ratings distribution
SELECT 
    'Delivery Speed Distribution' AS analysis_type,
    delivery_time_satisfaction AS rating,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage,
    CASE 
        WHEN delivery_time_satisfaction >= 4 THEN 'Fast Delivery'
        WHEN delivery_time_satisfaction >= 3 THEN 'Moderate Speed'
        WHEN delivery_time_satisfaction >= 2 THEN 'Slow Delivery'
        ELSE 'Very Slow Delivery'
    END AS speed_category
FROM survey_data
GROUP BY delivery_time_satisfaction, speed_category
ORDER BY delivery_time_satisfaction DESC;

-- 3. Customer satisfaction segmentation analysis
SELECT 
    'Customer Satisfaction Segmentation' AS analysis_type,
    CASE 
        WHEN delivery_satisfaction >= 4 AND food_quality_satisfaction >= 4 AND delivery_time_satisfaction >= 4 THEN 'Highly Satisfied'
        WHEN delivery_satisfaction >= 3 AND food_quality_satisfaction >= 3 AND delivery_time_satisfaction >= 3 THEN 'Satisfied'
        WHEN delivery_satisfaction >= 2 AND food_quality_satisfaction >= 2 AND delivery_time_satisfaction >= 2 THEN 'Neutral'
        ELSE 'Dissatisfied'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM survey_data
GROUP BY customer_segment
ORDER BY customer_count DESC;


-- Task 04: Business Intelligence & Impact Analysis
-- =====================================================

-- 1. Order accuracy impact on customer satisfaction
SELECT 
    'Order Accuracy Impact Analysis' AS analysis_type,
    order_accuracy,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage_of_orders,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_delivery_satisfaction,
    ROUND(AVG(food_quality_satisfaction), 2) AS avg_food_quality,
    ROUND(AVG(delivery_time_satisfaction), 2) AS avg_delivery_time_satisfaction,
    ROUND((AVG(delivery_satisfaction) + AVG(food_quality_satisfaction) + AVG(delivery_time_satisfaction)) / 3, 2) AS overall_satisfaction_score
FROM survey_data
GROUP BY order_accuracy
ORDER BY order_accuracy;

-- 2. Statistical significance analysis
SELECT 
    'Statistical Analysis by Order Accuracy' AS analysis_type,
    order_accuracy,
    COUNT(*) AS sample_size,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_delivery_score,
    ROUND(STDDEV(delivery_satisfaction), 2) AS delivery_stddev,
    ROUND(VARIANCE(delivery_satisfaction), 2) AS delivery_variance,
    ROUND(AVG(food_quality_satisfaction), 2) AS avg_food_score,
    ROUND(STDDEV(food_quality_satisfaction), 2) AS food_stddev
FROM survey_data
GROUP BY order_accuracy;

-- 3. Customer retention risk analysis
SELECT 
    'Customer Retention Risk Analysis' AS analysis_type,
    CASE 
        WHEN delivery_satisfaction <= 2 OR food_quality_satisfaction <= 2 OR delivery_time_satisfaction <= 2 THEN 'High Risk'
        WHEN delivery_satisfaction = 3 AND food_quality_satisfaction = 3 AND delivery_time_satisfaction = 3 THEN 'Medium Risk'
        WHEN delivery_satisfaction >= 4 OR food_quality_satisfaction >= 4 OR delivery_time_satisfaction >= 4 THEN 'Low Risk'
        ELSE 'Moderate Risk'
    END AS retention_risk,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_delivery,
    ROUND(AVG(food_quality_satisfaction), 2) AS avg_food,
    ROUND(AVG(delivery_time_satisfaction), 2) AS avg_delivery_time
FROM survey_data
GROUP BY retention_risk
ORDER BY 
    CASE retention_risk 
        WHEN 'High Risk' THEN 1 
        WHEN 'Medium Risk' THEN 2 
        WHEN 'Moderate Risk' THEN 3 
        WHEN 'Low Risk' THEN 4 
    END;


-- Task 05: Correlation & Relationship Analysis
-- =====================================================

-- 1. Food quality vs delivery speed correlation
SELECT 
    'Food Quality vs Delivery Speed Correlation' AS analysis_type,
    ROUND(
        (
            COUNT(*) * SUM(food_quality_satisfaction * delivery_time_satisfaction) - 
            SUM(food_quality_satisfaction) * SUM(delivery_time_satisfaction)
        ) / 
        (
            SQRT(
                COUNT(*) * SUM(food_quality_satisfaction * food_quality_satisfaction) - 
                POW(SUM(food_quality_satisfaction), 2)
            ) * 
            SQRT(
                COUNT(*) * SUM(delivery_time_satisfaction * delivery_time_satisfaction) - 
                POW(SUM(delivery_time_satisfaction), 2)
            )
        ), 
    3) AS correlation_coefficient,
    CASE 
        WHEN ABS(
            (COUNT(*) * SUM(food_quality_satisfaction * delivery_time_satisfaction) - 
             SUM(food_quality_satisfaction) * SUM(delivery_time_satisfaction)) / 
            (SQRT(COUNT(*) * SUM(food_quality_satisfaction * food_quality_satisfaction) - 
                  POW(SUM(food_quality_satisfaction), 2)) * 
             SQRT(COUNT(*) * SUM(delivery_time_satisfaction * delivery_time_satisfaction) - 
                  POW(SUM(delivery_time_satisfaction), 2)))
        ) > 0.7 THEN 'Strong Correlation'
        WHEN ABS(
            (COUNT(*) * SUM(food_quality_satisfaction * delivery_time_satisfaction) - 
             SUM(food_quality_satisfaction) * SUM(delivery_time_satisfaction)) / 
            (SQRT(COUNT(*) * SUM(food_quality_satisfaction * food_quality_satisfaction) - 
                  POW(SUM(food_quality_satisfaction), 2)) * 
             SQRT(COUNT(*) * SUM(delivery_time_satisfaction * delivery_time_satisfaction) - 
                  POW(SUM(delivery_time_satisfaction), 2)))
        ) > 0.3 THEN 'Moderate Correlation'
        ELSE 'Weak Correlation'
    END AS correlation_strength
FROM survey_data;

-- 2. Delivery time impact on overall delivery satisfaction
SELECT 
    'Delivery Time Impact on Overall Satisfaction' AS analysis_type,
    delivery_time_satisfaction,
    COUNT(*) AS customer_count,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_overall_delivery_satisfaction,
    ROUND(STDDEV(delivery_satisfaction), 2) AS satisfaction_variability,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage_of_customers
FROM survey_data
GROUP BY delivery_time_satisfaction
ORDER BY delivery_time_satisfaction;

-- 3. Cross-dimensional satisfaction analysis
SELECT 
    'Cross-Dimensional Satisfaction Matrix' AS analysis_type,
    food_quality_satisfaction AS food_rating,
    delivery_time_satisfaction AS delivery_rating,
    COUNT(*) AS customer_count,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_overall_satisfaction,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM survey_data
GROUP BY food_quality_satisfaction, delivery_time_satisfaction
HAVING customer_count >= 5  -- Only show combinations with sufficient data
ORDER BY food_quality_satisfaction DESC, delivery_time_satisfaction DESC;

-- 4. Satisfaction correlation matrix
SELECT 
    'Satisfaction Correlation Matrix' AS analysis_type,
    'Delivery vs Food Quality' AS relationship_type,
    ROUND(
        (COUNT(*) * SUM(delivery_satisfaction * food_quality_satisfaction) - 
         SUM(delivery_satisfaction) * SUM(food_quality_satisfaction)) / 
        (SQRT(COUNT(*) * SUM(delivery_satisfaction * delivery_satisfaction) - 
              POW(SUM(delivery_satisfaction), 2)) * 
         SQRT(COUNT(*) * SUM(food_quality_satisfaction * food_quality_satisfaction) - 
              POW(SUM(food_quality_satisfaction), 2))), 3
    ) AS correlation_coefficient
FROM survey_data
UNION ALL
SELECT 
    'Satisfaction Correlation Matrix' AS analysis_type,
    'Delivery vs Delivery Time' AS relationship_type,
    ROUND(
        (COUNT(*) * SUM(delivery_satisfaction * delivery_time_satisfaction) - 
         SUM(delivery_satisfaction) * SUM(delivery_time_satisfaction)) / 
        (SQRT(COUNT(*) * SUM(delivery_satisfaction * delivery_satisfaction) - 
              POW(SUM(delivery_satisfaction), 2)) * 
         SQRT(COUNT(*) * SUM(delivery_time_satisfaction * delivery_time_satisfaction) - 
              POW(SUM(delivery_time_satisfaction), 2))), 3
    ) AS correlation_coefficient
FROM survey_data;


-- Task 06: Temporal Analysis & Trends
-- =====================================================

-- 1. Weekly satisfaction trends
SELECT 
    'Weekly Satisfaction Trends' AS analysis_type,
    DATE_FORMAT(created_at, '%Y-%u') AS week,
    COUNT(*) AS order_count,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_delivery,
    ROUND(AVG(food_quality_satisfaction), 2) AS avg_food,
    ROUND(AVG(delivery_time_satisfaction), 2) AS avg_delivery_time,
    ROUND((AVG(delivery_satisfaction) + AVG(food_quality_satisfaction) + AVG(delivery_time_satisfaction)) / 3, 2) AS overall_satisfaction
FROM survey_data
GROUP BY week
HAVING order_count >= 10  -- Only weeks with significant data
ORDER BY week;

-- 2. Daily patterns analysis
SELECT 
    'Daily Satisfaction Patterns' AS analysis_type,
    DAYNAME(created_at) AS day_of_week,
    DAYOFWEEK(created_at) AS day_number,
    COUNT(*) AS order_count,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_delivery_satisfaction,
    ROUND(AVG(food_quality_satisfaction), 2) AS avg_food_quality,
    ROUND(AVG(delivery_time_satisfaction), 2) AS avg_delivery_time,
    ROUND(STDDEV(delivery_satisfaction), 2) AS satisfaction_variability
FROM survey_data
GROUP BY day_of_week, day_number
ORDER BY day_number;

-- 3. Hourly patterns analysis
SELECT 
    'Hourly Satisfaction Patterns' AS analysis_type,
    HOUR(created_at) AS hour_of_day,
    COUNT(*) AS order_count,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_delivery_satisfaction,
    ROUND(AVG(food_quality_satisfaction), 2) AS avg_food_quality,
    ROUND(AVG(delivery_time_satisfaction), 2) AS avg_delivery_time,
    CASE 
        WHEN HOUR(created_at) BETWEEN 6 AND 10 THEN 'Breakfast'
        WHEN HOUR(created_at) BETWEEN 11 AND 14 THEN 'Lunch'
        WHEN HOUR(created_at) BETWEEN 15 AND 17 THEN 'Afternoon'
        WHEN HOUR(created_at) BETWEEN 18 AND 22 THEN 'Dinner'
        ELSE 'Late Night'
    END AS meal_period
FROM survey_data
GROUP BY hour_of_day, meal_period
HAVING order_count >= 5  -- Only hours with sufficient data
ORDER BY hour_of_day;

-- 4. Peak vs off-peak performance
SELECT 
    'Peak vs Off-Peak Analysis' AS analysis_type,
    CASE 
        WHEN HOUR(created_at) BETWEEN 11 AND 14 OR HOUR(created_at) BETWEEN 18 AND 21 THEN 'Peak Hours'
        ELSE 'Off-Peak Hours'
    END AS time_category,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage_of_orders,
    ROUND(AVG(delivery_satisfaction), 2) AS avg_delivery_satisfaction,
    ROUND(AVG(food_quality_satisfaction), 2) AS avg_food_quality,
    ROUND(AVG(delivery_time_satisfaction), 2) AS avg_delivery_time
FROM survey_data
GROUP BY time_category;


-- Task 07: Views & Dashboard Integration
-- =====================================================

-- Create comprehensive view for dashboard analysis
CREATE OR REPLACE VIEW customer_satisfaction_analysis AS
SELECT 
    id,
    delivery_satisfaction,
    food_quality_satisfaction,
    delivery_time_satisfaction,
    order_accuracy,
    created_at,
    
    -- Satisfaction level categorization
    CASE 
        WHEN delivery_satisfaction >= 4 THEN 'High'
        WHEN delivery_satisfaction >= 2 THEN 'Medium'
        ELSE 'Low'
    END AS delivery_satisfaction_level,
    
    CASE 
        WHEN food_quality_satisfaction >= 4 THEN 'High'
        WHEN food_quality_satisfaction >= 2 THEN 'Medium'
        ELSE 'Low'
    END AS food_quality_level,
    
    CASE 
        WHEN delivery_time_satisfaction >= 4 THEN 'High'
        WHEN delivery_time_satisfaction >= 2 THEN 'Medium'
        ELSE 'Low'
    END AS delivery_time_level,
    
    -- Overall satisfaction score
    ROUND((delivery_satisfaction + food_quality_satisfaction + delivery_time_satisfaction) / 3, 2) AS overall_satisfaction_score,
    
    -- Customer segment
    CASE 
        WHEN delivery_satisfaction >= 4 AND food_quality_satisfaction >= 4 AND delivery_time_satisfaction >= 4 THEN 'Highly Satisfied'
        WHEN delivery_satisfaction >= 3 AND food_quality_satisfaction >= 3 AND delivery_time_satisfaction >= 3 THEN 'Satisfied'
        WHEN delivery_satisfaction >= 2 AND food_quality_satisfaction >= 2 AND delivery_time_satisfaction >= 2 THEN 'Neutral'
        ELSE 'Dissatisfied'
    END AS customer_segment,
    
    -- Time-based attributes
    HOUR(created_at) AS hour_of_day,
    DAYNAME(created_at) AS day_of_week,
    DATE_FORMAT(created_at, '%Y-%m') AS year_month,
    
    -- Meal period classification
    CASE 
        WHEN HOUR(created_at) BETWEEN 6 AND 10 THEN 'Breakfast'
        WHEN HOUR(created_at) BETWEEN 11 AND 14 THEN 'Lunch'
        WHEN HOUR(created_at) BETWEEN 15 AND 17 THEN 'Afternoon'
        WHEN HOUR(created_at) BETWEEN 18 AND 22 THEN 'Dinner'
        ELSE 'Late Night'
    END AS meal_period
FROM survey_data;

-- Task 08: Final Business Intelligence Queries
-- =====================================================

-- 1. Customer satisfaction distribution summary (for CSV export)
SELECT 
    'Customer Satisfaction Distribution Summary' AS report_type,
    delivery_satisfaction_level,
    COUNT(*) AS responses,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM customer_satisfaction_analysis
GROUP BY delivery_satisfaction_level
ORDER BY 
    CASE delivery_satisfaction_level 
        WHEN 'High' THEN 1 
        WHEN 'Medium' THEN 2 
        WHEN 'Low' THEN 3 
    END;

-- 2. Executive dashboard summary
SELECT 
    'Executive Dashboard Summary' AS report_type,
    COUNT(*) AS total_feedback_responses,
    ROUND(AVG(overall_satisfaction_score), 2) AS average_satisfaction_score,
    SUM(CASE WHEN customer_segment = 'Highly Satisfied' THEN 1 ELSE 0 END) AS highly_satisfied_customers,
    SUM(CASE WHEN customer_segment = 'Dissatisfied' THEN 1 ELSE 0 END) AS dissatisfied_customers,
    ROUND(SUM(CASE WHEN customer_segment = 'Highly Satisfied' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS high_satisfaction_rate,
    ROUND(SUM(CASE WHEN customer_segment = 'Dissatisfied' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS dissatisfaction_rate,
    ROUND(SUM(CASE WHEN order_accuracy = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS order_accuracy_rate
FROM customer_satisfaction_analysis;

-- 3. Key performance indicators
SELECT 
    'Key Performance Indicators' AS report_type,
    'Delivery Satisfaction' AS metric,
    ROUND(AVG(delivery_satisfaction), 2) AS average_score,
    ROUND(STDDEV(delivery_satisfaction), 2) AS score_variability
FROM survey_data
UNION ALL
SELECT 
    'Key Performance Indicators' AS report_type,
    'Food Quality' AS metric,
    ROUND(AVG(food_quality_satisfaction), 2) AS average_score,
    ROUND(STDDEV(food_quality_satisfaction), 2) AS score_variability
FROM survey_data
UNION ALL
SELECT 
    'Key Performance Indicators' AS report_type,
    'Delivery Speed' AS metric,
    ROUND(AVG(delivery_time_satisfaction), 2) AS average_score,
    ROUND(STDDEV(delivery_time_satisfaction), 2) AS score_variability
FROM survey_data;

-- 4. Business recommendations query
SELECT 
    'Business Recommendations' AS report_type,
    'Priority Action Items' AS category,
    CONCAT('Focus on ', 
           CASE 
               WHEN (SELECT AVG(delivery_satisfaction) FROM survey_data) < 
                    (SELECT AVG(food_quality_satisfaction) FROM survey_data) AND
                    (SELECT AVG(delivery_satisfaction) FROM survey_data) < 
                    (SELECT AVG(delivery_time_satisfaction) FROM survey_data) 
               THEN 'delivery satisfaction improvement'
               WHEN (SELECT AVG(food_quality_satisfaction) FROM survey_data) < 
                    (SELECT AVG(delivery_time_satisfaction) FROM survey_data)
               THEN 'food quality enhancement'
               ELSE 'delivery time optimization'
           END) AS recommendation,
    ROUND((SELECT COUNT(*) FROM survey_data WHERE delivery_satisfaction <= 2 OR 
           food_quality_satisfaction <= 2 OR delivery_time_satisfaction <= 2) * 100.0 / 
          (SELECT COUNT(*) FROM survey_data), 1) AS at_risk_customers_percentage;

-- Display view contents for verification
SELECT 'View Verification' AS check_type, COUNT(*) AS total_records FROM customer_satisfaction_analysis;