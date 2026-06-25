---
name: frontend-mobile-posthog
description: >
  Setup and integration guide for PostHog product analytics in Capacitor + React mobile apps targeting iOS and Android stores.
  Use this skill whenever the user mentions: PostHog, product analytics, usage logging, event tracking, user behavior,
  funnels, retention, feature flags, session recording, or any request to track how users interact with a mobile app.
  Also trigger when the user asks "combien d'users font X", "quel écran est le plus visité", "track les events",
  "logs d'usage", "analytics produit", or wants to understand user behavior in production.
  Trigger even for vague requests like "je veux savoir ce que font les users" or "track user actions".
---

# Mobile Analytics — PostHog + Capacitor + React

## Overview

PostHog is the recommended analytics solution for Capacitor/React apps when you want:
- **Control over data** — self-hostable (EU cloud available), GDPR-friendly by design
- **Offline buffering** — events queued locally and flushed when network returns
- **Free tier** — 1M events/month on PostHog Cloud
- **All-in-one** — events, funnels, retention, feature flags, session replay in one tool

---

## Package

```bash
npm install posthog-js
```

No native Capacitor plugin needed — `posthog-js` is a pure JS SDK that works in the WebView.

---

## Init — main.tsx

Initialize PostHog **before** rendering the React tree, after your app bootstrap.

```ts
// main.tsx
import posthog from "posthog-js";

if (import.meta.env.PROD) {
  posthog.init(import.meta.env.VITE_POSTHOG_KEY, {
    api_host: import.meta.env.VITE_POSTHOG_HOST ?? "https://eu.i.posthog.com",
    capture_pageview: false,       // manual control — no DOM-based pageviews on mobile
    capture_pageleave: false,
    autocapture: false,            // disable click autocapture — too noisy on mobile WebView
    persistence: "localStorage",   // survives app restarts; switch to "memory" if GDPR requires no storage before consent
    disable_session_recording: true, // enable explicitly only if needed + consent obtained
  });
}
```

`VITE_POSTHOG_KEY` and `VITE_POSTHOG_HOST` go in `.env.production`.

**EU data residency**: use `https://eu.i.posthog.com` as `api_host` — data stays in EU, simplifies GDPR.

---

## AnalyticsService — service-based pattern

Wrap PostHog behind a service for testability and decoupling from components.

```ts
// services/AnalyticsService.ts
import posthog from "posthog-js";

export class AnalyticsService {
  /**
   * Identify a user. Use a stable anonymous UUID — never PII.
   * Call once on app start after retrieving/generating the UUID from storage.
   */
  identify(anonymousId: string, properties?: Record<string, unknown>): void {
    posthog.identify(anonymousId, properties);
  }

  /**
   * Track a user action or product event.
   */
  capture(event: string, properties?: Record<string, unknown>): void {
    posthog.capture(event, properties);
  }

  /**
   * Track a screen view manually (replaces autocapture pageview).
   */
  screen(screenName: string, properties?: Record<string, unknown>): void {
    posthog.capture("$screen", { $screen_name: screenName, ...properties });
  }

  /**
   * Set persistent properties sent with every subsequent event.
   */
  setPersonProperties(properties: Record<string, unknown>): void {
    posthog.people.set(properties);
  }

  /**
   * Reset on logout or when the user clears their data.
   */
  reset(): void {
    posthog.reset();
  }

  /**
   * Opt user out of tracking (GDPR consent withdrawal).
   */
  optOut(): void {
    posthog.opt_out_capturing();
  }

  /**
   * Opt user back in after consent.
   */
  optIn(): void {
    posthog.opt_in_capturing();
  }
}
```

Register in the composition root:

```ts
// services/index.ts
import { AnalyticsService } from "./AnalyticsService";
export const analyticsService = new AnalyticsService();
```

---

## Event naming conventions

Use `snake_case`, `object_action` pattern. Be consistent — PostHog groups by exact event name.

```
screen_viewed          — every screen transition
pack_opened            — user opens a content pack
lesson_started         — user begins a lesson
lesson_completed       — user finishes a lesson (+ duration_seconds)
quiz_answered          — single answer (+ correct: boolean)
quiz_completed         — end of quiz (+ score, pack_id)
onboarding_completed   — finished the onboarding flow
language_selected      — user picks a target language
error_shown            — non-fatal error displayed to user (complement to Sentry)
```

Example capture:
```ts
analyticsService.capture("lesson_completed", {
  pack_id: pack.id,
  lesson_id: lesson.id,
  duration_seconds: elapsed,
  score: score,
});
```

---

## Screen tracking

On mobile there are no URL changes. Track screens manually by calling `analyticsService.screen(screenName, properties)` on each screen transition.

For React-specific patterns (useEffect per screen, React Router subscription) → see `references/react.md`.

---

## Anonymous ID — GDPR-safe identification

Never use device ID or any PII. Generate a UUID on first launch and persist it in IndexedDB.

```ts
// services/UserService.ts (example)
async getOrCreateAnonymousId(): Promise<string> {
  let id = await this.db.get("anonymous_id");
  if (!id) {
    id = crypto.randomUUID();
    await this.db.set("anonymous_id", id);
  }
  return id;
}
```

Call `analyticsService.identify(anonymousId)` once on app start after retrieving the ID.

---

## GDPR considerations

PostHog EU cloud (`eu.i.posthog.com`) keeps data in EU — simplest path to compliance.

**Required actions:**
1. Mention PostHog in your privacy policy as a data processor
2. Never send PII in event properties — no names, emails, or device identifiers
3. Implement opt-out if your market requires explicit consent for analytics:

```ts
// On consent screen — user declines
analyticsService.optOut();

// User accepts
analyticsService.optIn();
```

If you need to delay all tracking until consent: init PostHog with `opt_out_capturing_by_default: true`, then call `optIn()` after consent.

```ts
posthog.init(key, {
  // ...
  opt_out_capturing_by_default: true,
});
```

---

## Offline buffering

PostHog JS queues events in `localStorage` when offline and flushes them automatically when connectivity returns. No extra configuration needed.

To verify: put the device in airplane mode, trigger events, reconnect — check PostHog dashboard for delayed event arrival.

---

## Feature flags (optional)

Use PostHog feature flags to roll out features progressively or run A/B tests:

```ts
// Check a flag
const showNewOnboarding = posthog.isFeatureEnabled("new-onboarding-flow");

// In AnalyticsService
isFeatureEnabled(flag: string): boolean {
  return posthog.isFeatureEnabled(flag) ?? false;
}
```

Flags are evaluated locally after a bootstrap fetch on init — they work offline once cached.

---

## PostHog dashboard — useful setup

1. **Insights → Trends**: plot `lesson_completed` over time to track engagement
2. **Funnels**: `pack_opened` → `lesson_started` → `lesson_completed` — find where users drop off
3. **Retention**: % of users who return after day 1, 7, 30
4. **Dashboards**: pin your key metrics (DAU, lessons completed/day, quiz pass rate)
5. **Persons**: click any anonymous ID to see their full event history

---

## Step: Build checklist

Before building the production binary, complete the build checklist.

> **Refer to the dedicated build skill** — search available skills for "build" or "mobile build checklist". That skill contains the full pre-build checklist for Capacitor apps. Complete it before generating the iOS/Android binary.

PostHog-specific items to verify at build time:
- [ ] `VITE_POSTHOG_KEY` set in CI/CD build env, not committed to git
- [ ] `VITE_POSTHOG_HOST` set to EU endpoint if required (`https://eu.i.posthog.com`)
- [ ] `import.meta.env.PROD` guard in place — PostHog not initialized in dev
- [ ] `autocapture: false` and `capture_pageview: false` confirmed

---

## Step: Store submission checklist

Before submitting to the App Store or Google Play, complete the store submission checklist.

> **Refer to the dedicated store skill** — search available skills for "store" or "store submission checklist". That skill contains the full checklist for App Store and Google Play submissions. Complete it before submitting.
>
> **Important**: the store skill has a section for third-party SDKs / data collection. Add PostHog there: declare it as an analytics processor, specify that it collects anonymous usage events, and note the data storage location (EU cloud if using `eu.i.posthog.com`).

PostHog-specific items to verify at submission time:
- [ ] Privacy policy mentions PostHog as a data processor
- [ ] No PII in event properties — audit a sample of captured events in PostHog dashboard
- [ ] Opt-out flow implemented and reachable from app settings if required
- [ ] Offline buffering tested: airplane mode → trigger events → reconnect → verify arrival in dashboard
- [ ] Feature flags bootstrapped correctly (no flickering on first load)
