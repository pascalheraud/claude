---
name: db
description: Generic database design conventions — data integrity independent of any specific DBMS
---

# Database Conventions

## Conditional constraints

**Golden rule: the database can never be in an inconsistent state**, even if application code has a bug.

- Any functional state that is not a valid state of the domain must be unrepresentable in the DB — enforce it with a `CHECK` constraint in the DDL, never rely solely on application code to guarantee it.
- If a column is nullable only under certain conditions (e.g. mandatory when another column has a given value, forbidden otherwise), enforce it with a `CHECK` constraint.
- Same applies to any combination of column values that would be invalid or incoherent together, even when every column involved is individually valid on its own (e.g. an `ENUM` column set to `TOTAL` requires a paired `count` column to be `> 4`). Express the rule as a `CHECK` constraint, not just as validation in application code.
- When implementing or reviewing a table, enumerate the functionally impossible states explicitly and check each one is covered by a constraint, not just the ones that came up naturally while writing the DDL.
- This also applies to every migration that changes an existing table, not just table creation: adding a column, adding a new `ENUM` value, or changing a column's nullability can each introduce new invalid combinations. Re-check existing `CHECK` constraints still cover every impossible state after the change, and add/extend constraints as needed in the same migration.
- Apply this in both the production schema and the test schema, so integration tests catch violations too.

## creation_date

- Every table has a `creation_date` column, `NOT NULL`, defaulting to `now()`.
- Depending on the backend's mode of operation, this default can be set either by the database default value itself, or by a backend mechanism that sets it explicitly at insert time — pick whichever matches the project's existing convention for default values (e.g. see [[postgresql]] for the "no DEFAULT in DDL, applied by the application layer" convention).

## Naming

- Tables are named in the singular, like a class name: `contract`, not `contracts`; `client`, not `clients`.
- Join tables are named using both related table names, singular, separated by an underscore. In a 1→N relation, the "1" side comes first: a client has N contracts, so the join table is `client_contract`.
- Prefer scoping tables in a schema/namespace (when the DBMS supports it) over prefixing table names: `myapp.contract` and `myapp.client`, not `myapp_contract` or `myapp_client`.

## Entity scope

- A database entity must only contain data tied to the database: columns, or objects/lists of objects reachable through relations.
- No computed values on an entity. A field derived from other data (aggregation, business rule, "is there a pending X") does not belong there, even if it's convenient to expose alongside the entity's real data.
- To "augment" an entity with non-persisted data (e.g. a value computed by a controller/service for a specific response), prefer composition over inheritance: wrap or pair the entity with the extra data in a separate class, rather than adding a field to the entity itself.
