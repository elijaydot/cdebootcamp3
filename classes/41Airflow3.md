# Demystifying Apache Airflow: Architecture Internals, The Executor Matrix & Live DAG Debugging

*A Comprehensive Technical Summary of the Apache Airflow Architecture Masterclass with Najeeb Sulaiman (Orchestration 3.0)*

**Lead Instructor:** Najeeb Sulaiman  
**Teaching Assistants:** Nancy Amandi, Charles Edeki  
**Date:** October 23, 2026 | **Duration:** 148 Minutes  
**Core Topics:** Pre-Class Architectural Refresher, The Core Components of Airflow, The Executor Comparison Matrix (Local vs. Celery vs. Kubernetes), Under-the-Hood Docker Compose Architecture, Building the CDE Bites Orders DAG, and Live Path/Environment Debugging.

---

## Executive Summary

In this foundational architecture deep dive, **Najeeb Sulaiman** peeled back the abstraction layer of **Apache Airflow**. While beginner tutorials often treat Airflow as a monolithic web application where Python scripts magically turn into workflow graphs, this session revealed Airflow for what it truly is: **a distributed, multi-component operating system for batch data pipelines**.

The masterclass walked through three major learning arcs:
1. **The Component Decomposition:** Dissecting the 7 core background daemons that power Airflow (Metadata DB, Scheduler, API Server, DagFileProcessor, Executor, Workers, and Triggerer).
2. **The Distributed Execution Matrix:** Analyzing how task scheduling shifts when transitioning from single-node `LocalExecutor` to multi-worker `CeleryExecutor` (with Redis brokers) and dynamically provisioned `KubernetesExecutor` pods.
3. **From Raw Code to Production DAG (The CDE Bites Pipeline):** Converting Dele's raw Python functions into an active Airflow DAG, encountering live execution errors (`OSError`, pathing mismatches, missing `.env` database secrets), and systematically debugging them through container logs.

---

## 1. Pre-Class Architectural Refresher & Quiz

The class opened with an intensive 15-question architectural quiz facilitated by TA **Nancy Amandi** (won by **Ro / Alamin**, with **Mina** and **Elijah** leading earlier rounds):

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CORE ARCHITECTURE TAKEAWAYS                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Origin: Airflow was authored by Maxime Beauchemin at Airbnb (2014). │
│ 2. Batch vs. Streaming: Airflow is built for batch orchestration (DAGs)│
│    and is fundamentally NOT suited for event-by-event streaming.       │
│ 3. Airflow vs. Airbyte & dbt: Airflow orchestrates third-party tools;  │
│    it does not replace specialized extract/load (Airbyte) or SQL       │
│    transformation (dbt) engines.                                       │
│ 4. DAG Definition: Directed Acyclic Graph (finite directed flows with  │
│    strictly NO circular loops).                                        │
│ 5. schedule=None: Means the pipeline is manual/triggered only; it has  │
│    no automated temporal schedule.                                     │
│ 6. Task Dependency Syntax: Declared using the bitshift operators       │
│    (>> and <<) or set_upstream() / set_downstream().                   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Developer Environment Gotchas: VS Code & Docker Host Isolation

Before diving into engine internals, students tackled common environment setup blockers:

### A. The "Missing IntelliSense" Dilemma (VS Code vs. Docker Container)
Student **Alani** noticed that typing `from airflow.sdk import DAG` inside VS Code threw linting errors on the host OS, but worked fine inside WSL.

**Najeeb's Explanation of Process Isolation:**
```
       HOST MACHINE (Developer Laptop)                 DOCKER HOST / RUNTIME
┌──────────────────────────────────────────┐      ┌───────────────────────────────┐
│ VS Code Editor                           │      │ Airflow Worker Container      │
│ • Runs as a local host process.          │      │ • Isolated namespace process. │
│ • Python interpreter searches local OS   │      │ • apache-airflow installed    │
│   site-packages (Airflow is not there!). │      │   INSIDE the container image. │
└────────────────────┬─────────────────────┘      └───────────────────────────────┘
                     │
                     ▼ The Fix: Local Dev Environment
┌──────────────────────────────────────────┐
│ Create a local Python virtualenv (.venv) │
│ Run: pip install apache-airflow          │
│ Install the Microsoft Pylance extension. │
│ (VS Code can now auto-complete symbols!) │
└──────────────────────────────────────────┘
```

### B. Linux / WSL File Permission Collisions (UID 50000)
Student **Immaculate Okoro** encountered permission errors when Airflow attempted to write logs into mapped host folders.
* **The Root Cause:** Official Airflow containers run as internal user UID `50000` (`airflow:root`). If host directories are owned by standard user accounts (UID `1000`), the container cannot write logs.
* **The Solution:** Export the host's actual user ID into `.env` prior to running `docker compose`:
  ```bash
  echo -e "AIRFLOW_UID=$(id -u)" > .env
  docker compose up airflow-init
  docker compose up -d
  ```

### C. Resource Hygiene: Docker Desktop Sleeping vs. Stopping
Student **Chidinma** admitted to leaving Docker Desktop running continuously for 6 days.
* **The Warning:** Airflow is heavily multi-threaded and resource-intensive. Leaving 7 containers running continuously on a personal laptop causes memory leaks, CPU throttling, and degraded performance.
* **Best Practice:** When pausing work, use `docker compose stop` (pauses containers without deleting them) and close Docker Desktop. When resuming work, run `docker compose start`.

---

## 3. Deconstructing the Airflow Engine: The 7 Core Components

Airflow is not a single executable; it is an ensemble of coordinated background services:

```
                                  AIRFLOW UI / USER
                                          │
                                          │ Web / REST Requests
                                          ▼
                               ┌─────────────────────┐
                               │   API Server        │
                               │   (FastAPI/React)   │
                               └──────────┬──────────┘
                                          │
                        ┌─────────────────┴─────────────────┐
                        │                                   │
                        ▼                                   ▼
          ┌───────────────────────────┐       ┌───────────────────────────┐
          │     Scheduler Daemon      │       │     DagFileProcessor      │
          │  • Polls task states.     │       │  • Parses /dags Python.   │
          │  • Contains the Executor. │       │  • Serializes DAG models. │
          └─────────────┬─────────────┘       └─────────────┬─────────────┘
                        │                                   │
                        ▼                                   ▼
          ┌───────────────────────────────────────────────────────────────┐
          │              METADATA DATABASE (The Brain)                    │
          │              PostgreSQL / MySQL (State, Runs, Logs)           │
          └───────────────────────────────┬───────────────────────────────┘
                                          │
                                          │ Task Queues & Status
                                          ▼
          ┌───────────────────────────────────────────────────────────────┐
          │                       THE EXECUTOR                            │
          │       Determines WHERE and HOW tasks will be executed         │
          └─────────────┬───────────────────────────────────┬─────────────┘
                        │                                   │
                        ▼ (Celery Queue via Redis)          ▼ (Kubernetes API)
          ┌───────────────────────────┐       ┌───────────────────────────┐
          │     Celery Workers        │       │      Kubernetes Pods      │
          │  • Always-on VMs.         │       │  • Dynamic ephemeral pods.│
          │  • Consumes from Redis.   │       │  • Self-healing, zero-idle│
          └───────────────────────────┘       └───────────────────────────┘
```

### Detailed Component Inventory:

| Component | Architecture Role | Technical Detail |
| :--- | :--- | :--- |
| **1. Metadata Database** | **The Brain & Single Source of Truth** | Stores historical DAG runs, task execution states (`queued`, `running`, `success`, `failed`), variables, connections, and XComs. Supported: **PostgreSQL**, **MySQL** (SQLite for local dev only). Never write raw pipeline business data here! |
| **2. API Server (FastAPI)** | **The Secure Intermediary / Waiter** | Provides an API layer between the React UI, external consumers, workers, and the metadata DB. Isolates worker code from opening direct database sockets. |
| **3. Scheduler** | **The Conductor** | Continuously monitors the metadata DB, checks if task dependencies and scheduling intervals are satisfied, and passes ready tasks to the Executor. |
| **4. DagFileProcessor** | **The Serializer** | Reads Python files in the `/dags` folder, executes top-level code, checks for syntax/DAG errors, and serializes DAG structures into JSON blobs inside the metadata database. |
| **5. Executor** | **The Logistics Coordinator** | Lives *inside* the Scheduler process. It does not run task logic directly; it decides **where and how** task instructions are dispatched. |
| **6. Workers** | **The Physical Laborers** | The actual operating system processes, Docker containers, or Kubernetes pods running the Python code, SQL queries, or Bash commands. |
| **7. Triggerer** | **The Asynchronous Deferral Daemon** | Offloads long-waiting tasks (sensors, external jobs like Airbyte syncs) from occupying active worker memory slots using Python `asyncio`. |

---

## 4. The Executor Matrix: Local vs. Celery vs. Kubernetes

A major section of the masterclass deconstructed how Airflow scales across execution environments:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               THE EXECUTOR COMPARISON MATRIX                           │
├──────────────────────┬────────────────────────┬────────────────────────────────────────┤
│ Executor Type        │ Where Tasks Run        │ Architecture, Pros & Cons             │
├──────────────────────┼────────────────────────┼────────────────────────────────────────┤
│ **LocalExecutor**    │ Single Machine         │ • Tasks run as local OS sub-processes. │
│                      │ (Scheduler process)    │ • Scales via multi-processing/threads. │
│                      │                        │ • ❌ Cannot scale across multiple VMs. │
│                      │                        │ • Best for: Local testing & lightweight│
│                      │                        │   single-node servers.                 │
├──────────────────────┼────────────────────────┼────────────────────────────────────────┤
│ **CeleryExecutor**   │ Distributed Worker VMs │ • Tasks pushed to a message broker     │
│                      │ (Always-on fleet)      │   (Redis / RabbitMQ).                  │
│                      │                        │ • Workers poll queue and run tasks.    │
│                      │                        │ • ❌ High idle cost; workers stay on.  │
│                      │                        │ • Best for: High-throughput, steady,   │
│                      │                        │   predictable batch workloads.         │
├──────────────────────┼────────────────────────┼────────────────────────────────────────┤
│ **KubernetesExecutor**│ Dynamic Kubernetes Pods│ • Each task instance launches its own  │
│                      │ (Ephemeral containers) │   isolated container pod via K8s API.  │
│                      │                        │ • ✅ Zero idle cost; pods terminate.   │
│                      │                        │ • ❌ Cold-start pod spin-up latency.   │
│                      │                        │ • Best for: Resource-heavy, spiky, or  │
│                      │                        │   strict-isolation workloads.          │
└──────────────────────┴────────────────────────┴────────────────────────────────────────┘
```

### The Concept of the Queue (Redis / RabbitMQ)
* If **100 tasks** are ready to run simultaneously, but your worker fleet only has **10 concurrency slots**:
  * 10 tasks enter the `running` state on workers.
  * The remaining **90 tasks wait in the Redis message queue** in a `queued` state until slots become available.

---

## 5. Under the Hood: Dissecting `docker-compose.yaml`

Najeeb opened Docker Desktop and mapped running containers directly to the services defined in the official Airflow Docker Compose manifest:

```yaml
# Mapping docker-compose services to architectural roles:
services:
  postgres:           # 1. The Metadata Database
    image: postgres:13
    
  redis:              # 2. The Message Queue Broker (for CeleryExecutor)
    image: redis:7.2-alpine
    
  airflow-webserver:  # 3. The Web Interface (Flask/React on Port 8080)
    restart: always
    
  airflow-scheduler:  # 4. The Scheduler & Embedded Executor
    restart: always
    
  airflow-worker:     # 5. The Celery Worker Node (Executes task code)
    restart: always
    
  airflow-triggerer:  # 6. Async Deferral Daemon (For sensors/triggers)
    restart: always
    
  airflow-init:       # 7. Ephemeral bootstrap container (Runs DB migrations & exits)
```

> 💡 **Why is there no dedicated `executor` container?**  
> The Executor is a Python class executing **inside the Scheduler daemon process**, meaning it does not run as an independent operating system container.

---

## 6. Practical Lab: Converting Dele's Scripts to `orders_dag.py`

The cohort walked step-by-step through translating the four loose procedural scripts from the **CDE Bites** problem statement into a declarative, multi-step pipeline.

```
       CDE BITES PIPELINE TOPOLOGY
┌────────────────┐     ┌─────────────┐     ┌──────────────────┐     ┌───────────────┐
│ extract_orders │ ──> │ load_orders │ ──> │ transform_orders │ ──> │ notify_orders │
└────────────────┘     └─────────────┘     └──────────────────┘     └───────────────┘
```

### The Initial Implementation (`dags/orders.py`)

```python
import os
from pendulum import datetime
from datetime import datetime as dt
import pandas as pd
from sqlalchemy import create_engine

from airflow import DAG
from airflow.operators.python import PythonOperator

# 1. Logic Definitions (Embedded for prototyping)
def extract():
    url = "https://docs.google.com/spreadsheets/d/.../export?format=csv"
    df = pd.read_csv(url)
    os.makedirs("/opt/airflow/dags/data", exist_ok=True)
    df.to_csv("/opt/airflow/dags/data/raw_sales.csv", index=False)

def load():
    engine = create_engine(os.getenv("DATABASE_URL"))
    df = pd.read_csv("/opt/airflow/dags/data/raw_sales.csv")
    df.to_sql("raw_sales", con=engine, if_exists="replace", index=False)

def transform():
    engine = create_engine(os.getenv("DATABASE_URL"))
    df = pd.read_sql("SELECT * FROM raw_sales", con=engine)
    df = df.drop_duplicates(subset=["order_id"])
    df["order_date"] = pd.to_datetime(df["order_date"])
    df["customer_name"] = df["customer_name"].fillna("Unknown")
    df["total_sales"] = df["quantity"] * df["price"]
    df.to_sql("transformed_sales", con=engine, if_exists="replace", index=False)

def notify():
    today_str = dt.today().strftime('%Y-%m-%d')
    with open("/opt/airflow/dags/data/report.txt", "w") as f:
        f.write(f"CDE Bites Daily Report for {today_str}: Orders processed successfully.")

# 2. DAG Instantiation
with DAG(
    dag_id="cde_bites_orders_v1",
    start_date=datetime(2026, 10, 23),
    schedule=None,  # Manual trigger for development
    catchup=False,
    tags=["cde_bites", "orders"]
) as dag:

    # 3. Task Declarations via PythonOperator
    task_extract = PythonOperator(
        task_id="extract_orders",
        python_callable=extract
    )

    task_load = PythonOperator(
        task_id="load_orders",
        python_callable=load
    )

    task_transform = PythonOperator(
        task_id="transform_orders",
        python_callable=transform
    )

    task_notify = PythonOperator(
        task_id="notify_orders",
        python_callable=notify
    )

    # 4. Dependency Chaining
    task_extract >> task_load >> task_transform >> task_notify
```

---

## 7. Live Debugging: Resolving Real-World Container Failures

When Najeeb manually triggered `cde_bites_orders_v1` from the Airflow UI, the pipeline failed on the very first task:

```
[ extract_orders ] (FAILED ❌) ──> [ load_orders ] (UPSTREAM_FAILED ⚠️)
                               ──> [ transform_orders ] (UPSTREAM_FAILED ⚠️)
                               ──> [ notify_orders ] (UPSTREAM_FAILED ⚠️)
```

### Bug 1: The `OSError: [Errno 2] No such file or directory: 'data'`
* **What Happened:** The code specified `df.to_csv("data/raw_sales.csv")`.
* **The Log Investigation:** Najeeb opened the task logs (`Task Instance -> Logs`) and traced the stack trace to line 19.
* **The Root Cause:** The current working directory of the Airflow worker container is `/opt/airflow`. It was searching for `/opt/airflow/data`, which did not exist.

### Bug 2: The Host Path vs. Container Path Trap
* **The Attempted Fix:** Setting a relative path or using the developer's laptop host path (`/Users/najeeb/Documents/bootcamp/dags/data`).
* **The Architectural Rule:** Containers do not understand host laptop paths. Airflow volumes are bind-mounted inside the container at `/opt/airflow/dags/`.
* **The Correct Fix:** Declare the fully qualified container path:
  ```python
  DATA_PATH = "/opt/airflow/dags/data"
  df.to_csv(f"{DATA_PATH}/raw_sales.csv", index=False)
  ```

### Bug 3: `OperationalError: connection to server failed`
* **What Happened:** `task_extract` passed, but `task_load` crashed immediately when attempting to connect to the Supabase PostgreSQL database.
* **The Root Cause:** `os.getenv("DATABASE_URL")` evaluated to `None`. The `.env` file containing connection credentials had not been mounted into the DAG execution directory.
* **The Fix:** Placed the `.env` credentials in the mounted project directory, re-triggered the pipeline, and verified that all 4 tasks turned solid green (`SUCCESS`).

---

## 8. Interactive Q&A and Troubleshooting Register

| Participant | Question / Discussion | Resolution & Engineering Guidance |
| :--- | :--- | :--- |
| **Prince Peter** | *"How do we convert a normal Python function into an Airflow task?"* | Use an Operator (e.g., `PythonOperator`). Supply a unique `task_id` and pass the function reference via `python_callable=my_function`. |
| **Immaculate Okoro** | *"Why do we have to install `pandas` separately if we're using `PythonOperator`?"* | `PythonOperator` is merely an orchestration template for calling functions; it does not ship with external third-party data manipulation libraries. Those must be installed in the worker's Python environment. |
| **Immaculate Okoro** | *"If a task succeeds and we rerun the DAG, won't it create duplicate records?"* | Yes! Airflow handles scheduling and dependencies, but it does **not** guarantee business-logic idempotency. Deduplication and idempotent loads must be engineered inside your code/queries. |
| **Judith Ani** | *"What does `OSError` mean in the task logs?"* | Operating System error. The OS kernel could not complete a filesystem action (e.g., attempting to write a file into a non-existent directory). |
| **Osakpolor Ogieriakhi** | *"Is mounting host folders via Docker Compose considered bad practice in production?"* | Yes. In production, code and dependencies are baked directly into immutable Docker images or deployed via CI/CD artifacts onto cloud storage/git-sync, not mapped from local laptop folders. |
| **Dennis Humes** | *"Can we use `docker compose stop` instead of `down`?"* | Yes! `docker compose stop` pauses container execution without destroying network bridges or containers, allowing for a much faster `docker compose start` when resuming development. |

---

## 9. Action Checklist for Engineers

* [ ] **Review DAG Anatomy:** Ensure you can construct an end-to-end DAG script from memory (`DAG` context manager, `PythonOperator`, bitshift `>>` dependencies).
* [ ] **Inspect Container Volumes:** Exec into the scheduler container (`docker exec -it <scheduler_id> bash`) and run `ls -la /opt/airflow/dags` to verify how host files map into container paths.
* [ ] **Prepare for Refactoring:** Notice how `orders.py` currently embeds raw business logic inside the DAG file—review this ahead of the modular refactoring lab in Orchestration 4.0.
* [ ] **Practice Failure Triage:** When tasks fail, avoid guessing. Open the Airflow UI, inspect the **Graph View**, drill into the red task instance, open the **Logs**, and locate the Python traceback line.