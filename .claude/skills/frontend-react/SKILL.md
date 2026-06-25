---
name: frontend-react
description: React + TypeScript conventions — strict typing, component decomposition with inner functions, no inline styles, SSR/ClientOnly
---

# React + TypeScript Conventions

## TypeScript strict mode

- No `any`, no `unknown`, no non-null assertions (`!`), no type casting
- Props typed inline as `Readonly<{…}>` or as a named `type Props = {…}`

## No inline styles for static values

Never use `style={{…}}` for static values — always create a CSS class instead. Inline styles are only acceptable for truly dynamic values (e.g. a color coming from data).

## Page template decomposition

Split page templates into **inner functions** defined inside the page component to improve readability. Each function renders a named section or conditional variant. The root `return` stays minimal and reads like an outline.

```tsx
export default function MyPage() {
  const [data, setData] = useState<MyType>();

  function Header() { /* … */ }
  function HasItems() { /* … */ }
  function HasNoItems() { /* … */ }
  function ItemsSection() {
    return hasItems ? <HasItems /> : <HasNoItems />;
  }

  return (
    <>
      <Header />
      <ItemsSection />
    </>
  );
}
```

- Name functions after what they represent, not how they render (`ItemsSection`, not `RenderItems`)
- Keep conditional logic in a dispatcher function that delegates to leaf functions
- Leaf functions contain only JSX, no branching

## SSR / client-only

Components that use `window`, `Date`, or browser APIs must be wrapped in a `<ClientOnly>` boundary to prevent SSR hydration errors.

## API error handling

### 500 — Internal server error

```tsx
const [internalError, setInternalError] = useState(false);

// in API call catch:
.catch((e) => {
  if (e.serverError) setInternalError(true);
});

// in JSX:
{internalError && (
  <InternalErrorPopup onClose={() => setInternalError(false)} />
)}
```

### 404 / 403 — Update or Delete

```ts
const { status } = await fetchJson(`/api/resource/${id}`, { method: "DELETE" });
if (status === 404 || status === 403) {
  setError("Resource not found.");
  return;
}
```

## Empty select (dropdown)

```tsx
{items.length === 0 ? (
  <p>
    You don't have any items yet.{" "}
    <button type="button" className="link-button" onClick={onGoToItems}>
      Add one
    </button>
  </p>
) : (
  <select>…</select>
)}
```
