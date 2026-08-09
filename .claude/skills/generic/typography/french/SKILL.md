---
name: french
description: French typography rules for i18n translation strings — non-breaking spaces before punctuation and inside guillemets. Load this skill whenever writing or reviewing French (`fr`) translation strings in a multilingual app. See [[typography]] for other locales and [[frontend/react/french-typography]] for JSX text nodes specifically.
---

# French Typography in i18n Strings

## Rule: non-breaking space before certain punctuation

In French (`fr`) entries only, use a non-breaking space (U+00A0) — not a regular space — before `:`, `;`, `!`, `?`, and on both sides inside French guillemets (`« … »`).

This is standard French typographic convention and prevents the punctuation mark from wrapping onto its own line.

**Applies only to `fr` entries** in a multilingual i18n file.

## How to write it in an i18n string file

Use the literal ` ` character (U+00A0), not an HTML entity — a translation string isn't rendered through an HTML/JSX parser, so an entity like `&nbsp;` would show up as literal text instead of a space.

```ts
// i18n service / translation file — literal non-breaking space
fr: {
  confirmDelete: "Supprimer ?",
  score: "Score : 10",
  quote: "« Bonjour »",
}
```

## What to check when reviewing French strings

- Every `?`, `!`, `:`, `;` preceded by a regular space → replace with non-breaking space
- Every `«` not followed by non-breaking space → add it
- Every `»` not preceded by non-breaking space → add it

If the string is rendered as JSX text rather than read from a translation file directly, see [[frontend/react/french-typography]] for how the same rule is expressed there.
