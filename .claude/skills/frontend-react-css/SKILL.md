---
name: frontend-react-css
description: React CSS conventions — SCSS Modules with one file per component, shared variables, clsx for conditional classes, and Vite path alias for variables
---

# React CSS — Skill

## Purpose

This skill defines how to write styles in a React + TypeScript project using **SCSS Modules**. Each component owns its styles. Shared design values live in a single variables file.

---

## Setup

```bash
npm install -D sass clsx
```

Vite supports SCSS natively once `sass` is installed — no additional configuration required.

---

## File structure

```
src/
  styles/
    _variables.scss   ← shared design values (colours, typography, spacing)
    _base.scss        ← minimal global resets
    global.scss       ← entry point — imports variables and base

  ui/atoms/
    Button.tsx
    Button.module.scss

  features/shop/
    ProductCard.tsx
    ProductCard.module.scss
```

One `.module.scss` file per component, colocated with the component file.

---

## Global styles

### `styles/_variables.scss`

All shared design values. Import this file in every module that needs a variable.

```scss
// Colours
$color-primary:        #0369A1;
$color-primary-hover:  #0284C7;
$color-primary-light:  #E0F2FE;

$color-success:        #10B981;
$color-success-light:  #F0FDF4;

$color-error:          #EF4444;
$color-error-light:    #FEF2F2;

$color-warning:        #F59E0B;
$color-warning-light:  #FEF3C7;

$color-surface:        #FFFFFF;
$color-bg:             #F1F5F9;
$color-border:         #E2E8F0;
$color-border-strong:  #CBD5E1;

$color-text-primary:   #0F172A;
$color-text-secondary: #475569;
$color-text-muted:     #94A3B8;
$color-text-on-dark:   #FFFFFF;

// Typography
$font-family:          system-ui, -apple-system, sans-serif;
$font-size-xs:         0.72rem;
$font-size-sm:         0.82rem;
$font-size-md:         0.95rem;
$font-size-lg:         1.1rem;
$font-size-xl:         1.4rem;

$font-weight-normal:   400;
$font-weight-medium:   500;
$font-weight-bold:     700;

$line-height-tight:    1.2;
$line-height-normal:   1.5;

// Spacing
$space-1:  4px;
$space-2:  8px;
$space-3:  12px;
$space-4:  16px;
$space-5:  20px;
$space-6:  24px;
$space-8:  32px;
$space-10: 40px;

// Border radius
$radius-sm:   6px;
$radius-md:   12px;
$radius-lg:   16px;
$radius-full: 9999px;

// Shadows
$shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.06);
$shadow-md: 0 4px 12px rgba(0, 0, 0, 0.08);
$shadow-lg: 0 8px 24px rgba(0, 0, 0, 0.12);

// Transitions
$transition-fast:   120ms ease;
$transition-normal: 200ms ease;
$transition-slow:   350ms ease;

// Z-index scale
$z-base:    0;
$z-overlay: 100;
$z-modal:   200;
$z-toast:   300;
```

### `styles/_base.scss`

Minimal resets — only what is genuinely needed in 2026.

```scss
*, *::before, *::after {
  box-sizing: border-box;   // universal, essential
}

body {
  margin: 0;                // browsers add 8px by default
}

img, video {
  max-width: 100%;
  display: block;           // removes gap below images
}

button {
  cursor: pointer;
  border: none;
  background: none;
  font: inherit;            // buttons don't inherit font by default
  padding: 0;
}

a {
  color: inherit;
  text-decoration: none;
}

ul, ol {
  list-style: none;
  margin: 0;
  padding: 0;
}

h1, h2, h3, h4, h5, h6, p {
  margin: 0;                // removes browser default margins
}
```

### `styles/global.scss`

```scss
@use 'variables' as *;
@use 'base';

body {
  font-family:      $font-family;
  font-size:        $font-size-md;
  line-height:      $line-height-normal;
  background-color: $color-bg;
  color:            $color-text-primary;
  -webkit-font-smoothing: antialiased;
}
```

### `main.tsx`

```tsx
import './styles/global.scss';
```

---

## Component styles

### One module per component

```
ProductCard.tsx
ProductCard.module.scss   ← scoped to this component only
```

### Importing variables

```scss
// ProductCard.module.scss
@use '../../styles/variables' as *;  // adjust path as needed

.card {
  background:    $color-surface;
  border:        1.5px solid $color-border;
  border-radius: $radius-md;
  padding:       $spacing-md;        // use variables, never magic numbers
  transition:    box-shadow $transition-normal, transform $transition-normal;

  &:hover {
    box-shadow: $shadow-md;
    transform:  translateY(-2px);
  }
}
```

### SCSS nesting — keep it shallow

Use nesting for states and pseudo-classes. Do not go deeper than 3 levels.

```scss
// ✅ shallow nesting — clear and maintainable
.card {
  background: $color-surface;

  &:hover          { box-shadow: $shadow-md; }   // hover state
  &:focus-visible  { outline: 2px solid $color-primary; }

  &.selected       { border-color: $color-primary; }
  &.disabled       { opacity: 0.5; cursor: default; }
}

.title {
  font-size:   $font-size-md;
  font-weight: $font-weight-bold;
  color:       $color-text-primary;
}

// ❌ too deep — hard to read
.card {
  .header {
    .title {
      span { … }   // 4 levels deep
    }
  }
}
```

### BEM-inspired naming (without the verbose syntax)

Name classes after their role within the component. Since CSS Modules scopes everything automatically, you do not need the full BEM `block__element--modifier` syntax.

```scss
// ✅ clear, no BEM verbosity needed — CSS Modules handles scoping
.card      { … }
.header    { … }
.title     { … }
.subtitle  { … }
.footer    { … }
.badge     { … }

// Modifiers as extra classes
.card.selected  { … }
.card.disabled  { … }
.title.large    { … }
```

---

## Mixins — only for real shared property groups

Don't reach for a mixin just because two components share a variable value — that's what shared variables in `_variables.scss` are for. Add a mixin only when multiple components share the same *group* of property declarations (not just one value), e.g. several components all needing the same flex-centering + transition + disabled-state block. One `.module.scss` file still owns the component's unique styles; the mixin only factors out the literally-identical block.

```scss
// styles/_mixins.scss
@use "variables" as *;   // mixins need their own @use even if variables are globally injected

@mixin button-base {
  display:         inline-flex;
  align-items:     center;
  justify-content: center;
  transition:      opacity $transition-fast, transform $transition-fast;

  &.disabled { opacity: 0.5; cursor: not-allowed; pointer-events: none; }
}
```

```scss
// Button.module.scss
.btn {
  @include button-base;
  gap: $btn-icon-gap;
  // ...component-specific styles
}
```

If using the Vite path-alias setup below, register `_mixins.scss` alongside `_variables.scss` so every module gets both without an explicit `@use`:

```ts
additionalData: `@use "${path.resolve(__dirname, 'styles/variables')}" as *; @use "${path.resolve(__dirname, 'styles/mixins')}" as *;`,
```

---

## Conditional classes — clsx

Use `clsx` to combine class names. More readable than template literals.

```tsx
import clsx from 'clsx';
import styles from './ProductCard.module.scss';

export function ProductCard({ isSelected, isDone, isDisabled }: ProductCardProps) {
  return (
    <div className={clsx(
      styles.card,
      isSelected  && styles.selected,
      isDone      && styles.done,
      isDisabled  && styles.disabled,
    )}>
      …
    </div>
  );
}
```

---

## Full example

**`features/shop/ProductCard.module.scss`**

```scss
@use '../../styles/variables' as *;

.card {
  background:    $color-surface;
  border:        1.5px solid $color-border;
  border-radius: $radius-md;
  padding:       $space-4;
  cursor:        pointer;
  transition:    box-shadow $transition-normal, transform $transition-normal;

  &:hover {
    box-shadow: $shadow-md;
    transform:  translateY(-2px);
  }

  &.done {
    background:    $color-success-light;
    border-color:  $color-success;
  }

  &.selected {
    border-color: $color-primary;
    box-shadow:   0 0 0 3px $color-primary-light;
  }
}

.header {
  display:     flex;
  align-items: center;
  gap:         $space-3;
}

.title {
  font-size:   $font-size-md;
  font-weight: $font-weight-bold;
  color:       $color-text-primary;
}

.subtitle {
  font-size:  $font-size-sm;
  color:      $color-text-muted;
  margin-top: $space-1;
}

.price {
  font-size:   $font-size-lg;
  font-weight: $font-weight-bold;
  color:       $color-primary;
  margin-top:  $space-3;
}
```

**`features/shop/ProductCard.tsx`**

```tsx
import clsx from 'clsx';
import styles from './ProductCard.module.scss';
import type { Product } from '@/models';

interface ProductCardProps {
  product:    Product;
  isSelected?: boolean;
  isDone?:     boolean;
  onClick:     () => void;
}

export function ProductCard({ product, isSelected, isDone, onClick }: ProductCardProps) {
  return (
    <div
      className={clsx(styles.card, isSelected && styles.selected, isDone && styles.done)}
      onClick={onClick}
    >
      <div className={styles.header}>
        <div>
          <p className={styles.title}>{product.name}</p>
          <p className={styles.subtitle}>{product.category}</p>
        </div>
      </div>
      <p className={styles.price}>{product.price} €</p>
    </div>
  );
}
```

---

## Path alias for variables

To avoid `../../styles/variables` in every file, add an alias in `vite.config.ts`:

```ts
// vite.config.ts
css: {
  preprocessorOptions: {
    scss: {
      additionalData: `@use "${path.resolve(__dirname, 'src/styles/variables')}" as *;`
    }
  }
}
```

This automatically imports variables into every `.module.scss` file — no `@use` needed:

```scss
// ✅ variables available without explicit import
.card {
  background: $color-surface;
  padding:    $space-4;
}
```

### Avoid the deprecated legacy Sass JS API

The plain `sass` package defaults to its legacy JS API under Vite, which logs a `DEPRECATION WARNING [legacy-js-api]` for every compiled file and will be removed in Dart Sass 2.0.0. Opt into the modern API explicitly:

```ts
// vite.config.ts
css: {
  preprocessorOptions: {
    scss: {
      api: 'modern', // or 'modern-compiler' if using the `sass-embedded` package
      additionalData: `@use "${path.resolve(__dirname, 'src/styles/variables')}" as *;`
    }
  }
}
```

---

## Rules summary

| Rule | Detail |
|------|--------|
| One `.module.scss` per component | Colocated with the `.tsx` file |
| Always use variables | No magic numbers or hardcoded colours |
| Nesting max 3 levels | States and pseudo-classes only |
| Flat class names | BEM verbosity not needed — CSS Modules scopes automatically |
| Conditional classes | Use `clsx`, not template literals |
| No global styles in modules | Global rules go in `global.scss` only |
| Variables path alias | Configure in `vite.config.ts` to avoid long relative paths |
