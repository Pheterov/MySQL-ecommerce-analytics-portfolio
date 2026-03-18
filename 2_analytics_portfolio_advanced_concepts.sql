#####################################################################################################
# 🎯 Project: E-commerce Analytics SQL Portfolio
# 🛠️ Database: supersales - modified by KajoData MySQL 8.0+
# 👤 Author: Piotr Rzepka
# 📝 Description: Full-stack SQL-driven e-commerce analytics portfolio
# 🔍 Focus: customer retention, revenue analysis, product & category performance
#####################################################################################################

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
1️⃣ Revenue and Order Count by Delivery State
🎯 Goal: Measure regional sales performance
🛠️ Stack: SQL
💡 Impact: Identifies high-performing regions for targeted marketing
📊 Example KPI:
| delivery_state | revenue    | orders_cnt  |
|----------------|------------|-------------|
| California 	 | 451 450,55 | 	  1 021 |
| New York		 | 312 376,98 | 		562 |
| Texas			 | 164 948,68 | 		487 |
=====================================================================================================*/
SELECT
	o.delivery_state
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))), 2) 				revenue
	,COUNT(DISTINCT op.order_id)																					orders_cnt
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.delivery_state
ORDER BY revenue DESC;

/*================================================================================================================================================================================================
🎯 Goal: Show difference between baseline metric vs enhanced insight.
		 Benchmark delivery_state across revenue, customer value and purchasing behavior to support
		 data-driven regional prioritization.

🛠️ Stack: SQL

💡 Business Impact:
- Identifies top-performing states for targeted marketing and budget allocation
- Highlights underperforming regions requiring pricing, operational or acquisition improvements
- Differentiates volume-driven vs value-driven markets for better strategic focus

🔍 Key Insights:
- Use revenue_rank and revenue_share_pct to identify core markets and assess business dependency
- Compare AOV, revenue_per_customer and purchase_frequency to distinguish high-value vs high-volume states
- States with high value metrics but low revenue share signal underpenetrated growth opportunities,
  while high volume with low value may require upsell or margin optimization

📊 Example KPI:
| delivery_state | revenue    | orders_cnt  | unique_customers | AoV 	 | revenue_per_customer | total_items_sold | avg_items_per_order | purchase_frequency | revenue_share_pct | revenue_rank |
|----------------|------------|-------------|------------------|---------|----------------------|------------------|---------------------|--------------------|-------------------|--------------|
| California 	 | 451 450,55 | 	  1 021 |			   577 |  442,17 |				 782,41 |			 7 667 |				7,51 |				 1,77 |				19,90 |			   1 |
| New York	 	 | 312 376,98 | 	  	562 |			   415 |  555,83 |				 752,72 |			 4 224 |				7,52 |				 1,35 |				13,77 |			   2 |
| Texas		 	 | 164 948,68 | 	  	487 |			   370 |  338,70 |				 445,81 |			 3 724 |				7,65 |				 1,32 |				 7,27 |			   3 |
==================================================================================================================================================================================================*/

WITH state_metrics AS
(
SELECT
    o.delivery_state
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2)      																revenue
    ,COUNT(DISTINCT op.order_id)                                                                                  	orders_cnt
    ,COUNT(DISTINCT o.customer_id)                                                                                	unique_customers
    ,SUM(op.item_quantity)                                                                                        	total_items_sold
    ,ROUND(SUM(op.item_quantity) * 1.0 / 
		COUNT(DISTINCT op.order_id), 2)                                           									avg_items_per_order
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.delivery_state
), calculations AS
(
SELECT
    delivery_state
    ,revenue
    ,orders_cnt
    ,unique_customers
    ,ROUND(revenue / orders_cnt, 2)                                                                                	AoV
    ,ROUND(revenue / unique_customers, 2)                                                                          	revenue_per_customer
    ,total_items_sold
    ,avg_items_per_order
    ,ROUND(orders_cnt * 1.0 / unique_customers, 2)                                                                 	purchase_frequency
    ,ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)                                                               revenue_share_pct
    ,RANK() OVER (ORDER BY revenue DESC)                                                                            revenue_rank
FROM state_metrics
)
SELECT
	delivery_state
	,revenue
	,orders_cnt
	,unique_customers
	,AoV
	,revenue_per_customer
	,total_items_sold
	,avg_items_per_order
	,purchase_frequency
	,revenue_share_pct
	,revenue_rank
FROM calculations
ORDER BY revenue DESC;

/* Using 2 CTEs separates base aggregations from derived metrics,
   improving readability and maintainability */

/*===================================================================================================
2️⃣ Top 5 Cities by Units Sold
🎯 Goal: Identify high-volume cities for logistics optimization
🛠️ Stack: SQL
💡 Impact: Prioritizes warehouse locations and delivery routes
📊 Example KPI:
| ranking | delivery_city | items_sold  |
|---------|---------------|-------------|
|  	    1 | New York City | 	  3 417 |
| 		2 |	Los Angeles   | 	  2 879 |
|		3 | Philadelphia  | 	  1 981 |
====================================================================================================*/
WITH city_sales AS
(
SELECT
	o.delivery_city
	,SUM(op.item_quantity) 																							items_sold
	,DENSE_RANK() OVER(
		ORDER BY SUM(op.item_quantity) DESC)																		ranking
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
GROUP BY o.delivery_city
)
SELECT
	ranking
	,delivery_city
	,items_sold
FROM city_sales
WHERE ranking <= 5;

/*==============================================================================================================
🎯 Goal: Show difference between baseline metric vs enhanced insight.
		  Benchmarks delivery_city performance by shifting focus
		  from unit volume to revenue quality and pricing health.

🛠️ Stack: SQL

💡 Business Impact:
Ensures investment in logistics and marketing targets high-value markets
that contribute sustainably to the bottom line.Reduces profit leakage
by identifying regions where volume dominance relies excessively on price concessions.

🔍 Key Insights:
Misalignment between item_ranking and revenue_ranking reveals
markets generating low monetary yield despite high transaction counts.
An elevated avg_discount_depth_pct signals aggressive pricing tactics required
to maintain sales activity in specific territories.

📊 Example KPI:
|revenue_ranking | items_ranking | delivery_city | total_revenue | items_sold | AoV	   | avg_disctount_depth_pct |
|----------------|---------------|---------------|---------------|------------|--------|-------------------------|
| 			   1 |			   1 | New York City |	  258 988,76 |		3 417 |	575.53 |					8.97 |
|			   2 |			   2 | Los Angeles	 |	  173 235,36 |		2 879 |	451.13 |				   12.82 |
|			   3 |			   5 | Seattle		 |	  119 720,46 |		1 590 |	564.72 |					7.97 |
|			   4 |			   4 | San Francisco |	  111 361,31 |		1 935 |	420.23 |				   12.33 |
|			   5 |			   3 | Philadelphia	 |	  105 241,09 |		1 981 |	397.14 |					36.4 |
================================================================================================================*/

WITH city_metrics AS
(
SELECT
	o.delivery_city
	,SUM(op.item_quantity) 																							items_sold
	,RANK() OVER (
		ORDER BY SUM(op.item_quantity) DESC)																		items_ranking
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2)																	total_revenue
	,ROUND(
		ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
			(1-COALESCE(op.position_discount,0))), 2) / 
		COUNT(DISTINCT o.order_id), 2)																				AoV
	,ROUND(
		SUM(op.item_quantity*COALESCE(p.product_price,0)*
			COALESCE(op.position_discount,0)) / 
		SUM(op.item_quantity*COALESCE(p.product_price,0))*100.0, 2)													avg_discount_depth_pct
	,DENSE_RANK() OVER(
		ORDER BY SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) DESC)																	revenue_ranking
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.delivery_city
)
SELECT
	revenue_ranking
	,items_ranking
	,delivery_city
	,total_revenue
	,items_sold
	,AoV
	,avg_discount_depth_pct
FROM city_metrics
WHERE revenue_ranking <= 5
ORDER BY revenue_ranking;

/*===================================================================================================
3️⃣ Running Total Revenue per Customer
🎯 Goal: Track cumulative customer spending over time
🛠️ Stack: SQL
💡 Impact: Identifies high-value customers for retention programs
====================================================================================================*/
WITH customer_orders AS
(
SELECT
	o.customer_id
	,o.order_id
	,o.order_date
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) 																		revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.customer_id, o.order_id, o.order_date
)
SELECT
	customer_id
	,order_date
	,ROUND(
		SUM(revenue) OVER (
		PARTITION BY customer_id
ORDER BY order_date, order_id), 2)																	 				running_total_revenue
FROM customer_orders
ORDER BY customer_id, order_date, order_id;

/*===================================================================================================
4️⃣ Year-over-Year revenue change
🎯 Goal: Measure revenue trends
🛠️ Stack: SQL
💡 Impact: Serves as a starting point for diagnosing drivers
====================================================================================================*/
WITH yearly_metrics AS
(
SELECT
	EXTRACT(YEAR FROM o.order_date)						 															year
	,COUNT(DISTINCT op.order_id) 																					orders_cnt
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) 																		revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY year
)
SELECT
	year
	,ROUND(revenue, 2)																								revenue
	,ROUND(
		(revenue - LAG(revenue) OVER (ORDER BY year)) * 100.0 /
		NULLIF(LAG(revenue) OVER (ORDER BY year),0), 2) 															revenue_pct_change_vs_previous_year
FROM yearly_metrics
ORDER BY year;

/*=========================================================================================================================================================================================================================================================
🎯 Goal: Show difference between baseline metric vs enhanced insight.
		  Evaluate city-level performance by comparing year-over-year changes in revenue, customer base, and order value.
		  Identify whether growth is driven by customer expansion, higher spending per order, or both.

🛠️ Stack: SQL

💡 Business Impact:
Enables more precise allocation of marketing and expansion budgets by distinguishing
between cities growing through customer acquisition versus higher monetization.
Highlights markets where revenue growth may be unsustainable
due to declining order value or shrinking customer base.Supports strategic decisions
on whether to prioritize scaling demand or improving revenue quality in specific regions.

🔍 Key Insights:
Strong growth markets (e.g. New York City, Los Angeles) are driven
by both increasing customer base and rising average order value, indicating healthy and scalable expansion.
Some cities (e.g. San Diego) show rapid growth primarily fueled by higher order value, 
suggesting potential pricing or basket-size optimization effects.Declining markets (e.g. San Francisco)
exhibit simultaneous drops in revenue, customers, and AOV, signaling structural demand issues rather than temporary fluctuations.
Mixed-signal cities (e.g. Philadelphia) reveal customer growth alongside decreasing AOV,
which may indicate reliance on discounts or lower-value transactions to drive volume.

📊 Example KPI:
| revenue_share_pct | delivery_city  | revenue_2019 | revenue_2018 | revenue_growth_pct | unique_customers_2019 | unique_customers_2018 | customers_diff | avg_order_value_2019 | avg_order_value_2018 | avg_order_value_diff | avg_order_value_pct_diff |
|-------------------|----------------|--------------|--------------|--------------------|-----------------------|-----------------------|----------------|----------------------|----------------------|----------------------|--------------------------|
|             15,83 | New York City  |    74 849,79 |    35 206,02 |          	 112.61 |                    98 |                    67 |             31 |               741.09 |               525,46 |      	       215,63 |               	   41,04 |
|              8,32 | Los Angeles    |    39 355,24 |    21 941,66 |           	  79.36 |                    74 |                    58 |             16 |               491.94 |               371,89 |               120,05 |                	   32,28 |
|              4,53 | Seattle        |    21 427,00 |    22 847,99 |           	  -6.22 |                    38 |                    35 |              3 |               549.41 |               634,67 |        	   -85,26 |                	  -13,43 |
|              4,09 | Philadelphia   |    19 322,31 |    14 663,35 |           	  31.77 |                    60 |                    42 |             18 |               316.76 |               349,13 |           	   -32,37 |               	   -9,27 |
|              3,35 | San Francisco  |    15 855,28 |    28 143,73 |          	 -43.66 |                    37 |                    53 |            -16 |               406.55 |               521,18 |       	   	  -114,63 |                   -21,99 |

==========================================================================================================================================================================================================================================================*/

WITH local_sales AS
(
SELECT
	o.delivery_city                                																	delivery_city
	,SUM(CASE 
			WHEN EXTRACT(YEAR FROM o.order_date) = 2019 
			THEN op.item_quantity*COALESCE(p.product_price, 0)*
				(1-COALESCE(op.position_discount, 0))
			ELSE 0
		END) 																										revenue_2019
	,SUM(CASE 
			WHEN EXTRACT(YEAR FROM o.order_date) = 2018 
			THEN op.item_quantity*COALESCE(p.product_price, 0)*
				(1-COALESCE(op.position_discount, 0))
			ELSE 0
		END) 										 																revenue_2018
	,COUNT(DISTINCT CASE
		WHEN EXTRACT(YEAR FROM o.order_date) = 2019 
		THEN o.order_id
		END) 																										orders_cnt_2019
	,ROUND(SUM(CASE
		WHEN EXTRACT(YEAR FROM o.order_date) = 2019 
		THEN op.item_quantity*COALESCE(p.product_price, 0)*
			(1-COALESCE(op.position_discount,0))
		ELSE 0
		END) * 1.0 / 
		NULLIF(
			COUNT(DISTINCT CASE
					WHEN EXTRACT(YEAR FROM o.order_date) = 2019 
					THEN o.order_id
		END),0), 2) 																								avg_order_value_2019
	,ROUND(SUM(CASE
		WHEN EXTRACT(YEAR FROM o.order_date) = 2018 
		THEN op.item_quantity*COALESCE(p.product_price, 0)*
			(1-COALESCE(op.position_discount,0))
		ELSE 0
		END) * 1.0 / 
		NULLIF(
			COUNT(DISTINCT CASE
					WHEN EXTRACT(YEAR FROM o.order_date) = 2018 
					THEN o.order_id
		END),0), 2) 																								avg_order_value_2018
	,COUNT(DISTINCT CASE
			WHEN EXTRACT(YEAR FROM o.order_date) = 2019 
			THEN o.customer_id 
		END) 																										unique_customers_2019
	,COUNT(DISTINCT CASE
			WHEN EXTRACT(YEAR FROM o.order_date) = 2018 
			THEN o.customer_id 
		END) 																										unique_customers_2018
FROM order_positions op
JOIN orders o ON op.order_id = o.order_id
JOIN products p ON op.product_id = p.product_id
WHERE EXTRACT(YEAR FROM o.order_date) IN (2018, 2019)
GROUP BY o.delivery_city
)
SELECT
	ROUND(revenue_2019 * 100.0 /
		SUM(revenue_2019) OVER (), 2) 																				revenue_share_pct
	,delivery_city
	,ROUND(revenue_2019, 2)																							revenue_2019
	,ROUND(revenue_2018, 2)																							revenue_2018
	,ROUND((revenue_2019 - revenue_2018) * 100.0 / 
		NULLIF(revenue_2018,0), 2) 																					revenue_growth_pct	
	,unique_customers_2019
	,unique_customers_2018
	,unique_customers_2019 - unique_customers_2018																	customers_diff
	,avg_order_value_2019
	,avg_order_value_2018
	,avg_order_value_2019 - avg_order_value_2018																	avg_order_value_diff
	,ROUND((avg_order_value_2019 - avg_order_value_2018) /
		avg_order_value_2018*100.0, 2)																				avg_order_value_pct_diff
FROM local_sales
ORDER BY revenue_2019 DESC;

/*===================================================================================================
5️⃣ Top 2 Products by Revenue within Each Category
🎯 Goal: Identify best-performing products per category
🛠️ Stack: SQL
💡 Impact: Guides product placement and promotion strategies
====================================================================================================*/
WITH products_grouped AS
(
SELECT
	pg.category
	,op.product_id
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*
	(1-COALESCE(op.position_discount,0))) 																			revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
JOIN product_groups pg ON p.group_id = pg.group_id
GROUP BY pg.category, op.product_id
), products_ranking AS
(
SELECT
	category
	,product_id
	,ROUND(revenue, 2)																								revenue
	,DENSE_RANK() OVER (
	PARTITION BY category
ORDER BY revenue DESC) 																								ranking
FROM products_grouped
)
SELECT
	category
	,product_id
	,revenue
	,ranking
FROM products_ranking
WHERE ranking <= 2
ORDER BY category, ranking, revenue DESC;

/*===================================================================================================
6️⃣ Customers Spending More Than in Previous Month
🎯 Goal: Identify customers with increasing spend patterns
🛠️ Stack: SQL
💡 Impact: Targets customers for upsell opportunities
====================================================================================================*/
WITH customer_monthly_spending AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 																			month
	,o.customer_id
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))) 						revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month, o.customer_id
), spending_with_prev AS
(
SELECT
	customer_id
	,month
	,revenue
	,LAG(month) OVER (
	PARTITION BY customer_id
	ORDER BY month) 																								prev_month
	,LAG(revenue) OVER (
	PARTITION BY customer_id
	ORDER BY month) 																								prev_month_revenue
FROM customer_monthly_spending
)
SELECT
	customer_id
	,month
	,ROUND(revenue, 2) 																								current_month_revenue
	,ROUND(prev_month_revenue, 2) prev_month_revenue
FROM spending_with_prev
WHERE prev_month = DATE_SUB(month, INTERVAL 1 MONTH) AND
	revenue > prev_month_revenue
ORDER BY customer_id, month;

/*===================================================================================================
7️⃣ Month+1 Purchase Return Rate
🎯 Goal: Measure customer retention month-over-month
🛠️ Stack: SQL
💡 Impact: Evaluates loyalty program effectiveness
====================================================================================================*/
WITH customers_month AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') month
	,o.customer_id
FROM orders o
GROUP BY month, o.customer_id
), order_next AS
(
SELECT
	month
	,customer_id
	,LEAD(month) OVER (
	PARTITION BY customer_id 
	ORDER BY month) 																								next_order
,DATE_ADD(month, INTERVAL 1 MONTH) 																					next_month
FROM customers_month
)
SELECT
	month
	,COUNT(customer_id) monthly_customers
	,COUNT(CASE
		WHEN next_order = next_month
		THEN customer_id
	END) 																											bought_next_month
	,ROUND(COUNT(CASE
		WHEN next_order = next_month
		THEN customer_id
	END) * 100.0 /
	COUNT(customer_id), 2) 																							next_month_buyers_pct
FROM order_next
GROUP BY month
ORDER BY month;

/*===================================================================================================
8️⃣ Discount Effectiveness Analysis
🎯 Goal: Evaluate impact of discounts on order value
🛠️ Stack: SQL
💡 Impact: Informs discount strategy optimization
====================================================================================================*/
WITH position_values AS
(
SELECT
	op.order_id
	,op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0)) 																		position_value
	,(op.item_quantity*COALESCE(p.product_price,0)) -
		(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) 																		discount_value
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
), order_flags AS
(
SELECT
	order_id
	,SUM(position_value) 																							order_value
	,SUM(discount_value) 																							total_discount_value
	,CASE
		WHEN SUM(discount_value) > 0
		THEN 1
		ELSE 0
	END																												discounted_order
FROM position_values
GROUP BY order_id
)
SELECT
	ROUND(AVG(CASE
		WHEN discounted_order = 1
		THEN order_value
	END), 2) 																										avg_discounted_order_value
	,ROUND(AVG(CASE
		WHEN discounted_order = 0
		THEN order_value
	END), 2) 																										avg_non_discounted_order_value
	,ROUND(AVG(CASE
		WHEN discounted_order = 1
		THEN order_value 
	END) -
	AVG(CASE
	WHEN discounted_order = 0
	THEN order_value 
	END), 2) 																										avg_order_value_diff
FROM order_flags;

/*===================================================================================================
9️⃣ Customer Value Segmentation with NTILE
🎯 Goal: Segment customers by lifetime value
🛠️ Stack: SQL
💡 Impact: Enables targeted marketing strategies
====================================================================================================*/
WITH customer_revenue_totals AS
(
SELECT
	o.customer_id
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) 																		revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.customer_id
), customer_segments AS
(
SELECT
	customer_id
	,revenue
	,NTILE(5) OVER (
		ORDER BY revenue DESC) 																						percentile_group
FROM customer_revenue_totals
), customer_segment_revenue AS
(
SELECT
	customer_id
	,revenue
	,CASE
		WHEN percentile_group = 1
		THEN 'High Value'
		WHEN percentile_group = 2
		THEN 'Medium Value'
		ELSE 'Low Value'
	END 																											segment
FROM customer_segments
)
SELECT
	segment
	,ROUND(SUM(revenue), 2) 																						segment_revenue
FROM customer_segment_revenue
GROUP BY segment
ORDER BY segment_revenue DESC;
