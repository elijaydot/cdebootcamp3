# Core Data Engineers (CDE) Bootcamp — Linux Deep Dive & System Administration

**Session Date:** August 24, 2026  
**Instructor:** Najeeb Sulaiman  
**Duration:** 113 Minutes  
**Focus Areas:** Linux User & Group Management, Superuser Privileges (`sudo`), File & Directory Permissions (Symbolic & Octal Modes), Debian Package Management (`apt`), and Practice Platforms.

---

## 1. Executive Summary & Context

The session served as an in-depth, hands-on Linux administration masterclass tailored for aspiring data engineers. Emphasizing terminal comfort and the practicalities of production server administration, the lecture explored:
- Multi-user server operations and access control using the **DRY (Don't Repeat Yourself)** principle.
- The mechanics of privilege escalation (`sudo`), the dangers of logging directly into the `root` account, and safe sudoer configuration management via `visudo`.
- Comprehensive file and directory permission systems, breaking down `ls -l` outputs, symbolic mode operations, and the binary mathematics behind octal permission sets.
- Package lifecycle management on Debian-based distributions (`apt update`, `apt upgrade`, `apt install`, `apt remove`).
- Recommended practice repositories and interactive data engineering platforms like PraxiCraft.

---

## 2. User & Group Administration

### 2.1 The "Don't Repeat Yourself" (DRY) Philosophy in Access Management
On multi-user Linux environments (e.g., hosting database engines, Airflow schedulers, or data pipelines), individual permission assignment is inefficient and error-prone. If a team has 10 data engineers, manually granting access to each engineer 10 times violates the DRY principle. By grouping users, administrators manage permissions collectively:
- **Adding an engineer:** Simply add the user to the target group.
- **Offboarding an engineer:** Remove the user from the group.

### 2.2 Key Configuration Files
- `/etc/passwd`: Stores user account details (UID, GID, home directory, default shell).
- `/etc/group`: Stores group definitions and membership rosters.

### 2.3 Command Reference: User & Group Management

| Action | Command | Explanation |
| :--- | :--- | :--- |
| **Create Group** | `sudo groupadd cde` | Creates a new group named `cde`. |
| **Inspect Memberships** | `groups <username>` | Lists all groups to which `<username>` belongs. |
| **Append User to Group** | `sudo usermod -aG cde <username>` | Appends (`-a`) the user to the supplementary group (`-G`). **Warning:** Omitting `-a` will overwrite existing groups. |
| **Remove User from Group** | `sudo gpasswd -d <username> cde` | Deletes (`-d`) the user from the specified group without removing the user account. |
| **Delete Group** | `sudo groupdel cde` | Removes the group definition from the system. |
| **Delete User Account** | `sudo userdel <username>` | Removes user login privileges while preserving home directories and data. |
| **Delete User & Data** | `sudo userdel -r <username>` | Recursively deletes the user account alongside their home directory `/home/<username>`. |

### 2.4 Data Persistence Post-User Deletion
When deleting a user with standard `userdel`, Linux retains their home directory and created resources by default. This safeguards data, running processes, and application files from accidental data loss. Cleanup of orphaned directories can be performed manually via `rm -r /home/<username>` by an administrator when confirmed.

---

## 3. Superuser Privileges: Demystifying Sudo & Root

### 3.1 Principle of Least Privilege: Why Avoid Direct Root Logins?
The `root` user represents the unrestricted superuser of the Linux system.
- Direct root logins are dangerous because simple typos (e.g., `rm -rf /`) can destroy an entire environment.
- Root credentials must remain protected.
- Industry best practice requires administrative engineers to work under standard named user accounts, explicitly calling `sudo` (SuperUser DO) only for elevated operations.

### 3.2 The Sudoers File (`/etc/sudoers`)
The sudoers configuration controls fine-grained superuser privileges:
- Direct user rules: `root ALL=(ALL:ALL) ALL` (specifies user without `%`).
- Group-level rules: `%sudo ALL=(ALL:ALL) ALL` or `%cde ALL=(ALL:ALL) ALL` (prefixed with `%` to denote group inheritance).
- Passwordless execution: Adding the `NOPASSWD:` tag allows specific automated tasks or trusted users to run commands without repetitive password prompts.

### 3.3 Safe Configuration with `visudo`
Directly editing `/etc/sudoers` with generic editors like `nano` can result in syntax errors that lock administrators out of `sudo` entirely. The dedicated tool `visudo`:
- Locks the sudoers file against concurrent edits.
- Performs rigorous syntax parsing upon saving.
- Prompts for immediate correction if invalid entries are detected before applying changes.

---

## 4. File & Directory Permissions: Deep Dive

### 4.1 Permission Categories & Action Matrix
Permissions are assigned across three distinct entity levels:
1. **User (`u`)**: The owner/creator of the file or directory.
2. **Group (`g`)**: The group associated with the file.
3. **Others (`o`)**: Every other user account on the operating system.

| Permission | Representation | Action on Files | Action on Directories |
| :---: | :---: | :--- | :--- |
| **Read** | `r` | View/read contents of the file. | List directory contents (`ls`). |
| **Write** | `w` | Modify, edit, truncate, or delete the file. | Create, delete, or rename files within the directory. |
| **Execute** | `x` | Run the file as an executable program/script. | Enter/traverse the directory (`cd`). |

### 4.2 Anatomy of `ls -l`
Executing `ls -l` provides the detailed attribute string:
```text
- r w x r - x r - -  1  najeeb  najeeb  47  Aug 22 07:21  file.txt
┬ └──┬──┘ └──┬──┘ └──┬──┘
│    │       │       └── Others: Read-only (r--)
│    │       └────────── Group: Read & Execute (r-x)
│    └────────────────── User/Owner: Read, Write & Execute (rwx)
└─────────────────────── File Type: '-' for File, 'd' for Directory
```

### 4.3 Permission Modification via Symbolic Mode (`chmod`)
Symbolic mode uses reference characters (`u`, `g`, `o`, or omitted for all) and operators (`+` to add, `-` to remove, `=` to set explicitly):
- `chmod u+x file.txt` — Adds execute permission for the file owner.
- `chmod o-w file.txt` — Removes write permissions from others.
- `chmod +x script.sh` — Adds execute permissions across User, Group, and Others.
- `chmod g=rw file.txt` — Explicitly sets the group permissions to read and write only.

### 4.4 Permission Modification via Octal (Numeric) Mode
Octal mode maps permissions to a 3-bit binary system:
- **`r` (Read)** = $2^2 = 4$
- **`w` (Write)** = $2^1 = 2$
- **`x` (Execute)** = $2^0 = 1$
- **No Access** = $0$

By summing values for User, Group, and Others, a 3-digit number is formed:

| Octal Sum | Binary Form | Permissions | Meaning |
| :---: | :---: | :---: | :--- |
| **7** | `111` | `rwx` | Full read, write, and execute privileges ($4+2+1$). |
| **6** | `110` | `rw-` | Read and write privileges ($4+2$). |
| **5** | `101` | `r-x` | Read and execute privileges ($4+1$). |
| **4** | `100` | `r--` | Read-only privilege ($4$). |
| **3** | `011` | `-wx` | Write and execute privileges ($2+1$). |
| **2** | `010` | `-w-` | Write-only privilege ($2$). |
| **1** | `001` | `--x` | Execute-only privilege ($1$). |
| **0** | `000` | `---` | No privileges ($0$). |

#### Common Industry Configurations:
- `chmod 600 config.key` — Read and write for the owner only; zero access for all others (used for private keys/credentials).
- `chmod 755 run_pipeline.sh` — Full access for owner; read and execute for group and others (standard script setup).
- `chmod 711 restricted.sh` — Full access for owner; execute-only access for group and others.

---

## 5. Debian Package Management (APT)

### 5.1 Open Source Packaging Architecture
Unlike Windows environments that rely on licensed, closed-source desktop software, Linux environments are lean and modular. Linux distributions ship with minimal core utilities and rely on package managers to fetch open-source tools from centralized online repositories.

### 5.2 APT (Advanced Package Tool) Workflow
On Debian and Ubuntu systems, `apt` serves as the primary package manager:

```bash
# 1. Update the local index metadata from remote repositories
sudo apt update

# 2. Upgrade installed packages to their latest versions and security patches
sudo apt upgrade

# 3. Install a new package (e.g., nano text editor or htop monitor)
sudo apt install nano

# 4. Remove a package from the system
sudo apt remove nano
```

*Note:* Searching and auditing Ubuntu package repositories can also be performed via web at `https://packages.ubuntu.com/`.

---

## 6. Curated Resources & Practice Platforms

1. **Official Bootcamp GitHub Repository:**  
   Review, clone, and star the official curated curriculum and exercises:  
   👉 [Core Data Engineers - Linux Module](https://github.com/coredataengineers/CDE-BOOTCAMP/tree/main/01_linux)

2. **Interactive Terminal Sandbox — PraxiCraft:**  
   A specialized hands-on platform designed for data engineers with realistic production tasks, automated test feedback, and AI code review:  
   👉 [PraxiCraft Platform](https://praxicraft.com/)
