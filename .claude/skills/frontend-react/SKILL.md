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

## Event handlers as named functions

Handlers are defined as named functions inside the component, never inline in JSX (no `onClick={() => …}` with logic). Bind static args via closures over component scope, not inline arrow bodies.

```tsx
function handleNavigateToLang() {
  navigate(`/lang/${code}`);
}

<button onClick={handleNavigateToLang}>…</button>
```

## Loops in templates

Loops in JSX (`.map`, etc.) must delegate rendering to a named function defined in the component, not inline an arrow function body with JSX inside `.map`.

```tsx
function LangCardItem(code: string) {
  return (
    <LangCard key={code} lang={code} onClick={() => handleLangCardClick(code)} />
  );
}

<div>{activeLanguages.map(LangCardItem)}</div>
```

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

## Error UX rule

**Never close a form on error.** When an API call fails, keep the form open and display the error inline (a message inside the form body). Never use a modal/popup to show the error when the form is itself inside a modal — stacked modals close each other. Only close a form after a successful operation.

## API error handling

### Global error popup (automatic)

Wire a global error handler once at the layout level (`ErrorProvider`). API helpers call it automatically on failure — no `.catch()` needed per call site.

```tsx
// layout.tsx — register once
import { registerGlobalErrorHandler } from "../model/utils";

export function ErrorProvider({ children }) {
  const [message, setMessage] = useState<string | null>(null);
  const onFinallyRef = useRef<(() => void) | undefined>(undefined);

  useEffect(() => {
    registerGlobalErrorHandler((onFinally) => {
      onFinallyRef.current = onFinally;
      setMessage("Une erreur s'est produite. Veuillez réessayer.");
    });
  }, []);

  function handleClose() {
    setMessage(null);
    const fn = onFinallyRef.current;
    onFinallyRef.current = undefined;
    fn?.();
  }

  return (
    <ErrorContext.Provider value={…}>
      {children}
      {message !== null && <ErrorPopup message={message} onClose={handleClose} />}
    </ErrorContext.Provider>
  );
}

// In API helpers — withErrorHandling fires globalErrorHandler on error
function withErrorHandling(promise, options) {
  return promise
    .catch(normalizeError)
    .catch((e) => {
      if (options?.onError) {
        options.onError(e);
        options.onFinally?.();
      } else {
        globalErrorHandler?.(options?.onFinally); // passes onFinally to the popup
      }
      return new Promise(() => {}); // never resolves — .then() is skipped silently
    })
    .then((result) => {
      options?.onFinally?.();
      return result;
    });
}

// Call site — no .catch() needed, error popup fires automatically
post("/api/resource", payload, ["field"]).then(() => { … });
```

### onFinally — re-enable buttons / reset loading state

Pass `onFinally` in the options object. **On success** it fires immediately after `.then()`. **On error** it fires when the user closes the error popup — the button stays disabled until the user acknowledges the error.

```ts
post("/api/resource", payload, ["field"], {
  onFinally: () => setLoading(false),
}).then(() => { … });
```

### Custom error handling (onError)

When a call site needs to handle a specific error (e.g. 400 inline message), pass `onError`. The global popup is suppressed; the caller is fully in control. `onFinally` fires immediately after `onError`.

```ts
post("/api/resource", payload, ["field"], {
  onError: (e) => {
    if (e.networkError) setInlineError("Opération impossible.");
    else globalErrorHandler?.(); // re-trigger for 500
  },
  onFinally: () => setLoading(false),
}).then(() => { … });
```

### 404 / 403 — inspecting status directly

For calls where you need the raw HTTP status (e.g. DELETE returning 204/404), use `fetchJson` and call `showError()` manually for 5xx:

```ts
const { showError } = useGlobalError();
const { status } = await fetchJson(`/api/resource/${id}`, { method: "DELETE" });
if (status >= 500) showError();
if (status === 404) setError("Resource not found.");
```

### Error in a modal — always inline

Never open an error popup on top of a modal — stacked modals close each other. Show the error as an inline `<p>` inside the modal body instead.

```tsx
// ✗ wrong — InternalErrorPopup inside a modal closes the parent modal when dismissed
{error && <InternalErrorPopup onClose={() => setError(false)} />}

// ✓ correct — inline message inside the form/modal body
{error && <p>Une erreur est survenue, veuillez réessayer.</p>}
```

## Test coverage

If a tests are required in this project, every component, service, and store must have a corresponding test file. Don't skip tests for "simple" components — even a one-line atom gets a render test.

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
