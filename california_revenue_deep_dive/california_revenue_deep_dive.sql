Project: E-commerce Analytics SQL Portfolio
🛠️ Database: supersales - modified by KajoData MySQL 8.0+
👤 Author: Piotr Rzepka
📝 Description: SQL e-commerce analytics portfolio

																					"The story of California's revenue" 

/*
SQL analysis of 2018–2022 e-commerce data reveals that California leads in total revenue,
but since 2021 its growth has been driven primarily by low-value customer acquisition.
This shift reduced retention potential and puts future revenue stability at risk.
*/
	
/*================================================================================================================================================================================================
1️⃣ Revenue and Order Count by Delivery State
================================================================================================================================================================================================*/
	   
SELECT
	o.delivery_state
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2) 																							revenue
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
We've only identified which region is the most profitable, but let's dig a little deeper and try to figure out why, step by step.
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
ORDER BY year DESC;

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

THIS QUERY IS A CLASSIC EXAMPLE OF HOW MISLEADING CONCLUSIONS CAN ARISE FROM "just take the average" type of thinking.

📝What am I going to do next:
- validate data completeness and add months column to the result
- double-check aggregation logic
- adjust filtering to compare with other regions
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
2️⃣.1️⃣ Examining a YoY red flag
================================================================================================================================================================================================*/
	
SELECT
	EXTRACT(YEAR FROM o.order_date)																											year
	,EXTRACT(MONTH FROM o.order_date)																										month
	,o.delivery_state
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2) 																							revenue
	,COUNT(DISTINCT op.order_id)																											orders_cnt
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2022
GROUP BY year,month,o.delivery_state
ORDER BY year DESC,month DESC, revenue DESC;

/*================================================================================================================================================================================================
Query result snippet:

| year | month | delivery_state | revenue    | orders_cnt |
|------|-------|----------------|------------|------------|
| 2022 |     1 | California     | 16 186,48  |         37 |
| 2022 |     1 | New York       |  5 757,49  |         19 |
| 2022 |     1 | Kentucky       |  4 113,58  |          4 |
| 2022 |     1 | Illinois       |  3 730,73  |         10 |
| 2022 |     1 | Michigan       |  3 663,71  |          5 |

As expected the data confirms that 2022 currently includes only January.
This explains the apparent YoY revenue drop and indicates that the issue is related to data completeness rather than actual business performance.
We can continue our work focusing on California.
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
3️⃣ California's MoM performance - basic insight
================================================================================================================================================================================================*/

SELECT
    EXTRACT(YEAR FROM o.order_date)                                                                         								year
    ,EXTRACT(MONTH FROM o.order_date)                                                                       								month
    ,o.delivery_state                                                                                        								delivery_state
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))), 2) 																							revenue
    ,COUNT(DISTINCT op.order_id)                                                                            							    orders_cnt
    ,COUNT(DISTINCT o.customer_id)                                                                          								unique_customers
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) /
    COUNT(DISTINCT o.order_id), 2)                                                                         									aov
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY year, month, o.delivery_state
-- Note: o.delivery_state is intentionally included in GROUP BY to support
-- potential multi-state extension of this query in future analysis steps
ORDER BY year DESC, month DESC, revenue DESC;

/*================================================================================================================================================================================================
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

/*================================================================================================================================================================================================
4️⃣ YoY insight
================================================================================================================================================================================================*/

WITH base_metrics AS 
(
SELECT
    EXTRACT(YEAR FROM o.order_date)                                                                         								year
    ,EXTRACT(MONTH FROM o.order_date)                                                                       								month
    ,o.delivery_state                                                                                        								delivery_state
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1 - COALESCE(op.position_discount,0))), 2) 																						revenue
    ,COUNT(op.order_id)                                                                                      								orders_cnt
    ,COUNT(DISTINCT o.customer_id)                                                                          								unique_customers
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) /
           COUNT(DISTINCT o.order_id), 2)                                                                   								aov
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY year, month, o.delivery_state
ORDER BY year DESC, month DESC, revenue DESC
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
    ,aov
    ,LAG(aov) OVER(
		PARTITION BY month
		ORDER BY year)                                   																					last_year_aov
FROM base_metrics
ORDER BY year DESC, month DESC;

/*================================================================================================================================================================================================
Query result snippet:

| delivery_state | year | month | current_year_revenue | last_year_revenue | orders_cnt | last_year_orders_cnt | unique_customers | last_year_unique_customers |   aov  | last_year_aov |
|----------------|------|-------|----------------------|-------------------|------------|----------------------|------------------|----------------------------|--------|---------------|
| California     | 2022 |     1 |            16 186,48 |         19 957,45 |         37 |                   33 |               35 |                         33 | 437,47 |        604,77 |
| California     | 2021 |    12 |            13 860,23 |         19 555,03 |         53 |                   45 |               49 |                         45 | 261,51 |        434,56 |
| California     | 2021 |    11 |            18 346,94 |          8 693,27 |         26 |                   28 |               26 |                         26 | 705,65 |        310,47 |
| California     | 2021 |    10 |            15 769,12 |         12 468,53 |         40 |                   33 |               40 |                         33 | 394,23 |        377,83 |
| California     | 2021 |     9 |            20 248,41 |         11 782,73 |         32 |                   19 |               30 |                         19 | 632,76 |        620,14 |

📝 Notes & Reflections
   The table became quite wide, mainly due to verbose column names. Since it currently serves internal analytical purposes, we can simplify it in the next steps.
   We can also start evaluating which metrics are truly useful and which may be redundant. At this stage, `delivery_state` is no longer necessary, as the analysis is focused solely on California.

   Next step: Identify metrics that actually explain revenue dynamics.
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
4️⃣.1️⃣ YoY math calculations, column decision making, column names optimization, discount depth, code optimization
================================================================================================================================================================================================*/

WITH base_metrics AS 
(
-- CTE 1: Monthly aggregation for California
-- Calculate revenue, orders, unique customers, items sold, AOV, discount depth
SELECT
    EXTRACT(YEAR FROM o.order_date)																											year
    ,EXTRACT(MONTH FROM o.order_date)																										month
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))),2)																							revenue           -- total revenue
    ,COUNT(DISTINCT op.order_id)																											orders_cnt        -- total orders
    ,COUNT(DISTINCT o.customer_id)																											unique_customers  -- unique customers
    ,SUM(op.item_quantity)																													items_sold        -- total items sold
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0)))/
        NULLIF(COUNT(DISTINCT op.order_id),0),2)																							aov               -- average order value
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*COALESCE(op.position_discount,0)) /
        NULLIF(SUM(op.item_quantity*COALESCE(p.product_price,0)),0)*100,2)																	discount_depth    -- revenue-weighted average discount rate (total discount value / total pre-discount revenue)
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
), materialized AS
(
-- CTE 2: Materialize base_metrics to avoid alias resolution issues in MySQL 8.0
SELECT *
FROM base_metrics
), yoy_metrics AS
(
-- CTE 3: Year-over-Year comparison
-- Add previous year values for each month using window functions
SELECT
    year
    ,month
    ,revenue																																cyr_rev      -- current year revenue
    ,LAG(revenue) OVER(
		PARTITION BY month
		ORDER BY year)																														lyr_rev      -- last year revenue
    ,orders_cnt																																orders_cnt   -- current year orders
    ,LAG(orders_cnt) OVER(
		PARTITION BY month
		ORDER BY year)																														lyr_o_cnt    -- last year orders
    ,unique_customers																														uniq_cstmr   -- current year customers
    ,LAG(unique_customers) OVER(
		PARTITION BY month
		ORDER BY year)																														lyr_uniq     -- last year customers
    ,items_sold																																items_sold   -- current year items
    ,LAG(items_sold) OVER(
		PARTITION BY month
		ORDER BY year)																														lyr_items    -- last year items
    ,aov																																	aov          -- current year AOV
    ,LAG(aov) OVER(
		PARTITION BY month 
		ORDER BY year)																														lyr_aov      -- last year AOV
    ,discount_depth																															d_depth      -- current year discount depth
    ,LAG(discount_depth) OVER(
		PARTITION BY month
		ORDER BY year)																														lyr_d_depth  -- last year discount depth
FROM materialized
)
SELECT
-- Final SELECT: YoY differences and percentage changes for all metrics
    year
    ,month
    ,cyr_rev
    ,lyr_rev
    ,cyr_rev-lyr_rev																														rev_diff          -- revenue difference
    ,ROUND((cyr_rev-lyr_rev) /
		NULLIF(lyr_rev,0)*100,2)																											rev_pct_diff      -- revenue % change
    ,orders_cnt
    ,lyr_o_cnt
    ,orders_cnt-lyr_o_cnt																													ord_diff          -- orders difference
    ,ROUND((orders_cnt-lyr_o_cnt) /
		NULLIF(lyr_o_cnt,0)*100,2)																											ord_pct_diff      -- orders % change
    ,uniq_cstmr
    ,lyr_uniq
    ,uniq_cstmr-lyr_uniq																													cstmr_diff        -- customers difference
    ,ROUND((uniq_cstmr-lyr_uniq) /
		NULLIF(lyr_uniq,0)*100,2)																											cstmr_pct_diff    -- customers % change
    ,items_sold
    ,lyr_items
    ,items_sold-lyr_items																													items_diff        -- items difference
    ,ROUND((items_sold-lyr_items) /
		NULLIF(lyr_items,0)*100,2)																											items_pct_diff    -- items % change
    ,aov
    ,lyr_aov
    ,aov-lyr_aov																															aov_change        -- AOV difference
    ,ROUND((aov-lyr_aov) /
		NULLIF(lyr_aov,0)*100,2)																											aov_pct_change    -- AOV % change
    ,d_depth
    ,lyr_d_depth
    ,d_depth-lyr_d_depth																													d_depth_diff      -- discount difference
    ,ROUND((d_depth-lyr_d_depth) /
		NULLIF(lyr_d_depth,0)*100,2)																										d_depth_pct_change -- discount % change
FROM yoy_metrics
ORDER BY year DESC, month DESC;

/*================================================================================================================================================================================================
Query result snippet:
-- Result is presented in three grouped sections for readability. All rows share the same year/month keys.

-- Revenue & Orders
| year | month |   cyr_rev |   lyr_rev |   rev_diff | rev_pct_diff | orders_cnt | lyr_o_cnt | ord_diff | ord_pct_diff |
|------|-------|-----------|-----------|------------|--------------|------------|-----------|----------|--------------|
| 2022 |     1 | 16 186,48 | 19 957,45 | -3 770,97  |       -18,90 |         37 |        33 |        4 |        12,12 |
| 2021 |    12 | 13 860,23 | 19 555,03 | -5 694,80  |       -29,12 |         53 |        45 |        8 |        17,78 |
| 2021 |    11 | 18 346,94 |  8 693,27 |  9 653,67  |       111,05 |         26 |        28 |       -2 |        -7,14 |
| 2021 |    10 | 15 769,12 | 12 468,53 |  3 300,59  |        26,47 |         40 |        33 |        7 |        21,21 |
| 2021 |     9 | 20 248,41 | 11 782,73 |  8 465,68  |        71,85 |         32 |        19 |       13 |        68,42 |

-- Customers & Items
| year | month | uniq_cstmr | lyr_uniq | cstmr_diff | cstmr_pct_diff | items_sold | lyr_items | items_diff | items_pct_diff |
|------|-------|------------|----------|------------|----------------|------------|-----------|------------|----------------|
| 2022 |     1 |         35 |       33 |          2 |           6,06 |        300 |       327 |        -27 |          -8,26 |
| 2021 |    12 |         49 |       45 |          4 |           8,89 |        336 |       312 |         24 |           7,69 |
| 2021 |    11 |         26 |       26 |          0 |           0,00 |        239 |       199 |         40 |          20,10 |
| 2021 |    10 |         40 |       33 |          7 |          21,21 |        329 |       230 |         99 |          43,04 |
| 2021 |     9 |         30 |       19 |         11 |          57,89 |        283 |       151 |        132 |          87,42 |

-- AOV & Discount Depth
| year | month |    aov |  lyr_aov | aov_change | aov_pct_change | d_depth | lyr_d_depth | d_depth_diff | d_depth_pct_change |
|------|-------|--------|----------|------------|----------------|---------|-------------|--------------|--------------------|
| 2022 |     1 | 437,47 |   604,77 |    -167,30 |         -27,66 |   13,73 |       15,21 |        -1,48 |              -9,73 |
| 2021 |    12 | 261,51 |   434,56 |    -173,05 |         -39,82 |   12,32 |        8,93 |         3,39 |              37,96 |
| 2021 |    11 | 705,65 |   310,47 |     395,18 |         127,28 |   11,85 |        8,96 |         2,89 |              32,25 |
| 2021 |    10 | 394,23 |   377,83 |      16,40 |           4,34 |   13,95 |       11,29 |         2,66 |              23,56 |
| 2021 |     9 | 632,76 |   620,14 |      12,62 |           2,04 |   11,58 |       17,62 |        -6,04 |             -34,28 |

These tables are serving us in future calculations, we're not going to report it in its current form.

The number of columns may feel overwhelming at first glance. So why structure it this way when we have previously mentioned reducing amount for easier decision making rather than producing noise?

Because metrics without context are misleading - as we have presented in the very 1st query of this presentation.
Comparing a single metric often requires looking at multiple related values.

A percentage change like -5% means very little on its own. Does it represent a drop from 1,000 customers to 950, or from 20 customers to 19?
The business impact in these two scenarios is completely different. The same applies to absolute values — losing 10 customers might be insignificant at scale, or critical if your baseline is small.

This table is intentionally designed to preserve that context. By showing current and previous state as well as both absolute values and their changes (numeric and percentage),
we can properly assess the significance of each movement instead of reacting to isolated figures.

Of course, this is only part of the story.

From a business perspective, not all customers are equal. Losing one high-value, repeat customer may hurt far more than losing several low-value, one-time buyers.

This is exactly the direction we'll explore next.

⭐ On a side note things worth noticing solely from this tiny snippet:

- In the case of September, the increase in revenue can be correlated with the growth in the customer base in comparison to the last year.
  +71% revenue, +68% orders, +57% customers, nearly doubled items sold. This suggests that growth was volume-driven rather than changes in pricing or customer behavior.

- However, November 2021 presents a particularly interesting case.
  Equal amount of customers, slightly less orders but revenue is more than doubled +111%, strong candidate for deeper analysis.

💡 While November 2021 presents an interesting anomaly, it does not directly contribute to explaining California's overall performance.
   It is therefore intentionally excluded from deeper analysis at this stage and marked as a potential follow-up investigation.

📝 Notes & Reflections
   Currently, all our activities are taking place at the state level, but as we move forward, we will begin to analyze them in greater detail.
   The answers are not in plain sight, we have to constantly make decisions which columns to add or delete, adjust, change granularity.
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
5️⃣ Customer Lifetime Value & Segmentation
🎯 Goal: Calculate CLV per customer and assign each to a business segment.
💡 Context: Not all customers are equal. This query identifies who drives real value
            by combining purchase frequency, order value, and customer lifetime.
            Segments: top_customer, risky_high_value, loyal_low_value, low_value.

Customers were classified into four segments based on repeat behavior and CLV score.
The CLV threshold of 1,000 was derived from the empirical distribution of California customer CLV (n = 577):
the median CLV is 387.72 and the 75th percentile is 1,094.30, making 1,000 a defensible approximation of the top quartile.

CLV Normalization note:
    Raw CLV (avg_order_value × purchase_frequency × lifetime_months) is biased toward
    older customers who had more time to accumulate history.
================================================================================================================================================================================================*/

WITH customer_metrics AS 
(
SELECT
    o.customer_id                                                                   customer_id
    ,COUNT(DISTINCT o.order_id)                                                     orders_cnt
    ,SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0)))                                     total_revenue
    ,MIN(o.order_date)                                                              first_order_date
    ,MAX(o.order_date)                                                              last_order_date
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY o.customer_id
), customer_enriched AS 
(
SELECT
    customer_id                                                                     customer_id
    ,orders_cnt                                                                     orders_cnt
    ,total_revenue                                                                  total_revenue
    ,total_revenue / NULLIF(orders_cnt, 0)                                          avg_order_value
    ,TIMESTAMPDIFF(MONTH, first_order_date, last_order_date)+1                    	lifetime_months
    ,orders_cnt /
		NULLIF(TIMESTAMPDIFF(MONTH, first_order_date, last_order_date) + 1, 0) 		purchase_frequency
    ,CASE WHEN orders_cnt > 1
		THEN 1
		ELSE 0
	END                                     										is_repeat_customer
FROM customer_metrics
)
SELECT
    customer_id                                                                     customer_id
    ,orders_cnt                                                                     orders_cnt
    ,ROUND(total_revenue, 2)                                                        historical_revenue
    ,ROUND(avg_order_value, 2)                                                      avg_order_value
    ,lifetime_months                                                                lifetime_months
    ,ROUND(purchase_frequency, 2)                                                   purchase_frequency
    ,ROUND(avg_order_value*purchase_frequency*lifetime_months, 2)                   clv
    ,ROUND(avg_order_value*purchase_frequency*lifetime_months*is_repeat_customer, 2) clv_retention_adjusted
    ,CASE
        WHEN is_repeat_customer = 1
        AND avg_order_value*purchase_frequency*lifetime_months >= 1000
        THEN 'top_customer'
        WHEN is_repeat_customer = 0
        AND avg_order_value*purchase_frequency*lifetime_months >= 1000
        THEN 'risky_high_value'
        WHEN is_repeat_customer = 1
        THEN 'loyal_low_value'
        ELSE 'low_value'
    END                                                                             customer_segment
FROM customer_enriched
ORDER BY clv_retention_adjusted DESC, clv DESC;

/*================================================================================================================================================================================================
Query result snippet:

| customer_id | orders_cnt | historical_revenue | avg_order_value | lifetime_months | purchase_frequency |      clv | clv_retention_adjusted | customer_segment |
|-------------|------------|--------------------|-----------------|-----------------|--------------------|----------|------------------------|-------=----------|
|         457 |          2 |           8 349,89 |        4 174,95 |              40 |               0,05 | 8 349,89 |               8 349,89 | top_customer     |
|         433 |          2 |           7 301,73 |        3 650,86 |              13 |               0,15 | 7 301,73 |               7 301,73 | top_customer     |
|         450 |          4 |           7 182,77 |        1 795,69 |              36 |               0,11 | 7 182,77 |               7 182,77 | top_customer     |
|         280 |          3 |           5 848,69 |        1 949,56 |              30 |               0,10 | 5 848,69 |               5 848,69 | top_customer     |
|         579 |          2 |           5 182,58 |        2 591,29 |              33 |               0,06 | 5 182,58 |               5 182,58 | top_customer     |

📝 Notes & Reflections
   CLV here is a historical approximation: avg_order_value × purchase_frequency × lifetime_months.
   clv_retention_adjusted zeroes out one-time buyers, isolating customers who have demonstrated
   repeat behavior. This distinction drives the segmentation logic.

   top_customer: repeat buyer with CLV >= 1000 — highest business value.
   risky_high_value: one-time buyer with CLV >= 1000 — high spend but no proven loyalty.
   loyal_low_value: repeat buyer with CLV < 1000 — consistent but lower spend.
   low_value: one-time buyer with CLV < 1000 — lowest priority segment.

   This segmentation feeds directly into the next three queries which cross-reference
   customer quality with acquisition timing and revenue growth.
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
5️⃣.1️⃣ Customer Segment Distribution by Acquisition Month
🎯 Goal: Understand what kind of customers were acquired each month.
💡 Context: Segments are based on full customer history (CLV query).
            This shows whether high-value customers were acquired during growth months.
================================================================================================================================================================================================*/

WITH customer_metrics AS 
(
SELECT
    o.customer_id
    ,COUNT(DISTINCT o.order_id)                                                     orders_cnt
    ,SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0)))                                     total_revenue
    ,MIN(o.order_date)                                                              first_order_date
    ,MAX(o.order_date)                                                              last_order_date
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY o.customer_id
), customer_enriched AS (
SELECT
    customer_id
    ,orders_cnt
    ,total_revenue
    ,total_revenue / NULLIF(orders_cnt, 0)                                          avg_order_value
    ,TIMESTAMPDIFF(MONTH, first_order_date, last_order_date)+1	                    lifetime_months
    ,orders_cnt / 
		NULLIF(TIMESTAMPDIFF(MONTH, first_order_date, last_order_date)+1, 0) 		purchase_frequency
    ,CASE WHEN orders_cnt > 1 THEN 1 ELSE 0 END                                     is_repeat_customer
    ,DATE_FORMAT(first_order_date, '%Y-%m-01')                                      acquisition_month
FROM customer_metrics
), customer_segmented AS 
(
SELECT
    customer_id
    ,acquisition_month
    ,ROUND(avg_order_value * purchase_frequency * lifetime_months, 2)               clv
    ,CASE
        WHEN is_repeat_customer = 1
        AND avg_order_value * purchase_frequency * lifetime_months >= 1000
        THEN 'top_customer'
        WHEN is_repeat_customer = 0
        AND avg_order_value * purchase_frequency * lifetime_months >= 1000
        THEN 'risky_high_value'
        WHEN is_repeat_customer = 1
        THEN 'loyal_low_value'
        ELSE 'low_value'
    END                                                                             customer_segment
FROM customer_enriched
)
SELECT
    acquisition_month
    ,customer_segment
    ,COUNT(DISTINCT customer_id)                                                    customers_cnt
    ,ROUND(SUM(clv), 2)                                                             total_clv
    ,ROUND(AVG(clv), 2)                                                             avg_clv
FROM customer_segmented
GROUP BY acquisition_month, customer_segment
ORDER BY acquisition_month DESC, customer_segment;

/*================================================================================================================================================================================================
Query result snippet:

| acquisition_month | customer_segment | customers_cnt | total_clv | avg_clv |
|-------------------|------------------|---------------|-----------|---------|
| 2022-01-01        | low_value        |            11 |  2 214,32 |  201,30 |
| 2022-01-01        | loyal_low_value  |             1 |    186,62 |  186,62 |
| 2021-12-01        | low_value        |             8 |  2 317,81 |  289,73 |
| 2021-12-01        | loyal_low_value  |             2 |    430,44 |  215,22 |
| 2021-12-01        | risky_high_value |             3 |  4 279,36 | 1426,45 |

📝 Notes & Reflections
   Based on the full query result spanning 2018–2022, a clear pattern emerges.

   The earlier acquisition cohorts (2018–2020) show a healthy mix of segments — top_customers
   and risky_high_value customers appear consistently, with top_customers generating
   significantly higher avg_clv than any other segment.

   From mid-2021 onward, the segment mix shifts noticeably. Months that showed strong
   volume-driven YoY growth in our earlier analysis (September, October 2021) acquired
   predominantly low_value customers. top_customer acquisitions become increasingly rare
   in this period.

   This raises a critical question: was California's 2021 growth sustainable,
   or was it largely driven by customers unlikely to return?

   The next step will cross-reference this segment distribution with YoY revenue data
   to quantify the relationship between acquisition quality and revenue performance.
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
5️⃣.2️⃣ Acquisition Quality vs Revenue Growth
🎯 Goal: Cross-reference YoY revenue growth with the quality of customers acquired that month.
💡 Context: High revenue growth driven by low_value customers is a warning signal.
            High revenue growth driven by top_customers suggests sustainable expansion.
================================================================================================================================================================================================*/

WITH customer_metrics AS 
(
SELECT
    o.customer_id
    ,COUNT(DISTINCT o.order_id)                                                     orders_cnt
    ,SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0)))                                     total_revenue
    ,MIN(o.order_date)                                                              first_order_date
    ,MAX(o.order_date)                                                              last_order_date
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY o.customer_id
), customer_enriched AS 
(
SELECT
    customer_id
    ,total_revenue
    ,total_revenue / NULLIF(orders_cnt, 0)                                          avg_order_value
    ,TIMESTAMPDIFF(MONTH, first_order_date, last_order_date)+1                   	lifetime_months
    ,orders_cnt / 
		NULLIF(TIMESTAMPDIFF(MONTH, first_order_date, last_order_date)+1, 0) 		purchase_frequency
    ,CASE WHEN orders_cnt > 1 
		THEN 1
		ELSE 0
	END                                     										is_repeat_customer
    ,DATE_FORMAT(first_order_date, '%Y-%m-01')                                      acquisition_month
FROM customer_metrics
), customer_segmented AS
(
SELECT
    customer_id
    ,acquisition_month
    ,ROUND(avg_order_value * purchase_frequency * lifetime_months, 2)               clv
    ,CASE
        WHEN is_repeat_customer = 1
        AND avg_order_value * purchase_frequency * lifetime_months >= 1000
        THEN 'top_customer'
        WHEN is_repeat_customer = 0
        AND avg_order_value * purchase_frequency * lifetime_months >= 1000
        THEN 'risky_high_value'
        WHEN is_repeat_customer = 1
        THEN 'loyal_low_value'
        ELSE 'low_value'
    END                                                                             customer_segment
FROM customer_enriched
), segment_by_month AS 
(
SELECT
    acquisition_month
    ,COUNT(DISTINCT CASE WHEN customer_segment = 'top_customer' 
		THEN customer_id 
	END) 																			top_customers
    ,COUNT(DISTINCT CASE WHEN customer_segment = 'risky_high_value' 
		THEN customer_id
	END) 																			risky_high_value
    ,COUNT(DISTINCT CASE WHEN customer_segment = 'loyal_low_value'   
		THEN customer_id 
	END) 																			loyal_low_value
    ,COUNT(DISTINCT CASE WHEN customer_segment = 'low_value'         
		THEN customer_id
	END) 																			low_value
    ,COUNT(DISTINCT customer_id)                                                    total_customers
FROM customer_segmented
GROUP BY acquisition_month
), monthly_revenue AS 
(
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m-01')                                           month
    ,SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0)))                                     revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY month
), revenue_yoy AS 
(
SELECT
    month
    ,ROUND(revenue, 2)                                                              cyr_rev
    ,ROUND(LAG(revenue) OVER(
        PARTITION BY MONTH(month)
        ORDER BY month), 2)                                                         lyr_rev
    ,ROUND((revenue-LAG(revenue) OVER(
        PARTITION BY MONTH(month)
        ORDER BY month)) /
        NULLIF(LAG(revenue) OVER(
        PARTITION BY MONTH(month)
        ORDER BY month), 0)*100.0, 2)                                               rev_pct_diff
FROM monthly_revenue
)
SELECT
    r.month                                                                         acquisition_month
    ,r.cyr_rev
    ,r.lyr_rev
    ,r.rev_pct_diff
    ,COALESCE(s.top_customers, 0)                                                   top_customers
    ,COALESCE(s.risky_high_value, 0)                                                risky_high_value
    ,COALESCE(s.loyal_low_value, 0)                                                 loyal_low_value
    ,COALESCE(s.low_value, 0)                                                       low_value
    ,COALESCE(s.total_customers, 0)                                                 total_customers
FROM revenue_yoy r
LEFT JOIN segment_by_month s ON r.month = s.acquisition_month
ORDER BY acquisition_month DESC;

/*================================================================================================================================================================================================
Query result snippet:

| acquisition_month | cyr_rev   | lyr_rev   | rev_pct_diff | top_customers | risky_high_value | loyal_low_value | low_value | total_customers |
|-------------------|-----------|-----------|--------------|---------------|------=-----------|-----------------|-----------|-----------------|
| 2022-01-01        | 16 186,48 | 19 957,45 |       -18,90 |             0 |       	        0 |               1 |        11 |              12 |
| 2021-12-01        | 13 860,23 | 19 555,03 |       -29,12 |             0 |                3 |               2 |         8 |              13 |
| 2021-11-01        | 18 346,94 |  8 693,27 |       111,05 |             0 |                3 |               0 |         9 |              12 |
| 2021-10-01        | 15 769,12 | 12 468,53 |        26,47 |             0 |                0 |               1 |         7 |               8 |
| 2021-09-01        | 20 248,41 | 11 782,73 |        71,85 |             0 |               	3 |               1 |         7 |              12 |

📝 Notes & Reflections
   Based on the full query result, the data tells a clear and consistent story.

   In 2018–2020, months with strong revenue were typically backed by a healthy share
   of top_customers — January 2019 alone acquired 9 top_customers followed by a strong
   YoY growth of +144.44% in February. December 2020 brought 3 top_customers and +78.6% YoY.
   This suggests that early California growth was driven by genuinely high-value acquisitions.

   From 2021 onward the picture changes. The months that showed the strongest YoY growth
   numbers — September 2021 (+71.85%), November 2021 (+111.05%), March 2021 (+179.05%) —
   acquired zero or one top_customer. The dominant segment in these months was low_value
   and risky_high_value. High revenue in risky_high_value is not backed by repeat purchase
   behavior, making it structurally fragile.

   The December 2021 and January 2022 results reinforce this — revenue declined YoY
   while new acquisitions were overwhelmingly low_value. The pipeline of high-value
   customers was not being replenished.

   This is the core answer to the question posed in query 1️⃣:
   California generates the highest revenue — but the quality of its customer acquisition
   deteriorated significantly from 2021 onward. Growth became volume-driven and
   segment-shallow. Without a strategic shift toward acquiring and retaining top_customers,
   the revenue trajectory is at risk.

   The final step will confirm whether retention rates differ meaningfully across segments —
   validating or challenging this conclusion.
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
5️⃣.3️⃣ Month+1 Retention Rate by Customer Segment
🎯 Goal: Confirm whether top_customers retain better than other segments.
💡 Context: If top_customers retain at a higher rate, it validates CLV segmentation
            and confirms that acquiring them is worth the investment.
================================================================================================================================================================================================*/

WITH customer_metrics AS (
SELECT
    o.customer_id
    ,COUNT(DISTINCT o.order_id)                                                     orders_cnt
    ,SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0)))                                     total_revenue
    ,MIN(o.order_date)                                                              first_order_date
    ,MAX(o.order_date)                                                              last_order_date
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY o.customer_id
), customer_enriched AS 
(
SELECT
    customer_id
    ,total_revenue / NULLIF(orders_cnt, 0)                                          avg_order_value
    ,TIMESTAMPDIFF(MONTH, first_order_date, last_order_date) + 1                    lifetime_months
    ,orders_cnt / 
		NULLIF(TIMESTAMPDIFF(MONTH, first_order_date, last_order_date)+1, 0) 		purchase_frequency
    ,CASE WHEN orders_cnt > 1 
		THEN 1
		ELSE 0
	END                                     										is_repeat_customer
FROM customer_metrics
), customer_segmented AS
(
SELECT
    customer_id
    ,CASE
        WHEN is_repeat_customer = 1
        AND avg_order_value * purchase_frequency * lifetime_months >= 1000
        THEN 'top_customer'
        WHEN is_repeat_customer = 0
        AND avg_order_value * purchase_frequency * lifetime_months >= 1000
        THEN 'risky_high_value'
        WHEN is_repeat_customer = 1
        THEN 'loyal_low_value'
        ELSE 'low_value'
    END                                                                             customer_segment
FROM customer_enriched
), customer_activity AS (
SELECT DISTINCT
    o.customer_id
    ,DATE_FORMAT(o.order_date, '%Y-%m-01')                                          month
FROM orders o
WHERE o.delivery_state = 'California'
), customer_next_purchase AS (
SELECT
    a.customer_id
    ,a.month
    ,s.customer_segment
    ,LEAD(a.month) OVER (
        PARTITION BY a.customer_id
        ORDER BY a.month)                                                          	next_purchase_month
    ,DATE_ADD(a.month, INTERVAL 1 MONTH)                                            next_calendar_month
FROM customer_activity a
JOIN customer_segmented s ON a.customer_id = s.customer_id
)
SELECT
    customer_segment
    ,COUNT(*)                                                                       active_customers
    ,COUNT(CASE WHEN next_purchase_month = next_calendar_month
        THEN 1 END)                                                                 retained_customers
    ,ROUND(COUNT(CASE WHEN next_purchase_month = next_calendar_month
        THEN 1 END)*100.0 /
        NULLIF(COUNT(*), 0), 2)                                                     retention_rate_pct
FROM customer_next_purchase
GROUP BY customer_segment
ORDER BY retention_rate_pct DESC;

/*================================================================================================================================================================================================
Query result snippet:

| customer_segment | active_customers | retained_customers | retention_rate_pct |
|------------------|------------------|--------------------|--------------------|
| loyal_low_value  |              317 |                 11 |               3,47 |
| top_customer     |              408 |                 11 |               2,70 |
| low_value        |              244 |                  0 |               0,00 |
| risky_high_value |               39 |                  0 |               0,00 |

📝 Notes & Reflections
   The retention results are unexpected and require careful interpretation.

   low_value and risky_high_value show 0% Month+1 retention — confirming that these
   segments do not return the following month. This aligns with the hypothesis built
   in previous steps: California's 2021 growth was structurally fragile.

   However, top_customer retention (2.70%) is slightly lower than loyal_low_value (3.47%).
   This appears counterintuitive but is explained by the CLV segment definition itself.
   top_customers are classified based on total historical revenue, not purchase frequency.
   A customer who placed two very large orders spread across 40 months will be classified
   as top_customer despite low month-to-month activity — which is exactly what the data
   shows (avg lifetime_months for top_customers is high).

   loyal_low_value customers by definition return — that is what makes them loyal —
   but their order values are low. Their slightly higher Month+1 retention reflects
   more frequent but lower-value purchasing behavior.

   This is a known limitation of the CLV model used here, documented in the assumptions.
   A more granular segmentation incorporating purchase frequency as a standalone dimension
   would produce cleaner retention separation between segments.

   ⭐ Final conclusion:
   California leads in revenue across all states. Its growth from 2018 to 2020 was backed
   by consistent top_customer acquisition. From 2021 onward, acquisition quality declined —
   growth became volume-driven, dominated by low_value and risky_high_value customers
   who do not return. The revenue base is at risk unless acquisition strategy shifts
   back toward retaining and growing the top_customer segment.

   This analysis has demonstrated that a single revenue metric tells almost nothing.
   The full story required understanding time, customer quality, acquisition patterns,
   and retention behavior — step by step.
================================================================================================================================================================================================*/
