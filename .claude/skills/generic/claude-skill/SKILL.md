---
name: claude-skill
description: Best practices for writing Claude Code skills — structure, scope, content rules, and relationship between generic and project-specific skills
---

# Writing Claude Code Skills

## File structure

Skills live in `.claude/skills/<skill-name>/SKILL.md` and are invoked via `/<skill-name>` in the chat.

Required frontmatter:

```markdown
---
name: skill-name
description: One-line summary — specific enough to decide relevance at load time
---
```

The `description` is what Claude reads to decide whether to load the skill. Make it precise: name the domain, the tech, and the scope.

## Scope rules

**One skill per topic.** Do not bundle unrelated concerns in one file. Prefer small, focused skills over large catch-all ones.

**Separate generic from project-specific.** Generic skills live in a shared repo and are reusable across projects. Project skills reference them with `[[skill-name]]` and only add what is specific.

## Naming convention

`.claude/skills/` supports nested directories — hierarchy is expressed with real subfolders, one domain/subdomain per level, not with dash-prefixed names. A skill's `name:` is just its own directory's basename; the path to it is what carries the domain/subdomain context:

```
.claude/skills/
  <domain>/
    <skill>/SKILL.md              # name: <skill>
    <subdomain>/
      <skill>/SKILL.md            # name: <skill>
```

A directory can itself hold both a `SKILL.md` (the domain's own generic skill) and subdirectories with their own skills — e.g. `backend/java/SKILL.md` (general Java conventions) alongside `backend/java/spring-boot/SKILL.md` (Spring Boot specifics).

**A `generic/` subfolder holds the skills in a domain that aren't tied to any particular language.** It sits as a sibling to the domain's language-specific subfolders — e.g. `backend/generic/api` (route guards, status codes — framework/language-agnostic) next to `backend/java/spring-boot` (the same rules, Spring Boot-specific). At the repo root, `generic/` holds skills tied to no domain at all (not even frontend/backend).

Current domains and subdomains:

| Path | Meaning |
|---|---|
| `generic/` | Tied to no domain — not frontend, not backend, not a dev tool |
| `tooling/` | Developer tooling used across any project (git, and other CLIs/tools that aren't part of the app itself) |
| `languages/` | Conventions tied to a language but to no domain (e.g. `languages/java`, `languages/typescript`) — see "Domain-first, not language-first" below |
| `test/` | Testing conventions tied to no language (e.g. `test/e2e`) |
| `frontend/` | Frontend (web or mobile) |
| `frontend/react/` | React-specific frontend |
| `frontend/mobile/` | Mobile app (Capacitor) |
| `backend/` | Backend |
| `backend/generic/` | Backend, tied to no particular language (API conventions, DB conventions, emails) |
| `backend/java/` | Java/JVM backend |
| `backend/generic/db/` | Database (PostgreSQL, PostGIS, Liquibase) — DB vendor, not a language |

Examples:
- `frontend/react/routing` — routing conventions, React-specific
- `frontend/mobile/sentry` — Sentry setup, mobile context
- `backend/java/spring-boot` — Spring Boot, Java backend
- `backend/generic/db/liquibase` — Liquibase migrations, database layer
- `backend/generic/api` — route handler/service split, status-code discipline — language-agnostic
- `languages/typescript` — never run bare `tsc` without `--noEmit` — tied to TypeScript, not to backend or frontend
- `test/e2e` — E2E testing conventions, tied to no domain or language

### Domain-first, not language-first

The tree is organised **domain-first** (`backend/`, `frontend/` at the root), never language-first (no `typescript/backend/`, no `java/frontend/`). This matches how a consuming project actually adopts skills à la carte: a backend Java project wants one subtree, `backend/java/`; it does not want to go hunting through `typescript/`, `java/`, and `python/` folders for the backend-relevant leaf in each.

A language can still show up in more than one domain (TypeScript in both `frontend/js` and a Node backend, say). Don't duplicate the language-generic rule under each domain, and don't invert the tree to `typescript/backend` + `typescript/frontend` either — instead, extract the part of the convention that holds regardless of domain into `languages/<lang>`, and have each domain's skill link to it with `[[languages/<lang>]]` for the framework/domain-specific rest.

**The test for where a convention belongs**: does it change if the domain changes?
- No (e.g. "never run `tsc` without `--noEmit`", "prefer `var` when the type is obvious") → `languages/<lang>`, written once.
- Yes (e.g. "a Spring Boot controller never references React", CSS Modules conventions) → stays under `<domain>/<lang-or-framework>/`, since the rule only makes sense in that domain.

`backend/java/spring-boot` and `frontend/react/typescript` both link out to `languages/java` / `languages/typescript` for the domain-agnostic half of what they cover, rather than repeating it.

**On a name clash**, Claude Code disambiguates by showing the skill as `<dir>:<name>` (e.g. `backend/generic/db:db` vs `backend/java/db:db`) — a plain `[[db]]` reference stays ambiguous only if two skills share that exact basename; qualify the link with the path prefix in that case (`[[backend/java/db]]`).

**Why this matters beyond tidiness**: a consuming project only wants the tech it actually uses. Since a skill's identity is a real path, a consumer can pull in just one subtree — e.g. a git submodule pointed at `backend/java/` alone, or a workspace folder scoped to `frontend/mobile/` — instead of the whole collection. This is the reason the prefix convention was replaced with real folders.

## Content rules

**Capture the non-obvious.** A skill should record conventions that cannot be derived by reading the current code — hidden constraints, architectural decisions, invariants, patterns the team has settled on.

Do not document:
- What is already in the code (naming is self-explanatory)
- What any developer would do by default
- Ephemeral state or in-progress work

**Use code examples for patterns with a specific shape.** If a convention has a fixed structure (a 3-step migration, a specific class hierarchy, a validated payload pattern), show it with a minimal code snippet.

**Keep it actionable.** A skill is a prompt, not a reference manual. Every section should help Claude make a decision or write correct code. Cut anything that does not affect output.

## Referencing other skills

Link to related skills with `[[skill-name]]`. This keeps each skill focused and avoids duplication.

```markdown
For migration conventions, see [[liquibase]].
```

## Before creating a new skill

Check what generic skills already exist in the shared repo (README.md). If a new convention fits an existing generic skill, propose updating that skill rather than creating a new one. Only create a new skill if the topic is genuinely distinct from all existing ones.

## Maintenance rules

- When a new pattern is established in code, update the relevant skill immediately.
- **If the pattern is generic (not tied to one project's domain/business logic), edit it in the shared `claude` skills module first**, not in the project-local skill. Project skills should only hold project-specific guidance and `[[reference]]` links into the generic skill — never re-explain a generic pattern locally, even partially.
- When a project skill duplicates content already in a generic skill, remove the duplicate and add a `[[reference]]`.
- When a skill becomes stale (the pattern it describes no longer exists), update or delete it.
- **When adding or renaming a skill that belongs to a collection with a README**, update the README to reflect the change: add a row in the correct section, use the right prefix group, and include a one-line description.

## Language

- Skills in shared/generic repos: **English**
- Skills in project repos: match the project's convention (may be French for functional content, English for technical content)
