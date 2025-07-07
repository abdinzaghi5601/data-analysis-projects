create database Feedback;	
use feedback;

CREATE TABLE survey_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    delivery_satisfaction INT,
    food_quality_satisfaction int,
    delivery_time_satisfaction INT,
    order_accuracy varchar(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

use feedback; 

Select * from survey_data;

select distinct(order_accuracy) from survey_data;

 show columns from survey_data;
 
 -- Identify records with missing feedback
SELECT COUNT(*) 
FROM survey_data 
WHERE delivery_satisfaction IS NULL 
   OR food_quality_satisfaction IS NULL 
   OR delivery_time_satisfaction IS NULL;
   
   
   -- Basic distribution analysis (including blanks)
SELECT 
    COALESCE(order_accuracy, 'blank') AS accuracy_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM survey_data
GROUP BY accuracy_status;


UPDATE survey_data
SET order_accuracy = CASE
    WHEN delivery_satisfaction >= 4 THEN 'yes' -- High satisfaction likely accurate
    WHEN food_quality_satisfaction <= 2 THEN 'no' -- Low food quality may indicate inaccuracy
    ELSE 'no' -- Default to no
END
WHERE order_accuracy IS NULL OR order_accuracy = '';
 
 -- Basic customer distribution (if you had a region column, you would GROUP BY region)
SELECT 
    COUNT(*) AS total_customers,
    AVG(delivery_satisfaction) AS avg_delivery_satisfaction,
    AVG(food_quality_satisfaction) AS avg_food_quality,
    AVG(delivery_time_satisfaction) AS avg_delivery_time_satisfaction
FROM survey_data;


-- Delivery experience ratings distribution
SELECT 
    delivery_satisfaction AS rating,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM survey_data
GROUP BY delivery_satisfaction
ORDER BY count DESC;

-- Food quality ratings distribution
SELECT 
    food_quality_satisfaction AS rating,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM survey_data
GROUP BY food_quality_satisfaction
ORDER BY count DESC;

-- Delivery speed ratings distribution
SELECT 
    delivery_time_satisfaction AS rating,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM survey_data
GROUP BY delivery_time_satisfaction
ORDER BY count DESC;


-- Satisfaction metrics by order accuracy
SELECT 
    order_accuracy,
    COUNT(*) AS order_count,
    AVG(delivery_satisfaction) AS avg_delivery_satisfaction,
    AVG(food_quality_satisfaction) AS avg_food_quality,
    AVG(delivery_time_satisfaction) AS avg_delivery_time_satisfaction
FROM survey_data
GROUP BY order_accuracy
ORDER BY order_accuracy;

-- Statistical significance test (simple version)
SELECT 
    order_accuracy,
    AVG(delivery_satisfaction) AS avg_score,
    VARIANCE(delivery_satisfaction) AS variance
FROM survey_data
GROUP BY order_accuracy;


-- Food quality vs delivery speed correlation
SELECT 
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
    2) AS correlation_coefficient
FROM survey_data;

-- Delivery time vs delivery satisfaction
SELECT 
    delivery_time_satisfaction,
    AVG(delivery_satisfaction) AS avg_overall_delivery_satisfaction,
    COUNT(*) AS count
FROM survey_data
GROUP BY delivery_time_satisfaction
ORDER BY delivery_time_satisfaction;


-- Weekly satisfaction trends
SELECT 
    DATE_FORMAT(created_at, '%Y-%u') AS week,
    AVG(delivery_satisfaction) AS avg_delivery,
    AVG(food_quality_satisfaction) AS avg_food,
    AVG(delivery_time_satisfaction) AS avg_delivery_time,
    COUNT(*) AS order_count
FROM survey_data
GROUP BY week
ORDER BY week;

-- Hourly patterns
SELECT 
    HOUR(created_at) AS hour_of_day,
    AVG(delivery_satisfaction) AS avg_delivery_satisfaction,
    COUNT(*) AS order_count
FROM survey_data
GROUP BY hour_of_day
ORDER BY hour_of_day;

use feedback;
show columns from survey_data;

select * from survey_data;


-- Create a view for dashboard analysis
CREATE VIEW customer_satisfaction_analysis AS
SELECT 
    id,
    delivery_satisfaction,
    food_quality_satisfaction,
    delivery_time_satisfaction,
    order_accuracy,
    
    CASE 
        WHEN delivery_satisfaction >= 4 THEN 'High'
        WHEN delivery_satisfaction >= 2 THEN 'Medium'
        ELSE 'Low'
    END AS delivery_satisfaction_level,
    CASE 
        WHEN food_quality_satisfaction >= 4 THEN 'High'
        WHEN food_quality_satisfaction >= 2 THEN 'Medium'
        ELSE 'Low'
    END AS food_quality_level
FROM survey_data;


select * from customer_satisfaction_analysis;
-- Most Common Delivery Issues

SELECT 
    delivery_satisfaction_level,
    COUNT(*) AS responses,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM survey_data), 1) AS percentage
FROM customer_satisfaction_analysis
GROUP BY delivery_satisfaction_level;




SELECT 
    (
        SUM((food_quality_satisfaction - avg_food) * (delivery_time_satisfaction - avg_delivery)) / 
        (COUNT(*) * STDDEV_POP(food_quality_satisfaction) * STDDEV_POP(delivery_time_satisfaction))
    ) AS correlation_coefficient
FROM 
    customer_satisfaction_analysis,
    (
        SELECT 
            AVG(food_quality_satisfaction) AS avg_food,
            AVG(delivery_time_satisfaction) AS avg_delivery
        FROM customer_satisfaction_analysis
    ) AS averages;