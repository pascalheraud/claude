# Release checklist template — used by the skill to generate RELEASE_CHECKLIST.md

When generating the file, replace `{{APP_NAME}}` with the actual app name if known.
Output the content below (starting from the `#` heading) verbatim as `RELEASE_CHECKLIST.md`
at the project root.

---

# {{APP_NAME}} — Release Checklist

> Copy this checklist for each release. Check off items as you go.
> Trigger the GitHub Actions release workflow only after completing all pre-release steps.

---

## 1. Code & version

- [ ] All features for this release are merged into the release branch
- [ ] No debug code, `console.log`, or dev-only flags left in production paths
- [ ] `versionName` updated in `android/app/build.gradle` (e.g. `1.2.0`)
- [ ] `versionCode` incremented in `android/app/build.gradle` (must be strictly higher than the last Play Store upload)
- [ ] Version reflected in the app UI if displayed (e.g. about screen, settings)
- [ ] `CHANGELOG.md` or release notes updated

## 2. Testing

- [ ] Dev APK built locally or via GitHub Actions (`build-dev.yml`) and installed via `adb`
- [ ] Smoke test on a physical Android device (not only emulator)
- [ ] Tested on minimum supported Android version
- [ ] All critical user flows verified:
  - [ ] Onboarding / first launch
  - [ ] Core feature: _______________
  - [ ] Core feature: _______________
  - [ ] Offline behaviour (if applicable)
- [ ] No crashes observed during testing
- [ ] Performance acceptable (no janky animations, acceptable load times)

## 3. Assets & store listing

- [ ] App icon up to date (all densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- [ ] Play Store screenshots updated if UI changed
- [ ] Feature graphic updated (if applicable)
- [ ] Short description updated in Play Console (if changed)
- [ ] Full description updated in Play Console (if changed)
- [ ] Privacy policy URL still valid

## 4. Permissions & compliance

- [ ] No new Android permissions added without justification
- [ ] If new permissions were added: Play Store declaration updated
- [ ] GDPR / privacy requirements checked for any new data collection

## 5. Pre-release trigger

- [ ] All items above checked
- [ ] Release branch is clean (`git status` shows nothing uncommitted)
- [ ] Decided which branch to trigger the release from: _______________
- [ ] Version tag to use: `v_______________`

## 6. GitHub Actions release

- [ ] Go to **Actions → Build Release AAB → Run workflow**
- [ ] Select branch: _______________
- [ ] Enter version tag: `v_______________`
- [ ] Trigger the workflow
- [ ] Workflow completed successfully (green ✓)
- [ ] GitHub Release created with the correct tag
- [ ] AAB asset attached to the GitHub Release

## 7. Play Store upload

- [ ] Download the signed AAB from the GitHub Release
- [ ] Upload AAB to Play Console (Internal Testing → or target track)
- [ ] Release notes written for this version (all languages if applicable)
- [ ] Rollout percentage set (100% or staged rollout)
- [ ] Review & publish submitted

## 8. Post-release

- [ ] Monitor Play Console for ANRs and crashes (first 24–48h)
- [ ] Monitor user reviews for regressions
- [ ] Tag confirmed on `main` (or merge release branch back to `main`)
- [ ] Team notified of the release

---

_Last updated: {{DATE}}_
