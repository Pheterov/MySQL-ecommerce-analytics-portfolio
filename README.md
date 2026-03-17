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
2019+: returning customers 15–40% (maturation)
What this tells a business: Transition from acquisition to retention strategy needed.

---

## 📝 Documented Assumptions

```sql
-- Revenue = calculated at order_date (regardless of shipping)
-- position_discount = multiplier 0–1 (0 = no discount)
-- NULL in discount/price → treated as 0
-- shipping_date < order_date → excluded from shipping metrics
-- "New customer" = first order in that calendar month
