---
name: backend-java
description: General Java coding conventions — naming, Boolean handling, var usage
---

# Java Conventions

## Naming

- **No single-letter variable names** — all variables must have explicit, descriptive names. Use the type name or a domain term (`auxiliaire`, `dossier`, `newsletter`), not `a`, `d`, `n` (except loop indices where the meaning is obvious, e.g. `for (int i = …)`).

## Boolean

- When a `Boolean` field is guaranteed non-null (e.g. maps to a `NOT NULL` database column), use direct autoboxing (`!entity.getFlag()`) rather than `Boolean.TRUE.equals(...)`. The null-safe form hides a bug: a `null` here means the mapping is broken and should throw, not silently evaluate to `false`.

## `var`

- `var` is **not recommended in general** — explicit types make code easier to read without IDE assistance.
- Exception: when introducing an intermediate variable adds meaningful documentation but the inferred type is too verbose to write explicitly (e.g. `Stream<T>`, `Map.Entry<K, V>`). In that case, `var` lets you name the step without cluttering the line with an uninformative type.

## Enum predicates

When testing conditions on enum values, encode the predicate as a method on the enum itself. This documents the business intent clearly and avoids repeating multi-value conditions at call sites.

```java
// Bad — condition scattered in caller
if (statut == NewsletterStatut.EN_COURS_ENVOI || statut == NewsletterStatut.FINI) { … }

// Good — predicate lives in the enum
public enum NewsletterStatut {
    NOUVELLE, A_ENVOYER, EN_COURS_ENVOI, FINI;

    public boolean isSupprimable() {
        return this != EN_COURS_ENVOI && this != FINI;
    }
}

// Caller
if (!newsletter.getStatut().isSupprimable()) { … }
```

## Loops

- **No `break` or `continue`** — they create hidden control flow. Replace `continue` with a positive `if` or a stream `filter`; replace `break` with a boolean flag or `Stream.takeWhile` / `findFirst`.
- **Loop body in a method** — extract the body of any loop into a named private method. For nested loops, each level calls its own method.
- **Prefer streams for simple loops** — use streams for filter/map/collect/forEach with no checked exceptions and no complex branching. Use a loop when the body throws checked exceptions or when a stream would produce an unreadable one-liner.
- **Name intermediate stream steps with `var`** — when a stream chain has multiple steps, break it into named `var` variables; each name documents the intent of that step.
