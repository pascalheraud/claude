---
name: pydantic-settings
description: Configuration management with pydantic-settings — env vars, per-environment .env files, dev defaults vs required prod values. Load when wiring up app configuration/settings in a Python backend.
---

# pydantic-settings — Configuration conventions

## No hardcoded config in code

Application configuration (DB URLs, secrets, external endpoints) must come from the environment, not literals in the settings class — except for an explicit, documented **dev-only** default (see below). This keeps the same code correct across dev/staging/prod without edits, and keeps secrets out of the repo.

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env.dev", env_prefix="")

    database_url: str  # required — no default, must come from the environment

settings = Settings()
```

## Per-environment `.env` files, not one shared `.env`

Use a distinct `.env.<environment>` file per environment (e.g. `.env.dev`) rather than a single generic `.env`. The class only ever declares one `env_file` — the one for local development — since staging/prod inject real environment variables directly (container orchestrator, secret manager) and never read a file at all.

- `.env.dev` — **committed on purpose**, not gitignored. It holds local dev values only (e.g. matching a local `docker-compose.yml`) — never secrets, since anything in it is public to everyone with repo access. It doubles as both the working dev config and the documentation of every variable the app needs, so there's no separate `.env.dev.example` template to keep in sync.
- Anything containing a real secret (a `.env` used to hold a staging/prod override locally, a personal `.env.local`) stays gitignored — keep that pattern for those files, just not for `.env.dev`.
- A real environment variable, when set, always overrides the `.env.dev` file — this is `pydantic-settings`' default precedence (process env > env file), so staging/prod work by simply not shipping a `.env.dev` and setting real env vars instead.

## Rule: don't put a hardcoded default back "for convenience"

It's tempting to add `database_url: str = "postgresql://..."` directly on the field so the app "just works" with zero setup. Don't — that reintroduces hardcoded config and makes the required-ness of the value silently disappear for every environment, not just dev. Use `.env.dev` (loaded automatically via `env_file`) for the zero-setup dev experience instead; the field itself stays required.

## Setup checklist

1. Add `python-dotenv` as a dependency ([[poetry]]) — required by `pydantic-settings` to read `env_file`.
2. Gitignore `.env.dev` (and any other `.env.*` that isn't the `.example` template).
3. Commit `.env.dev.example` with every variable documented and a working local value.
4. Keep the field required (no default) in the `Settings` class — the `.env.dev` file is what supplies the dev-time value, not the code.
