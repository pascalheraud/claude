---
name: frontend-mobile-capacitor
description: >
  Use this skill whenever building, designing, or reviewing UI/UX for a Capacitor app targeting
  Android and/or iOS. Triggers include: any mention of Capacitor, Ionic, mobile app with React/Vue/Angular,
  WebView-based mobile app, cross-platform app for Android or iPhone, mentions of safe area, status bar,
  back button handling, mobile gestures, or splash screen. Also trigger when the user asks about
  performance in a mobile WebView, keyboard handling on mobile, dark mode on Android/iOS, or any CSS/layout
  issue that sounds like a mobile app context. When in doubt and a mobile context is likely, trigger this skill.
---

# Capacitor Mobile — Android & iOS Design Skill

Capacitor wraps a web app in a native WebView. The browser is mostly standard Chromium (Android) or
WebKit (iOS), but the native shell introduces constraints that a pure web app never sees. This skill
covers the full set of pitfalls and best practices so every screen feels intentional on both platforms.

Read the relevant reference file(s) before writing any platform-specific code:
- **Android specifics** → `references/android.md`
- **iOS specifics** → `references/ios.md`
- **Shared / cross-platform** → `references/shared.md`
- **React + Capacitor** → `references/react.md`
- **Soumission App Store / Google Play** → `references/store.md`

---

## Quick decision map

| Situation | Go to |
|-----------|-------|
| Back button, status bar color, nav bar insets | `references/android.md` |
| Safe area, home indicator, swipe-back gesture | `references/ios.md` |
| Scroll performance, keyboard, dark mode, fonts | `references/shared.md` |
| Splash screen, app icon, orientation lock | Both platform files |
| Service / plugin selection (Camera, FS, etc.) | `references/shared.md` → Plugins section |
| Listener cleanup, StrictMode, useEffect + plugins | `references/react.md` |
| Back button + React Router | `references/react.md` |
| Custom hooks (keyboard, network, app state) | `references/react.md` |
| Listes longues, React.memo, lazy routes | `references/react.md` |
| IndexedDB + React state pattern | `references/react.md` |
| Vite config (`base: './'`, sourcemaps, target) | `references/react.md` |
| Permissions, politique de confidentialité, IAP | `references/store.md` |
| Screenshots, metadata, review process | `references/store.md` |
| targetSdkVersion, AAB, Data Safety, versionCode | `references/store.md` |

---

## Non-negotiable rules (apply everywhere)

1. **Never use `px` for touch targets.** Use `rem` or design-token variables. Minimum tap target: 48 × 48 dp (Android) / 44 × 44 pt (iOS).
2. **Always handle safe area insets** with `env(safe-area-inset-*)`. Add `viewport-fit=cover` to the meta viewport tag.
3. **Never rely on `:hover` alone** for interactive feedback. Use `:active` for tap states.
4. **Test with the real keyboard**, not a simulator. Keyboard appearance changes scroll behavior differently per platform.
5. **Respect `prefers-color-scheme`** — Android and iOS both propagate the OS dark mode into the WebView.
6. **Use only `transform` / `opacity` for animations** inside lists or scroll containers. Avoid animating `height`, `width`, `top`, `left`.

---

## Checklist before shipping a screen

**Plateforme**
- [ ] Safe area insets applied (top, bottom, sides)
- [ ] Status bar color set via `@capacitor/status-bar`
- [ ] Android back button handled (or Capacitor default behaviour confirmed intentional)
- [ ] Touch targets ≥ 48 dp / 44 pt
- [ ] Scroll containers use `-webkit-overflow-scrolling: touch` + `overscroll-behavior: contain`
- [ ] No fixed-position elements obscured by keyboard on Android
- [ ] Dark mode tested on both platforms
- [ ] Splash screen assets generated for all densities
- [ ] Font rendering checked on a real mid-range Android device

**React**
- [ ] Tous les `addListener` Capacitor ont un cleanup dans le `useEffect` return
- [ ] Back button connecté à `navigate(-1)` (React Router), pas à `window.history.back()`
- [ ] Plugins natifs appelés uniquement dans `useEffect` ou event handlers (jamais pendant le render)
- [ ] `vite.config.ts` a `base: './'` et `sourcemap: false`
- [ ] `npx cap sync` exécuté après le build
- [ ] Listes longues virtualisées si > ~50 items
- [ ] App resume (`appStateChange`) rafraîchit les données si nécessaire

**Store (avant chaque soumission)**
- [ ] `server.url` retiré de `capacitor.config.ts`
- [ ] Version et build number incrémentés
- [ ] App testée en mode release sur un vrai appareil
- [ ] Permissions déclarées = permissions réellement utilisées
- [ ] Politique de confidentialité en ligne et déclarée
- [ ] iOS : screenshots iPhone 6.9" fournis, compte de démo si login requis
- [ ] Android : `targetSdkVersion` à jour, AAB uploadé, Data Safety remplie
