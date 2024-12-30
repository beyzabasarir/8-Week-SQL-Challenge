# Case Study #2: Pizza Runner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png" alt="Image" width="450" height="470">

## Table of Contents
1. [Introduction](#introduction)
2. [Data Overview](#data-overview)
3. [Data Cleaning](#data-cleaning)
4. [Case Study Questions and Solutions](#case-study-questions-and-solutions)
    - [A-Pizza Metrics](#a-pizza-metrics)
    - [B-Runner and Customer Experience](#b-runner-and-customer-experience)
    - [C-Ingredient Optimisation](#c-ingredient-optimisation)
    - [D-Pricing and Ratings](#d-pricing-and-ratings)
6. [Bonus Questions](#bonus-questions)

For more details about the original challenge, please refer to the [8 Week SQL Challenge website](https://8weeksqlchallenge.com/case-study-2/).

---
## Introduction

Pizza Runner is a fictional business concept that combines traditional pizza delivery with a modern, app-based model. This system leverages runners for efficient delivery, aiming to enhance customer satisfaction while streamlining operations.

---
## Data Overview

The database for this case study consists of six interconnected tables that provide insights into the business operations, including customer orders, runner activities, and pizza recipes. Below is a brief overview of each table:

<details>
<summary> Table 1: runners </summary>

This table includes information about delivery runners and their registration dates. It serves as the foundation for analyzing runner availability and performance.

| Column Name      | Description                                  |
|------------------|----------------------------------------------|
| runner_id        | Unique identifier for each runner            |
| registration_date| Date the runner was registered               |

</details>

<details>
<summary> Table 2: customer_orders </summary>

Captures individual pizza orders, including any customizations such as ingredient exclusions or additions.

| Column Name      | Description                                  |
|------------------|----------------------------------------------|
| order_id         | Unique identifier for each order             |
| customer_id      | Identifier for the customer placing the order|
| pizza_id         | Type of pizza ordered                        |
| exclusions       | Ingredients to exclude                       |
| extras           | Additional ingredients requested             |
| order_time       | Timestamp of the order placement             |

</details>
<details>
<summary> Table 3: runner_orders </summary>

Tracks the assignment and delivery performance of runners, including timestamps and delivery metrics.

| Column Name      | Description                                  |
|------------------|----------------------------------------------|
| order_id         | Unique identifier for the customer order     |
| runner_id        | Assigned runner for the order                |
| pickup_time      | Timestamp when the order was picked up       |
| distance         | Distance covered to complete the delivery    |
| duration         | Time taken to deliver the order              |
| cancellation     | Reason for cancellation, if applicable       |

</details>
<details>
<summary> Table 4: pizza_names </summary>

Defines the current pizza offerings. At present, there are two options available:

| Column Name      | Description                                  |
|------------------|----------------------------------------------|
| pizza_id         | Unique identifier for each pizza type        |
| pizza_name       | Name of the pizza                            |

</details>

<details>
<summary> Table 5: pizza_recipes </summary>

Details the standard set of toppings for each pizza type, linking the pizza_id with corresponding topping_id values.

| Column Name      | Description                                  |
|------------------|----------------------------------------------|
| pizza_id         | Pizza type identifier                        |
| topping_id       | Identifier for the topping                   |

</details>

<details>
<summary> Table 6: pizza_toppings </summary>

Provides a comprehensive list of all available pizza toppings and their unique identifiers.

| Column Name      | Description                                  |
|------------------|----------------------------------------------|
| topping_id       | Unique identifier for toppings               |
| topping_name     | Name of the topping                          |

</details>

An Entity Relationship Diagram (ERD) illustrating the connections between these tables is provided below:

![ERD Image](https://github.com/beyzabasarir/8-Week-SQL-Challenge/blob/main/Case%20Study%20%232-%20Pizza%20Runner/ERD.png)

---
## Data Cleaning

The cleaning process focused on three main areas:
1. **Handling Null Values**: Ensuring missing or empty values are properly represented as NULL for consistency.
2. **Standardizing Data Formats**: Removing unnecessary text and ensuring uniformity in data representation.
3. **Converting Data Types**: Aligning column types with the requirements for analysis and calculations.

#### In the `customer_orders` table, the exclusions and extras columns were updated to replace invalid values with NULL:

```sql
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
```

#### In the runner_orders table, similar cleaning was applied to pickup_time, distance, duration, and cancellation columns. Unnecessary text such as km and minutes was removed from the distance and duration columns:

```sql
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
```

#### After standardization, column types were updated to align with analysis requirements:

```sql
ALTER TABLE runner_orders
ALTER COLUMN distance  
TYPE float
USING distance::double precision, 
ALTER COLUMN duration TYPE int
USING duration::integer, 
ALTER COLUMN pickup_time TYPE Timestamp
USING pickup_time::timestamp without time zone
```

---
## Case Study Questions and Solutions

### A-Pizza Metrics

#### 1. How many pizzas were ordered?

```sql
SELECT COUNT(order_id) AS order_count
FROM customer_orders;
```

| order_count |
|-------------|
| 14          |


---

#### 2. How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT(customer_id)) AS unique_customers
FROM customer_orders;
#### 1. How many pizzas were ordered?
```

| unique_customers |
|------------------|
| 5                |

5 unique customers placed orders.

---

#### 3. How many successful orders were delivered by each runner?

```sql
SELECT runner_id, COUNT(order_id) AS delivered_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
```

| runner_id | delivered_orders |
|-----------|------------------|
| 1         | 4                |
| 2         | 3                |
| 3         | 1                |

 Runner 1 delivered the highest number of successful orders (4), followed by Runner 2 (3), and Runner 3 (1).

---

#### 4. How many of each type of pizza was delivered?

```sql
SELECT co.pizza_id, pn.pizza_name, COUNT(ro.order_id) AS order_count
FROM runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY 1,2;
````

| pizza_id | pizza_name   | order_count |
|----------|--------------|-------------|
| 1        | Meatlovers   | 9           |
| 2        | Vegetarian   | 3           |

Meatlovers pizzas were significantly more popular, with 9 successful deliveries, compared to only 3 deliveries of Vegetarian pizzas.

---

#### 5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT co.customer_id, pn.pizza_name, COUNT(pn.pizza_name) AS order_count
FROM customer_orders co 
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY 1,2
ORDER BY 1;
```

| customer_id | pizza_name   | order_count |
|-------------|--------------|-------------|
| 101         | Meatlovers   | 2           |
| 101         | Vegetarian   | 1           |
| 102         | Meatlovers   | 2           |
| 102         | Vegetarian   | 1           |
| 103         | Meatlovers   | 3           |
| 103         | Vegetarian   | 1           |
| 104         | Meatlovers   | 3           |
| 105         | Vegetarian   | 1           |

Meatlovers pizzas were consistently ordered more frequently by customers, with some individuals (e.g., Customer 103 and 104) ordering three. Vegetarian pizzas were ordered less often, with only one instance per customer.

---

#### 6. What was the maximum number of pizzas delivered in a single order?

```sql
SELECT co.order_id, COUNT(co.pizza_id) AS pizza_count
FROM customer_orders co
JOIN runner_orders ro ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
```

| order_id | pizza_count |
|----------|-------------|
| 4        | 3           |

The highest number of pizzas delivered in a single order was three, associated with order ID 4.

---

#### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
SELECT co.customer_id, COUNT (co.order_id) AS order_count,
CASE WHEN co.exclusions IS NULL AND co.extras IS NULL 
       THEN 'No Changes'
     ELSE 'Change'
   END AS change_status
FROM customer_orders co
JOIN runner_orders ro ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1,3;
```

| customer_id | order_count | change_status |
|-------------|-------------|---------------|
| 101         | 2           | No Changes    |
| 102         | 3           | No Changes    |
| 103         | 3           | Change        |
| 104         | 2           | Change        |
| 104         | 1           | No Changes    |
| 105         | 1           | Change        |

Customers exhibited varied ordering behaviors: some consistently placed orders with no changes (e.g., Customer 102), while others included changes frequently (e.g., Customer 103). Customer 104 had a mix of both.

---

#### 8. How many pizzas were delivered that had both exclusions and extras?

```sql
SELECT co.order_id, COUNT(co.order_id) AS order_count
FROM customer_orders co
JOIN runner_orders ro ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL 
AND co.exclusions IS NOT NULL 
AND co.extras IS NOT NULL  
GROUP BY 1;
```

| order_id | order_count |
|----------|-------------|
| 10       | 1           |

Only one delivered pizza was customized with both exclusions and extras. This indicates that while customizations are common, combining both types of changes in a single order is relatively rare among customers.

---

#### 9. What was the total volume of pizzas ordered for each hour of the day?

```sql
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
```

| order_hour | order_count | order_percentage |
|------------|-------------|------------------|
| 11         | 1           | 7.14             |
| 13         | 3           | 21.43            |
| 18         | 3           | 21.43            |
| 19         | 1           | 7.14             |
| 21         | 3           | 21.43            |
| 23         | 3           | 21.43            |

Pizza orders were spread across various hours of the day, with peak activity observed at 13:00, 18:00, 21:00, and 23:00 hours, each accounting for 21.43% of the total pizza orders. This indicates that demand tends to be highest during meal times and in the late evening.

--- 

#### 10. What was the volume of orders for each day of the week?

```sql
SELECT TO_CHAR(order_time, 'Day') AS order_day, 
       COUNT (order_id) AS order_count,
       ROUND(100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER(), 2) AS order_percentage
FROM customer_orders
GROUP BY 1
ORDER BY 2 DESC;
```

| order_day   | order_count | order_percentage |
|-------------|-------------|------------------|
| Saturday    | 5           | 35.71            |
| Wednesday   | 5           | 35.71            |
| Thursday    | 3           | 21.43            |
| Friday      | 1           | 7.14             |

Pizza orders were primarily concentrated on Saturdays and Wednesdays, each accounting for 35.71% of total orders. Thursdays followed with 21.43% of the orders, while Friday saw the least demand with only 7.14%.

--- 

### B-Runner and Customer Experience

#### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
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
```

| week_number  | runner_count |
|--------------|--------------|
| Week Start   | 1            |
| Week 1       | 2            |
| Week 2       | 1            |

--- 

#### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```sql
SELECT runner_id, 
       ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60),0)  AS avg_pickup_time 
FROM runner_orders ro
JOIN customer_orders co ON 
ro.order_id=co.order_id
WHERE pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 2;
```

| runner_id | avg_pickup_time |
|-----------|-----------------|
| 3         | 10              |
| 1         | 16              |
| 2         | 24              |

Runner 3 displayed the fastest pickup performance, taking an average of 10 minutes to arrive at the Pizza Runner HQ. Runner 1 followed with an average of 16 minutes, while Runner 2 exhibited the slowest pickup time, averaging 24 minutes.

--- 

#### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
WITH pizza_count AS (
SELECT order_id, order_time, COUNT(pizza_id) AS pizza_count
FROM customer_orders 
    GROUP BY 1,2
    )
SELECT pizza_count,    
ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60),0)  AS preperation_time 
FROM pizza_count pc
JOIN runner_orders ro ON 
ro.order_id=pc.order_id
WHERE pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 1;
```

| pizza_count | preperation_time |
|-------------|------------------|
| 1           | 12               |
| 2           | 18               |
| 3           | 29               |

Orders containing a single pizza take approximately 12 minutes to prepare on average, while orders with two pizzas take 18 minutes. Preparation time increases significantly for three pizzas, averaging 29 minutes. This trend highlights the increased time required to handle larger orders, which is an expected operational outcome.

--- 

#### 4. What was the average distance travelled for each customer?

```sql
SELECT customer_id, 
       ROUND(AVG(ro.distance)::numeric, 0) AS avg_distance
FROM customer_orders co 
JOIN runner_orders ro ON co.order_id=ro.order_id
WHERE distance IS NOT NULL
GROUP BY 1
ORDER BY 1;
```

| customer_id | avg_distance |
|-------------|--------------|
| 101         | 20           |
| 102         | 17           |
| 103         | 23           |
| 104         | 10           |
| 105         | 25           |

The average distance traveled varies by customer, reflecting differences in delivery locations or order patterns. Customer 105 records the highest average distance, with 25 km, while customer 104 records the shortest average distance of 10 km.

--- 

#### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(duration::NUMERIC) AS longest_delivery,
       MIN(duration::NUMERIC) AS shortest_delivery,
       MAX(duration::NUMERIC) - MIN(duration::NUMERIC) AS delivery_time_difference
FROM runner_orders
WHERE duration IS NOT NULL;
```

| longest_delivery | shortest_delivery | delivery_time_difference |
|------------------|-------------------|---------------------------|
| 40               | 10                | 30                        |

The longest recorded delivery time is 40 minutes, while the shortest is 10 minutes, showing a difference of 30 minutes.

--- 

#### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```sql
SELECT runner_id, distance,  ROUND(duration / 60.0, 2) AS duration_hour, 
       ROUND(AVG(distance/duration * 60)::numeric, 2) AS avg_speed
FROM runner_orders 
WHERE distance IS NOT NULL
GROUP BY 1,2,3
ORDER BY 1;
```

| runner_id | distance | duration_hour | avg_speed |
|-----------|----------|---------------|-----------|
| 1         | 20       | 0.53          | 37.50     |
| 1         | 13.4     | 0.33          | 40.20     |
| 1         | 20       | 0.45          | 44.44     |
| 1         | 10       | 0.17          | 60.00     |
| 2         | 25       | 0.42          | 60.00     |
| 2         | 23.4     | 0.67          | 35.10     |
| 2         | 23.4     | 0.25          | 93.60     |
| 3         | 10       | 0.25          | 40.00     |

Runner 2 records the highest average speed at 93.60 km/h, achieved during a notably shorter delivery duration of just 0.25 hours. This performance warrants further investigation, as it significantly deviates from the typical speed range. Overall, shorter delivery durations tend to correlate with higher speeds, especially when the distances are moderate. The other runners generally maintain speeds between 35 km/h and 60 km/h.

--- 

#### 7. What is the successful delivery percentage for each runner?

```sql
SELECT 
    runner_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE distance IS NOT NULL) / COUNT(*), 0) AS success_percentage
FROM 
    runner_orders
GROUP BY 
    runner_id
ORDER BY 
    runner_id;
```

| runner_id | success_percentage |
|-----------|---------------------|
| 1         | 100                 |
| 2         | 75                  |
| 3         | 50                  |

Runner 1 achieved a 100% success rate, completing all assigned deliveries successfully. Runner 2 achieved a success rate of 75%, while Runner 3 completed only half of their deliveries, resulting in a 50% success rate.

--- 

### C-Ingredient Optimisation

#### 1. What are the standard ingredients for each pizza?

```sql
SELECT 
    pn.pizza_name,
    STRING_AGG(pt.topping_name, ', ') AS ingredients
FROM pizza_recipes pr
JOIN pizza_toppings pt
    ON pt.topping_id = ANY(STRING_TO_ARRAY(pr.toppings, ',')::INT[])
JOIN pizza_names pn
    ON pr.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name;
```

| pizza_name   | ingredients                                                                          |
|--------------|--------------------------------------------------------------------------------------|
| Meatlovers   | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami               |
| Vegetarian   | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce                         |

---

#### 2. What was the most commonly added extra?

```sql
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
```

| topping_name | frequency |
|--------------|-----------|
| Bacon        | 4         |

The most frequently added extra topping across all orders was Bacon, with a total of 4 occurrences.

---

#### 3. What was the most common exclusion?

```sql
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
```

| topping_name | frequency |
|--------------|-----------|
| Cheese       | 4         |

The result shows that "Cheese" is the most frequently excluded topping, with 4 customers choosing to remove it from their orders.

---

#### 4.	Generate an order item for each record in the customers_orders table in the format of one of the following:
-	Meat Lovers
-	Meat Lovers - Exclude Beef
-	Meat Lovers - Extra Bacon
-	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


```sql
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
```

| order_id | customer_id | order_item                                                        |
|----------|-------------|-------------------------------------------------------------------|
| 1        | 101         | Meatlovers                                                       |
| 2        | 101         | Meatlovers                                                       |
| 3        | 102         | Meatlovers                                                       |
| 3        | 102         | Vegetarian                                                       |
| 4        | 103         | Meatlovers - Exclude Cheese                                      |
| 4        | 103         | Vegetarian - Exclude Cheese                                      |
| 5        | 104         | Meatlovers - Extra Bacon                                         |
| 6        | 101         | Vegetarian                                                       |
| 7        | 105         | Vegetarian - Extra Bacon                                         |
| 8        | 102         | Meatlovers                                                       |
| 9        | 103         | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
| 10       | 104         | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

---

#### 5.	Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

```sql
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
```

|  order_id | customer_id | formatted_ingredients                                                                               |
|----------|-------------|------------------------------------------------------------------------------------------------------|
| 1        | 101         | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami                    |
| 2        | 101         | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami                    |
| 3        | 102         | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami                    |
| 3        | 102         | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                               |
| 4        | 103         | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami                    |
| 4        | 103         | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                               |
| 5        | 104         | Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami                  |
| 6        | 101         | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                               |
| 7        | 105         | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                               |
| 8        | 102         | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami                    |
| 9        | 103         | Meatlovers: 2xBacon, 2xChicken, BBQ Sauce, Beef, Cheese, Mushrooms, Pepperoni, Salami                |
| 10       | 104         | Meatlovers: 2xBacon, 2xCheese, Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |

---

#### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

```sql
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
```

| topping_name | topping_count |
|--------------|---------------|
| Bacon        | 9             |
| Mushrooms    | 6             |
| Cheese       | 6             |
| Chicken      | 6             |
| Pepperoni    | 5             |
| BBQ Sauce    | 5             |
| Salami       | 5             |
| Beef         | 5             |
| Tomatoes     | 2             |
| Tomato Sauce | 2             |
| Onions       | 2             |
| Peppers      | 2             |
| Cheese       | 1             |

---

### D-Pricing and Ratings

#### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

```sql
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
    1, 2
ORDER BY 
    2 DESC;
```

| pizza_name   | total_earnings |
|--------------|----------------|
| Meatlovers   | 108            |
| Vegetarian   | 30             |

- **Meat Lovers**: $108 (9 orders × $12 per pizza)  
- **Vegetarian**: $30 (3 orders × $10 per pizza)  
  
**Total Earnings:** $138

---

#### 2. What if there was an additional $1 charge for any pizza extras?

```sql
WITH delivered_orders AS (
  SELECT co.pizza_id, pn.pizza_name, COUNT(ro.order_id) AS order_count, co.extras
  FROM runner_orders ro
  JOIN customer_orders co ON ro.order_id = co.order_id
  JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
  WHERE ro.cancellation IS NULL
  GROUP BY 1,2,4
),

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
```

| pizza_name   | extra_count | order_count | total_earnings |
|--------------|--------------|-------------|----------------|
| Meatlovers   | 0            | 7           | 84             |
| Vegetarian   | 0            | 2           | 20             |
| Meatlovers   | 2            | 1           | 14             |
| Meatlovers   | 1            | 1           | 13             |
| Vegetarian   | 1            | 1           | 11             |

- **Meat Lovers**:
  - 7 orders with no extras: $84 (7 × $12)
  - 1 order with 2 extras: $14 (1 × ($12 + 2))
  - 1 order with 1 extra: $13 (1 × ($12 + 1))

- **Vegetarian**:
  - 2 orders with no extras: $20 (2 × $10)
  - 1 order with 1 extra: $11 (1 × ($10 + 1))

**Total Earnings:** $142

---

#### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner. How would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5?

```sql
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

SELECT * FROM runner_rating;
```

| order_id | rating | review                                           |
|----------|--------|-------------------------------------------------|
| 1        | 2      | Not the best experience; I expected more...     |
| 2        | 3      | Decent delivery, but I had higher hopes...      |
| 3        | 4      | Took longer than expected, but the pizza...     |
| 4        | 1      | Really disappointed with the service...         |
| 5        | 5      | Fantastic service! The pizza was fresh...       |
| 7        | 4      | Service was okay, but there was a bit...        |
| 8        | 3      | I was pleased with the delivery...              |
| 10       | 5      | Excellent service! The pizza was amazing...     |

- We add a new `runner_rating` table tied to `order_id`.
- Ratings range from 1 (very poor) to 5 (excellent).
- Canceled orders are excluded from the system.

---

#### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?

```sql
SELECT customer_id, ro.order_id, runner_id, rating, order_time, pickup_time,
       ROUND((EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60), 2)  AS order_to_pickup_time,
       duration, 
       ROUND(AVG(distance/duration * 60)::numeric, 2) AS avg_speed,
       COUNT(pizza_id) AS pizza_count
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN runner_rating rr ON ro.order_id = rr.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1,2,3,4,5,6,8;
```

| customer_id | order_id | runner_id | rating | order_time           | pickup_time          | order_to_time_to_pickup_time | duration | avg_speed | pizza_count |
|-------------|----------|-----------|--------|----------------------|----------------------|----------------|-------------------|-----------|------------------|
| 101         | 1        | 1         | 2      | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 10.53          | 32                | 37.50     | 1                  |
| 101         | 2        | 1         | 3      | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 10.03          | 27                | 44.44     | 1                  |
| 102         | 3        | 1         | 4      | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 21.23          | 20                | 40.20     | 2                  |
| 102         | 8        | 2         | 3      | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 20.48          | 15                | 93.60     | 1                  |
| 103         | 4        | 2         | 1      | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 29.28          | 40                | 35.10     | 3                  |
| 104         | 5        | 3         | 5      | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 10.47          | 15                | 40.00     | 1                  |
| 104         | 10       | 1         | 5      | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 15.52          | 10                | 60.00     | 2                  |
| 105         | 7        | 2         | 4      | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 10.27          | 25                | 60.00     | 1                  |

---

#### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

```sql
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
```

| total_pizza_income | total_delivery_payment | remaining_profit |
|--------------------|------------------------|------------------|
| 160                | 43.56                 | 116.44           |

- **Pizza Revenue:** $160  
- **Delivery Costs:** $43.56  
- **Profit:** $116.44

---

## Bonus Question

If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

```sql
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

SELECT * FROM pizza_names
```

| pizza_id   | pizza_name     |
|------------|----------------|
| 1          | Meatlovers     |
| 2          | Vegetarian     |
| 2          | Supreme        |

```sql
INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

SELECT * FROM pizza_recipes
```

| pizza_id   | toppings                                |
|------------|-----------------------------------------|
| 1          | 1, 2, 3, 4, 5, 6, 8, 10                 |
| 2          | 4, 6, 7, 9, 11, 12                      |
| 2          | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12   |

---

