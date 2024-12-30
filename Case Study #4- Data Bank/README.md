# Case Study #4: Data Bank

<img src="https://8weeksqlchallenge.com/images/case-study-designs/4.png" alt="Image" width="450" height="470">

## Table of Contents
- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Data Overview](#data-overview)
- [Case Study Questions and Solutions](#case-study-questions-and-solutions)
    - [A-Customer Nodes Exploration](#a-customer-nodes-exploration)
    - [B-Customer Transactions](#b-customer-transactions)
    - [C-Data Allocation Challenge](#c-data-allocation-challenge)

You can visit the official [8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-4/) website for a comprehensive overview of the original case study.   

---
## Introduction
Data Bank is an innovative digital-only bank that combines traditional banking services with a cutting-edge, secure distributed data storage platform. Customers' data storage limits are directly linked to their account balances, creating a unique blend of financial and data management services. Established to bridge the gap between Neo-Banks, cryptocurrency, and data analytics, Data Bank operates entirely online, eliminating the need for physical branches.

---
## Problem Statement
With a focus on expanding its customer base and enhancing data utilization, Data Bank leverages advanced analytics to gain insights into user behavior and forecast future needs. This case study explores key metrics and strategies to optimize operations and drive sustainable growth.

---

## Data Overview


<details>
  <summary>Table 1: Regions</summary>

The Regions table represents the global distribution of nodes, similar to branches in traditional banking. Each node is associated with a specific region.

| Column Name | Description                              |
|-------------|------------------------------------------|
| region_id   | Unique identifier for each region.       |
| region_name | Name of the region.                      |

</details>

<details>
  <summary>Table 2: Customer Nodes</summary>

Customers' data and cash are distributed across different nodes, which are mapped to their respective regions.  

| Column Name  | Description                                                  |
|---------------|--------------------------------------------------------------|
| customer_id   | Unique identifier for each customer.                        |
| region_id     | Identifier linking the customer to their region.             |
| node_id       | Identifier for the node where the customer's data resides.  |
| start_date    | The start date of the customer's data allocation on the node.|
| end_date      | The end date of the customer's data allocation on the node.  |

</details>

<details>
  <summary>Table 3: Customer Transactions</summary>

This table logs customer transactions, including deposits, withdrawals, and purchases made using Data Bank debit cards.

| Column Name  | Description                                     |
|---------------|-------------------------------------------------|
| customer_id   | Unique identifier for each customer.           |
| txn_date      | The date of the transaction.                    |
| txn_type      | The type of transaction (e.g., deposit, withdrawal). |
| txn_amount    | The amount involved in the transaction.         |

</details>

### ERD Diagram

![alt text](https://github.com/beyzabasarir/8-Week-SQL-Challenge/blob/main/Case%20Study%20%234-%20Data%20Bank/ERD.png)

--- 

## Case Study Questions and Solutions

### A-Customer Nodes Exploration

#### 1. How many unique nodes are there on the Data Bank system?

```sql
SELECT COUNT(DISTINCT(node_id)) AS unique_nodes
FROM customer_nodes;
```

| unique_nodes |
|--------------|
|5             |

---

### 2.	 What is the number of nodes per region?

```sql
SELECT cn.region_id, region_name,
COUNT(node_id) AS node_number 
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY 1,2
ORDER BY 3 DESC;
```

| region_id | region_name | node_number |
|-----------|-------------|-------------|
| 1         | Australia   | 770         |
| 2         | America     | 735         |
| 3         | Africa      | 714         |
| 4         | Asia        | 665         |
| 5         | Europe      | 616         |

The data reveals that Australia has the highest number of nodes, followed by America and Africa.

---

#### 3.	 How many customers are allocated to each region?

```sql
SELECT region_name,
COUNT(DISTINCT(customer_id)) AS customer_count 
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY 1
ORDER BY 2 DESC;
```

| region_id | region_name | node_number |
|-----------|-------------|-------------|
| 1         | Australia   | 770         |
| 2         | America     | 735         |
| 3         | Africa      | 714         |
| 4         | Asia        | 665         |
| 5         | Europe      | 616         |

Australia has the highest number of customers, followed closely by America and Africa. Europe has the lowest customer allocation among the regions.

---

#### 4.	 How many days on average are customers reallocated to a different node?

_Note: Records with the outlier date of 9999-12-31 were excluded from the calculation to ensure the accuracy of the results._

```sql
SELECT MAX (end_date) FROM customer_nodes;
```
| max_date    |
|-------------|
|9999-12-31   |


```sql
SELECT ROUND(AVG(end_date - start_date),0) AS avg_days
FROM customer_nodes
WHERE end_date != '9999-12-31';
```

| avg_days    |
|-------------|
|15           |

On average, customers are reallocated to a different node every 15 days. 

---

#### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region? 

```sql
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
```
| region_name | median | p80 | p95 |
|-------------|--------|-----|-----|
|  Africa     | 15     | 24  | 28  |
|  America    | 15     | 23  | 28  |
|  Asia       | 15     | 23  | 28  |
|  Australia  | 15     | 23  | 28  |
|  Europe     | 15     | 24  | 28  |

The median reallocation duration is consistent at 15 days across all regions. The 80th and 95th percentiles show slight regional variations, with most values clustering around 23–28 days, indicating similar patterns in reallocation times across regions.

---

### B-Customer Transactions

#### 1.  What is the unique count and total amount for each transaction type?

```sql
SELECT txn_type, 
       COUNT(*) AS transaction_count,
       SUM (txn_amount) AS total_amount
FROM customer_transactions
GROUP BY 1
ORDER BY 2 DESC;
```

| txn_type   | transaction_count | total_amount |
|------------|-------------------|--------------|
|  deposit   | 2671              | 1359168      |
|  purchase  | 1617              | 806537       |
|  withdrawal| 1580              | 793003       |

Deposits are the most frequent transaction type, both in count and total amount. Withdrawals and purchases follow, with similar transaction amounts but differing frequencies.

---

#### 2. What is the average total historical deposit counts and amounts for all customers?

```sql
WITH historical_deposit AS (
SELECT customer_id, txn_type,
       COUNT(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END ) AS deposit_count,
	   SUM (CASE WHEN txn_type = 'deposit' THEN txn_amount END ) AS total_amount
	   FROM customer_transactions
	   GROUP BY 1,2 )
	   SELECT txn_type, 
	   ROUND(AVG (deposit_count), 2) avg_count,
	   ROUND(AVG (total_amount), 2) AS avg_amount
	   FROM historical_deposit
	   WHERE txn_type ='deposit' 
	   GROUP BY 1;
```

| avg_count | avg_amount |
|-----------|------------|
| 5         | 2718.34   |

On average, each customer made 5 deposit transactions, with a cumulative average amount of $2,718.34, indicating a moderate level of engagement.

---

#### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

```sql
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
```

| month_name | customer_count |
|------------|----------------|
| January    | 115            |
| February   | 108            |
| March      | 113            |
| April      | 50             |


The highest customer activity was observed in January, with 115 customers meeting the specified criteria.

#### 4. What is the closing balance for each customer at the end of the month?

```sql
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
```

##### Sample Output for Customers 1-5:

| customer_id | month | closing_balance |
|-------------|-------|-----------------|
| 1           | 1     | 312             |
| 1           | 3     | -640            |
| 2           | 1     | 549             |
| 2           | 3     | 610             |
| 3           | 1     | 144             |
| 3           | 2     | -821            |
| 3           | 3     | -1222           |
| 3           | 4     | -729            |
| 4           | 1     | 848             |
| 4           | 3     | 655             |
| 5           | 1     | 954             |
| 5           | 3     | -1923           |
| 5           | 4     | -2413           |
---

#### 5. What is the percentage of customers who increase their closing balance by more than 5%?

_Note: In this query, the evaluation has been expanded to include scenarios where customers with negative balances move into positive territory or significantly reduce their deficit by more than 5%._

```sql
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
```

| percentage_increase |
|---------------------|
|55.16                |

Approximately 55.16% of customers were found to increase their closing balance by more than 5%. 

---

### C-Data Allocation Challenge

#### To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time

For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

#### Running customer balance column that includes the impact each transaction

```sql
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
```
##### Sample Output for Customers 1-5:

| customer_id | txn_type  | txn_date  | txn_amount | running_balance |
|-------------|-----------|-----------|------------|-----------------|
| 1           | deposit   | 2020-01-02 | 312        | 312             |
| 1           | purchase  | 2020-03-05 | 612        | -300            |
| 1           | deposit   | 2020-03-17 | 324        | 24              |
| 1           | purchase  | 2020-03-19 | 664        | -640            |
| 2           | deposit   | 2020-01-03 | 549        | 549             |
| 2           | deposit   | 2020-03-24 | 61         | 610             |
| 3           | deposit   | 2020-01-27 | 144        | 144             |
| 3           | purchase  | 2020-02-22 | 965        | -821            |
| 3           | withdrawal| 2020-03-05 | 213        | -1034           |
| 3           | withdrawal| 2020-03-19 | 188        | -1222           |
| 3           | deposit   | 2020-04-12 | 493        | -729            |
| 4           | deposit   | 2020-01-07 | 458        | 458             |
| 4           | deposit   | 2020-01-21 | 390        | 848             |
| 4           | purchase  | 2020-03-25 | 193        | 655             |
| 5           | deposit   | 2020-01-15 | 974        | 974             |
| 5           | deposit   | 2020-01-25 | 806        | 1780            |
| 5           | withdrawal| 2020-01-31 | 826        | 954             |
| 5           | purchase  | 2020-03-02 | 886        | 68              |
| 5           | deposit   | 2020-03-19 | 718        | 786             |
| 5           | withdrawal| 2020-03-26 | 786        | 0               |
| 5           | withdrawal| 2020-03-27 | 700        | -288            |
| 5           | deposit   | 2020-03-27 | 412        | -288            |
| 5           | purchase  | 2020-03-29 | 852        | -1140           |
| 5           | purchase  | 2020-03-31 | 783        | -1923           |
| 5           | withdrawal| 2020-04-02 | 490        | -2413           |



The cumulative balance for each customer is calculated to reflect the impact of every transaction. This method may be suited for real-time allocation (Option 3), as it provides precise and up-to-date information. However, the need for continuous updates and higher storage could make it more resource-intensive.

---

#### Customer balance at the end of each month

```sql
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
```

##### Sample Output for Customers 1-5:

| customer_id | month      | balance |
|-------------|------------|---------|
| 1           | January    | 312     |
| 1           | March      | -952    |
| 2           | January    | 549     |
| 2           | March      | 61      |
| 3           | April      | 493     |
| 3           | February   | -965    |
| 3           | January    | 144     |
| 3           | March      | -401    |
| 4           | January    | 848     |
| 4           | March      | -193    |
| 5           | April      | -490    |
| 5           | January    | 954     |
| 5           | March      | -2877   |


Balances at the end of each month are summarized, which could be ideal for monthly allocation (Option 1). By focusing only on month-end values, data volume is minimized efficiently. However, intra-month fluctuations may not be captured, potentially reducing accuracy for customers with variable balances.

---

#### Minimum, average and maximum values of the running balance for each customer

```sql
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
```


##### Sample Output for Customers 1-5:

| customer_id | min_running_balance | avg_running_balance | max_running_balance |
|-------------|---------------------|---------------------|---------------------|
| 1           | -640                | -151.00             | 312                 |
| 2           | 549                 | 579.50              | 610                 |
| 3           | -1222               | -732.40             | 144                 |
| 4           | 458                 | 653.67              | 848                 |
| 5           | -2413               | -135.45             | 1780                |


Key metrics, including minimum, average, and maximum running balances, are determined for each customer. This approach may support average-based allocation (Option 2), offering a balanced view of data needs. While less demanding than real-time updates, its effectiveness could vary depending on the consistency of customer balances over time.

---

#### Using all of the data available - how much data would have been required for each option on a monthly basis?

When assessing the data requirements for each option, the monthly provision calculations highlight several differences:

- Option 1:
    - Minimizes data storage and is simple to implement.
    - However, it may overlook intra-month variations in customer behavior.
- Option 2:
    - Provides a more comprehensive view of customer behavior.
    - Balances computational efficiency and data accuracy.
    - Avoids the high computational and storage costs of real-time tracking.
- Option 3:
    - Offers the highest accuracy and flexibility for real-time allocation.
    - Comes with significant computational and storage overhead.

Option 2 appears to be the best compromise, balancing data accuracy with computational efficiency. It allows for responsive allocation while minimizing the resource demands associated with real-time tracking. The estimated data requirements for Option 2 can align well with practical resource management, ensuring effective performance with minimal complexity.

---
