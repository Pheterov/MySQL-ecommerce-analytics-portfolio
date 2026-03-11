# sql-ecommerce-analytics-portfolio
> *"The goal is not to write SQL. The goal is to answer business questions."*
# SQL Analytics Portfolio — Supersales modified by KajoData

**Business-focused SQL analysis project built on an e-commerce dataset.**  
This repository presents a collection of SQL solutions for real-world analytical problems related to sales performance, customer behavior, retention, promotions, and product analytics.

The goal of this project is not only to show SQL syntax proficiency, but also to demonstrate:
- structured analytical thinking,
- correct aggregation logic,
- business interpretation of results,
- clean and maintainable query design.

---

## Project Overview

This portfolio is based on the **Supersales modified by KajoData** dataset and simulates the type of work performed by a **Data Analyst / BI Analyst / E-commerce Analyst** in a real business environment.

The analyses focus on questions such as:
- How is revenue changing over time?
- Which products and categories generate the highest value?
- Are customers returning after their first purchase?
- Do discounts improve or dilute business performance?
- Is company growth driven by acquisition or retention?

All solutions were written in **MySQL 8+** and designed with readability, business usefulness, and production-style structure in mind.

---

## Skills Demonstrated

### SQL Fundamentals
- `JOIN`
- `GROUP BY`
- `COUNT(DISTINCT ...)`
- `CASE WHEN`
- date transformations and time granularity handling

### Analytical SQL
- Common Table Expressions (**CTE**)
- Window Functions:
  - `LAG()`
  - `LEAD()`
  - `ROW_NUMBER()`
  - `DENSE_RANK()`
  - `NTILE()`
  - `MIN() OVER()`
  - `FIRST_VALUE()`
  - `LAST_VALUE()`

### Business Analytics Concepts
- Revenue and AOV analysis
- Product and category performance
- Customer segmentation
- New vs returning customers
- Monthly retention (M+1)
- One-time customer analysis
- Discount effectiveness
- Growth attribution analysis

---

## Database Structure

```bash

The project uses the **supersales - modified by KajoData** database, consisting of the following tables:

orders
├── order_id (INT)
├── customer_id (INT)
├── order_date (DATE)
├── shipping_date (DATE)
├── shipping_mode (VARCHAR)
├── delivery_country (VARCHAR)
├── delivery_city (VARCHAR)
├── delivery_state (VARCHAR)
└── order_return (INT)

order_positions
├── order_id (INT)
├── order_position_id (INT)
├── product_id (INT)
├── item_quantity (INT)
└── position_discount (FLOAT)

products
├── product_id (INT)
├── group_id (INT)
├── product_name (VARCHAR)
└── product_price (FLOAT)

product_groups
├── group_id (INT)
├── product_group (VARCHAR)
└── category (VARCHAR)

order_ratings
├── order_id (INT)
└── rating (INT)

order_returns
├── order_id (INT)
└── next_order_free (INT)

### Relationships
orders ──── order_positions ──── products ──── product_groups
│ │
│ └── (many positions per order)
│
├── order_ratings (1:1)
└── order_returns (1:1)

Dataset Description
The Supersales database consists of the following core tables:

orders
Contains order-level information:

order_id
customer_id
order_date
shipping_date
shipping_mode
delivery-related fields
order_positions
Contains product-level details within each order:

order_id
product_id
item_quantity
position_discount
products
Contains product metadata:

product_id
group_id
product_name
product_price
product_groups
Maps products into broader business groupings:

group_id
product_group
category
Representative Business Problems Solved
1. Monthly Revenue Performance
total revenue by month
number of orders
number of unique customers
average order value (AOV)
2. Product & Category Analysis
top-selling products by units sold
top products by monthly revenue
category contribution to total company revenue
3. Customer Analytics
new vs returning customers
one-time customers and their share of total revenue
customer revenue ranking
average revenue per active month
4. Retention & Growth
month-over-month revenue growth
M+1 retention rate
growth source analysis: new customers vs returning customers
5. Discount & Promotion Analysis
discounted vs non-discounted orders
impact of discounts on order value
monthly percentage of discounted orders
Example Analytical Approach
The SQL in this repository follows a consistent analytical structure:

Choose the correct level of granularity
Example: month, customer-month, or order-level.

Prepare the data with CTEs
This improves readability and makes each step logically testable.

Use window functions only when they are the right tool
Ranking, month-over-month comparisons, first purchase logic, and retention calculations.

Prioritize business meaning over unnecessary complexity
Queries are designed to answer business questions clearly, not just to be syntactically clever.

Why This Repository Exists
This project was built as part of a structured preparation path for Junior / Junior+ Data Analyst roles and evolved into a portfolio demonstrating a stronger level of SQL maturity.

The key objective was to move beyond:

writing queries that “work”,
and toward writing queries that are:
correct,
explainable,
scalable,
and business-relevant.
Tools Used
MySQL 8+
DBeaver
Git / GitHub
How to Use
Clone the repository
Open the SQL file in your SQL editor
Connect to a MySQL environment with the supersales dataset
Run queries individually
What Recruiters / Hiring Managers Can Expect Here
This repository is intended to showcase:

practical SQL problem solving,
understanding of analytical business questions,
ability to translate requirements into clear query logic,
portfolio-quality communication through code comments and structure.
It is especially relevant for roles such as:

Junior Data Analyst
Junior BI Analyst
E-commerce Analyst
Reporting Analyst
Analytics / Commercial Data Analyst
Future Improvements
Planned extensions of this repository may include:

cohort analysis,
churn logic,
RFM segmentation,
rolling averages,
anomaly detection,
dashboard-ready SQL outputs.
Author
Piotr Rzepka
Aspiring Data Analyst focused on SQL, analytics, and business problem solving.
