# CDE Bootcamp 3.0: Terraform Finale — Input Variables, Enterprise GitOps Guardrails, CI Linting & Live Atlantis Pull Request Battles

> *"In a real engineering team, you never push directly to `main`, you never hardcode repeated values across fifty files, and you never bypass CI checks. When five engineers open Pull Requests simultaneously against the same cloud state, the winners are the ones who understand `git pull`, state locking, and how to read a `terraform plan` diff before hitting apply."*
>
> — **Mayowa Akinyele**

**Date:** November 16, 2026  
**Duration:** 133 Minutes  
**Lead Instructor:** Mayowa Akinyele (Opening Quiz & PR Reviews by Abdulhakeem Salaudeen)  
**Curriculum Module:** 10 Infrastructure as Code (IaC) — Terraform Finale: Input Variables (`variables.tf`), Repository Governance (`CODEOWNERS` & Branch Rulesets), Automated CI Linting Pipelines (GitHub Actions), and Live Multi-Engineer Collaborative Pull Request Simulations with Atlantis

---

## Executive Overview & Class Atmosphere

As the grand finale of the **Terraform & Infrastructure as Code** module (right before diving into **Apache Spark** distributed processing and the final **Capstone Project**), this session brought together everything students learned over the past week into a high-stakes, real-world production simulation.

Mayowa began by introducing **Terraform Input Variables** (`variables.tf`), showing how to eliminate repetitive hardcoding across large infrastructure repositories. He then pulled back the curtain on **enterprise GitHub repository governance**—revealing the exact `CODEOWNERS` files, branch protection rulesets, stale-approval dismissals, and **GitHub Actions CI Linter workflows** (`terraform fmt -check` and `terraform validate`) protecting production infrastructure.

To cement the lessons, Mayowa first played the role of a developer making a deliberate formatting mistake on a Pull Request to demonstrate how CI blocks bad code. Then, he threw open the live shared repository (`coredataengineers/cde-data-infrastructure`) to the students—triggering an unforgettable, chaotic, real-world multi-engineer Pull Request battle complete with **Atlantis state locks**, **`atlantis unlock` rescues**, **invalid EC2 AMI errors**, **S3 `BucketAlreadyOwnedByYou` collisions**, and **un-pulled branch drift**.

---

## Part 1: Warm-Up Quiz — Resource Referencing, SSM & Remote Backends Recap
*(Facilitated by Abdulhakeem Salaudeen)*

The session opened with an interactive Slido quiz testing retention from Saturday’s deep dives:

1. **Dynamic Resource Referencing:**
   * Rather than hardcoding resource names or ARNs, referencing `<RESOURCE_TYPE>.<LOCAL_NAME>.<ATTRIBUTE>` dynamically links resources and automatically builds Terraform's execution dependency graph.
2. **Securing Database Credentials in Production:**
   * Never hardcode passwords in `.tf` files or expose them in `providers.tf`. Generate passwords dynamically (`random_password`) and store them securely in **AWS Systems Manager (SSM) Parameter Store** (`aws_ssm_parameter`).
3. **Pull Request Approval vs. Resource Provisioning:**
   * Approving a Pull Request on GitHub **does not create cloud resources**. Provisioning occurs only when **`atlantis apply`** (or `terraform apply`) is executed against the approved plan.
4. **Why S3 Buckets Use Random Suffixes:**
   * Because **S3 bucket names must be globally unique across all AWS accounts worldwide**, appending random suffixes prevents `BucketAlreadyOwnedByYou` collisions.
5. **Terraform Remote Backends:**
   * Configuring a `backend "s3"` block moves `terraform.tfstate` off local laptops into a centralized, versioned cloud bucket for team safety.
   * *Quiz Winners:* **Small Osas (Olugbade Waziri)**, **Big Osas (Osakpolor Ogieriakhi)**, **Roqeeb Olaniran**, and **Temitope Asama** 🏆

---

## Part 2: Eliminating Repetition with Terraform Input Variables (`variables.tf`)

In production repositories containing dozens of S3 buckets, EC2 instances, IAM roles, and databases, repeating identical tags (`Team = "Data Engineering"`, `Environment = "Production"`, `ManagedBy = "Terraform"`) or region strings in every single block violates the **DRY (Don't Repeat Yourself)** engineering principle.

```
[ variables.tf ] (Single Source of Truth)
  ├── variable "team"        { default = "Data Platform Team" }
  ├── variable "environment" { default = "Production" }
  └── variable "managed_by"  { default = "Terraform" }
               │
               ├──────────────────────────┬──────────────────────────┐
               ▼                          ▼                          ▼
  [ datalake.tf ]            [ airbyte.tf ]             [ redshift.tf ]
  tags = {                   tags = {                   tags = {
    Team = var.team            Team = var.team            Team = var.team
  }                          }                          }
```

### How Input Variables Work:
1. **Declaration (`variables.tf`):** Define reusable inputs inside a dedicated `variables.tf` file using `variable "<NAME>"` blocks:
   ```hcl
   variable "environment" {
     description = "Deployment environment (e.g., Production, Staging)"
     type        = string
     default     = "Production"
   }

   variable "team" {
     description = "Owning engineering squad for FinOps cost allocation"
     type        = string
     default     = "Data Engineering"
   }

   variable "managed_by" {
     description = "Provisioning tool identifier"
     type        = string
     default     = "Terraform"
   }
   ```
2. **Consumption (`var.<VARIABLE_NAME>`):** Reference those variables anywhere in your `.tf` files using the `var.` prefix:
   ```hcl
   resource "aws_s3_bucket" "airflow_logs" {
     bucket = "cde-airflow-logs-prod-2026"

     tags = {
       Team        = var.team
       Environment = var.environment
       ManagedBy   = var.managed_by
     }
   }
   ```
3. **Instant Global Updates:** If your squad is renamed from `"Data Engineering"` to `"Data Platform Team"`, you update **one single line** in `variables.tf`, and Terraform propagates the tag update across hundreds of cloud resources on the next `apply`.

> 🔗 **Official Terraform Docs:** [Terraform Input Variables Documentation](https://developer.hashicorp.com/terraform/language/values/variables)

---

## Part 3: Enterprise GitHub Repository Governance & Guardrails

Before letting engineers collaborate on a shared infrastructure repository (`coredataengineers/cde-data-infrastructure`), platform leads lock down the repository with four layers of automated protection:

```
[ Engineer Feature Branch ] ──git push──► [ GitHub Pull Request ]
                                                │
       ┌────────────────────────────────────────┼────────────────────────────────────────┐
       ▼                                        ▼                                        ▼
[ 1. Branch Ruleset ]                [ 2. CODEOWNERS File ]                 [ 3. GitHub Actions CI ]
- Direct push to `main` BLOCKED      - Auto-assigns Senior Leads            - Runs `terraform fmt -check`
- PR required before merge           - Self-approval strictly blocked       - Runs `terraform validate`
- Dismisses stale approvals on push  - Requires 1+ Code Owner approval      - Blocks merge if Red ❌
```

### 1. `.gitignore` Protection:
* Explicitly ignores `.terraform/` (heavy provider binaries) and `*.tfstate*` (sensitive state files containing plain-text secrets) so they are never committed to version control.
### 2. `CODEOWNERS` File:
* Located in `.github/CODEOWNERS` (or root). Automatically assigns designated senior leads (e.g., Mayowa, Abdulhakeem, Rofiat) as mandatory reviewers whenever any `.tf` file is modified—preventing engineers from approving their own Pull Requests.
### 3. Branch Protection Rulesets (Protecting `main`):
* **Block Direct Pushes:** Nobody can run `git push origin main`. All changes must arrive via a feature branch Pull Request.
* **Require Code Owner Approval:** At least one designated Code Owner must formally approve the PR.
* **Dismiss Stale Pull Request Approvals:** If an engineer gets their PR approved, and then pushes a new commit modifying the code, GitHub **automatically revokes the prior approval** and forces a fresh review!
* **Require Status Checks to Pass:** GitHub blocks merging (and Atlantis blocks `atlantis apply`) until all automated CI checks turn green.

---

## Part 4: Automated CI Linting Pipeline (`terraform_linter`)

Mayowa demonstrated a **GitHub Actions CI workflow** triggered automatically whenever a Pull Request touches any file ending in `.tf`:

```yaml
# .github/workflows/terraform_ci.yml (Conceptual Pipeline Flow)
on:
  pull_request:
    paths:
      - '**.tf'

jobs:
  terraform_linter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Check HCL Formatting
        run: terraform fmt -check -recursive
      - name: Initialize & Validate Syntax
        run: |
          terraform init -backend=false
          terraform validate
```

### How the CI Linter Protects Production:
1. **`terraform fmt -check -recursive`:** Scans every `.tf` file in the repository. If even one line has sloppy indentation or misaligned `=` signs, the CI job **fails immediately** and highlights the exact line diff in the GitHub Actions log.
2. **`terraform validate`:** Verifies HCL syntax, unclosed braces, and valid resource argument schemas.
3. **Hard Gate on Atlantis:** Even if a senior lead clicks "Approve" on your PR, **Atlantis refuses to run `atlantis apply`** while the CI status check is red (`Pull request must be mergeable before running apply`).

---

## Part 5: Lessons from the Live Multi-Engineer Atlantis Battle

During the live classroom exercise, multiple students cloned `cde-data-infrastructure` simultaneously and opened Pull Requests—exposing four real-world collaborative pitfalls that every cloud engineer must know how to handle:

### 1. The Atlantis Project Lock (`atlantis unlock`)
* **What Happened:** When Waziri opened the first Pull Request modifying `production/datalake.tf`, Atlantis acquired a **directory lock** on `production/` so no two Pull Requests could modify the same state simultaneously. When Roqeeb opened a second PR targeting `production/`, Atlantis halted his plan with: *"This project is currently locked by PR #X."*
* **How to Resolve:** In production, message the teammate holding the lock on Slack to coordinate. Once agreed, comment **`atlantis unlock`** on the blocking PR to discard its stale plan and release the lock, then comment **`atlantis plan`** on your own PR.

### 2. The "Merge Without Apply" Drift Trap
* **What Happened:** One student's PR was approved and **merged into `main` without running `atlantis apply` first**.
* **The Consequence:** The `.tf` code on `main` claimed an S3 bucket existed, while AWS had **never provisioned it**. When the next engineer ran `git pull` and opened a new PR to create an IAM user, Atlantis's `terraform plan` unexpectedly showed `2 to add` (their IAM user *plus* the un-applied S3 bucket from the previous merged PR!).
* **Golden Rule:** Always execute **`atlantis apply`** and verify green success **before** clicking **Merge pull request** on GitHub!

### 3. The "Forgot to `git pull`" Destruction Trap
* **What Happened:** After Engineer A applied and merged a new resource into `main`, Engineer B pushed a feature branch created from an outdated `main` branch without running `git pull origin main`.
* **The Consequence:** Because Engineer B's `.tf` files did not contain Engineer A's newly merged resource, Terraform compared Engineer B's outdated code against the live remote S3 state file and planned `1 to destroy`—threatening to wipe out Engineer A's live infrastructure!
* **Golden Rule:** Always run `git checkout main && git pull origin main` (or rebase your feature branch) before pushing updates.

### 4. Invalid Resource Arguments (`InvalidAMIID.NotFound` & `BucketAlreadyOwnedByYou`)
* **What Happened:** Students attempting to provision an EC2 instance using a copied AMI ID from another AWS region hit `InvalidAMIID.NotFound` during `atlantis apply` (because AMI IDs are strictly region-specific). Another student reused an existing S3 bucket name, hitting `BucketAlreadyOwnedByYou`.
* **Lesson Learned:** Passing `terraform validate` only checks HCL syntax—cloud provider API constraints (like region-specific AMIs or globally unique S3 bucket names) are validated only when AWS executes `apply`.

---

## Part 6: Comprehensive Student Q&A Index

| Student | Core Question | Mayowa's Technical Clarification |
| :--- | :--- | :--- |
| **Temitope Asama** | *Why didn't we need an `import` statement at the top of `datalake.tf` to read `variables.tf`?* | Terraform automatically loads and merges **all `.tf` files** in the working directory into a single namespace, so `var.<NAME>` works seamlessly across any file in the same folder. |
| **Josephine Adah** | *Why do we use `var.<NAME>` instead of `variable.<NAME>`, and is `variables.tf` mandatory?* | `var.` is Terraform's built-in interpolation prefix for reading input variables. Naming the file `variables.tf` is a universal industry convention so teammates immediately know where inputs are declared. |
| **Yezid Olanase** | *Can a single `variable` block hold multiple values, or how do we handle deploying resources across different AWS regions?* | A `variable` block holds one value (or a structured list/map), with `default` acting as its fallback value. For multi-region deployments, teams either configure provider aliases or organize separate folders per region (e.g., `eu-north-1/`, `eu-central-1/`). |
| **AbdulRasaq Bilau** | *Are Terraform variables strictly for tags, or can they be used anywhere?* | Variables can be used for **any** argument in Terraform—bucket names, EC2 instance types (`var.instance_type`), CIDR blocks (`var.vpc_cidr`), database storage sizes, and tags. |
| **Roqeeb Olaniran** | *When we fixed the formatting error and pushed a new commit to the same PR, why did we need a new approval?* | Because the repository ruleset had **Dismiss stale pull request approvals when new commits are pushed** enabled—ensuring nobody can get an innocent PR approved and then sneak malicious code into a follow-up commit. |
| **Osakpolor Ogieriakhi (Osas)** | *Why not automate `atlantis apply` immediately upon PR approval so humans never forget to apply before merging?* | Making `atlantis apply` an explicit human command gives engineers granular control—allowing them to inspect the final plan, apply multi-step changes incrementally, and coordinate timing during active deployment windows. |
| **Abdulsamad Ibrahim** | *How can teams replicate this workflow using standard CI/CD (GitHub Actions) instead of Atlantis?* | Teams can configure a GitHub Actions workflow triggered on `pull_request` (running `fmt`, `validate`, and `plan`) and a second workflow triggered on `push` to `main` (running `terraform apply -auto-approve`) using OIDC IAM roles. |
| **Roqeeb Olaniran** | *Isn't it risky that any teammate can run `atlantis unlock` on another person's PR?* | Atlantis logs the exact GitHub user who ran `atlantis unlock` in the PR audit trail and notifies the PR author. In engineering teams, technical guardrails work alongside professional communication—always message the PR owner before unlocking. |
| **Zainab Olamiji** | *Does the CI linter catch if an S3 bucket name already exists in AWS?* | **No.** The CI linter (`terraform fmt` and `terraform validate`) runs offline syntax checks only. Cloud-level conflicts like duplicate S3 bucket names surface during `plan` or `apply` when talking to AWS APIs. |

---

## Part 7: Hands-On Labs & Live Demos — Step-by-Step Execution Guide

This section provides complete, reproducible guides for both demonstrations conducted during the finale session.

### Demo 1: Refactoring Hardcoded Infrastructure Using `variables.tf`

#### Objective:
Create a multi-resource Terraform configuration (`aws_s3_bucket` and `aws_ssm_parameter`), extract repeated tags and region values into `variables.tf`, and verify dynamic propagation via `terraform plan`.

#### Step-by-Step Instructions:

1. **Create a Clean Project Directory:**
   ```bash
   mkdir quick-variables
   cd quick-variables
   code .
   ```

2. **Create `variables.tf`:**
   Define reusable variables for your AWS region and FinOps tags:
   ```hcl
   variable "aws_region" {
     description = "Target AWS deployment region"
     type        = string
     default     = "eu-north-1"
   }

   variable "team" {
     description = "Owning engineering team"
     type        = string
     default     = "Data Engineering"
   }

   variable "environment" {
     description = "Deployment environment"
     type        = string
     default     = "Production"
   }

   variable "managed_by" {
     description = "IaC management tool"
     type        = string
     default     = "Terraform"
   }
   ```

3. **Create `providers.tf` Referencing `var.aws_region`:**
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 6.0"
       }
     }
   }

   provider "aws" {
     region = var.aws_region
   }
   ```

4. **Create `datalake.tf` Using Shared Tag Variables:**
   ```hcl
   resource "aws_s3_bucket" "airflow_logs" {
     bucket = "cde-airflow-logs-var-demo-2026"

     tags = {
       Team        = var.team
       Environment = var.environment
       Service     = "Airflow"
       ManagedBy   = var.managed_by
     }
   }

   resource "aws_ssm_parameter" "pipeline_config" {
     name  = "/production/data-engineering/airflow/env"
     type  = "String"
     value = var.environment

     tags = {
       Team        = var.team
       Environment = var.environment
       ManagedBy   = var.managed_by
     }
   }
   ```

5. **Initialize and Preview Variable Substitution:**
   ```bash
   terraform init
   terraform plan
   ```
   * **Observation:** Inspect the `tags` block in the plan output—all `var.*` references resolve cleanly to `"Data Engineering"`, `"Production"`, and `"Terraform"`.

6. **Test Single-Point Update:**
   * Open `variables.tf` and change `default = "Data Engineering"` to `default = "Data Platform Squad"`.
   * Save the file and re-run `terraform plan`.
   * **Result:** Both the S3 bucket and the SSM parameter automatically update their `Team` tag simultaneously.

---

### Demo 2: Collaborative Enterprise GitOps Pull Request Workflow (CI Linter + Atlantis)

#### Objective:
Execute the complete end-to-end collaborative GitOps lifecycle: clone a protected repository, create a feature branch, intentionally trigger and fix a CI linter failure, obtain Code Owner approval, deploy via `atlantis apply`, and merge cleanly.

#### Step-by-Step Instructions:

##### Step 1: Clone & Sync the Protected Repository
```bash
git clone https://github.com/coredataengineers/cde-data-infrastructure.git
cd cde-data-infrastructure
git checkout main
git pull origin main
```

##### Step 2: Create a Feature Branch
```bash
git checkout -b feat/braze-api-bucket
```

##### Step 3: Add Infrastructure Code & Test CI Linting
1. Open `production/datalake.tf` in VS Code and add a new S3 bucket block with intentional bad indentation to test the CI linter:
   ```hcl
   resource "aws_s3_bucket" "braze_ingestion" {
   bucket = "cde-braze-api-ingestion-2026"
     tags = {
         Team = "Data Engineering"
       Environment = "Production"
     }
   }
   ```
2. Commit and push your feature branch:
   ```bash
   git add .
   git commit -m "feat: add Braze API ingestion S3 bucket"
   git push -u origin feat/braze-api-bucket
   ```
3. Open a **Pull Request** on GitHub against `main`.
4. **Observation:**
   * GitHub automatically assigns `CODEOWNERS` as reviewers.
   * The **`terraform_linter` CI check FAILS** (Red ❌) due to formatting violations, and GitHub blocks merging.

##### Step 4: Fix Formatting Locally & Push Update
1. Navigate into `production/` and run Terraform's formatter and validator:
   ```bash
   cd production
   terraform fmt
   terraform init -backend=false
   terraform validate
   cd ..
   ```
2. Commit and push the formatted code:
   ```bash
   git add .
   git commit -m "style: format HCL with terraform fmt"
   git push origin feat/braze-api-bucket
   ```
3. **Observation:** The `terraform_linter` CI check turns **Green ✅**, and Atlantis automatically posts the updated `terraform plan` diff in the PR comments.

##### Step 5: Code Owner Approval & `atlantis apply`
1. Have a designated Code Owner review the `terraform plan` comment and click **Approve** on the Pull Request.
2. In the Pull Request comment box, type:
   ```text
   atlantis apply
   ```
3. Click **Comment** and wait for Atlantis to confirm: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`

##### Step 6: Merge PR & Sync Local `main` Branch
1. Click **Merge pull request** on GitHub (now unlocked and green).
2. Return to your local terminal and update `main` so you are ready for future tasks:
   ```bash
   git checkout main
   git pull origin main
   git branch -d feat/braze-api-bucket
   ```

---

## Part 8: Infrastructure Teardown & Clean-Up Checklist

1. **Local Workspace Cleanup (Demo 1):**
   * If you ran `terraform apply` in `quick-variables`, run `terraform destroy` inside `quick-variables` and confirm with `yes`.
2. **Shared GitOps Repository Cleanup (Demo 2):**
   * Create a new branch (`git checkout -b chore/cleanup-braze-bucket`), comment out or remove your test `aws_s3_bucket` block from `production/datalake.tf`, open a PR, get approval, run `atlantis apply`, and merge into `main`.