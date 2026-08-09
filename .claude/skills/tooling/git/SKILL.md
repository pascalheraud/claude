---
name: git
description: Git conventions — currently covers restricting git usage to read-only, inspection commands (diff, log, branch listing, status). Load this skill whenever the user asks to look at git history, diffs, branches, or status without intending to change the working tree or repo state.
---

# Git

## Scope: git commands only

This restricts **git commands**, not code changes. Editing, writing, or creating files (Edit/Write tools) is unaffected and stays governed by the normal rules — only the `git` CLI itself is limited to inspection here. Fixing a bug found in this repo still means editing the file directly; it's committing/pushing that requires the user.

## Read-only usage

### Rule: never run a git command that mutates the working tree, the index, or repo state

Only inspection commands are allowed:

- `git status`
- `git diff` / `git diff --staged` / `git diff <ref>...<ref>`
- `git log` (any form: `--oneline`, `--graph`, `-p`, `--stat`, etc.)
- `git branch` / `git branch -a` / `git branch -vv` (listing only)
- `git show`
- `git blame`

**Never** run, even if the user's request seems to imply it or it would be the fastest fix:

- `git stash` (any subcommand, including `stash pop`/`stash drop`)
- `git commit` (including `--amend`)
- `git checkout` / `git switch` (these change tracked files or HEAD)
- `git revert`
- `git reset` (any mode)
- `git push` / `git pull` / `git fetch --prune`
- `git add` / `git rm` / `git mv`
- `git merge` / `git rebase` / `git cherry-pick`
- `git branch -d` / `git branch -D` (deletion, as opposed to listing)
- `git clean`

### Why

This applies in contexts where git is used purely to inspect state (review, investigation, reporting) and any side effect on the working tree or repo history is out of scope and unwanted, regardless of how minor or reversible it looks.

### How to apply

If a task seems to require a mutating command (e.g. "check what's stashed" implying `git stash list` is fine, but resolving it implies `git stash pop`), stop and explain to the user that the action requires a mutating git command, and ask them to run it or explicitly approve it — do not run it yourself even with a justification.

`git stash list` and `git diff stash@{0}` are read-only and allowed; `git stash pop`/`apply`/`drop` are not.
