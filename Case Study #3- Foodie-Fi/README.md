# Case Study #3: Foodie-Fi

<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png" alt="Image" width="450" height="470">

## Table of Contents
- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Data Overview](#data-overview)
- [Case Study Questions and Solutions](#case-study-questions-and-solutions)
    - [A-Customer Journey](#a-customer-journey)
    - [B-Data Analysis Questions](#b-data-analysis-questions)
    - [C-Challenge Payment Question](#c-challenge-payment-question)
    - [D-Outside The Box Questions](#d-outside-the-box-questions)


For a comprehensive overview of the original case study, you can visit the official [8 Week SQL Challenge website](https://8weeksqlchallenge.com/case-study-3/).

---
## Introduction
Foodie-Fi is a subscription-based streaming service designed exclusively for food enthusiasts, providing unlimited access to culinary videos, cooking shows, and related content from around the world. Founded in 2020, it offers flexible subscription plans tailored to diverse user needs, including free trials, monthly subscriptions, and annual options. The service aims to leverage data-driven insights to optimize business strategies, understand customer behavior, and drive growth.

---
## Problem Statement
This case study utilizes subscription-style data to address business questions, focusing on two primary tables: plans and subscriptions. Our objective is to analyze user behavior, plan engagement, and churn trends, providing actionable insights to support strategic decisions.

---

## Data Overview
This case study emphasizes two core tables: plans and subscriptions. Below is a brief summary of each table, along with the relevant entity-relationship diagram (ERD).

<details>
  <summary>Table 1: Plans</summary>

| plan_id | plan_name      | price |
|---------|----------------|-------|
| 0       | trial          | 0     |
| 1       | basic monthly  | 9.90  |
| 2       | pro monthly    | 19.90 |
| 3       | pro annual     | 199   |
| 4       | churn          | null  |

Plan Details:
-	Trial Plan: A free 7-day trial that transitions to a pro monthly subscription unless the customer cancels or downgrades.
-	Basic Monthly Plan: Limited access with streaming capabilities at $9.90 per month.
-	Pro Monthly Plan: No viewing limits and includes offline downloads, costing $19.90 per month.
- Pro Annual Plan: Similar to the pro monthly plan but offered at $199 per year.
- Churn: Represents canceled subscriptions, effective until the end of the billing cycle.

</details>

<details>
  <summary> Table 2: Subscriptions</summary>

| customer_id | plan_id | start_date |
|-------------|---------|------------|
| 1           | 0       | 2020-08-01 |
| 1           | 1       | 2020-08-08 |
| 2           | 0       | 2020-09-20 |
| 2           | 3       | 2020-09-27 |
| 11          | 0       | 2020-11-19 |
| 11          | 4       | 2020-11-26 |
| 13          | 0       | 2020-12-15 |
| 13          | 1       | 2020-12-22 |
| 13          | 2       | 2021-03-29 |

-	The start_date represents the date a new plan becomes active.
-	Customers can upgrade or downgrade plans, with the higher plan remaining effective until its billing period ends.
-	Churn records indicate cancellations, allowing continued access until the end of the current cycle.

</details>

### ERD Diagram

![alt text](https://github.com/beyzabasarir/8-Week-SQL-Challenge/blob/main/Case%20Study%20%233-%20Foodie-Fi/ERD.png)

--- 

## Case Study Questions and Solutions

### A-Customer Journey

#### Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

```sql
SELECT customer_id, start_date, plan_name, price 
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);
```

| customer_id | start_date  | plan_name      | price  |
|-------------|-------------|----------------|--------|
| 1           | 2020-08-01  | trial          | 0.00   |
| 1           | 2020-08-08  | basic monthly  | 9.90   |
| 2           | 2020-09-20  | trial          | 0.00   |
| 2           | 2020-09-27  | pro annual     | 199.00 |
| 11          | 2020-11-19  | trial          | 0.00   |
| 11          | 2020-11-26  | churn          | NULL   |
| 13          | 2020-12-15  | trial          | 0.00   |
| 13          | 2020-12-22  | basic monthly  | 9.90   |
| 13          | 2021-03-29  | pro monthly    | 19.90  |
| 15          | 2020-03-17  | trial          | 0.00   |
| 15          | 2020-03-24  | pro monthly    | 19.90  |
| 15          | 2020-04-29  | churn          | NULL   |
| 16          | 2020-05-31  | trial          | 0.00   |
| 16          | 2020-06-07  | basic monthly  | 9.90   |
| 16          | 2020-10-21  | pro annual     | 199.00 |
| 18          | 2020-07-06  | trial          | 0.00   |
| 18          | 2020-07-13  | pro monthly    | 19.90  |
| 19          | 2020-06-22  | trial          | 0.00   |
| 19          | 2020-06-29  | pro monthly    | 19.90  |
| 19          | 2020-08-29  | pro annual     | 199.00 |

The onboarding journeys of the sample customers show diverse paths:
- Some transitioned directly from a trial to a higher-tier plan like pro annual (e.g., Customer 2, 16).
- Others initially subscribed to basic monthly before upgrading to pro plans (e.g., Customer 13, 19).
- Notably, certain customers churned shortly after trying or subscribing to initial plans (e.g., Customer 11, 15).

---

### B-Data Analysis Questions

#### 1. How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT(DISTINCT(customer_id)) AS unique_customers
FROM subscriptions;
```

| unique_customers |
|------------------|
|1000              |

Foodie-Fi has had a total of 1,000 unique customers.

---

#### 2.	 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

```sql
SELECT TO_CHAR (DATE_TRUNC('month',start_date), 'MM') AS trial_start_month, 
       COUNT (customer_id) AS customer_count
FROM subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY 1;
```
| trial_start_month | customer_count |
|-------------------|----------------|
| 01                | 88             |
| 02                | 68             |
| 03                | 94             |
| 04                | 81             |
| 05                | 88             |
| 06                | 79             |
| 07                | 89             |
| 08                | 88             |
| 09                | 87             |
| 10                | 79             |
| 11                | 75             |
| 12                | 84             |


The monthly distribution of trial plan starts is relatively consistent, with March (94) and July (89) showing the highest counts. February has the fewest trial starts (68).

---

#### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

```sql
SELECT p.plan_name, COUNT(*) AS event_count
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.start_date > '2020-12-31'
GROUP BY 1
ORDER BY 2 DESC;
```

| plan_name      | event_count |
|----------------|-------------|
| churn          | 71          |
| pro annual     | 63          |
| pro monthly    | 60          |
| basic monthly  | 8           |


The majority of plan events after 2020 relate to "churn" (71 occurrences), highlighting customer attrition. "Pro annual" (63) and "pro monthly" (60) plans also saw significant activity, indicating higher adoption of premium plans, while "basic monthly" had minimal engagement (8 events).

---

#### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

```sql
SELECT 
    COUNT(DISTINCT customer_id) AS churn_customers,
    ROUND((COUNT(DISTINCT customer_id)::DECIMAL / NULLIF((SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0)) * 100, 1) AS churned_percentage
FROM 
    subscriptions
WHERE 
    plan_id = 4;
```

| churn_customers      | churned_percentage |
|----------------------|--------------------|
| 307                  | 30.7               |

	
Out of all customers, 307 have churned, representing 30.7% of the total customer base. This indicates a significant proportion of customers who did not maintain long-term engagement, which can serve as a key point for retention strategies.

---

#### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
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
```

| churned_after_trial  | churn_percentage   |
|----------------------|--------------------|
| 92                   | 9                  |

A total of 92 customers churned immediately after completing their free trial, accounting for 9% of the total customer base.

---

#### 6. What is the number and percentage of customer plans after their initial free trial?

```sql
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
```

| plan_name      | customer_count | customer_percentage |
|----------------|----------------|---------------------|
| basic monthly  | 546            | 54.6                |
| pro monthly    | 325            | 32.5                |
| churn          | 92             | 9.2                 |
| pro annual     | 37             | 3.7                 |

After the initial free trial, 54.6% of customers transitioned to the "Basic Monthly" plan, making it the most popular choice. The "Pro Monthly" plan follows with 32.5%, while 9.2% of customers churned immediately. Only a small proportion (3.7%) upgraded directly to the "Pro Annual" plan, indicating that most customers prefer lower commitment options after the trial period.

---

#### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

```sql
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
```
| plan_name      | customer_count | percentage |
|----------------|----------------|------------|
| pro monthly    | 326            | 32.6       |
| churn          | 236            | 23.6       |
| basic monthly  | 224            | 22.4       |
| pro annual     | 195            | 19.5       |
| trial          | 19             | 1.9        |

By the end of 2020, the "pro monthly" plan had the highest engagement, accounting for 32.6% of customers. This is followed by "churn" at 23.6%, highlighting the importance of retention strategies. "Basic monthly" and "pro annual" plans collectively represent significant portions, while the "trial" plan had the least share at 1.9%, indicating limited transition from trial to active plans.

---

#### 8. How many customers have upgraded to an annual plan in 2020?

```sql
SELECT plan_name, COUNT(customer_id) AS total_customers
    FROM subscriptions
    JOIN plans USING (plan_id)
    WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31'
	AND plan_id = 3
	GROUP BY 1;
```

| plan_name  | total_customers    |
|------------|--------------------|
| pro annual | 195                |

A total of 195 customers upgraded to the "pro annual" plan in 2020.

---

#### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

```sql
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
```

| customer_count  | avg_days_until_annual_plan |
|-----------------|----------------------------|
| 258             | 105                        |

Out of all customers, 258 upgraded to the "pro annual" plan, taking an average of 105 days from their initial subscription to make this transition.

---

#### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

```sql
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
```
| segmented_days  | customers |
|-----------------|-----------|
| 0-30 Days       | 49        |
| 31-60 Days      | 24        |
| 61-90 Days      | 34        |
| 91-120 Days     | 35        |
| 121-150 Days    | 42        |
| 151-180 Days    | 36        |
| 180+ Days       | 38        |

According to the data, the most significant number of customers transitioned to an annual plan within the first 30 days. The second-largest cohorts were observed within the 121-150 days and 180+ days ranges.

---

#### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql
WITH next_plans AS (
SELECT *,
          lead(plan_id, 1) over(PARTITION BY customer_id
          ORDER BY start_date) AS next_plan
   FROM subscriptions)
SELECT COUNT(*) AS downgrade_count
FROM next_plans np 
WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31'
AND plan_id = 2 AND next_plan = 1;
```
| downgrade_count  | 
|------------------|
| 0                | 

No customers downgraded from a Pro Monthly plan to a Basic Monthly plan in 2020.

---


### C-Challenge Payment Question

#### The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-	upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-	once a customer churns they will no longer make payments

```sql
CREATE TABLE payments (
  customer_id INTEGER,
  plan_id INTEGER,
  plan_name VARCHAR(20),
  payment_date DATE,
  amount DECIMAL(5,2),
  payment_order INTEGER
);

WITH RECURSIVE RecursivePayments AS (
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
LIMIT 10;
```

##### Output for the first 10 rows

| customer_id | plan_id | plan_name    | payment_date | amount | payment_order |
|-------------|---------|--------------|--------------|--------|---------------|
| 1           | 1       | basic monthly| 2020-08-08   | 9.90   | 1             |
| 1           | 1       | basic monthly| 2020-09-08   | 9.90   | 2             |
| 1           | 1       | basic monthly| 2020-10-08   | 9.90   | 3             |
| 1           | 1       | basic monthly| 2020-11-08   | 9.90   | 4             |
| 1           | 1       | basic monthly| 2020-12-08   | 9.90   | 5             |
| 2           | 3       | pro annual   | 2020-09-27   | 199.00 | 1             |
| 3           | 1       | basic monthly| 2020-01-20   | 9.90   | 1             |
| 3           | 1       | basic monthly| 2020-02-20   | 9.90   | 2             |
| 3           | 1       | basic monthly| 2020-03-20   | 9.90   | 3             |
| 3           | 1       | basic monthly| 2020-04-20   | 9.90   | 4             |

---

### D-Outside The Box Questions

#### 1.	How would you calculate the rate of growth for Foodie-Fi?

```sql
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
```

| payment_month | month      | revenue   | revenue_growth |
|----------------|------------|-----------|----------------|
| 1              | January   | 6654.60   | NULL           |
| 2              | February  | 6424.30   | -0.04          |
| 3              | March     | 6382.10   | -0.01          |
| 4              | April     | 8768.20   | 0.27           |
| 5              | May       | 7561.90   | -0.16          |
| 6              | June      | 9241.20   | 0.18           |
| 7              | July      | 11040.50  | 0.16           |
| 8              | August    | 13276.90  | 0.17           |
| 9              | September | 14688.20  | 0.10           |
| 10             | October   | 17104.50  | 0.14           |
| 11             | November  | 15451.00  | -0.11          |
| 12             | December  | 16414.70  | 0.06           |

The growth rate fluctuates throughout the year, with significant peaks in April (27%), June (18%), and July (16%). The negative growth rates in February (-4%) and May (-16%) indicate a drop in revenue, while the overall trend suggests positive growth, especially in the second half of the year.

---

#### 2.	What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

To assess performance, management can track these metrics:
-	Monthly Recurring Revenue (MRR): Tracks revenue consistency from subscriptions.
-	Churn Rate: Percentage of customers canceling their subscriptions.
-	Customer Lifetime Value (CLV): Measures the total revenue a customer generates over their lifetime.
-	Retention Rate: Percentage of customers retained over time.

---

#### 3.	What are some key customer journeys or experiences that you would analyse further to improve customer retention?
To improve customer retention, we can further analyze the following key customer experiences:
-	By examining content consumption patterns, we can identify which types of content resonate most with customers and understand the factors driving their engagement.
-	Analyzing transaction data and customer feedback provides valuable insights into customer behavior during plan upgrades or downgrades.
-	Reviewing payment and renewal data can highlight potential friction points, such as failed payments or delayed renewals, that may negatively impact customer satisfaction.
-	Studying customer behavior before cancellations—such as a decline in usage or increasing negative feedback—can help us detect early warning signs, allowing us to take proactive steps to retain these customers.

---

****4.	If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

Key questions could include:

1.	What was your primary reason for canceling your subscription?
2.	Was there a specific feature or experience that didn’t meet your expectations?
3.	How would you rate the value for money of your subscription?
4.	Were there any technical or usability issues?
5.	Would you consider re-subscribing in the future? Why or why not?
6.	What improvements or new features would encourage you to stay?

---

#### 5.	What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

The following strategies could be considered to reduce customer churn for Foodie-Fi:
-	Offering time-sensitive discounts could help retain customers who are considering cancellation.
-	Providing tailored, flexible plans would allow Foodie-Fi to meet the various needs of its customers.
-	Implementing proactive customer support can address user issues promptly and enhance satisfaction.
-	Personalizing recommendations based on user preferences could increase engagement and prevent churn.
-	Launching targeted recovery campaigns for churned customers may help win back lost users.
To validate the effectiveness of these strategies, key metrics such as churn rate, retention rate, and customer satisfaction should be measured before and after implementation. A/B testing can be leveraged to compare the impact of these strategies.

---


