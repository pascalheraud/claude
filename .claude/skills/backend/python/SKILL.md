---
name: python
description: Python backend conventions independent from the concrete framework stack — layering, DI, persistence boundaries. The language/tooling baseline lives in [[languages/python]], the stack itself in the app skill.
---

# Python backend conventions

Load [[api]] and [[languages/python]] first. This skill only adds the backend-domain-specific half of Python conventions — it does not repeat language or tooling rules already covered by `languages/python`.

## Technology references

- Keep validation models and API contracts aligned with the concrete framework selected by the application.
- Keep persistence boundaries explicit and aligned with the selected storage layer of the application.
- Do not restate the application-level technology choices in this Python skill.

## Python-specific responsibilities

- Keep the HTTP layer thin: request parsing and response shaping remain at the framework's route/handler boundary.
- Keep business logic in services or use cases, not in route handlers.
- Use dependency injection for services, repositories, and session configuration.
- Keep database access behind repository or adapter abstractions, following [[backend/generic/db]] for the data-integrity rules themselves.
- Keep ORM models, repository adapters, and domain logic separate enough to avoid leaking persistence concerns into the business layer.

## Framework-agnostic Python API patterns

- Define clear request and response models for API contracts.
- Validate inputs at schema boundaries rather than ad hoc dict validation in handlers.
- Use dependency injection for DB sessions, auth context, and service wiring.
- Prefer explicit status codes and structured error handling as defined in [[api]].

## Logging

- Every HTTP request is logged, including its parameters — query-string/GET parameters and path parameters — not just the method and path. A route hit with no visibility into which resource/filter was requested is not useful for debugging.
- The concrete mechanism (framework middleware, WSGI/ASGI wrapper, access-log config) is framework-specific — see the stack skill (e.g. [[fastapi]]) for how it's actually wired, and [[api]]'s "Logging" section for the request-correlation convention this ties into.

### Request-id / correlation libraries

Per [[api]]'s request-correlation convention (one id persisting across HTTP + SQL + application logs), a Python backend doesn't need to hand-roll this — pick a library rather than reimplementing a `contextvars`-based id-and-log-filter mechanism from scratch:

- **ASGI stacks (FastAPI/Starlette)**: [[asgi-correlation-id]] — a middleware that generates/reads the id and injects it into every log line via a `logging.Filter`, including SQLAlchemy's query log. The default choice for a FastAPI backend.
- **WSGI stacks (Flask/Django)**: no single default equivalent — the same `contextvars` + `logging.Filter` pattern `asgi-correlation-id` uses applies, but via a WSGI middleware instead of an ASGI one (e.g. Django's own `request.id`-style middleware patterns, or a hand-wired `threading.local`-based filter for Flask). Document the concrete choice in the project skill once one is made — don't leave this generic skill deciding it.

## Project-specific usage

A project skill using this backend Python convention should define only the application-specific structure and integration points that are not generic to Python itself, such as:

- the concrete application layout for that project,
- the repository/service boundaries for that codebase,
- the database integration contract for that project,
- the project-specific validation and packaging workflow.
