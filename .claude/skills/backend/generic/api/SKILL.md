---
name: api
description: Generic backend API conventions — route handler vs service split, route guards (auth/ownership/state/duplicates), status-code discipline (no intentional 500s), response shape (resource vs computed view), injectable time, and API test focus. Framework/language-agnostic.
---

# Backend API Conventions

Generic conventions for a backend HTTP API, independent of language or framework (Spring Boot, Express, FastAPI, ...). A project skill for a specific stack builds on this one — load this first, then the stack-specific skill for the concrete syntax/annotations/libraries.

## Route handler vs service layer

A route handler calls the data layer **directly** if and only if it makes **a single data-layer call**:
- a single insert/update/delete of the payload
- a single read

As soon as there is **more than one call** (read + write, multiple reads, multi-entity orchestration, or non-trivial business logic), the logic is extracted into a service/use-case layer.

- **The route handler decides what data the response needs** (which fields/columns to load), as much as possible, and passes that down to the service. This keeps the "what does this response need" decision at the HTTP boundary, close to where the response shape is defined.
- **The route handler never passes raw HTTP-layer objects to the service** (the request/response objects, raw query-param wrappers, etc.). It's the route handler's job to extract whatever the service needs and pass plain, service-usable values (ids, parsed payloads, primitives) instead — the service layer shouldn't need to know an HTTP framework exists.

## Route guards

- **Update / Delete** — always verify the resource exists before acting:
  - Resource not found → **404 Not Found**
  - Resource found but belonging to someone else → **403 Forbidden**
- **Any access to user-owned data** (read or write) must verify upfront that the caller is the owner. Load the ownership field from the database and compare it to the authenticated caller's id — return 403 if it doesn't match. Never trust an id/owner field sent in the payload or the URL.
- **Create** — if the domain forbids duplicates on some field, check for an existing duplicate before inserting and return **409 Conflict** if one is found.
- **State-gated actions** — an action that only applies to a resource in a specific state must load the current state from the database and verify it before proceeding; if it doesn't match, return **409 Conflict**. Never rely on the client having sent the resource in the expected state — always re-read from the DB.
- **State predicates belong on the state type itself** — never write inline multi-value state checks in route handlers or services (e.g. `status != A && status != B`). Define a named predicate on the state's own type (an enum method, a class method, ...) and call that instead. This centralizes the allowed-state logic next to the domain model rather than scattering it across call sites.

## Route identifier: PK vs. external UUID

Don't reach for an external/opaque UUID identifier in a URL by default — decide based on who can reach that route, not habit:

- **Authenticated routes gated by an ownership check** (route guard above: load the resource, compare its owner to the caller, 403 if it doesn't match) — use the resource's own numeric/PK id in the URL (`/resource/{id}`). The ownership check already prevents one user from acting on another's resource; a UUID adds no additional protection there, only extra indirection (a lookup by UUID instead of by PK) for no benefit.
- **A route reachable without that ownership check** — a public link (e.g. emailed to the resource's owner, or shared/forwarded), or any endpoint where enumerating sequential ids would leak information (existence, approximate count, creation order) to someone who isn't authenticated as the owner — use an external UUID (`external_id`, generated independently of the PK) instead of the PK, so the id can't be enumerated or guessed.

A resource can have both: an internal PK used for every authenticated, ownership-gated route, and a separate external UUID used only for the one or two routes/links that are reachable outside that gate (e.g. a one-click link in a notification email). Don't default the UUID onto every route "for consistency" once one genuinely needs it — that just adds an indirection cost to routes that get no security benefit from it.

## No route intentionally raises a 500

A `500 Internal Server Error` means "the server hit a bug/unexpected failure" — it is never a deliberate way to signal an expected, name-able condition. No route throws/raises a generic, unhandled exception as a substitute for a real response:

- A condition the caller can act on (bad input, not found, conflict, forbidden, not-yet-in-the-right-state) always maps to the matching **4xx** status — see "Route guards" above for the specific cases.
- A condition the front end needs to distinguish and react to in its own UI is **not an error at all** from the API's point of view — it's an expected, documented response shape (a `2xx` body with a discriminating field, or a specific 4xx with a body the front end parses), not a thrown exception that happens to produce a status code.
- The only legitimate path to a 500 is a **genuine, unanticipated failure** (a bug, an infrastructure hiccup) — something that was never meant to happen and that no caller-side branch exists for. If a test or a manual check turns up a route that reaches a 500 for a condition that *is* anticipated (an unknown id, a bad email, invalid state, ...), that route has a real bug to fix: give the condition its own explicit status code, don't leave it falling through to an uncaught exception.

## Response shape: raw resource vs computed/composed view

- A route returns the underlying resource/entity directly when its data is enough as-is.
- A route returns a **dedicated response/view type** when the response needs data the resource itself doesn't carry — computed values, or data composed from several resources/queries. Don't bolt such fields onto the persisted entity/model itself (persisted types only hold DB-tied data) — build a separate response type instead.
- That response type is built in the **service layer**, not the route handler, as soon as it requires an algorithm (a computed/derived field) or more than one data-layer call to assemble. If it only wraps a single already-loaded resource with no extra computation, building it inline in the route handler is fine.
- Prefer composition over inheritance when building a response type around a resource: embed the resource as a field rather than extending/subclassing it, and flatten it into the response at serialization time (most JSON libraries have an "unwrap/inline this nested object" annotation or option) rather than duplicating its fields by hand.

## Route handler shared logic

When multiple route handlers perform the same checks (e.g. existence + ownership), extract them into a shared helper.

Prefer accepting an already-loaded resource rather than an id — this avoids an extra query and keeps the caller in control of which fields were loaded:

```
// Good — accepts the already-loaded resource
function checkOwnership(resource, userId) {
  if (!resource) throw notFound();
  if (resource.ownerId !== userId) throw forbidden();
}

// Bad — triggers an extra query inside the helper
function checkOwnership(resourceId, userId) {
  const resource = repository.findById(resourceId);
  ...
}
```

## Time as an injectable dependency

Never call the system clock (`now()`, `new Date()`, `Date.now()`, ...) directly from business logic — it can't be controlled in tests, and makes time-dependent behavior (expirations, "due" checks, date-bucketed queries) impossible to exercise deterministically.

Inject a small clock/time abstraction instead — one method, returning the current time — and swap in a fixed/fake implementation in tests. The concrete injection mechanism (constructor param, DI container, module-level override) is stack-specific; see the project skill.

## Dependency injection: explicit wiring, not hidden lookups

Prefer whatever the stack's idiomatic **explicit** dependency-injection mechanism is (constructor injection, explicit factory functions, an application-level composition root) over global/implicit lookups (service locators, ambient singletons reached from deep inside business logic, framework magic that hides what a class depends on). Explicit wiring keeps dependencies visible at a glance, makes a class testable without spinning up the whole framework, and turns circular-dependency mistakes into an immediate, loud error instead of a runtime surprise.

## Logging

- **Request correlation**: every request is identifiable by a single id that persists across every log line produced while handling it — the HTTP access log, any SQL query log, and every application log statement in between. Without this, tracing "what happened for this one request" across a busy log stream means guessing from timestamps. The concrete mechanism (a generated/propagated request id stored in a thread-local/async-local context and injected into the log formatter) is stack-specific — see the project's stack skill for the concrete library/middleware.
- **Silent mechanisms are logged**: anything that runs without a caller directly observing it — a scheduled job, a batch, a background worker, a queue consumer, a TTL/cleanup sweep — logs at least its start (with its parameters/scope: what it's about to process, how much, since when) and its end (what it actually did: how many rows/items affected, how long it took). A batch that only logs on failure is invisible when it's silently doing nothing or doing the wrong thing — the absence of an error is not evidence it ran correctly.
- **Service-level start/end**: every service-layer call (the unit identified in "Route handler vs service layer" above — a use case, not a single-line delegation) logs an `INFO` line when it starts and another when it finishes. This gives a log-only trace of what the backend actually did for a request, independent of the HTTP access log, and is what makes the request-correlation id above actually useful — without a marker per service call, there's nothing for that id to tie together beyond "a request happened." Keep both lines short (service/use-case name + key identifying parameters); leave detailed intermediate steps to `DEBUG` if needed.

## API tests

Test focus for a route/handler test, regardless of stack:
- **Validation** — missing/invalid input → the matching 4xx.
- **Business logic** — ownership → 403, duplicate/conflict/wrong-state → 409, not found → 404.
- **Happy path** — 2xx + correct response shape.

Don't test the framework's own authentication/authorization *mechanics* in these tests (that the auth middleware itself works) — assume the framework's auth is correct and focus on what the route does once a caller is authenticated/not authenticated. Use whatever lightweight test harness the stack offers for testing a single route/handler in isolation (no full app/integration boot) as the default; reach for a full end-to-end test only when the thing under test genuinely spans multiple routes or the real stack (see [[test/e2e]]).

## Project-specific usage

A project skill using these conventions should document:
- The concrete language/framework (Spring Boot, Express, FastAPI, ...) and its idioms for each section above (validation annotations/decorators, DI mechanism, the lightweight single-route test harness, transaction handling).
- Where DTOs/response types, entities/models, and shared route-guard helpers live in the codebase.
- The concrete injectable-time mechanism used (interface name, module, fixture pattern for tests).
