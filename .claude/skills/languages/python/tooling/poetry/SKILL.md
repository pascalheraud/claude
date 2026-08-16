---
name: poetry
description: Dependency and build management with Poetry — environment creation, dependency resolution, and project packaging conventions.
---

# Poetry

## Core rules

- Install the project's dependencies with `poetry install`.
- Add dependencies with `poetry add` and keep the lock file committed.
- Use the project-local virtual environment through `poetry run`.
- Keep the `pyproject.toml` as the source of truth for package metadata and dependencies.

## Typical workflow

```bash
poetry install
poetry run pytest
poetry build
```

## Virtualenv

Poetry manages the project's virtualenv — see [[venv]] for gitignore and naming conventions that apply to it.
