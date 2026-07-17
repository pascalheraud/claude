# Checklists de soumission store

Deux checklists indépendantes, une par store. Chacune couvre l'intégralité du processus de
préparation jusqu'à la mise en ligne, dans l'ordre chronologique.

---

# ✅ CHECKLIST APP STORE (APPLE)

## PHASE 1 — Préparation du compte

- [ ] Compte Apple Developer Program actif (99 $/an)
- [ ] Accord Paid Applications signé dans App Store Connect (obligatoire même pour les apps gratuites avec IAP)
- [ ] Rôle "App Manager" ou supérieur sur le compte App Store Connect
- [ ] Certificat de distribution iOS valide dans Xcode (Signing & Capabilities)
- [ ] Provisioning Profile de distribution généré et à jour

## PHASE 2 — Fiche store (App Store Connect)

- [ ] App créée dans App Store Connect (My Apps → +)
- [ ] Bundle ID enregistré et correspondant à celui de l'app
- [ ] **App Name** rempli (≤ 30 car.)
- [ ] **Subtitle** rempli (≤ 30 car.)
- [ ] **Promotional Text** rédigé (≤ 170 car. — modifiable sans mise à jour)
- [ ] **Description** rédigée (≤ 4000 car., accroche forte dans les 3 premières lignes)
- [ ] **Keywords** saisis (≤ 100 car., séparés par virgules sans espace, sans répéter le nom)
- [ ] **Support URL** renseignée (page accessible sans login)
- [ ] **Privacy Policy URL** renseignée (URL publique stable)
- [ ] **Copyright** renseigné (ex: © 2025 Studio Name)
- [ ] Catégorie principale sélectionnée
- [ ] Catégorie secondaire sélectionnée (optionnel)

## PHASE 3 — Assets visuels

- [ ] **Icône** 1024×1024 px, PNG sans alpha, intégrée dans Xcode (générée automatiquement)
- [ ] **Screenshots iPhone 6.9"** (1320×2868 px) — obligatoires, min. 1, max. 10
- [ ] Screenshots iPhone 6.7" (1290×2796 px) — optionnels si 6.9" fournis
- [ ] **Screenshots iPad 13"** (2064×2752 px) — obligatoires si l'app supporte iPad
- [ ] Screenshots iPad 11" (1668×2388 px) — optionnels si 13" fournis
- [ ] Screenshots montrent l'app réelle (pas des mockups sans UI)
- [ ] App Preview video (optionnel, 15–30 s, .mov/.mp4, résolution native)

## PHASE 4 — Classification & confidentialité

- [ ] **Age Rating** rempli (questionnaire dans App Store Connect)
- [ ] Section **App Privacy** complétée (toutes les données collectées déclarées, y compris via SDK tiers)
- [ ] Si app pour enfants : "Designed for Kids" coché et SDK approuvés uniquement
- [ ] Si IAP : type déclaré (consommable / non-consommable / abonnement)
- [ ] Si IAP non-consommable : bouton "Restore Purchases" présent dans l'app

## PHASE 5 — Build & technique

- [ ] Build en mode **Release** (pas Debug)
- [ ] `NSUsageDescription` dans `Info.plist` pour chaque permission utilisée, formulation spécifique
- [ ] Aucune permission déclarée qui n'est pas utilisée
- [ ] Pas de code de debug ou `console.log` sensible en production
- [ ] Pas d'écran vide, placeholder, ou feature "Coming Soon" visible
- [ ] App fonctionne sans réseau (si présentée comme offline)
- [ ] App testée sur un vrai appareil physique en mode release
- [ ] Numéro de **Build (CFBundleVersion)** incrémenté par rapport au dernier upload
- [ ] Numéro de **Version (CFBundleShortVersionString)** mis à jour si applicable
- [ ] Build uploadé via Xcode (Product → Archive → Distribute) ou `xcrun altool`

## PHASE 6 — Soumission

- [ ] Build sélectionné dans App Store Connect (onglet "Build")
- [ ] **Notes for Reviewer** remplies :
  - [ ] Compte de démo (email + mot de passe) si login requis
  - [ ] Instructions spéciales si flow non évident
  - [ ] Justification des fonctionnalités natives si app hybride ou offline
  - [ ] Explication des permissions si leur usage n'est pas évident
- [ ] Pas de paiement web pour du contenu numérique in-app
- [ ] Pas de lien vers d'autres stores ou méthodes de paiement alternatives
- [ ] Soumission envoyée → statut "Waiting for Review"

## PHASE 7 — Après soumission

- [ ] Surveiller les notifications App Store Connect (email + portail)
- [ ] En cas de rejet : lire le message dans le Resolution Center avant de re-soumettre
- [ ] Ne pas re-soumettre sans adresser le motif de rejet (allonge les délais)
- [ ] En cas de rejet injustifié : utiliser le bouton "Appeal" dans le Resolution Center

---

# ✅ CHECKLIST GOOGLE PLAY

## PHASE 1 — Préparation du compte

- [ ] Compte Google Play Developer actif (frais unique 25 $)
- [ ] Informations de paiement configurées dans la Play Console
- [ ] Accord Developer Distribution Agreement accepté
- [ ] Si IAP : compte Google Payments configuré

## PHASE 2 — Fiche store (Play Console)

- [ ] App créée dans la Play Console (Create app)
- [ ] Type d'app sélectionné (App ou Game)
- [ ] Distribution sélectionnée (Gratuit / Payant)
- [ ] **App Name** renseigné (≤ 30 car.)
- [ ] **Short Description** rédigée (≤ 80 car. — s'affiche dans les résultats de recherche)
- [ ] **Full Description** rédigée (≤ 4000 car., accroche forte au début)
- [ ] **Support email** renseigné (affiché sur la fiche)
- [ ] **Privacy Policy URL** renseignée
- [ ] Catégorie sélectionnée
- [ ] Tags sélectionnés (optionnel, améliorent la découvrabilité)

## PHASE 3 — Assets visuels

- [ ] **Icon** 512×512 px, PNG 32-bit with alpha channel
- [ ] **Feature Graphic** 1024×500 px, JPEG or PNG without alpha — required
- [ ] **Phone screenshots**: min. 2, JPEG or PNG, between 320–3840 px per side (ratio 9:16 or 16:9) — recommended 1080×1920 px, DPR=1
- [ ] **7" tablet screenshots**: min. 2, **required** to save the store listing — recommended 1200×1920 px, DPR=1
- [ ] 10" tablet screenshots (optional)
- [ ] **Capture from browser DevTools**: F12 → phone icon → set resolution manually → DPR=1 → take screenshot. Never use DPR=2 (doubles resolution, exceeds 3840 px limit)
- [ ] **Video** (optional): YouTube URL, public or unlisted

## PHASE 4 — Classification & confidentialité

- [ ] **Content Rating** rempli (questionnaire IARC dans Play Console → Policy → App content)
- [ ] Section **Data Safety** complétée (Policy → App content → Data safety)
  - [ ] Données collectées déclarées (y compris via Firebase, Sentry, etc.)
  - [ ] Partage avec des tiers déclaré si applicable
  - [ ] Chiffrement en transit déclaré
  - [ ] Option "Delete data" proposée si des données sont collectées
- [ ] Si app pour enfants : programme Families activé (restrictions supplémentaires)
- [ ] Si contenu généré par utilisateurs : politique de modération déclarée
- [ ] Si publicités : déclaré dans le questionnaire App content
- [ ] Si IAP : déclaré dans App content → In-app purchases

## PHASE 5 — Build & technique

- [ ] **targetSdkVersion** à jour (API 34 minimum en 2025 — vérifier exigence courante)
- [ ] **minSdkVersion** adapté (21 recommandé pour couvrir ~99% des appareils)
- [ ] Build en mode **Release**, signé
- [ ] Format **AAB** (Android App Bundle) — pas APK
- [ ] **Play App Signing** activé (par défaut sur les nouvelles apps)
- [ ] **Upload Key** (.jks / .keystore) sauvegardée en lieu sûr
- [ ] Pas de permissions inutiles dans `AndroidManifest.xml`
- [ ] Permissions dangereuses justifiées (si `MANAGE_EXTERNAL_STORAGE` etc. : justification écrite requise)
- [ ] Pas de code de debug en production
- [ ] Pas d'écran vide, placeholder, ou feature "Coming Soon" visible
- [ ] App testée sur un vrai appareil physique en mode release
- [ ] **versionCode** incrémenté (entier strict, +1 minimum par rapport au dernier upload)
- [ ] **versionName** mis à jour si applicable

## PHASE 6 — Submission

**New developer accounts**: Google requires closed testing with 12 testers for 14 days before production access.

- [ ] Upload AAB to Internal testing track → verify on physical device
  - Each tester must be added by email to a distribution list (no open link for internal testing)
  - Open link from **Chrome** signed in with an account in the list; release must be **Active** (not Draft)
- [ ] Upload AAB to Closed testing track → submit for Google review (delay: a few hours to 7 days)
  - Once approved, get the open link: Testers → "Join on the web" → share on r/androiddev
  - Wait for 12 testers and 14 days (starting from the first tester who joins)
- [ ] Request production access from the Play Console dashboard after 14 days
- [ ] Upload AAB to Production → all left-nav sections green ✅
- [ ] Submit for review → status "In review"

## PHASE 7 — After submission

- [ ] Monitor Play Console notifications and developer email
- [ ] If rejected: read the reason in Policy status before resubmitting
- [ ] If suspended: use the Appeal button in Policy status
- [ ] Staged rollout: monitor metrics (crashes, ANR, ratings) before expanding rollout
- [ ] Stop rollout immediately if crash rate > 1% or ratings drop sharply
