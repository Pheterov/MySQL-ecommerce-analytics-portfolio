/*
===============================================================================
Project: SQL Analytics Portfolio — Supersales (Set 2)
Database: supersales modified by KajoData
Description: Advanced SQL exercises focused on delivery performance, customer
             spending behavior, discount analysis, and value segmentation.
===============================================================================
*/

/*
================================================================================
Task 1: Revenue and Order Count by Delivery State
Business Objective:
Measure regional sales performance by delivery state.
The query returns total revenue and unique order count for each delivery state.
================================================================================
*/
SELECT
    o.delivery_state
    ,ROUND(SUM(op.item_quantity*p.product_price*(1-op.position_discount)), 2) 	revenue
    ,COUNT(DISTINCT op.order_id) 												orders_cnt
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.delivery_state
ORDER BY revenue DESC;

/*
================================================================================
Task 2: Top 5 Cities by Units Sold
Business Objective:
Identify cities generating the highest sales volume in units sold.
Useful for logistics prioritization and regional commercial analysis.
================================================================================
*/
SELECT
    o.delivery_city
    ,SUM(op.item_quantity) 														items_sold
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
GROUP BY o.delivery_city
ORDER BY items_sold DESC
LIMIT 5;

/*
================================================================================
Task 3: Average Shipping Time by Shipping Mode
Business Objective:
Compare operational efficiency across shipping modes.
Measures average number of days between order placement and shipping.
In its current form, this task lacks context and provides limited value for the business. 
Adding metrics such as shipping time for specific products, orders with discounts,
 or comparisons between courier companies would make the analysis more actionable.
================================================================================
*/
SELECT
    o.shipping_mode
    ,ROUND(AVG(DATEDIFF(o.shipping_date, o.order_date)), 1) 					avg_delivery_time
FROM orders o
GROUP BY o.shipping_mode
ORDER BY avg_delivery_time;

/*
================================================================================
Task 4: Top Category by Units Sold in 2019
Business Objective:
Find the product category with the highest unit sales in the year 2019.
================================================================================
*/
WITH year_sales AS
(
SELECT
	pg.category
	,SUM(op.item_quantity) 														items_sold
FROM order_positions op
JOIN orders o ON op.order_id = o.order_id
JOIN products p ON op.product_id = p.product_id
JOIN product_groups pg ON p.group_id = pg.group_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2019
GROUP BY pg.category
)
SELECT
    category
    ,items_sold
FROM year_sales
ORDER BY items_sold DESC
LIMIT 1;

/*
================================================================================
Task 5: Running Total Revenue per Customer
Business Objective:
Track cumulative spending per customer from their first purchase onward.
Methodology:
- Revenue is first aggregated at order level to avoid merging multiple orders
  placed on the same day.
- Running total is calculated using a window function ordered by date and order_id.
================================================================================
*/
WITH customer_orders AS
(
SELECT
	o.customer_id
	,o.order_id
	,o.order_date
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount)) 		revenue
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
		ORDER BY order_date, order_id), 2) 										running_total_revenue
FROM customer_orders
ORDER BY customer_id, order_date, order_id;

/*
================================================================================
Task 6: Month-over-Month AOV Change
Business Objective:
Measure how average order value changes over time.
Methodology:
- Monthly revenue and order count are aggregated first.
- AOV is then compared with the previous month using LAG().
================================================================================
*/
WITH monthly_metrics AS 
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,COUNT(DISTINCT op.order_id) 												orders_cnt
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount))		revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
), monthly_averages AS
(
SELECT
	month
	,revenue
	,revenue / orders_cnt 														AoV
FROM monthly_metrics
)
SELECT
    MONTH
    ,ROUND(
        (AoV - LAG(AoV) OVER (ORDER BY month)) * 100.0 /
        LAG(AoV) OVER (ORDER BY month), 2) 										AoV_pct_change_vs_previous_month
FROM monthly_averages
ORDER BY month;

/*
================================================================================
Task 7: Top 2 Products by Revenue within Each Category
Business Objective:
Identify best-performing products inside each category.
Methodology:
- Revenue is aggregated by category and product.
- DENSE_RANK is used to preserve ties within category.
================================================================================
*/
WITH products_grouped AS 
(
SELECT
	pg.category
	,op.product_id
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount)) 		revenue
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
	,ROUND(revenue, 2)															revenue
	,DENSE_RANK() OVER (
	PARTITION BY category
	ORDER BY revenue DESC)														ranking
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

/*
================================================================================
Task 8: Customers Spending More Than in Previous Month
Business Objective:
Find customers whose monthly spending increased compared to the immediately
previous active month, but only if the previous active month is the actual
calendar month directly before the current one.
================================================================================
*/
WITH customer_monthly_spending AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 										month
	,o.customer_id
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount))		revenue
FROM orders o
JOIN order_positions op ON op.order_id = o.order_id
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
	ORDER BY month) 															prev_month
	,LAG(revenue) OVER (
	PARTITION BY customer_id 
	ORDER BY month) 															prev_month_revenue
FROM customer_monthly_spending
)
SELECT
    customer_id
    ,month
    ,ROUND(revenue, 2) 															current_month_revenue
    ,ROUND(prev_month_revenue, 2) 												prev_month_revenue
FROM spending_with_prev
WHERE prev_month = DATE_SUB(month, INTERVAL 1 MONTH) AND
	revenue > prev_month_revenue
ORDER BY customer_id, month;

/*
================================================================================
Task 9: Month+1 Purchase Return Rate
Business Objective:
Measure what percentage of customers active in a given month also purchased
in the following calendar month.
Methodology:
- Activity is deduplicated to customer-month level.
- LEAD is used to identify the next active month for each customer.
================================================================================
*/
WITH customers_month AS 
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01')										month
	,o.customer_id
FROM orders o
GROUP BY month, o.customer_id
), order_next AS 
(
SELECT
	month
	,customer_id
	,LEAD(month) OVER (PARTITION BY customer_id ORDER BY month) 				next_order
	,DATE_ADD(month, INTERVAL 1 MONTH) 											next_month
FROM customers_month
)
SELECT
    month
    ,COUNT(customer_id) 														monthly_customers
    ,COUNT(
	CASE WHEN next_order = next_month 
		THEN customer_id 
	END) 																		bought_next_month
    ,ROUND(
        COUNT(CASE WHEN next_order = next_month 
        THEN customer_id 
        END) * 100.0 /
        COUNT(customer_id), 2)													next_month_buyers_pct
FROM order_next
GROUP BY month
ORDER BY month;

/*
================================================================================
Task 10: Discount Effectiveness Analysis
Business Objective:
Since product cost is not available, discounts are evaluated by comparing
average order value for discounted vs non-discounted orders.
Methodology:
- Discount amount is calculated at position level.
- Order-level flag identifies whether the order contained any discount.
- Final comparison shows whether discounted orders tend to be larger or smaller.
================================================================================
*/
WITH position_values AS 
(
SELECT
	op.order_id
	,op.item_quantity * p.product_price * (1 - op.position_discount) 			position_value
	,(op.item_quantity * p.product_price) -
	(op.item_quantity * p.product_price * (1 - op.position_discount)) 			discount_value
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
), order_flags AS 
(
SELECT
	order_id
	,SUM(position_value) 														order_value
	,SUM(discount_value) 														total_discount_value
	,CASE
		WHEN SUM(discount_value) > 0
		THEN 1
		ELSE 0
	END 																		discounted_order
FROM position_values
GROUP BY order_id
)
SELECT
    ROUND(AVG(
    CASE WHEN discounted_order = 1
    	THEN order_value 
    END), 2) 																	avg_discounted_order_value
    ,ROUND(AVG(
    CASE WHEN discounted_order = 0 
    	THEN order_value 
    END), 2) 																	avg_non_discounted_order_value
    ,ROUND(
        AVG(CASE WHEN discounted_order = 1 THEN order_value END) -
        AVG(CASE WHEN discounted_order = 0 THEN order_value END),
        2
    ) 																			avg_order_value_diff
FROM order_flags;

/*
================================================================================
Task 11: Customer Value Segmentation with NTILE
Business Objective:
Segment customers into High / Medium / Low value groups based on total revenue.
Methodology:
- NTILE(5) is used to divide customers into quintiles.
- Top 20% are labeled "High Value".
- Second quintile is labeled "Medium Value".
- Remaining 60% are labeled "Low Value".
================================================================================
*/
WITH customer_revenue_totals AS 
(
SELECT
	o.customer_id
	,SUM(op.item_quantity * p.product_price * (1 - op.position_discount)) 		revenue
FROM orders o
JOIN order_positions op ON op.order_id = o.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.customer_id
), customer_segments AS
(
SELECT
	customer_id
	,revenue
	,NTILE(5) OVER (ORDER BY revenue DESC) 										percentile_group
FROM customer_revenue_totals
), customer_segment_revenue AS 
(
SELECT
	customer_id
	,revenue
	,CASE WHEN percentile_group = 1
		THEN 'High Value'
	WHEN percentile_group = 2
		THEN 'Medium Value'
		ELSE 'Low Value'
	END 																		segment
FROM customer_segments
)
SELECT
    segment
    ,ROUND(SUM(revenue), 2)														segment_revenue
FROM customer_segment_revenue
GROUP BY segment
ORDER BY segment_revenue DESC;
