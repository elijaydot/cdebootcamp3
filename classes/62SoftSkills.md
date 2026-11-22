# CDE Bootcamp 3.0: The High-Performer Playbook — Building Habits & Skills of an Exceptional Data Engineer

> *"Technical excellence gets you in the door, but communication, business curiosity, and stakeholder trust determine how fast you rise. Never stop at being a 'data bender' who just builds pipelines and dashboards—speak outcomes instead of outputs, begin with the end goal in mind, and become a true Partner in Progress."*
>
> — **Oloyede Akinmade ("Mr. Oye")**

**Date:** November 21, 2026  
**Duration:** 132 Minutes  
**Guest Speaker:** Oloyede Akinmade ("Mr. Oye") — Solution Owner at SunExpress Airlines; Certified Product Owner & Product Analyst (formerly at KFC, McKesson Europe, Next Level Coffee; Co-founder of NextWave Solutions & Velocity Technologies; First-Class Graduate of FUTA & Master's Alumnus in Germany)  
**Host & Moderator:** Blessing Akwaowo ("CDE Communications")  
**Curriculum Module:** Career Acceleration & Executive Soft Skills — Stakeholder Mapping, Requirement Discovery, Technical-to-Business Translation, Crisis Communication, Time Management Frameworks & Leadership Without Authority

---

## Executive Overview & Class Atmosphere

Stepping away from YAML files, Terraform state locks, and Spark executors, this Saturday afternoon masterclass focused on the invisible multiplier that separates mid-level technicians from high-impact senior engineers and tech leads: **Executive Soft Skills**.

Hosted energetically by Blessing ("CDE Communications"), the session welcomed **Oloyede Akinmade ("Mr. Oye")**, a seasoned digital product leader and solution owner with over seven years of cross-industry experience spanning aviation, e-commerce, pharmaceuticals, retail, and fintech across Africa and Europe.

Mr. Oye dismantled the common trap that ensnares deeply technical engineers: believing that writing clean code or working 48 hours nonstop to fix a pipeline bug speaks for itself. Through candid stories from boardrooms, requirement clashes between Actuarial and Product heads, acronym misunderstandings (`GTM` = *Go-To-Market* vs. *Google Tag Manager*), and live role-play simulations with students, he laid out a step-by-step blueprint for turning raw data engineering skills into undeniable business influence.

---

## Part 1: Outputs vs. Outcomes — Becoming a "Partner in Progress"

Mr. Oye opened with a defining lesson from his early career when presenting to a Chief Client Officer (CCO). After listing every task he had completed, the CCO looked at him and said: *"Everything you just showed me is just outputs. I see zero outcomes."*

```
+-----------------------------------------------------------------------------------------+
|                   THE EVOLUTION OF A DATA PROFESSIONAL                                  |
|                                                                                         |
|  [ Level 1: The "Data Bender" / Technician ]                                            |
|  - Speaks in Outputs: "I built an Airflow DAG joining 4 tables into Redshift."          |
|  - Waits passively for tickets; builds dashboards nobody opens.                         |
|  - Treated as a ticket-taker / cost center.                                             |
|                                           │                                             |
|                                           ▼ (Shifts Mindset: "Begin with the End")      |
|  [ Level 2: The "Partner in Progress" / High-Performer ]                                |
|  - Speaks in Outcomes: "This automated feed cuts reporting latency by 6 hours and       |
|    identifies top-churning regions so Sales can intervene before renewal."              |
|  - Proactively surfaces Friday pet-project insights; challenges vague requirements.     |
|  - Invited into strategic leadership rooms; fast-tracked for promotions!                |
+-----------------------------------------------------------------------------------------+
```

### Real-World Case Study: The App Splash Screen Insight
* **The Context:** Mr. Oye mentioned to a data analyst on his team that he was considering redesigning the airline app's splash screen to feature travel destinations.
* **The High-Performer Move:** Instead of waiting for a formal Jira ticket, the analyst took initiative, queried historical customer search and booking trends, and returned with actionable insights: *"Here are the top 5 most-searched destinations vs. least-traveled routes—highlighting these three specific cities on the splash screen will capture high-intent traffic."*
* **The Result:** Immediate executive trust. The analyst transitioned from a dashboard builder into a strategic thought partner.

---

## Part 2: Stakeholder Mapping & Department-Tailored Communication

A **Stakeholder** is any individual, team, or executive impacted by—or capable of influencing—your data pipelines and analytical deliverables. Mr. Oye stressed that you must map stakeholders not merely by their job title, but by their **Power/Influence**, **Interest Level**, and **Human Personality**.

### 1. The 2D Power–Interest Stakeholder Matrix

```
        HIGH POWER / INFLUENCE
                  ▲
                  │
  [ KEEP SATISFIED / INFORMED ]      [ MANAGE CLOSELY (Key Players) ]
  - e.g., CFO, VP of Engineering     - e.g., Direct Manager, Product Owner
  - Busy executives; want concise,   - Deeply invested; need regular updates,
    bottom-line summaries & risks.     early alignment & clear trade-offs.
                  │
  ────────────────┼──────────────────────────────────────────────────►
                  │                                           HIGH INTEREST
  [ MONITOR (Minimal Effort) ]       [ KEEP INFORMED (Vocal Allies) ]
  - e.g., Peripheral teams           - e.g., Marketing Analysts, Ops Leads
  - Periodic status broadcasts;      - High day-to-day usage; need clear
    avoid overwhelming with noise.     documentation & training.
                  │
```

### 2. Tailoring Your Message Across Business Units
Never use the same vocabulary across different departments:

| Department / Stakeholder | What They Care About Most | Communication Strategy |
| :--- | :--- | :--- |
| **Finance (CFO)** | Revenue accuracy, cash inflows/outflows, cloud cost control, auditability | Lead with exact numbers, financial variance, and timeline to resolution. |
| **Marketing (CMO)** | Customer acquisition, campaign ROI, retention, churn rates | Highlight customer segments, conversion funnels, and channel performance. |
| **Sales (Head of Sales)** | Closed deals, pipeline velocity, cancellations, regional targets | Focus on conversion blockers, top-performing products, and lead drop-offs. |
| **Compliance & InfoSec** | Data privacy (GDPR), access controls, vulnerabilities, audit trails | **Over-communicate upfront:** provide thorough security documentation early to prevent review bottlenecks. |
| **Legal Team** | Contractual liability, regulatory exposure | **Keep it concise and targeted:** supplying excessive unprompted pages invites endless legal redlines. |
| **C-Suite / CEO** | High-level strategic impact, bottom-line risk, clear decisions | **Be brief (under 2 minutes):** Answer first, impact second, next steps third. *(e.g., Mr. Oye's 2-minute elevator pitch to the Head of Technology).* |

### 3. The Acronym Trap (`GTM` Lesson)
Mr. Oye shared a humorous cautionary tale: he invited the Head of Marketing Analytics to a *"GTM Workshop."* He meant **Go-To-Market** (product launch strategy), while she assumed **Google Tag Manager** (analytics tracking tags)—causing complete misalignment. **Never assume shared acronyms across departments; spell terms out explicitly.**

---

## Part 3: Requirement Discovery — Pushing Back on Vague & Unrealistic Requests

When stakeholders approach you saying, *"I need a blue ship with a steam engine powered by AI by next Tuesday,"* accepting the request blindly guarantees wasted weeks building a submarine nobody uses.

### The Requirement Discovery Toolkit:
1. **Ask the "5 Ws" & Diagnostic Questions Before Writing Code:**
   * *"What specific business decision will this data support?"*
   * *"What does success look like for this project?"* *(Forces the stakeholder to begin with the end goal in mind).*
   * *"Who needs access to this output, and how frequently will they use it?"*
   * *"What is explicitly **out of scope** for Phase 1 so we can deliver value iteratively?"*
2. **The "Three Whys" Technique:**
   * Ask *"Why?"* three consecutive times to peel away surface requests and uncover the true root business problem:
     * *Request:* "I need a regional sales export." $\rightarrow$ *Why #1?* "Because the regional office is complaining." $\rightarrow$ *Why #2?* "Their stock numbers don't match HQ." $\rightarrow$ *Why #3?* "Inventory syncs are delayed by 24 hours." *(True solution: Fix the inventory sync latency, not build a manual export!).*
3. **Handling Conflicting Requirements Across Hierarchy:**
   * When two senior leaders give contradictory business rules (such as Mr. Oye's clash between the Head of Actuarial and Head of Product over insurance premium multipliers), **never argue emotionally or guess**. Send a polite, objective email summarizing both conflicting specifications, tag both leaders alongside your manager, and ask for written alignment on which rule governs production.

---

## Part 4: Technical-to-Business Translation & Crisis Communication

When a production pipeline breaks 30 minutes before an executive board meeting, technical jargon destroys stakeholder confidence.

### Jargon vs. Executive Translation:

| Scenario | ❌ Technical Jargon (Confuses Executives) | ✅ Executive Business Translation (Builds Trust) |
| :--- | :--- | :--- |
| **Broken Revenue Dashboard** | *"Our Airflow ELT DAG failed during the Redshift merge because upstream Postgres introduced a schema drift dropping revenue by 18%."* | *"We detected an unexpected formatting change in today's incoming sales feed that temporarily under-reported revenue by 18%. Our team has isolated the issue and the corrected report will be live by 11:00 AM."* |
| **Slow Query Performance** | *"Data scientists are running unoptimized cross-joins causing heavy disk spills and CPU saturation on our warehouse cluster."* | *"Heavy ad-hoc modeling queries are currently slowing down morning executive reports. We are moving those workloads to a separate environment today so dashboard speeds return to normal."* |

### The 4 Cornerstones of Stakeholder Trust (`S-I-A-N` Framework):
Whenever reporting progress or incidents, structure your update in four crisp bullets:
1. **Status:** Where are we right now? *(e.g., "Data ingestion is 80% complete; validation is underway.")*
2. **Impact:** How does this affect business operations or revenue? *(e.g., "Marketing campaign metrics are delayed by 2 hours, but customer checkouts are unaffected.")*
3. **Action:** What concrete steps are we taking right now? *(e.g., "We are patching the schema parser and re-running today's batch.")*
4. **Next Update:** Exactly when will the stakeholder hear from you next? *(e.g., "I will send a confirmed status update at 2:00 PM sharp.")*

> **Golden Rule:** Always separate **verified facts** from **hypotheses** (*"Based on December seasonal trends, we hypothesize flight bookings are rising due to holiday travel, which we are confirming with marketing data"*).

---

## Part 5: Mastering Time Management & Defeating Workplace Chaos

A typical day for a data engineer involves simultaneous interruptions: a broken revenue pipeline at 9:00 AM, a CFO verifying numbers, a Marketing segmentation request, a 10:00 AM standup, Jira comments, Slack pings, and personal life commitments. Without a system, you invite **burnout, technical debt, and missed deadlines**.

### 1. The Eisenhower Priority Matrix (Urgency vs. Importance)

```
                     URGENT                              NOT URGENT
          +-----------------------------------+-----------------------------------+
          |        QUADRANT 1: DO NOW         |      QUADRANT 2: SCHEDULE         |
IMPORTANT | - Broken production revenue DAG   | - Strategic architecture upgrades |
          | - P0 / P1 data outage             | - Deep work & documentation       |
          | - CFO board report due in 1 hour  | - Refactoring technical debt      |
          +-----------------------------------+-----------------------------------+
          |       QUADRANT 3: DELEGATE        |      QUADRANT 4: ELIMINATE        |
NOT       | - Routine status inquiries        | - Doomscrolling TikTok/Instagram  |
IMPORTANT | - Non-critical ad-hoc pings       | - Unscheduled office gossip (GTA6)|
          | - Redirect to self-serve docs     | - Low-value meetings w/o agendas  |
          +-----------------------------------+-----------------------------------+
```

### 2. High-Performance Productivity Frameworks:
* **"Eat That Frog":** Identify the single hardest, ugliest, most high-impact task on your list and tackle it **first thing in the morning** before checking Slack or email.
* **Calendar Time-Blocking & Deep Work:** Block 2-to-4-hour windows on your work calendar marked as **Busy — Deep Work**. Silence phone notifications, turn your phone face-down, and execute uninterrupted engineering work.
* **The 3-3-3 Method:** Dedicate **3 hours** to your single most important project, complete **3 urgent shorter tasks**, and handle **3 maintenance/admin activities** (emails, Jira hygiene, standups).
* **The 1-3-5 Rule:** Plan each day around completing **1 major task**, **3 medium tasks**, and **5 small tasks**.
* **Strategic Negotiation ("Yes, If..."):** When overloaded with five competing deadlines in four days, never silently burn out. Approach your manager professionally: *"I have Tasks A, B, and C on my plate for Thursday. Taking on Task D today means pushing Task C to Monday—which priority would you prefer I focus on first?"*

---

## Part 6: Leadership Without Authority & Career Acceleration

You do not need a "Lead" or "Manager" title to lead:
* **Take Radical Ownership:** If you spot a data quality gap, missing documentation, or an undocumented pipeline, step up and fix it without waiting to be asked.
* **Build Cross-Functional Social Currency:** Don't stay isolated inside the engineering silo. Grab virtual or in-person coffees with colleagues in Finance, Sales, and Marketing. People help and trust colleagues they know as human beings.
* **Be Relentlessly Inquisitive & Coachable:** In your first 90 days on a new job, ask *"Why?"* constantly to learn the domain model, remain humble and coachable, and become the reliable problem-solver your manager never has to micromanage.

---

## Part 7: Comprehensive Student Q&A Index

| Student | Core Question | Mr. Oye's Practical Guidance |
| :--- | :--- | :--- |
| **Temitope Asama** | *What slows down data engineering impact most?* | Unclear requirements and unrealistic stakeholder timelines ("we need this built by next week" without accounting for data discovery, modeling, and QA). |
| **Oluwatobi Owamokele** | *How do you manage difficult stakeholders who hold preconceived biases against you (e.g., as a Black woman in tech) and refuse to listen?* | Anchor every conversation in **undeniable data evidence and business outcomes**. Don't engage in emotional battles in large group settings; build 1-on-1 alignment first, document requirements and decisions in writing, and let consistent, high-impact delivery dismantle bias over time. |
| **Josephine Adah** | *How do you navigate complex organizational hierarchies when communicating across teams?* | Identify who owns the decision and who is impacted. When middle managers block clarity or give conflicting instructions, send a neutral, fact-based summary email copying the relevant leads and your line manager to establish transparent alignment. |
| **Temitope Asama** | *As a brand-new intern or junior engineer, what specific habits lead to rapid promotions?* | 1. **High inquisitiveness** (asking *why* to master the business domain).<br>2. **Radical ownership** (solving problems end-to-end without hand-holding).<br>3. **Coachability** (absorbing feedback fast).<br>4. **Outcome-focused updates** (making your manager's life easier). |
| **Goodness Azike** | *As a neurodivergent engineer experiencing severe social anxiety during daily standups and presentations, how can I communicate clearly without rambling?* | **Preparation eliminates anxiety:**<br>1. Use sticky notes or flashcards with 3 bullet points (*What I did, What I'm doing next, Any blockers*).<br>2. **Answer first, explain second** (state the conclusion upfront before details).<br>3. Practice aloud in front of a mirror or record voice notes to trim filler words before the meeting. |
| **Pelumi Tytler** | *Is it okay for a new hire to reach out directly to other departments (Finance, Marketing) to ask questions, or must everything go through my manager?* | After initial introductions, **reach out directly!** Build genuine work friendships across departments through brief 10-minute coffee chats. Having trusted allies in Finance or Marketing gives you insider context that makes your data work 10x more accurate. |

---

## Part 8: Practical Role-Play Exercises & Workplace Action Playbook

During the session, Mr. Oye conducted live role-play simulations where students (**Oluwatobi Owamokele**, **Temitope Asama**, and **Chinenye Jessica**) practiced translating technical analytics projects into zero-jargon executive briefings for C-suite leaders.

### Exercise 1: The "Zero-Jargon" Executive Briefing Drill (Self-Practice)

#### Objective:
Practice translating a complex technical data engineering pipeline into a crisp, 60-second business briefing for a non-technical executive (CEO/CFO/CMO) without mentioning a single tool (`SQL`, `Airflow`, `Spark`, `Redshift`, `Terraform`).

#### Step-by-Step Execution Guide:
1. **Pick Your Current Technical Project:**
   * Select any pipeline or dashboard you built during the bootcamp (e.g., an Airbyte/Airflow pipeline ingesting e-commerce orders into a data warehouse).
2. **Strip Out All Technical Nouns:**
   * Ban words like *DAG, ingestion, schema, Parquet, S3, Docker, join, SQL, query, cluster*.
3. **Draft Your 4-Sentence Executive Pitch Using the `S-I-A-N` Template:**
   * **Sentence 1 (Context & Status):** *"We have automated our daily customer order tracking across all regional stores so leadership no longer waits 48 hours for manual spreadsheets."*
   * **Sentence 2 (Key Business Insight / Impact):** *"Our latest numbers show that website orders retain 25% more repeat buyers than social media ads, with our highest growth coming from customers aged 25–30 in Lagos and Ogun State."*
   * **Sentence 3 (Recommended Action):** *"We recommend shifting 15% of next month's ad budget toward website conversion campaigns targeting that demographic."*
   * **Sentence 4 (Next Step / Timeline):** *"I will share the full regional breakdown with the Marketing Lead by 4:00 PM today."*
4. **Record & Critique Yourself:**
   * Record a 60-second voice note on your phone delivering the pitch. Listen back to verify: *Would a 12-year-old or a busy CFO immediately understand the business value?*

---

### Exercise 2: The Monday Morning Chaos Prioritization Drill

#### Objective:
Apply the **Eisenhower Matrix** and **Stakeholder Mapping** to triage competing workplace requests without burning out.

#### Scenario Prompt:
You log in at 9:00 AM Monday with an **8-hour workday** and face five incoming requests:
1. **Broken Production Revenue Pipeline** (CFO needs numbers for a 12:00 PM board call — *Est. 3 hours*).
2. **Marketing Customer Segmentation Request** (CMO wants ad-hoc campaign metrics by Thursday — *Est. 3 hours*).
3. **Finance Cost Reconciliation** (Finance analyst wants AWS billing tags explained by Friday — *Est. 2 hours*).
4. **Colleague Asking for Help Debugging a Local Docker Setup** (*Est. 1 hour*).
5. **Unscheduled Slack Message Discussing Weekend Football / Movies** (*Est. 30 mins*).

#### Step-by-Step Execution Guide:
1. **Triage into Quadrants:**
   * **Quadrant 1 (Do Immediately — 9:00 AM to 12:00 PM):** Fix the **Broken Production Revenue Pipeline** (3 hours). Send an immediate `S-I-A-N` update to the CFO at 9:10 AM confirming the fix will be ready before 12:00 PM.
   * **Quadrant 2 (Time-Block for Afternoon — 1:00 PM to 4:00 PM):** Block 3 hours on your calendar (`Busy — Deep Work`) to execute the **Marketing Segmentation Request** so you stay ahead of Thursday's deadline.
   * **Quadrant 2 (Schedule for Tuesday Morning — 9:00 AM to 11:00 AM):** Reply to the Finance analyst scheduling a 15-minute alignment call tomorrow morning and commit to delivering the AWS cost breakdown by Tuesday afternoon.
   * **Quadrant 3 (Delegate / Async Unblock):** Send your colleague a link to the team's Docker troubleshooting guide and offer a quick 10-minute huddle at 4:30 PM if they are still stuck.
   * **Quadrant 4 (Eliminate During Work Hours):** Mute non-work banter threads until your 5:00 PM wrap-up.
2. **Close the Day with a 5-Minute Review:**
   * Check off completed tasks, prepare tomorrow's "Eat That Frog" top priority on a sticky note, and log off with zero lingering stress.

---

## 🔗 Additional Resources & Recommended Reading

* 📖 **Book Recommendation (Referenced Principle):** *The 7 Habits of Highly Effective People* by Stephen R. Covey (*Habit 2: Begin with the End in Mind* & *Habit 3: Put First Things First / Eisenhower Matrix*)
* 📖 **Book Recommendation:** *Eat That Frog!* by Brian Tracy (Overcoming procrastination on high-impact tasks)
* 🤝 **Connect with the Speaker:** Look up **Oloyede Akinmade** on LinkedIn (shared in the CDE Bootcamp Slack channel) to connect and continue the conversation on product-minded data engineering.