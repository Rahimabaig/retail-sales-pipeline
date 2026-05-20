# Retail Sales Pipeline - Snowflake + dbt

An end-to-end ELT pipeline that unifies raw retail transaction data into a trusted analytical layer — surfacing revenue trends, cancellation leakage, and inventory risk signals that were previously invisible.

---

## The Problem

A UK-based retailer had 541,000+ transaction records but no reliable way to answer three critical business questions:

- **Which months drove the most revenue — and is the business growing?**
- **How much revenue is being silently lost to cancellations every month?**
- **Which products are dead stock — and which are flying off the shelves?**

Cancellation records were embedded inside the same export as real sales. Nobody had isolated them. The buying team was making restocking decisions without a cross-product view. Finance was reporting gross revenue without netting out reversals.

This pipeline fixes all three problems.

---

## Architecture

```
Source (UCI Online Retail Dataset)
        │
        ▼
┌─────────────────────────────────┐
│         Snowflake RAW           │
│  raw_sales                      │
│  raw_cancellations              │
│  raw_customers                  │
└─────────────────────────────────┘
        │
        ▼ (dbt staging layer — views)
┌─────────────────────────────────┐
│          STAGING schema         │
│  stg_sales                      │
│  stg_cancellations              │
│  stg_customers                  │
└─────────────────────────────────┘
        │
        ▼ (dbt intermediate layer — view)
┌─────────────────────────────────┐
│       INTERMEDIATE schema       │
│  int_sales_unified              │  ← single source of truth
│  (sales + cancellations unified)│
└─────────────────────────────────┘
        │
        ▼ (dbt marts layer — tables)
┌─────────────────────────────────┐
│          MARTS schema           │
│  mart_monthly_revenue           │
│  mart_revenue_leakage           │
│  mart_top_products              │
└─────────────────────────────────┘
```
---
![Lineage Graph](assets/lineage_graph.png)
---

## Tech Stack

| Tool | Purpose |
|---|---|
| **Snowflake** | Cloud data warehouse — RAW, STAGING, INTERMEDIATE, MARTS schemas |
| **dbt Core** | Data transformation — staging, intermediate, mart models |
| **Python** | Data splitting — separating sales, cancellations, customers from source |
| **Git + GitHub** | Version control |

---

## Data Source

**UCI Online Retail Dataset** — 541,909 real transactions from a UK-based retailer (Dec 2010 – Dec 2011).

Split into 3 logical sources mirroring how real systems export data:

| Table | Rows | Description |
|---|---|---|
| `raw_sales` | ~490,000 | Completed sales transactions |
| `raw_cancellations` | ~9,300 | Reversed/cancelled orders (InvoiceNo starting with 'C') |
| `raw_customers` | ~4,300 | Unique customer-country reference |

---

## dbt Models

```
models/
  staging/
    stg_sales.sql              — cast types, filter negatives, add channel flag
    stg_cancellations.sql      — isolate cancellations, compute revenue_lost
    stg_customers.sql          — deduplicate customers, clean IDs
    sources.yml                — declare RAW tables as dbt sources
    schema.yml                 — data quality tests
  intermediate/
    int_sales_unified.sql      — UNION ALL sales + cancellations, is_cancellation flag
  marts/
    mart_monthly_revenue.sql   — revenue trend by month
    mart_revenue_leakage.sql   — cancellation rate vs gross revenue per month
    mart_top_products.sql      — product velocity classification
macros/
    generate_schema_name.sql   — override dbt schema naming for clean schema separation
```

---

## dbt Tests Applied

| Test | Column | Model |
|---|---|---|
| `not_null` | invoice_no | stg_sales, stg_cancellations |
| `not_null` | revenue, quantity, customer_id | stg_sales |
| `not_null` | revenue_lost | stg_cancellations |
| `not_null` | customer_id, country | stg_customers |
| `unique` | customer_id | stg_customers |
| `accepted_values` | channel = 'online_store' | stg_sales |

---

## Results — What The Data Revealed

### 1. Revenue Trend (mart_monthly_revenue)

| Month | Orders | Units Sold | Revenue (£) | Avg Order Value (£) |
|---|---|---|---|---|
| 2010-12 | 1,559 | 736,766 | £2,836,218 | £17.27 |
| 2011-01 | 1,086 | 697,612 | £1,667,667 | £12.00 |
| 2011-09 | 1,837 | 779,022 | £1,906,142 | £15.47 |
| 2011-10 | 2,040 | 861,069 | £2,083,564 | £15.16 |
| **2011-11** | **2,769** | **1,439,003** | **£4,292,434** | **£18.34** |
| 2011-12 | 819 | 529,103 | £1,603,961 | £18.31 |

**Key insight:** November 2011 was the peak month — £4.29M revenue, 2,769 orders. 2.8x the average month. Classic pre-Christmas wholesale surge.

---

### 2. Revenue Leakage (mart_revenue_leakage)

| Month | Cancellations | Revenue Lost (£) | Gross Revenue (£) | Cancellation Rate |
|---|---|---|---|---|
| 2011-01 | 260 | £427,345 | £1,667,667 | **25.63%** |
| 2011-12 | 146 | £440,630 | £1,603,961 | **27.47%** |
| 2011-04 | 240 | £56,418 | £1,088,616 | 5.18% |
| 2011-11 | 441 | £194,403 | £4,292,434 | 4.53% |

**Key insight:** January 2011 and December 2011 had cancellation rates above 25% — more than 1 in 4 pounds earned was reversed. Industry standard is under 3%. This is a serious fulfilment or product quality signal that was completely invisible before this pipeline existed.

---

### 3. Inventory Risk (mart_top_products)

| Velocity | Products |
|---|---|
| Fast Moving | 2,243 |
| Dead Stock | 718 |
| Slow Moving | 630 |
| Moderate | 567 |

**Key insight:** 718 SKUs (17% of all products) are classified as Dead Stock — moving fewer than 50 units total across the entire year. If the buying team had reordered any of these, that is direct cash tied up in unsellable inventory.

---

## How To Run This Project

```bash
# Clone the repo
git clone https://github.com/Rahimabaig/retail-sales-pipeline.git
cd retail-sales-pipeline

# Install dbt
pip install dbt-snowflake

# Configure your Snowflake credentials
# Edit ~/.dbt/profiles.yml with your account details

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

---

## Project Structure

```
retail_pipeline/
  models/
    staging/
    intermediate/
    marts/
  macros/
  dbt_project.yml
  .gitignore
README.md
```

---

## Key Engineering Decisions

**Why separate cancellations into their own RAW table?**
In real systems, returns and cancellations often live in a separate table from sales. Separating them at ingestion mirrors production architecture and prevents naive aggregations from over-reporting revenue.

**Why use an intermediate model instead of building marts directly from staging?**
`int_sales_unified` is the single source of truth — one model where sales and cancellations are unified with an `is_cancellation` flag. All 3 marts read from this one model. If business logic changes, it changes in one place, not three.

**Why materialized staging as views and marts as tables?**
Staging views are always fresh and cost nothing to store. Mart tables are pre-computed so BI tools and analysts get instant query results without re-running expensive joins on 500K rows every time.

---

*Built as part of a data engineering portfolio — architecture inspired by real client projects at Folio3 Data Services.*