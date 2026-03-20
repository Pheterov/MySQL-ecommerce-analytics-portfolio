	 Project: E-commerce Analytics SQL Portfolio
🛠️ Database: supersales - modified by KajoData MySQL 8.0+
👤 Author: Piotr Rzepka
📝 Description: SQL e-commerce analytics portfolio
🔍 Focus: customer retention, revenue analysis, product & category performance


EXPLICIT ASSUMPTIONS
-------------------------------------------------------------------------------
All queries are based on the following conscious, documented assumptions:

1.  Revenue is calculated at order_date, regardless of shipping status
2.  position_discount is a multiplier between 0 and 1 (0 = no discount, 1 = 100% discount)
3.  NULL values in position_discount or product_price are treated as 0
4.  Orders with shipping_date < order_date are considered data entry errors
    and are excluded only from shipping-time related metrics
5.  A customer is considered "new" in the calendar month of their first order

-------------------------------------------------------------------------------
KNOWN LIMITATIONS
-------------------------------------------------------------------------------
These are conscious tradeoffs for readability and portfolio clarity:

1.  Shipping time per category is calculated at the order line level. For
    orders containing multiple categories, this will weight the average by
    number of line items, not by number of orders.
2.  Retention is defined as Month+1 retention, not 30 day rolling retention.

-------------------------------------------------------------------------------

/*===================================================================================================
1️⃣ Top 10% Products Revenue Contribution (Pareto Analysis)
🎯 Goal: See how much of total revenue comes from the top 10% selling products.
🛠️ Stack: SQL
		 
Query result snippet:
		 
| top_10_pct_revenue | total_revenue | revenue_pct |
|--------------------|---------------|-------------|
|    	1 348 957,66 |  2 268 169,36 |  	 59,47 |
====================================================================================================*/

WITH product_revenue AS
(
SELECT
    p.product_id
    ,p.product_name
    ,SUM(op.item_quantity*COALESCE(p.product_price,0)*
    	(1 - COALESCE(op.position_discount,0))) 								revenue
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
GROUP BY p.product_id, p.product_name
), ranked_products AS
(
SELECT
    product_id
    ,product_name
    ,revenue
    ,NTILE(10) OVER (
    ORDER BY revenue DESC) 														decile
FROM product_revenue
)
SELECT
    ROUND(SUM(CASE WHEN decile = 1 THEN revenue END), 2)                        top_10pct_revenue
    ,ROUND(SUM(revenue), 2)                                                     total_revenue
    ,ROUND(
        SUM(CASE
			WHEN decile = 1
			THEN revenue
		END) * 100.0 /
        SUM(revenue), 2)                                                        top_10pct_revenue_pct
FROM ranked_products;

/*=============================================================================================================================
2️ Growth Analysis: New vs Existing Customers
🎯 Goal: Understand what drives revenue growth — new customers or returning ones.
🛠️ Stack: SQL
💡 Insight: In 2018, growth came mostly from acquiring new customers; from 2019 onward, retaining existing customers became the main driver.

Query result snippet:

| month   	 | new_customer_revenue | returning_customer_revenue | new_customer_revenue_pct | returning_customer_revenue_pct |
|------------|----------------------|----------------------------|--------------------------|--------------------------------|
| 2018-01-01 | 				 324,04 | 					  [NULL] |					    100 | 	   					  [NULL] |
| 2018-02-01 | 			  14 470,88 | 		        	  [NULL] | 						100 | 	   					  [NULL] |
| 2018-03-01 | 			   8 326,86 |       		   	  225,23 | 					  97,37 | 	   	 					2,63 |
| 2018-04-01 | 			  39 682,17 |       		   	1 150,89 | 					  97,18 | 	   	 					2,82 |
| 2018-05-01 | 			  23 230,08 |       		   	3 270,22 | 					  87,66 | 	   					   12,34 |
==============================================================================================================================*/

WITH customer_monthly_revenue AS 
(
SELECT
	o.customer_id
	,DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,SUM(op.item_quantity*COALESCE(p.product_price,0) * 
		(1-COALESCE(op.position_discount,0)))									revenue
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

/*===================================================================================================
2️⃣ Product Category Performance (Units Sold) 
🎯 Goal: Identify top-selling product categories.
🛠️ Stack: SQL
💡 Impact: Helps plan inventory and focus on the categories that matter most.

Query result snippet:

| category		  | total_units_sold | 
|-----------------|------------------|
| Office Supplies | 		  22 906 |
| Furniture		  |			   8 028 |
| Technology 	  | 		   6 939 |
====================================================================================================*/
SELECT
	pg.category
	,SUM(op.item_quantity) 														total_units_sold
FROM order_positions op
JOIN products p ON op.product_id = p.product_id 
JOIN product_groups pg ON p.group_id = pg.group_id
GROUP BY pg.category 
ORDER BY total_units_sold DESC;


/*======================================================================================================
# 🎯 Goal: Show how simple totals hide trends.
#    - Just looking at total units alone hides trends.
#    - Checking month-over-month numbers (both absolute and percentage changes) makes it clearer which categories are growing or shrinking.
#    - Negative changes stand out to ease spotting declining performance.

Query result snippet:

| month				| product_category		      | total_units_sold | units_change | units_change_pct |
|-------------------|-----------------------------|------------------|--------------|------------------|
| 2018-02-01		| Furniture    	  			  |				  70 |		 [NULL] |			[NULL] |
| 2018-03-01		| Furniture    	  			  |				  54 |		  	-16 |			-22,86 |
| 2018-03-01		| Furniture    	  			  |		   		 103 |		  	 49 |			 90,74 |
=======================================================================================================*/

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
3️⃣ Monthly Business Performance Metrics
🎯 Goal: Monthly KPIs for management.
🛠️ Stack: SQL

Query result snippet:

| month      | revenue   | unique_customers  | orders_count | avg_order_value |
|------------|-----------|-------------------|--------------|-----------------|
| 2018-01-01 |    324,04 | 		   		   3 |	 		  3 |		   108,01 |
| 2018-02-01 | 14 470,88 | 		  		  32 |	   		 32 |		   452,22 |
| 2018-03-01 |  8 552,10 | 		  		  38 |	   		 40 |		   213,80 |	
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
        COUNT(DISTINCT o.order_id), 2)											avg_order_value
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
ORDER BY month;

/*===================================================================================================
4️⃣ Month-over-Month Revenue Growth
🎯 Goal: Track how revenue changes from month to month.
🛠️ Stack: SQL
💡 Impact: Shows which months grow or shrink, helping plan actions and priorities.

Query result snippet:

| 	month	 |  revenue  | previous_month_revenue | revenue_change | revenue_change_pct |
|------------|-----------|------------------------|----------------|--------------------|
| 2018-01-01 |    324,04 | 				   [NULL] | 		[NULL] |			 [NULL] |
| 2018-02-01 | 14 470,88 |	 	  		   324,04 |   	 14 146,84 |	  	   4 365,72 |
| 2018-02-01 |  8 552,10 |	 	  		14 470,88 |   	 -5 918,79 |	  		 -40,90 |
====================================================================================================*/

WITH monthly_revenue AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,SUM(op.item_quantity*COALESCE(p.product_price,0) * 
		(1-COALESCE(op.position_discount,0))) 									revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
)
SELECT
    month
    ,ROUND(revenue,2)															revenue
    ,ROUND(LAG(revenue) OVER(
		ORDER BY month),2) 														previous_month_revenue
    ,ROUND(revenue - LAG(revenue) OVER(
		ORDER BY month),2) 														revenue_change
    ,ROUND((revenue - LAG(revenue) OVER (
		ORDER BY month))*100.0 / 
        NULLIF(LAG(revenue) OVER (ORDER BY month),0),2) 						revenue_change_pct
FROM monthly_revenue
ORDER BY month;

/*===================================================================================================
5️⃣ Monthly Top 3 Products by Revenue
🎯 Goal: Track top-revenue products monthly
🛠️ Stack: SQL
💡 Impact: Identify top-revenue products to guide marketing and inventory decisions.

Query reult snippet:

| month   	 | product_name       |	revenue	  	  | ranking |
|------------|--------------------|---------------|---------|
| 2018-01-01 | SAFCO-Boltless     |    	   272,74 |		  1 |
| 2018-01-01 | Avery-Hi-Liter     |     	19,54 | 	  2 |
| 2018-01-01 | Message-Book       |     	16,45 |		  3 |
| 2018-02-01 | Global-Deluxe      |   	 2 573,82 |	      1 |
| 2018-02-01 | Tennsco6--and-18   |   	 1 325,85 |       2 |
| 2018-02-01 | Hon-4700-Series    |   	 1 067,94 |	      3 |
====================================================================================================*/

WITH monthly_product_revenue AS 
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,p.product_name
	,SUM(op.item_quantity*COALESCE(p.product_price, 0)*
    	(1 - COALESCE(op.position_discount, 0)))								revenue
	,DENSE_RANK() OVER (
		PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m-01')
		ORDER BY SUM(op.item_quantity*COALESCE(p.product_price, 0)*
    	(1 - COALESCE(op.position_discount, 0))) DESC)							ranking
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month, p.product_name
)
SELECT
    month
    ,product_name
    ,ROUND(revenue, 2)															revenue
    ,ranking
FROM monthly_product_revenue
WHERE ranking <= 3
ORDER BY month, ranking;

/*===================================================================================================
6️⃣ New vs Returning Customer Analysis
🎯 Goal: Compare amount of new customers to returning ones.
🛠️ Stack: SQL
💡 Impact: Shows whether we’re keeping customers or just gaining new ones.

Query result snippet:

| month   	 | new_customers | returning_customers |
|------------|---------------|---------------------|
| 2018-01-01 |             3 | 				  	 0 |
| 2018-02-01 |            32 | 				  	 0 |
| 2018-03-01 |            35 | 				  	 3 |
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
7️⃣ One-Time Customer Analysis
🎯 Goal: Measure how many customers buy only once also calculate their contribution to total revenue.
🛠️ Stack: SQL
💡  Insight: The result suggests exceptionally high retention or a unique characteristic of the dataset.

Query result snippet:

| one_time_customers_pct | one_time_customers_revenue_pct |
|------------------------|--------------------------------|
|                	1,51 | 						     0,26 |
====================================================================================================*/

WITH customer_stats AS 
(
SELECT
	o.customer_id
	,COUNT(DISTINCT o.order_id) AS order_count
	,SUM(op.item_quantity*COALESCE(p.product_price,0) * 
		(1-COALESCE(op.position_discount,0)))									total_revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.customer_id
)
SELECT
    ROUND(
        COUNT(CASE WHEN order_count = 1 THEN customer_id END) * 100.0 / 
        COUNT(DISTINCT customer_id), 2)											one_time_customers_pct
    ,ROUND(
        SUM(CASE WHEN order_count = 1 THEN total_revenue END) * 100.0 / 
        SUM(total_revenue), 2) 													one_time_customers_revenue_pct
FROM customer_stats;

/*===================================================================================================
8️⃣ Month+1 Customer Retention Rate
🎯 Goal: Calculate next-month retention
🛠️ Stack: SQL

Query result snippet:

| month   	 | active_customers | retained_customers | retention_rate_pct |
|------------|------------------|--------------------|--------------------|
| 2018-01-01 | 		          3 | 				   0 | 					0 |
| 2018-02-01 |       		 32 | 		           3 | 				 9,38 |
| 2018-03-01 |       		 38 | 		           5 | 				13,16 |
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



