# Case Study #1: Danny’s Diner

<img src="https://user-images.githubusercontent.com/81607668/127727503-9d9e7a25-93cb-4f95-8bd0-20b87cb4b459.png" alt="Image" width="450" height="470">

## Table of Contents
- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Data Overview](#data-overview)
- [Case Study Questions and Solutions](#case-study-questions-and-solutions)
- [Bonus Questions](#bonus-questions)

For complete details regarding the challenge, you can visit [here](https://8weeksqlchallenge.com/case-study-1/).

---
## Introduction
Danny’s Diner, a small Japanese restaurant, opened in early 2021, offering a simple menu of sushi, curry, and ramen. To support its growth, the diner has collected data over several months and now seeks to leverage this information for business improvement.

---
## Problem Statement
This analysis is designed to provide insights into customer behavior, including their visit frequency, spending trends, and favorite menu items. By understanding these patterns, we can make informed decisions to improve the customer experience and refine our loyalty program.

---

## Data Overview

This case study includes three main datasets:

<details>
<summary>Table 1: Sales</summary>

| Column Name  | Description |
|--------------|-------------|
| customer_id  | Identifies the customer who made the purchase |
| order_date   | The date the order was placed |
| product_id   | A reference to the ordered product from the menu |

</details>

<details>
<summary>Table 2: Menu</summary>

| Column Name  | Description |
|--------------|-------------|
| product_id   | A unique identifier for each product on the menu |
| product_name | The name of the product (menu item) |
| price        | The price of the product |

</details>

<details>
<summary>Table 3: Members</summary>

| Column Name  | Description |
|--------------|-------------|
| customer_id  | Identifies the customer who joined the loyalty program |
| join_date    | The date the customer joined the loyalty program |

</details>

The relationships between these tables are shown in the following ERD diagram:

![alt text](https://github.com/beyzabasarir/8-Week-SQL-Challenge/blob/main/Case%20Study%20%231-%20Danny's%20Diner/ERD.png)

---
## Case Study Questions and Solutions

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT 
    s.customer_id, 
    SUM(m.price) AS total_revenue
FROM 
    sales s
JOIN 
    menu m ON s.product_id = m.product_id
GROUP BY 
    s.customer_id
ORDER BY 
    total_revenue DESC;
```

| customer_id | total_revenue |
|-------------|----------------|
| A           | 76             |
| B           | 74             |
| C           | 36             |


The total amount spent by each customer shows that:

- Customer A spent the highest amount, with a total of $76.
- Customer B is close behind with $74.
- Customer C spent significantly less, at $36.

---

### 2. How many days has each customer visited the restaurant?

```sql
SELECT 
    customer_id, 
    COUNT(DISTINCT order_date) AS visit_days
FROM 
    sales
GROUP BY 
    customer_id;
```

| customer_id | visit_days |
|-------------|------------|
| A           | 4          |
| B           | 6          |
| C           | 2          |

- Customer A visited on 4 different days.
- Customer B visited the most, with 6 visits.
- Customer C only visited on 2 days.

---

### 3. What was the first item from the menu purchased by each customer?
```sql
WITH ranked_orders AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    m.product_name,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
  FROM 
    sales s
  INNER JOIN 
    menu m
    ON s.product_id = m.product_id
)
SELECT 
  DISTINCT customer_id, 
  product_name,
  order_date
FROM ranked_orders
WHERE rn = 1
```

| customer_id | product_name | order_date |
|-------------|--------------|------------|
| A           | curry        | 2021-01-01 |
| A           | sushi        | 2021-01-01 |
| B           | curry        | 2021-01-01 |
| C           | ramen        | 2021-01-01 |

- Customer A ordered curry and sushi as their first items.
- Customer B’s first purchase was curry.
- Customer C ordered ramen during their first visit.

---

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
SELECT 
    m.product_name,
    COUNT(s.product_id) AS purchase_count
FROM 
    sales s
JOIN 
    menu m ON s.product_id = m.product_id
GROUP BY 
    m.product_name
ORDER BY 
    purchase_count DESC
LIMIT 1;
```

| product_name | purchase_count |
|--------------|----------------|
| ramen        | 8              |

'Ramen' emerged as the most frequently purchased item with a total of 8 purchases.

---

### 5. Which item was the most popular for each customer?
```sql
WITH order_counts AS (
    SELECT 
        s.customer_id, 
        m.product_name, 
        COUNT(s.product_id) AS order_count
    FROM 
        sales s 
    JOIN 
        menu m ON s.product_id = m.product_id
    GROUP BY 
        s.customer_id, m.product_name
    ORDER BY 
        s.customer_id ASC, order_count DESC
), 
ranked_orders AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_count DESC) AS rn
    FROM 
        order_counts
)
SELECT 
    customer_id, 
    product_name, 
    order_count 
FROM 
    ranked_orders 
WHERE 
    rn = 1
ORDER BY 
    customer_id ASC, order_count DESC;
```

| customer_id | product_name | order_count |
|-------------|--------------|-------------|
| A           | ramen        | 3           |
| B           | sushi        | 2           |
| B           | curry        | 2           |
| B           | ramen        | 2           |
| C           | ramen        | 3           |

- Customer A's favorite item is ramen with 3 orders.
- Customer B's orders were equally split among sushi, curry, and ramen with 2 orders each.
- Customer C's most popular item was ramen with 3 orders.

---

### 6. Which item was purchased first by the customer after they became a member?
```sql
WITH purchases_after_join AS (
    SELECT 
        m.customer_id,
        s.order_date,
	    m.join_date,
        s.product_id,
        ROW_NUMBER() OVER (PARTITION BY m.customer_id ORDER BY s.order_date) AS purchase_rank
    FROM 
        members m
    JOIN 
        sales s ON m.customer_id = s.customer_id
    WHERE 
        s.order_date >= m.join_date 
	)
SELECT 
    pa.customer_id,
    m.product_name,
    pa.join_date,
    pa.order_date
FROM 
    purchases_after_join pa
JOIN 
    menu m ON pa.product_id = m.product_id
WHERE 
    pa.purchase_rank = 1;
```

| customer_id | product_name | join_date  | order_date |
|-------------|--------------|------------|------------|
| B           | sushi        | 2021-01-09 | 2021-01-11 |
| A           | curry        | 2021-01-07 | 2021-01-07 |

Customer A ordered 'Curry' on the same day they joined, while Customer B ordered 'Sushi' two days after joining.

---

### 7. Which item was purchased just before the customer became a member?
```sql
WITH purchases_before_join AS (
  SELECT 
    m.customer_id,
    s.order_date,
    s.product_id,
    DENSE_RANK() OVER (PARTITION BY m.customer_id ORDER BY s.order_date ASC) AS item_rank
  FROM 
    members m
  JOIN 
    sales s ON m.customer_id = s.customer_id
  WHERE 
    s.order_date < m.join_date
)
SELECT 
  pb.customer_id,
  m.product_name,
  pb.order_date
FROM 
  purchases_before_join pb
JOIN 
  menu m ON pb.product_id = m.product_id
WHERE 
  pb.item_rank = 1
ORDER BY 
  pb.customer_id, pb.order_date;
```

| customer_id | product_name | order_date |
|-------------|--------------|------------|
| A           | sushi        | 2021-01-01 |
| A           | curry        | 2021-01-01 |
| B           | sushi        | 2021-01-04 |

- Customer A purchased 'Sushi' and 'Curry' on the same day.
- Customer B's last pre-membership purchase was 'Sushi'.

---

### 8. What is the total number of items and amount spent for each member before they became a member?
```sql
SELECT 
m.customer_id, 
COUNT(s.product_id) AS total_items, 
SUM(me.price) AS total_amount 
FROM 
members m 
JOIN 
sales s ON m.customer_id = s.customer_id 
JOIN 
menu me ON s.product_id = me.product_id 
WHERE 
s.order_date < m.join_date 
GROUP BY 
m.customer_id;
```

| customer_id | total_items | total_amount |
|-------------|-------------|--------------|
| B           | 3           | 40           |
| A           | 2           | 25           |

- Customer B purchased 3 items totaling $40.
- Customer A purchased 2 items totaling $25.

---

### 9. How many points would each customer have if each $1 spent equates to 10 points and sushi has a 2x points multiplier?
```sql
WITH total_spending AS (
    SELECT
        s.customer_id,
        SUM(CASE
            WHEN s.product_id = 1 THEN me.price * 2  
            ELSE me.price
        END) AS total_spent
    FROM
        sales s
    JOIN
        menu me ON s.product_id = me.product_id
    GROUP BY
        s.customer_id
)
SELECT
    customer_id,
    total_spent * 10 AS total_points 
FROM
    total_spending
ORDER BY 2 DESC;
```

| customer_id | total_points |
|-------------|--------------|
| B           | 940          |
| A           | 860          |
| C           | 360          |

Customer B earned the highest points (940), followed by Customer A (860) and Customer C (360).

---

### 10.	 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
WITH sales_with_price AS (
    SELECT 
        s.customer_id,
        s.order_date,
        s.product_id,
        m.price,
        m.product_name
    FROM 
        sales s
    JOIN 
        menu m ON s.product_id = m.product_id
),

points_calculation AS (
    SELECT 
        swp.customer_id,
        SUM(swp.price) AS total_spent,
        SUM(CASE 
            WHEN m.join_date <= swp.order_date AND swp.order_date <= m.join_date + INTERVAL '6 days' THEN
                swp.price * 2  
            WHEN swp.product_name = 'sushi' THEN
                swp.price * 2
            ELSE
                swp.price
        END) AS points_earned
    FROM 
        sales_with_price swp
    JOIN 
        members m ON swp.customer_id = m.customer_id
    WHERE 
        swp.order_date <= '2021-01-31'
    GROUP BY 
        swp.customer_id
)

SELECT 
    customer_id,
    total_spent,
    points_earned * 10 AS total_points  
FROM 
    points_calculation;
```

| customer_id | total_spent  | total_points |
|-------------|--------------|--------------|
| A           | 76           | 1370         |
| B           | 62           | 820          |


-	Customer A earned 1370 points, spending a total of $76.
-	Customer B earned 820 points, with a total spending of $62.
-	During the first week after joining, all purchases earned 2x points, contributing significantly to the points totals.
  
**Data Considerations:**
1.	Only transactions up to January 31, 2021, were considered.
2.	The "first week" includes the join date and six subsequent days.
3.	All sushi purchases, regardless of timing, received a 2x multiplier.

---

## BONUS Questions 

### 1. Join All The Things

Recreate a data table that includes customer purchase details and their membership status at the time of purchase using SQL.
The query should output:
-	Customer ID
-	Order Date
-	Product Name
-	Price
-	Membership Status (Y for member, N for non-member based on the order date relative to the membership join date).

```sql
SELECT 
    s.customer_id, 
    s.order_date, 
    m.product_name, 
    m.price, 
    CASE 
        WHEN s.order_date < me.join_date THEN 'N'
        WHEN s.order_date >= me.join_date THEN 'Y'
        ELSE 'N' 
    END AS member
FROM 
    sales s
JOIN 
    menu m ON s.product_id = m.product_id
LEFT JOIN 
    members me ON s.customer_id = me.customer_id
ORDER BY 
    s.customer_id, s.order_date ASC;
```
| Customer ID | Order Date | Product Name | Price | Membership Status |
|-------------|------------|--------------|-------|-------------------|
| A           | 2021-01-01 | sushi        | 10    | N                 |
| A           | 2021-01-01 | curry        | 15    | N                 |
| A           | 2021-01-07 | curry        | 15    | Y                 |
| A           | 2021-01-10 | ramen        | 12    | Y                 |
| A           | 2021-01-11 | ramen        | 12    | Y                 |
| A           | 2021-01-11 | ramen        | 12    | Y                 |
| B           | 2021-01-01 | curry        | 15    | N                 |
| B           | 2021-01-02 | curry        | 15    | N                 |
| B           | 2021-01-04 | sushi        | 10    | N                 |
| B           | 2021-01-11 | sushi        | 10    | Y                 |
| B           | 2021-01-16 | ramen        | 12    | Y                 |
| B           | 2021-02-01 | ramen        | 12    | Y                 |
| C           | 2021-01-01 | ramen        | 12    | N                 |
| C           | 2021-01-01 | ramen        | 12    | N                 |
| C           | 2021-01-07 | ramen        | 12    | N                 |

---

### 2.	Rank All The Things

Generate a ranked table of customer purchases, ensuring rankings are applied only to purchases made by members of the loyalty program. Non-member purchases should display null values for rankings.

```sql
WITH customers_info AS (
    SELECT 
        s.customer_id, 
        s.order_date, 
        m.product_name, 
        m.price, 
        CASE 
            WHEN s.order_date < me.join_date THEN 'N'
            WHEN s.order_date >= me.join_date THEN 'Y'
            ELSE 'N' 
        END AS member 
    FROM 
        sales s 
    JOIN 
        menu m ON s.product_id = m.product_id
    LEFT JOIN 
        members me ON s.customer_id = me.customer_id
    ORDER BY 
        s.customer_id, s.order_date ASC
)
SELECT 
    *, 
    CASE 
        WHEN member = 'N' THEN NULL 
        ELSE RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)  
    END AS ranking
FROM 
    customers_info;
```
| Customer ID | Order Date | Product Name | Price | Membership Status | Quantity |
|-------------|------------|--------------|-------|-------------------|----------|
| A           | 2021-01-01 | sushi        | 10    | N                 | NULL     |
| A           | 2021-01-01 | curry        | 15    | N                 | NULL     |
| A           | 2021-01-07 | curry        | 15    | Y                 | 1        |
| A           | 2021-01-10 | ramen        | 12    | Y                 | 2        |
| A           | 2021-01-11 | ramen        | 12    | Y                 | 3        |
| A           | 2021-01-11 | ramen        | 12    | Y                 | 3        |
| B           | 2021-01-01 | curry        | 15    | N                 | NULL     |
| B           | 2021-01-02 | curry        | 15    | N                 | NULL     |
| B           | 2021-01-04 | sushi        | 10    | N                 | NULL     |
| B           | 2021-01-11 | sushi        | 10    | Y                 | 1        |
| B           | 2021-01-16 | ramen        | 12    | Y                 | 2        |
| B           | 2021-02-01 | ramen        | 12    | Y                 | 3        |
| C           | 2021-01-01 | ramen        | 12    | N                 | NULL     |
| C           | 2021-01-01 | ramen        | 12    | N                 | NULL     |
| C           | 2021-01-07 | ramen        | 12    | N                 | NULL     |

---
