# Nova Retail: End-to-End Automated Modern Data Stack Pipeline

An end-to-end, fully automated retail data engineering pipeline built using the **Medallion Architecture (Bronze → Silver → Gold)**. This project ingests raw operational data from multiple sources, performs data cleansing and schema validation via **dbt Core**, models a **Star Schema** on **Databricks**, and feeds a dynamic **Power BI** executive dashboard hosted on **Microsoft Fabric**.


## Architecture & Operational Workflow

The entire pipeline is orchestrated via a multi-task **Databricks Workflow** (`nova_retail_pipeline`) scheduled to run daily:

```
[ Google Drive / Source Dropzone ]
               │
               ▼
┌──────────────────────────────────────────────┐
│ Task 1: 01_bronze_ingestion                  │ ◄── Python Script (Daily Run)
│ (CSV, JSON, Excel → Bronze Delta Tables)     │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ Task 2: 02_dbt_silver_gold_transformations   │ ◄── dbt deps && dbt run && dbt test
│ (Data Cleansing & Star Schema Modeling)      │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ Task 3: 03_update_powerbi_data               │ ◄── Programmatic REST API Refresh
│ (Automated Refresh on Microsoft Fabric)      │
└──────────────────────────────────────────────┘
```
## Tech Stack & Key Features

* **Storage & Compute:** Databricks (Lakehouse / Delta Lake) + Spark
* **Ingestion:** Python (Scheduled via Databricks Workflows)
* **Transformations & Governance:** dbt Core (Data Build Tool)
* **Data Quality & Testing:** dbt Schema Assertions (`unique`, `not_null`, `relationships`, `accepted_values`)
* **Data Modeling:** Dimensional Modeling / Star Schema (3 Facts, 3 Dimensions)
* **Semantic Layer & Analytics:** Power BI report (published on Microsoft Fabric).
* **Version Control & CI/CD:** GitHub

## Data Quality & Transformations (Bronze → Silver)

* **`stg_sales` (`raw_sales_transactions.csv`):**
  * **Date Cleansing & Backfill:** Multi-pattern date parsing (`yyyy-MM-dd`, `dd/MM/yyyy`, etc.) with a windowed `last_value()` fallback for relative dates (`'today'`).
  * **Customer Parsing:** Delimited customer strings (`FullName | Email | Phone`) split and normalized into scalar staging fields.
  * **Financial Standardizations:** Derived `gross_revenue` (`quantity * unit_price`), `net_revenue` (`quantity * unit_price * (1 - discount_pct)`), and `estimated_profit` (30% margin on net revenue).
* **`stg_reviews` (`web_reviews.json`):**
  * **JSON Flattening:** Extracted nested user objects into flat staging entities; converted Unix epoch timestamps to UTC datetimes.
  * **Out-of-bounds Handling:** Filtered ratings outside 1–5 using dbt `accepted_values` assertions.
* **`stg_targets` (`finance_targets_2023.xlsx`):**
  * **Unpivot Logic:** SQL unpivot applied to widen horizontal month columns into a clean, reproducible vertical tabular layout.

---

## Dimensional Data Model (Gold - Star Schema)

The Gold layer structures operational data into an enterprise-ready dimensional model:

* **Fact Tables:**
  * `FACT_Sales`: Granular transaction line items (`order_id`, `date_key`, `customer_id`, `product_id`, `gross_revenue`, `net_revenue`, `estimated_profit`, etc.)
  * `FACT_Targets`: Unpivoted regional monthly targets (`target_key`, `region`, `product_category`, `target_month`, `target_revenue`)
  * `FACT_Reviews`: Product ratings and text sentiment (`review_id`, `product_id`, `review_date`, `rating`, `review_text`)
* **Dimension Tables:**
  * `DIM_Customers`: Cleaned customer profile attributes (`customer_id`, `customer_name`, `customer_email`, `customer_phone`)
  * `DIM_Products`: Product catalog hierarchy (`product_id`, `product_category`)
  * `DIM_Date`: Daily granularity master calendar table (`date_key`, `first_day_of_month`, `month_name`, `year`, etc.)
 
### Semantic Model Relationships
* `DIM_Customers[customer_id] → FACT_Sales[customer_id]` (1:N, Single Direction)
* `DIM_Products[product_id] → FACT_Sales[product_id]` (1:N, Single Direction)
* `DIM_Products[product_id] → FACT_Reviews[product_id]` (1:N, Single Direction)
* `DIM_Date[date_key] → FACT_Sales[date_key]` (1:N, Single Direction)
* `DIM_Date[date_key] → FACT_Reviews[review_date]` (1:N, Single Direction)
* `DIM_Date[date_key] → FACT_Targets[target_month]` (1:N, Single Direction)

---

## Executive Power BI Dashboard

The Power BI report (`Nova Retail Report`) is published on **Microsoft Fabric**.
