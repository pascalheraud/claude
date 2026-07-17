---
name: backend-db
description: Generic database design conventions — data integrity independent of any specific DBMS
---

# Database Conventions

## Conditional constraints

**Golden rule: the database can never be in an inconsistent state**, even if application code has a bug.

- If a column is nullable only under certain conditions (e.g. mandatory when another column has a given value, forbidden otherwise), enforce it with a `CHECK` constraint in the DDL — never rely solely on application code to guarantee it.
- Same applies to forbidden/invalid value combinations across columns.
- Apply this in both the production schema and the test schema, so integration tests catch violations too.

## creation_date

- Every table has a `creation_date` column, `NOT NULL`, defaulting to `now()`.
- Depending on the backend's mode of operation, this default can be set either by the database default value itself, or by a backend mechanism that sets it explicitly at insert time — pick whichever matches the project's existing convention for default values (e.g. see [[backend-db-postgresql]] for the "no DEFAULT in DDL, applied by the application layer" convention).

## Entity scope

- A database entity must only contain data tied to the database: columns, or objects/lists of objects reachable through relations.
- No computed values on an entity. A field derived from other data (aggregation, business rule, "is there a pending X") does not belong there, even if it's convenient to expose alongside the entity's real data.
- To "augment" an entity with non-persisted data (e.g. a value computed by a controller/service for a specific response), prefer composition over inheritance: wrap or pair the entity with the extra data in a separate class, rather than adding a field to the entity itself.
