/*
===============================================================================
Project: E-commerce Analytics SQL Portfolio
Database: supersales - modified by KajoData
Author: Piotr Rzepka
Description: Collection of SQL queries solving real-world business problems.
             Focus on customer retention, revenue analysis, and product performance.
===============================================================================
*/

/*
================================================================================
Task 1: Monthly Business Performance Metrics
Business Objective:
Provide management with a high-level view of monthly performance.
Key metrics: total revenue, unique customers, order count, and average order value (AOV).
================================================================================
*/
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m-01')										month
    ,ROUND(SUM(op.item_quantity*p.product_price*(1-op.position_discount)), 2) 	revenue
    ,COUNT(DISTINCT o.customer_id)												unique_customers
    ,COUNT(DISTINCT op.order_id) 												order_count
    ,ROUND(
        SUM(op.item_quantity*p.product_price*(1-op.position_discount)) / 
        COUNT(DISTINCT op.order_id), 2)											avg_order_value
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
ORDER BY month;

/*
================================================================================
Task 2: Product Category Performance (Units Sold)
Business Objective:
Identify which product categories drive the highest volume sales.
Used for inventory planning and category management.
================================================================================
*/
SELECT
    pg.category
    ,SUM(op.item_quantity) 														total_units_sold
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
JOIN product_groups pg ON p.group_id = pg.group_id
GROUP BY pg.category
ORDER BY total_units_sold DESC;

/*
================================================================================
Task 3: Top 5 Products by Sales Volume
Business Objective:
Identify best-selling products to focus marketing and stock allocation.
Methodology:
- Aggregates total units sold per product.
- Uses DENSE_RANK to handle ties (multiple products with same sales volume).
- Returns exactly 5 products.
- Could've been also done by turning this below SELECT
  to a CTE and then filtered by WHERE in final select.
================================================================================
*/
SELECT
    p.product_name
    ,SUM(op.item_quantity) 														total_units_sold
    ,DENSE_RANK() OVER (
    	ORDER BY SUM(op.item_quantity) DESC)									sales_rank
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
GROUP BY p.product_name
ORDER BY sales_rank
LIMIT 5;

/*
================================================================================
Task 4: Average Shipping Time Analysis
Business Objective:
Measure operational efficiency by calculating average days between order and shipping.
Note: This is a baseline metric. Further segmentation by product/category is recommended.
================================================================================
*/
SELECT
    ROUND(AVG(
    	DATEDIFF(o.shipping_date, o.order_date)), 2)							avg_shipping_days
FROM orders o;

/*
================================================================================
Task 5: Monthly Top 3 Products by Revenue
Business Objective:
Identify highest-revenue generating products each month for performance tracking.
Methodology:
- Revenue calculated with position-level discounts applied.
- DENSE_RANK used within each month partition to handle revenue ties.
- Returns top 3 products per month.
================================================================================
*/
WITH monthly_product_revenue AS 
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,p.product_name
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount))		revenue
	,DENSE_RANK() OVER (
		PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m-01')
		ORDER BY SUM(op.item_quantity * p.product_price * (1 - op.position_discount)) DESC
	)																			revenue_rank
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month, p.product_name
)
SELECT
    month
    ,product_name
    ,ROUND(revenue, 2)															revenue
    ,revenue_rank
FROM monthly_product_revenue
WHERE revenue_rank <= 3
ORDER BY month, revenue_rank;

/*
================================================================================
Task 6: Customer Revenue Ranking
Business Objective:
Segment customers by their total lifetime revenue for targeted marketing.
Methodology:
- Calculates total revenue per customer (with discounts applied).
- Uses DENSE_RANK to assign positions, handling revenue ties appropriately.
================================================================================
*/
SELECT
    o.customer_id
    ,ROUND(SUM(op.item_quantity*p.product_price*(1-op.position_discount)), 2)	total_revenue
    ,DENSE_RANK() OVER (
        ORDER BY SUM(op.item_quantity*p.product_price*(1-op.position_discount)) DESC
    ) 																			revenue_rank
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.customer_id
ORDER BY total_revenue DESC;

/*
================================================================================
Task 7: Month-over-Month Revenue Growth
Business Objective:
Track revenue trends and identify growth/decline patterns.
Methodology:
- Calculates monthly revenue.
- Uses LAG window function to compare with previous month.
- Shows both absolute and percentage change.
================================================================================
*/
WITH monthly_revenue AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount)) 		revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
)
SELECT
    month
    ,ROUND(revenue, 2)															revenue
    ,ROUND(LAG(revenue) OVER (
    ORDER BY month), 2) 														previous_month_revenue
    ,ROUND(revenue - LAG(revenue) OVER (
    ORDER BY month), 2) 														revenue_change
    ,ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0 / 
        LAG(revenue) OVER (ORDER BY month), 2) 									revenue_change_pct
FROM monthly_revenue
ORDER BY month;

/*
================================================================================
Task 8: New vs Returning Customer Analysis (Monthly)
Business Objective:
Understand customer acquisition vs retention dynamics.
Methodology:
- First identifies each customer's first order month using MIN() OVER().
- Classifies each monthly appearance as "new" (first month) or "returning" (subsequent months).
================================================================================
*/
WITH customer_months AS
(
SELECT DISTINCT
	customer_id
	,DATE_FORMAT(order_date, '%Y-%m-01')										month
FROM orders
), customer_first_month AS 
(
SELECT
	customer_id
	,month
	,MIN(month) OVER (PARTITION BY customer_id) 								first_order_month
FROM customer_months
)
SELECT
    month
    ,COUNT(
    	CASE WHEN month = first_order_month 
    	THEN 1 
    END) 																		new_customers
    ,COUNT(
    	CASE WHEN month > first_order_month 
    	THEN 1 
    END) 																		returning_customers
FROM customer_first_month
GROUP BY month
ORDER BY month;

/*
================================================================================
Task 9: One-Time Customer Analysis
Business Objective:
Measure customer loyalty by analyzing percentage of customers who purchase only once
and their contribution to total revenue.
Methodology:
- Identifies customers with exactly one order.
- Calculates their share of total customer base and total revenue.
================================================================================
*/
WITH customer_stats AS 
(
SELECT
	o.customer_id
	,COUNT(DISTINCT op.order_id) AS order_count
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount))		total_revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.customer_id
)
SELECT
    ROUND(
        COUNT(CASE WHEN order_count = 1 THEN customer_id END) * 100.0 / 
        COUNT(*), 2) 															one_time_customers_pct
    ,ROUND(
        SUM(CASE WHEN order_count = 1 THEN total_revenue END) * 100.0 / 
        SUM(total_revenue), 2) 													one_time_customers_revenue_pct
FROM customer_stats;

/*
================================================================================
Task 10: Month+1 Customer Retention Rate
Business Objective:
Measure customer loyalty by calculating what percentage of active customers
in a given month return to purchase in the following month.
Methodology:
- Deduplicates customer-month activity.
- Uses LEAD() to find next purchase month.
- Compares with calendar next month to identify retention.
================================================================================
*/
WITH customer_month_activity AS (
SELECT DISTINCT
	customer_id
	,DATE_FORMAT(order_date, '%Y-%m-01') 										month
FROM orders
), customer_next_purchase AS 
(
SELECT
	month
	,customer_id
	,LEAD(month) OVER (
		PARTITION BY customer_id 
		ORDER BY month) 														next_purchase_month
	,DATE_ADD(month, INTERVAL 1 MONTH) 											next_calendar_month
FROM customer_month_activity
)
SELECT
    month
	,COUNT(*)														 			active_customers
    ,COUNT(CASE WHEN next_purchase_month = next_calendar_month 
    	THEN 1 
    END) 																		retained_customers
    ,ROUND(COUNT(
    CASE WHEN next_purchase_month = next_calendar_month
        THEN 1 
	END) * 100.0 / 
	COUNT(*), 2)																retention_rate_pct
FROM customer_next_purchase
GROUP BY month
ORDER BY month;

/*
================================================================================
Task 11: Growth Analysis - New vs Existing Customers
Business Objective:
Determine whether company growth is driven by acquiring new customers
or increasing revenue from existing customers.
Methodology:
1. Aggregates revenue to customer-month level.
2. Identifies each customer's first purchase month.
3. Classifies revenue as "new" (first month) or "returning" (subsequent months).
4. Tracks monthly trend of revenue share from both segments.

Analytical Insight:
Data shows 2018 was primarily an acquisition phase (new customer revenue dominant).
From 2019 onward, the company entered a retention phase where returning customers
generate the majority of revenue, indicating successful customer relationship building.
================================================================================
*/
WITH customer_monthly_revenue AS 
(
SELECT
	o.customer_id
	,DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount))		revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.customer_id, month
), customer_first_month AS
(
SELECT
	customer_id
	,month
	,revenue
	,MIN(month) OVER (PARTITION BY customer_id)									first_purchase_month
FROM customer_monthly_revenue
)
SELECT
    month
    ,ROUND(SUM(
    	CASE WHEN month = first_purchase_month 
    	THEN revenue 
    END), 2) 																	new_customer_revenue
    ,ROUND(SUM(
    	CASE WHEN month > first_purchase_month 
    	THEN revenue 
	END), 2) 																	returning_customer_revenue
    ,ROUND(
        SUM(CASE WHEN month = first_purchase_month THEN revenue END) * 100.0 / 
        SUM(revenue), 2) 														new_customer_revenue_pct
    ,ROUND(
        SUM(CASE WHEN month > first_purchase_month THEN revenue END) * 100.0 / 
        SUM(revenue), 2)														returning_customer_revenue_pct
FROM customer_first_month
GROUP BY month
ORDER BY month;