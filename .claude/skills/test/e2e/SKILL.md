---
name: e2e
description: Generic End-to-End testing conventions — real browser against a real-schema DB and the app in production mode, scenario-based test breakdown, PageObject pattern, snapshot testing for content pages, and SQL-based test data seeding
---

# End-to-End tests

Generic conventions for E2E tests: what they run against, how they're organized, and the patterns that keep the test code as maintainable as the code under test.

## Environment

E2E tests drive a real browser against:
- A **real database**, with the real schema (migrations applied, not a hand-rolled test schema).
- The **real app**, running in production mode (built/packaged the same way it would be deployed), not a dev server with hot-reload or debug shortcuts.

This means an E2E test exercises the same code path a real user would hit — no mocked backend, no in-memory DB, no dev-only behavior masking a bug that would only show up in production mode.

## Writing E2E tests never touches application code

Writing or extending E2E tests is a **read-only exercise against the app's existing behavior** — the goal is to describe what the app actually does, not to shape what it does. While writing E2E tests, application/production code is never modified, not even for a one-line fix that looks obviously safe or unrelated to the test itself.

This includes, without exception:
- "Obvious" bugs noticed while exploring the app to write a test.
- Behavior that doesn't match the feature's spec (the test should encode the spec mismatch as a documented deviation, or ask, not silently correct the app to match the spec).
- Anything that would make a stubborn test pass (adjusting a response code, a validation rule, an error message, timing/async behavior) rather than adjusting the test to match reality.
- Refactors that would make the app "more testable" (extracting a hook, exposing an id, adding a test-only branch) unless the project's own conventions already call for that pattern independent of testing.

**At the first sign this boundary is about to be crossed — or already has been — stop and report to the user** instead of continuing or self-correcting silently: a test failing because the app's real behavior differs from what was assumed, a fix that would require touching non-test code to go green, an ambiguous case where "fix the app" vs "fix the test" isn't obvious. Report what was observed, what the two options are, and let the user decide — don't pick "fix the app" as the default resolution.

The one narrow exception a project skill may define is test-only scaffolding required to make the app observable/controllable in a test environment at all (e.g. the mocking seams described below, or a dedicated TEST environment flag) — never a change to real business logic, validation, or user-facing behavior.

## External dependencies: mocked via a TEST environment, not the real thing

Dependencies external to the application itself — sending emails, third-party APIs, payment providers, anything that leaves the process boundary — are **mocked**, not called for real, even though the app otherwise runs in production mode (this skill's "real app" rule is about *the app's own code path*, not about reaching third parties from a test run).

The app has a dedicated **TEST environment** (alongside its normal dev/prod environments) that is otherwise identical to PROD — same code paths, same behavior, no other dev-only shortcuts — with exactly one difference: every external dependency is neutralized, the real call is never made. TEST is not a relaxed/DEV-like mode; it must not be used to skip or shortcut anything other than these external calls, or it stops being a valid stand-in for "production mode" in this skill's "real app" rule. Each neutralized dependency:
- **Writes a trace** of the call (what was called, with what arguments) to a dedicated table — so a test can assert "the app tried to send this email" or "the app called this API with this payload."
- **Reads its return value** from a second dedicated table — so a test can pre-arrange what the mocked dependency responds with, without a real integration point on the other end (e.g. a mocked third-party lookup returning a specific result for a specific input).

Both tables are managed by the test-data loader (a dedicated table-/row-based seeding tool — see the project-specific skill for which one), the same way any other test fixture is: **wiped before every test**, so no trace or canned response leaks from one test into the next. A scenario that depends on a mocked dependency's output seeds the return-value table via the loader before exercising the flow, then asserts against the call-trace table afterward.

This keeps the "real app in production mode" guarantee for the app's own logic while making external side effects deterministic and assertable in CI, where the real third parties usually aren't reachable (or reachable but non-deterministic/rate-limited/costly to call per test run).

### Mocking is non-intrusive: subclass + override, never an `if` in production code

A mocked dependency is never implemented as a branch inside the real service (no `if (isTest()) { ... } else { realCall(); }` in production code). Instead:
- The real service exposes its external call as an overridable extension point (a `protected` method containing just the part that leaves the process — not the whole method).
- A **mock subclass** overrides only that extension point, doing the call-trace-table write instead of the real call. It's a normal class, testable and readable on its own, not a conditional buried in the real service.
- The mock is wired in ahead of the real implementation via dependency-injection priority (e.g. Spring's `@Primary` on the mock bean) — the app's own wiring code never mentions the mock by name.

The production service ends up with **zero knowledge that it can be mocked** — no test-only imports, no environment check, no dead branch shipped to real users. This also means the mock can be unit-tested and reasoned about independently, and swapping frameworks/mocking strategies later never touches the real service's code.

**Everything that exists only to support mocking is kept out of the production build, not just the override class.** If the mock needs its own supporting types — a call-trace/return-value entity, its repository, a fake in-memory client — those live alongside the mock subclass, excluded the same way. The test that something belongs in the excluded area isn't "is this a mock" but "would a real production deployment ever need this class" — if the only caller is the mock, it goes with the mock. See the project-specific skill for how a given project's build enforces the exclusion (e.g. a dedicated source directory or package excluded from the production artifact).

### Triggering specific mock behavior: naming conventions on the input, not always the return-value table

For a mocked dependency with a handful of well-known behaviors a scenario needs on demand (an unknown recipient, a call that throws, a rate-limit response, ...), seeding the return-value table for every test that wants one of these is more ceremony than the behavior needs. Prefer encoding the desired behavior directly in the value passed to the mocked call, via a fixed, documented naming convention the mock recognizes — the same idea as this skill's `test-XXXX@example.com` convention for addresses, extended to also select *behavior*, not just avoid real domains:
- `test-unknown@example.com` — the mock treats this recipient as never seen before.
- `test-exception@example.com` — the mock throws, simulating the dependency failing.
- `test-baddomain@example.com` — the mock reports this address's domain as invalid (e.g. for a mocked domain/MX check).

A scenario test then just uses the right input value; no extra seeding step, no return-value table row to clean up. Document the full list of recognized values next to the mock class itself (not scattered across scenario tests) — it's effectively the mock's API. Reach for the return-value table instead when the needed response can't be reduced to a fixed input-triggered case (e.g. an arbitrary payload the test wants echoed back, or a response that needs to vary per assertion within the same test).

## Test data setup: SQL, not the app

The database is seeded directly with SQL through a dedicated loader (project-specific — for a Java example, see [[backend/java/test/playwright]] and the project's own test-data skill), not by driving the app's own UI or API to create prerequisite state. Seeding through raw SQL keeps test setup independent from the code under test — a bug in the "create X" flow can't silently corrupt the fixtures used to test a *different* flow ("edit X", "delete X").

## Scenarios, not features

Tests are split into **scenarios**. A scenario is a linear sequence of actions and screens — it does not necessarily map to one feature. Examples: "sign-up", "search". A single feature can span several scenarios, and a single scenario can touch several features, depending on what a user actually does end-to-end in one sitting.

Keep each scenario focused on one coherent user journey. Don't merge unrelated journeys into one scenario just because they share a starting screen — that produces a slow, hard-to-diagnose test where a failure could be caused by either half.

## Given/When/Then structure

Each test method is written as **Given/When/Then**, marked with a comment per section (`// Given`, `// When`, `// Then`) even when a section is a single line — the labels are what make a long scenario body skimmable, not a framework requirement (no Cucumber/Gherkin needed):
- **Given** — the state the test starts from: data seeded via the test-data loader (see below), and/or the page already navigated to where the journey begins.
- **When** — the action(s) under test: the click, the form submission, the navigation that's actually being verified.
- **Then** — the assertions.

A test with multiple meaningfully-distinct When/Then pairs in sequence (e.g. "submit once, see the error; fix the field, submit again, see success") is fine — repeat the `// When` / `// Then` pair rather than forcing an artificial single pass. What doesn't belong in one test method is multiple *unrelated* Givens bolted together to save setup time — that's the same "don't merge unrelated journeys" rule as scenario-splitting, applied at the method level.

See [[backend/java/test/playwright]] for a worked Java/JUnit example.

## Assert the expected outcome, not just the absence of a bug

A `Then` assertion states what the app is *supposed* to show or do — never just "no error text visible" or "the buggy string isn't there." A negative-only assertion (e.g. checking a title doesn't contain "undefined") still passes for other wrong values the bug could produce (an empty string, a stale name, a swapped field), so it doesn't actually pin down correct behavior — it only rules out the one symptom already noticed. Assert the concrete expected value instead (e.g. the title equals "Contacter " + the seeded auxiliaire's real name), using data available from the Given step (the test-data loader's return value, a known fixture) rather than a value discovered by reading the bug.

This applies to regression tests written after finding a bug, not only to tests written up front: encode what "fixed" looks like, not just what "broken" looked like.

## Snapshot tests for simple content pages

Pages that are pure static/rendered content (no meaningful interaction, no state to drive through) are tested with a **single-step check** instead of a scripted action scenario — navigate to the page, then assert on its rendered output, instead of writing a multi-step user journey. This avoids writing brittle step-by-step scenarios for pages where the only thing worth verifying is "the content renders as expected."

"Snapshot" here means *not a scenario*, not necessarily a literal stored-output diff (Jest/Playwright-style snapshot files). What counts as "the output" is project-specific: a full rendered-output snapshot is one option, but targeted assertions (page title, one or two distinctive text elements) are equally valid and often cheaper to maintain — a project skill should say which one it uses and why.

Reserve scenario-based testing for pages/flows where the user actually does something (fills a form, clicks through steps, triggers state changes).

## Programmatic browser control

Tests are code, driven through an API that programmatically controls a real browser (e.g. Playwright, Selenium, Cypress) — not a record-and-replay tool and not manual QA scripts. This keeps tests versionable, reviewable, and runnable in CI like any other code.

## Automatic execution in CI

Tests run automatically according to the project's build/CI tooling (Maven, Gradle, GitHub Actions, GitLab CI, ...) — not as a manual, human-triggered step. A scenario that only a developer remembers to run locally provides much weaker protection than one wired into the pipeline that blocks merges/deploys on failure.

## Test code quality

E2E test code gets the same care as the code it tests: DRY, KISS, no copy-pasted step sequences across scenarios, no half-finished/skipped scenarios left in the suite. A flaky or unmaintained E2E suite is worse than no suite — it trains the team to ignore failures.

## PageObject pattern

Each page gets one **PageObject** class. It's the single place that knows about the underlying browser-automation framework for that page:
- Navigation methods (go to this page, wait for it to be ready).
- Element-access methods (locate the button, the form field, the list row) using the framework's selectors/locators.

The PageObject exposes *what can be done or read on the page*, hiding *how* the framework finds and interacts with elements. This means a framework migration (e.g. Selenium → Playwright) or a selector change from a markup refactor is contained to the PageObject classes, without touching every scenario that uses the page.

**Assertions stay in the test, not in the PageObject.** The PageObject returns values/state (e.g. `getErrorMessage()`, `isSubmitButtonEnabled()`); the test decides what to assert about them. This keeps one page's PageObject reusable across every scenario that touches it, including scenarios that expect different outcomes from the same page.

**A method that navigates to a different page returns that page's PageObject, not `this`.** A click/submit/navigation method whose real-world outcome is landing on a different page should return an instance of *that* page's PageObject — the test then chains straight into the new page's own methods, and the type itself documents where the action leads. Only methods that stay on the same page return `this` (or a same-page fluent-builder return) or nothing. A method whose destination depends on runtime state (e.g. "wrong password" keeps you on the login page, "success" navigates away) has no single correct return type — leave it returning nothing/`this` and let the test navigate/construct the next PageObject explicitly once it knows which branch happened.

**Reaching a page directly (typing a URL, not clicking through from another page) goes through a static `open` factory, not an instance method.** Each PageObject exposes a `static` (or language-equivalent — a module-level function, a named constructor) method — named `open`, taking the framework's page/browser-context handle plus whatever the URL needs (path params, query params) — that performs the navigation and returns the already-navigated PageObject instance. This keeps "how do I land on this page from nothing" and "what can I do once I'm here" both owned by the same class, without a separate constructor-then-navigate dance at every call site.

See [[backend/java/test/playwright]] for a worked Java example (`LoginPage`/`AccountPage`, including the "returns the destination page's PageObject" rule above).

## Project-specific usage

A project skill using these conventions should document:
- Which browser-automation framework/API is used.
- Where PageObjects live and the project's naming convention for them.
- How the real-schema DB and production-mode app are started for E2E runs (containers, docker-compose, ...).
- Where the concrete test-data loader/builder lives.
- Which external dependencies are mocked via the TEST environment, and where the call-trace/mock-return tables live and how they're queried/seeded.
- Where scenario tests live, and the CI job(s) that run them.
