---
name: js
description: JS/TS frontend conventions, framework-agnostic — model types, API error handling (500/404/403), empty select handling. Load this for any JS/TS frontend; see [[react]] for the React-specific implementation of these patterns.
---

# JS/TS Frontend Conventions

## Model types

- Use `interface` for API response shapes, `type` for unions and mapped types
- Date fields are `string` in ISO 8601 format
- No optional (`?`) on fields that the backend always returns — use `string` not `string | undefined`

## API error handling

### 500 — Internal server error

Any 500 response must display an internal error popup:
- The popup is closeable and must not destroy the current form — the user can retry after closing
- Never show technical details to the user
- Pattern: a boolean `internalError` state; set it to `true` on any rejection with `serverError: true` or any `status >= 500`

See [[react]] for the React implementation pattern.

### 404 / 403 — Update or Delete

PUT and DELETE calls may receive a `404` (resource not found) or `403` (resource belongs to another user). Both cases should be caught and displayed with a generic error message of the form **"[Resource name] not found."**. Do not distinguish 404 from 403 in the UI — both mean the object is no longer accessible.

Use a low-level fetch helper that returns `{ status, body }` to inspect the status before processing the response:

```ts
const { status } = await fetchJson(`/api/resource/${id}`, { method: "DELETE" });
if (status === 404 || status === 403) {
  setError("Resource not found.");
  return;
}
```

## Lookups with `Array.find()`

`Array.find()` always types its result as `T | undefined`, even in strict mode, because nothing guarantees a match exists. Don't paper over this with `?.` / `??` fallbacks when a missing match actually means corrupted/inconsistent data (e.g. looking up a related record that should always exist) — that silently hides a bug instead of surfacing it.

- Isolate the lookup in its own function
- If no match should ever be possible given valid data, throw inside that function instead of returning `undefined`
- This narrows the return type to `T` for callers, removing the need for `?.` everywhere downstream

```ts
function findLessonTranslation(translationPack: TranslationPack, lessonId: LessonId): LessonTranslation {
  const lessonTranslation = translationPack.lessons.find((l) => l.id === lessonId);
  if (!lessonTranslation) {
    throw new Error(`Missing translation for lesson ${lessonId}`);
  }
  return lessonTranslation;
}
```

Only keep a silent fallback (`?? defaultValue`) when the absence of a match is an expected, normal case — not a sign of a data bug.

## Empty select (dropdown)

When a `<select>` may be empty due to missing data, do not display an empty select. Instead:

- Show an explanatory message: *"You don't have any [resource] yet."*
- If possible, offer a link or button to navigate to where one can be created
- Disable the form submit button while no value is available

See [[react]] for the React implementation pattern.
