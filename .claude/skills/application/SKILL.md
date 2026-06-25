---
name: application
description: Generic application development conventions — feature documentation (spec + plan), code/spec sync rules, post-implementation verification
---

# Application Development Conventions

## Feature documentation

Each feature is documented in a dedicated folder with two files:

- **spec** — functional specification: what and why, no code. Describes expected behavior, data model, and constraints.
- **plan** — implementation plan: how. Describes architecture decisions, package layout, entity fields, API routes, payload shapes.

## Rule: spec, plan and code must stay in sync

Any code modification must update or complete the related spec(s) and plan(s):

- Adding a feature → write or complete the spec before or alongside the code
- Changing behavior → update the spec to reflect the new behavior
- If code and spec diverge, fix the spec

## Rule: verify alignment after backend implementation

After implementing or modifying backend code for a feature, always cross-check:

1. **Spec** — does the implemented behavior match the functional requirements?
2. **Plan** — does the code match package layout, entity fields, repository method signatures, controller routes, payload shapes, and validation rules described in the plan? Update the plan if the implementation differs for a good reason.
3. **Skill files** — do the relevant skills reflect any new conventions or patterns introduced?

Typical divergences to look for:
- Missing classes in package layout
- Undocumented repository methods
- Controller routes, HTTP methods, or response shapes that differ from the plan
- New architectural patterns not yet captured in a skill

## Rule: batch transactions and external resources

In a long-running batch that accesses both the database and external resources (HTTP, email, file system, etc.), never include external resource access inside a database transaction. Use explicit, short transactions and keep external calls outside of them.

Choose the transaction strategy based on whether partial results are acceptable:

| Situation | Strategy |
|---|---|
| Partial results acceptable (e.g. sending N out of M emails) | One transaction per element (N transactions total) |
| All-or-nothing (e.g. atomic data migration) | One transaction for all elements |

**The 2-phase pattern per element** (when partial results are acceptable):

1. **Transaction A** — pre-flight DB update (e.g. mark item as `IN_PROGRESS`) → commit
2. **Outside any transaction** — call the external resource (send email, HTTP call, etc.)
3. **Transaction B** — result DB update (e.g. mark as `DONE` or `ERROR`) → commit

Move the `@Transactional` DB methods into a `@Service` bean so the batch can call them without wrapping everything in a single transaction. The batch orchestrates; the service owns the transaction boundaries.

## Rule: run tests after development

After completing backend or frontend development, ask the user whether they want to run the tests before declaring the work done. Do not run tests automatically without asking first.
