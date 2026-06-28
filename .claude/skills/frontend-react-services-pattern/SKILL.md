---
name: frontend-react-services-pattern
description: React services pattern — separating business logic into injectable TypeScript service classes, composition root, singleton injection via props, reactive Store/KeyedStore for state shared across components (useSyncExternalStore), custom hooks decision flowchart
---

# React Services Pattern — Skill

## Purpose

This skill defines how to separate **business logic** from **React components** using TypeScript service classes. It applies to any React + TypeScript project.

---

## The core principle

```
Component     → what to show, when to show it, user interactions
Service       → how to compute it, what the rules are, how to transform data
Hook          → shared side effects only (browser events, subscriptions)
```

React components are responsible for **rendering UI and managing local display state**.
Business logic belongs in **injectable TypeScript service classes**.

---

## What is a service?

A service is a **TypeScript class** with no React dependency. It encapsulates business rules and is instantiated once (singleton) in the composition root.

```ts
// services/CartService.ts
export class CartService {
  add(cart: Cart, item: CartItem): Cart {
    const existing = cart.items.find(i => i.id === item.id);
    if (existing) {
      return { ...cart, items: cart.items.map(i => i.id === item.id ? { ...i, qty: i.qty + 1 } : i) };
    }
    return { ...cart, items: [...cart.items, { ...item, qty: 1 }] };
  }

  remove(cart: Cart, itemId: string): Cart {
    return { ...cart, items: cart.items.filter(i => i.id !== itemId) };
  }

  total(cart: Cart): number {
    return cart.items.reduce((sum, i) => sum + i.price * i.qty, 0);
  }

  isEmpty(cart: Cart): boolean {
    return cart.items.length === 0;
  }
}
```

Key properties:
- No `import from 'react'`
- No `useState`, `useEffect`, `useContext`
- Methods are pure where possible: same input → same output
- Effectful methods (storage, network) are clearly named and isolated

---

## Composition root

All service classes are instantiated **once** in `services/index.ts`. The exported singleton is named after its class, camelCased, with an `Instance` suffix — `CartService` → `cartServiceInstance`, `CartStore` → `cartStoreInstance`. The suffix isn't decorative: every component that injects a service also exposes a prop of the un-suffixed name (`cartService?: CartService`, see "Naming injected props" below), and a default-parameter value can't be the same identifier as what it defaults to — `cartServiceInstance` and `cartService` are different identifiers, so there is no collision anywhere, ever, without aliasing or renaming at the call site.

```ts
// services/index.ts
import { CartService }    from './CartService';
import { OrderService }   from './OrderService';
import { StorageService } from './StorageService';
import { ApiService }     from './ApiService';

export const storageServiceInstance = new StorageService();
export const apiServiceInstance     = new ApiService();
export const cartServiceInstance    = new CartService();
export const orderServiceInstance   = new OrderService(cartServiceInstance, apiServiceInstance);

export type { CartService }    from './CartService';
export type { OrderService }   from './OrderService';
export type { StorageService } from './StorageService';
```

Everything else imports from `@services` (the barrel) — never from individual service files.

```ts
// ✅ import from composition root
import { cartServiceInstance, type CartService } from '@services';

// ❌ bypass composition root — creates a second instance
import { CartService } from '@services/CartService';
const cartService = new CartService();
```

---

## The recommended pattern

Services are injected as props with the singleton as default. The component holds UI state and calls service methods in event handlers.

```tsx
// features/shop/CheckoutScreen.tsx
import { useState } from 'react';
import { cartServiceInstance, orderServiceInstance } from '@services';
import type { CartService, OrderService } from '@services';
import type { Cart } from '@/models';

interface CheckoutScreenProps {
  userId:        string;
  onDone:        () => void;
  cartService?:  CartService;
  orderService?: OrderService;
}

export function CheckoutScreen({
  userId,
  onDone,
  cartService  = cartServiceInstance,
  orderService = orderServiceInstance,
}: CheckoutScreenProps) {

  const [basket,     setBasket]     = useState<Cart>(() => cartService.load(userId));
  const [submitting, setSubmitting] = useState(false);
  const [error,      setError]      = useState<string | null>(null);

  function handleRemoveItem(itemId: string) {
    setBasket(cartService.remove(basket, itemId));
  }

  async function handleSubmit() {
    setSubmitting(true);
    setError(null);
    try {
      await orderService.place(basket, userId);
      cartService.clear(userId);
      onDone();
    } catch {
      setError('Order failed. Please try again.');
    } finally {
      setSubmitting(false);
    }
  }

  return ( … );
}
```

**What belongs where:**

| Responsibility | Location |
|---------------|----------|
| "Is the cart empty?" | `CartService.isEmpty()` |
| "What is the total?" | `CartService.total()` |
| "How do I place an order?" | `OrderService.place()` |
| "What is currently in the basket?" | `useState` in the component |
| "Should I show the loading spinner?" | `useState` in the component |
| "When should I submit?" | Event handler in the component |

---

## Naming injected props

The **prop key** of an injected service or store — what appears in the `interface` and what callers/tests pass — is always named after its class, camelCased, never a shortened domain word: `CartService` is injected as `cartService?: CartService`, never `cart?: CartService`; `CartStore` is injected as `cartStore?: CartStore`, never `cart?: CartStore`. Same logic for every class that gets injected, service or store alike. This is not situational — apply it even when only one object is injected and there's no ambiguity to resolve, so the type is legible from the prop name alone, in the interface, without opening the import.

```tsx
// ❌ shortened to the domain word — type isn't legible from the prop name
interface CheckoutScreenProps {
  cart?:   CartService;
  orders?: OrderService;
}

// ✅ named after the class
interface CheckoutScreenProps {
  cartService?:  CartService;
  orderService?: OrderService;
}
```

Inside the destructuring parameter, the prop key can't *also* be the local binding name when it defaults to the singleton import of the same name — `{ cartService = cartService }` throws (`Cannot access 'cartService' before initialization`), because the default-value expression resolves against the new binding being declared, not the `@services` import. Don't work around this by aliasing the singleton import (`import { cartService as cartServiceSingleton } from '@services'`) — that renames the singleton for no benefit and the alias inevitably drifts from the real name. Instead use destructuring's rename syntax: keep the prop key as the class-derived name, give the *local* binding any distinct, body-appropriate name, and default it to the plain unaliased import:

```tsx
// ✅ the pattern to use — see services/PacksService.ts consumers for a real example
import { packsService, type PacksService } from '@services';

interface LessonListProps {
  packsService?: PacksService;
}

export function LessonList({ packsService: packs = packsService }: LessonListProps) {
  packs.buildLessonSummaries(/* … */);
}
```

The prop key (`packsService`, matching the interface — the public API tests and callers see) stays the class-derived name; the local binding (`packs`) is whatever reads best in the function body; `= packsService` on the right unambiguously refers to the plain, unaliased import because the local binding has a different name.

---

## Service dependencies — constructor injection

When services depend on each other, inject via constructor. Wire everything in the composition root.

```ts
// services/OrderService.ts
export class OrderService {
  constructor(
    private readonly cartService: CartService,
    private readonly apiService:  ApiService,
  ) {}

  async place(cart: Cart, userId: string): Promise<Order> {
    const total = this.cartService.total(cart);
    return this.apiService.post('/orders', { cart, total, userId });
  }
}
```

---

## Testing

```tsx
// features/shop/CartScreen.test.tsx
const fakeCartService = {
  load:   vi.fn().mockReturnValue({ items: [] }),
  remove: vi.fn(),
  total:  vi.fn().mockReturnValue(0),
} as unknown as CartService;

it('renders empty cart', () => {
  render(<CartScreen userId="u1" cartService={fakeCartService} />);
  expect(screen.getByText('Your cart is empty')).toBeInTheDocument();
});
```

In production, `cartService` is not passed → singleton is used.
In tests, `cartService={fakeCartService}` is passed → no real storage or network is touched.

---

## Stores — when a service's state is read by more than one component

A service method like `cart.load(userId)` only returns a snapshot: if two sibling components each call it independently and hold the result in their own `useState`, they end up with two disconnected copies — one updates, the other goes stale. A **store** fixes this by holding the canonical in-memory value once, persisting through the service, and notifying every subscriber via React's built-in `useSyncExternalStore`.

**Rule of thumb:** stateless or single-reader logic stays a plain service (no store). Reach for a store only when the same persisted value must stay in sync across more than one component.

### `Store<T>` — single shared value

```ts
// services/Store.ts
export abstract class Store<T> {
  private value: T;
  private readonly listeners = new Set<() => void>();

  constructor(initial: T) {
    this.value = initial;
  }

  protected setValue(next: T): void {
    this.value = next;
    this.listeners.forEach((listener) => listener());
  }

  getSnapshot = (): T => this.value;

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };
}
```

```ts
// services/CartStore.ts
export class CartStore extends Store<Cart> {
  constructor(private readonly service: CartService, userId: string) {
    super(service.load(userId));
  }

  add = (item: CartItem): void => {
    this.setValue(this.service.add(this.getSnapshot(), item));
  };

  remove = (itemId: string): void => {
    this.setValue(this.service.remove(this.getSnapshot(), itemId));
  };
}
```

```tsx
// any component reading the cart — always in sync, no prop drilling
const cart = useSyncExternalStore(cartStore.subscribe, cartStore.getSnapshot);
```

### `KeyedStore<T>` — values keyed by id, loaded asynchronously

For state that is fetched per-key from an async source (a database, IndexedDB, an API) rather than available synchronously at construction time.

Do not model this with `T | undefined`: that single `undefined` is forced to mean two different things — "still loading" and "loaded, no data found" — and callers can't tell them apart (e.g. showing a skeleton vs. an empty state). Use an explicit `LoadState<T>` discriminated union instead:

```ts
// services/Store.ts (same file)
export type LoadState<T> =
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'loaded'; value: T };

export abstract class KeyedStore<T> {
  private values: Record<string, LoadState<T>> = {};
  private pending = new Map<string, Promise<void>>();
  private readonly listeners = new Set<() => void>();

  protected setValue(key: string, next: T | undefined): void {
    const state: LoadState<T> = next === undefined ? { status: 'empty' } : { status: 'loaded', value: next };
    this.values = { ...this.values, [key]: state };
    this.listeners.forEach((listener) => listener());
  }

  getSnapshot = (key: string): LoadState<T> => this.values[key] ?? { status: 'loading' };

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  protected ensureLoaded(key: string, loader: () => Promise<T | undefined>): void {
    if (key in this.values || this.pending.has(key)) return;
    const promise = loader().then((value) => {
      this.setValue(key, value);
      this.pending.delete(key);
    });
    this.pending.set(key, promise);
  }
}
```

```ts
// services/OrderStore.ts
export class OrderStore extends KeyedStore<Order> {
  constructor(private readonly service: OrderService) {
    super();
  }

  load = (orderId: string): void => {
    this.ensureLoaded(orderId, () => this.service.fetch(orderId));
  };

  save = async (orderId: string, order: Order): Promise<void> => {
    await this.service.save(orderId, order);
    this.setValue(orderId, order);
  };
}
```

```tsx
// component: trigger the load, then branch on the explicit status
useEffect(() => orderStore.load(orderId), [orderId]);
const orderState = useSyncExternalStore(orderStore.subscribe, () => orderStore.getSnapshot(orderId));

if (orderState.status === 'loading') return <Skeleton />;
if (orderState.status === 'empty') return <EmptyState />;
const order = orderState.value; // narrowed to T
```

Stores are wired into the composition root exactly like services, with the underlying service injected via the constructor:

```ts
// services/index.ts
export const cartService = new CartService();
export const cartStore   = new CartStore(cartService, currentUserId);

export const orderService = new OrderService();
export const orderStore   = new OrderStore(orderService);
```

---

## Context vs Service/Store

React Context (`createContext` / `useContext`) and the Service/Store pattern solve different problems — don't reach for a store when Context is the right tool, and vice versa.

| | Context | Store (`Store`/`KeyedStore`) |
|---|---|---|
| Backing | Lives only in React state | Backed by a `*Service` doing real I/O (storage, network) |
| Survives unmount of provider? | No — state is gone when the `<Provider>` unmounts | Yes — service/store are singletons outside React |
| Use for | Ephemeral UI state shared across the tree (toasts, theme, current-locale) | Persisted data shared across components (cart, user progress, auth session) |
| Read via | `useContext` | `useSyncExternalStore` |

**Context is correct** when the state only exists because a component is mounted, has no persistence layer underneath, and side effects like `setTimeout` belong directly in the provider's `useState`/`useCallback` — not delegated to a service:

```tsx
// contexts/ToastContext.tsx — ephemeral, no service underneath
const ToastContext = createContext<ToastContextValue>(/* … */);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const dismissToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const showToast = useCallback((message: string, type: ToastType = 'info') => {
    const id = crypto.randomUUID();
    setToasts((prev) => [...prev, { id, message, type }]);
    setTimeout(() => dismissToast(id), 3000);
  }, [dismissToast]);

  return (
    <ToastContext.Provider value={{ toasts, showToast, dismissToast }}>
      {children}
    </ToastContext.Provider>
  );
}

export function useToastContext() {
  return useContext(ToastContext);
}
```

**A Store is correct** when the same value must also be readable/writable from outside the component tree (e.g. a singleton service module), must survive a provider unmounting, or is backed by `localStorage`/IndexedDB/an API through a `*Service` — see the Stores section above.

---

## When to write a custom hook

Custom hooks are **not the default**. Write one only when **all three** are true:
1. It involves `useEffect`, `useRef`, or a browser event subscription
2. The same side effect is needed in **more than one component**
3. It cannot be replaced by a simple service method call in each component

### Decision flowchart

```
Does it involve useEffect, useRef, or a browser subscription?
  No  → put it in a service, call it directly in the component
  Yes → Is the same effect needed in more than one component?
          No  → put the useEffect directly in the component
          Yes → write a custom hook
```

### ✅ Valid hooks

```ts
// useOnlineStatus — browser event with cleanup, reused in multiple components
export function useOnlineStatus(): boolean {
  const [online, setOnline] = useState(navigator.onLine);
  useEffect(() => {
    const on  = () => setOnline(true);
    const off = () => setOnline(false);
    window.addEventListener('online',  on);
    window.addEventListener('offline', off);
    return () => {
      window.removeEventListener('online',  on);
      window.removeEventListener('offline', off);
    };
  }, []);
  return online;
}
```

### ❌ Hooks that should not exist

```ts
// ❌ just a service method — no side effect
export function useCartTotal(cart: Cart) {
  return cartService.total(cart);
}
// ✅ call it directly
const total = cartService.total(basket);

// ❌ wrapping a service that is already injectable
export function useCart() {
  return cartService;
}
// ✅ inject via prop
export function CartScreen({ cartService: cart = cartService }: CartScreenProps) { … }
```

---

## Anti-patterns to avoid

### Business logic in components

```tsx
// ❌ pricing logic belongs in CartService
function handleCheckout() {
  const total    = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  const discount = total > 100 ? total * 0.1 : 0;
  setFinalTotal(total - discount);
}

// ✅ delegate to the service
function handleCheckout() {
  setFinalTotal(cartService.totalWithDiscount(basket));
}
```

### Instantiating services inside components

```tsx
// ❌ creates a new instance on every render, not injectable
export function CartScreen({ userId }: CartScreenProps) {
  const cartService = new CartService();
  …
}

// ✅ inject via prop with singleton as default
export function CartScreen({ userId, cartService: cart = cartService }: CartScreenProps) { … }
```
