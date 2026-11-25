# CDE Bootcamp 3.0: Production Spark Big Data Architecture — Ephemeral EMR Clusters, Airflow Orchestration & CI/CD Pipelines

> *"Keeping a 24/7 Spark cluster running when no jobs are executing is pure financial waste. In real production data platforms, you write PySpark code locally, lint and sync it to S3 automatically via CI/CD, and let Apache Airflow spin up an ephemeral Amazon EMR cluster on a schedule—processing terabytes of data in minutes before terminating the entire cluster to zero out your bill."*
>
> — **Mayowa Akinyele**

**Date:** November 25, 2026

**Duration:** 77 Minutes

**Lead Instructor:** Mayowa Akinyele (Opening Quiz by Ayodeji Ajayi; Pair-Engineering Collaboration with Taofeecoh Adesanu)

**Curriculum Module:** 11 Distributed Data Processing (Finale) — End-to-End Production Spark Platform Architecture: Ephemeral (Transient) Amazon EMR Clusters, EMR Node Roles (`Primary`, `Core`, `Task`), Spot vs. On-Demand FinOps Rules, Apache Airflow EMR Orchestration, CI/CD Linting (`Ruff`) & S3 Deployment, and Slido Hall of Fame

## Executive Overview & Class Atmosphere

As the celebratory finale of Mayowa Akinyele’s instructional modules (preceding Friday's **Apache Kafka** deep-dive, Saturday's **CV Review**, and the cohort **Capstone Project**), this session united every single technology taught across the bootcamp—**Git, GitHub Actions CI/CD, Ruff Linting, Amazon S3, IAM Roles, VPC Networking, EC2 Spot Economics, Apache Airflow, and Apache Spark**—into one cohesive, real-world production architecture.

Mayowa walked through an active production big data project built at Core Data Engineers designed to process **~1 Terabyte** of shipment data without incurring massive 24/7 cloud server bills. Before the session, Mayowa and student **Taofeecoh Adesanu** spent four hours pair-engineering and debugging permissions, EMR configurations, and Airflow sensors until the entire automated pipeline ran seamlessly end-to-end.

The evening concluded with the official **CDE Bootcamp 3.0 Slido Leaderboard Hall of Fame**, celebrating the most consistent quiz champions across the cloud, Terraform, and Spark modules.

## Part 1: Speed-Round Warm-Up Quiz — Spark & Partitioning Mastery

*(Facilitated by Ayodeji Ajayi)*

The session kicked off with a rapid-fire speed quiz consolidating Monday’s Spark join and partitioning internals:

1. **Broadcast Join Table Sizing:**

   * The **smaller lookup table** (default $\le 10\text{ MB}$) is loaded into Driver memory and broadcasted across all Executors—eliminating network shuffling of the massive fact table.

2. **Spark Actions vs. Transformations:**

   * `.show()` is an **Action** that triggers immediate cluster execution, whereas `.groupBy()` and `.withColumnRenamed()` are lazy **Transformations**.

3. **Narrow vs. Wide Transformations:**

   * `.filter()` is a **Narrow Transformation** (executes locally in RAM with zero network shuffle), whereas `.join()` and `.groupBy()` are **Wide Transformations**.

4. **Default Spark Partition Size:**

   * $128\text{ MB}$ (`spark.sql.files.maxPartitionBytes`), inherited from Hadoop HDFS block sizing.

5. **The Golden Execution Law:**

   * **1 Task $\leftrightarrow$ 1 CPU Core $\leftrightarrow$ 1 Partition** (at a time).

6. **What Triggers Jobs vs. Shuffles:**

   * Calling an **Action** triggers a **Spark Job**; executing a **Wide Transformation** triggers a **Network Shuffle** (and splits a Job into Stages).

7. **Production Deploy Mode:**

   * **`cluster` mode** (`--deploy-mode cluster`) is mandatory in production so the Spark Driver runs safely inside the cluster rather than on an engineer's laptop/SSH session.

   * *Quiz Winner:* **Olugbade Waziri** 🏆 *(holding 1st place from start to finish!)*

## Part 2: The End-to-End Production Spark Platform Architecture

Mayowa unveiled the complete architectural blueprint showing how raw PySpark code travels from an engineer's laptop to an automated, self-destructing **Amazon EMR** cluster:

```
+-----------------------------------------------------------------------------------------+
|                   END-TO-END PRODUCTION SPARK PLATFORM ARCHITECTURE                     |
|                                                                                         |
|  [ 1. Engineer Laptop (VS Code) ]                                                       |
|     - Writes PySpark script (`spark_job.py`) + Airflow DAG (`emr_dag.py`)               |
|     - Tests on small subset via Dev EMR / local Docker Spark                            |
|                │                                                                        |
|                ▼ (git push & Open Pull Request)                                         |
|  [ 2. GitHub Repository & CI/CD Pipeline ]                                              |
|     - CI Workflow: Runs `ruff check` (Python Linter) on PR                              |
|     - CD Workflow: Upon merge to `main`, syncs `spark_job.py` to Amazon S3!             |
|                │                                                                        |
|                ▼ (Uploads Script to S3 Artifacts Bucket)                                |
|  [ 3. Amazon S3 Storage Layer ]                                                         |
|     - `s3://cde-spark-scripts/artifacts/jobs/spark_job.py` (Code Artifact)              |
|     - `s3://cde-apex-data/raw/shipments/` (1 TB Raw Input Data)                         |
|     - `s3://cde-emr-logs/` (Cluster & Driver Diagnostic Logs)                           |
|                                           ▲                                             |
|                                           │ (Reads Data & Writes Aggregated Parquet)    |
|  [ 4. Apache Airflow Orchestrator ] ──────┼──────────────────────────────────────────┐  |
|     (Running on EKS / EC2 + RDS Postgres) │                                          │  |
|     - Step 1: `EmrCreateJobFlowOperator` ─┼─► Spins up Ephemeral EMR Cluster         │  |
|     - Step 2: `EmrAddStepsOperator` ──────┼─► Submits `spark-submit` Job Step        │  |
|     - Step 3: `EmrStepSensor` ────────────┼─► Polls every 30s (Reschedule mode)      │  |
|     - Step 4: `EmrTerminateJobFlowOperator`─► Destroys EMR Cluster immediately!      │  |
|                                           │                                          │  |
|                                           ▼                                          │  |
|  [ 5. Ephemeral Amazon EMR Cluster (EC2 + YARN + Spark) ] ───────────────────────────┘  |
|     - Primary Node (On-Demand): Hosts YARN Resource Manager                             |
|     - Core Node    (On-Demand): Hosts HDFS + Spark Driver (`cluster` mode)              |
|     - Task Nodes   (Spot):      Hosts Spark Executors (Parallel Workers)                |
+-----------------------------------------------------------------------------------------+

```

### Why Use an Ephemeral (Transient) Spark Cluster?

* **The Long-Running Cluster Trap:** Leaving a multi-node Spark cluster running 24/7 when daily batch jobs only take 10 minutes each morning wastes 99% of your compute budget.

* **The Ephemeral Cluster Solution:** Airflow dynamically provisions the EMR cluster on schedule (e.g., 9:00 AM daily), submits the `spark-submit` step, waits for completion, and **immediately terminates all EC2 nodes**—billing you only for the exact ~6 minutes of runtime!

## Part 3: Amazon EMR Node Architecture & FinOps Rules

Unlike a generic EC2 setup, **Amazon EMR (Elastic MapReduce)** divides cluster servers into three specialized node groups. Mixing up **Spot** and **On-Demand** instances across these three node groups can cause catastrophic job failures:

| EMR Node Type | Count | Primary Responsibilities | Purchasing Rule (FinOps) | 
| ----- | ----- | ----- | ----- | 
| **Primary Node** *(Master)* | Strictly `1` | Hosts the **YARN Resource Manager** and master cluster daemons. | **MUST be On-Demand.** If AWS reclaims the Primary Node, the entire cluster collapses immediately. | 
| **Core Node** | `1` or more | Hosts **HDFS** (cluster storage) and runs the **Spark Driver** (in `cluster` deploy mode) plus Executors. | **MUST be On-Demand.** If AWS reclaims a Core Node hosting the Spark Driver, the Driver's Lineage DAG is wiped and the job restarts from zero. | 
| **Task Nodes** | `0` to $N$ | Pure compute workers running **Spark Executors** only (no HDFS storage). | **Use SPOT Instances!** Saves 60%–80% on compute. If AWS reclaims a Task Node, the Driver detects the missed heartbeat and re-schedules lost tasks on surviving nodes! | 

### Storage & Networking Checklist for EMR:

* **EBS Storage Sizing on Core Nodes:** During heavy `SortMergeJoin` or wide aggregations on ~1 TB datasets, Spark spills intermediate shuffle files to local disk. Always attach sufficient EBS storage (e.g., 100 GB–500 GB) to Core/Task nodes beyond the 64 GB default root volume.

* **S3 Log Bucket:** Configure `LogUri` (`s3://cde-emr-logs/`) so EMR persists YARN Resource Manager, Driver, and Executor logs to S3 for debugging even after the cluster terminates.

* **IAM Roles:** EMR requires two distinct IAM roles: an **EMR Service Role** (allowing EMR to provision EC2 instances) and an **EC2 Instance Profile** (allowing Spark Executors to read/write S3 buckets).

> 🔗 **Official AWS EMR Docs:** [Amazon EMR Cluster Architecture (Primary, Core, and Task Nodes)](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-master-core-task-nodes.html)

## Part 4: Automated CI/CD Pipeline (`Ruff` Linter + S3 Sync)

In production, engineers never manually upload `.py` scripts to S3 via the AWS Console:

1. **Continuous Integration (`CI` — Pull Request Gate):**

   * Whenever an engineer opens a Pull Request modifying Python files, GitHub Actions triggers **Ruff** (`ruff check`), an ultra-fast Python linter, to catch syntax errors, unused imports, and formatting violations before merging.

2. **Continuous Deployment (`CD` — Automated S3 Deployment):**

   * Once peer-reviewed and merged into `main`, the CD pipeline authenticates with AWS (using **OpenID Connect / OIDC** in enterprise setups, or GitHub Actions Secrets `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) and runs `aws s3 sync` to overwrite the latest `spark_job.py` inside `s3://cde-spark-scripts/artifacts/jobs/`.

   * The next time Airflow spins up an EMR cluster, it automatically pulls the newly deployed script from S3!

## Part 5: Apache Airflow EMR Orchestration Operators

Mayowa walked through the four core Airflow operators from the `apache-airflow-providers-amazon` package that orchestrate the entire ephemeral cluster lifecycle:

```
[ create_emr_cluster ] ──► [ add_spark_step ] ──► [ wait_for_spark_step ] ──► [ terminate_emr_cluster ]
(EmrCreateJobFlowOperator) (EmrAddStepsOperator)     (EmrStepSensor:             (EmrTerminateJobFlowOperator:
                                                     mode="reschedule")           trigger_rule="all_done")

```

1. **`EmrCreateJobFlowOperator`:** Calls the AWS EMR API to provision the Primary, Core, and Task EC2 instances inside your VPC subnet and returns the `job_flow_id` (Cluster ID) via XCom.

2. **`EmrAddStepsOperator`:** Submits the `spark-submit --master yarn --deploy-mode cluster ... s3://.../spark_job.py` command as an EMR Step.

3. **`EmrStepSensor`:** Polls the EMR API every `30` seconds (`poke_interval=30`) using **`mode="reschedule"`** (releasing the Airflow worker slot between checks so it doesn't block other DAGs) until the Spark step finishes.

4. **`EmrTerminateJobFlowOperator`:** Shuts down and terminates the EMR cluster immediately upon step completion. *(Pro Tip: Set `trigger_rule="all_done"` so Airflow terminates the cluster even if the Spark job fails, preventing runaway billing!)*

> 🔗 **Official Airflow AWS Provider Docs:** [Apache Airflow Amazon EMR Operators Guide](https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/operators/emr/emr.html)

## Part 6: Crucial Homework — Spark Memory Management

Mayowa emphasized one vital topic that students must research independently before interviewing for senior Spark roles: **Spark Executor Memory Management**.

When you allocate `--executor-memory 4g` (`4 GB`) to a Spark Executor, **you do NOT get all 4 GB for processing your DataFrame!** Spark divides that memory into strict internal regions:

```
+-----------------------------------------------------------------------------------------+
|                   SPARK EXECUTOR MEMORY LAYOUT (--executor-memory 4g)                   |
|                                                                                         |
|  1. Reserved Memory (300 MB hardcoded)    --> Reserved for Spark internal engine safety  |
|  2. User Memory (40% of remaining)        --> Stores user data structures & UDF objects |
|  3. Spark Unified Memory (60% of remaining)                                             |
|     ├── Storage Memory (50% default)      --> Holds cached DataFrames (`.cache()`)      |
|     └── Execution Memory (50% default)    --> Holds active Joins, Sorts & Aggregations  |
+-----------------------------------------------------------------------------------------+

```

* *Result:* Out of a `4 GB` (`4096 MB`) allocation, only **~1.1 GB** is initially dedicated to Execution Memory (though Unified Memory allows Execution and Storage to borrow unused space dynamically). Understanding this math prevents unexpected Out-Of-Memory (OOM) crashes!

> 🔗 **Official Spark Memory Tuning Docs:** [Apache Spark Memory Management Overview](https://spark.apache.org/docs/latest/tuning.html#memory-management-overview)

## Part 7: CDE Bootcamp 3.0 Slido Leaderboard Hall of Fame

At the close of the module, Mayowa and Ayodeji recognized the top Slido quiz champions across the entire Cloud, Terraform, and Spark curriculum:

| Rank | Champion | Total Quiz Wins | 
| ----- | ----- | ----- | 
| 🥇 **1st Place** | **Olawale Akinyele** | **8 Wins** 🏆 *(Undisputed Cohort Scholar)* | 
| 🥈 **2nd Place** | **Big Osas (Osakpolor Ogieriakhi)** | **4 Wins** | 
| 🥉 **3rd Place (Tie)** | **Uche Nmaju** & **YT** | **3 Wins Each** | 
| 🏅 **4th Place** | **Lorreta Anyika** | **2 Wins** | 
| ⭐ **1-Time Winners** | **Alani Sodiq**, **Judith Ani**, **Zainab Olamiji**, **Oluwabukunmi Akinmi**, **Adeyinka**, **Jehovah AI**, **Olugbade Waziri** | **1 Win Each** | 

## Part 8: Hands-On Lab & Demo Guide — Reproducing the Ephemeral EMR Pipeline

Mayowa made the complete repository public for all students to clone, inspect, and run:  
🔗 **Public GitHub Repository:** [coredataengineers/ephemeral-spark-cluster-bootstrap](https://github.com/coredataengineers/ephemeral-spark-cluster-bootstrap)

### Demo Objective:

Clone the bootcamp ephemeral Spark repository, configure GitHub Actions CI/CD secrets to deploy your PySpark job to S3, launch Airflow locally via Docker Compose, and trigger an automated DAG that spins up a 3-node Amazon EMR cluster, executes a PySpark aggregation on S3 data, and terminates the cluster automatically.

### Step-by-Step Instructions:

#### Step 1: Clone the Public Repository & Inspect Structure

```
git clone https://github.com/coredataengineers/ephemeral-spark-cluster-bootstrap.git
cd ephemeral-spark-cluster-bootstrap
ls -la

```

* **Key Directories & Files:**

  * `spark_jobs/process_shipments.py` — Production PySpark script reading raw S3 Parquet data and writing aggregated Parquet outputs.

  * `dags/emr_ephemeral_dag.py` — Airflow DAG orchestrating cluster creation, step submission, sensor polling, and teardown.

  * `dags/emr_config.py` — EMR cluster hardware specs (Primary, Core, Task nodes, VPC subnet ID, S3 log URI, and `spark-submit` arguments).

  * `.github/workflows/` — CI (`ruff` linter) and CD (`aws s3 sync`) GitHub Actions YAML pipelines.

  * `docker-compose.yml` — Local containerized Airflow environment.

#### Step 2: Prepare S3 Buckets & AWS IAM Prerequisites

1. **Create Required S3 Buckets in Your AWS Region (e.g., `eu-north-1`):**

   * `cde-spark-scripts-xxxx` (for storing deployed `.py` job artifacts).

   * `cde-emr-logs-xxxx` (for storing EMR cluster and Spark execution logs).

   * Ensure your input dataset bucket contains your raw shipment Parquet files.

2. **Verify Default EMR IAM Roles Exist:**

   * If you have never launched an EMR cluster in your AWS account before, run this one-time AWS CLI command to generate the standard `EMR_DefaultRole` and `EMR_EC2_DefaultRole`:

     ```
     aws emr create-default-roles
     
     ```

3. **Note Your VPC Public Subnet ID:**

   * Copy the Subnet ID (e.g., `subnet-0abc12345def67890`) from the **VPC Console** where your EMR nodes will launch.

#### Step 3: Configure CI/CD Secrets in Your Forked GitHub Repository

1. Fork `ephemeral-spark-cluster-bootstrap` to your personal GitHub account.

2. Navigate to **Settings** $\rightarrow$ **Secrets and variables** $\rightarrow$ **Actions** $\rightarrow$ Click **New repository secret**:

   * Add `AWS_ACCESS_KEY_ID`

   * Add `AWS_SECRET_ACCESS_KEY`

   * Add `S3_ARTIFACTS_BUCKET` (your `cde-spark-scripts-xxxx` bucket name)

3. Push a minor edit on a feature branch, open a Pull Request to verify **Ruff CI Linting** passes, and merge into `main` to trigger the **CD workflow**—confirming `process_shipments.py` uploads automatically to `s3://cde-spark-scripts-xxxx/artifacts/jobs/`.

#### Step 4: Configure `emr_config.py` & Launch Local Airflow

1. Open `dags/emr_config.py` and update:

   * `LogUri`: `"s3://cde-emr-logs-xxxx/"`

   * `Ec2SubnetId`: `"subnet-0abc12345def67890"`

   * `Args` inside `HadoopJarStep`: Update the S3 paths pointing to your `process_shipments.py` script and input/output data buckets.

2. Start Airflow via Docker Compose:

   ```
   docker compose up -d
   
   ```

3. Open the **Airflow Web UI** in your browser at `http://localhost:8080` and configure your `aws_default` connection under **Admin** $\rightarrow$ **Connections** with your AWS Region and credentials.

#### Step 5: Trigger the Ephemeral EMR Pipeline & Monitor Execution

1. On the Airflow dashboard, unpause and trigger `emr_ephemeral_spark_pipeline`.

2. **Track Live Execution Across 3 Consoles:**

   * **Airflow Graph View:** Watch `create_emr_cluster` turn green $\rightarrow$ `add_spark_step` turn green $\rightarrow$ `wait_for_spark_step` enter `up_for_reschedule` (polling every 30s).

   * **Amazon EMR Console:** Watch your cluster transition from `Starting` $\rightarrow$ `Bootstrapping` $\rightarrow$ `Running` (~5 minutes).

   * **EC2 Console:** Observe 3 EC2 instances (1 Primary + 1 Core + 1 Task node) spin up, execute the ~1-minute Spark job, and automatically transition to `Terminated` once `terminate_emr_cluster` completes!

3. **Verify Output Data in S3:**

   * Open your output S3 folder and confirm the partitioned `.parquet` files have been generated cleanly.

#### Step 6: Local Clean-Up

```
docker compose down

```

## Useful Spark Ariticles

🔗 [Before you learn spark unedrstand mapreduce](https://medium.com/towards-data-engineering/before-you-learn-apache-spark-understand-mapreduce-here-it-is-one-phase-at-a-time-f9f3349deac1)
🔗 [CLuster Overview](https://spark.apache.org/docs/latest/cluster-overview.html)
🔗 [Apache Spark](https://www.geeksforgeeks.org/devops/apache-spark/)
🔗 [Spark Theory](https://www.sparkplayground.com/tutorials/spark-theory/jobs-stages-tasks)

*(Verify in the AWS EMR and EC2 consoles that your ephemeral cluster terminated automatically and zero active instances remain running).*