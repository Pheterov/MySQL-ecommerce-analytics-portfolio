#####################################################################################################
# 🎯 Project: E-commerce Analytics SQL Portfolio
# 🛠️ Database: supersales - modified by KajoData MySQL 8.0+
# 👤 Author: Piotr Rzepka
# 📝 Description: Full-stack SQL-driven e-commerce analytics portfolio
# 🔍 Focus: customer retention, revenue analysis, product & category performance
#####################################################################################################

/*===================================================================================================
1️⃣ Monthly Business Performance Metrics
🎯 Goal: Monthly KPIs for management
🛠️ Stack: SQL
💡 Impact: Tracks trends, enables informed decision-making
📊 Example KPI:
| Month     | Revenue    | Unique Customers | Orders | Avg Order Value |
|-----------|-----------|-------------------|--------|-----------------|
| 2018-01   |   324.04	| 		   3       	|	 3   |		108.01     |
| 2018-02   | 14470.88	| 		  32        |	32   |		452.22     |
| 2018-03   |  8552.10	| 		  38        |	40   |		213.80     |	
====================================================================================================*/
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m-01')										month
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price, 0)*
    	(1 - COALESCE(op.position_discount, 0))), 2) 							revenue
    ,COUNT(DISTINCT o.customer_id)												unique_customers
    ,COUNT(DISTINCT op.order_id) 												order_count
    ,ROUND(
        SUM(op.item_quantity*COALESCE(p.product_price, 0)*
    	(1 - COALESCE(op.position_discount, 0))) / 
        COUNT(DISTINCT op.order_id), 2)											avg_order_value
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
ORDER BY month;

/*===================================================================================================
2️⃣ Product Category Performance (Units Sold)
🎯 Goal: Identify top-selling product categories
🛠️ Stack: SQL
📈 KPI: total_units_sold per category
💡 Impact: Supports inventory planning, category prioritization
📊 Example KPI:
| Category     	  | Units Sold |
|-----------------|------------|
| Office Supplies |  22,906    |
| Furniture       |   8,028    |
| Technology      |   6,939    |
====================================================================================================*/
SELECT
    pg.category
    ,SUM(op.item_quantity) 														total_units_sold
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
JOIN product_groups pg ON p.group_id = pg.group_id
GROUP BY pg.category
ORDER BY total_units_sold DESC;

/*===================================================================================================
# 🎯 Goal: Show difference between baseline metric vs enhanced insight
# 🛠️ Stack: SQL
# 💡 Business Insight:
#    - Baseline total units sold per category lacks temporal context
#    - Enhanced metric: month-over-month comparison, numeric + percentage change
#    - Negative change shown as minus, highlights decreasing performance
📊 Example KPI:
|		month		|		 product_category     | total_units_sold | units_change | units_change_pct |
|-------------------|-----------------------------|------------------|--------------|------------------|
| 	  2018-02-01	|  			Furniture    	  |			70		 |		  [NULL]|			 [NULL]|
| 	  2018-03-01	|  			Furniture    	  |			54		 |		  	 -16|			 -22.86|
| 	  2018-03-01	|  			Furniture    	  |		   103		 |		  	  49|			  90.74|
====================================================================================================*/

WITH monthly_category_sales AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01')                  						month
	,pg.category                                         						product_category
	,SUM(op.item_quantity)                               						total_units_sold
FROM order_positions op
JOIN orders o ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
JOIN product_groups pg ON p.group_id = pg.group_id
GROUP BY month, pg.category
)
SELECT
    month
    ,product_category
    ,total_units_sold
    ,total_units_sold - LAG(total_units_sold) OVER (
        PARTITION BY product_category
        ORDER BY month)                                        					units_change
    ,ROUND(
        (total_units_sold - LAG(total_units_sold) OVER (
			PARTITION BY product_category
			ORDER BY month)) * 100.0 /
		NULLIF(LAG(total_units_sold) OVER (
			PARTITION BY product_category
			ORDER BY month),0), 2)												units_change_pct
FROM monthly_category_sales
ORDER BY product_category, month;
/*===================================================================================================
3️⃣ Top 5 Products by Sales Volume
🎯 Goal: Highlight best-sellers for marketing & stock allocation
🛠️ Stack: SQL 
💡 Impact: Prioritizes top performers to drive revenue
📊 Example KPI:
| Product Name          | Units Sold | Rank |
|-----------------------|------------|------|
| Staples				|     215    |   1  |
| Staple-envelope       |     170    |   2  |
| Easy-staple-paper		|     150    |   3  |
| Staples-in-misc.		|      86    |   4  |
| Logitech P710e-Mobile |      75    |   5  |
====================================================================================================*/
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

/*===================================================================================================
4️⃣ Average Shipping Time Analysis
🎯 Goal: Measure operational efficiency
🛠️ Stack: SQL
💡 Impact: Baseline metric
📊 Example KPI: 3,96 days
====================================================================================================*/
SELECT
    ROUND(AVG(
    	DATEDIFF(o.shipping_date, o.order_date)), 2)							avg_shipping_days
FROM orders o;

/*============================================================================================================================================
🎯 Goal: Show difference between baseline metric vs enhanced insight
🛠️ Stack: SQL
💡 Business Insight:
   - Baseline avg shipping time is not enough; comparing Discounted orders vs Full Price orders is a bare minimum
   - Enables management to assess whether promotions affect fulfillment
   - Note: database is a modified Supersales by KajoData; 
     some results (e.g., Furniture, First Class) reflect dataset structure, not real-world logistics
📊 Example KPI:
| product_category       | shipping_type    | discounted_flag | avg_shipping_days | min_shipping_days | max_shipping_days | orders_count |
| Furniture				 |Standard Class	|Full Price		  |			5.06	  |			4		  |			7		  |		 445	 |
| Furniture				 |Standard Class	|Discounted		  |			4.92	  |			3		  |			7		  |		 626	 |
| Office Supplies		 |First Class		|Full Price		  |			2.18	  |			1		  |			3		  |		 300	 |
| Office Supplies		 |First Class		|Discounted		  |			2.22	  |			1		  |			4		  |		 326	 |
============================================================================================================================================*/

SELECT
    pg.category                                 								product_category
    ,o.shipping_mode                              								shipping_type
    ,'Discounted'                                 								discounted_flag
    ,ROUND(AVG(DATEDIFF(o.shipping_date, o.order_date)), 2) 					avg_shipping_days
    ,ROUND(MIN(DATEDIFF(o.shipping_date, o.order_date)), 2) 					min_shipping_days
    ,ROUND(MAX(DATEDIFF(o.shipping_date, o.order_date)), 2) 					max_shipping_days
    ,COUNT(DISTINCT o.order_id)                    								orders_count
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
JOIN product_groups pg ON p.group_id = pg.group_id
WHERE op.position_discount > 0
GROUP BY pg.category, o.shipping_mode
UNION ALL
SELECT
    pg.category                                 								product_category
    ,o.shipping_mode                              								shipping_type
    ,'Full Price'                                 								discounted_flag
    ,ROUND(AVG(DATEDIFF(o.shipping_date, o.order_date)), 2) 					avg_shipping_days
    ,ROUND(MIN(DATEDIFF(o.shipping_date, o.order_date)), 2) 					min_shipping_days
    ,ROUND(MAX(DATEDIFF(o.shipping_date, o.order_date)), 2) 					max_shipping_days
    ,COUNT(DISTINCT o.order_id)                    								orders_count
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
JOIN product_groups pg ON p.group_id = pg.group_id
WHERE op.position_discount = 0
GROUP BY pg.category, o.shipping_mode
ORDER BY product_category, shipping_type, discounted_flag DESC;

/*===================================================================================================
5️⃣ Monthly Top 3 Products by Revenue
🎯 Goal: Track top-revenue products monthly
🛠️ Stack: SQL (CTE + DENSE_RANK)
📈 KPI: revenue, revenue_rank
💡 Impact: Focuses attention on revenue drivers
📊 Example KPI:
| Month   | Product Name       | Revenue   | Rank |
|---------|------------------|-----------|------|
| 2018-01 | Wireless Mouse    | 25,200.50 | 1    |
| 2018-01 | Bluetooth Speaker | 18,400.75 | 2    |
| 2018-01 | Laptop Stand      | 12,500.00 | 3    |
====================================================================================================*/
WITH monthly_product_revenue AS 
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,p.product_name
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount))		revenue
	,DENSE_RANK() OVER (
		PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m-01')
		ORDER BY SUM(op.item_quantity*p.product_price*(1-op.position_discount)) DESC
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

/*===================================================================================================
6️⃣ Customer Revenue Ranking
🎯 Goal: Segment customers by total lifetime revenue
🛠️ Stack: SQL (DENSE_RANK)
📈 KPI: total_revenue, revenue_rank
💡 Impact: Identifies top contributors; enables targeted loyalty campaigns
📊 Example KPI:
| Customer ID | Total Revenue | Rank |
|------------|---------------|------|
| CUST_102   | 12,500.50     | 1    |
| CUST_215   | 11,200.75     | 2    |
| CUST_078   | 10,900.00     | 3    |
====================================================================================================*/
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

/*===================================================================================================
7️⃣ Month-over-Month Revenue Growth
🎯 Goal: Track revenue trends & growth patterns
🛠️ Stack: SQL (LAG)
📈 KPI: revenue_change, revenue_change_pct
💡 Impact: Insights into revenue fluctuations; informs strategy
📊 Example KPI:
| Month   | Revenue   | Revenue Change | Revenue Change % |
|---------|-----------|----------------|-----------------|
| 2018-01 | 120,500   | NULL           | NULL            |
| 2018-02 | 125,400   | 4,900          | 4.07%           |
====================================================================================================*/
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

/*===================================================================================================
8️⃣ New vs Returning Customer Analysis
🎯 Goal: Analyze acquisition vs retention
🛠️ Stack: SQL (MIN() OVER)
📈 KPI: new_customers, returning_customers
💡 Impact: Tracks retention trends; informs engagement strategy
📊 Example KPI:
| Month   | New Customers | Returning Customers |
|---------|---------------|------------------|
| 2018-01 | 300           | 900              |
| 2018-02 | 280           | 920              |
====================================================================================================*/
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

/*===================================================================================================
9️⃣ One-Time Customer Analysis
🎯 Goal: Quantify customer loyalty via one-time purchases
🛠️ Stack: SQL
📈 KPI: one_time_customers_pct, one_time_customers_revenue_pct
💡 Impact: Identifies churn risk and revenue concentration
📊 Example KPI:
| One-time Customers % | Revenue % |
|---------------------|-----------|
| 22.5                | 9.8       |
====================================================================================================*/
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

/*===================================================================================================
🔟 Month+1 Customer Retention Rate
🎯 Goal: Calculate next-month retention
🛠️ Stack: SQL (LEAD)
📈 KPI: retention_rate_pct
💡 Impact: Key loyalty metric
📊 Example KPI:
| Month   | Active Customers | Retained Customers | Retention % |
|---------|-----------------|-----------------|-------------|
| 2018-01 | 1,200           | 960             | 80.0        |
| 2018-02 | 1,250           | 1,000           | 80.0        |
====================================================================================================*/
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

/*===================================================================================================
1️⃣1️⃣ Growth Analysis: New vs Existing Customers
🎯 Goal: Determine revenue growth drivers: new vs returning customers
🛠️ Stack: SQL (CTE + window functions)
📈 KPI: new_customer_revenue_pct, returning_customer_revenue_pct
💡 Insight: 2018 = acquisition-focused, 2019+ = retention-driven
📊 Example KPI:
| Month   | New Revenue | Returning Revenue | New % | Returning % |
|---------|------------|-----------------|-------|-------------|
| 2018-01 | 25,000     | 95,000          | 20.8  | 79.2        |
| 2018-02 | 24,500     | 100,900         | 19.5  | 80.5        |
====================================================================================================*/
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
