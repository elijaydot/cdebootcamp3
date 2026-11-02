# Mastering Apache Airflow: Modular DAG Refactoring, Top-Level Code Traps & In-Warehouse Pushdown Compute

*A Deep-Dive Technical Summary of the Apache Airflow Architecture & Implementation Masterclass with Najeeb Sulaiman (Orchestration 4.0)*

**Lead Instructor:** Najeeb Sulaiman  
**Teaching Assistants:** Nancy Amandi, Charles Edeki, Leo Osigbemhe  
**Date:** October 24, 2026 | **Duration:** 143 Minutes  

---

## Executive Summary

In this hands-on engineering session, **Najeeb Sulaiman** tackled the most common traps that convert promising data pipelines into unstable production bottlenecks. Moving past naive scripts where business logic is dumped directly inside DAG definition files, the masterclass covered:

1. **The Top-Level Code Trap:** How Airflow’s continuous DAG-parsing loop turns innocent top-level database connections and API calls into denial-of-service self-attacks.
2. **Modular Code Decoupling:** Extracting ETL business logic out of DAG definitions into clean, reusable utility modules (`include/orders_util.py`).
3. **The Compute Governance Law:** Why Airflow workers must **never** process heavy data in-memory, and how to push transformations down to the target Data Warehouse via `SQLExecuteQueryOperator`.
4. **Extending Airflow via Providers & Docker:** The architectural difference between **Operators**, **Hooks**, and **Connections**, and how to build deterministic custom Docker images rather than relying on runtime pip injections.

---

## 1. Pre-Class Architecture Refresher & Quiz Breakdown

The session kicked off with an interactive technical quiz hosted by TA **Nancy Amandi** (won decisively by **Alamin**, followed by **Oluwabukunmi** and **Mina**). 

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CORE ARCHITECTURE QUIZ LOG                      │
├────────────────────────────────────────────────────────────────────────┤
│ 1. The Central Nervous System: The Scheduler is the brain of Airflow.  │
│    Without it, DAGs cannot evaluate state or trigger task instances.   │
│ 2. Metadata Database Support: PostgreSQL & MySQL are tier-1 production │
│    engines (SQLite is supported strictly for local single-process dev).│
│ 3. UI Trigger Routing: Triggering a DAG from the Web UI writes a state │
│    record into the Metadata DB; the Scheduler detects and queues it.   │
│ 4. Distributed Task Queuing: The CeleryExecutor requires a message     │
│    broker/queue (Redis or RabbitMQ) to distribute tasks to workers.    │
│ 5. DagFileProcessor: The background subprocess responsible for         │
│    continuously parsing DAG Python files into serialized representations│
│    stored inside the metadata database.                                │
│ 6. The Execution API (AIP-44): Modern Airflow workers communicate via  │
│    an execution interface to prevent arbitrary worker pods from holding │
│    direct, insecure connections to the core metadata database.         │
└────────────────────────────────────────────────────────────────────────┘
```

### Critical Troubleshooting Corner: Linux & WSL User ID Permissions
Student **Immaculate Okoro** highlighted a common stumbling block when running Airflow via Docker Compose on Linux/WSL: **File permission exceptions when writing to mounted host volumes.**

* **The Problem:** The default Apache Airflow container runs internally under user UID `50000`. When Airflow creates folders (`dags/`, `logs/`, `plugins/`), the host OS assigns ownership to UID `50000`. The host user cannot edit or create files inside those folders without `sudo`.
* **The Production Fix:** Export your exact host user UID into the container environment before initialization:
  ```bash
  # Generate .env with matching host user UID
  echo -e "AIRFLOW_UID=$(id -u)" > .env
  
  # Initialize and launch
  docker compose up airflow-init
  docker compose up -d
  ```

---

## 2. The Silent Production Killer: The "Top-Level Code" Trap

Najeeb inspected the legacy DAG script: **98 lines of Python code containing 4 tasks mixed with database connections, CSV reading logic, and transformation loops.**

```
AIRFLOW DAG DIRECTORY (/opt/airflow/dags)
          │
          ▼  Scanned every 30 seconds!
┌────────────────────────────────────────────────────────────────────────┐
│  AIRFLOW SCHEDULER: DagFileProcessor Loop                              │
│  (Configured via min_file_process_interval = 30 in airflow.cfg)        │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
              Executes the Python file from top to bottom!
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│ ❌ TOP-LEVEL CODE ANTI-PATTERN:                                         │
│                                                                        │
│ engine = create_engine(DB_URL)      <-- Connects to DB every 30s!      │
│ df = pd.read_csv("large_data.csv")  <-- Loads 500MB into RAM every 30s!│
│ resp = requests.get("https://api")  <-- Floods API every 30s!          │
│                                                                        │
│ def my_dag():                                                          │
│     ...                                                                │
└────────────────────────────────────────────────────────────────────────┘
```

### Why Top-Level Code Destroys Production Environments:
1. **Continuous Execution:** The Airflow Scheduler does not wait for a DAG's scheduled execution window to parse its Python file. It executes the file **every 30 seconds** (`min_file_process_interval`) to discover new DAGs, detect code changes, and evaluate scheduling intervals.
2. **Resource Exhaustion:** If a top-level code block opens a database connection or imports heavy, un-instantiated data structures, **the scheduler opens that connection every 30 seconds across every file in the directory**.
3. **The Result:** 50 DAGs with top-level database connections will open thousands of unmanaged connections per hour, overwhelming warehouse connection pools and starving scheduler worker threads.

---

## 3. Modular Architecture: Decoupling DAGs with `include/`

To enforce the **Single Responsibility Principle** and eliminate clutter, Najeeb demonstrated how to refactor an Airflow repository:

```
airflow_workspace/
├── dags/
│   ├── orders_dag.py             <-- PURE DECLARATION: Tasks, dependencies, tags
│   └── include/
│       ├── __init__.py
│       ├── config.py             <-- Path declarations & environment settings
│       └── orders_util.py        <-- BUSINESS LOGIC: Pure Python ETL functions
```

### Step 1: The Business Logic Module (`include/orders_util.py`)
All extraction, loading, cleaning, and alerting logic is relocated into standalone, testable functions:

```python
# dags/include/orders_util.py
import os
import pandas as pd
from sqlalchemy import create_engine
from include import config

def extract():
    """Extracts raw orders data into the local landing directory."""
    df = pd.read_csv(config.SOURCE_DATA_URL)
    os.makedirs(os.path.dirname(config.LANDING_FILE_PATH), exist_ok=True)
    df.to_csv(config.LANDING_FILE_PATH, index=False)
    print(f"Extracted {len(df)} records to landing zone.")

def load():
    """Bulk loads staged CSV into target warehouse staging table."""
    engine = create_engine(config.DATABASE_URL)
    df = pd.read_csv(config.LANDING_FILE_PATH)
    df.to_sql("raw_orders", con=engine, if_exists="replace", index=False)
    print("Successfully loaded raw records to database.")
```

### Step 2: The Clean, Declarative DAG File (`dags/orders_dag.py`)
The pipeline definition becomes lightweight, readable, and free of processing overhead:

```python
# dags/orders_dag.py
from pendulum import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

# Clean absolute import from the custom utility module
from include.orders_util import extract, load

with DAG(
    dag_id="cde_bites_orders_v2",
    start_date=datetime(2026, 10, 24),
    schedule=None,  # Manual trigger for development
    catchup=False,
    tags=["cde_bites", "orders", "refactored"]
) as dag:

    task_extract = PythonOperator(
        task_id="extract_orders",
        python_callable=extract
    )

    task_load = PythonOperator(
        task_id="load_orders",
        python_callable=load
    )

    task_extract >> task_load
```

---

## 4. The Golden Rule of Orchestration: In-Warehouse Pushdown Compute

Najeeb called out the most widespread architectural flaw in data teams:

> *"Airflow is an **orchestrator**, not a compute engine. Airflow has no business performing data transformations inside worker memory."*

```
❌ WRONG: Pulling Heavy Data into Airflow Workers
   Database / S3 ───> Airflow Worker Memory (Pandas DataFrame) ───> Warehouse
   ⚠️ Risk: Worker runs Out-Of-Memory (OOM), task dies, Scheduler freezes.

✅ RIGHT: In-Warehouse Pushdown Compute (ELT Pattern)
   Airflow Task ─── (Sends SQL Query / Triggers dbt) ───> Target Warehouse
   ⚡ The Data Warehouse (PostgreSQL, Snowflake, BigQuery) computes the transformation!
```

### Refactoring Python Transformations to SQL Pushdown
Instead of pulling rows into worker memory to clean strings and compute metrics with Pandas, delegate the work directly to the database engine using `SQLExecuteQueryOperator`.

```python
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

transform_orders = SQLExecuteQueryOperator(
    task_id="transform_orders_sql",
    conn_id="supabase_postgres_conn",
    sql="""
        DROP TABLE IF EXISTS transformed_orders;
        
        CREATE TABLE transformed_orders AS
        SELECT DISTINCT
            order_id,
            customer_id,
            TRY_CAST(order_date AS DATE) AS order_date,
            COALESCE(customer_name, 'Unknown') AS customer_name,
            COALESCE(product_name, 'Unknown') AS product_name,
            quantity,
            price,
            (quantity * price) AS total_sales
        FROM raw_orders
        WHERE order_id IS NOT NULL;
    """
)
```

---

## 5. Providers, Hooks & Connections Explained

To interact securely with external systems without hardcoding passwords in scripts, Airflow decouples execution across three distinct layers:

```
┌────────────────────────────────────────────────────────────────────────┐
│ 1. CONNECTION (The What & Who)                                         │
│    • Stored securely in Metadata DB (Admin -> Connections).            │
│    • Encapsulates Host, Port, Login, Password, and Extra configs.      │
├────────────────────────────────────────────────────────────────────────┤
│ 2. HOOK (The Engine & Protocol)                                        │
│    • Low-level Python interface (e.g., PostgresHook, S3Hook).          │
│    • Handles connection pooling, authentication handshakes, and wire   │
│      communication protocols.                                          │
├────────────────────────────────────────────────────────────────────────┤
│ 3. OPERATOR (The Orchestration Template)                               │
│    • High-level task wrapper instantiated inside the DAG script        │
│      (e.g., SQLExecuteQueryOperator).                                  │
│    • Defines dependencies, retries, and execution order. Under the hood│
│      it calls the Hook to run queries.                                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Extending Airflow: Deterministic Custom Docker Builds

By default, the official Apache Airflow Docker image contains core operational packages, but excludes external database drivers (like `apache-airflow-providers-postgres`).

### Why `_PIP_ADDITIONAL_REQUIREMENTS` Fails in Production:
* Re-installs packages over the internet **every single time a container restarts**.
* Slows down deployment and startup times.
* Risks silent pipeline breaks if upstream package repositories experience network timeouts.

### The Production Solution: Custom Dockerfile Layering

#### Step 1: Create a `Dockerfile` in the Project Root
```dockerfile
# Use official image matching your Docker Compose version
FROM apache/airflow:2.10.2

# Switch to root to manage system dependencies (if needed)
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Switch back to the airflow user to install Python packages
USER airflow

# Install official enterprise providers
RUN pip install --no-cache-dir \
    apache-airflow-providers-postgres==5.13.0 \
    apache-airflow-providers-common-sql==1.18.0
```

#### Step 2: Update `docker-compose.yaml`
```yaml
# 1. Comment out the default static image
# image: ${AIRFLOW_IMAGE_NAME:-apache/airflow:2.10.2}

# 2. Instruct Docker Compose to build your custom Dockerfile
build: .
```

#### Step 3: Build and Launch
```bash
docker compose down
docker compose up -d --build
```

---

## 7. Live Troubleshooting Log & Student Q&A Register

| Participant | Issue / Question | Root Cause | Solution Applied |
| :--- | :--- | :--- | :--- |
| **Roqeeb Olaniran** | Webserver container showed status `unhealthy` upon startup. | System resource starvation on local PC. | Restart host machine to clear memory contention; allow up to 2–3 minutes for initial health checks to pass. |
| **Immaculate Okoro** | Permission denied when creating files inside mounted `dags/` folder. | Container user UID `50000` owned the directory instead of host user. | Generated `.env` with `AIRFLOW_UID=$(id -u)` matching local host user ID. |
| **Prince Peter** | How is Supabase different from PostgreSQL if we connect using `PostgresHook`? | Supabase is a managed PostgreSQL database. | Under the hood it runs standard PostgreSQL; configure connection using `conn_type='postgres'`. |
| **Lorreta Anyika** | Can we install dependencies via `_PIP_ADDITIONAL_REQUIREMENTS` in `docker-compose.yaml`? | Asking about alternative dependency installation. | Acceptable for quick local tests, but prohibited in production. Use a dedicated `Dockerfile` build step. |
| **Josephine Adah** | Why specify the data path in Python when Airflow's config already declares paths? | Path confusion. | `airflow.cfg` configures internal engine directories (`/opt/airflow/dags`); custom ETL scripts require explicit paths for business logic. |

---

## 8. Action Checklist for Engineers

- [ ] **Audit Top-Level Code:** Inspect all DAG scripts to ensure no database connections, heavy file reads, or API requests exist outside task functions.
- [ ] **Enforce Directory Structure:** Separate execution logic into `dags/` and modular functions into `dags/include/`.
- [ ] **Implement Pushdown Transformations:** Transition data-cleaning and transformation tasks from Python memory to `SQLExecuteQueryOperator`.
- [ ] **Harden Container Builds:** Add required external providers (`apache-airflow-providers-postgres`) via a custom `Dockerfile` using `docker compose up -d --build`.
- [ ] **Configure Managed Connections:** Register external database credentials inside `Admin -> Connections` rather than hardcoding connection strings in source code.