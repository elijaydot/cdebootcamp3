# CDE Bootcamp 3.0: Terraform Deep-Dive — Documentation Mastery, AWS SSM Parameter Store, Resource Referencing & Data Sources

> *"AI will happily hallucinate cloud costs and hand you broken Terraform configurations. True senior engineers live inside the official Terraform Registry documentation, understand the exact line between Argument References and Attribute References, chain resources dynamically without hardcoding secrets, and pull existing cloud infrastructure safely using Data Sources."*  
> — **Mayowa Akinyele**

**Date:** November 14, 2026 (Afternoon Session)  
**Duration:** 145 Minutes  
**Lead Instructor:** Mayowa Akinyele (Opening Quiz by Abdulhakeem Salaudeen)  
**Curriculum Module:** 10 Infrastructure as Code (IaC) — Terraform Registry Navigation, Argument vs. Attribute References, AWS Systems Manager (SSM) Parameter Store vs. Secrets Manager, Chained Resource Referencing, and Terraform Data Sources (`data` blocks)

---

## Executive Overview & Class Atmosphere

Building directly on Friday evening’s introduction to Infrastructure as Code and Terraform's core internal architecture (`Terraform Core`, `Provider Plugins`, and `terraform.tfstate`), this afternoon masterclass bridged the gap between writing standalone `.tf` blocks and building **interconnected, production-grade cloud infrastructure**.

Mayowa opened with a wake-up call grounded in reality: he pulled up a live **Senior Data Engineer job description** he had recently authored for his own team in Europe. The message was unmistakable—modern hiring managers no longer look for people who merely write Python scripts or move CSV files. They demand holistic ownership, **FinOps cost awareness**, and mandatory **Terraform proficiency**.

Throughout the session, Mayowa trained students on how to read the **Terraform Registry Documentation** like a senior architect—distinguishing between **Arguments** (inputs you define) and **Attributes** (outputs AWS generates)—and demonstrated how to wire multiple cloud resources together seamlessly using **Resource Referencing** and **Data Sources**.

---

## Part 1: Warm-Up Quiz — Terraform Internals & Lifecycle Recap
*(Facilitated by Abdulhakeem Salaudeen)*

The session opened with an interactive 10-question Slido quiz reinforcing Friday's Terraform fundamentals:

1. **The Role of Provider Plugins:**
   * While **Terraform Core** parses HCL files and builds execution plans, **Provider Plugins** (e.g., `hashicorp/aws`) act as the "errand boys"—translating those plans into authenticated REST API calls against AWS, Snowflake, Databricks, or GCP.
2. **The Brain of Terraform (`terraform.tfstate`):**
   * Stores metadata and real-world cloud identifiers (ARNs, IDs, attributes) for every resource provisioned. Deleting `terraform.tfstate` blinds Terraform to existing infrastructure.
3. **The Mandatory 3-Step CLI Sequence:**
   * `terraform init` (downloads provider plugins) $\rightarrow$ `terraform plan` (previews additions, modifications, and destructions) $\rightarrow$ `terraform apply` (provisions live infrastructure and updates state).
4. **Declarative IaC vs. Application Code:**
   * Terraform does **not** write your Python/SQL application pipelines or fix bugs in DAGs; it declaratively provisions and manages the underlying cloud infrastructure (buckets, servers, networks, permissions) in version-controlled code.
5. **Multi-Provider Capabilities:**
   * Terraform is completely cloud-agnostic—a single repository can simultaneously manage providers for **AWS**, **Snowflake**, **Databricks**, **GCP**, **Azure**, and **dbt Cloud**.
   * *Quiz Winners:* **Yezid Olanase** (1st Place) & **Blessed Ebosele** (2nd Place) 🏆

---

## Part 2: Industry Reality Check — Anatomy of a Senior Data Engineer JD

Mayowa shared a real-world **Senior Data Engineer** job description he recently wrote to replace a departing teammate, highlighting three critical takeaways for students entering the job market:

1. **"You Build It, You Own It" Mentality:**
   * Companies reject engineers who say *"I only write pipelines; infrastructure and permissions aren't my job."* You must understand the entire lifecycle from network sockets and IAM permissions to orchestration and warehouse performance.
2. **FinOps Is Non-Negotiable:**
   * Hiring managers actively screen for candidates who understand cloud billing dimensions. Mayowa shared a real-world example where he audited a cross-cloud migration from **AWS Redshift to Google BigQuery** using **Cross-Cloud Interconnect**—catching massive hidden networking costs in the official GCP documentation that AI tools (Gemini/ChatGPT) completely hallucinated as cheap.
3. **Terraform Is a Hard Prerequisite:**
   * In cloud-native organizations, Terraform is listed at the very top of technical requirements. Without it, engineers cannot ship infrastructure into production.

---

## Part 3: Mastering the Terraform Registry Documentation

Mayowa emphasized that senior engineers do **not** memorize HCL syntax—they know how to navigate the **Terraform Registry** rapidly. Every resource documentation page is divided into two critical sections that you must never confuse:

```
+-----------------------------------------------------------------------------------------+
| Terraform Registry Resource Page (e.g., aws_s3_bucket / aws_iam_user)                   |
|                                                                                         |
|  1. Example Usage          --> Basic copy-paste boilerplate template                    |
|                                                                                         |
|  2. Argument Reference     --> INPUTS YOU PROVIDE inside the resource { ... } block     |
|     - Required arguments   --> Must be supplied or `terraform validate` / `plan` fails  |
|     - Optional arguments   --> Have AWS defaults (e.g., `force_destroy = false`)        |
|                                                                                         |
|  3. Attribute Reference    --> OUTPUTS AWS GENERATES after `terraform apply`            |
|     - Read-only values     --> `arn`, `id`, `unique_id`, `secret`                       |
|     - Used for chaining    --> Referenced by OTHER resources via `<TYPE>.<NAME>.<ATTR>` |
+-----------------------------------------------------------------------------------------+
```

### Real-World Documentation Insights Highlighted in Class:
* **`force_destroy` on `aws_s3_bucket`:** By default (`false`), AWS prevents deleting an S3 bucket if it still contains objects. Setting `force_destroy = true` in Terraform allows deleting non-empty buckets cleanly.
* **`instance_tenancy` on `aws_vpc`:** Configurable as `default` (shared hardware) or `dedicated` (isolated hardware carrying an extra **$2.00/hour** AWS dedicated region fee).
* **VS Code Extension Tip:** Install the official **HashiCorp Terraform** extension in VS Code to get instant syntax highlighting, auto-completion for Argument/Attribute names, and inline validation.

> 🔗 **Official Terraform Registry:** [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## Part 4: Secrets Storage — AWS Secrets Manager vs. SSM Parameter Store

Before generating programmatic credentials for Airflow, Mayowa compared the two primary AWS services for storing sensitive configuration values and passwords:

| Dimension | AWS Secrets Manager | AWS Systems Manager (SSM) Parameter Store |
| :--- | :--- | :--- |
| **Primary Purpose** | Dedicated enterprise secrets vault with automated rotation | Hierarchical key-value configuration & secrets store |
| **Pricing Dimensions** | **2 Dimensions:** Monthly storage fee per secret (~$0.40/secret/mo) **PLUS** API request charges (~$0.05 per 10,000 API calls) | **1 Dimension:** Standard parameters are **FREE** to store (up to 10,000 parameters); billed only for API throughput/advanced tiers |
| **Built-In Features** | Native automatic password rotation for RDS/Redshift | Hierarchical path organization (e.g., `/prod/data-eng/airflow/key`) |
| **Terraform Resource** | `aws_secretsmanager_secret` | `aws_ssm_parameter` |

### Critical Security Warning on `terraform.tfstate`:
* Even when using `aws_ssm_parameter` with `type = "SecureString"`, **Terraform writes the plain-text secret value inside `terraform.tfstate`**.
* **Golden Rule:** **NEVER commit or push `terraform.tfstate` to GitHub!** Always add `*.tfstate` and `*.tfstate.*` to `.gitignore` and store production state remotely in encrypted, access-controlled S3 buckets.

> 🔗 **Official Terraform Docs:** [aws_ssm_parameter Resource Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)

---

## Part 5: Resource Referencing — Chaining Cloud Infrastructure

In production, cloud resources rarely exist in isolation—an access key belongs to an IAM user, a subnet belongs to a VPC, and a secret parameter stores a generated key. **Resource Referencing** allows one Terraform resource block to dynamically read an **Attribute** generated by another resource block.

### Universal Resource Reference Syntax:

$$\Large \texttt{<RESOURCE\_TYPE>.<LOCAL\_IDENTIFIER>.<ATTRIBUTE\_NAME>}$$

### How Terraform Chains Our Airflow Credential Pipeline:

```
[ 1. aws_iam_user.airflow_user ]
     Creates IAM User: "data_airflow_production"
     Exposes Attribute: .name
                │
                ▼ (Referenced via: aws_iam_user.airflow_user.name)
[ 2. aws_iam_access_key.airflow_keys ]
     Generates AWS Access Key ID & Secret Access Key
     Exposes Attributes: .id  and  .secret
                │                                │
                ▼ (.id)                          ▼ (.secret)
[ 3. aws_ssm_parameter.airflow_access_key ]   [ 4. aws_ssm_parameter.airflow_secret_key ]
     Saves Access Key ID to Parameter Store        Saves Secret Key to Parameter Store
```

* **Implicit Dependency Ordering:** Because `aws_iam_access_key` references `aws_iam_user.airflow_user.name`, Terraform automatically builds a dependency graph—guaranteeing the IAM user is created *before* attempting to generate its access keys, and the keys are generated *before* saving them into SSM Parameter Store.

---

## Part 6: Terraform Data Sources (`data` Blocks) — Importing Existing Cloud Resources

What happens when you need to attach a policy or generate access keys for an IAM user (or deploy an EC2 server into a VPC) that **already exists in AWS**, having been created manually or by a different team's Terraform repository?

* **If you use a `resource` block:** Terraform tries to create a brand new duplicate resource and crashes with an `EntityAlreadyExists` error.
* **The Solution (`data` block):** A **Data Source** performs a read-only query against AWS during `terraform plan`, fetches all attributes (ARN, ID, username) of the pre-existing resource, and makes them available inside your Terraform project without taking ownership or modifying that resource.

```
[ Existing AWS Infrastructure ]                 [ Your Terraform Workspace ]
  IAM User: "loretta"                             data "aws_iam_user" "existing_user" {
  (Created outside this project)  ──Read-Only──►    user_name = "loretta"
                                                  }
                                                         │
                                                         ▼ (Referenced via: data.aws_iam_user.existing_user.user_name)
                                                  resource "aws_iam_access_key" "loretta_key" {
                                                    user = data.aws_iam_user.existing_user.user_name
                                                  }
```

### Universal Data Source Reference Syntax:

$$\Large \texttt{data.<DATA\_SOURCE\_TYPE>.<LOCAL\_IDENTIFIER>.<ATTRIBUTE\_NAME>}$$

* **Best Practice:** In production repositories, group all read-only lookups into a dedicated file named **`data.tf`**.
* **Important Limitation Confirmed in Class:** While `data "aws_iam_user"` fetches a user's `arn`, `user_id`, and `user_name`, **AWS never exposes an existing Secret Access Key** via API or Data Source once created. If a secret key is lost, you must generate a new access key pair (AWS allows up to 2 active keys per IAM user) and deactivate/delete the old one.

> 🔗 **Official Terraform Docs:** [aws_iam_user Data Source Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_user)

---

## Part 7: Comprehensive Student Q&A Index

| Student | Core Question | Mayowa's Technical Clarification |
| :--- | :--- | :--- |
| **Yezid Olanase** | *Is the `$2.00/hr` dedicated tenancy fee shown in the `aws_vpc` docs charged by Terraform?* | **No.** Terraform itself is completely free and open-source. The Terraform Registry documentation notes AWS billing rules so engineers don't accidentally enable expensive AWS features like Dedicated Tenancy. |
| **Judith Ani** | *How does `terraform.tfstate` get generated, and is it created during `init`?* | `terraform.tfstate` is generated **only after `terraform apply`** finishes creating live resources in AWS. `terraform init` only downloads the provider plugin binaries (`.terraform/`). |
| **Lorreta Anyika** | *Can we skip `terraform plan` and run `terraform apply` directly?* | Yes—running `terraform apply` automatically calculates an internal plan and prompts `yes/no` before making changes. However, running `terraform plan` first is best practice for careful review. |
| **Roqeeb Olaniran** | *As we keep creating more resources, do they all accumulate inside the same `terraform.tfstate` file?* | **Yes.** Every resource managed within that directory/workspace is tracked as a JSON object inside that single `terraform.tfstate` file. |
| **Immaculate Okoro** | *Can we think of Resource Attributes like the return output of a Python function?* | **Spot on!** Arguments are like function input parameters; Attributes are like the return dictionary values you extract and pass into subsequent function calls. |
| **Zainab Olamiji** | *Are the Attributes we can reference the same metadata fields displayed in the `terraform plan` output?* | **100% yes.** Everything listed under a resource block in `terraform plan` (including items marked `(known after apply)`) represents the exact schema of Arguments and Attributes available for that resource. |
| **Immaculate Okoro** | *What is `terraform.tfstate.backup`, and should we push state files to GitHub?* | `terraform.tfstate.backup` stores the previous state snapshot before your latest `apply` for local rollback safety. **Never push `.tfstate` or `.tfstate.backup` to GitHub** because they contain plain-text secrets (such as AWS Secret Access Keys). |
| **Lorreta Anyika** | *Is an `aws_iam_access_key` the same as the `.pem` Key Pair used to SSH into EC2?* | **No.** EC2 `.pem` Key Pairs are RSA cryptographic keys used for Linux SSH login. IAM Access Keys (`AKIA...` + Secret Key) are programmatic API credentials used by applications (like Airflow or Python `boto3`) to authenticate with AWS services. |
| **John Babatunde & Timothy Olaniyi** | *Why use a `data` block to fetch an existing IAM user instead of just hardcoding the username string?* | Hardcoding a string gives you only the name. Using a `data` block dynamically pulls **all** of that user's live AWS metadata (`arn`, `user_id`, `path`, `tags`), allowing you to reference attributes across multiple resources without manual copying. |
| **Zainab Olamiji** | *If an IAM user already has an access key in AWS, can a Terraform `data` block retrieve its Secret Access Key?* | **No.** AWS permanently hides the Secret Access Key immediately after initial creation for security. Neither the AWS Console nor Terraform Data Sources can ever retrieve a lost secret key—you must create a second key pair, store it in SSM Parameter Store, and deactivate/delete the old key. |

---

## Part 8: Hands-On Labs & Live Demos — Step-by-Step Execution Guide

This section provides complete, reproducible guides for every live coding demonstration executed during the afternoon session.

### Demo 1: Multi-File Project Setup & Storing Secrets in AWS SSM Parameter Store

#### Objective:
Organize a clean multi-file Terraform workspace (`providers.tf` and `airflow_credentials.tf`) and provision a parameter inside **AWS Systems Manager (SSM) Parameter Store**.

#### Step-by-Step Instructions:

1. **Create and Open the Workspace:**
   ```
   mkdir terraform-projects
   cd terraform-projects
   code .
   ```

2. **Create `providers.tf`:**
   Create a new file named `providers.tf` to isolate provider configurations:
   ```
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 6.0"
       }
     }
   }

   provider "aws" {
     region = "eu-north-1"   # Stockholm region
   }
   ```

3. **Initialize Terraform:**
   ```
   terraform init
   ```

4. **Create `airflow_credentials.tf`:**
   Create a second file named `airflow_credentials.tf` and define an SSM Parameter resource:
   ```
   resource "aws_ssm_parameter" "airflow_password" {
     name  = "/production/data-engineering/airflow/db-password"
     type  = "SecureString"
     value = "SuperSecretAirflowPass2026!"
   }
   ```

5. **Plan and Apply:**
   ```
   terraform plan
   terraform apply
   ```
   * Type `yes` when prompted.
   * **Observation:** In the terminal output, notice that `value` is masked as `(sensitive value)`, yet inspecting `terraform.tfstate` reveals the plain-text string—reinforcing why state files must never be committed to Git.

6. **Verify in AWS Console:**
   * Open **AWS Management Console** $\rightarrow$ Search for **Systems Manager** $\rightarrow$ Click **Parameter Store** (left menu).
   * Locate `/production/data-engineering/airflow/db-password` and click **Show** under Value to confirm it was stored.

---

### Demo 2: Chained Resource Referencing (IAM User $\rightarrow$ Access Keys $\rightarrow$ SSM Parameter Store)

#### Objective:
Create an IAM service account (`data_airflow_production`), generate programmatic API credentials (`aws_iam_access_key`) using Resource Referencing, and automatically pipe both the Access Key ID and Secret Access Key into SSM Parameter Store so engineers never lose the secret key.

#### Step-by-Step Instructions:

1. **Update `airflow_credentials.tf` with Chained Resources:**
   Replace the contents of `airflow_credentials.tf` with the complete 4-resource chain:
   ```
   # 1. Create the IAM Service User for Airflow
   resource "aws_iam_user" "airflow_user" {
     name = "data_airflow_production"
   }

   # 2. Generate Programmatic Access Key & Secret Key (References Resource #1)
   resource "aws_iam_access_key" "airflow_keys" {
     user = aws_iam_user.airflow_user.name
   }

   # 3. Store the Access Key ID in SSM Parameter Store (References Resource #2)
   resource "aws_ssm_parameter" "airflow_aws_access_key" {
     name  = "/production/data-engineering/airflow/aws-access-key"
     type  = "String"
     value = aws_iam_access_key.airflow_keys.id
   }

   # 4. Store the Secret Access Key in SSM Parameter Store (References Resource #2)
   resource "aws_ssm_parameter" "airflow_aws_secret_key" {
     name  = "/production/data-engineering/airflow/aws-secret-key"
     type  = "SecureString"
     value = aws_iam_access_key.airflow_keys.secret
   }
   ```

2. **Format, Validate, and Preview the Dependency Graph:**
   ```
   terraform fmt
   terraform validate
   terraform plan
   ```
   * **Observation:** Terraform detects that `airflow_user` must be created first, followed by `airflow_keys`, followed by the two SSM parameters (`Plan: 4 to add, 0 to change, 1 to destroy` — destroying the old standalone test parameter from Demo 1).

3. **Apply the Infrastructure:**
   ```
   terraform apply
   ```
   * Type `yes` and press **Enter**.

4. **Verify End-to-End Integration in AWS:**
   * **IAM Console:** Navigate to **IAM** $\rightarrow$ **Users** $\rightarrow$ Click `data_airflow_production` $\rightarrow$ **Security credentials** tab. Confirm an active Access Key (`AKIA...`) is listed.
   * **SSM Parameter Store:** Navigate to **Systems Manager** $\rightarrow$ **Parameter Store**. Filter by `/production/data-engineering/airflow/` and verify both `aws-access-key` and `aws-secret-key` are stored safely and match the IAM key ID.

---

### Demo 3: Fetching Pre-Existing AWS Infrastructure via Terraform Data Sources (`data.tf`)

#### Objective:
Query an existing IAM user already present in AWS (created outside your Terraform project) using a `data` block, extract their live attributes (`user_name`, `arn`), and generate new programmatic access keys for them without recreating the user.

#### Step-by-Step Instructions:

1. **Identify an Existing IAM User in AWS:**
   * Open the **AWS IAM Console** $\rightarrow$ **Users** and note the exact username of an existing user (e.g., `loretta` or another existing test user with fewer than 2 access keys).

2. **Create `data.tf` to Query the Existing User:**
   In your Terraform project directory, create a new file named `data.tf`:
   ```
   # Read-only lookup of an existing IAM user in AWS
   data "aws_iam_user" "existing_user" {
     user_name = "loretta"   # Replace with an actual existing IAM username in your account
   }
   ```

3. **Create `user_access_keys.tf` Referencing the Data Source:**
   Create a file named `user_access_keys.tf` that uses the `data.` prefix to reference the queried user:
   ```
   resource "aws_iam_access_key" "existing_user_key" {
     user = data.aws_iam_user.existing_user.user_name
   }
   ```

4. **Preview and Apply:**
   ```
   terraform plan
   ```
   * **Observation:** Notice Terraform outputs `data.aws_iam_user.existing_user: Reading...` and `Read complete!`, followed by `Plan: 1 to add, 0 to change, 0 to destroy`. It does **not** attempt to recreate the user!
   ```
   terraform apply
   ```
   * Type `yes` to generate the access key for the existing user.

5. **Verify in IAM Console:**
   * Refresh the existing user's **Security credentials** tab in the AWS IAM Console and verify the newly generated Access Key ID appears.

---

## Part 9: Infrastructure Teardown & Clean-Up Checklist

Always clean up test users, access keys, and SSM parameters after completing your practice labs:

1. **Remove Test `.tf` Configurations & Apply:**
   * Delete `user_access_keys.tf` and `data.tf`, and comment out the resource blocks inside `airflow_credentials.tf`.
   * Run:
     ```
     terraform plan    # Confirm: Plan: 0 to add, 0 to change, 5 to destroy
     terraform apply   # Type 'yes' to remove all IAM users, access keys, and SSM parameters
     ```

2. **Verify Clean AWS State:**
   * Confirm in the **IAM Console** that `data_airflow_production` is deleted and no stray test access keys remain on existing users.
   * Confirm in **SSM Parameter Store** that `/production/data-engineering/airflow/*` parameters are removed.