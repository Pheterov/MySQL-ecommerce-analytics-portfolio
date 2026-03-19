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
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))), 2) 										revenue
	,COUNT(DISTINCT op.order_id)																											orders_cnt
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
	EXTRACT(YEAR FROM o.order_date)																											year
	,o.delivery_state
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2) 																							revenue
	,COUNT(DISTINCT op.order_id)																											orders_cnt
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
	EXTRACT(YEAR FROM o.order_date)																											YEAR
	,EXTRACT(MONTH FROM o.order_date)																										MONTH
	,o.delivery_state
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2) 																							revenue
	,COUNT(DISTINCT op.order_id)																											orders_cnt
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
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2) 																							revenue
    ,COUNT(DISTINCT op.order_id)                                                                                      						orders_cnt
    ,COUNT(DISTINCT o.customer_id)                                                                          								unique_customers
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) /
    COUNT(DISTINCT o.order_id), 2)                                                                         									aov
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY year, month, o.delivery_state
ORDER BY year DESC,month DESC, revenue DESC;

/*===============================================================================================================================================================================================	
Query result snippet:

| year | month | delivery_state | revenue	 | orders_cnt | unique_customers | aov	  |
|------|-------|----------------|------------|------------|------------------|--------|
| 2022 |     1 | California     |  16 186,48 |         37 |               35 | 437,47 |
| 2021 |    12 | California     |  13 860,23 |         53 |               49 | 261,51 |
| 2021 |    11 | California     |  18 346,94 |         26 |               26 | 705,65 |
| 2021 |    10 | California     |  15 769,12 |         40 |               40 | 394,23 |
| 2021 |     9 | California     |  20 248,41 |         32 |               30 | 632,76 |

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
           COUNT(DISTINCT o.order_id), 2)                                                                         							aov
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
    ,LAG(aov) OVER(PARTITION BY delivery_state, month ORDER BY year)                                   										last_year_aov
FROM base_metrics
ORDER BY year DESC, month DESC;

/*================================================================================================================================================================================================
Query result snippet:

| delivery_state | year | month | current_year_revenue | last_year_revenue | orders_cnt | last_year_orders_cnt | unique_customers | last_year_unique_customers |   aov  | last_year_aov |
|----------------|------|-------|----------------------|-------------------|------------|----------------------|------------------|----------------------------|--------|---------------|
| California     | 2022 |     1 |          16 186,48   |        19 957,45  |         80 |                   71 |               35 |                         33 | 437,47 |       604,77  |
| California     | 2021 |    12 |          13 860,23   |        19 555,03  |         86 |                   82 |               49 |                         45 | 261,51 |       434,56  |
| California     | 2021 |    11 |          18 346,94   |         8 693,27  |         54 |                   52 |               26 |                         26 | 705,65 |       310,47  |
| California     | 2021 |    10 |          15 769,12   |        12 468,53  |         83 |                   65 |               40 |                         33 | 394,23 |       377,83  |
| California     | 2021 |     9 |          20 248,41   |        11 782,73  |         77 |                   40 |               30 |                         19 | 632,76 |       620,14  |

Notes & Reflections
Table became lengthy mainly because of column names, since for now it only serves a purpose for our own self,
we can make some adjustments for future calculations.Also we can define what's still useful and what can be dealt with.
I'm convinced that for now delivery_state is redundant, it's obvious which state we're focusing on.
Is amount of orders important to us or maybe we'd like to know how many customers contribute to the revenue ? Maybe both metrics carry much value to our report ?

Next step: column name adjustments, math calculations, choosing important metrics, deleting redundant columns 
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
4️⃣.1️⃣ YoY math calculations, column decision making, column names optimization
================================================================================================================================================================================================*/

WITH base_metrics AS 
(
SELECT
    EXTRACT(YEAR FROM o.order_date)                                                                         								year
    ,EXTRACT(MONTH FROM o.order_date)                                                                       								month
    ,o.delivery_state                                                                                        								delivery_state
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2) 																							revenue
    ,COUNT(DISTINCT op.order_id)                                                                                      						orders_cnt
    ,COUNT(DISTINCT o.customer_id)                                                                          								unique_customers
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) /
    COUNT(DISTINCT o.order_id), 2)                                                                         									aov
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY YEAR, MONTH, o.delivery_state
ORDER BY YEAR DESC, MONTH DESC, REVENUE DESC
)
SELECT
    year																																	
    ,month
    ,revenue                                                                                               									cyr_rev
    ,LAG(revenue) OVER(PARTITION BY delivery_state, month ORDER BY year)                                   									lyr_rev
        ,revenue - LAG(revenue) OVER(PARTITION BY delivery_state, month ORDER BY year)														rev_diff
    ,orders_cnt
    ,LAG(orders_cnt) OVER(PARTITION BY delivery_state, month ORDER BY year)                                   								lyr_o_cnt
    ,orders_cnt - LAG(orders_cnt) OVER(PARTITION BY delivery_state, month ORDER BY year)													ord_diff
    ,unique_customers 																														uniq_cstmr
    ,LAG(unique_customers) OVER(PARTITION BY delivery_state, month ORDER BY year)                                   						lyr_uniq
    ,unique_customers - LAG(unique_customers) OVER(PARTITION BY delivery_state, month ORDER BY year)										cstmr_diff
    ,ROUND(aov, 2)						 																									aov
    ,LAG(aov) OVER(PARTITION BY delivery_state, month ORDER BY year)																		lyr_aov
FROM base_metrics
ORDER BY year DESC, month DESC;

/*================================================================================================================================================================================================
Query result snippet:

| year | month | cyr_rev   | lyr_rev   | rev_diff  | orders_cnt | lyr_o_cnt | ord_diff | uniq_cstmr | lyr_uniq | cstmr_diff |   aov  | lyr_aov |
|------|-------|-----------|-----------|-----------|------------|-----------|----------|------------|----------|------------|--------|---------|
| 2022 |     1 | 16 186,48 | 19 957,45 | -3 770,97 |         37 |        33 |        4 |         35 |       33 |          2 | 437,47 | 	604,77 |
| 2021 |    12 | 13 860,23 | 19 555,03 | -5 694,80 |         53 |        45 |        8 |         49 |       45 |          4 | 261,51 | 	434,56 |
| 2021 |    11 | 18 346,94 |  8 693,27 |  9 653,67 |         26 |        28 |       -2 |         26 |       26 |          0 | 705,65 | 	310,47 |
| 2021 |    10 | 15 769,12 | 12 468,53 |  3 300,59 |         40 |        33 |        7 |         40 |       33 |          7 | 394,23 | 	377,83 |
| 2021 |     9 | 20 248,41 | 11 782,73 |  8 465,68 |         32 |        19 |       13 |         30 |       19 |         11 | 632,76 | 	620,14 |

This table is serving us in future calculations, we're not going to report it in it's current form. 
Now that we decided wchich metrics to use we can add some % based calculations, it will extend columns but it's essential for our future visual report.
Also November of 2021 repesents very interesting case. Equal amount of customers, less orders but revenue is doubled, would've been nice to
take a deeper look there.

Notes & Reflections
Currently everything we do is happening on a state-level granurality, as we keep on going we'll begin to examine smaller and smaller scale.

Next step: discount depth, percentage values, revenue and items sold comparison 


