# App Store (Apple) — Référence complète

## 1. Guidelines critiques

### Guideline 4.2 — Minimum Functionality
L'app doit offrir une valeur suffisante pour justifier une installation. Motifs de rejet fréquents :
- Simple wrapper autour d'un site web existant
- App avec trop peu de contenu ou fonctionnalités ("thin app")
- App dont toutes les fonctionnalités sont déjà disponibles dans Safari

Pour une app hybride/JS : mettre en avant le mode offline, les interactions natives, et le contenu
embarqué dans le champ "Notes for Reviewer" lors de la soumission.

### Guideline 2.1 — App Completeness
Ne soumettre que ce qui est terminé :
- Pas d'écrans avec "Coming Soon" ou placeholders visibles
- Pas de boutons qui ne font rien
- Pas de features désactivées sans explication claire

Désactiver proprement (masquer) toute feature non prête plutôt que de la laisser visible mais cassée.

### Guideline 3.1 — Payments & Purchases
- Tout achat numérique in-app → IAP Apple obligatoire
- Ne pas mentionner d'autres moyens de paiement dans l'app
- Ne pas rediriger vers un site web pour acheter du contenu in-app
- Bouton "Restore Purchases" obligatoire si l'app a des IAP non-consommables

### Guideline 5.1.1 — Data Collection & Storage
- Collecter uniquement les données nécessaires au fonctionnement
- Ne pas accéder au carnet d'adresses, photos, localisation sans raison légitime
- Données sensibles chiffrées en transit et au repos

---

## 2. App Store Connect — Metadata

### Screenshots (obligatoires)
| Device | Taille | Obligatoire |
|--------|--------|-------------|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320×2868 px | ✅ Oui |
| iPhone 6.7" (iPhone 15 Plus) | 1290×2796 px | Optionnel si 6.9" fourni |
| iPad 13" (iPad Pro M4) | 2064×2752 px | ✅ Si l'app supporte iPad |
| iPad 11" | 1668×2388 px | Optionnel si 13" fourni |

Règles screenshots :
- Montrer l'app réelle en fonctionnement (pas des mockups sur fond dégradé)
- Le contenu visible doit correspondre à ce que l'app fait réellement
- Pas de bordures de device physique sauf si générées par Xcode

### App Preview (vidéo — optionnel mais recommandé)
- Durée : 15–30 secondes
- Doit montrer l'app en fonctionnement réel (pas une vidéo marketing)
- Enregistrement depuis un vrai appareil ou simulateur Xcode
- Format : .mov ou .mp4, résolution native du device

### Textes
- **App Name** : 30 caractères max, pas de mots-clés génériques (ex: "Best App")
- **Subtitle** : 30 caractères, apparaît sous le nom dans les résultats de recherche
- **Keywords** : 100 caractères, séparés par virgules, pas d'espaces après virgule
- **Description** : 4000 caractères, les 3 premières lignes visibles avant "More"
- **Promotional Text** : 170 caractères, modifiable sans mise à jour de l'app

### Support URL & Privacy Policy URL
Les deux champs sont obligatoires. L'URL de politique de confidentialité doit être accessible
sans login.

---

## 3. Permissions iOS — NSUsageDescription

Chaque permission accédée doit avoir une entrée dans `Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string><!-- Raison spécifique et honnête --></string>

<key>NSMicrophoneUsageDescription</key>
<string><!-- ... --></string>

<key>NSLocationWhenInUseUsageDescription</key>
<string><!-- ... --></string>

<key>NSPhotoLibraryUsageDescription</key>
<string><!-- ... --></string>

<key>NSContactsUsageDescription</key>
<string><!-- ... --></string>

<key>NSFaceIDUsageDescription</key>
<string><!-- ... --></string>
```

---

## 4. Privacy Nutrition Labels (App Privacy)

Dans App Store Connect, déclarer toutes les données collectées, même via des SDK tiers.
Apple affiche ces informations sur la fiche de l'app.

Catégories à déclarer si applicable :
- **Contact Info** : email, nom, téléphone
- **Identifiers** : User ID, Device ID
- **Usage Data** : historique de navigation in-app, données de crash
- **Diagnostics** : logs de performance

Les SDK courants qui collectent des données et nécessitent une déclaration :
- Firebase Analytics / Crashlytics
- Sentry
- Amplitude, Mixpanel
- Meta / Google Ads SDK

---

## 5. TestFlight — tests avant soumission

TestFlight permet de distribuer des builds à des testeurs avant soumission officielle.

**Internal testing** (jusqu'à 100 testeurs, membres de l'équipe App Store Connect) :
- Disponible immédiatement après upload
- Pas de review Apple

**External testing** (jusqu'à 10 000 testeurs, invitation par email ou lien public) :
- Require une Beta App Review d'Apple (généralement 24–48h)
- Obligatoire pour tester avec des utilisateurs extérieurs à l'équipe

Workflow recommandé :
1. Build release → upload via Xcode ou `xcrun altool`
2. Internal testing avec l'équipe
3. External testing sur un panel représentatif
4. Soumission en production

---

## 6. Compte de démo pour les reviewers

Si l'app nécessite une connexion, fournir un compte de démo fonctionnel dans le champ
"Notes for Reviewer" d'App Store Connect. Sans ça, le reviewer ne peut pas tester l'app → rejet.

Le compte doit :
- Fonctionner sans intervention de l'équipe
- Avoir du contenu pré-rempli représentatif
- Ne pas expirer pendant la période de review

---

## 7. Répondre à un rejet

En cas de rejet, Apple envoie un message dans App Store Connect Resolution Center.

Options :
- **Corriger et re-soumettre** : adresser le point soulevé, mettre à jour le build
- **Appeler la décision** : si le rejet semble injustifié, utiliser le bouton "Appeal"
- **Contacter l'App Review** : via le Resolution Center pour clarifier avant re-soumission

Ne jamais re-soumettre sans adresser le motif de rejet — cela allonge les délais.
