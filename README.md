# sql-ecommerce-analytics-portfolio
> *"The goal is not to write SQL. The goal is to answer business questions."*
# SQL Analytics Portfolio — Supersales

**Business-focused SQL analysis project built on an e-commerce dataset.**  
This repository presents a collection of SQL solutions for real-world analytical problems related to sales performance, customer behavior, retention, promotions, and product analytics.

The goal of this project is not only to show SQL syntax proficiency, but also to demonstrate:
- structured analytical thinking,
- correct aggregation logic,
- business interpretation of results,
- clean and maintainable query design.

---

## Project Overview

This portfolio is based on the **Supersales** dataset and simulates the type of work performed by a **Data Analyst / BI Analyst / E-commerce Analyst** in a real business environment.

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
