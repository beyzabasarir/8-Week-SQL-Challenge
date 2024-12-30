-- High Level Sales Analysis
-- 1. What was the total quantity sold for all products?

SELECT SUM(qty) AS total_product_sold
FROM sales;

-- 2. What is the total generated revenue for all products before discounts

SELECT TO_CHAR(SUM(qty * price), '$999,999,999') AS revenue_before_discount
FROM sales;

-- 3. What was the total discount amount for all products?

SELECT 
	TO_CHAR(SUM(price * qty * discount)/100.0 , '$999,999.99') AS total_discount
FROM sales;

--Transaction Analysis
-- 1. How many unique transactions were there?

SELECT COUNT(DISTINCT (txn_id)) AS unique_txn 
FROM sales;

-- 2. What is the average unique products purchased in each transaction?

-- Group transactions by txn_id and count distinct products for each.
-- Use AVG() to find the mean of these counts, rounded to the nearest whole number.

WITH prod_counts AS (
SELECT txn_id, 
       COUNT(DISTINCT prod_id) AS product_count
FROM sales 
GROUP BY 1 ) 
SELECT ROUND(AVG(product_count),0) AS avg_unique_products
FROM prod_counts;


-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

-- Calculate revenue per transaction by factoring in quantity, price, and discount.
-- Use percentile_cont() function to compute specified percentile values.

WITH revenue AS (
SELECT *, 
       ROUND(qty * price * (1 - discount / 100.0),2) AS revenue_per_transaction
FROM sales
ORDER BY revenue_per_transaction  )
SELECT percentile_cont(0.25) WITHIN GROUP (ORDER BY revenue_per_transaction) AS Q1,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY revenue_per_transaction) AS Q2,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY revenue_per_transaction) AS Q3
FROM revenue;

-- 4. What is the average discount value per transaction?

SELECT ROUND(AVG(price * qty * discount / 100.0), 2) AS avg_discount_per_transaction
FROM sales;


-- 5. What is the percentage split of all transactions for members vs non-members? 

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


-- 6. What is the average revenue for member transactions and non-member transactions?

-- Calculate revenue per transaction considering discounts.
-- Use CASE to categorize transactions as 'Member' or 'Non-Member.'
-- Group by member status and calculate average revenue for each group.

SELECT 
    CASE WHEN member = true THEN 'Member' ELSE 'Non-Member' END AS member_status,
    ROUND(AVG(price * qty * (1 - discount / 100.0)), 2) AS avg_revenue_per_transaction
FROM sales
GROUP BY member_status;

-- Product Analysis
-- 1. What are the top 3 products by total revenue before discount?

-- Calculate total_revenue by multiplying price and quantity sold.
-- Group by product_name to show revenue per product.
-- Limit to the top 3 products.

SELECT product_name, 
       TO_CHAR (SUM(s.price * qty), '$999,999') AS total_revenue
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- 2. What is the total quantity, revenue and discount for each segment?
-- Calculate revenue using price, quantity, and discount.
-- Calculate total discount by multiplying quantity, price, and discount percentage.
SELECT segment_name,
      SUM(qty) AS total_quantity,
	  ROUND(SUM(qty * s.price * (1 - discount / 100.0)), 2) AS total_revenue,
	  ROUND(SUM(s.price * qty * discount)/100.0,2) AS total_discount
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1;
	  
--3. What is the top selling product for each segment?

-- Rank products within each segment by total quantity sold.
-- Partition by segment_name to rank separately for each segment.
-- Select the top-ranked product per segment (most sold product).

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

-- 4. What is the total quantity, revenue and discount for each category?

SELECT category_name,
      SUM(qty) AS total_quantity,
	  ROUND(SUM(qty * s.price * (1 - discount / 100.0)), 2) AS total_revenue,
	  ROUND(SUM(s.price * qty * discount)/100.0,2) AS total_discount
FROM product_details pd
JOIN sales s ON pd.product_id = s.prod_id
GROUP BY 1;

-- 5. What is the top selling product for each category?

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

-- 6. What is the percentage split of revenue by product for each segment?

-- Compute the total revenue for each segment (total_segment_revenue CTE).
-- Compute the revenue generated by each product within segments (product_revenue CTE).
-- Join the CTEs and calculate revenue percentage for each product in its segment.

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

-- 7. What is the percentage split of revenue by segment for each category?

-- Calculate total revenue for each category and segment using price, quantity, and discount.
-- Percentage split of revenue: (segment revenue / total category revenue) * 100.

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

-- 8. What is the percentage split of total revenue by category?

-- Calculate total revenue across all sales using quantity, price, and discount.
-- Calculate revenue split by category by comparing each category's revenue to the total 


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

-- 9. What is the total transaction “penetration” for each product? 
-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

-- Penetration: (distinct transactions involving a product / total distinct transactions).
-- Consider only transactions with quantity greater than 0 for penetration calculation.

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

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

WITH product_combinations AS (
    -- Step 1: Extract all transactions with a quantity greater than 0
    SELECT txn_id, prod_id
    FROM sales
    WHERE qty > 0  
),

all_combinations AS (
    -- Step 2: Generate all unique combinations of three products per transaction
    SELECT DISTINCT c1.txn_id, 
                    c1.prod_id AS prod1, 
                    c2.prod_id AS prod2, 
                    c3.prod_id AS prod3
    FROM product_combinations c1
    JOIN product_combinations c2 
        ON c1.txn_id = c2.txn_id 
        AND c1.prod_id < c2.prod_id  -- Combination of two products: prod1 and prod2
    JOIN product_combinations c3 
        ON c1.txn_id = c3.txn_id 
        AND c2.prod_id < c3.prod_id  -- Third product added: prod3
)

-- Step 3: Join with product details to get the product names and count the combinations
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
ORDER BY combo_count DESC  -- Order by most common first
LIMIT 1;  -- Limit to the most common combination


-- Reporting Challenge
-- Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

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



-- Bonus Challenge
-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

WITH RECURSIVE product_hierarchy_cte AS (
    -- Anchor member: Start with the 'Category' level
    SELECT 
        id AS hierarchy_id,
        level_text AS name,
        level_name,
        parent_id,
        id AS category_id,
        level_text AS category_name,
        CAST(NULL AS INTEGER) AS segment_id, 
        CAST(NULL AS TEXT) AS segment_name, 
        CAST(NULL AS INTEGER) AS style_id,  
        CAST(NULL AS TEXT) AS style_name 
    FROM product_hierarchy
    WHERE level_name = 'Category'
    
    UNION ALL

    -- Recursive member: Add 'Segment' and 'Style' levels
    SELECT 
        ph.id AS hierarchy_id,
        ph.level_text AS name,
        ph.level_name,
        ph.parent_id,
        cte.category_id,
        cte.category_name,
        CASE WHEN ph.level_name = 'Segment' THEN ph.id ELSE cte.segment_id END AS segment_id,
        CASE WHEN ph.level_name = 'Segment' THEN ph.level_text ELSE cte.segment_name END AS segment_name,
        CASE WHEN ph.level_name = 'Style' THEN ph.id ELSE cte.style_id END AS style_id,
        CASE WHEN ph.level_name = 'Style' THEN ph.level_text ELSE cte.style_name END AS style_name
    FROM product_hierarchy ph
    JOIN product_hierarchy_cte cte ON ph.parent_id = cte.hierarchy_id
)
-- Final query to join with product prices and generate product details
SELECT 
    pp.product_id, 
    pp.price, 
    CONCAT(cte.style_name, ' ', cte.segment_name, ' - ', cte.category_name) AS product_name,
    cte.category_id, 
    cte.segment_id, 
    cte.style_id, 
    cte.category_name, 
    cte.segment_name, 
    cte.style_name
FROM product_hierarchy_cte cte
JOIN product_prices pp ON cte.style_id = pp.id
WHERE cte.level_name = 'Style' -- Only consider the 'Style' level for final output
ORDER BY cte.category_id, cte.segment_id, cte.style_id;