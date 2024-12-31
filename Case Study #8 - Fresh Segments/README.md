# Case Study #8: Fresh Segments

<img src="https://8weeksqlchallenge.com/images/case-study-designs/8.png" alt="Image" width="450" height="470">

## Table of Contents
- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Data Overview](#data-overview)
- [Case Study Questions and Solutions](#case-study-questions-and-solutions)
    - [A-Data Exploration and Cleansing](#a-data-exploration-and-cleansing)
    - [B-Interest  Analysis](#b-interest-analysis)
    - [C-Segment Analysis](#c-segment-analysis)
    - [D-Index Analysis](#d-index-analysis)

For detailed background and the original case description, please visit the [8 Week SQL Challenge]( https://8weeksqlchallenge.com/case-study-8/) website. 

---
## Introduction
Fresh Segments is a digital marketing agency that provides insights into customer behavior by analyzing aggregated metrics related to online ad interactions. The agency works with clients to understand the interests and preferences of their customer base, helping businesses optimize their digital advertising strategies.

---
## Problem Statement
The dataset provides insights into customer behavior by tracking interactions with various online interests over defined periods. Our analysis will focus on identifying key trends in these interactions and offering actionable recommendations based on the aggregated metrics. By examining interest data, we aim to pinpoint how the client’s customers engage with different online interests over time.

---
## Data Overview

For this case, we have two datasets to work with:

<details>
  <summary>Table 1: Interest Metrics</summary>

This table provides a breakdown of customer interactions with specific interests, showing how each interest ranks based on metrics.

| `_month` | `_year` | `month_year` | `interest_id` | `composition` | `index_value` | `ranking` | `percentile_ranking` |
|----------|---------|--------------|---------------|---------------|---------------|-----------|----------------------|
| January  | 2024    | January 2024 | 101           | 15.2%         | 1.12          | 1       | 90th                   |
| February | 2024    | February 2024| 102           | 12.8%         | 1.05          | 2       | 85th                   |
| March    | 2024    | March 2024   | 103           | 9.5%          | 0.98          | 3       | 75th                   |
| April    | 2024    | April 2024   | 104           | 7.3%          | 0.85          | 4       | 65th                   |
| May      | 2024    | May 2024     | 105           | 11.1%         | 1.02          | 5       | 80th                   |

</details>

<details>
  <summary>Table 2: Interest Map</summary>

This mapping table connects each interest_id to its relevant segment information, providing additional context for analysis.
  
| `id` | `interest_name`              | `interest_summary`                                      | `created_at`        | `last_modified`     |
|------|------------------------------|---------------------------------------------------------|---------------------|---------------------|
| 101  | Sports Enthusiasts           | Customers interested in various sports activities.      | 2023-01-15 08:30:00 | 2023-03-01 10:45:00 |
| 102  | Tech Savvy                   | Customers with a strong interest in technology.         | 2023-02-10 09:00:00 | 2023-03-10 11:20:00 |
| 103  | Health & Wellness            | Customers focused on fitness and healthy living.        | 2023-03-05 07:45:00 | 2023-04-02 13:00:00 |
| 104  | Fashion & Style              | Customers interested in the latest fashion trends.      | 2023-04-01 10:00:00 | 2023-05-01 09:30:00 |
| 105  | Home & Garden                | Customers interested in home improvement and gardening. | 2023-05-10 11:15:00 | 2023-06-02 14:20:00 |

</details>

---

## Case Study Questions and Solutions

### A-Data Exploration and Cleansing

#### 1.	Update the interest_metrics table by modifying the month_year column to be a date data type with the start of the month

```sql
ALTER TABLE interest_metrics
ALTER COLUMN month_year TYPE date 
USING TO_DATE(month_year, 'MM-YYYY');
```
---

#### 2.	What is count of records in the interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

```sql
SELECT month_year, COUNT (*) AS record_count
FROM interest_metrics
GROUP BY 1
ORDER BY month_year NULLS FIRST;
```

| month_year  | record_count |
|-------------|--------------|
| NULL        | 1194         |
| 2018-07-01  | 729          |
| 2018-08-01  | 767          |
| 2018-09-01  | 780          |
| 2018-10-01  | 857          |
| 2018-11-01  | 928          |
| 2018-12-01  | 995          |
| 2019-01-01  | 973          |
| 2019-02-01  | 1121         |
| 2019-03-01  | 1136         |
| 2019-04-01  | 1099         |
| 2019-05-01  | 857          |
| 2019-06-01  | 824          |
| 2019-07-01  | 864          |
| 2019-08-01  | 1149         |

---

#### 3.	What do you think we should do with these null values in the interest_metrics

_Since 1,194 records lack month-year information and may not contribute meaningfully to trend analysis, we can remove the rows with null values in the interest_metrics._

```sql
DELETE FROM interest_metrics 
WHERE month_year IS NULL;
```

---

#### 4.	How many interest_id values exist in the interest_metrics table but not in the interest_map table?

```sql
SELECT COUNT(DISTINCT me.interest_id) AS values_not_in_map
FROM interest_metrics me
LEFT JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE ma.id IS NULL;
```

| values_not_in_map |
|-------------------|
| 0                 |


#### What about the other way around?

```sql
SELECT COUNT(DISTINCT ma.id) AS values_not_in_metrics
FROM interest_map ma
LEFT JOIN interest_metrics me ON ma.id = me.interest_id::integer
WHERE me.interest_id IS NULL;
```

| values_not_in_metrics |
|-----------------------|
| 7                     |


There are no interest_id values in the interest_metrics table that are missing in the interest_map table. We identified 7 interest_id values that are present in the interest_map table but have no corresponding entries in the interest_metrics table. 

---

#### 5.	Summarise the id values in the interest_map by its total record count in this table

```sql
SELECT COUNT (id) AS total_records
FROM interest_map;
```
| total_records |
|---------------|
| 1209          |

The total record count in the interest_map table is 1,209.

---

#### 6.	What sort of table join should we perform for our analysis and why? 
Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from interest_metrics and all columns from interest_map except from the id column.

```sql
SELECT me.*, ma.interest_name, 
       ma.interest_summary, 
	   ma.created_at,
	   ma.last_modified
FROM interest_metrics me
INNER JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE interest_id = '21246';
```

| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking | interest_name               | interest_summary                                        | created_at          | last_modified       |
|--------|-------|------------|-------------|-------------|-------------|---------|---------------------|-----------------------------|---------------------------------------------------------|---------------------|---------------------|
| 4      | 2019  | 2019-04-01 | 21246       | 1.58        | 0.63        | 1092    | 0.64                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 3      | 2019  | 2019-03-01 | 21246       | 1.75        | 0.67        | 1123    | 1.14                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 2      | 2019  | 2019-02-01 | 21246       | 1.84        | 0.68        | 1109    | 1.07                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 1      | 2019  | 2019-01-01 | 21246       | 2.05        | 0.76        | 954     | 1.95                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 12     | 2018  | 2018-12-01 | 21246       | 1.97        | 0.70        | 983     | 1.21                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 11     | 2018  | 2018-11-01 | 21246       | 2.25        | 0.78        | 908     | 2.16                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 10     | 2018  | 2018-10-01 | 21246       | 1.74        | 0.58        | 855     | 0.23                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 9      | 2018  | 2018-09-01 | 21246       | 2.06        | 0.61        | 774     | 0.77                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 8      | 2018  | 2018-08-01 | 21246       | 2.13        | 0.59        | 765     | 0.26                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 7      | 2018  | 2018-07-01 | 21246       | 2.26        | 0.65        | 722     | 0.96                | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources.  | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |

We performed an inner join between the interest_metrics and interest_map tables, allowing us to connect interest_id values across both tables. 

---

#### 7.	Are there any records in your joined table where the month_year value is before the created_at value from the interest_map table?  Do you think these values are valid and why?

```sql
SELECT COUNT (*)
FROM interest_metrics me
INNER JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE month_year < created_at
```

| count |
|-------|
| 188   |

```sql
SELECT ma.*, me.month_year
FROM interest_metrics me
INNER JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE month_year < created_at
```
- Sample Output for 1–20 rows:

 | id     | interest_name              | interest_summary                                                                                                      | created_at           | last_modified         | month_year  |
|--------|----------------------------|-----------------------------------------------------------------------------------------------------------------------|----------------------|-----------------------|-------------|
| 32704  | Major Airline Customers     | People visiting sites for major airline brands to plan and view travel itinerary.                                      | 2018-07-06 14:35:04  | 2018-07-06 14:35:04   | 2018-07-01  |
| 33191  | Online Shoppers             | People who spend money online                                                                                          | 2018-07-17 10:40:03  | 2018-07-17 10:46:58   | 2018-07-01  |
| 32703  | School Supply Shoppers      | Consumers shopping for classroom supplies for K-12 students.                                                           | 2018-07-06 14:35:04  | 2018-07-06 14:35:04   | 2018-07-01  |
| 32701  | Womens Equality Advocates   | People visiting sites advocating for women's equal rights.                                                             | 2018-07-06 14:35:03  | 2018-07-06 14:35:03   | 2018-07-01  |
| 32705  | Certified Events Professionals | Professionals reading industry news and researching products and services for event management.                        | 2018-07-06 14:35:04  | 2018-07-06 14:35:04   | 2018-07-01  |
| 32702  | Romantics                   | People reading about romance and researching ideas for planning romantic moments.                                      | 2018-07-06 14:35:04  | 2018-07-06 14:35:04   | 2018-07-01  |
| 34465  | Toronto Blue Jays Fans      | People reading news about the Toronto Blue Jays and watching games. These consumers are more likely to spend money on team gear. | 2018-08-15 18:00:04  | 2018-08-15 18:00:04   | 2018-08-01  |
| 34463  | Boston Red Sox Fans         | People reading news about the Boston Red Sox and watching games. These consumers are more likely to spend money on team gear. | 2018-08-15 18:00:04  | 2018-08-15 18:00:04   | 2018-08-01  |
| 34464  | New York Yankees Fans       | People reading news about the New York Yankees and watching games. These consumers are more likely to spend money on team gear. | 2018-08-15 18:00:04  | 2018-08-15 18:00:04   | 2018-08-01  |
| 33959  | Boston Bruins Fans          | People reading news about the Boston Bruins and watching games. These consumers are more likely to spend money on team gear. | 2018-08-02 16:05:03  | 2018-08-02 16:05:03   | 2018-08-01  |
| 34469  | Jazz Festival Enthusiasts   | People researching and planning to attend jazz music festivals.                                                         | 2018-08-15 18:00:04  | 2018-08-15 18:00:04   | 2018-08-01  |
| 33971  | Sun Protection Shoppers     | Consumers comparing brands and shopping for sun protection products.                                                   | 2018-08-02 16:05:05  | 2018-08-02 16:05:05   | 2018-08-01  |
| 34462  | Baltimore Orioles Fans      | People reading news about the Baltimore Orioles and watching games. These consumers are more likely to spend money on team gear. | 2018-08-15 18:00:03  | 2018-08-15 18:00:03   | 2018-08-01  |
| 34082  | New England Patriots Fans   | People reading news about the New England Patriots and watching games. These consumers are more likely to spend money on team gear. | 2018-08-07 17:10:04  | 2018-08-07 17:10:04   | 2018-08-01  |
| 34574  | F1 Racing Enthusiasts       | People visiting websites and reading articles about F1 racing.                                                          | 2018-08-17 10:50:03  | 2018-08-17 10:50:03   | 2018-08-01  |
| 33960  | Chicago Blackhawks Fans     | People reading news about the Chicago Blackhawks and watching games. These consumers are more likely to spend money on team gear. | 2018-08-02 16:05:03  | 2018-08-02 16:05:03   | 2018-08-01  |
| 33967  | New York Rangers Fans       | People reading news about the New York Rangers and watching games. These consumers are more likely to spend money on team gear. | 2018-08-02 16:05:04  | 2018-08-02 16:05:04   | 2018-08-01  |
| 34461  | Jazz Music Fans             | People reading about jazz music and musicians.                                                                         | 2018-08-15 18:00:03  | 2018-08-15 18:00:03   | 2018-08-01  |
| 34466  | Detroit Tigers Fans         | People reading news about the Detroit Tigers and watching games. These consumers are more likely to spend money on team gear. | 2018-08-15 18:00:04  | 2018-08-15 18:00:04   | 2018-08-01  |

It can be observed that the data in the output corresponds to the same month. This discrepancy has most likely occurred because we adjusted the month_year column to reflect the first day of the month, which explains the difference. Therefore, this is valid.

---

### B-Interest Analysis

#### 1.	Which interests have been present in all month_year dates in our dataset?

_Total number of distinct month_year values and distinct interest_id values in the interest_metrics table._

```sql
SELECT 
  COUNT(DISTINCT month_year) AS total_months,
  COUNT(DISTINCT interest_id) AS unique_interest
FROM interest_metrics;
```

| total_months | unique_interest |
|--------------|-----------------|
| 14           | 1202            |

```sql
WITH interests AS (
SELECT 
  interest_id, 
  COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
GROUP BY interest_id
)

SELECT 
  total_months,
  COUNT(DISTINCT i.interest_id) interest_count
FROM interests i
WHERE total_months = 14
GROUP BY 1
ORDER BY 2 DESC;
```

| total_months | unique_interest |
|--------------|-----------------|
| 14           | 480             |

There are 14 unique month_year dates and 1202 unique interests in total. Out of these, 480 interests have been present in every one of the 14 months

---

#### 2.	Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

```sql
WITH month_cte AS (
  SELECT
    DISTINCT interest_id,
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  GROUP BY interest_id
),
interest_cte AS (
  SELECT 
    total_months,
    COUNT(DISTINCT interest_id) AS interest_count
  FROM month_cte
  GROUP BY total_months
), cumulative_cte AS (
SELECT 
  total_months,
  interest_count, 
  ROUND(SUM(interest_count)OVER(ORDER BY total_months DESC) *100.0/(SELECT SUM(interest_count) FROM   interest_cte),2) AS cumulative_percent
FROM interest_cte
)
SELECT *
FROM cumulative_cte
WHERE cumulative_percent > 90;
```

  | total_months | interest_count | cumulative_percent |
  |--------------|----------------|--------------------|
  | 6            | 33             | 90.85              |
  | 5            | 38             | 94.01              |
  | 4            | 32             | 96.67              |
  | 3            | 15             | 97.92              |
  | 2            | 12             | 98.92              |
  | 1            | 13             | 100.00             |

The cumulative percentage exceeds 90% at the 6 months level.

---

#### 3.	If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

```sql
WITH total_month_cte AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) < 6
)
SELECT COUNT(interest_id) AS interest_record_to_remove
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM total_month_cte);
```

| interest_record_to_remove |
|---------------------------|
| 400                       |

A total of 400 records would be removed if we eliminate all interest_id values with fewer than 6 months of data, as identified in the previous analysis. 

---

#### 4.	Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

```sql
WITH month_cte AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  GROUP BY interest_id
),
removed_data AS (
  SELECT 
    me.month_year,
    COUNT(DISTINCT CASE WHEN mc.total_months >= 6 THEN mc.interest_id END) AS remaining_interest,
    COUNT(DISTINCT CASE WHEN mc.total_months < 6 THEN mc.interest_id END) AS removed_interest
  FROM month_cte mc
  JOIN interest_metrics me ON mc.interest_id = me.interest_id
  GROUP BY me.month_year
)
SELECT 
  month_year,
  remaining_interest,
  removed_interest,
  ROUND((removed_interest * 100.0) / (remaining_interest + removed_interest), 2) AS removed_prcnt
FROM removed_data
ORDER BY month_year;
```

  | month_year  | remaining_interest | removed_interest | removed_prcnt |
  |-------------|--------------------|------------------|---------------|
  | 2018-07-01  | 709                | 20               | 2.74          |
  | 2018-08-01  | 752                | 15               | 1.96          |
  | 2018-09-01  | 774                | 6                | 0.77          |
  | 2018-10-01  | 853                | 4                | 0.47          |
  | 2018-11-01  | 925                | 3                | 0.32          |
  | 2018-12-01  | 986                | 9                | 0.90          |
  | 2019-01-01  | 966                | 7                | 0.72          |
  | 2019-02-01  | 1072               | 49               | 4.37          |
  | 2019-03-01  | 1078               | 58               | 5.11          |
  | 2019-04-01  | 1035               | 64               | 5.82          |
  | 2019-05-01  | 827                | 30               | 3.50          |
  | 2019-06-01  | 804                | 20               | 2.43          |
  | 2019-07-01  | 836                | 28               | 3.24          |
  | 2019-08-01  | 1062               | 87               | 7.57          |

By removing interests present for fewer than 6 months, we eliminate a relatively small portion of the total data (ranging from 0.32% to 7.57% of interests depending on the month). This suggests that the removal does not significantly impact the overall dataset. 

---

#### 5.	After removing these interests - how many unique interests are there for each month?

```sql
WITH total_month_cte AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
  FROM interest_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) < 6
)
SELECT month_year,
       COUNT(DISTINCT interest_id) AS remaining_interests
FROM interest_metrics
WHERE interest_id NOT IN (SELECT interest_id FROM total_month_cte)
GROUP BY 1;
```

  | month_year  | remaining_interests |
  |-------------|---------------------|
  | 2018-07-01  | 709                 |
  | 2018-08-01  | 752                 |
  | 2018-09-01  | 774                 |
  | 2018-10-01  | 853                 |
  | 2018-11-01  | 925                 |
  | 2018-12-01  | 986                 |
  | 2019-01-01  | 966                 |
  | 2019-02-01  | 1072                |
  | 2019-03-01  | 1078                |
  | 2019-04-01  | 1035                |
  | 2019-05-01  | 827                 |
  | 2019-06-01  | 804                 |
  | 2019-07-01  | 836                 |
  | 2019-08-01  | 1062                |

After removing interest segments with fewer than 6 months of data, the number of unique interests per month remains relatively consistent, with values ranging from 709 to 1078. 

--- 

### C-Segment Analysis

#### 1.	Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year

•	_Created  filtered table_

```sql
CREATE TABLE filtered_data AS
SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
GROUP BY interest_id
HAVING COUNT(DISTINCT month_year) >= 6;
```

•	_TOP 10_ 

```sql
SELECT month_year,
       interest_id,
	   interest_name, 
       MAX(composition) AS max_composition
FROM interest_metrics me
JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE interest_id IN (SELECT interest_id FROM filtered_data)
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 10;
```

  | month_year  | interest_id | interest_name                     | max_composition |
  |-------------|-------------|-----------------------------------|-----------------|
  | 2018-12-01  | 21057       | Work Comes First Travelers        | 21.2            |
  | 2018-10-01  | 21057       | Work Comes First Travelers        | 20.28           |
  | 2018-11-01  | 21057       | Work Comes First Travelers        | 19.45           |
  | 2019-01-01  | 21057       | Work Comes First Travelers        | 18.99           |
  | 2018-07-01  | 6284        | Gym Equipment Owners              | 18.82           |
  | 2019-02-01  | 21057       | Work Comes First Travelers        | 18.39           |
  | 2018-09-01  | 21057       | Work Comes First Travelers        | 18.18           |
  | 2018-07-01  | 39          | Furniture Shoppers                | 17.44           |
  | 2018-07-01  | 77          | Luxury Retail Shoppers            | 17.19           |
  | 2018-10-01  | 12133       | Luxury Boutique Hotel Researchers | 15.15           |

•	_BOTTOM 10_

```sql
SELECT month_year,
       interest_id,
	   interest_name, 
       MAX(composition) AS max_composition
FROM interest_metrics me
JOIN interest_map ma ON me.interest_id::integer = ma.id
WHERE interest_id IN (SELECT interest_id FROM filtered_data)
GROUP BY 1,2,3
ORDER BY 4 
LIMIT 10;
```

  | month_year  | interest_id | interest_name               | max_composition |
  |-------------|-------------|-----------------------------|-----------------|
  | 2019-05-01  | 45524       | Mowing Equipment Shoppers   | 1.51            |
  | 2019-06-01  | 34083       | New York Giants Fans        | 1.52            |
  | 2019-05-01  | 4918        | Gastrointestinal Researchers | 1.52           |
  | 2019-04-01  | 44449       | United Nations Donors       | 1.52            |
  | 2019-05-01  | 20768       | Beer Aficionados            | 1.52            |
  | 2019-06-01  | 35742       | Disney Fans                 | 1.52            |
  | 2019-05-01  | 39336       | Philadelphia 76ers Fans     | 1.52            |
  | 2019-05-01  | 36877       | Crochet Enthusiasts         | 1.53            |
  | 2019-06-01  | 6314        | Online Directory Searchers  | 1.53            |
  | 2019-05-01  | 6127        | LED Lighting Shoppers       | 1.53            |
  

The top 10 interests with the highest composition values are dominated by "Work Comes First Travelers," which has the largest values across multiple months. On the other hand, the bottom 10 interests have much smaller composition values, generally ranging between 1.5 and 1.53.

---

#### 2.	Which 5 interests had the lowest average ranking value?

```sql
SELECT 
       interest_name,
       ROUND(AVG(ranking),2) AS avg_ranking
FROM interest_map ma
JOIN interest_metrics me ON me.interest_id::integer = ma.id
WHERE interest_id IN (SELECT interest_id FROM filtered_data)
GROUP BY 1
ORDER BY 2 ASC
LIMIT 6;
```

  | interest_name                   | avg_ranking |
  |---------------------------------|-------------|
  | Winter Apparel Shoppers         | 1.00        |
  | Fitness Activity Tracker Users  | 4.11        |
  | Mens Shoe Shoppers              | 5.93        |
  | Shoe Shoppers                   | 9.36        |
  | Preppy Clothing Shoppers        | 11.86       |
  | Luxury Retail Researchers       | 11.86       |


_Note: We included six rows since "Preppy Clothing Shoppers" and "Luxury Retail Researchers" shared the same average ranking value._

The interests with the lowest average ranking values include "Winter Apparel Shoppers," with a significantly low ranking of 1, followed by "Fitness Activity Tracker Users" at 4.11.

---

#### 3.	Which 5 interests had the largest standard deviation in their percentile_ranking value?

```sql
SELECT interest_id,
    interest_name,
    ROUND(STDDEV(percentile_ranking::integer),2) AS std_ranking_prcnt
FROM interest_map ma
JOIN interest_metrics me ON me.interest_id::integer = ma.id
WHERE interest_id IN (SELECT interest_id FROM filtered_data)
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;
``` 
  | interest_id | interest_name                             | std_ranking_prcnt |
  |-------------|-------------------------------------------|--------------------|
  | 23          | Techies                                   | 30.30              |
  | 20764       | Entertainment Industry Decision Makers    | 28.88              |
  | 38992       | Oregon Trip Planners                      | 28.23              |
  | 43546       | Personalized Gift Shoppers                | 26.29              |
  | 10839       | Tampa and St Petersburg Trip Planners     | 25.60              |

The "Techies" category exhibited the highest variability in percentile ranking, indicating significant fluctuations in its ranking performance over time. Other interests like "Entertainment Industry Decision Makers" and "Oregon Trip Planners" also showed high volatility.

---

#### 4.	For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

```sql
WITH top_5_interest AS (
    SELECT 
        me.interest_id,
        ma.interest_name,
	    ma.interest_summary, 
        ROUND(STDDEV(me.percentile_ranking::integer), 2) AS std_ranking_prcnt
    FROM interest_map ma
    JOIN interest_metrics me ON me.interest_id::integer = ma.id
    WHERE me.interest_id IN (SELECT interest_id FROM filtered_data)
    GROUP BY me.interest_id, ma.interest_name, ma.interest_summary
    ORDER BY std_ranking_prcnt DESC
    LIMIT 5
),
percentile_rankings AS (
    SELECT 
        t.interest_id,
        t.interest_name,
	    t.interest_summary,
        MIN(me.percentile_ranking) AS min_ranking,
        MAX(me.percentile_ranking) AS max_ranking,
        (SELECT month_year 
         FROM interest_metrics 
         WHERE interest_id = t.interest_id 
         AND percentile_ranking = MIN(me.percentile_ranking)
         ) AS min_year,
        (SELECT month_year 
         FROM interest_metrics 
         WHERE interest_id = t.interest_id 
         AND percentile_ranking = MAX(me.percentile_ranking)
         ) AS max_year
    FROM interest_metrics me
    JOIN top_5_interest t ON me.interest_id = t.interest_id
    GROUP BY t.interest_id, t.interest_name, t.interest_summary
)
SELECT 
    interest_name,
	interest_summary,
    min_year,
    min_ranking,
    max_year,
    max_ranking
FROM percentile_rankings
ORDER BY max_ranking DESC;
```

  | interest_name                             | interest_summary                                                                                   | min_year    | min_ranking | max_year    | max_ranking |
  |-------------------------------------------|----------------------------------------------------------------------------------------------------|-------------|-------------|-------------|-------------|
  | Techies                                   | Readers of tech news and gadget reviews.                                                           | 2019-08-01  | 7.92        | 2018-07-01  | 86.69       |
  | Entertainment Industry Decision Makers    | Professionals reading industry news and researching trends in the entertainment industry.          | 2019-08-01  | 11.23       | 2018-07-01  | 86.15       |
  | Oregon Trip Planners                      | People researching attractions and accommodations in Oregon. These consumers are more likely to spend money on travel and local attractions. | 2019-07-01  | 2.2         | 2018-11-01  | 82.44       |
  | Tampa and St Petersburg Trip Planners     | People researching attractions and accommodations in Tampa and St Petersburg. These consumers are more likely to spend money on flights, hotels, and local attractions. | 2019-03-01  | 4.84        | 2018-07-01  | 75.03       |
  | Personalized Gift Shoppers                | Consumers shopping for gifts that can be personalized.                                             | 2019-06-01  | 5.7         | 2019-03-01  | 73.15       |

The analyzed interests exhibited some fluctuations in their percentile rankings, with peaks often occurring earlier followed by subsequent declines. For instance, "Techies" appears to have peaked in July 2018, reaching a high of 86.69, only to decline significantly by August 2019 to just 7.92. Similarly, "Entertainment Industry Decision Makers" seem to show a pattern of peak rankings earlier, followed by a decline, which might suggest a shift in interest or engagement over time.
It could also be that seasonality plays a role, especially for travel-related segments like "Oregon Trip Planners" and "Tampa and St Petersburg Trip Planners." "Personalized Gift Shoppers" might also follow a seasonal pattern, with spikes around holidays or special occasions, followed by a drop afterward.

---

#### 5.	How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

Customers in this segment show a broad range of interests, with a common focus on personalization, experiences, and innovation. "Techies" and "Entertainment Industry Decision Makers" are drawn to advanced technology and media solutions. "Oregon Trip Planners" and "Tampa and St Petersburg Trip Planners" value curated travel experiences, while "Personalized Gift Shoppers" appreciate unique, customized items, often for special occasions or personal preferences.

This segment is likely to be drawn to products and services that blend innovation with a personal touch. Offering the latest technology, premium entertainment tools, and unique travel experiences would resonate well. Customized items, like personalized gifts or apparel, will appeal to their desire for something special. It's best to steer clear of generic products or overly technical options that might not suit everyone. Also, seasonal promotions should be thoughtfully timed to match their interests and trends.

--- 

### D-Index Analysis

The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

####  1.	What is the top 10 interests by the average composition for each month?

- Sample Output
  
```sql
 | month_year  | interest_name                | avg_composition |
  |-------------|------------------------------|-----------------|
  | 2018-07-01  | Las Vegas Trip Planners      | 7.36            |
  | 2018-07-01  | Gym Equipment Owners         | 6.94            |
  | 2018-07-01  | Cosmetics and Beauty Shoppers| 6.78            |
  | 2018-07-01  | Luxury Retail Shoppers       | 6.61            |
  | 2018-07-01  | Furniture Shoppers           | 6.51            |
  | 2018-07-01  | Asian Food Enthusiasts       | 6.10            |
  | 2018-07-01  | Recently Retired Individuals | 5.72            |
  | 2018-07-01  | Family Adventures Travelers  | 4.85            |
  | 2018-07-01  | Work Comes First Travelers   | 4.80            |
  | 2018-07-01  | HDTV Researchers             | 4.71            |
```

_Note: The data reflects a total of 14 months worth of records; however, only July 2018 data is provided for demonstration purposes._

---

#### 2.	For all of these top 10 interests - which interest appears the most often?

```sql
WITH monthly_composition AS (
    SELECT 
	    month_year,
        interest_name,
        ROUND((composition / index_value)::numeric, 2) AS avg_composition
    FROM interest_map ma
    JOIN interest_metrics me ON me.interest_id::integer = ma.id
    WHERE me.interest_id IN (SELECT interest_id FROM filtered_data)
), 
ranked_interests AS (
    SELECT 
        interest_name,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS ranking
    FROM monthly_composition
)
SELECT 
    interest_name,
    COUNT(*) AS repeated_interests
FROM ranked_interests
WHERE ranking <= 10  -- Top 10 based on the ranking
GROUP BY interest_name
HAVING COUNT(*) = (
    SELECT MAX(count) 
    FROM (
        SELECT COUNT(*) AS count
        FROM ranked_interests
        WHERE ranking <= 10
        GROUP BY interest_name
    ) AS subquery
)
ORDER BY repeated_interests DESC;
```

  | interest_name               | repeated_interests |
  |-----------------------------|--------------------|
  | Solar Energy Researchers    | 10                 |
  | Alabama Trip Planners       | 10                 |
  | Luxury Bedding Shoppers     | 10                 |

The analysis reveals that "Solar Energy Researchers," "Alabama Trip Planners," and "Luxury Bedding Shoppers" each appeared 10 times within the top 10 rankings across months.

---

#### 3.	What is the average of the average composition for the top 10 interests for each month?

```sql
WITH monthly_composition AS(
SELECT 
    month_year,
    interest_name, 
    ROUND((composition / index_value)::numeric, 2) AS avg_composition
FROM interest_map ma
JOIN interest_metrics me ON me.interest_id::integer = ma.id
WHERE me.interest_id IN (SELECT interest_id FROM filtered_data)) ,
ranked_interests AS (
    SELECT 
        month_year,
        interest_name,
        avg_composition,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS ranking
    FROM monthly_composition)
	SELECT month_year,
        ROUND(AVG(avg_composition),2) AS avg_avg_composition
		FROM ranked_interests
	WHERE ranking < 11
	GROUP BY 1
	ORDER BY 1,2;
```

  | month_year  | avg_avg_composition |
  |-------------|---------------------|
  | 2018-07-01  | 6.04                |
  | 2018-08-01  | 5.95                |
  | 2018-09-01  | 6.90                |
  | 2018-10-01  | 7.07                |
  | 2018-11-01  | 6.62                |
  | 2018-12-01  | 6.65                |
  | 2019-01-01  | 6.32                |
  | 2019-02-01  | 6.58                |
  | 2019-03-01  | 6.12                |
  | 2019-04-01  | 5.75                |
  | 2019-05-01  | 3.54                |
  | 2019-06-01  | 2.43                |
  | 2019-07-01  | 2.77                |
  | 2019-08-01  | 2.63                |

We can observe a declining trend starting in mid-2019, with significant decreases in May through August.

---

#### 4.	What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.

 | month_year  | interest_name               | max_index_composition | 3_month_moving_avg | 1_month_ago                                | 2_month_ago                                |
  |-------------|-----------------------------|-----------------------|--------------------|--------------------------------------------|--------------------------------------------|
  | 2018-09-01  | Work Comes First Travelers  | 8.26                  | 7.61               | Las Vegas Trip Planners: 7.21              | Las Vegas Trip Planners: 7.36              |
  | 2018-10-01  | Work Comes First Travelers  | 9.14                  | 8.20               | Work Comes First Travelers: 8.26           | Las Vegas Trip Planners: 7.21              |
  | 2018-11-01  | Work Comes First Travelers  | 8.28                  | 8.56               | Work Comes First Travelers: 9.14           | Work Comes First Travelers: 8.26           |
  | 2018-12-01  | Work Comes First Travelers  | 8.31                  | 8.58               | Work Comes First Travelers: 8.28           | Work Comes First Travelers: 9.14           |
  | 2019-01-01  | Work Comes First Travelers  | 7.66                  | 8.08               | Work Comes First Travelers: 8.31           | Work Comes First Travelers: 8.28           |
  | 2019-02-01  | Work Comes First Travelers  | 7.66                  | 7.88               | Work Comes First Travelers: 7.66           | Work Comes First Travelers: 8.31           |
  | 2019-03-01  | Alabama Trip Planners       | 6.54                  | 7.29               | Work Comes First Travelers: 7.66           | Work Comes First Travelers: 7.66           |
  | 2019-04-01  | Solar Energy Researchers    | 6.28                  | 6.83               | Alabama Trip Planners: 6.54                | Work Comes First Travelers: 7.66           |
  | 2019-05-01  | Readers of Honduran Content | 4.41                  | 5.74               | Solar Energy Researchers: 6.28             | Alabama Trip Planners: 6.54                |
  | 2019-06-01  | Las Vegas Trip Planners     | 2.77                  | 4.49               | Readers of Honduran Content: 4.41          | Solar Energy Researchers: 6.28             |
  | 2019-07-01  | Las Vegas Trip Planners     | 2.82                  | 3.33               | Las Vegas Trip Planners: 2.77              | Readers of Honduran Content: 4.41          |
  | 2019-08-01  | Cosmetics and Beauty Shoppers| 2.73                  | 2.77               | Las Vegas Trip Planners: 2.82              | Las Vegas Trip Planners: 2.77              |

```sql
WITH avg_compositions AS (
  SELECT 
    month_year,
    interest_id,
    ROUND((composition / index_value)::numeric, 2) AS avg_comp,
    ROUND(MAX(composition / index_value) OVER(PARTITION BY month_year)::numeric, 2) AS max_avg_comp
  FROM interest_metrics
  WHERE month_year IS NOT NULL
),
max_avg_compositions AS (
  SELECT *
  FROM avg_compositions
  WHERE avg_comp = max_avg_comp
),
moving_avg_compositions AS (
  SELECT 
    mac.month_year,
    im.interest_name,
    mac.max_avg_comp AS max_index_composition,
    ROUND(AVG(mac.max_avg_comp) 
          OVER(ORDER BY mac.month_year 
               ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)::numeric, 2) AS "3_month_moving_avg",
    LAG(im.interest_name) OVER (ORDER BY mac.month_year) || ': ' ||
    CAST(LAG(mac.max_avg_comp) OVER (ORDER BY mac.month_year) AS VARCHAR(4)) AS "1_month_ago",
    LAG(im.interest_name, 2) OVER (ORDER BY mac.month_year) || ': ' ||
    CAST(LAG(mac.max_avg_comp, 2) OVER (ORDER BY mac.month_year) AS VARCHAR(4)) AS "2_month_ago"
  FROM max_avg_compositions mac 
  JOIN interest_map im 
    ON CAST(mac.interest_id AS INTEGER) = im.id
)
SELECT *
FROM moving_avg_compositions
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';
```

As shown in the table, Work Comes First Travelers consistently holds high composition values, but the moving average fluctuates, particularly in the later months. This is due to a drop in composition values from segments like Las Vegas Trip Planners and other interests in those months.

---

#### 5.	Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

The changes in the max average composition could be tied to seasonal shifts or changes in travel interest. For instance, the spike in "Las Vegas Trip Planners" during certain months might reflect increased travel demand, while the drop in others could signal a slower period. If these shifts happen too often, it could indicate that the business model relies too heavily on seasonal trends, which might make it harder to maintain steady growth over time.

---





