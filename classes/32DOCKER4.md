# 🔌 Docker Mastery: Volumes, Port Mapping & Database Persistence

*A Deep-Dive Technical Summary of the Digital Engineering Community Lecture*  
**Lead Instructor:** Ilekura Idowu  
**Teaching Assistant Demonstration:** Edeki Charles  
**Date:** October 2, 2026 | **Duration:** 152 Minutes  

---

## Executive Summary

Building on container immutability, instructor **Ilekura Idowu** and TA **Edeki Charles** dove into the core mechanics required to run real-world data pipelines and databases in Docker: **Volume Mounting** (bridging ephemeral container state to persistent host disks) and **Port Forwarding/Mapping** (routing external and host traffic into container network namespaces).

Through practical, live demonstrations—from writing JSON files from Python into container storage to provisioning isolated **PostgreSQL** instances inspected via **DBeaver**—the session drove home a central tenet of modern data infrastructure: **Containers are disposable processes; data is not.**

---

## 1. Warm-Up Quiz & Core Knowledge Refresher

The lecture kicked off with a 10-question Slido interactive refresher moderated by TA **Leo Osigbemhe** (won by *Oluwabukunmi*):

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CORE QUIZ TAKEAWAYS                             │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Dockerfile Line = A Layer: Every single directive (FROM, COPY, RUN) │
│    creates a cached, intermediate filesystem layer.                    │
│ 2. Layer Ordering Matters: Static dependencies (base images, packages) │
│    belong at the top; rapidly changing application code belongs at     │
│    the bottom to preserve build cache.                                 │
│ 3. Docker Build Flag (-t): -t designates the human-readable tag/name;  │
│    the trailing dot (.) sets the current build context path.           │
│ 4. sleep 5 vs. Container Exit: 'sleep 5' pauses the foreground         │
│    process for 5 seconds; it does NOT delete the container.            │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. The Ephemeral Dilemma: Why Containers Lose Data

By default, any data written inside a running Docker container is written to its top **read-write container layer**. 

```
   Container Layer (Read-Write)  <-- Ephemeral! Destroyed on container stop/removal
  ───────────────────────────────
   Image Layer 3 (Read-Only)
   Image Layer 2 (Read-Only)
   Image Layer 1 (Read-Only)
```

### Live Experiment: Charles Edeki's Screen Share
To demonstrate this disaster scenario, Charles ran an ETL script that extracted records and outputted `output.json`:

1. **Execution 1:** The container ran, executed the script, and wrote `output.json`. Running `cat output.json` inside the container verified the data was present.
2. **Execution 2:** Charles spun up a second container instance from the exact same image. Inspecting the directory showed **zero trace** of `output.json`.
3. **The Lesson:** When a container shuts down or crashes, all local unmounted modifications vanish. In high-stakes production (e.g., banking event ingestion, webhook listeners), unmounted data loss causes silent, irrecoverable record drops.

---

## 3. Docker Volumes: The Bi-Directional Pipe

To persist data, Docker borrows the concept of **filesystem mounting (`mount`)** native to Linux.

```
       [ Host Machine ]                           [ Docker Container ]
    /local/path/data_new      <══ Bi-directional ══>       /app/data
   (Persistent, Durable Disk)           Pipe             (Isolated Process)
```

### Characteristics of Volume Mounts:
* **Persistence Across Container Lifecycles:** When the container dies, the data remains untouched on the host drive.
* **Bi-Directional Synchronization:** Modifying or adding a file on the host (e.g., `touch test.py`) makes it instantly accessible inside the running container, and vice-versa.
* **Shared Storage Across Multiple Containers:** Multiple worker containers can mount the exact same host directory simultaneously to pass files along an ETL chain (e.g., an Extractor container outputs JSON $\rightarrow$ a Transformer container ingests it).

### Command Syntax Breakdown:
```bash
docker run -d \
  --name python_with_volume \
  -v $(pwd)/data_new:/app/data \
  my_python_image
```
* `-v` or `--volume`: Specifies the mount mapping.
* Host Path (`$(pwd)/data_new`): The absolute or relative directory on your local machine.
* Container Path (`/app/data`): The destination mount point inside the container.

---

## 4. Port Forwarding: Bridging Networks Without Conflicts

When running server applications (like PostgreSQL, Redis, or Apache Airflow) inside Docker, containers run inside an isolated network namespace.

```
  Local Machine (Host)                     Docker Container
  ─────────────────────                    ────────────────
  DBeaver / Python Client                  PostgreSQL Server
  Connects to localhost:5435  ═════════>   Listens on Port 5432
             │                                     │
             └────────── Port Forwarding ──────────┘
                            -p 5435:5432
```

### The Conflict Problem:
* PostgreSQL natively listens on port `5432`.
* If a data engineer already has a local installation of PostgreSQL running on their machine, that local instance already owns port `5432`.
* Attempting to bind a container directly to `5432` results in an immediate bind failure (`address already in use`).

### The Mapping Solution (`-p host_port:container_port`):
* `-p 5435:5432`: Instructs Docker to open port `5435` on the host machine and route all inbound traffic to port `5432` inside the container.
* Host tools (DBeaver, Python scripts, TablePlus) connect to `localhost:5435`. The containerized PostgreSQL instance remains completely unaware that port translation is occurring.

---

## 5. Running Production PostgreSQL on Docker

Rather than building database engines from scratch, engineers pull official images from **Docker Hub** and configure them using environment variables.

### Starting a Persistent PostgreSQL Container

```bash
docker run -d \
  --name de_postgres_db \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5435:5432 \
  -v $(pwd)/postgres_data:/var/lib/postgresql/data \
  postgres:latest
```

### Flag-by-Flag Breakdown:
| Parameter | Role |
| :--- | :--- |
| `-d` | **Detached Mode:** Runs the container in the background, freeing up the terminal prompt. |
| `--name de_postgres_db` | Assigns an explicit, human-readable name rather than a random container hash. |
| `-e POSTGRES_PASSWORD=...` | Injects an **environment variable** used by the image's entrypoint script (`initdb`) to configure the default `postgres` superuser. |
| `-p 5435:5432` | Maps host port `5435` to container internal port `5432`. |
| `-v $(pwd)/postgres_data:/var/lib/postgresql/data` | Mounts the internal directory where Postgres persists table data, indexes, and write-ahead logs (`PGDATA`) directly to the local disk. |

---

## 6. End-to-End Pipeline: Connecting Python to Containerized Postgres

To illustrate how data ingestion pipelines operate, Idowu wrote and executed a Python script that connected to the containerized database via **SQLAlchemy**.

```python
# connect_postgres.py
from sqlalchemy import create_engine, text

# Notice the host port 5435 in the connection URI
DATABASE_URI = "postgresql://postgres:mysecretpassword@localhost:5435/postgres"

engine = create_engine(DATABASE_URI)

with engine.connect() as connection:
    # 1. Create a relational table
    connection.execute(text("""
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50),
            age INT,
            city VARCHAR(50)
        );
    """))
    
    # 2. Insert records
    connection.execute(text("""
        INSERT INTO users (name, age, city) 
        VALUES ('John Doe', 30, 'New York');
    """))
    
    # 3. Explicit transaction commit
    connection.commit()
    print("Record successfully ingested into Dockerized Postgres!")
```

### Verification in DBeaver:
1. Created a new connection to `Host: localhost`, `Port: 5435`, `Database: postgres`, `User: postgres`.
2. Queried `SELECT * FROM public.users;` $\rightarrow$ verified row insertion.
3. Inspected the local host folder (`./postgres_data`) $\rightarrow$ verified that raw database engine catalogs (`base/`, `global/`, `pg_wal/`) were written straight to the developer's laptop drive.

---

## 7. Live Troubleshooting Log & Pedagogical Insights

| Participant | Issue / Question | Root Cause | Resolution / Explanation |
| :--- | :--- | :--- | :--- |
| **Suliyat Dauda** | Confused between port mapping and volume mapping. | Blended network routing with file persistence. | Instructor used the telephone/socket vs. carbon copy analogy: Ports connect voices; volumes store written letters. |
| **Christian Omoluabi** | *"It felt like magic; can we get a step-by-step?"* | Fast-paced command line transitions. | Clarified the sequence: Create local folder $\rightarrow$ Mount via `-v` $\rightarrow$ Run container $\rightarrow$ Verify files sync. |
| **Lorreta Anyika** | Inquired whether she needed to install Postgres or PGAdmin locally on her OS. | Assumed Docker requires native host software. | Clarified that Docker replaces local installations; all database binaries run inside the container. DBeaver connects remotely. |
| **Temitope Asama** | Wanted to know if port numbers (like `5435` or `5437`) are arbitrary. | Unclear how port collisions work. | Ports $>1024$ and $<65535$ that are unassigned by active host software can be freely chosen for port forwarding. |
| **Qudus Abdulahi** | Where does `-p` belong in the command line? | Syntax confusion. | Flags (`-p`, `-v`, `-e`) can be passed in any order, provided they come **before** the image name. |

---

## 8. Critical Instructor Takeaways ("Idowuisms")

* **"We Don't Cram Here":** Memorizing long flags is pointless. Understanding *why* something is mapped (host vs. container) allows an engineer to adapt when moving from Docker to Kubernetes or AWS ECS.
* **"AI Will Displace the Syntax Typists":** Anyone can prompt an LLM to generate a `docker run` command. Elite data engineers understand network routing, persistent volume semantics, and troubleshooting connection failures under pressure.
* **"Write and Publish":** Writing technical articles (like TA Charles did during his *100 Days of Linux*) builds professional credibility, accelerates assimilation, and creates hiring leverage.

---

## 9. Hands-On Homework Challenge

To cement this class before the upcoming **Docker Compose** module:

1. **Spin up a containerized database** (PostgreSQL or MySQL) with port mapping and volume mounts.
2. **Author an ingestion script** in Python using `SQLAlchemy` or `psycopg2` that extracts records from a public CSV or API and inserts them into the database.
3. **Terminate the container** (`docker stop`, `docker rm`).
4. **Spin up a brand-new container** referencing the same volume mount $\rightarrow$ verify that all tables and rows remain fully intact.
5. *(Optional)* Document your findings in a LinkedIn technical post.