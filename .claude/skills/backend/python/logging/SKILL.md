---
name: python-logging
description: Patterns for encapsulating start/end logging of Python backend service calls — decorator, auto-wrapping base class, and DI/AOP interception, with tradeoffs. The concrete choice is a project architecture decision, documented per-project, not mandated here.
---

# Python service-call logging patterns

Implements [[api]]'s "service-level start/end" logging convention (every service-layer call logs an `INFO` line on start and on end) for Python specifically: how to apply that without hand-writing a log line in every service method.

**This skill lists the options and their tradeoffs — it does not pick one.** The concrete choice (which pattern, which library if any) is a project architecture decision, made once and documented in the project's own skill alongside the other stack choices (see [[backend/python]], [[fastapi]]).

## Option 1 — Explicit decorator

```python
import functools
import logging
import time

logger = logging.getLogger("app.services")

def logged(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        logger.info("→ %s", func.__qualname__)
        start = time.monotonic()
        try:
            return func(*args, **kwargs)
        finally:
            logger.info("← %s (%.1fms)", func.__qualname__, (time.monotonic() - start) * 1000)
    return wrapper

class MessageService:
    @logged
    def post(self, message_uuid: uuid.UUID, content: str) -> Message:
        ...
```

For an `async def` service method, write (or generate) an async variant of the wrapper — `functools.wraps` plus an `async def wrapper(...)` that `await`s `func(...)` instead of calling it directly; a single decorator can dispatch to either based on `inspect.iscoroutinefunction(func)` if both sync and async services exist in the same codebase.

- **Pros**: explicit at the call site — reading the method, you see it's logged. Works identically whether the class is otherwise plain. Easy to reason about and to debug (a normal function wrapping another).
- **Cons**: must be applied to every method that should log, by hand — a new service method logs nothing until someone remembers to add `@logged`. Nothing enforces the convention beyond code review.

## Option 2 — Auto-wrapping base class

```python
import inspect

class Service:
    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        for name, attr in vars(cls).items():
            if callable(attr) and not name.startswith("_"):
                setattr(cls, name, _wrap_logged(attr))

class MessageService(Service):
    def post(self, ...): ...  # logged automatically, no decorator needed
```

- **Pros**: zero boilerplate per method; impossible to forget once the class inherits from the base.
- **Cons**: implicit — nothing at the call site signals that logging happens; every public method is wrapped indiscriminately (including ones that shouldn't be, e.g. simple getters), unless the base class also grows an opt-out mechanism; wrapping via introspection can complicate stack traces and interacts awkwardly with `async def` methods (need to detect and wrap coroutines differently) and with any framework that introspects the original method's signature (rare for a plain service class, but worth checking).

## Option 3 — DI-container / AOP interception

If services are resolved through a real dependency-injection container (not the case with FastAPI's plain `Depends`, but relevant if a project adopts one), the container's proxy/interceptor mechanism can wrap every service call at resolution time instead of at class-definition time.

- **Pros**: fully centralized — the service classes themselves stay completely plain, with no decorator or base class at all.
- **Cons**: only applicable if the project already has (or is willing to adopt) a DI container with interception support; overkill for a project using plain constructor injection.

## Choosing

- Option 1 (explicit decorator) is the right default for a small-to-medium codebase without a DI container: it's the least magical, and the "must remember to add it" cost is manageable with a handful of services and a code-review habit.
- Option 2 earns its implicitness once the number of services grows large enough that forgetting the decorator becomes a real, recurring problem.
- Option 3 only makes sense if the DI container is already there for other reasons.

## Project-specific usage

A project skill using one of these patterns should document:
- Which option was chosen, and why.
- Where the decorator/base class/interceptor lives in the codebase.
- The exact log format (what's logged on start vs end — method name, key parameters, duration, outcome).
