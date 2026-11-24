# CDE Bootcamp 3.0: Apache Spark Join Execution Strategies & Partitioning Internals

> *"Knowing how to write `df1.join(df2, 'user_id')` in PySpark is just syntax. Senior engineers know when Spark defaults to a disk-spilling `SortMergeJoin` for two massive tables versus when to inject a `broadcast()` hint to eliminate network shuffling—and they live by the Golden Execution Law: 1 Task, 1 CPU Core, 1 Partition."*
>
> — **Mayowa Akinyele**

**Date:** November 23, 2026  
**Duration:** 94 Minutes  
**Lead Instructor:** Mayowa Akinyele (Opening Quiz by Ayodeji Ajayi / Abdulhakeem Salaudeen)  
**Curriculum Module:** 11 Distributed Data Processing — Apache Spark Join Physical Execution Strategies (`SortMergeJoin` vs. `BroadcastHashJoin`), Spark Partitioning Internals ($128\text{ MB}$ Partition Sizing & `openCostInBytes`), Hive-Style Storage Partitioning vs. Spark Compute Partitions, and the `1 Task : 1 Core : 1 Partition` Law

---

## Executive Overview & Class Atmosphere

Following Saturday's deep dive into lazy evaluation and Catalyst `.explain()` execution plans, this Monday night session tackled two of the most critical performance bottlenecks in distributed data engineering: **Physical Join Execution Strategies** and **Spark Partitioning Internals**.

Mayowa opened with a quick-fire recap of the Spark lifecycle (from PySpark script submission $\rightarrow$ Driver Lineage DAG $\rightarrow$ Catalyst Optimizer $\rightarrow$ Physical Plan $\rightarrow$ Executor Tasks) before diving into why joining two large datasets triggers expensive network shuffling and disk spills, and how **Broadcast Joins** rescue performance when joining a massive fact table against a small lookup table.

In the second half of the session, Mayowa demystified **Spark Partitions** using a live **3.4 GB Amazon S3 Parquet dataset (162 million rows)**—demonstrating mathematically why Spark divided 3.4 GB into **30 partitions** (factoring in the $128\text{ MB}$ default partition size plus the $4\text{ MB}$ `openCostInBytes` file-opening overhead) and proving visually in the **Spark Web UI** how **2 CPU cores process 30 tasks strictly 2 at a time**.

---

## Part 1: Warm-Up Quiz — Catalyst Execution Plans Recap

*(Facilitated by Ayodeji Ajayi / Abdulhakeem Salaudeen)*

The session opened with an interactive Slido quiz reinforcing Saturday's `.explain()` execution plan concepts:

1. **Reading a Spark Physical Plan Tree:**
   * Always read the operators inside an execution plan **from Bottom to Top**—starting at the leaf data scan (`FileScan` / `LogicalRDD`) at the bottom and tracing transformations upward toward the final `Project` or `HashAggregate` at the top.
   * *Quiz Winner:* **Olawale Akinyele** 🏆 *(securing his 4th consecutive quiz victory!)*

---

## Part 2: Spark Physical Join Execution Strategies

When you write `df1.join(df2, "user_id", "inner")` in PySpark, you are only specifying the *logical* join type (`inner`, `left`, `right`, `full`, `cross`). Behind the scenes, the Spark Driver's **Catalyst Optimizer** must choose a **Physical Join Execution Strategy** to execute that join across distributed worker nodes.

Mayowa unpacked the two primary physical join strategies in Spark:

```
+-----------------------------------------------------------------------------------------+
|                 SPARK PHYSICAL JOIN EXECUTION STRATEGIES COMPARISON                     |
+-------------------------+-------------------------------+-------------------------------+
| Dimension               | SortMergeJoin (SMJ)           | BroadcastHashJoin (BHJ)       |
+-------------------------+-------------------------------+-------------------------------+
| Dataset Size Profile    | Two LARGE tables              | One LARGE table + One SMALL   |
|                         | (e.g., 700 GB + 450 GB)       | lookup table (Default <= 10MB)|
| Default Behavior        | Spark's DEFAULT join strategy | Auto-triggered if small table |
|                         | when both tables are large.   | <= 10 MB, or forced via hint. |
| Network Shuffle?        | YES (Expensive! Both tables   | NO Shuffle on the big table!  |
|                         | are hashed & shuffled by key).| Small table copied to nodes.  |
| Disk Spill Safety       | Gracefully spills sorted runs | Must fit completely inside    |
|                         | to disk to prevent OOM crash. | Driver AND Executor RAM!      |
| Primary Risk            | Slower due to network shuffle | Driver / Executor Out-Of-     |
|                         | and disk sorting overhead.    | Memory (OOM) if abused!       |
+-------------------------+-------------------------------+-------------------------------+
```

### 1. SortMergeJoin (`SMJ`) — The Heavy-Duty Default for Two Big Tables

```
[ Large Table A: Users (700 GB) ]            [ Large Table B: Orders (450 GB) ]
               │                                            │
               ▼ (Step 1: Hash & Network Shuffle by `user_id`)
        [ Partition 1: user_id = 101 ]       [ Partition 2: user_id = 102 ]
               │                                            │
               ▼ (Step 2: Sort keys locally — Spills to Disk if RAM fills!)
        [ Sorted Users + Sorted Orders ]     [ Sorted Users + Sorted Orders ]
               │                                            │
               ▼ (Step 3: Merge matching sorted keys linearly)
        [ Joined Output Partition 1 ]        [ Joined Output Partition 2 ]
```

* **How It Works:**
  1. **Shuffle:** Spark hashes the join key (`user_id`) across both massive tables and shuffles matching keys onto the exact same Executor partitions.
  2. **Sort:** Each Executor sorts both incoming partitions by `user_id`. If the sorted data exceeds Executor RAM, Spark **gracefully spills sorted chunks to local SSD disk** rather than crashing with an Out-Of-Memory error.
  3. **Merge:** Spark iterates linearly through both sorted streams simultaneously to emit matched rows.
* **When to Use:** Whenever joining two large tables that cannot fit into memory. Because it is Spark's built-in default, you do not need to pass any special hints.

### 2. BroadcastHashJoin (`BHJ`) — Eliminating Shuffles on Small Lookup Tables

```
[ Large Fact Table: Orders (500 GB) ]        [ Small Lookup Table: Countries (7 MB) ]
  (Stays distributed across Executors)                     │
               │                                           ▼ (1. Pulled into Driver RAM!)
               │                                [ Spark Driver Memory ]
               │                                           │
               │                                           ▼ (2. Broadcasted to all nodes!)
               ├──────────────────────────┬────────────────┴──────────────────────────┐
               ▼                          ▼                                           ▼
  [ Executor 1 (Orders Part 1) ]   [ Executor 2 (Orders Part 2) ]   [ Executor 3 (Orders Part 3) ]
  + Local Copy of Countries (7MB)  + Local Copy of Countries (7MB)  + Local Copy of Countries (7MB)
  ──► Joins locally in RAM with ZERO network shuffling of the 500 GB fact table!
```

* **How It Works:**
  1. The **Spark Driver** collects the entire small table (e.g., a 7 MB `countries` or `users` lookup table) into **its own Driver RAM**.
  2. The Driver **broadcasts** a full read-only copy of that small table over the network to **every single Executor** in the cluster.
  3. Each Executor builds an in-memory hash table of the small dataset and joins it locally against its partitions of the massive 500 GB table—**completely eliminating network shuffling of the massive fact table**.
* **Configuration & Safety Limits (`spark.sql.autoBroadcastJoinThreshold`):**
  * By default, Spark automatically uses `BroadcastHashJoin` whenever a table is **$\le 10\text{ MB}$** (`10485760` bytes).
  * Setting `spark.sql.autoBroadcastJoinThreshold = -1` disables automatic broadcast joins completely.
* **The Critical OOM Danger (Driver Memory Trap!):**
  * Engineers can force a broadcast join on larger tables using `from pyspark.sql.functions import broadcast` (`big_df.join(broadcast(small_df), "id")`).
  * **Warning:** If you force-broadcast a **2 GB** lookup table when your Spark Driver only has **2 GB of total RAM**, the Driver will immediately crash with an **`OutOfMemoryError (OOM)`**! Always verify Driver and Executor RAM capacity before broadcasting tables larger than 10 MB.

> 🔗 **Official PySpark Docs:** [PySpark `broadcast()` Function Reference](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.functions.broadcast.html)  
> 🔗 **Spark Join Performance Tuning:** [Apache Spark SQL Performance Tuning Guide](https://spark.apache.org/docs/latest/sql-performance-tuning.html)

---

## Part 3: Spark Partitioning Internals & The Golden Execution Law

How does Spark read a massive **3.4 GB** dataset from S3 into an Executor that only has **2 GB of RAM** without crashing? **Partitions.**

### 1. The Golden Execution Law: `1 Task : 1 CPU Core : 1 Partition`

Mayowa emphasized that every data engineer must memorize this fundamental hardware execution rule:

$$\Large \text{1 Task} \quad \longleftrightarrow \quad \text{1 CPU Core} \quad \longleftrightarrow \quad \text{1 Partition (at a time)}$$

```
+-----------------------------------------------------------------------------------------+
|                  SPARK EXECUTOR (2 CPU Cores, 2 GB RAM)                                 |
|                                                                                         |
|  [ CPU Core 1 ] ──Executes Task 0──► Streams Partition 0 (128 MB) in small row batches  |
|  [ CPU Core 2 ] ──Executes Task 1──► Streams Partition 1 (128 MB) in small row batches  |
|                                                                                         |
|  * Core 1 CANNOT process 2 partitions simultaneously!                                   |
|  * If a dataset has 30 Partitions, 2 Cores process 2 partitions in parallel, discard    |
|    processed rows from RAM, and repeat across 15 waves until all 30 tasks complete!     |
+-----------------------------------------------------------------------------------------+
```

* **Streaming Execution (Why Spark Doesn't OOM):** Spark does *not* load all 30 partitions into RAM at once. Each CPU core streams records from its assigned partition in tiny batches, processes them in RAM, discards them, and moves on to the next partition once finished.
* **Degree of Parallelism:** If you have **30 partitions** and **2 CPU cores**, at most **2 tasks** run in parallel at any instant. If you provision **30 CPU cores**, all **30 partitions** execute simultaneously in a single wave!

### 2. Hive-Style S3 Folder Partitioning vs. Spark Compute Partitions

Mayowa clarified a major point of confusion during the live S3 inspection:
* **Hive-Style Storage Partitioning (Physical S3 Folders):**
  * Folders structured like `s3://bucket/raw/shipments/year=2026/month=09/day=01/part-000.parquet`.
  * Used on disk/S3 to organize files by date/region so query engines can skip irrelevant folders (**Partition Pruning**).
* **Spark In-Memory Partitions (Logical Compute Chunks):**
  * When Spark reads those Parquet files from S3, Spark dynamically slices the data into logical compute chunks governed by **`spark.sql.files.maxPartitionBytes`**—which defaults to **$128\text{ MB}$** (`134217728` bytes).

### 3. The Partition Sizing Math & `openCostInBytes` ($4\text{ MB}$ Overhead)

During the live demo on a **3.4 GB** S3 dataset (comprising ~27 Parquet files of ~116 MB each):
* **Naive Calculation:**
  $$\frac{3.4\text{ GB} \times 1024\text{ MB/GB}}{128\text{ MB}} = \frac{3481.6\text{ MB}}{128\text{ MB}} \approx 27.2 \text{ Partitions}$$
* **Actual Spark Output (`df.rdd.getNumPartitions()`):** **`30 Partitions`!**
* **Why 30 instead of 27? (`spark.sql.files.openCostInBytes`):**
  * Spark includes a default file-opening overhead parameter (`spark.sql.files.openCostInBytes = 4 MB`).
  * Every time Spark opens a physical file in S3, it adds **4 MB** of estimated cost to that file's size ($116\text{ MB} + 4\text{ MB} = 120\text{ MB}$) when packing files into $128\text{ MB}$ partitions—resulting in **30 total partitions** (and therefore **30 parallel tasks** in the Spark UI!).

> 🔗 **Official PySpark Docs:** [RDD.getNumPartitions() API Reference](https://spark.apache.org/docs/latest/api/python/reference/api/pyspark.RDD.getNumPartitions.html)  
> 🔗 **Deep-Dive Resource:** [Mayowa Akinyele's LinkedIn Breakdown on Spark Shuffle Files & Partitions](https://www.linkedin.com/feed/update/urn:li:activity:7496563495409250304/)

---

## Part 4: Comprehensive Student Q&A Index

| Student | Core Question | Mayowa's Technical Clarification |
| :--- | :--- | :--- |
| **John Babatunde** | *Is `SortMergeJoin` Spark's default join strategy?* | **Yes.** Whenever both tables exceed the broadcast threshold (`10 MB` by default), Spark automatically selects `SortMergeJoin` (`SMJ`). |
| **AbdulRasaq Bilau** | *When `SortMergeJoin` shuffles rows across nodes, does it generate duplicate rows in our output?* | No—`SortMergeJoin` itself does not create duplicates. Duplicates in join output occur due to **many-to-many join keys** in the source tables (e.g., multiple orders per user), which you clean using `.dropDuplicates()` or proper join granularity. |
| **Alani Sodiq** | *In `SortMergeJoin`, what happens if the data spilled to disk exceeds the worker node's physical disk capacity?* | If intermediate shuffle/sort files exhaust 100% of the worker node's local SSD disk, the job crashes with a `No space left on device` error. Preventing this requires **Cluster Capacity Planning** (sizing EBS/instance disks properly before running terabyte-scale joins). |
| **Immaculate Okoro** | *Does each CPU core represent one partition permanently?* | No. A **Partition** is a chunk of data ($128\text{ MB}$), while a **CPU Core** is the worker slot executing a **Task** on that partition. One CPU core processes **one partition at a time**, then picks up the next waiting partition until all partitions are finished. |
| **Blessed Ebosele** | *When a CPU core finishes processing a partition and moves to the next one, does it write the output to disk?* | For **Narrow Transformations** (like `.filter()`), processed records either stream directly to the next narrow step in RAM or write to the final S3 destination. For **Wide Transformations** (like `.groupBy()`), intermediate shuffle blocks are written to local disk so downstream reducers can fetch them. |
| **Immaculate Okoro** | *Are Spark partitions pre-created inside S3 before Spark reads the files?* | **No.** S3 only holds raw Parquet/CSV files (optionally organized in Hive-style folders like `month=09/day=01/`). Spark calculates logical **$128\text{ MB}$ partitions dynamically** in memory when scanning the S3 file metadata. |
| **Roqeeb Olaniran** | *Is a Spark Task the exact same thing as a YARN Container?* | **No.** A **YARN Container** is the overarching resource box (e.g., `2 CPU cores + 4 GB RAM`) hosting a **Spark Executor** JVM process. A **Task** is an individual unit of work (processing 1 partition) scheduled onto **1 CPU core** inside that Executor container. |
| **Osakpolor Ogieriakhi (Osas)** | *Is Spark's $128\text{ MB}$ partition sizing based on the same $128\text{ MB}$ HDFS block-splitting logic from Hadoop MapReduce?* | **100% yes!** Spark inherited the $128\text{ MB}$ default partition size (`spark.sql.files.maxPartitionBytes`) directly from Hadoop HDFS's classic $128\text{ MB}$ block size because it balances parallel throughput against task scheduling overhead. |

---

## Part 5: Hands-On Labs & Live Demos — Step-by-Step Execution Guide

This section provides complete, reproducible guides for both live Jupyter Notebook and Spark UI demonstrations conducted during the session.

### Demo 1: Comparing `SortMergeJoin` vs. `BroadcastHashJoin` in `.explain()` & Spark UI

#### Objective:
Execute a join between a primary dataset and a lookup dataset—first letting Spark default to **`SortMergeJoin`** (observing the Shuffle `Exchange` in `.explain()` and the Spark UI), and then applying **`broadcast()`** to eliminate the shuffle via **`BroadcastHashJoin`**.

#### Step-by-Step Instructions:

1. **Launch Your Local Spark Jupyter Environment:**
   ```bash
   cd spark-dev-environment
   docker compose up -d
   ```
   Open Jupyter Notebook at `http://localhost:8888` and Spark UI at `http://localhost:4040`.

2. **Create Sample `users` and `orders` DataFrames:**
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import broadcast

   # Disable auto-broadcast temporarily so we can observe SortMergeJoin on small demo data!
   spark = (
       SparkSession.builder
       .appName("Join_Strategies_Demo")
       .config("spark.sql.autoBroadcastJoinThreshold", "-1")
       .getOrCreate()
   )

   users_data = [
       (101, "Temitope", "UK"),
       (102, "Habeeb", "Nigeria"),
       (103, "Mayowa", "Germany"),
       (104, "Immaculate", "Nigeria")
   ]
   orders_data = [
       (1, 101, "Coca-Cola", 5.0),
       (2, 102, "Garlic", 12.0),
       (3, 103, "Kiwi", 8.5),
       (4, 101, "Laptop", 1200.0),
       (5, 104, "Headphones", 150.0)
   ]

   users_df = spark.createDataFrame(users_data, ["user_id", "name", "country"])
   orders_df = spark.createDataFrame(orders_data, ["order_id", "user_id", "item", "amount"])
   ```

3. **Run Standard Join (`SortMergeJoin` — Default for Large Tables):**
   ```python
   smj_df = orders_df.join(users_df, on="user_id", how="inner")

   # Inspect Physical Plan
   smj_df.explain()

   # Trigger Execution
   smj_df.show()
   ```
   * **Expected Physical Plan Output:**
     Look for **`SortMergeJoin [user_id#1L], [user_id#7L], Inner`** preceded by **`Exchange hashpartitioning(user_id#1L, 200)`** on *both* tables—proving both datasets were shuffled across the network!

4. **Force `BroadcastHashJoin` Using `broadcast()`:**
   ```python
   # Broadcast the smaller `users_df` lookup table to all Executors
   bhj_df = orders_df.join(broadcast(users_df), on="user_id", how="inner")

   # Inspect Physical Plan
   bhj_df.explain()

   # Trigger Execution
   bhj_df.show()
   ```
   * **Expected Physical Plan Output:**
     Look for **`BroadcastHashJoin [user_id#1L], [user_id#7L], Inner, BuildRight`** preceded by **`BroadcastExchange`** on `users_df` *only*—the `orders_df` fact table undergoes **zero shuffling**!

5. **Stop SparkSession:**
   ```python
   spark.stop()
   ```

---

### Demo 2: Inspecting Partition Counts (`getNumPartitions()`) & Parallel Task Waves in Spark UI

#### Objective:
Configure a Spark Executor with **2 CPU cores**, read a multi-file Parquet dataset from Amazon S3, inspect the calculated partition count using `df.rdd.getNumPartitions()`, and observe how Spark executes **30 tasks strictly 2 at a time** in the Spark UI Timeline.

#### Step-by-Step Instructions:

1. **Initialize Spark with Explicit 2-Core Executor Sizing:**
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import col

   spark = (
       SparkSession.builder
       .appName("Spark_Partitioning_Demo")
       .config("spark.executor.instances", "1")
       .config("spark.executor.cores", "2")
       .config("spark.executor.memory", "2g")
       .config("spark.hadoop.fs.s3a.access.key", "<YOUR-AWS-ACCESS-KEY>")
       .config("spark.hadoop.fs.s3a.secret.key", "<YOUR-AWS-SECRET-KEY>")
       .config("spark.hadoop.fs.s3a.endpoint", "s3.eu-north-1.amazonaws.com")
       .getOrCreate()
   )
   ```

2. **Read the 3.4 GB S3 Parquet Dataset & Check Partition Count:**
   ```python
   s3_path = "s3a://cdebytes-data-lake/raw/shipments/2026/"
   shipments_df = spark.read.parquet(s3_path)

   # Inspect the number of 128 MB partitions Spark generated
   num_partitions = shipments_df.rdd.getNumPartitions()
   print(f"Total Spark Partitions Generated: {num_partitions}")
   # Expected Output for 3.4 GB dataset: 30 partitions
   ```

3. **Execute a Filtered Count Action & Monitor the Spark UI:**
   ```python
   # Filter for DELAYED shipments and trigger count() Action
   delayed_count = shipments_df.filter(col("status") == "DELAYED").count()
   print(f"Total Delayed Shipments: {delayed_count}")
   ```

4. **Verify the `1 Task : 1 Core : 1 Partition` Law in Spark UI (`localhost:4040`):**
   * Open `http://localhost:4040` $\rightarrow$ Click **Jobs** $\rightarrow$ Click the active/completed `count` job $\rightarrow$ Click **Stage 0**.
   * Observe **Total Tasks: `30`** (matching the exact `30` partitions returned by `getNumPartitions()`!).
   * Expand the **Event Timeline** section:
     * Notice that at any timestamp along the horizontal axis, **at most 2 task bars run concurrently** (because `--executor-cores` is set to `2`), executing across 15 sequential waves until all 30 partitions are completed.

5. **Clean Up:**
   ```python
   spark.stop()
   ```
   ```bash
   docker compose down
   ```