---
name: pytest
description: Python testing conventions with pytest — deterministic tests, fixtures, parametrization, and backend validation strategy.
---

# Pytest

## Core rules

- Prefer pytest fixtures for setup and repeated test scaffolding.
- Use parametrization to cover multiple valid and invalid inputs.
- Keep assertions centered on behavior and domain outcomes.
- Avoid relying on wall-clock values in tests.

## Typical workflow

```bash
pytest
pytest tests/unit/test_example.py
```
