use airline_data;

show columns from flights_deduped;


-- Check for missing values
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN DepTime IS NULL THEN 1 ELSE 0 END) AS missing_departures,
    SUM(CASE WHEN ArrTime IS NULL THEN 1 ELSE 0 END) AS missing_arrivals,
    SUM(CASE WHEN ArrDelay IS NULL THEN 1 ELSE 0 END) AS missing_delays
FROM airlinedata;

-- Format date and time fields (convert string to proper datetime)
ALTER TABLE airlinedata
ADD COLUMN formatted_flightdate DATE,
ADD COLUMN formatted_departure DATETIME,
ADD COLUMN formatted_arrival DATETIME;

UPDATE airlinedata
SET 
    formatted_flightdate = STR_TO_DATE(FlightDate, '%Y-%m-%d'),
    formatted_departure = STR_TO_DATE(CONCAT(FlightDate, ' ', DepartureTime), '%Y-%m-%d %H:%i:%s'),
    formatted_arrival = STR_TO_DATE(CONCAT(FlightDate, ' ', ArrivalTime), '%Y-%m-%d %H:%i:%s');
    
    
    -- Total number of flights
SELECT COUNT(*) AS total_flights FROM airlinedata;

-- Average delay time by carrier
SELECT 
    UniqueCarrier,
    AVG(ArrDelay) AS avg_arrival_delay,
    AVG(DepDelay) AS avg_departure_delay,
    COUNT(*) AS flight_count
FROM airlinedata
GROUP BY UniqueCarrier
ORDER BY avg_arrival_delay DESC;

-- Delay causes (for delayed flights)
SELECT 
    CASE 
        WHEN ArrDelay > 0 THEN 'Arrival Delay'
        WHEN DepDelay > 0 THEN 'Departure Delay'
        ELSE 'On Time'
    END AS delay_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airlinedata), 2) AS percentage
FROM airlinedata
GROUP BY delay_type;


-- Top 10 busiest origin airports
SELECT 
    Origin,
    COUNT(*) AS departure_count,
    AVG(DepDelay) AS avg_departure_delay
FROM airlinedata
GROUP BY Origin
ORDER BY departure_count DESC
LIMIT 10;

-- 	
SELECT 
    Dest,
    COUNT(*) AS arrival_count,
    AVG(ArrDelay) AS avg_arrival_delay
FROM airlinedata
GROUP BY Dest
ORDER BY arrival_count DESC
LIMIT 10;

-- Airport pairs with most flights
SELECT 
    Origin,
    Dest,
    COUNT(*) AS flight_count,
    AVG(Distance) AS avg_distance,
    AVG(ArrDelay) AS avg_delay
FROM airlinedata
GROUP BY Origin, Dest
ORDER BY flight_count DESC
LIMIT 10;


-- Delay trends by day of week
SELECT 
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
    AVG(ArrDelay) AS avg_delay,
    COUNT(*) AS flight_count
FROM airlinedata
GROUP BY DayOfWeek
ORDER BY avg_delay DESC;

-- Delay trends by month
SELECT 
    Month,
    AVG(ArrDelay) AS avg_delay,
    COUNT(*) AS flight_count
FROM airlinedata
GROUP BY Month
ORDER BY Month;

-- First, add the new columns
ALTER TABLE airlinedata
ADD COLUMN formatted_flightdate DATE,
ADD COLUMN formatted_departure DATETIME,
ADD COLUMN formatted_arrival DATETIME;

-- Clean the data first
UPDATE airlinedata
SET 
    DepartureTime = REPLACE(DepartureTime, '24:', '00:'),
    ArrivalTime = REPLACE(ArrivalTime, '24:', '00:')
WHERE DepartureTime LIKE '24:%' OR ArrivalTime LIKE '24:%';

-- Then convert
UPDATE airlinedata
SET 
    formatted_flightdate = STR_TO_DATE(FlightDate, '%Y-%m-%d'),
    formatted_departure = STR_TO_DATE(CONCAT(FlightDate, ' ', DepartureTime), '%Y-%m-%d %H:%i:%s'),
    formatted_arrival = STR_TO_DATE(CONCAT(FlightDate, ' ', ArrivalTime), '%Y-%m-%d %H:%i:%s');



-- Delay trends by time of day
SELECT 
    HOUR(formatted_departure) AS hour_of_day,
    AVG(DepDelay) AS avg_departure_delay,
    AVG(ArrDelay) AS avg_arrival_delay,
    COUNT(*) AS flight_count
FROM airlinedata
GROUP BY hour_of_day
ORDER BY hour_of_day;



-- Cancellation reasons
SELECT 
    CancellationCode,
    CASE CancellationCode
        WHEN 'A' THEN 'Carrier'
        WHEN 'B' THEN 'Weather'
        WHEN 'C' THEN 'NAS'
        WHEN 'D' THEN 'Security'
        ELSE 'Unknown'
    END AS cancellation_reason,
    COUNT(*) AS cancellation_count
FROM airlinedata
WHERE Cancelled = 1
GROUP BY CancellationCode
ORDER BY cancellation_count DESC;

use airline_data;

SELECT *
   
FROM airlinedata;