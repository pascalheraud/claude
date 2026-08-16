---
name: sqlalchemy
description: SQLAlchemy-specific backend conventions — ORM/persistence boundaries, session handling, and SQL query logging. Builds on the generic Python-backend skill.
---

# SQLAlchemy Conventions

Builds on [[backend/python]] (persistence-boundary rules) and [[api]] (the generic backend conventions). This skill only adds what's specific to SQLAlchemy.

## Query logging

- SQL query logging is enabled — every statement SQLAlchemy executes (and its bound parameters) is visible in the logs. A silent ORM layer makes it impossible to tell what a request actually did to the database from the logs alone.
- Preferred mechanism: configure the standard `sqlalchemy.engine` Python logger, rather than the `echo=True` engine flag — this lets the log level be toggled via the app's normal logging configuration (env var, per-environment config) instead of being baked into `create_engine(...)`:

```python
import logging

logging.getLogger("sqlalchemy.engine").setLevel(logging.INFO)
```

- `echo=True` on `create_engine()` is acceptable for a quick local check, but shouldn't be how it's left wired in the codebase — it can't be toggled without a code change, and it's a separate on/off switch from the rest of the app's logging config.
- SQL parameter logging includes literal bound values. Before enabling this beyond local development, check whether any bound value could be sensitive (credentials, tokens, free-text user content) — see [[api]]'s "Logging" section for the general caution on this.
- Where the project has a request-correlation id (see [[api]]), SQL log lines should carry it too, so a slow/unexpected query can be traced back to the HTTP request that triggered it — the exact wiring depends on the logging setup (e.g. a `logging.Filter`/`contextvars`-based injector), not something SQLAlchemy provides on its own.

## Project-specific usage

A project skill using this convention should document:
- The concrete session-per-request pattern used (see the stack skill, e.g. [[fastapi]]'s "Database session").
- Whether query logging is on by default in dev and how it's toggled per environment.
