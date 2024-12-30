-- 1. Data Cleansing Steps
-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales: 
-- Convert the week_date to a DATE format
-- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-- Add a month_number with the calendar month for each week_date value as the 3rd column
-- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
-- Add a new demographic column using the following mapping for the first letter in the segment values
-- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
DROP TABLE clean_weekly_sales
CREATE TABLE clean_weekly_sales (
week_date date,
week_number int,
month_number int,
calendar_year int,
region varchar(50),
platform varchar(50),
segment varchar(50),
age_band varchar(50),
demographic varchar(50),
customer_type varchar(50),
transactions int,
sales int,
avg_transaction float
);


INSERT INTO clean_weekly_sales (
    week_date,
    week_number,
    month_number,
    calendar_year,
    region,
    platform,
    segment,
    age_band,
    demographic,
	customer_type,
    transactions,
    sales,
    avg_transaction
)
WITH new_columns AS (
    SELECT 
        TO_DATE(week_date, 'DD-MM-YY') AS week_date,
        DATE_PART('Week', TO_DATE(week_date, 'DD-MM-YY')) AS week_number,
        EXTRACT(MONTH FROM TO_DATE(week_date, 'DD-MM-YY')) AS month_number,
        EXTRACT(YEAR FROM TO_DATE(week_date, 'DD-MM-YY')) AS calendar_year,
        region,
        platform,
        CASE 
	        WHEN segment = 'null' THEN 'Unknown'
	        ELSE segment END AS segment,
        CASE 
            WHEN segment LIKE '%1' THEN 'Young Adults'   
            WHEN segment LIKE '%2' THEN 'Middle Aged'   
            WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'   
            ELSE 'Unknown' 
        END AS age_band, 
        CASE 
            WHEN segment LIKE 'C%' THEN 'Couples'   
            WHEN segment LIKE 'F%' THEN 'Families'   
            ELSE 'Unknown' 
        END AS demographic,
	    customer_type,
        transactions,
        sales,
        ROUND((sales / NULLIF(transactions, 0)), 2) AS avg_transaction
    FROM weekly_sales
)
SELECT * FROM new_columns;

SELECT * FROM clean_weekly_sales;

-- 2. Data Exploration
-- 1. What day of the week is used for each week_date value?

SELECT DISTINCT
       TO_CHAR(week_date, 'Day') AS day_of_week
FROM clean_weekly_sales;

-- 2. What range of week numbers are missing from the dataset?

-- Generate a complete list of weeks (1 to 52).
-- Identify existing weeks in the dataset using DISTINCT on the week_number column.
-- LEFT JOIN between complete and existing weeks.
-- Filter for weeks that are missing by checking for NULL values in the join result.

WITH complete_week AS (
    SELECT generate_series(1, 52) AS complete_weeks
),
existing_week AS (
    SELECT DISTINCT week_number AS existing_weeks
    FROM clean_weekly_sales
)
SELECT complete_weeks AS missing_weeks
FROM complete_week cw
LEFT JOIN existing_week ew ON cw.complete_weeks = ew.existing_weeks
WHERE ew.existing_weeks IS NULL;


-- 3. How many total transactions were there for each year in the dataset?

SELECT calendar_year, 
       TO_CHAR(SUM(transactions), '999,999,999') AS total_transactions
FROM clean_weekly_sales
GROUP BY 1;

-- 4. What is the total sales for each region for each month?

SELECT region, 
       month_number, 
	   SUM (sales) AS total_sales
FROM clean_weekly_sales
GROUP BY 1,2
ORDER BY 1,2;

-- 5. What is the total count of transactions for each platform

SELECT platform,
       SUM (transactions) AS transtaction_count
FROM clean_weekly_sales
GROUP BY 1
ORDER BY 2 DESC;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?

-- Aggregate total sales for both Retail and Shopify for each calendar year and month.
-- Calculate the total sales for the month to determine the percentage share.
-- Retail Sales Percentage = (Retail Sales / Total Sales) × 100
-- Shopify Sales Percentage = (Shopify Sales / Total Sales) × 100

WITH sales_totals AS (
SELECT 
    calendar_year,
    month_number,
    SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) AS Retail,
    SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) AS Shopify,
    SUM(sales) AS total_sale
FROM 
    clean_weekly_sales
GROUP BY 
    calendar_year, month_number)
	SELECT calendar_year,
	       month_number,
		   ROUND((Retail*100.0/total_sale),2) AS retail_percentage,
		   ROUND((Shopify*100.0/total_sale),2) AS shopify_percentage
	FROM sales_totals
	ORDER BY 1,2;
	
-- 7. What is the percentage of sales by demographic for each year in the dataset?

-- Sum sales based on the demographic values: Couples, Families, and Unknown.
-- Compute the total sales for each year.
-- Sales Percentage=( Total Sales / Demographic Sales)×100

WITH sales_CTE AS (
SELECT 
    calendar_year AS year,
    SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) AS couples_sales,
    SUM(CASE WHEN demographic = 'Families'  THEN sales ELSE 0 END) AS families_sales,
	SUM(CASE WHEN demographic = 'Unknown'  THEN sales ELSE 0 END) AS unknown_sales,
    SUM(sales) AS total_sale
FROM 
    clean_weekly_sales
GROUP BY 
    calendar_year)
SELECT year, 
       ROUND((couples_sales*100.0/total_sale),2) AS couples_percentage,
       ROUND((families_sales*100.0/total_sale),2) AS families_percentage,
       ROUND((unknown_sales*100.0/total_sale),2) AS unknown_percentage
FROM sales_CTE;

-- 8. Which age_band and demographic values contribute the most to Retail sales?

-- Sum sales by age_band and demographic where the platform is 'Retail'
-- Sales Percentage=( Age & Demographic Sales for Retail / Total Retail Sales )×100
-- Used a subquery to calculate the total Retail sales for the denominator in percentage calculation.

SELECT age_band,
       demographic,
	   SUM(sales) AS total_sales,
	   ROUND(SUM(sales)*100.0 /(SELECT SUM(sales) FROM clean_weekly_sales WHERE  platform='Retail' ) ,2) AS sales_percentage
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY 1,2   
ORDER BY 3 DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
-- Overall Average Transaction Size= (Total Transactions / Total Sales)
-- Calculate the average of the avg_transaction column for each year and platform.

SELECT 
    calendar_year,
    platform,
    ROUND(SUM(sales::numeric) / NULLIF(SUM(transactions::numeric),0),2) AS overall_avg,
    ROUND(AVG(avg_transaction::numeric), 2) AS avg_of_avg
FROM 
    clean_weekly_sales
GROUP BY 
    calendar_year, platform
ORDER BY 
    calendar_year, platform;

-- 3. Before & After Analysis
-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales? 

-- Identify the week number for the baseline week (2020-06-15). 

SELECT DISTINCT week_number  
FROM clean_weekly_sales  
WHERE week_date = '2020-06-15' AND calendar_year = '2020';  

-- Define the period before and after the baseline date by filtering the weeks before and after this date.
-- Sum sales for the 'Before' (weeks 21-24) and 'After' (weeks 25-28) periods.
-- Calculate the sales difference and the growth rate (percentage change).

WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 21 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 28 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 21 AND 28 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT 
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
)
SELECT 
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales;

-- 2. What about the entire 12 weeks before and after?

-- 1. Define the period before (weeks 13-24) and after (weeks 25-37) the baseline date.
-- 2. Filter data for weeks 13-37 of the year 2020.
-- 3. Sum sales for the 'Before' and 'After' periods.
-- 4. Growth Rate=((After Sales − Before Sales) / Before Sales)×100

WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT 
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
)
SELECT 
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales;

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
-- a)4 weeks 
WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 21 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 28 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 21 AND 28
),
before_after_sales AS (
    SELECT 
        calendar_year, 
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
    GROUP BY calendar_year
)
SELECT 
    calendar_year, 
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / before_sales, 2) AS change_percent
FROM before_after_sales
GROUP BY calendar_year, before_sales, after_sales
ORDER BY calendar_year;

-- b) 12 weeks 

WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37
),
before_after_sales AS (
    SELECT 
        calendar_year, 
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
    GROUP BY calendar_year
)
SELECT 
    calendar_year, 
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / before_sales, 2) AS change_percent
FROM before_after_sales
GROUP BY calendar_year, before_sales, after_sales
ORDER BY calendar_year;

-- 4. Bonus Question
-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

-- Define the 'Before' (weeks 13-24) and 'After' (weeks 25-37) periods.
-- Filter the data for weeks 13-37 in 2020.
-- Calculate sales totals for both 'Before' and 'After' periods.
-- Calculate the sales difference and percentage change for each variable.


-- a. region

WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT region,
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
	GROUP BY 1
)
SELECT region,
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales
GROUP BY 1,2,3
ORDER BY 5 DESC;

-- b. platform
WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT platform,
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
	GROUP BY 1
)
SELECT platform,
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales
GROUP BY 1,2,3
ORDER BY 5 DESC;

-- age_band

WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT age_band,
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
	GROUP BY 1
)
SELECT age_band,
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales
GROUP BY 1,2,3
ORDER BY 5 DESC;

-- demographic

WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT demographic,
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
	GROUP BY 1
)
SELECT demographic,
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales
GROUP BY 1,2,3
ORDER BY 5 DESC;

-- customer_type

WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT customer_type,
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
	GROUP BY 1
)
SELECT customer_type,
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales
GROUP BY 1,2,3
ORDER BY 5 DESC;
