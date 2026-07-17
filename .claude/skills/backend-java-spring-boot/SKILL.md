---
name: backend-java-spring-boot
description: General Spring Boot backend conventions — Controllers, Services, Entities, validation, and controller tests
---

# Spring Boot Backend Conventions

## Controllers vs Services

A controller **calls the repository directly** if and only if the endpoint makes **a single repository call**:
- a single insert/update/delete passing the entity payload
- a single read

As soon as there is **more than one call** (read + write, multiple reads, multi-entity orchestration, or non-trivial business logic), the logic is extracted into a `@Service` bean.

- **The controller decides which columns to load**, as much as possible, and passes that column list as a parameter to the service. This keeps the "what data does this response need" decision at the HTTP boundary, close to where the response shape is defined.
- **The controller never passes HTTP-layer objects to a service** (`HttpServletRequest`, `HttpServletResponse`, `@RequestParam`/`@RequestBody` raw wrappers, etc.). It is the controller's responsibility to extract whatever it needs from these objects and pass plain, service-usable values (ids, entities, primitives) instead.

## Controller route guards

- **Update / Delete** — always verify that the resource exists before acting:
  - Resource not found → `404 Not Found` (`HttpStatus.NOT_FOUND`)
  - Resource found but belonging to another user → `403 Forbidden` (`HttpStatus.FORBIDDEN`)
- **Any access to user-owned data** (read or write) must verify upfront that the logged-in user is the owner. Load the ownership field from the database, compare it with the connected user's id, and return `403 Forbidden` if the check fails. Never trust an id from the payload or the URL.
- **Post (creation)** — if the domain forbids duplicates on a field, check for absence of a duplicate before inserting and return `409 Conflict` (`HttpStatus.CONFLICT`) if one is detected.
- **State-gated actions** — any action that only applies to a resource in a specific state must load the current state from the database and verify it before proceeding. If the state doesn't match, return `409 Conflict`. Never rely on the client having sent the resource in the right state — always re-read from the DB.
- **State predicates belong on the enum** — never write inline multi-value statut checks in controllers or services (e.g. `statut != A && statut != B`). Instead, define a boolean method on the enum (e.g. `isEnvoyable()`, `isSupprimable()`) and call it from the controller. This centralises the allowed-state logic and keeps it close to the domain model.

## Controllers

- `@RestController` + `@RequestMapping`
- All dates serialized as strings use **ISO 8601** format (e.g. `"2026-06-10T09:00:00"`)
- **All controller inputs are validated:**
  - When the request body is a **reusable entity**, define validation marker interfaces inside the entity class and annotate fields with `@NotNull(groups = MyGroup.class)`. Use `@Validated(MyGroup.class)` on the controller parameter.
  - When the request body is a **dedicated payload** (single-purpose), use a **bean class** (not a record) with `@Data @NoArgsConstructor` (Lombok), annotate fields with Jakarta constraints (`@NotBlank`, `@NotNull`, etc.) and use `@Valid` on the controller parameter.

## Entities

- Use **Lombok**: `@Data` for getters/setters, `@NoArgsConstructor`, `@AllArgsConstructor` as needed
- **No default field values** — fields are always set explicitly by the caller or mapped from the database
- **Entities double as controller payloads** — when the same entity is used as a request body in multiple operations (insert, partial update…), group validation constraints with marker interfaces defined inside the entity (`Insert`, `ServiceUpdate`, `AddressUpdate`, etc.) and annotate each field with `@NotNull(groups = MyGroup.class)`. The controller uses `@Validated(MyGroup.class)` to trigger only the relevant constraints. This avoids duplicating separate payload classes for each operation.

### Adding a NOT NULL column to an inserted entity

When adding a `NOT NULL` column without a `DEFAULT`, you must **always**:

1. **Annotate the field** with `@NotNull(groups = Insert.class)` (or the appropriate validation group) in the Java entity.
2. **Initialize the field before insert** in the creation handler, and **include it in the column list** passed to the insert call.

Missing either step causes either a NOT NULL constraint violation in the database, or a Spring 400 validation error.

## Controller responses — entity vs DTO

- A route returns an **entity** directly when its data is enough as-is.
- A route returns a **DTO** when the response needs data the entity doesn't carry — computed values, or data composed from several entities/queries. Never add such fields to the entity itself (see [[backend-db]] — entities only hold DB-tied data); build a dedicated class instead.
- DTO classes are always suffixed `DTO` (e.g. `AuxiliaireAuthDTO`).
- A DTO is built in a **service**, never in the controller, as soon as it requires an algorithm (e.g. computing a derived flag) or more than one repository call to assemble. If the DTO only wraps a single already-loaded entity with no extra computation, building it inline in the controller is fine.
- Prefer composition over inheritance to build a DTO around an entity: embed the entity as a field rather than extending it, and use `@JsonUnwrapped` on that field to keep the entity's properties flattened at the top level of the JSON response.

## Controller — private helper methods

When multiple controller methods perform the same checks or operations (e.g. null check + ownership check), extract them into a **private method of the controller**.

Prefer accepting an already-loaded entity rather than an id — this avoids an extra query and keeps the caller in control of which columns are loaded:

```java
// Good — accepts the already-loaded entity
private void checkOwnership(Newsletter newsletter, Long userId) {
    if (newsletter == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
    if (!userId.equals(newsletter.getAuxiliaireId())) throw new ResponseStatusException(HttpStatus.FORBIDDEN);
}

// Bad — triggers an extra query inside the helper
private void checkOwnership(Long newsletterId, Long userId) {
    Newsletter newsletter = newsletterRepository.findById(newsletterId, ...);
    ...
}
```

## Time management

Never call `new Date()` or `LocalDateTime.now()` directly in business code — these calls cannot be controlled in tests.

Define an injectable `ITime` interface and mock it in tests:

```java
public interface ITime {
    Date now();
}

@Component
public class SystemTime implements ITime {
    @Override
    public Date now() { return new Date(); }
}

// In a service
@Service
@RequiredArgsConstructor
public class MyService {
    private final ITime time;

    public void doSomething() {
        entity.setDateTraitement(time.now());
    }
}

// In a test
ITime fixedTime = () -> new Date(1234567890000L);
```

## Dependency injection

Always use **constructor injection** — never `@Autowired` on fields.

With Lombok, declare dependencies as `final` fields and annotate the class with `@RequiredArgsConstructor`:

```java
@Service
@RequiredArgsConstructor
public class MyService {
    private final MyRepository myRepository;
    private final OtherService otherService;
}
```

Benefits: immutable fields, testability without a Spring context, circular dependency errors caught at compile time.

## Transactions

By default, each repository call runs in its own auto-commit transaction — one SQL query = one transaction.

### `@Transactional` — useful but limited

`@Transactional` groups multiple calls into an atomic transaction, but **only works when the method is called from outside the bean** (via the Spring proxy). When called from another method of the same service, the annotation is silently ignored — no transaction is started.

### Prefer `TransactionTemplate` (programmatic)

To avoid this pitfall, prefer programmatic transaction management with `TransactionTemplate`:

```java
@RequiredArgsConstructor
public class MyService {
    private final TransactionTemplate transactionTemplate;

    public void doSomething() {
        transactionTemplate.execute(status -> {
            repository.insert(...);
            repository.update(...);
            return null;
        });
    }
}
```

`TransactionTemplate` works regardless of the caller, including internal calls within the same service.

## Controller tests

- Use `@WebMvcTest(XxxController.class)` — loads only the web layer (no full Spring context)
- Declare dependencies as `@MockBean` (repositories, login managers)
- Use `@WithMockUser` to satisfy Spring Security filters on protected routes
- Use `MockMvc` for HTTP calls; assert status codes and JSON fields with `andExpect`
- Test focus: validation (missing/invalid fields → 4xx), business logic (ownership → 403, overlap → 409), happy path (2xx + correct response shape)
- Do **not** test authentication mechanics — that belongs to security tests
