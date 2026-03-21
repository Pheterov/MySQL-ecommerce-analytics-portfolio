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

Result is suspicious... immediately raises a red flag
Between 2018 - 2021 California was doing fantastic and then in 2022... sudden ~90% revenue drop.
Such a drastic change is highly unlikely from a business perspective.

THIS QUERY IS A CLASSIC EXAMPLE OF HOW MISLEADING CONCLUSIONS CAN ARISE FROM “just take the average” type of thinking.

📝What am I going to do next:
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
It's a good moment to step back and define what we actually want to measure and how we want to approach it:
	- including every variation of a metric can generate noise rather than insight
	- metrics should be logically consistent and easy to interpret — combining everything into a single table is not the right approach
	- the structure will evolve — adding and removing columns is a part of the analytical process
	- the goal is not to present the final answer immediately, but to clearly show the reasoning path that leads to it

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
    ,LAG(revenue) OVER(
		PARTITION BY month 
		ORDER BY year)                                   																					last_year_revenue
    ,orders_cnt
    ,LAG(orders_cnt) OVER(
		PARTITION BY month
		ORDER BY year)                                   																					last_year_orders_cnt
    ,unique_customers
    ,LAG(unique_customers) OVER(
		PARTITION BY month 
		ORDER BY year)																                                   						last_year_unique_customers
    ,AoV
    ,LAG(aov) OVER(
		PARTITION BY month
		ORDER BY year)                                   																					last_year_aov
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

📝 Notes & Reflections
   The table became quite wide, mainly due to verbose column names. Since it currently serves internal analytical purposes, we can simplify it in the next steps.
   We can also start evaluating which metrics are truly useful and which may be redundant. At this stage, `delivery_state` is no longer necessary, as the analysis is focused solely on California.

   Next step: Identify metrics that actually explain revenue dynamics.
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
4️⃣.1️⃣ YoY math calculations, column decision making, column names optimization, discount depth, revenue, code optimization
================================================================================================================================================================================================*/

WITH base_metrics AS (
SELECT
    EXTRACT(YEAR FROM o.order_date)																											year
    ,EXTRACT(MONTH FROM o.order_date)																										month
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
    	(1-COALESCE(op.position_discount,0))), 2)																							revenue
    ,COUNT(DISTINCT op.order_id)																											orders_cnt
    ,COUNT(DISTINCT o.customer_id)																											unique_customers
    ,SUM(op.item_quantity)																													items_sold
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
    	(1-COALESCE(op.position_discount,0))) /
    	NULLIF(COUNT(DISTINCT op.order_id),0),2)																							aov
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price, 0)*
		COALESCE(op.position_discount, 0)) /
    	NULLIF(SUM(op.item_quantity*COALESCE(p.product_price, 0)), 0) * 100, 2)																discount_depth
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY year, month
)
SELECT
    year
    ,month
    ,revenue																																cyr_rev
    ,LAG(revenue) OVER(
    	PARTITION BY MONTH
    	ORDER BY year)																														lyr_rev
    ,revenue - LAG(revenue) OVER(
    	PARTITION BY MONTH
    	ORDER BY year)																														rev_diff
    ,ROUND((revenue - LAG(revenue) OVER(
    	PARTITION BY MONTH
    	ORDER BY year)) /
    LAG(revenue) OVER(
    	PARTITION BY MONTH
    	ORDER BY year)*100.0, 2)																											rev_pct_diff
    ,orders_cnt																																orders_cnt
    ,LAG(orders_cnt) OVER(
    	PARTITION BY month 
    	ORDER BY year)																														lyr_o_cnt
    ,orders_cnt - LAG(orders_cnt) OVER(
    	PARTITION BY month 
    	ORDER BY year)																														ord_diff
    ,ROUND((orders_cnt - LAG(orders_cnt) OVER(
    	PARTITION BY month 
    	ORDER BY year)) /
    LAG(orders_cnt) OVER(
    	PARTITION BY month 
    	ORDER BY year)*100.0, 2)																											ord_pct_diff
    ,unique_customers																														uniq_cstmr
    ,LAG(unique_customers) OVER(
    	PARTITION BY month 
    	ORDER BY year)																														lyr_uniq
    ,unique_customers - LAG(unique_customers) OVER(
    	PARTITION BY MONTH
    	ORDER BY year)																														cstmr_diff
    ,ROUND((unique_customers - LAG(unique_customers) OVER(
    	PARTITION BY month 
    	ORDER BY year)) / 
    LAG(unique_customers) OVER(
    	PARTITION BY month 
    	ORDER BY year)*100.0, 2)																											cstmr_pct_diff
    ,items_sold																																items_sold
    ,LAG(items_sold) OVER(
    	PARTITION BY month 
    	ORDER BY year)																														lyr_items
    ,items_sold - LAG(items_sold) OVER(
    	PARTITION BY MONTH
    	ORDER BY year)																														items_diff
    ,ROUND((items_sold - LAG(items_sold) OVER(
    	PARTITION BY month 
    	ORDER BY year)) /
    LAG(items_sold) OVER(
    	PARTITION BY month 
    	ORDER BY year)*100.0, 2)																											items_pct_diff	
    ,ROUND(aov,2)																															aov
    ,LAG(aov) OVER(
    	PARTITION BY month 
    	ORDER BY year)																														lyr_aov
    ,ROUND(aov - LAG(aov) OVER(
    	PARTITION BY month 
    	ORDER BY year), 2)																													aov_change
    ,ROUND((aov - LAG(aov) OVER(
    	PARTITION BY month 
    	ORDER BY year)) /
    LAG(aov) OVER(
    	PARTITION BY month 
    	ORDER BY year)*100.0, 2)																											aov_pct_change
    ,discount_depth																															d_depth
    ,LAG(discount_depth) OVER(
    	PARTITION BY month 
    	ORDER BY year)																														lyr_d_depth
    ,discount_depth - LAG(discount_depth) OVER(
    	PARTITION BY MONTH
    	ORDER BY year)																														d_depth_diff
    ,ROUND((discount_depth- LAG(discount_depth) OVER(
    	PARTITION BY month 
    	ORDER BY year)) / 
    LAG(discount_depth) OVER(
    	PARTITION BY month 
    	ORDER BY year)*100.0, 2)																											d_depth_pct_change
FROM base_metrics
ORDER BY year DESC, month DESC;

/*================================================================================================================================================================================================
-- Our initial version of the code is not team-friendly, neither it'll be easy for us to understand what's going on there in a week. Let's fix that. 
================================================================================================================================================================================================*/

WITH base_metrics AS (
-- CTE 1: Monthly aggregation for California
-- Calculate revenue, orders, unique customers, items sold, AOV, discount depth
SELECT
    EXTRACT(YEAR FROM o.order_date)																											year
    ,EXTRACT(MONTH FROM o.order_date)																										month
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))),2)										revenue -- total revenue
    ,COUNT(DISTINCT op.order_id)																											orders_cnt -- total orders
    ,COUNT(DISTINCT o.customer_id)																											unique_customers -- unique customers
    ,SUM(op.item_quantity)																													items_sold -- total items sold
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0)))/
        NULLIF(COUNT(DISTINCT op.order_id),0),2)																							aov -- average order value
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*COALESCE(op.position_discount,0))/
        NULLIF(SUM(op.item_quantity*COALESCE(p.product_price,0)),0)*100,2)																	discount_depth -- average discount %
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY EXTRACT(YEAR FROM o.order_date),EXTRACT(MONTH FROM o.order_date)
),
materialized AS (
-- CTE 2: Materialize base_metrics to avoid alias resolution issues in LAG() ORDER BY
SELECT *
FROM base_metrics
),
yoy_metrics AS (
-- CTE 3: Year-over-Year comparison
-- Add previous year values for each month using window functions
SELECT
    year
    ,month
    ,revenue																																cyr_rev -- current year revenue
    ,LAG(revenue) OVER(PARTITION BY month ORDER BY year)																					lyr_rev -- last year revenue
    ,orders_cnt																																orders_cnt -- current year orders
    ,LAG(orders_cnt) OVER(PARTITION BY month ORDER BY year)																					lyr_o_cnt -- last year orders
    ,unique_customers																														uniq_cstmr -- current year customers
    ,LAG(unique_customers) OVER(PARTITION BY month ORDER BY year)																			lyr_uniq -- last year customers
    ,items_sold																																items_sold -- current year items
    ,LAG(items_sold) OVER(PARTITION BY month ORDER BY year)																					lyr_items -- last year items
    ,aov																																	aov -- current year AOV
    ,LAG(aov) OVER(PARTITION BY month ORDER BY year)																						lyr_aov -- last year AOV
    ,discount_depth																															d_depth -- current year discount depth
    ,LAG(discount_depth) OVER(PARTITION BY month ORDER BY year)																				lyr_d_depth -- last year discount depth
FROM materialized
)
SELECT
-- Final SELECT with all YoY differences and percentages
    year
    ,month
    ,cyr_rev
    ,lyr_rev
    ,cyr_rev - lyr_rev																														rev_diff -- revenue difference
    ,ROUND((cyr_rev - lyr_rev)/NULLIF(lyr_rev,0)*100,2)																						rev_pct_diff -- revenue % change
    ,orders_cnt
    ,lyr_o_cnt
    ,orders_cnt - lyr_o_cnt																													ord_diff -- orders difference
    ,ROUND((orders_cnt - lyr_o_cnt)/NULLIF(lyr_o_cnt,0)*100,2)																				ord_pct_diff -- orders % change
    ,uniq_cstmr
    ,lyr_uniq
    ,uniq_cstmr - lyr_uniq																													cstmr_diff -- customers difference
    ,ROUND((uniq_cstmr - lyr_uniq)/NULLIF(lyr_uniq,0)*100,2)																				cstmr_pct_diff -- customers % change
    ,items_sold
    ,lyr_items
    ,items_sold - lyr_items																													items_diff -- items difference
    ,ROUND((items_sold - lyr_items)/NULLIF(lyr_items,0)*100,2)																				items_pct_diff -- items % change
    ,aov
    ,lyr_aov
    ,aov - lyr_aov																															aov_change -- AOV difference
    ,ROUND((aov - lyr_aov)/NULLIF(lyr_aov,0)*100,2)																							aov_pct_change -- AOV % change
    ,d_depth
    ,lyr_d_depth
    ,d_depth - lyr_d_depth																													d_depth_diff -- discount difference
    ,ROUND((d_depth - lyr_d_depth)/NULLIF(lyr_d_depth,0)*100,2)																				d_depth_pct_change -- discount % change
FROM yoy_metrics
ORDER BY year DESC, month DESC;
/*================================================================================================================================================================================================
Query result snippet:

| year | month |   cyr_rev |   lyr_rev |   rev_diff | rev_pct_diff | orders_cnt | lyr_o_cnt | ord_diff | ord_pct_diff | uniq_cstmr | lyr_uniq | cstmr_diff | cstmr_pct_diff | items_sold | lyr_items | items_diff | items_pct_diff |    aov |  lyr_aov | aov_change | aov_pct_change | d_depth | lyr_d_depth | d_depth_diff | d_depth_pct_change |
|------|-------|-----------|-----------|------------|--------------|------------|-----------|----------|--------------|------------|----------|------------|----------------|------------|-----------|------------|----------------|--------|----------|------------|----------------|---------|-------------|--------------|--------------------|
| 2022 |     1 | 16 186,48 | 19 957,45 | -3 770,97  |       -18,90 |         37 |        33 |        4 |        12,12 |         35 |       33 |          2 |           6,06 |        300 |       327 |        -27 |          -8,26 | 437,47 |   604,77 |    -167,30 |         -27,66 |   13,73 |       15,21 |        -1,48 |              -9,73 |
| 2021 |    12 | 13 860,23 | 19 555,03 | -5 694,80  |       -29,12 |         53 |        45 |        8 |        17,78 |         49 |       45 |          4 |           8,89 |        336 |       312 |         24 |           7,69 | 261,51 |   434,56 |    -173,05 |         -39,82 |   12,32 |        8,93 |         3,39 |              37,96 |
| 2021 |    11 | 18 346,94 |  8 693,27 |  9 653,67  |       111,05 |         26 |        28 |       -2 |        -7,14 |         26 |       26 |          0 |           0,00 |        239 |       199 |         40 |          20,10 | 705,65 |   310,47 |     395,18 |         127,28 |   11,85 |        8,96 |         2,89 |              32,25 |
| 2021 |    10 | 15 769,12 | 12 468,53 |  3 300,59  |        26,47 |         40 |        33 |        7 |        21,21 |         40 |       33 |          7 |          21,21 |        329 |       230 |         99 |          43,04 | 394,23 |   377,83 |      16,40 |           4,34 |   13,95 |       11,29 |         2,66 |              23,56 |
| 2021 |     9 | 20 248,41 | 11 782,73 |  8 465,68  |        71,85 |         32 |        19 |       13 |        68,42 |         30 |       19 |         11 |          57,89 |        283 |       151 |        132 |          87,42 | 632,76 |   620,14 |      12,62 |           2,04 |   11,58 |       17,62 |        -6,04 |             -34,28 |



This table is serving us in future calculations, we're not going to report it in it's current form.

The number of columns may feel overwhelming at first glance. So why structure it this way when we have previously mentioned reducing amount for easier decision making rather than producing noise ?

Comparing a single metric often requires looking at multiple related values.
Because metrics without context are misleading - as we have presented in the very 1st query of this presentation.

A percentage change like -5% means very little on its own. Does it represent a drop from 1,000 customers to 950, or from 20 customers to 19?
The business impact in these two scenarios is completely different. The same applies to absolute values — losing 10 customers might be insignificant at scale, or critical if your baseline is small.

This table is intentionally designed to preserve that context. By showing current and previous state aswell with both absolute values and their changes (numeric and percentage),
we can properly assess the significance of each movement instead of reacting to isolated figures.

Of course, this is only part of the story.

From a business perspective, not all customers are equal. Losing one high-value, repeat customer may hurt far more than losing several low-value, one-time buyers.

This is exactly the direction we’ll explore next.

⭐ On a side note things worth noticing solely from this tiny snippet:

- In the case of September, the increase in revenue can be corellated with the growth in the customer base in comparison to the last year.
  +71% revenue +68% orders, +57% customers, nearly doubled items sold.This suggests that growth was volume-driven rather than changes in pricing or customer behavior.

- However, November 2021 presents a particularly interesting case.
  Equal amount of customers, slightly less orders but revenue is more than doubled +111%,strong candidate for deeper analysis.

💡 While November 2021 presents an interesting anomaly, it does not directly contribute to explaining California’s overall performance.
   It is therefore intentionally excluded from deeper analysis at this stage and marked as a potential follow-up investigation.

📝 Notes & Reflections
   Currently, all our activities are taking place at the state level, but as we move forward, we will begin to analyze them in greater detail.
   The answers are not in a plain sight, we have to constantly make decisions which columns to add or delete, adjust, change granularity.


/*================================================================================================================================================================================================

================================================================================================================================================================================================*/
