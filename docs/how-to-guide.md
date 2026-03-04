# How-To Guide: NocoDB and Apache Superset

**Audience:** Lab colleagues who will use the system to enter data and create visualisations.
No technical background is assumed.

**Prerequisites:** The Lab Data Stack is running and you can open these URLs:
- NocoDB: http://localhost:8080 (or http://server-ip:8080 on the lab network)
- Superset: http://localhost:8088 (or http://server-ip:8088 on the lab network)

---

## Table of Contents

**Part 1 — NocoDB (Data Entry)**
1. [Signing In to NocoDB](#1-signing-in-to-nocodb)
2. [Creating a New Base (Project)](#2-creating-a-new-base-project)
3. [Creating a New Table](#3-creating-a-new-table)
4. [Adding and Configuring Columns](#4-adding-and-configuring-columns)
5. [Entering Data](#5-entering-data)
6. [Filtering and Sorting Data](#6-filtering-and-sorting-data)
7. [Importing Data from a CSV or Spreadsheet](#7-importing-data-from-a-csv-or-spreadsheet)
8. [Creating Views](#8-creating-views)
9. [Linking Tables Together](#9-linking-tables-together)

**Part 2 — Apache Superset (Visualisation)**
10. [Signing In to Superset](#10-signing-in-to-superset)
11. [Connecting to a Database](#11-connecting-to-a-database)
12. [Adding a Dataset (Table)](#12-adding-a-dataset-table)
13. [Creating a Chart](#13-creating-a-chart)
14. [Creating a Dashboard](#14-creating-a-dashboard)
15. [Editing and Refreshing Dashboards](#15-editing-and-refreshing-dashboards)
16. [Common Chart Types and When to Use Them](#16-common-chart-types-and-when-to-use-them)

---

# Part 1 — NocoDB (Data Entry)

NocoDB looks and works like a spreadsheet, but stores everything in a proper database.
Think of it as a self-hosted Airtable.

---

## 1. Signing In to NocoDB

1. Open http://localhost:8080 (or your server's URL) in a browser.
2. **First time only:** You will see a "Sign Up" form. Enter your email address and
   choose a password, then click **Sign Up**. This creates your NocoDB account.
3. **Subsequent visits:** Enter your email and password and click **Sign In**.

> **Note on accounts:** The first person to sign up becomes the "super admin" and can
> invite other team members later via **Team & Settings -> Team**.

---

## 2. Creating a New Base (Project)

In NocoDB, a **Base** is a container for related tables — similar to a "workbook"
in Excel or a "database" in Airtable. You might have one base per project or per
research area.

1. On the left sidebar, click the **+** icon next to "Bases" (or the **New Base** button).
2. Choose **Create new base**.
3. Give it a name (e.g., "Experiment Logs 2024", "Sample Inventory").
4. Click **Create Base**.

You now have an empty base with one blank table called "Table1".

---

## 3. Creating a New Table

A **table** is like a single sheet in a spreadsheet. Each row is one record (e.g., one
experiment), and each column is one type of information (e.g., date, sample ID, result).

### Create a blank table

1. In the left sidebar, click **+ Add new table** (at the bottom of the table list
   inside your base).
2. Enter a name for the table (e.g., "Measurements", "Samples", "Patients").
3. Press **Enter** or click **Save**.

### Import a table from a CSV or Excel file

See [Section 7](#7-importing-data-from-a-csv-or-spreadsheet) below.

---

## 4. Adding and Configuring Columns

NocoDB creates a default table with a few starter columns (ID, Title, etc.).
You will want to add columns that match your data.

### Add a new column

1. Click the **+** icon to the right of the last column header.
2. A panel opens on the right side. Enter the **column name** (e.g., "Sample ID",
   "Temperature (°C)", "Observation Date").
3. Choose a **field type** from the dropdown. Common types:

   | Field Type | Use it for |
   |---|---|
   | **Single line text** | Short text (names, IDs, codes) |
   | **Long text** | Notes, descriptions, free text |
   | **Number** | Integers or decimals (measurements, counts) |
   | **Decimal** | Numbers with decimal places |
   | **Date** | A calendar date |
   | **Date and time** | A specific date + time |
   | **Checkbox** | Yes/No, True/False values |
   | **Single select** | One option from a fixed list (e.g., "Pending/Active/Done") |
   | **Multi select** | Multiple options from a fixed list |
   | **Attachment** | File uploads (images, PDFs, etc.) |
   | **Email** | Email address |
   | **URL** | Web address |
   | **Link to another record** | Connect this record to a row in another table |

4. Click **Save Column**.

### Edit or rename a column

Double-click the column header to open the edit panel. Change the name or type,
then click **Save Column**.

### Delete a column

Right-click the column header -> **Delete Column**.

> **Caution:** Deleting a column deletes all the data in it permanently.

---

## 5. Entering Data

### Type data directly

Click any empty cell and start typing. Press **Tab** to move to the next column,
or **Enter** to move to the next row.

### Expand a row for more detail

Click the **expand** icon (the small arrows) at the left of any row to open a
full-screen form for that record. This is useful for filling in long text or
viewing attachments.

### Add a new row

- Click the **+** at the bottom of the table, or
- Press **Enter** when you are in the last row.

### Delete a row

Right-click the row number on the left -> **Delete Row**.

---

## 6. Filtering and Sorting Data

### Filter (show only rows that match a condition)

1. Click **Filter** in the toolbar above the table.
2. Click **+ Add filter**.
3. Choose the column, the condition (e.g., "is equal to", "contains", "is before"),
   and the value.
4. Add more filters if needed. Choose **AND** (all conditions must match) or **OR**
   (any condition can match).
5. To remove a filter, click the **x** next to it.

### Sort (order rows by a column)

1. Click **Sort** in the toolbar.
2. Click **+ Add Sort**.
3. Choose the column and direction (A → Z for ascending, Z → A for descending).

---

## 7. Importing Data from a CSV or Spreadsheet

If you already have data in a CSV file or Excel spreadsheet, you can import it
directly into a NocoDB table.

### Import into a new table

1. In your base, click **+** next to "Tables".
2. Choose **Import from file**.
3. Upload your CSV or Excel file.
4. NocoDB will preview the data and suggest column types.
5. Review and adjust column names and types, then click **Import**.

### Import into an existing table

1. Open the table you want to add data to.
2. Click the **...** menu (top right of the toolbar) -> **Import more records**.
3. Upload your CSV. NocoDB will try to match columns by name.

### Tips for a clean import

- Make sure the first row of your CSV contains column headers.
- Remove any merged cells or summary rows before importing from Excel.
- Date columns import best when formatted as `YYYY-MM-DD` (e.g., 2024-03-15).

---

## 8. Creating Views

A **view** is a saved way of looking at a table — with specific filters, sorts,
or hidden columns — without changing the underlying data.

You might create:
- A view showing only "active" experiments
- A gallery view for image-heavy data
- A view with only the columns relevant to a particular team member

### Create a view

1. On the left sidebar, below the table name, click **+ Add View**.
2. Choose the view type:
   - **Grid** — spreadsheet layout (default)
   - **Gallery** — card layout (good for image attachments)
   - **Form** — a clean form for entering one record at a time
   - **Kanban** — drag-and-drop board by category (requires a Single select column)
   - **Calendar** — calendar view (requires a Date column)
3. Give the view a name and click **Save**.

Each view has its own filters, sorts, and hidden columns. Switching between views
is instant.

### Share a view with a public link

1. In the view, click **Share** (top right).
2. Toggle **Share View** on.
3. Copy the link. Anyone with the link can see (but not edit) the data in that view —
   no NocoDB account required.

---

## 9. Linking Tables Together

NocoDB allows you to connect records across tables. For example:
- A "Samples" table linked to an "Experiments" table (each experiment uses one or more samples)
- A "Researchers" table linked to "Experiment Logs" (who ran each experiment)

### Create a link between tables

1. In the table you want to add the link to, click **+** to add a new column.
2. Choose field type **Link to another record**.
3. Under "Child table", choose the table to link to.
4. Click **Save Column**.

You'll now see a column where you can click to search and select a related record
from the other table. Both tables will show the connection.

---

# Part 2 — Apache Superset (Visualisation)

Superset is where you create charts and dashboards from the data stored in PostgreSQL.

---

## 10. Signing In to Superset

1. Open http://localhost:8088 (or your server's URL) in a browser.
2. Enter your credentials:
   - **Username:** the value of `SUPERSET_ADMIN_USER` from the `.env` file (default: `admin`)
   - **Password:** the value of `SUPERSET_ADMIN_PASSWORD` from the `.env` file
3. Click **Log in**.

You will land on the Superset home page, showing recent charts and dashboards.

---

## 11. Connecting to a Database

Before you can create any charts, you need to tell Superset where to find your data.
This is a one-time setup step per database.

1. Click **Settings** (gear icon, top right) -> **Database Connections**.
2. Click **+ Database** (top right).
3. From the list, select **PostgreSQL**.
4. Fill in the connection form:

   | Field | What to enter | Where this comes from |
   |---|---|---|
   | **Display Name** | `Lab PostgreSQL` | Any name you choose |
   | **Host** | `postgres` | The PostgreSQL service name in `docker-compose.yml`. Docker uses service names as internal hostnames — do NOT use `localhost` here |
   | **Port** | `5432` | Standard PostgreSQL port, defined in `docker-compose.yml` |
   | **Database name** | `nocodb` | Created automatically by `init-db.sql` on first start. This is where NocoDB writes all your data |
   | **Username** | *(your value)* | `POSTGRES_USER` in your `.env` file |
   | **Password** | *(your value)* | `POSTGRES_PASSWORD` in your `.env` file |

   Not sure what your username/password are? Run this in your terminal:
   ```bash
   cat .env
   ```

5. Click **Test Connection**. You should see "Connection looks good!"
6. Click **Connect**.

> **Why `postgres` as the hostname and not `localhost`?**
> Superset runs inside a Docker container. Inside that container, `localhost`
> means the container itself — not your Mac and not the PostgreSQL container.
> Docker gives each service its own hostname matching the service name in
> `docker-compose.yml`, so `postgres` is how Superset reaches the database
> over Docker's internal network.
>
> If you ever connect to PostgreSQL from *outside* Docker (e.g. from TablePlus
> on your Mac), use `localhost` and port `5432` instead.

---

## 12. Adding a Dataset (Table)

A **dataset** in Superset represents one table (or a saved SQL query) from your
database. You need to register a table as a dataset before you can chart it.

1. Click **Datasets** in the top menu.
2. Click **+ Dataset** (top right).
3. Choose:
   - **Database:** the connection you just created (e.g., `Lab PostgreSQL`)
   - **Schema:** `public` (the default PostgreSQL schema)
   - **Table:** select the table you want to visualise
4. Click **Create Dataset and Create Chart** (or just **Save** to register without
   immediately making a chart).

You can add more datasets from different tables the same way.

---

## 13. Creating a Chart

### Start from a dataset

1. Click **Charts** in the top menu.
2. Click **+ Chart** (top right).
3. Choose a **Dataset** from the list.
4. Choose a **Chart type** (see [Section 16](#16-common-chart-types-and-when-to-use-them)
   for guidance).
5. Click **Create new chart**.

### The chart editor

The chart editor has three main areas:

- **Left panel — Data:** Choose which columns to use (what goes on the X axis,
  what to count or sum, how to group the data).
- **Left panel — Customize:** Change colours, labels, font sizes, legend position, etc.
- **Centre — Chart preview:** Shows a live preview that updates when you click
  **Update chart**.

### Example: Bar chart counting samples per category

Suppose you have a "Samples" table with a "Status" column (e.g., "Collected",
"Processed", "Archived").

1. Create a new chart from the "Samples" dataset.
2. Choose **Bar Chart**.
3. In the Data panel:
   - **X Axis:** Status
   - **Metric:** Count (click the metric field -> choose **COUNT(*)**)
4. Click **Update chart** to see the preview.
5. Give the chart a title by clicking **[untitled chart]** at the top.
6. Click **Save** and choose a folder or dashboard.

### Save the chart

Click **Save** (top right) to open the save dialog:
- Enter a **chart name** (be descriptive — e.g., "Sample Status Breakdown 2024")
- Choose whether to add it to an existing dashboard or save it standalone

---

## 14. Creating a Dashboard

A **dashboard** is a page that holds multiple charts side by side. Use dashboards
to tell a story with your data or give an at-a-glance overview.

### Create a new dashboard

1. Click **Dashboards** in the top menu.
2. Click **+ Dashboard** (top right).
3. A blank dashboard opens in edit mode.

### Add charts to the dashboard

1. On the right side, click the **Charts** tab in the panel.
2. Drag any chart from the list onto the canvas in the centre.
3. Resize charts by dragging their bottom-right corner.
4. Rearrange by dragging chart headers.

### Add text, dividers, and headers

In the right panel, under **Layout elements**, you can drag:
- **Header** — a large text title
- **Divider** — a horizontal line to separate sections
- **Markdown** — formatted text, useful for adding notes or context

### Save and publish

1. Click **Save** (top right) to save the current layout.
2. The dashboard is now accessible to anyone with a Superset account.
3. To share with someone who doesn't have an account, see **Share -> Share dashboard**
   for a public link option (if enabled by the admin).

---

## 15. Editing and Refreshing Dashboards

### Edit an existing dashboard

1. Open the dashboard.
2. Click **Edit dashboard** (pencil icon, top right).
3. Drag, resize, or delete charts, add new ones, or rearrange.
4. Click **Save** when done.

### Refresh chart data

Charts show data as of the last time they were loaded. To see the latest data:

- **Refresh one chart:** Hover over the chart -> three dots menu -> **Refresh chart**
- **Refresh all charts on the dashboard:** Click the three dots at the top of the
  dashboard -> **Refresh dashboard**

### Set auto-refresh (for live monitoring)

1. Open the dashboard.
2. Click the three dots at the top -> **Set auto refresh interval**.
3. Choose a refresh rate (e.g., every 10 minutes, every hour).

---

## 16. Common Chart Types and When to Use Them

| Chart Type | Best for | Example use |
|---|---|---|
| **Bar Chart** | Comparing counts or values across categories | Samples by status, experiments per month |
| **Line Chart** | Showing trends over time | Temperature readings over days, weekly counts |
| **Pie / Donut Chart** | Showing proportions of a whole | Percentage of samples in each category |
| **Scatter Plot** | Showing relationship between two measurements | Comparing two variables (e.g., dose vs. response) |
| **Table** | Displaying raw data with sorting and filtering | Top 20 most recent experiments |
| **Big Number** | Single key metric at a glance | Total samples collected, active experiments count |
| **Big Number with Trend** | Key metric + whether it's going up or down | Samples this week vs. last week |
| **Heatmap** | Showing intensity across two dimensions | Activity by day of week and hour |
| **Box Plot** | Showing data distribution and outliers | Range and median of measurement results |
| **Histogram** | Showing how values are distributed | Distribution of reaction times or weights |

### Tips for choosing chart types

- Use **bar charts** when you have categories (text labels) on one axis.
- Use **line charts** when one axis is a date or time and you want to show change.
- Use **pie charts sparingly** — they are hard to read with more than 5 slices.
  A bar chart usually communicates the same information more clearly.
- Use **tables** when exact numbers matter more than visual comparison.
- Use **Big Number** for the most important single metric on a dashboard.

---

## Quick Reference

### NocoDB keyboard shortcuts

| Key | Action |
|---|---|
| `Tab` | Move to next cell |
| `Enter` | Confirm edit / move to row below |
| `Escape` | Cancel edit |
| `Ctrl+Z` / `Cmd+Z` | Undo |
| `Ctrl+F` / `Cmd+F` | Search in table |
| Click + Shift+Click | Select multiple rows |

### Superset common actions

| Action | Where to find it |
|---|---|
| Add a database connection | Settings -> Database Connections |
| Register a table as a dataset | Datasets -> + Dataset |
| Create a new chart | Charts -> + Chart |
| Create a new dashboard | Dashboards -> + Dashboard |
| Refresh a chart | Hover chart -> ... -> Refresh chart |
| Download chart as image | Hover chart -> ... -> Download |
| Share a dashboard | Three dots at top of dashboard -> Share |

---

## Getting Help

- **NocoDB documentation:** https://docs.nocodb.com
- **Apache Superset documentation:** https://superset.apache.org/docs/
- **For stack issues (Docker, setup, connectivity):** contact whoever manages this
  server, or refer to the `README.md` troubleshooting section.
