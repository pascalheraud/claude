---
name: french-typography
description: French typography rules for JSX text nodes — non-breaking spaces before punctuation and inside guillemets, written as `&nbsp;`. Load this skill whenever writing or reviewing French (`fr`) JSX text in a React app. For the underlying rule and i18n translation-file strings, see [[french]].
---

# French Typography in JSX

Builds on [[french]] — read that one first for the
rule itself (non-breaking space before `: ; ! ?` and inside `« »`, `fr`
locale only). This skill only covers the JSX-specific detail: how to write
that same non-breaking space in a JSX text node.

## How to write it

A JSX text node is HTML, not a plain string — use the `&nbsp;` HTML entity,
not a literal U+00A0 character (invisible in source, easy to mistake for a
regular space in a diff or accidentally strip via formatting).

```tsx
<p>Supprimer&nbsp;?</p>
<p>Score&nbsp;: 10</p>
<p>«&nbsp;Bonjour&nbsp;»</p>
```

**A translated string coming from an i18n string file already has the
correct literal non-breaking space baked in** (see [[french]]) —
don't re-wrap it in `&nbsp;` when interpolating it into JSX (`{t('confirmDelete')}`
renders the string's own U+00A0 as-is). The `&nbsp;` entity is only for
French text written directly as a JSX literal, not routed through the i18n
layer.

## What to check when reviewing French JSX

- Every `?`, `!`, `:`, `;` in a JSX text literal preceded by a regular space → replace with `&nbsp;`
- Every `«` in a JSX text literal not followed by `&nbsp;` → add it
- Every `»` in a JSX text literal not preceded by `&nbsp;` → add it
- A string interpolated from the i18n layer (`t('key')`) → no `&nbsp;` needed in the JSX itself, the rule is already applied in the translation file
