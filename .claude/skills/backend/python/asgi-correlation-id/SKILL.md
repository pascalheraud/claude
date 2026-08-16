---
name: asgi-correlation-id
description: Request correlation IDs for ASGI apps (FastAPI/Starlette) via the asgi-correlation-id middleware — generates/propagates a request id and injects it into every log line for that request, including SQLAlchemy's. Load when wiring up request correlation/tracing in a Python ASGI backend.
---

# asgi-correlation-id — Request correlation

Implements [[api]]'s "request correlation" convention (a request id that persists across HTTP + SQL + application logs) for an ASGI app (FastAPI/Starlette). See [[fastapi]] for the middleware-based HTTP request-logging convention this integrates with, and [[sqlalchemy]] for the SQL-side logging it correlates.

## What it does

- Generates a unique id per incoming request (or reads one from an inbound header, e.g. `X-Request-ID`, if the caller/gateway already set one).
- Stores it in a `contextvars.ContextVar`, so it's implicitly available to any code running within that request — no need to thread it through every function call manually.
- Injects it into the standard Python `logging` output via a `logging.Filter`, so **every** log line emitted while handling that request carries the same id automatically — the HTTP access log line, SQLAlchemy's query log, and any application log call — without changing those call sites.
- Optionally echoes the id back in the response headers, so a client/gateway can correlate its own logs with the backend's.

## Setup

```python
from asgi_correlation_id import CorrelationIdMiddleware
from asgi_correlation_id.context import correlation_id

app.add_middleware(CorrelationIdMiddleware)
```

Wire the filter into the logging config so the id actually appears in formatted output:

```python
import logging
from asgi_correlation_id import CorrelationIdFilter

handler = logging.StreamHandler()
handler.addFilter(CorrelationIdFilter(uuid_length=8))
handler.setFormatter(logging.Formatter("%(levelname)s [%(correlation_id)s] %(name)s: %(message)s"))
logging.getLogger().addHandler(handler)
```

- Add the same filter/formatter to any other logger that needs the id (e.g. `sqlalchemy.engine`, per [[sqlalchemy]]'s query-logging section) — the `ContextVar` is process-global, so any logger picks up the current request's id once the filter is attached to its handler.
- `CorrelationIdMiddleware` must be the **outermost** middleware (added last, so it runs first) that anything logging-related depends on, so the id is set before any other middleware or route code logs.

## Reading the id in application code

```python
from asgi_correlation_id.context import correlation_id

def some_service_function() -> None:
    logger.info("doing work", extra={"request_id": correlation_id.get()})
```

Rarely needed directly — the logging filter already injects it into every log record. Read it explicitly only when the id itself needs to be part of a non-log payload (e.g. returned in an error response body for support correlation).

## Project-specific usage

A project skill using this convention should document:
- Whether the id is trusted from an inbound header (behind a trusted gateway) or always generated fresh at the edge.
- The exact log format string and which loggers (app, `sqlalchemy.engine`, uvicorn access log) have the filter attached.
