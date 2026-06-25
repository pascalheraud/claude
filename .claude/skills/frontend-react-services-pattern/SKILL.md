---
name: frontend-react-services-pattern
description: React services pattern — separating business logic into injectable TypeScript service classes, composition root, singleton injection via props, custom hooks decision flowchart
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

All service classes are instantiated **once** in `services/index.ts`.

```ts
// services/index.ts
import { CartService }    from './CartService';
import { OrderService }   from './OrderService';
import { StorageService } from './StorageService';
import { ApiService }     from './ApiService';

export const storageService = new StorageService();
export const apiService     = new ApiService();
export const cartService    = new CartService();
export const orderService   = new OrderService(cartService, apiService);

export type { CartService }    from './CartService';
export type { OrderService }   from './OrderService';
export type { StorageService } from './StorageService';
```

Everything else imports from `@services` (the barrel) — never from individual service files.

```ts
// ✅ import from composition root
import { cartService, CartService } from '@services';

// ❌ bypass composition root — creates a second instance
import { CartService } from '@services/CartService';
const cart = new CartService();
```

---

## The recommended pattern

Services are injected as props with the singleton as default. The component holds UI state and calls service methods in event handlers.

```tsx
// features/shop/CheckoutScreen.tsx
import { useState } from 'react';
import { cartService, orderService, CartService, OrderService } from '@services';
import type { Cart } from '@/models';

interface CheckoutScreenProps {
  userId:   string;
  onDone:   () => void;
  cart?:    CartService;
  orders?:  OrderService;
}

export function CheckoutScreen({
  userId,
  onDone,
  cart   = cartService,
  orders = orderService,
}: CheckoutScreenProps) {

  const [basket,     setBasket]     = useState<Cart>(() => cart.load(userId));
  const [submitting, setSubmitting] = useState(false);
  const [error,      setError]      = useState<string | null>(null);

  function handleRemoveItem(itemId: string) {
    setBasket(cart.remove(basket, itemId));
  }

  async function handleSubmit() {
    setSubmitting(true);
    setError(null);
    try {
      await orders.place(basket, userId);
      cart.clear(userId);
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

## Service dependencies — constructor injection

When services depend on each other, inject via constructor. Wire everything in the composition root.

```ts
// services/OrderService.ts
export class OrderService {
  constructor(
    private readonly cart: CartService,
    private readonly api:  ApiService,
  ) {}

  async place(cart: Cart, userId: string): Promise<Order> {
    const total = this.cart.total(cart);
    return this.api.post('/orders', { cart, total, userId });
  }
}
```

---

## Testing

```tsx
// features/shop/CartScreen.test.tsx
const fakeCart = {
  load:   vi.fn().mockReturnValue({ items: [] }),
  remove: vi.fn(),
  total:  vi.fn().mockReturnValue(0),
} as unknown as CartService;

it('renders empty cart', () => {
  render(<CartScreen userId="u1" cart={fakeCart} />);
  expect(screen.getByText('Your cart is empty')).toBeInTheDocument();
});
```

In production, `cart` is not passed → singleton is used.
In tests, `cart={fakeCart}` is passed → no real storage or network is touched.

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
const total = cart.total(basket);

// ❌ wrapping a service that is already injectable
export function useCart() {
  return cartService;
}
// ✅ inject via prop
export function CartScreen({ cart = cartService }: CartScreenProps) { … }
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
  setFinalTotal(cart.totalWithDiscount(basket));
}
```

### Instantiating services inside components

```tsx
// ❌ creates a new instance on every render, not injectable
export function CartScreen({ userId }: CartScreenProps) {
  const cart = new CartService();
  …
}

// ✅ inject via prop with singleton as default
export function CartScreen({ userId, cart = cartService }: CartScreenProps) { … }
```
