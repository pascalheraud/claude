---
name: testcontainers
description: Generic Testcontainers conventions — running real dependencies (databases, queues, ...) in Docker containers for integration tests, container lifecycle scope, and the transaction-rollback isolation pattern. Language-agnostic; see the language-specific skill (e.g. languages/python/tooling/testcontainers) for concrete APIs.
---

# Testcontainers — generic conventions

## Why

Prefer a real instance of the dependency (Postgres, Kafka, Redis, ...) running in a Docker container over an in-memory fake (e.g. SQLite standing in for Postgres) for integration tests. A fake diverges from production behavior in ways that matter — dialect-specific SQL, constraint enforcement, types, transaction semantics — and those gaps show up as bugs the tests didn't catch. A real container closes that gap at the cost of a slower test run, which is worth it for anything beyond the most trivial persistence logic.

Only fall back to a fake in-memory dependency when the tests genuinely don't exercise dependency-specific behavior, or when the container can't be provisioned in the test environment at all.

## Container lifecycle: start once, isolate per test

Starting a fresh container per test is correct but slow (container startup dominates the run). The standard pattern is:

1. **Session-scoped container** — start the container once for the whole test run (or test module), not per test.
2. **Per-test isolation without restarting the container** — reset state between tests without paying the container-startup cost again. Two common strategies:
   - **Transaction rollback** (preferred when the driver/ORM supports it): wrap each test in a transaction (or a savepoint nested inside an outer transaction) and roll it back at the end — the schema and any session-scoped setup persist, only the test's data changes disappear.
   - **Schema/database reset**: truncate tables or recreate the schema between tests when transactional isolation isn't practical (e.g. the code under test manages its own commits/rollbacks and a savepoint would be committed away).

Don't create a new container per test method — that's the anti-pattern this skill exists to avoid.

## What this replaces

An in-memory fake database (e.g. SQLite for a Postgres-backed app) used purely for test speed/simplicity. If the project's persistence layer targets a specific database, integration tests for that layer should run against that database via Testcontainers, not a different engine that merely resembles it.

## Setup requirements

- A **Docker daemon** must be reachable from wherever tests run (local dev machine, CI runner) — Testcontainers talks to it via the Docker socket (or a configured `DOCKER_HOST`) to pull the image and start/stop containers. No Docker available means these tests cannot run at all; that's a hard requirement, not a fallback-to-fake situation.
- The user/CI runner needs permission to use Docker (in the `docker` group locally, or an equivalent in CI — most hosted CI providers already have Docker-in-Docker or a Docker socket available for this).
- First run pulls the container image (e.g. `postgres:16-alpine`) — expect a one-time delay; pin the image tag for reproducibility, same as any other Docker usage (see [[docker]]).
- In CI, budget for container startup time in the job timeout, and prefer image tags already cached on the runner when possible to keep the pipeline fast.

## Language-specific implementation

- Python: [[testcontainers]] (`languages/python/tooling/testcontainers`) — `testcontainers-python`, pytest fixtures, SQLAlchemy transaction-rollback pattern.
