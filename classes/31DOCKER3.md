# Docker Under the Hood: Caching, Container Execution & Working Directories

*A Complete, Engaging Deep-Dive Summary of the Digital Engineering Community Lecture*

**Instructor:** Ilekura Idowu  
**Session Date:** September 30, 2026 | **Duration:** 126 Minutes  

---

## Executive Overview

In this fast-paced, highly interactive deep dive, **Ilekura Idowu** pushes the cohort beyond simply running basic Docker commands into the operational reality of building containerized pipelines. The lecture dissects:
* How Docker executes **layer caching** and byte-level cache invalidation.
* How to inspect image histories with `docker history` to detect hidden vulnerabilities.
* The critical mechanics of **`docker exec -it`** (interactive pseudo-TTY terminal routing into container namespaces).
* Why working in the container root (`/`) is an enterprise security risk, and how **`WORKDIR`** creates isolated application contexts.
* The exact distinction between **`docker run`** and **`docker start`**.

---

## 1. Warm-Up Quiz & The Core Rule: "Docker is Not a New Computer"

The session opened with an interactive quiz hosted by TAs **Chinyere Nwigwe** and **Leo Osigbemhe** (won with a perfect 15/15 by **Yetunde "Yeti" Afolabi**, followed closely by **Gbenga "GB" Owoeye**).

A key question highlighted a common beginner misconception:
* **The Misconception:** *"Docker creates a new computer."*
* **The Reality:** Docker does **not** create a computer or a full virtualized machine. It creates an isolated **Linux user-space process** confined by kernel **cgroups** and **namespaces**.

---

## 2. Image Forensics: Inspecting Layers with `docker history`

Idowu demonstrated that every line in a `Dockerfile` leaves an immutable forensic footprint:

```bash
docker history <image_name_or_id>
```

### Why Enterprise Engineers Inspect Image History
1. **Auditing Upstream Bases:** Official and public images contain pre-configured environment variables (`ENV`), default working directories, and exposed ports.
2. **Security & Secrets Leak Detection:** Because Docker containers default to running as `root` (UID 0), attackers can embed malicious scripts or misconfigurations. Inspecting the build steps reveals every command executed during image assembly.

---

## 3. The Science of Docker Layer Caching & Invalidation

A major live experiment walked students through Docker's build cache behavior using two Python scripts: `hello.py` and `yeti.py`.

```
Dockerfile Build Stack:
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: FROM ubuntu:latest            (Cached: [1/3])      │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: COPY hello.py /hello.py       (Cached: [2/3]) ───┐ │
├─────────────────────────────────────────────────────────────┤     🚨 EDIT IN hello.py
│ Layer 3: COPY yeti.py /yeti.py         (Cached: [3/3]) ───┼─┼───> Invalidates Layer 2
└─────────────────────────────────────────────────────────────┘     AND forces Layer 3
                                                                    to rebuild!
```

### The Invalidation Chain Rule:
1. When Docker processes a `COPY` directive, it calculates a **checksum / byte comparison** of the source file's metadata and contents.
2. **The Domino Effect:** If layer $N$ has changed, **layer $N$ and every subsequent layer ($N+1, N+2, \dots$) are immediately invalidated** and re-executed.
3. **The Proof:**
   * Editing `hello.py` (Layer 2) caused Docker to re-copy `hello.py` **and** re-copy `yeti.py` (Layer 3), even though `yeti.py` was untouched.
   * Conversely, modifying only `yeti.py` (Layer 3) left Layer 1 and Layer 2 fully cached, rebuilding only the final step.

> 💡 **The Golden Rule of Dockerfile Optimization:** Order commands from the **least frequently changing** (base OS, package manager updates, library installs) to the **most frequently changing** (application source scripts) at the very bottom.

---

## 4. Real-World Context: Airflow & dbt in Production

To show why containerization is indispensable for data engineers, Idowu shared a production repository from his own work:

* **The Problem:** In Apache Airflow, DAG tasks running directly on host worker environments frequently suffer from conflicting Python dependencies (e.g., conflicting versions of Pandas, dbt, or cloud SDKs).
* **The Docker Solution:** By wrapping pipeline tasks inside Docker operators (`DockerOperator` / containerized task runners), each task executes inside its own pristine environment:
  * Task 1 can run Python 3.8 with legacy libraries.
  * Task 2 can run Python 3.11 with modern dbt-core.
  * **Result:** Total environmental isolation. No more *"It worked on my local machine but failed on the Airflow worker."*

---

## 5. Inside the Container: Inspecting and Interacting with `docker exec`

Idowu unpacked how to bridge your terminal into a running container's shell environment.

### Syntax Breakdown

```bash
docker exec -it <container_name_or_id> /bin/bash
```

* **`exec`:** Spawns a new process inside an already running container without restarting it.
* **`-i` (`--interactive`):** Keeps standard input (`STDIN`) open so the container can receive your keystrokes.
* **`-t` (`--tty`):** Allocates a pseudo-terminal (TTY), connecting your keyboard and terminal formatting to the container's shell.
* **`/bin/bash` or `/bin/sh`:** The target command interpreter invoked inside the container.

```
   Host Terminal (Local Keyboard)
                │
                ▼   (-it Flags)
   Allocates Pseudo-TTY & Keeps STDIN Open
                │
                ▼
   [ Container Namespace ] ── Spawns ──> /bin/bash (Interactive Shell as root)
```

### Debugging Scenario (Why Engineers Use `exec`):
When a containerized data pipeline crashes silently or throws an unexplained error:
1. Check the execution logs: `docker logs <container_id>`.
2. Exec into the container: `docker exec -it <container_id> /bin/bash`.
3. Verify files and dependencies directly: Check if configuration files landed in the expected directories and test CLI commands inside the isolated network.

---

## 6. `docker run` vs. `docker start`: The Car Analogy

A frequent point of confusion was clarified using an intuitive automotive analogy:

```
                  docker run
  [ Docker Image ] ─────────> [ New Running Container ]
                                     │
                                     │ docker stop
                                     ▼
                              [ Stopped Container ]
                                     │
                                     │ docker start
                                     ▼
                              [ Resumed Container ]
```

* **`docker run` (Buying & Assembly):** Takes an image (the blueprint), provisions fresh container storage and network namespaces, and fires up the root process for the first time.
* **`docker stop` (Turning off the Ignition):** Pauses and halts the running container process while retaining its local state in memory/disk.
* **`docker start` (Restarting the Engine):** Wakes up an *already existing, stopped container* using its existing ID without creating a new instance.

---

## 7. Best Practice: Isolating Code with `WORKDIR`

By default, Docker containers place user operations and copied assets into the system root directory (`/`).

### Why Operating in `/` is Hazardous:
* The root directory houses fundamental Linux operating system trees (`/bin`, `/etc`, `/lib`, `/proc`, `/sys`).
* Overwriting root system files can break the underlying OS image or open critical privilege-escalation vulnerabilities.

### The Fix: Declaring `WORKDIR`

```dockerfile
FROM ubuntu:latest

# Automatically creates /app and sets it as the active working directory
WORKDIR /app

# Copies files directly into /app (relative destination)
COPY hello.py .
COPY yeti.py .

CMD ["python3", "hello.py"]
```

### Key Behaviors of `WORKDIR`:
1. **Auto-Creation:** If the specified folder does not exist, Docker creates it automatically.
2. **Automatic Directory Navigation:** It acts like an implicit `cd`. Any subsequent `RUN`, `COPY`, `ADD`, or `CMD` directive executes relative to that directory.
3. **Nesting Behavior:** If consecutive relative `WORKDIR` directives are defined:
   ```dockerfile
   WORKDIR /app
   WORKDIR data
   # Active directory becomes: /app/data
   ```

---

## 8. Syntax Rules & Common Gotchas Log

| Topic / Command | Critical Rule / Gotcha | Why It Matters |
| :--- | :--- | :--- |
| **`Dockerfile` Naming** | Must be strictly named `Dockerfile` (capital `D`, lowercase `ockerfile`). | Case-sensitive; Docker CLI will not auto-detect `dockerfile` or `docker_file`. |
| **Alternative Dockerfiles** | Use `-f` to point to non-standard names: `docker build -f Dockerfile.new -t my_tag .` | Allows managing multi-stage or environment-specific builds in a single directory. |
| **The Trailing Dot (`.`)** | `docker build -t my_image .` | Specifies the **build context** (the directory sent to the Docker daemon to resolve relative `COPY` paths). |
| **Container IDs** | You only need to type the first 3–4 characters of a container ID (e.g., `1cf` instead of `1cf89a2b4...`). | Docker hashes are globally unique hex strings; typing the prefix is sufficient. |
| **Persistent Container Modifs** | Changes made inside a running container via `exec` (e.g., `apt install curl`) disappear if that container is destroyed. | To persist libraries across all container instances, declarations **must be written into the `Dockerfile` image layers**. |

---

## 9. Class Banter & Instructor Wisdom

* **"No Miracle Workers in Engineering":** You cannot serve a pizza without baking the dough; you cannot run a container without first building the image from a declarative Dockerfile.
* **"Take Your Life into Your Own Hands":** Never sit passively waiting for class recordings or handouts. Reach out proactively to peers and TAs (Leo, Charles, Chichi) to debug blockers immediately.
* **"Write to Solidify Knowledge":** Writing technical articles on LinkedIn, Substack, or Medium forces you to unpack low-level system abstractions (like Docker caching and Linux namespaces) in your own words.

---

## Comprehensive Student Action Plan

Before the upcoming sessions on **Volumes** and **Docker Compose**:
* [ ] Verify local installation of Docker Engine / Docker Desktop.
* [ ] Build a custom Python image utilizing `WORKDIR /app` and multi-file `COPY` instructions.
* [ ] Practice entering an active container using `docker exec -it <container_id> /bin/bash` and running `pwd` to confirm the active working directory.
* [ ] Test layer cache invalidation by modifying code at different positions in the build stack and observing terminal cache outputs (`CACHED` vs. re-execution).