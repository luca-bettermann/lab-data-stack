# NocoDB & Superset — How-To Reference

Assumes the stack is running. For setup, see `README.md`.

---

## NocoDB

### Migrating existing data

NocoDB has no SQLite→PostgreSQL migration tool. Recommended approach:

1. Export each table from old NocoDB: table → **…** → **Download → CSV**
2. Start new stack (old `~/nocodb/noco.db` is untouched)
3. Sign up at http://localhost:8080 (first user = admin)
4. Import CSVs: **+ New Table → Import from file → CSV**

Linked/relational fields must be re-created manually after import.

---

### Table names in PostgreSQL

NocoDB stores user tables with a hashed prefix, e.g.:

```
nc_b7d6___Experiments
nc_b7d6___Samples
```

Find exact names in psql:
```bash
docker exec lab_postgres psql -U labuser -d nocodb -c "\dt"
```

---

### Column types reference

| Type | Use for |
|---|---|
| Single line text | IDs, short strings |
| Long text | Notes, free text |
| Number / Decimal | Counts, measurements |
| Date / DateTime | Calendar dates, timestamps |
| Checkbox | Boolean flags |
| Single / Multi select | Fixed-option categories |
| Link to another record | Foreign-key style relations |
| Attachment | File uploads |
| Formula | Computed values (app-layer only — not in PostgreSQL) |

---

### Views

Views save a filtered/sorted/column-hidden perspective on a table without copying data.
Types: **Grid** (default), **Gallery** (image cards), **Form** (single-record entry), **Kanban** (requires Single select), **Calendar** (requires Date).

Share a read-only public link: view → **Share** → toggle on → copy URL.

---

## Superset

### Connecting to PostgreSQL

Settings → Database Connections → + Database → PostgreSQL:

| Field | Value | Source |
|---|---|---|
| Host | `postgres` | Docker service name |
| Port | `5432` | `docker-compose.yml` |
| Database | `nocodb` | `init-db.sql` |
| Username | your value | `POSTGRES_USER` in `.env` |
| Password | your value | `POSTGRES_PASSWORD` in `.env` |

---

### Adding a dataset

Datasets → + Dataset → select database / schema `public` / table → Save.

NocoDB tables appear with their hashed names (e.g. `nc_b7d6___Experiments`). Add one dataset per table you want to chart.

---

### Multi-table queries (virtual datasets)

Superset datasets map to a single table. To JOIN across tables, use a virtual dataset:

SQL Lab → write query → **Save → Save as dataset**:

```sql
SELECT
    e.id,
    e.date,
    e.grams_in,
    s.name AS sample_name,
    e.grams_in / NULLIF(e.rounds, 0) AS grams_per_round
FROM nc_b7d6___Experiments e
JOIN nc_b7d6___Samples s ON s.id = e.sample_id;
```

The saved dataset appears in the Datasets list and can be charted normally.

---

### Formula fields caveat

NocoDB Formula / Lookup / Rollup columns are computed by the NocoDB application layer. They are **not stored in PostgreSQL** and are **invisible to Superset**.

Equivalent SQL to use in virtual datasets instead:

| NocoDB formula | SQL equivalent |
|---|---|
| `{grams_in} / {rounds}` | `grams_in / NULLIF(rounds, 0)` |
| `CONCATENATE({a}, ' ', {b})` | `a \|\| ' ' \|\| b` |
| Rollup SUM on linked table | `JOIN … GROUP BY … SUM(…)` |

---

### Metric aggregation

In the chart editor, **Metrics** must use an aggregate function (SUM, AVG, COUNT, etc.) whenever **Dimensions** (GROUP BY) are present. You cannot drop a raw column as a metric alongside a dimension.

Rename a metric: click the metric pill → pencil icon → set label.

---

### Dashboard export / import

**Export:** Dashboards → select dashboard → **…** → **Export** → saves a `.zip`.

**Import:** Dashboards → **Import** (top right) → upload `.zip`.

The zip includes chart definitions and dataset metadata but not the underlying data or database connection credentials — you must reconnect the database on the target instance.

---

## Quick Reference

### NocoDB shortcuts

| Key | Action |
|---|---|
| `Tab` | Next cell |
| `Enter` | Confirm / next row |
| `Escape` | Cancel edit |
| `Cmd+Z` | Undo |
| `Cmd+F` | Search |

### Superset actions

| Action | Path |
|---|---|
| Add database | Settings → Database Connections → + Database |
| Add dataset | Datasets → + Dataset |
| New chart | Charts → + Chart |
| New dashboard | Dashboards → + Dashboard |
| Refresh chart | Hover chart → … → Refresh |
| Download chart image | Hover chart → … → Download |
| Export dashboard | Dashboards → select → … → Export |

---

## External docs

- NocoDB: https://docs.nocodb.com
- Superset: https://superset.apache.org/docs/
