# Google Play — Référence complète

## 1. Target API Level

Google impose un API level minimum qui augmente chaque année. Ne pas être à jour = app retirée
du store pour les nouveaux appareils, ou refus de soumission.

| Année | Nouvelles apps | Mises à jour |
|-------|---------------|--------------|
| 2024 | API 34 (Android 14) | API 34 |
| 2025 | API 35 (Android 15) | API 35 (à confirmer) |

Vérifier la page officielle : https://developer.android.com/google/play/requirements/target-sdk

Dans `build.gradle` (app) :
```gradle
android {
    compileSdk 34
    defaultConfig {
        targetSdkVersion 34
        minSdkVersion 21   // Android 5.0 — couvre ~99% des appareils actifs
    }
}
```

---

## 2. Format de soumission — AAB obligatoire

Depuis août 2021, Google Play n'accepte plus les APK pour les nouvelles apps. Il faut soumettre
un **Android App Bundle (AAB)**.

Avantages pour l'utilisateur : Google génère un APK optimisé pour chaque appareil (moins lourd).
Avantages pour le développeur : plus besoin de gérer les densités d'écran et architectures manuellement.

Générer l'AAB dans Android Studio :
**Build → Generate Signed Bundle / APK → Android App Bundle**

Ou via CLI (Gradle) :
```bash
./gradlew bundleRelease
# Output : app/build/outputs/bundle/release/app-release.aab
```

---

## 3. App Signing

**Play App Signing** est activé par défaut pour les nouvelles apps. Google détient la clé de
signature finale ; le développeur uploade un AAB signé avec une "upload key".

À ne pas confondre :
- **Upload key** : utilisée pour signer l'AAB lors de l'upload (peut être regénérée si perdue)
- **App signing key** : détenue par Google, utilisée pour signer l'APK distribué aux utilisateurs

Conserver la upload key en sécurité (fichier `.jks` ou `.keystore`). La perdre = impossible
d'uploader de nouvelles versions sans contacter le support Google.

```bash
# Générer une upload key
keytool -genkey -v -keystore upload-key.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 9125
```

---

## 4. Data Safety Section (obligatoire)

Dans la Play Console → **Policy → App content → Data safety**.

Déclarer explicitement pour chaque type de donnée :
- Est-elle collectée ?
- Est-elle partagée avec des tiers ?
- Est-elle chiffrée en transit ?
- L'utilisateur peut-il demander sa suppression ?

Types de données à déclarer si collectées :
- Localisation (précise ou approximative)
- Données personnelles (nom, email, téléphone)
- Identifiants (User ID, Device ID, cookies)
- Activité in-app (historique de recherche, interactions)
- Données de performance (logs de crash, diagnostics)

**Incohérence entre la déclaration et le comportement réel = suspension de l'app.**

Les SDK tiers collectent souvent des données automatiquement. Vérifier les Data Safety forms
des SDK utilisés (Firebase, Sentry, etc.) et les inclure dans la déclaration.

---

## 5. Release Tracks

Google Play propose plusieurs tracks pour gérer les déploiements progressifs :

| Track | Visibilité | Usage |
|-------|-----------|-------|
| **Internal testing** | Jusqu'à 100 testeurs (email obligatoire) | Tests internes, disponible immédiatement sans examen |
| **Closed testing (Alpha)** | Groupes de testeurs définis | Beta fermée, passe par examen Google |
| **Open testing (Beta)** | Public, opt-in | Beta ouverte |
| **Production** | Tous les utilisateurs | Release officielle |

**Staged rollout** : déployer progressivement (ex: 10% → 50% → 100%) pour détecter les
problèmes avant d'atteindre tous les utilisateurs. Possible uniquement sur le track Production.

### Mandatory workflow for new developer accounts

Google requires for new accounts: **closed testing with 12 testers for at least 14 days** before production access is granted.

1. **Internal testing** → functional verification on a physical device
   - Each tester must be added manually by email in a distribution list — no open link
   - The `/apps/internaltest/XXX` link only works from **Chrome** signed in with an account in the list
   - The release must be **Active** (not Draft) before sharing the link
2. **Closed testing** → minimum 12 testers, minimum 14 days
   - Goes through Google review (delay: a few hours to 7 days)
   - Open link ("Join on the web") available once approved — share on r/androiddev
   - The 14 days start from the first tester who joins
3. **Production** → only accessible after the 14-day closed testing period

---

## 6. Permissions Android — bonnes pratiques

Déclarer uniquement les permissions utilisées dans `AndroidManifest.xml`.

**Permissions normales** (accordées automatiquement à l'installation) :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

**Permissions dangereuses** (demandées à l'utilisateur au runtime) :
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

Permissions qui déclenchent une **review manuelle** et nécessitent une justification écrite :
- `MANAGE_EXTERNAL_STORAGE` (accès à tous les fichiers)
- `QUERY_ALL_PACKAGES` (liste de toutes les apps installées)
- `READ_CALL_LOG` / `WRITE_CALL_LOG`
- `PROCESS_OUTGOING_CALLS`

---

## 7. Play Console — Metadata

### Screenshots (required)
- Minimum 2 **phone** screenshots (recommended portrait: 1080×1920 px)
- Minimum 2 **7" tablet** screenshots — required to save the store listing (recommended: 1200×1920 px)
- Format: JPEG or PNG 24-bit, between 320 px and 3840 px per side, ratio 16:9 or 9:16
- **DPR**: always capture with DPR=1 in browser DevTools — DPR=2 doubles the resolution and exceeds the 3840 px limit
- Capture from Chrome/Firefox DevTools: F12 → phone icon → set resolution manually → DPR=1 → "Capture screenshot" (Chrome) or "···" → "Take a Screenshot" (Firefox)

### Feature Graphic (obligatoire)
Banner 1024×500 px affiché en haut de la fiche — obligatoire pour apparaître dans les
mises en avant éditoriales. Format JPG ou PNG 24 bits (pas d'alpha).

### App Icon
512×512 px, PNG 32 bits avec couche alpha. Généré depuis Android Studio / Asset Studio ou
`@capacitor/assets`.

### Textes
- **App Name** : 30 caractères max
- **Short Description** : 80 caractères, visible dans les résultats de recherche
- **Full Description** : 4000 caractères

---

## 8. Répondre à un rejet ou une suspension

**Rejet à la soumission** : email + message dans la Play Console. Corriger le point soulevé et
re-soumettre. Pas besoin d'incrémenter le versionCode si le binaire n'a pas changé (metadata
uniquement).

**Suspension d'app** : plus sévère — l'app est retirée du store. Causes fréquentes :
- Violation de la politique de données (Data Safety incohérente)
- Contenu trompeur ou malveillant détecté
- Violation des droits de propriété intellectuelle

Pour contester : Play Console → **Policy status → Appeal**.

Délai de réponse aux appels : 3–7 jours ouvrables.
