# 🛒 SQL E-commerce Analytics Portfolio

> **Business-focused SQL analysis on e-commerce data**  
> MySQL 8+ • Window Functions • CTEs • Retention & Revenue Analytics

---

## 👔 For Recruiters — TL;DR

| What | Details |
|------|---------|
| **Role fit** | Junior+ / Mid Data Analyst, BI Analyst, E-commerce Analyst |
| **SQL level** | Window functions, CTEs, multi-table JOINs, business metrics |
| **Business focus** | Revenue, retention, customer segmentation, growth attribution |
| **Code quality** | Documented assumptions, consistent formatting, production-style |

### 🎯 Key Queries Included
✅ Monthly KPIs (revenue, AOV, orders)  
✅ M+1 Customer Retention Rate  
✅ New vs Returning Customer Revenue Split  
✅ Top Products by Revenue (monthly ranking)  
✅ Pareto Analysis (top 10% products contribution)  
✅ Discount Impact on Shipping & Revenue  

**Bottom line**: If you need someone who writes SQL that answers business questions—not just joins tables—this is what that looks like.

---

## 🔧 Tech Stack

![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?logo=mysql&logoColor=white)
![DBeaver](https://img.shields.io/badge/DBeaver-IDE-382923?logo=dbeaver&logoColor=white)

---

## 📊 Skills Demonstrated

| Category | Techniques |
|----------|------------|
| **Fundamentals** | `JOIN`, `GROUP BY`, `CASE WHEN`, `COALESCE`, `NULLIF` |
| **Window Functions** | `LAG`, `LEAD`, `DENSE_RANK`, `NTILE`, `MIN() OVER` |
| **Advanced** | Multi-level CTEs, MoM comparisons, cohort logic |
| **Business Metrics** | Revenue, AOV, Retention Rate, Customer LTV, Pareto |

---

## 🗄️ Database Schema

orders ─┬── order_positions ─── products ─── product_groups
<br>
├── order_ratings (1:1)
<br>
└── order_returns (1:1)


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

## 📈 Sample Output

**Query 1 Monthly Revenue Performance**
| month | revenue | unique_customers | orders | AOV |
|-------|---------|------------------|--------|-----|
| 2018-01 | 324.04 | 3 | 3 | 108.01 |
| 2018-02 | 14,470.88 | 32 | 32 | 452.22 |
| 2018-03 | 8,552.10 | 38 | 40 | 213.80 |

**Query 10 M+1 Retention Rate**
| month | active_customers | retained | retention_rate |
|-------|------------------|----------|----------------|
| 2018-02 | 32 | 3 | 9.38% |
| 2018-03 | 38 | 5 | 13.16% |

**Query 11 (Growth Attribution) reveals:**

2018: 97%+ new customer revenue (acquisition phase)
<br>
2019+: returning customers 15–40% (maturation)
<br>
What this tells a business: Transition from acquisition to retention strategy needed.

---

## 📝 Documented Assumptions

```sql
-- Revenue = calculated at order_date (regardless of shipping)
-- position_discount = multiplier 0–1 (0 = no discount)
-- NULL in discount/price → treated as 0
-- shipping_date < order_date → excluded from shipping metrics
-- "New customer" = first order in that calendar month
```

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

> “I don’t just query tables — I extract decisions hidden in data.”

---

## 📊 Highlighted Insights (Real Impact)

| Focus | Insight | Business Takeaway |
|-------|---------|-----------------|
| Revenue Performance | Top 10% products generate ~60% of revenue | Focus marketing & inventory on high-impact products |
| Customer Retention | M+1 retention: 9–13% early, 15–40% later | Shift from acquisition-heavy to retention strategy |
| Delivery Efficiency | ~15% orders consistently delayed | Potential logistics bottlenecks |
| Discount Impact | Correlation with revenue & shipping delays | Informs promotion & pricing strategy |

---

## 🔧 Tech Stack & Skills

![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?logo=mysql&logoColor=white)  
![DBeaver](https://img.shields.io/badge/DBeaver-IDE-382923?logo=dbeaver&logoColor=white)  

**SQL Techniques:** `JOIN`, `GROUP BY`, `CASE WHEN`, `COALESCE`, `NULLIF`  
**Window Functions:** `LAG`, `LEAD`, `DENSE_RANK`, `NTILE`, `MIN() OVER`  
**Advanced:** Multi-level CTEs, MoM comparisons, cohort logic  
**Business Metrics:** Revenue, AOV, Retention Rate, Customer LTV, Pareto Analysis  

---

## 🗄️ Schema (Simple View)
orders ─┬── order_positions ─── products ─── product_groups
<br>
├── order_ratings
<br>
└── order_returns


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
| Month | Revenue | Unique Customers | Orders | AOV |
|-------|---------|----------------|--------|-----|
| 2018-01 | 324.04 | 3 | 3 | 108.01 |
| 2018-02 | 14,470.88 | 32 | 32 | 452.22 |
| 2018-03 | 8,552.10 | 38 | 40 | 213.80 |

**Retention Insight (M+1)**  
| Month | Active Customers | Retained | Retention Rate |
|-------|----------------|----------|----------------|
| 2018-02 | 32 | 3 | 9.38% |
| 2018-03 | 38 | 5 | 13.16% |

> Early stage: heavy acquisition → later stage: focus on returning customer revenue (15–40%)

---

## 📝 Documented Assumptions

```sql
-- Revenue = calculated at order_date
-- Discounts: 0–1 multiplier, NULL → treated as 0
-- Shipping_date < order_date → excluded
-- New customer = first order in calendar month
```

🎯 Bottom Line

If you need someone who writes SQL that actually drives decisions, this repo shows business-first, reproducible analysis with real e-commerce data.

I don’t just analyze data — I look for decisions hidden inside the numbers.
