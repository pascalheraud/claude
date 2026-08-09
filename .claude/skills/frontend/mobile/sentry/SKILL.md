---
name: sentry
description: >
  Setup and integration guide for Sentry error monitoring in Capacitor + React mobile apps targeting iOS and Android stores.
  Use this skill whenever the user mentions: Sentry, crash reporting, error monitoring, error tracking, logging errors to a dashboard,
  offline error buffering, mobile crash analytics, or any request to capture and report JS/native errors in a Capacitor app.
  Also trigger when the user asks how to debug production crashes, monitor app health post-release, or set up alerting for mobile errors.
  Even if the user only says "je veux voir les erreurs en prod" or "comment logger les crashes", this skill applies.
---

# Mobile Monitoring — Sentry + Capacitor + React

## Overview

Sentry is the recommended solution for Capacitor/React apps targeting mobile stores. Key advantages:
- **Offline buffering**: errors captured without network are queued and sent when connectivity returns
- **Native crash capture**: iOS/Android crashes via `@sentry/capacitor` (wraps Sentry Cocoa + Android SDK)
- **JS error capture**: unhandled exceptions, promise rejections, manual captures
- **Free tier**: 5k events/month, sufficient for indie/small team apps

---

## Packages

```bash
npm install @sentry/capacitor @sentry/react
npx cap sync
```

`@sentry/capacitor` is the Capacitor wrapper. It delegates to `@sentry/react` for the JS layer and to native Sentry SDKs for crashes. **Always use both together.**

---

## Init

Initialize Sentry **before** rendering the app. Pass `dsn`, `environment`, `release`, and `enabled: import.meta.env.PROD` (skip in dev).

`VITE_SENTRY_DSN` and `VITE_APP_VERSION` go in `.env.production`. Never commit the DSN in source; it's not a secret but keeping it env-based is cleaner.

For React-specific init (two-argument form with `@sentry/react`) and the Error Boundary component → see `references/react.md`.

---

## Error Boundary

Wrap the app root to catch render errors and report them to Sentry.

For the React implementation (`withErrorBoundary`, `SentryErrorBoundary` component) → see `references/react.md`.

---

## ErrorService — service-based pattern

For apps using constructor-injection services (composition root in `services/index.ts`), wrap Sentry behind a service to keep components decoupled and testable.

```ts
// services/ErrorService.ts
import * as Sentry from "@sentry/capacitor";

export interface ErrorContext {
  [key: string]: unknown;
}

export class ErrorService {
  captureException(error: unknown, context?: ErrorContext): void {
    console.error("[ErrorService]", error, context);
    Sentry.captureException(error, { extra: context });
  }

  captureMessage(message: string, level: Sentry.SeverityLevel = "info"): void {
    Sentry.captureMessage(message, level);
  }

  addBreadcrumb(message: string, category: string, data?: ErrorContext): void {
    Sentry.addBreadcrumb({ message, category, data, level: "info" });
  }

  setAppContext(context: ErrorContext): void {
    Sentry.setContext("app", context);
  }

  setUserContext(anonymousId: string): void {
    // GDPR: never send PII. Use a stable anonymous ID (e.g. UUID stored in IndexedDB).
    Sentry.setUser({ id: anonymousId });
  }

  clearUser(): void {
    Sentry.setUser(null);
  }
}
```

Register in the composition root:

```ts
// services/index.ts
import { ErrorService } from "./ErrorService";
export const errorService = new ErrorService();
```

Inject as prop where needed. Do **not** import `errorService` directly inside components — pass it in to keep things testable.

---

## What to capture — practical patterns

### Unhandled async errors (IndexedDB, fetch, etc.)
```ts
// In a service method
async loadPack(id: string): Promise<Pack> {
  try {
    return await this.db.getPack(id);
  } catch (error) {
    this.errorService.captureException(error, { packId: id, operation: "loadPack" });
    throw error; // re-throw so the UI can react
  }
}
```

### Breadcrumbs for user flow context
```ts
// Before a risky operation
this.errorService.addBreadcrumb("User started quiz", "navigation", { packId, lessonId });
```

### App context (useful for filtering in Sentry dashboard)
```ts
// After loading user preferences
this.errorService.setAppContext({
  packCount: packs.length,
  appLanguage: userLang,
  appVersion: APP_VERSION,
});
```

---

## GDPR considerations

Sentry **does** send data to Sentry's US servers by default.

**Minimum required actions:**
1. Document Sentry as a data processor in your privacy policy
2. Don't send any PII (name, email, device ID) — anonymous UUID only
3. Use `beforeSend` to scrub accidental PII:

```ts
Sentry.init({
  // ...
  beforeSend(event) {
    // Strip any accidental user fields except our anonymous id
    if (event.user) {
      event.user = { id: event.user.id };
    }
    return event;
  },
});
```

**If you need EU data residency:** Sentry offers an EU region endpoint. Set `dsn` to the EU DSN from your Sentry project settings. No other code changes needed.

**If you want user consent before enabling:** Call `Sentry.init` with `enabled: false` initially, then call `Sentry.getCurrentHub().getClient()?.getOptions()` and flip `enabled` to `true` after consent. Simpler alternative: just don't init at all until consent, then call `Sentry.init(...)` at consent time — one-time init is fine.

---

## iOS / Android native setup

After `npx cap sync`, Sentry's native SDKs are auto-integrated via Capacitor's plugin system. No manual `AppDelegate` or `MainActivity` edits needed for basic crash reporting.

**iOS only** — add to `ios/App/App/Info.plist` if you want symbolicated stack traces in Xcode builds:
```xml
<key>SentryDSN</key>
<string>$(SENTRY_DSN)</string>
```

Set `SENTRY_DSN` in your Xcode scheme environment variables (not required for production — Sentry reads it from the JS init).

**Source maps / dSYMs for readable stack traces:**
- For JS: add `@sentry/vite-plugin` to `vite.config.ts` to upload source maps on build
- For native iOS: add the Sentry CLI to your Xcode build phase to upload dSYMs

```bash
npm install --save-dev @sentry/vite-plugin
```

```ts
// vite.config.ts
import { sentryVitePlugin } from "@sentry/vite-plugin";

export default defineConfig({
  plugins: [
    react(),
    sentryVitePlugin({
      org: "your-org",
      project: "your-project",
      authToken: process.env.SENTRY_AUTH_TOKEN, // CI secret
    }),
  ],
  build: { sourcemap: true },
});
```

---

## Sentry dashboard — useful setup

Once events arrive:

1. **Alerts**: set up an alert rule for `event.type:error` to get notified on first occurrence of a new issue
2. **Environments**: filter by `production` vs `development` (set by `environment` in init)
3. **Releases**: tag errors to a release to track when a bug was introduced (`release` in init)
4. **Performance**: enable if `tracesSampleRate > 0` — shows slow screens and DB queries

---

## Step: Build checklist

Before building the production binary, complete the build checklist.

> **Refer to the dedicated build skill** — search available skills for "build" or "mobile build checklist". That skill contains the full pre-build checklist for Capacitor apps. Complete it before generating the iOS/Android binary.

Sentry-specific items to verify at build time:
- [ ] `VITE_SENTRY_DSN` set in CI/CD build env, not committed to git
- [ ] `VITE_APP_VERSION` set from `package.json` version in CI
- [ ] `build: { sourcemap: true }` in `vite.config.ts`
- [ ] Sentry Vite plugin configured and `SENTRY_AUTH_TOKEN` available in CI

---

## Step: Store submission checklist

Before submitting to the App Store or Google Play, complete the store submission checklist.

> **Refer to the dedicated store skill** — search available skills for "store" or "store submission checklist". That skill contains the full checklist for App Store and Google Play submissions. Complete it before submitting.
>
> **Important**: the store skill has a section for third-party SDKs / data collection. Add Sentry there: declare it as a crash reporting processor, specify that it collects anonymous crash data, and note the data transfer to Sentry's servers (or EU region if configured).

Sentry-specific items to verify at submission time:
- [ ] `enabled: import.meta.env.PROD` — Sentry off in dev builds
- [ ] Privacy policy mentions Sentry as a data processor
- [ ] No PII sent — `beforeSend` scrubber in place
- [ ] dSYMs uploaded to Sentry (iOS) for symbolicated native stack traces
- [ ] Test offline buffering: kill app mid-session, reopen with network, verify event appears in Sentry dashboard
