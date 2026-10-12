# Docker Grand Finale: Architecture, Compose, Multi-Stage Builds & Production Optimization

*A Masterclass Technical Summary of the Final Docker Engineering Module*  
**Lead Instructor:** Ilekura Idowu  
**Teaching Assistants:** Chinyere Nwigwe, Leo Osigbemhe, Charles Edeki  
**Date:** October 5, 2026 | **Duration:** 153 Minutes  

---

## Executive Summary

In this final capstone session of the Docker curriculum, lead instructor **Ilekura Idowu** synthesized container fundamentals into enterprise-grade deployment strategies. Moving beyond elementary container lifecycles, the cohort tackled:
* The internal plumbing of the **Docker Client-Daemon-Registry architecture**.
* The subtle, interview-critical divergence between **`CMD` vs. `ENTRYPOINT`**.
* **Docker Compose orchestration**, modular service dependencies (`depends_on`), and the **YAML DRY (Don't Repeat Yourself) principle** using anchors and aliases.
* **Multi-stage builds** to slash production image sizes from nearly a gigabyte down to lightweight, minimal runtimes.
* Container hardening against **privilege escalation (never run as `root`)** and resource guardrails (CPU, RAM, swap, and logging limits).

---

## 1. Concept Clarification: Ports, Bridges & Volume Mappings

Before diving into advanced mechanics, TA **Chinyere Nwigwe** and students (**Temitope Asama**, **Qudus Abdulahi**, **Zainab Olamiji**, and **AbdulRasaq Bilau**) reviewed key networking and storage fundamentals:

```
    Host Machine (OS)                        Docker Container Namespace
┌─────────────────────────┐               ┌───────────────────────────────┐
│ Host Port: 5435         │ ════ Bridge ═>│ Target Port: 5432 (Postgres)  │
│ (External entry point)  │  (-p 5435:5432)│ (Internal listening daemon)   │
└─────────────────────────┘               └───────────────────────────────┘
            ▲                                             ▲
            │                                             │
┌─────────────────────────┐               ┌───────────────────────────────┐
│ Host Storage Path       │ ══ Mounting ═>│ In-Container Target Path      │
│ /my_local/postgres_data │  (-v host:dir)│ /var/lib/postgresql/data      │
│ (Persistent, durable)   │ (Bi-dir pipe) │ (Ephemeral runtime storage)   │
└─────────────────────────┘               └───────────────────────────────┘
```

* **Port Mapping (`-p host:container`):** Bridges the host machine’s network stack to the isolated container namespace. If host port `5432` is already owned by a native PostgreSQL instance, traffic can be mapped to an open host port (e.g., `5435`), translating packets into the container's standard internal port `5432`.
* **Volume Mapping (`-v host:container`):** Bridges host storage into container directories. Because containers are ephemeral processes, volumes provide a persistent, bi-directional pipe ensuring data survives container termination.
* **Docker Networks:** Containers under the same custom bridge network can resolve and communicate with one another using container service names rather than fragile, hardcoded IP addresses.

---

## 2. Under the Hood: Docker Engine Architecture

Idowu unpacked what actually occurs when terminal commands are executed:

```
┌──────────────────┐          UNIX Socket / REST API          ┌──────────────────────────────────┐
│  Docker Client   │ ───────────────────────────────────────> │          Docker Daemon           │
│   (CLI Binary)   │    (/var/run/docker.sock or HTTP API)    │             (dockerd)            │
└──────────────────┘                                          └─────────────────┬────────────────┘
                                                                                │
                                           ┌────────────────────────────────────┼────────────────┐
                                           ▼                                    ▼                ▼
                                    ┌──────────────┐                     ┌──────────────┐ ┌──────────────┐
                                    │ Image Cache  │                     │  Containers  │ │   Volumes    │
                                    │  & Builders  │                     │ (Namespaces) │ │  & Networks  │
                                    └──────┬───────┘                     └──────────────┘ └──────────────┘
                                           │
                                           ▼ Pull / Push
                                  ┌──────────────────┐
                                  │ Docker Registry  │
                                  │ (Hub, ECR, GCR)  │
                                  └──────────────────┘
```

1. **The Docker Client:** The command-line interface (`docker run`, `docker build`). It does not run containers directly; it serializes requests into API calls.
2. **The Docker Daemon (`dockerd`):** The persistent background "House Manager." It listens for API requests over the Unix domain socket `/var/run/docker.sock` and manages Linux namespaces, cgroups, images, and networking.
   * *The Broken Socket Trap:* If Docker Desktop or the system daemon is stopped, executing `docker run` throws:
     > `Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?`
3. **The Registry:** A remote image repository (Docker Hub, AWS ECR, GCP Artifact Registry). When an image cannot be found locally, the daemon automatically queries the configured registry, pulls the image layers, and caches them locally.

---

## 3. The Interview Gauntlet: `CMD` vs. `ENTRYPOINT`

A classic senior engineering interview topic: how does Docker decide which process to execute when a container launches?

```
                   CONTAINER EXECUTION OVERRIDE MATRIX
                   
  Directive Used                   Command Run                   Resulting Execution
┌───────────────────────────────┬───────────────────────────────┬────────────────────────────────┐
│ CMD ["echo", "Hello"]         │ docker run my_img             │ Prints: Hello                  │
├───────────────────────────────┼───────────────────────────────┼────────────────────────────────┤
│ CMD ["echo", "Hello"]         │ docker run my_img ls -la      │ ❌ Overridden! Executes ls -la │
├───────────────────────────────┼───────────────────────────────┼────────────────────────────────┤
│ ENTRYPOINT ["echo", "Hello"]  │ docker run my_img             │ Prints: Hello                  │
├───────────────────────────────┼───────────────────────────────┼────────────────────────────────┤
│ ENTRYPOINT ["echo", "Hello"]  │ docker run my_img World       │ ✅ Appends! Prints Hello World │
└───────────────────────────────┴───────────────────────────────┴────────────────────────────────┘
```

* **`CMD` (Default & Overridable):** Provides default parameters and commands. If the operator passes arguments at the command line (`docker run <image> <command>`), Docker **completely discards** the default `CMD` in favor of the CLI arguments.
* **`ENTRYPOINT` (Immutable Executable):** Establishes the core executable. Passing arguments on the command line does **not** override `ENTRYPOINT`; instead, the arguments are **appended as parameters** to the entrypoint executable.
* **Production Best Practice:** Use `ENTRYPOINT` when building utility CLI tools or production pipelines where a script *must* execute without accidental overrides. Use `CMD` when providing optional defaults intended to be overridden during development.

---

## 4. Multi-Container Orchestration with Docker Compose

Rather than chaining massive, brittle terminal commands containing ports, volumes, environment variables, and network flags, teams codify entire application stacks into `docker-compose.yml`.

### The DRY Principle: YAML Anchors & Aliases
In enterprise compose manifests (e.g., production Apache Airflow deployments), repeating identical environment blocks across multiple worker services creates maintenance overhead. Idowu demonstrated how to use standard YAML anchors (`&`) and aliases (`*`):

```yaml
version: '3.8'

# 1. Define the reusable anchor block
x-airflow-common: &airflow-common
  image: apache/airflow:2.7.1-python3.10
  environment:
    AIRFLOW__CORE__EXECUTOR: CeleryExecutor
    AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
  volumes:
    - ./dags:/opt/airflow/dags
    - ./logs:/opt/airflow/logs
  depends_on:
    - postgres
    - redis

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow

  redis:
    image: redis:latest

  # 2. Inject configuration into workers via alias
  airflow-webserver:
    <<: *airflow-common
    command: webserver
    ports:
      - "8080:8080"

  airflow-scheduler:
    <<: *airflow-common
    command: scheduler
```

### Essential Docker Compose CLI Commands

```bash
# Spin up all services in the background (detached mode)
docker compose up -d

# Force image rebuilds before bringing services up
docker compose up --build -d

# Stop running services without destroying containers
docker compose stop

# Restart services that were stopped
docker compose start

# Gracefully stop and tear down containers, networks, and internal resources
docker compose down

# Tear down containers AND delete persistent named volumes (-v)
docker compose down -v
```

> ⚠️ **Resource Note:** Always run `docker compose down` on local development laptops when testing concludes. Unattended background containers running databases and Celery workers will consume host CPU and memory.

---

## 5. Multi-Stage Builds: Slicing Image Bloat by 50%+

A common anti-pattern among junior engineers is deploying images packed with compilers, headers, and build caches, inflating image sizes beyond $1\text{ GB}$.

```
STAGE 1: THE BUILDER (Heavyweight Kitchen)
┌─────────────────────────────────────────────────────────────┐
│ FROM python:3.12-slim AS builder                            │
│ • Installs build-essential, gcc, git (Compilers & Tools)    │
│ • Runs: pip install --user -r requirements.txt (Pandas, etc)│
│ ⚠️ Output Image Size: ~893 MB                                │
└──────────────────────────────┬──────────────────────────────┘
                               │
               Only Copy Needed Artifacts
            (/root/.local/ compiled binaries)
                               │
                               ▼
STAGE 2: THE RUNTIME (Clean Dining Room)
┌─────────────────────────────────────────────────────────────┐
│ FROM python:3.12-slim                                       │
│ • COPY --from=builder /root/.local /root/.local             │
│ • COPY app.py /app/app.py                                   │
│ • Stripped clean of gcc, caches, and build tools            │
│ ✅ Final Production Image Size: ~404 MB (54% Reduction!)    │
└─────────────────────────────────────────────────────────────┘
```

### The Production Dockerfile (`Dockerfile.multistage`)

```dockerfile
# ==========================================
# Stage 1: Build Environment (Builder Stage)
# ==========================================
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install dependencies into user directory without caching wheel files
RUN pip install --no-cache-dir --user -r requirements.txt

# ==========================================
# Stage 2: Final Minimal Runtime Environment
# ==========================================
FROM python:3.12-slim

WORKDIR /app

# Copy ONLY the pre-compiled Python packages from the builder stage
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY app.py .

# Update PATH to prioritize pre-compiled binaries
ENV PATH=/root/.local/bin:$PATH

ENTRYPOINT ["python3", "app.py"]
```

#### Live Lab Results
* **Single-Stage Build (Standard):** Build tools and caches retained $\rightarrow$ **893 MB**
* **Multi-Stage Build (`--from=builder`):** Compilers discarded $\rightarrow$ **404 MB**  
* *Total space saved:* **$489\text{ MB}$ (over $50\%$ reduction)** for identical application behavior!

---

## 6. Enterprise Hardening & Performance Optimization

Idowu concluded the technical review with non-negotiable security and operational standards:

### 1. Privilege Escalation: Never Run as `root`
* By default, Docker containers execute processes with `UID 0` (`root`).
* If a remote attacker exploits a vulnerability in a web service or LLM agent executing inside a container, they inherit root-level capabilities, creating a container escape vulnerability.
* **The Fix:** Create a dedicated, non-privileged system user:
  ```dockerfile
  RUN useradd -m -u 1000 appuser
  USER appuser
  ```

### 2. Disk Space Hygiene: Reclaiming Lost Gigabytes
Over weeks of building images, dangling layers and stopped containers consume disk space.
```bash
# Reclaims unused containers, dangling networks, and build caches
docker system prune -a --volumes
```
*(During the live session, executing this command freed up over $17\text{ GB}$ of host storage).*

### 3. Build Optimization: Grouping `RUN` Commands
```dockerfile
# ANTI-PATTERN: Creates 3 distinct layers that retain package archives
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# ✅ BEST PRACTICE: Executes in a single layer, cleaning up within the same step
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*
```

### 4. Resource Guardrails: CPU, Memory & Log Throttling
Prevent runaway containers from starving the host machine of resources:
```bash
docker run -d \
  --name heavy_worker \
  --cpus="1.5" \
  --memory="1g" \
  --memory-swap="2g" \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  my_data_pipeline:latest
```

---

## 7. Engineering Wisdom & Career Guidance

In the final hour, Idowu shared personal career advice for transitioning into professional engineering roles:

* **"Don't Cram Syntax; Master the Trade-Offs":** In technical interviews, explaining *why* you chose a multi-stage build, *how* layer caching invalidation works, or *why* you avoided root privileges distinguishes senior engineers from junior coders.
* **"AI Can Write Dockerfiles; It Lacks Architectural Context":** LLMs often produce bloated Dockerfiles that install unnecessary tools or leak credentials. The value of an engineer lies in spotting anti-patterns, securing deployments, and controlling cloud budgets.
* **"Public Proof of Work Destroys Imposter Syndrome":**
  * Share what you build publicly on LinkedIn, Substack, Medium, or YouTube.
  * You don't need to be an expert to teach; documenting your learning path builds authority, leads to job referrals, and reinforces technical recall.
* **"Use Your Teaching Assistants":** TAs (Leo, Chichi, Charles) are active industry practitioners. Engaging with them on real blockers accelerates career growth.

---

## Comprehensive Final Checklist

- [ ] **Docker Engine Architecture:** Understand the interaction between the Client, `dockerd` daemon, Unix socket, and Registries.
- [ ] **Runtime Directives:** Know when to implement `ENTRYPOINT` vs. `CMD`.
- [ ] **Orchestration:** Be comfortable defining multi-service applications using `docker-compose.yml`, managing dependencies with `depends_on`, and structuring configs using YAML anchors (`&`) and aliases (`*`).
- [ ] **Image Optimization:** Implement multi-stage builds (`COPY --from=builder`) to minimize deployment artifacts.
- [ ] **Container Security:** Configure non-root users (`USER appuser`) and isolate build contexts using `.dockerignore`.
- [ ] **System Hygiene:** Clean up host environments using `docker system prune -a` and manage container resources (`--cpus`, `--memory`).