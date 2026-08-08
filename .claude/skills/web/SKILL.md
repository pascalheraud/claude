---
name: web
description: Generic public website conventions — sitemap maintenance. Load this skill whenever adding, removing, or renaming a publicly indexable page.
---

# Web Conventions

## Rule: keep the sitemap in sync

Every publicly indexable page must be listed in the site's `sitemap.xml` (or equivalent sitemap file/route).

- **Adding a page** → do not add it to the sitemap automatically. Ask the user whether the page should be indexed — not every new page is relevant for search engines (e.g. auth-gated, admin, internal tooling, or transient pages). Only add it once confirmed.
- **Removing a page** → remove its entry from the sitemap.
- **Renaming/moving a page's URL** → update the sitemap entry to the new URL.
- **Pages that must not be indexed** (auth-gated, admin, internal tooling) → do not add them to the sitemap; keep them out instead of relying on `robots.txt` alone.
- **Pages behind authentication** (logged-in area, account pages, dashboards) → never list in the sitemap, regardless of user confirmation — they are not publicly indexable content.

## Rule: every sitemap page needs description, keywords, and a canonical URL

Every page listed in the sitemap must have:

- A **meta description** — concise, specific to that page's content, not a generic site-wide fallback.
- **Keywords** relevant to the page's content (meta keywords and/or naturally reflected in the page's title/headings/copy).
- A **canonical URL** (`<link rel="canonical">`) pointing to the page's single authoritative URL, to avoid duplicate-content issues when a page is reachable via multiple paths or query parameters.

Do not add a page to the sitemap until these three are in place.

## Rule: robots.txt for pages excluded from the sitemap

A page absent from the sitemap is not automatically a `robots.txt` candidate — treat the two files
differently depending on **discoverability**, not just sitemap membership:

- **Publicly linked but not indexable** (e.g. an auth page like `/connexion` or `/inscription`,
  reachable from a public nav/link) → add a `Disallow` entry in `robots.txt`. Since the page is
  discoverable via normal crawling regardless of the sitemap, explicitly excluding it is what
  actually keeps it out of search results.
- **Authenticated/private area** (account pages, dashboards, anything behind login) → never list
  individual paths in `robots.txt` — enumerating them would expose the existence and structure of
  private routes to anyone reading the file. Block the whole area with a single prefix pattern
  instead (e.g. `Disallow: /compte/`), not one line per page.
- **Hidden/unlinked pages** (not linked from any public page, e.g. an internal tool or a page only
  reachable via a direct URL nobody publishes) → do not add them to `robots.txt` at all. They are
  already undiscoverable by crawling; listing them there would be the only thing revealing them.

**Any addition to `robots.txt` must be confirmed by the user first**, same as sitemap additions —
propose the entry and wait for confirmation before writing it.

## Rule: noindex and nofollow must match reality, in both directions

- Every **private/non-indexable page** must carry a `noindex` meta tag (or route-level equivalent) —
  and conversely, every page marked `noindex` must actually be private/non-indexable. Don't tag a
  public page `noindex` by mistake, and don't leave a private page without it.
- Every **link pointing to a non-indexed page** must carry `nofollow` — and conversely, a `nofollow`
  link should only ever point to a non-indexed page. Don't `nofollow` a link to a page that's actually
  meant to be indexed (it starves that page of crawl signal), and don't leave a link to a `noindex`
  page without `nofollow`.

In short: `noindex` ⇔ private page, and `nofollow` ⇔ link target is `noindex`. Check both directions
when adding a page or a link, not just the one that prompted the change.

To verify `noindex`/`nofollow`/link consistency, don't rely on reading source files page by page —
crawl a running instance of the site (local dev server or a deployed environment) and check the
actual rendered meta tags and links. This catches cases that static reading misses: tags injected at
runtime, layout-level links, or pages only reachable through client-side routing. A crawl also
surfaces `sitemap.xml`/`robots.txt` drift that's hard to spot by reading source: pages linked from
the site but missing from the sitemap or not excluded in `robots.txt`, and pages listed in
`sitemap.xml`/`robots.txt` that no longer exist or aren't actually reachable that way.

The sitemap is what search engines use to discover and re-crawl pages. A page that works but is missing from the sitemap can go unindexed indefinitely.
