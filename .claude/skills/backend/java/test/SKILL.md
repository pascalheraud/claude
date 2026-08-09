---
name: test
description: Generic Java backend unit/integration testing conventions — deterministic test data, independent of when the test happens to run
---

# Backend Java tests (unit/integration)

Generic conventions for Java backend unit and integration tests.

## Never use the current date/time as test data

A test must never depend on "now" — no `new Date()`, no `Instant.now()`, no `LocalDate.now()`, no builder-style `now()` helper (e.g. `DateBuilder.now()`), for any value that becomes test data (a field being inserted, a comparison bound, an assertion's expected value). Use a fixed, arbitrary, real-looking date/time instead — hardcode a specific calendar date.

**Why:** a value derived from "now" makes the test's outcome depend on the moment it happens to run. This produces flaky failures near boundaries (midnight, month/year rollover, DST transitions) that are painful to reproduce, and makes two runs of the same test non-comparable — a bug that only shows up in some timezones or on some future date. A fixed date is deterministic and reviewable: the test's expected behavior for that exact date is visible in the diff.

```java
// Avoid — depends on when the test runs
Date creationDate = new Date();
Date creationDate = DateBuilder.now().getDate();

// Prefer — fixed, arbitrary, real date
Date creationDate = DateBuilder.date(2026, 1, 15).getDate();
```

This applies even to "now plus/minus an offset" patterns (`DateBuilder.now().addMinutes(-1)`, `new Date(System.currentTimeMillis() - 60_000)`) — express both ends of a range as fixed dates instead:

```java
// Avoid
Date from = DateBuilder.now().addMinutes(-1).getDate();
Date to = DateBuilder.now().addMinutes(1).getDate();

// Prefer
Date reference = DateBuilder.date(2026, 1, 15).getDate();
Date from = DateBuilder.date(reference).addMinutes(-1).getDate();
Date to = DateBuilder.date(reference).addMinutes(1).getDate();
```

**Exception:** code under test that itself needs "the current instant" (e.g. a `creationDate` your production code stamps via an injectable time source) should get that instant from a fake/mock of the injected time abstraction (e.g. a fake `ITime` returning a fixed `Date`) — not from the test calling `new Date()`/`now()` directly and hoping it lines up.
