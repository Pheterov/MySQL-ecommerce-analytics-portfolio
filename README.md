# 🛒 SQL E-commerce Analytics Portfolio

> **Turning raw e-commerce data into revenue & retention insights**  
> MySQL 8+ • Window Functions • CTEs • Cohort & Pareto Analysis

---

## 👀 Summary / Role Fit — Why You Should Care

| What | Snapshot |
|------|---------|
| **Role Fit** | Junior+ / Mid Data Analyst, BI Analyst, E-commerce Analyst |
| **SQL Level** | Advanced: multi-table JOINs, CTEs, window functions, cohort analysis |
| **Business Impact** | Revenue growth, retention optimization, customer segmentation |
| **Code Quality** | Documented assumptions, reproducible pipelines, clean formatting |

> I don’t just run queries — I dig into the numbers to find decisions that actually matter.

&nbsp;

## 📊 Highlighted Insights (Real Impact)

| Focus | Insight | Business Takeaway |
|-------|---------|-----------------|
| <p align="center">💰<br>Revenue Performance</p> | Top 10% customers generate ~60% of revenue. | Retaining top customers is key to growth. |
| <p align="center">👥<br>Customer Retention(M+1)</p> | New customers drive initial revenue; returning customers’ share grows over time | Focus on keeping customers, not just acquiring new ones. |
| <p align="center">🚚<br>Delivery Efficiency</p>  | ~15% of orders are consistently delayed | Look into logistics bottlenecks to improve delivery. |
| <p align="center">🎯<br>Discount Impact</p>| Discounts affect revenue and delivery times | Adjust pricing and promotions |

&nbsp;

## 🔧 Tech Stack & Skills

![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?logo=mysql&logoColor=white)  
![DBeaver](https://img.shields.io/badge/DBeaver-IDE-382923?logo=dbeaver&logoColor=white)  

| Category | Techniques |
|----------|------------|
| **Fundamentals** | `JOIN`, `GROUP BY`, `CASE WHEN`, `COALESCE`, `NULLIF` |
| **Window Functions** | `LAG`, `LEAD`, `DENSE_RANK`, `NTILE`, `MIN() OVER` |
| **Advanced** | Multi-level CTEs, MoM comparisons, cohort logic |
| **Business Metrics** | Revenue, AOV, Retention Rate, Customer LTV, Pareto |

&nbsp;

## 🗄️ Schema (Simple View)
orders ─┬── order_positions ─── products ─── product_groups  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── order_ratings  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── order_returns  

<details>
<summary>📋 Click for full table structure</summary>

| Table | Key Columns |
|-------|-------------|
| `orders` | order_id, customer_id, order_date, shipping_date, shipping_mode |
| `order_positions` | order_id, product_id, item_quantity, position_discount |
| `products` | product_id, product_name, product_price, group_id |
| `product_groups` | group_id, category, product_group |

</details>


## 🏆 Sample Output (Interpretation Ready)

**Monthly Revenue Breakdown: New vs Returning Customers**  

*Dates are shown as MM-YY for compactness.*

| month       | new_customer_revenue | returning_customer_revenue | new_revenue_pct | returning_revenue_pct |
|------------|----------------------|----------------------------|----------------|----------------------|
| 01-18' | 324,04               | [NULL]                     | 100            | [NULL]               |
| 02-18' | 14 470,88            | [NULL]                     | 100            | [NULL]               |
| 03-18' | 8 326,86             | 225,23                      | 97,37          | 2,63                 |
| 04-18' | 39 682,17            | 1 150,89                    | 97,18          | 2,82                 |
| 05-18' | 23 230,08            | 3 270,22                     | 87,66          | 12,34                |
| 06-18' | 23 276,30            | 6 036,73                     | 79,41          | 20,59                |

&nbsp;

## **💡 Key Insight:**  
New customers bring in the first revenue, but returning customers gradually take a bigger share. Retention is what keeps growth steady.

&nbsp;

## 📝 Documented Assumptions

```sql
-- Revenue = calculated at order_date
-- Discounts: 0–1 multiplier, NULL → treated as 0
-- Shipping_date < order_date → excluded
-- New customer = first order in calendar month
```

## 🎯 Bottom Line

This repository demonstrates business-focused, reproducible SQL analyses on real e-commerce data.
