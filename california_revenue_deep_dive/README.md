# The Story of California's Revenue: From False Alarm to Real Insight

> **SQL Portfolio · E-Commerce Analytics**  
> Author: Piotr Rzepka · Database: `supersales` (MySQL 8.0+) · Period: 2018–2022  

> **Analytical note:** This project was developed as a learning exercise with AI-assisted code review. The analytical methodology — tenure bias control, right-censoring, revenue decomposition — was introduced through mentored feedback. All SQL is my own, written and verified against the live dataset.

---

## Key Numbers at a Glance

| Metric | Value |
|---|---|
| California Total Revenue | $451,451 — #1 of all states |
| Orders Analyzed | 1,021 (2018–2021 complete; 2022 = January only) |
| Customer Segments | 4 (revenue + repeat behavior) |
| 90-Day Cohort Repeat Rate | 3.75% (2018) → 7.95% (2021) — improving |
| Returning Customer Revenue Share (2021-Q4) | 63% of quarterly revenue |

---

## Executive Summary

California is the top-performing state in this e-commerce dataset — by total revenue, order count, and customer volume. But the surface-level story is misleading in ways that reveal fundamental principles about analytical rigor.

A segmentation analysis based on full customer history shows a dramatic shift: since 2021, new customer acquisitions skewed heavily toward low-value, one-time buyers. The top_customer segment nearly vanished from recent cohorts. The natural conclusion — that acquisition quality was deteriorating — appears supported by the data.

**That conclusion is wrong.**

It is an artifact of tenure bias: customers acquired in 2018 had four years to accumulate revenue and repeat purchases, while 2021 customers had only months. When every cohort is given the same 90-day observation window, the 2021 cohort shows the *highest* early repeat rate in the dataset — nearly double the 2018 baseline. Meanwhile, revenue decomposition reveals that 63–70% of 2021 quarterly revenue comes from returning customers acquired in earlier years. California's growth is not built on fragile one-time purchases. It is sustained by a maturing customer base.

**The real story is not one of declining quality, but of a growing business whose newest customers haven't yet had time to prove their value.**

> This analysis demonstrates that even a multi-step, well-structured investigation can lead to incorrect conclusions when measurement bias is not controlled. The full story requires understanding time, customer quality, acquisition patterns, retention behavior, and the difference between what data *shows* and what it *means*.

---

## The Problem: A Single Number That Tells You Nothing

### Starting Point: Revenue by State

Every analysis begins somewhere. The natural starting point is the most visible metric: total revenue by delivery state. California leads decisively — $451,451 in revenue. New York follows at $312,377, and Texas at $164,948. On a dashboard, this looks like a clear answer to the question "Where should we focus?"

But this is precisely the **trap of vanity metrics**. A single aggregated figure collapses four years of business history into one number. It cannot tell us whether California is growing or declining, whether customers are returning, or whether the revenue base is structurally sound. It only tells us the final score — not how the game was played.

<img width="1011" height="408" alt="image" src="https://github.com/user-attachments/assets/873a5cdc-8298-4fdd-b361-92cc181643e7" />

---

## First Red Flag: The Mysterious Revenue Drop

The logical next step is to examine California's performance over time. A year-over-year breakdown appears to reveal a catastrophe: a near 90% revenue collapse between 2021 and 2022, dropping from $148,729 to just $16,186.

**Good analysis demands skepticism before reaction.** A drop of this magnitude, from one year to the next without any external context, is statistically unlikely in a functioning business. The question isn't just "what happened?" — it's "is this real, or is something wrong with the data?"

A simple month-level breakdown of 2022 data immediately reveals the truth: **the dataset for 2022 contains only January.** The apparent collapse is not a business failure — it is an incomplete dataset being compared against a full calendar year. One month of revenue will almost always look smaller than twelve.

<img width="1022" height="495" alt="image" src="https://github.com/user-attachments/assets/95790aec-74d3-4c2d-9cd6-950c52c8d48a" />

This moment illustrates a foundational analytical principle: **never draw conclusions from numbers you haven't validated.** A flawed report that reaches the wrong audience can trigger resource misallocation, false urgency, or misplaced confidence. Data completeness is not a technical detail — it is a business risk.

> **Analytical decision:** 2022 is excluded from all subsequent comparative analyses. However, January 2022 orders are retained in the underlying customer calculations — a customer acquired in December 2021 who ordered again in January 2022 must count as a repeat buyer. The distinction between "exclude from reporting" and "exclude from computation" matters.

---

## Deeper Dive: Unpacking Growth Drivers

With data integrity confirmed, the analysis moves to understanding California's growth dynamics. Month-over-month and year-over-year metrics — revenue, order counts, unique customers, items sold, average order value, and discount depth — paint a picture of strong growth through late 2021.

September 2021 shows +71.85% YoY revenue growth, nearly doubling items sold (+87%) and growing unique customers by +58%. November 2021 produces even more striking numbers: +111% revenue growth, with the same number of unique customers as the prior year.

By conventional metrics, these are headline-worthy results. But a critical question emerges: **what kind of customers are being acquired during these growth months?**

Volume is easy to measure. Quality is harder — and far more important. A business acquiring a thousand low-value, one-time buyers is in a fundamentally different position than one acquiring a hundred high-value repeat customers, even if the short-term revenue looks identical.

> **Key analytical decision:** Rather than accepting volume growth as success, the analysis shifts to a customer-quality lens. The question becomes not "how much did we grow?" but "who did we grow with?" This reframe is what separates descriptive reporting from genuine business intelligence.

---

## Customer Segmentation: Who Drives Real Value?

### Building the Segmentation Model

To move beyond revenue as a proxy for value, customers are classified into four segments based on two observable dimensions: **total historical revenue** and **demonstrated repeat purchase behavior** (orders > 1).

The revenue threshold of 1,000 is derived from the empirical distribution of California customer revenue (n = 565, after excluding 12 customers acquired only in January 2022): the median is ~390 and the 75th percentile is ~1,050, making 1,000 a defensible approximation of the top quartile boundary.

| Segment | Definition | Count | Revenue | % of Total Revenue |
|---|---|---|---|---|
| `top_customer` | Repeat buyer, revenue ≥ 1,000 | 120 (21%) | $256,291 | 57% |
| `risky_high_value` | One-time buyer, revenue ≥ 1,000 | 39 (7%) | $72,972 | 16% |
| `loyal_low_value` | Repeat buyer, revenue < 1,000 | 173 (31%) | $72,032 | 16% |
| `low_value` | One-time buyer, revenue < 1,000 | 233 (41%) | $47,754 | 11% |

Top customers — 21% of the customer base — account for 57% of total California revenue. This concentration is the analytical foundation: if the top_customer pipeline dries up, revenue follows.

> **Metric transparency note:** A common CLV formula (avg_order_value × purchase_frequency × lifetime_months) algebraically simplifies to total_revenue in all cases. Using total_revenue directly is both simpler and more honest — it avoids creating the appearance of a predictive model when the metric is purely descriptive.

---

## The Apparent Warning: Segment Composition Over Time

Applying the segmentation model to acquisition cohorts by quarter reveals what initially appears to be the most important finding in this dataset.

| Period | Total | Top | Risky | Loyal | Low | Top % | Repeat % |
|--------|-------|-----|-------|-------|-----|-------|----------|
| 2018-Q2 | 43 | 20 | 0 | 15 | 8 | 46.5% | 81.4% |
| 2019-Q1 | 32 | 14 | 2 | 9 | 7 | 43.8% | 71.9% |
| 2020-Q3 | 36 | 10 | 4 | 10 | 12 | 27.8% | 55.6% |
| 2021-Q2 | 27 | 2 | 1 | 2 | 22 | 7.4% | 14.8% |
| 2021-Q4 | 33 | 0 | 6 | 3 | 24 | 0.0% | 9.1% |

The pattern is dramatic: top_customer rates collapse from 24–47% in 2018 to 0–7% in 2021. Repeat rates fall from 61–81% to 9–32%. The low_value segment dominates every 2021 quarter.

<img width="1068" height="512" alt="image" src="https://github.com/user-attachments/assets/fc64d722-8821-4b0d-9a61-2c3d2ed12330" />

<img width="1091" height="585" alt="image" src="https://github.com/user-attachments/assets/b5e62f9d-5f50-4e3a-ae7e-d9a438c43e10" />

**The instinctive conclusion:** California's acquisition quality has collapsed. The pipeline of high-value customers is drying up. Revenue is at risk.

**That conclusion feels compelling. It is also wrong.**

---

## The Trap: Tenure Bias

### Why the Segmentation Is Misleading

The segmentation assigns labels based on a customer's *full* purchase history — every order they've ever placed through January 2022. This creates a structural advantage for older customers:

- A customer acquired in **Q2 2018** had **~44 months** to accumulate revenue and demonstrate repeat behavior
- A customer acquired in **Q4 2021** had **~2 months**

The top_customer threshold requires both revenue ≥ 1,000 AND orders > 1. A 2021 customer could have made a $500 purchase with every intention of returning — but the data simply doesn't extend far enough to observe it. Labeling this customer "low_value" based on incomplete observation creates a *measurement artifact* that masquerades as a business insight.

> **This is tenure bias:** the systematic misclassification of newer customers as low-quality, caused by unequal observation windows — not by genuine differences in customer behavior.

### The Consequences of Not Catching This

If this bias goes undetected, the analytical cascade is predictable and damaging:

1. **Incomplete data** → segments skew toward low_value for recent cohorts
2. **Skewed segments** → analyst concludes acquisition quality is declining
3. **False conclusion** → business redirects resources to "fix" acquisition
4. **Misallocation** → actual opportunities (retention, nurturing recent customers) are ignored

The path from measurement error to strategic misallocation is short and plausible. This makes tenure bias not just a statistical concern, but a business risk.

---

## Three Independent Tests

### Test 1: Revenue Decomposition — Where Does Growth Actually Come From?

To understand whether 2021's growth is genuinely fragile, quarterly revenue is decomposed into two streams: revenue from **newly acquired customers** (first order in that quarter) versus revenue from **returning customers** (acquired in prior periods).

| Quarter | Total Revenue | New Customer Rev | Returning Customer Rev | New % |
|---------|---------------|------------------|------------------------|-------|
| 2018-Q4 | $22,805 | $19,742 | $3,064 | 86.6% |
| 2019-Q4 | $30,827 | $24,445 | $6,381 | 79.3% |
| 2020-Q2 | $27,129 | $7,271 | $19,858 | 26.8% |
| 2020-Q4 | $40,717 | $23,078 | $17,639 | 56.7% |
| 2021-Q1 | $31,525 | $9,354 | $22,171 | 29.7% |
| 2021-Q4 | $47,976 | $17,754 | $30,222 | 37.0% |

`[CHART 5: Revenue Composition — New vs Returning Customers (quarterly stacked area or 100% stacked bar, 2018-Q1 to 2021-Q4)]`

The trend is unambiguous. In 2018, nearly 100% of revenue comes from new customers — naturally, the business is starting. By 2021-Q1, **70.3% of revenue comes from returning customers.** In Q4 2021, returning customers contribute $30,222 — more than total quarterly revenue in any quarter of 2018.

**This directly contradicts the "fragile growth" hypothesis.** California's 2021 revenue is not built on one-time purchases from low-value newcomers. It is sustained by the accumulated value of customers acquired in earlier years who keep coming back. The business is maturing, not deteriorating.

### Test 2: Retention by Segment — Do Top Customers Actually Retain Better?

Retention rates are calculated per purchase occasion with right-censoring correction — each observation window (30, 90, 180 days) only includes purchase events where the full window falls within available data. This prevents orders from late 2021 from being penalized for insufficient follow-up time.

| Segment | Eligible (180d) | Retained | Rate | Eligible (90d) | Retained | Rate | Eligible (30d) | Retained | Rate |
|---|---|---|---|---|---|---|---|---|---|
| `top_customer` | 264 | 56 | **21.21%** | 294 | 31 | **10.54%** | 313 | 7 | **2.24%** |
| `loyal_low_value` | 324 | 45 | **13.89%** | 362 | 28 | **7.73%** | 399 | 14 | **3.51%** |
| `risky_high_value` | 29 | 0 | 0.00% | 34 | 0 | 0.00% | 39 | 0 | 0.00% |
| `low_value` | 198 | 0 | 0.00% | 217 | 0 | 0.00% | 233 | 0 | 0.00% |

The results reveal a nuanced picture rather than a simple hierarchy:

- At **180 days**, top_customers retain at 1.5× the rate of loyal_low_value (21.21% vs 13.89%)
- At **90 days**, top_customers lead at 1.4× (10.54% vs 7.73%)
- At **30 days**, the pattern **reverses**: loyal_low_value retains better (3.51% vs 2.24%)

This suggests different purchasing cadences, not a simple "better/worse" ranking. Loyal_low_value customers make more frequent, smaller purchases — a quick-reorder behavior. Top customers make larger, more deliberate purchases at wider intervals. Both patterns represent genuine business value, but they require different retention strategies.

The 0% retention for low_value and risky_high_value is a definitional tautology, not an analytical finding: both segments are defined as one-time buyers (orders = 1), so by construction they have no subsequent order.

### Test 3: Cohort Repeat Rate — The Decisive Test

Instead of labeling customers by their full history, each acquisition cohort is given the same **90-day window** to demonstrate repeat behavior. A customer "repeated" if they placed any subsequent California order within 90 days of their first purchase. Only customers acquired at least 90 days before the dataset boundary (2022-01-25) are included.

| Acquisition Year | Customers Acquired | Repeated (90d) | Repeat Rate |
|---|---|---|---|
| 2018 | 160 | 6 | **3.75%** |
| 2019 | 147 | 9 | **6.12%** |
| 2020 | 147 | 10 | **6.80%** |
| 2021 | 88 | 7 | **7.95%** |

`[CHART 6: 90-Day Cohort Repeat Rate by Acquisition Year — bar chart, 4 bars, ascending trend line]`

**The 2021 cohort has the highest repeat rate in the dataset** — nearly double the 2018 baseline. The trend is monotonically increasing: 3.75% → 6.12% → 6.80% → 7.95%.

This result overturns the apparent finding from the segmentation analysis. The appearance of fewer top_customers in 2021 is not a signal of declining acquisition quality. It is a measurement artifact caused by unequal observation windows. When given equal time, 2021 customers demonstrate *stronger* early engagement than any prior cohort.

The quarterly breakdown adds seasonal nuance: Q4 cohorts consistently show the highest within-year repeat rates (4.48%, 11.11%, 11.32%, 10.00%), suggesting holiday-acquired customers have stronger initial engagement. However, 2021-Q4 contains only 10 eligible customers — too few for reliable inference. The yearly aggregates provide more stable trend estimates.

---

## Final Conclusion: Separating Signal from Artifact

This analysis begins with a single revenue figure and methodically peels back the layers underneath. Along the way, it encounters a classic analytical trap — and avoids it.

### What is real

- **California leads in revenue** ($451,450) and its growth from 2018 to 2021 is genuine and consistent
- **Top customers are disproportionately valuable** — 21% of customers generating 57% of revenue, with 1.4–1.5× higher long-term retention
- **The business is maturing** — returning customer revenue grows from 0% to 63–70% of quarterly revenue by 2021, a structural positive
- **Recent cohorts show improving engagement** — 90-day repeat rates double from 2018 to 2021
- **Different segments have different purchasing cadences** — loyal_low_value customers buy more frequently at 30 days; top_customers sustain engagement over 90–180 days

### What is an artifact

- **The "collapse" of top_customer acquisitions in 2021** — tenure bias, not a real quality decline. Newer customers haven't had enough time to cross the revenue and repeat thresholds
- **The segment composition shift** — visually dramatic in charts 3 and 4, but expected given unequal observation windows
- **Any "warning signal" narrative claiming California's revenue is at risk** — compelling at first glance, but empirically refuted by controlled cohort analysis

### Strategic Implications

- **Nurture 2021 cohorts** — they show the highest early repeat rate. Post-purchase engagement, loyalty programs, and reactivation campaigns should target these customers before they lapse
- **Monitor 90-day repeat rate as a leading indicator** — it is less biased than segment composition and more actionable than full-history revenue totals
- **Recognize the returning customer base as an asset** — 63% of Q4 2021 revenue comes from returning customers. This base is the revenue engine; protecting it matters more than optimizing new acquisition

> *California leads in revenue. Its newest customers show the strongest early engagement in the dataset. The real risk is not that the business is acquiring the wrong customers — it's that it might fail to retain the right ones.*

---

## Why This Matters: The Analyst's Mindset

This project demonstrates something more important than SQL proficiency: **the willingness to disprove your own hypothesis.**

The segmentation analysis builds a coherent, well-supported case that California's acquisition quality is declining. The charts are compelling. The tables align. The narrative makes intuitive sense. It would pass most reviews.

It is also wrong.

The error is not in the SQL. The queries return correct results. The error is in the analytical framework — applying a retrospective segmentation (which rewards tenure) to a time-series question (which requires controlled comparison). Catching this requires stepping outside the analysis, questioning the methodology, and building an independent test that can falsify the conclusion.

The technical work — window functions, CTEs, right-censoring, cohort analysis — is in service of that mindset. Tools matter. But knowing when your tools are deceiving you matters more.

---

*Piotr Rzepka · SQL E-Commerce Analytics Portfolio · `supersales` DB · MySQL 8.0+*
