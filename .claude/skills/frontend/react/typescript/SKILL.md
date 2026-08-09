---
name: typescript
description: React + TypeScript conventions — named exports, Props interface, no business logic in components, services as pure TS, hooks for side effects only, avoid any, shared models.ts. For framework-agnostic TypeScript conventions (e.g. check-only `tsc` usage), see [[languages/typescript]].
---

# React + TypeScript — Component Architecture Skill

## Purpose

Guidelines for writing React components, hooks and services in a TypeScript + Vite project. Apply these rules before creating any new file.

---

## File conventions

| Element | Convention | Extension |
|---------|-----------|-----------|
| Component | PascalCase | `.tsx` |
| Hook | camelCase, prefixed `use` | `.ts` |
| Service (pure logic) | camelCase | `.ts` |
| Context | PascalCase suffixed `Context` | `.tsx` |
| Test without JSX | same name suffixed `.test` | `.ts` |
| Test with JSX | same name suffixed `.test` | `.tsx` |
| Barrel | `index` | `.ts` |

Files containing JSX use `.tsx`. Files without JSX use `.ts`.

---

## Exports

Always use **named exports**. Avoid default exports — they are harder to refactor and grep.

```tsx
// ✅
export function UserCard({ name }: UserCardProps) { … }

// ❌
export default function UserCard() { … }
```

Each folder exposes a barrel `index.ts`:

```ts
export { UserCard } from './UserCard';
export { UserList } from './UserList';
```

---

## Components

### Props interface

Define a `Props` interface in the same file, directly above the component.

```tsx
interface UserCardProps {
  name:      string;
  avatar?:   string;
  isActive?: boolean;
  onClick:   () => void;
}

export function UserCard({ name, avatar, isActive = false, onClick }: UserCardProps) {
  …
}
```

### Props naming conventions

| Case | Convention | Example |
|------|-----------|---------|
| Optional prop | `?` suffix | `avatar?: string` |
| Event callback | `on` + PascalCase | `onClick`, `onClose`, `onSubmit` |
| Boolean flag | `is` or `has` prefix | `isActive`, `hasError`, `isLoading` |
| Render children | `React.ReactNode` | `children: React.ReactNode` |

### No business logic in components

Components handle **rendering and local UI state only**. Business logic goes in services.

```tsx
// ✅ component calls a service
function handleSubmit() {
  const result = validateForm(formData);
  setError(result.error ?? null);
}

// ❌ business logic inline in component
function handleSubmit() {
  if (!formData.email.includes('@')) setError('Invalid email');
  if (formData.password.length < 8) setError('Too short');
  …
}
```

---

## Services

Services are **pure TypeScript** — no React, no side effects beyond their explicit purpose.

```ts
// ✅ pure function — deterministic, testable
export function computeScore(answers: Answer[]): number {
  return answers.filter(a => a.correct).length;
}

// ❌ never import React hooks in a service
import { useState } from 'react';
```

---

## Hooks

Hooks handle **side effects only**: network fetch, timers, browser APIs.
Business logic lives in services.

```ts
// ✅ hook handles the side effect, delegates logic to a service
export function useScore(answers: Answer[]) {
  const [score, setScore] = useState<number | null>(null);

  useEffect(() => {
    setScore(computeScore(answers));
  }, [answers]);

  return score;
}

// ❌ business logic should not live in a hook
export function useScore(answers: Answer[]) {
  useEffect(() => {
    let s = 0;
    for (const a of answers) { if (a.correct) s++; }  // ← belongs in a service
    setScore(s);
  }, [answers]);
}
```

---

## Component + service pattern (recommended)

Use `useState` in the component and call services directly. Avoid wrapping everything in a custom hook unless the side effect is reused in multiple components.

```tsx
import { useState } from 'react';
import { computeScore, rankAnswers } from '@services/quiz';
import { storageSet } from '@services/storage';

export function QuizScreen({ questions, onDone }: QuizScreenProps) {
  const [answers,   setAnswers]   = useState<Answer[]>([]);
  const [validated, setValidated] = useState(false);

  function handleSubmit() {
    const score  = computeScore(answers);
    const ranked = rankAnswers(answers, questions);
    storageSet('quiz:last', { score, ranked });
    setValidated(true);
    if (score === questions.length) onDone();
  }

  …
}
```

---

## State management

| State type | Location |
|-----------|----------|
| Local UI state (open/closed, selected, error) | `useState` in the component |
| Derived state | Compute inline, no extra `useState` |
| Cross-component state | React Context |
| Server / async state | `useState` + `useEffect` or a data-fetching hook |
| Complex state with transitions | `useReducer` |

---

## Contexts

Use a Context when state needs to be accessed by many components at different nesting levels.

```tsx
interface UserLangContextValue {
  userLang:    string;
  setUserLang: (lang: string) => void;
}

export const UserLangContext = createContext<UserLangContextValue | null>(null);

export function useUserLang(): UserLangContextValue {
  const ctx = useContext(UserLangContext);
  if (!ctx) throw new Error('useUserLang must be used inside UserLangProvider');
  return ctx;
}
```

Always export a typed accessor hook (`useUserLang`) instead of exposing the raw context.

---

## TypeScript

### Single models file

Keep all shared types in one file (`src/models.ts`). Split only if the file exceeds ~500 lines.

```ts
// models.ts
export type LangCode  = 'fr' | 'en' | 'es';
export interface User { id: string; name: string; lang: LangCode; }
```

### Prefer type over interface for unions and aliases

```ts
// ✅ type alias for unions
export type Feedback = 'correct' | 'wrong' | null;

// ✅ interface for object shapes
export interface Answer { phraseId: string; selected: string; correct: boolean; }
```

### Avoid `any`

Use `unknown` when the type is genuinely unknown and narrow it before use.

```ts
// ✅
function parse(raw: unknown): User {
  if (typeof raw !== 'object' || !raw) throw new Error('Invalid user');
  return raw as User;
}

// ❌
function parse(raw: any): User { return raw; }
```

---

## Testing

| Type | File | Tools |
|------|------|-------|
| Service unit test | `service.test.ts` | Vitest only, no React |
| Hook unit test | `useHook.test.ts` | Vitest + `renderHook` |
| Component test | `Component.test.tsx` | Vitest + Testing Library |

Prefer testing services — they are pure functions and require no React setup.

Test files live next to the files they test. No separate `__tests__` folder.

---

## Dev-only code

```tsx
{import.meta.env.DEV && <DevToolsPanel />}
```

Never ship dev tools in production.
