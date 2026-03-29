# The Story of California's Revenue: A Data-Driven Warning 

> **SQL Portfolio · E-Commerce Analytics**  
> Author: Piotr Rzepka · Database: `supersales` (MySQL 8.0+) · Period: 2018–2022

---

## Key Numbers at a Glance

| Metric | Value |
|---|---|
| California Total Revenue | $451,450 — #1 of all states |
| Orders Analyzed | 1,021 (2018–2021 complete) |
| Customer Segments | 4 (CLV-based model) |
| Low-value Share of New Acquisitions (Jan 2022) | ~92% |

---

## Executive Summary

California is the top-performing state in this e-commerce dataset — by total revenue, order count, and customer volume. On the surface, it tells a success story. But surface-level metrics are designed to flatter, not inform. This analysis begins with a single revenue figure and methodically peels back the layers underneath: a suspicious YoY anomaly, a data completeness gap, a volume surge that masked customer quality decline, and finally, a retention signal that confirms the fragility of California's recent growth. **The conclusion is sobering: since 2021, California's revenue growth has been built on customers who don't come back.** Without a strategic shift, the pipeline of high-value repeat buyers will continue to dry up — and the revenue trajectory is likely to follow.

> A single revenue metric tells almost nothing. The full story required understanding time, customer quality, acquisition patterns, and retention behavior — step by step.

---

## The Problem: What looks like SUCCES might be RISK

### Starting Point: Revenue by State

Every analysis begins somewhere. The natural starting point is the most visible metric: total revenue by delivery state. California leads decisively — $451,450 in revenue. New York follows at $312,377, and Texas at $164,948. On a dashboard, this looks like a clear answer to the question "Where should we focus?"

But this is precisely the **trap of vanity metrics**. A single aggregated figure collapses four years of business history into one number. It cannot tell us whether California is growing or declining, whether customers are returning, or whether the revenue base is structurally sound. It only tells us the final score — not how the game was played.

<img width="1084" height="606" alt="image" src="https://github.com/user-attachments/assets/c99b85d6-35d2-48d0-9094-8198bddde5eb" />
Chart 1: Revenue by Delivery State — California's outsized lead. The metric that would be reported to leadership, and the metric that, without deeper analysis, would lead to misallocated resources and false confidence.

---

## First Red Flag: The mysterious revenue drop

The logical next step was to examine California's performance over time. A year-over-year breakdown appeared to reveal a catastrophe: a near 90% revenue collapse between 2021 and 2022, dropping from $148,729 to just $16,186. For any analyst — or any executive reading a report — this would trigger immediate alarm.

**But good analysis demands skepticism before reaction.** A drop of this magnitude, from one year to the next without any external context, is statistically unlikely in a functioning business. The question isn't just "what happened?" — it's "is this real, or is something wrong with the data?"

A simple month-level breakdown of 2022 data immediately revealed the truth: the dataset for 2022 contains only January. The apparent collapse was not a business failure — it was an incomplete dataset being compared against a full calendar year. One month of revenue will most of the time look smaller than twelve.

<img width="1084" height="606" alt="image" src="https://github.com/user-attachments/assets/68e0c01c-3149-4d5a-8950-73abb0ac1c0c" />
Chart 2: California YoY Revenue and orders count — steady and consistent across 2018–2021. The apparent YoY and orders count cliff disappears entirely when the incomplete 2022 data is understood for what it is: a partial year, not a decline.

This moment illustrates a foundational analytical principle: **never draw conclusions from numbers you haven't validated.** A flawed report that reaches the wrong audience can trigger resource misallocation, false urgency, or misplaced confidence. Data completeness is not a technical detail — it is a business risk.

---

## Deeper Dive: Unpacking growth drivers

With data integrity confirmed, the analysis moved to understanding California's growth dynamics at a monthly level. Month-over-month and year-over-year metrics — revenue, order counts, unique customers, items sold, average order value, and discount depth — painted a picture of strong apparent growth in late 2021.

Revenue
<img width="1084" height="202" alt="image" src="https://github.com/user-attachments/assets/79128c37-da98-4cec-ba6f-4dcd934e364a" />

Orders
<img width="1084" height="202" alt="image" src="https://github.com/user-attachments/assets/6dfc6155-7678-413f-b5c3-379d0fdb61c6" />

Customers
<img width="1084" height="202" alt="image" src="https://github.com/user-attachments/assets/dc8d2a3d-284f-4cdc-9f77-f38434fa7d78" />

Items
<img width="1084" height="202" alt="image" src="https://github.com/user-attachments/assets/5a669231-64c3-47ad-a08e-7693cad3accd" />

AoV
<img width="1084" height="202" alt="image" src="https://github.com/user-attachments/assets/e503b0ef-ca4a-4089-ba59-534bb51e5f12" />

Discount Depth
<img width="1084" height="202" alt="image" src="https://github.com/user-attachments/assets/78275d06-a02a-4aa0-a97b-4fc9cc16a8e1" />


September 2021 showed +71.85% YoY revenue growth, nearly doubling items sold (+87%) and growing unique customers by +58%. November 2021 produced even more striking numbers: +111% revenue growth, with the same number of unique customers as the prior year. By conventional metrics, these are headline-worthy results.

But a critical question emerged: **what kind of customers were being acquired during these growth months?** Volume is easy to measure. Quality is harder — and far more important. Orders and customers are not interchangeable units. A business acquiring a thousand low-value, one-time buyers is in a fundamentally different position than one acquiring a hundred high-value repeat customers, even if the short-term revenue looks identical.

> **Key Analytical Decision:** Rather than accepting volume growth as success, the analysis shifted to a customer-quality lens. The question became not "how much did we grow?" but "who did we grow with?" This reframe is what separates descriptive reporting from genuine business intelligence.

---

## Customer segmentation & CLV analysis

To move beyond revenue as a proxy for value, a Customer Lifetime Value (CLV) model was constructed from first principles. CLV is defined here as a historical approximation:

```
CLV = avg_order_value × purchase_frequency × lifetime_months
```

This gives a single comparable figure per customer that reflects both the size and consistency of their purchasing behavior. A critical adjustment was applied: CLV was zeroed out for one-time buyers (`clv_retention_adjusted`), isolating customers who have demonstrably returned and distinguishing proven loyalty from a single high-value transaction that may never repeat.

### Segmentation Logic

Customers were classified into four segments based on repeat behavior and CLV score. The **CLV threshold of 1,000** was derived from the empirical distribution of California customer CLV (n = 577): the median CLV is 387.72 and the 75th percentile is 1,094.30, making 1,000 a defensible approximation of the **top quartile**.

| Segment | Definition | Business Value |
|---|---|---|
| `top_customer` | Repeat buyer with CLV ≥ 1,000 | Highest — retained, high spend |
| `risky_high_value` | One-time buyer with CLV ≥ 1,000 | Fragile — high spend, no proven loyalty |
| `loyal_low_value` | Repeat buyer with CLV < 1,000 | Stable — consistent but lower spend |
| `low_value` | One-time buyer with CLV < 1,000 | Lowest — unlikely to return |

This segmentation provides something that revenue alone cannot: a **quality signal**. It allows every acquisition cohort to be evaluated not just by how much customers spent, but by how likely they are to return and what their long-term contribution to the business might be.

---

## Key Insight: Growth ≠ Health

Applying the segmentation model to acquisition cohorts revealed the central finding of this analysis. In 2018–2020, months with strong YoY revenue were consistently backed by meaningful `top_customer` acquisition. October 2020 brought in 4 top customers alongside +49.55% YoY growth. December 2020 added 3 top customers with +78.6% revenue growth. The growth was real, and the customers driving it had demonstrated their willingness to return.

<img width="1084" height="202" alt="image" src="https://github.com/user-attachments/assets/ac3d2698-db26-402f-842e-6f04af0717ac" />

From 2021 onward, that pattern broke down. The months with the most dramatic revenue spikes — September 2021 (+71.85%), November 2021 (+111.05%), March 2021 (+179.05%) — acquired **zero or one top_customer**. The dominant segments were `low_value` and `risky_high_value`. Revenue numbers looked strong because volume was high. But the customers behind that volume had no demonstrated propensity to return.

<img width="1084" height="202" alt="image" src="https://github.com/user-attachments/assets/66177173-8891-4a83-919e-6db1f9b2ba6a" />

<img width="1086" height="606" alt="image" src="https://github.com/user-attachments/assets/a87a9f4a-e4f5-416f-9fcc-166c163a5699" />
<img width="1084" height="606" alt="image" src="https://github.com/user-attachments/assets/674304d1-cbc6-452d-b3e4-8ac1a379334f" />
Charts 3 and 4: The defining visual of this case study. Monthly YoY revenue growth (%) overlaid with top_customer acquisitions per month. The divergence is stark: the tallest revenue spikes in 2021 coincide with bars near zero for top_customer acquisition. The strongest top_customer months are concentrated in 2018–2020.

> We traded sustainable growth for fragile volume. The numbers looked better. The business got worse.

By December 2021 and January 2022, revenue had already begun to decline YoY. New acquisitions in those months were overwhelmingly `low_value`. **The pipeline of high-value customers was not being replenished.** Unlike a temporary dip in revenue, a hollowed-out customer base takes months or years to rebuild.

---

## Retention validation

To validate the segmentation model, Month+1 retention rates were calculated for each segment — measuring what percentage of active customers placed another order the following calendar month.

| Segment | Active Customers | Retained (M+1) | Retention Rate |
|---|---|---|---|
| `loyal_low_value` | 247 | 9 | **3.47%** |
| `top_customer` | 478 | 13 | **2.70%** |
| `low_value` | 219 | 0 | **0.00%** |
| `risky_high_value` | 64 | 0 | **0.00%** |

`low_value` and `risky_high_value` show **0% Month+1 retention** — confirming that customers in these segments do not return the following month. This directly validates the concern raised in the acquisition quality analysis: California's 2021 growth was built on customers structurally unlikely to come back.

The retention gap between `top_customer` (2.70%) and `loyal_low_value` (3.47%) requires nuanced interpretation. Top customers are classified on total historical revenue, not purchase frequency. A customer who placed two very large orders spread across 40 months is classified as `top_customer` despite low month-to-month activity — infrequent but high-value purchasing behavior that Month+1 retention is not designed to capture.

> **Model Limitation — Documented**  
> The CLV threshold of 1,000 was derived from the empirical distribution (P75 ≈ 1,094). An arbitrary threshold such as 500 — which falls between the median and P75 — would cut through the middle of the distribution without statistical justification. The threshold should be recalibrated against actual CAC data in a production environment, where CLV:CAC ≥ 3:1 serves as an additional validation benchmark. A more granular model incorporating purchase frequency as a standalone dimension would produce cleaner retention separation across segments.

---

## Final Conclusion: The real cost of short-term thinking

The data tells a coherent and cautionary story. California is the highest-revenue state in this dataset — that fact is not in dispute. But the nature of that revenue has fundamentally changed since 2021. The early years showed genuine, compounding growth: high-value customers being acquired, returning, and expanding their spend. That growth was slow by comparison, but it was durable.

From 2021 onward, acquisition shifted toward volume. More customers, more orders, higher monthly numbers. The revenue metrics responded accordingly, producing impressive YoY figures that would have satisfied a standard reporting requirement. What those figures obscured was the accelerating share of customers with no demonstrated intention to return.

By early 2022, the consequences were already visible: revenue declining YoY, new cohorts dominated by `low_value` customers, and the `top_customer` pipeline running dry. **Without intervention, this trajectory is likely continue.** A revenue base built on one-time buyers is not a revenue base — it is a recurring acquisition cost.

### Forward-looking recommendations

- **Shift acquisition focus** — Redirect marketing investment from broad-reach campaigns toward targeted programs that attract buyers with high repeat-purchase potential. Prioritize channels and product categories that historically correlate with `top_customer` acquisition.

- **Build retention infrastructure** — Implement post-purchase engagement mechanics: personalized email flows, loyalty programs, and reactivation campaigns specifically designed to convert `risky_high_value` customers into repeat buyers before they churn.

- **Monitor acquisition quality monthly** — Integrate CLV-based segment distribution into standard monthly reporting. A dashboard showing revenue alongside `top_customer` acquisition rate would have made this degradation visible months earlier.

- **Refine the CLV model** — Extend the segmentation framework to incorporate purchase frequency as an independent dimension. This will produce sharper retention predictions and more actionable customer scoring.

> *California leads in revenue. But revenue without retention is not a business — it is a treadmill. The goal is not to acquire customers. It is to keep them.*

---

## Why this matters: The analyst's mindset

This project was built around a deliberate analytical philosophy: **never stop at "what happened."** Every answer should generate a better question. Revenue by state generates "Is it growing?" YoY growth generates "Is the data complete?" Volume growth generates "What kind of customers?" Acquisition counts generate "Are they coming back?"

The analytical choices made throughout — questioning the apparent 2022 drop, adding discount depth as a context variable, constructing CLV from behavioral signals rather than revenue alone, validating segmentation through retention — each reflect a structured approach to moving from raw numbers toward genuine insight.

Great analysts are not data retrieval systems. They are sense-making engines. They know which questions to ask, when to distrust a number, and how to communicate a finding in a way that informs a decision rather than simply describes the past. The technical work here — SQL, window functions, CTEs, segmentation logic — is in service of that goal, not an end in itself.

---

***This isn't just SQL. It's business intelligence in motion.***

---

*Piotr Rzepka · SQL E-Commerce Analytics Portfolio · `supersales` DB · MySQL 8.0+*
