---
name: backend-java-spring-boot
description: Spring Boot-specific backend conventions — Controllers, Services, Entities, validation, transactions, and controller tests. Builds on the generic backend-api skill.
---

# Spring Boot Backend Conventions

Spring Boot/Java-specific implementation of the [[backend-api]] conventions. Load [[backend-api]] first — this skill only adds what's specific to Spring Boot; it doesn't repeat the route-guard/status-code/response-shape/DI rules.

## Controllers vs Services

Same split as [[backend-api]]'s "route handler vs service layer": a controller **calls the repository directly** if and only if the endpoint makes **a single repository call**; anything more goes into a `@Service` bean.

- **The controller decides which columns to load**, passing that column list as a parameter to the service.
- **The controller never passes HTTP-layer objects to a service** (`HttpServletRequest`, `HttpServletResponse`, `@RequestParam`/`@RequestBody` raw wrappers, etc.) — extract plain values first.

## Controllers

- `@RestController` + `@RequestMapping`
- All dates serialized as strings use **ISO 8601** format (e.g. `"2026-06-10T09:00:00"`)
- **All controller inputs are validated:**
  - When the request body is a **reusable entity**, define validation marker interfaces inside the entity class and annotate fields with `@NotNull(groups = MyGroup.class)`. Use `@Validated(MyGroup.class)` on the controller parameter.
  - When the request body is a **dedicated payload** (single-purpose), use a **bean class** (not a record) with `@Data @NoArgsConstructor` (Lombok), annotate fields with Jakarta constraints (`@NotBlank`, `@NotNull`, etc.) and use `@Valid` on the controller parameter.
- Route guards (404/403/409, ownership, state-gating) and the "no intentional 500" rule follow [[backend-api]] as-is — implement them with `ResponseStatusException`/`@ResponseStatus`/a `ResponseEntity` status, never an uncaught plain exception standing in for a real status code.

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

Same principle as [[backend-api]]'s "response shape" rule, in Spring Boot terms:

- DTO classes are always suffixed `DTO` (e.g. `AuxiliaireAuthDTO`).
- A DTO is built in a **service**, never in the controller, as soon as it requires an algorithm or more than one repository call to assemble. If it only wraps a single already-loaded entity with no extra computation, building it inline in the controller is fine.
- Prefer composition over inheritance: embed the entity as a field rather than extending it, and use `@JsonUnwrapped` on that field to keep the entity's properties flattened at the top level of the JSON response.

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

Spring Boot implementation of [[backend-api]]'s "time as an injectable dependency" rule: never call `new Date()` or `LocalDateTime.now()` directly in business code.

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

Spring Boot implementation of [[backend-api]]'s "explicit wiring" rule: always use **constructor injection** — never `@Autowired` on fields.

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

Spring Boot implementation of [[backend-api]]'s "API tests" focus:

- Use `@WebMvcTest(XxxController.class)` — loads only the web layer (no full Spring context)
- Declare dependencies as `@MockBean` (repositories, login managers)
- Use `@WithMockUser` to satisfy Spring Security filters on protected routes
- Use `MockMvc` for HTTP calls; assert status codes and JSON fields with `andExpect`
- Test focus: validation (missing/invalid fields → 4xx), business logic (ownership → 403, overlap → 409), happy path (2xx + correct response shape)
- Do **not** test authentication mechanics — that belongs to security tests
