# CDE Bootcamp 3: Learning Data Engineering, One Pipeline at a Time

Welcome to my **Core Data Engineers Bootcamp** learning journal. This repository follows my journey from understanding how data moves through modern systems to working confidently with Linux, Git, GitHub, SQL, and production-minded engineering practices.

The goal is simple: learn the concepts, practise the workflows, and leave a useful trail of notes behind. Data may arrive messy, but the repository does not have to.

## What Is Inside?

```text
cdebootcamp3/
├── assignments/   # Applied projects and design exercises
├── classes/       # Session notes, practical examples, and SQL scripts
└── README.md       # You are here
```

## Learning Roadmap

| Session | Topic | Highlights |
| :---: | --- | --- |
| 01 | [Data Engineering Fundamentals I](classes/01DengFundamentals1.md) | Data lifecycles, ingestion, storage, ETL/ELT, OLTP, and OLAP |
| 02 | [Data Engineering Fundamentals II](classes/02DengFundamentals2.md) | Compute, storage, networking, system architecture, and DataOps |
| 03 | [Linux I](classes/03Linux1.md) | Linux fundamentals, filesystems, and the command line |
| 04 | [Git I](classes/04Git1.md) | Version control, staging, commits, branches, and remotes |
| 05 | [Linux II](classes/05Linux2.md) | Shells, pipes, redirection, text processing, and users |
| 06 | [Linux III](classes/06Linux3.md) | System administration and deeper Linux operations |
| 07 | [Git II](classes/07Git2.md) | Real-world collaboration, pull requests, and branch protection |
| 08 | [Git III](classes/08Git3.md) | CI/CD, GitHub Actions, reviews, and production workflows |
| 09 | [SQL I: RDBMS Foundations](classes/09SQL1.md) | Data classification, normalization, DDL/DML, transactions, and referential integrity |
| 10 | [SQL II: Querying Data](classes/10SQL2.md) | DQL, filtering, date functions, sorting, aggregation, `WHERE`, and `HAVING` |

The SQL sessions are supported by practical scripts for [creating the Parch & Posey tables](classes/assets/Parch_and_Posey_Create_Table.sql), [loading sample data](classes/assets/Parch_and_Posey_Insert_Data.sql), and [practising DML operations](classes/assets/DML%20SQL%20Script.sql).

## Featured Assignment

### Beejan Technologies Complaint Data Pipeline

The first assignment designs a conceptual end-to-end pipeline for customer complaints arriving through social media, call-centre logs, SMS, and website forms. It covers hybrid ingestion, cleaning, classification, layered storage, serving, orchestration, monitoring, and DataOps.

[Read the full design](assignments/A1-DataEngineeringFundamentals.md)

![Beejan Technologies conceptual complaint data pipeline](assignments/assets/pipeline-diagram.png)

## Key Ideas I Am Building On

- Reliable pipelines begin with a clear understanding of their sources.
- Raw data should remain recoverable; curated data should remain trustworthy.
- Batch and streaming are design choices, not popularity contests.
- Linux fluency makes infrastructure less mysterious.
- Git is more than a backup tool: it is how engineering teams collaborate safely.
- SQL turns relational data into trustworthy answers, but safe filtering and transaction discipline matter.
- Testing, reviews, observability, and documentation are part of the product.

## How to Explore

Start with [Session 01](classes/01DengFundamentals1.md), follow the roadmap in order, and then visit the [assignments](assignments/) to see the concepts applied. The SQL scripts in [classes/assets](classes/assets/) provide hands-on practice alongside Sessions 09 and 10. Each class file is written as a standalone reference, so jumping directly to a topic works too.

## About This Repository

This is an evolving collection of notes and assignments created during **CDE Bootcamp 3**. It documents both the technical material and the professional habits behind dependable data systems.

---

<p align="center"><strong>From raw events to reliable insight.</strong></p>
