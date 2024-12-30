--A. Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT(node_id)) AS unique_nodes
FROM customer_nodes;

-- 2. What is the number of nodes per region?

SELECT cn.region_id, region_name,
COUNT(node_id) AS node_number 
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- 3. How many customers are allocated to each region?

SELECT region_name,
COUNT(DISTINCT(customer_id)) AS customer_count 
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY 1
ORDER BY 2 DESC;


-- 4. How many days on average are customers reallocated to a different node?

--Identify the maximum end_date in the dataset.

SELECT MAX (end_date) FROM customer_nodes;

-- Exclude invalid data (end_date = '9999-12-31') to avoid skewed results.
-- Calculate the difference between start_date and end_date for each record.
-- Use AVG to determine the mean duration.

SELECT ROUND(AVG(end_date - start_date),0) AS avg_days
FROM customer_nodes
WHERE end_date != '9999-12-31';

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- calculate reallocation days for each record, excluding invalid end_date values ('9999-12-31').
-- Apply PERCENTILE_CONT to compute the median (50th), 80th, and 95th percentiles.
-- Grouped results by region to show metrics per region.

WITH reallocation_day AS (
SELECT*, (end_date - start_date) AS reallocation_days
FROM customer_nodes
WHERE end_date != '9999-12-31'
)
SELECT region_name, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Reallocation_Days) AS Median,
       PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Reallocation_Days) AS P80,
       PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Reallocation_Days) AS P95
FROM reallocation_day rd
JOIN regions r ON rd.region_id = r.region_id
GROUP BY 1;


-- B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?

SELECT txn_type, 
       COUNT(*) AS transaction_count,
       SUM (txn_amount) AS total_amount
FROM customer_transactions
GROUP BY 1
ORDER BY 2 DESC;

--2. What is the average total historical deposit counts and amounts for all customers?

-- Calculate deposit counts and total amounts for each customer using conditional aggregation. Then, take their averages.

WITH historical_deposit AS (
    SELECT customer_id,
           COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS total_amount
    FROM customer_transactions
    GROUP BY customer_id
)
SELECT 
    ROUND(AVG(deposit_count), 0) AS avg_count,
    ROUND(AVG(total_amount), 2) AS avg_amount
FROM historical_deposit;
	   
-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

-- Use CTE to compute monthly transaction counts by customer and transaction type.
-- Filter customers with more than one deposit and at least one purchase or withdrawal within the same month.

WITH txn_counts AS (
    SELECT customer_id,
           EXTRACT(MONTH FROM txn_date) AS month_number,  
           TO_CHAR(txn_date, 'FMMonth') AS month_name,   
           COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
           COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
           COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
    FROM customer_transactions
    GROUP BY customer_id, month_number, month_name
)
SELECT month_name, COUNT(customer_id) AS customer_count
FROM txn_counts
WHERE deposit_count > 1 
  AND (purchase_count = 1 OR withdrawal_count = 1)
GROUP BY month_name, month_number
ORDER BY month_number;

-- 4. What is the closing balance for each customer at the end of the month?

-- Use CTE to calculate the monthly net transaction amount for each customer by categorizing deposits as positive and other transactions as negative.
-- Apply a window function to compute the cumulative closing balance, partitioned by customer ID and ordered by month.

WITH MonthlyBalance AS (
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            ELSE -txn_amount 
        END) AS monthly_amount
    FROM 
        customer_transactions
    GROUP BY 
        customer_id, month
)

SELECT 
    customer_id, 
    month,
    SUM(monthly_amount) OVER (PARTITION BY customer_id ORDER BY month) AS closing_balance
FROM 
    MonthlyBalance
ORDER BY 
    customer_id, month;
	
-- 5. What is the percentage of customers who increase their closing balance by more than 5%?

WITH MonthlyBalance AS (
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            WHEN txn_type = 'withdrawal' THEN -txn_amount
            WHEN txn_type = 'purchase' THEN -txn_amount
            ELSE 0 
        END) AS monthly_amount
    FROM 
        customer_transactions
    GROUP BY 
        customer_id, month
),
ClosingBalance AS (
    SELECT 
        customer_id,
        month,
        SUM(monthly_amount) OVER (PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM 
        MonthlyBalance
),
PercentageIncrease AS (
    SELECT 
        customer_id,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month) AS previous_balance
    FROM 
        ClosingBalance
)
SELECT 
    ROUND(
        (COUNT(*) FILTER (WHERE 
            (closing_balance - previous_balance) / NULLIF(previous_balance, 0) > 0.05
            OR (previous_balance < 0 AND closing_balance >= 0)  
        ) * 100.0) / NULLIF(COUNT(*) FILTER (WHERE previous_balance IS NOT NULL), 0),
    2) AS percentage_increase
FROM 
    PercentageIncrease;


-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
-- Using all of the data available - how much data would have been required for each option on a monthly basis?


-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
-- 1. running customer balance column that includes the impact each transaction

-- Use SUM() OVER() to compute cumulative balances partitioned by customer_id.
-- Ensure ORDER BY txn_date for chronological accuracy.
-- Handle transaction type impact using CASE WHEN logic.

SELECT 
    customer_id,
    txn_type,
    txn_date,
    txn_amount,
    SUM(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount 
        ELSE -txn_amount 
    END) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM 
    customer_transactions
ORDER BY 
    customer_id, txn_date;
	
-- 2. Customer balance at the end of each month

-- Use TO_CHAR to group dates by month.
-- Calculate month-end balance with MAX(txn_date).
-- Aggregate balances by customer_id and month.

    SELECT 
        customer_id,
        TO_CHAR (txn_date, 'Month') AS month,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            ELSE -txn_amount 
        END) AS balance
    FROM 
        customer_transactions
    GROUP BY 
        customer_id, month
	ORDER BY 
    customer_id, month;
	
-- 3. minimum, average and maximum values of the running balance for each customer

WITH Balance AS (
SELECT 
    customer_id,
    SUM(CASE 
        WHEN txn_type = 'deposit' THEN txn_amount 
        ELSE -txn_amount 
    END) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM 
    customer_transactions
ORDER BY 
    customer_id, txn_date)
	
SELECT customer_id,
       MIN (running_balance) AS min_running_balance,
	   ROUND(AVG(running_balance),2) AS avg_running_balance,
	   MAX(running_balance) AS max_running_balance
FROM Balance
GROUP BY customer_id;

