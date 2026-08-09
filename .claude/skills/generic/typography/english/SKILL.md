---
name: english
description: English typography rules for i18n translation strings — regular space before punctuation, straight quotes, dash usage. Load this skill whenever writing or reviewing English (`en`) translation strings in a multilingual app. See [[typography]] for other locales.
---

# English Typography in i18n Strings

## Rule: regular space before punctuation

Use a plain regular space before `:`, `;`, `!`, and `?` — exactly as it
would be written outside of code.

```ts
en: {
  confirmDelete: "Delete?",
  score: "Score: 10",
}
```

## Quotes: straight double quotes

English UI text uses straight double quotes (`"…"`), not curly/smart quotes
(`"…"`) unless the project has an explicit house style calling for
typographic quotes.

```ts
en: {
  quote: "Hello",
}
```

## Dashes: hyphen for compounds, em dash for a break in thought

- Hyphen (`-`) for compound words and ranges written with no surrounding
  spaces (`well-known`, `10-20`).
- Em dash (`—`) for a parenthetical break in a sentence, with no surrounding
  spaces (`the result — unexpected — was logged`).

## What to check when reviewing English strings

- Every `?`, `!`, `:`, `;` preceded by anything other than a regular space → fix it
- Any curly/smart quote where the project's house style calls for straight quotes → replace it
- A hyphen surrounded by spaces standing in for an em dash → replace with `—`
