---
name: frontend-react-routing
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

Define all routes in one place — `App.tsx` or a dedicated `routes.tsx`.

```tsx
// App.tsx
import { Routes, Route, Navigate } from 'react-router-dom';

export function App() {
  return (
    <Routes>
      <Route path="/"                  element={<DashboardScreen />} />
      <Route path="/shop"              element={<ShopScreen />} />
      <Route path="/shop/:productId"   element={<ProductScreen />} />
      <Route path="/cart"              element={<CartScreen />} />
      <Route path="/checkout"          element={<CheckoutScreen />} />
      <Route path="/account"           element={<AccountScreen />} />
      <Route path="/account/settings"  element={<SettingsScreen />} />
      <Route path="*"                  element={<Navigate to="/" replace />} />
    </Routes>
  );
}
```

---

## Navigation

### Declarative — `<Link>`

Use `<Link>` for navigation that the user triggers explicitly (menu items, product tiles).

```tsx
import { Link } from 'react-router-dom';

<Link to="/shop">Shop</Link>
<Link to={`/shop/${product.id}`}>{product.name}</Link>
```

### Programmatic — `useNavigate`

Use `useNavigate` for navigation triggered by code (after form submit, after async action).

```tsx
import { useNavigate } from 'react-router-dom';

export function CheckoutScreen() {
  const navigate = useNavigate();

  async function handleSubmit() {
    await orderService.place(cart);
    navigate('/order-confirmation', { replace: true });
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
| Normal link (menu, card) | `<Link to="…">` |
| Navigate after async action | `useNavigate` + `navigate('…')` |
| Navigate without adding history | `navigate('…', { replace: true })` |
| Back button | `navigate(-1)` |
| Read URL param (`:id`) | `useParams()` |
| Read/write query string | `useSearchParams()` |
| Pass state through navigation | `navigate('…', { state: { … } })` |
| Shared layout for child routes | Nested routes + `<Outlet />` |
| Guard a route | `<RequireAuth>` wrapper |
| Modal / sheet | `useState` — no route |
| Multi-step flow | One route per step |
