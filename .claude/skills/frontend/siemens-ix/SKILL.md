---
name: siemens-ix
description: Siemens iX (Industrial Experience) design system — framework-agnostic overview, npm packages, theming, and icons, built on Stencil web components. For React-specific setup and usage, see the frontend/react/siemens-ix-react skill.
---

# Siemens iX — Design system

## Purpose

Siemens iX is Siemens' open-source design system for industrial-context UIs. Components are implemented once as framework-agnostic web components (Stencil) and exposed through thin per-framework wrapper packages (React, Angular, Vue) plus a Blazor integration. Prefer an iX component over a hand-rolled one whenever iX already covers the need; only build a custom component when it doesn't.

Docs: https://ix.siemens.io/docs/home/overview — components list at `/docs/components/overview`, icons at `/docs/icons/icon-library`, styling/theming at `/docs/styles/colors`.

Full categorized component catalog (name, React export, doc URL, sourced from `/docs/components/overview`): [components.md](references/components.md). Check it before building a custom component — iX likely already has it.

Framework-specific setup and usage:
- React: [[siemens-ix-react]]

---

## Packages

| Package | Purpose |
|---|---|
| `@siemens/ix` | Core web components (Stencil) — framework-agnostic, required by every framework wrapper |
| `@siemens/ix-react` | React wrapper components/hooks |
| `@siemens/ix-angular` | Angular wrapper components/directives |
| `@siemens/ix-vue` | Vue wrapper components |
| `@siemens/ix-icons` | Icon set, used via icon name strings or the `<ix-icon>` element |
| `@siemens/ix-echarts` | Optional — iX theme for ECharts, only if the project uses ECharts |
| `@siemens/ix-aggrid` | Optional — iX theme for AG Grid, only if the project uses AG Grid |

Scaffolding a fresh app instead of adding iX to an existing one: `npx degit siemens/ix-starter/apps/<framework>-starter my-app` gives a preconfigured shell (theming, light/dark toggle, example pages) — useful as a reference, not required for an existing app.

---

## Theming

- iX ships light and dark themes out of the box; toggle per the docs at `/docs/styles/colors` rather than hand-rolling a competing theme system.
- Prefer iX design tokens (CSS custom properties) over hardcoded colors/spacing when styling around iX components, so custom CSS/SCSS stays visually consistent with the library.
- Don't override iX component internals with deep CSS selectors — use the documented component props/slots first; only fall back to CSS custom properties if the component exposes them for that purpose.

---

## Icons

Use `@siemens/ix-icons` names with the `<ix-icon>` element (or an icon prop on components that accept one) instead of inlining SVGs.

---

## Rules summary

| Rule | Detail |
|---|---|
| Reach for iX first | Only build a custom component when iX genuinely doesn't cover the need |
| Icons via `@siemens/ix-icons` | No inlined/duplicated SVGs for icons the library already has |
| Theme via iX tokens | Don't build a parallel color/spacing system for iX-adjacent custom styles |
| Framework wrapper over raw elements | Use the framework's wrapper package (e.g. [[siemens-ix-react]]) instead of the raw `<ix-*>` custom elements directly, for typed props and idiomatic event handling |
