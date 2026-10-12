# Advanced Data Ingestion: Airbyte Sync Modes, Custom Connector Builder & Production Warehousing

*A Unified Masterclass Summary on Ingestion Strategies, API Pagination, and Lakehouse Integration*

**Lead Instructor:** Ahmed Oladapo ("DataGuy")  
**Session Date:** October 10, 2026 | **Combined Duration:** 78 Minutes  

---

## Executive Summary

In this capstone ingestion session, **Ahmed Oladapo ("DataGuy")** bridges high-level data warehousing design and real-world pipeline execution. Expanding beyond standard UI point-and-click connections, Ahmed dissects:

* **The Economics of Sync Modes:** The cost, performance, and compute differences between **Full Refresh (Overwrite, Append)** and **Incremental Sync (Append, Append + Deduped)**.
* **Architecture-First Thinking:** Why real-world data volume ($6.9\text{ million records/sec}$ at Uber-scale) renders naive scripts and micro-services useless and forces custom engineering.
* **Production Safety & POC Environments:** Why production databases should never be used as test sandboxes, and how to programmatically mock high-cardinality test datasets.
* **Hands-on Airbyte Connector Builder:** Building low-code API connectors from scratch against REST endpoints (the *Rick and Morty API*), configuring multiple streams, handling JSON records, handling schema evolution, and managing pagination.
* **JSON Document Storage vs. Flattening:** The trade-offs between landing semi-structured payloads as raw variant/struct blobs versus auto-flattening into rigid relational columns.

---

## 1. The Economics of Sync Strategies: Full Refresh vs. Incremental

Ahmed grounded the session in cloud infrastructure economics. When pipelines ingest millions of records daily, choosing the wrong sync mode wastes thousands of dollars in warehouse compute credits.

```
SCENARIO: 300 Million Records Ingested Weekly (Cost: $100 per Full Run)

Mode A: Full Refresh (Every Day, Mon-Fri)
Mon: 300M rows ($100) ──> Tue: 300M rows ($100) ──> Wed: 300M rows ($100) ──> Thu: 300M rows ($100) ──> Fri: 300M rows ($100)
Total Weekly Spend: $500 (Even if zero rows changed!) 💸

Mode B: Incremental Sync (Delta-Based Tracking)
Mon: 300M Initial ($100) ──> Tue: 0 changes ($0) ──> Wed: 0 changes ($0) ──> Thu: 0 changes ($0) ──> Fri: 20K changes ($20)
Total Weekly Spend: $120 (Saves $380 / 76% per week!) 🚀
```

### The Ingestion Strategy Matrix

| Sync Mode | Source Behavior | Destination Behavior | State / Cursor Requirement | Ideal Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Full Refresh - Overwrite** | Reads entire source table. | **Truncates** target table and rewrites current snapshot. | None | Small dimensions, static lookup tables ($< 100\text{k}$ rows). |
| **Full Refresh - Append** | Reads entire source table. | Appends full snapshot to existing data without truncating. | None | Periodic auditing where point-in-time full snapshots are preserved. |
| **Incremental - Append** | Reads records where cursor $>$ previous watermark. | Appends new/modified records as fresh rows. | Requires cursor column (e.g., `updated_at`, `created_at`). | Immutable event streams, logs, clickstreams, audit logs. |
| **Incremental - Append + Deduped** | Reads records where cursor $>$ previous watermark. | Appends deltas and **deduplicates** by Primary Key (latest cursor wins). | Requires Cursor **and** Primary Key. | Mutable entities (Users, Accounts, Subscriptions) needing current state. |

> ⚠️ **The Initial Run Rule:** Even in incremental modes, **Run 1 is always a Full Refresh**. The ingestion engine must establish the base state and record the initial cursor timestamp before it can track deltas.

---

## 2. High-Throughput Engineering: When Pipelines Break Scale

Ahmed challenged junior engineers who attempt to solve enterprise performance bottlenecks by converting database tables into views or using serverless functions:

### The Uber Scale Benchmark
* **The Reality:** Platforms like Uber ingest over **$7.7\text{ Petabytes}$ of data per day** ($\approx 6.9\text{ million records per second}$).
* **The Serverless Trap:** Firing an **AWS Lambda** function or running basic Python scripts against 7+ petabytes of streaming data will immediately fail due to memory limits, timeout thresholds (15 minutes on Lambda), and socket saturation.
* **The Enterprise Architectural Stack:** High-throughput streaming requires purpose-built distributed systems:
  * **Apache Kafka / Kafka Connect:** Decoupled distributed message ingestion and buffer management.
  * **Tiered Storage (e.g., KIP-405 in Kafka / Apache Hudi):** Decoupling log segment storage into hot and cold tiers.
  * **Apache Spark / Flink on Kubernetes:** Distributed real-time stream processing and compute scaling.

### Treating the Cause vs. Treating the Symptoms

$$\text{"Leaving Leprosy to Treat Ringworm"}$$

Ahmed warned against surface-level fixes when pipelines slow down:
* Converting heavy tables into **SQL Views** does not solve performance issues. Views recompute the underlying query on every execution, increasing warehouse query loads.
* When pipelines lag, evaluate the underlying infrastructure: cluster sizing, partitioning, micro-batching, and network routing, rather than rewriting cosmetic SQL queries.

---

## 3. Production Safety: Proof of Concept (POC) & Synthetic Data

A recurring operational danger is developers testing new ingestion connectors or incremental logic directly against production databases.

```
  DANGEROUS ANTI-PATTERN: Testing on Production
  [ Production App Database ] ── Pipeline Test / Bug ──> Corrupted Balances & Deleted Rows ──> 🚨 Executive Crisis!

  BEST PRACTICE: Synthetic Isolation
  [ Source Data Schema ] ── Prompt/Faker Engine ──> [ Mock DB: 10M Synthetic Rows ] ── Stress Test ──> [ Verified Pipeline ]
```

### Mocking Data for Resilient Testing:
1. **Never test untested sync modes on live production OLTP tables.** An unindexed query or an accidental write lock can freeze user transactions.
2. **Generate Synthetic Datasets:** Use Python libraries (`Faker`, `mimesis`) or AI prompts to generate $10\text{M} - 50\text{M}$ synthetic rows matching your production schema.
3. **Run Load & Stress Tests:** Verify how your destination warehouse handles bulk `MERGE` and deduping performance under heavy volume before touching real user data.

---

## 4. Building Custom API Connectors: Hands-on Airbyte Builder

Many business sources do not have native database drivers. Third-party SaaS providers, CRM tools, and partner feeds expose data via REST APIs. Ahmed demonstrated how to build a production-grade connector using **Airbyte's Low-Code Connector Builder** against the *Rick and Morty REST API*.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   AIRBYTE LOW-CODE CONNECTOR BUILDER                   │
│                                                                        │
│   Stream 1: 'episodes'  ─── URL: /api/episode   ─── Selector: results  │
│   Stream 2: 'characters' ─── URL: /api/character ─── Selector: results │
│                                                                        │
│   Pagination: Page-based / Cursor-based (Jinja: {{ response.info.next }})
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼ Export YAML Manifest
                         [ episodes.yaml ]
                                   │
                                   ▼ Deploy to Airbyte Engine
                    [ Multi-Stream Ingestion Pipeline ]
```

### Step 1: Defining the API Base & Endpoints
* **Base URL:** `https://rickandmortyapi.com/api`
* **Stream 1 (Episodes):** Endpoint path `/episode`, Method `GET`.
* **Stream 2 (Characters):** Endpoint path `/character`, Method `GET`.

### Step 2: Record Extraction (Record Selector)
REST APIs wrap responses in metadata objects:
```json
{
  "info": {
    "count": 51,
    "pages": 3,
    "next": "https://rickandmortyapi.com/api/episode?page=2",
    "prev": null
  },
  "results": [
    {
      "id": 1,
      "name": "Pilot",
      "air_date": "December 2, 2013",
      "episode": "S01E01"
    }
  ]
}
```
* **Setting the Record Selector:** Setting the selector to `results` instructs Airbyte to extract the nested array into individual stream rows.
* Leaving the record selector blank causes Airbyte to ingest the entire root JSON response (metadata + array) as a single row.

### Step 3: Handling API Pagination
APIs partition large datasets into discrete pages to protect server memory. Airbyte's Builder supports:
* **Page-based Pagination:** Increments a query parameter (`page={{ next_page_token }}`) starting at `1`.
* **Cursor-based (Next URL) Pagination:** Uses Jinja templating to read the next URL path directly from the response envelope (`{{ response.info.next }}`). Ingestion continues until the field evaluates to `null`.

### Step 4: Exporting and Sharing Connector Manifests (`YAML`)
Airbyte connectors are defined as declarative YAML manifests.
* Connectors can be exported directly as YAML files (e.g., `episodes.yaml`).
* This enables team collaboration: developers can build a connector locally, push the YAML manifest to Git, and import it into production Airbyte instances without manual reconfiguration.

---

## 5. Semi-Structured Storage: Raw JSON Blobs vs. Relational Flattening

Ahmed explored the architectural debate: **Should ingestion engines auto-flatten JSON payloads into columns, or land them as raw variant/struct blobs?**

```
Approach 1: Semi-Structured Raw Variant Ingestion
Table: raw_episodes
┌────┬──────────────────────────────────────────────────────────────┐
│ ID │ results (VARIANT / JSON Blob)                                │
├────┼──────────────────────────────────────────────────────────────┤
│ 1  │ {"id": 1, "name": "Pilot", "air_date": "Dec 2, 2013", ...}   │
└────┴──────────────────────────────────────────────────────────────┘

Approach 2: Relational Flattened Ingestion
Table: flattened_episodes
┌────┬─────────┬──────────────┬──────────┐
│ id │ name    │ air_date     │ episode  │
├────┼─────────┼──────────────┼──────────┤
│ 1  │ Pilot   │ Dec 2, 2013  │ S01E01   │
└────┴─────────┴──────────────┴──────────┘
```

### Trade-Off Comparison

| Metric / Scenario | Raw Semi-Structured Blob (Variant) | Pre-Flattened Relational Columns |
| :--- | :--- | :--- |
| **Schema Evolution** | **Resilient.** Upstream API adding new fields does not break downstream ingestion. | **Brittle.** New or altered fields cause schema mismatch errors. |
| **Ingestion Complexity** | Minimal. The engine extracts the root payload directly. | High. Requires nested schema mappings and data type casts. |
| **Query Ergonomics** | Requires JSON path extractions (`:` or `LATERAL FLATTEN`). | Clean, standard SQL `SELECT column_name`. |
| **Best Practice Location** | **Landing / Raw / Bronze Layer** | **Conformed / Silver / Gold Layer** |

### Parsing Semi-Structured Data in Snowflake SQL
When data lands as a raw JSON blob, downstream dbt models flatten the fields into typed relational structures:

```sql
-- Flattening JSON Variant Columns in Snowflake
SELECT
    raw_payload:id::INT AS episode_id,
    raw_payload:name::STRING AS episode_name,
    raw_payload:air_date::STRING AS air_date,
    raw_payload:episode::STRING AS season_episode_code,
    CURRENT_TIMESTAMP() AS transformed_at
FROM cde_warehouse.raw.raw_episodes_unflattened;
```

* In Databricks, dot notation is used: `SELECT raw_payload.id, raw_payload.name FROM ...`
* In BigQuery, `JSON_EXTRACT_SCALAR()` is used.

---

## 6. Interactive Q&A & Technical Deep-Dive Register

| Student / Participant | Topic / Question | Technical Answer & Engineering Rule |
| :--- | :--- | :--- |
| **Efeoghene Oghenechovwen** | *"Can Airbyte move data backward from Snowflake back into operational applications (Reverse ETL)?"* | While Airbyte can read from Snowflake as a source, pushing computed scores back into operational apps or frontends is best handled by dedicated **Reverse ETL tools** (e.g., Census, Hightouch) or purpose-built internal microservice APIs. |
| **Ose Benson** | *"My company is hitting performance issues. Should I rewrite tables into SQL views?"* | **No.** Converting complex tables into views shifts computation from write-time to read-time, worsening query latency. Address root causes instead: cluster sizing, partitioning, micro-batching, and moving heavy workloads to distributed frameworks like Apache Spark. |
| **Osakpolor Ogieriakhi** | *"Does Incremental Append + Deduped delete records from the source database?"* | **Never.** Ingestion engines only possess read permissions on source databases. Deduplication happens entirely within the destination warehouse landing tables using the declared Primary Key and cursor. |
| **Godwin Nosa** | *"Why send unflattened JSON to Snowflake instead of flattening immediately in Airbyte?"* | Landing raw JSON preserves the complete payload as an audit log. If upstream APIs introduce unexpected fields, the raw data is retained without breaking schemas, allowing downstream dbt models to handle extraction cleanly. |
| **Roqeeb Olaniran** | *"How do we handle multiple endpoints from the same API in Airbyte?"* | Create multiple **Streams** within the same connector builder (e.g., Stream 1: `/episode`, Stream 2: `/character`). Airbyte replicates each stream into its own separate destination table. |

---

## 7. Actionable Key Takeaways for Data Engineers

1. **Focus on Outcomes Over Syntax:** Businesses reward system reliability, cost efficiency, and uptime—not raw lines of code or complex toolchains.
2. **Prioritize Incremental Syncs:** As data scales past millions of records, transition from Full Refresh to incremental replication to control cloud warehouse costs.
3. **Isolate Sandbox Environments:** Never test connector behavior or schema changes on live production systems. Use synthetic data generators to run load and regression tests.
4. **Preserve Raw Payloads:** When handling third-party REST APIs, consider landing raw JSON objects in the Bronze/Raw layer to safeguard against breaking upstream schema changes.