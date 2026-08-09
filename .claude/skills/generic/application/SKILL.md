---
name: application
description: Generic application development conventions — feature documentation (spec + plan), code/spec sync rules, post-implementation verification, and status-file tracking for long-running plans. Load this skill whenever the user says to "continue", "resume", "carry on with", or "implement" a plan or a feature (e.g. "continue ce plan", "implémente cette feature", "reprends le développement de X") — before doing any exploration of the code or plan file.
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

## Rule: a plan must not leave open decisions

Everything must be settled during the planning phase. Before presenting a plan as ready, resolve every
technical decision it depends on — do not leave a "to be decided during implementation" list, a TBD
cron value, an unresolved architectural choice, or a "confirm this still holds" placeholder. If a
decision requires information you don't have (checking existing code, an external API's behavior, a
user preference), go get that information — read the code, search, or ask the user — before finalizing
the plan, rather than deferring it. Only genuinely implementation-time discoveries (e.g. "this fails at
runtime for an unforeseen reason") are acceptable to handle later, and even those get recorded in the
plan's `## Log` once resolved, not left as a pre-existing open item.

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

## Rule: track progress for long-running implementations

When the user asks to continue, resume, or implement a plan or feature, check first — before exploring the code — whether a status file already exists next to the plan/spec (`<plan-name>-status.md`). If it exists, read it first instead of re-deriving progress from the code. If it doesn't exist yet and the plan spans multiple sessions or sprints, create one.

When implementing a feature from a plan that spans multiple sessions or sprints (a plan with several phases/sprints, or any work too large to finish in one sitting), maintain a status file next to the plan: `<plan-name>-status.md` (e.g. `travelingo-plan-phase1-status.md` next to `travelingo-plan-phase1.md`).

The status file tracks, per sprint/phase/component:
- What's done
- What's stubbed, mocked, or explicitly deferred (and why)
- What's not started
- Open decisions that block resuming the work

Update it at the end of each work session that makes meaningful progress on the plan — not after every small edit. When resuming work on a long-running plan, read the status file first instead of re-deriving progress from the code or re-deciding settled questions.
