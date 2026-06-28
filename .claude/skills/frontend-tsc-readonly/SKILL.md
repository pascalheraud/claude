---
name: frontend-tsc-readonly
description: Restricts TypeScript compiler usage to non-emitting, check-only invocations — never run a bare `tsc` or `npm run build` that emits .js files. Load this skill whenever the user asks to type-check, verify types, or run tsc in a frontend TS/TSX project that uses Vite/bundler module resolution.
---

# TypeScript — check-only usage

## Rule: never run a `tsc` invocation that emits output files

In a Vite (or other bundler) project, source files are `.ts`/`.tsx` and are never compiled by `tsc` directly — Vite/esbuild/rollup handles that. Running `tsc` without `--noEmit` writes a `.js` sibling next to every `.ts`/`.tsx` file (e.g. `Badge.tsx` → `Badge.js`). Once created, the stale `.js` file shadows the `.tsx` source for Node/bundler module resolution, breaking imports and tests in ways that are confusing to debug (wrong file silently picked up).

Only these forms are allowed:

- `npx tsc --noEmit`
- `npx tsc --noEmit -p <tsconfig>`
- Any `tsc` invocation already piped through a config/script that has `"noEmit": true` set in the resolved `tsconfig.json` `compilerOptions`

**Never** run, even to compare against a baseline or "just to check the full build":

- `npx tsc` (bare, no `--noEmit`)
- `npm run build` / `yarn build` / `pnpm build` — if the script's `build` target invokes bare `tsc` before bundling (check `package.json` first), this has the same effect
- Any `tsc` invocation when you have not confirmed `noEmit` is set, either via `--noEmit` on the command line or in the active `tsconfig.json`

## How to apply

Before running any `tsc`-based command, check `package.json`'s `scripts` and the project's `tsconfig.json` `compilerOptions.noEmit`. If `noEmit` isn't already guaranteed, add `--noEmit` explicitly rather than trusting the script name.

If you ever do run a command that turns out to have emitted `.js` files (e.g. you ran `npm run build` without checking first), immediately find and delete the generated `.js` files next to their `.ts`/`.tsx` sources — `git status --porcelain | grep -E '\.js$'` will show them as untracked if the repo doesn't otherwise ship compiled output.

## Why

This applies to any frontend project where `.ts`/`.tsx` are the only source of truth and a bundler (not `tsc`) produces the actual build output — `tsc` here is a type-checker only, and its emit mode is a footgun, not a feature.
