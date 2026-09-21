# 🚀 Python for Data Engineering: Databases, REST APIs, Production ETL & Career Mastery

**Masterclass Technical & Strategic Summary | Final Cohort Session (207 Minutes)**  
**Facilitator:** Ahmed Oladapo ("Data Guy")  
**Core Modules:** Relational Database Connectivity (`sqlite3`, `psycopg2`, `SQLAlchemy`), Parameterization & SQL Injection Defense, REST API Ingestion & Pagination Mechanics, Error Handling Architecture (`try/except/else/finally`), Full vs. Incremental ETL Implementation (Watermarking & State Tracking), and The Data Engineering Career Narrative.

---

## 📌 Executive Overview & Core Philosophy

This 207-minute marathon capstone brought the Python module to a close by synthesizing programmatic foundations into **enterprise-grade data engineering infrastructure**.

Instructor **Ahmed Oladapo** centered the masterclass on a single pragmatic axiom:

> *"Writing code is only 20% to 30% of your work. The remaining 70% is deep architectural thinking, budget constraints, error boundaries, and understanding the business problem. Anyone can push a button or write a script, but true data engineers build resilient pipes instead of fragile electrical poles." don’t start with code, start with the business problem*

The session combined low-level relational operations, automated REST API traversal, robust exception boundaries, and a live build of both **Full-Load** and **Incremental State-Tracked ETL pipelines** extracting from transactional databases and loading into cloud enterprise warehouses (**Snowflake**).

---

## 🔌 Part 1: Relational Database Connectivity & Low-Level Drivers

Ahmed opened by deconstructing how Python interacts with relational database engines, progressing from raw local execution to enterprise-grade abstraction layers.

```
 ┌─────────────────────────────────────────────────────────────┐
 │                  THE DATABASE PROTOCOL                      │
 └──────────────────────────────┬──────────────────────────────┘
                                │
                                ▼
 ┌─────────────────────────────────────────────────────────────┐
 │ 1. Connection (Handshake, auth, socket lifecycle)           │
 ├─────────────────────────────────────────────────────────────┤
 │ 2. Cursor (The internal pointer & query execution engine)   │
 ├─────────────────────────────────────────────────────────────┤
 │ 3. Execution (execute, executemany, executescript)          │
 ├─────────────────────────────────────────────────────────────┤
 │ 4. Transaction State (commit vs. rollback)                  │
 ├─────────────────────────────────────────────────────────────┤
 │ 5. Context / Cleanup (Deterministic connection teardown)    │
 └─────────────────────────────────────────────────────────────┘
```

### 1. The Anatomy of Database Interaction
Every relational database library follows a standardized communication protocol:
* **The Connection (`connection = sqlite3.connect(...)`):** Represents the network/file socket established between your Python runtime and the database engine.
* **The Cursor (`cursor = connection.cursor()`):** The working engine that traverses rows, manages query context, and executes SQL statements.
* **Execution Primitives:**
  * `cursor.execute(query)`: Runs a single atomic DDL/DML statement.
  * `cursor.executemany(query, seq_of_params)`: Efficiently binds an iterable of tuples/records to a parameterized query.
  * `cursor.executescript(sql_script)`: Executes multiple semicolon-delimited SQL commands in a single round-trip.
* **Retrieval Primitives:**
  * `cursor.fetchone()`: Pulls the next singular record.
  * `cursor.fetchmany(size)`: Pulls a specific batch.
  * `cursor.fetchall()`: Ingests all matching rows into memory (warning: dangerous on multi-million-row operational tables).

### 2. The Danger of Orphaned Connections & Resource Exhaustion
When **Temitope Asama** asked why closing connections is critical:
* **The Mechanism:** Operational databases (PostgreSQL, MySQL, Oracle) enforce hard thresholds on concurrent socket connections (connection pools).
* **The Failure Mode:** If an application opens connections without calling `connection.close()` (or without using context managers), those connections remain orphaned. During high-traffic events (e.g., promotional campaigns or payment bursts), new incoming customer transactions are rejected with `Too Many Connections` errors, taking services offline.
* **Best Practice:** Always use Python context managers:
  ```python
  import sqlite3

  # Context manager automatically handles commits and rollbacks
  with sqlite3.connect("shop.db") as conn:
      cursor = conn.cursor()
      cursor.execute("CREATE TABLE IF NOT EXISTS users (id INT, name TEXT)")
  # Connection terminates safely
  ```

---

## 🛡️ Part 2: Security, Parameterization & SQL Injection Defense

Ahmed addressed secure coding practices when writing dynamic SQL queries inside data pipelines.

### 1. The Vulnerability: Raw Dynamic Formatting (`f-strings`)
```python
# HIGHLY VULNERABLE TO SQL INJECTION - DO NOT USE IN PRODUCTION
user_input = "1; DROP TABLE users; --"
query = f"SELECT * FROM users WHERE id = {user_input}"
```

### 2. The Defense: Database Placeholders & Parameterized Queries
Never concatenate raw strings into a query. Relational database engines compile the SQL execution plan before binding incoming parameters:
* **In SQLite:** Use `?` placeholders:
  ```python
  cursor.execute("INSERT INTO products (name, price) VALUES (?, ?)", ("Laptop", 1200))
  ```
* **In PostgreSQL (`psycopg2`):** Use `%s` placeholders:
  ```python
  cursor.execute("SELECT * FROM customers WHERE locale = %s", ("US",))
  ```

### 3. ACID Transactions: Atomicity Illustrated
Using an analogy between participants **Osas** and **Zainab**:
* **Scenario:** Osas transfers \$2,000 to Zainab.
* **Step A:** Debit \$2,000 from Osas's balance.
* **Step B:** Credit \$2,000 to Zainab's balance.
* **The Failure State:** If the application crashes or the network drops after Step A, the system cannot leave Osas debited while Zainab remains uncredited.
* **The Engine Rule:** Enclose operations inside `BEGIN ... COMMIT`. If any step fails, issue `ROLLBACK` to return state to origin.

---

## 🌐 Part 3: REST APIs, Pagination & Data Ingestion

Modern data pipelines ingest significant volumes of business data from external third-party SaaS platforms (e.g., Stripe, HubSpot, Zendesk, PayPal).

```
   ┌───────────────────────┐   ┌───────────────────────┐   ┌───────────────────────┐
   │    Stripe / PayPal    │   │  Zendesk / HelpDesk   │   │  PostHog / Analytics  │
   │  (Financial Records)  │   │  (Customer Tickets)   │   │  (Behavioral Clicks)  │
   └───────────┬───────────┘   └───────────┬───────────┘   └───────────┬───────────┘
               │                           │                           │
               │ HTTP GET (JSON Streams)   │                           │
               └───────────────────────────┼───────────────────────────┘
                                           ▼
                       ┌───────────────────────────────────────┐
                       │       PYTHON EXTRACTION LAYER         │
                       │     (Session, Requests, Headers)      │
                       └───────────────────┬───────────────────┘
                                           ▼
                       ┌───────────────────────────────────────┐
                       │        DATA LAKEHOUSE / DWH           │
                       │   Unified Customer Single-Source      │
                       └───────────────────────────────────────┘
```

### 1. Controlled Access: Why APIs Exist
* Companies do not expose their internal transactional databases to external clients.
* An **API (Application Programming Interface)** acts as a controlled gateway, enforcing rate limiting, authentication, and bounded data structures.

### 2. Status Codes Every Data Engineer Must Know
* `200 OK`: Request succeeded; body contains payload.
* `201 Created`: Resource successfully minted (standard response for `POST`).
* `400 Bad Request`: Malformed syntax or missing query parameters.
* `401 Unauthorized / 403 Forbidden`: Missing or invalid bearer API tokens.
* `404 Not Found`: Endpoint URL does not exist.
* `429 Too Many Requests`: Rate limit breached; server requires cooldown.
* `500 / 502 / 504`: Upstream infrastructure failure or timeout.

### 3. Automated Pagination Traversal
APIs paginate payloads to avoid returning gigabytes in a single request. Ahmed demonstrated handling the **Rick and Morty REST API** (`https://rickandmortyapi.com/api/character`):

```python
import requests
import pandas as pd

base_url = "https://rickandmortyapi.com/api/character"
all_characters = []
current_url = base_url

while current_url:
    response = requests.get(current_url)
    
    if response.status_code != 200:
        print(f"Extraction halted on status code: {response.status_code}")
        break
        
    data = response.json()
    all_characters.extend(data.get("results", []))
    
    # Update cursor pointer to the next page URL
    current_url = data.get("info", {}).get("next")

df = pd.DataFrame(all_characters)
print(f"Ingested {len(df)} total records across all paginated pages.")
```

---

## 🧯 Part 4: Production Error Handling (`try / except / else / finally`)

Data pipelines running in production must handle edge-case failures gracefully without crashing downstream processing jobs.

```python
try:
    # Risky code: Network call, database cursor execution, parsing
    response = requests.get("https://api.example.com/data", timeout=10)
    response.raise_for_status()
    payload = response.json()
except requests.exceptions.HTTPError as http_err:
    # Runs ONLY if an HTTP error (4xx/5xx) occurs
    print(f"HTTP error encountered: {http_err}")
except KeyError as key_err:
    # Runs ONLY if response schema drifted
    print(f"Missing expected schema key: {key_err}")
except Exception as e:
    # Catches any unspecified generic runtime exception
    print(f"Unexpected pipeline catastrophe: {e}")
else:
    # Runs ONLY if the try block succeeded without exceptions
    print(f"Successfully processed {len(payload)} rows.")
finally:
    # ALWAYS executes regardless of success or total pipeline failure
    # Perfect for closing connections, releasing locks, sending metrics
    print("Execution cycle complete. Releasing operational hooks.")
```

---

## 🏗️ Part 5: Live Production Pipeline: Full vs. Incremental ETL

In the hands-on demonstration, Ahmed extracted tables from an operational relational store (**Chinook Database** via `SQLAlchemy`) and loaded them into a cloud analytical warehouse (**Snowflake**).

```
 ═══════════════════════════════════════════════════════════════════════════════════════
 PIPELINE ARCHITECTURE: FROM OPERATIONAL DB TO CLOUD WAREHOUSE
 ═══════════════════════════════════════════════════════════════════════════════════════

    ┌───────────────────────────┐                ┌───────────────────────────┐
    │  OPERATIONAL SOURCE (OLTP)│                │ CLOUD DATA WAREHOUSE (DWH)│
    │  PostgreSQL / Chinook DB  │                │ Snowflake Data Warehouse  │
    └─────────────┬─────────────┘                └─────────────▲─────────────┘
                  │                                            │
                  │ Extract via SQLAlchemy                     │ Load via to_sql / Copy
                  ▼                                            │
    ┌───────────────────────────┐                ┌─────────────┴─────────────┐
    │  EXTRACTION ENGINE        │                │   STATE TRACKING ENGINE   │
    │  Dynamically inspects     │───────────────►│   Stores last watermark   │
    │  all database schema      │                │   timestamp to prevent    │
    │  tables via `inspect()`   │                │   re-reading old rows     │
    └───────────────────────────┘                └───────────────────────────┘
```

### 1. Strategy A: Full Table Load
* **The Process:** The extraction engine identifies every table, selects all records, and uses `df.to_sql(if_exists='replace')` to overwrite the destination warehouse table.
* **The Failure Mode:** If a table contains 50 million rows, transferring the entire dataset every 15 minutes wastes bandwidth, overloads operational read replicas, and inflates cloud warehouse compute bills.

### 2. Strategy B: Incremental Load via Watermarking
* **The Process:** Only records created or modified since the last successful sync are extracted.
* **The Mechanism:**
  1. Read the highest previously ingested timestamp from an audit table (`watermark.json` or warehouse control table).
  2. Query source tables filtering for changes: `WHERE updated_at > :last_watermark`.
  3. Load extracted delta rows using `if_exists='append'`.
  4. Update the watermark state to `MAX(updated_at)`.

```python
import json
import os
from datetime import datetime
import pandas as pd
from sqlalchemy import create_engine, text

# Configuration & State Setup
WATERMARK_FILE = "pipeline_watermark.json"
SOURCE_ENGINE = create_engine("postgresql://user:pass@host:5432/source_db")
WAREHOUSE_ENGINE = create_engine("snowflake://user:pass@account/db/schema")

def get_last_watermark():
    if os.path.exists(WATERMARK_FILE):
        with open(WATERMARK_FILE, "r") as f:
            return json.load(f).get("last_synced_at", "1970-01-01 00:00:00")
    return "1970-01-01 00:00:00"

def set_last_watermark(new_watermark):
    with open(WATERMARK_FILE, "w") as f:
        json.dump({"last_synced_at": str(new_watermark)}, f)

# Incremental Sync Engine
def sync_incremental_products():
    last_sync = get_last_watermark()
    print(f"Extracting products updated after: {last_sync}")
    
    query = text("SELECT * FROM products WHERE updated_at > :checkpoint ORDER BY updated_at ASC")
    
    with SOURCE_ENGINE.connect() as conn:
        df = pd.read_sql(query, conn, params={"checkpoint": last_sync})
        
    if df.empty:
        print("Zero new records detected. Pipeline sleeping.")
        return

    print(f"Extracted {len(df)} new/updated records. Ingesting to Snowflake...")
    
    # Load into Cloud Warehouse (Append-only delta)
    df.to_sql("stg_products", WAREHOUSE_ENGINE, if_exists="append", index=False)
    
    # Advance Watermark State
    new_checkpoint = df["updated_at"].max()
    set_last_watermark(new_checkpoint)
    print(f"Ingestion successful. Updated watermark to: {new_checkpoint}")
```

### 3. Critical Production Nuances Addressed
* **Handling Systems Lacking `updated_at` (Qudus Abdulahi):**
  * If an operational table lacks a modification timestamp, **incremental loading is impossible**. The engineer must fall back to full table loads or configure database transaction-log Change Data Capture (CDC).
* **Using `created_at` for Incremental Ingestion (Prince Peter):**
  * `created_at` will capture new insertions, but **completely misses updates to existing records** (e.g., status updates or address changes).
* **High-Throughput Loading (Snowflake `to_sql` Alternatives):**
  * While `pandas.to_sql()` works well for prototyping and small-to-medium datasets, enterprise-scale pipelines stage data into cloud object storage (S3/GCS) and issue `COPY INTO` commands for parallel bulk ingestion.

---

## 💼 Part 6: Career Strategy & Technical Interview Blueprint

In the final hour, Ahmed shifted from code syntax to senior career positioning, addressing common obstacles junior engineers encounter.

### 1. Breaking the "Junior Engineer Plateau"
* Junior engineers often focus exclusively on syntax details and memorizing tools.
* Senior engineers stand out through **architectural ownership, systems thinking, and trade-off analysis**.

### 2. Crafting a Compelling Professional Narrative
Ahmed shared his own career trajectory as a model for cohort members:

```
                  ┌──────────────────────────────────────────────┐
                  │          THE DATA CAREER NARRATIVE           │
                  └──────────────────────┬───────────────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                ▼                                ▼
 ┌──────────────┐                 ┌──────────────┐                 ┌──────────────┐
 │ ORIGIN POINT │                 │  THE PROBLEM │                 │ THE SOLUTION │
 ├──────────────┤                 ├──────────────┤                 ├──────────────┤
 │ Statistical  │ ──────────────► │ Conflicting  │ ──────────────► │ Shifted to   │
 │ Analyst / BI │                 │ metrics and  │                 │ Data Eng. to │
 │ Dashboarding │                 │ broken pipes │                 │ fix pipeline │
 └──────────────┘                 └──────────────┘                 │ foundations  │
                                                                   └──────────────┘
```

* **The Narrative Structure:**
  * **The Origin:** Started in statistical analysis and BI reporting.
  * **The Problem Observed:** Different departments reported conflicting numbers (e.g., Marketing reported 10,200 customers, Sales reported 10,000, Logistics reported 10,500). Analysts were blamed for reporting inconsistencies caused by broken upstream pipelines.
  * **The Turning Point:** Realized that analytics is only as reliable as the underlying data platform, prompting a focus on data engineering, system design, and cost governance.
  * **The Value Proposition:** Experienced across the full data lifecycle—from setting up greenfield platforms to migrating on-premises workloads to cloud environments while managing infrastructure costs.

### 3. Practical Action Plan: Two-Week Mastery Routine
For cohort members preparing for technical interviews, Ahmed outlined a targeted two-week study plan:

* **Week 1: Containers & Control Flow Foundations**
  * Practice manipulating primitive and collection types: lists, tuples, dictionaries, and sets.
  * Solve real-world looping, conditional branching, and exception handling problems until syntax becomes second nature.
* **Week 2: Data Engineering Libraries & Ecosystem Tooling**
  * Work through core Pandas methods: `.groupby()`, `.merge()`, `.read_sql()`, and `.to_sql()`.
  * Set up local end-to-end extraction scripts that connect to SQLite/PostgreSQL, query endpoints via `requests`, and write out structured outputs.

---

## 📋 Action Items & Next Steps

| Category | Action Item | Target / Details |
| :--- | :--- | :--- |
| **Code Review** | Refactor Local Scripts | Update database scripts to use `with` context managers and parameterization (`?` / `%s`). |
| **API Practice** | Build a Paginated Ingestion Script | Write an extraction script handling `current_url = data['info']['next']` pagination loops. |
| **ETL Practice** | Test Watermark Incremental Logic | Implement a test script using a local JSON file or table to store and advance state checkpoints. |
| **Tooling Setup** | Set Up Databricks & GitHub | Ensure free Databricks accounts and empty GitHub repositories are configured for the upcoming **dbt** module. |
| **Module Transition**| Transition to Analytics Engineering | Next course: Data Transformation, Dimensional Modeling, and Pipeline Automation using **dbt**. |



# SUMMARY 
## Class Recap: Python for Data Engineering, Databases, APIs, and ETL

## Big Picture
This session was a practical, highly interactive walkthrough of how Python fits into data engineering. Ahmed kept repeating one core message: **don’t start with code, start with the business problem**. The class moved through database basics, cursor behavior, SQL execution methods, API consumption, pagination, error handling, and finally a full ETL-style workflow using Python, SQLite, pandas, and SQLAlchemy.

## 1) The opening mood: gratitude, energy, and a reminder to think
Ahmed began by appreciating the class and calling out many attendees by name. The tone was warm and emotional at the start, then quickly shifted into a teaching mode. He explained that this class was not about blindly writing Python code, but about learning how to think through data problems properly.

He stressed:
- **Architecture matters more than rushing code**
- **Business use case comes first**
- **Budget, scale, and volume change the solution**
- **Not every problem needs the same pipeline design**

He used simple examples to show that a small business with 50,000 records yearly should not be engineered the same way as a business handling millions of records daily. The same idea was repeated many times: **look at the context first, then choose the right approach**.

## 2) What data engineering really means in practice
Ahmed explained that in real life, companies have data everywhere:
- office databases
- external systems
- APIs
- spreadsheets/files
- payment systems
- support systems
- analytics tools

His point was that data engineers are often the people who **move data from the source systems into a warehouse** so that everyone can use one reliable version of the truth.

He described the practical workflow as:
- take data from the source
- store it in a controlled place
- transform it
- model it
- make it ready for business use

He emphasized that data engineering is not about “decorating code”; it is about **solving business problems with the right data movement strategy**.

## 3) Python fundamentals in context: containers, control flow, functions
Ahmed connected earlier Python lessons to data engineering:
- **containers**: list, tuple, dictionary, set
- **control flow**: if statements, loops, conditions
- **functions**: reusable blocks of logic
- **libraries/packages**: tools that help you do more without reinventing the wheel

He explained that once you understand what each structure is for, everything becomes easier:
- lists for ordered collections
- dictionaries for key/value data
- control flow for decisions
- functions for reuse
- packages for more advanced work

He also said that if you understand the fundamentals well, you can move quickly to bigger tools like pandas and SQLAlchemy without getting lost.

## 4) Database basics using SQLite
The class then moved into database work using SQLite. Ahmed created a sample database file, `shop.db`, and used it to demonstrate:
- `sqlite3.connect()`
- creating a cursor
- executing SQL statements
- creating tables
- inserting records
- selecting records
- fetching data
- committing changes
- closing connections

### Key teaching point: cursor vs connection
Ahmed described the cursor as the object used to **run operations inside the database**, while the connection is the actual link to the database file.

### Important distinction: `execute()` vs `executescript()`
A major part of the class was devoted to this difference:
- **`execute()`** runs **one SQL statement at a time**
- **`executescript()`** runs **multiple SQL statements together**

He used a kitchen/house analogy to explain that you should not use the wrong tool for the job. If a function is meant for a single statement, don’t expect it to behave like a multi-statement runner.

### Why commit matters
Ahmed explained that if you do not call **`commit()`**, your changes are not fully saved.

He repeatedly compared this to real-life systems:
- a bank transaction
- a login process
- a database-backed application

The class learned that commit is what makes your changes permanent, while the connection must be closed properly to avoid exhausting available resources.

## 5) Why not close connections? Resource problems explained clearly
A long discussion focused on what happens when connections are left open.

Ahmed said that if you keep leaving database connections open:
- the system can run out of available connections
- applications may stop working
- other users may not be able to log in
- the database can become blocked

He used a connection-pool style explanation: if all available connections are occupied, new requests cannot be served.

This was one of the strongest practical lessons in the class:
- always commit when needed
- always close your connections
- never leave resources hanging

## 6) SQL injection and placeholders
When students asked about inserting values, Ahmed introduced the reason for using placeholders like `?` in SQL queries.

He explained:
- placeholders help prevent **SQL injection**
- they keep user input separate from SQL logic
- they are safer than building SQL strings directly with f-strings

He discouraged using f-strings for SQL because it can expose the system to attack or broken queries.

## 7) SQLite, PostgreSQL, and transfer of knowledge
Ahmed then compared SQLite with PostgreSQL and other databases.

He explained that:
- SQLite is a lightweight local database
- PostgreSQL uses a different connector/library
- SQL syntax is often similar, but the connection method differs
- you do not re-learn everything from scratch; you **transfer knowledge** from one system to another

He also pointed out that some libraries have different names depending on the database:
- SQLite uses `sqlite3`
- PostgreSQL often uses `psycopg2`
- SQLAlchemy can abstract several database engines

## 8) SQLAlchemy and pandas as abstractions
Ahmed introduced SQLAlchemy as an object-relational mapper (ORM) that helps Python talk to different databases more cleanly.

He also explained how pandas can simplify database interactions:
- use `read_sql()` to pull SQL data into a DataFrame
- use pandas to inspect, transform, and move data around
- when pandas works, it can save a lot of manual effort

But he also warned that not every environment allows you to rely on pandas alone.
Sometimes you need to use direct database tools because:
- the environment is restricted
- external libraries are not allowed
- performance considerations require lower-level control

## 9) APIs: what they are and why they matter
Another major section covered APIs.

Ahmed explained that an API is like a controlled doorway into a system. It lets people access **specific data or actions** without exposing everything.

He emphasized that API design is about control:
- users should only access what they are allowed to access
- the endpoint is the URL where the request is sent
- APIs protect the internal system
- data can be exposed safely in a controlled way

### GET vs POST
He explained the basics:
- **GET** is used to retrieve data
- **POST** is used to send or submit data

### Endpoints
The class learned that an endpoint is the actual route or URL used to request a resource.

Ahmed made it clear that when you don’t control the source system, you work within the rules it provides. That means:
- read the API documentation
- learn the data structure
- respect rate limits
- understand paging/pagination

## 10) Pagination and rate limits
The API example became very practical when Ahmed demonstrated pagination.

He showed that many APIs do not give all records at once because that would be too heavy for the server.
Instead, they split data into pages.

Important ideas covered:
- some APIs return metadata like `info`, `count`, `pages`, and `next`
- data often lives in `results`
- you may need to loop through pages
- some APIs cap the number of requests you can make
- some systems apply rate limiting to prevent abuse

He explained that the data provider decides:
- how much data you can pull
- how often you can pull it
- what format the data comes in

## 11) Real-world API use cases
Ahmed gave examples of common external systems that organizations pull data from:
- payment providers
- customer support tools
- analytics systems
- ticketing tools
- social or commerce platforms

He explained that businesses often want all this data in one warehouse so they can see a complete customer picture. This is where data enrichment comes in: combining many different sources into one coherent model.

## 12) Web scraping and Beautiful Soup
The class briefly touched on web scraping.

Ahmed explained that when data is not exposed through an API, you may need to:
- inspect the web page structure
- use Beautiful Soup
- parse HTML tags
- extract useful data from the page

He noted that many websites block or restrict scraping, so this area requires care and understanding of HTML structure.

## 13) ETL and practical pipeline thinking
The class then tied everything back to ETL and data movement.

Ahmed described ETL as:
- **Extract** data from a source
- **Transform** it into the right shape
- **Load** it into a warehouse or target system

He also mentioned that some tools now allow ELT or hybrid patterns, but the central idea remains the same: move data in a controlled, repeatable way.

### Simple function idea
He used tiny functions like:
- extract name
- transform name
- load data

to show how pipeline stages are chained together.

## 14) Error handling in Python
Ahmed spent time explaining exceptions because he wants students to build production-minded code.

He covered:
- syntax errors
- type errors
- value errors
- name errors
- division by zero errors

Then he explained the standard structure:
- `try`
- `except`
- `else`
- `finally`

### Why this matters
Errors should not crash your entire pipeline if they can be handled.
In production, the goal is often:
- catch the issue
- log it
- continue safely or roll back
- avoid breaking the whole system

He showed how `except Exception as e` can catch many kinds of errors when you’re not sure exactly what will happen.

## 15) Full load vs incremental load
One of the most practical parts of the class was the comparison between full load and incremental load.

### Full load
Full load means you pull **everything every time**.
That is simple, but expensive when the dataset is large.

### Incremental load
Incremental loading means you only pull **what changed** since the last successful run.

Ahmed explained the need for a **watermark**:
- a stored timestamp or marker representing the last successful load
- the next run checks data updated after that point
- this avoids duplicate loads and saves compute cost

### Why it matters
Incremental loads are crucial when:
- data volumes are large
- compute cost matters
- you want efficient refreshes
- you don’t want duplicates

If a source table has no `updated_at` column, Ahmed said you may need to do a full load or create a suitable tracking field like `created_at` if it fits the use case.

## 16) The watermark table concept
Ahmed compared the watermark to a simple tracking table that remembers the last run.
He described it like a sign-in book or a list of who has already been served.

The idea is simple:
- first run loads everything
- the watermark is saved
- next run checks whether new data exists
- only new records are loaded

This helps avoid reprocessing the same records repeatedly.

## 17) Practical concerns: speed, duplicates, and design choices
Ahmed answered several important practical questions:
- if rows are many, performance matters
- pandas may not always be the best tool for huge loads
- sometimes database-native bulk loading tools are better
- Snowflake and other warehouses have optimized loading mechanisms
- design choices depend on volume, scale, and source capabilities

He also explained why duplicate records happen when code is rerun without guardrails, and why idempotency is a major data engineering principle.

## 18) What to learn first if you’re new
Ahmed ended with a very strong learning roadmap.
He said the first things to master are:
1. **Containers**
2. **Control flow**
3. **Core Python packages and libraries**
4. **SQL and database basics**
5. **Practical thinking about business use cases**

He encouraged students to spend time building confidence, not just memorizing code.

## 19) Career advice and motivation
The closing portion of the class became motivational.
Ahmed urged students to:
- understand their current skill level honestly
- identify what they can do right now
- build a strong professional story
- avoid rushing into advanced topics without a foundation
- keep practicing until they can explain solutions confidently

He also explained that many companies use a mix of:
- hand-written Python
- managed ETL tools
- cloud data platforms
- low-code/no-code tools like ADF, SSIS, Dataiku, or Airbyte

The lesson was that **the best engineers know both the code and the tools**, and choose based on the problem.

## 20) Final takeaways
The class ended with a strong summary of the bigger message:
- Python is powerful, but not the whole story
- data engineering is about solving business problems
- know your data source
- know the access pattern
- know the business goal
- choose between full load, incremental load, API pulls, or tools depending on the context
- always protect your systems with good connection handling, error handling, and safe SQL practices

## Closing thought
If this class had one slogan, it would be:

**“Think first, code second, and always build for the business.”**

Ahmed repeatedly showed that real engineering is not about writing flashy code. It is about making good decisions, understanding the source, and building reliable pipelines that work in the real world.