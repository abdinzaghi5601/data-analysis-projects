-- =====================================================
-- AIRLINE PERFORMANCE ANALYSIS PROJECT
-- SQL Script for Data Preprocessing & Analysis
-- =====================================================

USE airline_data;

-- Task 01: Data Preprocessing & SQL Setup
-- =====================================================

-- 1. Create structured table and define primary keys
-- Verify table structure
SHOW COLUMNS FROM airlinedata;

-- Add primary key if not exists
-- ALTER TABLE airlinedata ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- 2. Check for missing values and data quality
SELECT 
    'Data Quality Assessment' AS analysis_type,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN DepTime IS NULL THEN 1 ELSE 0 END) AS missing_dep_time,
    SUM(CASE WHEN ArrTime IS NULL THEN 1 ELSE 0 END) AS missing_arr_time,
    SUM(CASE WHEN ArrDelay IS NULL THEN 1 ELSE 0 END) AS missing_arr_delays,
    SUM(CASE WHEN DepDelay IS NULL THEN 1 ELSE 0 END) AS missing_dep_delays,
    SUM(CASE WHEN UniqueCarrier IS NULL THEN 1 ELSE 0 END) AS missing_carrier,
    SUM(CASE WHEN Origin IS NULL THEN 1 ELSE 0 END) AS missing_origin,
    SUM(CASE WHEN Dest IS NULL THEN 1 ELSE 0 END) AS missing_destination
FROM airlinedata;

-- 3. Format date and time fields (convert string to proper datetime)
ALTER TABLE airlinedata
ADD COLUMN formatted_flightdate DATE,
ADD COLUMN formatted_departure DATETIME,
ADD COLUMN formatted_arrival DATETIME;

-- Clean time format anomalies first
UPDATE airlinedata
SET 
    DepartureTime = REPLACE(DepartureTime, '24:', '00:'),
    ArrivalTime = REPLACE(ArrivalTime, '24:', '00:')
WHERE DepartureTime LIKE '24:%' OR ArrivalTime LIKE '24:%';

-- Convert to proper datetime format
UPDATE airlinedata
SET 
    formatted_flightdate = STR_TO_DATE(FlightDate, '%Y-%m-%d'),
    formatted_departure = STR_TO_DATE(CONCAT(FlightDate, ' ', DepartureTime), '%Y-%m-%d %H:%i:%s'),
    formatted_arrival = STR_TO_DATE(CONCAT(FlightDate, ' ', ArrivalTime), '%Y-%m-%d %H:%i:%s');

-- 4. Remove duplicates (if any)
-- Check for duplicate records
SELECT 
    FlightDate, UniqueCarrier, Origin, Dest, DepartureTime, COUNT(*) as duplicate_count
FROM airlinedata
GROUP BY FlightDate, UniqueCarrier, Origin, Dest, DepartureTime
HAVING COUNT(*) > 1;

-- Task 02: Exploratory Data Analysis (EDA) Using SQL
-- =====================================================

-- 1. Calculate key performance metrics
-- Total number of flights
SELECT 
    'Flight Volume Metrics' AS metric_type,
    COUNT(*) AS total_flights,
    COUNT(DISTINCT UniqueCarrier) AS total_carriers,
    COUNT(DISTINCT Origin) AS total_origin_airports,
    COUNT(DISTINCT Dest) AS total_destination_airports,
    MIN(formatted_flightdate) AS earliest_date,
    MAX(formatted_flightdate) AS latest_date
FROM airlinedata;

-- 2. Average delay time and performance by carrier
SELECT 
    'Carrier Performance Analysis' AS analysis_type,
    UniqueCarrier,
    COUNT(*) AS total_flights,
    AVG(ArrDelay) AS avg_arrival_delay,
    AVG(DepDelay) AS avg_departure_delay,
    STDDEV(ArrDelay) AS delay_variability,
    MIN(ArrDelay) AS best_performance,
    MAX(ArrDelay) AS worst_performance,
    SUM(CASE WHEN ArrDelay > 0 THEN 1 ELSE 0 END) AS delayed_flights,
    ROUND(SUM(CASE WHEN ArrDelay > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS delay_rate_percent,
    SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) AS cancellations,
    ROUND(SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate_percent
FROM airlinedata
GROUP BY UniqueCarrier
ORDER BY avg_arrival_delay DESC;

-- 3. Delay causes and performance categorization
SELECT 
    'Flight Performance Distribution' AS analysis_type,
    CASE 
        WHEN ArrDelay > 0 AND DepDelay > 0 THEN 'Both Delays'
        WHEN ArrDelay > 0 THEN 'Arrival Delay Only'
        WHEN DepDelay > 0 THEN 'Departure Delay Only'
        ELSE 'On Time'
    END AS delay_category,
    COUNT(*) AS flight_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata), 2) AS percentage
FROM airlinedata
GROUP BY delay_category
ORDER BY flight_count DESC;

-- Delay severity analysis
SELECT 
    'Delay Severity Analysis' AS analysis_type,
    CASE 
        WHEN ArrDelay <= 0 THEN 'On Time/Early'
        WHEN ArrDelay <= 15 THEN 'Minor Delay (1-15 min)'
        WHEN ArrDelay <= 60 THEN 'Moderate Delay (16-60 min)'
        WHEN ArrDelay <= 180 THEN 'Major Delay (61-180 min)'
        ELSE 'Severe Delay (>180 min)'
    END AS delay_severity,
    COUNT(*) AS flight_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata), 2) AS percentage,
    AVG(ArrDelay) AS avg_delay_in_category
FROM airlinedata
GROUP BY delay_severity
ORDER BY AVG(ArrDelay);


-- 4. Identify busiest airports and analyze delay trends
-- Top 10 busiest origin airports with performance metrics
SELECT 
    'Top Busiest Origin Airports' AS analysis_type,
    Origin,
    COUNT(*) AS departure_count,
    AVG(DepDelay) AS avg_departure_delay,
    STDDEV(DepDelay) AS delay_consistency,
    SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) AS significant_delays,
    SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) AS cancellations,
    ROUND(SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS significant_delay_rate
FROM airlinedata
GROUP BY Origin
ORDER BY departure_count DESC
LIMIT 10;

-- Top 10 busiest destination airports with performance metrics
SELECT 
    'Top Busiest Destination Airports' AS analysis_type,
    Dest,
    COUNT(*) AS arrival_count,
    AVG(ArrDelay) AS avg_arrival_delay,
    STDDEV(ArrDelay) AS delay_consistency,
    SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) AS significant_delays,
    ROUND(SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS significant_delay_rate
FROM airlinedata
GROUP BY Dest
ORDER BY arrival_count DESC
LIMIT 10;

-- High-traffic airport pairs with performance analysis
SELECT 
    'High-Traffic Routes Analysis' AS analysis_type,
    Origin,
    Dest,
    COUNT(*) AS flight_count,
    AVG(Distance) AS avg_distance,
    AVG(ArrDelay) AS avg_arrival_delay,
    AVG(DepDelay) AS avg_departure_delay,
    SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) AS significant_delays,
    ROUND(SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS significant_delay_rate
FROM airlinedata
GROUP BY Origin, Dest
HAVING flight_count >= 100
ORDER BY flight_count DESC
LIMIT 15;

-- 5. Temporal Analysis - Delay trends by various time dimensions
-- Delay trends by day of week
SELECT 
    'Weekly Delay Patterns' AS analysis_type,
    DayOfWeek,
    CASE DayOfWeek
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END AS day_name,
    COUNT(*) AS flight_count,
    AVG(ArrDelay) AS avg_arrival_delay,
    AVG(DepDelay) AS avg_departure_delay,
    SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) AS cancellations,
    ROUND(SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS significant_delay_rate
FROM airlinedata
GROUP BY DayOfWeek, day_name
ORDER BY avg_arrival_delay DESC;

-- Delay trends by month (seasonal patterns)
SELECT 
    'Monthly Seasonal Patterns' AS analysis_type,
    Month,
    CASE Month
        WHEN 1 THEN 'January' WHEN 2 THEN 'February' WHEN 3 THEN 'March'
        WHEN 4 THEN 'April' WHEN 5 THEN 'May' WHEN 6 THEN 'June'
        WHEN 7 THEN 'July' WHEN 8 THEN 'August' WHEN 9 THEN 'September'
        WHEN 10 THEN 'October' WHEN 11 THEN 'November' WHEN 12 THEN 'December'
    END AS month_name,
    COUNT(*) AS flight_count,
    AVG(ArrDelay) AS avg_arrival_delay,
    AVG(DepDelay) AS avg_departure_delay,
    STDDEV(ArrDelay) AS delay_variability,
    SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) AS cancellations
FROM airlinedata
GROUP BY Month, month_name
ORDER BY Month;

-- Delay trends by time of day (hourly patterns)
SELECT 
    'Hourly Performance Patterns' AS analysis_type,
    HOUR(formatted_departure) AS departure_hour,
    COUNT(*) AS flight_count,
    AVG(DepDelay) AS avg_departure_delay,
    AVG(ArrDelay) AS avg_arrival_delay,
    SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) AS significant_dep_delays,
    SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) AS significant_arr_delays,
    ROUND(SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS dep_delay_rate
FROM airlinedata
WHERE formatted_departure IS NOT NULL
GROUP BY departure_hour
ORDER BY departure_hour;

-- Peak hour analysis
SELECT 
    'Peak Hour Analysis' AS analysis_type,
    CASE 
        WHEN HOUR(formatted_departure) BETWEEN 6 AND 9 THEN 'Morning Peak (6-9 AM)'
        WHEN HOUR(formatted_departure) BETWEEN 10 AND 15 THEN 'Midday (10 AM-3 PM)'
        WHEN HOUR(formatted_departure) BETWEEN 16 AND 19 THEN 'Evening Peak (4-7 PM)'
        WHEN HOUR(formatted_departure) BETWEEN 20 AND 23 THEN 'Night (8-11 PM)'
        ELSE 'Late Night/Early Morning'
    END AS time_period,
    COUNT(*) AS flight_count,
    AVG(DepDelay) AS avg_departure_delay,
    AVG(ArrDelay) AS avg_arrival_delay,
    ROUND(SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS significant_delay_rate
FROM airlinedata
WHERE formatted_departure IS NOT NULL
GROUP BY time_period
ORDER BY AVG(ArrDelay) DESC;



-- 6. Cancellation Analysis
-- Cancellation reasons breakdown
SELECT 
    'Cancellation Analysis' AS analysis_type,
    CancellationCode,
    CASE CancellationCode
        WHEN 'A' THEN 'Carrier'
        WHEN 'B' THEN 'Weather'
        WHEN 'C' THEN 'National Air System'
        WHEN 'D' THEN 'Security'
        ELSE 'Unknown'
    END AS cancellation_reason,
    COUNT(*) AS cancellation_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata WHERE Cancelled = 1), 2) AS percentage_of_cancellations
FROM airlinedata
WHERE Cancelled = 1
GROUP BY CancellationCode, cancellation_reason
ORDER BY cancellation_count DESC;

-- Carrier-specific cancellation rates
SELECT 
    'Carrier Cancellation Performance' AS analysis_type,
    UniqueCarrier,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) AS cancellations,
    ROUND(SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate_percent
FROM airlinedata
GROUP BY UniqueCarrier
HAVING total_flights >= 100
ORDER BY cancellation_rate_percent DESC;

-- Task 03: Views for Power BI Integration
-- =====================================================

-- Create comprehensive view for dashboard integration
CREATE OR REPLACE VIEW dashboard_performance_summary AS
SELECT 
    UniqueCarrier,
    Origin,
    Dest,
    formatted_flightdate AS flight_date,
    YEAR(formatted_flightdate) AS year,
    MONTH(formatted_flightdate) AS month,
    DayOfWeek,
    HOUR(formatted_departure) AS departure_hour,
    ArrDelay AS arrival_delay,
    DepDelay AS departure_delay,
    Distance,
    Cancelled,
    CancellationCode,
    CASE 
        WHEN ArrDelay <= 0 THEN 'On Time'
        WHEN ArrDelay <= 15 THEN 'Minor Delay'
        WHEN ArrDelay <= 60 THEN 'Moderate Delay'
        ELSE 'Major Delay'
    END AS performance_status,
    CASE DayOfWeek
        WHEN 1 THEN 'Monday' WHEN 2 THEN 'Tuesday' WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday' WHEN 5 THEN 'Friday' WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END AS day_name,
    CASE 
        WHEN HOUR(formatted_departure) BETWEEN 6 AND 9 THEN 'Morning Peak'
        WHEN HOUR(formatted_departure) BETWEEN 10 AND 15 THEN 'Midday'
        WHEN HOUR(formatted_departure) BETWEEN 16 AND 19 THEN 'Evening Peak'
        ELSE 'Off Peak'
    END AS time_period
FROM airlinedata
WHERE formatted_flightdate IS NOT NULL;

-- Task 04: Business Intelligence Insights
-- =====================================================

-- Key insights for recommendations
-- Which airlines experience the highest delays?
SELECT 
    'Airlines with Highest Delays' AS insight_category,
    UniqueCarrier,
    AVG(ArrDelay) AS avg_delay,
    COUNT(*) AS flight_count,
    'Requires immediate intervention' AS recommendation
FROM airlinedata
GROUP BY UniqueCarrier
HAVING flight_count >= 500
ORDER BY avg_delay DESC
LIMIT 5;

-- Which airports have the most congestion?
SELECT 
    'Most Congested Airports' AS insight_category,
    Origin AS airport,
    COUNT(*) AS traffic_volume,
    AVG(DepDelay) AS avg_delay,
    'Infrastructure optimization needed' AS recommendation
FROM airlinedata
GROUP BY Origin
ORDER BY traffic_volume DESC, avg_delay DESC
LIMIT 5;

-- What are the primary causes of delays?
SELECT 
    'Primary Delay Causes' AS insight_category,
    CASE 
        WHEN ArrDelay > 0 AND DepDelay > 0 THEN 'Operational Issues'
        WHEN ArrDelay > 0 THEN 'Arrival Congestion'
        WHEN DepDelay > 0 THEN 'Departure Issues'
        ELSE 'On Schedule'
    END AS delay_cause,
    COUNT(*) AS occurrence_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata), 2) AS percentage
FROM airlinedata
GROUP BY delay_cause
ORDER BY occurrence_count DESC;

-- How do peak flight hours impact delays?
SELECT 
    'Peak Hour Impact on Delays' AS insight_category,
    CASE 
        WHEN HOUR(formatted_departure) BETWEEN 7 AND 9 THEN 'Morning Rush (7-9 AM)'
        WHEN HOUR(formatted_departure) BETWEEN 17 AND 19 THEN 'Evening Rush (5-7 PM)'
        ELSE 'Non-Peak Hours'
    END AS hour_category,
    COUNT(*) AS flight_count,
    AVG(ArrDelay) AS avg_delay,
    'Schedule optimization opportunity' AS recommendation
FROM airlinedata
WHERE formatted_departure IS NOT NULL
GROUP BY hour_category
ORDER BY avg_delay DESC;

-- Summary statistics for executive dashboard
SELECT 
    'Executive Summary Statistics' AS summary_type,
    COUNT(*) AS total_flights,
    COUNT(DISTINCT UniqueCarrier) AS total_carriers,
    COUNT(DISTINCT Origin) AS total_airports,
    ROUND(AVG(ArrDelay), 2) AS overall_avg_delay,
    ROUND(SUM(CASE WHEN ArrDelay <= 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS on_time_performance_percent,
    ROUND(SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate_percent
FROM airlinedata;