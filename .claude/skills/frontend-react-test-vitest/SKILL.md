---
name: frontend-react-test-vitest
description: Vitest unit-testing conventions for React + TypeScript projects — config setup, jsdom/globals gotchas, test scope (pure logic vs DOM vs IndexedDB), and test file structure
---

# React Testing with Vitest — Skill

## Setup

```bash
npm install -D vitest jsdom @testing-library/react @testing-library/jest-dom
```

`vite.config.ts` needs a `test` block:

```ts
test: {
  environment: 'jsdom',
  globals: true,
  setupFiles: ['./vitest.setup.ts'],
},
```

`vitest.setup.ts`:

```ts
import '@testing-library/jest-dom';
```

**Both `jsdom` and `globals: true` are required, and easy to silently omit:**
- Without the `jsdom` package installed, Vitest fails at startup with `Cannot find dependency 'jsdom'` even though `environment: 'jsdom'` is set in config — the config alone does not pull in the package.
- Without `globals: true`, `@testing-library/jest-dom`'s setup file throws `ReferenceError: expect is not defined`, because it extends the global `expect` instead of an imported one. Test files can still import `describe`/`it`/`expect` from `'vitest'` explicitly even with `globals: true` on — both styles work together.

## What to unit-test first

Prioritize **pure logic services** — no IndexedDB, no DOM, no network. They run instantly and need no mocking:
- Game/quiz scoring logic, pool/window advancement
- Pure helper methods on otherwise-async services (e.g. a `PlacementService` with both pure scoring methods and async IDB methods — test the pure ones directly, skip the async ones until IndexedDB is actually mocked)
- `localStorage`-backed services (jsdom implements `localStorage` natively, no extra setup)

**Do not** attempt to unit-test methods that hit `indexedDB` without first adding `fake-indexeddb` (or similar) as a dependency — jsdom does not implement IndexedDB, and tests will hang or throw confusingly without a clear signal that the dependency is missing.

### Testing IndexedDB-backed code with `fake-indexeddb`

```bash
npm install -D fake-indexeddb
```

Import the polyfill once at the top of the test file, before importing the code under test:

```ts
import 'fake-indexeddb/auto';
```

**Do not reset state between tests with `indexedDB.deleteDatabase()` if any connection from a prior test is still open.** A service that never calls `db.close()` (a common, reasonable choice for an app-lifetime singleton) leaves its connection open across tests. `deleteDatabase` then hangs indefinitely instead of firing `onblocked` — this reproduces with plain `fake-indexeddb` outside of Vitest too, it is not a Vitest/jsdom-specific issue. Symptom: `Hook timed out in 10000ms` on the *second* test in the file, not the first.

Use one shared, never-closed connection for the whole test file instead, and reset by clearing object stores:

```ts
const idb = new IdbService();        // opened once for the file
beforeEach(async () => {
  await idb.clearAll();              // clears every store, keeps the connection open
});
```

## Test file structure

One `*.test.ts` file colocated next to the service it tests (e.g. `GameService.ts` → `GameService.test.ts`). Group with `describe` per method, one `it` per behavior — name the `it` after the observable behavior, not the implementation:

```ts
describe('applyAnswer', () => {
  it('marks correct: true and increments score on the right target', () => { ... });
  it(`marks phraseDone once the score reaches WIN_TARGET (${WIN_TARGET})`, () => { ... });
});
```

Build minimal local fixtures (a `makePack()`/`makePhrases()` factory) rather than importing real fixture data — keeps tests independent of content changes.

## Testing components with React Testing Library

File: `*.test.tsx` colocated next to the component (e.g. `Badge.tsx` → `Badge.test.tsx`). One `describe` per component, one `it` per observable behavior (rendered text, presence/absence of an element, applied class, prop default).

```tsx
import { render, screen } from '@testing-library/react';
import { Badge } from './Badge';

describe('Badge', () => {
  it('renders the label', () => {
    render(<Badge label="New" />);
    expect(screen.getByText('New')).toBeInTheDocument();
  });
});
```

Query by what the user/DOM exposes (`getByText`, `getByRole`) rather than implementation details. For CSS-module class assertions, check `className` contains the expected token — CSS Modules hash class names, so exact-match assertions are brittle:

```ts
expect(screen.getByText('New').className).toContain('success');
```

Test presence/absence of conditionally-rendered markup (e.g. an optional icon) with `.queryBy*` or by asserting a child selector is `null`, not just the happy path.

Prioritize presentational/atom components (no services, no context, no routing) first — they need no mocking, same rationale as pure logic services above. Components wired to services/context/router need their dependencies stubbed or wrapped before they're worth testing; defer those until that pattern is established.
