# Secrets setup — Android signing

## Step 1 — Generate a keystore (skip if you already have one)

```bash
keytool -genkeypair \
  -v \
  -keystore release.keystore \
  -alias my-key-alias \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

You'll be prompted for:
- Keystore password (store it safely)
- Key password (can be the same as keystore password)
- Distinguished name fields (name, org, country…)

> ⚠️ Keep `release.keystore` out of git. Add it to `.gitignore`.
> If you lose this file you cannot update your app on the Play Store.

---

## Step 2 — Encode the keystore to base64

**macOS / Linux:**
```bash
base64 -i release.keystore | tr -d '\n'
```

**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release.keystore"))
```

Copy the entire output (one long string, no line breaks).

---

## Step 3 — Add secrets to GitHub

Go to your repo → **Settings → Secrets and variables → Actions → New repository secret**

| Secret name         | Value                                      |
|---------------------|--------------------------------------------|
| `KEYSTORE_BASE64`   | The base64 string from Step 2              |
| `KEYSTORE_PASSWORD` | Keystore password                          |
| `KEY_ALIAS`         | The alias you chose (e.g. `my-key-alias`)  |
| `KEY_PASSWORD`      | Key password                               |

---

## Step 4 — Verify locally (optional sanity check)

```bash
# Decode back and verify
echo "$KEYSTORE_BASE64" | base64 --decode > /tmp/test.keystore
keytool -list -v -keystore /tmp/test.keystore
rm /tmp/test.keystore
```

---

## Notes

- Secrets are **never** printed in workflow logs (GitHub masks them automatically)
- If you rotate the keystore, update all 4 secrets at the same time
- For team projects, store the original `.keystore` file in a password manager or secure vault
