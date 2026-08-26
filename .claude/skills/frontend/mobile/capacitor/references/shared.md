# Shared — Cross-Platform Capacitor Reference

## 1. Viewport meta tag (required on both platforms)

```html
<meta
  name="viewport"
  content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover"
/>
```

- `viewport-fit=cover`: enables `env(safe-area-inset-*)` to return real values
- `user-scalable=no`: prevents accidental pinch-zoom in app-like UIs (remove if accessibility is a priority)

---

## 2. Scroll containers

```css
/* Root scroll */
html, body {
  height: 100%;
  overflow: hidden;         /* prevent double-scroll on mobile */
  overscroll-behavior: none;
}

/* Each scrollable panel */
.scroll-area {
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;  /* iOS momentum scroll */
  overscroll-behavior-y: contain;     /* prevent pull-to-refresh bubbling */
}
```

**Never put scroll on `<body>` in a Capacitor app.** Use a dedicated `.scroll-area` container so
fixed headers and bottom bars remain stable.

---

## 3. Dark mode

Both platforms pass `prefers-color-scheme` into the WebView.

```css
:root {
  --bg: #ffffff;
  --text: #1a1a1a;
  --surface: #f5f5f5;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #121212;
    --text: #e8e8e8;
    --surface: #1e1e1e;
  }
}
```

Then sync the status bar style when the mode changes:
```typescript
import { StatusBar, Style } from '@capacitor/status-bar';

const darkMQ = window.matchMedia('(prefers-color-scheme: dark)');
const syncStatusBar = (dark: boolean) =>
  StatusBar.setStyle({ style: dark ? Style.Light : Style.Dark });

syncStatusBar(darkMQ.matches);
darkMQ.addEventListener('change', e => syncStatusBar(e.matches));
```

---

## 4. Typography

```css
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-size-adjust: 100%;   /* prevent iOS auto-zoom on input focus */
}
```

**Minimum font sizes** (below these, users pinch-zoom or can't read):
- Body / labels: 16 px (1 rem)
- Secondary / captions: 13 px
- Never go below 12 px

---

## 5. Touch targets & interactions

```css
/* Minimum tap target — even if the visible element is smaller */
.tap-target {
  min-width: 48px;
  min-height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Remove tap highlight flash on Android */
* {
  -webkit-tap-highlight-color: transparent;
}

/* Provide your own tap feedback instead */
.btn:active {
  opacity: 0.7;
  transform: scale(0.97);
  transition: transform 0.1s ease, opacity 0.1s ease;
}
```

**Avoid `cursor: pointer`** — it adds a 300 ms delay on some older Android WebViews. Use
`touch-action: manipulation` to eliminate the delay:
```css
button, a, [role="button"] {
  touch-action: manipulation;
}
```

---

## 6. Animations

Use only `transform` and `opacity` for animated elements inside scrollable containers:

```css
/* ✅ GPU-composited, smooth */
.card-enter { transform: translateY(20px); opacity: 0; }
.card-enter-active { transform: translateY(0); opacity: 1; transition: transform 0.25s ease, opacity 0.25s ease; }

/* ❌ Causes layout reflow — jank on mobile */
.bad-enter { height: 0; margin-top: -20px; }
```

Respect reduced motion:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 7. Keyboard — shared patterns

```typescript
import { Keyboard } from '@capacitor/keyboard';

// Dismiss keyboard on tap outside
document.addEventListener('touchstart', (e) => {
  const target = e.target as HTMLElement;
  if (!target.closest('input, textarea, select')) {
    Keyboard.hide();
  }
});
```

**Input types cheat sheet:**

| Data | `type` | `inputmode` | Extra attrs |
|------|--------|-------------|-------------|
| Email | `email` | — | `autocorrect="off" autocapitalize="none"` |
| Password | `password` | — | — |
| Phone | `tel` | `tel` | — |
| Integer | `text` | `numeric` | `pattern="[0-9]*"` |
| Decimal | `text` | `decimal` | — |
| URL | `url` | — | `autocorrect="off"` |
| Search | `search` | `search` | — |

---

## 8. Orientation lock

In `capacitor.config.ts`:
```typescript
// Portrait only
android: {
  allowMixedContent: false,
},
ios: {
  // contentInset: 'automatic',
}
```

And in `AndroidManifest.xml`:
```xml
<activity android:screenOrientation="portrait" ...>
```

In `Info.plist` (iOS):
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
  <string>UIInterfaceOrientationPortrait</string>
</array>
```

---

## 9. Common Capacitor plugins reference

| Need | Plugin |
|------|--------|
| Status bar color/style | `@capacitor/status-bar` |
| Safe area insets (JS) | `@capacitor-community/safe-area` |
| Splash screen | `@capacitor/splash-screen` |
| Keyboard events & control | `@capacitor/keyboard` |
| Haptic feedback | `@capacitor/haptics` |
| App lifecycle (back button, resume) | `@capacitor/app` |
| Local storage (large data) | `@capacitor/preferences` or custom IndexedDB |
| Camera | `@capacitor/camera` |
| Filesystem | `@capacitor/filesystem` |
| Network status | `@capacitor/network` |
| Push notifications | `@capacitor/push-notifications` |

Install pattern:
```bash
npm install @capacitor/status-bar @capacitor/keyboard @capacitor/haptics @capacitor/app
npx cap sync
```

`@capacitor/status-bar` and `@capacitor-community/safe-area` **conflict** — don't install both. On
Android 15+ (`targetSdkVersion 35+`), edge-to-edge is OS-enforced and `env(safe-area-inset-*)` can
silently read `0` unless the safe-area plugin is installed *and* native edge-to-edge is enabled in
`MainActivity` — see `android.md` §1 for the exact fix and why (this bites on real devices/emulators,
not desktop Chrome, so it's easy to ship unnoticed).

---

## 10. Capacitor config template

`capacitor.config.ts`:
```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.yourcompany.appname',
  appName: 'AppName',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 0,
      backgroundColor: '#121212',
      showSpinner: false,
    },
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#121212',
    },
    Keyboard: {
      resize: 'body',      // 'body' | 'ionic' | 'native' | 'none'
      resizeOnFullScreen: true,
    },
  },
};

export default config;
```
