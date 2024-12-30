# Case Study #5: Data Mart 

<img src="https://8weeksqlchallenge.com/images/case-study-designs/5.png" alt="Image" width="450" height="470">

## Table of Contents
- [Introduction](#introduction)
- [Problem Statement](#problem-statement)
- [Data Overview](#data-overview)
- [Case Study Questions and Solutions](#case-study-questions-and-solutions)
    - [A-Data Cleansing Steps](#a-data-cleansing-steps)
    - [B-Data Exploration](#b-data-exploration)
    - [C-Before and After Analysis](#c-before-and-after-analysis)
    - [D-Bonus Question](#d-bonus-question)

For the original case study, visit the [8 Week SQL Challenge website]( https://8weeksqlchallenge.com/case-study-5/). 

---
## Introduction
Data Mart is a modern enterprise specializing in fresh produce, utilizing an international, multi-region approach to serve a diverse customer base. Leveraging both physical retail and a Shopify-powered online store, the company delivers quality products while adapting to changing consumer demands.

In mid-2020, Data Mart introduced sustainable packaging across its entire supply chain. Following this transition, an evaluation was initiated to understand its impact on sales performance and identify areas for improvement.

---
## Problem Statement
The primary aim of this case study is to analyze the sales data to uncover how the transition to sustainable packaging influenced different aspects of Data Mart’s operations. The analysis addresses the following key questions:
-	What measurable effects did the packaging update have on sales performance?
-	How were different platforms, regions, customer segments, and types affected?
-	What strategies can be developed to minimize potential sales disruptions during future sustainability efforts?

---

## Data Overview

The dataset for this case study is structured in a single table **weekly_sales** . This table includes weekly aggregated sales data, with a focus on multiple regions and sales channels. It also contains customer demographic details, including age and other relevant factors. The key metrics in the dataset are the number of transactions and total sales revenue.

| Column Name      | Description                                                   |
|------------------|---------------------------------------------------------------|
| `week_date`      | Start date of the sales week.                                 |
| `region`         | Geographic region of the sales (e.g., Asia, Europe).          |
| `platform`       | Sales platform (Retail or Shopify).                           |
| `segment`        | Customer segmentation category (e.g., C1, C2, etc.).          |
| `customer_type`  | Type of customer (New, Existing, Guest).                      |
| `transactions`   | Count of unique purchases in the given week.                  |
| `sales`          | Total sales revenue in dollars for the week.                  |

### ERD Diagram

![alt text](https://github.com/beyzabasarir/8-Week-SQL-Challenge/blob/main/Case%20Study%20%235-%20Data%20Mart/ERD.png)

---

## Case Study Questions and Solutions

### A-Data Cleansing Steps

#### In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

-	Convert the week_date to a DATE format
-	Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-	Add a month_number with the calendar month for each week_date value as the 3rd column
-	Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-	Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

| Segment | Age Band      |
|---------|---------------|
| 1       | Young Adults  |
| 2       | Middle Aged   |
| 3 or 4   | Retirees      |

- Add a new demographic column using the following mapping for the first letter in the segment values:
  
| Segment | Demographic |
|---------|-------------|
| C       | Couples     |
| F       | Families    |

- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-	Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

```sql
CREATE TABLE clean_weekly_sales (
week_date date,
week_number int,
month_number int,
calendar_year int,
region varchar(50),
platform varchar(50),
segment varchar(50),
age_band varchar(50),
demographic varchar(50),
customer_type varchar(50),
transactions int,
sales int,
avg_transaction float
);


INSERT INTO clean_weekly_sales (
    week_date,
    week_number,
    month_number,
    calendar_year,
    region,
    platform,
    segment,
    age_band,
    demographic,
	customer_type,
    transactions,
    sales,
    avg_transaction
)
WITH new_columns AS (
    SELECT 
        TO_DATE(week_date, 'DD-MM-YY') AS week_date,
        DATE_PART('Week', TO_DATE(week_date, 'DD-MM-YY')) AS week_number,
        EXTRACT(MONTH FROM TO_DATE(week_date, 'DD-MM-YY')) AS month_number,
        EXTRACT(YEAR FROM TO_DATE(week_date, 'DD-MM-YY')) AS calendar_year,
        region,
        platform,
        CASE 
	        WHEN segment = 'null' THEN 'Unknown'
	        ELSE segment END AS segment,
        CASE 
            WHEN segment LIKE '%1' THEN 'Young Adults'   
            WHEN segment LIKE '%2' THEN 'Middle Aged'   
            WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'   
            ELSE 'Unknown' 
        END AS age_band, 
        CASE 
            WHEN segment LIKE 'C%' THEN 'Couples'   
            WHEN segment LIKE 'F%' THEN 'Families'   
            ELSE 'Unknown' 
        END AS demographic,
	    customer_type,
        transactions,
        sales,
        ROUND((sales / NULLIF(transactions, 0)), 2) AS avg_transaction
    FROM weekly_sales
)
SELECT * FROM new_columns;


SELECT * FROM clean_weekly_sales;

```
##### Sample Output for 1–10 rows:

| week_date  | week_number | month_number | calendar_year | region | platform | segment | age_band     | demographic | customer_type | transactions | sales    | avg_transaction |
|------------|-------------|--------------|---------------|--------|----------|---------|--------------|-------------|---------------|--------------|----------|-----------------|
| 2020-08-31 | 36          | 8            | 2020          | ASIA   | Retail   | C3      | Retirees     | Couples     | New           | 120631       | 3656163  | 30              |
| 2020-08-31 | 36          | 8            | 2020          | ASIA   | Retail   | F1      | Young Adults | Families    | New           | 31574        | 996575   | 31              |
| 2020-08-31 | 36          | 8            | 2020          | USA    | Retail   | Unknown | Unknown      | Unknown     | Guest         | 529151       | 16509610 | 31              |
| 2020-08-31 | 36          | 8            | 2020          | EUROPE | Retail   | C1      | Young Adults | Couples     | New           | 4517         | 141942   | 31              |
| 2020-08-31 | 36          | 8            | 2020          | AFRICA | Retail   | C2      | Middle Aged  | Couples     | New           | 58046        | 1758388  | 30              |
| 2020-08-31 | 36          | 8            | 2020          | CANADA | Shopify  | F2      | Middle Aged  | Families    | Existing      | 1336         | 243878   | 182             |
| 2020-08-31 | 36          | 8            | 2020          | AFRICA | Shopify  | F3      | Retirees     | Families    | Existing      | 2514         | 519502   | 206             |
| 2020-08-31 | 36          | 8            | 2020          | ASIA   | Shopify  | F1      | Young Adults | Families    | Existing      | 2158         | 371417   | 172             |
| 2020-08-31 | 36          | 8            | 2020          | AFRICA | Shopify  | F2      | Middle Aged  | Families    | New           | 318          | 49557    | 155             |
| 2020-08-31 | 36          | 8            | 2020          | AFRICA | Retail   | C3      | Retirees     | Couples     | New           | 111032       | 3888162  | 35              |

---

### B-Data Exploration

#### 1. What day of the week is used for each week_date value?

```sql
SELECT DISTINCT
       TO_CHAR(week_date, 'Day') AS day_of_week
FROM clean_weekly_sales;
```

| day_of_week    |
|----------------|
|Monday          |

The data uses Mondays as the starting day for each week.

---

#### 2. What range of week numbers are missing from the dataset?

```sql
WITH complete_week AS (
    SELECT generate_series(1, 52) AS complete_weeks
),
existing_week AS (
    SELECT DISTINCT week_number AS existing_weeks
    FROM clean_weekly_sales
)
SELECT complete_weeks AS missing_weeks
FROM complete_week cw
LEFT JOIN existing_week ew ON cw.complete_weeks = ew.existing_weeks
WHERE ew.existing_weeks IS NULL;
```
| missing_weeks |
|---------------|
| 1             |
| 2             |
| 3             |
| 4             |
| 5             |
| 6             |
| 7             |
| 8             |
| 9             |
| 10            |
| 11            |
| 12            |
| 37            |
| 38            |
| 39            |
| 40            |
| 41            |
| 42            |
| 43            |
| 44            |
| 45            |
| 46            |
| 47            |
| 48            |
| 49            |
| 50            |
| 51            |
| 52            |

A total of 28 weeks are missing in the dataset. These missing weeks include weeks 1 to 12 and weeks 37 to 52, which are concentrated in the early and late parts of the year.

---

#### 3. How many total transactions were there for each year in the dataset?

```sql
SELECT calendar_year, 
       TO_CHAR(SUM(transactions), '999,999,999') AS total_transactions
FROM clean_weekly_sales
GROUP BY 1;
```

| calendar_year | total_transactions |
|---------------|--------------------|
| 2018          | 346,406,460        |
| 2019          | 365,639,285        |
| 2020          | 375,813,651        |

The number of transactions increased steadily across the years:
•	2018: 346 million
•	2019: 366 million
•	2020: 376 million

---

#### 4.What is the total sales for each region for each month?

```sql
SELECT region, 
       month_number, 
	   SUM (sales) AS total_sales
FROM clean_weekly_sales
GROUP BY 1,2
ORDER BY 1,2;
```

##### Sample Outpu

| region        | month_number | total_sales    |
|---------------|--------------|----------------|
| AFRICA        | 3            | 567767480      |
| AFRICA        | 4            | 1911783504     |
| AFRICA        | 5            | 1647244738     |
| AFRICA        | 6            | 1767559760     |
| AFRICA        | 7            | 1960219710     |
| AFRICA        | 8            | 1809596890     |
| AFRICA        | 9            | 276320987      |
| ASIA          | 3            | 529770793      |
| ASIA          | 4            | 1804628707     |
| ASIA          | 5            | 1526285399     |
| ASIA          | 6            | 1619482889     |
| ASIA          | 7            | 1768844756     |
| ASIA          | 8            | 1663320609     |
| ASIA          | 9            | 252836807      |
| CANADA        | 3            | 144634329      |
| CANADA        | 4            | 484552594      |
| CANADA        | 5            | 412378365      |
| CANADA        | 6            | 443846698      |
| CANADA        | 7            | 477134947      |
| CANADA        | 8            | 447073019      |
| CANADA        | 9            | 69067959       |
| EUROPE        | 3            | 35337093       |
| EUROPE        | 4            | 127334255      |
| EUROPE        | 5            | 109338389      |
| EUROPE        | 6            | 122813826      |
| EUROPE        | 7            | 136757466      |
| EUROPE        | 8            | 122102995      |
| EUROPE        | 9            | 18877433       |
| OCEANIA       | 3            | 783282888      |
| OCEANIA       | 4            | 2599767620     |
| OCEANIA       | 5            | 2215657304     |
| OCEANIA       | 6            | 2371884744     |
| OCEANIA       | 7            | 2563459400     |
| OCEANIA       | 8            | 2432313652     |
| OCEANIA       | 9            | 372465518      |

The data indicates significant variations in sales across regions and months. Regions like Oceania, Africa and Asia have substantial sales figures compared to others, with peaks observed during specific months.

---

#### 5. What is the total count of transactions for each platform?

```sql
SELECT platform,
       SUM (transactions) AS transtaction_count
FROM clean_weekly_sales
GROUP BY 1
ORDER BY 2 DESC;
```

| platform   | transaction_count |
|------------|-------------------|
| Retail     | 1081934227        |
| Shopify    | 5925169           |

The majority of transactions come from the "Retail" platform, significantly outpacing "Shopify."

--- 

#### 6.	 What is the percentage of sales for Retail vs Shopify for each month?

```sql
WITH sales_totals AS (
SELECT 
    calendar_year,
    month_number,
    SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) AS Retail,
    SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) AS Shopify,
    SUM(sales) AS total_sale
FROM 
    clean_weekly_sales
GROUP BY 
    calendar_year, month_number)
	SELECT calendar_year,
	       month_number,
		   ROUND((Retail*100.0/total_sale),2) AS retail_percentage,
		   ROUND((Shopify*100.0/total_sale),2) AS shpoify_percentage
	FROM sales_totals
	ORDER BY 1,2;
```

| calendar_year | month_number | retail_percentage | shopify_percentage |
|---------------|--------------|-------------------|---------------------|
| 2018          | 3            | 97.92             | 2.08                |
| 2018          | 4            | 97.93             | 2.07                |
| 2018          | 5            | 97.73             | 2.27                |
| 2018          | 6            | 97.76             | 2.24                |
| 2018          | 7            | 97.75             | 2.25                |
| 2018          | 8            | 97.71             | 2.29                |
| 2018          | 9            | 97.68             | 2.32                |
| 2019          | 3            | 97.71             | 2.29                |
| 2019          | 4            | 97.80             | 2.20                |
| 2019          | 5            | 97.52             | 2.48                |
| 2019          | 6            | 97.42             | 2.58                |
| 2019          | 7            | 97.35             | 2.65                |
| 2019          | 8            | 97.21             | 2.79                |
| 2019          | 9            | 97.09             | 2.91                |
| 2020          | 3            | 97.30             | 2.70                |
| 2020          | 4            | 96.96             | 3.04                |
| 2020          | 5            | 96.71             | 3.29                |
| 2020          | 6            | 96.80             | 3.20                |
| 2020          | 7            | 96.67             | 3.33                |
| 2020          | 8            | 96.51             | 3.49                |


Across all the months and years, the Retail platform consistently dominates the sales percentage, making up around 96% to 98% of total sales. Shopify sales, while growing, still represent a small fraction (around 2-3%) of the total sales.

---

#### 7.	What is the percentage of sales by demographic for each year in the dataset?

```sql
WITH sales_CTE AS (
SELECT 
    calendar_year AS year,
    SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) AS couples_sales,
    SUM(CASE WHEN demographic = 'Families'  THEN sales ELSE 0 END) AS families_sales,
	SUM(CASE WHEN demographic = 'Unknown'  THEN sales ELSE 0 END) AS unknown_sales,
    SUM(sales) AS total_sale
FROM 
    clean_weekly_sales
GROUP BY 
    calendar_year)
SELECT year, 
       ROUND((couples_sales*100.0/total_sale),2) AS couples_percentage,
       ROUND((families_sales*100.0/total_sale),2) AS families_percentage,
       ROUND((unknown_sales*100.0/total_sale),2) AS unknown_percentage
FROM sales_CTE;
```

| year | couples_percentage | families_percentage | unknown_percentage |
|------|--------------------|---------------------|--------------------|
| 2018 | 26.38              | 31.99               | 41.63              |
| 2019 | 27.28              | 32.47               | 40.25              |
| 2020 | 28.72              | 32.73               | 38.55              |

The percentage of sales by demographic shows a steady increase in the share of sales attributed to "Couples," rising from 26.38% in 2018 to 28.72% in 2020. "Families" consistently represent the highest proportion of sales, maintaining a relatively stable percentage throughout the years. The "Unknown" demographic, slightly decreases over time but still constitutes a notable portion, underlining the presence of unclassified or unidentified demographic information in the dataset.

--- 

#### 8.	Which age_band and demographic values contribute the most to Retail sales?

```sql
SELECT age_band,
       demographic,
	   SUM(sales) AS total_sales,
	   ROUND(SUM(sales)*100.0 /(SELECT SUM(sales) FROM clean_weekly_sales WHERE  platform='Retail' ) ,2) AS sales_percentage
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY 1,2   
ORDER BY 3 DESC;
```

| age_band       | demographic | total_sales | sales_percentage |
|----------------|-------------|-------------|------------------|
| Unknown        | Unknown     | 16067285533 | 40.52            |
| Retirees       | Families    | 6634686916  | 16.73            |
| Retirees       | Couples     | 6370580014  | 16.07            |
| Middle Aged    | Families    | 4354091554  | 10.98            |
| Young Adults   | Couples     | 2602922797  | 6.56             |
| Middle Aged    | Couples     | 1854160330  | 4.68             |
| Young Adults   | Families    | 1770889293  | 4.47             | 

The age_band and demographic combination with the highest contribution to Retail sales is "Unknown" values, accounting for 40.52% of the total. Significant contributions are also observed from "Retirees" with "Families" and "Couples" accounting for 16.73% and 16.07% respectively    

---

#### 9.	Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

```sql
SELECT 
    calendar_year,
    platform,
    ROUND(SUM(sales::numeric) / NULLIF(SUM(transactions::numeric),0),2) AS overall_avg,
    ROUND(AVG(avg_transaction::numeric), 2) AS avg_of_avg
FROM 
    clean_weekly_sales
GROUP BY 
    calendar_year, platform
ORDER BY 
    calendar_year, platform;
```

| calendar_year | platform | overall_avg | avg_of_avg |
|---------------|----------|-------------|------------|
| 2018          | Retail   | 36.56       | 42.41      |
| 2018          | Shopify  | 192.48      | 187.80     |
| 2019          | Retail   | 36.83       | 41.47      |
| 2019          | Shopify  | 183.36      | 177.07     |
| 2020          | Retail   | 36.56       | 40.14      |
| 2020          | Shopify  | 179.03      | 174.40     |

- 	The results show some discrepancies between the two measures. The avg_of_avg column, which is based on the avg_transaction column, tends to report slightly higher values compared to the overall average (overall_avg). This indicates that while avg_transaction provides a good approximation, it doesn't perfectly represent the true average transaction size when calculated directly from sales and transactions.
- 	For Retail, the overall average remains consistent around 36.5 across the years. For Shopify, the overall averages are consistently higher than Retail, with a small downward trend from 192.48 in 2018 to 179.03 in 2020.

---

### C-Before and After Analysis

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:

#### 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

```sql
SELECT DISTINCT week_number  
FROM clean_weekly_sales  
WHERE week_date = '2020-06-15' AND calendar_year = '2020';  
```

| week_number    |
|----------------|
|25              |

```sql
WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 21 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 28 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 21 AND 28 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT 
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
)
SELECT 
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales;
```

| before_sales | after_sales  | sales_diff  | growth_rate |
|--------------|--------------|-------------|-------------|
| 2345878357   | 2318994169   | -26884188   | -1.15       |

The total sales for the 4 weeks before and after the implementation of the sustainable packaging changes show a slight decrease in sales following the change. Specifically, there is a reduction of approximately 26.88 million in sales, corresponding to a decrease of about 1.15%.

---

#### 2. What about the entire 12 weeks before and after? 

```sql
WITH before_after_periods AS ( 
SELECT 
*, 
CASE 
WHEN week_number BETWEEN 13 AND 24 THEN 'Before' 
WHEN week_number BETWEEN 25 AND 37 THEN 'After' 
END AS period 
FROM clean_weekly_sales 
WHERE week_number BETWEEN 13 AND 37 AND calendar_year = '2020' 
), 
before_after_sales AS ( 
SELECT 
SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales, 
SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales 
FROM before_after_periods 
) 
SELECT 
before_sales, 
after_sales, 
(after_sales - before_sales) AS sales_diff, 
ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate 
FROM before_after_sales;
```

| before_sales | after_sales  | sales_diff  | growth_rate |
|--------------|--------------|-------------|-------------|
| 7126273147   | 6973947753   | -152325394   | -2.14       |

Over the 12 weeks before and after the sustainable packaging change, total sales declined by 2.14%, representing a reduction of approximately 152.3 million.

---

#### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

#### a)	4 weeks 

```sql
WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 21 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 28 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 21 AND 28
),
before_after_sales AS (
    SELECT 
        calendar_year, 
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
    GROUP BY calendar_year
)
SELECT 
    calendar_year, 
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / before_sales, 2) AS change_percent
FROM before_after_sales
GROUP BY calendar_year, before_sales, after_sales
ORDER BY calendar_year;
```

| calendar_year | before_sales | after_sales  | sales_diff  | growth_rate |
|------|--------------|--------------|-------------|-------------|
| 2018 | 2125140809   | 2129242914   | 4102105     | 0.19        |
| 2019 | 2249989796   | 2252326390   | 2336594     | 0.10        |
| 2020 | 2345878357   | 2318994169   | -26884188   | -1.15       |

2018 and 2019 show minimal increases in sales over the 4-week period before and after week 25 (0.19% and 0.10%, respectively). In contrast, 2020 stands out with a 1.15% decrease in sales for the same period, indicating a negative impact post-packaging changes compared to the previous years. 

#### b)	12 weeks 

```sql
WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37
),
before_after_sales AS (
    SELECT 
        calendar_year, 
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
    GROUP BY calendar_year
)
SELECT 
    calendar_year, 
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / before_sales, 2) AS change_percent
FROM before_after_sales
GROUP BY calendar_year, before_sales, after_sales
ORDER BY calendar_year;

| calendar_year | before_sales | after_sales  | sales_diff   | growth_rate |
|---------------|--------------|--------------|--------------|-------------|
| 2018          | 6396562317   | 6500818510   | 104256193    | 1.63        |
| 2019          | 6883386397   | 6862646103   | -20740294    | -0.30       |
| 2020          | 7126273147   | 6973947753   | -152325394   | -2.14       |
```
For the 12-week period before and after the change, 2020 experienced a larger decline in sales compared to 2019 and 2018. The decline in 2020 was 2.14%, with a drop of about 152.33 million in sales. This compares to a 0.30% decline in 2019 and a 1.63% growth in 2018. The 2020 data indicates a more noticeable negative impact, particularly when compared to 2018 and 2019. 

---
### D-Bonus Question

#### Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

#### Region

_Note: The same query logic was applied to platform, age_band, demographic, and customer_type by replacing the region variable with the respective dimensions._

```sql
WITH before_after_periods AS (
    SELECT 
        *,
        CASE 
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 37 THEN 'After'
        END AS period
    FROM clean_weekly_sales
    WHERE week_number BETWEEN 13 AND 37 AND calendar_year = '2020'
),
before_after_sales AS (
    SELECT region,
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales,
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales
    FROM before_after_periods
	GROUP BY 1
)
SELECT region,
    before_sales, 
    after_sales, 
    (after_sales - before_sales) AS sales_diff,
    ROUND((after_sales - before_sales) * 100.0 / NULLIF(before_sales, 0), 2) AS growth_rate
FROM before_after_sales
GROUP BY 1,2,3
ORDER BY 5 DESC;
```
| region        | before_sales  | after_sales   | sales_diff   | growth_rate |
|---------------|---------------|---------------|--------------|-------------|
| EUROPE        | 108886567     | 114038959     | 5152392      | 4.73        |
| AFRICA        | 1709537105    | 1700390294    | -9146811     | -0.54       |
| USA           | 677013558     | 666198715     | -10814843    | -1.60       |
| CANADA        | 426438454     | 418264441     | -8174013     | -1.92       |
| SOUTH AMERICA | 213036207     | 208452033     | -4584174     | -2.15       |
| OCEANIA       | 2354116790    | 2282795690    | -71321100    | -3.03       |
| ASIA          | 1637244466    | 1583807621    | -53436845    | -3.26       |

Asia and Oceania regions experienced the highest negative impact in sales with decreases of 3.26% and 3.03% Europe, on the other hand, showed a positive sales growth of 4.73%.

---
#### Platform

| platform | before_sales | after_sales  | sales_diff  | growth_rate |
|----------|--------------|--------------|-------------|-------------|
| Shopify  | 219412034    | 235170474    | 15758440    | 7.18        |
| Retail   | 6906861113   | 6738777279   | -168083834  | -2.43       |

Shopify outperformed significantly, with a 7.18% increase in sales, while Retail platforms faced a decline of 2.43%.

---
#### Age Band

| age_band        | before_sales | after_sales  | sales_diff  | growth_rate |
|-----------------|--------------|--------------|-------------|-------------|
| Young Adults    | 801806528    | 794417968    | -7388560    | -0.92       |
| Retirees        | 2395264515   | 2365714994   | -29549521   | -1.23       |
| Middle Aged     | 1164847640   | 1141853348   | -22994292   | -1.97       |
| Unknown         | 2764354464   | 2671961443   | -92393021   | -3.34       |

The "Unknown" age band saw the largest negative sales impact with a 3.34% decline, likely due to a higher volume of records without specific demographic data. Other age bands, such as "Middle Aged" and "Retirees," also faced negative impacts, though to a lesser extent.

---
#### Demographic

| demographic | before_sales | after_sales  | sales_diff  | growth_rate |
|-------------|--------------|--------------|-------------|-------------|
| Couples     | 2033589643   | 2015977285   | -17612358   | -0.87       |
| Families    | 2328329040   | 2286009025   | -42320015   | -1.82       |
| Unknown     | 2764354464   | 2671961443   | -92393021   | -3.34       |

The "Unknown" demographic again experienced the largest negative impact, with a 3.34% reduction in sales. Both "Families" and "Couples" also saw negative growth

---
#### Customer Type

| customer_type | before_sales | after_sales  | sales_diff  | growth_rate |
|---------------|--------------|--------------|-------------|-------------|
| New           | 862720419    | 871470664    | 8750245     | 1.01        |
| Existing      | 3690116427   | 3606243454   | -83872973   | -2.27       |
| Guest         | 2573436301   | 2496233635   | -77202666   | -3.00       |

“Guest" customers had the largest decline, with a 3.00% drop in sales, while "Existing" customers also experienced a decline of 2.27%. On the other hand, "New" customers showed a positive growth of 1.01%.

---












