# 📊 Cross-Platform Attribution, Databricks Governance & Production CI/CD with dbt

*A Comprehensive Technical Synthesis of the CDC Marketing Case Study Review led by Okon Victor*  
**Date:** October 24, 2026 | **Duration:** 125 Minutes  
**Session Focus:** Multi-Platform Ad Modeling (Facebook & Snapchat), Databricks Unity Catalog Architecture, Column-Level Lineage, and Automated GitHub Actions Slim CI/CD.

---

## Executive Summary

In this capstone case study review, **Okon Victor** led a hands-on architectural post-mortem analyzing how to transition from fragmented ad-platform reporting to an enterprise-grade, automated analytics lakehouse.

The session resolved critical real-world engineering bottlenecks:
1. **The Business Dilemma:** Marketers were manually downloading CSV extracts across disparate advertising platforms (Facebook Ads, Snapchat Ads, Google Ads) to reconcile performance metrics in Excel.
2. **The Modeling Strategy:** Building a conformed, unified dimensional model (**Star Schema**) using `dbt_utils.union_relations` to merge multi-platform entities without writing hundreds of lines of fragile SQL.
3. **Real-World Data Quirks:** Managing timezone drifts, multi-country granularity, missing ad-group IDs, mixed currencies ($USD$ vs. $€UR$), and dirty string nulls.
4. **Lakehouse Governance:** Clarifying the boundaries between **Workspaces**, **Environments** (Dev, CI, Staging, Prod), **Catalogs** (`bronze_production`, `silver_staging`, `gold_production`), and **Schemas** in Databricks Unity Catalog.
5. **Production CI/CD Pipelines:** Deconstructing an enterprise GitHub Actions workflow featuring dynamic ephemeral PR schemas, `dbt-project-evaluator` governance checks, empty dry-runs (`--empty`), and cost-efficient Slim CI builds (`state:modified+`).

---

## 1. The Business Context & The Three Modeling Laws

Victor opened by reiterating the fundamental law of analytics engineering:

> *"We don't build data models just because we know how to write SQL. We build models to solve specific business problems."*

### The Problem Statement
The marketing leadership team needed an automated, single pane of glass to track ad spend, impressions, clicks, click-through rates (CTR), and budgets across paid channels. The architecture had to be:
* **Centralized:** Eliminating manual CSV exports.
* **Extensible:** Capable of onboarding new marketing sources (TikTok, Twitter/X, Google Ads) without redesigning core fact tables.
* **Query-Optimized:** Structured specifically for consumption by BI dashboards (Tableau, Power BI) and autonomous AI analytics agents.

```
┌────────────────────────────────────────────────────────────────────────┐
│             3 MANDATORY STEPS BEFORE WRITING TRANSFORMATION CODE       │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Understand the Entity Relationships:                                │
│    Map the operational hierarchy of the domain:                        │
│    Account ──(1:N)──> Campaign ──(1:N)──> AdGroup ──(1:N)──> Ad        │
│                                                                        │
│ 2. Identify the End Consumers:                                         │
│    • BI / Reporting / AI Agents ──> Denormalized Star Schema (Fewer    │
│      joins, higher read performance).                                  │
│    • Reverse ETL / Marketing Mix Models (MMM) ──> Normalized / 3NF     │
│      relational entities.                                              │
│                                                                        │
│ 3. Define the Grain & Data Anomalies:                                  │
│    Verify primary keys, composite natural grains, SCD tracking, and    │
│    currency conversion strategies.                                     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Exploratory Data Analysis & Production Edge Cases

During student presentations (**Roqeeb**, **David**, **Lorreta**, **John**, and **Ose**), several production anomalies in the raw datasets were surfaced and resolved:

### A. The Snapchat AdGroup Deduplication Challenge
* **Symptom:** `adgroup_id` was not globally unique in the raw extract; multiple records existed with identical IDs.
* **Root Cause:** Upstream tracking captured operational updates over time, recording multiple historical timestamps.
* **Solution:** Deduplicate within the staging/intermediate CTEs using window functions before joining downstream:
  ```sql
  QUALIFY ROW_NUMBER() OVER (
      PARTITION BY adgroup_id 
      ORDER BY updated_at DESC
  ) = 1
  ```

### B. The Currency Reconciliation Debate ($USD$ vs. $€UR$)
* **Symptom:** Facebook accounts billed in both $USD$ and $€UR$, whereas Snapchat was billed exclusively in $USD$.
* **The Engineering Debate:**
  * *Option 1 (Naive):* Sum raw spend columns directly. ❌ **Catastrophic Failure:** Generates mathematically invalid blended totals on dashboards.
  * *Option 2 (Dual Columns):* Retain raw `amount_spent` alongside currency codes, and append a normalized `amount_spent_usd` column converted via daily exchange rate lookup tables.
  * *Option 3 (Explicit Documentation):* Retain the native currency dimension and mandate that downstream BI metrics split spend by `currency_code`.

### C. Dirty String Nulls & Schema Standardization
* **Symptom:** Upstream tracking emitted literal string values (`'null'`, `'undefined'`, `'-'`) in numeric metric fields (clicks, impressions).
* **Fix:** Apply `TRY_CAST(NULLIF(clicks, 'null') AS INT)` inside the staging layer to prevent hard pipeline compilation crashes.

---

## 3. Unified Modeling: Merging Facebook & Snapchat

To construct conformed dimensions and facts, the cohort moved from platform-specific models to unified marts.

```
       FACEBOOK AD PLATFORM                             SNAPCHAT AD PLATFORM
 ┌──────────────────────────────┐                 ┌──────────────────────────────┐
 │ stg_facebook_ads__campaigns  │                 │ stg_snapchat_ads__campaigns  │
 │ stg_facebook_ads__adgroups   │                 │ stg_snapchat_ads__adgroups   │
 │ stg_facebook_ads__ads        │                 │ stg_snapchat_ads__ads        │
 └──────────────┬───────────────┘                 └──────────────┬───────────────┘
                │                                                │
                ▼                                                ▼
 ┌──────────────────────────────┐                 ┌──────────────────────────────┐
 │  int_facebook_ads__joined    │                 │  int_snapchat_ads__joined    │
 └──────────────┬───────────────┘                 └──────────────┬───────────────┘
                │                                                │
                └───────────────────────┬────────────────────────┘
                                        │
                                        ▼  dbt_utils.union_relations
                         ┌─────────────────────────────┐
                         │   dim_marketing_ads         │
                         │   (Conformed Dimension)     │
                         └─────────────────────────────┘
                                        │
                                        │ 1:M Join on ad_id
                                        ▼
                         ┌─────────────────────────────┐
                         │   fct_marketing_spend_daily │
                         │   (Unified Fact Table)      │
                         └─────────────────────────────┘
```

### Eliminating Boilerplate with `dbt_utils.union_relations`
Instead of writing 200+ lines of brittle `UNION ALL` statements mapping dozens of mismatched column names, Victor demonstrated the `dbt_utils.union_relations` macro:

```sql
-- models/marts/marketing/dim_marketing_ads.sql
{{ config(materialized='table') }}

WITH unioned_platforms AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_facebook_ads__joined'),
            ref('int_snapchat_ads__joined')
        ],
        source_column_name='platform'
    ) }}
)

SELECT * FROM unioned_platforms
```
* **Advantage:** Automatically matches column schemas, injects `NULL` for platform-specific columns, appends a tracking column (`platform`), and keeps project code strictly DRY (Don't Repeat Yourself).

---

## 4. Lineage Observability: Beyond Model DAGs to Column-Level Lineage (CLL)

Victor challenged the cohort to examine standard documentation DAGs (`dbt docs generate`):

* **The Operational Gap:** Standard DAGs only illustrate table-to-table dependencies ($A \rightarrow B$). If an upstream software team announces they are deprecating `campaign_group_id`, a table-level DAG cannot tell you whether that specific column feeds financial reporting.
* **The Solution (Column-Level Lineage):** Integrating metadata tools (such as **Elementary**, **dbt-loom**, or **DataHub**) maps individual column flows from raw ingestion to downstream marts.
* **AI Integration:** Feeding structured column-level metadata directly into LLM agent interfaces (like Databricks Genie or Claude Code) allows engineers to query impact assessments using significantly fewer LLM context tokens.

---

## 5. Databricks Unity Catalog Architecture Demystified

A significant portion of the session cleared up pervasive confusion regarding **Workspaces**, **Environments**, **Catalogs**, and **Schemas**.

```
                           DATABRICKS ACCOUNT (Single Workspace)
  ═════════════════════════════════════════════════════════════════════════════════════
  CATALOG: ci_dev_catalog              CATALOG: silver_staging        CATALOG: gold_production
  (Ephemeral Developer PRs)            (Pre-Production QA)            (Live Enterprise Assets)
  ┌──────────────────────────────┐     ┌────────────────────────┐     ┌────────────────────────┐
  │ Schema: pr_snapchat_ads_101  │     │ Schema: preparation    │     │ Schema: marketing_spend│
  │ • stg_snapchat_ads           │     │ • int_facebook_joined  │     │ • dim_marketing_ads    │
  │ • int_snapchat_joined        │     │ • int_snapchat_joined  │     │ • fct_marketing_spend  │
  └──────────────────────────────┘     └────────────────────────┘     └────────────────────────┘
```

### Definitions & Governance Rules:

| Structural Unit | Purpose | Production Implementation |
| :--- | :--- | :--- |
| **Workspace** | The computing interface and collaboration plane. | Typically **one single workspace** across the team (separate workspaces are only provisioned for strict regulatory/isolation requirements). |
| **Environment** | The operational lifecycle tier. | **Dev** (Local terminal), **CI** (GitHub PRs), **Staging** (Pre-release QA), and **Prod** (Live). |
| **Catalog** | The top-level data container in Unity Catalog. | Segregated by environment and storage tier: `bronze_production`, `silver_staging`, `silver_production`, `gold_production`. |
| **Schema** | The logical domain grouping inside a catalog. | Mirrors business domains: `marketing_spend`, `crm`, `finance`, or lifecycle layers (`staging`, `preparation`). |

> **The Golden Environment Rule:** Schemas remain uniform across environments (e.g., `marketing_spend`), while the **Catalog** changes dynamically based on the active target environment (`gold_staging` vs. `gold_production`).

---

## 6. Production-Grade GitHub Actions CI/CD Architecture

Victor walked line-by-line through the enterprise CI/CD workflow located in `.github/workflows/dbt_ci_cd.yml` and `.github/actions/`:

```
   Pull Request Opened
          │
          ▼
   [ Step 1: Fetch Prod Manifest ] ──> Downloads latest production manifest.json artifact
          │
          ▼
   [ Step 2: Export Dynamic Schema] ──> Sanitizes branch: PR_snapchat_ads_20261024
          │
          ▼
   [ Step 3: Setup & Compile ]     ──> dbt deps, dbt debug, dbt source freshness
          │
          ▼
   [ Step 4: Drop Stale Schema ]   ──> Cleans previous runs from Databricks via drop_schema macro
          │
          ▼
   [ Step 5: Project Evaluator ]   ──> Enforces naming rules, documentation, and mandatory tests
          │
          ▼
   [ Step 6: Empty Dry Run ]       ──> Compiles SQL with --empty (Validates schema with 0 rows)
          │
          ▼
   [ Step 7: Slim CI Build ]       ──> dbt build --select state:modified+ --defer --state ./prod
          │
          ▼
   [ Step 8: Docs & Observability ]──> Generates lineage and uploads Elementary test report
```

### Deep Dive into Key CI/CD Steps:

#### 1. Dynamic Ephemeral PR Schemas
To ensure pull requests do not collide, the workflow dynamically computes a sanitized schema name directly from the Git reference:
```bash
# GitHub Action Script Step
PR_NAME="PR_${{ github.head_ref }}"
CLEAN_SCHEMA=$(echo "$PR_NAME" | tr '/.-' '___')
echo "DBT_DEV_SCHEMA=$CLEAN_SCHEMA" >> $GITHUB_ENV
```

#### 2. Cleaning Stale Branches on Re-Commit
When a developer pushes multiple commits to an open PR, the active workflow cancels running jobs and drops the temporary Databricks schema before rebuilding:
```sql
-- macros/drop_schema.sql
{% macro drop_schema(schema_name) %}
    {% set drop_query %}
        DROP SCHEMA IF EXISTS {{ target.catalog }}.{{ schema_name }} CASCADE;
    {% endset %}
    {% do run_query(drop_query) %}
{% endmacro %}
```

#### 3. Linting with `dbt-project-evaluator`
* Automatically blocks PR merges if:
  * A raw source is declared in `sources.yml` but has no downstream models referencing it.
  * A staging or mart model lacks a primary key test (`unique`, `not_null`).
  * Models violate standard naming conventions (e.g., staging models not prefixed with `stg_`).

#### 4. The `--empty` Compilation Dry-Run
* Executes `dbt build --empty` (or `WHERE 1=0`).
* Creates table structures and evaluates Databricks query plans without loading data rows, catching SQL syntax errors and column mismatches in seconds while consuming zero warehouse compute.

#### 5. Slim CI Execution (`state:modified+`)
* Rather than rebuilding all 500 models in the project, the runner inspects the downloaded production `manifest.json`:
  ```bash
  uv run dbt build --select state:modified+ --defer --state ./manifest_state
  ```
* **Result:** Only modified models and their direct downstream children build inside the ephemeral PR schema; unchanged upstream tables are referenced directly from production.

#### 6. Staging & Production Deployment Routing
* **Deploy to Staging:** Triggered dynamically when a reviewer applies the GitHub PR label `deploy-to-staging`.
* **Deploy to Production:** Triggered automatically upon merging into `main`. The workflow builds to `gold_production`, archives the new `manifest.json`, and triggers the cleanup job to drop the ephemeral PR schema from Databricks.

---

## 7. Live Troubleshooting Log & Student Q&A

| Participant | Question / Blocker | Resolution & Architectural Guidance |
| :--- | :--- | :--- |
| **John Babatunde** | Staging and mart models were joined into a single flat model without domain subfolders. | Maintain strict layer separation. Place marketing entities inside `models/marts/marketing/` rather than dumping files into a generic root folder. |
| **Lorreta Anyika** | Elementary test reports failed to display model test results. | Elementary was writing to the local `dev` schema instead of reading from `silver_production`. Point Elementary explicitly to production credentials in `profiles.yml`. |
| **Modinat Titilayo** | Confusion over whether catalogs or schemas change across environments. | Schemas remain constant (`marketing_spend`); the **Catalog** changes dynamically based on the active target environment (`silver_staging` vs. `silver_production`). |
| **Osakpolor Ogieriakhi** | How do we trigger deployment to staging without multiple long-lived Git branches? | Use **GitHub Labels**. Applying `deploy-to-staging` triggers the staging action while maintaining a single, clean `main` branch. |
| **Kwabena Baffour** | Do intermediate models get deployed to production, or only Gold marts? | All layers build to production, but each routes to its dedicated catalog: Staging/Intermediate land in `silver_production`, while Marts land in `gold_production`. |

---

## 8. Comprehensive Action Checklist

### For Students & Engineers:
* [ ] **Review Repository Codebase:** Inspect the unified marketing implementation on Victor's repository: [`github.com/victoredo/cdc_modelling`](https://github.com/victoredo/cdc_modelling).
* [ ] **Enforce Entity Deduplication:** Implement `QUALIFY ROW_NUMBER() OVER (PARTITION BY ... ORDER BY updated_at DESC) = 1` across all ad staging models.
* [ ] **Implement Unified Unions:** Refactor disparate platform models into conformed marts using `dbt_utils.union_relations`.
* [ ] **Audit CI/CD Configuration:**
  * Configure GitHub Secrets (`DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_HTTP_PATH`).
  * Verify `drop_schema` macro execution on PR closure.
  * Run `dbt-project-evaluator` to eliminate unused sources and un-tested models.