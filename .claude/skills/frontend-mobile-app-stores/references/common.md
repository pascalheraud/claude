# Règles communes — App Store & Google Play

## 1. Fonctionnalité réelle requise

Une app doit offrir une expérience qui justifie une installation native. Apple est particulièrement
strict : une WebView qui charge une URL externe est rejetée (guideline 4.2). Une app JS embarquée
(assets locaux, offline, interactions natives) passe si l'expérience est substantielle.

Critères qui renforcent le dossier :
- Fonctionnement offline
- Accès à des capacités natives (camera, haptics, notifications, géolocalisation)
- Contenu embarqué non accessible via un simple browser

## 2. Pas de code exécutable téléchargé à la volée

Les deux stores interdisent d'exécuter du code JS téléchargé après installation.

| Pratique | Android | iOS |
|----------|---------|-----|
| `eval()` sur code distant | ❌ | ❌ |
| Bundle JS chargé depuis CDN | ❌ | ❌ |
| Live updates (Expo OTA, Ionic Appflow, Capacitor Updater) | ✅ autorisé | ⚠️ limité |

**Règle iOS pour les live updates (guideline 3.3.2)** : autorisé uniquement si la mise à jour ne
change pas les fonctionnalités principales de l'app, n'ajoute pas de fonctionnalités majeures, et
reste dans le périmètre décrit lors de la soumission. En pratique : corrections de bugs et contenu
→ OK. Nouvelles features → risque de rejet.

## 3. Permissions — déclarer uniquement ce qu'on utilise

Chaque permission non utilisée est un motif de rejet ou de suspension potentiel.

**Android** — supprimer les permissions auto-ajoutées par les SDK ou frameworks non utilisés :
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" tools:node="remove"/>
```

**iOS** — chaque `NS*UsageDescription` dans `Info.plist` doit être honnête et spécifique au cas
d'usage réel. Une description vague ou générique entraîne un rejet.

```xml
<!-- ✅ Accepté -->
<key>NSCameraUsageDescription</key>
<string>Used to scan QR codes for importing vocabulary packs</string>

<!-- ❌ Rejeté -->
<key>NSCameraUsageDescription</key>
<string>This app requires camera access</string>
```

Demander les permissions **au moment où elles sont nécessaires** (not at launch), et expliquer
le contexte à l'utilisateur avant le prompt système.

## 4. Politique de confidentialité

**Obligatoire** dès qu'une de ces conditions est vraie :
- L'app collecte des données utilisateur (même anonymes ou agrégées)
- L'app utilise des analytics (Firebase, Mixpanel, Amplitude…)
- L'app s'adresse à des mineurs (COPPA aux US, RGPD enfants en Europe)
- L'app utilise des SDK tiers qui collectent des données
- L'app propose des achats in-app

La politique doit :
- Être accessible sur une URL publique stable (pas un PDF téléchargeable)
- Lister explicitement quelles données sont collectées et pourquoi
- Mentionner les SDK tiers et leurs propres politiques
- Être déclarée dans les métadonnées du store (champ dédié sur les deux plateformes)

## 5. Paiements numériques

**Apple** : tout achat de contenu numérique ou fonctionnalité in-app **doit passer par l'IAP
Apple** (30% de commission, réduit à 15% pour les petits développeurs via le Small Business Program).
Impossible de rediriger vers un paiement web pour du contenu consommé dans l'app.

Exceptions Apple :
- Apps B2B avec authentification compte entreprise
- "Reader apps" (Netflix, Spotify) : peuvent ne pas proposer d'achat in-app si l'abonnement
  est géré en dehors, mais ne peuvent pas mettre de lien vers leur propre page de paiement
- Biens et services physiques (livraison, covoiturage, e-commerce) → paiement web autorisé

**Google** : mêmes règles en substance, avec commission de 15–30% selon le cas. Google est
légèrement plus souple sur les liens vers des alternatives de paiement dans certaines régions
(suite à des décisions réglementaires en Corée du Sud, Europe).

## 6. Age rating & contenu pour enfants

Déclarer le bon age rating lors de la soumission. Si l'app cible des enfants (< 13 ans US,
< 16 ans Europe) :
- Pas de publicité comportementale
- Pas de collecte de données personnelles sans consentement parental
- Pas de liens vers des sites externes
- Pas d'achats in-app sans confirmation parentale

Sur l'App Store, cela implique de cocher "Designed for Kids" — ce qui impose des restrictions
supplémentaires sur les SDK autorisés (liste Apple de SDK approuvés uniquement).

## 7. Ce qui déclenche une re-review

Les deux stores re-reviewent l'app à chaque mise à jour. Apple est plus systématique :

| Changement | Apple | Google Play |
|------------|-------|-------------|
| Correction de bug | ✅ re-review | Souvent automatique |
| Nouvelle fonctionnalité | ✅ re-review | ✅ re-review |
| Nouvelle permission | ✅ re-review | ✅ re-review |
| Changement de catégorie | ✅ re-review | ✅ re-review |
| Changement de screenshots | ✅ re-review | Parfois automatique |

Délais moyens : App Store 24–48h (jusqu'à 7j), Google Play quelques heures à 3 jours.
