---
name: pyenv
description: Python version management with pyenv — default interpreter selection, project-local version pinning, and reproducible Python environments.
---

# Pyenv

## Core rules

- Pin the project's interpreter version locally with `pyenv local` (writes `.python-version`).
- Keep the active interpreter aligned with the project requirements, not the system Python.
- Avoid installing dependencies into the global interpreter.

## Typical workflow

```bash
pyenv install 3.11.9
pyenv local 3.11.9
poetry env use 3.11.9
```
