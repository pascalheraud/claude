---
name: venv
description: Python virtual environment conventions — creation, naming, and gitignore patterns. Applies whether the venv is Poetry-managed or created directly with venv/virtualenv.
---

# Python virtual environments

## Gitignore it thoroughly

Ignore the venv with a pattern broad enough to catch any throwaway/secondary virtualenv, not just the one exact name normally used:

```gitignore
.venv/
.venv*/
venv/
```

`.venv*/` matters in practice: a quick verification venv created alongside the project for a one-off check (e.g. `.venv-check/`, to sanity-check something outside the normal install flow) is easy to forget and would otherwise get committed — a `.venv/`-only pattern misses it.

## Naming

- Default to `.venv` (dot-prefixed) as the project-local virtualenv directory — the convention most tools (editors, Poetry with `virtualenvs.in-project`) look for automatically.
- A throwaway venv created for a one-off check should still follow the `.venv*` prefix (e.g. `.venv-check`) so it's caught by the gitignore pattern above without a separate rule, and should be deleted once the check is done rather than left around.
