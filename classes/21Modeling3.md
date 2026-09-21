# 🏛️ Medallion Architecture, CDC Ingestion & Enterprise Governance

**Masterclass Technical & Strategic Summary | September 16, 2026 (Parts 1 & 2 Unified)**  
**Facilitator:** Victor Okon  
**Session Scope:** Live PostgreSQL-to-Databricks Change Data Capture (CDC), Cursor Optimization, The Medallion Lakehouse Paradigm (Bronze/Silver/Gold), Downstream Data Consumption (LLMs & Reverse ETL), The Semantic Layer, and Domain Governance.

---

## 📌 Executive Overview

Continuing directly from the foundations of data modeling and operational transactional design, this masterclass transitioned from theoretical system diagrams to **live, end-to-end cloud pipeline implementation**. 

The core narrative of the session addressed a vital engineering milestone:
> *"How do we move data out of an operational OLTP database into an analytical lakehouse incrementally without breaking production, how do we structure it as it matures, and how do we govern its definitions so that humans, algorithms, and AI agents speak the exact same business language?"*

Through live terminal executions in **DataGrip**, an **AWS-hosted PostgreSQL database**, and **Databricks Lakehouse**, instructor Victor Okon demonstrated live log-based and incremental ingestion, unraveled cursor selection mechanics, deconstructed the **Medallion Architecture (Bronze $\rightarrow$ Silver $\rightarrow$ Gold)**, and explained why modern analytical stacks require a **Universal Semantic Layer** to eliminate conflicting KPIs.

---

## ⚙️ Part 1: Live Technical Demo — PostgreSQL to Databricks Ingestion

The first half of the masterclass was dedicated to setting up, troubleshooting, and verifying an ingestion pipeline from an operational relational store into a cloud lakehouse.

```
 ┌─────────────────────────────────────────────────────────────┐
 │               OPERATIONAL LAYER (OLTP)                      │
 │   AWS-Hosted PostgreSQL Instance                            │
 │   • Managed via DataGrip / DBeaver / pgAdmin                │
 │   • Source Tables: users, lesson_events, subscriptions      │
 └──────────────────────────────┬──────────────────────────────┘
                                │
                                │ Managed Databricks Ingestion Pipeline
                                │ (Direct ingestion; no volume stage required)
                                ▼
 ┌─────────────────────────────────────────────────────────────┐
 │                LAKEHOUSE LANDING (OLAP)                     │
 │   Databricks Unity Catalog / Ingestion Tables               │
 │   • Initial Execution: Full snapshot load                   │
 │   • Subsequent Runs: Incremental capture via cursor key     │
 └─────────────────────────────────────────────────────────────┘
```

### 1. The Tooling Environment: Clarifying DataGrip vs. Databricks
Early in the session, attendees (including **Osakpolor Ogieriakhi**, **Temitope Asama**, and **Prince Peter**) sought clarification regarding the software on screen:
* **DataGrip (by JetBrains):** A universal database Integrated Development Environment (IDE) used to connect to, query, and manage relational database engines (PostgreSQL, MySQL, AWS Redshift, Snowflake). Alternatives mentioned by students include **DBeaver**, **pgAdmin**, or **VS Code database extensions**.
* **Databricks:** An enterprise Unified Data Analytics Platform / Lakehouse combining data engineering, data warehousing, and machine learning runtimes on top of cloud object storage (AWS S3, Azure Data Lake, GCP Cloud Storage).
* **Architecture Clarification:** DataGrip was used merely as the administrative client to run DDL/DML queries against an **AWS-hosted PostgreSQL** instance, which was subsequently ingested into **Databricks**.

### 2. Operational Database Provisioning
Victor executed administrative commands in PostgreSQL:
* Created a dedicated transactional database and schema (`raw_events`).
* Provisioned core relational entities:
  * `users`: `user_id` (PK), `email`, `country_locale`, `created_at`.
  * `lesson_events`: `event_id` (PK), `user_id`, `event_type`, `occurred_at`.
  * `subscriptions`: `subscription_id` (PK), `user_id`, `plan_type`, `started_at`.
* Configured enterprise security roles, granting connection rights, schema usage, and explicit `SELECT` privileges to the ingestion user across existing and future tables.

### 3. Pipeline Ingestion Dynamics: Postgres vs. SQL Server
Victor resolved an important architectural nuance from the prior class regarding staging storage:
* When ingesting from certain engines (such as **Microsoft SQL Server**), Databricks often stages raw files into an intermediate **DBFS / Cloud Volume** before writing to Delta tables.
* For **PostgreSQL**, Databricks connects directly through the ingestion connector, streaming records straight into managed target tables without requiring an intermediary staging volume.

---

## 🔍 Part 2: Change Data Capture (CDC) & Cursor Mechanics

Change Data Capture ensures that an analytical lakehouse reflects updates and insertions from the transactional engine without executing full table dumps on every refresh cycle.

### 1. Full Snapshot vs. Incremental Ingestion
* **Run 1 (Initial Load):** The ingestion job executes a **full table snapshot**, reading and writing all existing rows:
  * `users`: 3 initial records.
  * `lesson_events`: 3 initial records.
  * `subscriptions`: 3 initial records.
* **Run 2+ (Incremental Sync):** The engine monitors a designated identifier column to append/merge only net-new operations.

### 2. The Great Cursor Debate: What Defines an Event?
The class engaged in an extensive technical debate over which attribute should serve as the **Cursor Column** (the tracking column that tells the engine where the last ingestion ended) for the `lesson_events` table:

```
                  ┌──────────────────────────────────────────────┐
                  │    WHICH CURSOR FOR AN IMMUTABLE EVENT?      │
                  └──────────────────────┬───────────────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
   ┌───────────────────────────┐                   ┌───────────────────────────┐
   │        occurred_at        │                   │         event_id          │
   │        (Timestamp)        │                   │       (Primary Key)       │
   ├───────────────────────────┤                   ├───────────────────────────┤
   │ • Clock skew issues       │                   │ • Discrete & unique       │
   │ • Multiple events share   │                   │ • Monotonically increasing│
   │   identical timestamps    │                   │ • Guaranteed resolution   │
   │ • Prone to edge collisions│                   │ • THE WINNING CHOICE      │
   └───────────────────────────┘                   └───────────────────────────┘
```

* **The Contenders:**
  * **Option A: `occurred_at` (Timestamp)** — Suggested by John Babatunde, Mudi Oke, and Godwin Nosa.
  * **Option B: `event_id` (Discrete Primary Key)** — Suggested by Chidinma Okeh, Gbenga Owoeye, and Pamela Olowojebutu.
  * **Option C: `event_type`** — Suggested by Prince Peter (e.g., status changing from 'start' to 'complete').

* **The Instructor's Analogy (The LiveScore Football Match):**
  > *"Think of a live football match between Chelsea and Arsenal on LiveScore. When a goal is scored, that is an immutable event. It receives a unique, discrete `event_id`. Can the fact that this goal occurred change retroactively? No. If two goals or card bookings happen within the exact same microsecond, their timestamps collide, but their `event_id` keys remain distinct."*

* **The Consensus:**
  * For append-only event streams, using a unique, sequential surrogate or primary key like **`event_id`** prevents dropped records caused by timestamp collisions.
  * Timestamps are viable for mutable tables (e.g., updating a customer profile where an `updated_at` column tracks mutations), but the pipeline designer must understand whether the underlying table follows **append-only** or **in-place update** semantics.

### 3. Live Verification of Incremental Sync
To prove the CDC mechanism on screen:
1. Victor inserted additional records into `lesson_events` in PostgreSQL.
2. The manual sync was triggered on Databricks.
3. The cluster initiated (acknowledging cold-start latency due to compute cluster spinning up).
4. The ingestion log confirmed: **Exactly 3 new records were read and appended**, leaving prior rows untouched.

---

## 🥇 Part 3: The Medallion Architecture Deconstructed

Once raw operational records land inside Databricks, how should data be structured across its analytical lifecycle? Victor walked through the industry-standard **Medallion Architecture**.

```
    ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
    │     BRONZE      │  ───► │     SILVER      │  ───► │      GOLD       │
    │   (Raw / Staging)│       │ (Clean / Trans) │       │(Curated / Serving)
    └─────────────────┘       └─────────────────┘       └─────────────────┘
      • Append-only             • Deduplication           • Business KPIs
      • Unaltered schema        • Type casting            • Star / Snowflake
      • Complete history        • Enrichment & joins      • Aggregated metrics
      • Retains corrupt rows    • Conformed schemas       • Ready for BI & AI
```

### 1. Bronze Layer (Raw Ingestion / Landing Zone)
* **Purpose:** Stores raw, uncleaned data in its authentic source state.
* **Characteristics:** Append-only, preserves source column naming, retains malformed rows and semi-structured payloads (e.g., raw JSON strings from Kafka, S3, or marketing APIs).
* **Guiding Rule:** Zero complex business transformations occur here.

### 2. Silver Layer (Cleaned, Enriched & Conformed)
* **Purpose:** Provides a consistent, enterprise-wide view of core entities.
* **Transformations Performed:**
  * Deduplication of batch payloads.
  * Data type casting (converting string dates to ISO timestamps, parsing currency strings to numeric decimals).
  * Flattening nested JSON structures into relational tabular columns.
  * Handling missing values and enforcing relational constraints.

### 3. Gold Layer (Curated Business & Serving Marts)
* **Purpose:** Powers high-throughput reporting, strategic dashboards, machine learning features, and external integrations.
* **Characteristics:** Dimensional models (**Star Schema / Snowflake Schema / OBT**), pre-computed aggregations, and business metrics (e.g., Monthly Recurring Revenue, Daily Active Users).

### 4. Organizational Naming Variations
In response to **Yinka Ogunneye** and **Goodness Azike**, Victor emphasized that companies don't always use the words *Bronze, Silver, Gold*:
* Alternate conventions include: **Raw $\rightarrow$ Staging / Intermediate $\rightarrow$ Reporting / Serving / Production**.
* **Anti-Pattern Warning:** Victor cited a prior company that named their gold serving layer `"Tableau"`. When new engineers and analysts joined, they were hesitant to query the database, assuming it was exclusively reserved for Tableau dashboard extracts. Standard naming (**Gold / Serving**) guarantees smooth organizational onboarding.

---

## 🤖 Part 4: Downstream Data Consumption: Who Gets Access to What?

A critical theme of the session was evaluating downstream data requests and applying the **Principle of Least Privilege**.

### 1. LLMs and AI Agents: Exposing Gold vs. Silver
When Victor polled the class on which layer should feed Large Language Models (LLMs) and autonomous AI query engines (via interfaces like Model Context Protocol - MCP):
* **Initial Audience Split:** Some suggested Bronze or Silver.
* **The Correct Architectural Decision:** **Gold Layer**.
* **Reasoning:**
  * LLMs ingest text prompts and generate SQL queries or analytical summaries. Exposing them to Bronze or dirty Silver tables risks severe **hallucination**, as the model must guess business logic, handle duplicate rows, and filter corrupted records.
  * Querying Gold guarantees the LLM works against validated metrics, clean relational constraints, and curated definitions.

### 2. Reverse ETL (Syncing Lakehouse Data to HubSpot, Salesforce, Google Ads)
* **The Decision:** Expose exclusively from the **Gold Layer**.
* **Reasoning:** Reverse ETL pipes metrics out of the lakehouse back into customer-facing tools (e.g., passing audience churn scores to HubSpot for targeted sales campaigns). Syncing unvetted Bronze/Silver data could trigger misdirected marketing emails or corrupted customer profiles.

### 3. Security, Column-Level Masking & Governance
Responding to **Godwin Nosa's** point on data privacy:
* Just because a table resides in the Gold layer does not mean every user or tool receives unrestricted access.
* **Best Practice:** Apply **dynamic views** or **column-level masking policies** over Gold tables to restrict Personally Identifiable Information (PII) like email addresses, phone numbers, and home addresses, granting access only to authorized personnel while exposing aggregate metrics to general users.

---

## 🎯 Part 5: The Universal Semantic Layer

Victor introduced the **Semantic Layer**, framing it as the ultimate solution to corporate metric discrepancies.

```
                      WITHOUT A SEMANTIC LAYER
     ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
     │   Model A    │    │   Model B    │    │   Model C    │
     │  (Analyst 1) │    │  (Analyst 2) │    │  (Analyst 3) │
     └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
            ▼                   ▼                   ▼
       Active Subs =       Active Subs =       Active Subs =
       Paid only           Paid + Free Trial   Paid + Grace Period
            └───────────────────┼───────────────────┘
                                ▼
                   EXECUTIVE BOARDROOM CONFUSION!
 ═══════════════════════════════════════════════════════════════════════════
                       WITH A SEMANTIC LAYER
                 ┌───────────────────────────────┐
                 │    UNIVERSAL SEMANTIC LAYER   │
                 │   Single Governed Definition  │
                 │ "Active Sub = Paid Status > 0"│
                 └──────────────┬────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
 ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
 │ PowerBI / BI │        │ SQL Analysts │        │  LLM / MCP   │
 └──────────────┘        └──────────────┘        └──────────────┘
            ALL CONSUMERS REPORT THE EXACT SAME NUMBER!
```

### 1. The Metric Discrepancy Crisis
Consider three data analysts in the same company asked to compute **Active Subscriptions**:
* **Analyst 1 (Yinka):** Writes SQL defining an active subscriber as anyone who paid cash this month.
* **Analyst 2 (Timmy):** Includes customers on 14-day free trials.
* **Analyst 3 (Pamela):** Includes customers whose accounts are suspended in a 7-day payment grace period.
* **The Result:** Three conflicting numbers presented to the executive team, eroding trust in the entire data organization.

### 2. The Solution: Governed Metrics
A **Semantic Layer** acts as an abstraction layer sitting between transformation models and downstream consumers:
* Business logic is defined **once in code** (e.g., using **dbt MetricFlow / semantic models** via YAML configurations).
* Whether a query originates from **PowerBI**, a raw **SQL query in Databricks**, or a **ChatGPT agent**, every consumer references the exact same upstream metric definition.
* **Tool-Agnostic Durability:** If an enterprise migrates from Tableau to PowerBI, the underlying KPIs remain untouched because they reside in the data platform code base rather than inside proprietary dashboard workbooks.

---

## 💬 Part 6: Cohort Q&A & Technical Clarifications

Throughout the two-part session, several high-impact questions were addressed:

* **Q: Can an enterprise maintain multiple Gold layers? (Elijah 'Dotun Aremu & Ose Benson)**  
  * **Victor:** Absolutely. Gold layers are frequently segregated by business domain (e.g., `gold_finance`, `gold_marketing`, `gold_supply_chain`). You do not dump every department's analytical models into a single monolithic schema.

* **Q: If analysts are still joining 5 or 6 tables in the Gold layer, does that mean the data engineering team failed? (Gbenga Owoeye)**  
  * **Victor:** Not necessarily. The Gold layer implements dimensional modeling (**Star Schema**). Having a central Fact table join to 4 or 5 Dimension tables via primary/foreign surrogate keys is standard best practice. What analysts should **never** have to do in Gold is extract raw JSON strings, parse regex, or clean messy string representations—that work belongs in Silver.

* **Q: Is data modeling primarily theoretical, or will we write actual code? (Yinka Ogunneye)**  
  * **Victor:** Modeling theory establishes the architectural blueprint. In the upcoming transformation modules, students will use **dbt** and **Databricks SQL** to build out real-world fact and dimension tables, test assertions, and build production data models hands-on.

---

## 📋 Comprehensive Action Items & Preparation Checklist

| Category | Requirement | Context & Next Steps |
| :--- | :--- | :--- |
| **Cloud Setup** | **Databricks Free Account** | Every student must create a free Databricks account prior to the dbt hands-on transformation module. |
| **Version Control** | **GitHub Repository** | Initialize an empty public/private GitHub repository to link with dbt and Databricks for CI/CD tracking. |
| **Concepts to Review** | **Medallion Pipeline Stages** | Review the responsibilities of Bronze (raw ingestion), Silver (cleaning/deduping), and Gold (serving/Star schema). |
| **Tooling Exploration** | **dbt Semantic Layer** | Read introductory documentation on dbt semantic models and MetricFlow ahead of class code demonstrations. |
| **Resource Distribution**| **Postgres Scripts** | Instructor Victor Okon will distribute the DDL/DML scripts used to seed the AWS PostgreSQL instance. |


### Key Highlights:

- **Unified Flow:** Seamlessly bridges Part 1 (hands-on database setup, DataGrip vs. Databricks, PostgreSQL privilege granting) with Part 2 (live ingestion verification, cursor selection, Medallion Architecture, LLMs, and semantic layers).
- **Clear Visual Architecture Diagrams:** Includes clean ASCII workflows for operational CDC streaming, the cursor debate decision tree, the Medallion progression, and the Metric Discrepancy Crisis solved by a Semantic Layer.
- **Comprehensive Technical Coverage:** Retains every real-world nuance discussed by attendees, including discrete vs. timestamp cursors, Postgres direct ingestion (vs. SQL Server volumes), least-privilege access masking, and domain-specific Gold schema partitioning.