# CDE Bootcamp 3.0: Apache Spark Architecture Deep-Dive — YARN Cluster Manager, Driver vs. Executors, Heartbeats & Deploy Modes

> *"YouTube tutorials teach you how to write 10 lines of PySpark in a local Jupyter notebook and call it a day. That is just looking at the shiny paint on the outside of the car. Tonight, we pop open the hood to inspect the engine: how YARN allocates containers, how the Spark Driver compiles logical plans into physical tasks, how heartbeat monitoring heals dead nodes, and why deploying in Client Mode instead of Cluster Mode can crash your production pipeline the moment your SSH terminal blinks."*
>
> — **Mayowa Akinyele**

**Date:** November 20, 2026  
**Duration:** 135 Minutes  
**Lead Instructor:** Mayowa Akinyele (Opening Quiz by Abdulhakeem Salaudeen)  
**Curriculum Module:** 11 Distributed Data Processing — Apache Spark Internal Architecture: Cluster Managers (YARN vs. Kubernetes), Resource Manager & Node Manager, Spark Driver & Executors, YARN Containers, Cluster Heartbeat & Fault Recovery Workflows, Catalyst Query Optimizer (Logical to Physical Plans), and Deploy Modes (`client` vs. `cluster`)

---

## Executive Overview & Class Atmosphere

Building directly on Wednesday’s hardware and big data foundations, this masterclass popped open the black box of **Apache Spark's distributed runtime architecture**.

Mayowa opened by reminding students that **PySpark** is merely the Python API used to communicate instructions to the underlying Spark engine. While anyone can generate PySpark syntax using AI, senior data engineers stand apart in interviews and production incidents because they understand **what happens inside the cluster when a job is submitted**.

Through detailed Excalidraw sequence mappings and live demonstrations on both a **local Dockerized Jupyter environment** and a **3-node Amazon EMR production cluster**, Mayowa traced the exact step-by-step lifecycle of a `spark-submit` job—covering YARN container allocation, Driver lineage DAG compilation, Executor task execution, heartbeat failure detection, dynamic executor allocation, and why production jobs must always run in **`cluster` deploy mode**.

---

## Part 1: Warm-Up Quiz — Hardware Internals, MapReduce & Shuffling Recap
*(Facilitated by Abdulhakeem Salaudeen)*

The session opened with an interactive Slido quiz reinforcing Wednesday’s distributed computing concepts:

1. **Cluster Memory vs. Disk Capacity Math:**
   * A 4-node cluster where each node has `4 CPU cores`, `16 GB RAM`, and `256 GB Disk` provides **$4 \times 16\text{ GB} = 64\text{ GB}$ of pooled Memory (RAM)** (do not confuse Disk storage with volatile RAM!).
2. **Hadoop MapReduce's Fatal Bottleneck:**
   * MapReduce suffered from severe **Disk I/O latency** because it was forced to write intermediate results back to physical disk between every single transformation stage.
3. **Why Network Shuffling Is Expensive:**
   * Wide transformations (`groupBy`, `join`) force data to move across network cables between nodes so matching keys land in the same memory space—incurring serialization overhead, network latency, and AWS cross-AZ data transfer fees.
4. **Data Skewness:**
   * Occurs when one grouping key holds vastly more records than others (e.g., 14 billion `US` rows vs. 1 million `EU` rows), causing one worker node to choke or crash with Out-Of-Memory (OOM) errors while sibling nodes sit idle.
5. **Apache Spark's Core Breakthrough:**
   * Eliminates MapReduce's intermediate Disk I/O by chaining transformations inside volatile **RAM (Memory)**, writing to disk only at the very end (or spilling gracefully if RAM overflows).
   * *Quiz Winner:* **Olawale Akinyele** 🏆 *(scoring 9/10)*

---

## Part 2: The 3 Core Components of an Apache Spark Cluster

When you submit a PySpark script to a production cluster, three core architectural pillars collaborate to execute your workload:

```
+-----------------------------------------------------------------------------------------+
|                         APACHE SPARK DISTRIBUTED CLUSTER                                |
|                                                                                         |
|  1. CLUSTER MANAGER (YARN / Kubernetes)                                                 |
|     - The infrastructure landlord & resource negotiator                                 |
|     - Tracks available CPU cores & RAM across all physical/virtual servers              |
|     - Spawns isolated resource boxes (YARN Containers) for the Driver and Executors     |
|                                           │                                             |
|                 ┌─────────────────────────┴─────────────────────────┐                   |
|                 ▼                                                   ▼                   |
|  2. SPARK DRIVER ("The Brain")                       3. SPARK EXECUTORS ("The Workers") |
|     - Runs your main() PySpark script                   - Worker JVMs running in YARN   |
|     - Builds the Lineage DAG & optimizes plans            containers across nodes       |
|     - Splits work into parallel Tasks                   - Read data from S3/HDFS into   |
|     - Schedules Tasks onto Executors &                    RAM, execute tasks in parallel|
|       monitors Executor heartbeats                        and write final outputs       |
+-----------------------------------------------------------------------------------------+
```

1. **Cluster Manager (YARN or Kubernetes):**
   * Spark does not manage physical servers itself; it relies on a **Cluster Manager**—most commonly **Apache Hadoop YARN (Yet Another Resource Negotiator)** on Amazon EMR/on-prem clusters, or **Kubernetes** in containerized environments.
   * **Role:** Allocates CPU cores and RAM across cluster nodes and launches isolated execution environments.
2. **Spark Driver ("The Brain"):**
   * **Does NOT exist before you submit your application.** It is spawned dynamically upon job submission.
   * Parses your PySpark code, constructs the **Lineage DAG (Directed Acyclic Graph)**, runs query optimizations, breaks the job into granular **Tasks**, schedules tasks onto Executors, and tracks application lifecycle until completion.
   * *Single Point of Failure Warning:* Because the Lineage DAG lives inside the Driver's memory, if the Driver crashes permanently, all progress is lost and the job must restart from scratch.
3. **Spark Executors ("The Workers"):**
   * Dedicated worker processes launched inside containers across cluster worker nodes.
   * Each Executor receives an explicit allocation of CPU cores (slots) and RAM (e.g., `2 cores, 4 GB RAM`).
   * Executors perform all heavy lifting: reading Parquet/CSV files from S3 into RAM, running filters/joins/aggregations in parallel, and writing final results out to S3 or Redshift.

---

## Part 3: Inside YARN — Resource Manager, Node Managers & YARN Containers

To understand how Spark requests hardware, Mayowa unpacked the internal master–slave architecture of **YARN**:

```
+-----------------------------------------------------------------------------------------+
|                              YARN CLUSTER ARCHITECTURE                                  |
|                                                                                         |
|  [ Primary / Master Server ]                                                            |
|  +-----------------------------------------------------------------------------------+  |
|  | YARN Resource Manager (The Boss)                                                  |  |
|  | - Receives `spark-submit` requests                                                |  |
|  | - Tracks global cluster CPU & RAM inventory via Node Manager reports              |  |
|  +-----------------------------------------+-----------------------------------------+  |
|                                            │ (Instructs to launch YARN Containers)      |
|                      ┌─────────────────────┴─────────────────────┐                      |
|                      ▼                                           ▼                      |
|  [ Worker / Slave Node 1 (EC2) ]             [ Worker / Slave Node 2 (EC2) ]            |
|  +-----------------------------------+       +-----------------------------------+      |
|  | YARN Node Manager (Local Agent)   |       | YARN Node Manager (Local Agent)   |      |
|  | - Monitors local server CPU/RAM   |       | - Monitors local server CPU/RAM   |      |
|  | - Kills containers exceeding RAM! |       | - Reports capacity to Resource Mgr|      |
|  |                                   |       |                                   |      |
|  |  +-----------------------------+  |       |  +-----------------------------+  |      |
|  |  | YARN Container (2 vCPU, 2GB)|  |       |  | YARN Container (2 vCPU, 4GB)|  |      |
|  |  |   [ Spark Driver Process ]  |  |       |  |  [ Spark Executor 1 Process]|  |      |
|  |  +-----------------------------+  |       |  +-----------------------------+  |      |
|  +-----------------------------------+       +-----------------------------------+      |
+-----------------------------------------------------------------------------------------+
```

### Key YARN Mechanics:
* **Resource Manager (Master):** Runs on the primary/master node. Acts as the central scheduler that receives incoming `spark-submit` resource requests.
* **Node Managers (Slaves):** Lightweight agents installed on every worker server. They continuously report available local CPU and RAM to the Resource Manager and enforce container resource limits (if an Executor tries to consume more RAM than allocated, the Node Manager immediately kills it with an OOM error).
* **YARN Containers (Not Docker Containers!):** A YARN Container is **not** a Docker container. It is an isolated, logical resource reservation box (e.g., *2 CPU cores + 4 GB RAM*) carved out by a Node Manager to host either a Spark Driver or a Spark Executor process.

---

## Part 4: Step-by-Step `spark-submit` Execution Lifecycle

When an engineer or an Airflow DAG executes `spark-submit --master yarn --deploy-mode cluster --num-executors 2 --executor-cores 2 --executor-memory 4g process_s3_data.py`, the following exact sequence unfolds:

```
[ Engineer / Airflow ]
        │
        ▼ (1) Submits PySpark app & resource specs
[ YARN Resource Manager ]
        │
        ▼ (2) Negotiates with a Node Manager to spawn Container #1
[ Spark Driver Boots Up ]
        │
        ├──────────────────────────────┐
        ▼ (3a) Requests Executors      ▼ (3b) Compiles PySpark Code
[ YARN Resource Manager ]       [ Driver Internal Optimizer ]
        │                        - Builds Lineage DAG
        ▼ (4) Spawns Containers  - Logical Plan ──► Catalyst Optimizer ──► Physical Plan
[ Spark Executors Boot Up ]      - Splits Physical Plan into parallel Tasks
        │                                      │
        ▼ (5) Register & Heartbeat             ▼ (6) Dispatches Tasks to Executors
[ Executors Ready ] ◄──────────────────────────┘
        │
        ▼ (7) Executors read S3 data into RAM, process in parallel & write back to S3
[ Job Complete ] ──► Executors shut down & YARN releases containers!
```

1. **Job Submission:** `spark-submit` sends the Python script and resource flags to the **YARN Resource Manager**.
2. **Driver Provisioning:** The Resource Manager selects a Node Manager with sufficient capacity and launches a YARN container hosting the **Spark Driver**.
3. **Parallel Initialization:** Once booted, the Spark Driver simultaneously:
   * Contacts the Resource Manager to request YARN containers for the **Executors** (`--num-executors 2`).
   * Analyzes your PySpark script, builds the **Lineage DAG**, optimizes it through the **Catalyst Optimizer** (Unresolved Logical Plan $\rightarrow$ Logical Plan $\rightarrow$ Optimized Logical Plan $\rightarrow$ Physical Plan), and breaks the physical plan into granular **Tasks**.
4. **Executor Registration:** As Node Managers boot up the Executor containers, each Executor reaches back directly to the Spark Driver to register itself and announce readiness for work.
5. **Task Dispatch & Execution:** The Driver's Task Scheduler distributes tasks across the Executor CPU cores. Executors fetch data from S3 into RAM, execute transformations in parallel, and write final Parquet outputs back to S3.
6. **Teardown:** Once all tasks succeed, the Driver notifies the Resource Manager, and YARN terminates the containers to free cluster capacity.

---

## Part 5: Cluster Heartbeat & Failure Recovery Workflows

Mayowa highlighted how distributed clusters detect silent crashes and self-heal through continuous **Heartbeat Signals**:

```
  [ Node Managers ] ──(Reports node health & free CPU/RAM)──► [ YARN Resource Manager ]
                                                                         ▲
  [ Spark Driver  ] ──(Heartbeats: "Driver is alive!")───────────────────┘
         ▲
         │
  [ Spark Executors ] ──(Heartbeats: "Executor alive & task progress")───┘
```

| Failure Scenario | How the Cluster Detects It | Automated Recovery Behavior |
| :--- | :--- | :--- |
| **An Executor Crashes** (e.g., OOM kill or hardware glitch) | The Executor stops sending heartbeats to the **Spark Driver**. | The Driver marks the Executor dead, asks the **YARN Resource Manager** to launch a replacement Executor container, and uses its **Lineage DAG** to recompute only the lost partitions! |
| **A Worker Node Dies** (e.g., EC2 hardware failure) | The **Node Manager** stops sending heartbeats to the **YARN Resource Manager**. | The Resource Manager removes the dead node from the cluster pool and schedules replacement containers on healthy surviving nodes. |
| **The Spark Driver Crashes** | The **Spark Driver** stops sending heartbeats to the **YARN Resource Manager**. | By default (`yarn.resourcemanager.am.max-attempts = 2` or `3`), YARN kills all orphaned Executors, launches a brand-new Driver container, and restarts the Spark application from scratch. |

---

## Part 6: Deploy Modes — `client` vs. `cluster` (Critical Production Rule!)

One of the most important architectural flags in `spark-submit` is `--deploy-mode`, which dictates **where the Spark Driver process physically runs**:

```
                    [ CLIENT MODE (--deploy-mode client) ]
  [ Your Laptop / SSH Bastion ]                 [ YARN Worker Nodes ]
  +---------------------------+                 +-----------------------+
  |   Spark Driver Runs HERE! | ◄──Network───►  |  Executor 1 & 2       |
  +---------------------------+                 +-----------------------+
  ⚠️ DANGER: If your laptop sleeps, Wi-Fi drops, or SSH session closes (`Ctrl+D`),
             the Spark Driver dies immediately and kills the entire production job!

-------------------------------------------------------------------------------------------

                   [ CLUSTER MODE (--deploy-mode cluster) ]
  [ Your Laptop / Airflow ]                     [ YARN Worker Nodes ]
  +---------------------------+                 +-----------------------+
  | Submits job & disconnects |                 |  Node 1: Spark Driver |
  | (Safe to close terminal!) |                 |  Node 2: Executor 1   |
  +---------------------------+                 |  Node 3: Executor 2   |
                                                +-----------------------+
  ✅ PRODUCTION STANDARD: The Driver runs safely inside a YARN container on the cluster!
```

* **`client` Mode:** Ideal **only** for interactive development and debugging (such as Jupyter Notebooks or quick terminal tests) because driver logs stream directly to your local screen. Never use in production!
* **`cluster` Mode:** Mandatory for all scheduled production pipelines (Airflow, cron, CI/CD). Even if the orchestrator or engineer's laptop disconnects immediately after submission, the Driver continues running safely inside the cluster until completion.

> 🔗 **Official Apache Spark Docs:** [Submitting Applications (`spark-submit` & Deploy Modes)](https://spark.apache.org/docs/latest/submitting-applications.html)  
> 🔗 **Spark on YARN Docs:** [Running Spark on YARN Configuration](https://spark.apache.org/docs/latest/running-on-yarn.html)

---

## Part 7: Comprehensive Student Q&A Index

| Student | Core Question | Mayowa's Technical Clarification |
| :--- | :--- | :--- |
| **Blessed Ebosele** | *When we submit a script, does the Spark Driver ask our permission before optimizing our query?* | **No.** The Driver's Catalyst Optimizer automatically rewrites and optimizes your execution plan (e.g., pushing filters down before joins) behind the scenes without prompting for confirmation. |
| **Blessed Ebosele** | *If a worker node is overworked due to Data Skewness, can the Executor request a larger EC2 server automatically?* | **No.** Heartbeats come from the JVM processes (Executors and Node Managers), not physical hardware resizing. If an Executor exceeds its container memory allocation, the Node Manager kills it with an OOM error. |
| **Oluseyi Odude & Roqeeb Olaniran** | *Can the Spark Driver and an Executor reside on the same worker server, and what separates them?* | **Yes.** Both run inside separate, isolated **YARN Containers** on worker nodes. The Driver container runs the orchestration/planning brain, while Executor containers run data processing tasks. |
| **Suliyat Dauda** | *What if data volume fluctuates between 1 million rows and 200,000 rows? Can Spark scale Executors automatically?* | **Yes!** Spark supports **Dynamic Allocation** (`spark.dynamicAllocation.enabled=true`), which automatically spins up additional Executors during peak load and terminates idle Executors when traffic drops—similar to an AWS Auto Scaling Group. |
| **Suliyat Dauda** | *What happens if we request more Executor CPU/RAM than the cluster physically owns, versus processing a dataset larger than cluster RAM?* | **Two completely different outcomes:**<br>1. If you request *more container CPU/RAM* than the cluster possesses, YARN rejects or hangs the allocation immediately.<br>2. If your *input dataset* (e.g., 200 GB) is larger than cluster RAM (e.g., 20 GB), Spark processes it smoothly in chunks using partitions and graceful **spill-to-disk**! |
| **Godwin Nosa** | *When Executors finish a Spark job, do they stay idle and waste money, or terminate immediately?* | Once the Spark application finishes (`spark.stop()`), YARN **immediately terminates all Executor and Driver containers**, releasing those CPU and RAM resources back to the cluster. (Note: On AWS EMR, the underlying EC2 instances continue billing until you terminate the EMR cluster itself). |
| **Yetunde Afolabi** | *Why does the Spark Driver run on only one node instead of all three nodes?* | The Driver is the central single coordinator (like the Leader Node in Redshift) responsible for maintaining the master Lineage DAG and scheduling tasks; therefore, every Spark application has **exactly one active Driver**. |
| **Dennis Humes** | *Does this architecture apply to YARN or Kubernetes?* | The core Spark components (**Driver** and **Executors**) are identical in both! Only the underlying Cluster Manager changes—YARN launches YARN containers via Node Managers, whereas Kubernetes launches Driver and Executor Pods via the Kubelet. |

---

## Part 8: Hands-On Labs & Live Demos — Step-by-Step Execution Guide

This section provides complete, reproducible guides for both Spark demonstrations conducted during the session.

### Demo 1: Running a Local Dockerized PySpark Environment (Jupyter Notebook)

#### Objective:
Launch a local containerized Spark environment using Docker Compose, execute a PySpark script in Jupyter Notebook that reads raw order records from Amazon S3, filters paid transactions, aggregates revenue by region, and writes Parquet output back to S3.

#### Step-by-Step Instructions:

1. **Clone the Bootcamp Spark Development Environment:**
   ```bash
   git clone https://github.com/coredataengineers/spark-dev-environment.git
   cd spark-dev-environment
   ```

2. **Spin Up the Local Spark Containers:**
   ```bash
   docker compose up -d
   docker ps   # Confirm spark-master, spark-worker, and jupyter-notebook containers are running
   ```

3. **Open Jupyter Notebook:**
   * Open your browser and navigate to `http://localhost:8888`.
   * Create a new Python 3 notebook.

4. **Execute the PySpark Aggregation Pipeline:**
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import col, sum as _sum

   # 1. Initialize SparkSession (Instantiates the Spark Driver)
   spark = (
       SparkSession.builder
       .appName("CDE_Orders_Aggregation_Demo")
       .config("spark.hadoop.fs.s3a.access.key", "<YOUR-AWS-ACCESS-KEY>")
       .config("spark.hadoop.fs.s3a.secret.key", "<YOUR-AWS-SECRET-KEY>")
       .config("spark.hadoop.fs.s3a.endpoint", "s3.eu-north-1.amazonaws.com")
       .getOrCreate()
   )

   # 2. Read Raw Data from Amazon S3
   input_path = "s3a://cdebytes-data-lake/raw/orders.csv"
   df = spark.read.option("header", "true").option("inferSchema", "true").csv(input_path)

   # 3. Narrow Transformation: Filter for PAID orders only
   paid_df = df.filter(col("status") == "PAID")

   # 4. Wide Transformation (Triggers Shuffle): Group by Region & Sum Revenue
   revenue_by_region_df = (
       paid_df.groupBy("region")
       .agg(_sum("amount").alias("total_revenue"))
   )

   # 5. Preview Results & Write Output Parquet to S3
   revenue_by_region_df.show()

   output_path = "s3a://cdebytes-data-lake/processed/revenue_by_region/"
   revenue_by_region_df.write.mode("overwrite").parquet(output_path)

   # 6. Stop SparkSession to release resources
   spark.stop()
   ```

---

### Demo 2: Submitting a Production PySpark Job to a 3-Node Amazon EMR Cluster (`spark-submit`)

#### Objective:
Provision a multi-node **Amazon EMR** cluster (1 Primary Node + 2 Core Worker Nodes), SSH into the Primary Node where the YARN Resource Manager runs, submit a PySpark script with explicit Executor CPU/RAM allocations via `spark-submit`, and test resource over-allocation errors.

#### Step-by-Step Instructions:

##### Step 1: Launch a 3-Node Spark Cluster on Amazon EMR
1. Log in to the **AWS Management Console** $\rightarrow$ Search for **EMR** $\rightarrow$ Click **Clusters** $\rightarrow$ Click **Create cluster**.
2. **Name:** `cde-spark-prod-cluster`.
3. **Application bundle:** Select **Spark** (includes Hadoop YARN and Spark).
4. **Cluster configuration (Nodes):**
   * **Primary node (Master):** `1` instance of `c5.xlarge` (hosts the YARN Resource Manager).
   * **Core nodes (Workers):** `2` instances of `c5.xlarge` (hosts Node Managers and Spark Executors).
5. **Networking & Security:**
   * Select your VPC and a public subnet.
   * Select your EC2 SSH Key Pair (`cde_demo_keypair`) so you can SSH into the Primary Node.
   * Ensure the Primary Node Security Group allows inbound SSH (`Port 22`) from **My IP**.
6. Click **Create cluster** and wait \~6–8 minutes until status changes to **Waiting**.

##### Step 2: SSH into the Primary Node & Create the PySpark Script
1. Copy the **Primary node public DNS** from the EMR summary page and connect via SSH:
   ```bash
   ssh -i ~/Downloads/cde_demo_keypair.pem hadoop@<EMR-PRIMARY-PUBLIC-DNS>
   ```
2. Create a file named `process_s3_data.py`:
   ```bash
   nano process_s3_data.py
   ```
3. Paste the production PySpark script (no hardcoded AWS keys needed because EMR attaches an EC2 IAM Instance Profile automatically!):
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import col, sum as _sum

   spark = SparkSession.builder.appName("EMR_S3_Orders_Pipeline").getOrCreate()

   df = spark.read.option("header", "true").option("inferSchema", "true").csv(
       "s3://cdebytes-data-lake/raw/orders.csv"
   )

   result_df = (
       df.filter(col("status") != "CANCELLED")
       .groupBy("region")
       .agg(_sum("amount").alias("total_revenue"))
   )

   result_df.write.mode("overwrite").parquet(
       "s3://cdebytes-data-lake/processed/emr_revenue_by_region/"
   )

   spark.stop()
   ```
   Save and exit (`Ctrl + O`, `Enter`, `Ctrl + X`).

##### Step 3: Execute `spark-submit` with Explicit Executor Sizing
Run the job on YARN, explicitly requesting `2` Executors with `2` CPU cores and `2 GB` RAM each:
```bash
spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --num-executors 2 \
  --executor-cores 2 \
  --executor-memory 2g \
  --driver-memory 2g \
  process_s3_data.py
```
* **Observation:** Watch the YARN application logs track the lifecycle (`ACCEPTED` $\rightarrow$ `RUNNING` $\rightarrow$ `FINISHED`). Verify in the S3 Console that the output `.parquet` files were written cleanly!

##### Step 4: Simulate Resource Over-Allocation Failure (Bonus Experiment)
Attempt to request `4` Executors with `8` CPU cores and `8 GB` RAM each—exceeding the physical capacity of your two `c5.xlarge` worker nodes:
```bash
spark-submit \
  --master yarn \
  --deploy-mode client \
  --num-executors 4 \
  --executor-cores 8 \
  --executor-memory 8g \
  process_s3_data.py
```
* **Expected Output:** YARN immediately flags that the requested container memory/vCores exceed the maximum node allocation (`Required executor memory is above the max threshold`), demonstrating why cluster sizing must match underlying EC2 hardware specs.

---

## Part 9: Infrastructure Teardown & Clean-Up Checklist

Amazon EMR clusters bill continuously per hour for all 3 EC2 nodes even while sitting in `Waiting` state:

1. **Terminate the Amazon EMR Cluster Immediately:**
   * Open the **Amazon EMR Console** $\rightarrow$ **Clusters** $\rightarrow$ Select `cde-spark-prod-cluster`.
   * Click **Terminate** $\rightarrow$ Confirm termination.
   * Verify in the **EC2 Console** that all 3 cluster instances transition to `Terminated`.
2. **Stop Local Docker Containers:**
   ```bash
   docker compose down
   ```