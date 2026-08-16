---
name: fastapi
description: FastAPI-specific backend conventions — routers, Pydantic models, dependency injection, error handling, and route tests. Builds on the generic backend-api and Python-backend skills.
---

# FastAPI Backend Conventions

FastAPI-specific implementation of the [[api]] conventions. Load [[api]] and [[backend/python]] first — this skill only adds what's specific to FastAPI; it doesn't repeat the route-guard/status-code/response-shape/DI rules already defined there.

## Routers vs services

Same split as [[api]]'s "route handler vs service layer": a path operation function **calls the repository/session directly** if and only if it makes **a single data-layer call**; anything more goes into a service function/class injected via `Depends`.

- **The route decides which columns/fields to load**, passing that down to the service.
- **The route never passes FastAPI's own request-layer objects to a service** (`Request`, `Response`, raw `Query`/`Path`/`Body` parameter objects) — extract plain values (ids, parsed payloads, primitives) first.

## Request/response models

- Every route declares an explicit Pydantic **request model** (the `Body`/`Query` parameter type) and **response model** (`response_model=` on the decorator) — never a raw `dict` or an untyped payload.
- Use `model_config = ConfigDict(from_attributes=True)` (Pydantic v2) on response models that are built from ORM instances, instead of manually copying fields.
- A response model is a **dedicated Pydantic class**, not the ORM/persistence model reused as-is — keep DB-tied models and API-facing models separate even when their fields currently overlap, so a schema change on one doesn't silently leak into the other.
- Field-level validation (`Field(...)`, `field_validator`) lives on the request model; cross-field/business validation that needs a DB lookup stays out of the Pydantic model and happens in the route/service (Pydantic validators can't await a DB call).

## Route guards

Implemented via `HTTPException(status_code=..., detail=...)`, raised as soon as the condition is detected — never an uncaught exception standing in for a status code. Follows [[api]]'s guard rules (404/403/409, ownership, state-gating) as-is.

```python
resource = await repository.get_by_id(resource_id, columns=[...])
if resource is None:
    raise HTTPException(status_code=404)
if resource.owner_id != current_user.id:
    raise HTTPException(status_code=403)
```

## Responses — resource vs computed view

Same principle as [[api]]'s "response shape" rule, in FastAPI/Pydantic terms:

- A route returns the underlying resource's Pydantic model directly when its data is enough as-is.
- A response that needs computed/composed data uses a **dedicated response model**, built in the service layer once it needs more than one data-layer call or a computed field.
- Compose rather than inherit: embed the resource model as a field on the response model (e.g. `resource: ResourceOut`) rather than subclassing it.

## Dependency injection

FastAPI implementation of [[api]]'s "explicit wiring" rule: dependencies (DB session, current user, services) are wired through `Depends`, declared explicitly on each path operation's signature — never fetched via a global/module-level singleton from inside a service.

```python
async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> User:
    ...

@router.get("/resource/{resource_id}")
async def get_resource(
    resource_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ...
```

- Keep dependency functions small and composable — a dependency that itself needs another dependency takes it via `Depends`, forming an explicit chain FastAPI resolves automatically.
- Prefer `Annotated[Type, Depends(fn)]` aliases for dependencies reused across many routes, to avoid repeating `Depends(fn)` at every call site.

## Time as an injectable dependency

FastAPI implementation of [[api]]'s "time as an injectable dependency" rule: never call `datetime.now()`/`datetime.utcnow()` directly in business logic.

```python
class Clock(Protocol):
    def now(self) -> datetime: ...

class SystemClock:
    def now(self) -> datetime:
        return datetime.now(timezone.utc)

def get_clock() -> Clock:
    return SystemClock()

# In a service, injected via Depends(get_clock) at the route boundary and passed down
```

In tests, override `get_clock` via `app.dependency_overrides` with a fixed clock.

## Database session

- The DB session is a request-scoped dependency (`Depends(get_db)`), yielded by a generator/async-generator function that closes/rolls back the session after the request — never a module-level global session shared across requests.
- Repository/service functions receive the session as a parameter; they never create their own.

## Route tests

FastAPI implementation of [[api]]'s "API tests" focus:

- Use `TestClient` (sync) or `httpx.AsyncClient` (async) against the FastAPI `app` instance — no real network call, no full server process.
- Override dependencies with `app.dependency_overrides[get_db] = ...` / `app.dependency_overrides[get_current_user] = ...` instead of monkeypatching or real auth flows.
- Assert on `response.status_code` and `response.json()` against the declared response model's fields.
- Test focus: validation (missing/invalid body → 422), business logic (ownership → 403, conflict → 409), happy path (2xx + correct response shape per [[api]]).
- Do **not** test FastAPI's own request-validation/serialization mechanics (that Pydantic itself rejects a malformed body) — assume the framework works and focus on what the route does once the request is valid/authenticated.
