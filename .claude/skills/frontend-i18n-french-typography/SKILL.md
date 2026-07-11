---
name: frontend-i18n-french-typography
description: French typography rules for i18n UI strings and JSX text — non-breaking spaces before punctuation and inside guillemets. Load this skill whenever writing or reviewing French (`fr`) translation strings or JSX text in a multilingual app.
---

# French Typography in i18n Strings and JSX

## Rule: non-breaking space before certain punctuation

In French (`fr`) entries only, use a non-breaking space (U+00A0) — not a regular space — before `:`, `;`, `!`, `?`, and on both sides inside French guillemets (`« … »`).

This is standard French typographic convention and prevents the punctuation mark from wrapping onto its own line.

**Applies only to `fr` entries.** Other languages (`en`, `es`, `de`, `it`, `pt`, `ro`, …) use a regular space — do not apply this rule to them.

## How to write it

| Context | How |
|---|---|
| String value in a `.ts` / `.json` i18n file | Literal ` ` character (U+00A0), not an HTML entity |
| JSX text node | `&nbsp;` HTML entity |

Examples:

```ts
// i18n service / translation file — literal non-breaking space
fr: {
  confirmDelete: "Supprimer ?",
  score: "Score : 10",
  quote: "« Bonjour »",
}
```

```tsx
// JSX text — use &nbsp;
<p>Supprimer&nbsp;?</p>
<p>Score&nbsp;: 10</p>
<p>«&nbsp;Bonjour&nbsp;»</p>
```

## What to check when reviewing French strings

- Every `?`, `!`, `:`, `;` preceded by a regular space → replace with non-breaking space
- Every `«` not followed by non-breaking space → add it
- Every `»` not preceded by non-breaking space → add it
- None of the above in non-`fr` locales → leave as regular space
