# Case Study #6: Clique Bait 

<img src="https://8weeksqlchallenge.com/images/case-study-designs/6.png" alt="Image" width="450" height="470">

## Table of Contents
- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Data Overview](#data-overview)
- [Case Study Questions and Solutions](#case-study-questions-and-solutions)
    - [A-Enterprise Relationship Diagram](#a-enterprise-relationship-diagram)
    - [B-Digital Analysis](#b-digital-analysis)
    - [C-Product Funnel Analysis](#c-product-funnel-analysis)
    - [D-Campaigns Analysis](#d-campaigns-analysis)

8 Week SQL Challenge [website]( https://8weeksqlchallenge.com/case-study-6/). 

---
## Introduction
Clique Bait is an innovative e-commerce platform specializing in seafood, bringing a unique experience to online grocery shopping. The company was founded by Danny, a former digital data analyst, who sought to merge his data-driven background with the seafood industry. Clique Bait's approach centers on using customer data and website interaction patterns to enhance user experience, boost engagement, and optimize sales strategies.

---
## Problem Statement
This case study focuses on analyzing user behavior, campaign effectiveness, and overall funnel performance for Clique Bait’s website. The goal is to evaluate customer interactions, from page views to purchases, and identify potential areas for improvement in the customer journey.

---
## Data Overview

To address the business questions in this study, five datasets were provided. 

<details>
  <summary>Table 1: Users</summary>
  
Contains information about visitors to the Clique Bait website.

| Column Name | Description                                      |
|-------------|--------------------------------------------------|
| `user_id`     | Unique identifier for each user.                 |
| `cookie_id`   | Tracks customer visits via cookies.              |
| `start_date`  | The date the user first visited the website.     |

</details>


<details>
  <summary>Table 2: Events</summary>

  Logs various customer activities on the site, including page views, ad clicks, and purchases.

  | Column Name     | Description                                                                 |
|-----------------|-----------------------------------------------------------------------------|
| `visit_id`        | Unique identifier for each visit to the website.                           |
| `cookie_id`       | Tracks which customer made the visit.                                      |
| `page_id`         | Identifies the page visited.                                                |
| `event_type`      | Describes the type of event (e.g., page view, purchase).                    |
| `sequence_number` | Orders the events within a single visit.                                    |
| `event_time`      | The exact time the event occurred.                                          |

</details>

<details>
  <summary>Table 3: Event Identifier</summary>

Provides the event types recorded on the website.

| Column Name   | Description                                                  |
|---------------|--------------------------------------------------------------|
| `event_type`    | Describes the type of event (e.g., page view, add to cart).  |
| `event_name`    | A more detailed name for each event type.                    |

</details>

<details>
  <summary>Table 4: Campaign Identifier</summary>

Lists the marketing campaigns run by Clique Bait, including promotion details and timeframes.

| Column Name   | Description                                                   |
|---------------|---------------------------------------------------------------|
| `campaign_id`   | Unique ID for each campaign.                                  |
| `products`      | Specifies which products were promoted in the campaign.       |
| `campaign_name` | Name of the marketing campaign.                               |
| `start_date`    | The date the campaign began.                                  |
| `end_date`      | The date the campaign ended.                                  |

</details>

<details>
  <summary>Table 5: Page Hierarchy</summary>

Describes the pages on the website.

| Column Name    | Description                                                     |
|----------------|-----------------------------------------------------------------|
| `page_id`        | Unique ID for each page on the site.                            |
| `page_name`      | Name of the webpage (e.g., Home, Checkout).                     |
| `product_category` | The product category displayed on the page (e.g., fish, shellfish). |
| `product_id`     | Identifies the product showcased on the page.                   |

</details>

---

## Case Study Questions and Solutions

### A-Enterprise Relationship Diagram

<img src="https://github.com/beyzabasarir/8-Week-SQL-Challenge/blob/main/Case%20Study%20%236-Clique%20Bait/ERD.png" alt="Image" width="600" height="470">

---

### B-Digital Analysis

#### 1.	How many users are there?

```sql
SELECT COUNT(DISTINCT(user_id)) AS total_users FROM users;
```
| total_users    |
|----------------|
|500             | 

There are 500 users in total.

---

#### 2.	How many cookies does each user have on average?
   
```sql
SELECT ROUND(AVG(cookie_count),0) AS avg_cookie
FROM (
    SELECT user_id, COUNT(cookie_id) AS cookie_count
    FROM users
    GROUP BY user_id
) AS user_counts;
```

| avg_cookie    |
|---------------|
|4              | 

On average, each user has 4 cookies associated with their account.

---
#### 3.	What is the unique number of visits by all users per month?

```sql
SELECT EXTRACT(MONTH FROM event_time) AS month_number,
       TO_CHAR(event_time, 'Month') AS month_name, 
       COUNT(DISTINCT(visit_id)) AS unique_visits
FROM events
GROUP BY 1,2; 
```

| month_number | month_name | unique_visits |
|--------------|------------|---------------|
| 1            | "January"  | 876           |
| 2            | "February" | 1488          |
| 3            | "March"    | 916           |
| 4            | "April"    | 248           |
| 5            | "May"      | 36            | 

The data shows that February saw the highest unique user visits (1,488), while May had significantly fewer (36).

---
#### 4.	What is the number of events for each event type?

```sql
SELECT event_name, COUNT(e.event_type) AS event_count
FROM events e
JOIN event_identifier ei ON e.event_type = ei.event_type 
GROUP BY 1
ORDER BY 2 DESC;
```

| event_name      | event_count |
|-----------------|-------------|
| "Page View"     | 20928       |
| "Add to Cart"   | 8451        |
| "Purchase"      | 1777        |
| "Ad Impression" | 876         |
| "Ad Click"      | 702         |

The most frequent event is "Page View" with over 20,000 occurrences, followed by "Add to Cart" at 8,451. "Purchase" events are significantly fewer (1,777), suggesting a drop-off in user engagement from browsing to buying. Ad-related events ("Ad Impression" and "Ad Click") are comparatively low.

---
#### 5.	What is the percentage of visits which have a purchase event?

```sql
WITH purchase_events AS (
    SELECT COUNT(DISTINCT(visit_id)) AS purchase_event
    FROM events
    WHERE event_type = 3
),
total_visits AS (
    SELECT COUNT(DISTINCT(visit_id)) AS total_visit
    FROM events
)
SELECT ROUND((pe.purchase_event::NUMERIC / tv.total_visit * 100),2) AS purchase_percentage
FROM purchase_events pe, total_visits tv;
```

| purchase_percentage    |
|------------------------|
|49.86                   | 

Approximately 49.86% of all visits resulted in a purchase event, indicating a strong conversion rate. This suggests that nearly half of the site visitors engage in purchasing,

---
#### 6.	What is the percentage of visits which view the checkout page but do not have a purchase event?

```sql
WITH checkout_events AS (
    SELECT COUNT(DISTINCT(visit_id)) AS total_checkouts
    FROM events
    WHERE page_id = 12
	AND event_type != 3 
),
purchase_events AS (
    SELECT COUNT(DISTINCT(visit_id)) AS total_purchase
    FROM events
    WHERE event_type = 3
)
SELECT ce.total_checkouts,pe.total_purchase,
       100-round(pe.total_purchase* 100.0/ce.total_checkouts,2) as prcnt
FROM checkout_events ce, purchase_events pe;
```

| total_checkouts | total_purchase | prcnt |
|-----------------|----------------|-------|
| 2103            | 1777           | 15.50 |

The result shows that out of 2,103 distinct visits that reached the checkout page, 1,777 resulted in a purchase event. Therefore, 15.5% of the users who viewed the checkout page did not make a purchase. 

---
#### 7.	What are the top 3 pages by number of views?

```sql
SELECT page_name, COUNT (visit_id) AS total_views
FROM events e
JOIN page_hierarchy ph ON e.page_id= ph.page_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;
```

| page_name      | total_views |
|----------------|-------------|
| "All Products" | 4752        |
| "Lobster"      | 2515        |
| "Crab"         | 2513        |

The "All Products" page has the highest number of views, indicating it is the most frequently visited page. "Lobster" and "Crab" are the next most popular pages.

---
#### 8.	What is the number of views and cart adds for each product category?

```sql
SELECT product_category, 
       SUM (CASE WHEN event_type = 1 THEN 1 ELSE 0 END ) AS views,
	   SUM (CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM events e 
JOIN page_hierarchy ph ON e.page_id= ph.page_id
WHERE product_category IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;
```

| product_category | views | cart_adds |
|------------------|-------|-----------|
| "Shellfish"      | 6204  | 3792      |
| "Fish"           | 4633  | 2789      |
| "Luxury"         | 3032  | 1870      | 

The 'Shellfish' category leads with 6,204 views and 3,792 cart adds, significantly outpacing 'Fish' and 'Luxury'.

---
#### 9.	What are the top 3 products by purchases?

```sql
WITH table1 AS (
    SELECT DISTINCT visit_id 
  FROM events 
  WHERE event_type = 3 ),
table2 AS (
	SELECT ph.page_name,
	e.page_id,
	e.visit_id
	FROM events e
	LEFT JOIN page_hierarchy ph ON e.page_id = ph.page_id
	WHERE product_id IS NOT NULL
	AND event_type = 2)
SELECT t2.page_name,
	   COUNT (*) AS purchases
	FROM table1 t1
	LEFT JOIN table2 t2 ON t1.visit_id = t2.visit_id
	GROUP BY 1
	ORDER BY 2 DESC
	LIMIT 3;
```
| page_name | purchases |
|-----------|-----------|
| "Lobster" | 754       |
| "Oyster"  | 726       |
| "Crab"    | 719       |

The product "Lobster" leads in purchases with 754, followed closely by "Oyster" with 726, and "Crab" at 719.

---

### C-Product Funnel Analysis

#### Using a single SQL query - create a new output table which has the following details:
-	How many times was each product viewed?
-	How many times was each product added to cart?
-	How many times was each product added to a cart but not purchased (abandoned)?
-	How many times was each product purchased?

```sql
CREATE TABLE products_details AS 
WITH table1 AS (
    SELECT DISTINCT visit_id 
    FROM events 
    WHERE event_type = 3
),
table2 AS (
    SELECT 
        ph.page_name,
        e.page_id,
        ph.product_id,
        ph.product_category,
        e.visit_id
    FROM events e
    LEFT JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE product_id IS NOT NULL
      AND event_type = 2
),
table3 AS (
    SELECT 
        ph.page_name, 
        COUNT(visit_id) AS view_count
    FROM events e
    JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE event_type = 1
      AND product_id IS NOT NULL
    GROUP BY ph.page_name
),
table4 AS (
    SELECT 
        ph.page_name, 
        COUNT(visit_id) AS cart_added
    FROM events e
    JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE event_type = 2
      AND product_id IS NOT NULL
    GROUP BY ph.page_name
),
table5 AS (
SELECT  
    t2.product_id, 
    t2.page_name AS product_name, 
    t3.view_count AS views, 
    t4.cart_added AS added_to_cart, 
    t4.cart_added - COUNT(t1.visit_id) AS abandoned,
    COUNT(t1.visit_id) AS purchases
FROM table1 t1
LEFT JOIN table2 t2 ON t1.visit_id = t2.visit_id
LEFT JOIN table3 t3 ON t2.page_name = t3.page_name
LEFT JOIN table4 t4 ON t3.page_name = t4.page_name
GROUP BY 1,2,3,4
ORDER BY 1) 
SELECT * FROM table5;

SELECT * FROM products_details;
```
| product_id | product_name     | views | added_to_cart | abandoned | purchases |
|------------|------------------|-------|---------------|-----------|-----------|
| 1          | Salmon           | 1559  | 938           | 227       | 711       |
| 2          | Kingfish         | 1559  | 920           | 213       | 707       |
| 3          | Tuna             | 1515  | 931           | 234       | 697       |
| 4          | Russian Caviar   | 1563  | 946           | 249       | 697       |
| 5          | Black Truffle    | 1469  | 924           | 217       | 707       |
| 6          | Abalone          | 1525  | 932           | 233       | 699       |
| 7          | Lobster          | 1547  | 968           | 214       | 754       |
| 8          | Crab             | 1564  | 949           | 230       | 719       |
| 9          | Oyster           | 1568  | 943           | 217       | 726       |

-	**Number of Views:** Products like "Oyster" (1568 views) and "Crab" (1564 views) have the highest view counts, while others, like "Salmon" (1559 views) and "Kingfish" (1559 views), are also quite close in terms of views.
- **Number of Times Added to Cart:** "Lobster" (968 additions) and "Russian Caviar" (946 additions) stand out with slightly higher cart additions, but again, the numbers are fairly close across products, with the lowest being "Salmon" (938 additions).
-	**Abandoned Carts:** "Russian Caviar" has the highest abandonment rate (249).
-	**Number of Purchases:** "Lobster" has the highest number of purchases (754), indicating strong conversion. However, products like "Tuna" and "Abalone" have lower conversion rates.

Overall, the values for views, cart additions, abandoned carts, and purchases are all relatively close across the products. This suggests that, while there are some differences, the overall performance of the products is fairly even.

---

#### Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

```sql
CREATE TABLE category_details AS 
WITH table1 AS (
    SELECT DISTINCT visit_id 
    FROM events 
    WHERE event_type = 3
),
table2 AS (
    SELECT 
        ph.page_name,
        e.page_id,
        ph.product_id,
        ph.product_category,
        e.visit_id
    FROM events e
    LEFT JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE product_id IS NOT NULL
      AND event_type = 2
),
table3 AS (
    SELECT 
        ph.product_category, 
        COUNT(visit_id) AS view_count
    FROM events e
    JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE event_type = 1
      AND product_id IS NOT NULL
    GROUP BY ph.product_category
),
table4 AS (
    SELECT 
        ph.product_category, 
        COUNT(visit_id) AS cart_added
    FROM events e
    JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE event_type = 2
      AND product_id IS NOT NULL
    GROUP BY ph.product_category
), table5 AS (
SELECT  
    t2.product_category AS product_category, 
    t3.view_count AS views, 
    t4.cart_added AS added_to_cart, 
    t4.cart_added - COUNT(t1.visit_id) AS abandoned,
    COUNT(t1.visit_id) AS purchases
FROM table1 t1
LEFT JOIN table2 t2 ON t1.visit_id = t2.visit_id
LEFT JOIN table3 t3 ON t2.product_category = t3.product_category
LEFT JOIN table4 t4 ON t3.product_category = t4.product_category
GROUP BY 1,2,3
ORDER BY 1) 
SELECT * FROM table5;

SELECT * FROM category_details;
```
| product_category | views | added_to_cart | abandoned | purchases |
|------------------|-------|---------------|-----------|-----------|
| Fish             | 4633  | 2789          | 674       | 2115      |
| Luxury           | 3032  | 1870          | 466       | 1404      |
| Shellfish        | 6204  | 3792          | 894       | 2898      |

---

#### Use your 2 new output tables - answer the following questions:

#### 1.	Which product had the most views, cart adds and purchases?

#### -	Most viewed product

```sql
SELECT product_name, 
       views AS most_view 
	FROM products_details
	ORDER BY 2 DESC
	LIMIT 1;
```

| product_name | most_view |
|--------------|-----------|
| Oyster       | 1568      | 

#### -Most cart adds

```sql
SELECT product_name, 
       added_to_cart AS most_cart_adds 
	FROM products_details
	ORDER BY 2 DESC
	LIMIT 1;
```
| product_name | most_cart_adds |
|--------------|----------------|
| Lobster      | 968            | 
	

#### - Most purchased product

```sql
SELECT product_name, 
       purchases AS most_purchases 
	FROM products_details
	ORDER BY 2 DESC
	LIMIT 1; 
```
| product_name | most_purchases |
|--------------|----------------|
| Lobster      | 754            | 
	
Oyster" had the highest views with 1568, while "Lobster" led in cart adds (968) and purchases (754). These results demonstrate that "Lobster" had a strong overall performance, excelling in both cart adds and purchases, while "Oyster" stood out in views but didn't have the same success in conversions.

---
#### 2.	Which product was most likely to be abandoned?

```sql
SELECT product_name, 
       abandoned AS most_abandoned 
	FROM products_details
	ORDER BY 2 DESC
	LIMIT 1;
```

| product_name   | most_abandoned |
|----------------|----------------|
| Russian Caviar | 249            | 
	
"Russian Caviar" had the highest number of abandoned carts, with 249 instances. This suggests that, despite a notable interest in the product (as indicated by cart adds), a significant number of users chose not to follow through with the purchase.

---
#### 3.	Which product had the highest view to purchase percentage?

```sql
SELECT product_name, 
	   round(purchases*100.0/views,2 ) as view_to_purchase
	  FROM products_details
	  GROUP BY 1,2
	  ORDER BY 2 DESC
	  LIMIT 1;
```

| product_name | view_to_purchase |
|--------------|------------------|
| Lobster      | 48.74            | 

The product with the highest view-to-purchase percentage is "Lobster," with a conversion rate of 48.74%. This means nearly half of all views for this product result in a purchase

---
#### 4.	What is the average conversion rate from view to cart add?
#### 5.	What is the average conversion rate from cart add to purchase?

_Note : Using a single query for these calculations simplifies the analysis by allowing easy comparison of conversion rates at each stage of the funnel._

```sql
SELECT ROUND(AVG(COALESCE(added_to_cart, 0)::NUMERIC / views * 100),2) AS view_to_cart_conversion,
       ROUND(AVG(COALESCE(purchases, 0)::NUMERIC / added_to_cart * 100),2) AS cart_to_purchase_conversion
FROM products_details;
```

| view_to_cart_conversion | cart_to_purchase_conversion |
|-------------------------|-----------------------------|
| 60.95                   | 75.93                       | 

The data indicates that 60.95% of product views result in cart additions, while 75.93% of cart additions lead to purchases. These rates suggest strong customer intent and may reflect a streamlined shopping experience. However, there could be room for improvement in converting views to cart additions, as nearly 40% of views do not lead to engagement.

---
### D-Campaigns Analysis

#### Generate a table that has 1 single row for every unique visit_id record and has the following columns:
-	user_id
-	visit_id
-	visit_start_time: the earliest event_time for each visit
-	page_views: count of page views for each visit
-	cart_adds: count of product cart add events for each visit
-	purchase: 1/0 flag if a purchase event exists for each visit
-	campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-	impression: count of ad impressions for each visit
-	click: count of ad clicks for each visit
-	(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

```sql
CREATE TABLE campaign_analysis
(
    user_id INT,
    visit_id VARCHAR(20),
    visit_start_time TIMESTAMP, -- Replaced datetime2(3) with timestamp
    page_views INT,
    cart_adds INT,
    purchase INT,
    impressions INT,
    click INT,
    campaign_name VARCHAR(200),
    cart_products VARCHAR(200)
);

WITH cte AS (
SELECT DISTINCT visit_id,
       user_id,
       visit_start_time,
       SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS page_views,
       SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS cart_adds,
       SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase,
       SUM(CASE WHEN event_type = 4 THEN 1 ELSE 0 END) AS impressions,
       SUM(CASE WHEN event_type = 5 THEN 1 ELSE 0 END) AS click,
       campaign_name,
       STRING_AGG(CASE
                    WHEN event_type = 2 AND product_id IS NOT NULL THEN page_name
                    ELSE NULL
                  END, ',' ORDER BY sequence_number) AS cart_products
FROM (
    SELECT visit_id,
           user_id,
           event_time,
           MIN(event_time) OVER (PARTITION BY visit_id) AS visit_start_time,
           event_type,
           CASE 
               WHEN event_time > '2020-01-01 00:00:00' AND event_time < '2020-01-14 00:00:00' THEN 'BOGOF - Fishing For Compliments'
               WHEN event_time > '2020-01-15 00:00:00' AND event_time < '2020-01-28 00:00:00' THEN '25% Off - Living The Lux Life'
               WHEN event_time > '2020-02-01 00:00:00' AND event_time < '2020-03-31 00:00:00' THEN 'Half Off - Treat Your Shellf(ish)'
               ELSE NULL
           END AS campaign_name,
           ph.product_id,
	       ph.page_name,
           e.sequence_number
    FROM events e
    JOIN users u ON e.cookie_id = u.cookie_id
    JOIN page_hierarchy ph ON e.page_id = ph.page_id  
) AS subquery
GROUP BY visit_id, user_id, visit_start_time, campaign_name
ORDER BY user_id, visit_start_time)

INSERT INTO campaign_analysis 
    (user_id, visit_id, visit_start_time, page_views, cart_adds, purchase, impressions, click, campaign_name, cart_products)
SELECT user_id, visit_id, visit_start_time, page_views, cart_adds, purchase, impressions, click, campaign_name, cart_products
FROM cte;

SELECT * FROM campaign_analysis;
```

##### Sample Output: 

| **user_id** | **visit_id** | **visit_start_time**      | **page_views** | **cart_adds** | **purchase** | **impressions** | **click** | **campaign_name**               | **cart_products**                                                                  |
|-------------|--------------|---------------------------|----------------|---------------|--------------|-----------------|-----------|---------------------------------|-----------------------------------------------------------------------------------|
| 1           | 0fc437       | 2020-02-04 17:49:49.602976| 10             | 6             | 1            | 1               | 1         | Half Off - Treat Your Shellf(ish) | Tuna, Russian Caviar, Black Truffle, Abalone, Crab, Oyster                        |
| 1           | ccf365       | 2020-02-04 19:16:09.182546| 7              | 3             | 1            | 0               | 0         | Half Off - Treat Your Shellf(ish) | Lobster, Crab, Oyster                                                             |
| 1           | 0826dc       | 2020-02-26 05:58:37.918618| 1              | 0             | 0            | 0               | 0         | Half Off - Treat Your Shellf(ish) |                                                                                   |
| 1           | 02a5d5       | 2020-02-26 16:57:26.260871| 4              | 0             | 0            | 0               | 0         | Half Off - Treat Your Shellf(ish) |                                                                                   |
| 1           | f7c798       | 2020-03-15 02:23:26.312543| 9              | 3             | 1            | 0               | 0         | Half Off - Treat Your Shellf(ish) | Russian Caviar, Crab, Oyster                                                      |
| 1           | 30b94d       | 2020-03-15 13:12:54.023936| 9              | 7             | 1            | 1               | 1         | Half Off - Treat Your Shellf(ish) | Salmon, Kingfish, Tuna, Russian Caviar, Abalone, Lobster, Crab                    |
| 1           | 41355d       | 2020-03-25 00:11:17.860655| 6              | 1             | 0            | 0               | 0         | Half Off - Treat Your Shellf(ish) | Lobster                                                                           |
| 1           | eaffde       | 2020-03-25 20:06:32.342989| 10             | 8             | 1            | 1               | 1         | Half Off - Treat Your Shellf(ish) | Salmon, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster        |
| 2           | 3b5871       | 2020-01-18 10:16:32.158475| 9              | 6             | 1            | 1               | 1         | 25% Off - Living The Lux Life    | Salmon, Kingfish, Russian Caviar, Black Truffle, Lobster, Oyster                   |
| 2           | c5c0ee       | 2020-01-18 10:35:22.765382| 1              | 0             | 0            | 0               | 0         | 25% Off - Living The Lux Life    |                                                                                   |
| 2           | e26a84       | 2020-01-18 16:06:40.90728 | 6              | 2             | 1            | 0               | 0         | 25% Off - Living The Lux Life    | Salmon, Oyster                                                                    |
| 2           | d58cbd       | 2020-01-18 23:40:54.761906| 8              | 4             | 0            | 0               | 0         | 25% Off - Living The Lux Life    | Kingfish, Tuna, Abalone, Crab                                                     |
| 2           | 910d9a       | 2020-02-01 10:40:46.875968| 8              | 1             | 0            | 0               | 0         | Half Off - Treat Your Shellf(ish) | Abalone                                                                           |
| 2           | 1f1198       | 2020-02-01 21:51:55.078775| 1              | 0             | 0            | 0               | 0         | Half Off - Treat Your Shellf(ish) |                                                                                   |
| 2           | 49d73d       | 2020-02-16 06:21:27.138532| 11             | 9             | 1            | 1               | 1         | Half Off - Treat Your Shellf(ish) | Salmon, Kingfish, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster |
| 2           | 0635fb       | 2020-02-16 06:42:42.73573 | 9              | 4             | 1            | 0               | 0         | Half Off - Treat Your Shellf(ish) | Salmon, Kingfish, Abalone, Crab                                                  |

---

#### Use the subsequent dataset to generate at least 5 insights for the Clique Bait team. Some ideas you might want to investigate further include: 

- **Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event**

```sql
WITH user_impressions AS (
    SELECT 
        visit_id,
        SUM(CASE WHEN impressions > 0 THEN 1 ELSE 0 END) AS has_impression,
        SUM(CASE WHEN click > 0 THEN 1 ELSE 0 END) AS has_click
    FROM campaign_analysis
    GROUP BY visit_id
),
metrics_comparison AS (
    SELECT 
        ui.has_impression,
        ui.has_click,
        COUNT(DISTINCT ca.visit_id) AS total_visits,
        ROUND(AVG(ca.page_views), 2) AS avg_page_views,
        ROUND(AVG(ca.cart_adds), 2) AS avg_cart_adds,
        ROUND(AVG(ca.purchase), 2) AS purchase_rate
    FROM user_impressions ui
    JOIN campaign_analysis ca ON ui.visit_id = ca.visit_id
    GROUP BY ui.has_impression, ui.has_click
)
SELECT 
    CASE 
        WHEN has_impression = 1 AND has_click = 0 THEN 'Impression Only'
        WHEN has_impression = 1 AND has_click = 1 THEN 'Impression and Click'
        ELSE 'No Impression'
    END AS user_group,
    total_visits,
    avg_page_views,
    avg_cart_adds,
    purchase_rate
FROM metrics_comparison;
```

|campaign_status            | total_visits     |avg_page_views      | avg_cart_adds     | purchase_rate         |
|---------------------------|------------------|--------------------|-------------------|-----------------------|
| No Impression             | 2688             | 5.00               | 1.50              | 0.39                  |
| Impression Only           | 174              | 6.41               | 2.31              | 0.65                  |
| Impression and Click      | 702              | 9.07               | 5.72              | 0.89                  |

Users who engaged with both impressions and clicks exhibited the highest purchase rates (0.89). Those who only received impressions without clicks showed moderate engagement, while users with no impressions demonstrated the lowest rates.

---
- **Does clicking on an impression lead to higher purchase rates?**

```sql
SELECT 
    SUM(CASE WHEN click > 0 THEN purchase ELSE 0 END) AS purchases_with_click,
    SUM(CASE WHEN click > 0 THEN 1 ELSE 0 END) AS total_clicks,
    ROUND(SUM(CASE WHEN click > 0 THEN purchase ELSE 0 END) * 100.0 / NULLIF(SUM(CASE WHEN click > 0 THEN 1 ELSE 0 END), 0), 2) AS purchase_rate_with_click
FROM campaign_analysis;
```
| purchases_with_click     | total_clicks     | purchase_rate_with_click         |
|--------------------------|------------------|----------------------------------|
| 624                      | 702              | 88.89                            |

The analysis shows that users who clicked on impressions exhibit a higher purchase rate.

---
- **What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?**

```sql
WITH campaign_impression_data AS (
    SELECT visit_id,
           purchase,
           CASE 
               WHEN impressions > 0 AND click > 0 THEN 'clicked'
               WHEN impressions > 0 AND click = 0 THEN 'viewed_only'
               ELSE 'no_impression'
           END AS campaign_status
    FROM campaign_analysis
)
SELECT campaign_status,
       COUNT(*) AS total_visits,
       SUM(purchase) AS total_purchases,
       ROUND(SUM(purchase) * 100.0 / COUNT(*), 2) AS purchase_rate
FROM campaign_impression_data
GROUP BY campaign_status;
```

| campaign_status     | total_visits     | total_purchases     | purchase_rate         |
|---------------------|------------------|---------------------|-----------------------|
| clicked             | 702              | 624                 | 88.89                 |
| viewed_only         | 174              | 113                 | 64.94                 |
| no_impression       | 2688             | 1040                | 38.69                 |

Users who clicked on impressions have a purchase rate of 88.89%, a significant uplift compared to users without impressions (38.69%) and those who only viewed impressions (64.94%).

--- 
#### -	What metrics can you use to quantify the success or failure of each campaign compared to each other?

- **Purchase Conversion Rate by Campaign**
_We used the purchase conversion rate because it directly measures the effectiveness of campaigns in turning visits into purchases._

```sql
SELECT 
    campaign_name,
    COUNT(DISTINCT visit_id) AS total_visits,
    SUM(purchase) AS total_purchases,
    ROUND(SUM(purchase) * 100.0 / NULLIF(COUNT(DISTINCT visit_id), 0), 2) AS purchase_conversion_rate
FROM campaign_analysis
WHERE campaign_name IS NOT NULL 
GROUP BY campaign_name
ORDER BY purchase_conversion_rate DESC;
```

|campaign_name                          | total_visits     | total_purchases     | purchase_conversion_rate         |
|---------------------------------------|------------------|---------------------|----------------------------------|
| 25% Off - Living The Lux Life         | 404              | 202                 | 50.00                            |
| Half Off - Treat Your Shellf(ish)     | 2388             | 1180                | 49.41                            |
| BOGOF - Fishing For Compliments       | 260              | 127                 | 48.85                            |

The "25% Off - Living The Lux Life" campaign achieved the highest purchase conversion rate, followed closely by "Half Off - Treat Your Shellf(ish)" and "BOGOF - Fishing For Compliments." Despite differences in visit numbers, the campaigns performed similarly in converting visits into purchases.

---
- **Click-Through Rate (CTR) by Campaign**
_CTR was chosen to measure user engagement, as it reflects the effectiveness of campaigns in encouraging users to click on ads._

```sql
SELECT 
    campaign_name,
    SUM(impressions) AS total_impressions,
    SUM(click) AS total_clicks,
    ROUND(SUM(click) * 100.0 / NULLIF(SUM(impressions), 0), 2) AS click_through_rate
FROM campaign_analysis
WHERE campaign_name IS NOT NULL 
GROUP BY campaign_name
ORDER BY click_through_rate DESC;
```

| campaign_name                         | total_impressions    | total_clicks     | click_through_rate        |
|---------------------------------------|----------------------|------------------|---------------------------|
| BOGOF - Fishing For Compliments       | 65                   | 55               | 84.62                     |
| Half Off - Treat Your Shellf(ish)     | 578                  | 463              | 80.10                     |
| 25% Off - Living The Lux Life         | 104                  | 81               | 77.88                     |

The "25% Off - Living The Lux Life" campaign achieved the highest click-through rate, indicating stronger user engagement compared to the other campaigns.

---
- **Additional Analysis** 

_In this additional analysis, we sought to evaluate overall user engagement by aggregating total page views, cart additions, and purchases._

```sql
SELECT 
    campaign_name,
    SUM(page_views) AS total_page_views,
    SUM(cart_adds) AS total_cart_adds,
    SUM(purchase) AS total_purchases,
    (SUM(page_views) + SUM(cart_adds) + SUM(purchase)) AS total_interactions
FROM campaign_analysis
WHERE campaign_name IS NOT NULL 
GROUP BY campaign_name
ORDER BY total_interactions DESC;
```
| campaign_name                     | total_page_views | total_cart_adds | total_purchases| total_interactions |
|-----------------------------------|------------------|-----------------|----------------|--------------------|
| Half Off - Treat Your Shellf(ish) | 13897            | 5592            | 1180           | 20669              |
| 25% Off - Living The Lux Life     | 2434             | 991             | 202            | 3627               |
| BOGOF - Fishing For Compliments   | 1536             | 625             | 127            | 2288               |

The insights indicate that while "Half Off - Treat Your Shellf(ish)" excelled in driving interactions, the "25% Off - Living The Lux Life" campaign was more effective in terms of conversion and engagement.
 
---














