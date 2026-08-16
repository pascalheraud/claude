---
name: python-3.11
description: Python 3.11-specific language features — exception groups, TaskGroup, tomllib, typing additions, traceback locations.
---

# Python 3.11

Builds on [[languages/python]] for the version-agnostic conventions. This skill covers only what changes because the interpreter is 3.11.

## Exception groups

- Use `except*` to handle multiple unrelated exceptions raised concurrently (e.g. from an `asyncio.TaskGroup`), each clause matching one exception type within the group.
- Raise `ExceptionGroup`/`BaseExceptionGroup` when a single operation can produce several independent failures that all need to be reported, instead of picking and raising only the first one.

```python
try:
    ...
except* ValueError as eg:
    ...
except* TypeError as eg:
    ...
```

## Structured concurrency

- Use `asyncio.TaskGroup` instead of `asyncio.gather` for spawning concurrent tasks that should be waited on and cancelled together — a failure in one task cancels the sibling tasks automatically and surfaces as an `ExceptionGroup`.

```python
async with asyncio.TaskGroup() as tg:
    tg.create_task(coro_a())
    tg.create_task(coro_b())
```

## Standard library

- Use the built-in `tomllib` (read-only) to parse TOML files (e.g. `pyproject.toml`) instead of a third-party dependency. It does not support writing TOML.

## Typing additions

- Use `typing.Self` as the return type of a method that returns an instance of its own class (constructors, fluent builders), instead of a `TypeVar` bound to the class.
- Use `typing.LiteralString` to annotate a parameter that must be a literal string (not runtime-built), e.g. for APIs that build SQL/shell commands from string literals only.
- Use `Required[...]` / `NotRequired[...]` inside a `TypedDict` to mark individual keys as required/optional, instead of splitting into two `TypedDict` classes with `total=`.

## Tracebacks

Error locations in tracebacks are reported at the sub-expression level (e.g. pinpoint which attribute access in a chained call raised) — no code changes needed, but expect and read the more precise location when debugging.
