---
name: typography
description: Locale-specific typography rules for i18n strings and JSX text — spacing before punctuation, quote marks, dashes. This skill only points to the per-language skill; load [[french]] or [[english]] (add others as they're written) for the actual rules, matching the locale of the text being written or reviewed.
---

# Typography (i18n)

Typographic conventions — spacing before punctuation, which quote marks to
use, dash usage — are **locale-specific**, not universal. A rule correct for
one language's entries is often wrong for another's in the exact same i18n
file. Never apply one locale's convention to a different locale's entries.

## Load the skill matching the locale you're touching

| Locale | Skill |
|---|---|
| `fr` | [[french]] |
| `en` | [[english]] |

Add a new per-language skill under `generic/typography/<language>/` when a
project needs a locale not yet covered here — don't fold a second language's
rules into an existing one's skill file, even if the rules happen to be
similar (e.g. `en` and other Latin-script languages sharing "no
non-breaking space" doesn't mean they share every rule; keep the file split
per language so each can diverge independently later).

## Framework-specific detail lives one level down

A per-language skill documents the rule itself, generally in terms of an
i18n string file. Where the rule's *encoding* differs by rendering context
(e.g. a literal U+00A0 character in a translation string vs. an `&nbsp;`
HTML entity in JSX) that split lives as a further child skill next to the
language skill — see [[frontend/react/french-typography]] for the JSX-specific
half of [[french]], as an example of the pattern to follow for another
language/framework combination.
