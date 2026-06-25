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
