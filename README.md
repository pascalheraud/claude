# Claude Skills

A collection of reusable Claude Code skills for general-purpose use across projects.

## What are skills?

Skills are prompt files that Claude Code loads on demand to provide specialized knowledge or behavior for a given task. They live in `.claude/skills/<path>/SKILL.md` and are invoked via `/<name>` in the chat (or `/<dir>:<name>` when two skills share a basename).

## Structure

```
.claude/
  skills/
    <domain>/
      <skill>/
        SKILL.md          # The skill prompt loaded by Claude
        references/       # Optional reference files loaded on demand
      <subdomain>/
        <skill>/SKILL.md
```

Skills are organised as real nested folders — a skill's `name:` is its own directory's basename; the path to it carries the domain/subdomain. A `generic/` subfolder holds the skills in a domain that aren't tied to any particular language (e.g. `backend/generic/api` vs `backend/java/spring-boot`); the repo-root `generic/` holds skills tied to no domain at all. See `generic/claude-skill` for the full naming convention.

## Adopting this repo à la carte

Because the hierarchy is real folders, a consuming project doesn't have to take every skill in this repo — it can add this repo as a submodule and use `git sparse-checkout` to materialize only the subtree(s) it actually needs (e.g. a backend Java project only wants `backend/java/`, `backend/generic/`, `languages/java/`, `test/`, `generic/`, `tooling/` — not `frontend/`).

```bash
# from the consuming project's root
git submodule add https://github.com/pascalheraud/claude .claude/skills/claude
cd .claude/skills/claude
git sparse-checkout init --cone
git sparse-checkout set .claude/skills/backend .claude/skills/generic .claude/skills/tooling .claude/skills/languages .claude/skills/test
cd -
git add .gitmodules .claude/skills/claude
git commit -m "Add claude skills (backend/generic/tooling/languages/test subtrees)"
```

**This is not automatic on a plain clone.** `.gitmodules` and the submodule's pinned commit are committed and travel with the repo, but `git clone` alone leaves the submodule directory empty, and even `git submodule update --init` on its own restores the *full* tree, not the sparse subset — the `sparse-checkout set` step is local config, not something Git replays for you. Document the exact `sparse-checkout set` command for your project (e.g. in a setup script or this section of your own README) so every clone reapplies the same scope:

```bash
git submodule update --init
git -C .claude/skills/claude sparse-checkout set <your subtrees>
```

Adjust the subtree list to match what the project actually uses — e.g. a React frontend might set `.claude/skills/frontend .claude/skills/languages/typescript .claude/skills/generic .claude/skills/tooling .claude/skills/test`, while a Java backend takes `.claude/skills/backend/java .claude/skills/backend/generic .claude/skills/languages/java .claude/skills/generic .claude/skills/tooling .claude/skills/test`. Skip subtrees you don't use — a backend-only project has no reason to carry `frontend/`, for instance.

## Skills

### Generic (repo root)

| Skill | Description |
|---|---|
| [generic/application](.claude/skills/generic/application/SKILL.md) | Generic app development — feature spec/plan documentation, code/spec sync rules, post-implementation verification |
| [generic/claude-skill](.claude/skills/generic/claude-skill/SKILL.md) | Best practices for writing Claude Code skills — structure, scope, content rules, generic vs. project-specific |
| [generic/typography](.claude/skills/generic/typography/SKILL.md) | Points to the per-language typography skill matching the locale being written/reviewed |
| [generic/typography/french](.claude/skills/generic/typography/french/SKILL.md) | French typography rules for i18n translation strings — non-breaking spaces before punctuation and inside guillemets |
| [generic/typography/english](.claude/skills/generic/typography/english/SKILL.md) | English typography rules for i18n translation strings — regular space before punctuation, straight quotes, dash usage |

### Tooling

| Skill | Description |
|---|---|
| [tooling/git](.claude/skills/tooling/git/SKILL.md) | Git conventions — currently: restricting usage to read-only commands (diff, log, branch listing, status) — never stash, commit, checkout, revert |

### Languages

| Skill | Description |
|---|---|
| [languages/java](.claude/skills/languages/java/SKILL.md) | General Java coding conventions — naming, Boolean handling, var usage |
| [languages/python](.claude/skills/languages/python/SKILL.md) | Python language conventions independent from any framework or tooling choice — typing, module structure, version-specific feature reference |
| [languages/python/python-3.11](.claude/skills/languages/python/python-3.11/SKILL.md) | Python 3.11-specific features — exception groups, TaskGroup, tomllib, typing additions |
| [languages/python/tooling/poetry](.claude/skills/languages/python/tooling/poetry/SKILL.md) | Dependency and build management with Poetry |
| [languages/python/tooling/pyenv](.claude/skills/languages/python/tooling/pyenv/SKILL.md) | Python interpreter version management with Pyenv |
| [languages/python/tooling/pyinstaller](.claude/skills/languages/python/tooling/pyinstaller/SKILL.md) | Standalone executable packaging with PyInstaller |
| [languages/python/tooling/cibuildwheel](.claude/skills/languages/python/tooling/cibuildwheel/SKILL.md) | Multi-platform wheel builds with cibuildwheel |
| [languages/python/tooling/pyarmor](.claude/skills/languages/python/tooling/pyarmor/SKILL.md) | Code protection/obfuscation with PyArmor |
| [languages/typescript](.claude/skills/languages/typescript/SKILL.md) | TypeScript conventions, tied to no framework — currently: restricting `tsc` to non-emitting, check-only invocations |

### Test

| Skill | Description |
|---|---|
| [test/e2e](.claude/skills/test/e2e/SKILL.md) | Generic End-to-End testing — real app/DB in production mode, mocked external dependencies, scenarios, Given/When/Then, PageObject pattern |
| [test/e2e/playwright](.claude/skills/test/e2e/playwright/SKILL.md) | Playwright conventions, tied to no language binding — Browser/BrowserContext/Page lifecycle, PageObjects holding a Page |
| [test/pytest](.claude/skills/test/pytest/SKILL.md) | Python testing conventions with pytest — fixtures, parametrization, determinism |

### Frontend

| Skill | Description |
|---|---|
| [frontend/js](.claude/skills/frontend/js/SKILL.md) | JS/TS frontend conventions, framework-agnostic — model types, API error handling (500/404/403), empty select pattern |
| [frontend/web](.claude/skills/frontend/web/SKILL.md) | Public website conventions — keep the sitemap in sync with page additions/removals/renames |

#### Frontend › React

| Skill | Description |
|---|---|
| [frontend/react](.claude/skills/frontend/react/SKILL.md) | React + TypeScript — strict typing, inner function decomposition, no inline styles, SSR/ClientOnly, API error patterns |
| [frontend/react/component-design](.claude/skills/frontend/react/component-design/SKILL.md) | Component categorisation, naming suffix vocabulary, props design, state ownership, when to extract |
| [frontend/react/css](.claude/skills/frontend/react/css/SKILL.md) | SCSS Modules — one file per component, shared variables, clsx, Vite path alias |
| [frontend/react/folder-structure](.claude/skills/frontend/react/folder-structure/SKILL.md) | Project layout — ui/, features/, services/, hooks/, contexts/, barrel files, import aliases |
| [frontend/react/routing](.claude/skills/frontend/react/routing/SKILL.md) | React Router v6 — Link vs useNavigate, Back button rules, protected routes, scroll restoration |
| [frontend/react/services-pattern](.claude/skills/frontend/react/services-pattern/SKILL.md) | Injectable TypeScript service classes, composition root, singleton injection, custom hooks decision flowchart |
| [frontend/react/test-vitest](.claude/skills/frontend/react/test-vitest/SKILL.md) | Vitest unit-testing conventions — config setup, jsdom/globals gotchas, test scope, test file structure |
| [frontend/react/french-typography](.claude/skills/frontend/react/french-typography/SKILL.md) | French typography in JSX text nodes — `&nbsp;` entity, builds on [[french]] |
| [frontend/react/typescript](.claude/skills/frontend/react/typescript/SKILL.md) | Named exports, Props interface, no business logic in components, avoid any, shared models.ts |

#### Frontend › Mobile

| Skill | Description |
|---|---|
| [frontend/mobile/capacitor](.claude/skills/frontend/mobile/capacitor/SKILL.md) | UI/UX for Capacitor apps — safe area, status bar, back button, gestures, splash screen, Android/iOS specifics |
| [frontend/mobile/app-stores](.claude/skills/frontend/mobile/app-stores/SKILL.md) | App Store & Google Play submission — metadata, signing, review rules, privacy, Data Safety |
| [frontend/mobile/github-actions-android](.claude/skills/frontend/mobile/github-actions-android/SKILL.md) | GitHub Actions CI/CD for Capacitor Android — APK/AAB build, signing, Play Store upload |
| [frontend/mobile/posthog](.claude/skills/frontend/mobile/posthog/SKILL.md) | PostHog analytics in Capacitor/React — setup, AnalyticsService, event naming, GDPR, offline buffering |
| [frontend/mobile/sentry](.claude/skills/frontend/mobile/sentry/SKILL.md) | Sentry error monitoring in Capacitor/React — setup, ErrorService, GDPR, iOS/Android native setup |

### Backend

#### Backend › Generic (language-agnostic)

| Skill | Description |
|---|---|
| [backend/generic/api](.claude/skills/backend/generic/api/SKILL.md) | Generic backend API — route handler vs service split, route guards, status-code discipline, response shape, injectable time |
| [backend/generic/emails](.claude/skills/backend/generic/emails/SKILL.md) | Conventions for links inside transactional/plain-text emails |
| [backend/generic/db](.claude/skills/backend/generic/db/SKILL.md) | Generic database design — data integrity independent of any specific DBMS |
| [backend/generic/db/postgresql](.claude/skills/backend/generic/db/postgresql/SKILL.md) | PostgreSQL schema — naming, FK rules, default values, test schema patterns with Testcontainers |
| [backend/generic/db/postgis](.claude/skills/backend/generic/db/postgis/SKILL.md) | PostGIS geometry columns — coordinate order, SRID, insert syntax, test schema differences |
| [backend/generic/db/liquibase](.claude/skills/backend/generic/db/liquibase/SKILL.md) | Liquibase migrations — SQL format, changeset rules, adding NOT NULL columns to existing tables |

#### Backend › Java

| Skill | Description |
|---|---|
| [backend/java/db](.claude/skills/backend/java/db/SKILL.md) | Java database access — column loading, required columns documentation, partial entity patterns |
| [backend/java/spring-boot](.claude/skills/backend/java/spring-boot/SKILL.md) | Spring Boot conventions — controllers, services, entities, validation, controller tests. Builds on [[api]] |
| [backend/java/test](.claude/skills/backend/java/test/SKILL.md) | Generic Java backend unit/integration testing — deterministic test data |
| [backend/java/test/playwright](.claude/skills/backend/java/test/playwright/SKILL.md) | Java E2E testing with Playwright for Java — Testcontainers, one scenario class per scenario. Builds on [[test/e2e]] and [[test/e2e/playwright]] |

#### Backend › Python

| Skill | Description |
|---|---|
| [backend/python](.claude/skills/backend/python/SKILL.md) | Python backend conventions — layering, DI, persistence boundaries. Builds on [[api]] and [[languages/python]] |
| [backend/python/fastapi](.claude/skills/backend/python/fastapi/SKILL.md) | FastAPI conventions — routers, Pydantic models, dependency injection, error handling, route tests. Builds on [[api]] and [[backend/python]] |
| [backend/python/test](.claude/skills/backend/python/test/SKILL.md) | Python backend testing conventions, independent of the web/test framework. Builds on [[api]] |
