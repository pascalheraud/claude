---
name: test
description: Python-specific backend testing conventions, built on the generic API skill. Independent of the concrete web framework and test framework — see the project skill for both.
---

# Python backend tests

Load [[api]] first, plus the project's chosen web framework and test framework skills. This skill adds only the Python-backend-specific testing conventions; it does not repeat the generic API rules or any framework-specific ones.

## Test strategy

- Use the web framework's request-level test client/harness for endpoint tests.
- Keep endpoint tests focused on contract validation and response shape.
- Prefer service-level tests for business logic and domain invariants.
- Use fixtures for DB state, auth context, and dependency overrides where needed.

## Python-specific test expectations

- Validate request and response schema contracts, not just mocked method calls.
- Cover the expected error conditions already defined in [[api]]: not found, forbidden, conflict, validation issues, and success responses.
- Prefer small, isolated tests rather than broad end-to-end setups for every rule.

## Project-specific usage

A project skill using this test convention should define:

- the concrete web framework's test client setup,
- the concrete rollback/isolation strategy for the database fixtures,
- the naming conventions for API and service tests in that repo.
