# Android — Capacitor Design Reference

## 1. System bars & insets

### Status bar
```typescript
// Set color and style on every route change
import { StatusBar, Style } from '@capacitor/status-bar';

await StatusBar.setStyle({ style: Style.Dark }); // light icons on dark bg
await StatusBar.setBackgroundColor({ color: '#1A1A2E' });

// Make status bar translucent (content bleeds under it — you handle insets)
await StatusBar.setOverlaysWebView({ overlay: true });
```

### Navigation bar (bottom)
Android's 3-button or gesture nav bar sits at the bottom. Its height varies by device (typically 48 dp).
```css
/* Always account for it */
.screen-root {
  padding-bottom: env(safe-area-inset-bottom);
}
```

Use the **Safe Area plugin** for reliable values at runtime:
```bash
npm install @capacitor/status-bar
```
Then in CSS:
```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```
```css
:root {
  --safe-top: env(safe-area-inset-top);
  --safe-bottom: env(safe-area-inset-bottom);
}
```

---

## 2. Back button

Android's physical/gesture back button fires a Capacitor event. Not handling it means the WebView
navigates back in its history — or closes the app on the root screen.

```typescript
import { App } from '@capacitor/app';

App.addListener('backButton', ({ canGoBack }) => {
  if (!canGoBack) {
    App.exitApp();   // or show an "exit?" dialog
  } else {
    window.history.back();
  }
});
```

**SPA routers**: if you use React Router or similar, replace `window.history.back()` with your
router's navigate(-1) so state stays consistent.

Remove listeners on component unmount to avoid stacking duplicates.

---

## 3. Keyboard behaviour

Android has two modes set in `AndroidManifest.xml`:

| Mode | Effect |
|------|--------|
| `adjustResize` | Viewport shrinks — content reflows above keyboard |
| `adjustPan` | Viewport pans up — useful for single-field screens |

Default Capacitor sets `adjustResize`. This is usually correct. Problems arise when:
- A fixed bottom bar gets pushed up with the content (use `position: fixed` carefully)
- A scrollable list loses its bottom padding behind the keyboard

Fix for fixed bottom bars with `adjustResize`:
```css
.bottom-bar {
  position: fixed;
  bottom: 0;
  /* Let JS set this when keyboard opens */
}
```
```typescript
import { Keyboard } from '@capacitor/keyboard';

Keyboard.addListener('keyboardWillShow', info => {
  document.documentElement.style.setProperty('--keyboard-height', `${info.keyboardHeight}px`);
});
Keyboard.addListener('keyboardWillHide', () => {
  document.documentElement.style.setProperty('--keyboard-height', '0px');
});
```

---

## 4. Gesture navigation (Android 10+)

Swipe from left/right edges triggers the system back gesture — not a Capacitor event. If your UI
has interactive elements near the edges (drawer handle, side swipe), you must declare exclusion zones
via the `android:windowLayoutInDisplayCutoutMode` setting, or rethink the placement.

Practical rule: **keep interactive elements at least 20 dp from screen edges**.

---

## 5. Screen densities

Android devices range from mdpi (160 dpi) to xxxhdpi (640 dpi). Never use `px` for spacing or touch
targets. Use:
- CSS: `rem`, `em`, `vh`, `vw`
- Images: SVG or a density-bucketed set (`@2x`, `@3x` in WebP)

For app icons and splash screens, generate all densities:
```bash
npx @capacitor/assets generate --android
```
This produces mipmap-mdpi → mipmap-xxxhdpi from a single 1024×1024 source.

---

## 6. WebView version & CSS compatibility

Capacitor uses the **system WebView** (Android System WebView / Chrome), which updates independently
of the OS. Minimum supported version for Capacitor 5+ is Chrome 60+.

Avoid or polyfill:
- CSS `backdrop-filter` (heavy on mid-range devices; test before shipping)
- CSS Container Queries (available Chrome 105+, but older devices may lag)
- Web Animations API complex sequences

Test CSS features at: https://caniuse.com — filter by "Chrome for Android".

---

## 7. Performance tips specific to Android

- **Avoid GPU-composited layers on long lists.** `will-change: transform` on every list item causes
  memory pressure on low-RAM devices (2 GB is still common in emerging markets).
- **Use `contain: layout style`** on card/list item components to limit paint scope.
- **Disable rubber-band scroll** at the root to avoid the grey overshoot flicker:
  ```css
  html, body {
    overscroll-behavior: none;
  }
  ```
- **Image decoding**: add `decoding="async"` to all `<img>` tags in lists.

---

## 8. Splash screen (Android)

```bash
npm install @capacitor/splash-screen
npx cap sync
```

`capacitor.config.ts`:
```typescript
SplashScreen: {
  launchShowDuration: 2000,
  backgroundColor: '#1A1A2E',
  androidSplashResourceName: 'splash',
  showSpinner: false,
}
```

Hide programmatically when the app is ready (not on a timer):
```typescript
import { SplashScreen } from '@capacitor/splash-screen';
// After data/fonts loaded:
await SplashScreen.hide();
```
