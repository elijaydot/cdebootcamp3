# Demystifying Data Orchestration: From Jollof Rice to Apache Airflow

*A Deep-Dive Summary of the Airflow Module Kickoff with Najeeb Sulaiman*

**Lead Instructor:** Najeeb Sulaiman  
**Teaching Assistants:** Nancy Amandi, Charles Edeki, Leo Osigbemhe  
**Session Date:** October 19, 2026 | **Duration:** 126 Minutes  

---

## Executive Overview

In this module kickoff, **Najeeb Sulaiman** introduced the central nervous system of data engineering: **Workflow Orchestration**. Rejecting the idea of teaching tools as isolated syntax, Najeeb anchored the curriculum in foundational first principles:

> *"Our goal is not for you to simply 'know Airflow.' Our goal is for you to understand **workflow orchestration** conceptually, using Airflow merely as our vehicle of implementation."*

Through two intuitive analogies—**Cooking a Massive Pot of Nigerian Jollof Rice** and the **Human Digestive System**—alongside the operational struggles of fictional startup **CDE Bites**, the class traced the technical evolution that led to modern workflow orchestrators like **Apache Airflow**, **Prefect**, and **Dagster**.

---

## 1. The Real-World Mental Model: Orchestrating Jollof Rice

To strip away intimidation, Najeeb asked: *What does it actually mean to orchestrate?*

Cooking a world-record pot of Nigerian Jollof Rice requires specific, coordinated steps:

```
[ Wash Rice ] ──> [ Boil Protein ] ──> [ Fry Pepper Mix ] ──> [ Separate Stock ] 
       │
       └───> [ Combine Stock & Pepper Mix ] ──> [ Add Spices ] ──> [ Pour Rice ] ──> [ Wait to Cook ]
```

### The 5 Pillars of Orchestration

Every orchestration system in computer science answers five core operational questions:

```
┌────────────────────────────────────────────────────────────────────────┐
│                      THE 5 PILLARS OF ORCHESTRATION                    │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Task (WHAT):        The discrete unit of execution (e.g., wash      │
│                        rice, fry pepper mix).                          │
│ 2. Dependency (ORDER): The directed flow of execution (cannot cook     │
│                        the rice before preparing the stock).           │
│ 3. Schedule (WHEN):    The precise temporal trigger (start at 7:00 AM) │
│ 4. Monitoring (STATE): Live visibility into health (is it burning,     │
│                        is there too much salt, did a burner fail?).   │
│ 5. Recovery (RETRY):   The strategy when failure strikes (can we       │
│                        resume from where it failed, or must we start   │
│                        completely from scratch?).                      │
└────────────────────────────────────────────────────────────────────────┘
```

### The Biological Counterpart: The Digestive System
Orchestration is a universal law of nature:
$$\text{Eat (Schedule)} \longrightarrow \text{Mouth (Ingest)} \longrightarrow \text{Teeth (Masticate)} \longrightarrow \text{Stomach (Deconstruct)} \longrightarrow \text{Intestines (Absorb)} \longrightarrow \text{Excrete}$$
If your stomach attempts to digest before you swallow, the pipeline crashes. Each step is interdependent, ordered, and governed by biological triggers.

---

## 2. The Case of CDE Bites: The Evolution of Pipeline Failure

To understand why custom scripts and cron fail at scale, Najeeb introduced the operational dilemma of **CDE Bites** (a food delivery startup):

* **Amara (Founder / Ops Lead):** Requires an operational executive report delivered to her phone via Slack **every morning at 8:00 AM** showing yesterday's order volume, top products, top customers, and gross revenue.
* **Dele (The "All-Rounder" Engineer):** The solo engineer tasked with pulling data from raw Google Sheets/CSVs, loading it into a warehouse, transforming metrics, and dispatching the notification.

---

### Stage 0: The Brute-Force Manual Approach

Dele wrote four clean Python scripts:
1. `extract.py`: Reads the raw orders spreadsheet and saves a raw CSV into a local folder (`/data`).
2. `load.py`: Reads the raw CSV and writes rows into an SQLite/PostgreSQL table (`raw_orders`).
3. `transform.py`: Casts timestamps, deduplicates rows, and computes clean sales metrics (`transformed_orders`).
4. `notify.py`: Aggregates KPIs, generates a Slack payload, and writes out `report.txt`.

#### The Workflow:
Every single morning at **7:30 AM**, Dele wakes up, opens his terminal, and manually types:
```bash
python extract.py
python load.py
python transform.py
python notify.py
```

```
                          STAGE 0: MANUAL TERMINAL EXECUTION
   Dele Wakes Up ──> [ python extract.py ] ──> [ python load.py ] ──> [ python transform.py ] ──> [ python notify.py ]
   (7:30 AM Daily)
```

#### What Broke? (The Bottlenecks)
* **Single Point of Failure (SPOF):** Dele is the orchestrator. If Dele oversleeps, falls ill, or goes on annual leave (PTO), Amara gets no report.
* **Knowledge Silo:** The sequence of execution lives entirely in Dele's head. A newly hired engineer cannot deduce the dependencies without manual documentation.
* **Workstation Fragility:** If Dele’s personal laptop runs out of battery, experiences a power surge, or hits a local network glitch, the business pipeline halts.

---

### Stage 1: The Monolithic Master Script

Dele realized manual execution was inefficient. He wrapped all four functions into a single script: `run_pipeline.py`.

```python
# run_pipeline.py
from extract import extract_data
from load import load_data
from transform import transform_data
from notify import send_notification

def main():
    extract_data()
    load_data()
    transform_data()
    send_notification()

if __name__ == "__main__":
    main()
```

Now, Dele only executes one command at 7:30 AM:
```bash
python run_pipeline.py
```

#### What Broke?
* **Zero Granular Retries:** If `extract()` and `load()` process 100 million rows successfully over 45 minutes, but `transform()` throws a division-by-zero or network glitch:
  * **The entire script crashes.**
  * After fixing the bug, Dele must **re-extract and re-load all 100 million rows from the beginning**, blowing compute budgets and missing the 8:00 AM SLA.
* **No Automatic Failure Recovery:** If a temporary network timeout drops the connection, there is no automatic retry backoff.
* **Still Manual:** Dele still has to trigger the master script manually.

---

### Stage 2: Scheduling with Cron

Dele automated the trigger using Linux's built-in scheduler (`crontab`).

To avoid running everything in one monolithic script, he scheduled the discrete jobs across staggered time windows:
```cron
# Dele's Crontab Configuration
30 7 * * * /usr/bin/python3 /scripts/extract.py
35 7 * * * /usr/bin/python3 /scripts/load.py
40 7 * * * /usr/bin/python3 /scripts/transform.py
50 7 * * * /usr/bin/python3 /scripts/notify.py
```

```
                                  STAGE 2: CRON TIME-STAGGERING
  7:30 AM                     7:35 AM                     7:40 AM                     7:50 AM
┌─────────────┐             ┌─────────────┐             ┌─────────────┐             ┌─────────────┐
│ extract.py  │             │   load.py   │             │transform.py │             │  notify.py  │
└─────────────┘             └─────────────┘             └─────────────┘             └─────────────┘
  (Blind timer: Has extract finished? Cron doesn't know and doesn't care!)
```

#### What Broke? (The Overlap Disaster)
* **Cron is State-Blind:** Cron only understands **wall-clock time**, not task completion status. It fires blindly regardless of whether the previous step succeeded, failed, or is still running.
* **The Overlapping Cascade:**
  * Suppose an upstream marketing campaign drives massive traffic, causing `extract.py` to take 12 minutes instead of 4.
  * At 7:35 AM, Cron blindly launches `load.py`.
  * `load.py` reads a partially written, corrupted CSV file, dumping incomplete rows into the warehouse.
  * At 7:40 AM, `transform.py` calculates erroneous KPIs based on partial data.
  * At 7:50 AM, Amara receives a faulty revenue report.
* **Silent Failures:** If `extract.py` fails silently, no notification is fired. `load.py` runs on empty data, and the pipeline delivers an empty report without anyone realizing a crash occurred.

---

### Stage 3: The Custom In-House Framework

Determined to fix state-blindness, Dele spent weeks writing a custom Python orchestration framework featuring `try/except` blocks, custom polling loops, custom SQLite metadata tracking, and Slack webhook alerts.

```
┌─────────────────────────────────────────────────────────────┐
│                 DELE'S CUSTOM ORCHESTRATION ENGINE          │
│  • Custom State Tracking & Dependency Engine               │
│  • Custom Retry Backoff Logic & Slack Webhooks             │
│  • Custom CLI / Web Viewer                                 │
└─────────────────────────────────────────────────────────────┘
```

#### Why Custom In-House Orchestrators Fail:
1. **Total Cost of Ownership (TCO):** Engineering cost is not just cloud hosting bills. If Dele spends 15 hours a week debugging his custom engine instead of delivering data features, the business loses money.
2. **Onboarding Friction:** When CDE Bites hires Engineer #2, that engineer must spend weeks deciphering Dele's custom framework instead of using industry-standard tooling.
3. **No Community Ecosystem:** Dele must personally write and maintain connectors for every new database, warehouse, and API the company adopts.
4. **Lack of Advanced Features:** Implementing dynamic backfills, cross-DAG dependencies, concurrency limits, and distributed workers from scratch is complex and error-prone.

---

## 3. The Orchestration Tooling Landscape

The limitations Dele faced mirror the challenges that tech giants encountered in the early 2010s, giving rise to modern open-source orchestrators:

```
┌────────────────────────┬───────────────────┬───────────────────────────────────────────────┐
│ Tool                   │ Originating Team  │ Defining Characteristics                     │
├────────────────────────┼───────────────────┼───────────────────────────────────────────────┤
│ **Luigi**              │ Spotify (2012)    │ Early Python pipeline tool; lacked an         │
│                        │                   │ internal cron-like scheduler.                 │
├────────────────────────┼───────────────────┼───────────────────────────────────────────────┤
│ **Apache Airflow**     │ Airbnb (2014)     │ The global industry standard. Workflows-as-   │
│                        │                   │ code in Python, extensive operator ecosystem. │
├────────────────────────┼───────────────────┼───────────────────────────────────────────────┤
│ **Prefect**            │ Prefect Technologies│ Modern, dynamic, Python-native engine       │
│                        │                   │ treating workflows as standard code blocks.   │
├────────────────────────┼───────────────────┼───────────────────────────────────────────────┤
│ **Dagster**            │ Elementl          │ Asset-based orchestration focusing on data    │
│                        │                   │ assets and lineage rather than bare tasks.    │
├────────────────────────┼───────────────────┼───────────────────────────────────────────────┤
│ **AWS Step Functions** │ Amazon Web Services│ Proprietary JSON/YAML state-machine          │
│                        │                   │ orchestration optimized for AWS serverless.   │
└────────────────────────┴───────────────────┴───────────────────────────────────────────────┘
```

### Why Apache Airflow Dominates Enterprise Data
* **Workflows as Code:** DAGs (Directed Acyclic Graphs) are declared entirely in standard Python, allowing full Git version control, continuous integration testing (CI/CD), PR reviews, and team collaboration.
* **Rich Extensibility:** Supported by thousands of pre-built community providers and operators (Databricks, Snowflake, dbt, Airbyte, AWS, GCP, Slack).
* **Backfilling & Catchup:** Airflow natively tracks execution dates, allowing engineers to rerun failed historic pipeline runs across specific date ranges with a single command.
* **Massive Community & Market Demand:** Roughly 8 out of 10 enterprise data engineering job descriptions explicitly demand Airflow experience.
* **Managed Ecosystems:** Supported across major clouds via managed offerings (Astronomer, AWS MWAA, Google Cloud Composer).

---

## 4. Critical Boundaries: Airflow vs. Airbyte

A common question addressed in class: *If Airbyte has a built-in scheduler, why do we need Airflow?*

```
   DATA LIFECYCLE COORDINATION
   
   [ Airflow DAG Orchestrator ]
         │
         ├── Step 1: Trigger Airbyte Ingestion Job ──> [ Airbyte Engine Moves Raw DB to Snowflake ]
         │           (Wait for success verification...)
         │
         ├── Step 2: Trigger dbt Cloud / dbt Core  ──> [ Transform Raw Bronze into Clean Gold ]
         │           (Wait for data tests to pass...)
         │
         └── Step 3: Trigger Slack / PagerDuty     ──> [ Notify Analytics Team of Fresh Marts ]
```

* **Airbyte** is a specialized **data ingestion engine**. It extracts data from point A and lands it raw at point B.
* **Airflow** is the **end-to-end coordinator**. It tells Airbyte *when* to extract, waits for extraction to finish, triggers dbt to transform the landed data, fires Great Expectations to test data quality, and alerts stakeholders if an error occurs.

---

## 5. Engineering Wisdom & Golden Principles

Throughout the session, Najeeb emphasized key engineering mindsets:

1. **"Problems in Engineering Never End—And That's Good":**
   * Every architectural solution introduces new operational challenges. Solving pipeline failures with automation creates maintenance overhead.
   * *Job security exists precisely because systems scale, schemas evolve, and pipelines break.*
2. **Think Holistically, Not Narrowly:**
   * Junior engineers patch only the immediate error in front of them (e.g., adding an alert).
   * Senior engineers evaluate the downstream effects: *Does adding this alert spam stakeholders 50 times during a loop failure? Does this fix preserve data idempotency?*
3. **Never Build What You Can Adopt:**
   * Writing a custom in-house framework feels productive, but building and maintaining bespoke tools steals time from delivering core business value.

---

## Action Items & Next Steps

* [ ] **Verify Airflow Environment:** Confirm your local Airflow instance is running and accessible via the webserver UI (default: `localhost:8080`), whether deployed through Docker Compose or virtualenv.
* [ ] **Trace the CDE Bites Failure Journey:** Review the code files for `extract.py`, `load.py`, `transform.py`, and `notify.py`. Mentally map each failure mode from Stages 0 through 3.
* [ ] **Self-Study:** Read the Apache Airflow architecture documentation covering the **Scheduler**, **Webserver**, **Metadata Database**, **Executor**, and **Worker**.
* [ ] **Next Class:** Deep dive into Airflow core concepts: writing your first DAG, configuring operators, mapping dependencies (`>>`), and managing execution contexts.