################################################################################
# 🎯 Project: E-commerce Analytics SQL Portfolio
# 🛠️ Database: supersales - modified by KajoData MySQL 8.0+
# 👤 Author: Piotr Rzepka
# 📝 Description: SQL-driven analytics portfolio solving real-world e-commerce business problems.
# 🔍 Focus: Customer retention, revenue analysis, product & category performance
################################################################################

/*================================================================================
1️⃣ Monthly Business Performance Metrics
🎯 Goal: High-level monthly KPIs for management
🛠️ Stack: SQL
📈 Metrics: revenue, unique customers, order count, avg order value (AOV)
💡 Impact: Tracks trends, enables informed decision-making
================================================================================*/
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

/*================================================================================
2️⃣ Product Category Performance (Units Sold)
🎯 Goal: Identify top-selling product categories
🛠️ Stack: SQL
📈 KPI: total_units_sold per category
💡 Impact: Supports inventory planning and category prioritization
================================================================================*/
SELECT
    pg.category
    ,SUM(op.item_quantity) 														total_units_sold
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
JOIN product_groups pg ON p.group_id = pg.group_id
GROUP BY pg.category
ORDER BY total_units_sold DESC;

/*================================================================================
3️⃣ Top 5 Products by Sales Volume
🎯 Goal: Highlight best-sellers for marketing focus & stock allocation
🛠️ Stack: SQL (DENSE_RANK)
📈 KPI: total_units_sold, sales_rank
💡 Impact: Prioritizes top-performing products to drive revenue
================================================================================*/
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

/*================================================================================
4️⃣ Average Shipping Time Analysis
🎯 Goal: Measure operational efficiency
🛠️ Stack: SQL
📈 KPI: avg_shipping_days
💡 Impact: Baseline metric for delivery performance, identifies areas for improvement
================================================================================*/
SELECT
    ROUND(AVG(
    	DATEDIFF(o.shipping_date, o.order_date)), 2)							avg_shipping_days
FROM orders o;

/*================================================================================
5️⃣ Monthly Top 3 Products by Revenue
🎯 Goal: Identify top-revenue products per month
🛠️ Stack: SQL (CTE + DENSE_RANK)
📈 KPI: revenue, revenue_rank
💡 Impact: Supports sales strategy, focuses on high-revenue items
================================================================================*/
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

/*================================================================================
6️⃣ Customer Revenue Ranking
🎯 Goal: Segment customers by total lifetime revenue
🛠️ Stack: SQL (DENSE_RANK)
📈 KPI: total_revenue, revenue_rank
💡 Impact: Identifies top contributors, enables targeted loyalty strategies
================================================================================*/
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

/*================================================================================
7️⃣ Month-over-Month Revenue Growth
🎯 Goal: Track revenue trends & growth patterns
🛠️ Stack: SQL (LAG)
📈 KPI: revenue_change, revenue_change_pct
💡 Impact: Provides insights into revenue fluctuations; informs strategy
================================================================================*/
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

/*================================================================================
8️⃣ New vs Returning Customer Analysis
🎯 Goal: Analyze customer acquisition vs retention dynamics
🛠️ Stack: SQL (MIN() OVER)
📈 KPI: new_customers, returning_customers
💡 Impact: Tracks retention trends; informs engagement strategy
================================================================================*/
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

/*================================================================================
9️⃣ One-Time Customer Analysis
🎯 Goal: Quantify customer loyalty via one-time purchases
🛠️ Stack: SQL
📈 KPI: one_time_customers_pct, one_time_customers_revenue_pct
💡 Impact: Identifies churn risk and revenue concentration from single-purchase customers
================================================================================*/
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

/*================================================================================
🔟 Month+1 Customer Retention Rate
🎯 Goal: Calculate next-month retention
🛠️ Stack: SQL (LEAD)
📈 KPI: retention_rate_pct
💡 Impact: Key loyalty metric; measures retention effectiveness
================================================================================*/
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

/*================================================================================
1️⃣1️⃣ Growth Analysis: New vs Existing Customers
🎯 Goal: Determine revenue growth drivers: new vs returning customers
🛠️ Stack: SQL (CTE + window functions)
📈 KPI: new_customer_revenue_pct, returning_customer_revenue_pct
💡 Insight: 2018 = acquisition-focused, 2019+ = retention-driven; informs long-term strategy
================================================================================*/
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
ORDER BY month;

################################################################################
# 🎯 Task 1: Monthly Business Performance Metrics (Ultra Jef Castello Level+)
# 🛠️ Stack: SQL
# 💡 Goal: Provide management with high-level monthly KPIs
# 🔍 Focus: revenue, unique customers, order count, avg order value (AOV)
################################################################################

/*================================================================================
📊 Mini KPI Dashboard (Example Data)
Month     | Revenue    | Unique Customers | Orders | Avg Order Value
----------|-----------|----------------|--------|----------------
2018-01   | 120,500   | 1,200           | 1,350  | 89.26
2018-02   | 125,400   | 1,250           | 1,400  | 89.57
2018-03   | 130,800   | 1,300           | 1,450  | 90.20

📈 Revenue Trend (ASCII Sparkline)
2018-01 ████████████ 120,500
2018-02 █████████████ 125,400
2018-03 ██████████████ 130,800

💡 Business Insight:
- Revenue steadily growing month-over-month (+4-5%).
- Average order value stable (~89-90), indicating consistent purchasing behavior.
- Number of unique customers increasing → positive acquisition trend.
================================================================================*/
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
