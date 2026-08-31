# Architecture Review Board: End-to-End Customer Complaint Data Pipeline (Bijan Technologies)

**Meeting Date:** August 31, 2026 | **Duration:** 147 mins  
**Facilitator & Lead Instructor:** Najeeb Sulaiman  
**Product / Project Manager:** Josephine Adah  
**Presenting Lead Engineers:** AbdulRasaq Bilau, Temitope Asama, Lorreta Anyika, Ogungbemi Enitan  
**Session Format:** Peer Design Review Board (Product Manager $\rightarrow$ Lead Engineer Presentation $\rightarrow$ Stakeholder Cross-Examination & Critique)

---

## Executive Problem Statement: The Bijan Technologies Challenge
Every day, **thousands of customers complain** to Bijan Technologies (a simulated telecom operator) about poor network coverage, incorrect billing, and unsatisfactory customer service. These complaints arrive via disparate channels:
* **Social Media (X / Twitter / Facebook)**
* **Call Center Log Files**
* **SMS Messages**
* **Website Feedback Forms**

### Current Operational Pain Points:
1. **Manual Spreadsheets & Silos:** Reporting teams manually stitch data together in spreadsheets.
2. **Delayed Insights:** No automated unified data pipeline exists; reports arrive days late.
3. **Escalating Customer Churn & Bad PR:** High-severity outages and systemic billing glitches are not detected early enough to take action.

### Assignment Objective:
Design a **conceptual, end-to-end data pipeline blueprint** covering the entire Data Engineering Lifecycle (Source Identification $\rightarrow$ Ingestion $\rightarrow$ Storage $\rightarrow$ Transformation $\rightarrow$ Serving $\rightarrow$ Orchestration/Monitoring $\rightarrow$ DataOps).

---

## The Core Golden Rule: "It Depends" & Design Trade-offs
Throughout the session, Najeeb Sulaiman emphasized the overarching mindset separating junior coders from senior system architects:

> *"There is no single correct answer. Engineering is not about blindly picking tools like Airflow or Docker; it is about asking clarifying questions, understanding business requirements, mapping trade-offs, and intentionally designing for failure."*

* **Batch vs. Streaming Trade-off:** Streaming offers ultra-low latency but introduces high infrastructure complexity, rate-limit bottlenecks, and heavy cloud computing costs. Batch offers reliability and cost efficiency but sacrifices real-time responsiveness.
* **The "Default to Batch" Principle:** Always evaluate whether a batch or micro-batch architecture satisfies the business SLA first before paying the operational tax of 24/7 continuous stream processing.

---

## Summary of Student Architectural Proposals & Defense

```
+---------------------------------------------------------------------------------------------------------+
|                                    BIJAN TECHNOLOGIES DATA PIPELINE                                     |
+---------------------------------------------------------------------------------------------------------+
| SOURCES:        [ Social Media ]       [ Call Center Logs ]       [ SMS Messages ]       [ Web Forms ]  |
+------------------------┬-----------------------┬-------------------------┬----------------------┬--------+
                         │                       │                         │                      │
INGESTION:        (Streaming / Batch)     (Batch File Pull)         (Streaming/Webhooks)   (Batch / DB)   |
                         │                       │                         │                      │
STORAGE (Raw):           └───────────────────────┼─────────────────────────┴──────────────────────┘       |
                                                 ▼                                                        |
                                      [ Data Lake / S3 / ADLS ]  <-- (Schema-on-Read, Parquet/JSON)       |
                                                 │                                                        |
TRANSFORMATION:                [ Cleaning, Deduplication, PII Masking, NLP/Sentiment ]                   |
                                                 │                                                        |
STORAGE (Processed):                             ▼                                                        |
                                   [ Data Warehouse / OLAP DWH ] <-- (Medallion: Bronze/Silver/Gold)      |
                                                 │                                                        |
SERVING:                        ┌────────────────┴────────────────┐                                       |
                                ▼                                 ▼                                       |
                      [ BI & Executive Dashboards ]    [ Customer Support Ops ]                           |
                                                                                                          |
CROSS-CUTTING:   ════════════════════════════════════════════════════════════════════════════════════════ |
                 [ DataOps (CI/CD, Git) ]  &  [ Orchestration, Alerting & Quality Health Checks ]         |
+---------------------------------------------------------------------------------------------------------+
```

### 1. AbdulRasaq Bilau's Blueprint
* **Core Philosophy:** 100% Real-time Streaming ingestion across all 4 channels to instantly catch customer complaints and prevent revenue churn.
* **Storage & Processing:** Raw data lands in a Data Lake; transforms via ELT using NLP/ML to process voice/audio logs; serves data into OLAP storage for real-time querying.
* **Cross-Examination & Critique:**
  * *Stakeholder Critique (John Babatunde, Timothy Olaniyi):* Questioned why call center text logs and static web forms need expensive real-time streaming instead of scheduled batch file pulls.
  * *Architecture Critique (Najeeb Sulaiman):*
    1. **Undercurrents vs. Pipeline Stages:** DataOps and Monitoring are *continuous undercurrents* spanning every lifecycle phase—not isolated sequential stages at the end.
    2. **Premature ML:** Machine learning categorization shouldn't be executed on raw, unvalidated ingestion streams before basic data hygiene and transformation.
    3. **The Silent Source Failure Scenario:** *What happens if social media stops sending data for 6 hours?* The pipeline must not run blank compute tasks; it needs threshold alerting and contract checks at the source.

---

### 2. Temitope Asama's Blueprint
* **Core Philosophy:** Pragmatic batch-first architecture. Acknowledged Bijan Technologies' low infrastructure maturity.
* **Ingestion Strategy:**
  * **Social Media:** Scheduled batch pull via Third-Party APIs (prevents hitting API rate limits and controls budget).
  * **Call Logs & Web Forms:** Batch ingestion from files/spreadsheets.
  * **SMS:** Streaming / Push via Webhooks.
* **Transformation & Hygiene:** Schema validation, PII (Personally Identifiable Information) masking, deduplication, and NLP sentiment analysis to prioritize urgent network outage complaints over casual feedback.
* **Cross-Examination & Critique:**
  * *Stakeholder Critique (Oluwatosin Amosu):* Argued that batching social media every few hours creates unacceptable latency during severe network blackouts (e.g., when thousands of users tweet during a citywide outage).
  * *The Deduplication Trap (Najeeb's Key Lesson):* Temitope suggested automatically merging or dropping duplicate complaints submitted by the same user via both SMS and Web. Najeeb corrected: **Deduplication is a business decision, not a purely technical one.** A customer complaining on multiple channels signals extreme dissatisfaction (high churn risk); merging them silently destroys valuable business signal.

---

### 3. Lorreta Anyika's Blueprint
* **Core Philosophy:** Real-world telecom SLA-driven ingestion based on operator/vendor industry standards.
* **Ingestion Breakdown:**
  * **Social Media:** Streaming Push (1–10 minute SLA threshold alerting).
  * **Call Center Logs:** Scheduled Batch (daily log rollups).
  * **SMS:** Micro-batching (30-minute freshness targets).
* **Storage Tiers:** Ingestion into raw Data Lake landing zones $
ightarrow$ Curated Data Lake layers $
ightarrow$ Analytical Data Warehouse.

---

### 4. Ogungbemi Enitan's Blueprint
* **Core Philosophy:** Continuous 24/7 streaming for high-impact public channels (Social Media, Call Logs) to prevent overnight PR crises, combined with scheduled batching for SMS and Web Forms.
* **Resilience Mechanisms:** Confidence scoring on sentiment models (routing low-confidence text to human reviewers) and ingestion message queues/buffers to absorb high-volume outage traffic spikes.
* **Stakeholder Cross-Examination (David Shegun):** Challenged the fundamental business goal: *Is this pipeline built for live customer service ticketing, or for unified historical churn analytics?* Designing continuous streaming for historical BI reporting introduces unnecessary architectural cost.

---

## Deep-Dive Architecture Concepts & Masterclass Lessons

### 1. The Core Lifecycle Undercurrents
* **Monitoring & Alerting:** Not a downstream task. Involves verifying data contracts at the source, alerting on upstream schema drifts, monitoring null-rate spikes, and tracking data pipeline SLA latencies.
* **DataOps:** Encompasses CI/CD, Git version control, environment isolation (Dev / Staging / Production), and automated regression testing.

### 2. Physical Storage: Lake, Warehouse, or Lakehouse?
* **Data Lake (Schema-on-Read):** Necessary for landing raw, heterogeneous, semi-structured data (JSON, Parquet, text logs) without rigid upfront constraints.
* **Data Warehouse (Schema-on-Write):** Highly optimized, relational/columnar storage structured for aggregate business intelligence queries.
* **Medallion Pattern (Internal DWH Stages):**
  * **Bronze (Raw Layer):** Immutable landing tables holding exact copies of source data.
  * **Silver (Cleaned / Conformed Layer):** Deduplicated, validated, PII-masked, standardized tables.
  * **Gold (Business / Aggregated Layer):** Star-schema dimensional models and metric marts ready for BI tools.
* **Data Lakehouse:** Modern alternative unifying Data Lake object storage with transactional metadata layers (Delta Lake, Apache Iceberg), allowing direct high-performance SQL querying over raw files without duplicate physical storage.

---

## Designing for Failure: Senior Engineer Checklist
To build truly resilient production pipelines, engineers must ask **"What could go wrong?"** at every stage:
1. **Upstream Schema Drift:** What happens if the web form drops a column or renames a key in the JSON payload?
2. **Source Ingestion Outages:** What happens when an external API returns HTTP 429 (Rate Limited) or HTTP 500? Does the pipeline implement exponential backoff and dead-letter queues (DLQ)?
3. **Pipeline Idempotency:** If a scheduled pipeline crashes halfway and restarts, does it produce duplicate financial or complaint rows? (Pipelines must be strictly idempotent).
4. **Data Quality & Logic Drift:** What happens when a pipeline runs successfully (exit code 0), but the transformed row count drops by 90%? Automated data anomaly checks must catch silent failures.

---

## Key Student Inquiries & Clarifications
* **Q: Is there an absolute 'Model Answer' for this project?**
  * *A:* No. Every architectural choice maps back to the specific operational assumptions made. The goal is justifying trade-offs logically.
* **Q: Can we store raw Parquet files directly in a traditional relational database?**
  * *A:* No. Traditional RDBMS engines store structured rows/columns on managed disk pages. Object storage (Data Lake) lands Parquet files, which are then copied or ingested into relational warehouse tables.
* **Q: How should we reconcile different schemas across 4 source channels?**
  * *A:* Maintain raw source schemas independently in Bronze landing tables, extract a common business entity key (e.g., Customer ID, Phone Number, or Account Number), and map shared fields (Timestamp, Channel, Category, Cleaned Text) in the Silver layer.

---

## Key Takeaways & Professional Soft Skills
* **Stakeholder Management:** Engineering is 50% technical design and 50% communication. Influence stakeholder expectations by aligning SLAs with cost reality.
* **Clarity Before Code:** Always draft pseudocode, conceptual architecture blueprints, and data dictionaries before provisioning infrastructure or writing pipeline code.


### Key Summary Highlights from the Session
  
- **Core Problem Statement (Bijan Technologies Case Study):** Addressing massive daily customer complaints across 4 disparate channels (Social Media, Call Center Logs, SMS, and Web Forms) to eliminate manual spreadsheet silos and delayed reporting.
- **The Engineer Mindset & "It Depends":** Emphasized that engineering is about mapping trade-offs (Batch vs. Streaming, Cost vs. Latency) to business requirements rather than blindly picking tools.
- **Student Architectural Reviews:**

- **AbdulRasaq Bilau:** Proposed a 100% real-time streaming pipeline. Critiqued on premature ML application, undercurrents misplacement, and handling silent source downtime.
- **Temitope Asama:** Proposed a pragmatic batch-first pipeline using third-party APIs and PII masking. Prompted a core discussion on why deduplication across channels is a business decision rather than a purely technical one.
- **Lorreta Anyika:** Modeled SLA-driven telecommunication vendor ingestion strategies (1–10 min social media streaming vs. scheduled call log batching).
- **Ogungbemi Enitan:** Emphasized continuous streaming to prevent overnight PR crises and using message buffers to handle traffic spikes.
- **Architecture Deep Dives:**

- **Data Lake vs. Data Warehouse vs. Lakehouse:** Understanding Schema-on-Read landing vs. Medallion storage layers (Bronze $\rightarrow$ Silver $\rightarrow$ Gold).
- **Designing for Failure:** Planning for upstream schema drift, silent pipeline failures, and idempotency.