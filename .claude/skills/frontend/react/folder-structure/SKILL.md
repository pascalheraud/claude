---
name: folder-structure
description: React project folder structure — ui/, features/, services/, hooks/, contexts/, models.ts, barrel files, import aliases, and dependency rules between layers
---

# React Project Folder Structure — Skill

## Purpose

This skill defines how to organise files and folders in a React + TypeScript project. It applies regardless of the application domain.

---

## Top-level structure

```
src/
  models.ts         ← All shared TypeScript types (single file until ~500 lines)
  App.tsx           ← Root component and screen router

  ui/               ← Generic design system — no domain knowledge
  features/         ← Domain-specific components, one folder per feature
  services/         ← Pure TypeScript business logic — no React
  hooks/            ← React hooks for side effects only
  contexts/         ← React Contexts for global state
  constants/        ← Shared constant values
  utils/            ← Pure utility functions (formatting, maths, strings)
```

---

## ui/ — Design system

Contains generic, reusable components with no application domain knowledge.

```
ui/
  atoms/        ← smallest elements: Button, Badge, Icon, Spinner…
  molecules/    ← composed patterns: Modal, Toast, SelectGrid…
  organisms/    ← page-level structures: Card, PageWrapper, EmptyState…
  index.ts      ← re-exports everything
```

**Rule:** nothing in `ui/` may import from `models.ts`, `services/`, `hooks/`, or `features/`.

---

## features/ — Domain components

One folder per feature domain. Each folder is self-contained.

```
features/
  auth/
    LoginScreen.tsx
    LoginForm.tsx
    index.ts
  shop/
    ProductCard.tsx
    CartScreen.tsx
    CheckoutScreen.tsx
    index.ts
  account/
    ProfileScreen.tsx
    PreferenceItem.tsx
    index.ts
```

**Rules:**
- Each folder has an `index.ts` barrel
- Feature folders do not import from each other (shared logic goes in `services/`)
- A Screen component is the entry point of a feature — it owns the page-level state

---

## services/ — Pure logic

Plain TypeScript modules. No React, no side effects beyond their explicit purpose.

```
services/
  StorageService.ts  ← localStorage / IndexedDB CRUD
  ApiService.ts      ← network fetch helpers
  CartService.ts     ← cart business rules
  OrderService.ts    ← order business rules
```

Services may import from `models.ts` and `constants/` only.

---

## hooks/ — Shared side effects only

Custom hooks are **not the default**. Most logic goes directly into components (via injected services) or into services. Write a hook only when a side effect involving `useEffect`, `useRef` or a browser subscription is needed in **more than one component**.

```
hooks/
  useOnlineStatus.ts    ← browser online/offline event listener with cleanup
  useToast.ts           ← accessor for the global ToastContext
  useFileUpload.ts      ← async upload with progress state, reused across screens
  index.ts
```

A hook is justified when **all three** are true:
1. It involves `useEffect`, `useRef`, or a browser event subscription
2. The same effect is needed in more than one component
3. It cannot be replaced by a simple service method call in each component

**What does NOT belong in a hook:**
- A single service method call (`storage.get(...)`) → call it directly in the component
- Business logic → belongs in a service class
- A service instance → inject it via prop instead

---

## contexts/ — Global state

React Contexts for state that is needed across many components.

```
contexts/
  ThemeContext.tsx
  UserContext.tsx
  ToastContext.tsx
  CartContext.tsx
  index.ts
```

Each context file exports:
1. The context object (internal use)
2. A Provider component
3. A typed accessor hook (`useUser`, `useTheme`…)

---

## constants/ — Shared values

Typed constants used across multiple files.

```
constants/
  config.ts      ← API base URL, feature flags
  limits.ts      ← MAX_RETRIES, TIMEOUT_MS, MAX_CART_ITEMS…
  index.ts
```

Use `as const` for object constants:

```ts
export const Limits = {
  MAX_RETRIES: 3,
  TIMEOUT_MS:  5000,
} as const;
```

**Rule: a constant belongs in `constants/` only if more than one file consumes it.** A constant (or static data array) read by a single service/context/component should live next to that consumer instead — either as a module-level `const` above the class, or as a private field — not in a separate `constants/` file nobody else imports.

```ts
// ❌ separate file, only one consumer
// constants/langs.ts
export const LANGUAGES: Language[] = [ /* … */ ];

// services/LangsService.ts
import { LANGUAGES } from '@constants/langs';
export class LangsService { /* uses LANGUAGES */ }

// ✅ co-located — nothing else needs to import it separately
// services/LangsService.ts
const LANGUAGES: Language[] = [ /* … */ ];
export class LangsService { /* uses LANGUAGES */ }
```

If a second consumer shows up later, promote it to `constants/` at that point — don't pre-extract for a hypothetical future reuse.

---

## utils/ — Utility functions

Pure functions that are generic enough to be used anywhere.

```
utils/
  format.ts      ← date, currency, string formatting
  math.ts        ← rounding, clamping, percentage
  array.ts       ← chunk, unique, groupBy
  index.ts
```

If a utility is only used in one feature, keep it in that feature's folder instead.

---

## models.ts — Shared types

All shared TypeScript types in a single file. Import from it with `@/models`.

```ts
// models.ts
export type UserId    = string;
export type ProductId = string;

export interface User    { id: UserId; name: string; email: string; }
export interface Product { id: ProductId; name: string; price: number; }
export interface Cart    { items: CartItem[]; }
export interface CartItem { id: ProductId; qty: number; price: number; }
```

Split into multiple files only when the file exceeds ~500 lines.

---

## Naming conventions

| Element | Convention | Extension |
|---------|-----------|-----------|
| Component | PascalCase | `.tsx` |
| Hook | camelCase, `use` prefix | `.ts` |
| Service | camelCase | `.ts` |
| Context | PascalCase, `Context` suffix | `.tsx` |
| Unit test | same name, `.test` suffix | `.ts` |
| Component test | same name, `.test` suffix | `.tsx` |
| Barrel | `index` | `.ts` |
| Feature folder | kebab-case | — |
| Constant | SCREAMING_SNAKE_CASE | — |

---

## Import aliases

Configure path aliases in `vite.config.ts` and `tsconfig.json` to avoid `../../../` chains.

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  resolve: {
    alias: {
      '@':          path.resolve(__dirname, 'src'),
      '@ui':        path.resolve(__dirname, 'src/ui'),
      '@features':  path.resolve(__dirname, 'src/features'),
      '@services':  path.resolve(__dirname, 'src/services'),
      '@hooks':     path.resolve(__dirname, 'src/hooks'),
      '@contexts':  path.resolve(__dirname, 'src/contexts'),
      '@constants': path.resolve(__dirname, 'src/constants'),
      '@utils':     path.resolve(__dirname, 'src/utils'),
    }
  }
});
```

```ts
// Usage
import { Button }          from '@ui/atoms';
import { DashboardScreen } from '@features/dashboard';
import { computeScore }    from '@services/game';
import { useToast }        from '@hooks';
import type { User }       from '@/models';
```

---

## Barrel files

Each folder with more than one exported file has a barrel `index.ts`. **Barrels are written and maintained by hand** — no auto-generation plugin.

```ts
// features/dashboard/index.ts
export { DashboardScreen } from './DashboardScreen';
export { SummaryCard }     from './SummaryCard';
```

```ts
// services/index.ts  ← composition root: instantiates and exports all singletons
export { CartService,    cartService }    from './CartService';
export { OrderService,   orderService }   from './OrderService';
export { StorageService, storageService } from './StorageService';
export { ApiService,     apiService }     from './ApiService';
```

Import from the barrel, not from individual files:

```ts
// ✅ import from barrel
import { DashboardScreen }          from '@features/dashboard';
import { cartService, CartService } from '@services';
import { Button, Badge }            from '@ui/atoms';

// ❌ bypasses the barrel
import { DashboardScreen } from '@features/dashboard/DashboardScreen';
import { CartService }     from '@services/CartService';
```

**Rules for maintaining barrels:**
- Add an export line every time you create a new file in the folder
- Remove the export line when you delete a file
- Never re-export from a barrel into another barrel (no chained re-exports)
- `services/index.ts` is also the **composition root** — the only place that instantiates service classes

---

## Test file placement

Tests live next to the files they test. No separate `__tests__` folder.

```
services/
  game.ts
  game.test.ts

features/shop/
  CartScreen.tsx
  CartScreen.test.tsx
  ProductCard.tsx
  ProductCard.test.tsx
```

---

## Dependency rules (import direction)

```
ui/          → no imports from the rest of the project
features/    → may import from ui/, services/, hooks/, contexts/, models.ts
services/    → may import from models.ts and constants/ only
hooks/       → may import from services/, models.ts, constants/
contexts/    → may import from services/, hooks/, models.ts
utils/       → no imports from the rest of the project (except models.ts if needed)
```

Circular imports are forbidden. If two features need to share logic, move it to `services/`.
