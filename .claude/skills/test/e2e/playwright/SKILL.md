---
name: playwright
description: Playwright browser-automation conventions, tied to no language binding — Browser/BrowserContext/Page lifecycle, PageObjects holding a Page not a Browser. Load this alongside [[test/e2e]] whenever the E2E stack uses Playwright, regardless of language. For a specific language binding (Java, TypeScript, ...), see that language's own Playwright skill if one exists.
---

# Playwright (generic)

Builds on [[test/e2e]] — read that one first for the scenario/PageObject/mocking
conventions this skill assumes. This skill only covers what's specific to
using **Playwright** as the browser-automation library, independent of which
language binding (Java, Node/TypeScript, Python, .NET) a project uses.

## Instance lifecycle: one Browser per run, one Context/Page per test

- **One shared `Playwright`/`Browser` instance for the whole test run** — launching a browser is expensive, and nothing about isolation requires a fresh one per test.
- **A fresh `BrowserContext` (and `Page` within it) per test** — a `BrowserContext` is Playwright's isolation boundary for cookies, local/session storage, and navigation state. Reusing a `Browser` across tests is safe and fast; reusing a `BrowserContext` is not, since it lets one test's login session or storage state leak into the next.

This two-level split (expensive, shared `Browser`; cheap, per-test `BrowserContext`) is what makes a Playwright E2E suite both fast to start and isolated per test, without needing a fresh browser process per scenario.

## PageObjects hold a `Page`, never a `Browser` or `BrowserContext`

A PageObject (see [[test/e2e]]'s PageObject pattern) only ever needs element-level access and navigation *within* a given page — that's everything a `Page` handle exposes. Holding a `Browser` or `BrowserContext` reference instead would let a PageObject reach outside its own page (open new tabs, touch other contexts), which isn't what a PageObject is for and makes it harder to reason about what a given PageObject can affect.

```java
// Java binding shown as an example — the shape is the same in any language binding
class LoginPage {
    private final Page page; // not Browser, not BrowserContext
    private LoginPage(Page page) { this.page = page; }

    static LoginPage open(Page page, String url) {
        page.navigate(url);
        return new LoginPage(page);
    }
}
```

## Project-specific usage

A project skill using Playwright should document:
- Which language binding is used, and that language's own Playwright skill if one exists (e.g. a Java-specific skill covering JUnit integration, Testcontainers wiring).
- Where the shared `Browser` is created/torn down (test run setup) and where the per-test `BrowserContext`/`Page` is created.
- Any non-default browser launch config (headless/headed, viewport, permissions, tracing/video capture for CI failures).
