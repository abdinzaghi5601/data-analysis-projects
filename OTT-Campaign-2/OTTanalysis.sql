create database MarketingCampaign;


use marketingcampaign;

select * from campaigndata;


show columns from campaigndata;


-- check for duplicates with a unique ID 

SELECT Campaign_ID, COUNT(*) as duplicate_count
FROM campaigndata
GROUP BY Campaign_ID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;



-- 2. REGEXP Convert Duration to numeric (handling '30 days', '2 weeks' ,'3 months') to 30 , 14, 90 days  
UPDATE campaigndata
SET Duration_Num = CASE
    WHEN Duration LIKE '%day%' THEN 
        CAST(REGEXP_REPLACE(Duration, '[^0-9]', '') AS UNSIGNED)
    WHEN Duration LIKE '%week%' THEN 
        CAST(REGEXP_REPLACE(Duration, '[^0-9]', '') AS UNSIGNED) * 7
    WHEN Duration LIKE '%month%' THEN 
        CAST(REGEXP_REPLACE(Duration, '[^0-9]', '') AS UNSIGNED) * 30
    ELSE 0
END;

-- 3. Convert Acquisition Cost to numeric (handling '$1,000.50')
UPDATE campaigndata
SET Acquisition_Cost_Numeric = CAST(
    REPLACE(
        REPLACE(Acquisition_Cost, '$', ''),
        ',', ''
    )
    AS DECIMAL(10,2)
);

-- 4. Handle any remaining NULL values
UPDATE campaigndata
SET 
    Duration_Num = COALESCE(Duration_Num, 0),
    Acquisition_Cost_Numeric = COALESCE(Acquisition_Cost_Numeric, 0);
    
 -- query to check if the right format has been applied
 
    SELECT 
    Duration,
    Duration_Num,
    Acquisition_Cost,
    Acquisition_Cost_Numeric
FROM campaigndata
LIMIT 10;



-- Handle missing values
UPDATE campaigndata
SET 
    Conversion_Rate = COALESCE(Conversion_Rate, 0),
    ROI = COALESCE(ROI, 0),
    Clicks = COALESCE(Clicks, 0),
    Impressions = COALESCE(Impressions, 0),
    Engagement_Score = COALESCE(Engagement_Score, 0),
    Age_Min = COALESCE(Age_Min, 18),
    Age_Max = COALESCE(Age_Max, 65);

-- Campaign Performance by Type and Channel

SELECT 
    Campaign_Type,
    Channel_Used,
    AVG(Conversion_Rate) AS avg_conversion,
    AVG(ROI) AS avg_roi,
    SUM(Clicks) AS total_clicks,
    SUM(Impressions) AS total_impressions,
    COUNT(*) AS campaign_count
FROM campaigndata
GROUP BY Campaign_Type, Channel_Used
ORDER BY avg_roi DESC;


-- Top-Performing Campaigns

SELECT 
    Campaign_ID,
    Company,
    Campaign_Type,
    Channel_Used,
    Conversion_Rate,
    ROI,
    ROUND((Clicks/Impressions)*100, 2) AS CTR,
    Engagement_Score
FROM campaigndata
ORDER BY ROI DESC
LIMIT 10;


-- Location and Audience Analysis

SELECT 
    Location,
    Target_Audience,
    AVG(Conversion_Rate) AS avg_conversion,
    AVG(ROI) AS avg_roi,
    AVG(Acquisition_Cost_Numeric) AS avg_acquisition_cost,
    COUNT(*) AS campaign_count
FROM campaigndata
GROUP BY Location, Target_Audience
ORDER BY avg_roi DESC;


-- Duration Impact Analysis

SELECT 
    Duration_Num,
    CASE 
        WHEN Duration_Num < 7 THEN 'Short (1-7 days)'
        WHEN Duration_Num BETWEEN 7 AND 30 THEN 'Medium (1-4 weeks)'
        ELSE 'Long (>1 month)'
    END AS duration_category,
    AVG(Conversion_Rate) AS avg_conversion,
    AVG(ROI) AS avg_roi,
    AVG(Engagement_Score) AS avg_engagement
FROM campaigndata
GROUP BY duration_category, Duration_Num
ORDER BY Duration_Num;

-- Financial Metrics Correlation


SELECT 
    Campaign_Type,
    AVG(Acquisition_Cost_Numeric) AS avg_cost,
    AVG(Conversion_Rate) AS avg_conversion,
    AVG(ROI) AS avg_roi,
    AVG(Engagement_Score) AS avg_engagement,
    (AVG(ROI)/AVG(Acquisition_Cost_Numeric)) AS cost_efficiency
FROM campaigndata
GROUP BY Campaign_Type
ORDER BY cost_efficiency DESC;

-- Time-Based Trends
SELECT 
    YEAR(Date) AS year,
    Quarter,
    MONTHNAME(Date) AS month,
    COUNT(*) AS campaign_count,
    AVG(ROI) AS avg_roi,
    SUM(Clicks) AS total_clicks
FROM campaigndata
GROUP BY year, Quarter,month
ORDER BY year, month;




-- Demographic Analysis
SELECT 
    Gender,
    CONCAT(Age_Min, '-', Age_Max) AS age_range,
    AVG(Conversion_Rate) AS avg_conversion,
    AVG(ROI) AS avg_roi,
    COUNT(*) AS campaign_count
FROM campaigndata
GROUP BY Gender, age_range
ORDER BY avg_conversion DESC;


-- Best Performing Channel by Company
SELECT 
    Company,
    Channel_Used,
    AVG(ROI) AS avg_roi,
    RANK() OVER (PARTITION BY Company ORDER BY AVG(ROI) DESC) AS channel_rank
FROM campaigndata
GROUP BY Company, Channel_Used;











SELECT 
    Campaign_Type,
    CASE 
        WHEN Acquisition_Cost_Numeric <= @q1 THEN 1
        WHEN Acquisition_Cost_Numeric <= @q2 THEN 2
        WHEN Acquisition_Cost_Numeric <= @q3 THEN 3
        ELSE 4
    END AS cost_quartile,
    AVG(ROI) AS avg_roi,
    AVG(Conversion_Rate) AS avg_conversion,
    COUNT(*) AS campaign_count
FROM campaigndata
GROUP BY Campaign_Type, cost_quartile
ORDER BY Campaign_Type, cost_quartile;



-- Create view for dashboard
CREATE VIEW campaign_overview AS
SELECT 
    Company,
    Campaign_Type,
    YEAR(Date) AS Year,
    MONTH(Date) AS Month,
    ROI,
    Conversion_Rate,
    Clicks,
    Impressions,
    Engagement_Score,
    Acquisition_Cost_Numeric AS Spend
FROM campaigndata;


select * from Campaign_overview;

SELECT * FROM campaigndata;

-- Create performance view
CREATE VIEW campaign_performanc AS
SELECT 
	Campaign_ID
    Campaign_Type,
    Channel_Used,
    Location,
    Target_Audience,
    Conversion_Rate,
    ROI,
    Engagement_Score,
    Clicks,
    (Clicks/Impressions)*100 AS CTR
FROM campaigndata
WHERE Impressions > 0;

Select * from campaign_performanc;



-- Highest ROI Campaign Type

SELECT 
    Campaign_Type,
    AVG(ROI) AS avg_roi
FROM campaigndata
GROUP BY Campaign_Type
ORDER BY avg_roi DESC
LIMIT 1;

-- Conversion Rate Comparison
SELECT 
    Campaign_Type,
    AVG(Conversion_Rate) AS avg_conversion,
    AVG(Acquisition_Cost_Numeric) AS avg_cost
FROM campaigndata
WHERE Campaign_Type IN ('Social Media', 'Email')
GROUP BY Campaign_Type;		

-- Top Target Audience by Clicks
SELECT 
    Target_Audience,
    SUM(Clicks) AS total_clicks,
    (SUM(Clicks)/SUM(Impressions))*100 AS ctr
FROM campaigndata
GROUP BY Target_Audience
ORDER BY total_clicks DESC
LIMIT 3;	


SELECT 
    CONCAT(YEAR(Date), ' Q', QUARTER(Date)) AS quarter,
    AVG(ROI) AS avg_roi,
    SUM(Clicks) AS total_clicks,
    SUM(Acquisition_Cost_Numeric) AS total_spend
FROM campaigndata
GROUP BY quarter
ORDER BY quarter;

-- Underperforming audiences
SELECT 
    Target_Audience,
    AVG(ROI) AS avg_roi,
    AVG(Conversion_Rate) AS avg_conversion
FROM campaigndata
GROUP BY Target_Audience
HAVING AVG(ROI) < (SELECT AVG(ROI) FROM campaigndata)
ORDER BY avg_roi ASC;