## Overview
The session on 2026-08-22 reviewed Linux fundamentals with hands‑on demonstrations covering shells vs terminals, kernel responsibilities, file and directory operations, text editing/viewing tools, redirection/pipes, searching and text processing, command chaining, environment variables, and basic user management. Instructors (primarily Edeki Charles and Najeeb Sulaiman) answered participant questions and demonstrated commands live on a Linux machine, emphasizing practical usage and safety (sudo, rm -r, etc.).


## Key Topics Covered

- Shell vs Terminal
  - "shell" is a command interpreter; "terminal" is the program/window that runs the shell. Shells are implementations of the command interpreter and the terminal is the interface.
  - Examples of shells mentioned: bash, fish, zsh, csh/corn shell, PowerShell (Windows).

- Why Linux is considered secure
  - Open-source advantages: a large community audits, contributes, debugs, and reports issues compared to closed‑source OSes.

- Kernel responsibilities and device drivers
  - Kernel acts as a middleman between applications and hardware (keyboard, mouse, screen, network card, disks).
  - Device drivers enable software to communicate with hardware; kernel manages driver access and permissions.

- Command-line basics & file operations (demonstrated by Najeeb)
  - Creating files:
    - touch file.txt (create empty file)
    - touch can create multiple files in one command (touch a b c)
  - Editing files:
    - nano file.txt (simple text editor demo: Ctrl+X, Y to save, supply filename)
    - vim referenced as more powerful but more complex
  - Viewing files:
    - cat file.txt (show full contents)
    - tac file.txt (reverse order of lines)
    - head -n 5 file.txt (first N lines) and tail -n 5 file.txt (last N lines)
    - tail -f file.log (follow file, continuous monitoring)
    - more (page output), less (pager with up/down navigation)
  - Redirection:
    - command > file (overwrite destination file)
    - command >> file (append to destination file)
    - examples showed risk of accidentally overwriting files and recommended caution
  - Pipes and command chaining:
    - && : run second command only if first succeeds
    - || : run second command only if first fails
    - ;  : run commands sequentially regardless of success
    - |  : pipe output of one command into another
    - Using ! and !! shortcuts to reference previous shell commands (e.g., !! to re-run last command, !n to run nth from history)

- Searching & text processing
  - grep: search within files (case-sensitive by default; -i for case-insensitive; -r for recursive)
    - Example: grep -r "CDE" cde/
  - find: locate files by name or pattern (find . -name "*.txt")
  - Practical examples: search for text inside many files, find files matching name patterns, then operate on matched files (copy/delete).
  - Distinction clarified: grep searches file content; find searches filenames across directories.

- File and directory manipulation
  - mkdir dir_name
  - cp source destination (copy file)
  - mv source destination (move/rename; removes original)
  - cp -r source_dir dest_dir (recursive copy of directory contents)
  - rm -r dir (recursive remove; caution: destructive)
  - rm -rf (force recursive remove) — strong caution: deleted data is generally gone (recovery possible but not trivial).
  - rsync suggested by participants as alternative for syncing/copying (preserves deltas).

- History, help and discovery tools
  - history navigation (up/down arrows), !! and !n shortcuts to reuse previous commands
  - man <command> for manual pages (detailed docs and options)
  - <command> --help or command -h for quick help
  - apropos <keyword> to find commands by description when you know what you want to do but not the command name

- Environment variables
  - Viewing: env or printenv
  - Setting for session: export VAR_NAME=/path/to/value (no spaces around =)
  - Referencing: echo $VAR_NAME
  - Unset/remove: unset VAR_NAME
  - Purpose: system- or session-wide key/value pairs accessible to processes; used for configuration, paths, credentials (but be cautious storing secrets in env vars).
  - Notes: export makes variable available to child processes for the session; persistence requires adding to profile files (not covered in depth).

- User & group basics (introductory demonstration)
  - Concepts:
    - user = identity (person or service account)
    - group = collection of users that share permissions
    - root = superuser (full privileges); recommended NOT to log in directly as root
  - Creating users:
    - adduser username (interactive, creates home dir and prompts for details)
    - useradd username (lower-level; may not create home dir by default)
    - sudo required for user management (permission model demonstration)
  - Inspecting users:
    - /etc/passwd contains user account entries (username, uid, gid, home dir, default shell)
    - /etc/shadow stores encrypted passwords (not human-readable)
  - Modifying users:
    - usermod -s /bin/bash username (change default shell)
    - usermod -l newname oldname (rename user) — participants reported process-in-use warnings when attempting rename
    - passwd username to set or change password
  - Switching users:
    - su - username (switch user; may require password)
    - sudo su - or sudo <command> to perform privileged actions (sudo is preferred over direct root login)
  - Behaviour differences across environments:
    - Several participants using Windows Git Bash, macOS, or WSL observed some commands differ or are unavailable (e.g., adduser not found); instructor recommended using a proper Linux environment (WSL, VM, remote Linux server) for full parity.

## Demos, Live Commands & Examples (selected)
- touch data.txt; touch data1.txt data2.txt data3.txt
- cat file.txt; tac file.txt
- nano file.txt (save via Ctrl+X, Y, ENTER)
- echo "Hello" > out.txt  (overwrite)
- echo "More" >> out.txt  (append)
- head -n 5 logfile; tail -n 5 logfile; tail -f /var/log/syslog (with sudo when required)
- ls -la; mkdir CDE; cp data.txt CDE/; mv data2.txt CDE/; cp -r CDE CD2/
- rm -r CDE/  (demonstrated with caution)
- grep -r "CDE" cde/  (recursive content search)
- find . -name "*.txt"
- export DATA_DIR=/home/node/data ; echo $DATA_DIR ; unset DATA_DIR
- sudo adduser uche  (demonstrated; interactive)
- sudo useradd temitope  (created without interactive prompts; then sudo passwd temitope; sudo usermod -s /bin/bash temitope)
- man ls and ls --help for help/manpage discovery
- apropos user to discover user-related commands

## Questions Raised and Clarifications Given
- Why is Linux more secure? (Open-source community auditing vs closed-source limited auditing) — Edeki
- Kernel vs drivers vs applications; how programs talk to keyboard/mouse/screen — explained with driver + kernel as middleman.
- Shell vs terminal differences — Raphael explained clearly.
- Why commands behave differently on Windows Git Bash / macOS: some utilities are missing or behave differently; recommended proper Linux environment (WSL, VM, remote Linux server) for parity.
- How to append vs overwrite with > and >>; strong caution about accidental overwrite.
- How to follow logs in real time (tail -f), how to show only top/bottom lines (head/tail).
- How to reuse previous commands: history, up arrow, !!, !n.
- How to search recursively inside files (grep -r) vs finding filenames (find -name).
- How to create users, difference between adduser and useradd, need for sudo, /etc/passwd and /etc/shadow contents, changing default shell (usermod -s), renaming users (usermod -l) and related issues (process in use).
- Is there a recycle bin for rm -r? No — deletion is permanent at filesystem level (recovery possible but complex), so use rm -r with caution.
- Best practice: avoid logging in as root; use sudo for privileged operations to add an extra deliberate step.

## Action Items & Recommendations
- Practice the demonstrated commands in a proper Linux environment (WSL, virtual machine like VirtualBox, or remote Linux server) — many reported Git Bash / macOS differences.
- Rewatch the recording and review the posted slides locally to reinforce learning.
- Practice objectives:
  - Create, edit, view, append, and remove files using touch, nano, cat, head, tail, more, less, echo, >, >>.
  - Use grep and find for content/name searches (including -i and -r flags).
  - Use cp, mv, mkdir, rm (with -r) and cp -r for directory recursion.
  - Explore man pages and apropos for discovering commands and options.
  - Practice creating/modifying users (adduser/useradd, passwd, usermod) in a safe environment.
  - Use environment variables (export, echo $VAR, unset) and understand session vs persisted variables.

---