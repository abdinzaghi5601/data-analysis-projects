-- =====================================================
-- AIRLINE PERFORMANCE ANALYSIS PROJECT
-- SQL Script for Data Preprocessing & Analysis
-- =====================================================

CREATE DATABASE IF NOT EXISTS airline_performance;
USE airline_performance;

-- =====================================================
-- TASK 01: DATA PREPROCESSING & SQL SETUP
-- =====================================================
-- 
-- TASK DESCRIPTION: Load dataset into SQL, create structured table, clean data, format fields, remove duplicates
-- BUSINESS PURPOSE: Establish clean, structured foundation for airline performance analysis
-- EXPECTED OUTCOME: Properly structured and validated airline performance database

-- 1. Create structured table and define primary keys
CREATE TABLE IF NOT EXISTS airlinedata (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Year INT NOT NULL,
    Month INT NOT NULL,
    DayofMonth INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DepTime INT,
    ArrTime INT,
    UniqueCarrier VARCHAR(10) NOT NULL,
    FlightNum INT NOT NULL,
    TailNum VARCHAR(10),
    ActualElapsedTime INT,
    AirTime INT,
    ArrDelay INT,
    DepDelay INT,
    Origin VARCHAR(5) NOT NULL,
    Dest VARCHAR(5) NOT NULL,
    Distance INT,
    TaxiIn INT,
    TaxiOut INT,
    Cancelled BOOLEAN DEFAULT FALSE,
    CancellationCode VARCHAR(1),
    Diverted BOOLEAN DEFAULT FALSE,
    -- Additional formatted fields
    FlightDate DATE,
    DepartureTime TIME,
    ArrivalTime TIME,
    formatted_departure DATETIME,
    formatted_arrival DATETIME,
    INDEX idx_carrier (UniqueCarrier),
    INDEX idx_origin (Origin),
    INDEX idx_dest (Dest),
    INDEX idx_date (FlightDate),
    INDEX idx_performance (ArrDelay, DepDelay)
);

-- Load data from CSV file
-- LOAD DATA LOCAL INFILE 'Airline Performance Dataset.csv' 
-- INTO TABLE airlinedata (Year, Month, DayofMonth, DayOfWeek, DepTime, ArrTime, UniqueCarrier, FlightNum, TailNum, ActualElapsedTime, AirTime, ArrDelay, DepDelay, Origin, Dest, Distance, TaxiIn, TaxiOut, Cancelled, CancellationCode, Diverted)
-- FIELDS TERMINATED BY ',' 
-- OPTIONALLY ENCLOSED BY '"' 
-- LINES TERMINATED BY '\n' 
-- IGNORE 1 ROWS;

-- Verify table structure
SHOW COLUMNS FROM airlinedata;

-- 2. Check for missing or inconsistent data and clean using SQL queries
SELECT 
    'Data Quality Assessment' AS analysis_type,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN DepTime IS NULL OR DepTime = 0 THEN 1 ELSE 0 END) AS missing_dep_time,
    SUM(CASE WHEN ArrTime IS NULL OR ArrTime = 0 THEN 1 ELSE 0 END) AS missing_arr_time,
    SUM(CASE WHEN ArrDelay IS NULL THEN 1 ELSE 0 END) AS missing_arr_delays,
    SUM(CASE WHEN DepDelay IS NULL THEN 1 ELSE 0 END) AS missing_dep_delays,
    SUM(CASE WHEN UniqueCarrier IS NULL OR UniqueCarrier = '' THEN 1 ELSE 0 END) AS missing_carrier,
    SUM(CASE WHEN Origin IS NULL OR Origin = '' THEN 1 ELSE 0 END) AS missing_origin,
    SUM(CASE WHEN Dest IS NULL OR Dest = '' THEN 1 ELSE 0 END) AS missing_destination,
    SUM(CASE WHEN Distance IS NULL OR Distance <= 0 THEN 1 ELSE 0 END) AS invalid_distance
FROM airlinedata;

-- Data consistency validation
SELECT 
    'Data Consistency Validation' AS analysis_type,
    SUM(CASE WHEN ArrDelay < -60 THEN 1 ELSE 0 END) AS unrealistic_early_arrivals,
    SUM(CASE WHEN DepDelay < -60 THEN 1 ELSE 0 END) AS unrealistic_early_departures,
    SUM(CASE WHEN ArrDelay > 1440 THEN 1 ELSE 0 END) AS extreme_delays_over_24h,
    SUM(CASE WHEN Month < 1 OR Month > 12 THEN 1 ELSE 0 END) AS invalid_months,
    SUM(CASE WHEN DayOfWeek < 1 OR DayOfWeek > 7 THEN 1 ELSE 0 END) AS invalid_day_of_week,
    SUM(CASE WHEN DayofMonth < 1 OR DayofMonth > 31 THEN 1 ELSE 0 END) AS invalid_day_of_month
FROM airlinedata;

-- Clean inconsistent data
SET SQL_SAFE_UPDATES = 0;

-- Handle missing delay values (set to 0 if flight wasn't cancelled)
UPDATE airlinedata 
SET 
    ArrDelay = CASE WHEN ArrDelay IS NULL AND Cancelled = 0 THEN 0 ELSE ArrDelay END,
    DepDelay = CASE WHEN DepDelay IS NULL AND Cancelled = 0 THEN 0 ELSE DepDelay END;

-- Clean extreme outliers (delays over 24 hours set to reasonable maximum)
UPDATE airlinedata 
SET 
    ArrDelay = CASE WHEN ArrDelay > 1440 THEN 1440 ELSE ArrDelay END,
    DepDelay = CASE WHEN DepDelay > 1440 THEN 1440 ELSE DepDelay END;

-- Handle missing times for non-cancelled flights
UPDATE airlinedata 
SET 
    DepTime = CASE WHEN DepTime IS NULL AND Cancelled = 0 THEN 1200 ELSE DepTime END,
    ArrTime = CASE WHEN ArrTime IS NULL AND Cancelled = 0 THEN 1400 ELSE ArrTime END;

-- 3. Format date and time fields and convert to proper datetime
-- Create FlightDate from Year, Month, DayofMonth
UPDATE airlinedata
SET FlightDate = STR_TO_DATE(CONCAT(Year, '-', Month, '-', DayofMonth), '%Y-%m-%d')
WHERE FlightDate IS NULL;

-- Convert time integers to proper TIME format
-- DepTime and ArrTime are in HHMM format (e.g., 1435 = 14:35)
UPDATE airlinedata
SET 
    DepartureTime = TIME(STR_TO_DATE(LPAD(DepTime, 4, '0'), '%H%i')),
    ArrivalTime = TIME(STR_TO_DATE(LPAD(ArrTime, 4, '0'), '%H%i'))
WHERE DepTime IS NOT NULL AND ArrTime IS NOT NULL AND Cancelled = 0;

-- Create full datetime fields
UPDATE airlinedata
SET 
    formatted_departure = TIMESTAMP(FlightDate, DepartureTime),
    formatted_arrival = TIMESTAMP(FlightDate, ArrivalTime)
WHERE DepartureTime IS NOT NULL AND ArrivalTime IS NOT NULL AND Cancelled = 0;

-- Handle overnight flights (arrival next day)
UPDATE airlinedata
SET formatted_arrival = DATE_ADD(formatted_arrival, INTERVAL 1 DAY)
WHERE formatted_arrival < formatted_departure AND Cancelled = 0;

-- 4. Remove duplicates (if any)
-- Check for duplicate records
SELECT 
    'Duplicate Check' AS analysis_type,
    FlightDate, UniqueCarrier, FlightNum, Origin, Dest, DepTime, COUNT(*) as duplicate_count
FROM airlinedata
GROUP BY FlightDate, UniqueCarrier, FlightNum, Origin, Dest, DepTime
HAVING COUNT(*) > 1;

-- Remove duplicates keeping the first occurrence
DELETE t1 FROM airlinedata t1
INNER JOIN airlinedata t2 
WHERE 
    t1.id > t2.id AND
    t1.FlightDate = t2.FlightDate AND
    t1.UniqueCarrier = t2.UniqueCarrier AND
    t1.FlightNum = t2.FlightNum AND
    t1.Origin = t2.Origin AND
    t1.Dest = t2.Dest AND
    t1.DepTime = t2.DepTime;

-- Final data quality summary
SELECT 
    'Final Data Quality Summary' AS analysis_type,
    COUNT(*) AS total_clean_records,
    SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) AS cancelled_flights,
    SUM(CASE WHEN Cancelled = 0 THEN 1 ELSE 0 END) AS completed_flights,
    MIN(FlightDate) AS earliest_flight,
    MAX(FlightDate) AS latest_flight,
    COUNT(DISTINCT UniqueCarrier) AS total_carriers,
    COUNT(DISTINCT Origin) AS total_origin_airports,
    COUNT(DISTINCT Dest) AS total_destination_airports
FROM airlinedata;

-- =====================================================
-- TASK 02: EXPLORATORY DATA ANALYSIS (EDA) USING SQL
-- =====================================================
-- 
-- TASK DESCRIPTION: Calculate key performance metrics, identify busiest airports, analyze delay trends
-- BUSINESS PURPOSE: Understand flight operations, performance patterns, and identify optimization opportunities
-- EXPECTED OUTCOME: Comprehensive insights into airline performance, delays, and operational efficiency

-- 1. Calculate key performance metrics such as total number of flights, average delay time, and delay causes

-- Total number of flights and basic metrics
SELECT 
    'Flight Volume Metrics' AS metric_type,
    COUNT(*) AS total_flights,
    COUNT(DISTINCT UniqueCarrier) AS total_carriers,
    COUNT(DISTINCT Origin) AS total_origin_airports,
    COUNT(DISTINCT Dest) AS total_destination_airports,
    MIN(FlightDate) AS earliest_date,
    MAX(FlightDate) AS latest_date,
    COUNT(DISTINCT CONCAT(Origin, '-', Dest)) AS unique_routes
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

-- Delay causes analysis
SELECT 
    'Delay Causes Analysis' AS analysis_type,
    CASE 
        WHEN Cancelled = 1 THEN 'Flight Cancelled'
        WHEN ArrDelay > 0 AND DepDelay > 0 THEN 'Both Departure & Arrival Delays'
        WHEN ArrDelay > 0 AND DepDelay <= 0 THEN 'Arrival Delay Only (En-route issues)'
        WHEN DepDelay > 0 AND ArrDelay <= 0 THEN 'Departure Delay Only (Recovered in flight)'
        WHEN ArrDelay <= 0 AND DepDelay <= 0 THEN 'On Time Performance'
        ELSE 'Unknown'
    END AS delay_cause_category,
    COUNT(*) AS flight_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata), 2) AS percentage_of_total,
    ROUND(AVG(CASE WHEN ArrDelay IS NOT NULL THEN ArrDelay ELSE 0 END), 2) AS avg_arrival_delay,
    ROUND(AVG(CASE WHEN DepDelay IS NOT NULL THEN DepDelay ELSE 0 END), 2) AS avg_departure_delay
FROM airlinedata
GROUP BY delay_cause_category
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


-- 2. Identify the busiest airports and analyze delay trends

-- Top 10 busiest origin airports with performance metrics
SELECT 
    'Top 10 Busiest Origin Airports' AS analysis_type,
    Origin AS airport_code,
    COUNT(*) AS total_departures,
    ROUND(AVG(DepDelay), 2) AS avg_departure_delay,
    ROUND(STDDEV(DepDelay), 2) AS delay_consistency,
    SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) AS significant_delays,
    SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) AS cancellations,
    ROUND(SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS significant_delay_rate,
    ROUND(SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate,
    'High traffic requires operational optimization' AS business_insight
FROM airlinedata
GROUP BY Origin
ORDER BY total_departures DESC
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

-- =====================================================
-- TASK 04: GENERATING INSIGHTS & RECOMMENDATIONS
-- =====================================================
-- 
-- TASK DESCRIPTION: Analyze data to generate actionable insights on airline delays, airport congestion, delay causes, and peak hour impacts
-- BUSINESS PURPOSE: Provide strategic recommendations for operational improvements and resource optimization
-- EXPECTED OUTCOME: Data-driven insights with specific recommendations for airline performance enhancement

-- 1. Which airlines experience the highest delays?
SELECT 
    'Airlines with Highest Delays Analysis' AS insight_category,
    UniqueCarrier AS airline_code,
    COUNT(*) AS total_flights,
    ROUND(AVG(ArrDelay), 2) AS avg_arrival_delay_minutes,
    ROUND(AVG(DepDelay), 2) AS avg_departure_delay_minutes,
    SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) AS significant_delays,
    ROUND(SUM(CASE WHEN ArrDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS significant_delay_rate,
    ROUND(SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate,
    CASE 
        WHEN AVG(ArrDelay) > 15 THEN 'URGENT: Implement operational efficiency programs'
        WHEN AVG(ArrDelay) > 10 THEN 'HIGH PRIORITY: Schedule optimization needed'
        ELSE 'MAINTAIN: Continue current performance levels'
    END AS recommendation
FROM airlinedata
GROUP BY UniqueCarrier
HAVING total_flights >= 100
ORDER BY avg_arrival_delay_minutes DESC
LIMIT 10;

-- 2. Which airports have the most congestion?
SELECT 
    'Most Congested Airports Analysis' AS insight_category,
    Origin AS airport_code,
    COUNT(*) AS traffic_volume,
    ROUND(AVG(DepDelay), 2) AS avg_departure_delay,
    ROUND(AVG(ArrDelay), 2) AS avg_arrival_delay,
    SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) AS significant_departure_delays,
    ROUND(SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS departure_delay_rate,
    ROUND(SUM(CASE WHEN Cancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate,
    CASE 
        WHEN COUNT(*) > 1000 AND AVG(DepDelay) > 10 THEN 'CRITICAL: Infrastructure expansion required'
        WHEN COUNT(*) > 500 AND AVG(DepDelay) > 8 THEN 'HIGH: Resource optimization needed'
        WHEN AVG(DepDelay) > 5 THEN 'MODERATE: Operational improvements recommended'
        ELSE 'MAINTAIN: Current performance acceptable'
    END AS congestion_recommendation
FROM airlinedata
GROUP BY Origin
ORDER BY traffic_volume DESC, avg_departure_delay DESC
LIMIT 10;

-- 3. What are the primary causes of delays?
SELECT 
    'Primary Delay Causes Analysis' AS insight_category,
    CASE 
        WHEN Cancelled = 1 THEN 'Flight Cancellations'
        WHEN ArrDelay > 0 AND DepDelay > 0 THEN 'Systemic Operational Issues'
        WHEN ArrDelay > 0 AND DepDelay <= 0 THEN 'En-route/Air Traffic Issues'
        WHEN DepDelay > 0 AND ArrDelay <= 0 THEN 'Ground Operations Issues'
        WHEN ArrDelay <= 0 AND DepDelay <= 0 THEN 'On-Time Performance'
        ELSE 'Unknown/Data Issues'
    END AS delay_cause_category,
    COUNT(*) AS occurrence_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata), 2) AS percentage_of_total,
    ROUND(AVG(CASE WHEN ArrDelay IS NOT NULL THEN ArrDelay ELSE 0 END), 2) AS avg_arrival_delay,
    ROUND(AVG(CASE WHEN DepDelay IS NOT NULL THEN DepDelay ELSE 0 END), 2) AS avg_departure_delay,
    CASE 
        WHEN COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata) > 30 THEN 'HIGH IMPACT: Immediate intervention required'
        WHEN COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata) > 15 THEN 'MEDIUM IMPACT: Process improvement needed'
        ELSE 'LOW IMPACT: Monitor and maintain'
    END AS priority_recommendation
FROM airlinedata
GROUP BY delay_cause_category
ORDER BY occurrence_count DESC;

-- 4. How do peak flight hours impact delays?
SELECT 
    'Peak Hour Impact on Delays Analysis' AS insight_category,
    CASE 
        WHEN HOUR(formatted_departure) BETWEEN 6 AND 9 THEN 'Morning Rush (6-9 AM)'
        WHEN HOUR(formatted_departure) BETWEEN 16 AND 19 THEN 'Evening Rush (4-7 PM)'
        WHEN HOUR(formatted_departure) BETWEEN 10 AND 15 THEN 'Midday Operations (10 AM-3 PM)'
        WHEN HOUR(formatted_departure) BETWEEN 20 AND 23 THEN 'Night Operations (8-11 PM)'
        ELSE 'Late Night/Early Morning (12-5 AM)'
    END AS time_period,
    COUNT(*) AS flight_count,
    ROUND(AVG(DepDelay), 2) AS avg_departure_delay,
    ROUND(AVG(ArrDelay), 2) AS avg_arrival_delay,
    SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) AS significant_delays,
    ROUND(SUM(CASE WHEN DepDelay > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS delay_rate,
    CASE 
        WHEN AVG(DepDelay) > 15 THEN 'URGENT: Redistribute flights to off-peak hours'
        WHEN AVG(DepDelay) > 10 THEN 'HIGH: Increase staffing and resources during peak'
        WHEN AVG(DepDelay) > 5 THEN 'MODERATE: Optimize scheduling and gate assignments'
        ELSE 'MAINTAIN: Current performance acceptable'
    END AS peak_hour_recommendation
FROM airlinedata
WHERE formatted_departure IS NOT NULL
GROUP BY time_period
ORDER BY avg_departure_delay DESC;

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