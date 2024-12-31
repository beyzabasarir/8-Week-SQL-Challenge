# Case Study #7: Balanced Tree Clothing Co.

<img src="https://8weeksqlchallenge.com/images/case-study-designs/7.png" alt="Image" width="450" height="470">

## Table of Contents
- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Data Overview](#data-overview)
- [Case Study Questions and Solutions](#case-study-questions-and-solutions)
    - [A-High Level Sales Analysis](#a-high-level-sales-analysis)
    - [B-Transaction  Analysis](#b-transaction-analysis)
    - [C-Product Analysis](#c-product-analysis)
- [Reporting Challenge](#reporting-challenge)
- [Bonus Challenge](#bonus-challenge)

For the original context and further details, please refer to the [8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-7/) website. 

---
## Introduction
Balanced Tree Clothing Company is a retailer offering a curated selection of clothing and lifestyle products designed to meet diverse customer preferences. The company places emphasis on functionality and versatility in its product range, catering to the needs of its customers.

---
## Problem Statement
The analysis focuses on examining sales transactions and product details to address key business questions related to sales trends, product performance, and customer behavior.
The primary goal is to identify patterns and trends that can inform business strategy and operational improvements.


---
## Data Overview

This case study involves four datasets, two of which are central to the analysis, while the remaining two are utilized for bonus questions. The key datasets and their columns are outlined below:

<details>
  <summary>Table 1: Product Details</summary>

- This table provides detailed information about the products offered by Balanced Tree.
 
| Column        | Description                                                        |
|---------------|--------------------------------------------------------------------|
| `product_id`    | Unique identifier for each product.                                |
| `price`         | Retail price of the product.                                       |
| `product_name`  | Name of the product, including descriptive details.                |
| `category_id`   | Identifier for the product's category.                             |
| `segment_id`    | Identifier for the product's segment (subcategory).               |
| `style_id`      | Identifier for the product's specific style.                       |
| `category_name` | The category of the product (e.g., Mens, Womens).                  |
| `segment_name`  | The segment of the product (e.g., Jeans, Shirts).                  |
| `style_name`    | The style description of the product (e.g., Navy Oversized, White Tee). |

</details>

<details>
  <summary>Table 2: Product Sales</summary>

-   This table contains transactional data for each product sold.
  
| Column            | Description                                                       |
|-------------------|-------------------------------------------------------------------|
| `prod_id`           | Unique identifier for the product.                                |
| `qty`               | Quantity of the product sold in a transaction.                    |
| `price`             | Sale price of the product during the transaction.                 |
| `discount`          | Percentage discount applied to the product.                       |
| `member`            | Indicates whether the customer is a member (true/false).          |
| `txn_id`            | Unique identifier for the transaction.                            |
| `start_txn_time`    | Timestamp when the transaction occurred.                          |

</details>

<details>
  <summary>Table 3: Product Hierarchy</summary>
  
| Column      | Description                                                       |
|-------------|-------------------------------------------------------------------|
| `id`          | Unique identifier for each record in the hierarchy.               |
| `parent_id`   | Reference to the parent level's identifier.                       |
| `level_text`  | Descriptive label for the hierarchy level (e.g., Mens, Womens).   |
| `level_name`  | Classification of the level (e.g., Category, Segment, Style).     |

</details>

<details>
  <summary>Table 4: Product Prices</summary>
  
| Column        | Description                                                       |
|---------------|-------------------------------------------------------------------|
| `id`            | Unique identifier for the price record.                           |
| `product_id`    | Reference to the product identifier from the product details table. |
| `price`         | Retail price of the product in the respective price record.       |

</details>

---

## Case Study Questions and Solutions

### A-High Level Sales Analysis

#### 1. What was the total quantity sold for all products?

```sql
SELECT SUM(qty) AS total_product_sold
FROM sales
```
| total_product_sold |
|--------------------|
| 45216              | 

A total of 45,216 units of products were sold across all transactions.

---

#### 2.	What is the total generated revenue for all products before discounts?


```sql
SELECT TO_CHAR(SUM(qty * price), '$999,999,999') AS revenue_before_discount
FROM sales;
```

| revenue_before_discount |
|-------------------------|
| $   1,289,453           | 

The gross revenue generated before applying discounts amounts to $1,289,453.

---

#### 3.	What was the total discount amount for all products?

```sql
SELECT 
	TO_CHAR(SUM(price * qty * discount)/100.0 , '$999,999.99') AS total_discount
FROM sales;
```
| total_discount |
|----------------|
| $ 156,229.14   | 

The total discount provided across all transactions was $156,229.00.

---

### B-Transaction Analysis

#### 1.	How many unique transactions were there?

```sql
SELECT COUNT(DISTINCT (txn_id)) AS unique_txn 
FROM sales;
```

| unique_txn |
|------------|
| 2500       | 

There were 2,500 unique transactions recorded.

---

#### 2.	What is the average unique products purchased in each transaction?

```sql
WITH prod_counts AS (
SELECT txn_id, 
       COUNT(DISTINCT prod_id) AS product_count
FROM sales 
GROUP BY 1 ) 
SELECT ROUND(AVG(product_count),0) AS avg_unique_products
FROM prod_counts;
```

| avg_unique_products |
|---------------------|
| 6                   | 

On average, customers purchased 6 unique products per transaction.

---

#### 3.	What are the 25th, 50th and 75th percentile values for the revenue per transaction?

```sql
WITH revenue AS (
SELECT *, 
       ROUND(qty * price * (1 - discount / 100.0),2) AS revenue_per_transaction
FROM sales
ORDER BY revenue_per_transaction  )
SELECT percentile_cont(0.25) WITHIN GROUP (ORDER BY revenue_per_transaction) AS Q1,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY revenue_per_transaction) AS Q2,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY revenue_per_transaction) AS Q3
FROM revenue;
```

| Q1    | Q2     | Q3      |
|-------|--------|---------|
| 31.54 | 55.76  | 103.74  |

The revenue per transaction has a 25th percentile value of $31.54, a median value of $55.76, and a 75th percentile value of $103.74.
		
---

#### 4.	What is the average discount value per transaction?

```sql
SELECT ROUND(AVG(price * qty * discount / 100.0), 2) AS avg_discount_per_transaction
FROM sales;
```

| avg_discount_per_transaction |
|------------------------------|
| 10.35                        | 

---

#### 5.	What is the percentage split of all transactions for members vs non-members?

```sql
WITH txn_total AS (
SELECT COUNT(txn_id) AS total_txn
FROM sales ),
members AS (
SELECT member,
       COUNT (txn_id) AS txn_count
FROM sales 
GROUP BY 1)
SELECT member, 
       ROUND((txn_count::numeric / txn_total.total_txn) * 100, 2) AS txn_percentage
FROM members, txn_total;
```

| member      | txn_percentage |
|-------------|----------------|
| True        | 39.97          |
| False       | 60.03          |

Members account for 60.03% of transactions, while non-members contribute to 39.97%.

---

#### 6.	What is the average revenue for member transactions and non-member transactions?

```sql
SELECT 
    CASE WHEN member = true THEN 'Member' ELSE 'Non-Member' END AS member_status,
    ROUND(AVG(price * qty * (1 - discount / 100.0)), 2) AS avg_revenue_per_transaction
FROM sales
GROUP BY member_status;
```

| member_status      | avg_revenue_per_transaction |
|--------------------|-----------------------------|
| Non-Member         | 74.54                       |
| Member             | 75.43                       |

The average revenue generated per transaction is slightly higher for members, compared to non-members.

---

### C-Product Analysis

#### 1.	What are the top 3 products by total revenue before discount?

```sql 
SELECT product_name, 
       TO_CHAR (SUM(s.price * qty), '$999,999') AS total_revenue
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;
```

| product_name                       | total_revenue |
|------------------------------------|---------------|
| Blue Polo Shirt - Mens             | $ 217,683     |
| Grey Fashion Jacket - Womens       | $ 209,304     |
| White Tee Shirt - Mens             | $ 152,000     |

The Blue Polo Shirt - Mens generated the highest total revenue before discount ($217,683), followed by the Grey Fashion Jacket - Womens and White Tee Shirt - Mens.

---

#### 2.	What is the total quantity, revenue and discount for each segment?

```sql
SELECT segment_name,
      SUM(qty) AS total_quantity,
	  ROUND(SUM(qty * s.price * (1 - discount / 100.0)), 2) AS total_revenue,
	  ROUND(SUM(s.price * qty * discount)/100.0,2) AS total_discount
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1;
```

| segment_name | total_quantity | total_revenue | total_discount |
|--------------|----------------|---------------|----------------|
| Shirt        | 11265          | 356548.73     | 49594.27       |
| Jeans        | 11349          | 183006.03     | 25343.97       |
| Jacket       | 11385          | 322705.54     | 44277.46       |
| Socks        | 11217          | 270963.56     | 37013.44       |


The Shirt segment achieved the highest total revenue ($356,548.73), while Jacket had the largest total quantity sold (11,385 units). Discount values are highest for Shirts.


---

#### 3.	What is the top selling product for each segment?

```sql
WITH ranked_products AS (
SELECT segment_name,
       product_name, 
	   SUM(qty) AS total_quantity,
	   ROW_NUMBER() OVER (PARTITION BY segment_name ORDER BY SUM(qty) DESC) AS rank
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1,2)
SELECT segment_name,
       product_name, 
	   total_quantity
FROM ranked_products
WHERE rank=1;
```

| segment_name | product_name                       | total_quantity |
|--------------|------------------------------------|----------------|
| Jacket       | Grey Fashion Jacket - Womens       | 3876           |
| Jeans        | Navy Oversized Jeans - Womens      | 3856           |
| Shirt        | Blue Polo Shirt - Mens             | 3819           |
| Socks        | Navy Solid Socks - Mens            | 3792           |

The Grey Fashion Jacket - Womens leads the Jacket segment with 3,876 units sold.

---

#### 4.	What is the total quantity, revenue and discount for each category?

```sql
SELECT category_name,
      SUM(qty) AS total_quantity,
	  ROUND(SUM(qty * s.price * (1 - discount / 100.0)), 2) AS total_revenue,
	  ROUND(SUM(s.price * qty * discount)/100.0,2) AS total_discount
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1;
``` 
| category_name | total_quantity | total_revenue | total_discount |
|---------------|----------------|---------------|----------------|
| Mens          | 22482          | 627512.29     | 86607.71       |
| Womens        | 22734          | 505711.57     | 69621.43       |


The Mens category slightly surpasses the Womens category in both total revenue and quantity sold. Discounts in the Mens category are also significantly higher.

---

#### 5.	What is the top selling product for each category?

```sql
WITH ranked_products AS (
SELECT category_name,
       product_name, 
	   SUM(qty) AS total_quantity,
	   ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY SUM(qty) DESC) AS rank
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1,2)
SELECT category_name,
       product_name, 
	   total_quantity
FROM ranked_products
WHERE rank=1;
```

| category_name | product_name                       | total_quantity |
|---------------|------------------------------------|----------------|
| Mens          | Blue Polo Shirt - Mens             | 3819           |
| Womens        | Grey Fashion Jacket - Womens       | 3876           |

The Blue Polo Shirt - Mens and Grey Fashion Jacket - Womens are the top sellers in their respective categories.

---

#### 6.	What is the percentage split of revenue by product for each segment?

```sql
WITH total_segment_revenue AS (
    SELECT 
        segment_name,
        SUM(qty * s.price * (1 - discount / 100.0)) AS total_revenue
    FROM product_details pd
    JOIN sales s ON pd.product_id = s.prod_id
    GROUP BY segment_name
),
product_revenue AS (
    SELECT 
        segment_name,
        product_name, 
        SUM(qty * s.price * (1 - discount / 100.0)) AS product_revenue
    FROM product_details pd
    JOIN sales s ON pd.product_id = s.prod_id
    GROUP BY segment_name, product_name
)
SELECT 
    pr.segment_name,
    pr.product_name,
    ROUND((pr.product_revenue / ts.total_revenue) * 100, 2) AS revenue_percentage
FROM product_revenue pr
JOIN total_segment_revenue ts ON pr.segment_name = ts.segment_name
ORDER BY pr.segment_name, revenue_percentage DESC;
```

| segment_name | product_name                       | revenue_percentage |
|--------------|------------------------------------|--------------------|
| Jacket       | Grey Fashion Jacket - Womens       | 56.99              |
| Jacket       | Khaki Suit Jacket - Womens         | 23.57              |
| Jacket       | Indigo Rain Jacket - Womens        | 19.44              |
| Jeans        | Black Straight Jeans - Womens      | 58.14              |
| Jeans        | Navy Oversized Jeans - Womens      | 24.04              |
| Jeans        | Cream Relaxed Jeans - Womens       | 17.82              |
| Shirt        | Blue Polo Shirt - Mens             | 53.53              |
| Shirt        | White Tee Shirt - Mens             | 37.48              |
| Shirt        | Teal Button Up Shirt - Mens        | 8.99               |
| Socks        | Navy Solid Socks - Mens            | 44.24              |
| Socks        | Pink Fluro Polkadot Socks - Mens   | 35.57              |
| Socks        | White Striped Socks - Mens         | 20.20              |

The Grey Fashion Jacket - Womens contributes over half (56.99%) of the total revenue in the Jacket segment. Similarly, the Black Straight Jeans - Womens dominates the Jeans segment revenue with 58.14%. 

---

#### 7.	What is the percentage split of revenue by segment for each category?

```sql
WITH total_category_revenue AS (
    SELECT 
        category_name,
        SUM(qty * s.price * (1 - discount / 100.0)) AS total_revenue
    FROM product_details pd
    JOIN sales s ON pd.product_id = s.prod_id
    GROUP BY category_name
),
segment_revenue AS (
    SELECT 
        category_name,
        segment_name, 
        SUM(qty * s.price * (1 - discount / 100.0)) AS segment_revenue
    FROM product_details pd
    JOIN sales s ON pd.product_id = s.prod_id
    GROUP BY category_name, segment_name
)
SELECT 
    sr.category_name,
    sr.segment_name,
    ROUND((sr.segment_revenue / tc.total_revenue) * 100, 2) AS revenue_percentage
FROM segment_revenue sr
JOIN total_category_revenue tc ON sr.category_name = tc.category_name
ORDER BY  sr.segment_name,revenue_percentage DESC;
```

| category_name | segment_name | revenue_percentage |
|---------------|--------------|--------------------|
| Womens        | Jacket       | 63.81              |
| Womens        | Jeans        | 36.19              |
| Mens          | Shirt        | 56.82              |
| Mens          | Socks        | 43.18              |

In the Womens category, Jackets dominate the revenue share with 63.81%, while Shirts lead the Mens category with a slightly smaller majority (56.82%).

---

#### 8.	What is the percentage split of total revenue by category?

```sql
WITH total_revenue_cte AS (
SELECT ROUND(SUM(qty * price * (1 - discount / 100.0)), 2) AS total_revenue
FROM sales ),
category_revene AS (
SELECT category_name,
       ROUND(SUM(qty * s.price * (1 - discount / 100.0)), 2) AS category_revenue
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1)
SELECT category_name, 
       ROUND((category_revenue::numeric / total_revenue) * 100, 2) AS revenue_percentage
FROM total_revenue_cte, category_revene;
```

| category_name | revenue_percentage |
|---------------|--------------------|
| Mens          | 55.37              |
| Womens        | 44.63              |

The Mens category accounts for a slightly higher revenue percentage (55.37%) compared to the Womens category (44.63%).

---

#### 9.	What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

```sql
WITH total_transactions AS (
    SELECT COUNT(DISTINCT txn_id) AS total_txn
    FROM sales
),
product_transactions AS (
    SELECT 
        prod_id, 
        COUNT(DISTINCT txn_id) AS product_txn
    FROM sales
    WHERE qty > 0
    GROUP BY prod_id
)
SELECT 
    pt.prod_id,
    pd.product_name,
    ROUND((pt.product_txn::numeric / tt.total_txn) * 100, 2) AS penetration
FROM product_transactions pt
JOIN total_transactions tt ON 1=1  
JOIN product_details pd ON pt.prod_id = pd.product_id  
ORDER BY penetration DESC;
```

| prod_id   | product_name                       | penetration |
|-----------|------------------------------------|-------------|
| f084eb    | Navy Solid Socks - Mens            | 51.24       |
| 9ec847    | Grey Fashion Jacket - Womens       | 51.00       |
| c4a632    | Navy Oversized Jeans - Womens      | 50.96       |
| 2a2353    | Blue Polo Shirt - Mens             | 50.72       |
| 5d267b    | White Tee Shirt - Mens             | 50.72       |
| 2feb6b    | Pink Fluro Polkadot Socks - Mens   | 50.32       |
| 72f5d4    | Indigo Rain Jacket - Womens        | 50.00       |
| d5e9a6    | Khaki Suit Jacket - Womens         | 49.88       |
| e83aa3    | Black Straight Jeans - Womens      | 49.84       |
| e31d39    | Cream Relaxed Jeans - Womens       | 49.72       |
| b9a74d    | White Striped Socks - Mens         | 49.72       |
| c8d436    | Teal Button Up Shirt - Mens        | 49.68       |

The Navy Solid Socks - Mens has the highest penetration, appearing in 51.24% of all transactions. The consistent presence of items like Grey Fashion Jacket - Womens and Navy Oversized Jeans - Womens suggests they are popular, cross-category staples.

---

#### 10.	What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

```sql
WITH product_combinations AS (
    SELECT txn_id, prod_id
    FROM sales
    WHERE qty > 0  
),
all_combinations AS (
    SELECT DISTINCT c1.txn_id, 
                    c1.prod_id AS prod1, 
                    c2.prod_id AS prod2, 
                    c3.prod_id AS prod3
    FROM product_combinations c1
    JOIN product_combinations c2 
        ON c1.txn_id = c2.txn_id 
        AND c1.prod_id < c2.prod_id  
    JOIN product_combinations c3 
        ON c1.txn_id = c3.txn_id 
        AND c2.prod_id < c3.prod_id  -- Third product added: prod3
)
SELECT pd1.product_name AS prod1, 
       pd2.product_name AS prod2, 
       pd3.product_name AS prod3, 
       COUNT(*) AS combo_count
FROM all_combinations ac
JOIN product_details pd1 
    ON ac.prod1 = pd1.product_id  
JOIN product_details pd2 
    ON ac.prod2 = pd2.product_id 
JOIN product_details pd3 
    ON ac.prod3 = pd3.product_id 
GROUP BY pd1.product_name, pd2.product_name, pd3.product_name  
ORDER BY combo_count DESC  
LIMIT 1;  
```

| prod1                          | prod2                          | prod3                          | combo_count |
|--------------------------------|--------------------------------|--------------------------------|-------------|
| White Tee Shirt - Mens         | Grey Fashion Jacket - Womens   | Teal Button Up Shirt - Mens    | 352         |

The combination of White Tee Shirt - Mens, Grey Fashion Jacket - Womens, and Teal Button Up Shirt - Mens is the most frequent across transactions, appearing 352 times.

---

## Reporting Challenge

#### Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

```sql
-- Sales Metrics
WITH total_revenue AS (
    SELECT 
        category_name,
        segment_name,
        s.prod_id,
        p.product_name,
        SUM(qty) AS sold,  -- Total quantity sold for each product 
        ROUND(SUM((qty * s.price) * (1 - discount * 0.01)), 2) AS Total_Revenues,  -- Total revenue generated after discounts 
        ROUND(SUM((discount * (qty * s.price)) / 100.0), 2) AS Total_Discount,  -- Total discount for all products 
        ROUND(COUNT(DISTINCT txn_id) * 100.0 / (SELECT COUNT(DISTINCT txn_id) FROM sales), 2) AS penetration,  -- Transaction penetration for each product
        ROUND(SUM(CASE WHEN member = 't' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS member_transaction,  -- Percentage of transactions from members 
        ROUND(SUM(CASE WHEN member = 'f' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS non_member_transaction,  -- Percentage of transactions from non-members
        ROUND(AVG(CASE WHEN member = 't' THEN (qty * s.price) * (1 - discount * 0.01) END), 2) AS avg_revenue_member,  -- Average revenue per member transaction 
        ROUND(AVG(CASE WHEN member = 'f' THEN (qty * s.price) * (1 - discount * 0.01) END), 2) AS avg_revenue_non_member,  -- Average revenue per non-member transaction 
        ROUND(AVG(discount), 2) AS avg_discount_per_txn  -- Average discount per transaction 
    FROM sales s
    JOIN product_details p ON s.prod_id = p.product_id
    WHERE EXTRACT(MONTH FROM start_txn_time) = 1  -- Filter for January sales data // For February: WHERE EXTRACT(MONTH FROM start_txn_time) = 2 
    GROUP BY category_name, segment_name, s.prod_id, p.product_name
),

-- Transaction Analysis
product_percentiles AS (
    SELECT 
        txn_id,
        SUM(qty * s.price * (1 - discount * 0.01)) AS revenue_per_txn,  -- Revenue per transaction for percentiles calculation
        s.prod_id
    FROM sales s
    GROUP BY txn_id, s.prod_id
),

-- Top 3 Products
top_3_products AS (
    SELECT 
        prod_id, 
        product_name, 
        category_name, 
        SUM(qty * s.price) AS revenue_before_discount  -- Revenue before discount for top 3 products 
    FROM sales s
	JOIN product_details p ON s.prod_id = p.product_id
    GROUP BY prod_id, product_name, category_name
    ORDER BY revenue_before_discount DESC
    LIMIT 3
),

-- Most Common Product Combinations
common_combinations AS (
    SELECT 
        ARRAY_AGG(DISTINCT p.product_name ORDER BY p.product_name) AS product_combination,  -- Most common product combinations
        COUNT(*) AS combination_count
    FROM sales s
    JOIN product_details p ON s.prod_id = p.product_id
    GROUP BY txn_id
    HAVING ARRAY_LENGTH(ARRAY_AGG(DISTINCT s.prod_id), 1) = 3 
    ORDER BY combination_count DESC
    LIMIT 1
)

-- Final Output
SELECT
    tr.category_name,
    tr.segment_name,
    tr.product_name,
    tr.sold,  -- Total quantity sold per product 
    tr.Total_Revenues,
    tr.Total_Discount,
    tr.penetration,  -- Penetration metric per product 
    tr.member_transaction,
    tr.non_member_transaction,
    tr.avg_revenue_member,
    tr.avg_revenue_non_member,
    tr.avg_discount_per_txn,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY pp.revenue_per_txn) ::numeric, 2) AS p25,  -- 25th percentile 
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pp.revenue_per_txn) ::numeric, 2) AS p50,  -- 50th percentile (Median)
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY pp.revenue_per_txn) ::numeric, 2) AS p75,  -- 75th percentile
	t3.revenue_before_discount AS top_3_revenue,  -- Revenue from top 3 products 
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY tr.category_name, tr.segment_name, tr.prod_id) = 1 
        THEN cc.product_combination  -- Most common product combination for each category/segment
        ELSE NULL
    END AS common_product_combination
FROM total_revenue tr
JOIN product_percentiles pp ON tr.prod_id = pp.prod_id
LEFT JOIN top_3_products t3 ON tr.prod_id = t3.prod_id
LEFT JOIN common_combinations cc ON TRUE  
GROUP BY tr.category_name, tr.segment_name, tr.prod_id, tr.product_name, tr.sold, tr.Total_Revenues, 
         tr.Total_Discount, tr.penetration, tr.member_transaction, tr.non_member_transaction, 
         tr.avg_revenue_member, tr.avg_revenue_non_member, tr.avg_discount_per_txn, t3.revenue_before_discount, cc.product_combination
ORDER BY tr.category_name, tr.segment_name;
```

- Output for January:

| category_name | segment_name | product_name                        | sold | total_revenues | total_discount | penetration | member_transaction | non_member_transaction | avg_revenue_member | avg_revenue_non_member | avg_discount_per_txn | p25   | p50   | p75   | top_3_revenue | common_product_combination                              |
|---------------|--------------|-------------------------------------|------|----------------|----------------|-------------|--------------------|------------------------|--------------------|------------------------|----------------------|-------|-------|-------|----------------|---------------------------------------------------------|
| Mens          | Shirt        | Blue Polo Shirt - Mens              | 1214 | 60674.22       | 8523.78        | 16.52       | 62.23              | 37.77                  | 145.11             | 149.88                 | 12.32                | 94.62 | 150.48 | 214.32 | 217683         | {"Black Straight Jeans - Womens","Indigo Rain Jacket - Womens","Navy Solid Socks - Mens"} |
| Mens          | Shirt        | White Tee Shirt - Mens              | 1256 | 44074.40       | 6165.60        | 16.64       | 58.89              | 41.11                  | 107.74             | 103.38                 | 12.31                | 64.80 | 104.40 | 152.00 | 152000         | NULL                                                    |
| Mens          | Shirt        | Teal Button Up Shirt - Mens         | 1220 | 10661.00       | 1539.00        | 16.44       | 57.18              | 42.82                  | 25.90              | 25.99                  | 12.53                | 16.20 | 25.50  | 36.80  | NULL           | NULL                                                    |
| Mens          | Socks        | Pink Fluro Polkadot Socks - Mens    | 1157 | 29461.39       | 4091.61        | 15.84       | 62.12              | 37.88                  | 76.66              | 70.69                  | 12.35                | 46.98 | 75.69  | 109.04 | NULL           | NULL                                                    |
| Mens          | Socks        | White Striped Socks - Mens          | 1150 | 17192.27       | 2357.73        | 15.96       | 60.15              | 39.85                  | 43.41              | 42.61                  | 12.06                | 26.86 | 43.86  | 63.92  | NULL           | NULL                                                    |
| Mens          | Socks        | Navy Solid Socks - Mens             | 1264 | 39946.68       | 5557.32        | 16.80       | 58.33              | 41.67                  | 95.83              | 94.11                  | 12.38                | 57.60 | 95.04  | 133.92 | NULL           | NULL                                                    |
| Womens        | Jacket       | Indigo Rain Jacket - Womens         | 1225 | 20422.72       | 2852.28        | 16.28       | 58.48              | 41.52                  | 49.28              | 51.45                  | 12.28                | 31.16 | 49.02  | 71.44  | NULL           | NULL                                                    |
| Womens        | Jacket       | Grey Fashion Jacket - Womens        | 1300 | 61619.40       | 8580.60        | 17.24       | 61.95              | 38.05                  | 142.65             | 143.49                 | 12.15                | 90.72 | 142.56 | 205.20 | 209304         | NULL                                                    |
| Womens        | Jacket       | Khaki Suit Jacket - Womens          | 1225 | 24736.50       | 3438.50        | 16.08       | 57.96              | 42.04                  | 61.20              | 62.00                  | 12.01                | 38.64 | 60.72  | 86.48  | NULL           | NULL                                                    |
| Womens        | Jeans        | Navy Oversized Jeans - Womens       | 1257 | 14317.16       | 2023.84        | 16.92       | 59.57              | 40.43                  | 34.83              | 32.40                  | 12.35                | 21.32 | 34.32  | 49.40  | NULL           | NULL                                                    |
| Womens        | Jeans        | Cream Relaxed Jeans - Womens        | 1282 | 11224.20       | 1595.80        | 17.28       | 60.19              | 39.81                  | 26.14              | 25.74                  | 12.41                | 16.00 | 26.40  | 37.20  | NULL           | NULL                                                    |
| Womens        | Jeans        | Black Straight Jeans - Womens       | 1238 | 34752.96       | 4863.04        | 16.32       | 58.09              | 41.91                  | 85.12              | 85.25                  | 12.35                | 52.64 | 85.44  | 120.32 | NULL           | NULL                                                    |

---

#### He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).


_To extract sales data for February, update the query by modifying the date filter to include transactions where `EXTRACT(MONTH FROM start_txn_time) = 2`._


- Output for February:

| category_name | segment_name | product_name                        | sold | total_revenues | total_discount | penetration | member_transaction | non_member_transaction | avg_revenue_member | avg_revenue_non_member | avg_discount_per_txn | p25   | p50   | p75   | top_3_revenue | common_product_combination                              |
|---------------|--------------|-------------------------------------|------|----------------|----------------|-------------|--------------------|------------------------|--------------------|------------------------|----------------------|-------|-------|-------|----------------|---------------------------------------------------------|
| Mens          | Shirt        | Blue Polo Shirt - Mens              | 1281 | 64048.62       | 8968.38        | 16.76       | 62.77              | 37.23                  | 153.46             | 151.84                 | 12.41                | 94.62 | 150.48 | 214.32 | 217683         | {"Black Straight Jeans - Womens","Indigo Rain Jacket - Womens","Navy Solid Socks - Mens"} |
| Mens          | Shirt        | White Tee Shirt - Mens              | 1198 | 42074.00       | 5846.00        | 15.80       | 60.76              | 39.24                  | 106.91             | 105.91                 | 12.34                | 64.80 | 104.40 | 152.00 | 152000         | NULL                                                    |
| Mens          | Shirt        | Teal Button Up Shirt - Mens         | 1205 | 10589.40       | 1460.60        | 16.84       | 60.57              | 39.43                  | 25.22              | 25.06                  | 12.08                | 16.20 | 25.50  | 36.80  | NULL           | NULL                                                    |
| Mens          | Socks        | Pink Fluro Polkadot Socks - Mens    | 1246 | 31833.30       | 4300.70        | 16.32       | 62.75              | 37.25                  | 80.72              | 73.47                  | 11.89                | 46.98 | 75.69  | 109.04 | NULL           | NULL                                                    |
| Mens          | Socks        | White Striped Socks - Mens          | 1252 | 18763.75       | 2520.25        | 16.72       | 62.68              | 37.32                  | 44.42              | 45.68                  | 12.16                | 26.86 | 43.86  | 63.92  | NULL           | NULL                                                    |
| Mens          | Socks        | Navy Solid Socks - Mens             | 1190 | 37583.64       | 5256.36        | 16.56       | 62.08              | 37.92                  | 90.37              | 91.46                  | 12.15                | 57.60 | 95.04  | 133.92 | NULL           | NULL                                                    |
| Womens        | Jacket       | Indigo Rain Jacket - Womens         | 1245 | 20724.44       | 2930.56        | 16.60       | 58.31              | 41.69                  | 48.95              | 51.32                  | 12.57                | 31.16 | 49.02  | 71.44  | NULL           | NULL                                                    |
| Womens        | Jacket       | Grey Fashion Jacket - Womens        | 1254 | 59200.74       | 8515.26        | 16.12       | 63.52              | 36.48                  | 144.53             | 151.03                 | 12.64                | 90.72 | 142.56 | 205.20 | 209304         | NULL                                                    |
| Womens        | Jacket       | Khaki Suit Jacket - Womens          | 1296 | 26252.66       | 3555.34        | 17.68       | 61.31              | 38.69                  | 58.27              | 61.18                  | 11.94                | 38.64 | 60.72  | 86.48  | NULL           | NULL                                                    |
| Womens        | Jeans        | Navy Oversized Jeans - Womens       | 1224 | 13983.06       | 1928.94        | 16.04       | 62.34              | 37.66                  | 34.77              | 35.04                  | 11.99                | 21.32 | 34.32  | 49.40  | NULL           | NULL                                                    |
| Womens        | Jeans        | Cream Relaxed Jeans - Womens        | 1205 | 10595.50       | 1454.50        | 15.68       | 58.93              | 41.07                  | 26.28              | 28.10                  | 12.08                | 16.00 | 26.40  | 37.20  | NULL           | NULL                                                    |
| Womens        | Jeans        | Black Straight Jeans - Womens       | 1224 | 34243.52       | 4924.48        | 16.36       | 62.35              | 37.65                  | 82.92              | 85.06                  | 12.48                | 52.64 | 85.44  | 120.32 | NULL           | NULL                                                    |

Overall, the comparison of January and February data suggests minor variations in sales performance across different products. Some products, like the Blue Polo Shirt - Mens, showed consistent improvement in terms of revenue and transaction performance, particularly among member transactions. On the other hand, certain products, such as the White Tee Shirt - Mens and Navy Oversized Jeans - Womens, experienced a slight decline in both sales volume and total revenue.
In terms of discounting behavior, there was no significant shift observed between the two months, as most products maintained stable discount rates. The comparison highlights the strong performance of member transactions, where average revenue per transaction tended to be higher than that of non-members, particularly for men's products.

---

## Bonus Challenge

#### Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

```sql
WITH cat AS (
  SELECT 
    id AS category_id, 
    level_text AS category_name
  FROM product_hierarchy 
  WHERE level_name = 'Category'
),
seg AS (
  SELECT 
    parent_id AS category_id, 
    id AS segment_id, 
    level_text AS segment_name
  FROM product_hierarchy 
  WHERE level_name = 'Segment'
),
style AS (
  SELECT 
    parent_id AS segment_id, 
    id AS style_id, 
    level_text AS style_name
  FROM product_hierarchy 
  WHERE level_name = 'Style'
),
prod_final AS (
  SELECT 
    c.category_id, 
    c.category_name, 
    s.segment_id, 
    s.segment_name, 
    st.style_id, 
    st.style_name
  FROM cat c 
  JOIN seg s ON c.category_id = s.category_id
  JOIN style st ON s.segment_id = st.segment_id
)
SELECT 
  pp.product_id, 
  pp.price, 
  CONCAT(pf.style_name, ' ', pf.segment_name, ' - ', pf.category_name) AS product_name,
  pf.category_id, 
  pf.segment_id, 
  pf.style_id, 
  pf.category_name, 
  pf.segment_name, 
  pf.style_name
FROM prod_final pf
JOIN product_prices pp ON pf.style_id = pp.id
ORDER BY pf.category_id, pf.segment_id, pf.style_id;
```
| product_id | price | product_name                        | category_id | segment_id | style_id | category_name | segment_name | style_name    |
|------------|-------|-------------------------------------|-------------|------------|----------|----------------|--------------|---------------|
| c4a632     | 13    | Navy Oversized Jeans - Womens       | 1           | 3          | 7        | Womens         | Jeans        | Navy Oversized|
| e83aa3     | 32    | Black Straight Jeans - Womens       | 1           | 3          | 8        | Womens         | Jeans        | Black Straight|
| e31d39     | 10    | Cream Relaxed Jeans - Womens        | 1           | 3          | 9        | Womens         | Jeans        | Cream Relaxed |
| d5e9a6     | 23    | Khaki Suit Jacket - Womens          | 1           | 4          | 10       | Womens         | Jacket       | Khaki Suit    |
| 72f5d4     | 19    | Indigo Rain Jacket - Womens         | 1           | 4          | 11       | Womens         | Jacket       | Indigo Rain   |
| 9ec847     | 54    | Grey Fashion Jacket - Womens        | 1           | 4          | 12       | Womens         | Jacket       | Grey Fashion  |
| 5d267b     | 40    | White Tee Shirt - Mens              | 2           | 5          | 13       | Mens           | Shirt        | White Tee     |
| c8d436     | 10    | Teal Button Up Shirt - Mens         | 2           | 5          | 14       | Mens           | Shirt        | Teal Button Up|
| 2a2353     | 57    | Blue Polo Shirt - Mens              | 2           | 5          | 15       | Mens           | Shirt        | Blue Polo     |
| f084eb     | 36    | Navy Solid Socks - Mens             | 2           | 6          | 16       | Mens           | Socks        | Navy Solid    |
| b9a74d     | 17    | White Striped Socks - Mens          | 2           | 6          | 17       | Mens           | Socks        | White Striped |
| 2feb6b     | 29    | Pink Fluro Polkadot Socks - Mens    | 2           | 6          | 18       | Mens           | Socks        | Pink Fluro Polkadot |

---












