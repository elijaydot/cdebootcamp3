# 🏗️ Data Modeling Masterclass: Architecting OLTP, OLAP & Scalable Enterprise Pipelines
**A Comprehensive, Catchy, and Highly Detailed Executive & Technical Summary of the 130-Minute Masterclass**

---

## 📅 Session Metadata
- **Date & Time:** September 12, 2026 | 8:51:38 PM – 11:01:38 PM (130 minutes)
- **Lead Instructor:** Victor Okon
- **Core Topics:** Data Modeling Phases, OLTP vs. OLAP Architecture, ERD Cardinality Dynamics, CDC (Change Data Capture), Dimensional Modeling (Star vs. Snowflake vs. OBT), and Live Telecom System Design.
- **Participants:** 44 active attendees (including AbdulRasaq Bilau, Lorreta Anyika, Osakpolor Ogieriakhi, Raphael Affiah, Dennis Humes, Chidinma Okeh, Adeyina Tolulope, Lahya Haidula, and others).

---

## 🧭 Executive Overview: The Consultant’s Fundamental Question

Data modeling is not merely drawing database diagrams in isolation—it is the strategic bridge between business operations and analytical intelligence. Instructor **Victor Okon** framed the entire session around a foundational principle every data engineer and consultant must master:

> *"Before touching SQL, spinning up a warehouse, or choosing a database engine, you must ask one critical question: **Who are the end users of this data, and what is the workload pattern?**"*

- If the end users are **mobile/web application customers** performing continuous, low-latency transactional updates $
ightarrow$ **Design an OLTP System (Normalized / 3NF)**.
- If the end users are **BI analysts, data scientists, and reporting dashboards** running massive analytical queries and aggregations $
ightarrow$ **Design an OLAP System (Denormalized / Star / Snowflake / OBT)**.

Attempting to force analytical workloads onto transactional engines—or vice-versa—results in catastrophic latency, application lag, and ballooning cloud warehouse compute bills.

---

## 🔄 Part 1: The Three Phases of Data Modeling & Implementation

Before diving into physical infrastructure, data models must mature through three progressive stages:

```
┌───────────────────────────────┐
│     1. CONCEPTUAL PHASE       │ ➔ High-Level Business Entities (What data exists?)
│  (Users, Rides, Transactions) │
└───────────────┬───────────────┘
                ▼
┌───────────────────────────────┐
│      2. LOGICAL PHASE         │ ➔ Attributes, Datatypes & Relationships (ERD)
│  (Columns, PKs, FKs, Grain)   │
└───────────────┬───────────────┘
                ▼
┌───────────────────────────────┐
│     3. PHYSICAL PHASE         │ ➔ Storage Engines, DDL, Views, Partitioning,
│ (PostgreSQL, Snowflake, DDL)  │   Clustering & Auto-scaling strategies
└───────────────┬───────────────┘
                ▼
┌───────────────────────────────┐
│   IMPLEMENTATION TECHNIQUE    │ ➔ 3NF (Normalized OLTP) vs. 
│  (Workload-Driven Selection)  │   Kimball Dimensional (Denormalized OLAP)
└───────────────────────────────┘
```

1. **Conceptual Phase:** Identifies core business entities (e.g., Users, Transactions, Products, Rides) based on business requirements without worrying about technical implementation.
2. **Logical Phase:** Defines specific attributes (columns) for each entity, establishes primary/foreign keys, determines the exact granularity (grain), and formalizes table relationships.
3. **Physical Phase:** Determines physical realization—materialized tables vs. views, choice of database engine (RDBMS vs. Columnar Cloud DWH), indexing, partitioning schemes, and compute scaling.

---

## ⚡ Part 2: OLTP vs. OLAP — The Tale of "Two Andrews"

To vividly illustrate why transactional and analytical engines cannot be naively combined at scale, Victor introduced a scenario featuring a user/analyst named **Andrew**.

### Scenario A: Andrew as the Mobile App Customer (OLTP)
- Andrew opens his ride-hailing app (Uber/Bolt) and updates his profile email.
- **Under an OLTP (3NF) Architecture:**
  - The app sends an HTTP request $
ightarrow$ Hits Backend API $
ightarrow$ Hits PostgreSQL/MySQL database.
  - The email is updated in exactly **one place**: the normalized `User` entity.
  - Every other table (e.g., `Rides`, `Transactions`) references `User` via `user_id`.
  - **Result:** Sub-millisecond execution, zero data redundancy, zero write conflicts.
- **The "OLAP Disaster" Failure Mode:**
  - If this operational app were built on a denormalized dimensional model, Andrew's email might be duplicated across the `Dim_User`, `Fact_Rides`, and `Fact_Transactions` tables.
  - Updating a single email would require expensive updates across millions of transactional rows, creating application lag, locks, and latency.

### Scenario B: Andrew as the Data Analyst (OLAP)
- Andrew needs a list of all customers who completed rides between specific dates, along with their emails, to launch a Black Friday promotional campaign.
- **Under an OLTP Architecture:**
  - Andrew must write queries with 5+ complex `LEFT JOIN` / `INNER JOIN` statements across normalized tables.
  - Doing this across millions of rows causes high disk I/O, heavy CPU utilization, and extreme latency.
- **Under an OLAP (Dimensional) Architecture:**
  - The warehouse pre-aggregates and denormalizes attributes into dimensions (`Dim_Users`, `Dim_Location`) surrounding a central `Fact_Rides` table.
  - Andrew performs a single, lightning-fast join.

### 🚪 The "Single-Door Banquet Hall" Metaphor (Handling Database Workload)
Addressing Adeyina Tolulope’s question on why we don't just point BI tools directly at operational PostgreSQL:
> Imagine a banquet hall with **one single door** used for both guests entering/exiting and waiters carrying food trays.
> - With **3 guests** (a tiny startup), one door works fine.
> - With **8,000 guests** (scaled production), waiters collide with guests, food spills, and movement grinds to a halt.
> - In databases: Operational writes (waiters) lock tables and collide with massive analytical `SELECT` scans (guests), causing query timeouts, CPU spikes, and application outages.

---

## 📊 Comprehensive Comparison: OLTP vs. OLAP

| Feature / Metric | OLTP (Online Transaction Processing) | OLAP (Online Analytical Processing) |
| :--- | :--- | :--- |
| **Primary End Users** | End-user mobile/web apps, operational staff | BI analysts, data scientists, executives, dashboards |
| **Workload Type** | High-concurrency, fast ACID write/update operations | Heavy read operations, multi-table aggregations |
| **Data Structure** | Highly Normalized (3rd Normal Form - 3NF) | Denormalized (Star Schema, Snowflake, One Big Table) |
| **Underlying Storage** | Row-oriented storage (fast row retrieval/updates) | Columnar storage (reads only query-relevant columns) |
| **Typical Engines** | PostgreSQL, MySQL, Oracle, CockroachDB | Snowflake, Databricks, Google BigQuery, AWS Redshift, DuckDB |
| **Optimization Focus** | Eliminating write redundancy & transaction lag | Minimizing compute cost, query execution duration & joins |

---

## 🔗 Part 3: Entity Relationship Diagrams (ERD) & Cardinality

Victor walked the cohort through practical relationship dynamics using real-world enterprise scenarios:

### 1. One-to-Many ($1 : M$)
- **Example:** A registered user can book multiple rides/trips over time; however, an individual ride ID belongs strictly to one unique user ID.
- **Example 2:** A customer can perform multiple subscription transactions, but each unique transaction ID maps to exactly one customer.

### 2. Many-to-Many ($M : N$)
- **Example:** Travel booking platform (Travelbeta / Wakanow). Multiple travelers can book tour packages to the Maldives, and a tour provider offers multiple packages booked by numerous travelers.
- **Resolution:** Implemented in relational databases via an associative **junction/bridge table**.

### 3. One-to-One ($1 : 1$)
- **Example:** In a telecom network, an individual assigned active SIM card phone number connects to one specific user profile record.

### 4. Zero/One-to-Many (Conditional Cardinality)
- **The "Fanta in the Store" Analogy:** A store stocks various Fanta flavors.
  - On a slow day, **0 people** purchase Fanta ($0$ relationship).
  - On a busy day, **multiple customers** purchase Fanta ($M$ relationship).
  - The product entity exists independently, whether or not downstream transactional events occur.

---

## 📱 Part 4: Interactive Architecture Workshop — Building "MTN-Style" Telecom Data System

Guided by student inputs (notably **Lorreta Anyika**, **Osakpolor Ogieriakhi**, and **Olugbade Waziri**), the class architected a full-scale telecommunications data system from the ground up:

```
                            ┌─────────────────────────────────┐
                            │   Mobile App / End Customer     │
                            └────────────────┬────────────────┘
                                             │ HTTP Requests
                                             ▼
                            ┌─────────────────────────────────┐
                            │     Backend API Application     │
                            └────────────────┬────────────────┘
                                             │ ACID Write Operations
                                             ▼
     ═════════════════════════════════════════════════════════════════════════
     PHASE 1: OPERATIONAL SYSTEM (OLTP)
     ═════════════════════════════════════════════════════════════════════════
                      ┌──────────────────────────────────────┐
                      │    PostgreSQL Operational Database   │
                      │  (Normalized 3NF: Users, Accounts,   │
                      │   Products/Plans, Subscriptions)     │
                      └──────────────────┬───────────────────┘
                                         │
                                         │  CDC Engine (Change Data Capture)
                                         │  Initial Full Snapshot + Stream Updates
                                         ▼
     ═════════════════════════════════════════════════════════════════════════
     PHASE 2: ANALYTICAL PIPELINE INGESTION (OLAP)
     ═════════════════════════════════════════════════════════════════════════
                      ┌──────────────────────────────────────┐
                      │   Databricks Ingestion Lakehouse     │
                      │  (DBFS Volume Storage Staging Area)  │
                      └──────────────────┬───────────────────┘
                                         │
                                         │  dbt (Transformation & Modeling)
                                         ▼
     ═════════════════════════════════════════════════════════════════════════
     PHASE 3: ANALYTICAL SERVING WAREHOUSE (OLAP)
     ═════════════════════════════════════════════════════════════════════════
                      ┌──────────────────────────────────────┐
                      │    Enterprise Dimensional Warehouse  │
                      │  (Star Schema / Snowflake / OBT)     │
                      └──────────────────┬───────────────────┘
                                         │
                   ┌─────────────────────┴─────────────────────┐
                   ▼                                           ▼
       ┌───────────────────────┐                   ┌───────────────────────┐
       │ BI Analysts / Reports │                   │ Reverse ETL (HubSpot) │
       └───────────────────────┘                   └───────────────────────┘
```

### 1. Conceptual & Logical Definitions
- **User / Customer Table:** `user_id` (PK), `name`, `age`, `contact_details`.
- **Subscription / Product Table:** `product_id` (PK), `plan_name` (e.g., "20GB Data Bundle"), `price`, `validity`.
- **Transaction Table:** `transaction_id` (PK), `user_id` (FK), `product_id` (FK), `amount`, `payment_timestamp`.
- **Location Table:** `location_id` (PK), `city_name`, `country_name`.

### 2. Startup MVP vs. Scaled Enterprise Architecture
- **Phase 1 (The Lean Startup):** When launching with 10–100 users, maintain a single PostgreSQL database for both operational app traffic and occasional internal reporting. Avoid premature optimization or unnecessary cloud warehouse overhead.
- **Phase 2 (The Scaled Enterprise):** As traffic surges to 1,000,000+ active subscribers, decouple operations immediately:
  - Route all app writes through PostgreSQL (OLTP).
  - Stream transaction logs into an analytical engine like Databricks or Snowflake (OLAP) via **CDC (Change Data Capture)**.

---

## 🔀 Part 5: Data Migration — Why CDC Trumps Python Scripts at Scale

When Chidinma Okeh and Raphael Affiah asked why data cannot simply be copied using a custom Python script or read replicas:

1. **Failure Modes of Python ETL Scripts at Scale:**
   - A Python ingestion script querying `SELECT * FROM source` consumes high source CPU, lacks reliable built-in state tracking, and crashes under billions of records.
2. **What is Change Data Capture (CDC)?**
   - **Step 1:** Takes an initial full snapshot of the source tables.
   - **Step 2:** Continuously monitors the database write-ahead/transaction log (WAL).
   - **Step 3:** Streams only net-new row modifications (`INSERT`, `UPDATE`, `DELETE`) directly into staging volumes (e.g., Databricks Volumes) without placing analytical query loads on the transactional database.

---

## ❄️ Part 6: Dimensional Modeling Deep Dive — Star vs. Snowflake vs. One Big Table (OBT)

Once data lands in the warehouse, how should it be structured? Victor compared the three primary modeling methodologies:

```
    STAR SCHEMA                  SNOWFLAKE SCHEMA                     ONE BIG TABLE (OBT)
 ─────────────────              ──────────────────                   ─────────────────────
    ┌──────────┐                   ┌──────────┐                       ┌─────────────────┐
    │ Dim_User │                   │ Dim_User │                       │                 │
    └────┬─────┘                   └────┬─────┘                       │                 │
         │                              │                             │   Denormalized  │
 ┌───────┴───────┐              ┌───────┴───────┐                     │   Single Table  │
 │ Fact_Transact │              │ Fact_Transact ├──┬──────────────┐   │                 │
 └───────┬───────┘              └───────┬───────┘  │              │   │  All Dimensions │
         │                              │     ┌────┴─────┐  ┌─────┴──┐│   + Metrics In  │
    ┌────┴─────┐                   ┌────┴─────│ Dim_City │  │Country ││   One Mega Row  │
    │ Dim_Plan │                   │ Dim_Plan │ └────────┘  └────────┘│                 │
    └──────────┘                   └──────────┘                       │                 │
 (Denormalized Dims)             (Normalized Sub-Dims)                └─────────────────┘
 Fast Joins, Clean DWH          Low Redundancy, Complex Joins         Zero Joins, High Storage
```

### 1. Star Schema
- **Structure:** A centralized quantitative `Fact` table surrounded by completely denormalized `Dimension` tables containing descriptive attributes.
- **Pros:** Fast query performance, intuitive business logic, fewer table joins.
- **Cons:** Moderate data redundancy within dimension tables.

### 2. Snowflake Schema
- **Structure:** An extension of the Star Schema where dimension tables are broken down into sub-dimensions (normalized). For example, separating `Location` into `Dim_City` and `Dim_Country`.
- **When is it used?**
  - Clarified for Osakpolor Ogieriakhi: Snowflake schema is valuable when specific sub-dimensions must be independently exposed to external auditors, regulatory interfaces, or specialized SaaS endpoints via **Reverse ETL** (e.g., syncing only verified operational cities into HubSpot or Salesforce).
- **Cons:** Introduces multi-level table joins, increasing warehouse query execution duration and compute credit burn.

### 3. One Big Table (OBT)
- **Structure:** Eliminates dimension tables entirely by flattening all metrics and descriptors into a single massive table.
- **Pros:** Zero joins required; business analysts write simple `SELECT` statements.
- **Cons:** High data redundancy; updating historical records requires scanning and rewriting wide partitions.

---

## ⚡ Part 7: Physical Optimization — Partitioning & Cloud Warehouse Billing

Victor underscored how physical tuning directly influences company cloud expenditure:

- **The Problem:** Running `SELECT * FROM transactions WHERE date = '2026-09-12'` against an unpartitioned table forces a full scan across years of transactional history, taking 30+ minutes and burning excessive cloud compute credits.
- **The Solution (Partitioning by Date):** 
  - Partitioning physically clusters storage blocks by calendar date.
  - The query engine uses partition pruning to scan **only** the September 12, 2026 partition block, reducing runtime from **30 minutes down to under 60 seconds**.
- **Rule of Thumb:** Partition tables on low-to-medium cardinality filtering columns (e.g., `event_date`) rather than high-cardinality values (e.g., `timestamp` or `transaction_id`).

---

## 📋 Comprehensive Action Items & Next Class Syllabus

| Area / Concept | Topic to Review | Context & Preparation |
| :--- | :--- | :--- |
| **Architectural Theory** | **Columnar vs. Row-Based Storage** | Study how Parquet/Delta (columnar) accelerates aggregations compared to row-based engines (Postgres). |
| **Data Ingestion** | **Change Data Capture (CDC)** | Review log-based CDC architecture and replication streaming into Databricks Volumes. |
| **Dimensional Modeling**| **Star vs. Snowflake Re-cap** | Revisit tradeoffs between join latency (Star) vs. dimensional normalization (Snowflake). |
| **Tooling & Transformation** | **dbt (data build tool)** | Next class will build hands-on facts and dimensions using dbt on Databricks. |
| **Class Materials** | **Review Slides & Diagram** | Review exported architectural diagrams and system whiteboard notes distributed by the instructor. |


### **Executive Summary & Key Highlights of the Session**

- **The Core Data Modeling Principle**: Data modeling choices depend entirely on **who the end user is** and **what operations they perform**. Operational app interactions require high-write, normalized OLTP systems, while reporting and analytics demand read-optimized, denormalized OLAP architectures.
- **The "Two Andrews" Case Study**: Contrasts how a single user update (e.g., changing an email) behaves smoothly in a 3NF OLTP database versus the write-amplification nightmare it creates in an OLAP model. Conversely, it shows how an analyst querying across complex operational joins causes latency and warehouse credit burn.
- **The "Single-Door Banquet Hall" Metaphor**: Explains database concurrency and resource contention—running heavy analytical queries directly against an operational database locks tables and crashes app responsiveness.
- **Entity Relationship Dynamics**: Clear explanations of $1:1$, $1:M$, $M:N$ (via bridge tables), and zero-to-many relationships (illustrated using the *"Fanta in the Store"* analogy).
- **Interactive Telecom System Architecture (MTN Blueprint)**: Step-by-step design of conceptual entities (Users, Products/Plans, Subscriptions, Transactions, Locations), detailing how a startup begins with a single PostgreSQL instance before evolving into an enterprise lakehouse.
- **CDC vs. Ad-Hoc Migration**: Why custom Python scripts fail under massive transaction loads and how log-based **Change Data Capture (CDC)** provides zero-impact streaming into staging areas like Databricks Volumes.
- **Dimensional Modeling Face-Off**: Comparative breakdown of **Star Schema**, **Snowflake Schema** (including specific use cases like Reverse ETL to external platforms such as HubSpot), and **One Big Table (OBT)**.
- **Physical Optimization & Partitioning**: How date-based partition pruning slashes analytical query execution times from 30 minutes down to 1 minute, lowering cloud billing costs.