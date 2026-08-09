# iOS — Capacitor Design Reference

## 1. Safe area & notch

iOS introduced the notch (iPhone X+) and Dynamic Island (iPhone 14 Pro+). The home indicator bar
sits at the bottom. **Without proper safe area handling, content will be hidden under these elements.**

### Required meta tag
```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```
Without `viewport-fit=cover`, `env(safe-area-inset-*)` returns 0 and the WebView leaves white
margins — not what you want on a full-bleed design.

### CSS variables
```css
:root {
  --safe-top:    env(safe-area-inset-top);     /* ~44–59px depending on device */
  --safe-bottom: env(safe-area-inset-bottom);  /* ~34px (home indicator) or 0 */
  --safe-left:   env(safe-area-inset-left);    /* ~0 portrait, ~44px landscape */
  --safe-right:  env(safe-area-inset-right);
}

.header {
  padding-top: calc(var(--safe-top) + 16px);
}

.tab-bar {
  padding-bottom: var(--safe-bottom);
}
```

---

## 2. Status bar

```typescript
import { StatusBar, Style } from '@capacitor/status-bar';

// Light content (white icons) for dark headers
await StatusBar.setStyle({ style: Style.Light });

// iOS: setBackgroundColor has no effect — the status bar is always transparent
// Instead control the appearance via StatusBar.setStyle()
```

**iOS gotcha**: `StatusBar.setBackgroundColor()` does nothing on iOS. The background comes from
whatever is rendered under the status bar area. Design your header to extend under it.

---

## 3. Swipe-back gesture

iOS users expect the swipe-from-left-edge gesture to go back. Capacitor's WKWebView forwards it to
the WebView history by default. This is usually correct, but can conflict with:
- Custom drawer components that open from the left
- Horizontal carousels at the left edge of the screen

If you need to disable the system swipe-back for a specific screen, do it via a Capacitor plugin or
native code — you cannot suppress it from CSS/JS.

**Design rule**: avoid placing the primary drag handle of a left-drawer within 20 pt of the left
edge. Give users a button alternative.

---

## 4. Keyboard behaviour

iOS uses `adjustPan` semantics by default in WKWebView — the whole page scrolls up to reveal the
focused input. There is no `adjustResize` equivalent.

```typescript
import { Keyboard } from '@capacitor/keyboard';

// iOS emits keyboardWillShow with the keyboard height
Keyboard.addListener('keyboardWillShow', ({ keyboardHeight }) => {
  document.documentElement.style.setProperty('--keyboard-height', `${keyboardHeight}px`);
});
Keyboard.addListener('keyboardWillHide', () => {
  document.documentElement.style.setProperty('--keyboard-height', '0px');
});
```

For forms that sit above a fixed bottom bar:
```css
.bottom-bar {
  position: fixed;
  bottom: calc(var(--keyboard-height, 0px) + var(--safe-bottom));
  transition: bottom 0.25s ease;
}
```

**Input type hints** that open the right keyboard:
```html
<input type="email" autocomplete="email" autocorrect="off" autocapitalize="none">
<input type="tel" inputmode="tel">
<input type="text" inputmode="numeric" pattern="[0-9]*">
```

---

## 5. WKWebView rendering quirks

iOS uses WKWebView (WebKit), **not** Chromium. Key differences:

| Feature | Chrome (Android) | WebKit (iOS) |
|---------|-----------------|--------------|
| `backdrop-filter` | Partially supported | Fully supported |
| CSS `gap` in flex | ✅ | ✅ (Safari 14.5+) |
| `position: sticky` in overflow containers | ✅ | ⚠️ Buggy — avoid |
| Scroll momentum | Manual via `-webkit-overflow-scrolling` | Native feel built-in |
| `overscroll-behavior` | ✅ | Partial |

For scrollable panels in iOS, always add:
```css
.scroll-panel {
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}
```

Without `-webkit-overflow-scrolling: touch`, inner scrollable divs feel sluggish on iOS.

---

## 6. Home indicator & landscape

The home indicator bar (bottom) is always present on notch-era iPhones. In landscape, safe area
insets shift to left/right (for the notch). Always apply both horizontal and vertical insets
if your app supports landscape.

```css
.full-screen-container {
  padding-top:    env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
  padding-left:   env(safe-area-inset-left);
  padding-right:  env(safe-area-inset-right);
}
```

---

## 7. Haptics

iOS users expect haptic feedback on significant interactions (selection, confirmation, error).
Capacitor provides this natively:

```typescript
import { Haptics, ImpactStyle, NotificationType } from '@capacitor/haptics';

// Light tap for selection
await Haptics.impact({ style: ImpactStyle.Light });

// Success / error feedback
await Haptics.notification({ type: NotificationType.Success });
await Haptics.notification({ type: NotificationType.Error });
```

Android also supports haptics via the same API (uses `VibrationEffect` under the hood).

---

## 8. Splash screen (iOS)

iOS requires a LaunchScreen storyboard. Capacitor handles this automatically:

```bash
npx @capacitor/assets generate --ios
```

Place a 1024×1024 icon (`icon.png`) and a 2732×2732 splash (`splash.png`) in `assets/` — the
generator produces all required sizes.

`capacitor.config.ts`:
```typescript
SplashScreen: {
  launchShowDuration: 0,   // 0 = hide immediately (recommended — avoids flash)
  backgroundColor: '#1A1A2E',
  iosSpinnerStyle: 'small',
  showSpinner: false,
}
```

---

## 9. Font rendering

Safari/WebKit renders fonts slightly heavier than Chrome. If you use a thin or light weight, check
it on a real iPhone — it may look thinner than intended and hurt legibility.

```css
body {
  -webkit-font-smoothing: antialiased; /* macOS/iOS: thinner rendering */
  text-rendering: optimizeLegibility;
}
```

Avoid system font stack differences by either bundling your font or accepting the native system font:
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
```
