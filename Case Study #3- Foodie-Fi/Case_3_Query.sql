-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.


SELECT customer_id, start_date, plan_name, price 
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);

-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?

-- Count distinct customer IDs to ensure each customer is counted only once.

SELECT COUNT(DISTINCT(customer_id)) AS unique_customers
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

-- DATE_TRUNC to group start dates by the beginning of each month.
-- Format the truncated date as MM (month) for grouping clarity.
-- Count the number of unique customers per month.

SELECT TO_CHAR (DATE_TRUNC('month',start_date), 'MM') AS trial_start_month, 
       COUNT (customer_id) AS customer_count
FROM subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY 1;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

-- Join the subscriptions table with plans to access plan names.
-- Filter subscriptions with start dates after December 31, 2020.
-- Count the number of events per plan_name to track activity.

SELECT p.plan_name, COUNT(*) AS event_count
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.start_date > '2020-12-31'
GROUP BY 1
ORDER BY 2 DESC;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

-- Count the unique customer IDs associated with the churn plan (plan_id = 4).
-- Churn Percentage = (Churned Customers / Total Unique Customers) * 100.

SELECT 
    COUNT(DISTINCT customer_id) AS churn_customers,
    ROUND((COUNT(DISTINCT customer_id)::DECIMAL / NULLIF((SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0)) * 100, 1) AS churned_percentage
FROM 
    subscriptions
WHERE 
    plan_id = 4;
	
	
-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

--  The LEAD window function finds the subsequent plan (next_plan) for each customer based on start_date.
--  Identify customers whose initial plan was a free trial (plan_id = 0) and whose next_plan is churn (plan_id = 4).
--  Count such customers and calculate the percentage relative to the total unique customers in the dataset.

WITH next_plans AS (
SELECT *,
          lead(plan_id, 1) over(PARTITION BY customer_id
          ORDER BY start_date) AS next_plan
   FROM subscriptions) , 
churned_customers AS (
	   SELECT *
   FROM next_plans
   WHERE next_plan=4
     AND plan_id=0) 
  SELECT COUNT (customer_id) AS churned_after_trial,
  ROUND (100 *COUNT(customer_id)/
               (SELECT count(DISTINCT customer_id) AS distinct_customers
                FROM subscriptions),0) AS churn_percentage
FROM churned_customers;

-- 6. What is the number and percentage of customer plans after their initial free trial?

--  The LAG window function retrieves the previous plan (previous_plan) for each customer based on start_date.
-- Focus on customers whose previous plan was a free trial (plan_id = 0).
-- Group the results by plan_name and calculate:
--         - The count of customers transitioning to each plan.
--         - The percentage of total customers who chose each plan after the trial.

WITH previous_plans AS (
  SELECT *,
         LAG(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS previous_plan
  FROM subscriptions
  JOIN plans USING (plan_id)
)
SELECT plan_name,
       COUNT(customer_id) AS customer_count,
       ROUND(100.0 * COUNT(DISTINCT customer_id) / 
             (SELECT COUNT(DISTINCT customer_id) 
              FROM subscriptions), 1) AS customer_percentage
FROM previous_plans
WHERE previous_plan = 0
GROUP BY 1
ORDER BY 2 DESC;
	
-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

-- Identify the latest active plan for each customer as of 2020-12-31 using row_number().
-- Filter customers based on their most recent subscription plan.
-- Calculate the count and percentage breakdown for each plan_name.

WITH latest_plans AS(
    SELECT *,
           row_number() over(PARTITION BY customer_id
                             ORDER BY start_date DESC) AS latest_plan
    FROM subscriptions
    JOIN plans USING (plan_id)
    WHERE start_date <= '2020-12-31'
)
SELECT 
       plan_name,
       COUNT(customer_id) AS customer_count,
       round(100.0 * COUNT(customer_id) / 
             (SELECT COUNT(DISTINCT customer_id)
              FROM subscriptions
              WHERE start_date <= '2020-12-31'),1)AS percentage
FROM latest_plans
WHERE latest_plan = 1   
GROUP BY 1
ORDER BY 2 DESC;

-- 8. How many customers have upgraded to an annual plan in 2020?

-- Filter for subscriptions that started in 2020 using the date range.
-- Focus on the "pro annual" plan by filtering with plan_id = 3.
-- Count the total number of unique customers who upgraded to this plan.

SELECT plan_name, COUNT(customer_id) AS total_customers
    FROM subscriptions
    JOIN plans USING (plan_id)
    WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31'
	AND plan_id = 3
	GROUP BY 1;


-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

-- Determine the first subscription date for each customer.
-- Identify the date when each customer upgraded to an annual plan (plan_id = 3).
-- Calculate the difference in days between these two dates, considering only customers who upgraded.
-- Compute the average difference across all relevant customers.

WITH customer_plans AS (
    SELECT 
        customer_id,
        MIN(start_date) AS first_start_date,
        MAX(CASE WHEN plan_id = 3 THEN start_date END) AS annual_plan_start_date
    FROM subscriptions s
    JOIN plans USING (plan_id)
    GROUP BY customer_id
) SELECT COUNT (customer_id) AS customer_count,
ROUND(AVG((annual_plan_start_date - first_start_date)::integer), 0) AS avg_days_until_annual_plan
FROM customer_plans
WHERE annual_plan_start_date IS NOT NULL;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

-- Calculate the difference in days between a customer's first subscription and their annual plan upgrade date.
-- Divide customers into predefined 30-day segments for analysis.
-- Calculate the total number of customers for each segment.

WITH customer_plans AS (
    SELECT 
        customer_id,
        MIN(start_date) AS first_start_date,
        MAX(CASE WHEN plan_id = 3 THEN start_date END) AS annual_plan_start_date
    FROM subscriptions s
    JOIN plans USING (plan_id)
    GROUP BY customer_id
),
annual_plan AS (
    SELECT 
        customer_id,
        (annual_plan_start_date - first_start_date)::integer AS days_until_annual
    FROM customer_plans
    WHERE annual_plan_start_date IS NOT NULL
)
SELECT 
    CASE 
        WHEN days_until_annual <= 30 THEN '0-30 Days'
        WHEN days_until_annual BETWEEN 31 AND 60 THEN '31-60 Days'
        WHEN days_until_annual BETWEEN 61 AND 90 THEN '61-90 Days'
        WHEN days_until_annual BETWEEN 91 AND 120 THEN '91-120 Days'
		WHEN days_until_annual BETWEEN 121 AND 150 THEN '121-150 Days'
		WHEN days_until_annual BETWEEN 151 AND 180 THEN '151-180 Days' 
        ELSE '180+ Days'
    END AS segmented_days,
    COUNT(customer_id) AS customers
FROM annual_plan
GROUP BY segmented_days
ORDER BY 
    MIN(days_until_annual);

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH next_plans AS (
SELECT *,
          lead(plan_id, 1) over(PARTITION BY customer_id
          ORDER BY start_date) AS next_plan
   FROM subscriptions)
SELECT COUNT(*) AS downgrade_count
FROM next_plans np 
WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31'
AND plan_id = 2 AND next_plan = 1;

-- C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments

CREATE TABLE payments (
  customer_id INTEGER,
  plan_id INTEGER,
  plan_name VARCHAR(20),
  payment_date DATE,
  amount DECIMAL(5,2),
  payment_order INTEGER
);

WITH RECURSIVE RecursivePayments AS (
  -- Step 1: Generate the first payment based on the start_date for each customer
  SELECT 
    s.customer_id, 
    s.plan_id, 
    p.plan_name, 
    s.start_date::DATE AS payment_date,  -- Ensure the payment date is based on start_date
    p.price AS amount, 
    1 AS payment_order
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE (p.plan_name LIKE '%monthly%' OR p.plan_name = 'pro annual')  -- Monthly and annual plans
  
  UNION ALL
  
  -- Step 2: Recursively generate subsequent monthly payments for monthly plans only
  SELECT 
    rp.customer_id, 
    rp.plan_id, 
    rp.plan_name, 
    (rp.payment_date + INTERVAL '1 month')::DATE AS payment_date,  -- Generate next month's payment
    rp.amount, 
    rp.payment_order + 1 AS payment_order
  FROM RecursivePayments rp
  JOIN subscriptions s ON rp.customer_id = s.customer_id
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE 
    rp.plan_name LIKE '%monthly%'  -- Only continue payments for monthly plans
    AND rp.payment_date + INTERVAL '1 month' <= '2020-12-31'  -- Generate payments up to the end of 2020
)

-- Step 3: Handle churn and upgrades
INSERT INTO payments (customer_id, plan_id, plan_name, payment_date, amount, payment_order)
SELECT DISTINCT rp.customer_id, rp.plan_id, rp.plan_name, rp.payment_date, rp.amount, rp.payment_order
FROM RecursivePayments rp
WHERE NOT EXISTS (
  SELECT 1 FROM subscriptions s 
  WHERE s.customer_id = rp.customer_id 
  AND s.plan_id = 4  -- Plan ID for churn
  AND s.start_date <= rp.payment_date -- No payments after churn
)
ORDER BY rp.customer_id, rp.payment_order;


SELECT * FROM payments
LIMIT 100;

-- D. Outside The Box Questions
-- 1. How would you calculate the rate of growth for Foodie-Fi?

-- Aggregate revenue by month using the payment data.
-- Use both numerical and formatted month values for sorting and display.
-- Growth Rate= (Current Month Revenue − Previous Month Revenue) / Previous Month Revenue

WITH
  monthly_revenue AS (
    SELECT
      EXTRACT(MONTH FROM payment_date) AS payment_month,
      TO_CHAR(payment_date, 'Month') AS month,
      SUM(amount) AS revenue
    FROM
      payments
    GROUP BY
      TO_CHAR(payment_date, 'Month'),
      EXTRACT(MONTH FROM payment_date)
  )
SELECT
  payment_month,
  month,
  ROUND(revenue, 2) AS revenue,
  ROUND((revenue - LAG(revenue) OVER (ORDER BY payment_month)) / revenue, 2) AS revenue_growth
FROM
  monthly_revenue
ORDER BY
  payment_month;
  
