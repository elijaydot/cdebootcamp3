# CDE Bootcamp 3.0: PySpark Internals — Eager vs. Lazy Evaluation, Narrow & Wide Transformations, Jobs/Stages/Tasks & Reading `.explain()` Plans

> *"Anyone can prompt an AI to write PySpark `.filter()` and `.groupBy()` code in 10 seconds. Real data engineers pop open the engine hood: they know why Spark refuses to execute a single line until an Action triggers the Driver, how Narrow transformations avoid network shuffles while Wide transformations incur egress costs, and how to read a Catalyst `.explain()` plan from the bottom up."*
>
> — **Mayowa Akinyele**

**Date:** November 21, 2026 (Evening Session)  
**Duration:** 145 Minutes  
**Lead Instructor:** Mayowa Akinyele (Opening Quiz by Ayodeji Ajayi)  
**Curriculum Module:** 11 Distributed Data Processing — PySpark Internal Mechanics: PySpark API vs. Spark Engine, Eager vs. Lazy Evaluation, Transformations (Narrow vs. Wide) vs. Actions, Execution Hierarchy (Applications $\rightarrow$ Jobs $\rightarrow$ Stages $\rightarrow$ Tasks), Catalyst Optimizer & Reading `.explain("extended")` Plans, and Spark UI Inspection

---

## Executive Overview & Class Atmosphere

Following Friday's architectural deep-dive into YARN, the Spark Driver, and Spark Executors, this Saturday evening masterclass bridged the gap between **writing PySpark scripts** and **understanding how the Spark Driver compiles, optimizes, and executes them**.

Mayowa reinforced a core philosophy for the cohort: *"Don't use your mouth to solve engineering problems—use your hands, inspect the logs, read the official docs, and break things intentionally."* Rather than treating PySpark as just another Python data-wrangling library like Pandas, Mayowa demonstrated live inside **Jupyter Notebook** and the **Spark Web UI (`localhost:4040`)** how Spark lazily builds a **Lineage DAG**, how the **Catalyst Optimizer** rewrites your queries behind the scenes (applying **Column Pruning** and **Predicate Pushdown**), and how **Actions** wake up the cluster to dispatch parallel **Tasks** to Executors.

---

## Part 1: Warm-Up Quiz — Spark & YARN Architecture Recap
*(Facilitated by Ayodeji Ajayi)*

Before launching into PySpark internals, Ayodeji led a razor-sharp Slido quiz reinforcing Friday's distributed cluster architecture:

1. **Query Optimization vs. Data Processing:**
   * The **Spark Driver** is responsible for parsing and optimizing your Spark application.
   * **Spark Executors** perform the actual parallel data processing work across worker nodes.
2. **Spark's Core Architectural Advantage:**
   * **Memory (RAM)** is the defining feature of Spark—performing transformations in volatile RAM rather than writing intermediate outputs to slow disk like Hadoop MapReduce.
3. **YARN Master–Slave Components:**
   * **Resource Manager** is the cluster leader (sitting on the primary node), while **Node Managers** are the follower agents running on worker nodes.
4. **Dynamic Spawning of Driver & Executors:**
   * Neither the Spark Driver nor Executors exist by default in an idle cluster. They are dynamically spawned inside YARN containers only when a Spark job is submitted.
5. **Production Deploy Mode (`cluster` vs. `client`):**
   * **`cluster` mode** is mandatory for production because the Driver runs safely inside the cluster. In **`client` mode**, the Driver runs on your local machine/SSH terminal—if your Wi-Fi blinks, the Driver dies and kills the entire job.
   * *Quiz Co-Winners:* **Olawale Akinyele** & **Pelumi Tytler** 🏆

---

## Part 2: What Is PySpark? (The Python API vs. The Spark Engine)

A frequent point of confusion for beginners is distinguishing between **Apache Spark** and **PySpark**:
* **Apache Spark:** The distributed processing engine written primarily in Scala/Java that runs across a multi-node cluster.
* **PySpark:** The official **Python API** wrapper that allows Python developers to write clean, expressive data pipelines and submit instructions to the underlying Spark engine.
* **DataFrames vs. RDDs:** While Spark originally operated on low-level **RDDs (Resilient Distributed Datasets)**, modern data engineers spend **99% of their time working with Spark DataFrames**—distributed, tabular structures with named columns and schemas that benefit from Spark's built-in **Catalyst Query Optimizer**.

> 🔗 **Official PySpark API Reference:** [PySpark SQL & DataFrame API Documentation](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/dataframe.html)

---

## Part 3: Eager Evaluation (Pandas) vs. Lazy Evaluation (Spark)

One of the most fundamental architectural differences between **Pandas** and **PySpark** lies in *when* code actually executes:

```
+-----------------------------------------------------------------------------------------+
|                   EAGER EVALUATION (Pandas) vs. LAZY EVALUATION (Spark)                 |
|                                                                                         |
|  [ Pandas: Eager Execution (Line-by-Line) ]                                             |
|  Line 1: df = pd.read_csv("orders.csv")          ──► Executes immediately in RAM!       |
|  Line 2: df = df[df["status"] == "COMPLETED"]    ──► Executes immediately in RAM!       |
|  Line 3: df = df.groupby("typo_column").sum()    ──► ❌ CRASHES! Wasted 5 mins compute! |
|                                                                                         |
|  [ Apache Spark: Lazy Evaluation (Plan First, Execute Later) ]                          |
|  Line 1: df = spark.read.csv("orders.csv")       ──► Driver records step in DAG (0 work)|
|  Line 2: df = df.filter(col("status") == "PAID") ──► Driver records step in DAG (0 work)|
|  Line 3: df = df.groupBy("typo_column").sum()    ──► Driver catches typo in Catalog     |
|                                                      BEFORE a single Executor wakes up! |
+-----------------------------------------------------------------------------------------+
```

### Why Spark's Lazy Evaluation Is a Superpower:
1. **Zero Wasted Compute on Syntax/Column Typos:** If line 50 of your PySpark script references a misspelled column (`"typo_category"`), Spark's **Catalyst Analyzer** catches the invalid column name immediately during plan validation—before spinning up Executors or scanning terabytes of S3 data.
2. **Holistic Query Optimization:** Because Spark waits until it sees your *entire* chain of transformations before executing, the **Catalyst Optimizer** can reorder operations (e.g., pushing `.filter()` and `.select()` ahead of expensive `.join()` and `.groupBy()` steps) to dramatically reduce memory and network load.

---

## Part 4: Transformations (Narrow vs. Wide) vs. Actions

Every DataFrame method in PySpark falls into one of two categories: **Transformations** or **Actions**.

### 1. Transformations (Lazy — Build the Lineage DAG)
Transformations take an existing DataFrame and return a **new DataFrame** without modifying the original (DataFrames are immutable). **Transformations do not trigger cluster execution.**

Spark divides transformations into two critical subtypes:

```
         [ NARROW TRANSFORMATION ]                      [ WIDE TRANSFORMATION ]
  (No Network Shuffle — Fast & Local)             (Triggers Shuffle — Moves Data Across Nodes!)

  Node 1 Partition ──► filter() ──► Out 1         Node 1 Partition ──┐  ┌──► Group A (Node 1)
  Node 2 Partition ──► filter() ──► Out 2                            ├──┤
                                                  Node 2 Partition ──┘  └──► Group B (Node 2)
```

| Transformation Type | Network Behavior | Common PySpark Functions | Cost & Performance Impact |
| :--- | :--- | :--- | :--- |
| **Narrow Transformation** *(Map Phase)* | **Zero Data Shuffle:** Each Executor partition computes its output independently in local RAM. | `.filter()`, `.where()`, `.select()`, `.withColumn()`, `.withColumnRenamed()`, `.drop()` | Blazing fast; zero network transfer overhead. |
| **Wide Transformation** *(Reduce Phase)* | **Triggers Shuffling:** Data must be serialized and transferred across network nodes so matching keys co-locate in the same partition. | `.groupBy()`, `.agg()`, `.join()`, `.distinct()`, `.orderBy()`, `.repartition()` | Expensive; incurs serialization CPU, network latency, and potential cross-AZ AWS transfer fees. |

### 2. Actions (Eager — Wake Up the Driver & Executors!)
An **Action** is an operation that demands a concrete result—either returning data back to the Driver's screen or writing output to external storage. **Calling an Action immediately wakes up the Spark Driver to compile the Physical Plan and dispatch Tasks to Executors.**

* **Common PySpark Actions:**
  * `.show()` (prints top $N$ rows to console/notebook)
  * `.count()` (returns total row count)
  * `.collect()` (pulls all rows into Driver RAM — *danger: can crash Driver with OOM on large datasets!*)
  * `.take(n)` / `.first()`
  * `.write.parquet(...)` / `.write.csv(...)` / `.write.saveAsTable(...)`

---

## Part 5: Spark Execution Hierarchy — Applications, Jobs, Stages & Tasks

When you open the **Spark Web UI**, Spark organizes work into a four-tier hierarchy:

```
[ 1. SPARK APPLICATION ] (Created when `SparkSession.builder.getOrCreate()` starts)
       │
       ├──► [ 2. JOB 1 ] (Triggered by Action #1, e.g., `df.show()`)
       │           │
       │           ├──► [ 3. STAGE 0 ] (Narrow steps before Shuffle: Read ──► Filter ──► Project)
       │           │           ├──► Task 0 (Runs on Executor Core 1 for Partition 0)
       │           │           └──► Task 1 (Runs on Executor Core 2 for Partition 1)
       │           │
       │           │    ═══════ SHUFFLE BOUNDARY (Exchange / groupBy) ═══════
       │           │
       │           └──► [ 3. STAGE 1 ] (Wide aggregation after Shuffle: HashAggregate)
       │                       ├──► Task 2 (Runs on Executor Core 1)
       │                       └──► Task 3 (Runs on Executor Core 2)
       │
       └──► [ 2. JOB 2 ] (Triggered by Action #2, e.g., `df.write.parquet(...)`)
```

1. **Application:** The entire PySpark program instantiated by your `SparkSession`.
2. **Jobs:** Every **Action** in your script triggers at least one **Job** (note: certain methods like `.read.csv(..., inferSchema=True)` or `.show()` can trigger hidden internal jobs behind the scenes to inspect schemas).
3. **Stages:** Every **Wide Transformation (Shuffle Boundary)** splits a Job into separate **Stages**. All consecutive Narrow Transformations are pipelined together into a single Stage.
4. **Tasks:** The smallest unit of execution! Inside each Stage, Spark creates **one Task per Data Partition** and dispatches those Tasks across available Executor CPU cores.

---

## Part 6: Under the Hood of the Driver — Reading `.explain("extended")`

Senior engineers inspect how Spark optimizes their code using the `.explain()` method (`df.explain(mode="extended")`), which prints the four phases of the **Catalyst Optimizer** inside the Spark Driver:

```
[ Your PySpark Code ]
        │
        ▼ (1) Syntax Check Only (Columns unresolved)
1. == Parsed Logical Plan ==
        │
        ▼ (2) Resolves Column Names & Data Types against Catalog (Catches Typos!)
2. == Analyzed Logical Plan ==
        │
        ▼ (3) Catalyst Optimizer Rewrites Query (Predicate Pushdown & Column Pruning!)
3. == Optimized Logical Plan ==
        │
        ▼ (4) Generates Executable Hardware Strategy (BroadcastHashJoin vs. SortMergeJoin)
4. == Physical Plan ==  ──► Dispatched to TaskScheduler & Executors!
```

### How to Read an `.explain()` Plan (Important Rule!):
* Read the **four plan sections from Top to Bottom** (`Parsed` $\rightarrow$ `Analyzed` $\rightarrow$ `Optimized` $\rightarrow$ `Physical`).
* Within **each individual plan tree**, read the execution steps **from Bottom to Top** (starting at the leaf `Scan` node at the bottom and flowing upward toward the final `Project` / `Aggregate` at the top).

### Live Optimization Example Demonstrated in Class:
* **What Mayowa Wrote:** Read all 6 columns $\rightarrow$ `.filter(status == "COMPLETED")` $\rightarrow$ `.groupBy("category").sum("quantity")` $\rightarrow$ `.select("category", "total_quantity")`.
* **What Catalyst Optimizer Did:**
  1. **Column Pruning:** Noticed that 3 columns (`order_id`, `product_name`, `price`) were never used in filtering or grouping, so it inserted an early `Project` right after reading the table to drop unused columns immediately.
  2. **Predicate Pushdown:** Pushed the `isnotnull(category)` and `status = 'COMPLETED'` filters all the way down to the initial file scan so irrelevant rows are discarded before entering aggregation memory.

> 🔗 **Official PySpark Docs:** [DataFrame.explain() API Reference](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.DataFrame.explain.html)

---

## Part 7: Comprehensive Student Q&A Index

| Student | Core Question | Mayowa's Technical Clarification |
| :--- | :--- | :--- |
| **Christian Omoluabi** | *Where can students run PySpark notebooks if they don't have an active AWS EMR cluster?* | You can run PySpark locally inside the **Dockerized Jupyter environment** provided in the bootcamp GitHub repository, or spin up a free **Databricks Community Edition** workspace in the browser. |
| **Efeoghene Oghenechovwen** | *Do Transformations and Actions apply only to Spark DataFrames?* | Yes, in modern PySpark (`pyspark.sql`), Transformations and Actions govern **Spark DataFrames** (though legacy RDDs share the same conceptual model). |
| **Habeeb Ajao** | *Aside from `.write()`, what other operations count as Actions in PySpark?* | `.show()`, `.count()`, `.collect()`, `.first()`, `.take(n)`, and `.toPandas()` are all Actions that trigger immediate Driver execution. |
| **Oluseyi Odude** | *What happens if a single PySpark script contains two Actions (e.g., `.count()` followed by `.write.parquet()`)?* | Each Action triggers a separate **Spark Job** (`Job 0` for `.count()` and `Job 1` for `.write.parquet()`). Unless you explicitly cache the DataFrame (`.cache()`), Spark recomputes the Lineage DAG from scratch for the second Action. |
| **Godwin Nosa** | *Can we visually inspect the Lineage DAG before calling an Action?* | The unexecuted Lineage DAG resides purely inside the Driver's JVM memory. However, calling `df.explain("extended")` prints the text representation of the logical and physical plans without executing a job. |
| **Suliyat Dauda** | *Does the Spark Driver execute Transformations while Executors execute Actions?* | **No.** The Driver *never* processes data rows—it only builds the Lineage DAG and optimizes the plan. When an Action is called, the Driver schedules Tasks, and **Executors execute both the Transformations and the Action** across worker nodes. |
| **Roqeeb Olaniran & Leo Osigbemhe** | *Can you have a Wide Transformation without a Narrow Transformation?* | In practice, every Wide Transformation (like `groupBy` or `join`) relies on underlying Narrow steps (scanning/reading partitions and projecting keys) before shuffling data across the network—which is why Stage 0 in the Spark UI always shows the initial scan/map phase before Stage 1's shuffle exchange. |
| **AbdulRasaq Bilau** | *If a dataset struggles in Pandas on a local laptop, must we always spin up a multi-node Spark cluster?* | **Not always!** Before paying for a multi-node Spark cluster (EMR/Databricks), test single-node multi-threaded engines like **Polars** or **DuckDB** on your machine. Reserve Spark for true multi-hundred-gigabyte or terabyte distributed workloads. |
| **Ose Benson** | *When reading the `.explain()` output, do we read from top-to-bottom or bottom-to-top?* | Read the **4 plan headers top-to-bottom** (`Parsed` $\rightarrow$ `Analyzed` $\rightarrow$ `Optimized` $\rightarrow$ `Physical`), and read the **operators inside each plan tree bottom-to-top** (from data scan at the bottom up to final output at the top). |
| **Efeoghene Oghenechovwen** | *Does this same Catalyst query optimization happen if we write Spark SQL instead of Python DataFrame code?* | **Yes!** Both PySpark DataFrame API calls and raw `spark.sql("SELECT ...")` queries compile down into the exact same Unresolved Logical Plan and pass through the identical **Catalyst Optimizer**. |
| **Habeeb Ajao** | *Is `.explain()` considered an Action or a Transformation?* | Neither—it is a diagnostic inspection method. Calling `.explain()` does **not** trigger a Spark Job in the Spark UI; it simply asks the Driver's Catalyst Optimizer to print its execution plan. |
| **Suliyat Dauda** | *If we run a small 20 GB dataset on Spark, does it still run through the full Catalyst Optimizer pipeline?* | **Yes.** Spark runs every query through the Catalyst Optimizer regardless of dataset size because the optimizer inspects schema structure and query logic—and if **Dynamic Allocation** is enabled, Spark automatically scales down unused Executors. |

---

## Part 8: Hands-On Labs & Live Demos — Step-by-Step Execution Guide

This section provides complete, reproducible guides for all three live Jupyter Notebook and Spark UI demonstrations conducted during the session.

### Demo 1: Proving Lazy Evaluation vs. Eager Execution (Pandas vs. PySpark)

#### Objective:
Compare how **Pandas** executes code line-by-line (wasting compute before crashing on a typo) versus how **PySpark** validates the entire Logical Plan lazily before running any tasks on Executors.

#### Step-by-Step Instructions:

1. **Start the Local Spark & Jupyter Environment:**
   ```bash
   cd spark-dev-environment
   docker compose up -d
   ```
   Open Jupyter Notebook in your browser at `http://localhost:8888` and open the Spark Web UI in a second tab at `http://localhost:4040`.

2. **Test Pandas Eager Execution (with Intentional Typo):**
   Run the following cell in Jupyter:
   ```python
   import pandas as pd

   data = [
       {"order_id": 1, "category": "Electronics", "status": "COMPLETED", "amount": 500},
       {"order_id": 2, "category": "Clothing", "status": "CANCELLED", "amount": 120},
       {"order_id": 3, "category": "Electronics", "status": "COMPLETED", "amount": 300}
   ]

   # Step 1: Loads immediately into RAM
   pdf = pd.DataFrame(data)
   print("Step 1 complete: Data loaded into Pandas!")

   # Step 2: Filters immediately in RAM
   pdf_filtered = pdf[pdf["status"] == "COMPLETED"]
   print("Step 2 complete: Filtered rows!")

   # Step 3: Crashes AFTER Steps 1 & 2 already consumed CPU and RAM
   pdf_grouped = pdf_filtered.groupby("typo_category")["amount"].sum()
   ```
   * **Observation:** Both `print` statements execute and consume memory before crashing with `KeyError: 'typo_category'`.

3. **Test PySpark Lazy Evaluation (with Intentional Typo):**
   Run the equivalent PySpark cell:
   ```python
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import col, sum as _sum

   spark = SparkSession.builder.appName("Lazy_Evaluation_Demo").getOrCreate()

   sdf = spark.createDataFrame(data)

   # Transformations are recorded lazily in the Driver's Lineage DAG
   sdf_filtered = sdf.filter(col("status") == "COMPLETED")
   sdf_grouped = sdf_filtered.groupBy("typo_category").agg(_sum("amount"))

   # Trigger Action
   sdf_grouped.show()
   ```
   * **Observation:** Spark immediately throws `AnalysisException: [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column or function parameter with name typo_category cannot be resolved. Did you mean one of the following? [category]`. Check the **Spark UI (`localhost:4040`)**—**zero jobs were executed** by Executors!

4. **Fix the Typo & Re-Run:**
   Change `"typo_category"` to `"category"` and re-run. Spark executes cleanly and displays the aggregated table.

---

### Demo 2: Observing Narrow vs. Wide Transformations in the Spark Web UI

#### Objective:
Verify visually in the Spark Web UI (`localhost:4040`) that **Narrow Transformations** execute inside a single Stage with zero data exchange, while **Wide Transformations** create a Shuffle boundary across multiple Stages.

#### Step-by-Step Instructions:

1. **Execute a Narrow Transformation Pipeline:**
   ```python
   # Narrow Transformations Only: Filter + Select (No Shuffle)
   narrow_df = (
       sdf.filter(col("amount") > 250)
          .select("order_id", "category", "amount")
   )

   # Trigger Action
   narrow_df.show()
   ```
   * **Spark UI Inspection (`localhost:4040` $\rightarrow$ Jobs $\rightarrow$ Click Latest Job):**
     * Notice there is **only 1 Stage (`Stage 0`)** in the DAG Visualization.
     * **Shuffle Read / Shuffle Write:** `0.0 B` (Zero network data exchange!).

2. **Execute a Wide Transformation Pipeline:**
   ```python
   # Wide Transformation: groupBy triggers network Shuffle
   wide_df = (
       sdf.groupBy("category")
          .agg(_sum("amount").alias("total_revenue"))
   )

   # Trigger Action
   wide_df.show()
   ```
   * **Spark UI Inspection (`localhost:4040` $\rightarrow$ Jobs $\rightarrow$ Click Latest Job):**
     * Notice the DAG Visualization now splits into **2 Stages (`Stage 0` and `Stage 1`)** connected by an **`Exchange` (Shuffle)** box!
     * `Stage 0` shows **Shuffle Write** bytes leaving initial partitions, and `Stage 1` shows **Shuffle Read** bytes entering the grouped partitions.

---

### Demo 3: Inspecting Catalyst Optimizations with `.explain("extended")`

#### Objective:
Use `.explain(mode="extended")` to inspect how the Spark Driver's Catalyst Optimizer rewrites queries using **Column Pruning** and **Predicate Pushdown** without triggering a cluster job.

#### Step-by-Step Instructions:

1. **Build a Multi-Step Query with Unused Columns:**
   ```python
   from pyspark.sql.functions import col, sum as _sum

   orders_data = [
       (101, "Laptop", "Electronics", "COMPLETED", 2, 1200.0),
       (102, "Shirt", "Apparel", "CANCELLED", 1, 45.0),
       (103, "Phone", "Electronics", "COMPLETED", 3, 800.0),
       (104, "Shoes", "Apparel", "COMPLETED", 2, 150.0)
   ]
   columns = ["order_id", "product_name", "category", "status", "quantity", "price"]

   orders_df = spark.createDataFrame(orders_data, columns)

   # Define Transformations (Notice we do NOT call .show() or .write())
   optimized_query = (
       orders_df
       .filter((col("status") == "COMPLETED") & (col("quantity") > 0))
       .groupBy("category")
       .agg(_sum("quantity").alias("total_quantity"))
       .select("category", "total_quantity")
   )

   # Print all 4 Catalyst Plans
   optimized_query.explain(mode="extended")
   ```

2. **Analyze the Output Plan:**
   * **`== Parsed Logical Plan ==`:** Shows the exact raw sequence you wrote (`Scan` $\rightarrow$ `Filter` $\rightarrow$ `Aggregate` $\rightarrow$ `Project`).
   * **`== Analyzed Logical Plan ==`:** Shows resolved column types (`category#2: string`, `quantity#4L: bigint`).
   * **`== Optimized Logical Plan ==`:** Look immediately above `LogicalRDD` (the bottom scan node)—Catalyst automatically injected `Project [category#2, quantity#4L]` **before** the aggregation, pruning `order_id`, `product_name`, and `price` early!
   * **`== Physical Plan ==`:** Shows the concrete hardware execution operators (`Filter` $\rightarrow$ `HashAggregate` (partial) $\rightarrow$ `Exchange hashpartitioning(category)` $\rightarrow$ `HashAggregate` (final)).
   * **Verify Zero Jobs in Spark UI:** Refresh `http://localhost:4040/jobs/`—confirm that `.explain()` ran purely inside the Driver without launching any Executor jobs.

3. **Stop the SparkSession When Finished:**
   ```python
   spark.stop()
   ```