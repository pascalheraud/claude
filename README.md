# Claude Skills

A collection of reusable Claude Code skills for general-purpose use across projects.

## What are skills?

Skills are prompt files that Claude Code loads on demand to provide specialized knowledge or behavior for a given task. They live in `.claude/skills/<skill-name>/SKILL.md` and are invoked via `/skill-name` in the chat.

## Structure

```
.claude/
  skills/
    <skill-name>/
      SKILL.md          # The skill prompt loaded by Claude
      references/       # Optional reference files loaded on demand
```

## Naming convention

Skills are organised with a prefix hierarchy that simulates folders. Two levels of prefix are used:

```
<domain>-<skill>
<domain>-<subdomain>-<skill>
```

Skills without a domain prefix are generic tools (not tied to frontend or backend).

## Skills

### Generic

| Skill | Description |
|---|---|
| [application](.claude/skills/application/SKILL.md) | Generic app development — feature spec/plan documentation, code/spec sync rules, post-implementation verification |
| [claude-skill](.claude/skills/claude-skill/SKILL.md) | Best practices for writing Claude Code skills — structure, scope, content rules, generic vs. project-specific |
| [git-readonly](.claude/skills/git-readonly/SKILL.md) | Restricts git usage to read-only commands — diff, log, branch listing, status — never stash, commit, checkout, revert |
| [test-e2e](.claude/skills/test-e2e/SKILL.md) | Generic End-to-End testing — real app/DB in production mode, mocked external dependencies, scenarios, Given/When/Then, PageObject pattern |

### Frontend

| Skill | Description |
|---|---|
| [frontend-js](.claude/skills/frontend-js/SKILL.md) | Generic JS/TS frontend — model types, API error handling (500/404/403), empty select pattern |

#### Frontend › React

| Skill | Description |
|---|---|
| [frontend-react](.claude/skills/frontend-react/SKILL.md) | React + TypeScript — strict typing, inner function decomposition, no inline styles, SSR/ClientOnly, API error patterns |
| [frontend-react-component-design](.claude/skills/frontend-react-component-design/SKILL.md) | Component categorisation, naming suffix vocabulary, props design, state ownership, when to extract |
| [frontend-react-css](.claude/skills/frontend-react-css/SKILL.md) | SCSS Modules — one file per component, shared variables, clsx, Vite path alias |
| [frontend-react-folder-structure](.claude/skills/frontend-react-folder-structure/SKILL.md) | Project layout — ui/, features/, services/, hooks/, contexts/, barrel files, import aliases |
| [frontend-react-routing](.claude/skills/frontend-react-routing/SKILL.md) | React Router v6 — Link vs useNavigate, Back button rules, protected routes, scroll restoration |
| [frontend-react-services-pattern](.claude/skills/frontend-react-services-pattern/SKILL.md) | Injectable TypeScript service classes, composition root, singleton injection, custom hooks decision flowchart |
| [frontend-react-typescript](.claude/skills/frontend-react-typescript/SKILL.md) | Named exports, Props interface, no business logic in components, avoid any, shared models.ts |

#### Frontend › Mobile

| Skill | Description |
|---|---|
| [frontend-mobile-capacitor](.claude/skills/frontend-mobile-capacitor/SKILL.md) | UI/UX for Capacitor apps — safe area, status bar, back button, gestures, splash screen, Android/iOS specifics |
| [frontend-mobile-app-stores](.claude/skills/frontend-mobile-app-stores/SKILL.md) | App Store & Google Play submission — metadata, signing, review rules, privacy, Data Safety |
| [frontend-mobile-github-actions-android](.claude/skills/frontend-mobile-github-actions-android/SKILL.md) | GitHub Actions CI/CD for Capacitor Android — APK/AAB build, signing, Play Store upload |
| [frontend-mobile-posthog](.claude/skills/frontend-mobile-posthog/SKILL.md) | PostHog analytics in Capacitor/React — setup, AnalyticsService, event naming, GDPR, offline buffering |
| [frontend-mobile-sentry](.claude/skills/frontend-mobile-sentry/SKILL.md) | Sentry error monitoring in Capacitor/React — setup, ErrorService, GDPR, iOS/Android native setup |

### Backend

#### Backend › Java

| Skill | Description |
|---|---|
| [backend-java](.claude/skills/backend-java/SKILL.md) | General Java conventions — naming, Boolean handling, var, loops, streams |
| [backend-java-db](.claude/skills/backend-java-db/SKILL.md) | Java database access — column loading, required columns documentation, partial entity patterns |
| [backend-java-test-data-builder](.claude/skills/backend-java-test-data-builder/SKILL.md) | Test data seeding via raw SQL only (no entities/repositories) — templated data clusters, naming, ordered insert/delete |
| [backend-java-spring-boot](.claude/skills/backend-java-spring-boot/SKILL.md) | Spring Boot conventions — controllers, services, entities, validation, controller tests |
| [java-test-e2e](.claude/skills/java-test-e2e/SKILL.md) | Java E2E testing — Playwright, Testcontainers, one scenario class per scenario. Builds on [[test-e2e]] |

#### Backend › Database

| Skill | Description |
|---|---|
| [backend-db-postgresql](.claude/skills/backend-db-postgresql/SKILL.md) | PostgreSQL schema — naming, FK rules, default values, test schema patterns with Testcontainers |
| [backend-db-postgis](.claude/skills/backend-db-postgis/SKILL.md) | PostGIS geometry columns — coordinate order, SRID, insert syntax, test schema differences |
| [backend-db-liquibase](.claude/skills/backend-db-liquibase/SKILL.md) | Liquibase migrations — SQL format, changeset rules, adding NOT NULL columns to existing tables |
