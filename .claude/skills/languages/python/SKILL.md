---
name: python
description: Python language conventions independent from any framework or tooling choice — explicit typing, module structure.
---

# Python conventions

## Version-specific features

Headline additions by version — the concrete version used by a project is a project-level choice; see the dedicated version skill for its specifics (e.g. [[python-3.11]]).

- **3.9** — dict merge operators (`|`, `|=`), `list`/`dict` generics without importing from `typing` (PEP 585).
- **3.10** — structural pattern matching (`match`/`case`), parenthesized context managers, `X | Y` union syntax in annotations.
- **3.11** — exception groups and `except*` (PEP 654), `asyncio.TaskGroup`, `tomllib` in the standard library, `typing.Self`/`LiteralString`, per-expression traceback locations.
- **3.12** — type parameter syntax for generics (PEP 695: `def f[T](x: T) -> T`), `type` statement for type aliases, f-string grammar relaxation (nested quotes, multiline expressions).
- **3.13** — experimental free-threaded build (no-GIL), experimental JIT, improved interactive REPL.

## Typing and clarity

- Prefer explicit type hints on function signatures and service boundaries.
- Use `typing` constructs when they improve readability and correctness.
- Avoid `Any` unless it is unavoidable at a boundary.
- Prefer small, explicit data models (`dataclass`, typed dicts, Pydantic models) over loosely structured dictionaries when the data has a real shape.
- On 3.10+, write union types as `X | Y` (PEP 604) — including `X | None` instead of `Optional[X]` — rather than `typing.Union`/`typing.Optional`; no import needed, and it keeps the whole codebase consistent once any file has adopted it.

## Structure and code style

- Keep modules focused on a single responsibility.
- Avoid hidden global state and ambient configuration.
- Use explicit dependency injection for services and infrastructure adapters.
- Keep naming clear and domain-oriented rather than framework-oriented.
