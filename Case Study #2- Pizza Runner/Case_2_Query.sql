-- DATA CLEANING
-- customer_orders Update

-- In the `customer_orders` table, null or empty values in the `exclusions` and `extras` columns were replaced with proper `NULL` values to standardize the dataset.

UPDATE customer_orders 
SET EXCLUSIONS = CASE
		WHEN EXCLUSIONS = 'null'
			OR EXCLUSIONS = '' THEN NULL
		ELSE EXCLUSIONS
	END,
EXTRAS = CASE
	    WHEN EXTRAS = 'null'
			OR EXTRAS = '' THEN NULL
		ELSE EXTRAS
	END;

-- runner_orders Update 

-- The `runner_orders` table was cleaned by addressing:
-- 1. Null values in `pickup_time`, `distance`, `duration`, and `cancellation` columns.
-- 2. Removing unnecessary text from `distance` and `duration`, and ensuring values are numeric where applicable.

UPDATE runner_orders 
SET pickup_time = CASE
		WHEN pickup_time = 'null'
		   THEN NULL
		ELSE pickup_time
	END,
distance = CASE
		WHEN distance = 'null' THEN NULL
		WHEN distance LIKE '%km' THEN TRIM (distance,'km')
		ELSE distance
	END,
duration = CASE
		WHEN duration = 'null' THEN NULL
		WHEN duration LIKE '%min%' THEN TRIM (duration,'minutes')
		ELSE duration
	END,
cancellation =  CASE
		WHEN cancellation = 'null' OR cancellation = '' THEN NULL
		ELSE cancellation
	END;
	
	
-- Data Type Conversion

-- `distance` was converted to `float` for numerical operations.
-- `duration` was converted to `int` for analysis involving time.
-- `pickup_time` was converted to `timestamp` for temporal analysis.

ALTER TABLE runner_orders
ALTER COLUMN distance  
TYPE float
USING distance::double precision, 
ALTER COLUMN duration TYPE int
USING duration::integer, 
ALTER COLUMN pickup_time TYPE Timestamp
USING pickup_time::timestamp without time zone

-- Case Study Questions
-- A. Pizza Metrics

-- 1. How many pizzas were ordered?

-- The `COUNT` function aggregates the number of `order_id` entries, providing a summary of overall pizza orders.

SELECT COUNT (order_id) AS order_count FROM customer_orders;

-- 2. How many unique customer orders were made?

--The `COUNT(DISTINCT(customer_id))` function identifies and counts unique customer IDs.

SELECT COUNT(DISTINCT(customer_id)) AS unique_customers FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?

-- The `WHERE cancellation IS NULL` filter ensures only completed (non-canceled) orders are included.
-- Orders are grouped by `runner_id` to attribute deliveries to the respective runners.

SELECT runner_id, COUNT(order_id) AS delivered_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?

-- A join between `runner_orders`, `customer_orders`, and `pizza_names` ensures we match each order to its corresponding pizza type.
-- The `WHERE ro.cancellation IS NULL` condition filters out canceled orders to focus on completed deliveries.

SELECT co.pizza_id, pn.pizza_name, COUNT(ro.order_id) AS order_count
FROM runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY 1,2;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

-- A join between `customer_orders` and `pizza_names` ensures the inclusion of the pizza type.
-- Grouping by `customer_id` and `pizza_name` allows for detailed aggregation per customer and pizza type.

SELECT co.customer_id, pn.pizza_name, COUNT(pn.pizza_name) AS order_count
FROM customer_orders co 
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY 1,2
ORDER BY 1;


-- 6. What was the maximum number of pizzas delivered in a single order?

-- The `COUNT` function is applied to count pizzas within each order (`order_id`).
-- A join with `runner_orders` excludes any cancelled orders using the `cancellation IS NULL` filter.
-- Results are sorted by the pizza count in descending order to retrieve the highest value.
-- The `LIMIT 1` clause ensures only the top result is returned.

SELECT co.order_id, COUNT(co.pizza_id) AS pizza_count
FROM customer_orders co
JOIN runner_orders ro ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

-- The `CASE` statement determines the change status based on whether both `exclusions` and `extras` are null.
-- Orders are filtered to exclude cancellations by joining with `runner_orders` and applying the `cancellation IS NULL` condition.
-- Grouping by `customer_id` and `change_status` ensures proper categorization of order counts.


SELECT co.customer_id, COUNT (co.order_id) AS order_count,
CASE WHEN co.exclusions IS NULL AND  co.extras IS NULL 
       THEN 'No Changes'
     ELSE 'Change'
   END AS change_status
FROM customer_orders co
JOIN runner_orders ro ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1,3;

-- 8. How many pizzas were delivered that had both exclusions and extras?

-- Filters ensure only non-cancelled orders are considered (`cancellation IS NULL`).
-- The conditions `exclusions IS NOT NULL` and `extras IS NOT NULL` verify that both modifications exist for each order.
-- Grouping by `order_id` ensures the count is calculated per order.

SELECT co.order_id, COUNT(co.order_id) AS order_count
FROM customer_orders co
JOIN runner_orders ro ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL 
AND co.exclusions IS NOT NULL 
AND co.extras IS NOT NULL  
GROUP BY 1;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- The hour is extracted from order_time and orders are grouped by these hourly intervals.
-- The percentage of total orders for each hour is calculated to provide insight into which times see the highest activity.
SELECT 
    TO_CHAR(order_time, 'HH24') AS order_hour, 
    COUNT(order_id) AS order_count,
    ROUND(100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER(), 2) AS order_percentage
FROM 
    customer_orders
GROUP BY 
    TO_CHAR(order_time, 'HH24')
ORDER BY 
    order_hour;

--10. What was the volume of orders for each day of the week?
--Orders are grouped by the day extracted from order_time, and their percentage of the total is calculated to highlight key trends. 

SELECT TO_CHAR(order_time, 'Day') AS order_day, 
       COUNT (order_id) AS order_count,
	   ROUND(100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER(), 2) AS order_percentage
FROM customer_orders
GROUP BY 1
ORDER BY 2 DESC;

-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

-- The `CASE` statement divides the registration dates into specific weekly periods, starting from January 1, 2021.
-- '2021-01-01' was designated as 'Week Start' because it was marked as the reference point for tracking weekly sign-ups.
-- The data captures the first two full weeks, reflecting the scope of available records in the dataset.

SELECT 
     CASE
	    WHEN registration_date = '2021-01-01' THEN 'Week Start'
        WHEN registration_date > '2021-01-01' AND registration_date <= '2021-01-08' THEN 'Week 1'
        WHEN registration_date > '2021-01-08' AND registration_date <= '2021-01-15' THEN 'Week 2'
    END AS week_number,
    Count(runner_id) AS runner_count
FROM
    runners
GROUP BY
    1;	


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

-- The `EXTRACT(EPOCH FROM ...)` function calculates the difference between `pickup_time` and `order_time` in seconds.
-- The result is divided by 60 to convert the time difference into minutes.
-- The `ROUND` function ensures that the average time is presented without decimals for clarity.
-- Filtering out records with `pickup_time IS NULL` ensures only completed pickups are included in the calculation.

SELECT runner_id, 
       ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60),0)  AS avg_pickup_time FROM runner_orders ro
JOIN customer_orders co ON 
ro.order_id=co.order_id
WHERE pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 2;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- Only completed orders are included in the analysis, as records with missing pickup times are filtered out.
-- Preparation times are grouped by pizza count, and the average preparation time is calculated for orders with the same number of pizzas.

WITH pizza_counts AS (
SELECT order_id, order_time, COUNT(pizza_id) AS pizza_count
FROM customer_orders 
	GROUP BY 1,2
	)
SELECT pizza_count,	
ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60),0)  AS preperation_time 
FROM pizza_counts pc
JOIN runner_orders ro ON 
ro.order_id=pc.order_id
WHERE pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- 4. What was the average distance travelled for each customer?

-- Filtering out `NULL` distances ensures that only completed deliveries with valid data are considered.
-- Joining `customer_orders` with `runner_orders` allows access to the `distance` field, as it resides in the `runner_orders` table.

SELECT customer_id, 
       ROUND(AVG(ro.distance)::numeric, 0) AS avg_distance
FROM customer_orders co 
JOIN runner_orders ro ON co.order_id=ro.order_id
WHERE distance IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- 5. What was the difference between the longest and shortest delivery times for all orders?

-- The `MAX` and `MIN` functions extract the longest and shortest delivery times from the `duration` column.
-- Results reflect delivery times recorded in the `runner_orders` table, excluding canceled or incomplete orders.

SELECT MAX(duration::NUMERIC) AS longest_delivery,
       MIN(duration::NUMERIC) AS shortest_delivery,
       MAX(duration::NUMERIC) - MIN(duration::NUMERIC) AS delivery_time_difference
FROM runner_orders
WHERE duration IS NOT NULL;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

-- Delivery duration is converted to hours for consistency.
-- Speed is computed by dividing distance by time, reflecting the runner’s efficiency.
-- Only valid entries with non-null distance are considered.

SELECT runner_id, distance,  ROUND(duration / 60.0, 2) AS duration_hour, 
       ROUND(AVG(distance/duration * 60)::numeric, 2) AS avg_speed
FROM runner_orders 
WHERE distance IS NOT NULL
GROUP BY 1,2,3
ORDER BY 1;


-- 7. What is the successful delivery percentage for each runner?

-- The query considers only completed deliveries to determine success.
-- The percentage is calculated relative to total assignments.
-- Results are rounded to the nearest whole number for clarity.

SELECT 
    runner_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE distance IS NOT NULL) / COUNT(*), 0) AS success_percentage
FROM 
    runner_orders
GROUP BY 
    runner_id
ORDER BY 
    runner_id;

-- C. Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?

---- The query processes comma-separated toppings and combines them with the pizza_toppings table to display the full set of ingredients for each pizza.

SELECT 
    pn.pizza_name,
    STRING_AGG(pt.topping_name, ', ') AS ingredients
FROM pizza_recipes pr
JOIN pizza_toppings pt
    ON pt.topping_id = ANY(STRING_TO_ARRAY(pr.toppings, ',')::INT[])
JOIN pizza_names pn
    ON pr.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name;

-- 2. What was the most commonly added extra?

-- The query parses the extras field into an array, then expands it into individual rows to count the frequency of each topping.
-- Aggregating by the common_extra value allows for identifying the most frequent topping.
-- The result is limited to the top-ranking topping by ordering and using LIMIT 1.
-- Joining with the pizza_toppings table ensures that topping names are shown instead of their IDs.

SELECT topping_name, frequency
FROM (
    SELECT unnest(string_to_array(extras, ', ')) AS common_extra, COUNT(*) AS frequency
    FROM customer_orders
	GROUP BY 1
	ORDER BY 2 DESC
	LIMIT 1
) AS ce
JOIN pizza_toppings pt
    ON pt.topping_id = ANY(STRING_TO_ARRAY(ce.common_extra, ',')::INT[]);

-- 3. What was the most common exclusion?

-- The string_to_array function is used to split the exclusions into individual toppings, and their frequency is calculated.
-- Only the most common exclusion is selected for further analysis.

SELECT topping_name, frequency
FROM (
    SELECT unnest(string_to_array(exclusions, ', ')) AS common_exclusion, COUNT(*) AS frequency
    FROM customer_orders
	GROUP BY 1
	ORDER BY 2 DESC
	LIMIT 1
) AS ce
JOIN pizza_toppings pt
    ON pt.topping_id = ANY(STRING_TO_ARRAY(ce.common_exclusion, ',')::INT[]);


-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following: 
-- Meat Lovers , 
-- Meat Lovers - Exclude Beef, 
-- Meat Lovers - Extra Bacon, 
-- Meat Lovers - Exclude Cheese, 
-- Bacon - Extra Mushroom, Peppers


-- The query starts by creating the order_details subquery to capture each order's pizza name, excluded toppings, and extra toppings.
-- STRING_AGG is used to aggregate the exclusions and extras into a single string for each order.
-- The main SELECT statement utilizes a CASE expression to format the order item, handling different scenarios based on the presence of exclusions and/or extras.
-- Four possible scenarios are covered:
-- 1. No exclusions or extras, returning only the pizza name.
-- 2. Exclusions only, appending the excluded toppings.
-- 3. Extras only, appending the extra toppings.
-- 4. Both exclusions and extras, appending both in the order of exclusions followed by extras.

WITH order_details AS (
    SELECT 
        co.order_id,
        co.customer_id,
        pn.pizza_name,
        STRING_AGG(DISTINCT pt_excluded.topping_name, ', ') AS excluded_toppings,
        STRING_AGG(DISTINCT pt_extra.topping_name, ', ') AS extra_toppings
    FROM customer_orders co
    LEFT JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
    LEFT JOIN pizza_toppings pt_excluded ON pt_excluded.topping_id = ANY(string_to_array(co.exclusions, ',')::int[])
    LEFT JOIN pizza_toppings pt_extra ON pt_extra.topping_id = ANY(string_to_array(co.extras, ',')::int[])
    GROUP BY co.order_id, co.customer_id, pn.pizza_name
)
SELECT 
    order_id,
    customer_id,
    CASE 
        WHEN excluded_toppings IS NULL AND extra_toppings IS NULL THEN pizza_name
        WHEN extra_toppings IS NULL THEN CONCAT(pizza_name, ' - Exclude ', excluded_toppings)
        WHEN excluded_toppings IS NULL THEN CONCAT(pizza_name, ' - Extra ', extra_toppings)
        ELSE CONCAT(pizza_name, ' - Exclude ', excluded_toppings, ' - Extra ', extra_toppings)
    END AS order_item
FROM order_details;


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- Within the CTE, STRING_AGG concatenates toppings, prefixing "2x" for extra toppings.
-- A LEFT JOIN is used to bring in pizza details from pizza_recipes and their respective toppings.
-- The CASE statement inside STRING_AGG ensures "2x" is applied only to extra toppings.
-- In the main SELECT, the pizza name is displayed followed by the ingredient list.

WITH pizza_ingredients AS (
    SELECT 
        co.order_id,
        co.customer_id,
        pn.pizza_name,
        STRING_AGG(DISTINCT pt.topping_name, ', ') AS all_ingredients,
        STRING_AGG(DISTINCT CASE 
            WHEN pt.topping_id = ANY(string_to_array(co.extras, ',')::int[]) THEN CONCAT('2x', pt.topping_name)
            ELSE pt.topping_name
        END, ', ') AS ingredient_list
    FROM customer_orders co
    LEFT JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
    LEFT JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
    LEFT JOIN pizza_toppings pt ON pt.topping_id = ANY(string_to_array(pr.toppings, ',')::int[])
    GROUP BY co.order_id, co.customer_id, pn.pizza_name
)
SELECT 
    order_id,
    customer_id,
    CONCAT(pizza_name, ': ', 
           STRING_AGG(DISTINCT ingredient_list, ', ' ORDER BY ingredient_list)) AS formatted_ingredients
FROM pizza_ingredients
GROUP BY order_id, customer_id, pizza_name
ORDER BY order_id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

-- The query handles exclusions and extras, ensuring that excluded toppings are not counted and extra toppings are included.
-- The results are sorted by the most frequent topping first.

WITH expanded_pizzas AS (
    SELECT 
        co.order_id,
        pr.pizza_id,
        pr.toppings AS all_toppings,
        co.exclusions,
        co.extras
    FROM 
        customer_orders co
    JOIN 
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
    WHERE 
        co.exclusions IS NOT NULL OR co.extras IS NOT NULL
),
processed_toppings AS (
    SELECT
        order_id,
        unnest(string_to_array(all_toppings, ',')) AS topping_id,
        exclusions,
        extras
    FROM 
        expanded_pizzas
    UNION ALL
    SELECT
        order_id,
        unnest(string_to_array(extras, ',')) AS topping_id,
        exclusions,
        extras
    FROM 
        expanded_pizzas
),
final_toppings AS (
    SELECT
        order_id,
        topping_id,
        CASE
            WHEN exclusions IS NOT NULL AND position(topping_id IN exclusions) > 0 THEN NULL
            ELSE topping_id
        END AS valid_topping
    FROM 
        processed_toppings
),
counted_toppings AS (
    SELECT 
        valid_topping,
        COUNT(*) AS topping_count
    FROM 
        final_toppings
    WHERE valid_topping IS NOT NULL
    GROUP BY valid_topping
)
SELECT 
    pt.topping_name,
    ct.topping_count
FROM 
    counted_toppings ct
JOIN 
    pizza_toppings pt ON ct.valid_topping::int = pt.topping_id
ORDER BY 
    ct.topping_count DESC;


-- D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

-- The delivered_orders CTE first filters out canceled orders and counts how many times each type of pizza was ordered.
-- The pizza_prices CTE assigns a price to each type of pizza: $12 for Meat Lovers and $10 for Vegetarian.
-- In the final SELECT, the total earnings are calculated by multiplying the number of orders by the corresponding pizza cost, and the results are grouped by pizza type.

WITH delivered_orders AS (
    SELECT 
        co.pizza_id, 
        pn.pizza_name, 
        COUNT(ro.order_id) AS order_count
    FROM 
        runner_orders ro
    JOIN 
        customer_orders co 
        ON ro.order_id = co.order_id
    JOIN 
        pizza_names pn 
        ON co.pizza_id = pn.pizza_id
    WHERE 
        ro.cancellation IS NULL
    GROUP BY 
        1, 2
), 
pizza_prices AS (
    SELECT 
        pizza_name, 
        CASE 
            WHEN pizza_id = 1 THEN 12
            ELSE 10 
        END AS pizza_cost
    FROM 
        delivered_orders
)
SELECT 
    d.pizza_name, 
    (d.order_count * pp.pizza_cost) AS total_earning
FROM 
    delivered_orders d
JOIN 
    pizza_prices pp 
    ON d.pizza_name = pp.pizza_name
GROUP BY 
    1,2
ORDER BY 
    2 DESC;


-- 2. What if there was an additional $1 charge for any pizza extras?

-- The delivered_orders CTE retrieves delivered pizza orders and includes information on extras.
-- The pizza_prices CTE assigns a base price to each pizza: $12 for Meat Lovers and $10 for Vegetarian.
-- In final_orders, the extra_count is calculated by determining the number of extra toppings in each order (using string length comparison).
-- The final query multiplies the number of orders by the pizza cost, including the extra charges, and groups the results by pizza type and extra count.

WITH delivered_orders AS (
  SELECT co.pizza_id, pn.pizza_name, COUNT(ro.order_id) AS order_count, co.extras
  FROM runner_orders ro
  JOIN customer_orders co ON ro.order_id = co.order_id
  JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
  WHERE ro.cancellation IS NULL
  GROUP BY 1,2,4
) , 
pizza_prices AS (
  SELECT pizza_name, 
    CASE WHEN pizza_id = 1 THEN 12
    ELSE 10 END AS pizza_cost
  FROM delivered_orders
),
final_orders AS (
  SELECT 
	     d.pizza_name, 
         d.order_count, 
         pp.pizza_cost, 
         COALESCE(LENGTH(d.extras) - LENGTH(REPLACE(d.extras, ',', '')) + 1, 0) AS extra_count 
  FROM delivered_orders d
  JOIN pizza_prices pp ON d.pizza_name = pp.pizza_name
)
SELECT pizza_name, extra_count, order_count,
       (order_count * (pizza_cost + extra_count)) AS total_earning
FROM final_orders
GROUP BY 1,2,3,4
ORDER BY 4 DESC;

-- 3.The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- Orders 6 and 9 have been excluded from the table due to cancellations.

DROP TABLE IF EXISTS runner_rating;

CREATE TABLE runner_rating (
    order_id INTEGER, 
    rating INTEGER, 
    review VARCHAR(100)
);

INSERT INTO runner_rating
VALUES 
    (1, 2, 'Not the best experience; I expected more from the service.'),
    (2, 3, 'Decent delivery, but I had higher hopes for the pizza quality.'),
    (3, 4, 'Took longer than expected, but the pizza tasted great.'),
    (4, 1, 'Really disappointed with the service; the pizza arrived cold.'),
    (5, 5, 'Fantastic service! The pizza was fresh and delicious.'),
    (7, 4, 'Service was okay, but there was a bit of confusion with my order.'),
    (8, 3, 'I was pleased with the delivery; the food was satisfying.'),
    (10, 5, 'Excellent service! The pizza was amazing and delivered perfectly.');

SELECT *
FROM runner_rating;

--4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id 
-- order_id 
-- runner_id
-- rating 
-- order_time 
-- pickup_time
-- Time between order and pickup : Difference between order_time and pickup_time in minutes.
-- Delivery duration 
-- Average speed : Calculated as distance / duration and scaled to minutes.
-- Total number of pizzas 

-- customer_orders and runner_orders are joined on order_id to link orders with deliveries.
-- runner_rating is joined to include customer ratings for each delivery.
-- Where clause filters only successful orders (no cancellations).


SELECT customer_id, ro.order_id, runner_id, rating, order_time, pickup_time,
       ROUND((EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60),2)  AS order_to_pickup_time,
	   duration, 
	   ROUND(AVG(distance/duration * 60)::numeric, 2) AS avg_speed,
	   COUNT (pizza_id) AS pizza_count
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN runner_rating rr ON ro.order_id= rr.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1,2,3,4,5,6,8;



--5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

-- Total revenue from pizza sales is calculated by assigning prices for each pizza type
-- Delivery costs are computed based on the distance traveled, with a rate of $0.30 per kilometer for each runner.
-- Canceled orders are excluded using the condition WHERE ro.cancellation IS NULL.

WITH total_pizza_revenue AS (
    SELECT 
        SUM(CASE
            WHEN co.pizza_id = 1 THEN 12  -- Meatlovers pizza
            WHEN co.pizza_id = 2 THEN 10  -- Vegetarian pizza
        END) AS pizza_revenue
    FROM customer_orders co
),
delivery_costs AS (
    SELECT 
        ro.distance,
        CASE
            WHEN ro.distance IS NOT NULL THEN ro.distance * 0.30  
            ELSE 0
        END AS delivery_payment
    FROM runner_orders ro
    WHERE ro.cancellation IS NULL  
),
total_delivery_cost AS (
    SELECT SUM(delivery_payment) AS total_delivery_expense
    FROM delivery_costs
)
SELECT
    total_pizza_revenue.pizza_revenue AS total_pizza_income,
    total_delivery_cost.total_delivery_expense AS total_delivery_payment,
    (total_pizza_revenue.pizza_revenue - total_delivery_cost.total_delivery_expense) AS remaining_profit
FROM total_pizza_revenue, total_delivery_cost;

-- BONUS QUESTION
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?


INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

SELECT * FROM pizza_names
SELECT * FROM pizza_recipes

