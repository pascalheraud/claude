---
name: backend-db-liquibase
description: Liquibase migration conventions — SQL format, changeset rules, adding NOT NULL columns to existing tables
---

# Liquibase Conventions (SQL format)

## General rules

- All migrations are **append-only** changesets in a root changelog file
- Format: `--changeset liquibase:<N>`
- Multi-statement changesets (functions, etc.): add `splitStatements:false`
- **Never modify an existing changeset** — always add a new one

## Adding a NOT NULL column to an existing table

When adding a `NOT NULL` column to a table that already has rows, and no `DEFAULT` should remain in the schema, use a 3-step migration in **a single changeset**:

```sql
--changeset liquibase:N
ALTER TABLE <schema>.<table> ADD COLUMN <col> <type>;
UPDATE <schema>.<table> SET <col> = <value> WHERE <col> IS NULL;
ALTER TABLE <schema>.<table> ALTER COLUMN <col> SET NOT NULL;
```

This avoids `null value in column violates not-null constraint` on existing rows while keeping no `DEFAULT` in the DDL.

### Adding several NOT NULL columns at once

Same 3 steps, but repeated **per column** — never one shared `UPDATE ... SET col1 = v1, col2 = v2, ... WHERE col1 IS NULL`. A single shared `WHERE` only guards `col1`: any row where `col1` is already `NULL` but `col2`/`col3`/... already hold real values (e.g. a partial backfill re-run, or columns added incrementally in an earlier, separately-applied changeset) gets those columns silently overwritten with the default. Each column needs its own guard so it only ever fills rows where *that* column is still unset:

```sql
--changeset liquibase:N
ALTER TABLE <schema>.<table> ADD COLUMN col1 <type>;
ALTER TABLE <schema>.<table> ADD COLUMN col2 <type>;

UPDATE <schema>.<table> SET col1 = <v1> WHERE col1 IS NULL;
UPDATE <schema>.<table> SET col2 = <v2> WHERE col2 IS NULL;

ALTER TABLE <schema>.<table> ALTER COLUMN col1 SET NOT NULL;
ALTER TABLE <schema>.<table> ALTER COLUMN col2 SET NOT NULL;
```
