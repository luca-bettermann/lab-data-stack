# Lab Data Stack — Tech Stack Overview

**Audience:** Lab colleagues who want to understand what the system is and how the pieces
fit together, without needing a software development background.

---

## What Problem Does This Solve?

Labs generate data constantly — measurements, samples, experiments, observations.
This data often ends up scattered: some in spreadsheets on one person's laptop, some
in email attachments, some in notebooks. That makes it hard to find, compare, or
visualise.

The Lab Data Stack brings all lab data into one central place that everyone on the
network can access. It lets anyone enter data through a familiar spreadsheet-style
interface, and anyone else create graphs and dashboards to make sense of it —
all without writing code.

---

## The Three Components

### 1. PostgreSQL — The Database

**What it is:** A database is a program that stores information in an organised,
structured way — think of it as a highly reliable, searchable filing cabinet that
can hold millions of records without slowing down.

**What PostgreSQL does in our stack:** PostgreSQL is the central storage layer.
Every piece of data you enter in NocoDB is actually stored in PostgreSQL.
Every chart you see in Superset reads its data from PostgreSQL. Neither NocoDB
nor Superset hold data themselves — PostgreSQL holds everything.

**Why PostgreSQL specifically:** PostgreSQL is one of the most widely used and
trusted open-source databases in the world, with over 35 years of development.
It handles multiple users simultaneously, enforces data integrity (no corrupted
or inconsistent records), and can scale from a small lab to a large enterprise
without changing how you use it. It is free, runs on any operating system, and
is supported by every major data tool on the market.

**Access:** PostgreSQL is intentionally not accessible directly from the internet
or even from your browser. It is a background service — the "engine" that other
components talk to. Only NocoDB and Superset communicate with it, through the
private Docker network.

---

### 2. NocoDB — The Data Entry Interface

**What it is:** NocoDB gives you a spreadsheet-like view of your database tables,
directly in a web browser. You can create tables, add columns, fill in rows, filter
and sort — all without knowing anything about databases or SQL.

**What NocoDB does in our stack:** NocoDB is the front door for putting data in.
When a researcher wants to log a new experiment, sample, or measurement, they open
NocoDB, find the right table, and type in the values — just like filling in a
Google Sheet. NocoDB translates those actions into database operations and stores
the result in PostgreSQL.

**Why NocoDB:** Many data-entry tools either require technical knowledge (writing
SQL queries) or are closed-source cloud services (like Airtable) that charge per
seat and keep your data on someone else's servers. NocoDB is:

- **Self-hosted:** Your data stays on your own machine/server.
- **Free and open-source:** No per-user fees.
- **Familiar interface:** Anyone who has used Excel or Google Sheets can use NocoDB
  within minutes.
- **Flexible:** Supports many column types (text, numbers, dates, attachments,
  relationships between tables, drop-down lists, etc.).

**Access:** http://localhost:8080 (on your Mac) or http://server-ip:8080 (on the lab
network).

---

### 3. Apache Superset — The Visualisation Tool

**What it is:** Apache Superset is a web application for creating interactive charts,
graphs, maps, and dashboards from data stored in a database. You connect it to a
database, pick a table, choose a chart type, and Superset draws the chart — no
coding required.

**What Superset does in our stack:** Superset is the front door for understanding
data. Once data is in PostgreSQL (entered via NocoDB or any other source), Superset
can query it and display it as bar charts, line graphs, scatter plots, heatmaps,
tables, and more. You can combine multiple charts into a dashboard that updates
automatically as new data comes in.

**Why Superset:** Superset is the industry-standard open-source data visualisation
tool, developed and maintained by the Apache Software Foundation (the same
organisation behind many foundational internet technologies). It is:

- **Self-hosted:** Dashboards and data stay on your server.
- **Free and open-source:** Used by companies like Airbnb, Twitter, and Lyft
  at massive scale.
- **Powerful but accessible:** Simple charts take two clicks; complex multi-table
  analyses are also possible for those who want them.
- **Shareable:** Dashboards have URLs you can share with colleagues.

**Access:** http://localhost:8088 (on your Mac) or http://server-ip:8088 (on the lab
network).

---

## How the Three Components Connect

Here is a diagram of how data flows through the system:

```
  YOU (in your browser)
         |
  ┌──────┴──────────────────────────────┐
  │                                      │
  ▼                                      ▼
NocoDB                              Superset
(Data Entry)                   (Data Visualisation)
http://...:8080                  http://...:8088
     │                                   │
     │  reads & writes                   │  reads only
     │                                   │
     └──────────────┬────────────────────┘
                    │
                    ▼
              PostgreSQL
           (Central Database)
           [not browser-accessible]
```

- **NocoDB** reads from and writes to PostgreSQL. When you add a row in NocoDB,
  it appears in PostgreSQL immediately.
- **Superset** reads from PostgreSQL. It only reads — it never modifies your data.
- **PostgreSQL** is the single source of truth. Even if NocoDB or Superset are
  restarted, the data in PostgreSQL is unchanged.

---

## What Is Docker and Why Does It Matter?

**The short version:** Docker is a way of packaging software so that it runs the
same way on any computer, without installation conflicts.

Each of the three services (PostgreSQL, NocoDB, Superset) runs inside its own
isolated "container" — a lightweight, self-contained environment that includes
all the software it needs. Docker manages these containers and lets them talk to
each other over a private internal network.

**What this means for you:**
- You don't need to install PostgreSQL, Python, or Node.js on your Mac or server.
- The stack runs identically on your Mac and on a Linux lab server.
- Each service is isolated — if Superset crashes, it doesn't affect PostgreSQL
  or NocoDB.
- Updates are straightforward: pull a new image version and restart.

---

## Data Storage and Persistence

Data is stored in **Docker volumes** — special storage areas managed by Docker
that persist even when containers are stopped or updated.

| Volume | What's stored there |
|---|---|
| `lab_postgres_data` | All PostgreSQL databases (your lab data, NocoDB config, Superset config) |
| `lab_nocodb_data` | NocoDB file attachments and uploads |
| `lab_superset_home` | Superset user sessions and cache |

**Backup:** The most important volume is `lab_postgres_data`. Backing up PostgreSQL
(see the README) backs up everything — your NocoDB tables and data, and all Superset
dashboards and chart configurations.

---

## Security Considerations

**For use on a trusted local network:** The current setup is suitable for a lab
network where you trust everyone who can access the server. Access is controlled
by the login screens in NocoDB and Superset.

**What is protected:**
- PostgreSQL is not accessible from outside the Docker network (no external port).
- Passwords and secret keys are stored in the `.env` file, not in code.
- Superset sessions are encrypted using the `SUPERSET_SECRET_KEY`.

**What is NOT set up (and would be needed for internet exposure):**
- HTTPS (encrypted traffic) — requires a domain name and SSL certificate.
- Network-level firewall rules — beyond the port allowances in the server setup.

If you ever need to expose this stack to the internet (rather than just the lab
network), consult with a system administrator before doing so.

---

## Why This Stack Was Chosen

The goal was a self-hosted, free, and maintainable system with three properties:

1. **No coding required for day-to-day use** — NocoDB and Superset both have
   polished, user-friendly interfaces.

2. **Data stays on your hardware** — nothing is sent to a third-party cloud service.
   This matters for unpublished research data and for compliance with data management
   policies.

3. **Industry-standard components** — PostgreSQL, Apache Superset, and NocoDB are
   all actively maintained, widely used, and well-documented. If you ever need help
   or want to extend the system, you'll find abundant resources online.

**Alternatives considered:**

| Alternative | Why not chosen |
|---|---|
| Airtable | Cloud-hosted (data leaves your lab), expensive at scale |
| Notion databases | Cloud-hosted, limited analysis features |
| Excel/Google Sheets | No central single source of truth, version conflicts |
| Metabase + Airtable | Metabase is excellent but lacks the data-entry component; Airtable is cloud-only |
| Full custom application | Requires a developer to build and maintain |

The Lab Data Stack gives you the benefits of a custom data platform — centralised
storage, structured data entry, and professional visualisation — without requiring
a developer to maintain it.
