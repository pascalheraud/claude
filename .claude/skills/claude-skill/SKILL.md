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

Since `.claude/skills/` is flat (no subdirectory support), hierarchy is expressed with dash-separated prefixes:

```
<domain>-<skill>
<domain>-<subdomain>-<skill>
```

Current domains and subdomains:

| Prefix | Meaning |
|---|---|
| *(none)* | Generic — not tied to frontend or backend |
| `frontend-` | Frontend (web or mobile) |
| `frontend-react-` | React-specific frontend |
| `frontend-mobile-` | Mobile app (Capacitor) |
| `backend-` | Backend |
| `backend-java-` | Java/JVM backend |
| `backend-db-` | Database (PostgreSQL, PostGIS, Liquibase) |

Examples:
- `frontend-react-routing` — routing conventions, React-specific
- `frontend-mobile-sentry` — Sentry setup, mobile context
- `backend-java-spring-boot` — Spring Boot, Java backend
- `backend-db-liquibase` — Liquibase migrations, database layer

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
