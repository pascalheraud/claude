---
name: emails
description: Conventions for links inside transactional/plain-text emails
---

# Emails — link conventions

Applies to any outbound transactional email (confirmation, notification, alert, newsletter, ...)
that includes a link back to the app.

## Link format

- **No GET query parameters, no spaces in the URL.** Prefer the identifier as a path segment over a
  query string.
  - ✅ `https://myapp.example/account/saved-searches/4145415614651465`
  - ❌ `https://myapp.example/account/saved-searches?id=4145415614651465`

  Query strings are a common source of broken links in plain-text emails: some clients (or a user
  manually copy-pasting the URL) truncate or mangle the `?`/`&`/`=` characters, and line-wrapping in a
  plain-text body can split a query string across lines. A path segment is copy-paste-safe and wraps
  more predictably.

## Link placement in the template

Always put the link **alone on its own line**, preceded and followed by a blank line:

```
Here are your results:

{{{link}}}

Best,
```

This isolates the URL from surrounding punctuation/text that some email clients or plain-text
renderers would otherwise glue onto the link (trailing comma, colon, or the next sentence), breaking
the clickable link or its target.

Note: if the templating engine HTML-escapes by default (e.g. Handlebars), use the raw/unescaped
variant (`{{{link}}}` rather than `{{link}}`) so query-string-free path segments and any special
characters in the URL aren't mangled.

## Route paths as named constants

Never inline the frontend route path as a string literal at the call site that builds the link
(`externalUrlHelper.get("/account/saved-searches/" + id)`). Centralize each linked route's path in a
single named constant (a small `FrontendRoutes`-style holder class, or equivalent for the stack in
use), and reference that constant everywhere a link to that route is built:

```java
externalUrlHelper.get(FrontendRoutes.SAVED_SEARCHES + id);
```

This keeps every backend reference to a given frontend route in one place — a route rename is a
one-line change instead of a grep-and-replace across every email class that happens to link there,
and it removes the risk of two call sites drifting to slightly different path strings for the same
route.
