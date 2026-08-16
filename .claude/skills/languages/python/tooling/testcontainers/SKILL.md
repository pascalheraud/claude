---
name: testcontainers
description: Testcontainers for Python — testcontainers-python setup, pytest fixtures, and the SQLAlchemy transaction-rollback isolation pattern for integration tests against a real containerized database.
---

# Testcontainers — Python

Builds on [[testcontainers]] (generic conventions, container lifecycle, setup requirements — read that first).

## Install

```bash
poetry add --group dev testcontainers sqlalchemy
```

No extra needed specifically for Postgres — `testcontainers.postgres.PostgresContainer` only requires a DB driver to actually connect (this project already has `psycopg` as a runtime dependency).

## Session-scoped container fixture

Start the container once for the whole test session, and pin the image tag to match the project's real dev/prod Postgres version:

```python
# tests/conftest.py
import pytest
from sqlalchemy import create_engine
from testcontainers.postgres import PostgresContainer

from app.core.database import Base


@pytest.fixture(scope="session")
def postgres_container():
    with PostgresContainer("postgres:16-alpine") as container:
        yield container


@pytest.fixture(scope="session")
def engine(postgres_container):
    engine = create_engine(postgres_container.get_connection_url())
    Base.metadata.create_all(bind=engine)
    return engine
```

## Per-test isolation via transaction rollback

Wrap each test in an outer transaction on a dedicated connection, bind the `Session` to that connection, and roll everything back afterwards — the schema created once by the session-scoped fixture survives, only the test's data changes disappear:

```python
# tests/conftest.py (continued)
from collections.abc import Iterator

from sqlalchemy.orm import Session, sessionmaker


@pytest.fixture
def db_session(engine) -> Iterator[Session]:
    connection = engine.connect()
    transaction = connection.begin()
    session_factory = sessionmaker(bind=connection, autoflush=False, autocommit=False)
    session = session_factory()

    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()
```

This is the standard SQLAlchemy "join a session into an external transaction" pattern. It works as long as the code under test doesn't call `session.commit()` itself in a way that would end the outer transaction — if it does, fall back to the schema/truncate-reset strategy from [[testcontainers]] instead.

## What this replaces

Don't stand up an in-memory SQLite engine (`sqlite:///:memory:`) as a Postgres stand-in for integration tests — see [[testcontainers]] for why. SQLite is still fine for something that is genuinely storage-engine-agnostic (e.g. testing a pure Python function that happens to take a `Session`), but not for anything that exercises actual Postgres behavior (schemas, constraints, types, dialect-specific SQL).
