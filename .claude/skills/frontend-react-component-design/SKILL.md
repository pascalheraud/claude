---
name: frontend-react-component-design
description: React component design — categorising components (design system vs domain), naming conventions with suffix vocabulary, props design, state ownership, and when to extract a new component
---

# React Component Design — Skill

## Purpose

This skill defines how to **model a UI into components** before writing any code. It covers how to identify, categorise, name and organise components from a design or specification.

---

## The two categories

Every component belongs to one of two categories. Decide which category first — it determines where the file lives and what the component is allowed to do.

### 1. Design system components (generic)

Reusable UI building blocks with **no knowledge of the application domain**. They receive only primitives or generic types as props (`string`, `number`, `boolean`, `React.ReactNode`).

Examples: `Button`, `Modal`, `ProgressBar`, `Badge`, `Card`, `Toast`

Rules:
- No imports from `models.ts` or domain types
- No calls to services or hooks
- Fully controlled by props — no internal business logic
- Reusable across any project

```tsx
// ✅ generic — knows nothing about the app
<ProgressBar value={75} color="blue" label="75%" />

// ❌ domain-aware — belongs in features/, not ui/
<ProgressBar orderStatus={order} cart={cart} />
```

### 2. Functional components (domain-specific)

Components that implement a specific feature of the application. They **know about the domain** — they import from `models.ts`, receive service instances as props, hold local UI state.

Examples: `ProductCard`, `CheckoutForm`, `OrderSummary`, `UserDashboard`

Rules:
- Organised by feature domain in `features/`
- Receive service instances via **injectable props** (with singleton as default)
- May import domain types from `models.ts`
- May hold local UI state with `useState`
- Should not contain business logic — delegate to injected services
- Should not contain reusable generic UI code (extract to `ui/` instead)

```tsx
// ✅ service injected via prop — testable, uses singleton in production
import { playerService, PlayerService } from '@services';

interface VideoPlayerProps {
  videoId:  string;
  player?:  PlayerService;          // injectable for tests
  onEnded:  () => void;
}

export function VideoPlayer({ videoId, player = playerService, onEnded }: VideoPlayerProps) {
  function handlePlay() {
    player.play(videoId);           // method call on injected service
  }
  …
}

// ❌ instantiating a service inside a component
import { PlayerService } from '@services/PlayerService';

export function VideoPlayer({ videoId }: VideoPlayerProps) {
  const player = new PlayerService();   // new instance every render, not injectable
  …
}
```

---

## The three layers within design system components

### Atoms

The smallest possible UI elements. They render a single HTML element or a tiny composition.

Traits: no children (or `children: React.ReactNode` only), minimal props, no layout opinions.

Examples: `Button`, `Badge`, `Avatar`, `Spinner`, `Tag`, `StatusDot`, `Icon`

### Molecules

Compositions of 2–5 **atom components** (actually imported and rendered, not just raw HTML elements) that form a recognisable UI pattern.

Traits: coordinate multiple atoms, may have simple internal state (open/closed), still generic. A molecule with the props stripped out is just a handful of atoms wired together — it has no layout opinion of its own beyond arranging them.

Examples: `Dropdown`, `ConfirmDialog` (composes `Modal` + `Button`), `SearchInput` (composes an input atom + `IconButton`), `ModalBar` (composes `IconButton`)

### Organisms

Large generic structures that provide layout or page-level scaffolding. They typically accept generic `children` and own the positioning/overlay behaviour around them, even if they don't compose any atoms internally.

Traits: accept `children`, provide context or layout, still generic (no domain knowledge).

Examples: `Card`, `PageWrapper`, `EmptyState`, `ErrorBoundary`, `Sidebar`, `Modal`, `BottomSheet`, `Toast`/`ToastContainer`

---

## Disambiguating atom vs. molecule vs. organism

Don't classify by feel — apply these checks in order:

1. **Does it render a single HTML element, or a couple of raw elements with no composed atom inside (e.g. a `<span>` + a raw `<button>`)?** → **Atom**, even if it has variant/size props. (`Badge`, `CounterBadge`, `InfoBanner`, `SectionLabel`, `DashedButton` are atoms for this reason — none of them import another `ui/` component.)
2. **Does it accept generic `children` and exist mainly to provide layout/positioning (overlay, centering, sliding panel, page wrapper) rather than to coordinate specific atoms?** → **Organism**, regardless of internal complexity. (`Modal`, `BottomSheet`, `Card`, `PageWrapper` are organisms for this reason — "accepts children + owns layout" outweighs "doesn't compose atoms".)
3. **Does it import and render 2–5 other `ui/` components (atoms, or occasionally an organism like `Modal`) to form one specific, non-generic-layout pattern (a dialog, a form field, a header bar)?** → **Molecule**.

When in doubt, check actual imports: grep the component file for `from '@ui/atoms'` or `from '@ui/organisms'`. A component with zero such imports is never a molecule — it's an atom (no composition) or an organism (children + layout).

---

## How to decompose a UI into components

Work top-down from the screen to the smallest element.

**Step 1 — Identify screens**

Each distinct full-page view is a `Screen` component. It owns the page-level state and orchestrates child components.

**Step 2 — Identify repeating structures**

Any UI block that appears more than once, or that has a clear single responsibility, is a component candidate.

**Step 3 — Separate generic from domain**

Ask: *"Could this component exist in a completely different app?"*
- Yes → `ui/` (design system)
- No → `features/{domain}/`

**Step 4 — Name by role, not by content**

Name components after what they *do*, not what they *contain*. Use the suffix vocabulary below.

---

## Suffix vocabulary

The suffix signals the component's role at a glance. Use it consistently.

| Suffix | Role | Example |
|--------|------|---------|
| `Screen` | Full page, owns page state | `CheckoutScreen`, `DashboardScreen` |
| `Card` | Clickable or informative tile | `ProductCard`, `UserCard` |
| `Sheet` | Bottom sheet (slides from bottom) | `FilterSheet`, `ShareSheet` |
| `Modal` | Centred popup with overlay | `ConfirmModal`, `ImageModal` |
| `List` | Renders a collection | `ProductList`, `NotificationList` |
| `Item` | Single element inside a list | `CartItem`, `NotificationItem` |
| `Bar` | Horizontal action or progress strip | `ActionBar`, `ProgressBar` |
| `Banner` | Full-width status message | `ErrorBanner`, `SuccessBanner` |
| `Section` | Grouped content block | `BillingSection`, `ProfileSection` |
| `Button` | Button with domain-specific behaviour | `AddToCartButton`, `FollowButton` |
| `Label` | Text-only display element | `PriceLabel`, `StatusLabel` |
| `Grid` | Selection or layout grid | `ColorGrid`, `SizeGrid` |
| `Panel` | Utility or debug panel | `DevToolsPanel`, `AdminPanel` |
| `Hero` | Full-width illustrated header | `ProductHero`, `CampaignHero` |
| `Icon` | Icon with behaviour | `PlayIcon`, `HeartIcon` |
| `Badge` | Small informational indicator | `CountBadge`, `StatusBadge` |

---

## Props design

### Keep props minimal

Pass only what the component needs. Avoid passing entire objects when only one field is used.

```tsx
// ✅ pass only what is needed
<UserCard name="Alice" avatar="/alice.jpg" role="Admin" onClick={…} />

// ❌ passing the whole object couples the component to the model
<UserCard user={user} onClick={…} />
```

Two exceptions where passing an object is correct:

**1. The component genuinely needs most fields of a domain object:**
```tsx
<OrderSummary order={order} onConfirm={onConfirm} />
```

**2. Service injection — always pass the service class, never individual methods:**
```tsx
// ✅ pass the service instance — testable, consistent
<VideoPlayer videoId={id} player={playerService} onEnded={onEnded} />

// ❌ passing individual methods breaks testability and loses cohesion
<VideoPlayer videoId={id} onPlay={playerService.play} onStop={playerService.stop} />
```

### Name props consistently

| Case | Convention |
|------|-----------|
| Event callback | `on` + PascalCase verb: `onClick`, `onClose`, `onSubmit` |
| Boolean | `is` or `has` prefix: `isLoading`, `hasError`, `isDisabled` |
| Optional | `?` suffix |
| Children | `children: React.ReactNode` |

### Define the Props interface above the component

```tsx
// ✅
interface ProductCardProps {
  name:       string;
  price:      number;
  imageUrl?:  string;
  isOnSale?:  boolean;
  onClick:    () => void;
  onAddToCart: () => void;
}

export function ProductCard({ name, price, imageUrl, isOnSale = false, onClick, onAddToCart }: ProductCardProps) { … }
```

---

## State ownership

Each piece of state should be owned by the **lowest common ancestor** of the components that need it.

| State type | Owner |
|-----------|-------|
| UI-only state (open, hover, error message) | `useState` in the component |
| State shared between siblings | `useState` in their parent |
| State needed across the whole app | React Context |
| State derived from other state | Compute inline — no `useState` |
| Business logic results | Service method call → stored in `useState` |
| Service instances | Injected via props (singleton as default) |
| Browser event subscription reused in 2+ components | Custom hook |

**Custom hooks are not the default.** If a side effect is only needed in one component, put the `useEffect` directly in that component. If there is no side effect at all, call the service method directly — no hook needed.

```tsx
// ✅ derived state — no extra useState
const isCartEmpty = items.length === 0;

// ❌ unnecessary state for derived value
const [isCartEmpty, setIsCartEmpty] = useState(false);
useEffect(() => setIsCartEmpty(items.length === 0), [items]);
```

---

## Composition over configuration

Prefer composing small focused components over adding many props to a single component.

```tsx
// ✅ composed — each piece is independently replaceable
<Card>
  <CardHeader title={product.name} badge={<StatusBadge status={product.status} />} />
  <CardBody>
    <PriceLabel amount={product.price} currency="EUR" />
    <SizeGrid sizes={product.sizes} selected={selected} onSelect={setSelected} />
  </CardBody>
  <CardFooter>
    <AddToCartButton productId={product.id} />
  </CardFooter>
</Card>

// ❌ one big component with too many responsibilities
<ProductCard
  name={product.name}
  price={product.price}
  status={product.status}
  sizes={product.sizes}
  selectedSize={selected}
  onSizeSelect={setSelected}
  onAddToCart={…}
  showBadge
  badgeVariant="sale"
  currency="EUR"
  …
/>
```

---

## Colocation

Keep related files together. Test files live next to the files they test.

```
features/shop/
  ProductCard.tsx
  ProductCard.test.tsx
  CartItem.tsx
  CartItem.test.tsx
  CheckoutScreen.tsx
  CheckoutScreen.test.tsx
  index.ts
```

No separate `__tests__` folder. No `components/` subfolder inside a feature folder.

---

## When to extract a new component

Extract when **any** of these is true:
- The JSX block is used in more than one place
- The block has its own clear single responsibility
- The block has its own state that does not affect its siblings
- The parent component is growing hard to read (> ~100 lines of JSX)

Do **not** extract just to reduce line count. A 30-line component that is only used once and has no clear independent responsibility is better left inline.
