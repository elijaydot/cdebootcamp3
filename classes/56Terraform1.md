# CDE Bootcamp 3.0: Infrastructure as Code (IaC) & Terraform Internals Masterclass

> *"Don't just prompt an AI for HCL snippets and hope for the best. If you don't understand how Terraform Core compares configuration files against the State File and communicates through Provider Plugins, you will accidentally wipe out a colleague's production infrastructure on your first pull request."*
>
> — **Mayowa Akinyele**

**Date:** November 13, 2026  
**Duration:** 147 Minutes  
**Lead Instructor:** Mayowa Akinyele (Opening Quiz by Abdulhakeem Salaudeen)  
**Curriculum Module:** 10 Infrastructure as Code (IaC) — Terraform Architecture, HashiCorp Configuration Language (HCL), Terraform Core, Provider Plugins, State File (`terraform.tfstate`) Mechanics, Drift Detection, GitOps with Atlantis, and Live Failure Simulations

---

## Executive Overview & Class Atmosphere

Having wrapped up the intensive AWS Cloud module (covering VPC networking, EC2 compute, IAM governance, S3 data lakes, RDS transactional databases, and Redshift distributed warehousing), this session marked a pivotal shift in engineering maturity: **moving away from clicking buttons in the AWS Console**.

Mayowa opened with an honest reflection on pacing and resilience, reassuring students who felt overwhelmed by the sheer volume of enterprise cloud engineering tools. He grounded the entire lecture in a relatable workplace scenario: **Judith Ani’s first urgent Jira sprint ticket**, where she is tasked with ingesting marketing data from the **Braze API** into **Amazon Redshift** via **S3** and **Airflow**—under one non-negotiable company mandate: **all cloud resources must be provisioned using Terraform**.

Instead of simply teaching HCL syntax, Mayowa took the class under the hood to dissect Terraform’s internal engine room. He intentionally broke configurations, deleted state files, wiped local credentials, and simulated manual UI deletions to prove *why* Terraform behaves the way it does.

---

## Part 1: Warm-Up Quiz — Amazon Redshift & Distributed Warehousing Recap
*(Facilitated by Abdulhakeem Salaudeen)*

Before launching into Terraform, Abdulhakeem led a high-energy quiz testing retention from Wednesday’s Redshift masterclass:

1. **Row-Oriented vs. Columnar Storage:**
   * Running `SELECT AVG(age) FROM students;` in a columnar warehouse like Redshift scans **only the `age` column blocks**, skipping all other columns and slashing disk I/O.
2. **Redshift Backend Heritage:**
   * Redshift is built on a heavily re-engineered PostgreSQL foundation converted into a **columnar storage** engine utilizing **Massively Parallel Processing (MPP)** across multiple nodes.
3. **Leader Node vs. Compute Nodes:**
   * **Leader Node:** Receives client SQL queries, parses syntax, optimizes execution plans, and coordinates work. Managed invisibly by AWS.
   * **Compute Nodes:** Dedicated worker instances partitioned into **Slices** that store table data and execute parallel query segments.
4. **Sort Keys (`SORTKEY`):**
   * **Timestamp columns** (`created_at`, `updated_at`) are the strongest candidates for Sort Keys because analytical queries and incremental loads heavily filter on date ranges, allowing Redshift to skip entire 1 MB disk blocks using Zone Maps.
5. **Security Group Attachment in Redshift:**
   * External SQL clients (DBeaver, Airflow, dbt) connect exclusively to the **Leader Node** on port `5439`; therefore, inbound firewall rules govern traffic reaching the Leader Node's ENI.
   * *Quiz Winner:* **Immaculate Okoro** 🏆 *(scoring a perfect 10/10!)*

---

## Part 2: The Real-World Scenario — Why "Click-Ops" Fails in Production

Mayowa presented a realistic workplace onboarding scenario on a **Jira Sprint Board**:

```
+-----------------------------------------------------------------------------------+
| JIRA TICKET: CDE-402 | Assignee: Judith Ani | Priority: URGENT                    |
+-----------------------------------------------------------------------------------+
| Summary: Ingest Braze Marketing API Data into Amazon Redshift Data Warehouse      |
|                                                                                   |
| Architecture Flow:                                                                |
| [ Braze API ] ──(Airflow on EC2)──► [ S3 Raw Staging Bucket ] ──► [ Redshift DWH ]|
|                                                                                   |
| Acceptance Criteria:                                                              |
| 1. Provision an S3 bucket to stage raw API JSON/Parquet payloads.                 |
| 2. Create an IAM Role & Policy allowing EC2 Airflow workers to write to S3.       |
| 3. MANDATORY: All cloud infrastructure MUST be provisioned via Terraform (IaC).   |
|    Manual creation via AWS Management Console ("Click-Ops") is strictly banned.   |
+-----------------------------------------------------------------------------------+
```

### The 4 Fatal Flaws of Manual Console Provisioning ("Click-Ops"):
1. **Zero Visibility & Accountability:** When 15 engineers have console access, nobody knows who created an expensive EC2 instance, who modified a Security Group, or who accidentally deleted a staging bucket.
2. **No Rollback Mechanism:** If an engineer misconfigures a VPC route table or changes a database parameter in the UI and breaks production, there is no `Ctrl + Z` to revert the infrastructure to yesterday’s working state.
3. **Painfully Slow & Repetitive:** Clicking through 12 screens to configure a VPC, 3 subnets, route tables, IAM policies, and RDS databases takes hours—and repeating that setup across `dev`, `staging`, and `prod` environments invites human error.
4. **Catastrophic Disaster Recovery:** If a critical bucket or server is accidentally deleted, engineers must scramble from memory trying to remember exact naming conventions, tags, encryption settings, and IAM permissions.

---

## Part 3: What is Infrastructure as Code (IaC) & Terraform?

* **Infrastructure as Code (IaC):** The practice of managing and provisioning cloud data centers, networks, databases, and permissions through machine-readable declarative definition files rather than interactive GUI clicks.
* **Terraform (by HashiCorp / IBM):** The industry-leading open-source IaC tool. Engineers write human-readable configuration files using **HCL (HashiCorp Configuration Language)** ending in `.tf`.

### Why Terraform Beats AWS CloudFormation:
* **AWS CloudFormation** is AWS’s native IaC tool, but it is locked strictly to AWS.
* **Terraform is Cloud- & Platform-Agnostic:** Using a single unified workflow, a data engineer can provision an **AWS S3 bucket**, configure a **Snowflake warehouse**, spin up a **Databricks cluster**, and manage **dbt Cloud jobs** inside the exact same project repository.

### Anatomy of an HCL Resource Block:

```hcl
# Resource Block Header: <RESOURCE_TYPE> "<LOCAL_IDENTIFIER>"
resource "aws_s3_bucket" "ingestion" {
  # Arguments (Key-Value pairs defining the desired state)
  bucket = "cde-api-ingestion-12"

  tags = {
    Team        = "Data Engineering"
    Environment = "Production"
  }
}
```

* **`resource`:** Top-level HCL keyword declaring an infrastructure object.
* **`"aws_s3_bucket"`:** The official resource type defined by the AWS Provider plugin.
* **`"ingestion"`:** The local Terraform identifier used to reference this specific block within your Terraform code.
* **Arguments (`bucket`, `tags`):** Configuration parameters specifying the desired state of the cloud resource.

> 🔗 **Official Terraform Registry:** [HashiCorp Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## Part 4: Under the Hood — How Terraform Works (The Internal Triad)

Mayowa drew out the complete internal architecture on Excalidraw to show what happens on your local machine when you execute Terraform commands:

```
+-----------------------------------------------------------------------------------------+
| Engineer's Local Machine (or CI/CD Runner)                                              |
|                                                                                         |
|  [ 1. Configuration Files (*.tf) ]          [ 3. Terraform State File ]                 |
|  - infra.tf (Declares Desired State)        - terraform.tfstate ("The Brain")           |
|  - Specifies Provider: hashicorp/aws        - Tracks real-world ARNs & metadata         |
|                │                                              ▲                         |
|                ▼                                              │ (Reads / Updates)       |
|  +------------------------------------------------------------+----------------------+  |
|  |                            2. TERRAFORM CORE (CLI Engine)                         |  |
|  |  - Parses .tf HCL code                                                            |  |
|  |  - Compares Desired State (.tf) vs. Current State (terraform.tfstate)             |  |
|  |  - Builds Dependency Graph & Execution Plan                                       |  |
|  +-----------------------------------------+-----------------------------------------+  |
|                                            │ (gRPC / Local RPC Calls)                   |
|                                            ▼                                            |
|  +-----------------------------------------------------------------------------------+  |
|  |                     4. PROVIDER PLUGINS (.terraform/providers/)                   |  |
|  |  - Compiled Go binary ("The Errand Boy", e.g., terraform-provider-aws_v6.73.0)    |  |
|  |  - Translates HCL plans into authenticated REST API requests                      |  |
|  +-----------------------------------------+-----------------------------------------+  |
+--------------------------------------------|--------------------------------------------+
                                             │ (HTTPS / AWS API Calls)
                                             ▼
                                 ☁️ AWS Cloud Infrastructure
                                 (Creates S3 Bucket, VPC, EC2, IAM)
```

### 1. Terraform Core
* The compiled CLI binary installed on your machine.
* Reads `.tf` configuration files, builds a dependency graph of resources, compares your desired configuration against the State File, and determines what needs to be created (`+`), updated (`~`), or destroyed (`-`).

### 2. Provider Plugins ("The Errand Boy")
* Terraform Core does not natively know how AWS, GCP, Snowflake, or dbt APIs work.
* When you run `terraform init`, Terraform Core downloads the specific **Provider Plugin** binary (e.g., `hashicorp/aws` v6.73.0) into a hidden `.terraform/` folder.
* During execution, Terraform Core hands instructions to the Provider Plugin, which translates them into authenticated cloud API calls.

### 3. Terraform State File (`terraform.tfstate` — "The Brain")
* A JSON file automatically generated after your first `terraform apply`.
* **Why it is critical:** `terraform.tfstate` maps your `.tf` code blocks (`aws_s3_bucket.ingestion`) to the real-world cloud resource identifiers (ARNs, bucket IDs, IP addresses).
* Without this file, Terraform has "amnesia"—it has no memory of what it previously created.
* **Golden Rule:** Never manually edit or delete `terraform.tfstate` in production.

---

## Part 5: The Core Terraform CLI Workflow

95% of daily Terraform engineering revolves around three foundational commands:

1. **`terraform init` (Initialize):**
   * Scans the current directory for `.tf` files, identifies required providers (`hashicorp/aws`), downloads the compiled provider plugin binaries into `.terraform/`, and creates a `.terraform.lock.hcl` dependency lock file.
   * *Authentication Check:* Does **not** require AWS credentials yet (only downloads plugins from the public Terraform Registry).
2. **`terraform plan` (Dry Run & Diff):**
   * Authenticates with AWS using your configured credentials.
   * Compares your `.tf` code (Desired State) against `terraform.tfstate` and queries live AWS APIs to detect **Infrastructure Drift**.
   * Prints a detailed execution plan showing exact additions (`+`), in-place modifications (`~`), and destructions (`-`) without altering any live infrastructure.
3. **`terraform apply` (Execute):**
   * Prompts for interactive confirmation (`yes`), then instructs the Provider Plugin to execute the API calls to create, update, or destroy resources on AWS, updating `terraform.tfstate` upon completion.

---

## Part 6: Production Collaboration & GitOps with Atlantis

Mayowa highlighted a critical architectural reality: **In a real company, engineers NEVER run `terraform apply` from their personal laptops, nor do they store `terraform.tfstate` locally.**

```
[ Engineer Laptop ] ──git push (Feature Branch)──► [ GitHub Repository ]
                                                            │
                                                     (Pull Request Opened)
                                                            │
                                                            ▼
                                              [ Atlantis Automation Server ]
                                              - Runs `terraform plan` automatically
                                              - Posts diff output as PR comment
                                              - Locks Remote State (S3 + DynamoDB)
                                                            │
                                               (Senior Lead Approves PR!)
                                                            │
                                                            ▼
                                              [ Engineer Comments: `atlantis apply` ]
                                              - Provisions live AWS infrastructure
                                              - Merges branch cleanly into `main`
```

### How Enterprise Teams Prevent Infrastructure Collisions:
1. **Read-Only Console Access:** Engineers are granted `ReadOnlyAccess` in the AWS Console. Nobody can manually click to create or delete production resources.
2. **Remote State Storage:** The `terraform.tfstate` file is stored centrally in a secure, versioned **Amazon S3 bucket** with state locking enabled so two engineers cannot overwrite state simultaneously.
3. **GitOps Pull Requests & Atlantis:**
   * Engineers write `.tf` code on a feature branch and open a **Pull Request (PR)** on GitHub.
   * **Atlantis** (an open-source Terraform automation tool) automatically detects the PR, runs `terraform plan`, and posts the exact infrastructure changes directly into the GitHub PR comments for peer review.
   * Once a senior engineer reviews and approves the PR, commenting `atlantis apply` triggers Atlantis to deploy the resources safely into AWS and merge the branch.

---

## Part 7: Comprehensive Student Q&A Index

| Student | Core Question | Mayowa's Technical Clarification |
| :--- | :--- | :--- |
| **Temitope Asama** | *How does Terraform differ from the AWS CLI?* | The AWS CLI is **imperative**—you issue step-by-step commands (`aws s3 mb ...`), and it has no memory of past actions. Terraform is **declarative**—you describe the final end-state you want in `.tf` files, and Terraform tracks state, calculates diffs, and manages updates or rollbacks automatically. |
| **Dennis Humes** | *Can Terraform also create IAM users, roles, and attach security policies?* | **Yes!** Every single AWS resource—IAM users, custom JSON policies, EC2 instances, VPCs, subnets, security groups, RDS databases, and Redshift clusters—can be defined and linked together in Terraform. |
| **Abdulmalik Adesokan** | *How does Terraform know which AWS account to deploy resources into?* | Terraform relies on the standard AWS credential chain: it checks hardcoded provider arguments (not recommended), environment variables (`AWS_ACCESS_KEY_ID`), shared local credential files (`~/.aws/credentials`), or attached EC2 **IAM Instance Profiles**. |
| **Immaculate Okoro** | *At what exact stage (`init`, `plan`, or `apply`) does Terraform authenticate with AWS?* | Authentication occurs during **`terraform plan`** (and `apply`). `terraform init` simply downloads public provider plugins from the HashiCorp registry and succeeds even with zero AWS credentials configured. |
| **Lorreta Anyika** | *Can we skip `terraform plan` and run `terraform apply` directly?* | Technically yes (`terraform apply` automatically generates an internal plan and asks for confirmation before executing), but running `terraform plan` separately is mandatory best practice to inspect changes safely before touching live infrastructure. |
| **Roqeeb Olaniran** | *If I forgot to enable Public IP on an EC2 instance, can I edit the `.tf` file and re-apply?* | Yes! You simply add `associate_public_ip_address = true` to your `.tf` block and run `terraform apply`. Terraform detects the configuration diff (`~`) and updates the resource automatically. |
| **Mayowa Oludoyi** | *If someone manually deletes an S3 bucket in the AWS UI, why doesn't Terraform alert us immediately?* | Terraform is a CLI tool, not a continuous background daemon. To track who manually altered or deleted resources in the AWS Console, organizations enable **AWS CloudTrail** auditing and enforce `ReadOnlyAccess` IAM policies on human users. |
| **Josephine Adah** | *Do we have to memorize all HCL resource names and arguments?* | **Never.** Even senior architects keep the **Terraform Registry Documentation** open constantly to copy official resource templates and look up argument references. |

---

## Part 8: Hands-On Labs & Live Experiments — Step-by-Step Execution Guide

This section compiles every live terminal experiment and failure simulation Mayowa executed during the class so you can reproduce them step-by-step and master how Terraform thinks.

---

### Demo 1: Setting Up a Terraform Project & Provisioning an S3 Bucket

#### Objective:
Initialize a clean Terraform workspace, configure the AWS provider (`hashicorp/aws`), preview infrastructure changes using `terraform plan`, and provision a live S3 bucket tagged for Data Engineering.

#### Step-by-Step Instructions:

1. **Create a Dedicated Project Workspace:**
   Open your terminal and create a fresh directory:
   ```bash
   mkdir terraform-playground
   cd terraform-playground
   code .   # Opens VS Code in the current directory
   ```

2. **Test `terraform init` in an Empty Directory (Experiment 1):**
   Run initialization before creating any `.tf` files:
   ```bash
   terraform init
   ```
   * **Expected Output:**
     `Terraform initialized in an empty directory! The directory has no Terraform configuration files.`

3. **Create the Infrastructure Configuration File (`infra.tf`):**
   Inside VS Code, create a file named `infra.tf` and define the AWS provider block:
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
     region = "eu-north-1"   # Stockholm region (change to your assigned region)
   }
   ```

4. **Download the AWS Provider Plugin:**
   Execute initialization again:
   ```bash
   terraform init
   ```
   * **Observation:** Terraform connects to `registry.terraform.io`, downloads the `hashicorp/aws` plugin binary into a hidden `.terraform/` directory, and creates `.terraform.lock.hcl`.

5. **Add an S3 Bucket Resource Block to `infra.tf`:**
   Append the following resource declaration to `infra.tf` *(ensure your bucket name is globally unique)*:
   ```hcl
   resource "aws_s3_bucket" "ingestion" {
     bucket = "cde-api-ingestion-demo-2026"

     tags = {
       Team        = "Data Engineering"
       Environment = "Production"
     }
   }
   ```
   Save the file (`Ctrl + S` / `Cmd + S`).

6. **Generate and Inspect the Execution Plan:**
   ```bash
   terraform plan
   ```
   * **Observation:** Terraform outputs:
     `Plan: 1 to add, 0 to change, 0 to destroy.`
     Notice the green `+` symbol next to `aws_s3_bucket.ingestion`.

7. **Provision the Live AWS Resource:**
   ```bash
   terraform apply
   ```
   * When prompted (`Do you want to perform these actions?`), type `yes` and press **Enter**.
   * **Result:**
     `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
   * **Verification:**
     1. Inspect your VS Code file explorer: a new file named **`terraform.tfstate`** has appeared containing the bucket's ARN, region, and tags.
     2. Open the **AWS S3 Console** in your browser and refresh the bucket list. `cde-api-ingestion-demo-2026` is live with both tags attached under **Properties**.

---

### Demo 2: Simulating Infrastructure Drift (Manual UI Deletion Recovery)

#### Objective:
Simulate a real-world disaster where a team member manually deletes your production S3 bucket in the AWS Console, and watch how Terraform detects the drift and heals the infrastructure automatically.

#### Step-by-Step Instructions:

1. **Manually Delete the Bucket in the AWS Console:**
   * Open the **Amazon S3 Console** $\rightarrow$ Select `cde-api-ingestion-demo-2026`.
   * Click **Delete** $\rightarrow$ Type `cde-api-ingestion-demo-2026` to confirm $\rightarrow$ Click **Delete bucket**.
   * *The bucket is now completely gone from AWS, yet `terraform.tfstate` on your laptop still believes it exists.*

2. **Run `terraform plan` to Detect Drift:**
   Return to your terminal and run:
   ```bash
   terraform plan
   ```
   * **What Happens Under the Hood:** Terraform Core reads `terraform.tfstate`, sees that `aws_s3_bucket.ingestion` is supposed to exist, queries the AWS API via the Provider Plugin, discovers the bucket is missing, and automatically generates a recovery plan:
     `Note: Objects have changed outside of Terraform... Plan: 1 to add, 0 to change, 0 to destroy.`

3. **Restore the Infrastructure:**
   ```bash
   terraform apply
   ```
   * Type `yes` and press **Enter**.
   * **Result:** Terraform recreates the bucket with the exact original name and tags in seconds.

---

### Demo 3: Simulating "Brain Loss" (Deleting `terraform.tfstate`)

#### Objective:
Understand why `terraform.tfstate` is indispensable by deleting the local state file while the S3 bucket still exists in AWS, and observing the resulting conflict.

#### Step-by-Step Instructions:

1. **Delete the Local State File:**
   In VS Code (or terminal), delete `terraform.tfstate` (and `terraform.tfstate.backup`):
   ```bash
   rm -f terraform.tfstate terraform.tfstate.backup
   ```

2. **Run `terraform plan`:**
   ```bash
   terraform plan
   ```
   * **Observation:** Because Terraform's "brain" was deleted, it has zero memory of the live bucket in AWS and naively plans to create it from scratch (`Plan: 1 to add`).

3. **Attempt `terraform apply`:**
   ```bash
   terraform apply
   ```
   * Type `yes`.
   * **Expected Error:**
     `Error: creating Amazon S3 (Simple Storage) Bucket (cde-api-ingestion-demo-2026): BucketAlreadyOwnedByYou: Your previous request to create the named bucket succeeded and you already own it.`
   * **Lesson Learned:** Without the State File, Terraform cannot map `.tf` code blocks to existing cloud resources.

4. **Manual Recovery Cleanup:**
   * Go to the **AWS S3 Console** and manually delete `cde-api-ingestion-demo-2026` so your workspace and AWS account are synchronized again.

---

### Demo 4: Proving When AWS Credentials Are Evaluated

#### Objective:
Verify Immaculate’s question experimentally by removing local AWS credentials and running `terraform init` vs. `terraform plan`.

#### Step-by-Step Instructions:

1. **Temporarily Rename or Remove Local AWS Credentials:**
   ```bash
   mv ~/.aws/credentials ~/.aws/credentials.bak
   ```

2. **Test `terraform init`:**
   ```bash
   rm -rf .terraform .terraform.lock.hcl
   terraform init
   ```
   * **Result:** **Succeeds completely!** `terraform init` only downloads provider binaries from the public registry and requires zero AWS credentials.

3. **Test `terraform plan`:**
   ```bash
   terraform plan
   ```
   * **Result:** Fails immediately with:
     `Error: No valid credential sources found for AWS Provider.`
   * **Conclusion:** Terraform only authenticates against your cloud account during **`plan`** and **`apply`**.

4. **Restore Your AWS Credentials:**
   ```bash
   mv ~/.aws/credentials.bak ~/.aws/credentials
   ```

---

## Part 9: Infrastructure Teardown & Clean-Up Checklist

Whenever you finish practicing with Terraform, destroy all provisioned resources cleanly using Terraform's built-in teardown command:

1. **Destroy All Terraform-Managed Resources:**
   ```bash
   terraform destroy
   ```
   * Review the red `-` destruction plan (`Plan: 0 to add, 0 to change, 1 to destroy`).
   * Type `yes` and press **Enter**.
2. **Verify Clean State:**
   * Confirm `terraform.tfstate` shows `"resources": []` (empty array) and refresh the AWS Console to ensure all test S3 buckets are removed.