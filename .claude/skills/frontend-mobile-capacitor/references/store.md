# Store Submission — Spécificités Capacitor

Ce fichier couvre uniquement ce qui est propre à Capacitor lors d'une soumission store.
Pour les règles générales (permissions, politique de confidentialité, IAP, screenshots, tracks),
voir la skill `js-app-stores`.

---

## 1. Retirer les outils de dev avant soumission

```typescript
// capacitor.config.ts
const config: CapacitorConfig = {
  // ❌ En dev uniquement — à retirer absolument avant soumission
  // server: { url: 'http://192.168.1.42:5173' },

  // ✅ Schéma HTTPS requis par les deux stores
  server: {
    androidScheme: 'https',
  },
};
```

Vérifier aussi que `import.meta.env.DEV` gate bien tout le code de debug :
logs, overlay d'erreur, hot reload, indicateurs de dev.

---

## 2. Vite — config production

```typescript
// vite.config.ts
export default defineConfig({
  base: './',            // chemins relatifs — obligatoire pour le WebView
  build: {
    sourcemap: false,    // ne pas embarquer les sources dans l'APK/IPA
    target: 'es2015',   // compatibilité WebView Android anciens
  },
});
```

---

## 3. Version bumping

Les deux stores exigent un identifiant de build strictement croissant à chaque upload,
y compris pour les re-soumissions après rejet.

**Android** — `android/app/build.gradle` :
```gradle
defaultConfig {
    versionCode 3        // entier, +1 à chaque upload Play Console
    versionName "1.1.0"  // affiché aux utilisateurs
}
```

**iOS** — dans Xcode : General → Identity → **Build** (pas Version).
Ou via `agvtool` :
```bash
cd ios/App
agvtool new-version -all 3
```

---

## 4. Permissions — plugins Capacitor non utilisés

Les plugins Capacitor injectent souvent des permissions dans `AndroidManifest.xml` et
`Info.plist` automatiquement au `cap sync`. Si un plugin est installé mais la feature
n'est pas utilisée, les permissions doivent être retirées explicitement.

**Android** :
```xml
<!-- AndroidManifest.xml — retirer les permissions inutiles -->
<uses-permission android:name="android.permission.CAMERA"
    tools:node="remove"/>
<uses-permission android:name="android.permission.READ_CONTACTS"
    tools:node="remove"/>
```

**iOS** — supprimer dans `Info.plist` les clés `NS*UsageDescription` correspondant
aux permissions non utilisées. Xcode les affiche dans Target → Info → Custom iOS Target Properties.

---

## 5. Guideline 4.2 Apple — justifier une app Capacitor

Apple peut rejeter une app Capacitor comme "thin app" ou "wrapper de site web". Dans le champ
**Notes for Reviewer** d'App Store Connect, expliquer explicitement :
- L'app fonctionne entièrement offline (si applicable)
- Le contenu est embarqué localement (pas chargé depuis une URL externe)
- Les fonctionnalités natives utilisées (haptics, notifications, camera…)

---

## 6. Live updates (Capacitor Updater / Ionic Appflow)

| Store | Statut |
|-------|--------|
| Google Play | ✅ Autorisé |
| App Store | ⚠️ Limité — corrections de bugs et contenu uniquement (guideline 3.3.2) |

Sur iOS, les live updates ne peuvent pas ajouter de nouvelles fonctionnalités ni modifier
le comportement principal de l'app. Les utiliser pour des correctifs ou du contenu dynamique
(textes, images, packs de données) est généralement accepté.

---

## 7. Workflow de build complet

```bash
# 1. Build web
npm run build

# 2. Sync vers les projets natifs
npx cap sync

# 3. Android — générer l'AAB signé
# Android Studio : Build → Generate Signed Bundle/APK → Android App Bundle
# Puis uploader l'AAB dans la Play Console

# 4. iOS — archiver depuis Xcode
# Product → Archive → Distribute App → App Store Connect
```

---

## 8. Checklist pré-soumission Capacitor

- [ ] `server.url` absent de `capacitor.config.ts`
- [ ] `androidScheme: 'https'` présent
- [ ] `sourcemap: false` dans `vite.config.ts`
- [ ] `base: './'` dans `vite.config.ts`
- [ ] `npx cap sync` exécuté après le dernier build
- [ ] `versionCode` (Android) et Build number (iOS) incrémentés
- [ ] Permissions inutiles (plugins non utilisés) retirées de AndroidManifest et Info.plist
- [ ] App testée en mode release (pas dev) sur un vrai appareil physique
- [ ] Notes for Reviewer rédigées (justifier l'app si hybride/offline)
