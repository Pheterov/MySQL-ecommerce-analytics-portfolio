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

>I don’t just query tables — I extract decisions hidden in data.

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

---

## 🏆 Sample Output (Interpretation Ready)

**Monthly Revenue Snapshot**  
| month | revenue | unique_customers | orders | AoV |
|-------|---------|----------------|--------|-----|
| 2018-01 | 324.04 | 3 | 3 | 108.01 |
| 2018-02 | 14,470.88 | 32 | 32 | 452.22 |
| 2018-03 | 8,552.10 | 38 | 40 | 213.80 |



**Retention Insight (M+1)**  
| month | active_customers | retained | retention_rate |
|-------|----------------|----------|----------------|
| 2018-02 | 32 | 3 | 9.38% |
| 2018-03 | 38 | 5 | 13.16% |
| 2018-04 | 63 | 4 | 6.35% |
| 2018-05 | 67 | 7 | 10.45% |
| 2018-06 | 67 | 6 | 8.96% |

Early stage: heavy acquisition → later stage: focus on returning customer revenue (15–40%)

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

> I don’t just analyze data — I look for decisions hidden inside the numbers.
