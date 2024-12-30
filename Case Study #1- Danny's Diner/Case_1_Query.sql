-- CASE STUDY #1: DANNY'S DINER 

-- Case Study Questions
-- 1. What is the total amount each customer spent at the restaurant?

-- Join 'sales' with 'menu' on product_id to access item prices
-- Group by customer_id to aggregate total spending for each customer

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

-- 2. How many days has each customer visited the restaurant?

-- Count distinct order dates to get unique visit days per customer
-- Group by customer_id to calculate visits for each customer

SELECT 
    customer_id, 
    COUNT(DISTINCT order_date) AS visit_days
FROM 
    sales
GROUP BY 
    customer_id;

--3. What was the first item from the menu purchased by each customer?

-- Rank all orders for each customer using DENSE_RANK() based on order_date
-- Filter the results to select only the first ranked purchase (rn = 1) for each customer
-- Use DISTINCT to remove any duplicate customer-product combinations
-- Note: DENSE_RANK() is chosen to handle cases where multiple orders might have occurred on the same date

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
WHERE rn = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-- Join the sales and menu tables to get product_name for each purchase
-- Group by product_name and count the number of purchases for each item
-- Sort the results by purchase count in descending order
-- Use LIMIT 1 to select only the most purchased item

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

-- 5. Which item was the most popular for each customer?

-- Calculate the order count for each product by each customer
-- Rank the products for each customer based on the order count
-- Select the product with the highest order count for each customer

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
	
-- 6. Which item was purchased first by the customer after they became a member?

-- Create a temporary table to rank purchases by each customer based on the order date.
-- The ROW_NUMBER function ensures that purchases are ordered sequentially by date.
-- Filter purchases made after the join date.
-- Select the first purchase (rank = 1) for each customer and retrieve product details.

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
	
-- 7. Which item was purchased just before the customer became a member?

-- The DENSE_RANK function ranks items in descending order based on purchase date for each customer.
-- Only purchases made before the membership join date are considered. (Customer A's order on January 7, 2021, is considered post-membership.)
-- The final selection filters the top-ranked (most recent) purchase for each customer.

WITH purchases_before_join AS (
  SELECT 
    m.customer_id,
    s.order_date,
    s.product_id,
    DENSE_RANK() OVER (PARTITION BY m.customer_id ORDER BY s.order_date DESC) AS item_rank
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

  
-- 8. What is the total items and amount spent for each member before they became a member?

-- The COUNT operation is used to determine the number of items purchased.
-- The SUM function is applied to calculate the total monetary value of the purchases.
-- Only purchases made prior to the membership join date are considered in this analysis.
-- The results are grouped by `customer_id` to ensure calculations are performed individually for each customer.

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
	
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- A 2x multiplier is applied to sushi purchases, identified by `product_id = 1`.
-- The `SUM` function aggregates spending per customer, applying the multiplier where applicable.
-- The final points are calculated by multiplying the total spending by 10.

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

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- Sushi purchases are awarded 2x points at all times.
-- Purchases made during the first week after a customer joins (including the join date) are awarded 2x points regardless of the product.
-- The `sales_with_price` CTE combines sales data with menu prices and product names for accurate calculations.
-- The `points_calculation` CTE applies the bonus multiplier rules to compute total spending and points earned.
-- Transactions are filtered to include only those made before February 2021.

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
	
-- BONUS QUESTIONS

-- 1. Join All The Things

--Select customer details along with their orders and product details.
--Add a flag to indicate membership status based on the join date.
-- 'N' for non-member purchases, 'Y' for purchases made after joining.
-- Combine data from the sales, menu, and members tables.

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
	
-- BONUS-2
-- 2. Rank All The Things

-- Create a base table with customer purchases and membership status.
-- Include order details, product names, prices, and flags indicating if the purchase occurred post-membership.
-- Rank member purchases based on order sequence.
-- Ranking is skipped (NULL) for non-member purchases to meet the requirement.
 
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

