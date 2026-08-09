---
name: routing
description: React Router v6 conventions — route definition, Link vs useNavigate, Back button rules (replace/navigate(-1)), modals without routes, protected routes, scroll restoration
---

# React Routing — Skill

## Purpose

This skill defines how to implement routing in a React + TypeScript application using **React Router v6**, with correct handling of the browser Back button and deep linking.

---

## Setup

```bash
npm install react-router-dom
```

```tsx
// main.tsx
import { BrowserRouter } from 'react-router-dom';

createRoot(document.getElementById('root')!).render(
  <BrowserRouter>
    <App />
  </BrowserRouter>
);
```

Use `BrowserRouter` for web apps. Use `MemoryRouter` for Capacitor / React Native (no real URL bar).

```tsx
// main.tsx — Capacitor / mobile
import { MemoryRouter } from 'react-router-dom';

createRoot(document.getElementById('root')!).render(
  <MemoryRouter>
    <App />
  </MemoryRouter>
);
```

---

## Route definition

Define every route path as a typed constant in a dedicated `routes.ts`. Never hardcode a path string in a component — both `<Route path>` declarations and every `navigate(...)` / `<Link to>` call read from this one file.

```ts
// routes.ts
export const ROUTES = {
  dashboard:       '/',
  shop:            '/shop',
  cart:            '/cart',
  checkout:        '/checkout',
  account:         '/account',
  accountSettings: '/account/settings',
} as const;

/** Static (parameter-free) route paths */
export type StaticRoute = typeof ROUTES[keyof typeof ROUTES];

/**
 * Builders for routes that take a param. Each return type is a template
 * literal type, not `string` — this is what lets `AppRoute` (below) reject
 * arbitrary strings while still accepting the built path.
 */
export const buildRoute = {
  product: (id: string): `/shop/${string}` => `/shop/${id}`,
} as const;

type BuiltRoute = ReturnType<typeof buildRoute[keyof typeof buildRoute]>;

/** Every path the app can navigate to — static or built */
export type AppRoute = StaticRoute | BuiltRoute;
```

```tsx
// App.tsx
import { Routes, Route, Navigate } from 'react-router-dom';
import { ROUTES } from './routes';

export function App() {
  return (
    <Routes>
      <Route path={ROUTES.dashboard}        element={<DashboardScreen />} />
      <Route path={ROUTES.shop}             element={<ShopScreen />} />
      <Route path="/shop/:productId"        element={<ProductScreen />} />
      <Route path={ROUTES.cart}             element={<CartScreen />} />
      <Route path={ROUTES.checkout}         element={<CheckoutScreen />} />
      <Route path={ROUTES.account}          element={<AccountScreen />} />
      <Route path={ROUTES.accountSettings}  element={<SettingsScreen />} />
      <Route path="*"                       element={<Navigate to={ROUTES.dashboard} replace />} />
    </Routes>
  );
}
```

Dynamic segments (`:productId`) still have to be written as a literal in `<Route path>` — React Router needs the pattern, not a value. `ROUTES`/`buildRoute` exist so every *consumer* of a route (links, navigation, redirects) goes through one typed surface instead of retyping `/shop/${id}` everywhere.

---

## Navigation

### A typed `navigate` — `useAppNavigate`

Wrap `useNavigate` so it only accepts an `AppRoute`. A typo or a route that was renamed in `routes.ts` becomes a compile error instead of a silent dead link.

```ts
// useAppNavigate.ts
import { useNavigate, type NavigateOptions } from 'react-router-dom';
import type { AppRoute } from './routes';

export interface AppNavigate {
  (to: AppRoute, options?: NavigateOptions): void;
  (delta: number): void; // history.go(delta) — e.g. navigate(-1) for Back
}

export function useAppNavigate(): AppNavigate {
  const navigate = useNavigate();
  return navigate as AppNavigate;
}
```

```tsx
// ✅ only known routes type-check
const navigate = useAppNavigate();
navigate(ROUTES.cart);
navigate(buildRoute.product(product.id));
navigate(-1); // Back button — see Rule 2 below

// ❌ compile error — not an AppRoute
navigate('/shop/' + product.id);
navigate('/shpo');
```

The two call signatures on `AppNavigate` mirror React Router's own overloaded `NavigateFunction` type, so `navigate(-1)` still type-checks while `navigate('/shpo')` does not. Use this hook everywhere instead of importing `useNavigate` from `react-router-dom` directly.

### Declarative — `<Link>`

Use `<Link>` for navigation that the user triggers explicitly (menu items, product tiles). Same rule applies: pass a `ROUTES`/`buildRoute` value, not a hand-typed string.

```tsx
import { Link } from 'react-router-dom';
import { ROUTES, buildRoute } from './routes';

<Link to={ROUTES.shop}>Shop</Link>
<Link to={buildRoute.product(product.id)}>{product.name}</Link>
```

### Programmatic — `useAppNavigate`

Use it for navigation triggered by code (after form submit, after async action).

```tsx
import { useAppNavigate } from './useAppNavigate';
import { ROUTES } from './routes';

export function CheckoutScreen() {
  const navigate = useAppNavigate();

  async function handleSubmit() {
    await orderService.place(cart);
    navigate(ROUTES.checkout, { replace: true }); // adjust to the real confirmation route
  }
}
```

---

## Back button — the key rules

### Rule 1 — Use `replace` when going back would be wrong

After a form submit, payment, or destructive action, use `replace: true` so the user cannot go back to the completed step.

```tsx
// ✅ after checkout — no back to the payment form
navigate('/confirmation', { replace: true });

// ✅ after login — no back to the login page
navigate('/dashboard', { replace: true });

// ❌ default push — user can go back to the payment form and re-submit
navigate('/confirmation');
```

### Rule 2 — Use `navigate(-1)` for explicit back buttons

Do not hardcode the parent route.

```tsx
// ✅ goes back to wherever the user came from
<button onClick={() => navigate(-1)}>← Back</button>

// ❌ hardcoded — breaks if the user arrived from a different route
<button onClick={() => navigate('/shop')}>← Back</button>
```

### Rule 3 — Use `<Link>` not `onClick + navigate` for normal links

`<Link>` supports middle-click, CMD+click (open in new tab), and correct history behaviour automatically.

```tsx
// ✅
<Link to={`/shop/${id}`}>View product</Link>

// ❌ breaks CMD+click and middle-click
<div onClick={() => navigate(`/shop/${id}`)}>View product</div>
```

### Rule 4 — Modals and sheets do not push a route

Overlays that are part of the same screen manage their state with `useState`.

```tsx
// ✅ modal state — no route push
const [isFilterOpen, setIsFilterOpen] = useState(false);

<FilterSheet open={isFilterOpen} onClose={() => setIsFilterOpen(false)} />
```

Exception: if the modal has its own shareable URL, give it a route.

### Rule 5 — Confirmation steps get their own route

Multi-step flows give each step its own route so Back works naturally.

```
/checkout/cart        ← step 1
/checkout/shipping    ← step 2
/checkout/payment     ← step 3
/checkout/confirm     ← step 4 (replace on submit → /order-confirmation)
```

```tsx
<Route path="/checkout">
  <Route index                 element={<Navigate to="cart" replace />} />
  <Route path="cart"           element={<CartStep />} />
  <Route path="shipping"       element={<ShippingStep />} />
  <Route path="payment"        element={<PaymentStep />} />
  <Route path="confirm"        element={<ConfirmStep />} />
</Route>
```

---

## Reading route params and query strings

```tsx
import { useParams, useSearchParams } from 'react-router-dom';

// Route: /shop/:productId
export function ProductScreen() {
  const { productId } = useParams<{ productId: string }>();
  …
}

// Route: /shop?category=shoes&sort=price
export function ShopScreen() {
  const [searchParams, setSearchParams] = useSearchParams();
  const category = searchParams.get('category') ?? 'all';
  const sort     = searchParams.get('sort') ?? 'relevance';

  function handleSortChange(newSort: string) {
    setSearchParams({ category, sort: newSort });
  }
}
```

---

## Preserving state across navigation

### Option 1 — URL as the source of truth

Store filters, pagination, and search terms in the URL (query params). State is automatically restored when the user goes Back.

### Option 2 — `useLocation` state

Pass lightweight state through the history entry. Survives Back within the session but not a page refresh.

```tsx
// Pushing state
navigate('/product/p1', { state: { fromCategory: 'shoes' } });

// Reading state
const location = useLocation();
const { fromCategory } = (location.state as { fromCategory?: string }) ?? {};
```

### Option 3 — Global state (Context or service)

For state that must survive across many navigations, store it in a Context or a service singleton.

---

## Nested routes and shared layouts

```tsx
// App.tsx
<Route path="/account" element={<AccountLayout />}>
  <Route index            element={<ProfileScreen />} />
  <Route path="settings"  element={<SettingsScreen />} />
  <Route path="orders"    element={<OrderHistoryScreen />} />
</Route>
```

```tsx
// AccountLayout.tsx
import { Outlet, NavLink } from 'react-router-dom';

export function AccountLayout() {
  return (
    <div>
      <nav>
        <NavLink to="/account">Profile</NavLink>
        <NavLink to="/account/settings">Settings</NavLink>
        <NavLink to="/account/orders">Orders</NavLink>
      </nav>
      <Outlet />
    </div>
  );
}
```

---

## Protected routes

```tsx
// components/RequireAuth.tsx
import { Navigate, useLocation } from 'react-router-dom';

export function RequireAuth({ children }: { children: React.ReactNode }) {
  const { user } = useUser();
  const location = useLocation();

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
```

```tsx
// LoginScreen.tsx — redirect back after login
const location = useLocation();
const from     = (location.state as { from?: Location })?.from?.pathname ?? '/';

async function handleLogin() {
  await authService.login(credentials);
  navigate(from, { replace: true });
}
```

---

## Scroll restoration

```tsx
// components/ScrollToTop.tsx
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

export function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}
```

```tsx
// App.tsx
<BrowserRouter>
  <ScrollToTop />
  <Routes> … </Routes>
</BrowserRouter>
```

---

## Quick reference

| Situation | Solution |
|-----------|---------|
| Route paths | Typed constants in `routes.ts` (`ROUTES`, `buildRoute`) — never a hand-typed string |
| Normal link (menu, card) | `<Link to={ROUTES.x}>` |
| Navigate after async action | `useAppNavigate()` + `navigate(ROUTES.x)` |
| Navigate without adding history | `navigate(ROUTES.x, { replace: true })` |
| Back button | `navigate(-1)` (plain `useNavigate`, not `useAppNavigate`) |
| Read URL param (`:id`) | `useParams()` |
| Read/write query string | `useSearchParams()` |
| Pass state through navigation | `navigate('…', { state: { … } })` |
| Shared layout for child routes | Nested routes + `<Outlet />` |
| Guard a route | `<RequireAuth>` wrapper |
| Modal / sheet | `useState` — no route |
| Multi-step flow | One route per step |
