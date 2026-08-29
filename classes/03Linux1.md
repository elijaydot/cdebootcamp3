## Overview
This session (Meeting Transcription) on 2026-08-21 continued a multi-part Linux module taught by Najeeb Sulaiman with support from Leo Osigbemhe and other facilitators; the instructor emphasized Linux fundamentals, why Linux matters for data engineers, and introduced the Linux filesystem and basic command-line usage. The goal is to get learners comfortable using Linux across roughly three class sessions and to prepare them to work with production servers and common data engineering tooling.

---

## Key objectives and framing
- Najeeb stated the module runs across approximately three sessions and aims to make participants comfortable with Linux so they can use it confidently for development, deployment, and interacting with production environments.
- Primary motivating questions: “Why should you care about Linux?” and “What is Linux?” — answers were framed specifically for data engineers and practitioners who primarily use Windows or macOS on their laptops.

---

## Why Linux matters (main reasons given)
1. Production parity and deployment:
   - Most servers and cloud virtual machines run Linux (Najeeb quoted “90+%” of servers), so understanding Linux is essential when you move code from local machines (Windows/macOS) to production.
   - Linux knowledge prevents environment mismatch and deployment pain.

2. Tooling ecosystem:
   - Many industry tools (Docker, Airflow, etc.) run natively on Linux or were built for Linux first; knowing Linux is often required to use or troubleshoot these tools.
   - Linux knowledge is described as a near-essential skill for modern data engineers.

3. Open-source advantages:
   - Linux is open source; large contributor base (Najeeb referenced Linux on GitHub with many contributors and commits).
   - Open-source nature leads to wide testing, customizability, reduced licensing costs, and suitability for organizations that want control over infrastructure.

4. Technical attributes:
   - Lightweight and customizable distributions (e.g., Alpine for containers, Kali for specific use cases).
   - Portability and dominance in server environments.
   - Considered secure partly due to design and community scrutiny.

---

## What Linux actually is (definitions and distinctions)
- Kernel vs Operating System:
  - Kernel (the “kernel” / “canal” in the talk) is the core program that manages hardware resources (CPU, memory, devices). Najeeb emphasized the kernel is analogous to an engine—it’s necessary but not a complete OS on its own.
  - GNU + Linux: The full operating system is the kernel plus utilities/libraries (GNU). The technically correct term is GNU/Linux, though people often say “Linux.”
- Kernel responsibilities explained:
  - Process scheduling and management
  - Memory management (isolation between programs)
  - Device control via drivers
  - Enforcing boundaries between processes (security/isolation)
- Difference from Unix:
  - Unix was earlier, and GNU/Linux takes influence from Unix; Linux (the kernel) and GNU utilities together produce modern Linux distributions.

---

## Linux distributions (distros)
- Explanation: distributions bundle the Linux kernel with different sets of utilities and UX choices; many distros exist to fit different use cases (desktop, server, lightweight containers, security, etc.).
- Examples mentioned: Ubuntu (popular desktop/server distro), Alpine (lightweight), Kali (security/hacking-focused).
- The kernel is the common ingredient across distributions; distributions use it but add different utilities and packaging.

---

## Open-source governance and maintenance
- Large contributor community: Najeeb referenced tens of thousands of contributors on the Linux GitHub (demonstrating community-driven maintenance).
- Maintenance structure: release/maintenance is coordinated by project maintainers/PMC (project management committees) who review and accept contributions (pull/merge requests). This governs how changes are validated and merged.
- Security and trust: openness increases peer review and validation; organizations choose Linux for control, customization, and reduced licensing costs.

---

## Linux filesystem (structure and conventions)
- Core idea: single-root tree (everything under “/”):
  - Contrast with Windows drive-letter model (C:\, D:\, etc.). Linux mounts devices into a single directory tree rooted at /.
  - Benefit: consistent absolute paths and easier reference across devices.
- Common top-level directories and their roles (overview, not exhaustive):
  - / — root of the filesystem
  - /bin — user binaries (commands like ls, pwd live here)
  - /sbin — system binaries (administrative commands)
  - /etc — configuration files
  - /dev — device files (devices appear here)
  - /proc — process and kernel virtual filesystem (process info)
  - /var — variable data (logs, databases)
  - /tmp — temporary files
  - /home — user home directories (e.g., /home/najeeb)
  - /boot — bootloader files
  - /lib — system libraries
  - /opt, /srv, /media — optional apps, service data, media mounts
- Hidden files: filenames beginning with a dot (.) are hidden by default (ls -a shows them).

---

## Command line, shells, and terminals — distinctions and anatomy
- Terminal vs Shell vs Shell implementation:
  - Terminal: the program/interface where you type commands (e.g., GNOME Terminal, iTerm).
  - Shell: the command interpreter that parses and executes commands (general concept).
  - Shell implementation: specific programs like bash, zsh, fish, PowerShell (Windows).
- Bash:
  - Bash = “Bourne Again SHell”; a very common Unix/Linux shell implementation.
  - Shells interpret user input and call programs (binaries) that exist on the filesystem (e.g., /bin/ls).
- Flow under the hood:
  - User types command in terminal → shell interprets → shell invokes the corresponding binary/program → kernel schedules execution and provides resources → output returns to shell → terminal displays results.
- Error differentiation examples:
  - “command not found”: the shell cannot locate an executable for the typed command (not a terminal issue).
  - Terminal problems (e.g., inability to type) are different from shell or program errors.
  - Permission or SSH failures come from the program (SSH) or system state, not typically from the terminal/shell itself.

---

## Basic commands and examples demonstrated
- Navigation and inspection:
  - pwd — print working directory (shows current absolute path)
  - ls — list directory contents
    - ls -a — include hidden files (dotfiles)
    - ls -l — long format (detailed listing: permissions, owner, size, timestamp)
    - ls -la (combined options)
  - cd <path> — change directory
    - Relative path example: cd utils (moves into a child directory)
    - Absolute path example: cd /home/najeeb/utils (root-based path)
    - cd .. — move up one level (parent directory)
    - cd ../.. — move up two levels
    - cd ~ — shortcut to home directory
    - cd / — go to root
- File locations:
  - Demonstration showing that common commands (ls, pwd, etc.) are files/binaries in /bin (or similar directories).
- Tab completion: pressing Tab autocompletes filenames/paths.
- Dotfiles: explained as hidden files; ls -a reveals them.

---

## Remote server demonstration and SSH
- Najeeb demonstrated connecting to a rented virtual server (VPS) via SSH (example IP: 91.98.230.160) and showed the remote system’s welcome message (Ubuntu).
- SSH: explained as a program (secure shell) used to connect to remote machines; it may be configured with key-based authentication (Najeeb noted he had SSH keys set up so it didn’t prompt for a password).
- Clarifications:
  - SSH failures (permission denied, connection errors) are caused by networking, authentication, or SSH-program-level issues — not the shell or terminal itself.

---

## Shell/case-sensitivity, environment differences, and cross-platform notes
- Case sensitivity: Linux commands and paths are case-sensitive (e.g., CD vs cd matters in Linux shells).
- macOS and Linux share Unix roots; many commands are similar but behavior and filesystem layout may differ.
- Windows support:
  - Windows has its own shell/terminal ecosystem (PowerShell, Command Prompt).
  - Tools such as Git Bash or WSL (Windows Subsystem for Linux) provide partial or full Linux-like environments on Windows; not all Linux commands are guaranteed to behave identically on these environments.
- zsh vs bash: macOS may default to zsh; participants using macOS saw zsh in their terminal prompt (behavior similar but not identical to bash).

---

## Questions raised and notable answers
- Why do servers run Linux while consumer machines run Windows/macOS?
  - Answer: Linux’s open-source, licensing, customization, stability, performance, and server-centric toolchain make it the dominant choice for servers.
- How is security high if Linux is open source?
  - Answer: Open-source development enables extensive peer review and testing by a large community, often increasing transparency and rapid fixes.
- How are changes controlled given vast numbers of contributors?
  - Answer: Project maintainers and PMC-style governance review and accept contributions through the established process (pull/merge requests).
- How to differentiate terminal vs shell vs program errors?
  - Answer: Understand the stack (terminal → shell → program → kernel); error messages and behavior indicate which layer is at fault (e.g., “command not found” originates from the shell).
- Cross-platform command behavior (Windows Git Bash/WSL):
  - Answer: These environments emulate or provide Linux command behavior on Windows; some commands can work in Git Bash but not all; WSL provides a more integrated Linux userland on Windows.
- Practicalities:
  - Tab completion, using relative vs absolute paths, and using shortcuts like ~ for home were demonstrated and recommended for learning-by-doing.

---

## Action items & next steps
- Continue the Linux module across the planned sessions.
- Hands-on practice: participants were encouraged to follow along with commands in their own terminals (Linux, macOS, or WSL/Git Bash) to reinforce learning.
- Research further on environment-specific questions (e.g., Git Bash behavior, SSH key setup, WSL differences).

---