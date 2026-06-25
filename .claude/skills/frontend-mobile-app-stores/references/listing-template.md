# Template — Préparation des fiches store

Remplir ce document avant toute soumission. Il sert de source de vérité commune aux deux stores :
la plupart des champs se réutilisent, avec des adaptations mineures de longueur ou format.

---

## BLOC 1 — Identité de l'app (commun aux deux stores)

| Champ | Valeur | Contraintes |
|-------|--------|-------------|
| **Nom de l'app** | | 30 car. max (Apple & Google) |
| **Bundle ID / Package Name** | | ex: `com.studio.appname` — immuable après création |
| **Catégorie principale** | | ex: Education, Productivity, Lifestyle |
| **Catégorie secondaire** | | Optionnel |
| **Age rating** | | 4+, 9+, 12+, 17+ (Apple) / Everyone, Teen… (Google) |
| **Langue principale** | | ex: fr-FR, en-US |
| **URL politique de confidentialité** | | URL publique stable, sans login |
| **URL support** | | Page de contact ou FAQ accessible |
| **Copyright** | | ex: © 2025 Studio Name |

---

## BLOC 2 — Textes de la fiche (à rédiger en amont)

### App Name & Subtitle

| Champ | Texte rédigé | Long. | Limite |
|-------|-------------|-------|--------|
| **App Name** | | | 30 car. |
| **Subtitle** (Apple) | | | 30 car. |
| **Short Description** (Google) | | | 80 car. |

> Le subtitle Apple apparaît directement sous le nom dans les résultats de recherche.
> La short description Google s'affiche sur la fiche avant le bouton "Voir plus".

---

### Description longue

La description longue est partagée entre les deux stores (4000 car. chacun).
Les 3 premières lignes sont visibles sans cliquer sur "Voir plus" — soigner l'accroche.

```
[APP NAME] — [Proposition de valeur en une phrase]

[Paragraphe 1 — Problème résolu / bénéfice principal]


[Paragraphe 2 — Fonctionnalités clés]
• 
• 
• 

[Paragraphe 3 — Pour qui / cas d'usage]


[Appel à l'action]
```

> Copier-coller ce squelette, rédiger en clair, puis adapter si besoin par store.

---

### Keywords / Mots-clés

| Store | Champ | Texte | Long. | Limite |
|-------|-------|-------|-------|--------|
| **Apple** | Keywords | | | 100 car., séparés par virgules sans espace |
| **Google** | Intégrés dans la description | — | — | Pas de champ dédié |

> Apple : ne pas répéter le nom de l'app dans les keywords (déjà indexé).
> Google : les mots-clés sont extraits automatiquement du titre et de la description.

---

### Promotional Text (Apple uniquement)

| Champ | Texte | Long. | Notes |
|-------|-------|-------|-------|
| **Promotional Text** | | | 170 car. max — modifiable sans mise à jour |

> Utilisé pour les promotions temporaires, nouveautés, ou mise en avant d'une feature.
> Seul champ modifiable sans soumettre une nouvelle version.

---

## BLOC 3 — Assets visuels

### Icône

| Plateforme | Taille | Format | Notes |
|------------|--------|--------|-------|
| Apple (App Store) | 1024×1024 px | PNG, sans alpha | Générée depuis l'icône Xcode |
| Google Play | 512×512 px | PNG 32 bits avec alpha | Uploadée directement dans la Play Console |

> Source recommandée : un fichier maître 1024×1024 px depuis lequel tout est généré.

---

### Screenshots

#### App Store (Apple)

| Slot | Device | Résolution | Obligatoire |
|------|--------|------------|-------------|
| iPhone principal | 6.9" (iPhone 16 Pro Max) | 1320×2868 px | ✅ Oui |
| iPhone secondaire | 6.7" (iPhone 15 Plus) | 1290×2796 px | Si différent du 6.9" |
| iPad principal | 13" (iPad Pro M4) | 2064×2752 px | ✅ Si iPad supporté |
| iPad secondaire | 11" (iPad Pro M2) | 1668×2388 px | Si différent du 13" |

Contenu des screenshots à planifier :

| # | Écran à capturer | Message clé à faire passer |
|---|-----------------|---------------------------|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |

#### Google Play

| Asset | Dimensions | Format | Obligatoire |
|-------|-----------|--------|-------------|
| Screenshot téléphone | 320–3840 px, ratio max 2:1 | JPEG ou PNG | ✅ Min. 2 |
| Screenshot tablette 7" | Idem | JPEG ou PNG | Recommandé |
| Screenshot tablette 10" | Idem | JPEG ou PNG | Recommandé |
| Feature Graphic | 1024×500 px | JPEG ou PNG, sans alpha | ✅ Oui |

---

### Vidéo de preview (optionnel)

| Store | Format | Durée | Notes |
|-------|--------|-------|-------|
| Apple App Preview | .mov ou .mp4, résolution native device | 15–30 s | Doit montrer l'app réelle, pas une vidéo marketing |
| Google Play | URL YouTube | Libre | La vidéo doit être publique ou non listée |

---

## BLOC 4 — Informations de classification

| Champ | Valeur | Notes |
|-------|--------|-------|
| **Contenu pour enfants** | Oui / Non | Si Oui → restrictions SDK sur Apple |
| **Contenu généré par les utilisateurs** | Oui / Non | Implique une modération |
| **Publicité** | Oui / Non | Google : déclarer si l'app contient des pubs |
| **Achats in-app** | Oui / Non | Si Oui → IAP Apple, déclaration Google Play |
| **Type d'IAP** (si applicable) | Consommable / Non-consommable / Abonnement | |
| **Prix de l'app** | Gratuit / Payant | Si payant : montant et devise |

---

## BLOC 5 — Informations pour les reviewers (Apple)

À saisir dans le champ "Notes for Reviewer" d'App Store Connect :

```
Compte de démo (si login requis)
  Email    : 
  Password : 

Instructions spéciales :
  [ Décrire ici toute étape non évidente pour tester l'app ]
  [ Justifier les fonctionnalités natives si app hybride/offline ]
  [ Expliquer pourquoi certaines permissions sont demandées ]
```

---

## BLOC 6 — Contacts & liens internes

| Rôle | Nom | Contact |
|------|-----|---------|
| Responsable soumission | | |
| Contact support (affiché sur le store) | | |
| Contact juridique / DPO | | |

---

## BLOC 7 — Suivi des soumissions

| Version | Date soumission | Store | Statut | Notes |
|---------|----------------|-------|--------|-------|
| | | App Store | | |
| | | Google Play | | |
