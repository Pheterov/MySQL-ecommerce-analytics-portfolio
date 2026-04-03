Project: E-commerce Analytics SQL Portfolio
🛠️ Database: supersales - modified by KajoData MySQL 8.0+
👤 Author: Piotr Rzepka
📝 Description: SQL e-commerce analytics portfolio

																					"The story of California's revenue" 

/*

This project was developed as a learning exercise with AI-assisted code review 
and iterative improvement. The analytical methodology (tenure bias control, 
right-censoring, revenue decomposition) was introduced through mentored feedback. 
All SQL is my own, written and verified against the live dataset.

SQL analysis of 2018–2022 e-commerce data reveals that California leads in total revenue.
Initial segmentation suggested declining acquisition quality from 2021, but cohort-controlled
analysis proved this was a tenure bias artifact — recent cohorts actually show improving
early repeat rates. Revenue growth in 2021 was driven by a maturing returning customer base.
*/

/*================================================================================================================================================================================================
📋 Data assumptions and conventions used throughout this analysis:

   1. COALESCE(p.product_price, 0) — NULL product prices are treated as zero (free items or missing data).
      COALESCE(op.position_discount, 0) — NULL discounts are treated as no discount applied.
      These are intentional business assumptions. If NULL instead represents "unknown," revenue figures
      may be overstated. This should be validated with the data owner before production use.

   2. delivery_state values are assumed to be clean and consistently formatted (e.g., no lowercase
      'california' or trailing whitespace). A preliminary SELECT DISTINCT delivery_state check
      was performed to confirm this.

   3. Revenue formula: item_quantity × product_price × (1 − position_discount).
      This represents net revenue after line-level discounts, before tax and shipping.
================================================================================================================================================================================================*/
	
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
    ,COUNT(DISTINCT op.order_id)                                                                             								orders_cnt
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
		ORDER BY year)																														lyr_orders   -- last year orders
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
    ,lyr_orders
    ,orders_cnt-lyr_orders																													ord_diff          -- orders difference
    ,ROUND((orders_cnt-lyr_orders) /
		NULLIF(lyr_orders,0)*100,2)																											ord_pct_diff      -- orders % change
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
| year | month |   cyr_rev |   lyr_rev |   rev_diff | rev_pct_diff | orders_cnt | lyr_orders | ord_diff | ord_pct_diff |
|------|-------|-----------|-----------|------------|--------------|------------|------------|----------|--------------|
| 2022 |     1 | 16 186,48 | 19 957,45 | -3 770,97  |       -18,90 |         37 |         33 |        4 |        12,12 |
| 2021 |    12 | 13 860,23 | 19 555,03 | -5 694,80  |       -29,12 |         53 |         45 |        8 |        17,78 |
| 2021 |    11 | 18 346,94 |  8 693,27 |  9 653,67  |       111,05 |         26 |         28 |       -2 |        -7,14 |
| 2021 |    10 | 15 769,12 | 12 468,53 |  3 300,59  |        26,47 |         40 |         33 |        7 |        21,21 |
| 2021 |     9 | 20 248,41 | 11 782,73 |  8 465,68  |        71,85 |         32 |         19 |       13 |        68,42 |

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

On a side note things worth noticing solely from this tiny snippet:

- In the case of September, the increase in revenue can be correlated with the growth in the customer base in comparison to the last year.
  +71% revenue, +68% orders, +57% customers, nearly doubled items sold. This suggests that growth was volume-driven rather than changes in pricing or customer behavior.

- However, November 2021 presents a particularly interesting case.
  Equal amount of customers, slightly less orders but revenue is more than doubled +111%, strong candidate for deeper analysis.

While November 2021 presents an interesting anomaly, it does not directly contribute to explaining California's overall performance.
   It is therefore intentionally excluded from deeper analysis at this stage and marked as a potential follow-up investigation.

   Before moving on, it is worth noting that an anomaly of this magnitude (+111% YoY with fewer orders)
   could be driven by a single outlier order. To rule this out, the order value distribution for that month
   should be checked (min, max, median, standard deviation). If one order accounts for a disproportionate
   share of revenue, the growth figure is misleading. This validation is deferred but recommended.

Notes & Reflections
   Currently, all our activities are taking place at the state level, but as we move forward, we will begin to analyze them in greater detail.
   The answers are not in plain sight, we have to constantly make decisions which columns to add or delete, adjust, change granularity.
================================================================================================================================================================================================*/

/*================================================================================================================================================================================================
5️⃣ Customer Segmentation by Historical Revenue & Repeat Behavior
Goal: Classify each customer into a business segment based on total historical revenue
         and demonstrated repeat purchase behavior.
Context: Not all customers are equal. This query identifies who drives real value
            by combining cumulative spend with observed loyalty (repeat vs one-time).
            Segments: top_customer, risky_high_value, loyal_low_value, low_value.
 
Customers were classified into four segments based on repeat behavior and total historical revenue.
The revenue threshold of 1,000 was derived from the empirical distribution of California customer
total revenue (n = 565, after excluding 2022-only acquisitions): the median is ~390 and the
75th percentile is ~1,050, making 1,000 a defensible approximation of the top quartile boundary.
 
Scope decisions:
    1. 2022 is excluded: only January data is available, giving those customers near-zero time
       to demonstrate repeat behavior. Including them would inflate the low_value segment artificially.
       However, 2022 orders ARE included in the base revenue/repeat calculation — a customer acquired
       in 2021 who ordered again in January 2022 correctly counts as a repeat buyer.
 
    2. All metrics use only California-delivered orders. Nearly all CA customers (574 of 577) also
       ordered to other states. Their CA-only profile may understate true engagement. This is an
       intentional scoping decision, documented for transparency.
 
    3. The segmentation metric is total historical revenue — not a "CLV model." A common CLV formula
       (avg_order_value × purchase_frequency × lifetime_months) algebraically simplifies to
       total_revenue in all cases, so using total_revenue directly is both simpler and more honest.
       This approach is biased toward older customers; query 5️⃣.4️⃣ controls for this.
================================================================================================================================================================================================*/
 
WITH customer_metrics AS 
(
-- All California orders 2018–2022 included for accurate revenue and repeat classification.
-- A customer acquired in Dec 2021 who ordered again in Jan 2022 must count as repeat buyer.
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
-- Exclude customers acquired in 2022 (incomplete period)
HAVING EXTRACT(YEAR FROM MIN(o.order_date)) < 2022
)
SELECT
    customer_id                                                                     customer_id
    ,orders_cnt                                                                     orders_cnt
    ,ROUND(total_revenue, 2)                                                        historical_revenue
    ,ROUND(total_revenue / NULLIF(orders_cnt, 0), 2)                                avg_order_value
    ,CASE WHEN orders_cnt > 1 THEN 1 ELSE 0 END                                    is_repeat_customer
    ,CASE
        WHEN orders_cnt > 1 AND total_revenue >= 1000 THEN 'top_customer'
        WHEN orders_cnt = 1 AND total_revenue >= 1000 THEN 'risky_high_value'
        WHEN orders_cnt > 1                            THEN 'loyal_low_value'
        ELSE 'low_value'
    END                                                                             customer_segment
FROM customer_metrics
ORDER BY total_revenue DESC;
 
/*================================================================================================================================================================================================
Query result — segment summary:
 
| customer_segment | customers_cnt | total_revenue | avg_revenue | avg_orders | min_revenue | max_revenue |
|------------------|---------------|---------------|-------------|------------|-------------|-------------|
| top_customer     |           120 |    256 290,76 |    2 135,76 |       2,67 |    1 029,17 |    8 349,89 |
| risky_high_value |            39 |     72 972,35 |    1 871,09 |       1,00 |    1 011,70 |    4 006,21 |
| loyal_low_value  |           173 |     72 032,08 |      416,37 |       2,40 |       20,02 |      996,58 |
| low_value        |           233 |     47 754,43 |      204,95 |       1,00 |        3,98 |      976,83 |
 
📝 Notes & Reflections
   After excluding 12 customers acquired only in January 2022, we have 565 California customers.
 
   top_customer (120, 21%): repeat buyers with revenue >= 1,000. They account for 57% of total
   California revenue while representing only 21% of the customer base.
 
   risky_high_value (39, 7%): one-time buyers with revenue >= 1,000. High spend but no proven
   loyalty — structurally fragile.
 
   loyal_low_value (173, 31%): repeat buyers with revenue < 1,000. Consistent engagement
   but lower individual contribution.
 
   low_value (233, 41%): one-time buyers with revenue < 1,000. Largest segment by count,
   smallest by revenue contribution.
 
   This segmentation has a known limitation: it is biased toward older customers who had more
   time to accumulate revenue and repeat purchases. A customer acquired in 2018 had ~4 years
   to build history, while one acquired in late 2021 had only months. Query 5️⃣.4️⃣ addresses
   this directly with a cohort-controlled repeat rate analysis.
================================================================================================================================================================================================*/
 
/*================================================================================================================================================================================================
5️⃣.1️⃣ Customer Segment Distribution by Acquisition Quarter
Goal: Understand what kind of customers were acquired each quarter.
Context: Segments are based on full customer history (query 5️⃣).
            This shows whether high-value customers were acquired during growth periods.
            Quarterly granularity provides more stable counts than monthly while allowing
            meaningful YoY comparison.
 
⚠️ 2022 excluded — customers acquired in January 2022 had near-zero repeat opportunity.
   Tenure bias caveat applies: see query 5️⃣.4️⃣ for controlled comparison.
================================================================================================================================================================================================*/
 
WITH customer_metrics AS 
(
SELECT
    o.customer_id
    ,COUNT(DISTINCT o.order_id)                                                     orders_cnt
    ,SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0)))                                     total_revenue
    ,MIN(o.order_date)                                                              first_order_date
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY o.customer_id
HAVING EXTRACT(YEAR FROM MIN(o.order_date)) < 2022
), customer_segmented AS 
(
SELECT
    customer_id
    ,CONCAT(EXTRACT(YEAR FROM first_order_date), '-Q',
        QUARTER(first_order_date))                                                  acq_quarter
    ,CASE
        WHEN orders_cnt > 1 AND total_revenue >= 1000 THEN 'top_customer'
        WHEN orders_cnt = 1 AND total_revenue >= 1000 THEN 'risky_high_value'
        WHEN orders_cnt > 1                            THEN 'loyal_low_value'
        ELSE 'low_value'
    END                                                                             customer_segment
FROM customer_metrics
)
SELECT
    acq_quarter                                                                     acquisition_quarter
    ,COUNT(*)                                                                       total_acquired
    ,SUM(CASE WHEN customer_segment = 'top_customer'     THEN 1 ELSE 0 END)        top_customers
    ,SUM(CASE WHEN customer_segment = 'risky_high_value' THEN 1 ELSE 0 END)        risky_high_value
    ,SUM(CASE WHEN customer_segment = 'loyal_low_value'  THEN 1 ELSE 0 END)        loyal_low_value
    ,SUM(CASE WHEN customer_segment = 'low_value'        THEN 1 ELSE 0 END)        low_value
    ,ROUND(SUM(CASE WHEN customer_segment = 'top_customer'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)                                  top_pct
    ,ROUND(SUM(CASE WHEN customer_segment IN ('top_customer','loyal_low_value')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)                                  repeat_pct
FROM customer_segmented
GROUP BY acq_quarter
ORDER BY acq_quarter;
 
/*================================================================================================================================================================================================
Query result snippet:
 
| acquisition_quarter | total | top | risky | loyal | low | top%  | repeat% |
|---------------------|-------|-----|-------|-------|-----|-------|---------|
| 2018-Q1             |    12 |   4 |     0 |     4 |   4 |  33,3 |   66,7 |
| 2018-Q2             |    43 |  20 |     0 |    15 |   8 |  46,5 |   81,4 |
| 2018-Q3             |    38 |   9 |     2 |    18 |   9 |  23,7 |   71,1 |
| 2018-Q4             |    67 |  16 |     1 |    25 |  25 |  23,9 |   61,2 |
| 2019-Q1             |    32 |  14 |     2 |     9 |   7 |  43,8 |   71,9 |
| 2019-Q2             |    33 |   6 |     3 |    11 |  13 |  18,2 |   51,5 |
| 2019-Q3             |    28 |   5 |     1 |    10 |  12 |  17,9 |   53,6 |
| 2019-Q4             |    54 |  12 |     6 |    17 |  19 |  22,2 |   53,7 |
| 2020-Q1             |    31 |   6 |     1 |    10 |  14 |  19,4 |   51,6 |
| 2020-Q2             |    27 |   5 |     0 |     9 |  13 |  18,5 |   51,9 |
| 2020-Q3             |    36 |  10 |     4 |    10 |  12 |  27,8 |   55,6 |
| 2020-Q4             |    53 |   9 |     3 |    19 |  22 |  17,0 |   52,8 |
| 2021-Q1             |    22 |   0 |     3 |     7 |  12 |   0,0 |   31,8 |
| 2021-Q2             |    27 |   2 |     1 |     2 |  22 |   7,4 |   14,8 |
| 2021-Q3             |    29 |   2 |     6 |     4 |  17 |   6,9 |   20,7 |
| 2021-Q4             |    33 |   0 |     6 |     3 |  24 |   0,0 |    9,1 |
 
📝 Notes & Reflections
   The data shows a dramatic shift in segment composition over time.
 
   2018 cohorts: top_customer rates between 24–47%, repeat rates 61–81%. The early customer base
   was heavily skewed toward high-value, repeat-purchasing customers.
 
   2019–2020 cohorts: top_customer rates stabilize at 17–28%, repeat rates around 52–56%.
   A more balanced but still healthy acquisition profile.
 
   2021 cohorts: top_customer rates collapse to 0–7%, repeat rates drop to 9–32%.
   The dominant segment shifts to low_value (one-time buyers with revenue < 1,000).
 
CRITICAL CAVEAT — tenure bias:
   This pattern is visually striking, but it is expected to some degree. Customers acquired in
   2018 had ~4 years to build revenue and demonstrate repeat behavior. Customers acquired in Q4 2021
   had at most ~2 months. Some of these "low_value" customers will eventually cross the 1,000
   threshold and make repeat purchases — they simply haven't had time yet.
 
   Query 5️⃣.4️⃣ controls for this bias by comparing cohorts within identical 90-day windows.
   The shift in segment composition is real in the data, but its interpretation requires caution.
================================================================================================================================================================================================*/
 
/*================================================================================================================================================================================================
5️⃣.2️⃣ Revenue Composition: New vs Returning Customers × Acquisition Quality
Goal: Decompose quarterly revenue into contributions from newly acquired customers
         vs returning customers, and cross-reference with the quality of new acquisitions.
Context: The original version of this query compared total monthly revenue with new customer
            segments — but most revenue in a given period comes from customers acquired EARLIER.
            That comparison created a false correlation. This version separates the two revenue
            streams so we can assess actual relationships.
 
            A "new customer" order is defined as an order placed in the same month as the
            customer's first-ever California order.
================================================================================================================================================================================================*/

-- customer_first includes ALL customers (even 2022-acquired) because we need their
-- first_order_date to correctly classify orders as "new" vs "returning" in quarterly_revenue.
-- This is intentionally broader than customer_metrics, which excludes 2022 for segmentation.
WITH customer_first AS
(
-- First order date per customer (includes 2022 orders for accurate attribution)
SELECT
    customer_id
    ,MIN(order_date)                                                                first_order_date
FROM orders
WHERE delivery_state = 'California'
GROUP BY customer_id
), customer_metrics AS
(
-- Full history for segment assignment (2022 acquisitions excluded from segmentation)
SELECT
    o.customer_id
    ,COUNT(DISTINCT o.order_id)                                                     orders_cnt
    ,SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0)))                                     total_revenue
    ,MIN(o.order_date)                                                              first_order_date
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY o.customer_id
HAVING EXTRACT(YEAR FROM MIN(o.order_date)) < 2022
), customer_segmented AS
(
SELECT
    customer_id
    ,first_order_date
    ,CONCAT(EXTRACT(YEAR FROM first_order_date), '-Q',
        QUARTER(first_order_date))                                                  acq_quarter
    ,CASE
        WHEN orders_cnt > 1 AND total_revenue >= 1000 THEN 'top_customer'
        WHEN orders_cnt = 1 AND total_revenue >= 1000 THEN 'risky_high_value'
        WHEN orders_cnt > 1                            THEN 'loyal_low_value'
        ELSE 'low_value'
    END                                                                             customer_segment
FROM customer_metrics
), segment_by_quarter AS
(
SELECT
    acq_quarter
    ,SUM(CASE WHEN customer_segment = 'top_customer'     THEN 1 ELSE 0 END)        top_customers
    ,SUM(CASE WHEN customer_segment = 'risky_high_value' THEN 1 ELSE 0 END)        risky_high_value
    ,SUM(CASE WHEN customer_segment = 'loyal_low_value'  THEN 1 ELSE 0 END)        loyal_low_value
    ,SUM(CASE WHEN customer_segment = 'low_value'        THEN 1 ELSE 0 END)        low_value
    ,COUNT(*)                                                                       total_new_customers
FROM customer_segmented
GROUP BY acq_quarter
), quarterly_revenue AS
(
-- Revenue decomposition: new customer orders vs returning customer orders
-- 2022 excluded from output; a "new" order is one placed in the customer's first-order month
SELECT
    CONCAT(EXTRACT(YEAR FROM o.order_date), '-Q',
        QUARTER(o.order_date))                                                      quarter
    ,EXTRACT(YEAR FROM o.order_date)                                                yr
    ,QUARTER(o.order_date)                                                          q
    ,ROUND(SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0))), 2)                                 total_rev
    ,ROUND(SUM(CASE
        WHEN DATE_FORMAT(o.order_date, '%Y-%m') = DATE_FORMAT(cf.first_order_date, '%Y-%m')
        THEN op.item_quantity*COALESCE(p.product_price, 0)
            *(1-COALESCE(op.position_discount, 0))
        ELSE 0
    END), 2)                                                                        new_cust_rev
    ,ROUND(SUM(CASE
        WHEN DATE_FORMAT(o.order_date, '%Y-%m') != DATE_FORMAT(cf.first_order_date, '%Y-%m')
        THEN op.item_quantity*COALESCE(p.product_price, 0)
            *(1-COALESCE(op.position_discount, 0))
        ELSE 0
    END), 2)                                                                        ret_cust_rev
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
JOIN customer_first cf ON o.customer_id = cf.customer_id
WHERE o.delivery_state = 'California'
  AND EXTRACT(YEAR FROM o.order_date) < 2022
GROUP BY quarter, yr, q
), revenue_yoy AS
(
SELECT
    quarter
    ,yr
    ,q
    ,total_rev                                                                      cyr_rev
    ,LAG(total_rev) OVER (
        PARTITION BY q
        ORDER BY yr)                                                                lyr_rev
    ,ROUND((total_rev - LAG(total_rev) OVER (
        PARTITION BY q
        ORDER BY yr)) /
        NULLIF(LAG(total_rev) OVER (
        PARTITION BY q
        ORDER BY yr), 0)*100.0, 2)                                                  rev_pct_diff
    ,new_cust_rev
    ,ret_cust_rev
    ,ROUND(new_cust_rev * 100.0 / NULLIF(total_rev, 0), 1)                         new_cust_rev_pct
FROM quarterly_revenue
)
SELECT
    r.quarter
    ,r.cyr_rev
    ,r.lyr_rev
    ,r.rev_pct_diff
    ,r.new_cust_rev
    ,r.ret_cust_rev
    ,r.new_cust_rev_pct
    ,COALESCE(s.top_customers, 0)                                                   top_customers
    ,COALESCE(s.risky_high_value, 0)                                                risky_high_value
    ,COALESCE(s.loyal_low_value, 0)                                                 loyal_low_value
    ,COALESCE(s.low_value, 0)                                                       low_value
    ,COALESCE(s.total_new_customers, 0)                                             total_new_customers
FROM revenue_yoy r
LEFT JOIN segment_by_quarter s ON r.quarter = s.acq_quarter
ORDER BY r.quarter;
 
/*================================================================================================================================================================================================
Query result snippet:
 
| quarter | cyr_rev   | lyr_rev   | rev_pct_diff | new_cust_rev | ret_cust_rev | new%  | top | risky | loyal | low | new_cust |
|---------|-----------|-----------|--------------|--------------|--------------|-------|-----|-------|-------|-----|----------|
| 2018-Q1 |  3 256,95 |      NULL |         NULL |     3 256,95 |         0,00 | 100,0 |   4 |     0 |     4 |   4 |       12 |
| 2018-Q2 | 20 083,21 |      NULL |         NULL |    20 083,21 |         0,00 | 100,0 |  20 |     0 |    15 |   8 |       43 |
| 2018-Q3 | 25 157,12 |      NULL |         NULL |    22 913,32 |     2 243,80 |  91,1 |   9 |     2 |    18 |   9 |       38 |
| 2018-Q4 | 22 805,19 |      NULL |         NULL |    19 741,56 |     3 063,63 |  86,6 |  16 |     1 |    25 |  25 |       67 |
| 2019-Q1 | 24 741,12 |  3 256,95 |       659,63 |    20 638,53 |     4 102,60 |  83,4 |  14 |     2 |     9 |   7 |       32 |
| 2019-Q2 | 22 395,39 | 20 083,21 |        11,51 |    18 002,50 |     4 392,89 |  80,4 |   6 |     3 |    11 |  13 |       33 |
| 2019-Q3 | 15 343,97 | 25 157,12 |       -39,01 |     9 979,32 |     5 364,65 |  65,0 |   5 |     1 |    10 |  12 |       28 |
| 2019-Q4 | 30 826,62 | 22 805,19 |        35,18 |    24 445,34 |     6 381,28 |  79,3 |  12 |     6 |    17 |  19 |       54 |
| 2020-Q1 | 17 415,10 | 24 741,12 |       -29,61 |    11 849,45 |     5 565,65 |  68,0 |   6 |     1 |    10 |  14 |       31 |
| 2020-Q2 | 27 129,42 | 22 395,39 |        21,14 |     7 271,37 |    19 858,05 |  26,8 |   5 |     0 |     9 |  13 |       27 |
| 2020-Q3 | 36 663,72 | 15 343,97 |       138,90 |    26 257,12 |    10 406,60 |  71,6 |  10 |     4 |    10 |  12 |       36 |
| 2020-Q4 | 40 716,83 | 30 826,62 |        32,08 |    23 077,68 |    17 639,15 |  56,7 |   9 |     3 |    19 |  22 |       53 |
| 2021-Q1 | 31 525,28 | 17 415,10 |        81,03 |     9 354,14 |    22 171,14 |  29,7 |   0 |     3 |     7 |  12 |       22 |
| 2021-Q2 | 26 714,29 | 27 129,42 |        -1,53 |     6 444,80 |    20 269,49 |  24,1 |   2 |     1 |     2 |  22 |       27 |
| 2021-Q3 | 42 513,58 | 36 663,72 |        15,95 |    19 441,16 |    23 072,42 |  45,7 |   2 |     6 |     4 |  17 |       29 |
| 2021-Q4 | 47 976,29 | 40 716,83 |        17,83 |    17 754,29 |    30 222,00 |  37,0 |   0 |     6 |     3 |  24 |       33 |
 
📝 Notes & Reflections
 
   The most important trend is the growth of returning customer revenue (ret_cust_rev):
   from 0 in Q1 2018 (naturally — the business was new) to 30,222 in Q4 2021 — accounting
   for 63% of total quarterly revenue. This is a sign of a maturing, healthy business
   that is successfully retaining and monetizing its existing customer base.
 
   The shift in acquisition mix (fewer top_customers in 2021) is visible, but its business
   impact is smaller than it first appeared. In 2021:
   - Q1: 70.3% of revenue came from returning customers, despite zero top_customer acquisitions
   - Q4: 63.0% of revenue from returning customers, with total revenue growing +17.83% YoY
 
   This means California's 2021 revenue growth was driven by returning customer revenue —
   the accumulated value of customers acquired in earlier years who continued purchasing.
 
   The segment composition of new acquisitions matters for future sustainability, but the
   current revenue trajectory is supported by a strong returning customer base.
 
The segment labels for 2021 acquisitions are subject to tenure bias (see query 5️⃣.4️⃣).
   Many customers labeled "low_value" today may graduate to higher segments given more time.
================================================================================================================================================================================================*/
 
/*================================================================================================================================================================================================
5️⃣.3️⃣ 30 / 90 / 180 Days Retention Rate by Customer Segment (Right-Censoring Corrected)
Goal: Examine whether top_customers retain better than loyal_low_value customers.
Context: If top_customers retain at a higher rate, it validates the revenue-based segmentation
            and confirms that acquiring high-revenue repeat buyers is worth the investment.
 
Methodological notes:
 
    1. Retention is measured per purchase occasion (each order is a row), not per unique customer.
       A customer with 10 orders contributes 10 rows to the denominator. This measures "what
       fraction of purchase events are followed by another purchase within X days."
 
    2. low_value and risky_high_value segments are one-time buyers (orders_cnt = 1).
       They have no subsequent order BY DEFINITION, so their retention is guaranteed to be 0%.
       This is a consequence of segmentation logic, not an analytical finding.
       The meaningful comparison is between top_customer and loyal_low_value only.
 
    3. Right-censoring correction: a purchase occasion is only eligible for a given retention
       window if the full window fits within the available data (ending 2022-01-25).
       Without this, orders from late 2021 would appear as "not retained" simply because
       there wasn't enough observation time — artificially deflating retention rates.
       Example: a December 2021 order has only ~25 days of follow-up data and is therefore
       excluded from the 90-day and 180-day windows, but included in the 30-day window.
 
    4. Customers acquired in 2022 are excluded from segmentation but their January 2022
       orders serve as valid next_order targets for late-2021 purchases.
================================================================================================================================================================================================*/
 
WITH customer_metrics AS
(
SELECT
    o.customer_id
    ,COUNT(DISTINCT o.order_id)                                                     orders_cnt
    ,SUM(op.item_quantity*COALESCE(p.product_price, 0)
        *(1-COALESCE(op.position_discount, 0)))                                     total_revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
WHERE o.delivery_state = 'California'
GROUP BY o.customer_id
HAVING EXTRACT(YEAR FROM MIN(o.order_date)) < 2022
), customer_segmented AS
(
SELECT
    customer_id
    ,CASE
        WHEN orders_cnt > 1 AND total_revenue >= 1000 THEN 'top_customer'
        WHEN orders_cnt = 1 AND total_revenue >= 1000 THEN 'risky_high_value'
        WHEN orders_cnt > 1                            THEN 'loyal_low_value'
        ELSE 'low_value'
    END                                                                             customer_segment
FROM customer_metrics
), customer_orders AS
(
-- All California orders including 2022 — needed as valid next_order targets.
-- Right-censoring filter in the final SELECT controls eligibility.
SELECT DISTINCT
    o.customer_id
    ,o.order_id
    ,o.order_date
FROM orders o
WHERE o.delivery_state = 'California'
  AND o.customer_id IN (SELECT customer_id FROM customer_segmented)
), customer_next_purchase AS
(
SELECT
    a.customer_id
    ,a.order_date                                                                   current_order_date
    ,s.customer_segment
    ,LEAD(a.order_date) OVER (
        PARTITION BY a.customer_id
        ORDER BY a.order_date, a.order_id)                                          next_order_date
FROM customer_orders a
JOIN customer_segmented s ON a.customer_id = s.customer_id
)
SELECT
    customer_segment
 
    -- 180-day retention (only purchase occasions with full 180-day observation window)
    ,COUNT(CASE
        WHEN DATEDIFF('2022-01-25', current_order_date) >= 180
        THEN 1
    END)                                                                            eligible_180d
    ,COUNT(CASE
        WHEN DATEDIFF('2022-01-25', current_order_date) >= 180
         AND DATEDIFF(next_order_date, current_order_date) <= 180
        THEN 1
    END)                                                                            retained_180d
    ,ROUND(
        COUNT(CASE
            WHEN DATEDIFF('2022-01-25', current_order_date) >= 180
             AND DATEDIFF(next_order_date, current_order_date) <= 180
            THEN 1
        END) * 100.0 /
        NULLIF(COUNT(CASE
            WHEN DATEDIFF('2022-01-25', current_order_date) >= 180
            THEN 1
        END), 0)
    , 2)                                                                            retention_rate_180d_pct
 
    -- 90-day retention (only purchase occasions with full 90-day observation window)
    ,COUNT(CASE
        WHEN DATEDIFF('2022-01-25', current_order_date) >= 90
        THEN 1
    END)                                                                            eligible_90d
    ,COUNT(CASE
        WHEN DATEDIFF('2022-01-25', current_order_date) >= 90
         AND DATEDIFF(next_order_date, current_order_date) <= 90
        THEN 1
    END)                                                                            retained_90d
    ,ROUND(
        COUNT(CASE
            WHEN DATEDIFF('2022-01-25', current_order_date) >= 90
             AND DATEDIFF(next_order_date, current_order_date) <= 90
            THEN 1
        END) * 100.0 /
        NULLIF(COUNT(CASE
            WHEN DATEDIFF('2022-01-25', current_order_date) >= 90
            THEN 1
        END), 0)
    , 2)                                                                            retention_rate_90d_pct
 
    -- 30-day retention (only purchase occasions with full 30-day observation window)
    ,COUNT(CASE
        WHEN DATEDIFF('2022-01-25', current_order_date) >= 30
        THEN 1
    END)                                                                            eligible_30d
    ,COUNT(CASE
        WHEN DATEDIFF('2022-01-25', current_order_date) >= 30
         AND DATEDIFF(next_order_date, current_order_date) <= 30
        THEN 1
    END)                                                                            retained_30d
    ,ROUND(
        COUNT(CASE
            WHEN DATEDIFF('2022-01-25', current_order_date) >= 30
             AND DATEDIFF(next_order_date, current_order_date) <= 30
            THEN 1
        END) * 100.0 /
        NULLIF(COUNT(CASE
            WHEN DATEDIFF('2022-01-25', current_order_date) >= 30
            THEN 1
        END), 0)
    , 2)                                                                            retention_rate_30d_pct
 
FROM customer_next_purchase
GROUP BY customer_segment
ORDER BY retention_rate_90d_pct DESC;
 
/*================================================================================================================================================================================================
Query result snippet:
 
| customer_segment | eligible_180d | retained_180d | rate_180d | eligible_90d | retained_90d | rate_90d | eligible_30d | retained_30d | rate_30d |
|------------------|---------------|---------------|-----------|--------------|--------------|----------|--------------|--------------|----------|
| top_customer     |           264 |            56 |     21,21 |          294 |           31 |    10,54 |          313 |            7 |     2,24 |
| loyal_low_value  |           324 |            45 |     13,89 |          362 |           28 |     7,73 |          399 |           14 |     3,51 |
| risky_high_value |            29 |             0 |      0,00 |           34 |            0 |     0,00 |           39 |            0 |     0,00 |
| low_value        |           198 |             0 |      0,00 |          217 |            0 |     0,00 |          233 |            0 |     0,00 |
 
📝 Notes & Reflections
   The meaningful comparison is between top_customer and loyal_low_value — both are repeat
   buyer segments, so their retention reflects genuine behavioral differences.
 
   At longer time horizons, top_customer leads clearly:
   - 180 days: top_customer 21.21% vs loyal_low_value 13.89% (1.5× higher)
   - 90 days:  top_customer 10.54% vs loyal_low_value 7.73% (1.4× higher)
 
   However, at the 30-day window, the pattern reverses:
   - 30 days:  top_customer 2.24% vs loyal_low_value 3.51%
 
   This is a noteworthy finding. loyal_low_value customers are MORE likely to make a quick
   follow-up purchase (within 30 days), but less likely to return over longer periods.
   top_customers return less frequently in the short term, but sustain engagement over months.
 
   This pattern suggests different purchasing cadences: loyal_low_value may represent frequent,
   small basket shoppers, while top_customers make larger, more deliberate purchases at wider
   intervals. Both behaviors have business value — but top_customers contribute disproportionately
   to revenue per retained occasion due to their higher order values.
 
   low_value and risky_high_value show 0% retention across all windows. This is a definitional
   consequence: both segments have orders_cnt = 1, so LEAD() always returns NULL. It confirms
   these customers did not return, but this was already known from the segment assignment.
================================================================================================================================================================================================*/
 
/*================================================================================================================================================================================================
5️⃣.4️⃣ Cohort Repeat Rate — Controlling for Tenure Bias (Quarterly Granularity)
Goal: Validate whether the decline in acquisition quality visible in queries 5️⃣.1️⃣ and 5️⃣.2️⃣
         is real or an artifact of newer customers having less time to demonstrate repeat behavior.
Context: A customer acquired in 2018 had ~4 years to accumulate revenue and repeat purchases.
            A customer acquired in Q4 2021 had ~2 months. This query compares cohorts using a
            fixed 90-day window from first purchase — giving every cohort an equal opportunity.
 
            Only cohorts whose first purchase occurred at least 90 days before the end of the
            dataset (2022-01-25) are included to avoid right-censoring bias.
================================================================================================================================================================================================*/
 
WITH first_orders AS
(
SELECT
    customer_id
    ,MIN(order_date)                                                                first_order_date
    ,CONCAT(EXTRACT(YEAR FROM MIN(order_date)), '-Q',
        QUARTER(MIN(order_date)))                                                   acq_quarter
    ,EXTRACT(YEAR FROM MIN(order_date))                                             acq_year
FROM orders
WHERE delivery_state = 'California'
GROUP BY customer_id
-- 90-day observation window must fit within available data
HAVING DATEDIFF('2022-01-25', MIN(order_date)) >= 90
), repeat_within_90d AS
(
SELECT
    f.customer_id
    ,f.acq_quarter
    ,f.acq_year
    ,CASE WHEN EXISTS (
        SELECT 1 FROM orders o2
        WHERE o2.customer_id = f.customer_id
          AND o2.order_date > f.first_order_date
          AND DATEDIFF(o2.order_date, f.first_order_date) <= 90
          AND o2.delivery_state = 'California'
    ) THEN 1 ELSE 0 END                                                            repeated_90d
FROM first_orders f
)
SELECT
    acq_quarter                                                                     acquisition_quarter
    ,COUNT(*)                                                                       total_acquired
    ,SUM(repeated_90d)                                                              repeated_within_90d
    ,ROUND(SUM(repeated_90d) * 100.0 / COUNT(*), 2)                                repeat_rate_90d_pct
FROM repeat_within_90d
GROUP BY acq_quarter
ORDER BY acq_quarter;
 
/*================================================================================================================================================================================================
Query result snippet:
 
| acquisition_quarter | total_acquired | repeated_within_90d | repeat_rate_90d_pct |
|---------------------|----------------|---------------------|---------------------|
| 2018-Q1             |             12 |                   0 |                0,00 |
| 2018-Q2             |             43 |                   2 |                4,65 |
| 2018-Q3             |             38 |                   1 |                2,63 |
| 2018-Q4             |             67 |                   3 |                4,48 |
| 2019-Q1             |             32 |                   0 |                0,00 |
| 2019-Q2             |             33 |                   1 |                3,03 |
| 2019-Q3             |             28 |                   2 |                7,14 |
| 2019-Q4             |             54 |                   6 |               11,11 |
| 2020-Q1             |             31 |                   1 |                3,23 |
| 2020-Q2             |             27 |                   2 |                7,41 |
| 2020-Q3             |             36 |                   1 |                2,78 |
| 2020-Q4             |             53 |                   6 |               11,32 |
| 2021-Q1             |             22 |                   1 |                4,55 |
| 2021-Q2             |             27 |                   2 |                7,41 |
| 2021-Q3             |             29 |                   3 |               10,34 |
| 2021-Q4             |             10 |                   1 |               10,00 |
 
Yearly summary:
 
| acquisition_year | total_acquired | repeated_within_90d | repeat_rate_90d_pct |
|------------------|----------------|---------------------|---------------------|
|             2018 |            160 |                   6 |                3,75 |
|             2019 |            147 |                   9 |                6,12 |
|             2020 |            147 |                  10 |                6,80 |
|             2021 |             88 |                   7 |                7,95 |
 
📝 Notes & Reflections
   The cohort repeat rate tells a story that directly contradicts the earlier segmentation analysis.
 
   When every cohort is given the same 90-day observation window, the data shows a consistently
   IMPROVING trend: 3.75% (2018) → 6.12% (2019) → 6.80% (2020) → 7.95% (2021).
 
   The 2021 cohort has the highest repeat rate — nearly double the 2018 baseline. This means
   the appearance of fewer "top_customers" in 2021 cohorts (queries 5️⃣.1️⃣ and 5️⃣.2️⃣) was primarily
   a tenure bias artifact, not a genuine decline in customer quality. Customers acquired in 2021
   simply had less time to accumulate revenue and repeat purchases needed to cross the top_customer
   threshold (historical revenue >= 1,000 AND orders > 1). Given equal observation windows, they
   actually return at a higher rate than earlier cohorts.
 
   The quarterly breakdown adds nuance: Q4 cohorts consistently show the highest repeat rates
   within each year (4.48%, 11.11%, 11.32%, 10.00%), suggesting seasonal patterns — customers
   acquired during the holiday season may have stronger initial engagement.
 
   Important limitation: 2021-Q4 has only 10 eligible customers (vs 67 in 2018-Q4),
   making its 10.00% rate less statistically reliable. The yearly aggregates provide
   more stable estimates for trend analysis.
 
   Conclusion:
   California leads in revenue across all states. Its customer base is NOT deteriorating.
   When controlled for observation time, recent cohorts demonstrate improving early repeat
   behavior. The earlier segmentation (queries 5️⃣.1️⃣ and 5️⃣.2️⃣) correctly identified a shift
   in segment composition, but misattributed it to declining acquisition quality — when in fact
   it was driven by shorter observation windows.
 
   The revenue decomposition (query 5️⃣.2️⃣) revealed that by 2021, 63–70% of quarterly revenue
   came from returning customers — the accumulated value of earlier cohorts continuing to purchase.
   This is a sign of a maturing business, not a deteriorating one.
 
   The retention analysis (query 5️⃣.3️⃣) confirmed that among repeat buyers, higher-revenue customers
   return at roughly 1.4–1.5× the rate of lower-revenue ones at 90 and 180 days — while
   lower-revenue repeat customers show stronger 30-day re-purchase frequency, suggesting
   different but complementary purchasing cadences.
 
   The real story of California's revenue is one of a growing customer base with improving early engagement
   — whose full lifetime value has yet to materialize. Strategic impliaction is "invest in retention
   programs that convert the improving 90-day repeat rate into sustained long-term loyalty."
 
   This analysis has demonstrated that a single revenue metric tells almost nothing — and that
   even multi-step segmentation analysis can lead to incorrect conclusions when tenure bias
   is not controlled. The full story required understanding time, customer quality, acquisition
   patterns, retention behavior, and measurement bias — step by step.
