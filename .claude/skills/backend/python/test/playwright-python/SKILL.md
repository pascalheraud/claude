---
name: playwright-python
description: Python End-to-End testing conventions using Playwright for Python — Testcontainers to stand up the DB, the app run as a real process in production mode, pytest-playwright for Browser/Context/Page lifecycle, one scenario module per scenario. Builds on the generic [[test/e2e]] and [[test/e2e/playwright]] skills.
---

# Python E2E tests with Playwright

Python-specific implementation of the [[test/e2e]] and [[test/e2e/playwright]] conventions. Load both first — this skill only adds what's specific to a Python/pytest/Testcontainers stack; it doesn't repeat the scenario/PageObject/snapshot rules or the generic Browser/Context/Page lifecycle.

[Playwright for Python](https://playwright.dev/python/) is the library used to drive the browser — the Python binding of [[test/e2e/playwright]]'s `Browser`/`BrowserContext`/`Page` lifecycle. Use the `pytest-playwright` plugin rather than driving `Playwright`/`Browser` by hand: it already implements [[test/e2e/playwright]]'s two-level lifecycle out of the box — a session-scoped `browser` fixture and a function-scoped `page` fixture (backed by a fresh `context`) — so scenario tests just take `page` as a parameter instead of managing setup/teardown themselves.

## Environment setup: Testcontainers for the DB, a real process for the app

The full stack for a test run is stood up as follows:
- **A DB container** (`testcontainers.postgres.PostgresContainer`, e.g. `postgres:16-alpine`), with the schema created the same way the app creates it on startup — via the app's own migration/`create_all` step, not a hand-copied DDL script. Always a Testcontainer, regardless of how the app itself is run.
- **The app, built and served in production mode**: the frontend is built (`npm run build`) before the run, and the backend is started as a plain process (`uvicorn app.main:app`, no `--reload`) pointed at the DB container's host-mapped connection URL via the same environment variable the app reads in any environment (e.g. `DATABASE_URL`). If the backend serves the built frontend assets itself (a single-origin deployment), starting the one process is enough to exercise the whole stack; if frontend and backend are served separately, start both as processes the same way.
- Don't containerize the app itself for E2E unless the project already ships a Dockerfile for other reasons — starting the built artifacts as OS processes against the DB container's host port is simpler and just as valid a "production mode" run.

Both the DB container and the app process are started **once per test session** (a session-scoped pytest fixture) and torn down at the end of the run. Isolation between scenarios comes from wiping/reseeding the relevant tables between tests (see below), not from restarting the container or the app process per test.

```python
import os
import subprocess
import time
import urllib.request

import pytest
from testcontainers.community.postgres import PostgresContainer


@pytest.fixture(scope="session")
def db_url() -> str:
    with PostgresContainer("postgres:16-alpine", driver="psycopg") as postgres:
        yield postgres.get_connection_url()


@pytest.fixture(scope="session")
def app_url(db_url: str) -> str:
    process = subprocess.Popen(
        ["uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000"],
        env={"DATABASE_URL": db_url, **os.environ},
        cwd="../backend",
    )
    _wait_for_health("http://127.0.0.1:8000/api/health")
    try:
        yield "http://127.0.0.1:8000"
    finally:
        process.terminate()
        process.wait()


def _wait_for_health(url: str, timeout: float = 10.0) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            if urllib.request.urlopen(url, timeout=0.5).status == 200:
                return
        except OSError:
            time.sleep(0.2)
    raise TimeoutError(f"App did not become ready at {url}")
```

## Test data setup: SQL through SQLAlchemy Core, not the ORM or the app

Per [[test/e2e]]'s "test data setup" rule, seed via SQL — in a Python/SQLAlchemy stack, that means plain `INSERT`/`DELETE` statements executed through a SQLAlchemy `Engine` (Core, not the app's ORM session or repositories), pointed at the same DB container. Wipe the relevant tables before each test (a function-scoped fixture that runs a `DELETE`/`TRUNCATE` before yielding) rather than restarting the container.

```python
from sqlalchemy import create_engine, text

@pytest.fixture
def seed(db_url: str):
    engine = create_engine(db_url)
    with engine.begin() as conn:
        conn.execute(text("DELETE FROM danslafoule.hello_worlds"))

    def _seed(row_count: int) -> None:
        with engine.begin() as conn:
            for _ in range(row_count):
                conn.execute(text("INSERT INTO danslafoule.hello_worlds DEFAULT VALUES"))

    yield _seed
    engine.dispose()
```

## Given/When/Then in pytest

[[test/e2e]]'s Given/When/Then structure, in pytest: a comment per section, even one-liners, inside a plain `test_*` function (no class needed — pytest doesn't require one).

```python
def test_wrong_password_shows_error_and_stays_on_page(page, app_url, seed):
    # Given a registered user and the login page
    seed_user = seed_user_with_password(seed, password="wrong-password-target")
    login_page = LoginPage.open(page, app_url)

    # When submitting an incorrect password
    login_page.fill_password("wrong-password")
    login_page.submit()

    # Then an error is shown and the user stays on the login page
    assert login_page.password_error() == "Your password is incorrect"
    assert "/login" in page.url
```

## PageObjects in Python

[[test/e2e]]'s PageObject conventions (a dedicated class per page, a `static`/module-level `open(...)` factory, destination-typed returns) and [[test/e2e/playwright]]'s "holds a `Page`, not a `Browser`/`BrowserContext`" rule apply as-is. In Python, the `open` factory is a `@staticmethod` or `@classmethod`:

```python
class HelloPage:
    def __init__(self, page):
        self._page = page

    @staticmethod
    def open(page, base_url: str) -> "HelloPage":
        page.goto(base_url)
        return HelloPage(page)

    def message(self) -> str:
        return self._page.locator("p").inner_text()
```

## One module per scenario

Every scenario (see [[test/e2e]] for what counts as a scenario) is its own test module (`test_<scenario>.py`) — no single module enumerating multiple unrelated scenarios as separate `test_*` functions. **All scenarios are covered**: every user journey the app supports has a corresponding scenario module, not just a representative subset.

A scenario module may still have multiple `test_*` functions if the scenario has meaningfully distinct paths (e.g. "sign-up" happy path vs. "sign-up with already-used email") — what it must not do is bundle a *different* scenario (e.g. "search") into the same module for convenience.

## Project-specific usage

A project skill using these conventions should document:
- The Testcontainers image/version used for the DB.
- How the backend and (if separate) frontend processes are started for E2E runs, and which environment variable(s) point them at the DB container.
- Where scenario test modules and PageObjects live, and the naming convention (e.g. `test_xxx_scenario.py`, `XxxPage`).
- The CI job that runs the E2E suite (see [[test/e2e]]).
