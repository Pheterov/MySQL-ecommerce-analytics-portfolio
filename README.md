# 🛒 SQL E-commerce Analytics Portfolio

> **Turning raw e-commerce data into revenue & retention insights**  
> MySQL 8+ • Window Functions • CTEs • Cohort & Pareto Analysis

---

## 👀 TL;DR — Why You Should Care

| What | Snapshot |
|------|---------|
| **Role Fit** | Junior+ / Mid Data Analyst, BI Analyst, E-commerce Analyst |
| **SQL Level** | Advanced: multi-table JOINs, CTEs, window functions, cohort analysis |
| **Business Impact** | Revenue growth, retention optimization, customer segmentation |
| **Code Quality** | Documented assumptions, reproducible pipelines, clean formatting |

> I don’t just analyze data or query tables — I look for decisions hidden inside the numbers.
---

## 📊 Highlighted Insights (Real Impact)

| Focus | Insight | Business Takeaway |
|-------|---------|-----------------|
| <p align="center">💰<br>Revenue Performance</p> | Top 10% products generate ~60% of revenue | Focus marketing & inventory on high-impact products |
| <p align="center">👥<br>Customer Retention(M+1)</p> </center> | M+1 retention: 9–13% early, 15–40% later | Shift from acquisition-heavy to retention strategy |
| <p align="center">🚚<br>Delivery Efficiency</p>  | ~15% orders consistently delayed | Potential logistics bottlenecks |
| <p align="center">🎯<br>Discount Impact</p>| Correlation with revenue & shipping delays | Informs promotion & pricing strategy |
<br>
Each insight highlights a measurable business opportunity based on real e-commerce data.

---

## 🔧 Tech Stack & Skills

![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?logo=mysql&logoColor=white)  
![DBeaver](https://img.shields.io/badge/DBeaver-IDE-382923?logo=dbeaver&logoColor=white)  

| Category | Techniques |
|----------|------------|
| **Fundamentals** | `JOIN`, `GROUP BY`, `CASE WHEN`, `COALESCE`, `NULLIF` |
| **Window Functions** | `LAG`, `LEAD`, `DENSE_RANK`, `NTILE`, `MIN() OVER` |
| **Advanced** | Multi-level CTEs, MoM comparisons, cohort logic |
| **Business Metrics** | Revenue, AOV, Retention Rate, Customer LTV, Pareto |

---

## 🗄️ Schema (Simple View)
orders ─┬── order_positions ─── products ─── product_groups
<br>
&emsp;&emsp;&emsp;&emsp;├── order_ratings
<br>
&emsp;&emsp;&emsp;&emsp;└── order_returns


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

**Top 10% Customer Contribution to Total Revenue**  
---
| top_10pct_revenue | total_revenue | top_10pct_revenue_pct |
|-------------------|---------------|-----------------------|
|    1 348 957,66   |  2 268 169,36 |                 59,47 |
<br>

💡 Key Insight:
Top 10% of customers generate nearly 60% of total revenue, highlighting the critical importance of retaining high-value clients for sustained business growth.

## **Monthly Revenue Breakdown: New vs Returning Customers**  
---
|       month      | new_customer_revenue | returning_customer_revenue | new_customer_revenue_pct | returning_customer_revenue_pct |
|------------|----------------------|----------------------------|--------------------------|--------------------------------|
| 2018-01-01   | 324,04 | [NULL] | 100 | [NULL] |
| 2018-02-01   | 14 470,88 | [NULL] | 100 | [NULL] |
| 2018-03-01   | 8 326,86 | 225,23 | 97,37 | 2,63 |
| 2018-04-01   | 39 682,17 | 1 150,89 | 97,18 | 2,82 |
| 2018-05-01   | 23 230,08 | 3 270,22 | 87,66 | 12,34 |
| 2018-06-01   | 23 276,30 | 6 036,73 | 79,41 | 20,59 |

💡 Key Insight:
New customers drive initial revenue, but the growing share of returning customers signals that retention strategies are key to sustainable growth.

---

## 📝 Documented Assumptions

```sql
-- Revenue = calculated at order_date
-- Discounts: 0–1 multiplier, NULL → treated as 0
-- Shipping_date < order_date → excluded
-- New customer = first order in calendar month
```

# 🎯 Bottom Line

If you need someone who writes SQL that actually drives decisions, this repo shows business-first, reproducible analysis with real e-commerce data.
