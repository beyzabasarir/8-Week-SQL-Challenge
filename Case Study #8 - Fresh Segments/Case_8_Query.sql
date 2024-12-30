-- Data Exploration and Cleansing
-- 1. Update the interest_metrics table by modifying the month_year column to be a date data type with the start of the month

ALTER TABLE interest_metrics
ALTER COLUMN month_year TYPE date 
USING TO_DATE(month_year, 'MM-YYYY');

-- 2. What is count of records in the interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

SELECT month_year, COUNT (*) AS record_count
FROM interest_metrics
GROUP BY 1
ORDER BY month_year NULLS FIRST;

-- 3. What do you think we should do with these null values in the interest_metrics

DELETE FROM interest_metrics 
WHERE month_year IS NULL;

-- 4. How many interest_id values exist in the interest_metrics table but not in the interest_map table? What about the other way around?


-- values in interest_metrics not present in interest_map 

SELECT COUNT(DISTINCT me.interest_id) AS values_not_in_map
FROM interest_metrics me
LEFT JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE ma.id IS NULL;

-- values in interest_map not present in interest_metrics

SELECT COUNT(DISTINCT ma.id) AS values_not_in_metrics
FROM interest_map ma
LEFT JOIN interest_metrics me ON ma.id = me.interest_id::integer
WHERE me.interest_id IS NULL;


-- 5. Summarise the id values in the interest_map by its total record count in this table 

SELECT COUNT (id) AS total_records
FROM interest_map;

-- 6. What sort of table join should we perform for our analysis and why?
-- Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from interest_metrics and all columns from interest_map except from the id column.

-- INNER JOIN was preferred to retrieve the rows where matching interest_id values ​​exist in both the interest_metrics and interest_map tables.

SELECT me.*, ma.interest_name, 
       ma.interest_summary, 
	   ma.created_at,
	   ma.last_modified
FROM interest_metrics me
INNER JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE interest_id = '21246';

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the interest_map table? Do you think these values are valid and why?

-- Count of month_year values that are earlier than the created_at value in the interest_map table
SELECT COUNT (*)
FROM interest_metrics me
INNER JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE month_year < created_at

-- Details of the relevant values
SELECT ma.*, me.month_year
FROM interest_metrics me
INNER JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE month_year < created_at


-- Interest Analysis
-- 1. Which interests have been present in all month_year dates in our dataset?

-- Total unique months and interests
SELECT 
  COUNT(DISTINCT month_year) AS total_months,
  COUNT(DISTINCT interest_id) AS unique_interest
FROM interest_metrics;

-- We have a total of 14 distinct month_year values.
-- Filter interests present in all months

WITH interests AS (
SELECT 
  interest_id, 
  COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
GROUP BY interest_id
)

SELECT 
  total_months,
  COUNT(DISTINCT i.interest_id) interest_count
FROM interests i
WHERE total_months = 14
GROUP BY 1
ORDER BY 2 DESC;


-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

-- Calculate the total number of distinct months for each interest_id
WITH month_cte AS (
  SELECT
    DISTINCT interest_id,
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  GROUP BY interest_id
),
-- Count of interest_ids for each total_months value
interest_cte AS (
  SELECT 
    total_months,
    COUNT(DISTINCT interest_id) AS interest_count
  FROM month_cte
  GROUP BY total_months
), 
-- Cumulative percentage of interest_count based on total_months in descending order
cumulative_cte AS (
SELECT 
  total_months,
  interest_count, 
  ROUND(SUM(interest_count)OVER(ORDER BY total_months DESC) *100.0/(SELECT SUM(interest_count) FROM   interest_cte),2) AS cumulative_percent
FROM interest_cte
)
SELECT *
FROM cumulative_cte
WHERE cumulative_percent > 90;


-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

-- Identify all interest_ids where total_months is less than 6
-- Count how many records in total would be removed from the dataset based on these interest_ids.

WITH total_month_cte AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) < 6
)
SELECT COUNT(interest_id) AS interest_record_to_remove
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM total_month_cte);

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

-- Count how many months each interest_id has been present in the dataset.
WITH month_cte AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  GROUP BY interest_id
),
-- Split the data into two categories: interests with >=6 months presence and <6 months presence.
removed_data AS (
  SELECT 
    me.month_year,
    COUNT(DISTINCT CASE WHEN mc.total_months >= 6 THEN mc.interest_id END) AS remaining_interest,
    COUNT(DISTINCT CASE WHEN mc.total_months < 6 THEN mc.interest_id END) AS removed_interest
  FROM month_cte mc
  JOIN interest_metrics me ON mc.interest_id = me.interest_id
  GROUP BY me.month_year
)

-- Calculate the percentage of interests that would be removed for each month. 
SELECT 
  month_year,
  remaining_interest,
  removed_interest,
  ROUND((removed_interest * 100.0) / (remaining_interest + removed_interest), 2) AS removed_prcnt
FROM removed_data
ORDER BY month_year;

-- 5. After removing these interests - how many unique interests are there for each month?

-- Identify interest_ids that appear in fewer than 6 distinct months.
-- For each month, count how many unique interest_ids remain after excluding those identified in total_month_cte 

WITH total_month_cte AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) < 6
)
SELECT month_year,
       COUNT(DISTINCT interest_id) AS remaining_interests
FROM interest_metrics
WHERE interest_id NOT IN (SELECT interest_id FROM total_month_cte)
GROUP BY 1;

-- Segment Analysis
-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest

-- Create table with filtered interests with more than 6 months of data 
CREATE TABLE filtered_data AS
SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
GROUP BY interest_id
HAVING COUNT(DISTINCT month_year) >= 6;

-- Filter interests to ensure the dataset only includes those with data for at least 6 months.
-- Use MAX(composition) for each interest across months to identify the strongest performance.
-- Extract the top and bottom 10 interests based on composition values for comparative insights.

-- TOP 10 
SELECT month_year,
       interest_id,
	   interest_name, 
       MAX(composition) AS max_composition
FROM interest_metrics me
JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE interest_id IN (SELECT interest_id FROM filtered_data)
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 10;

-- BOTTOM 10
SELECT month_year,
       interest_id,
	   interest_name, 
       MAX(composition) AS max_composition
FROM interest_metrics me
JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE interest_id IN (SELECT interest_id FROM filtered_data)
GROUP BY 1,2,3
ORDER BY 4 
LIMIT 10;


-- 2. Which 5 interests had the lowest average ranking value?

-- Join the interest_map and interest_metrics tables to associate rankings with interest names.
-- Filter the dataset to only include interests with more than six months of data.
-- Sort the results in ascending order to identify the lowest average rankings.
-- Use LIMIT 6 since the fifth and sixth entries share the same average ranking.
SELECT 
       interest_name,
       ROUND(AVG(ranking),2) AS avg_ranking
FROM interest_map ma
JOIN interest_metrics me ON me.interest_id::integer = ma.id
WHERE interest_id IN (SELECT interest_id FROM filtered_data)
GROUP BY 1
ORDER BY 2 ASC
LIMIT 6;


-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?

-- Join interest_map and interest_metrics tables to compute statistics for each interest.
-- Filter the dataset
-- Calculate the standard deviation of percentile_ranking values for each interest.
-- Sort results in descending order to identify the top five with the highest variability.

SELECT interest_id,
    interest_name,
    ROUND(STDDEV(percentile_ranking::integer),2) AS std_ranking_prcnt
FROM interest_map ma
JOIN interest_metrics me ON me.interest_id::integer = ma.id
WHERE interest_id IN (SELECT interest_id FROM filtered_data)
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;

-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

-- Identify the top 5 interests with the largest standard deviation from the previous query.
-- Join with interest_metrics to compute minimum and maximum percentile rankings for each interest.
-- Capture the corresponding year-month for the minimum and maximum values.

WITH top_5_interest AS (
    SELECT 
        me.interest_id,
        ma.interest_name,
	    ma.interest_summary, 
        ROUND(STDDEV(me.percentile_ranking::integer), 2) AS std_ranking_prcnt
    FROM interest_map ma
    JOIN interest_metrics me ON me.interest_id::integer = ma.id
    WHERE me.interest_id IN (SELECT interest_id FROM filtered_data)
    GROUP BY me.interest_id, ma.interest_name, ma.interest_summary
    ORDER BY std_ranking_prcnt DESC
    LIMIT 5
),
percentile_rankings AS (
    SELECT 
        t.interest_id,
        t.interest_name,
	    t.interest_summary,
        MIN(me.percentile_ranking) AS min_ranking,
        MAX(me.percentile_ranking) AS max_ranking,
        -- Selecting the months where the minimum and maximum rankings are found
        (SELECT month_year 
         FROM interest_metrics 
         WHERE interest_id = t.interest_id 
         AND percentile_ranking = MIN(me.percentile_ranking)
         ) AS min_year,
        (SELECT month_year 
         FROM interest_metrics 
         WHERE interest_id = t.interest_id 
         AND percentile_ranking = MAX(me.percentile_ranking)
         ) AS max_year
    FROM interest_metrics me
    JOIN top_5_interest t ON me.interest_id = t.interest_id
    GROUP BY t.interest_id, t.interest_name, t.interest_summary
)
SELECT 
    interest_name,
	interest_summary,
    min_year,
    min_ranking,
    max_year,
    max_ranking
FROM percentile_rankings
ORDER BY max_ranking DESC;

-- Index Analysis
-- 1. What is the top 10 interests by the average composition for each month?

-- Calculate the average composition for each interest by month using normalized composition values.
-- Rank the interests within each month based on their average composition.
-- Filter the top 10 interests for each month.

WITH monthly_composition AS(
SELECT 
    month_year,
    interest_name, 
    ROUND((composition / index_value)::numeric, 2) AS avg_composition
FROM interest_map ma
JOIN interest_metrics me ON me.interest_id::integer = ma.id
WHERE me.interest_id IN (SELECT interest_id FROM filtered_data)) ,
ranked_interests AS (
    SELECT 
        month_year,
        interest_name,
        avg_composition,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS ranking
    FROM monthly_composition)
	SELECT month_year,
        interest_name,
        avg_composition
		FROM ranked_interests
	WHERE ranking < 11;

-- 2. For all of these top 10 interests - which interest appears the most often?

WITH monthly_composition AS (
    SELECT 
	    month_year,
        interest_name,
        ROUND((composition / index_value)::numeric, 2) AS avg_composition
    FROM interest_map ma
    JOIN interest_metrics me ON me.interest_id::integer = ma.id
    WHERE me.interest_id IN (SELECT interest_id FROM filtered_data)
), 
ranked_interests AS (
    SELECT 
        interest_name,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS ranking
    FROM monthly_composition
)
SELECT 
    interest_name,
    COUNT(*) AS repeated_interests
FROM ranked_interests
WHERE ranking <= 10  -- Top 10 based on the ranking
GROUP BY interest_name
HAVING COUNT(*) = (
    SELECT MAX(count) 
    FROM (
        SELECT COUNT(*) AS count
        FROM ranked_interests
        WHERE ranking <= 10
        GROUP BY interest_name
    ) AS subquery
)
ORDER BY repeated_interests DESC;
	
-- 3. What is the average of the average composition for the top 10 interests for each month? 

-- Calculate the average composition for each interest monthly.
-- Rank the interests for each month based on the average composition.
-- Filter to select the top 10 interests for each month.
-- Compute the overall average composition of these top 10 interests per month.


WITH monthly_composition AS(
SELECT 
    month_year,
    interest_name, 
    ROUND((composition / index_value)::numeric, 2) AS avg_composition
FROM interest_map ma
JOIN interest_metrics me ON me.interest_id::integer = ma.id
WHERE me.interest_id IN (SELECT interest_id FROM filtered_data)) ,
ranked_interests AS (
    SELECT 
        month_year,
        interest_name,
        avg_composition,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS ranking
    FROM monthly_composition)
	SELECT month_year,
        ROUND(AVG(avg_composition),2) AS avg_avg_composition
		FROM ranked_interests
	WHERE ranking < 11
	GROUP BY 1
	ORDER BY 1,2;

-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.

-- Calculate average composition and the maximum composition for each month
WITH avg_compositions AS (
  SELECT 
    month_year,
    interest_id,
    ROUND((composition / index_value)::numeric, 2) AS avg_comp,
    ROUND(MAX(composition / index_value) OVER(PARTITION BY month_year)::numeric, 2) AS max_avg_comp
  FROM interest_metrics
  WHERE month_year IS NOT NULL
),

-- Filter rows where the average composition equals the maximum composition for the month
max_avg_compositions AS (
  SELECT *
  FROM avg_compositions
  WHERE avg_comp = max_avg_comp
),

-- Calculate the 3-month rolling average and include the previous top ranking interests
moving_avg_compositions AS (
  SELECT 
    mac.month_year,
    im.interest_name,
    mac.max_avg_comp AS max_index_composition,
    ROUND(AVG(mac.max_avg_comp) 
          OVER(ORDER BY mac.month_year 
               ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)::numeric, 2) AS "3_month_moving_avg",
    LAG(im.interest_name) OVER (ORDER BY mac.month_year) || ': ' ||
    CAST(LAG(mac.max_avg_comp) OVER (ORDER BY mac.month_year) AS VARCHAR(4)) AS "1_month_ago",
    LAG(im.interest_name, 2) OVER (ORDER BY mac.month_year) || ': ' ||
    CAST(LAG(mac.max_avg_comp, 2) OVER (ORDER BY mac.month_year) AS VARCHAR(4)) AS "2_month_ago"
  FROM max_avg_compositions mac 
  JOIN interest_map im 
    ON CAST(mac.interest_id AS INTEGER) = im.id
)

-- Filter data to include the desired time period from September 2018 to August 2019
SELECT *
FROM moving_avg_compositions
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';
