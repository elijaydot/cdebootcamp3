# Masterclass Summary: Foundations of Data Modeling & Database Normalization

**Instructor:** Okon Victor  
**Module:** Data Modeling for Data Engineers (Class 1 of 4)  
**Date:** September 9, 2026  
**Session Duration:** ~132 minutes  
**Focus:** Pragmatic Data Modeling, Conceptual vs. Logical vs. Physical Modeling, Business Entity Extraction, Tables vs. Views, OLTP (Write-Heavy) vs. OLAP (Read-Heavy), and the Mechanics of Normalization (1NF, 2NF, 3NF), Composite Keys, and Surrogate Keys.

---

## 1. Executive Overview: What Data Modeling Actually Is

The masterclass stepped away from dense academic abstractions to establish a practical baseline:

> *"Data modeling is the architectural blueprint of an enterprise system. Before you lay blocks to build a house, you design a blueprint defining what information is captured, how business entities connect, and where data physically lives."* — **Okon Victor**

### Why It Matters to Data Engineering
1. **Shared Business Taxonomy:** Bridges technical developers, database architects, and non-technical stakeholders under a single data contract.
2. **Cost & Query Optimization:** Eliminates query bottlenecks, redundant joins, and cloud warehouse spend upfront.
3. **Upstream to Downstream Clarity:** Traces operational business events from web apps directly into analytical dashboards.

---

## 2. The Three Progressive Phases of Data Modeling

Data modeling progresses through three structured abstraction layers:

```
[ 1. CONCEPTUAL PHASE ] ──► [ 2. LOGICAL PHASE ] ──► [ 3. PHYSICAL PHASE ]
High-Level Business Objects     Attributes, Relationships,     Data Types, Keys, Indexes,
(Entities & Domains)            Schemas & Cardinality          Storage Engines, Tables vs. Views
```

| Modeling Phase | Focus & Audience | Key Question Answered | Implementation Details |
| :--- | :--- | :--- | :--- |
| **1. Conceptual** | High-level business strategy (Stakeholders, Founders, Leads). | *What business entities do we need to track?* | Platform-agnostic entity identification (e.g., Customers, Orders, Products, Vendors). No technical constraints. |
| **2. Logical** | System architects & data engineers. | *What attributes define these entities and how do they connect?* | Attribute definition (e.g., `user_id`, `email`, `unit_price`), relationships (`1-to-Many`, `Many-to-Many`), cardinality, and business rules. |
| **3. Physical** | Database administrators & data warehouse engineers. | *How do we implement this schema in our chosen engine?* | Exact technical dialect (PostgreSQL, Snowflake, Databricks), column types (`VARCHAR`, `BIGINT`, `TIMESTAMP`), foreign key constraints, indexing, clustering, and partitioning. |

---

## 3. Interactive Workshop: Designing Jumia (E-Commerce Blueprint)

The class executed an end-to-end modeling exercise for an Amazon/Jumia e-commerce platform:

### Conceptual Entities Identified
* **`Customer`** (Buyers on the platform)
* **`Vendor`** (Sellers listing catalog items)
* **`Product`** (Items available for purchase)
* **`Order` / `OrderItem`** (Transactional records)
* **`Payment`** (Payment channels, gateways, and transaction references)
* **`Rider` / `Delivery`** (Fulfillment and dispatch tracking)
* **`Review`** (Ratings and feedback)

### Architectural Entity Design Rule
* **Entity vs. Column Decision Rule:** When asked if a customer review should be a column inside the `Customer` or `Product` table, the instructor clarified cardinality: *Because a single customer leaves reviews on multiple products, embedding reviews as columns creates bloated, unmanageable tables. A dedicated `Review` entity handles the 1-to-Many relationship cleanly.*

---

## 4. Physical Layer Deep-Dive: Tables vs. Views

Understanding when to persist data or compute on-the-fly directly impacts warehouse performance and cloud computing costs:

```
[ SELECT * FROM table_name ] ──► Fetches pre-computed rows directly from disk (Fast, storage cost).
[ SELECT * FROM view_name  ] ──► Re-executes the underlying SQL query on-the-fly (Slower, compute cost).
```

| Feature / Behavior | Physical Table (`CREATE TABLE`) | Virtual View (`CREATE VIEW`) |
| :--- | :--- | :--- |
| **Storage Footprint** | Persisted on disk; consumes physical bytes. | Virtual logic only; consumes near-zero storage. |
| **Query Performance** | **Fast reads:** Output is already pre-computed. | **Slower reads:** Recomputes joins, filters, and aggregations per execution. |
| **Freshness & Updates** | Requires scheduled ETL/ELT pipelines, full reloads, or incremental merges. | **Always real-time:** Instantly reflects underlying base-table mutations. |
| **Best Used For** | Large reporting tables, dimensional data marts, and frequent BI query models. | Lightweight security masking, access control, or modular SQL abstractions. |

---

## 5. Normalization vs. Denormalization: Trade-Offs & Operations

Data engineers balance two competing architectural styles depending on system consumption:

```
[ OLTP Application DB ] ──► (Normalized: 3NF)  ──► High-throughput WRITES / Low redundancy
          │
          ▼ (ETL / Ingestion Pipeline)
[ OLAP Data Warehouse ]  ──► (Denormalized)     ──► Fast Analytical READS / Pre-joined reporting
```

* **Normalization (Optimized for WRITES):**
  * Divides data into distinct, non-redundant tables linked by keys.
  * Ensures fast, atomic transactional mutations (`INSERT`, `UPDATE`, `DELETE`) without updating multiple rows across disparate locations.
* **Denormalization (Optimized for READS):**
  * Intentionally introduces controlled redundancy (e.g., embedding `product_name` directly into `order_items`).
  * Eliminates complex multi-table joins for business analysts, speeding up analytical aggregation queries.

---

## 6. Mastering Normal Forms: 1NF, 2NF, 3NF

The class examined progressive normalization mechanics with concrete database examples:

### First Normal Form (1NF): Atomic Values & No Repeating Groups
* **The Rule:** Each column must contain atomic (indivisible) values, no mixed data types in a single column, and no comma-separated lists.
* **Violation Example:**
  | order_id | customer | products |
  | :--- | :--- | :--- |
  | 101 | John | Pizza, Coke, Fries |
* **1NF Compliant Structure (Row Expansion):**
  | order_id | customer | product |
  | :--- | :--- | :--- |
  | 101 | John | Pizza |
  | 101 | John | Coke |
  | 101 | John | Fries |

---

### Second Normal Form (2NF): Full Functional Dependency (No Partial Dependencies)
* **The Rule:** Must first satisfy 1NF. Every non-key column must depend on the **entire** composite primary key, not just a subset of it.
* **Violation Example:**
  * **Composite Key:** `(order_id, product)`
  * **Columns:** `order_id`, `product`, `quantity`, `customer_name`
  * *Analysis:* `quantity` depends on both `(order_id, product)`. However, `customer_name` depends **only** on `order_id` (a partial dependency).
* **2NF Resolution (Table Decomposition):**
  1. **`Orders` Table:** `order_id` (PK), `customer_name`
  2. **`OrderItems` Table:** `order_id` (FK), `product` (FK), `quantity`

---

### Third Normal Form (3NF): No Transitive Dependencies
* **The Rule:** Must first satisfy 2NF. Non-key columns must not depend on other non-key columns (e.g., $A 
ightarrow B 
ightarrow C$). Non-key attributes must rely *strictly* on primary keys.
* **Violation Example:**
  | order_id (PK) | customer | city_id | city_name |
  | :--- | :--- | :--- | :--- |
  | 101 | John | 1 | Berlin |
  | 102 | Sarah | 2 | Paris |
  * *Analysis:* `city_name` depends on `city_id`, which in turn depends on `order_id`. `city_id` is not the table's primary key.
* **3NF Resolution (Decoupling Lookups):**
  1. **`Orders` Table:** `order_id` (PK), `customer`, `city_id` (FK)
  2. **`Cities` Table:** `city_id` (PK), `city_name`

---

## 7. Keys & Table Granularity: Composite vs. Surrogate Keys

Understanding table grain dictates pipeline idempotency and performance in transformation frameworks like dbt:

* **Table Grain:** The business meaning of an individual row. Answers: *What defines unique records in this table?*
* **Composite Key:**
  * A primary key formed by combining two or more existing business columns (e.g., `order_id + product_id`).
  * Does **not** add a new physical column to the database schema.
* **Surrogate Key:**
  * An artificial, system-generated identifier (e.g., an auto-incrementing integer `1, 2, 3...` or an MD5/SHA256 hash of concatenated natural keys: `MD5(order_id || '-' || product_id)`).
  * Exists as a physical column in the table definition.

---

## 8. Action Items & Roadmap for Saturday

1. **Self-Review:** Revisit 1NF, 2NF, and 3NF rules; practice decomposing unnormalized invoice schemas.
2. **Slack Channel Engagement:** Post remaining modeling questions directly in the technical Slack cohort channel for the instructor and TAs.
3. **Cohort Recap Accountability:** Silent attendees will be called on during Saturday's opening recap.
4. **Upcoming Module:** Dimensional Modeling, Star Schema, Snowflake Schema, Fact vs. Dimension Tables, and Slowly Changing Dimensions (SCD).

## Summary NOtes
### 1. Executive Overview: What Data Modeling Truly Is

- **Beyond Theory:** The instructor challenged attendees to abandon rigid textbook memorization.
- **The Architectural Blueprint:** Data modeling serves as the structural blueprint of an enterprise system. Just as an architect drafts building blueprints before masonry begins, a data model dictates what information is collected, how entities relate, and where records are physically stored.
- **Business & Financial Impact:** Proper data models align technical developers with non-technical stakeholders, optimize database storage, and eliminate costly computational bottlenecks in cloud data warehouses.

### 2. The Three Progressive Phases of Data Modeling
The session walked through the three distinct abstraction layers of system design:  

1. **Conceptual Phase (High-Level Domain Discovery):**

- Answers: *What core business concepts must be tracked?*
- Involves high-level stakeholders identifying business entities without technical jargon or database constraints.
2. **Logical Phase (Schema & Entity Relationships):**

- Answers: *What attributes belong to each entity, and how do they interconnect?*
- Defines fields (e.g., `user_id`, `email`, `address`), primary identifiers, relationships (`1-to-Many`, `Many-to-Many`), and cardinality rules.
3. **Physical Phase (Storage Implementation & Dialect):**

- Answers: *How is this realized inside our specific database engine?*
- Configures concrete data types (`VARCHAR`, `TIMESTAMP`), foreign key constraints, indexes, storage allocation, partitioning, and table vs. view materialization.

### 3. Interactive Workshop: Modeling Jumia (E-Commerce Case Study)
The cohort stepped into the shoes of e-commerce platform co-founders to map out data entities:  

- **Discovered Entities:** Customers, Vendors, Products, Orders, Payments, Riders/Deliveries, and Reviews.
- **Separating Users:** Decided to split the base user entity into distinct `Customer` and `Vendor` tables to maintain clean business logic and distinct verification requirements.
- **The Entity vs. Column Decision Rule:**

- *Question:* Should customer reviews be a column inside the Customer or Product table?
- *Resolution:* Because a single customer leaves reviews on multiple products, stuffing reviews into the customer entity creates bloated, non-scalable rows. Establishing a separate `Review` table handles the 1-to-Many relationship cleanly.

4. Physical Layer Mechanics: Tables vs. ViewsThe instructor clarified the computational trade-offs between persisting tables and evaluating views:  Physical Tables (CREATE TABLE):Persist raw query results on physical disk.  Trade-off: Faster query performance for downstream consumers, but requires scheduled pipelines, full reloads, or incremental merges to maintain data freshness.  Virtual Views (CREATE VIEW):Do not store pre-computed records; instead, they re-execute the underlying SQL logic on-the-fly every time they are queried.  Trade-off: Always reflects the latest upstream updates without refresh pipelines, but incurs heavy computing resources on multi-join logic

### 5. Architectural Paradigms: Normalization vs. Denormalization

- **Normalization (OLTP / Write-Heavy):**

- Splits entities into distinct, non-redundant relational tables linked by keys.
- Eliminates update anomalies and optimizes high-frequency `INSERT`, `UPDATE`, and `DELETE` transactional operations in customer-facing apps.
- **Denormalization (OLAP / Read-Heavy):**
- Intentionally introduces controlled redundancy (e.g., adding `product_name` directly into transactional line items).
- Eliminates complex multi-table joins for business analysts, optimizing queries for high-speed analytical reads and BI dashboards.

### 6. Normalization Deep-Dive: 1NF, 2NF, and 3NF

#### First Normal Form (1NF): Atomicity & No Repeating Groups

- **The Rule:** Each column must hold indivisible, atomic values, contain uniform data types, and avoid comma-separated lists.
- **The Fix:** Unpack arrays and multi-item rows into individual record rows with consistent scalar values.

#### Second Normal Form (2NF): No Partial Dependencies

- **The Rule:** Must satisfy 1NF, and every non-key column must depend on the **entire** composite primary key, rather than a partial subset.
- **The Problem:** In a table with composite key `(order_id, product_id)`, the `quantity` depends on both keys, but `customer_name` depends solely on `order_id`.
- **The Fix:** Decompose into two tables: an `Orders` table (`order_id`, `customer_name`) and an `OrderItems` table (`order_id`, `product_id`, `quantity`).

#### Third Normal Form (3NF): No Transitive Dependencies

- **The Rule:** Must satisfy 2NF, and no non-key attribute can depend on another non-key attribute ($A \rightarrow B \rightarrow C$). Non-key columns must depend strictly on the primary key.
- **The Problem:** Having `order_id` (PK), `city_id`, and `city_name` in one table creates a transitive dependency because `city_name` depends directly on `city_id`.
- **The Fix:** Separate lookups into an independent `Cities` reference table (`city_id`, `city_name`), keeping only foreign key `city_id` on the order record.

### 7. Table Grain & Keys: Composite vs. Surrogate

- **Table Grain:** The fundamental uniqueness and level of detail captured by a single row. Understanding grain is essential for configuring incremental builds and merge strategies in tools like dbt.
- **Composite Key:** A primary identifier created by combining two or more existing business columns (e.g., `order_id + product_id`) without generating a new physical column.
- **Surrogate Key:** An artificial, system-generated identifier (e.g., an auto-incrementing integer or an MD5/SHA-256 hash of natural key columns) stored as a dedicated physical column in the table schema.

### 8. Next Steps & Saturday Roadmap

- Practice applying 1NF, 2NF, and 3NF rules to real-world operational datasets.
- Post lingering modeling questions directly to the technical Slack cohort channel.
- **Upcoming Saturday Class:** Dimensional Modeling, Star Schema, Snowflake Schema, Fact vs. Dimension Tables, and Slowly Changing Dimensions (SCD).