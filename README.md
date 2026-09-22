automatically every day at midnight, with normal output and errors written to a
# CDE Bootcamp 3: Data Engineering Learning Journal

This repository documents my **Core Data Engineers Bootcamp 3** journey from data engineering foundations through Linux, Git, SQL, Python, data modeling, Change Data Capture, lakehouse architecture, and dbt development on Databricks.

The material combines class notes, architecture diagrams, commands, code examples, troubleshooting records, and practical assignments. The aim is not only to learn tools, but to understand how dependable data systems are designed, secured, tested, documented, and operated.

## Repository Contents

```text
cdebootcamp3/
|-- assignments/               # Architecture and automation projects
|   |-- A1-DataEngineeringFundamentals.md
|   `-- linux-git-project-A2/
|-- classes/                   # Notes for Sessions 01-25
|   |-- assets/                # SQL scripts and a Python notebook
|   |-- 01DengFundamentals1.md
|   |-- ...
|   `-- 25DBT2.md
`-- README.md
```

The companion [dbt project](../cdc_modeling/cdc_marketing/) contains the working Databricks adapter, dbt profile, models, tests, generated artifacts, and dependency configuration used during the final sessions.

## Learning Roadmap

### Data engineering, Linux, and Git

| Session | Class | Main topics |
| :---: | :--- | :--- |
| 01 | [Data Engineering Fundamentals I](classes/01DengFundamentals1.md) | Data lifecycles, ingestion, storage, ETL/ELT, OLTP, OLAP, and pipeline architecture |
| 02 | [Data Engineering Fundamentals II](classes/02DengFundamentals2.md) | Compute, storage, networking, system architecture, cloud concepts, and DataOps |
| 03 | [Linux I](classes/03Linux1.md) | Linux fundamentals, filesystems, terminal navigation, and command-line operations |
| 04 | [Git I](classes/04Git1.md) | Version control, repositories, staging, commits, branches, and remotes |
| 05 | [Linux II](classes/05Linux2.md) | Shells, pipes, redirection, text processing, permissions, and users |
| 06 | [Linux III](classes/06Linux3.md) | System administration, scheduling, automation, and deeper Linux operations |
| 07 | [Git II](classes/07Git2.md) | Collaboration, pull requests, merging, conflict handling, and branch protection |
| 08 | [Git III](classes/08Git3.md) | CI/CD, GitHub Actions, code review, and production Git workflows |
| 11 | [Data Engineering Fundamentals Review](classes/11DengFundamentalsReviewSession.md) | Batch versus streaming, medallion layers, resilience, architecture trade-offs, and peer design review |

### SQL

| Session | Class | Main topics |
| :---: | :--- | :--- |
| 09 | [SQL I: RDBMS Foundations](classes/09SQL1.md) | Data classification, normalization, DDL/DML, transactions, keys, and referential integrity |
| 10 | [SQL II: Querying Data](classes/10SQL2.md) | DQL, filtering, dates, sorting, aggregation, `WHERE`, and `HAVING` |
| 12 | [SQL III: Aggregation and Data Cleaning](classes/12SQL3.md) | Arithmetic and BODMAS, divide-by-zero safety, aggregate functions, `GROUP BY`, `HAVING`, `COALESCE`, `CASE`, strings, and type conversion |
| 13 | [SQL IV](classes/13SQL4.md) | Class file reserved; session notes have not yet been added |

### Python for data engineering

| Session | Class | Main topics |
| :---: | :--- | :--- |
| 14 | [Python I: Engineering Setup](classes/14Python1.md) | The data ecosystem, Python internals, Conda and `venv`, Jupyter, terminal workflows, PATH, and directory hygiene |
| 15 | [Python II: Primitives and Collections](classes/15Python2.md) | Variables, expressions, scalar types, strings, indexing, slicing, booleans, lists, tuples, and engineering mindset |
| 17 | [Python III: Operators and Control Flow](classes/17Python3.md) | Dictionaries, sets, arithmetic and logical operators, input, casting, object methods, conditionals, and loops |
| 20 | [Python V](classes/20Python5.md) | Class file reserved; session notes have not yet been added |
| 22 | [Python VI: Files, Pandas, and Production Practices](classes/22Python6.md) | Loop control, functions, object references, safe copying, comprehensions, file I/O, cursors, Pandas, and ecosystem architecture |
| 23 | [Python VII: Databases, APIs, and ETL](classes/23Python7.md) | Database drivers, parameterized SQL, transactions, REST APIs, pagination, exception handling, full loads, incremental ETL, and watermarks |

### Data modeling, CDC, and lakehouse architecture

| Session | Class | Main topics |
| :---: | :--- | :--- |
| 16 | [Data Modeling I: Foundations and Normalization](classes/16Modeling1.md) | Conceptual, logical, and physical models; entities; relationships; tables and views; 1NF, 2NF, 3NF; grain; composite and surrogate keys |
| 18 | [Data Modeling II: OLTP and OLAP Architecture](classes/18Python4.md) | Workload-driven design, OLTP versus OLAP, ERD cardinality, star/snowflake/OBT schemas, CDC, and telecom architecture |
| 19 | [Data Modeling III: Enterprise Pipeline Design](classes/19Modeling2.md) | Modeling phases, transactional and analytical workloads, cardinality, CDC, Databricks ingestion, dimensional serving, BI, and reverse ETL |
| 21 | [Medallion Architecture, CDC, and Governance](classes/21Modeling3.md) | PostgreSQL-to-Databricks ingestion, full and incremental sync, cursor selection, Bronze/Silver/Gold layers, semantic definitions, PII controls, LLMs, and reverse ETL |

### dbt and Databricks analytics engineering

| Session | Class | Main topics |
| :---: | :--- | :--- |
| 24 | [dbt I: Modern Analytics Engineering](classes/24DBT1.md) | ETL versus ELT, dbt's role, Astral `uv`, adapter installation, project initialization, dbt directories, Databricks profiles, PATs, OAuth service principals, and CI/CD preparation |
| 25 | [dbt II: Connectivity, Debugging, and Compilation](classes/25DBT2.md) | dbt Core versus Cloud, Unity Catalog and SQL Warehouse setup, Windows/macOS/Linux configuration, `dbt debug`, compilation, execution, tests, static documentation, lineage, and troubleshooting |

> **Documentation status:** Sessions 13 and 20 currently contain empty placeholder files. They remain in the roadmap so the class sequence is complete and the missing notes are visible rather than silently omitted.

## Practical Assets

The class material is supported by runnable examples in [classes/assets](classes/assets/):

- [Parch & Posey table creation](classes/assets/Parch_and_Posey_Create_Table.sql)
- [Parch & Posey sample data](classes/assets/Parch_and_Posey_Insert_Data.sql)
- [DML practice](<classes/assets/DML SQL Script.sql>)
- [`SELECT` and `WHERE` practice](classes/assets/01_SELECT_WHERE.sql)
- [Sorting, filtering, and date queries](classes/assets/02_SORTING_FILTERING_DATES.sql)
- [Python fundamentals notebook](classes/assets/1._python_basic_intro.ipynb)

## Practical Assignments

### Beejan Technologies complaint data pipeline

The [first assignment](assignments/A1-DataEngineeringFundamentals.md) designs an end-to-end customer complaint pipeline for social media, call-center logs, SMS, and website forms. It covers hybrid ingestion, cleaning, classification, layered storage, serving, orchestration, monitoring, and DataOps.

![Beejan Technologies conceptual complaint data pipeline](assignments/assets/pipeline-diagram.png)

### Linux and Git automation project

The [second assignment](assignments/linux-git-project-A2/README.md) converts Linux, Bash, and Git concepts into working data engineering tools. It includes:

- An ETL script that downloads a public Stats NZ dataset and promotes selected data through raw, transformed, and Gold layers.
- An interactive recursive organizer for CSV and JSON files with overwrite protection and clear success, skip, and failure reporting.
- A cron configuration that schedules the ETL pipeline for midnight and records normal output and errors in a log.
- Version-controlled source data, transformed outputs, JSON/CSV examples, and shell scripts.

## Current Technical Milestone

The latest practical work connects local dbt Core to a Databricks SQL Warehouse and builds the starter model in Unity Catalog.

```text
dbt SQL/Jinja models
	|
	| compile and execute through dbt-databricks
	v
Databricks SQL Warehouse
	|
	v
bronze_production.cdc_staging.my_first_dbt_model
```

The verified Windows PowerShell workflow now covers:

1. Installing `dbt-databricks` and optional Elementary observability dependencies with `uv`.
2. Initializing `cdc_marketing` without the interactive profile wizard.
3. Supplying the development catalog, schema, HTTP path, and PAT through environment variables.
4. Running `dbt debug`, `dbt compile`, `dbt run`, `dbt test`, `dbt build`, and `dbt show`.
5. Verifying `my_first_dbt_model` under `bronze_production.cdc_staging` in Databricks.
6. Generating `target/static_index.html` and opening the interactive lineage graph.
7. Keeping real credentials out of Git and using placeholders in environment templates.

The complete commands, platform-specific instructions, recovery steps, and end-to-end checklists are in [Session 25](classes/25DBT2.md).

## Core Engineering Principles

- Begin with the business problem, consumers, workload, and service expectations before selecting tools.
- Separate write-optimized OLTP systems from read-optimized analytical workloads as systems scale.
- Preserve recoverable raw data, clean and conform reusable entities, and expose trusted business-ready outputs.
- Choose CDC cursor columns according to source semantics; immutable event IDs and mutable update timestamps solve different problems.
- Define table grain before choosing keys or writing transformations.
- Use normalization to protect transactional integrity and dimensional models to simplify analytical reads.
- Treat Python and SQL as engineering tools for automation, validation, integration, and reliable data movement.
- Parameterize SQL, close resources deterministically, handle API pagination, and make incremental state explicit.
- Keep environments reproducible with dependency files and isolated runtimes.
- Keep credentials out of source control; use environment variables locally and managed secret stores in automation.
- Make SQL transformations modular and dependency-aware with dbt `ref()` and `source()`.
- Test, review, observe, document, and secure data products as part of their implementation, not as afterthoughts.

## Suggested Reading Order

Follow Sessions 01-25 in numerical order for the full progression. The sequence moves from system fundamentals into operating-system and collaboration skills, then SQL and Python, followed by workload-aware modeling, CDC and lakehouse governance, and finally dbt implementation on Databricks.

For a topic-focused route:

- **Platform foundations:** Sessions 01-08 and 11
- **SQL:** Sessions 09, 10, and 12
- **Python:** Sessions 14, 15, 17, 22, and 23
- **Data modeling and architecture:** Sessions 16, 18, 19, and 21
- **dbt and Databricks:** Sessions 24 and 25
- **Hands-on projects:** [assignments](assignments/) and [class assets](classes/assets/)

Each populated class file is designed to work as a standalone technical reference, so readers can also jump directly to the topic they need.

## About This Repository

This is an evolving collection of notes and assignments from **CDE Bootcamp 3**. It records both technical lessons and the professional habits required to build dependable data systems, from raw operational events to tested, documented analytical models.

---

<p align="center"><strong>From raw events to reliable insight.</strong></p>
