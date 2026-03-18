/*
===============================================================================
Project: E-commerce Analytics SQL Portfolio Set 3
Database: supersales - modified by KajoData MySQL 8.0+
Author: Piotr Rzepka
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

/*
===============================================================================
Project: E-commerce Analytics SQL Portfolio Set 3
Database: supersales - modified by KajoData MySQL 8.0+
Author: Piotr Rzepka
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
==================================================================================================================================================================================================*/
SELECT
	o.delivery_state
	,ROUND(SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))), 2) 	revenue
	,COUNT(DISTINCT op.order_id)																		orders_cnt
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY o.delivery_state
ORDER BY revenue DESC;

/*===================================================================================================
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
), final AS
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
FROM final
ORDER BY revenue DESC;



/*===================================================================================================
2️⃣ Top 5 Cities by Units Sold
🎯 Goal: Identify high-volume cities for logistics optimization
🛠️ Stack: SQL
💡 Impact: Prioritizes warehouse locations and delivery routes
====================================================================================================*/
SELECT
	o.delivery_city
	,SUM(op.item_quantity) 																				items_sold
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
GROUP BY o.delivery_city
ORDER BY items_sold DESC
LIMIT 5;

/*===================================================================================================
3️⃣ Average Shipping Time by Shipping Mode
🎯 Goal: Compare operational efficiency across shipping methods
🛠️ Stack: SQL
💡 Impact: Identifies fastest shipping options for customer satisfaction
====================================================================================================*/
SELECT
	o.shipping_mode
	,ROUND(AVG(
		DATEDIFF(o.shipping_date, o.order_date)), 1) 													avg_delivery_time
FROM orders o
WHERE o.shipping_date >= o.order_date
GROUP BY o.shipping_mode
ORDER BY avg_delivery_time;

/*===================================================================================================
4️⃣ Top Category by Units Sold in 2019
🎯 Goal: Identify best-performing category for inventory planning
🛠️ Stack: SQL
💡 Impact: Guides procurement and marketing focus
====================================================================================================*/
WITH year_sales AS
(
SELECT
	pg.category
	,SUM(op.item_quantity) 																				items_sold
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

/*===================================================================================================
5️⃣ Running Total Revenue per Customer
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
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))) 			revenue
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
ORDER BY order_date, order_id), 2)																	 	running_total_revenue
FROM customer_orders
ORDER BY customer_id, order_date, order_id;

/*===================================================================================================
6️⃣ Month-over-Month AOV Change
🎯 Goal: Measure average order value trends
🛠️ Stack: SQL
💡 Impact: Identifies pricing strategy effectiveness
====================================================================================================*/
WITH monthly_metrics AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01')						 										month
	,COUNT(DISTINCT op.order_id) 																		orders_cnt
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))) 			revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
), monthly_averages AS
(
SELECT
month
	,revenue
	,revenue / orders_cnt 																				AoV
FROM monthly_metrics
)
SELECT
	month
	,ROUND(
		(AoV - LAG(AoV) OVER (ORDER BY month)) * 100.0 /
		NULLIF(LAG(AoV) OVER (ORDER BY month),0), 2) AoV_pct_change_vs_previous_month
FROM monthly_averages
ORDER BY month;

/*===================================================================================================
7️⃣ Top 2 Products by Revenue within Each Category
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
	(1-COALESCE(op.position_discount,0))) 																revenue
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
	,ROUND(revenue, 2)																					revenue
	,DENSE_RANK() OVER (
	PARTITION BY category
ORDER BY revenue DESC) 																					ranking
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
8️⃣ Customers Spending More Than in Previous Month
🎯 Goal: Identify customers with increasing spend patterns
🛠️ Stack: SQL
💡 Impact: Targets customers for upsell opportunities
====================================================================================================*/
WITH customer_monthly_spending AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 																month
	,o.customer_id
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))) 			revenue
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
	ORDER BY month) 																					prev_month
	,LAG(revenue) OVER (
	PARTITION BY customer_id
	ORDER BY month) 																					prev_month_revenue
FROM customer_monthly_spending
)
SELECT
	customer_id
	,month
	,ROUND(revenue, 2) 																					current_month_revenue
	,ROUND(prev_month_revenue, 2) prev_month_revenue
FROM spending_with_prev
WHERE prev_month = DATE_SUB(month, INTERVAL 1 MONTH) AND
	revenue > prev_month_revenue
ORDER BY customer_id, month;

/*===================================================================================================
9️⃣ Month+1 Purchase Return Rate
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
	ORDER BY month) 																					next_order
,DATE_ADD(month, INTERVAL 1 MONTH) 																		next_month
FROM customers_month
)
SELECT
	month
	,COUNT(customer_id) monthly_customers
	,COUNT(CASE
		WHEN next_order = next_month
		THEN customer_id
		END) 																							bought_next_month
	,ROUND(COUNT(CASE
		WHEN next_order = next_month
		THEN customer_id
	END) * 100.0 /
	COUNT(customer_id), 2) 																				next_month_buyers_pct
FROM order_next
GROUP BY month
ORDER BY month;

/*===================================================================================================
🔟 Discount Effectiveness Analysis
🎯 Goal: Evaluate impact of discounts on order value
🛠️ Stack: SQL
💡 Impact: Informs discount strategy optimization
====================================================================================================*/
WITH position_values AS
(
SELECT
	op.order_id
	,op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0)) 															position_value
	,(op.item_quantity*COALESCE(p.product_price,0)) -
		(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) 															discount_value
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
), order_flags AS
(
SELECT
	order_id
	,SUM(position_value) 																				order_value
	,SUM(discount_value) 																				total_discount_value
	,CASE
		WHEN SUM(discount_value) > 0
		THEN 1
		ELSE 0
	END																									discounted_order
FROM position_values
GROUP BY order_id
)
SELECT
	ROUND(AVG(CASE
		WHEN discounted_order = 1
		THEN order_value
	END), 2) 																							avg_discounted_order_value
	,ROUND(AVG(CASE
		WHEN discounted_order = 0
		THEN order_value
	END), 2) 																							avg_non_discounted_order_value
	,ROUND(AVG(CASE
		WHEN discounted_order = 1
		THEN order_value 
	END) -
	AVG(CASE
	WHEN discounted_order = 0
	THEN order_value 
	END), 2) 																							avg_order_value_diff
FROM order_flags;

/*===================================================================================================
1️⃣1️⃣ Customer Value Segmentation with NTILE
🎯 Goal: Segment customers by lifetime value
🛠️ Stack: SQL
💡 Impact: Enables targeted marketing strategies
====================================================================================================*/
WITH customer_revenue_totals AS
(
SELECT
	o.customer_id
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) 															revenue
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
		ORDER BY revenue DESC) 																			percentile_group
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
	END 																								segment
FROM customer_segments
)
SELECT
	segment
	,ROUND(SUM(revenue), 2) 																			segment_revenue
FROM customer_segment_revenue
GROUP BY segment
ORDER BY segment_revenue DESC;

/*===================================================================================================
2️⃣ Top 5 Cities by Units Sold
🎯 Goal: Identify high-volume cities for logistics optimization
🛠️ Stack: SQL
💡 Impact: Prioritizes warehouse locations and delivery routes
====================================================================================================*/
SELECT
	o.delivery_city
	,SUM(op.item_quantity) 																				items_sold
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
GROUP BY o.delivery_city
ORDER BY items_sold DESC
LIMIT 5;

/*===================================================================================================
3️⃣ Average Shipping Time by Shipping Mode
🎯 Goal: Compare operational efficiency across shipping methods
🛠️ Stack: SQL
💡 Impact: Identifies fastest shipping options for customer satisfaction
====================================================================================================*/
SELECT
	o.shipping_mode
	,ROUND(AVG(
		DATEDIFF(o.shipping_date, o.order_date)), 1) 													avg_delivery_time
FROM orders o
WHERE o.shipping_date >= o.order_date
GROUP BY o.shipping_mode
ORDER BY avg_delivery_time;

/*===================================================================================================
4️⃣ Top Category by Units Sold in 2019
🎯 Goal: Identify best-performing category for inventory planning
🛠️ Stack: SQL
💡 Impact: Guides procurement and marketing focus
====================================================================================================*/
WITH year_sales AS
(
SELECT
	pg.category
	,SUM(op.item_quantity) 																				items_sold
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

/*===================================================================================================
5️⃣ Running Total Revenue per Customer
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
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))) 			revenue
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
ORDER BY order_date, order_id), 2)																	 	running_total_revenue
FROM customer_orders
ORDER BY customer_id, order_date, order_id;

/*===================================================================================================
6️⃣ Month-over-Month AOV Change
🎯 Goal: Measure average order value trends
🛠️ Stack: SQL
💡 Impact: Identifies pricing strategy effectiveness
====================================================================================================*/
WITH monthly_metrics AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01')						 										month
	,COUNT(DISTINCT op.order_id) 																		orders_cnt
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))) 			revenue
FROM orders o
JOIN order_positions op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
GROUP BY month
), monthly_averages AS
(
SELECT
month
	,revenue
	,revenue / orders_cnt 																				AoV
FROM monthly_metrics
)
SELECT
	month
	,ROUND(
		(AoV - LAG(AoV) OVER (ORDER BY month)) * 100.0 /
		NULLIF(LAG(AoV) OVER (ORDER BY month),0), 2) AoV_pct_change_vs_previous_month
FROM monthly_averages
ORDER BY month;

/*===================================================================================================
7️⃣ Top 2 Products by Revenue within Each Category
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
	(1-COALESCE(op.position_discount,0))) 																revenue
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
	,ROUND(revenue, 2)																					revenue
	,DENSE_RANK() OVER (
	PARTITION BY category
ORDER BY revenue DESC) 																					ranking
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
8️⃣ Customers Spending More Than in Previous Month
🎯 Goal: Identify customers with increasing spend patterns
🛠️ Stack: SQL
💡 Impact: Targets customers for upsell opportunities
====================================================================================================*/
WITH customer_monthly_spending AS
(
SELECT
	DATE_FORMAT(o.order_date, '%Y-%m-01') 																month
	,o.customer_id
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*(1-COALESCE(op.position_discount,0))) 			revenue
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
	ORDER BY month) 																					prev_month
	,LAG(revenue) OVER (
	PARTITION BY customer_id
	ORDER BY month) 																					prev_month_revenue
FROM customer_monthly_spending
)
SELECT
	customer_id
	,month
	,ROUND(revenue, 2) 																					current_month_revenue
	,ROUND(prev_month_revenue, 2) prev_month_revenue
FROM spending_with_prev
WHERE prev_month = DATE_SUB(month, INTERVAL 1 MONTH) AND
	revenue > prev_month_revenue
ORDER BY customer_id, month;

/*===================================================================================================
9️⃣ Month+1 Purchase Return Rate
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
	ORDER BY month) 																					next_order
,DATE_ADD(month, INTERVAL 1 MONTH) 																		next_month
FROM customers_month
)
SELECT
	month
	,COUNT(customer_id) monthly_customers
	,COUNT(CASE
		WHEN next_order = next_month
		THEN customer_id
		END) 																							bought_next_month
	,ROUND(COUNT(CASE
		WHEN next_order = next_month
		THEN customer_id
	END) * 100.0 /
	COUNT(customer_id), 2) 																				next_month_buyers_pct
FROM order_next
GROUP BY month
ORDER BY month;

/*===================================================================================================
🔟 Discount Effectiveness Analysis
🎯 Goal: Evaluate impact of discounts on order value
🛠️ Stack: SQL
💡 Impact: Informs discount strategy optimization
====================================================================================================*/
WITH position_values AS
(
SELECT
	op.order_id
	,op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0)) 															position_value
	,(op.item_quantity*COALESCE(p.product_price,0)) -
		(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) 															discount_value
FROM order_positions op
JOIN products p ON op.product_id = p.product_id
), order_flags AS
(
SELECT
	order_id
	,SUM(position_value) 																				order_value
	,SUM(discount_value) 																				total_discount_value
	,CASE
		WHEN SUM(discount_value) > 0
		THEN 1
		ELSE 0
	END																									discounted_order
FROM position_values
GROUP BY order_id
)
SELECT
	ROUND(AVG(CASE
		WHEN discounted_order = 1
		THEN order_value
	END), 2) 																							avg_discounted_order_value
	,ROUND(AVG(CASE
		WHEN discounted_order = 0
		THEN order_value
	END), 2) 																							avg_non_discounted_order_value
	,ROUND(AVG(CASE
		WHEN discounted_order = 1
		THEN order_value 
	END) -
	AVG(CASE
	WHEN discounted_order = 0
	THEN order_value 
	END), 2) 																							avg_order_value_diff
FROM order_flags;

/*===================================================================================================
1️⃣1️⃣ Customer Value Segmentation with NTILE
🎯 Goal: Segment customers by lifetime value
🛠️ Stack: SQL
💡 Impact: Enables targeted marketing strategies
====================================================================================================*/
WITH customer_revenue_totals AS
(
SELECT
	o.customer_id
	,SUM(op.item_quantity*COALESCE(p.product_price,0)*
		(1-COALESCE(op.position_discount,0))) 															revenue
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
		ORDER BY revenue DESC) 																			percentile_group
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
	END 																								segment
FROM customer_segments
)
SELECT
	segment
	,ROUND(SUM(revenue), 2) 																			segment_revenue
FROM customer_segment_revenue
GROUP BY segment
ORDER BY segment_revenue DESC;
