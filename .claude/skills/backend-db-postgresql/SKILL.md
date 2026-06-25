---
name: backend-db-postgresql
description: PostgreSQL schema conventions — naming, foreign keys, default values, test schema patterns with Testcontainers
---

# PostgreSQL Conventions

## Naming

- Table and column names: **snake_case**
- Java ↔ SQL mapping follows camelCase ↔ snake_case

## Foreign keys

- **No `ON DELETE CASCADE`** — cascading deletes are handled explicitly in application code or stored procedures, not by FK constraints
- FK columns follow the pattern `<table>_id bigint NOT NULL REFERENCES <schema>.<table>(id)`

## Default values

- Column default values **are not defined in the SQL schema** (no `DEFAULT` in DDL).
- The default value is applied by the application layer before insertion.
- A mandatory column with a default value must always be explicitly provided at insert time — never omitted or left to the database.
- Exception: technical columns managed by the database itself (`external_id uuid DEFAULT gen_random_uuid()`, `sent_date DEFAULT now()`, etc.) keep their `DEFAULT` because they are not exposed to the application layer.

## Test schema

The test schema is a flat `CREATE TABLE` file (no migration changesets) applied via Testcontainers for repository integration tests.

### Common simplifications vs. production schema

- Generated columns become plain columns with a simple `DEFAULT` (e.g. `boolean DEFAULT true`) — avoids needing to set all trigger conditions in tests
- Non-mandatory columns can be made nullable (drop `NOT NULL`) so tests only set what they need
- Infrequently tested tables can be omitted — only include tables needed by existing repository tests

### Keeping the test schema in sync

When a migration adds or removes a column used in repository tests, update the test schema file to match. Follow the same **no DEFAULT** convention as the production schema (except `boolean` flags which may use `DEFAULT false` for convenience).
