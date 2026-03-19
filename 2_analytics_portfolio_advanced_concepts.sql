   Project: E-commerce Analytics SQL Portfolio
🛠️ Database: supersales - modified by KajoData MySQL 8.0+
👤 Author: Piotr Rzepka
📝 Description: SQL e-commerce analytics portfolio

																					"The story of California's revenue" 

/*================================================================================================================================================================================================
1️⃣ Revenue and Order Count by Delivery State
================================================================================================================================================================================================*/
	   
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
Query result snippet:

| delivery_state | revenue    | orders_cnt  |
|----------------|------------|-------------|
| California 	 | 451 450,55 | 	  1 021 |
| New York		 | 312 376,98 | 		562 |
| Texas			 | 164 948,68 | 		487 |

This basic metric doesn't really tell us anything... Can we make an informed and profitable decision based on a report like this? 
We’ve only identified which region is the most profitable, but let’s dig a little deeper and try to figure out why, step by step.
What's next then ? Maybe it'd be nice to see performance over time.
================================================================================================================================================================================================*/


/*================================================================================================================================================================================================
2️⃣ YoY performance
================================================================================================================================================================================================*/

SELECT
	EXTRACT(YEAR FROM o.order_date)																					year
	,o.delivery_state
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))), 2) 				revenue
	,COUNT(DISTINCT op.order_id)																					orders_cnt
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state='California'
GROUP BY YEAR,o.delivery_state
ORDER BY year DESC

/*================================================================================================================================================================================================	
Query result snippet:

| year | delivery_state | revenue    | orders_cnt |
|------|----------------|------------|------------|
| 2022 | California     |  16 186,48 |         37 |
| 2021 | California     | 148 729,44 |        336 |
| 2020 | California     | 121 925,07 |        279 |
| 2019 | California     |  93 307,09 |        198 |
| 2018 | California     |  71 302,47 |        171 |

Result is suspicious... immediately raises a red flag.
Between 2018 - 2021 California was doing fantastic and then in 2022... sudden ~90% revenue drop.
Such a drastic change is highly unlikely from a business perspective.

This query is a classic example of how misleading conclusions can arise from “just take the average” type of thinking.

What am I going to do next:
- validate data completeness and add months column to the result
- double-check aggregation logic
- adjust filtering to compare with other regions
=================================================================================================================================================================================================*/

/*=================================================================================================================================================================================================
2️⃣.1️⃣ examinig a YoY red flag 
=================================================================================================================================================================================================*/
	
SELECT
	EXTRACT(YEAR FROM o.order_date)																					YEAR
	,EXTRACT(MONTH FROM o.order_date)																				MONTH
	,o.delivery_state
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))), 2) 				revenue
	,COUNT(DISTINCT op.order_id)																					orders_cnt
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2022
GROUP BY YEAR,MONTH,o.delivery_state
ORDER BY YEAR DESC,MONTH DESC, revenue DESC;

/*=================================================================================================================================================================================================
Query result snippet:

| year | month | delivery_state | revenue    | orders_cnt |
|------|-------|----------------|------------|------------|
| 2022 | 1     | California     | 16 186,48  |         37 |
| 2022 | 1     | New York       |  5 757,49  |         19 |
| 2022 | 1     | Kentucky       |  4 113,58  |          4 |
| 2022 | 1     | Illinois       |  3 730,73  |         10 |
| 2022 | 1     | Michigan       |  3 663,71  |          5 |

As expected the data confirms that 2022 currently includes only January.
This explains the apparent YoY revenue drop and indicates that the issue is related to data completeness rather than actual business performance.
We can continue our work focusing on California.
================================================================================================================================================================================================*/

/*===============================================================================================================================================================================================
3️⃣ California's MoM performance - basic insight
================================================================================================================================================================================================*/

SELECT
    EXTRACT(YEAR FROM o.order_date)                                                                         								year
    ,EXTRACT(MONTH FROM o.order_date)                                                                       								month
    ,o.delivery_state                                                                                        								delivery_state
    ,ROUND(SUM(op.item_quantity * COALESCE(p.product_price,0) * (1 - COALESCE(op.position_discount,0))), 2) 								revenue
    ,COUNT(op.order_id)                                                                                      								orders_cnt
    ,COUNT(DISTINCT o.customer_id)                                                                          								unique_customers
    ,ROUND(SUM(op.item_quantity * COALESCE(p.product_price,0) * (1 - COALESCE(op.position_discount,0))) /
           COUNT(o.customer_id), 2)                                                                         								AoV
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY year, month, o.delivery_state
ORDER BY year DESC,month DESC, revenue DESC;

/*===============================================================================================================================================================================================	
Query result snippet:

| year | month | delivery_state |     revenue | orders_cnt | unique_customers |       AoV |
|------|-------|----------------|------------|-------------|------------------|-----------|
| 2022 |     1 | California     |  16 186,48 |          80 |               35 |    202,33 |
| 2021 |    12 | California     |  13 860,23 |          86 |               49 |    161,17 |
| 2021 |    11 | California     |  18 346,94 |          54 |               26 |    339,76 |
| 2021 |    10 | California     |  15 769,12 |          83 |               40 |    189,99 |
| 2021 |     9 | California     |  20 248,41 |          77 |               30 |    262,97 |

We used month-over-month trends to confirm there is a complete data for every prior month. 
It's a good moment to decide what we'd love to calculate and clarify the approach:
	- including every variation of a metric can generate noise rather than insight
	- the data must make logical sense, mixing every important metric into one table is definitely not what we want

Next step: YoY metrics
================================================================================================================================================================================================*/

/*===============================================================================================================================================================================================
4️⃣ YoY insight
================================================================================================================================================================================================*/

WITH base_metrics AS 
(
SELECT
    EXTRACT(YEAR FROM o.order_date)                                                                         								year
    ,EXTRACT(MONTH FROM o.order_date)                                                                       								month
    ,o.delivery_state                                                                                        								delivery_state
    ,ROUND(SUM(op.item_quantity * COALESCE(p.product_price,0) * (1 - COALESCE(op.position_discount,0))), 2) 								revenue
    ,COUNT(op.order_id)                                                                                      								orders_cnt
    ,COUNT(DISTINCT o.customer_id)                                                                          								unique_customers
    ,ROUND(SUM(op.item_quantity * COALESCE(p.product_price,0) * (1 - COALESCE(op.position_discount,0))) /
           COUNT(o.customer_id), 2)                                                                         								AoV
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY YEAR, MONTH, o.delivery_state
ORDER BY YEAR DESC, MONTH DESC, REVENUE DESC
)
SELECT
	delivery_state
    ,year
    ,month
    ,revenue                                                                                               									current_year_revenue
    ,LAG(revenue) OVER(PARTITION BY delivery_state, month ORDER BY year)                                   									last_year_revenue
    ,orders_cnt
    ,LAG(orders_cnt) OVER(PARTITION BY delivery_state, month ORDER BY year)                                   								last_year_orders_cnt
    ,unique_customers
    ,LAG(unique_customers) OVER(PARTITION BY delivery_state, month ORDER BY year)                                   						last_year_unique_customers
    ,AoV
    ,LAG(AoV) OVER(PARTITION BY delivery_state, month ORDER BY year)                                   										last_year_AoV
FROM base_metrics
ORDER BY year DESC, month DESC;

/*================================================================================================================================================================================================
Query result snippet:

| delivery_state | year | month | current_year_revenue | last_year_revenue | orders_cnt | last_year_orders_cnt | unique_customers | last_year_unique_customers | AoV     | last_year_AoV |
|----------------|------|-------|----------------------|-------------------|------------|----------------------|------------------|----------------------------|---------|---------------|
| California     | 2022 |     1 |            16 186,48 |         19 957,45 |         80 |                   71 |               35 |                         33 |  202,33 |        281,09 |
| California     | 2021 |    12 |            13 860,23 |         19 555,03 |         86 |                   82 |               49 |                         45 |  161,17 |        238,48 |
| California     | 2021 |    11 |            18 346,94 |          8 693,27 |         54 |                   52 |               26 |                         26 |  339,76 |        167,18 |
| California     | 2021 |    10 |            15 769,12 |         12 468,53 |         83 |                   65 |               40 |                         33 |  189,99 |        191,82 |
| California     | 2021 |     9 |            20 248,41 |         11 782,73 |         77 |                   40 |               30 |                         19 |  262,97 |        294,57 |

Notes & Reflections
Table became lengthy mainly because of column names, since for now it only serves a purpose for our own self,
we can make some adjustments for future calculations.Also we can define what's still useful and what can be dealt with.
I'm convinced that for now delivery_state is redundant, it's obvious which state we're focusing on.
Is amount of orders important to us or maybe we'd like to know how many customers contribute to the revenue ? Maybe both metrics carry much value to our report ?

Next step: column quantity and name adjustments, math calculations, choosing important metrics 
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
2️⃣YoY performance

🛠️ Stac: SQL

Query result snippet:

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

Query result snippet:

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

Query result snippet:

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

Query result snippet:

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
	o.delivery_city																									delivery_city
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
			THEN o.customer_id 
		END) 																										unique_customers_2019
	,COUNT(DISTINCT CASE
			WHEN EXTRACT(YEAR FROM o.order_date) = 2018 
			THEN o.customer_id 
		END) 																										unique_customers_2018
	,SUM(CASE
			WHEN EXTRACT(YEAR FROM o.order_date) = 2019 
			THEN op.item_quantity*COALESCE(p.product_price, 0)*
				(1-COALESCE(op.position_discount,0))
			ELSE 0
		END) * 1.0 / 
		NULLIF(
			COUNT(DISTINCT CASE
					WHEN EXTRACT(YEAR FROM o.order_date) = 2019 
					THEN o.order_id
		END),0) 																									avg_order_value_2019
	,SUM(CASE
			WHEN EXTRACT(YEAR FROM o.order_date) = 2018 
			THEN op.item_quantity*COALESCE(p.product_price, 0)*
				(1-COALESCE(op.position_discount,0))
			ELSE 0
		END) * 1.0 / 
		NULLIF(
			COUNT(DISTINCT CASE
					WHEN EXTRACT(YEAR FROM o.order_date) = 2018 
					THEN o.order_id
		END),0) 																									avg_order_value_2018
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
	,ROUND(avg_order_value_2019, 2)																					avg_order_value_2019
	,ROUND(avg_order_value_2018, 2)																					avg_order_value_2018
	,ROUND(avg_order_value_2019 - avg_order_value_2018, 2)															avg_order_value_diff
	,ROUND((avg_order_value_2019 - avg_order_value_2018) /
		NULLIF(avg_order_value_2018, 0)*100.0, 2)																	avg_order_value_pct_diff
FROM local_sales
ORDER BY revenue_2019 DESC;

/*===================================================================================================
5️⃣ Top 2 Products by Revenue within Each Category
🎯 Goal: Identify best-performing products per category
🛠️ Stack: SQL
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
