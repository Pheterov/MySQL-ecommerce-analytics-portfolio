/*
===============================================================================
Project: E-commerce Analytics SQL Portfolio - Set 3
Module:  Advanced Analytics
Database: supersales modified by KajoData MySQL 8.0+
Description: Rolling metrics, Pareto analysis, cumulative sums.
             This is standard production code used in real business analytics.
===============================================================================
*/


/*
================================================================================
Task 1: 3-Month Rolling Average Revenue
Business Objective: Smooth revenue volatility and identify underlying trends.
Methodology:
- Calculates moving average only when full 3 month window is available.
- Explicitly handles edge cases for first months of dataset.
================================================================================
*/
WITH monthly_revenue AS (
SELECT
	DATE_FORMAT(order_date, '%Y-%m-01') 									month
	,SUM(op.item_quantity * p.product_price * (1 - position_discount)) 		revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
), rolling_avg AS 
(
SELECT
	month
	,revenue
	,AVG(revenue) OVER(
		ORDER BY month
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)							raw_rolling_avg
	,COUNT(revenue) OVER(
		ORDER BY month
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) 							rows_in_window
FROM monthly_revenue
)
SELECT
    month
    ,revenue
    ,ROUND(
        CASE WHEN rows_in_window = 3 
        THEN raw_rolling_avg 
        ELSE NULL 
        END, 2) 															rolling_avg_3m
FROM rolling_avg
ORDER BY month;

/*
================================================================================
Task 1: 3-Month Rolling Average Revenue
Solution #2 using SQL's default settings [NOT HANDLING EDGE CASES]
Business Objective: Smooth revenue volatility and identify underlying trends.
================================================================================
*/
WITH month_revenue AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') month
	,SUM(op.item_quantity*p.product_price*(1-op.position_discount)) 		revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
)
SELECT
	month
	,ROUND(revenue, 2) 														revenue
	,ROUND(
AVG(revenue) OVER(
ORDER BY month
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) 								rolling_avg_3m
FROM month_revenue
ORDER BY month;

/*
================================================================================
Task 2: Year To Date Cumulative Revenue
Business Objective: Track progress against annual budget targets.
Methodology:
- Partition running sum by calendar year.
- Reset cumulative sum on each year boundary.
================================================================================
*/
WITH month_revenue AS
(
SELECT
	EXTRACT(YEAR FROM o.order_date)											year
	,DATE_FORMAT(o.order_date, '%Y-%m-01')									month
	,SUM(op.item_quantity*p.product_price*(1-op.position_discount))			revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY year,month
)
SELECT
	month
	,ROUND(revenue, 2)														revenue
	,ROUND(SUM(revenue) OVER(
	PARTITION BY year
	ORDER BY month), 2)														revenue_ytd
	,year
FROM month_revenue
ORDER BY month;


/*
================================================================================
Task 3: Pareto Revenue Concentration Analysis
Business Objective: Verify 80/20 rule on customer base.
Methodology:
- Sort customers descending by total lifetime revenue.
- Calculate cumulative revenue percentage.
- Identify minimum percentage of customers generating 80% of total revenue.

Analytical Insight:
Top 50% of customers generate 80% of company's total revenue.
================================================================================
*/
WITH customer_revenue AS
(
SELECT
	o.customer_id
	,SUM(op.item_quantity *p.product_price*(1-op.position_discount))		revenue
FROM orders o
JOIN order_positions op 
	ON o.order_id = op.order_id
JOIN products p 
	ON op.product_id = p.product_id
GROUP BY o.customer_id
), ranked_customers AS
(
SELECT
	customer_id
	,revenue
	,SUM(revenue) OVER(ORDER BY revenue DESC)								cumulative_revenue
	,SUM(revenue) OVER()													total_revenue
FROM customer_revenue
)
SELECT
	customer_id
	,ROUND(revenue,2)														revenue
	,ROUND(cumulative_revenue / total_revenue * 100.0 , 2)					cumulative_revenue_pct
	,CASE
		WHEN cumulative_revenue / total_revenue <= 0.8
		THEN 'Top 80% revenue customers'
		ELSE 'Remaining customers'
	END																		pareto_segment
FROM ranked_customers
ORDER BY revenue DESC;


/*
Bonus question calculation: What percentage of customers generate 80% of revenue?
*/
WITH customer_revenue AS
(
SELECT
	o.customer_id
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount))	revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.customer_id
), ranked_customers AS
(
SELECT
	customer_id
	,SUM(revenue) OVER(ORDER BY revenue DESC)								cumulative_revenue
	,SUM(revenue) OVER()													total_revenue
FROM customer_revenue
)
SELECT
	ROUND(COUNT(*)/ (SELECT COUNT(*) FROM customer_revenue)*100.0, 2)		pct_customers_generating_80pct_revenue
FROM ranked_customers
WHERE cumulative_revenue / total_revenue <= 0.8;

/*
================================================================================
Task 4: Churn Analysis (90-Day Definition)
Business Objective:
Identify customers who have gone silent for 90+ days after any purchase.
This uses event-based churn definition: a customer can enter churn multiple times
if they return and then become inactive again.

Methodology:
- Churn occurs 90 days after a customer's last purchase.
- A customer can experience multiple churn events if they return after >90 days.
- This model captures both "final churn" and "temporary churn episodes".
================================================================================
*/
WITH customer_orders AS
(
SELECT
	o.customer_id
	,o.order_date
	,DATE_ADD(o.order_date, INTERVAL 90 DAY)								churn_date
	,LEAD(o.order_date) OVER(
	PARTITION BY customer_id
	ORDER BY order_date)													next_order
FROM orders o
), churn_flags AS
(
SELECT
	customer_id
	,churn_date
	,next_order
	,CASE WHEN
		next_order IS NULL
		AND CURDATE() >= churn_date
		THEN 1
		WHEN next_order IS NOT NULL
		AND next_order > churn_date
		THEN 1
		ELSE 0
		END																	is_churned
FROM customer_orders
)
SELECT
	DATE_FORMAT(churn_date, '%Y-%m-01')										churn_month
	,COUNT(DISTINCT
		CASE WHEN
			is_churned
		THEN customer_id
		END)																churned_customers
FROM churn_flags
GROUP BY churn_month
ORDER BY churn_month;

/*
================================================================================
Task 5: 7-Day Centered Moving Average (Daily Revenue)
Business Objective:
Smooth daily revenue fluctuations to identify underlying trends.
Uses centered window: 3 days back + current day + 3 days forward.

Note:
ROWS BETWEEN counts physical rows, not calendar days.
If data has gaps (e.g. no sales on weekends), the window may span
more than 7 calendar days. For strict calendar-day windows,
a date spine (calendar table) would be required.
================================================================================
*/
WITH daily_revenue AS
(
SELECT
	o.order_date
	,SUM(op.item_quantity*p.product_price*(1-op.position_discount))			revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id 
JOIN products p ON op.product_id = p.product_id
GROUP BY order_date
)
SELECT
	order_date
	,ROUND(revenue, 2)														daily_revenue
	,ROUND(AVG(revenue) OVER(
	ORDER BY order_date 
	ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING), 2) 							ma_seven
FROM daily_revenue
ORDER BY order_date;