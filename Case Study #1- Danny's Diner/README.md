# Case Study #1: Danny’s Diner

<img src="https://user-images.githubusercontent.com/81607668/127727503-9d9e7a25-93cb-4f95-8bd0-20b87cb4b459.png" alt="Image" width="450" height="470">

## Introduction
Danny’s Diner, a small Japanese restaurant, opened in early 2021, offering a simple menu of sushi, curry, and ramen. To support its growth, the diner has collected data over several months and now seeks to leverage this information for business improvement.

## Problem Statement
This analysis is designed to provide insights into customer behavior, including their visit frequency, spending trends, and favorite menu items. By understanding these patterns, we can make informed decisions to improve the customer experience and refine our loyalty program.

For complete details regarding the challenge, you can visit [here](https://8weeksqlchallenge.com/case-study-1/).

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



