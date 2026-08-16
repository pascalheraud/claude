---
name: siemens-ix-react
description: Siemens iX design system for React — @siemens/ix-react setup with Vite, component usage, and integration conventions. For the framework-agnostic design system (packages overview, theming, icons), see the frontend/siemens-ix skill.
---

# Siemens iX — React integration

Builds on [[siemens-ix]] (packages overview, theming, icons — read that first). This skill covers React-specific setup and usage via `@siemens/ix-react`.

## Packages

```bash
npm install @siemens/ix @siemens/ix-react @siemens/ix-icons
```

`@siemens/ix-react` peer-depends on React 18 or 19 and `@siemens/ix-icons`, and depends on `@siemens/ix`.

---

## Setup (Vite + React)

1. **Set the theme attributes on `<html>`, in `index.html`.** This step is easy to skip and, if skipped, doesn't error — it just silently produces unstyled-looking components (plain borders, no iX colors/spacing/typography, looks like raw HTML rather than a design system). It's the single most common cause of "iX components render but look wrong":

```html
<!-- index.html -->
<!doctype html>
<html lang="en" data-ix-theme="classic" data-ix-color-schema="light">
  <head>…</head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

`data-ix-color-schema` is `light` or `dark`; `data-ix-theme` is the theme name (`classic` is iX's default — see [[siemens-ix]] for others). Source: the official starter's `index.html` (`github.com/siemens/ix-starter/blob/main/apps/react-starter/index.html`, fetched 2026-08-13) sets `data-ix-theme="classic" data-ix-color-schema="dark"`.

2. Import the iX base theme CSS once, globally (do not import it per-component), and register the custom-elements bridge at the app root, before rendering. The official starter's `main.tsx` only imports the CSS — `@siemens/ix-react`'s components self-register their underlying custom elements on import in current versions, so an explicit `defineCustomElements()` call is not required, but is harmless to keep if already present:

```tsx
// main.tsx
import { defineCustomElements as defineIxIcons } from '@siemens/ix-icons/loader'; // NOT '@siemens/ix-icons/dist/svg/icon-loader' — that path doesn't exist in 3.x
import { defineCustomElements } from '@siemens/ix/loader';
import '@siemens/ix/dist/siemens-ix/siemens-ix.css';
import './styles/global.scss';

defineIxIcons();
defineCustomElements();
```

3. Use React components from `@siemens/ix-react`, not the raw `<ix-*>` custom elements, so props stay typed and event handlers stay React-idiomatic:

```tsx
import { IxButton } from '@siemens/ix-react';

export function Toolbar() {
  return (
    <IxButton variant="primary" onClick={() => console.log('clicked')}>
      Save
    </IxButton>
  );
}
```

Scaffolding a fresh React app instead of adding iX to an existing one: `npx degit siemens/ix-starter/apps/react-starter my-app`.

---

## Application shell

<!-- Source: https://github.com/siemens/ix-starter/blob/main/apps/react-starter/src/App.tsx (fetched 2026-08-13) — the official React starter's real app shell, copied close to verbatim. -->

A real app (more than a single demo screen) is wrapped in `IxApplication`, not rendered bare — it's the component that owns breakpoints, theming, and app-switch configuration, and its slots (`application-header`, `menu`, `default`) are what every other layout component composes into. The React wrapper auto-assigns slots by component type — no explicit `slot="..."` prop needed:

```tsx
import {
  IxApplication,
  IxApplicationHeader,
  IxAvatar,
  IxMenu,
  IxMenuItem,
  IxContent,
} from '@siemens/ix-react';
import { iconHome, iconGroup } from '@siemens/ix-icons/icons';

function App() {
  const navigate = useNavigate();
  const location = useLocation();
  const isActive = (path: string) => location.pathname === path;

  return (
    <IxApplication>
      <IxApplicationHeader name="My app">
        <IxAvatar initials="JD" aria-label="User avatar: JD" />
      </IxApplicationHeader>

      <IxMenu enableToggleTheme aria-label="Main navigation">
        <IxMenuItem
          icon={iconHome}
          active={isActive('/')}
          onClick={(e) => { e.preventDefault(); navigate('/'); }}
        >
          Home
        </IxMenuItem>
        <IxMenuItem
          icon={iconGroup}
          active={isActive('/groups')}
          onClick={(e) => { e.preventDefault(); navigate('/groups'); }}
        >
          Groups
        </IxMenuItem>
      </IxMenu>

      <IxContent id="main-content">
        {/* routed/page content goes here */}
      </IxContent>
    </IxApplication>
  );
}
```

Notes:
- `IxMenuItem`'s icon prop takes an **imported icon constant** from `@siemens/ix-icons/icons` (e.g. `iconHome`, `iconGroup` — the export name is `icon` + PascalCase of the SVG file name under `@siemens/ix-icons/svg/`), not a bare string like `icon="home"`.
- The menu item's label is its `children`, not a `label` prop, in this usage pattern (the component also accepts a `label` prop for the tooltip/collapsed-state text — pass both if the menu can collapse to icon-only).
- A page inside `IxContent` typically starts with an `IxContentHeader` (`headerTitle`, optional `hasBackButton`/`onBackButtonClick`) before its own content — see `/docs/components/content-header` in [[siemens-ix]]'s [component catalog](../../siemens-ix/references/components.md).
- A single-screen gate (e.g. an onboarding/sign-in form shown before the real app exists) is reasonably rendered *outside* `IxApplication` — there's no menu or multi-page nav to frame yet.

---

## Icons

```tsx
import { IxIcon } from '@siemens/ix-react';

<IxIcon name="save" />
```

---

## Rules summary

| Rule | Detail |
|---|---|
| Set theme attributes on `<html>` | `data-ix-theme`/`data-ix-color-schema` in `index.html` — missing this silently produces unstyled-looking components, not an error |
| Use the React wrapper | Import from `@siemens/ix-react`, not raw `<ix-*>` custom elements |
| Register once | The base CSS import (and `defineCustomElements()` if kept) happens once at app root |
| Wrap a real app in `IxApplication` | See "Application shell" above — a multi-screen app isn't rendered bare |
| Icons via `IxIcon` | See [[siemens-ix]] for the general icon rule |
| Theming | See [[siemens-ix]] — no React-specific theming mechanism beyond the shared design tokens and the `<html>` attributes above |
