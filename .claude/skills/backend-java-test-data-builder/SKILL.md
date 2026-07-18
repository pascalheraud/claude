---
name: backend-java-test-data-builder
description: Java test data seeding tool for E2E/integration tests — inserts rows via raw SQL only (no entities, no repositories), with templated data clusters, naming, and ordered insert/delete
---

# TestDataBuilder

A test-only tool that seeds a database with rows for E2E or integration tests, using **raw SQL only** — it never touches entity classes or repositories. This keeps seeded data independent from the application's persistence layer: a bug or a schema drift in an entity/repository cannot silently corrupt what the test believes it inserted.

## Core model

- **`TestDataBuilder`** is instantiated with a `DataSource`. It only ever sends SQL statements through it — no ORM, no repository call.
- **`Table`** (a project-specific `TestTable` implementation) is an enum, one value per table (e.g. `CLIENT`, `CONTRACT`). Each value carries the SQL table name as a constant, and its columns — see `TestColumn` below — via `getColumns()`.
- A column can be identified either by a raw `String`, or by a project-specific enum implementing **`TestColumn`** (mirrors `TestTable`: one constant per column, each carrying the SQL column name) — a typo-safe alternative, not mandatory. `Data.setColumn`/`getColumn` are overloaded for both:

```java
public interface TestColumn {
    String getSqlName();
}

enum ClientColumns implements TestColumn {
    EMAIL("email"), NAME("name");

    private final String sqlName;
    ClientColumns(String sqlName) { this.sqlName = sqlName; }
    public String getSqlName() { return sqlName; }
}
```

```java
client.setColumn("email", "test@example.com");           // raw string key
client.setColumn(ClientColumns.EMAIL, "test@example.com"); // typo-safe key, same effect
```

- **`Data`** represents one row to insert: a `Table` plus an ordered `Map<String, Object>` of column → value. A value is either an immediate literal or a reference to another `Data` (resolved to that row's generated id at insert time, for foreign keys). Any `Data` referenced this way must already be registered on the builder — template methods always create and register a parent before building a child that references it, so the builder never needs to insert one out of order.

```java
public interface TestTable {
    String getSqlName();
    TestColumn[] getColumns(); // e.g. ClientColumns.values()
}

enum Table implements TestTable {
    CLIENT("client", ClientColumns.values()),
    CONTRACT("contract", ContractColumns.values());

    private final String sqlName;
    private final TestColumn[] columns;
    Table(String sqlName, TestColumn[] columns) { this.sqlName = sqlName; this.columns = columns; }
    public String getSqlName() { return sqlName; }
    public TestColumn[] getColumns() { return columns; }
}

class Data {
    final TestTable table;
    final Map<String, Object> columns = new LinkedHashMap<>();
    Long generatedId; // filled in by create() after insert
    boolean added;    // true once create() has inserted this row

    Data(TestTable table) { this.table = table; }
}
```

`getColumns()` is metadata about the table (which columns exist), not about a specific `Data`'s populated values — useful for introspection (e.g. a generic "assert every column was set" helper), independent of whichever individual columns a given template happens to fill in.

## Templates

Each `Table` gets one or more **template methods** on the builder that instantiate a pre-filled `Data` with sane defaults, which the caller can then override before it's inserted:

```java
Data client = builder.newClient()
    .setColumn(ClientColumns.EMAIL.name(), "test@example.com");
```

A template method may build **more than one `Data`** at once when the cluster is naturally tied together — e.g. `newClientWithContract()` creates a `Client` and a linked `Contract`. Build this as **two steps, not one inlined method**: call `newClient()`, then `newContractForCurrentClient()` — the second step reads the just-created client from the "current" shortcut (below) rather than taking it as an explicit parameter. **Return a record holding every `Data` the cluster created**, not just one of them — the caller often needs the id of each:

```java
public record ClientWithContract(Data client, Data contract) {}

public ClientWithContract newClientWithContract() {
    Data client = newClient();
    Data contract = newContractForCurrentClient();
    return new ClientWithContract(client, contract);
}
```

This keeps the cluster method as a thin composition of the two single-table templates, keeps `newContractForCurrentClient()` reusable on its own (e.g. to add a second contract to a client created earlier), and gives the caller typed access to both rows (`result.client().getGeneratedId()`, `result.contract().getColumn(...)`) instead of having to look one of them up again by name afterwards.

### Multiple templates per table

A table isn't limited to one base template. Add several `newXxx...()` variants when different tests need different subsets of columns filled in — e.g. `newClient()` for the common case, `newClientWithName(String name)` when a test specifically cares about the name rather than the generated default:

```java
public Data newClient() { ... }                       // sane defaults for everything

public Data newClientWithName(String name) {
    return newClient().setColumn(ClientColumns.NAME.name(), name);
}
```

This is a special case of the parameterized-template rule below — `newClientWithName` fixes one specific column and documents the intent (this test cares about the name) directly at the call site, without the caller having to know which column key controls it.

### Partial templates (`setXxx`)

Not every reusable group of columns belongs in a `newXxx()` — some apply to a `Data` that's already been created (often by a different, more targeted test than the one that owns the base template). A **`setXxx(Data)` partial template** takes an existing `Data` and fills in one specific group of related columns, with the values fixed inside the method itself (not passed in by the caller):

```java
public Data setClientAddress(Data client) {
    return client
        .setColumn(ClientColumns.ADDRESS_CITY.name(), "Paris")
        .setColumn(ClientColumns.ADDRESS_LABEL.name(), "1 Rue de la Paix")
        .setColumn(ClientColumns.WORK_RADIUS_KM.name(), 15);
}
```

Use this to pull a recurring block of `setColumn()` calls (e.g. "a plausible address", "a full set of service flags") out of a test body and out of `newXxx()`, when that block doesn't belong in *every* call to the base template and isn't worth parameterizing — the values are just "a reasonable example of X", not something callers need to vary. Chain it directly after the base template:

```java
Data client = builder.newClient();
builder.setClientAddress(client);
```

Unlike the parameterized-template case above, a partial template doesn't take arguments for the values it sets — if a test needs different values, it overrides individual columns on the returned `Data` afterward with `setColumn(...)`, same as any other override.

### Parameterized templates

When a test scenario needs the same handful of columns filled in with different values *often enough that chaining `setColumn()` at every call site becomes repetitive noise*, add a **parameterized template method** instead — a `newXxx(...)` overload that takes those values as named parameters:

```java
public Data newClient(String idClient, String idRegion) {
    return newClient()
        .setColumn(ClientColumns.EXTERNAL_ID.name(), idClient)
        .setColumn(ClientColumns.REGION_ID.name(), idRegion);
}
```

This documents the recurring shape directly in the method signature — a caller reading `newClient("C-42", "FR-IDF")` sees which columns matter for that scenario without chasing `setColumn()` calls, and typos in column names are caught once, in the template, rather than at every call site. Keep the no-args `newXxx()` template as the base case; add a parameterized overload only for combinations of columns that actually recur across several tests — don't add one per single test's one-off values.

A parameterized template can also **compute** columns instead of just passing them through — e.g. a scenario built from a broken-down date/time plus a duration, with the template doing the arithmetic once instead of every call site repeating `LocalDateTime.of(...).plusMinutes(...)`. Prefer a plain `int` (e.g. minutes) over a `java.time.Duration` parameter — call sites read `newContract(2026, 6, 10, 9, 0, 120)` without an extra `Duration.ofMinutes(120)` wrapper:

```java
public Data newContract(int year, int month, int day, int hour, int minute, int durationMinutes) {
    LocalDateTime start = LocalDateTime.of(year, month, day, hour, minute);
    return newContract(start, start.plusMinutes(durationMinutes));
}

public Data newContract(LocalDateTime start, LocalDateTime end) {
    return newContract()
        .setColumn(ContractColumns.START.name(), start)
        .setColumn(ContractColumns.END.name(), end);
}
```

Layer overloads on the base `newXxx()` template (never duplicate its defaults): the broken-down-date overload delegates to the `(start, end)` overload, which delegates to the no-args template.

### Per-table index for distinct default values

The builder keeps a per-`Table` counter, incremented every time that table's base `newXxx()` template runs. Templates use this index to make their default values distinct across calls, instead of hardcoding one fixed literal that collides the second time the same template is called in a test:

```java
public Data newClient() {
    int index = nextIndex(Table.CLIENT); // 0, 1, 2, ...
    return register(new Data(Table.CLIENT)
        .setColumn(ClientColumns.EMAIL.name(), "client" + index + "@example.com")     // string: prefix with the index
        .setColumn(ClientColumns.CODE.name(), 50 + index)                             // number: offset a base by the index
        .setColumn(ClientColumns.ACTIVE.name(), index % 2 == 0)                       // boolean: alternate by index parity
        .setColumn(ClientColumns.STATUS.name(), Status.values()[index % Status.values().length])); // enum: alternate by ordinal
}
```

Rules of thumb per value shape:
- **Strings** — prefix or suffix with the index (`"client" + index + "@example.com"`).
- **Numbers** — offset a fixed base by the index (`50 + index`, giving `50`, `51`, `52`, ...), not a repeated constant.
- **Booleans** — alternate by index parity (`index % 2 == 0`), so consecutive rows don't all default to the same value.
- **Enums** — alternate by ordinal, wrapping with modulo (`values()[index % values().length]`).
- **UUIDs — the one exception**: keep `UUID.randomUUID()`, don't derive it from the index. A UUID column is a technical identifier, not a value a test scenario reasons about, and there's no readable "index-derived UUID" scheme worth inventing.

This means a test creating three clients via `newClient()` never has to override anything just to avoid a `UNIQUE` violation or to tell the three rows apart.

**Read expected values back from the `Data`, don't re-literal them in assertions.** Since defaults are index-derived rather than fixed, a test should assert against what the `Data` actually holds (e.g. `client.getColumn(ClientColumns.EMAIL.name())` or `client.getGeneratedId()`) instead of duplicating the computed literal (`"client0@example.com"`) in the test body. This also keeps assertions correct if the index scheme changes later — the test never hardcoded the derived value in the first place.

## "Current" shortcut

The builder keeps a `Map<Table, Data>` of the most-recently-created `Data` per table. This backs shortcut template methods like `newContractForCurrentClient()`, which links to whatever `Client` was last created — avoiding having to thread the same object through every call when tests build one linear chain of data. Cluster templates (above) are built on top of this shortcut, not by passing the parent `Data` explicitly between templates.

## Naming

Every `Data` is tagged with a **name**, a `String` identifying group of related rows within a test, defaulting to `"root"`. Call `builder.withName("client1")` to change the name used for subsequent template calls; it stays in effect until changed again.

The builder keeps `Map<String, Map<Table, List<Data>>> dataNaming` — for each name, for each table, the ordered list of `Data` created under that name. Calling a template method (e.g. `newClient()`) three times without changing the name appends three entries under the current name for `Table.CLIENT`.

Lookup methods read from this map:
- `getClient(name)` — returns the single `Data` for that name/table; **throws if there is more than one** (use `getClients` instead when several are expected).
- `getClients(name)` — returns the full list.

## Ordering and table tracking

The builder keeps every `Data` ever added in a single ordered sequence (`List<Data>`), preserving creation order across all tables and names — if `A` is created before `B`, `A` is inserted before `B`.

It also keeps an ordered `Set<Table> dataTables` — every table touched by at least one `Data`, in first-touched order. This drives cleanup (see `delete()` below).

## `apply()`

`apply()` = `delete()` followed by `create()` — the standard call at the start of a test scenario, right after all `Data` have been declared.

- **`delete()`** issues `DELETE FROM <table>;` for every table in `dataTables`. Run this in **reverse** of `dataTables`'s first-touched order: since a table is normally first touched when its own rows start referencing an earlier (already-touched) table, deleting in the same order the tables were first touched risks violating FK constraints — deleting children before parents (reverse order) is the safe default. If the schema has FKs that don't follow "referenced table touched first" (e.g. circular or deferred constraints), don't rely on `dataTables` order alone — say so in the project skill and document the exception explicitly.
- **`create()`** walks the single ordered `Data` sequence and, for each `Data`, builds `INSERT INTO <table> (<cols>) VALUES (<vals>) RETURNING id`, resolving any column value that references another `Data` to that `Data`'s `generatedId` (guaranteed available, since dependencies are always inserted first). The returned id is stored back onto the `Data` so later rows can reference it in turn.

### Cleaning up a table nothing seeds: `deleteTable(Table)`

Not every table that needs clearing between tests is one a `Data` template ever creates. A table the **app itself** writes to as a side effect of the flow under test — an audit/usage log, a call-trace table for a mocked dependency (see [[test-e2e]]'s "external dependencies" and "mocking is non-intrusive" rules) — never goes through `register()`, so `dataTables` never picks it up, and `delete()` leaves its rows behind. Left alone, those leftover rows can even block `delete()` itself with an FK violation (e.g. a log row still referencing the parent row `delete()` is about to remove).

`deleteTable(Table)` adds a table to `dataTables` directly, with no `Data` behind it — it only affects `delete()`'s cleanup pass, `create()` never sees it:

```java
protected void deleteTable(TestTable table) {
    dataTables.add(table);
}
```

**Ordering trick:** since `delete()` processes `dataTables` in *reverse* first-touched order, and `dataTables` is a `LinkedHashSet` (insertion order, no reordering on repeat adds), calling `deleteTable(LOG_TABLE)` **last** — after every `newXxx()` call a test has already made — makes it the most-recently-touched entry, so it's deleted *first* in the reversed pass, before whatever it references. A project's `delete()` override typically looks like:

```java
@Override
public void delete() {
    deleteTable(Table.USAGE_LOG); // written by the app itself, not seeded — clear it before its FK parent
    super.delete();
}
```

Reserve this for tables that are otherwise ordinary (real schema, tracked like any other) but structurally can't be seeded through a template — not for tables that must never exist outside a test build at all (e.g. a mock call-trace table compiled only for E2E runs), which stay as an explicit unconditional `DELETE` in the project's `delete()` override instead, since folding those into `dataTables`/`Table` would imply they're regular schema.

### Calling `create()` more than once

Every `Data` carries an `added` flag, `false` until `create()` inserts it. `create()` only inserts `Data` where `added` is still `false`, then flips it to `true` — so it's safe to call `create()` more than once: register more `Data` after an earlier `apply()`/`create()`, then call `create()` again, and only the newly-registered rows get inserted (nothing already in the database gets re-inserted or re-deleted). This is useful when a test needs to seed a second batch of rows partway through, depending on state produced earlier in the same test (e.g. an id returned by the code under test), without discarding what's already there.

## Columns that need a raw SQL expression

Most column values are plain bind parameters. Some column types need the value wrapped in a SQL function call instead — e.g. a PostGIS geometry column needs `ST_GeomFromText(?, 4326)` rather than a bare value the driver can't bind directly. Represent this with a small value type, e.g.:

```java
public record SqlExpression(String sql, Object... params) {}
```

`create()` special-cases a column whose value `instanceof SqlExpression`: it inlines `sql()` in place of that column's `?` placeholder in the generated `INSERT`, and appends `params()` to the bound values in its place (instead of binding the `SqlExpression` itself). Everything else about the row (dependencies, FK resolution, ordering) is unaffected — this only changes how one column's placeholder and bind value are produced.

```java
Data service = builder.newService()
    .setColumn("address_point", new SqlExpression("ST_GeomFromText(?, 4326)", "POINT(5.885139 45.308556)"));
```

## Why no entities, no repositories

- **No entity classes**: `Data` is a generic `Table` + `Map<String, Object>`, not tied to any `@Entity`/domain class. Test data setup keeps working even if an entity's Java shape changes, as long as the table/column names don't.
- **No repositories**: inserts go straight to the `DataSource` as SQL. This guarantees seeded state is independent of the repository layer under test — an E2E test asserting on data seeded by the same repository code it exercises risks masking bugs in that repository.

## Same API for repository tests and E2E tests

Because `TestDataBuilder` only depends on a plain `DataSource`, the identical builder/`Table`/`Data` code works unchanged in both contexts — only *where the `DataSource` comes from* differs:

- **Repository tests** (Testcontainers-backed, Spring context running): reuse the container/`DataSource` your base test class already manages (e.g. a `getDataSource()` exposed by a shared `BaseRepositoryTest`-style class) — don't spin up a second container just for the builder.
- **E2E tests** (no Spring context, or a Spring context running in its own container): start a `JdbcDatabaseContainer` (e.g. `PostgreSQLContainer`) directly with Testcontainers and build a plain `DataSource` from its connection info:

```java
public static DataSource dataSourceFrom(JdbcDatabaseContainer<?> container) {
    return new DriverManagerDataSource(
        container.getJdbcUrl(), container.getUsername(), container.getPassword());
}
```

  This is the same container whose network alias/port you wire into the front/backend containers for the E2E scenario, so `TestDataBuilder` and the running app read/write the same database.

**Isolation between tests differs by context, not by API.** Repository tests typically wrap each test in a Spring-managed transaction that's rolled back afterwards — `apply()` may not even need `delete()` in that setup if rollback already guarantees a clean slate. E2E tests have no such transaction (the browser drives the app through its own transactions), so `apply()`'s `delete()` + `create()` is what provides isolation between scenarios. Don't assume one mechanism when reusing builder code across both — check whether the calling test already gets rollback isolation, and skip a redundant `delete()` only in that case.

## Package layout: generic vs project-specific

Split the classes into two packages:
- A **`generic` subpackage** (e.g. `testsupport.generic`) holding everything that has no project knowledge: `TestDataBuilder`, `Data`, `TestTable`, `TestColumn`, `SqlExpression`. These types don't change from one project to another.
- The **parent `testsupport` package** holding the project-specific pieces: the concrete `Table`/`Column` enums (one `Column` enum per table, e.g. `ClientColumns`), the concrete `TestDataBuilder` subclass with its template methods, and any cluster records (`ClientWithContract`).

This mirrors the "generic vs project-specific" split used for skills themselves: the generic package is what would be copy-pasted into a new project as-is, the parent package is what gets rewritten per project's schema.

## Project-specific usage

A project skill using this tool should document:
- The concrete `Table` enum and per-table SQL name / columns.
- The template methods (`newXxx`, `newXxxWithYyy`, `newXxxForCurrentYyy`) available and their default column values.
- Any FK ordering exceptions to the `delete()` reverse-order rule.
- Where the shared/cached container + `DataSource` for repository tests lives, and how E2E tests start their own.
