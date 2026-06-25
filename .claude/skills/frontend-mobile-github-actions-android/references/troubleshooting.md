# Troubleshooting — GitHub Actions Capacitor Android builds

## Gradle build fails: `SDK location not found`

**Symptom:** `> SDK location not found. Define a valid SDK location with an sdk.dir...`

**Fix:** Capacitor generates `android/local.properties` on `npx cap sync` but it points to
your local SDK path. In CI, use the pre-installed SDK:

```yaml
- name: Set ANDROID_HOME
  run: echo "ANDROID_HOME=$ANDROID_SDK_ROOT" >> $GITHUB_ENV
```

Or add `sdk.dir` via a step before the Gradle build:

```yaml
- name: Set local.properties
  run: echo "sdk.dir=$ANDROID_SDK_ROOT" > android/local.properties
```

---

## Signing fails: `jarsigner: unable to open jar file`

The AAB path passed to jarsigner is wrong. Verify the exact output path:

```bash
find android/app/build/outputs -name "*.aab"
```

Common paths:
- `android/app/build/outputs/bundle/release/app-release.aab` ← most common
- `android/app/build/outputs/bundle/releaseRelease/app-release.aab` ← with custom flavors

---

## `KEYSTORE_BASE64` decoding produces a corrupt keystore

**Cause:** base64 encoding had line breaks in it.

**Fix:** Re-encode with no line breaks:
```bash
base64 -i release.keystore | tr -d '\n'
```
Then update the secret in GitHub.

---

## `bundleRelease` succeeds but AAB is unsigned

**Symptom:** Play Console rejects the AAB with "APK or AAB must be signed".

**Cause:** The `-P` flags weren't passed correctly to Gradle, or Gradle's signing config
in `build.gradle` overrides them.

**Fix:** Check `android/app/build.gradle` for an existing `signingConfigs` block. If one
exists pointing to a local file that doesn't exist in CI, it will silently fall back to
unsigned. Either remove it or make it conditional:

```groovy
// In android/app/build.gradle
android {
    signingConfigs {
        release {
            // Only apply if the file exists (local dev only)
            if (project.hasProperty('android.injected.signing.store.file')) {
                storeFile file(project.property('android.injected.signing.store.file'))
                storePassword project.property('android.injected.signing.store.password')
                keyAlias project.property('android.injected.signing.key.alias')
                keyPassword project.property('android.injected.signing.key.password')
            }
        }
    }
}
```

---

## `npx cap sync` fails: `Cannot find module '@capacitor/cli'`

**Fix:** Make sure `@capacitor/cli` is in `devDependencies` and that `npm ci` ran before
the sync step. Also ensure `node_modules/.bin` is on the PATH (it is by default with
`actions/setup-node`).

---

## GitHub Release not created: `Resource not accessible by integration`

**Cause:** The repo's Actions permissions don't allow creating releases.

**Fix:** Go to **Settings → Actions → General → Workflow permissions** and set it to
**Read and write permissions**. Or add this to the job:

```yaml
permissions:
  contents: write
```

---

## Build is slow (>10 min)

Check that the Gradle cache step is actually hitting:
- In the workflow summary, the cache step should say "Cache restored from key: gradle-..."
- If it always says "Cache not found", the `hashFiles` glob might be wrong

Also check npm cache: `actions/setup-node` with `cache: 'npm'` caches `~/.npm` automatically.

---

## `versionCode` rejected by Play Console: "must be higher than the last uploaded version"

The `versionCode` in `android/app/build.gradle` must be strictly greater than any version
ever uploaded to any track (even internal testing). Check the current max in
Play Console → Release → Setup → Advanced settings → Version codes.
