---
name: frontend-js
description: Generic JS/TS frontend conventions — model types, API error handling (500/404/403), empty select handling
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

See `frontend-react` for the React implementation pattern.

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

## Empty select (dropdown)

When a `<select>` may be empty due to missing data, do not display an empty select. Instead:

- Show an explanatory message: *"You don't have any [resource] yet."*
- If possible, offer a link or button to navigate to where one can be created
- Disable the form submit button while no value is available

See `frontend-react` for the React implementation pattern.
