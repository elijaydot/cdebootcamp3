# 🏗️ Data Modeling & System Architecture: OLTP, OLAP & Enterprise Pipeline Design
**Masterclass Technical & Strategic Summary | September 12, 2026**

---

## 📌 Executive Summary

This masterclass, facilitated by senior data engineer **Victor Okon**, tackles the fundamental crossroad every software and data engineer faces: **designing database architectures that balance operational responsiveness with analytical throughput**.

The central thesis of the session is clear:
> *"Before writing a line of DDL, selecting an ingestion tool, or provisioning a cloud warehouse, an engineer must answer one decisive question: **Who is the end user of this data, and what is the workload pattern?**"*

Using interactive analogies, live whiteboard system diagrams, and a collaborative enterprise telecom buildout (modeled after **MTN / Beejan Technologies**), the session contrasts **Online Transaction Processing (OLTP)** against **Online Analytical Processing (OLAP)**, breaks down **Entity Relationship Diagram (ERD) cardinality**, examines **Change Data Capture (CDC)** migration mechanics, and weighs the performance trade-offs between **Star**, **Snowflake**, and **One Big Table (OBT)** schemas.

---

## 👤 The Tale of "Two Andrews": Workload Mechanics

To illustrate why transactional and analytical requirements demand fundamentally different data structures, the instructor introduced two personas sharing the name **Andrew**:

```
                       ┌───────────────────────────────────────────────┐
                       │               THE TWO ANDREWS                 │
                       └───────────────────────┬───────────────────────┘
                                               │
               ┌───────────────────────────────┴───────────────────────────────┐
               ▼                                                               ▼
 ┌───────────────────────────┐                                   ┌───────────────────────────┐
 │   ANDREW THE APP USER     │                                   │   ANDREW THE DATA ANALYST │
 ├───────────────────────────┤                                   ├───────────────────────────┤
 │ • Updating email address  │                                   │ • Querying Black Friday   │
 │ • Low latency required    │                                   │   promo audience          │
 │ • Workload: High-write    │                                   │ • Multi-table joins       │
 │ • Architecture: OLTP/3NF  │                                   │ • Workload: Heavy-read    │
 │ • Single row affected     │                                   │ • Architecture: OLAP/Star │
 └───────────────────────────┘                                   └───────────────────────────┘
```

### 1. Andrew the Operational Mobile User (OLTP)
- **Action:** Andrew opens a ride-hailing app (e.g., Uber or Bolt) and updates his profile email address.
- **Under Normalized OLTP (3NF):**
  - The mobile client sends an HTTP request through the API gateway down to an operational RDBMS (e.g., PostgreSQL or MySQL).
  - The write touches **exactly one row** in the isolated `User` table.
  - Related tables (`Rides`, `Transactions`) reference Andrew via `user_id`.
  - **Result:** Sub-millisecond execution, zero write-amplification, no data anomalies.
- **The "Denormalized OLAP Failure Mode":**
  - If the operational app were backed by a denormalized schema where Andrew’s email was embedded across `Rides`, `Transactions`, and `Driver_Ratings`, a single email update would require locking and rewriting thousands or millions of historical records, causing app freezes, timeouts, and latency spikes.

### 2. Andrew the BI Analyst (OLAP)
- **Action:** Andrew is tasked by marketing stakeholders to extract emails of all riders who took trips between specific promotional dates to dispatch a campaign.
- **Under Normalized OLTP:**
  - Andrew must write a query spanning 5+ deep relational joins across `Users`, `Rides`, `Transactions`, and `Locations`.
  - Running this aggregation against millions of operational rows consumes massive memory and CPU, stalling the operational database.
- **Under Denormalized OLAP (Star Schema):**
  - Pre-joined and dimensionally structured tables (`Dim_User`, `Fact_Rides`) allow Andrew to fetch the required audience in a single, lightning-fast scan.

---

## 🚪 The "Single-Door Banquet Hall" Analogy

When **Adeyina Tolulope** questioned why companies cannot simply point Business Intelligence (BI) dashboards directly at the operational PostgreSQL database, Victor delivered the **Banquet Hall Metaphor**:

* **The Setup:** Imagine a banquet hall that has only **one physical door**.
* **The 3-Guest Scenario (Early-Stage Startup):** With only 3 attendees, one door easily accommodates guests walking in and out, as well as waiters carrying hot food trays into the hall.
* **The 8,000-Guest Scenario (Scaled Enterprise):** When 8,000 guests crowd the single door, waiters carrying trays (operational writes) collide with exiting guests (analytical read queries). Food spills, movement stops, and the door collapses under the weight.
* **The Database Reality:** Operational ACID writes and massive table-scanning analytical queries compete for the same CPU cores, disk I/O, and table locks. Analytical queries starve transactional updates, causing operational app crashes. **Separating OLTP (writes) from OLAP (reads) is mandatory at scale.**

---

## ⚖️ Architectural Matrix: OLTP vs. OLAP

| Feature / Dimension | OLTP (Online Transaction Processing) | OLAP (Online Analytical Processing) |
| :--- | :--- | :--- |
| **Primary Stakeholder** | End-user applications, operational backend APIs | Data analysts, analytics engineers, BI tools, data scientists |
| **Workload Pattern** | High concurrency, millisecond write/update operations | Complex batch reads, aggregations, scanning millions of records |
| **Data Schema** | Highly normalized (3rd Normal Form / 3NF) | Denormalized (Star Schema, Snowflake Schema, One Big Table) |
| **Storage Architecture** | Row-oriented storage (efficient for retrieving full single rows) | Columnar storage (reads only query-relevant attributes) |
| **Storage Engines** | PostgreSQL, MySQL, CockroachDB, Oracle | Snowflake, Databricks (Delta Lake), Google BigQuery, AWS Redshift |
| **Core Optimization** | Zero redundancy, ACID compliance, write speed | Query performance, minimized join complexity, lower compute costs |

---

## 🔗 ERD Dynamics: Demystifying Cardinality

Using interactive audience challenges, the class mapped out cardinalities across real-world business domains:

### 1. One-to-One ($1:1$)
- **Example:** Telecom SIM card to Phone Number. A single active operational SIM card maps strictly to one allocated network phone number.

### 2. One-to-Many ($1:M$)
- **Example:** User to Rides/Transactions. One user can hail hundreds of rides and generate hundreds of subscription payments; however, a unique `transaction_id` maps back strictly to one customer.

### 3. Many-to-Many ($M:N$)
- **Example:** Tour Platforms (**Travelbeta / Wakanow**). A tour operator lists vacation packages (e.g., trips to the Maldives, Spain, or Ghana). One traveler can book multiple tour packages over time, and a single tour package can be booked by dozens of independent travelers.
- **Relational Implementation:** Relational engines cannot natively resolve $M:N$ relationships without data duplication; they require an intermediate **associative entity (bridge / junction table)**.

### 4. Zero/One-to-Many ($0..1 : M$) — The "Fanta in the Store" Analogy
Addressing confusion raised by **Qudus Abdulahi**, **Salome Gabriel**, and **Uche Nmaju** regarding optional relationships:
- Walk into a supermarket and look at a shelf stocked with different flavored bottles of **Fanta**.
- **Case 0:** On a rainy Tuesday morning, zero customers purchase grape-flavored Fanta ($0$ relationship). The product exists in the catalog, but has zero child transaction records.
- **Case Many ($M$):** On a hot Saturday afternoon, 50 distinct customers buy the product ($M$ relationship).
- **Takeaway:** Cardinality must account for business reality—parent entities can exist in product catalogs prior to and independent of downstream transactional activity.

---

## 🏛️ Live System Design: Building a Scalable Telecom Architecture (MTN Blueprint)

Driven by requirements from student business owner **Lorreta Anyika**, the cohort designed the complete data lifecycle of a telecommunications service provider:

```
                              [ CUSTOMER MOBILE APP / USSD ]
                                             │
                                             │ HTTP / API Traffic
                                             ▼
                                   [ BACKEND API SERVICES ]
                                             │
                                             │ ACID Writes
                                             ▼
 ══════════════════════════════════════════════════════════════════════════════════════════════
 🟢 PHASE 1: OPERATIONAL SYSTEM (OLTP)
 ══════════════════════════════════════════════════════════════════════════════════════════════
                  ┌────────────────────────────────────────────────────────┐
                  │            PostgreSQL Transactional Database           │
                  │  ┌─────────────────┐ ┌─────────────────┐ ┌───────────┐ │
                  │  │   Users/Signup  │ │ Products/Plans  │ │ Locations │ │
                  │  └────────┬────────┘ └────────┬────────┘ └─────┬─────┘ │
                  │           │                   │                │       │
                  │           └─────────────┬─────┴────────────────┘       │
                  │                         ▼                              │
                  │              ┌──────────────────────┐                  │
                  │              │     Transactions     │                  │
                  │              └──────────────────────┘                  │
                  └─────────────────────────┬──────────────────────────────┘
                                            │
                                            │ Log-Based CDC Stream
                                            │ (Zero Operational Query Overhead)
                                            ▼
 ══════════════════════════════════════════════════════════════════════════════════════════════
 🔵 PHASE 2: INGESTION & STORAGE VOLUMES
 ══════════════════════════════════════════════════════════════════════════════════════════════
                  ┌────────────────────────────────────────────────────────┐
                  │              Databricks Ingestion Lakehouse            │
                  │  Raw Parquet Landing Zone (DBFS Volumes Storage Area)  │
                  └─────────────────────────┬──────────────────────────────┘
                                            │
                                            │ Transformations & Dimensional Modeling
                                            │ (orchestrated via dbt)
                                            ▼
 ══════════════════════════════════════════════════════════════════════════════════════════════
 🟣 PHASE 3: ANALYTICAL CONSUMPTION WAREHOUSE (OLAP)
 ══════════════════════════════════════════════════════════════════════════════════════════════
                  ┌────────────────────────────────────────────────────────┐
                  │              Dimensional Warehouse Schema              │
                  │                                                        │
                  │   [ Dim_Users ]       [ Dim_Plan ]     [ Dim_Location ]│
                  │         │                  │                  │        │
                  │         └────────────┐     │     ┌────────────┘        │
                  │                      ▼     ▼     ▼                     │
                  │                  ┌───────────────────┐                 │
                  │                  │ Fact_Transactions │                 │
                  │                  └───────────────────┘                 │
                  └──────────────────────────┬─────────────────────────────┘
                                             │
                        ┌────────────────────┴────────────────────┐
                        ▼                                         ▼
             [ BI Reports & Analytics ]               [ Reverse ETL / CRM Exports ]
             (Tableau, PowerBI, SQL)                  (Syncing Dim_City to HubSpot)
```

### 1. Conceptual & Logical Modeling
* **`User / Signup`:** Captures subscriber profile attributes (`user_id`, `name`, `age`, `registered_at`).
* **`Product / Subscription Plan`:** Captures bundle offerings (`product_id`, `plan_name`, `data_allowance_gb`, `validity_period`).
* **`Transaction / Payment`:** Ingests financial activities (`transaction_id`, `user_id`, `product_id`, `amount_paid`, `transaction_date`).
* **`Location`:** Tracks regional infrastructure (`location_id`, `city_name`, `country_name`).
* **Business Rules Established:** A customer can have multiple concurrent active subscriptions (e.g., an active voice call package running parallel to a data subscription bundle).

### 2. Physical Tuning: Partitioning vs. Warehouse Credit Burn
Victor illustrated how physical implementation choices directly control operational expense:
* **The Unpartitioned Query Trap:** Executing `SELECT * FROM transactions WHERE date = '2026-09-12'` against an unpartitioned table containing billions of rows forces the warehouse engine to perform a **full table scan**. The query runs for **30+ minutes**, burning valuable cloud compute credits.
* **Partition Pruning by Date:** By physically partitioning the storage blocks by calendar date (`PARTITION BY transaction_date`), the engine scans only the directory containing the requested date partition.
* **The Result:** Query execution drops from **30 minutes down to 1 minute**, preserving system resources and slashing compute costs.

---

## 🚚 Data Ingestion & Migration: Why CDC Beats Ad-Hoc Scripts

When **Chidinma Okeh** asked why a simple Python script cannot migrate data from PostgreSQL to Databricks/Snowflake, and **Raphael Affiah** proposed using read replicas:

### The Limitations of Custom Python Scripts at Scale
* A script issuing periodic `SELECT * FROM source` queries locks operational tables and consumes high database memory.
* If a Python job fails midway through a 500-million-row transfer, tracking state and resuming without creating duplicates is extremely difficult.
* Custom connectors struggle to handle schema evolution and high-throughput real-time changes.

### The Mechanics of Change Data Capture (CDC)
1. **Full Baseline Snapshot:** On initial setup, the CDC process captures an initial full-state image of the source tables.
2. **Write-Ahead Log (WAL) Monitoring:** Instead of querying the database engine directly, CDC reads the engine's internal transaction log (WAL in PostgreSQL).
3. **Event Streaming:** Row-level operations (`INSERT`, `UPDATE`, `DELETE`) are streamed as lightweight event payloads directly into intermediate cloud storage (e.g., Databricks Volumes) without querying operational tables or impacting application users.

---

## ❄️ Dimensional Modeling Schema Face-Off

Once data lands in the analytical environment, engineers must structure it into **Facts** (numerical measurements like revenue, quantity, call duration) and **Dimensions** (contextual attributes like subscriber name, location, bundle category).

```
   ┌───────────────────────┐   ┌───────────────────────┐   ┌───────────────────────┐
   │      STAR SCHEMA      │   │   SNOWFLAKE SCHEMA    │   │  ONE BIG TABLE (OBT)  │
   ├───────────────────────┤   ├───────────────────────┤   ├───────────────────────┤
   │ • Central fact table  │   │ • Dimensions broken   │   │ • No dimension tables │
   │ • Denormalized dims   │   │   into sub-dimensions │ • Entirely flattened  │
   │ • Simple joins        │   │ • Minimizes storage   │ • Zero table joins    │
   │ • Fast read queries   │   │ • Complex join trees  │ • High scan speed     │
   │ • Industry default    │   │ • Higher compute cost │ • Painful updates     │
   └───────────────────────┘   └───────────────────────┘   └───────────────────────┘
```

### Detailed Trade-Off Evaluation

#### 1. Star Schema (The Enterprise Standard)
* **Architecture:** A central quantitative `Fact_Transactions` table directly surrounded by flattened `Dim_User`, `Dim_Plan`, and `Dim_Location` tables.
* **Advantages:** Minimal table joins, fast aggregation performance, and highly intuitive for business analysts writing SQL.

#### 2. Snowflake Schema (The Normalized Alternative)
* **Architecture:** Dimension tables are normalized into sub-dimensions (e.g., `Location` splits into `Dim_City`, which references a distinct `Dim_Country` table).
* **The Deep Question:** **Osakpolor Ogieriakhi** asked: *"What is the advantage of Snowflake schema if it forces analysts to write multiple joins?"*
* **The Architectural Answer:** 
  1. It reduces data redundancy across dimensions with high-volume repetitive text.
  2. **Reverse ETL / External Boundaries:** If an enterprise needs to syndicate a clean, deduplicated list of operational cities to an external platform (e.g., syncing service areas into HubSpot for regional sales teams or providing isolated audit catalogs), keeping `Dim_City` as a clean, independent sub-dimension avoids exposing the broader `Dim_Location` structure.
* **Trade-Off:** Requires multi-level joins, triggering engine **data shuffle operations** that increase query execution times and warehouse credit burn.

#### 3. One Big Table (OBT - The Fully Denormalized Extreme)
* **Architecture:** Merges the central fact table and all dimension attributes into a single wide table containing dozens or hundreds of columns.
* **Advantages:** Completely eliminates SQL joins. Modern columnar engines (BigQuery, Snowflake) scan single wide tables rapidly.
* **Drawbacks:** Massively redundant storage footprint. Performing historical data updates or backfills requires rewriting massive partition files.

---

## 🎯 Next Steps & Study Directives

Before the cohort transitions into hands-on pipeline transformation using **dbt (data build tool)** on **Databricks**, the instructor assigned specific technical preparation:

1. **Storage Mechanics:** Research **Columnar (Parquet/ORC/Delta)** versus **Row-Oriented (PostgreSQL/MySQL)** storage engines to understand why columnar formats accelerate OLAP analytical aggregations.
2. **CDC Implementation Patterns:** Review how log-based replication mechanisms stream data into Databricks Volumes.
3. **Schema Practice:** Review the exported whiteboard diagrams, focusing on when to choose a Star Schema over a Snowflake Schema.
4. **Tooling Environment:** Set up Databricks community accounts ahead of the live dbt transformation module.


### **Summary**
The generated file `data_modeling_oltp_olap_masterclass.md` covers the entire masterclass in a structured, engaging format:

- **The Conceptual Framework:** Core principles of data modeling based on end-user workloads.
- **Workload Deep-Dive:** The "Two Andrews" operational vs. analytical case study and the "Single-Door Banquet Hall" metaphor for database resource contention.
- **Comparison Matrix:** Clear side-by-side analysis of OLTP vs. OLAP systems.
- **ERD & Cardinality:** $1:1$, $1:M$, $M:N$, and the "Fanta on the Shelf" conditional cardinality analogy.
- **Live System Design Walkthrough:** Step-by-step architecture of a telecom provider (MTN / Beejan Technologies) from early-stage single-database MVP to a scaled enterprise data platform.
- **Data Ingestion Analysis:** Detailed evaluation of custom Python scripts vs. Change Data Capture (CDC) and Write-Ahead Log (WAL) streaming.
- **Dimensional Modeling Face-Off:** Architectural and financial tradeoffs between Star Schema, Snowflake Schema (including Reverse ETL use-cases), and One Big Table (OBT).
- **Physical Tuning & Next Steps:** Partition pruning mechanics, cloud billing implications, and upcoming dbt on Databricks requirements.