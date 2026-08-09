# Sentry — React integration

## Init — main.tsx

Initialize Sentry **before** rendering the React tree. Use the two-argument form: Capacitor options first, then `SentryReact.init` as second arg.

```ts
// main.tsx
import * as Sentry from "@sentry/capacitor";
import * as SentryReact from "@sentry/react";

Sentry.init(
  {
    dsn: import.meta.env.VITE_SENTRY_DSN,
    environment: import.meta.env.MODE,          // "development" | "production"
    release: import.meta.env.VITE_APP_VERSION,  // e.g. "1.0.0" — set in CI
    enabled: import.meta.env.PROD,              // skip in dev
    tracesSampleRate: 0.2,                      // 20% perf traces — adjust to quota
  },
  SentryReact.init
);
```

## Error Boundary

Wrap the app root to catch React render errors:

```tsx
// main.tsx (after Sentry.init)
import { SentryErrorBoundary } from "./components/SentryErrorBoundary";

createRoot(document.getElementById("root")!).render(
  <SentryErrorBoundary>
    <App />
  </SentryErrorBoundary>
);
```

```tsx
// components/SentryErrorBoundary.tsx
import * as SentryReact from "@sentry/react";

export const SentryErrorBoundary = SentryReact.withErrorBoundary(
  ({ children }) => <>{children}</>,
  {
    fallback: ({ error, resetError }) => (
      <div>
        <p>Something went wrong.</p>
        <button onClick={resetError}>Retry</button>
      </div>
    ),
  }
);
```
