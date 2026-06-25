---
name: frontend-mobile-github-actions-android
description: >
  Use this skill whenever the user wants to set up, configure, or troubleshoot GitHub Actions
  workflows for building a React + Capacitor Android app (APK or AAB). Triggers include: any
  mention of "GitHub Actions" + "Android", "CI/CD" for a Capacitor app, "build workflow",
  "release workflow", "adb install", "Play Store upload", signing an APK/AAB with a keystore,
  managing secrets in GitHub for Android builds, or generating a release checklist for a
  mobile app. Also trigger when the user wants to create or update a RELEASE_CHECKLIST.md for
  a Capacitor Android project. Use this skill even if the user only mentions one of these
  aspects — the skill covers the full build pipeline from dev APK to signed production AAB.
---

# GitHub Actions — Capacitor Android Build Skill

Covers two workflows and a release checklist for a **React + Vite + Capacitor** app targeting
the Google Play Store. The rest of the Capacitor/Android project setup lives in the
`capacitor-app-mobile` skill — this skill is scoped to `.github/workflows/` and
`RELEASE_CHECKLIST.md` only.

---

## Project assumptions

- Build tool: **Vite**
- Capacitor target: **Android only**
- APK format: **APK** for dev (sideload via `adb`), **AAB** for prod (Play Store)
- Versioning: done manually in source before triggering the release (see checklist)
- Release trigger: **manual** (`workflow_dispatch`) with a `version_tag` input, on any branch
- Dev trigger: push to any branch (or PR) — produces a debug APK artifact
- Signing: upload keystore and credentials as **GitHub Actions secrets**

---

## File layout produced by this skill

```
.github/
  workflows/
    build-dev.yml       # Debug APK on every push
    build-release.yml   # Signed AAB on manual trigger
RELEASE_CHECKLIST.md    # Generated at project root
```

---

## 1. Secrets setup (do this once in the repo)

Read `references/secrets-setup.md` for the full procedure. Summary:

| Secret name              | Value |
|--------------------------|-------|
| `KEYSTORE_BASE64`        | `base64 -i your.keystore` output (single line) |
| `KEYSTORE_PASSWORD`      | Keystore password |
| `KEY_ALIAS`              | Key alias inside the keystore |
| `KEY_PASSWORD`           | Key password |

Add them under **Settings → Secrets and variables → Actions** in the GitHub repo.

---

## 2. Workflow: Dev build (`build-dev.yml`)

**Goal:** fast feedback loop — produces a debug APK downloadable as a GitHub artifact,
installable with `adb install app-debug.apk`.

Read `references/build-dev.yml` for the full file.

Key points:
- Triggers on `push` to any branch
- No signing required (debug keystore built into Android SDK)
- Uploads `app-debug.apk` as a workflow artifact (retention: 7 days)
- Uses `actions/cache` on Gradle and npm to keep builds fast
- Node version pinned via `.nvmrc` or hardcoded (use the same version as local)

---

## 3. Workflow: Production release (`build-release.yml`)

**Goal:** signed AAB ready for Play Store upload, tagged and attached to a GitHub Release.

Read `references/build-release.yml` for the full file.

Key points:
- Trigger: `workflow_dispatch` with a required input `version_tag` (e.g. `v1.2.0`)
- The workflow does **not** bump versions — that's done in source before triggering
- Decodes `KEYSTORE_BASE64` secret to a temp file, signs with `jarsigner`
- Runs `zipalign` then `apksigner verify` to confirm the signature
- Creates a GitHub Release with the tag and uploads the signed AAB as a release asset
- Cleans up the keystore temp file even if the job fails (`if: always()`)

---

## 4. Release checklist (`RELEASE_CHECKLIST.md`)

When the user asks to generate the release checklist, create `RELEASE_CHECKLIST.md` at the
**project root** using the template in `references/release-checklist-template.md`.

Replace `{{APP_NAME}}` with the actual app name if known, otherwise leave the placeholder.
The checklist is a living document — tell the user to commit it to the repo and update it
as the project evolves.

---

## Workflow: how to use this skill

1. **First time setup**
   - Walk the user through `references/secrets-setup.md`
   - Generate both workflow files
   - Generate `RELEASE_CHECKLIST.md`

2. **Adding workflows to an existing project**
   - Check if `.github/workflows/` already has conflicting files
   - Generate only what's missing

3. **Troubleshooting a failing build**
   - Ask for the failing step output
   - Common issues listed in `references/troubleshooting.md`

4. **Generating only the checklist**
   - Go straight to `references/release-checklist-template.md`

---

## Reference files

| File | When to read |
|------|-------------|
| `references/secrets-setup.md` | Explaining keystore generation and GitHub secret setup |
| `references/build-dev.yml` | Generating or debugging the dev workflow |
| `references/build-release.yml` | Generating or debugging the release workflow |
| `references/release-checklist-template.md` | Generating `RELEASE_CHECKLIST.md` |
| `references/troubleshooting.md` | Diagnosing CI failures |
