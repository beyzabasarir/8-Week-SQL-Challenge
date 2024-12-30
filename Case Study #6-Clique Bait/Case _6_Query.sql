-- 1. Enterprise Relationship Diagram
-- 2. Digital Analysis

-- 1. How many users are there?

SELECT COUNT(DISTINCT(user_id)) AS total_users FROM users;

-- 2. How many cookies does each user have on average?

-- Identify the number of cookies per user by counting `cookie_id` for each `user_id`.
-- Group by `user_id` to ensure the count is specific to each user.
-- Calculate the average number of cookies per user.

SELECT ROUND(AVG(cookie_count),0) AS avg_cookie
FROM (
    SELECT user_id, COUNT(cookie_id) AS cookie_count
    FROM users
    GROUP BY user_id
) AS user_counts;

--3. What is the unique number of visits by all users per month?

-- Extract the month from `event_time` to categorize visits by month.
-- Use `COUNT(DISTINCT(visit_id))` to ensure only unique visits are counted.

SELECT EXTRACT(MONTH FROM event_time) AS month_number,
       TO_CHAR(event_time, 'Month') AS month_name, 
       COUNT(DISTINCT(visit_id)) AS unique_visits
FROM events
GROUP BY 1,2;
			

-- 4. What is the number of events for each event type?

SELECT event_name, COUNT(e.event_type) AS event_count
FROM events e
JOIN event_identifier ei ON e.event_type = ei.event_type 
GROUP BY 1
ORDER BY 2 DESC;

-- 5. What is the percentage of visits which have a purchase event?

-- Calculate the number of visits that include a purchase event (event_type = 3) and the total number of visits.
-- Divide the number of purchase events by the total visits to get the percentage.
-- Round the result to two decimal places for clarity.

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

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event? 

-- Count the distinct visits that reached the checkout page but didn't trigger a purchase event.
-- Count the distinct visits that resulted in a purchase event.
-- Calculate the percentage of checkout visits that did not result in a purchase.

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


-- 7. What are the top 3 pages by number of views?

-- Join the events and page_hierarchy tables on page_id to get the page names.
-- Count the number of views (visits) for each page.
-- Group the results by page name to aggregate the total views per page.
-- Order the results by the total views in descending order and limit the output to the top 3 pages.

SELECT page_name, COUNT (visit_id) AS total_views
FROM events e
JOIN page_hierarchy ph ON e.page_id= ph.page_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- 8. What is the number of views and cart adds for each product category?

-- Join the events and page_hierarchy tables on page_id to get product categories.
-- Use conditional aggregation to count the number of views (event_type = 1) and cart adds (event_type = 2) for each category.
-- Ensure that we only include categories that are not null by adding a WHERE condition.

SELECT product_category, 
       SUM (CASE WHEN event_type = 1 THEN 1 ELSE 0 END ) AS views,
	   SUM (CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM events e 
JOIN page_hierarchy ph ON e.page_id= ph.page_id
WHERE product_category IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

-- 9. What are the top 3 products by purchases?

-- Identify the distinct visit IDs associated with purchase events (event_type = 3).
-- Create a second table to join event records with product information for each "Add to Cart" event (event_type = 2), ensuring product_id is not null.
-- Join these two tables on the visit_id to associate purchases with products.
-- Count the number of purchases for each product (page_name), and order them in descending order.
-- Limit the result to the top 3 products by purchase count.

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

--3. Product Funnel Analysis
-- Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?

CREATE TABLE products_details AS 

-- Identify distinct visit IDs associated with purchase events (event_type = 3) with table1. 
WITH table1 AS (
    SELECT DISTINCT visit_id 
    FROM events 
    WHERE event_type = 3
),

-- Join events with product details to identify 'Add to Cart' actions (event_type = 2) and get relevant product information.
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

-- Aggregate the number of views for each product (event_type = 1).
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

-- calculates the number of times a product was added to cart.
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

-- Combine the data, calculating abandoned carts and purchases by using the distinct visit IDs from the previous tables.
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

-- Display the newly created products_details table.
SELECT * FROM products_details;

-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
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

-- 1. Which product had the most views, cart adds and purchases?

--Most viewed product
SELECT product_name, 
       views AS most_view 
	FROM products_details
	ORDER BY 2 DESC
	LIMIT 1;
--Most cart adds
SELECT product_name, 
       added_to_cart AS most_cart_adds 
	FROM products_details
	ORDER BY 2 DESC
	LIMIT 1
--Most purchased product
SELECT product_name, 
       purchases AS most_purchases 
	FROM products_details
	ORDER BY 2 DESC
	LIMIT 1; 


-- 2. Which product was most likely to be abandoned?

SELECT product_name, 
       abandoned AS most_abandoned 
	FROM products_details
	ORDER BY 2 DESC
	LIMIT 1;

-- 3. Which product had the highest view to purchase percentage?

SELECT product_name, 
	   round(purchases*100.0/views,2 ) as view_to_purchase
	  FROM products_details
	  GROUP BY 1,2
	  ORDER BY 2 DESC
	  LIMIT 1;

-- 4. What is the average conversion rate from view to cart add?
-- 5. What is the average conversion rate from cart add to purchase?

-- In this query, both view-to-cart and cart-to-purchase conversion rates are calculated together.
-- The 'COALESCE' function is used to handle potential null values in the data.

SELECT ROUND(AVG(COALESCE(added_to_cart, 0)::NUMERIC / views * 100),2) AS view_to_cart_conversion,
       ROUND(AVG(COALESCE(purchases, 0)::NUMERIC / added_to_cart * 100),2) AS cart_to_purchase_conversion
FROM products_details;


-- 4. Campaigns Analysis
-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:


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

-- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event

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

--Does clicking on an impression lead to higher purchase rates?

SELECT 
    SUM(CASE WHEN click > 0 THEN purchase ELSE 0 END) AS purchases_with_click,
    SUM(CASE WHEN click > 0 THEN 1 ELSE 0 END) AS total_clicks,
    ROUND(SUM(CASE WHEN click > 0 THEN purchase ELSE 0 END) * 100.0 / NULLIF(SUM(CASE WHEN click > 0 THEN 1 ELSE 0 END), 0), 2) AS purchase_rate_with_click
FROM campaign_analysis;

-- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?

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

-- What metrics can you use to quantify the success or failure of each campaign compared to eachother?

-- a. Purchase Conversion Rate by Campaign

SELECT 
    campaign_name,
    COUNT(DISTINCT visit_id) AS total_visits,
    SUM(purchase) AS total_purchases,
    ROUND(SUM(purchase) * 100.0 / NULLIF(COUNT(DISTINCT visit_id), 0), 2) AS purchase_conversion_rate
FROM campaign_analysis
WHERE campaign_name IS NOT NULL 
GROUP BY campaign_name
ORDER BY purchase_conversion_rate DESC;

-- b. Click-Through Rate (CTR) by Campaign

SELECT 
    campaign_name,
    SUM(impressions) AS total_impressions,
    SUM(click) AS total_clicks,
    ROUND(SUM(click) * 100.0 / NULLIF(SUM(impressions), 0), 2) AS click_through_rate
FROM campaign_analysis
WHERE campaign_name IS NOT NULL 
GROUP BY campaign_name
ORDER BY click_through_rate DESC;

-- Additional Analysis 

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
