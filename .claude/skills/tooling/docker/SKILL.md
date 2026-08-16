---
name: docker
description: Generic Docker and Docker Compose conventions — compose file format, common pitfalls (obsolete `version` key), volumes, healthchecks. Load when writing or editing a Dockerfile or docker-compose.yml.
---

# Docker — Skill

## Compose file: no top-level `version` key

Modern Docker Compose (v2, the `docker compose` CLI) determines the schema automatically and ignores the top-level `version:` key. Do not add it to new `docker-compose.yml` files, and remove it when touching an existing one:

```yaml
# ❌ obsolete — triggers: "the attribute `version` is obsolete, it will be ignored"
version: "3.9"

services:
  ...
```

```yaml
# ✅ no version key needed
services:
  ...
```

## Dev database services

- Persist data in a named volume, not a bind mount, unless the host path is genuinely needed (e.g. seed files).
- Set credentials via environment variables with sane defaults (`${VAR:-default}`), so the compose file works out of the box but stays overridable.
- Add a `healthcheck` for services other containers or scripts wait on (e.g. `pg_isready` for Postgres), so dependents can use `depends_on: condition: service_healthy` instead of a fixed sleep.

## General

- Pin image tags to a specific version (e.g. `postgres:16-alpine`), never `latest`, so local environments stay reproducible.
- Keep one `docker-compose.yml` per concern/module (e.g. a dev-database compose file separate from an app compose file) rather than one large file mixing unrelated services, unless the project is small enough that splitting adds more friction than clarity.
