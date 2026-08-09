---
name: react
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

## Stale state right after calling its setter

A `setX(value)` call doesn't update `x` until the next render — reading `x` from component state
later in that *same* function invocation still sees the old value, not `value`. This bites hardest in
an async callback that both calls `setX(value)` and then, in that same callback, calls another function
that reads `x` from the closure (e.g. `setUser(u); ...; someHelper()` where `someHelper` internally
reads the `user` state variable): `someHelper` still sees the pre-update value, even though the setter
call is right above it. If that helper also mutates external state (localStorage, an API call, a ref)
based on what it read, the bug is a silent one-render-late decision that's easy to miss in review and
only surfaces on a specific timing path (e.g. "works the first time, reopens on the next page load").

Fix: pass the fresh value as a parameter to the helper instead of letting it read the stale state
closure — `someHelper(u)` instead of `someHelper()` relying on `user`. Give the parameter a default of
the state variable so call sites that already run after a normal re-render (e.g. a direct user click)
don't need to change: `function someHelper(forUser = user) { ... }`.

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

**Call these functions directly (`{Header()}`), never render them as JSX tags (`<Header />>`), unless the function takes `props` and is invoked inside a keyed list (see exception below).** A function declared inside the page component is a *new function value on every render* — used as a JSX tag, its identity (not just its output) becomes part of what React diffs, so on the next render React sees a "new component type" at that spot and unmounts/remounts the whole subtree instead of reconciling it. For a leaf with no state this is just wasted work; for a leaf wrapping a controlled input, a `useEffect`, or any component with mount-time side effects, it's a real bug — a text input remounted every render loses focus/selection on every keystroke, and if the remounted child's mount effect calls back up into the parent's state (e.g. an autocomplete component initializing its parent via a callback prop), each remount re-fires that effect, which re-renders the parent, which remounts the child again: an infinite `setState`-in-effect loop (React's "Maximum update depth exceeded"). This is not a rare edge case — it bit exactly this pattern in production (an address-autocomplete field wrapped in a per-render-redefined `AddressField()` section, converted to `<AddressField />>`, which remounted the autocomplete on every keystroke and looped).

```tsx
export default function MyPage() {
  const [data, setData] = useState<MyType>();

  function Header() { /* … */ }
  function HasItems() { /* … */ }
  function HasNoItems() { /* … */ }
  function ItemsSection() {
    return hasItems ? HasItems() : HasNoItems();
  }

  return (
    <>
      {Header()}
      {ItemsSection()}
    </>
  );
}
```

- Name functions after what they represent, not how they render (`ItemsSection`, not `RenderItems`)
- Keep conditional logic in a dispatcher function that delegates to leaf functions
- Leaf functions contain only JSX, no branching
- This applies to **every distinct logical block** of the template, not just top-level page sections:
  a modal/popup's `body` gets its own function (`ConfirmModalBody`), a form section gets its own
  function (`AddressField`, `SearchForm`), and a state machine with more than one branch (not-connected
  / not-validated / confirmed, loading / empty / loaded, …) becomes a dispatcher function plus one leaf
  function per branch, exactly like `ItemsSection`/`HasItems`/`HasNoItems` above — don't leave a 3-way
  `{cond1 && (...)} {cond2 && (...)} {cond3 && (...)}` chain inlined in the root `return` just because
  it's "only" a popup's content and not a page-level section.
- **Watch the syntax when converting an existing `<Foo />>` to `Foo()`** — the replacement depends on where it sits, and getting it wrong is a silent runtime/type error, not always a compiler error:
  - As JSX children (between tags): `{Foo()}` — one pair of braces, same as any other JSX expression.
  - Inside a prop that expects a JSX node (e.g. `body={<Foo />}` on a `Modal`): `body={Foo()}` — still one pair; writing `body={{Foo()}}` (keeping the old braces *and* adding the prop's) passes an object instead of a node.
  - Inside a `cond && <Foo />` or a ternary already living inside JSX children: drop the angle-bracket tag but keep the surrounding single brace — `{cond && Foo()}`, `{cond ? Foo() : Bar()}`.
  - As a bare `return` statement (a dispatcher function's body, not JSX children) — no braces at all: `return Foo();`, `if (x) return Foo();`. `return {Foo()};` is a parse trap (JS reads `{` there as the start of a block or object, not a JSX expression container).
- **Exception — components rendered inside `.map()` with a `key`:** the `key` prop can only be attached at JSX element creation, so keyed list items keep the `<Item key={id} .../>` tag form. This means a component used both as a list-item renderer and defined inside the same parent still carries the remount risk described above (its "type" changes every parent render, so React remounts every item on every render regardless of matching keys) — the real fix there is hoisting the item-renderer to module scope and passing everything it needs as props, not just switching syntax. Prefer that hoist for any list-item renderer that wraps a focus-sensitive input; a purely-presentational list item (no inputs, no effects) can stay as-is without urgency.

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
