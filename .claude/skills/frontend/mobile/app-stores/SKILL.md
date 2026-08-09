---
name: app-stores
description: >
  Use this skill whenever preparing, submitting, or reviewing a JavaScript/TypeScript mobile app
  for the Apple App Store or Google Play Store. Triggers include: any mention of app submission,
  store review, App Store Connect, Play Console, app rejection, screenshots for store, privacy policy
  for app, IAP, in-app purchase, app signing, AAB, versionCode, CFBundleVersion, Data Safety,
  targetSdkVersion, app metadata, app rating, age rating, COPPA, TestFlight, internal/external testing,
  release track, or any question about what Apple or Google allow or reject. Also trigger when the
  user asks about live updates, OTA updates, or code push in a mobile app context.
  When in doubt and a store submission context is likely, trigger this skill.
---

# JS App Stores — App Store & Google Play Submission Skill

Ce skill couvre les règles, pièges et checklists pour soumettre une app JS/TS mobile (React Native,
Capacitor, Ionic, Expo, ou autre) sur l'App Store Apple et Google Play.

Pour les précautions **spécifiques à Capacitor** (config, version bumping, permissions plugins),
voir `references/store.md` dans la skill `capacitor-mobile`.

Lire le fichier de référence selon la situation :
- **Règles communes aux deux stores** → `references/common.md`
- **App Store (Apple)** → `references/appstore.md`
- **Google Play** → `references/googleplay.md`
- **Préparer la fiche store** → `references/listing-template.md`
- **Checklists phase par phase** → `references/checklist.md`

---

## Quick decision map

| Situation | Go to |
|-----------|-------|
| Politique de confidentialité, permissions, code distant | `references/common.md` |
| Screenshots, IAP, review Apple, TestFlight | `references/appstore.md` |
| targetSdkVersion, AAB, Data Safety, tracks | `references/googleplay.md` |
| Guideline 4.2 (wrapper WebView), 3.1 (paiements) | `references/appstore.md` |
| Live updates / OTA — légalité par store | `references/common.md` |
| Préparer / remplir la fiche store (textes, assets, contacts) | `references/listing-template.md` |
| Checklist complète App Store ou Google Play | `references/checklist.md` |

---

## Checklist pré-soumission

Pour la checklist complète phase par phase (compte, fiche, assets, technique, soumission, après
soumission), lire `references/checklist.md` — une checklist indépendante par store.

Rappel rapide des points les plus souvent oubliés :

- [ ] Politique de confidentialité sur URL publique stable
- [ ] Permissions déclarées = permissions réellement utilisées
- [ ] App testée en mode release sur un vrai appareil physique
- [ ] Aucune feature "Coming Soon" ou écran vide visible
- [ ] Build/version number incrémenté
- [ ] **Apple** : Notes for Reviewer remplies (compte de démo + justifications)
- [ ] **Apple** : `NSUsageDescription` spécifique pour chaque permission
- [ ] **Apple** : IAP Apple pour tout achat numérique in-app
- [ ] **Google** : `targetSdkVersion` à jour, AAB uploadé, Data Safety remplie
